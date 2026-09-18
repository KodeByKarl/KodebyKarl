ESX = exports["es_extended"]:getSharedObject()

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

exports.qtarget:AddBoxZone("PharmacyMenu", vector3(-482.76, -1012.3, 24.29), 0.8, 5.8, {
	name="PharmacyMenu",
	heading=0,
	debugPoly=false,
	minZ=22.89,
	maxZ=25.09,
	}, {
		options = {
			{
				event = "pharma:getstock",
				icon = "fas fa-pills",
				label = "Pharmacy Menu",
				job = {['uwu'] = 3},
			},
		},
		distance = 2.5
})


RegisterNetEvent('pharma:getstock')
AddEventHandler('pharma:getstock', function()
    lib.registerContext({
        id = 'pharma_stocks',
        title = "Pharmacy Menu",
        options = {
            {
                title = "💊 Stress Tabs",
                description = "Get 5x StressTabs",
                arrow = false,
                event = 'pharma:stresstabs',
            },
            {
                title = "🩹 Bandage",
                description = "Get 5x Bandage",
                arrow = false,
                event = 'pharma:bandage',
            },
            {
                title = "🩹 Gauze",
                description = "Get 5x Gauze",
                arrow = false,
                event = 'pharma:gauze',
            },
            {
                title = "🩹 Medkit",
                description = "Get 5x Medkit",
                arrow = false,
                event = 'pharma:medkit',
            },
        }
    })
    lib.showContext('pharma_stocks')
end)


RegisterNetEvent('pharma:stresstabs')
AddEventHandler('pharma:stresstabs', function()
    loadDict("amb@prop_human_movie_bulb@idle_a")
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_movie_bulb@idle_a", "idle_b",  1.0, -1.0, -1, 49, 0, false, false, false)
    local finished = exports["cfx-hu-skillbar"]:taskBar(2000, math.random(5, 7))
    if finished <= 0 then
        exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
    local finished = exports["cfx-hu-skillbar"]:taskBar(1500, math.random(5, 7))
    if finished <= 0 then
		exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
	local finished = exports["cfx-hu-skillbar"]:taskBar(2000, math.random(5, 7))
    if finished <= 0 then
		exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
    ClearPedTasks(PlayerPedId())
    CraftBusinessItem('pharma_stresstabs')
end)

RegisterNetEvent('pharma:bandage')
AddEventHandler('pharma:bandage', function()
    loadDict("amb@prop_human_movie_bulb@idle_a")
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_movie_bulb@idle_a", "idle_b",  1.0, -1.0, -1, 49, 0, false, false, false)
    local finished = exports["cfx-hu-skillbar"]:taskBar(2000, math.random(5, 7))
    if finished <= 0 then
        exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
    local finished = exports["cfx-hu-skillbar"]:taskBar(1500, math.random(5, 7))
    if finished <= 0 then
		exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
	local finished = exports["cfx-hu-skillbar"]:taskBar(2000, math.random(5, 7))
    if finished <= 0 then
		exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
    ClearPedTasks(PlayerPedId())
    CraftBusinessItem('pharma_bandage')
end)

RegisterNetEvent('pharma:gauze')
AddEventHandler('pharma:gauze', function()
    loadDict("amb@prop_human_movie_bulb@idle_a")
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_movie_bulb@idle_a", "idle_b",  1.0, -1.0, -1, 49, 0, false, false, false)
    local finished = exports["cfx-hu-skillbar"]:taskBar(2000, math.random(5, 7))
    if finished <= 0 then
        exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
    local finished = exports["cfx-hu-skillbar"]:taskBar(1500, math.random(5, 7))
    if finished <= 0 then
		exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
	local finished = exports["cfx-hu-skillbar"]:taskBar(2000, math.random(5, 7))
    if finished <= 0 then
		exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
    ClearPedTasks(PlayerPedId())
    CraftBusinessItem('pharma_gauze')
end)

RegisterNetEvent('pharma:medkit')
AddEventHandler('pharma:medkit', function()
    loadDict("amb@prop_human_movie_bulb@idle_a")
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_movie_bulb@idle_a", "idle_b",  1.0, -1.0, -1, 49, 0, false, false, false)
    local finished = exports["cfx-hu-skillbar"]:taskBar(2000, math.random(5, 7))
    if finished <= 0 then
        exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
    local finished = exports["cfx-hu-skillbar"]:taskBar(1500, math.random(5, 7))
    if finished <= 0 then
		exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
	local finished = exports["cfx-hu-skillbar"]:taskBar(2000, math.random(5, 7))
    if finished <= 0 then
		exports['notification']:DoHudText('error', 'You Failed.')
        ClearPedTasksImmediately(PlayerPedId())
        return
    end
    ClearPedTasks(PlayerPedId())
    CraftBusinessItem('pharma_medikit')
end)

loadDict = function(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end
