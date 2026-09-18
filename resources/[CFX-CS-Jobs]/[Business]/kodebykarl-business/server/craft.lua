--[[
    All item grants for this resource happen here.

    Clients may only send a recipe id. Item names, counts, money, and
    ingredients are never taken from the client.
]]

local ox_inventory = exports.ox_inventory
local ESX = exports['es_extended']:getSharedObject()

local CRAFT_DISTANCE = 4.0
local CRAFT_COOLDOWN = 2

local busy = {}
local cooldown = {}

local Recipes = {
    -- UwU Cafe
    uwu_soup = {
        job = 'uwu',
        coords = vec3(-591.14, -1062.84, 22.75),
        ingredients = { { item = 'apple_a', count = 5 }, { item = 'grape_a', count = 5 } },
        output = { item = 'uwu_food1', count = 5 },
        label = 'UwU Soup',
    },
    uwu_ramen = {
        job = 'uwu',
        coords = vec3(-591.14, -1062.84, 22.75),
        ingredients = { { item = 'apple_a', count = 5 }, { item = 'grape_a', count = 5 } },
        output = { item = 'uwu_food2', count = 5 },
        label = 'UwU Ramen',
    },
    uwu_doughnut = {
        job = 'uwu',
        coords = vec3(-591.14, -1062.84, 22.75),
        ingredients = { { item = 'apple_a', count = 5 }, { item = 'grape_a', count = 5 } },
        output = { item = 'uwu_food3', count = 5 },
        label = 'UwU Doughnut',
    },
    uwu_donut = {
        job = 'uwu',
        coords = vec3(-591.14, -1062.84, 22.75),
        ingredients = { { item = 'apple_a', count = 5 }, { item = 'grape_a', count = 5 } },
        output = { item = 'uwu_food4', count = 5 },
        label = 'UwU Donut',
    },
    uwu_milktea = {
        job = 'uwu',
        coords = vec3(-586.88, -1061.99, 22.87),
        ingredients = { { item = 'mango_a', count = 5 }, { item = 'grape_a', count = 5 } },
        output = { item = 'uwu_coffee', count = 5 },
        label = 'Milk Tea',
    },
    uwu_frappe = {
        job = 'uwu',
        coords = vec3(-586.88, -1061.99, 22.87),
        ingredients = { { item = 'mango_a', count = 5 }, { item = 'grape_a', count = 5 } },
        output = { item = 'uwu_coffee2', count = 5 },
        label = 'Frappe',
    },
    uwu_yogart = {
        job = 'uwu',
        coords = vec3(-586.88, -1061.99, 22.87),
        ingredients = { { item = 'mango_a', count = 5 }, { item = 'grape_a', count = 5 } },
        output = { item = 'uwu_coffee3', count = 5 },
        label = 'Yogart',
    },
    uwu_meal1 = {
        job = 'uwu',
        coords = vec3(-591.14, -1062.84, 22.75),
        ingredients = { { item = 'uwu_food1', count = 10 }, { item = 'uwu_coffee', count = 10 } },
        output = { item = 'uwu_meal', count = 1 },
        label = 'UwU Box 1',
    },
    uwu_meal2 = {
        job = 'uwu',
        coords = vec3(-591.14, -1062.84, 22.75),
        ingredients = { { item = 'uwu_food2', count = 10 }, { item = 'uwu_coffee2', count = 10 } },
        output = { item = 'uwu_meal2', count = 1 },
        label = 'UwU Box 2',
    },
    uwu_unpack_meal1 = {
        job = false,
        coords = false,
        ingredients = { { item = 'uwu_meal', count = 1 } },
        extras = { { item = 'uwu_food1', count = 10 }, { item = 'uwu_coffee', count = 10 } },
        label = 'UwU Meal 1',
    },
    uwu_unpack_meal2 = {
        job = false,
        coords = false,
        ingredients = { { item = 'uwu_meal2', count = 1 } },
        extras = { { item = 'uwu_food2', count = 10 }, { item = 'uwu_coffee2', count = 10 } },
        label = 'UwU Meal 2',
    },

    -- Taco Shop
    taco_food = {
        job = 'taco',
        coords = false,
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = 'taco_food', count = 5 },
        label = 'Crispy Taco',
    },
    taco_drink = {
        job = 'taco',
        coords = false,
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = 'taco_drink', count = 5 },
        label = 'Taco Drink',
    },
    taco_box = {
        job = 'taco',
        coords = false,
        ingredients = { { item = 'taco_food', count = 5 }, { item = 'taco_drink', count = 5 } },
        output = { item = 'taco_box', count = 1 },
        label = 'Taco Combo Box',
    },
    -- Legacy Taco Shop aliases
    taco_plain = {
        job = 'taco',
        coords = false,
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = 'taco_food', count = 5 },
        label = 'Crispy Taco',
    },
    taco_lemon = {
        job = 'taco',
        coords = false,
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = 'taco_drink', count = 5 },
        label = 'Taco Drink',
    },
    taco_meal = {
        job = 'taco',
        coords = false,
        ingredients = { { item = 'taco_food', count = 5 }, { item = 'taco_drink', count = 5 } },
        output = { item = 'taco_box', count = 1 },
        label = 'Taco Combo Box',
    },

    -- 8-Ball Diner
    ['8ball_food'] = {
        job = '8ball',
        coords = false,
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = '8ball_food', count = 5 },
        label = '8-Ball Burger',
    },
    ['8ball_drink'] = {
        job = '8ball',
        coords = false,
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = '8ball_drink', count = 5 },
        label = '8-Ball Soda',
    },
    ['8ball_box'] = {
        job = '8ball',
        coords = false,
        ingredients = { { item = '8ball_food', count = 5 }, { item = '8ball_drink', count = 5 } },
        output = { item = '8ball_box', count = 1 },
        label = '8-Ball Combo Box',
    },

    -- Burger Shot
    bshot_classic = {
        job = 'burgershot',
        coords = vec3(-1196.11, -900.01, 13.89),
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = 'bshot_food1', count = 5 },
        label = 'Classic Burger',
    },
    bshot_cheesy = {
        job = 'burgershot',
        coords = vec3(-1196.11, -900.01, 13.89),
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = 'bshot_food2', count = 5 },
        label = 'Cheesy Burger',
    },
    bshot_cola = {
        job = 'burgershot',
        coords = vec3(-1190.67, -899.18, 13.89),
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = 'cola', count = 5 },
        label = 'Cola',
    },
    bshot_dew = {
        job = 'burgershot',
        coords = vec3(-1190.67, -899.18, 13.89),
        ingredients = { { item = 'food_ingredients', count = 5 } },
        output = { item = 'mountaindew', count = 5 },
        label = 'Mountain Dew',
    },

    -- MBOTG
    mbotg_food_1 = {
        job = 'mbotg',
        coords = vec3(120.9078, 270.4659, 108.2588),
        ingredients = { { item = 'tomato', count = 10 } },
        output = { item = 'mbotg_food_1', count = 1 },
        label = 'Chicken Biryani',
    },
    mbotg_food_2 = {
        job = 'mbotg',
        coords = vec3(120.9078, 270.4659, 108.2588),
        ingredients = { { item = 'tomato', count = 10 } },
        output = { item = 'mbotg_food_2', count = 1 },
        label = 'Beef Biryani',
    },
    mbotg_drink_1 = {
        job = 'mbotg',
        coords = vec3(120.9078, 270.4659, 108.2588),
        ingredients = { { item = 'bottle_milk', count = 10 } },
        output = { item = 'mbotg_drink_1', count = 1 },
        label = 'Strawberry Coconut Lassi',
    },
    mbotg_drink_2 = {
        job = 'mbotg',
        coords = vec3(120.9078, 270.4659, 108.2588),
        ingredients = { { item = 'bottle_milk', count = 10 } },
        output = { item = 'mbotg_drink_2', count = 1 },
        label = 'Mango Lassi',
    },

    -- Digital Den
    digiden_phone = {
        job = 'digiden',
        coords = vec3(382.8, -826.52, 29.31),
        ingredients = { { item = 'wood_a', count = 5 } },
        output = { item = 'blue_phone', count = 5 },
        label = 'Phone',
    },
    digiden_radio = {
        job = 'digiden',
        coords = vec3(382.8, -826.52, 29.31),
        ingredients = { { item = 'wood_a', count = 5 } },
        output = { item = 'radio', count = 5 },
        label = 'Radio',
    },
    digiden_boombox = {
        job = 'digiden',
        coords = vec3(382.8, -826.52, 29.31),
        ingredients = { { item = 'wood_a', count = 5 } },
        output = { item = 'boombox', count = 5 },
        label = 'Boombox',
    },

    -- White Widow
    widow_cannabis = {
        job = 'whitewidow',
        minGrade = 1,
        coords = vec3(164.32, -233.35, 50.07),
        ingredients = { { item = 'widowingredient', count = 5 } },
        output = { item = 'cannabispill', count = 5 },
        label = 'Cannabis Pill',
    },

    -- Pharmacy stock (job + location + cooldown; no client-chosen items)
    pharma_stresstabs = {
        job = 'uwu',
        minGrade = 3,
        coords = vec3(-482.76, -1012.3, 24.29),
        ingredients = {},
        output = { item = 'stresstabs', count = 5 },
        label = 'Stress Tabs',
        cooldown = 15,
    },
    pharma_bandage = {
        job = 'uwu',
        minGrade = 3,
        coords = vec3(-482.76, -1012.3, 24.29),
        ingredients = {},
        output = { item = 'bandage', count = 5 },
        label = 'Bandage',
        cooldown = 15,
    },
    pharma_gauze = {
        job = 'uwu',
        minGrade = 3,
        coords = vec3(-482.76, -1012.3, 24.29),
        ingredients = {},
        output = { item = 'gauze', count = 5 },
        label = 'Gauze',
        cooldown = 15,
    },
    pharma_medikit = {
        job = 'uwu',
        minGrade = 3,
        coords = vec3(-482.76, -1012.3, 24.29),
        ingredients = {},
        output = { item = 'medikit', count = 5 },
        label = 'Medkit',
        cooldown = 15,
    },
}

local function itemCount(src, item)
    return ox_inventory:Search(src, 'count', item) or 0
end

local function isNearCoords(src, coords)
    if not coords then return true end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= CRAFT_DISTANCE
end

local function hasJob(xPlayer, recipe)
    if not recipe.job then return true end
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= recipe.job then
        return false
    end
    if recipe.minGrade and (xPlayer.job.grade or 0) < recipe.minGrade then
        return false
    end
    return true
end

local function giveOutputs(src, recipe)
    if recipe.output then
        if not ox_inventory:CanCarryItem(src, recipe.output.item, recipe.output.count) then
            return false, 'Your inventory is full.'
        end
    end
    if recipe.extras then
        for i = 1, #recipe.extras do
            local extra = recipe.extras[i]
            if not ox_inventory:CanCarryItem(src, extra.item, extra.count) then
                return false, 'Your inventory is full.'
            end
        end
    end

    if recipe.ingredients then
        for i = 1, #recipe.ingredients do
            local ing = recipe.ingredients[i]
            if not ox_inventory:RemoveItem(src, ing.item, ing.count) then
                return false, 'Missing ingredients.'
            end
        end
    end

    if recipe.output then
        if not ox_inventory:AddItem(src, recipe.output.item, recipe.output.count) then
            if recipe.ingredients then
                for i = 1, #recipe.ingredients do
                    local ing = recipe.ingredients[i]
                    ox_inventory:AddItem(src, ing.item, ing.count)
                end
            end
            return false, 'Failed to deliver item.'
        end
    end

    if recipe.extras then
        for i = 1, #recipe.extras do
            local extra = recipe.extras[i]
            ox_inventory:AddItem(src, extra.item, extra.count)
        end
    end

    return true
end

lib.callback.register('cfx-hu-business:craft', function(source, recipeId)
    local src = source
    if type(recipeId) ~= 'string' or #recipeId > 48 then
        return false, 'Invalid request.'
    end

    local recipe = Recipes[recipeId]
    if not recipe then
        print(('[cfx-hu-business] blocked unknown recipe "%s" from %s'):format(recipeId, src))
        return false, 'Invalid request.'
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return false, 'Player not found.'
    end

    if busy[src] then
        return false, 'Already crafting.'
    end

    busy[src] = true

    local function finish(ok, msg)
        busy[src] = nil
        return ok, msg
    end

    local now = os.time()
    local cd = recipe.cooldown or CRAFT_COOLDOWN
    if cooldown[src] and (now - cooldown[src]) < cd then
        return finish(false, 'Wait a moment before doing that again.')
    end

    if not hasJob(xPlayer, recipe) then
        return finish(false, 'You are not allowed to do this.')
    end

    if not isNearCoords(src, recipe.coords) then
        return finish(false, 'You are too far from the station.')
    end

    if recipe.ingredients then
        for i = 1, #recipe.ingredients do
            local ing = recipe.ingredients[i]
            if itemCount(src, ing.item) < ing.count then
                return finish(false, 'You do not have enough ingredients.')
            end
        end
    end

    local ok, err = giveOutputs(src, recipe)
    if not ok then
        return finish(false, err)
    end

    cooldown[src] = now
    return finish(true, ('You received %s.'):format(recipe.label))
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
    cooldown[source] = nil
end)
