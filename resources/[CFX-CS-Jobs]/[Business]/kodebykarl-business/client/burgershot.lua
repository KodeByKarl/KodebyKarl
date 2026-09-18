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

exports.qtarget:AddBoxZone("FoodsMenuu", vector3(-1196.11, -900.01, 13.89), 0.95, 2.55, {
	name="FoodsMenuu",
	heading=344,
	debugPoly=false,
	minZ=12.54,
	maxZ=14.64,
	}, {
		options = {
			{
				event = "bshot:cookfoods",
				icon = "fa-solid fa-kitchen-set",
				label = "Foods Menu",
				job = {['burgershot'] = 0},
			},
		},
		distance = 2.5
})


RegisterNetEvent('bshot:cookfoods')
AddEventHandler('bshot:cookfoods', function()
    lib.registerContext({
        id = 'bshot_foodmenu',
        title = "Food Menu",
        icon = "",
        options = {
            {
                title = "🍔 Classic Burger",
                description = "Requirments: 5x Food Ingredients",
                arrow = false,
                event = 'bshot:classicburger',
            },
            {
                title = "🍔 Cheesy Burger",
                description = "Requirments: 5x Food Ingredients",
                arrow = false,
                event = 'bshot:cheesyburger',
            },
        }
    })
    lib.showContext('bshot_foodmenu')
end)

RegisterNetEvent("bshot:classicburger")
AddEventHandler("bshot:classicburger", function(items)
    local ped = PlayerPedId()
    lib.requestAnimDict('anim@amb@business@coc@coc_unpack_cut@', 100)
	TaskPlayAnim(ped, 'anim@amb@business@coc@coc_unpack_cut@', 'fullcut_cycle_v6_cokecutter', 1.0, -1.0, -1, 49, 1, false, false, false)  

	local success = lib.skillCheck({'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})

	if success then
	    CraftBusinessItem('bshot_classic')
        ClearPedTasks(ped)
    else
        TriggerEvent('ox_lib:notify', { title = 'SYSTEM', description = 'You Failed', position = 'center-left', type = 'error', duration = 5000 })
        ClearPedTasks(ped)
    end	
end)


RegisterNetEvent("bshot:cheesyburger")
AddEventHandler("bshot:cheesyburger", function(items)
    local ped = PlayerPedId()
    lib.requestAnimDict('anim@amb@business@coc@coc_unpack_cut@', 100)
	TaskPlayAnim(ped, 'anim@amb@business@coc@coc_unpack_cut@', 'fullcut_cycle_v6_cokecutter', 1.0, -1.0, -1, 49, 1, false, false, false)  

	local success = lib.skillCheck({'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})

	if success then
	    CraftBusinessItem('bshot_cheesy')
        ClearPedTasks(ped)
    else
        TriggerEvent('ox_lib:notify', { title = 'SYSTEM', description = 'You Failed', position = 'center-left', type = 'error', duration = 5000 })
        ClearPedTasks(ped)
    end	
end)


exports.qtarget:AddBoxZone("DrinksMenuu", vector3(-1190.67, -899.18, 13.89), 2.6, 1.25, {
	name="DrinksMenuu",
	heading=304,
	debugPoly=false,
	minZ=12.29,
	maxZ=14.69,
	}, {
		options = {
			{
				event = "bshot:makedrinks",
				icon = "fa-solid fa-bottle-droplet",
				label = "Drinks Menu",
				job = {['burgershot'] = 0},
			},
		},
		distance = 2.5
})

RegisterNetEvent('bshot:makedrinks')
AddEventHandler('bshot:makedrinks', function()
    lib.registerContext({
        id = 'bshot_drinkmenu',
        title = "Drinks Menu",
        icon = "",
        options = {
            {
                title = "🥤 Cola",
                description = "Requirments: 5x Food Ingredients",
                arrow = false,
                event = 'bshot:cocacola',
            },
            {
                title = "🥤 Mountain Dew",
                description = "Requirments: 5x Food Ingredients",
                arrow = false,
                event = 'bshot:dew',
            },
        }
    })
    lib.showContext('bshot_drinkmenu')
end)

RegisterNetEvent("bshot:cocacola")
AddEventHandler("bshot:cocacola", function(items)
    local ped = PlayerPedId()
    lib.requestAnimDict('anim@mp_player_intupperspray_champagne', 100)
	TaskPlayAnim(ped, 'anim@mp_player_intupperspray_champagne', 'idle_a', 1.0, -1.0, -1, 49, 1, false, false, false)  

	local success = lib.skillCheck({'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})

	if success then
	    CraftBusinessItem('bshot_cola')
        ClearPedTasks(ped)
    else
        TriggerEvent('ox_lib:notify', { title = 'SYSTEM', description = 'You Failed', position = 'center-left', type = 'error', duration = 5000 })
        ClearPedTasks(ped)
    end	
end)

RegisterNetEvent("bshot:dew")
AddEventHandler("bshot:dew", function(items)
    local ped = PlayerPedId()
    lib.requestAnimDict('anim@mp_player_intupperspray_champagne', 100)
	TaskPlayAnim(ped, 'anim@mp_player_intupperspray_champagne', 'idle_a', 1.0, -1.0, -1, 49, 1, false, false, false)  

	local success = lib.skillCheck({'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'}, {'w', 'a', 's', 'd'})

	if success then
	    CraftBusinessItem('bshot_dew')
        ClearPedTasks(ped)
    else
        TriggerEvent('ox_lib:notify', { title = 'SYSTEM', description = 'You Failed', position = 'center-left', type = 'error', duration = 5000 })
        ClearPedTasks(ped)
    end	
end)