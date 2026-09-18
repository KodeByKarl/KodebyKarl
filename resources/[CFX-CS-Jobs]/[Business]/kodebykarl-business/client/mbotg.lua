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

exports.ox_target:addBoxZone({
    name = "mbotg_menu",
    coords = vec3(120.9078, 270.4659, 108.2588),
    size = vec3(2.0, 2.0, 2.0),
    rotation = 164.4989,
    debug = false,
    options = {
        {
            icon = "fa-solid fa-kitchen-set",
            label = "Foods Menu",
            groups = { ['mbotg'] = 0 },
            onSelect = function()
                lib.showContext('mbotg_foodmenu')
            end
        },
        {
            icon = "fa-solid fa-kitchen-set",
            label = "Drinks Menu",
            groups = { ['mbotg'] = 0 },
            onSelect = function()
                lib.showContext('mbotg_drinkmenu')
            end
        }
    },
    drawDistance = 2.5
})

Citizen.CreateThread(function()
    lib.registerContext({
        id = 'mbotg_foodmenu',
        title = "Food Menu",
        options = {
            {
                title = "🍗 Chicken Biryani",
                description = "Requirements: 10x tomato",
                arrow = false,
                event = 'mbotg:prepareItem',
                args = { item = 'mbotg_food_1', animDict = 'anim@amb@business@coc@coc_unpack_cut@', animName = 'fullcut_cycle_v6_cokecutter' }
            },
            {
                title = "🥩 Beef Biryani",
                description = "Requirements: 10x tomato",
                arrow = false,
                event = 'mbotg:prepareItem',
                args = { item = 'mbotg_food_2', animDict = 'anim@amb@business@coc@coc_unpack_cut@', animName = 'fullcut_cycle_v6_cokecutter' }
            }
        }
    })

    lib.registerContext({
        id = 'mbotg_drinkmenu',
        title = "Drink Menu",
        options = {
            {
                title = "🍓 Strawberry Coconut Lassi",
                description = "Requirements: 10x Bottle Milk",
                arrow = false,
                event = 'mbotg:prepareItem',
                args = { item = 'mbotg_drink_1', animDict = 'anim@mp_player_intupperspray_champagne', animName = 'idle_a' }
            },
            {
                title = "🥭 Mango Lassi",
                description = "Requirements: 10x Bottle Milk",
                arrow = false,
                event = 'mbotg:prepareItem',
                args = { item = 'mbotg_drink_2', animDict = 'anim@mp_player_intupperspray_champagne', animName = 'idle_a' }
            }
        }
    })
end)

RegisterNetEvent("mbotg:prepareItem")
AddEventHandler("mbotg:prepareItem", function(args)
    local ped = PlayerPedId()
    lib.requestAnimDict(args.animDict, 100)
    TaskPlayAnim(ped, args.animDict, args.animName, 1.0, -1.0, -1, 49, 1, false, false, false)

    local success = lib.skillCheck({'easy', {areaSize = 60, speedMultiplier = 1}, {'w', 'a', 's', 'd'}})

    if success then
        CraftBusinessItem(args.item)
        ClearPedTasks(ped)
    else
        TriggerEvent('ox_lib:notify', { 
            title = 'SYSTEM', 
            description = 'You Failed', 
            position = 'center-left', 
            type = 'error', 
            duration = 5000 
        })
        ClearPedTasks(ped)
    end
end)