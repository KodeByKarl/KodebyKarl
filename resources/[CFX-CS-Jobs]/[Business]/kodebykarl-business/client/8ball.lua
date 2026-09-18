local ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

local function is8Ball()
    return ESX.PlayerData.job and ESX.PlayerData.job.name == '8ball'
end

-- Station Coords (Placeholders: ready to be updated once locations are chosen)
Config8Ball = {
    cookCoords = nil,   -- e.g. vec3(...)
    drinkCoords = nil,  -- e.g. vec3(...)
    packCoords = nil,   -- e.g. vec3(...)
}

-- Command for employees to access menu anywhere until coordinates are configured
RegisterCommand('8ballmenu', function()
    if not is8Ball() then
        TriggerEvent('ox_lib:notify', { title = '8-BALL DINER', description = 'Only 8-Ball employees can access this menu!', type = 'error', duration = 4000 })
        return
    end
    TriggerEvent('8ball:openMainMenu')
end, false)

RegisterNetEvent('8ball:openMainMenu', function()
    if not is8Ball() then return end
    lib.registerContext({
        id = '8ball_mainmenu',
        title = "8-Ball Diner Kitchen",
        options = {
            {
                title = "🍔 Cook Food Menu",
                description = "Craft 8-Ball Burgers",
                icon = "fa-solid fa-burger",
                event = '8ball:cookfoods',
            },
            {
                title = "🥤 Drink Menu",
                description = "Craft 8-Ball Sodas",
                icon = "fa-solid fa-wine-glass",
                event = '8ball:makedrinks',
            },
            {
                title = "📦 Pack Combo Box",
                description = "Requirements: 5x 8-Ball Burger & 5x 8-Ball Soda",
                icon = "fa-solid fa-box-open",
                event = '8ball:packmeal',
            },
        }
    })
    lib.showContext('8ball_mainmenu')
end)

-- Food Menu
RegisterNetEvent('8ball:cookfoods', function()
    if not is8Ball() then return end
    lib.registerContext({
        id = '8ball_foodsmenu',
        title = "8-Ball Food Station",
        menu = '8ball_mainmenu',
        options = {
            {
                title = "🍔 8-Ball Burger (x5)",
                description = "Requirements: 5x Food Ingredients",
                icon = "fa-solid fa-burger",
                event = '8ball:cookburger',
            },
        }
    })
    lib.showContext('8ball_foodsmenu')
end)

RegisterNetEvent('8ball:cookburger', function()
    if not is8Ball() then return end
    local count = exports.ox_inventory:Search('count', 'food_ingredients')
    if count < 5 then
        TriggerEvent('ox_lib:notify', { title = '8-BALL DINER', description = 'You need 5x Food Ingredients to cook burgers.', type = 'error', duration = 4000 })
        return
    end

    local ped = PlayerPedId()
    lib.requestAnimDict('anim@amb@business@coc@coc_unpack_cut@', 100)
    TaskPlayAnim(ped, 'anim@amb@business@coc@coc_unpack_cut@', 'fullcut_cycle_v6_cokecutter', 1.0, -1.0, -1, 49, 1, false, false, false)

    local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})
    ClearPedTasks(ped)

    if success then
        CraftBusinessItem('8ball_food')
    else
        TriggerEvent('ox_lib:notify', { title = '8-BALL DINER', description = 'Cooking failed!', type = 'error', duration = 3500 })
    end
end)

-- Drink Menu
RegisterNetEvent('8ball:makedrinks', function()
    if not is8Ball() then return end
    lib.registerContext({
        id = '8ball_drinksmenu',
        title = "8-Ball Drink Station",
        menu = '8ball_mainmenu',
        options = {
            {
                title = "🥤 8-Ball Soda (x5)",
                description = "Requirements: 5x Food Ingredients",
                icon = "fa-solid fa-bottle-droplet",
                event = '8ball:makesoda',
            },
        }
    })
    lib.showContext('8ball_drinksmenu')
end)

RegisterNetEvent('8ball:makesoda', function()
    if not is8Ball() then return end
    local count = exports.ox_inventory:Search('count', 'food_ingredients')
    if count < 5 then
        TriggerEvent('ox_lib:notify', { title = '8-BALL DINER', description = 'You need 5x Food Ingredients to make sodas.', type = 'error', duration = 4000 })
        return
    end

    local ped = PlayerPedId()
    lib.requestAnimDict('anim@mp_player_intupperspray_champagne', 100)
    TaskPlayAnim(ped, 'anim@mp_player_intupperspray_champagne', 'idle_a', 1.0, -1.0, -1, 49, 1, false, false, false)

    local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})
    ClearPedTasks(ped)

    if success then
        CraftBusinessItem('8ball_drink')
    else
        TriggerEvent('ox_lib:notify', { title = '8-BALL DINER', description = 'Drink preparation failed!', type = 'error', duration = 3500 })
    end
end)

-- Assemble Combo Box (Requires 5 Food + 5 Drink -> 1 Combo Box)
RegisterNetEvent('8ball:packmeal', function()
    if not is8Ball() then return end
    local hasFood = exports.ox_inventory:Search('count', '8ball_food')
    local hasDrink = exports.ox_inventory:Search('count', '8ball_drink')

    if hasFood < 5 or hasDrink < 5 then
        TriggerEvent('ox_lib:notify', {
            title = '8-BALL DINER',
            description = ('Missing items! You have %d/5 Burgers and %d/5 Sodas.'):format(hasFood, hasDrink),
            type = 'error',
            duration = 5000
        })
        return
    end

    local ped = PlayerPedId()
    lib.requestAnimDict('anim@amb@business@coc@coc_unpack_cut@', 100)
    TaskPlayAnim(ped, 'anim@amb@business@coc@coc_unpack_cut@', 'fullcut_cycle_v6_cokecutter', 1.0, -1.0, -1, 49, 0, false, false, false)

    local success = lib.skillCheck({'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})
    ClearPedTasks(ped)

    if success then
        CraftBusinessItem('8ball_box')
    else
        TriggerEvent('ox_lib:notify', { title = '8-BALL DINER', description = 'Packing failed!', type = 'error', duration = 3500 })
    end
end)
