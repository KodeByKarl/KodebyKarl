local ESX = exports['es_extended']:getSharedObject()
local configs = require 'shared.config'
local lastHarvest = {}

local function mopCfg()
    return configs.MopGrind
end

local function isAllowedJob(jobName)
    local cfg = mopCfg()
    if not cfg or not cfg.jobs then return false end
    return cfg.jobs[jobName] == true
end

local function resolveSpot(entry)
    if not entry then return nil end
    if type(entry) == 'vector4' or type(entry) == 'vector3' then
        return { x = entry.x, y = entry.y, z = entry.z, w = entry.w }
    end
    local coords = entry.coords or entry
    if not coords or not coords.x then return nil end
    return { x = coords.x, y = coords.y, z = coords.z, w = coords.w }
end

lib.callback.register('kodebykarl-ambulance:server:harvestCoins', function(source, spotIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then
        return false
    end

    local cfg = mopCfg()
    if not cfg or not cfg.enabled or not cfg.locations then
        return false
    end

    if not isAllowedJob(xPlayer.job.name) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'EMS',
            description = 'Only EMS staff can earn coins here.',
            type = 'error',
        })
        return false
    end

    local spot = resolveSpot(cfg.locations[spotIndex])
    if not spot then
        return false
    end

    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    local targetCoords = vector3(spot.x, spot.y, spot.z)
    if #(pCoords - targetCoords) > 4.5 then
        return false
    end

    local now = GetGameTimer()
    if lastHarvest[src] and (now - lastHarvest[src]) < 6500 then
        return false
    end
    lastHarvest[src] = now

    local reward = cfg.reward or {}
    local itemName = reward.item or 'grimemscoin'
    local amount = math.floor(tonumber(reward.amount) or 10)
    if amount < 1 then
        return false
    end

    local canCarry = exports.ox_inventory:CanCarryItem(src, itemName, amount)
    if not canCarry then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'EMS',
            description = 'Your inventory is full. You cannot carry more EMS coins.',
            type = 'error',
            duration = 4000,
        })
        return false
    end

    local success = exports.ox_inventory:AddItem(src, itemName, amount)
    if success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'EMS',
            description = ('Earned %d EMS Coin%s. Spend them at the EMS shop.'):format(amount, amount == 1 and '' or 's'),
            type = 'success',
            duration = 3500,
        })
        return true
    end

    return false
end)

AddEventHandler('playerDropped', function()
    lastHarvest[source] = nil
end)
