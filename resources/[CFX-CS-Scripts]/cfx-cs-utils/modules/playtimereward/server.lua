local Config = require 'configs.playtimereward'

if not Config or not Config.Enabled then return end

local claimedCache = {} -- [identifier][rewardId] = true
local claimBusy = {}

local function cacheKey(identifier, rewardId)
    return ('%s:%s'):format(identifier, rewardId)
end

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `cfx-keydi-playtimereward` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `reward_id` VARCHAR(32) NOT NULL DEFAULT 'sunrise',
            `plate` VARCHAR(12) NOT NULL,
            `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier_reward` (`identifier`, `reward_id`)
        )
    ]])

    -- Older installs only had UNIQUE(identifier). Add reward_id + migrate.
    pcall(function()
        MySQL.query.await('ALTER TABLE `cfx-keydi-playtimereward` ADD COLUMN IF NOT EXISTS `reward_id` VARCHAR(32) NOT NULL DEFAULT \'sunrise\' AFTER `identifier`')
    end)
    pcall(function()
        MySQL.query.await('ALTER TABLE `cfx-keydi-playtimereward` DROP INDEX `identifier`')
    end)
    pcall(function()
        MySQL.query.await('ALTER TABLE `cfx-keydi-playtimereward` ADD UNIQUE KEY `identifier_reward` (`identifier`, `reward_id`)')
    end)
    pcall(function()
        MySQL.update.await('UPDATE `cfx-keydi-playtimereward` SET `reward_id` = ? WHERE `reward_id` IS NULL OR `reward_id` = \'\'', { 'sunrise' })
    end)

    Wait(1000)
    local rows = MySQL.query.await('SELECT `identifier`, `reward_id` FROM `cfx-keydi-playtimereward`', {})
    if rows then
        for i = 1, #rows do
            local rewardId = rows[i].reward_id
            if type(rewardId) ~= 'string' or rewardId == '' then
                rewardId = 'sunrise'
            end
            claimedCache[cacheKey(rows[i].identifier, rewardId)] = true
        end
    end
end)

local function Notify(src, message, msgType)
    TriggerClientEvent('esx:Notify', src, Config.NotifyTitle or 'PLAYTIME REWARD', message, msgType or 'info', 7000)
end

local function formatPlayTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return ('%dd %dh %dm'):format(days, hours, minutes)
    end
    if hours > 0 then
        return ('%dh %dm'):format(hours, minutes)
    end
    return ('%dm'):format(math.max(1, minutes))
end

--- ESX cumulative playtime (lastPlaytime metadata + GetPlayerTimeOnline)
local function getTotalPlaySeconds(xPlayer)
    if not xPlayer or not xPlayer.getPlayTime then return 0 end
    return tonumber(xPlayer.getPlayTime()) or 0
end

local function generatePlate()
    if GetResourceState('jg-dealerships-v2') == 'started' then
        local ok, plate = pcall(function()
            return exports['jg-dealerships-v2']:generatePlate(nil, true)
        end)
        if ok and type(plate) == 'string' and plate ~= '' then
            return plate
        end
    end

    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    for _ = 1, 20 do
        local plate = ''
        for i = 1, 8 do
            local idx = math.random(1, #chars)
            plate = plate .. chars:sub(idx, idx)
        end
        local exists = MySQL.scalar.await('SELECT 1 FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
        if not exists then
            return plate
        end
    end
    return ('PT%06d'):format(math.random(0, 999999))
end

local function getReward(rewardId)
    local rewards = Config.Rewards
    if type(rewards) ~= 'table' then return nil end
    local reward = rewards[rewardId]
    if type(reward) ~= 'table' then return nil end
    return reward
end

local function itemsClaimKey(identifier, rewardId)
    return cacheKey(identifier, rewardId .. '_items')
end

local function markClaimed(identifier, rewardId, plate)
    local key = cacheKey(identifier, rewardId)
    local id = MySQL.insert.await(
        'INSERT INTO `cfx-keydi-playtimereward` (identifier, reward_id, plate) VALUES (?, ?, ?)',
        { identifier, rewardId, plate or '' }
    )
    if id then
        claimedCache[key] = true
        return true
    end
    return false
end

--- Returns ok, errMsg. Checks item defs + carry space before claim.
local function validateRewardItems(src, reward)
    if type(reward.Items) ~= 'table' or #reward.Items == 0 then
        return true
    end
    if GetResourceState('ox_inventory') ~= 'started' then
        return false, 'Inventory is not ready. Try again in a moment.'
    end

    for i = 1, #reward.Items do
        local entry = reward.Items[i]
        if entry and entry.item and (tonumber(entry.amount) or 0) > 0 then
            local amount = tonumber(entry.amount) or 0
            local itemData = exports.ox_inventory:Items(entry.item)
            if not itemData then
                print(('[playtimereward] missing item definition: %s'):format(entry.item))
                return false, ('Reward item missing: %s'):format(entry.item)
            end
            if not exports.ox_inventory:CanCarryItem(src, entry.item, amount) then
                return false, ('Not enough inventory space for %sx %s. Free space and try again.'):format(
                    amount,
                    itemData.label or entry.item
                )
            end
        end
    end
    return true
end

--- Give configured bonus items. Returns givenLabels[], failedCount
local function giveRewardItems(src, reward)
    local givenLabels = {}
    local failed = 0
    if type(reward.Items) ~= 'table' or #reward.Items == 0 then
        return givenLabels, failed
    end
    if GetResourceState('ox_inventory') ~= 'started' then
        return givenLabels, #reward.Items
    end

    for i = 1, #reward.Items do
        local entry = reward.Items[i]
        if entry and entry.item and (tonumber(entry.amount) or 0) > 0 then
            local amount = tonumber(entry.amount) or 0
            local ok, success, err = pcall(function()
                return exports.ox_inventory:AddItem(src, entry.item, amount)
            end)
            -- AddItem returns false on full/invalid without throwing; pcall alone is not enough
            if ok and success then
                local itemData = exports.ox_inventory:Items(entry.item)
                givenLabels[#givenLabels + 1] = itemData and itemData.label or entry.item
            else
                failed += 1
                print(('[playtimereward] AddItem failed src=%s item=%s x%s ok=%s success=%s err=%s'):format(
                    tostring(src),
                    tostring(entry.item),
                    tostring(amount),
                    tostring(ok),
                    tostring(success),
                    tostring(err)
                ))
            end
        end
    end
    return givenLabels, failed
end

--- Players who got the Neon car before items were fixed can reclaim starter items once.
local function tryClaimMissingItems(src, xPlayer, rewardId, reward)
    local vehicleKey = cacheKey(xPlayer.identifier, rewardId)
    local itemsKey = itemsClaimKey(xPlayer.identifier, rewardId)

    if not claimedCache[vehicleKey] then
        return false
    end
    if type(reward.Items) ~= 'table' or #reward.Items == 0 then
        return false
    end
    if claimedCache[itemsKey] then
        Notify(src, ('You have already claimed your free %s.'):format(reward.Label or rewardId), 'error')
        return true
    end

    local ok, errMsg = validateRewardItems(src, reward)
    if not ok then
        Notify(src, errMsg, 'error')
        return true
    end

    claimBusy[src] = true
    local givenLabels, failed = giveRewardItems(src, reward)
    claimBusy[src] = nil

    if #givenLabels == 0 then
        Notify(src, 'Could not give starter pack items. Free inventory space and try again.', 'error')
        return true
    end

    markClaimed(xPlayer.identifier, rewardId .. '_items', 'ITEMS')
    claimedCache[itemsKey] = true

    Notify(src, ('Starter pack received: %s.%s'):format(
        table.concat(givenLabels, ', '),
        failed > 0 and ' Some items failed — free space and claim again.' or ''
    ), failed > 0 and 'error' or 'success')
    print(('[playtimereward] %s [%s] received missing items for %s'):format(
        xPlayer.name,
        xPlayer.identifier,
        rewardId
    ))
    return true
end

local function claimReward(src, rewardId)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if claimBusy[src] then return end

    local reward = getReward(rewardId)
    if not reward then
        Notify(src, 'Invalid playtime reward.', 'error')
        return
    end

    local pedCoords = Config.PedCoords
    if pedCoords then
        local playerCoords = xPlayer.getCoords(true)
        if #(playerCoords - pedCoords) > (Config.DistanceCheck or 5.0) then
            Notify(src, 'You are too far from the playtime reward NPC.', 'error')
            return
        end
    end

    local key = cacheKey(xPlayer.identifier, rewardId)
    if reward.OneTime ~= false and claimedCache[key] then
        -- Neon already claimed without starter items → allow one-time item top-up
        if tryClaimMissingItems(src, xPlayer, rewardId, reward) then
            return
        end
        Notify(src, ('You have already claimed your free %s.'):format(reward.Label or rewardId), 'error')
        return
    end

    local playSeconds = getTotalPlaySeconds(xPlayer)
    local required = tonumber(reward.RequiredSeconds) or 0
    if playSeconds < required then
        local left = required - playSeconds
        Notify(src, ('Need %s total playtime for %s. You have %s (%s left).'):format(
            formatPlayTime(required),
            reward.Label or rewardId,
            formatPlayTime(playSeconds),
            formatPlayTime(left)
        ), 'error')
        return
    end

    -- Block claim early if starter pack won't fit (avoids car without items)
    local itemsOk, itemsErr = validateRewardItems(src, reward)
    if not itemsOk then
        Notify(src, itemsErr, 'error')
        return
    end

    claimBusy[src] = true

    local plate = generatePlate()
    local model = reward.VehicleModel or 'neon'
    local garageId = reward.GarageId or 'Legion Square'
    local nick = ('%s-%s'):format(reward.NicknamePrefix or ('REWARD-' .. rewardId:upper()), plate:upper())
    local vehicleJson = json.encode({ model = joaat(model), plate = plate })

    local inserted = false
    local lastErr

    local attempts = {
        {
            [[
                INSERT INTO owned_vehicles
                    (`owner`, `plate`, `vehicle`, `stored`, `in_garage`, `garage_id`, `nickname`, `fuel`, `engine`, `body`)
                VALUES (?, ?, ?, 1, 1, ?, ?, 100, 1000, 1000)
            ]],
            { xPlayer.identifier, plate, vehicleJson, garageId, nick },
        },
        {
            'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`, `in_garage`, `garage_id`, `nickname`) VALUES (?, ?, ?, 1, 1, ?, ?)',
            { xPlayer.identifier, plate, vehicleJson, garageId, nick },
        },
        {
            'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`, `nickname`) VALUES (?, ?, ?, 1, ?)',
            { xPlayer.identifier, plate, vehicleJson, nick },
        },
        {
            'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`) VALUES (?, ?, ?, 1)',
            { xPlayer.identifier, plate, vehicleJson },
        },
    }

    for i = 1, #attempts do
        local ok, err = pcall(function()
            MySQL.insert.await(attempts[i][1], attempts[i][2])
        end)
        if ok then
            inserted = true
            break
        end
        lastErr = err
    end

    if not inserted then
        claimBusy[src] = nil
        print(('[playtimereward] insert failed for %s (%s / %s): %s'):format(
            tostring(xPlayer.identifier),
            tostring(model),
            tostring(plate),
            tostring(lastErr)
        ))
        Notify(src, 'Failed to add vehicle to your garage. Try again.', 'error')
        return
    end

    if reward.OneTime ~= false then
        markClaimed(xPlayer.identifier, rewardId, plate)
    end

    -- Starter pack items (stash_car + food_drinks_box for neon)
    local itemNote = ''
    if type(reward.Items) == 'table' and #reward.Items > 0 then
        local givenLabels, failed = giveRewardItems(src, reward)
        if #givenLabels > 0 then
            itemNote = (' Also received: %s.'):format(table.concat(givenLabels, ', '))
            markClaimed(xPlayer.identifier, rewardId .. '_items', plate)
            claimedCache[itemsClaimKey(xPlayer.identifier, rewardId)] = true
        end
        if failed > 0 or #givenLabels == 0 then
            itemNote = itemNote .. ' Starter items failed — free inventory space and claim again at the NPC.'
            print(('[playtimereward] item grant incomplete for %s reward=%s given=%s failed=%s'):format(
                tostring(xPlayer.identifier),
                rewardId,
                tostring(#givenLabels),
                tostring(failed)
            ))
        end
    end

    claimBusy[src] = nil

    pcall(function()
        if GetResourceState('kodebykarl-ui') == 'started' then
            exports['kodebykarl-ui']:GiveKey(src, plate)
        end
    end)

    Notify(src, ('Free %s claimed! Plate %s — pick it up at %s garage.%s'):format(
        reward.Label or rewardId,
        plate:upper(),
        garageId,
        itemNote
    ), 'success')
    print(('[playtimereward] %s [%s] claimed %s (%s) plate %s (%s playtime)'):format(
        xPlayer.name,
        xPlayer.identifier,
        rewardId,
        model,
        plate,
        formatPlayTime(playSeconds)
    ))
end

RegisterNetEvent('cfx-keydi-utils:playtimereward:server:claim', function(rewardId)
    local src = source
    -- Back-compat: old ped/client with no arg claimed sunrise
    if type(rewardId) ~= 'string' or rewardId == '' then
        rewardId = 'sunrise'
    end
    claimReward(src, rewardId:lower())
end)
