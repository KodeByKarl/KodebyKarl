--[[
    cfx-keydi-market — server (sell grind items + editable ranges in DB)
]]

if ConfigMarket and ConfigMarket.Enabled == false then return end

local ESX = exports['es_extended']:getSharedObject()
local ox_inventory = exports.ox_inventory

local basePrices = {} ---@type table<string, { min: number, max: number }>
local priceLookup = {} ---@type table<string, number>
local itemMeta = {} ---@type table<string, { label: string, category: string, enabled: boolean, sort: number }>
local catalogOrder = {} ---@type string[]

local sellCooldown = {}

local intervalMinutes = tonumber((ConfigMarket.PriceUpdate or {}).IntervalMinutes) or 120
if intervalMinutes < 1 then intervalMinutes = 1 end
local intervalSeconds = math.floor(intervalMinutes * 60)
local lastUpdateAt = os.time()
local nextUpdateAt = lastUpdateAt + intervalSeconds

local function isOwnerDev(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local groups = (ConfigIpad and ConfigIpad.EconomyGroups)
        or (ConfigMarket.AdminGroups)
        or { owner = true, developer = true }
    return groups[group] == true
end

local function stampUpdate()
    lastUpdateAt = os.time()
    nextUpdateAt = lastUpdateAt + intervalSeconds
end

local function copyPrices()
    local out = {}
    for item, price in pairs(priceLookup) do
        out[item] = price
    end
    return out
end

local function applyRange(item, minP, maxP, label, category, enabled, sortOrder)
    minP = math.floor(tonumber(minP) or 1)
    maxP = math.floor(tonumber(maxP) or minP)
    if maxP < minP then
        minP, maxP = maxP, minP
    end
    minP = math.max(1, minP)
    maxP = math.max(minP, maxP)

    basePrices[item] = { min = minP, max = maxP }
    itemMeta[item] = {
        label = label or item,
        category = category or 'General',
        enabled = enabled ~= false and enabled ~= 0,
        sort = tonumber(sortOrder) or 0,
    }

    local cur = priceLookup[item]
    if not cur then
        priceLookup[item] = math.floor((minP + maxP) / 2)
    elseif cur < minP then
        priceLookup[item] = minP
    elseif cur > maxP then
        priceLookup[item] = maxP
    end
end

local function rebuildOrder()
    catalogOrder = {}
    for item in pairs(basePrices) do
        catalogOrder[#catalogOrder + 1] = item
    end
    table.sort(catalogOrder, function(a, b)
        local ma, mb = itemMeta[a], itemMeta[b]
        local sa = ma and ma.sort or 0
        local sb = mb and mb.sort or 0
        if sa ~= sb then return sa < sb end
        return a < b
    end)
end

local function EnsureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_market_items` (
            `item` VARCHAR(64) NOT NULL,
            `label` VARCHAR(96) NOT NULL DEFAULT '',
            `category` VARCHAR(64) NOT NULL DEFAULT 'General',
            `min_price` INT NOT NULL DEFAULT 1,
            `max_price` INT NOT NULL DEFAULT 1,
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `sort_order` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`item`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function SeedFromConfig()
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM grim_market_items') or 0
    if tonumber(count) > 0 then return end

    for i, entry in ipairs(ConfigMarket.Items or {}) do
        local minP = math.floor(tonumber(entry.minPrice) or tonumber(entry.price) or 1)
        local maxP = math.floor(tonumber(entry.maxPrice) or minP)
        if maxP < minP then minP, maxP = maxP, minP end
        MySQL.insert.await(
            [[INSERT INTO grim_market_items (item, label, category, min_price, max_price, enabled, sort_order)
              VALUES (?, ?, ?, ?, ?, 1, ?)]],
            {
                entry.item,
                entry.label or entry.item,
                entry.category or 'General',
                math.max(1, minP),
                math.max(minP, maxP),
                i,
            }
        )
    end
end

local function LoadFromDb()
    basePrices = {}
    itemMeta = {}
    local keepPrices = priceLookup
    priceLookup = {}

    local rows = MySQL.query.await(
        'SELECT item, label, category, min_price, max_price, enabled, sort_order FROM grim_market_items ORDER BY sort_order ASC, item ASC'
    ) or {}

    if #rows < 1 then
        -- Fallback to config if DB empty somehow
        for i, entry in ipairs(ConfigMarket.Items or {}) do
            applyRange(
                entry.item,
                entry.minPrice or entry.price,
                entry.maxPrice or entry.minPrice or entry.price,
                entry.label,
                entry.category,
                true,
                i
            )
            if keepPrices[entry.item] then
                priceLookup[entry.item] = keepPrices[entry.item]
            end
        end
    else
        for i = 1, #rows do
            local row = rows[i]
            applyRange(
                row.item,
                row.min_price,
                row.max_price,
                row.label,
                row.category,
                row.enabled,
                row.sort_order or i
            )
            if keepPrices[row.item] then
                local range = basePrices[row.item]
                local p = keepPrices[row.item]
                if p < range.min then p = range.min end
                if p > range.max then p = range.max end
                priceLookup[row.item] = p
            end
        end
    end

    rebuildOrder()
end

local function buildCatalog(includeDisabled)
    local items = {}
    for i = 1, #catalogOrder do
        local item = catalogOrder[i]
        local range = basePrices[item]
        local meta = itemMeta[item]
        if range and meta and (includeDisabled or meta.enabled) then
            items[#items + 1] = {
                item = item,
                label = meta.label,
                category = meta.category,
                price = priceLookup[item] or range.min,
                minPrice = range.min,
                maxPrice = range.max,
                enabled = meta.enabled,
            }
        end
    end
    return {
        items = items,
        lastUpdateAt = lastUpdateAt,
        nextUpdateAt = nextUpdateAt,
        intervalMinutes = intervalMinutes,
    }
end

local function randomizePrices()
    for item, range in pairs(basePrices) do
        local meta = itemMeta[item]
        if meta and meta.enabled then
            priceLookup[item] = math.random(range.min, range.max)
        end
    end
end

local function broadcastPrices(announce)
    TriggerClientEvent('cfx-keydi-market:client:pricesUpdated', -1, copyPrices(), announce == true)
end

lib.callback.register('cfx-keydi-market:server:getPrices', function()
    return copyPrices()
end)

lib.callback.register('cfx-keydi-market:server:getCatalog', function()
    return buildCatalog(false)
end)

lib.callback.register('cfx-keydi-market:server:adminGet', function(source)
    if not isOwnerDev(source) then
        return { ok = false, error = 'denied', items = {} }
    end
    local catalog = buildCatalog(true)
    catalog.ok = true
    return catalog
end)

lib.callback.register('cfx-keydi-market:server:adminSetRange', function(source, payload)
    if not isOwnerDev(source) then
        return { ok = false, error = 'denied' }
    end
    payload = type(payload) == 'table' and payload or {}
    local item = type(payload.item) == 'string' and payload.item or nil
    if not item or not basePrices[item] then
        return { ok = false, error = 'invalid_item' }
    end

    local minP = math.floor(tonumber(payload.minPrice) or basePrices[item].min)
    local maxP = math.floor(tonumber(payload.maxPrice) or basePrices[item].max)
    if maxP < minP then minP, maxP = maxP, minP end
    minP = math.max(1, minP)
    maxP = math.max(minP, maxP)

    local meta = itemMeta[item] or {}
    local enabled = payload.enabled
    if enabled == nil then
        enabled = meta.enabled ~= false
    else
        enabled = enabled and true or false
    end

    MySQL.update.await(
        [[UPDATE grim_market_items
          SET min_price = ?, max_price = ?, enabled = ?, label = COALESCE(NULLIF(?, ''), label), category = COALESCE(NULLIF(?, ''), category)
          WHERE item = ?]],
        {
            minP,
            maxP,
            enabled and 1 or 0,
            type(payload.label) == 'string' and payload.label or '',
            type(payload.category) == 'string' and payload.category or '',
            item,
        }
    )

    applyRange(item, minP, maxP, meta.label, meta.category, enabled, meta.sort)
    itemMeta[item].enabled = enabled
    if type(payload.label) == 'string' and payload.label ~= '' then
        itemMeta[item].label = payload.label
    end
    if type(payload.category) == 'string' and payload.category ~= '' then
        itemMeta[item].category = payload.category
    end

    -- Optional: set live price immediately
    if payload.price ~= nil then
        local live = math.floor(tonumber(payload.price) or priceLookup[item])
        if live < minP then live = minP end
        if live > maxP then live = maxP end
        priceLookup[item] = live
        broadcastPrices(false)
    end

    return {
        ok = true,
        item = {
            item = item,
            label = itemMeta[item].label,
            category = itemMeta[item].category,
            minPrice = minP,
            maxPrice = maxP,
            price = priceLookup[item],
            enabled = itemMeta[item].enabled,
        },
    }
end)

lib.callback.register('cfx-keydi-market:server:adminReroll', function(source)
    if not isOwnerDev(source) then
        return { ok = false, error = 'denied' }
    end
    randomizePrices()
    stampUpdate()
    broadcastPrices(true)
    local catalog = buildCatalog(true)
    catalog.ok = true
    return catalog
end)

RegisterNetEvent('cfx-keydi-market:server:sell', function(payload)
    local src = source
    if type(src) ~= 'number' or src < 1 then return end
    if type(payload) ~= 'table' or type(payload.cart) ~= 'table' then return end

    local now = GetGameTimer()
    if sellCooldown[src] and (now - sellCooldown[src]) < 1500 then
        return
    end
    sellCooldown[src] = now

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pos = GetEntityCoords(ped)
    local nearMarket = false
    for i = 1, #(ConfigMarket.Locations or {}) do
        local c = ConfigMarket.Locations[i].coords
        if c and #(pos - vector3(c.x, c.y, c.z)) <= 8.0 then
            nearMarket = true
            break
        end
    end
    if not nearMarket then
        KeydiElectron.Flag(src, "Market sell exploit (not at NPC)", "cfx-keydi-market")
        TriggerClientEvent('cfx-keydi-market:client:notify', src, 'You must be at the sell market.', 'error')
        return
    end

    local payout = payload.payout == 'bank' and 'bank' or 'cash'
    local total = 0
    local toRemove = {}

    for i = 1, #payload.cart do
        local row = payload.cart[i]
        if type(row) == 'table' then
            local itemName = row.item
            local amount = math.floor(tonumber(row.amount) or 0)
            local unitPrice = priceLookup[itemName]
            local meta = itemMeta[itemName]

            if itemName and amount > 0 and unitPrice and unitPrice > 0 and meta and meta.enabled then
                local have = ox_inventory:Search(src, 'count', itemName) or 0
                if have < amount then
                    TriggerClientEvent('cfx-keydi-market:client:notify', src, ('Not enough %s.'):format(itemName), 'error')
                    return
                end
                toRemove[#toRemove + 1] = { item = itemName, amount = amount, price = unitPrice }
                total = total + (unitPrice * amount)
            end
        end
    end

    if #toRemove < 1 or total < 1 then
        TriggerClientEvent('cfx-keydi-market:client:notify', src, 'Nothing to sell.', 'error')
        return
    end

    for i = 1, #toRemove do
        local row = toRemove[i]
        local removed = ox_inventory:RemoveItem(src, row.item, row.amount)
        if not removed then
            TriggerClientEvent('cfx-keydi-market:client:notify', src, 'Failed to remove items.', 'error')
            return
        end
    end

    if payout == 'bank' then
        xPlayer.addAccountMoney('bank', total)
    else
        xPlayer.addMoney(total)
    end

    TriggerClientEvent('cfx-keydi-market:client:sold', src, total, payout)
end)

AddEventHandler('playerDropped', function()
    sellCooldown[source] = nil
end)

CreateThread(function()
    EnsureTable()
    SeedFromConfig()
    LoadFromDb()

    local cfg = ConfigMarket.PriceUpdate or {}
    local interval = intervalSeconds * 1000

    math.randomseed(os.time() + GetGameTimer())
    randomizePrices()
    stampUpdate()
    broadcastPrices(false)

    while true do
        Wait(interval)
        randomizePrices()
        stampUpdate()
        broadcastPrices(cfg.Announce ~= false)

        if ConfigMarket.Debug then
            print(('^3[cfx-keydi-market]^0 prices updated (next in %sm)'):format(intervalMinutes))
        end
    end
end)
