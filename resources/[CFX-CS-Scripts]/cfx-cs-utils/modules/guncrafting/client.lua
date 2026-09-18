--[[
    Gun Crafting Module (Client)
    Spawns workbench props and initializes target zones based on server data.
    Provides ox_lib context menu UI and progress bar animations for crafting firearms.
]]

local Vars = require 'helpers.vars'
local Region = require 'helpers.region'

local busy = false
local Data = nil
local ActiveLocationId = nil
local SpawnedProps = {}

local SECTION_META = {
    weapons = { title = 'Choose a Firearm', icon = 'fa-solid fa-gun', desc = 'AP Pistol, SMG, Assault Rifle (AK)' },
    ammo = { title = 'Craft Ammo', icon = 'fa-solid fa-bullets', desc = 'AP / SMG 9mm and Assault Rifle 7.62' },
}

local function notify(msg, nType)
    ESX.Notify('GUN CRAFTING', msg, nType or 'info', 5000)
end

local function isRecipeForLocation(recipe, locationId)
    if not recipe.locations then return true end
    for i = 1, #recipe.locations do
        if recipe.locations[i] == locationId then
            return true
        end
    end
    return false
end

local function craftItem(recipe)
    if busy then
        return notify('You are already crafting an item.', 'error')
    end
    if not ActiveLocationId then
        return notify('Invalid crafting location.', 'error')
    end

    busy = true
    if Vars.oxTarget then
        Vars.oxTarget:disableTargeting(true)
    end

    -- Play crafting progress bar & animation
    local ok = lib.progressBar({
        duration = recipe.craftTime or 6000,
        label = ('Crafting %s…'):format(recipe.label),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped',
            flag = 49,
        },
    })

    busy = false
    if Vars.oxTarget then
        Vars.oxTarget:disableTargeting(false)
    end

    if not ok then
        return notify('Crafting cancelled.', 'error')
    end

    -- Request server to validate materials & give item
    local success, nameOrErr, count = lib.callback.await('cfx-keydi-utils:guncrafting:craft', false, ActiveLocationId, recipe.id)
    if success then
        notify(('Successfully crafted x%d %s!'):format(count or 1, nameOrErr or recipe.label), 'success')
    else
        notify(nameOrErr or 'Crafting failed.', 'error')
    end
end

local function openSection(sectionKey)
    if not Data or not ActiveLocationId then return end

    local recipes = {}
    for i = 1, #Data.recipes do
        local r = Data.recipes[i]
        if r.section == sectionKey and isRecipeForLocation(r, ActiveLocationId) then
            recipes[#recipes + 1] = r
        end
    end

    if #recipes == 0 then
        return notify('No recipes available in this category.', 'error')
    end

    local options = {}
    for i = 1, #recipes do
        local r = recipes[i]
        
        -- Fetch player's current stock count for ingredients
        local stock = lib.callback.await('cfx-keydi-utils:guncrafting:checkMaterials', false, r.id) or {}
        local ingList = {}
        local canCraft = true

        for j = 1, #(r.ingredients or {}) do
            local ing = r.ingredients[j]
            local userHas = tonumber(stock[j]) or 0
            local needed = ing.count or 1
            if userHas < needed then
                canCraft = false
            end
            ingList[#ingList + 1] = ('%s (%d/%d)'):format(ing.label or 'Material', userHas, needed)
        end

        local desc = r.description or ''
        if #ingList > 0 then
            desc = desc .. '\nRequired: ' .. table.concat(ingList, ', ')
        end

        options[#options + 1] = {
            title = ('%s  ×%d'):format(r.label, r.count or 1),
            description = desc,
            icon = canCraft and 'fa-solid fa-hammer' or 'fa-solid fa-circle-xmark',
            disabled = not canCraft,
            onSelect = function()
                craftItem(r)
            end,
        }
    end

    local loc
    for i = 1, #Data.locations do
        if Data.locations[i].id == ActiveLocationId then
            loc = Data.locations[i]
            break
        end
    end
    local singleSection = loc and loc.sections and #loc.sections == 1

    lib.registerContext({
        id = 'cfx_keydi_guncrafting_section',
        title = singleSection and (loc.label or 'Gun Crafting Workbench') or (SECTION_META[sectionKey] and SECTION_META[sectionKey].title or 'Crafting Recipes'),
        menu = singleSection and nil or 'cfx_keydi_guncrafting_root',
        options = options,
    })
    lib.showContext('cfx_keydi_guncrafting_section')
end

local function openRoot(locationId)
    if not Region.Allowed('illegal') then
        return notify(Region.Message('illegal'), 'error')
    end
    if not Data then return end
    ActiveLocationId = locationId

    local loc = nil
    for i = 1, #Data.locations do
        if Data.locations[i].id == locationId then
            loc = Data.locations[i]
            break
        end
    end

    if not loc then return end

    local sections = loc.sections or { 'weapons' }
    if #sections == 1 then
        return openSection(sections[1])
    end

    local options = {}

    for i = 1, #sections do
        local key = sections[i]
        local meta = SECTION_META[key]
        if meta then
            options[#options + 1] = {
                title = meta.title,
                description = meta.desc,
                icon = meta.icon,
                arrow = true,
                onSelect = function()
                    openSection(key)
                end,
            }
        end
    end

    lib.registerContext({
        id = 'cfx_keydi_guncrafting_root',
        title = loc.label or 'Gun Crafting Workbench',
        options = options,
    })
    lib.showContext('cfx_keydi_guncrafting_root')
end

-- Spawn props and initialize target zones
CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(200)
    end
    Vars.oxTarget = Vars.oxTarget or exports.ox_target

    Data = lib.callback.await('cfx-keydi-utils:guncrafting:getData', false)
    if not Data or not Data.locations then
        warn('[cfx-keydi-utils] guncrafting: failed to load server data')
        return
    end

    local dist = Data.interactDistance or 3.0

    for i = 1, #Data.locations do
        local loc = Data.locations[i]
        local locId = loc.id
        local objEntity = nil

        -- Spawn server-defined object/prop at location (soft-fail: zone still works)
        if loc.spawnProp and loc.model then
            local modelHash = type(loc.model) == 'number' and loc.model or joaat(loc.model)
            local loaded = pcall(function()
                lib.requestModel(modelHash, 5000)
            end)

            if not loaded or not HasModelLoaded(modelHash) then
                -- Gunrunning DLC props often time out — fall back to base-game bench
                local fallback = joaat('prop_tool_bench02')
                loaded = pcall(function()
                    lib.requestModel(fallback, 5000)
                end)
                if loaded and HasModelLoaded(fallback) then
                    modelHash = fallback
                else
                    modelHash = nil
                end
            end

            if modelHash and HasModelLoaded(modelHash) then
                objEntity = CreateObject(modelHash, loc.x, loc.y, loc.z, false, false, false)
                if objEntity and objEntity ~= 0 then
                    SetEntityHeading(objEntity, loc.heading or 0.0)
                    FreezeEntityPosition(objEntity, true)
                    SetEntityInvincible(objEntity, true)
                    SpawnedProps[#SpawnedProps + 1] = objEntity
                else
                    objEntity = nil
                end
                SetModelAsNoLongerNeeded(modelHash)
            end
        end

        -- Add target option on object or sphere zone
        if objEntity and DoesEntityExist(objEntity) then
            Vars.oxTarget:addLocalEntity(objEntity, {
                {
                    name = ('cfx_keydi_guncrafting_%s'):format(locId),
                    icon = 'fa-solid fa-screwdriver-wrench',
                    label = loc.label or 'Gun Crafting Workbench',
                    distance = dist,
                    onSelect = function()
                        openRoot(locId)
                    end,
                },
            })
        else
            Vars.oxTarget:addSphereZone({
                coords = vec3(loc.x, loc.y, loc.z),
                radius = dist,
                debug = false,
                options = {
                    {
                        name = ('cfx_keydi_guncrafting_%s'):format(locId),
                        icon = 'fa-solid fa-screwdriver-wrench',
                        label = loc.label or 'Gun Crafting Workbench',
                        distance = dist,
                        onSelect = function()
                            openRoot(locId)
                        end,
                    },
                },
            })
        end
    end
end)

-- Resource stop cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #SpawnedProps do
        if DoesEntityExist(SpawnedProps[i]) then
            DeleteObject(SpawnedProps[i])
        end
    end
end)
