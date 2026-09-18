local config = require 'configs.thermal'

local FG_RESOURCE_CANDIDATES = { 'grimbot', 'fiveguard', 'fg', 'FiveGuard' }
local HELI_FG_PERMS = { 'BypassNightVision', 'BypassThermalVision', 'BypassFreecam' }
local active = {}

local function fgResource()
    local named = GetConvar('fiveguard_resource', '')
    if named ~= '' and GetResourceState(named) == 'started' then
        return named
    end
    for i = 1, #FG_RESOURCE_CANDIDATES do
        local name = FG_RESOURCE_CANDIDATES[i]
        if GetResourceState(name) == 'started' then
            return name
        end
    end
    return nil
end

local function fgTemp(src, enable)
    local resource = fgResource()
    if not resource then return end
    pcall(function()
        for i = 1, #HELI_FG_PERMS do
            exports[resource]:SetTempPermission(src, 'Client', HELI_FG_PERMS[i], enable == true, false)
        end
    end)
end

local function hasHeliJob(src)
    local xPlayer = ESX and ESX.GetPlayerFromId and ESX.GetPlayerFromId(src)
    local job = xPlayer and xPlayer.job and xPlayer.job.name
    if not job then
        local state = Player(src).state
        job = state and state.job
        if type(job) == 'table' then
            job = job.name
        end
    end
    return job and config.jobs and config.jobs[job] ~= nil
end

local function setHeliVision(src, enable)
    if enable then
        if not hasHeliJob(src) then return end
        active[src] = true
        fgTemp(src, true)
        return
    end
    if not active[src] then return end
    active[src] = nil
    fgTemp(src, false)
end

RegisterNetEvent('kodebykarl-utils:thermal:heliVision', function(enabled)
    setHeliVision(source, enabled == true)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if active[src] then
        active[src] = nil
        fgTemp(src, false)
    end
end)
