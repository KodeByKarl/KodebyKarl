local ESX = exports['es_extended']:getSharedObject()

local function isSheriffBoss(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    if xPlayer.job.name ~= (ConfigSheriff.Job or 'sheriff') then return false end
    local need = ConfigSheriff.CallsignBossGradeName or 'boss'
    return xPlayer.job.grade_name == need
end

lib.addCommand('givescs', {
    help = 'Set sheriff callsign',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Sheriff Server ID',
        },
        {
            name = 'callsign',
            type = 'string',
            help = 'Sheriff Callsign',
        },
    },
}, function(source, args)
    local src = source
    local xTarget = ESX.GetPlayerFromId(args.target)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xTarget or not xPlayer then return end

    if not isSheriffBoss(xPlayer) then
        TriggerClientEvent('esx:Notify', src, 'SHERIFF', 'Only the Sheriff boss can set callsigns.', 'error', 5000)
        return
    end

    xTarget.setMeta('callsign', args.callsign)
    TriggerClientEvent('esx:Notify', src, 'SHERIFF',
        ('You set %s callsign to %s'):format(xTarget.name, args.callsign), 'success', 5000)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if GetResourceState('kodebykarl-police') ~= 'started' then
        print('^1[kodebykarl-sheriff]^7 kodebykarl-police must be started (F6 LEO menu / cuffs).')
    else
        print('^2[kodebykarl-sheriff]^7 BCSO online — scoreboard job `sheriff`, priority bag `rb_prio_sheriff`.')
    end
end)

exports('GetJobName', function()
    return ConfigSheriff.Job or 'sheriff'
end)

exports('GetOffDutyJobName', function()
    return ConfigSheriff.OffDutyJob or 'offsheriff'
end)

-- Sheriff Coin Harvest Server Callback
local lastHarvest = {}

lib.callback.register('kodebykarl-sheriff:server:harvestCoins', function(source, spotIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then
        return false
    end

    local allowedJob = (ConfigSheriff.CoinHarvest and ConfigSheriff.CoinHarvest.job) or 'sheriff'
    if xPlayer.job.name ~= allowedJob then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sheriff Station',
            description = 'Only Sheriff personnel can harvest Sheriff Coins!',
            type = 'error'
        })
        return false
    end

    local harvestCfg = ConfigSheriff.CoinHarvest
    if not harvestCfg or not harvestCfg.locations then
        return false
    end

    local spot = harvestCfg.locations[spotIndex]
    if not spot then
        return false
    end

    -- Distance check (anti-exploit)
    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    local targetCoords = vector3(spot.x, spot.y, spot.z)
    if #(pCoords - targetCoords) > 4.5 then
        return false
    end

    -- Rate limit
    local now = GetGameTimer()
    if lastHarvest[src] and (now - lastHarvest[src]) < 8500 then
        return false
    end
    lastHarvest[src] = now

    -- Calculate reward (1 to 10 chances)
    local rewardConfig = harvestCfg.reward or {}
    local itemName = rewardConfig.item or 'sheriff_coin'
    local min = rewardConfig.min or 1
    local max = rewardConfig.max or 10
    local amount = math.random(min, max)

    -- Inventory capacity check
    local canCarry = exports.ox_inventory:CanCarryItem(src, itemName, amount)
    if not canCarry then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sheriff Station',
            description = 'Your inventory is full! You cannot carry more Sheriff Coins.',
            type = 'error',
            duration = 4000
        })
        return false
    end

    local success = exports.ox_inventory:AddItem(src, itemName, amount)
    if success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sheriff Station',
            description = ('Harvested %d Sheriff Coin%s!'):format(amount, amount > 1 and 's' or ''),
            type = 'success',
            duration = 3500
        })
        return true
    end

    return false
end)

AddEventHandler('playerDropped', function()
    local src = source
    lastHarvest[src] = nil
end)
