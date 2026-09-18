--[[
    cfx-keydi-market — lb-phone app (Grim Market, prices only)
]]

if ConfigMarket and ConfigMarket.Enabled == false then return end

local phoneCfg = ConfigMarket.PhoneApp or {}
if phoneCfg.Enabled == false then return end

local ox_inventory = exports.ox_inventory
local APP_ID = phoneCfg.Identifier or 'grim-market'

local function decorateCatalog(catalog)
    if type(catalog) ~= 'table' then
        return { items = {} }
    end

    for _, row in ipairs(catalog.items or {}) do
        local oxItem = ox_inventory:Items(row.item)
        if oxItem and oxItem.label then
            row.label = oxItem.label
        end
        row.image = ('nui://ox_inventory/web/images/%s.png'):format(row.item)
        row.minPrice = nil
        row.maxPrice = nil
    end

    return catalog
end

local function fetchCatalog()
    local catalog = lib.callback.await('cfx-keydi-market:server:getCatalog', false)
    return decorateCatalog(catalog)
end

local function pushPhoneCatalog()
    if GetResourceState('lb-phone') ~= 'started' then return end
    pcall(function()
        exports['lb-phone']:SendCustomAppMessage(APP_ID, {
            type = 'pricesUpdated',
            catalog = fetchCatalog(),
        })
    end)
end

local function addApp()
    if GetResourceState('lb-phone') ~= 'started' then return end

    local resource = GetCurrentResourceName()
    local payload = {
        identifier = APP_ID,
        name = phoneCfg.Name or 'Grim Market',
        description = phoneCfg.Description or 'Live sell prices for autofarm & raven loot',
        developer = phoneCfg.Developer or 'Grim City',
        defaultApp = phoneCfg.DefaultApp ~= false,
        size = 18432,
        ui = resource .. '/Module/cfx-keydi-market/phone/index.html',
        icon = ('https://cfx-nui-%s/Module/cfx-keydi-market/phone/icon.png'):format(resource),
        fixBlur = true,
    }

    local added, err = exports['lb-phone']:AddCustomApp(payload)
    if not added and err == 'App already exists' then
        added = true
    elseif not added then
        pcall(function()
            exports['lb-phone']:RemoveCustomApp(APP_ID)
        end)
        added, err = exports['lb-phone']:AddCustomApp(payload)
    end

    if not added and ConfigMarket.Debug then
        print(('^3[cfx-keydi-market]^0 could not add phone app: %s'):format(err or 'unknown'))
    end
end

RegisterNUICallback('grim-market:getCatalog', function(_, cb)
    cb(fetchCatalog())
end)

-- Legacy alias (old Pandora id)
RegisterNUICallback('pandora-market:getCatalog', function(_, cb)
    cb(fetchCatalog())
end)

RegisterNetEvent('cfx-keydi-market:client:pricesUpdated', function()
    pushPhoneCatalog()
end)

CreateThread(function()
    while GetResourceState('lb-phone') ~= 'started' do
        Wait(500)
    end
    Wait(500)
    pcall(function()
        exports['lb-phone']:RemoveCustomApp('pandora-market')
    end)
    addApp()
    Wait(2000)
    addApp()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'lb-phone' then
        Wait(500)
        addApp()
    end
end)
