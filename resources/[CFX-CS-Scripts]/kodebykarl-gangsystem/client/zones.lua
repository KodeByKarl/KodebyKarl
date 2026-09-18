--[[
    Gang HQ Press-E TextUI (uses keyed ox_lib TextUI id so other scripts cannot wipe it).
]]

local InteractDistance = 2.0
local ExitDistance = 2.75 -- hysteresis: leave farther than enter
local DrawDistance = 12.0
local TEXT_ID = 'kodebykarl-gangsystem'
local points = {}
local activeId = nil
local textVisible = false

local function stashId(gangName, kind)
    if kind == 'share' then
        return ('gang_%s_share'):format(gangName)
    elseif kind == 'boss' then
        return ('gang_%s_boss'):format(gangName)
    end
    return ('gang_%s_%s'):format(gangName, kind)
end

local function openStash(gangName, kind)
    if not Gang.IsInGang(gangName) then
        return Gang.Notify('GANG', 'You are not a member of this gang.', 'error')
    end
    if kind == 'boss' and not Gang.IsBoss(gangName) then
        return Gang.Notify('GANG', 'Boss stash is for bosses only.', 'error')
    end

    if kind == 'private' then
        local id = lib.callback.await('kodebykarl-gangsystem:getPrivateStashId', false, gangName)
        if not id then
            return Gang.Notify('GANG', 'Unable to open private stash.', 'error')
        end
        exports.ox_inventory:openInventory('stash', id)
        return
    end

    exports.ox_inventory:openInventory('stash', stashId(gangName, kind))
end

local function openClothing(gangName)
    if not Gang.IsInGang(gangName) then
        return Gang.Notify('GANG', 'You are not a member of this gang.', 'error')
    end
    if GetResourceState('illenium-appearance') == 'started' then
        TriggerEvent('illenium-appearance:client:openOutfitMenu')
        return
    end
    Gang.Notify('GANG', 'Clothing menu is unavailable.', 'error')
end

local function openGunCrafting(gangName, locationId)
    if not Gang.IsInGang(gangName) then
        return Gang.Notify('GANG', 'You are not a member of this gang.', 'error')
    end
    TriggerEvent('kodebykarl-gangsystem:client:openGunCraft', gangName, locationId)
end

local function setupBlip(gangName, cfg)
    if not cfg.blip or not cfg.blip.enabled then return end
    local loc = cfg.locations and (cfg.locations.pressE or cfg.locations.shareStash)
    if not loc then return end

    local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(blip, cfg.blip.sprite or 84)
    SetBlipColour(blip, cfg.blip.colour or 21)
    SetBlipScale(blip, cfg.blip.scale or 0.5)
    SetBlipAsShortRange(blip, true)
    SetBlipDisplay(blip, 4)
    SetBlipHighDetail(blip, true)
    SetBlipCategory(blip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(cfg.blip.label or cfg.label)
    EndTextCommandSetBlipName(blip)
end

local function hideText()
    if textVisible then
        lib.hideTextUI(TEXT_ID)
        textVisible = false
    end
    activeId = nil
end

local function showText(pointId, label, icon)
    local text = ('[E] %s'):format(label)
    -- Always refresh keyed entry; ox_lib stack won't get wiped by other hideTextUI()
    lib.showTextUI(text, {
        id = TEXT_ID,
        icon = icon or 'hand',
        position = 'right-center',
    })
    activeId = pointId
    textVisible = true
end

local function registerPoint(opts)
    points[#points + 1] = {
        id = opts.id,
        coords = vector3(opts.coords.x, opts.coords.y, opts.coords.z),
        label = opts.label,
        icon = opts.icon,
        color = opts.color or { r = 139, g = 90, b = 43 },
        canUse = opts.canUse,
        onSelect = opts.onSelect,
    }
end

local function setupGangZones(gangName, cfg)
    local loc = cfg.locations
    if not loc then return end
    local color = cfg.color or { r = 139, g = 90, b = 43 }

    local function memberOnly()
        return Gang.IsInGang(gangName)
    end

    local function bossOnly()
        return Gang.IsBoss(gangName)
    end

    if loc.bossStash then
        registerPoint({
            id = ('gang_%s_boss_stash'):format(gangName),
            coords = loc.bossStash,
            label = 'Boss Stash',
            icon = 'lock',
            color = color,
            canUse = bossOnly,
            onSelect = function() openStash(gangName, 'boss') end,
        })
    end

    if loc.shareStash then
        registerPoint({
            id = ('gang_%s_share_stash'):format(gangName),
            coords = loc.shareStash,
            label = 'Shared Stash',
            icon = 'box-open',
            color = color,
            canUse = memberOnly,
            onSelect = function() openStash(gangName, 'share') end,
        })
    end

    if loc.privateStash then
        registerPoint({
            id = ('gang_%s_private_stash'):format(gangName),
            coords = loc.privateStash,
            label = 'Private Stash',
            icon = 'box',
            color = color,
            canUse = memberOnly,
            onSelect = function() openStash(gangName, 'private') end,
        })
    end

    if loc.clothing then
        registerPoint({
            id = ('gang_%s_clothing'):format(gangName),
            coords = loc.clothing,
            label = 'Clothing',
            icon = 'shirt',
            color = color,
            canUse = memberOnly,
            onSelect = function() openClothing(gangName) end,
        })
    end

    if loc.gunCrafting then
        registerPoint({
            id = ('gang_%s_guncraft'):format(gangName),
            coords = loc.gunCrafting,
            label = 'Gun Crafting',
            icon = 'gun',
            color = color,
            canUse = memberOnly,
            onSelect = function() openGunCrafting(gangName, ('gang_%s'):format(gangName)) end,
        })
    end
end

local function flatDist(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

CreateThread(function()
    while not ESX or not ESX.IsPlayerLoaded or not ESX.IsPlayerLoaded() do
        Wait(200)
    end

    for gangName, cfg in pairs(Config.Gangs) do
        setupBlip(gangName, cfg)
        setupGangZones(gangName, cfg)
    end

    while true do
        local sleep = 500
        local ped = cache.ped or PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local nearest, nearestDist = nil, 999.0
        local limit = textVisible and ExitDistance or InteractDistance

        for i = 1, #points do
            local pt = points[i]
            local dist = flatDist(pcoords, pt.coords)

            if dist <= DrawDistance then
                sleep = 0
                if pt.canUse and pt.canUse() then
                    local c = pt.color
                    DrawMarker(
                        2,
                        pt.coords.x, pt.coords.y, pt.coords.z + 0.1,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.2, 0.2, 0.2,
                        c.r, c.g, c.b, 160,
                        false, true, 2, false, nil, nil, false
                    )

                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = pt
                    end
                end
            end
        end

        if nearest and nearestDist <= limit then
            showText(nearest.id, nearest.label, nearest.icon)
            if IsControlJustReleased(0, 38) then
                hideText()
                nearest.onSelect()
                Wait(300)
            end
        else
            hideText()
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    hideText()
end)
