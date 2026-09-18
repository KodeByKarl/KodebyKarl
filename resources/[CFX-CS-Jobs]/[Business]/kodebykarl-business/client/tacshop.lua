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

local function isTaco()
    local jobName = ESX.PlayerData.job and ESX.PlayerData.job.name
    return jobName == 'taco' or jobName == 'tacoshop'
end

-- Command for employees to access menu anywhere until coordinates are configured
RegisterCommand('tacomenu', function()
    if not isTaco() then
        TriggerEvent('ox_lib:notify', { title = 'TACO SHOP', description = 'Only Taco Shop employees can access this menu!', type = 'error', duration = 4000 })
        return
    end
    TriggerEvent('tacoshop:cookmenu')
end, false)

RegisterNetEvent('tacoshop:cookmenu')
AddEventHandler('tacoshop:cookmenu', function()
    if not isTaco() then return end
    lib.registerContext({
        id = 'tacoshop_cookmenu',
        title = "Taco Shop Kitchen",
        options = {
            {
                title = "🌮 Cook Food Menu",
                description = "Craft Crispy Tacos",
                icon = "fa-solid fa-utensils",
                event = 'tacoshop:cookfoods',
            },
            {
                title = "🥤 Drinks Menu",
                description = "Craft Taco Drinks",
                icon = "fa-solid fa-bottle-droplet",
                event = 'tacoshop:makedrinks',
            },
            {
                title = "📦 Pack Combo Box",
                description = "Requirements: 5x Crispy Taco & 5x Taco Drink",
                icon = "fa-solid fa-box-open",
                event = 'tacoshop:tacomeal',
            },
        }
    })
    lib.showContext('tacoshop_cookmenu')
end)

RegisterNetEvent('tacoshop:cookfoods')
AddEventHandler('tacoshop:cookfoods', function()
    if not isTaco() then return end
    lib.registerContext({
        id = 'tacoshop_foodsmenu',
        title = "Taco Food Station",
        menu = 'tacoshop_cookmenu',
        options = {
            {
                title = "🌮 Crispy Taco (x5)",
                description = "Requirements: 5x Food Ingredients",
                icon = "fa-solid fa-utensils",
                event = 'tacoshop:tacoplain',
            },
        }
    })
    lib.showContext('tacoshop_foodsmenu')
end)

RegisterNetEvent("tacoshop:tacoplain")
AddEventHandler("tacoshop:tacoplain", function()
    if not isTaco() then return end
    local count = exports.ox_inventory:Search('count', 'food_ingredients')
    if count < 5 then
        TriggerEvent('ox_lib:notify', { title = 'TACO SHOP', description = 'You need 5x Food Ingredients to cook tacos.', type = 'error', duration = 4000 })
        return
    end

    local ped = PlayerPedId()
    lib.requestAnimDict('anim@amb@business@coc@coc_unpack_cut@', 100)
    TaskPlayAnim(ped, 'anim@amb@business@coc@coc_unpack_cut@', 'fullcut_cycle_v6_cokecutter', 1.0, -1.0, -1, 49, 1, false, false, false)

    local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})
    ClearPedTasks(ped)

    if success then
        CraftBusinessItem('taco_food')
    else
        TriggerEvent('ox_lib:notify', { title = 'TACO SHOP', description = 'Cooking failed!', type = 'error', duration = 3500 })
    end
end)

RegisterNetEvent('tacoshop:makedrinks')
AddEventHandler('tacoshop:makedrinks', function()
    if not isTaco() then return end
    lib.registerContext({
        id = 'tacoshop_drinkmenu',
        title = "Taco Drink Station",
        menu = 'tacoshop_cookmenu',
        options = {
            {
                title = "🥤 Taco Drink (x5)",
                description = "Requirements: 5x Food Ingredients",
                icon = "fa-solid fa-bottle-droplet",
                event = 'tacoshop:lemonjuice',
            },
        }
    })
    lib.showContext('tacoshop_drinkmenu')
end)

RegisterNetEvent("tacoshop:lemonjuice")
AddEventHandler("tacoshop:lemonjuice", function()
    if not isTaco() then return end
    local count = exports.ox_inventory:Search('count', 'food_ingredients')
    if count < 5 then
        TriggerEvent('ox_lib:notify', { title = 'TACO SHOP', description = 'You need 5x Food Ingredients to make drinks.', type = 'error', duration = 4000 })
        return
    end

    local ped = PlayerPedId()
    lib.requestAnimDict('anim@mp_player_intupperspray_champagne', 100)
    TaskPlayAnim(ped, 'anim@mp_player_intupperspray_champagne', 'idle_a', 1.0, -1.0, -1, 49, 1, false, false, false)

    local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})
    ClearPedTasks(ped)

    if success then
        CraftBusinessItem('taco_drink')
    else
        TriggerEvent('ox_lib:notify', { title = 'TACO SHOP', description = 'Drink preparation failed!', type = 'error', duration = 3500 })
    end
end)

-- Assemble Combo Box (Requires 5 Food + 5 Drink -> 1 Combo Box)
RegisterNetEvent('tacoshop:tacomeal')
AddEventHandler('tacoshop:tacomeal', function()
    if not isTaco() then return end
    local tacoCount = exports.ox_inventory:Search('count', 'taco_food') + exports.ox_inventory:Search('count', 'taco_food1')
    local drinkCount = exports.ox_inventory:Search('count', 'taco_drink') + exports.ox_inventory:Search('count', 'taco_drink1')

    if tacoCount < 5 or drinkCount < 5 then
        TriggerEvent('ox_lib:notify', {
            title = 'TACO SHOP',
            description = ('Missing items! You have %d/5 Tacos and %d/5 Drinks.'):format(tacoCount, drinkCount),
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
        CraftBusinessItem('taco_box')
    else
        TriggerEvent('ox_lib:notify', { title = 'TACO SHOP', description = 'Packing failed!', type = 'error', duration = 3500 })
    end
end)