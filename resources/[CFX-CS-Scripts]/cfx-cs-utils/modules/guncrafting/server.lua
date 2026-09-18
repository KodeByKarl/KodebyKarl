--[[
    Gun Crafting Module (Server)
    Workbench locations, prop objects, and crafting recipes live strictly server-side.
    Players consume raw materials and components to craft firearms, attachments, and ammo.
]]

local Vars = require 'helpers.vars'
local Region = require 'helpers.region'

local cooldown = {}
local recipeById = {}
local locationById = {}

local GunCrafting = {
    name = 'guncrafting',
    interactDistance = 3.0,
    cooldown = 3,

    -- Server-side Workbenches & Locations
    locations = {
        {
            id = 1,
            label = 'Gun Crafting Bench',
            coords = vec4(3310.6545, 5176.4243, 19.6146, 51.9649),
            model = 'prop_tool_bench02',
            spawnProp = true,
            sections = { 'weapons', 'ammo' },
        },
    },

    -- AP Pistol, SMG, Assault Rifle (AK) + matching ammo
    recipes = {
        {
            id = 'craft_appistol',
            section = 'weapons',
            label = 'AP Pistol',
            description = 'Requires 5 Copper Ingot, 5 AP Pistol Blueprint, 3 Aluminum Ingot.',
            item = 'WEAPON_APPISTOL',
            count = 1,
            craftTime = 7000,
            ingredients = {
                { item = 'copper', label = 'Copper Ingot', count = 5 },
                { item = 'gun_blueprint_appistol', label = 'AP Pistol Blueprint', count = 5 },
                { item = 'aluminum', label = 'Aluminum Ingot', count = 3 },
            },
        },

        {
            id = 'craft_smg',
            section = 'weapons',
            label = 'SMG',
            description = 'Requires 5 Iron Ingot, 5 SMG Blueprint, 3 Steel Ingot.',
            item = 'WEAPON_SMG',
            count = 1,
            craftTime = 7000,
            ingredients = {
                { item = 'iron', label = 'Iron Ingot', count = 5 },
                { item = 'gun_blueprint_smg', label = 'SMG Blueprint', count = 5 },
                { item = 'steel', label = 'Steel Ingot', count = 3 },
            },
        },

        {
            id = 'craft_assaultrifle',
            section = 'weapons',
            label = 'Assault Rifle (AK)',
            description = 'Requires 5 Copper Ingot, 5 Assault Rifle Blueprint, 5 Rubber.',
            item = 'WEAPON_ASSAULTRIFLE',
            count = 1,
            craftTime = 7000,
            ingredients = {
                { item = 'copper', label = 'Copper Ingot', count = 5 },
                { item = 'gun_blueprint_assaultrifle', label = 'Assault Rifle Blueprint', count = 5 },
                { item = 'rubber', label = 'Rubber', count = 5 },
            },
        },

        {
            id = 'craft_ammo_ap',
            section = 'ammo',
            label = 'AP Pistol Ammo',
            description = '9mm for AP Pistol. Requires 10 Gunpowder. Crafts 50 rounds.',
            item = 'ammo-9',
            count = 50,
            craftTime = 5000,
            ingredients = {
                { item = 'gunpowder', label = 'Gunpowder', count = 10 },
            },
        },

        {
            id = 'craft_ammo_smg',
            section = 'ammo',
            label = 'SMG Ammo',
            description = '9mm for SMG. Requires 10 Copper Ingot. Crafts 50 rounds.',
            item = 'ammo-9',
            count = 50,
            craftTime = 5000,
            ingredients = {
                { item = 'copper', label = 'Copper Ingot', count = 10 },
            },
        },

        {
            id = 'craft_ammo_assault',
            section = 'ammo',
            label = 'Assault Rifle Ammo',
            description = '7.62 for Assault Rifle. Requires 10 Assault Rifle Blueprint. Crafts 50 rounds.',
            item = 'ammo-rifle2',
            count = 50,
            craftTime = 5000,
            ingredients = {
                { item = 'gun_blueprint_assaultrifle', label = 'Assault Rifle Blueprint', count = 10 },
            },
        },
    },
}

-- Index location & recipe maps
for i = 1, #GunCrafting.locations do
    local loc = GunCrafting.locations[i]
    locationById[loc.id] = loc
end

for i = 1, #GunCrafting.recipes do
    local rec = GunCrafting.recipes[i]
    recipeById[rec.id] = rec
end

local function serializeLocations()
    local out = {}
    for i = 1, #GunCrafting.locations do
        local loc = GunCrafting.locations[i]
        out[i] = {
            id = loc.id,
            label = loc.label,
            x = loc.coords.x,
            y = loc.coords.y,
            z = loc.coords.z,
            heading = loc.coords.w or 0.0,
            model = loc.model,
            spawnProp = loc.spawnProp,
            sections = loc.sections,
        }
    end
    return out
end

local function serializeRecipes()
    local out = {}
    for i = 1, #GunCrafting.recipes do
        local r = GunCrafting.recipes[i]
        local ingredients = {}
        for j = 1, #(r.ingredients or {}) do
            local ing = r.ingredients[j]
            ingredients[j] = {
                label = ing.label or 'Material',
                count = ing.count or 1,
            }
        end
        out[i] = {
            id = r.id,
            section = r.section,
            label = r.label,
            description = r.description,
            count = r.count,
            craftTime = r.craftTime,
            ingredients = ingredients,
            locations = r.locations,
        }
    end
    return out
end

local function isPlayerNearLocation(src, locationId)
    local loc = locationById[locationId]
    if not loc then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    local c = loc.coords
    local maxDist = (GunCrafting.interactDistance or 3.0) + 3.0
    return #(coords - vec3(c.x, c.y, c.z)) <= maxDist
end

-- Return server config & catalog to client
lib.callback.register('cfx-keydi-utils:guncrafting:getData', function()
    return {
        name = GunCrafting.name,
        interactDistance = GunCrafting.interactDistance,
        locations = serializeLocations(),
        recipes = serializeRecipes(),
    }
end)

-- Return current player stock counts for recipe ingredients
lib.callback.register('cfx-keydi-utils:guncrafting:checkMaterials', function(source, recipeId)
    local src = source
    local recipe = recipeById[recipeId]
    if not recipe or not recipe.ingredients then
        return {}
    end

    local result = {}
    for i = 1, #recipe.ingredients do
        local ing = recipe.ingredients[i]
        result[i] = Vars.ox:Search(src, 'count', ing.item) or 0
    end
    return result
end)

-- Execute crafting on server
lib.callback.register('cfx-keydi-utils:guncrafting:craft', function(source, locationId, recipeId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return false, 'Player not found.'
    end

    if not Region.Allowed('illegal', src) then
        return false, Region.Message('illegal')
    end

    locationId = tonumber(locationId)
    if type(recipeId) ~= 'string' or not locationId then
        return false, 'Invalid crafting request.'
    end

    local loc = locationById[locationId]
    local recipe = recipeById[recipeId]
    if not loc or not recipe then
        return false, 'Unknown crafting recipe.'
    end

    -- Verify location distance
    if not isPlayerNearLocation(src, locationId) then
        return false, 'Too far from the crafting workbench.'
    end

    -- Verify cooldown
    local now = os.time()
    local cd = GunCrafting.cooldown or 3
    if cooldown[src] and (now - cooldown[src]) < cd then
        return false, 'Wait a moment before crafting again.'
    end

    -- Verify location restrictions if specified
    if recipe.locations then
        local allowed = false
        for i = 1, #recipe.locations do
            if recipe.locations[i] == locationId then
                allowed = true
                break
            end
        end
        if not allowed then
            return false, 'This workbench cannot craft that item.'
        end
    end

    -- Check required ingredients
    local missing = {}
    for i = 1, #recipe.ingredients do
        local ing = recipe.ingredients[i]
        local userCount = Vars.ox:Search(src, 'count', ing.item) or 0
        local needed = ing.count or 1
        if userCount < needed then
            missing[#missing + 1] = ('%s (%d/%d)'):format(ing.label or 'Material', userCount, needed)
        end
    end

    if #missing > 0 then
        return false, ('Missing materials: %s'):format(table.concat(missing, ', '))
    end

    -- Check carry capacity
    local canCarry = Vars.ox:CanCarryItem(src, recipe.item, recipe.count or 1)
    if canCarry == false then
        return false, 'Not enough inventory space for crafted item.'
    end

    -- Remove ingredients
    for i = 1, #recipe.ingredients do
        local ing = recipe.ingredients[i]
        Vars.ox:RemoveItem(src, ing.item, ing.count or 1)
    end

    -- Deliver crafted item
    if not Vars.ox:AddItem(src, recipe.item, recipe.count or 1) then
        -- Refund ingredients if giving item fails
        for i = 1, #recipe.ingredients do
            local ing = recipe.ingredients[i]
            Vars.ox:AddItem(src, ing.item, ing.count or 1)
        end
        return false, 'Failed to deliver crafted item. Materials refunded.'
    end

    cooldown[src] = now
    return true, recipe.label, recipe.count or 1
end)

AddEventHandler('playerDropped', function()
    cooldown[source] = nil
end)
