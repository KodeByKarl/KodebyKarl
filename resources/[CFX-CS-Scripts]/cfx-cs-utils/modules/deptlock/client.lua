local config = require 'configs.deptlock'

local allowedJobs = config.jobs or {}
local pistols = config.pistols or {}
local lastNotify = 0

local function isAllowedJob()
    local data = ESX.GetPlayerData and ESX.GetPlayerData() or {}
    local job = data.job and data.job.name
    return job and allowedJobs[job] == true
end

local function isLockedPistol(weapon)
    if type(weapon) == 'string' then
        return pistols[weapon] == true
    end
    if type(weapon) == 'number' then
        for name in pairs(pistols) do
            if joaat(name) == weapon then
                return true
            end
        end
    end
    return false
end

local function notifyDenied()
    local now = GetGameTimer()
    local cooldown = tonumber(config.notifyCooldown) or 4000
    if (now - lastNotify) < cooldown then return end
    lastNotify = now
    ESX.Notify(
        config.notifyTitle or 'DEPARTMENT',
        config.notifyMessage or 'Only Police and Sheriff can use this.',
        'error',
        5000
    )
end

local function denyPistol()
    notifyDenied()
    TriggerEvent('ox_inventory:disarm', true)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
end

local function enforce(weapon)
    if not weapon or isAllowedJob() then return end
    if isLockedPistol(weapon) then
        denyPistol()
    end
end

AddEventHandler('ox_inventory:currentWeapon', function(item)
    if not item or not item.name then return end
    enforce(item.name)
end)

AddEventHandler('esx:setJob', function()
    if cache.weapon then
        enforce(cache.weapon)
    end
end)

CreateThread(function()
    while true do
        local weapon = cache.weapon
        if weapon and not isAllowedJob() and isLockedPistol(weapon) then
            denyPistol()
            Wait(500)
        else
            Wait(1000)
        end
    end
end)
