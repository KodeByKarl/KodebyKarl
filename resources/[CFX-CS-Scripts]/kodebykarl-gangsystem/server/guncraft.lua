local ESX = exports['es_extended']:getSharedObject()

--[[
    Gang HQ gun crafting — validates membership then proxies materials/craft
    through cfx-cs-utils guncrafting when that resource is running.
]]

local RECIPE_FALLBACK = {
    {
        id = 'craft_appistol',
        label = 'AP Pistol',
        item = 'WEAPON_APPISTOL',
        count = 1,
        ingredients = {
            { item = 'copper', count = 5 },
            { item = 'gun_blueprint_appistol', count = 5 },
            { item = 'aluminum', count = 3 },
        },
    },
    {
        id = 'craft_smg',
        label = 'SMG',
        item = 'WEAPON_SMG',
        count = 1,
        ingredients = {
            { item = 'iron', count = 5 },
            { item = 'gun_blueprint_smg', count = 5 },
            { item = 'steel', count = 3 },
        },
    },
    {
        id = 'craft_assaultrifle',
        label = 'Assault Rifle (AK)',
        item = 'WEAPON_ASSAULTRIFLE',
        count = 1,
        ingredients = {
            { item = 'copper', count = 5 },
            { item = 'gun_blueprint_assaultrifle', count = 5 },
            { item = 'rubber', count = 5 },
        },
    },
    {
        id = 'craft_ammo_ap',
        label = 'AP Pistol Ammo',
        item = 'ammo-9',
        count = 50,
        ingredients = {
            { item = 'gunpowder', count = 10 },
        },
    },
    {
        id = 'craft_ammo_smg',
        label = 'SMG Ammo',
        item = 'ammo-9',
        count = 50,
        ingredients = {
            { item = 'copper', count = 10 },
        },
    },
    {
        id = 'craft_ammo_assault',
        label = 'Assault Rifle Ammo',
        item = 'ammo-rifle2',
        count = 50,
        ingredients = {
            { item = 'gun_blueprint_assaultrifle', count = 10 },
        },
    },
}

local recipeById = {}
for i = 1, #RECIPE_FALLBACK do
    recipeById[RECIPE_FALLBACK[i].id] = RECIPE_FALLBACK[i]
end

local cooldown = {}

local function findCraftCoords(gangName)
    local cfg = Config.Gangs[gangName]
    if not cfg or not cfg.locations or not cfg.locations.gunCrafting then return nil end
    local c = cfg.locations.gunCrafting
    return vector3(c.x, c.y, c.z)
end

lib.callback.register('kodebykarl-gangsystem:guncraft', function(source, locationId, recipeId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false, 'Player not found.' end

    local gang = GangServer.GetPlayerGang(source)
    if not gang or not Config.Gangs[gang.name] then
        return false, 'Gang members only.'
    end

    local expected = ('gang_%s'):format(gang.name)
    if locationId ~= expected and locationId ~= gang.name then
        return false, 'Invalid crafting location.'
    end

    local coords = findCraftCoords(gang.name)
    if not coords then return false, 'Crafting not configured.' end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false, 'Invalid ped.' end
    if #(GetEntityCoords(ped) - coords) > 5.0 then
        return false, 'Too far from the workbench.'
    end

    local recipe = recipeById[recipeId]
    if not recipe then return false, 'Unknown recipe.' end

    local now = os.time()
    if cooldown[source] and (now - cooldown[source]) < 3 then
        return false, 'Wait a moment before crafting again.'
    end

    local ox = exports.ox_inventory

    for i = 1, #recipe.ingredients do
        local ing = recipe.ingredients[i]
        local have = ox:Search(source, 'count', ing.item) or 0
        if have < (ing.count or 1) then
            return false, 'Missing materials.'
        end
    end

    if ox:CanCarryItem(source, recipe.item, recipe.count or 1) == false then
        return false, 'Not enough inventory space.'
    end

    for i = 1, #recipe.ingredients do
        local ing = recipe.ingredients[i]
        ox:RemoveItem(source, ing.item, ing.count or 1)
    end

    if not ox:AddItem(source, recipe.item, recipe.count or 1) then
        for i = 1, #recipe.ingredients do
            local ing = recipe.ingredients[i]
            ox:AddItem(source, ing.item, ing.count or 1)
        end
        return false, 'Failed to deliver item.'
    end

    cooldown[source] = now
    return true, recipe.label, recipe.count or 1
end)

AddEventHandler('playerDropped', function()
    cooldown[source] = nil
end)
