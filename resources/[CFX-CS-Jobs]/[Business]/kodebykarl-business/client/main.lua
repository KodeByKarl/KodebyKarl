local ox_inventory = exports.ox_inventory

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

CreateThread(function()
    while true do
        local sleep = 500
        local coords = GetEntityCoords(cache.ped)
        if ESX.PlayerLoaded then
            for i = 1, #Config.Business do
                local trayData = Config.Business[i].Tray
                if trayData then
                    for tray = 1, #trayData do
                        local t = trayData[tray]
                        if t and t.leftinv and t.rightinv then
                            local ltdist = #(coords - t.leftinv)
                            local rtdist = #(coords - t.rightinv)
                            if ltdist <= 0.9 then
                                sleep = 0
                                ESX.DrawText3D(t.leftinv.x, t.leftinv.y, t.leftinv.z, '[~b~E~w~] Tray')
                                if IsControlJustReleased(0, 38) then
                                    ox_inventory:openInventory('stash', t.id)
                                    break
                                end
                            elseif ltdist <= 1.8 then
                                sleep = 0
                                ESX.DrawMarker(t.leftinv, 255, 255, 255, 255)
                            end
                            if rtdist <= 0.9 then
                                sleep = 0
                                ESX.DrawText3D(t.rightinv.x, t.rightinv.y, t.rightinv.z, '[~b~E~w~] Tray')
                                if IsControlJustReleased(0, 38) then
                                    ox_inventory:openInventory('stash', t.id)
                                    break
                                end
                            elseif rtdist <= 1.8 then
                                sleep = 0
                                ESX.DrawMarker(t.rightinv, 255, 255, 255, 255)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand('asdawdacdw', function()
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'hdlc' then
    	TriggerEvent('cfx-hu-business:hdlcbillmenu')
	end
end, false)

RegisterKeyMapping('asdawdacdw', 'HDLC Bill Menu', 'keyboard', 'f6')

RegisterNetEvent('cfx-hu-business:hdlcbillmenu')
AddEventHandler('cfx-hu-business:hdlcbillmenu', function()
    lib.registerContext({
        id = 'hdlc_billmenu',
        title = "HDLC Actions",
		icon = "fa-solid fa-file-invoice",
        options = {
			{
                title = "Billing",
                description = "Bill Customer",
                arrow = false,
                event = 'cfx-hu-business:hdlcbilling',
            },
        }
    })
    lib.showContext('hdlc_billmenu')
end)

RegisterNetEvent('cfx-hu-business:hdlcbilling')
AddEventHandler('cfx-hu-business:hdlcbilling', function()
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	if closestPlayer == -1 or closestDistance > 3.0 then
        lib.notify({title = 'BUSINESS', description = 'no players nearby!', type = 'error', duration = 5000})
	else
		ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
			title = 'Bill Amount'
		}, function(data, menu)
			local amount = tonumber(data.value)
			if amount == nil or amount < 0 then
                lib.notify({title = 'BUSINESS', description = 'Invalid Amount!', type = 'error', duration = 5000})
			else
				menu.close()
				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
					title = 'Bill label'
				}, function(data2, menu2)
					menu2.close()
					if data2.value == nil or data2.value == '' then
						data2.value = 'HDLC'
					end
					TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_hdlc', data2.value, amount)
				end, function(data2, menu2)
					menu2.close()
				end)
			end
		end, function(data, menu)
			menu.close()
		end)
	end
end)
