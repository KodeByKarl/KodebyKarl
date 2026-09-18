local ESX = exports['es_extended']:getSharedObject()

local sessions = {} -- [src] = { identifier, name, coins, total_earned, progress, dirty }
local itemStock = {} -- [productId] = remaining (nil key = unlimited)

local INTERVAL = math.floor((ConfigPlaytimeShop.RewardIntervalMinutes or 35) * 60)
local REWARD = math.floor(ConfigPlaytimeShop.RewardCoins or 3)
local TICK = math.floor(ConfigPlaytimeShop.TickSeconds or 60)

local function InitItemStock()
    itemStock = {}
    local function seed(list)
        for i = 1, #(list or {}) do
            local p = list[i]
            if p.stock ~= nil then
                itemStock[p.id] = math.floor(tonumber(p.stock) or 0)
            end
        end
    end
    seed(ConfigPlaytimeShop.Items)
    seed(ConfigPlaytimeShop.Cars)
end

InitItemStock()

local function EnsureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_playtime_coins` (
            `identifier` VARCHAR(60) NOT NULL,
            `coins` INT NOT NULL DEFAULT 0,
            `total_earned` INT NOT NULL DEFAULT 0,
            `progress_seconds` INT NOT NULL DEFAULT 0,
            `player_name` VARCHAR(80) DEFAULT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`),
            KEY `coins` (`coins`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function Notify(src, msg, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Playtime Shop',
        description = msg,
        type = nType or 'inform',
    })
end

local function LoadRow(identifier, playerName)
    local row = MySQL.single.await(
        'SELECT coins, total_earned, progress_seconds FROM grim_playtime_coins WHERE identifier = ? LIMIT 1',
        { identifier }
    )
    if not row then
        MySQL.insert.await(
            'INSERT INTO grim_playtime_coins (identifier, coins, total_earned, progress_seconds, player_name) VALUES (?, 0, 0, 0, ?)',
            { identifier, playerName }
        )
        return { coins = 0, total_earned = 0, progress = 0 }
    end
    return {
        coins = tonumber(row.coins) or 0,
        total_earned = tonumber(row.total_earned) or 0,
        progress = tonumber(row.progress_seconds) or 0,
    }
end

local function SaveSession(src)
    local s = sessions[src]
    if not s or not s.dirty then return end
    MySQL.update.await(
        'UPDATE grim_playtime_coins SET coins = ?, total_earned = ?, progress_seconds = ?, player_name = ? WHERE identifier = ?',
        { s.coins, s.total_earned, s.progress, s.name, s.identifier }
    )
    s.dirty = false
end

local function GeneratePlate()
    if GetResourceState('jg-dealerships-v2') == 'started' then
        local ok, plate = pcall(function()
            return exports['jg-dealerships-v2']:generatePlate()
        end)
        if ok and plate and plate ~= '' then return tostring(plate):upper() end
    end
    if GetResourceState('jg-dealerships') == 'started' then
        local ok, plate = pcall(function()
            return exports['jg-dealerships']:generatePlate()
        end)
        if ok and plate and plate ~= '' then return tostring(plate):upper() end
    end
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = ''
    for _ = 1, 8 do
        local i = math.random(1, #charset)
        plate = plate .. charset:sub(i, i)
    end
    return plate
end

local function GenerateUniquePlate()
    for _ = 1, 40 do
        local plate = GeneratePlate()
        local exists = MySQL.scalar.await('SELECT 1 FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
        if not exists then return plate end
    end
    return nil
end

--- SERVER ONLY — never called from client trust of item names
local function ResolveShopProjectModel()
    if GetResourceState('kodebykarl-projectcars') == 'started' then
        local ok, model = pcall(function()
            return exports['kodebykarl-projectcars']:PickRandomProjectModel()
        end)
        if ok and type(model) == 'string' and model ~= '' then
            return model
        end
    end
    return ConfigPlaytimeShop.ProjectModel or 'ody18'
end

local function ResolveShopPartItem(itemName, model)
    if itemName == 'vehicle_shell' or itemName == 'car_blueprint' or itemName == 'project_parts_box' then
        return itemName
    end
    if GetResourceState('kodebykarl-projectcars') == 'started' then
        local ok, uniqueName = pcall(function()
            return exports['kodebykarl-projectcars']:ResolvePartItem(itemName, model)
        end)
        if ok and type(uniqueName) == 'string' and uniqueName ~= '' then
            return uniqueName
        end
    end
    return itemName
end

local function IsShopProjectItem(itemName)
    if not itemName then return false end
    local projectItems = ConfigPlaytimeShop.ProjectPartItems
    if projectItems and projectItems[itemName] then
        return true
    end
    if itemName == 'vehicle_shell' or itemName == 'car_blueprint' or itemName == 'project_parts_box' then
        return true
    end
    if GetResourceState('kodebykarl-projectcars') == 'started' then
        local ok, partType = pcall(function()
            return exports['kodebykarl-projectcars']:GetPartTypeFromItem(itemName)
        end)
        if ok and partType then
            return true
        end
    end
    return false
end

local function BuildProjectMetadata(itemName, product, model)
    if product and product.metadata then
        return product.metadata
    end
    if not IsShopProjectItem(itemName) and not (product and IsShopProjectItem(product.item)) then
        return nil
    end
    if itemName == 'project_parts_box' then
        return {
            label = 'Project Parts Box',
            description = 'Unpacks mixed project-car parts. Each part fits one random pack vehicle.',
        }
    end
    model = tostring(model or ResolveShopProjectModel()):lower():gsub('%s+', '')
    if GetResourceState('kodebykarl-projectcars') == 'started' then
        local ok, meta = pcall(function()
            return exports['kodebykarl-projectcars']:BuildPartMetadata(itemName, model)
        end)
        if ok and type(meta) == 'table' then
            return meta
        end
    end
    return { model = model, vehicle = model:upper(), label = itemName }
end

local function GiveItem(src, itemName, amount, metadata)
    amount = math.floor(tonumber(amount) or 1)
    if amount < 1 then return false, 'invalid_amount' end
    local ok = exports.ox_inventory:AddItem(src, itemName, amount, metadata)
    if not ok then return false, 'inventory_full' end
    return true
end

local function GetStock(product)
    if not product or product.stock == nil then return nil end
    local left = itemStock[product.id]
    if left == nil then return math.floor(tonumber(product.stock) or 0) end
    return left
end

local function GiveCar(src, model)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false, 'no_player' end
    model = tostring(model):lower():gsub('%s+', '')
    local plate = GenerateUniquePlate()
    if not plate then return false, 'plate_failed' end

    local garageId = ConfigPlaytimeShop.GarageId or 'Legion Square'
    local props = json.encode({ model = joaat(model), plate = plate })

    local ok = pcall(function()
        MySQL.insert.await([[
            INSERT INTO owned_vehicles
                (`owner`, `plate`, `vehicle`, `stored`, `in_garage`, `garage_id`, `fuel`, `engine`, `body`)
            VALUES (?, ?, ?, 1, 1, ?, 100, 1000, 1000)
        ]], { xPlayer.identifier, plate, props, garageId })
    end)
    if not ok then
        MySQL.insert.await(
            'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`) VALUES (?, ?, ?, ?)',
            { xPlayer.identifier, plate, props, true }
        )
    end

    pcall(function()
        exports['kodebykarl-ui']:GiveKey(src, plate)
    end)

    return true, plate
end

local function FindProduct(category, productId)
    local list = category == 'cars' and ConfigPlaytimeShop.Cars or ConfigPlaytimeShop.Items
    for i = 1, #list do
        if list[i].id == productId then
            return list[i]
        end
    end
    return nil
end

local function CatalogForClient()
    local items = {}
    for i = 1, #(ConfigPlaytimeShop.Items or {}) do
        local p = ConfigPlaytimeShop.Items[i]
        local stock = GetStock(p)
        items[#items + 1] = {
            id = p.id,
            label = p.label,
            amount = p.amount or 1,
            price = p.price,
            image = p.image or p.item,
            stock = stock,
            kind = 'item',
        }
    end
    local cars = {}
    for i = 1, #(ConfigPlaytimeShop.Cars or {}) do
        local p = ConfigPlaytimeShop.Cars[i]
        local kind = p.kind or (p.item and 'part' or 'vehicle')
        local stock = GetStock(p)
        cars[#cars + 1] = {
            id = p.id,
            label = p.label,
            amount = p.amount or 1,
            price = p.price,
            image = p.image or p.item or 'car',
            model = p.model,
            stock = stock,
            kind = kind,
        }
    end
    return items, cars
end

local function SecondsLeft(s)
    local left = INTERVAL - (s.progress or 0)
    if left < 0 then left = 0 end
    return left
end

local function BuildOpenPayload(src)
    local s = sessions[src]
    if not s then return nil end
    local items, cars = CatalogForClient()
    return {
        playerName = s.name,
        coins = s.coins,
        totalEarned = s.total_earned,
        nextRewardSeconds = SecondsLeft(s),
        rewardCoins = REWARD,
        rewardMinutes = ConfigPlaytimeShop.RewardIntervalMinutes or 25,
        items = items,
        cars = cars,
        pageSize = ConfigPlaytimeShop.PageSize or 6,
    }
end

local function GetTopEarners(limit)
    limit = math.min(math.floor(tonumber(limit) or ConfigPlaytimeShop.TopLimit or 10), 25)
    local rows = MySQL.query.await(
        'SELECT player_name, coins, total_earned FROM grim_playtime_coins WHERE coins > 0 ORDER BY coins DESC LIMIT ?',
        { limit }
    ) or {}
    local list = {}
    for i = 1, #rows do
        list[#list + 1] = {
            rank = i,
            name = rows[i].player_name or 'Unknown',
            coins = tonumber(rows[i].coins) or 0,
            totalEarned = tonumber(rows[i].total_earned) or 0,
        }
    end
    return list
end

local function StartSession(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local name = xPlayer.getName and xPlayer.getName() or GetPlayerName(src) or 'Player'
    local data = LoadRow(xPlayer.identifier, name)
    sessions[src] = {
        identifier = xPlayer.identifier,
        name = name,
        coins = data.coins,
        total_earned = data.total_earned,
        progress = data.progress,
        dirty = false,
    }
end

local function StopSession(src)
    SaveSession(src)
    sessions[src] = nil
end

local function TickPlayer(src, s, seconds)
    s.progress = (s.progress or 0) + seconds
    local awarded = 0
    while s.progress >= INTERVAL do
        s.progress = s.progress - INTERVAL
        s.coins = s.coins + REWARD
        s.total_earned = s.total_earned + REWARD
        awarded = awarded + REWARD
    end
    if awarded > 0 then
        s.dirty = true
        SaveSession(src)
        Notify(src, ('+%s Grim Coins for playtime'):format(awarded), 'success')
        TriggerClientEvent('cfx-keydi-playtimeshop:coinsUpdated', src, {
            coins = s.coins,
            nextRewardSeconds = SecondsLeft(s),
        })
    else
        s.dirty = true
    end
end

CreateThread(function()
    EnsureTable()
    while true do
        Wait(TICK * 1000)
        for src, s in pairs(sessions) do
            if GetPlayerPed(src) and GetPlayerPed(src) ~= 0 then
                TickPlayer(src, s, TICK)
            end
        end
        -- periodic save of dirty progress
        for src, s in pairs(sessions) do
            if s.dirty then SaveSession(src) end
        end
    end
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    StartSession(playerId)
end)

AddEventHandler('playerDropped', function()
    StopSession(source)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(1000)
    for _, playerId in ipairs(ESX.GetPlayers()) do
        StartSession(tonumber(playerId))
    end
end)

lib.callback.register('cfx-keydi-playtimeshop:open', function(source)
    if not sessions[source] then StartSession(source) end
    return BuildOpenPayload(source)
end)

lib.callback.register('cfx-keydi-playtimeshop:top', function()
    return GetTopEarners(ConfigPlaytimeShop.TopLimit or 10)
end)

lib.callback.register('cfx-keydi-playtimeshop:buy', function(source, data)
    local s = sessions[source]
    if not s then return { ok = false, error = 'no_session' } end

    local category = type(data) == 'table' and data.category or nil
    local productId = type(data) == 'table' and data.id or nil
    if category ~= 'items' and category ~= 'cars' then
        return { ok = false, error = 'invalid_category' }
    end

    local product = FindProduct(category, productId)
    if not product then
        return { ok = false, error = 'invalid_product' }
    end

    local price = math.floor(tonumber(product.price) or 0)
    if price < 1 then return { ok = false, error = 'invalid_price' } end
    if s.coins < price then
        return { ok = false, error = 'insufficient', coins = s.coins }
    end

    local stockLeft = GetStock(product)
    if stockLeft ~= nil and stockLeft < 1 then
        local items, cars = CatalogForClient()
        return { ok = false, error = 'out_of_stock', coins = s.coins, items = items, cars = cars }
    end

    -- Deduct first (atomic enough for single-threaded FiveM)
    s.coins = s.coins - price
    s.dirty = true
    if stockLeft ~= nil then
        itemStock[product.id] = stockLeft - 1
    end

    local isPart = product.item ~= nil and (product.kind == 'part' or product.kind == 'item' or not product.model)
    local ok, err
    local shopVehicleLabel
    if isPart or (category == 'items') then
        local amount = math.floor(tonumber(product.amount) or 1)
        local projectItems = ConfigPlaytimeShop.ProjectPartItems
        local isProjectPart = product.item and projectItems and projectItems[product.item] and not product.metadata
        if isProjectPart then
            local given = 0
            for _ = 1, amount do
                local model = ResolveShopProjectModel()
                local giveName = ResolveShopPartItem(product.item, model)
                local meta = BuildProjectMetadata(giveName, product, model)
                local gOk = GiveItem(source, giveName, 1, meta)
                if not gOk then
                    break
                end
                given = given + 1
                shopVehicleLabel = meta and meta.label or meta and meta.vehicle or shopVehicleLabel
            end
            ok = given > 0
            if given == 0 then
                err = 'inventory_full'
            end
        else
            local meta = BuildProjectMetadata(product.item, product)
            shopVehicleLabel = meta and meta.vehicle
            ok, err = GiveItem(source, product.item, amount, meta)
        end
    else
        ok, err = GiveCar(source, product.model)
    end

    if not ok then
        s.coins = s.coins + price -- refund
        s.dirty = true
        if stockLeft ~= nil then
            itemStock[product.id] = stockLeft
        end
        SaveSession(source)
        return { ok = false, error = err or 'give_failed', coins = s.coins }
    end

    SaveSession(source)
    local boughtAmount = math.floor(tonumber(product.amount) or 1)
    local itemMsg = ('Purchased %sx %s'):format(boughtAmount, product.label)
    if shopVehicleLabel and boughtAmount == 1 then
        itemMsg = ('Purchased %s (%s)'):format(product.label, shopVehicleLabel)
    elseif shopVehicleLabel and boughtAmount > 1 then
        itemMsg = ('Purchased %sx %s — mixed vehicles, check item descriptions'):format(boughtAmount, product.label)
    end
    Notify(
        source,
        (not isPart and category == 'cars')
            and ('Purchased %s — stored in garage (plate %s)'):format(product.label, tostring(err))
            or itemMsg,
        'success'
    )

    local items, cars = CatalogForClient()
    return {
        ok = true,
        coins = s.coins,
        nextRewardSeconds = SecondsLeft(s),
        items = items,
        cars = cars,
    }
end)

-- Staff grant (owner ACE)
RegisterCommand('givegrimcoins', function(src, args)
    if src > 0 and not IsPlayerAceAllowed(src, 'group.owner') and not IsPlayerAceAllowed(src, 'group.developer') then
        return
    end
    local target = tonumber(args[1])
    local amount = math.floor(tonumber(args[2]) or 0)
    if not target or amount < 1 then return end
    if not sessions[target] then StartSession(target) end
    local s = sessions[target]
    if not s then return end
    s.coins = s.coins + amount
    s.dirty = true
    SaveSession(target)
    Notify(target, ('+%s Grim Coins (staff)'):format(amount), 'success')
    if src > 0 then
        Notify(src, ('Gave %s coins to %s'):format(amount, target), 'success')
    else
        print(('[playtimeshop] Gave %s coins to %s'):format(amount, target))
    end
end, true)

function AddPlaytimeCoins(target, amount, reason)
    target = tonumber(target)
    amount = math.floor(tonumber(amount) or 0)
    if not target or amount < 1 then return false end
    if not sessions[target] then StartSession(target) end
    local s = sessions[target]
    if not s then return false end
    s.coins = s.coins + amount
    s.total_earned = (s.total_earned or 0) + amount
    s.dirty = true
    SaveSession(target)
    TriggerClientEvent('cfx-keydi-playtimeshop:coinsUpdated', target, {
        coins = s.coins,
        total_earned = s.total_earned,
        progress = s.progress
    })
    Notify(target, ('+%s Grim Coins (%s)'):format(amount, reason or 'Reward'), 'success')
    return true
end

AddCoins = AddPlaytimeCoins
exports('AddCoins', AddPlaytimeCoins)


