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
    coords = vec3(-591.14, -1062.84, 22.75),
    size = vec3(1, 1, 1),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            name = 'box',
            event = 'uwucafe:foodmenu',
            icon = '',
            label = 'Food Menu',
            groups = {['uwu'] = 0},
        }
    }
})

RegisterNetEvent('uwucafe:foodmenu')
AddEventHandler('uwucafe:foodmenu', function()
    lib.registerContext({
        id = 'uwucafe_menu',
        title = "Food Menu",
        icon = "",
        options = {
            {
                title = "Food Menu",
                description = "",
                arrow = false,
                event = 'uwucafe:cookfoods',
            },
            {
                title = "Uwu Box",
                description = "",
                arrow = false,
                event = 'uwucafe:uwumeallssss',
            },
        }
    })
    lib.showContext('uwucafe_menu')
end)


RegisterNetEvent('uwucafe:cookfoods')
AddEventHandler('uwucafe:cookfoods', function()
    lib.registerContext({
        id = 'uwucafe_foodmenu',
        title = "Food Menu",
        icon = "",
        options = {
            {
                title = "UwU Soup",
                description = "Requirments: 5x Apple & 5x Grapes",
                arrow = false,
                event = 'uwucafe:soup',
            },
            {
                title = "UwU Ramen",
                description = "Requirments: 5x Apple & 5x Grapes",
                arrow = false,
                event = 'uwucafe:ramen',
            },
            {
                title = "UwU Doughnut",
                description = "Requirments: 5x Apple & 5x Grapes",
                arrow = false,
                event = 'uwucafe:doughnut',
            },
            {
                title = "UwU Donut",
                description = "Requirments: 5x Apple & 5x Grapes",
                arrow = false,
                event = 'uwucafe:donut',
            },
            {
                title = "Go Back",
                icon = "fas fa-sign-in-alt",
                description = "",
                arrow = false,
                event = 'uwucafe:foodmenu',
            },
        }
    })
    lib.showContext('uwucafe_foodmenu')
end)

RegisterNetEvent('uwucafe:uwumeallssss')
AddEventHandler('uwucafe:uwumeallssss', function()
    lib.registerContext({
        id = 'uwucafe_mealsmenu',
        title = "Food Menu",
        icon = "",
        options = {
            {
                title = "UwU Box 1",
                description = "Requirments: 10x UwU Soup & 10x Milk Tea",
                arrow = false,
                event = 'uwucafe:meal1',
            },
            {
                title = "UwU Box 2",
                description = "Requirments: 10x UwU Ramen or 10x Frappe",
                arrow = false,
                event = 'uwucafe:meal2',
            },
            {
                title = "Go Back",
                icon = "fas fa-sign-in-alt",
                description = "",
                arrow = false,
                event = 'uwucafe:foodmenu',
            },
        }
    })
    lib.showContext('uwucafe_mealsmenu')
end)

RegisterNetEvent("uwucafe:meal1")
AddEventHandler("uwucafe:meal1", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
            exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_meal1')
end)

RegisterNetEvent("uwucafe:meal2")
AddEventHandler("uwucafe:meal2", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
            exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_meal2')
end)


RegisterNetEvent("uwucafe:soup")
AddEventHandler("uwucafe:soup", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
            exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_soup')
end)

RegisterNetEvent("uwucafe:ramen")
AddEventHandler("uwucafe:ramen", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
			exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_ramen')
end)

RegisterNetEvent("uwucafe:doughnut")
AddEventHandler("uwucafe:doughnut", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
			exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_doughnut')
end)

RegisterNetEvent("uwucafe:donut")
AddEventHandler("uwucafe:donut", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
			exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_donut')
end)



--DRINKS

exports.ox_target:addBoxZone({
    coords = vec3(-586.88, -1061.99, 22.87),
    size = vec3(1, 1, 1),
    rotation = 45,
    debug = drawZones,
    options = {
        {
            name = 'box',
            event = 'uwucafe:coffeemenu',
            icon = '',
            label = 'Coffee Menu',
            groups = {['uwu'] = 0},
        }
    }
})

RegisterNetEvent('uwucafe:coffeemenu')
AddEventHandler('uwucafe:coffeemenu', function()
    lib.registerContext({
        id = 'uwucoffee_menu',
        title = "Coffee Menu",
        options = {
            {
                title = "Milk Tea",
                description = "Requirments: 5x Grapes & 5x Mango",
                arrow = false,
                event = 'uwucafe:milktea',
            },
            {
                title = "Frappe",
                description = "Requirments: 5x Grapes & 5x Mango",
                arrow = false,
                event = 'uwucafe:frappe',
            },
            {
                title = "Yogart",
                description = "Requirments: 5x Grapes & 5x Mango",
                arrow = false,
                event = 'uwucafe:yogart',
            },
        }
    })
    lib.showContext('uwucoffee_menu')
end)

RegisterNetEvent("uwucafe:milktea")
AddEventHandler("uwucafe:milktea", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
			exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_milktea')
end)

RegisterNetEvent("uwucafe:frappe")
AddEventHandler("uwucafe:frappe", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
			exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_frappe')
end)

RegisterNetEvent("uwucafe:yogart")
AddEventHandler("uwucafe:yogart", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@business@coc@coc_unpack_cut@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

	for i = 1, 3, 1 do
		local finished = exports['cfx-hu-skillbar']:taskBar(2000, math.random(1, 5))
        if finished <= 0 then
			exports['notification']:DoHudText('error', 'You Failed.')
          ClearPedTasks(PlayerPedId())
          isBusy = false
          return
        end 
    end

	ClearPedTasks(PlayerPedId())
	isBusy = false
	CraftBusinessItem('uwu_yogart')
end)

local sheshkadong = 2800 -- 
local mayginagawapa = false

RegisterNetEvent("cfx-hu-business:uwumeal1")
AddEventHandler("cfx-hu-business:uwumeal1", function()
    if not mayginagawapa then
	    mayginagawapa = true
	    playAnim('mp_arresting', 'a_uncuff', 2800)
        exports.rprogress:Start('Using Uwu Meal', sheshkadong)
	    ClearPedTasks(PlayerPedId())
        exports.rprogress:Stop()
        CraftBusinessItem('uwu_unpack_meal1')
        mayginagawapa = false
    end
end) 

RegisterNetEvent("cfx-hu-business:uwumeal2")
AddEventHandler("cfx-hu-business:uwumeal2", function()
    if not mayginagawapa then
	    mayginagawapa = true
	    playAnim('mp_arresting', 'a_uncuff', 2800)
        exports.rprogress:Start('Using Uwu Meal', sheshkadong)
	    ClearPedTasks(PlayerPedId())
        exports.rprogress:Stop()
        CraftBusinessItem('uwu_unpack_meal2')
        mayginagawapa = false
    end
end)

loadDict = function(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end

function playAnim(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Citizen.Wait(0) end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1.0, duration, 49, 1, false, false, false)
    RemoveAnimDict(animDict)
  end
