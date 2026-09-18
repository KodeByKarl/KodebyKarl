local Config = require 'configs.newplayerkit'
local Vars = require 'helpers.vars'

if not Config or not Config.Enabled then return end

local claimedCache = {}

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `cfx-keydi-newplayerkit` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`)
        )
    ]])

    Wait(1000)
    local rows = MySQL.query.await('SELECT `identifier` FROM `cfx-keydi-newplayerkit`', {})
    if rows then
        for i = 1, #rows do
            claimedCache[rows[i].identifier] = true
        end
    end
end)

local function Notify(src, message, msgType)
    TriggerClientEvent('esx:Notify', src, Config.NotifyTitle or 'NEW PLAYER KIT', message, msgType or 'info', 7000)
end

RegisterNetEvent('cfx-keydi-utils:newplayerkit:server:claim', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local pedCoords = Config.PedCoords
    if pedCoords then
        local playerCoords = xPlayer.getCoords(true)
        if #(playerCoords - pedCoords) > (Config.DistanceCheck or 5.0) then
            Notify(src, 'You are too far from the New Player Kit NPC.', 'error')
            return
        end
    end

    if Config.OneTime and claimedCache[xPlayer.identifier] then
        Notify(src, 'You have already claimed your New Player Kit.', 'error')
        return
    end

    local rewards = Config.Rewards
    if not rewards or #rewards == 0 then
        Notify(src, 'New Player Kit is not configured.', 'error')
        return
    end

    -- Validate all reward items exist and can be carried
    for i = 1, #rewards do
        local reward = rewards[i]
        local itemData = Vars.ox:Items(reward.item)
        if not itemData then
            print(('[cfx-keydi-utils] New Player Kit missing item definition: %s'):format(reward.item))
            Notify(src, ('Kit item missing: %s'):format(reward.item), 'error')
            return
        end
        if not Vars.ox:CanCarryItem(src, reward.item, reward.amount) then
            Notify(src, ('Not enough space for %sx %s. Free inventory space and try again.'):format(reward.amount, itemData.label or reward.item), 'error')
            return
        end
    end

    if Config.OneTime then
        local id = MySQL.insert.await('INSERT INTO `cfx-keydi-newplayerkit` (identifier) VALUES (?)', { xPlayer.identifier })
        if not id then
            Notify(src, 'Unable to claim kit right now. Try again.', 'error')
            return
        end
        claimedCache[xPlayer.identifier] = true
    end

    local given = 0
    for i = 1, #rewards do
        local reward = rewards[i]
        local success = Vars.ox:AddItem(src, reward.item, reward.amount)
        if success then
            given += 1
        else
            print(('[cfx-keydi-utils] Failed to give %sx %s to %s'):format(reward.amount, reward.item, xPlayer.identifier))
        end
    end

    if given == 0 then
        Notify(src, 'Failed to give New Player Kit items.', 'error')
        return
    end

    Notify(src, ('New Player Kit claimed! Received %s/%s rewards.'):format(given, #rewards), 'success')
end)
