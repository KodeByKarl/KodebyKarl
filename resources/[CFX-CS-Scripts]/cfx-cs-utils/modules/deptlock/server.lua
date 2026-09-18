local config = require 'configs.deptlock'

local allowedJobs = config.jobs or {}
local consumables = config.consumables or {}
local pistols = config.pistols or {}
local lastNotify = {}

local function isAllowedJob(jobName)
    return type(jobName) == 'string' and allowedJobs[jobName] == true
end

local function playerAllowed(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then return false end
    return isAllowedJob(xPlayer.job.name)
end

local function lockedItemName(name)
    if type(name) ~= 'string' or name == '' then return false end
    return consumables[name] == true or pistols[name] == true
end

local function itemFilter()
    local filter = {}
    for name in pairs(consumables) do
        filter[name] = true
    end
    for name in pairs(pistols) do
        filter[name] = true
    end
    return filter
end

local function notifyDenied(src)
    if type(src) ~= 'number' or src < 1 then return end
    local now = GetGameTimer()
    local cooldown = tonumber(config.notifyCooldown) or 4000
    if lastNotify[src] and (now - lastNotify[src]) < cooldown then return end
    lastNotify[src] = now
    TriggerClientEvent('esx:Notify', src,
        config.notifyTitle or 'DEPARTMENT',
        config.notifyMessage or 'Only Police and Sheriff can use this.',
        'error',
        5000
    )
end

local function deny(src)
    notifyDenied(src)
    TriggerClientEvent('ox_inventory:disarm', src, true)
    return false
end

local hookId

local function registerHook()
    if GetResourceState('ox_inventory') ~= 'started' then return end

    if hookId then
        pcall(function()
            exports.ox_inventory:removeHooks(hookId)
        end)
        hookId = nil
    end

    hookId = exports.ox_inventory:registerHook('usingItem', function(payload)
        local item = payload and payload.item
        local name = item and item.name
        if not lockedItemName(name) then return end
        if playerAllowed(payload.source) then return end
        return deny(payload.source)
    end, {
        itemFilter = itemFilter(),
        print = false,
    })
end

CreateThread(function()
    Wait(1000)
    registerHook()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'ox_inventory' or resource == GetCurrentResourceName() then
        CreateThread(function()
            Wait(500)
            registerHook()
        end)
    end
end)

AddEventHandler('esx:setJob', function(src, job)
    src = tonumber(src)
    if not src or isAllowedJob(job and job.name) then return end

    local weapon = exports.ox_inventory:GetCurrentWeapon(src)
    if weapon and pistols[weapon.name] then
        deny(src)
    end
end)

AddEventHandler('playerDropped', function()
    lastNotify[source] = nil
end)
