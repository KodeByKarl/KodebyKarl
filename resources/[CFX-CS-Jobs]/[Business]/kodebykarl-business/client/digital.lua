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

exports.qtarget:AddBoxZone("DigitalDenMenu", vector3(382.8, -826.52, 29.31), 4.0, 1.8, {
	name="DigitalDenMenu",
	heading=0,
	debugPoly=false,
	minZ=27.51,
	maxZ=30.11,
	}, {
		options = {
			{
				event = "digitalden:getstock",
				icon = "fa-solid fa-store",
				label = "App Store Menu",
				job = {['digiden'] = 0},
			},
		},
		distance = 2.5
})

RegisterNetEvent('digitalden:getstock')
AddEventHandler('digitalden:getstock', function()
    lib.registerContext({
        id = 'digitalden_stocks',
        title = "Digital Den Menu",
        options = {
            {
                title = 'Phone',
				icon = 'fa-solid fa-mobile',
				iconColor = 'blue',
                description = "REQUIRMENTS: 5X WOOD",
                arrow = false,
                event = 'digitalden:phone',
            },
            {
                title = "Radio",
				icon = 'fa-solid fa-walkie-talkie',
				iconColor = 'green',
                description = "REQUIRMENTS: 5X WOOD",
                arrow = false,
                event = 'digitalden:radio',
            },
            {
                title = "Boombox",
				icon = 'fa-solid fa-radio',
				iconColor = 'gold',
                description = "REQUIRMENTS: 5X WOOD",
                arrow = false,
                event = 'digitalden:boombox',
            },
        }
    })
    lib.showContext('digitalden_stocks')
end)

RegisterNetEvent("digitalden:phone")
AddEventHandler("digitalden:phone", function(items)
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
	CraftBusinessItem('digiden_phone')
end)

RegisterNetEvent("digitalden:radio")
AddEventHandler("digitalden:radio", function(items)
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
	CraftBusinessItem('digiden_radio')
end)

RegisterNetEvent("digitalden:boombox")
AddEventHandler("digitalden:boombox", function(items)
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
	CraftBusinessItem('digiden_boombox')
end)


--// BILLING MENU //--

RegisterCommand('digibill', function()
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'digitalden' then
    	TriggerEvent('cfx-hu-business:digitalactionsmenu')
	end
end, false)

RegisterKeyMapping('digibill', 'Digital Den Bill Menu', 'keyboard', 'f6')

RegisterNetEvent('cfx-hu-business:digitalactionsmenu')
AddEventHandler('cfx-hu-business:digitalactionsmenu', function()
    lib.registerContext({
        id = 'digitalden_billmenu',
        title = "Digital Den Actions",
		icon = "fa-solid fa-file-invoice",
        options = {
			{
                title = "Billing",
                description = "Bill Customer",
                arrow = false,
                event = 'cfx-hu-business:digitalbilling',
            },
        }
    })
    lib.showContext('digitalden_billmenu')
end)

RegisterNetEvent('cfx-hu-business:digitalbilling')
AddEventHandler('cfx-hu-business:digitalbilling', function()
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	if closestPlayer == -1 or closestDistance > 3.0 then
        exports['notification']:DoHudText('error', 'no players nearby.')
	else
		ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
			title = 'Bill Amount'
		}, function(data, menu)
			local amount = tonumber(data.value)
			if amount == nil or amount < 0 then
                exports['notification']:DoHudText('error', 'Invalid Amount.')
			else
				menu.close()
				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
					title = 'Bill label'
				}, function(data2, menu2)
					menu2.close()
					if data2.value == nil or data2.value == '' then
						data2.value = 'Digital Den'
					end
					TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_digitalden', data2.value, amount)
				end, function(data2, menu2)
					menu2.close()
				end)
			end
		end, function(data, menu)
			menu.close()
		end)
	end
end)

loadDict = function(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end