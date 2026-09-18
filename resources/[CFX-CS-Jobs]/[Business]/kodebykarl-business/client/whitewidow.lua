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

exports.ox_target:addBoxZone({
    coords = vec3(164.32, -233.35, 50.07),
    size = vec3(1, 1, 1),
    rotation = 50,
    debug = drawZones,
    options = {
        {
            name = 'box',
            event = 'whitewidow:getstock',
            icon = '',
            label = 'White Widow Menu',
			groups = {['whitewidow'] = 1}
        }
    }
})

RegisterNetEvent('whitewidow:getstock')
AddEventHandler('whitewidow:getstock', function()
    lib.registerContext({
        id = 'whitewidow_menu',
        title = "Digital Den Menu",
        options = {
            {
                title = "Cannabis Pill",
                description = "REQUIRMENTS: 5X Whitewidow Ingredients",
                arrow = false,
                event = 'whitewidow:cannabis',
            },
        }
    })
    lib.showContext('whitewidow_menu')
end)

RegisterNetEvent("whitewidow:cannabis")
AddEventHandler("whitewidow:cannabis", function(items)
	isBusy = true
	ClearPedTasks(PlayerPedId())
	loadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") 
	TaskPlayAnim(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0, 1.0, -1, 49, 0, 0, 0, 0)  

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
	CraftBusinessItem('widow_cannabis')
end)

loadDict = function(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end