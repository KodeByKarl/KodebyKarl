local ESX = exports['es_extended']:getSharedObject()
local lastHarvest = {}

lib.callback.register('kodebykarl-police:server:harvestCoins', function(source, spotIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then
        return false
    end

    -- Job check: only configured job (police) can harvest
    local allowedJob = (Config.CoinHarvest and Config.CoinHarvest.job) or 'police'
    if xPlayer.job.name ~= allowedJob then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Police Armory',
            description = 'Only Police Officers have access to harvest police coins!',
            type = 'error'
        })
        return false
    end

    -- Spot verification
    if not Config.CoinHarvest or not Config.CoinHarvest.locations then
        return false
    end

    local spot = Config.CoinHarvest.locations[spotIndex]
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

    -- Rate limit: minimum 8.5 seconds between harvests
    local now = GetGameTimer()
    if lastHarvest[src] and (now - lastHarvest[src]) < 8500 then
        return false
    end
    lastHarvest[src] = now

    -- Calculate reward
    local rewardConfig = Config.CoinHarvest.reward or {}
    local itemName = rewardConfig.item or 'grimpolicecoin'
    local min = rewardConfig.min or 1
    local max = rewardConfig.max or 10
    local amount = math.random(min, max)

    -- Inventory capacity check
    local canCarry = exports.ox_inventory:CanCarryItem(src, itemName, amount)
    if not canCarry then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Police Armory',
            description = 'Your inventory is full! You cannot carry more Grim Police Coins.',
            type = 'error',
            duration = 4000
        })
        return false
    end

    -- Award coins
    local success = exports.ox_inventory:AddItem(src, itemName, amount)
    if success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Police Armory',
            description = ('Harvested %d Grim Police Coin%s!'):format(amount, amount > 1 and 's' or ''),
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
