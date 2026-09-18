--[[
    cfx-keydi-market — client (sell grind items)
]]

if ConfigMarket and ConfigMarket.Enabled == false then return end

local ESX = exports['es_extended']:getSharedObject()
local ox_inventory = exports.ox_inventory

local isOpen = false
local livePrices = {}

local function Notify(msg, nType)
    ESX.ShowNotification(msg, nType or 'info')
end

local function SyncBasePrices()
    for _, entry in ipairs(ConfigMarket.Items or {}) do
        if livePrices[entry.item] == nil then
            local minP = tonumber(entry.minPrice) or tonumber(entry.price) or 0
            local maxP = tonumber(entry.maxPrice) or minP
            livePrices[entry.item] = math.floor((minP + maxP) / 2)
        end
    end
end

SyncBasePrices()

local function BuildListing()
    local listing = {}
    for _, entry in ipairs(ConfigMarket.Items or {}) do
        local count = ox_inventory:Search('count', entry.item) or 0
        local oxItem = ox_inventory:Items(entry.item)
        local minP = tonumber(entry.minPrice) or tonumber(entry.price) or 0
        local maxP = tonumber(entry.maxPrice) or minP
        local fallback = math.floor((minP + maxP) / 2)
        listing[#listing + 1] = {
            item = entry.item,
            label = (oxItem and oxItem.label) or entry.label or entry.item,
            category = entry.category or 'General',
            price = livePrices[entry.item] or fallback,
            count = count,
            image = ('nui://ox_inventory/web/images/%s.png'):format(entry.item),
        }
    end
    return listing
end

local function CloseMarket()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'cfx-keydi-market:hide' })
end

local function OpenMarket()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'cfx-keydi-market:show',
        data = {
            items = BuildListing(),
        },
    })
end

RegisterNUICallback('cfx-keydi-market:close', function(_, cb)
    cb('ok')
    CloseMarket()
end)

RegisterNUICallback('cfx-keydi-market:refresh', function(_, cb)
    cb({ items = BuildListing() })
end)

RegisterNUICallback('cfx-keydi-market:sell', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' or type(data.cart) ~= 'table' or #data.cart < 1 then
        return
    end

    TriggerServerEvent('cfx-keydi-market:server:sell', {
        cart = data.cart,
        payout = data.payout or 'cash', -- cash | bank
    })
end)

RegisterNetEvent('cfx-keydi-market:client:sold', function(total, payout)
    Notify(('Sold items for $%s (%s)'):format(ESX.Math.GroupDigits(total or 0), payout == 'bank' and 'bank' or 'cash'), 'success')
    if isOpen then
        SendNUIMessage({
            action = 'cfx-keydi-market:update',
            data = { items = BuildListing() },
        })
    end
end)

RegisterNetEvent('cfx-keydi-market:client:notify', function(msg, nType)
    Notify(msg, nType)
end)

RegisterNetEvent('cfx-keydi-market:client:pricesUpdated', function(prices, announce)
    if type(prices) == 'table' then
        livePrices = prices
        SyncBasePrices()
    end

    if announce then
        local cfg = ConfigMarket.PriceUpdate or {}
        local msg = cfg.AnnounceMessage or 'Sell Market prices have been updated!'
        local sender = cfg.AnnounceSender or 'Sell Market'

        SendNUIMessage({
            action = 'cfx-keydi-admin:announcementReceived',
            message = msg,
            sender = sender,
        })
    end

    if isOpen then
        SendNUIMessage({
            action = 'cfx-keydi-market:update',
            data = { items = BuildListing() },
        })
    end
end)

CreateThread(function()
    Wait(1500)
    local prices = lib.callback.await('cfx-keydi-market:server:getPrices', false)
    if type(prices) == 'table' then
        livePrices = prices
        SyncBasePrices()
    end
end)

if ConfigMarket.OpenCommand and type(ConfigMarket.OpenCommand) == 'string' and ConfigMarket.OpenCommand ~= '' then
    RegisterCommand(ConfigMarket.OpenCommand, function()
        OpenMarket()
    end, false)
end

RegisterNetEvent('cfx-keydi-market:client:open', function()
    OpenMarket()
end)

exports('OpenSellMarket', OpenMarket)
exports('OpenMarket', OpenMarket)

local marketBlips = {}

local function ClearMarketBlips()
    for _, blip in ipairs(marketBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    marketBlips = {}
end

local function CreateMarketBlips()
    ClearMarketBlips()
    -- If cfx-cs-utils is started, its ped system (configs/peds.lua) manages the Market ped and blip.
    -- If cfx-cs-utils is not running, create the blips directly from ConfigMarket.Locations.
    if GetResourceState('cfx-cs-utils') == 'started' then
        return
    end

    for _, loc in ipairs(ConfigMarket.Locations or {}) do
        local b = loc.blip
        if b and loc.coords then
            local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, b.sprite or 78)
            SetBlipColour(blip, b.color or 2)
            SetBlipScale(blip, b.scale or 0.8)
            SetBlipAsShortRange(blip, b.shortRange ~= false)
            SetBlipDisplay(blip, b.display or 4)
            SetBlipHighDetail(blip, true)
            SetBlipCategory(blip, b.category or 1)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(b.label or "Market")
            EndTextCommandSetBlipName(blip)

            marketBlips[#marketBlips + 1] = blip
        end
    end
end

CreateThread(function()
    CreateMarketBlips()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CloseMarket()
    ClearMarketBlips()
end)
