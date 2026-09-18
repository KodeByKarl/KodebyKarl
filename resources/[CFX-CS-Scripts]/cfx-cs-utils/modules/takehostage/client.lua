local takeHostage = require 'configs.takehostage'
if not takeHostage.enable then return end

for k,v in pairs(takeHostage.commands) do
	RegisterCommand(v,function()
		callTakeHostage()
	end)
end

function callTakeHostage()
	if cache.vehicle then return end
	ClearPedSecondaryTask(cache.ped)
	DetachEntity(cache.ped, true, false)
	local canTakeHostage = false
	if cache.weapon and takeHostage.allowedWeapons[cache.weapon] then
		canTakeHostage = true 
		foundWeapon = takeHostage.allowedWeapons[cache.weapon]
	end
	if not canTakeHostage then 
		ESX.Notify('TAKE HOSTAGE', 'You need a pistol with ammo to take a hostage at gunpoint!', 'error', 5000)
		return
	end
	if not takeHostage.InProgress and canTakeHostage then			
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
			local targetSrc = GetPlayerServerId(closestPlayer)
			if targetSrc ~= -1 then
				SetCurrentPedWeapon(cache.ped, foundWeapon, true)
				takeHostage.InProgress = true
				takeHostage.targetSrc = targetSrc
				TriggerServerEvent("TakeHostage:sync", targetSrc)
				lib.requestAnimDict(takeHostage.agressor.animDict, 10000)
				takeHostage.type = "agressor"
			else
				ESX.Notify('TAKE HOSTAGE', 'No one nearby to take as hostage!', 'error', 5000)
			end
		else
			ESX.Notify('TAKE HOSTAGE', 'No one nearby to take as hostage!', 'error', 5000)
		end
	end
end 

RegisterNetEvent("TakeHostage:syncTarget")
AddEventHandler("TakeHostage:syncTarget", function(target)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
	takeHostage.InProgress = true
	lib.requestAnimDict(takeHostage.hostage.animDict, 10000)
	AttachEntityToEntity(cache.ped, targetPed, 0, takeHostage.hostage.attachX, takeHostage.hostage.attachY, takeHostage.hostage.attachZ, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
	takeHostage.type = "hostage" 
end)

RegisterNetEvent("TakeHostage:releaseHostage")
AddEventHandler("TakeHostage:releaseHostage", function()
	takeHostage.InProgress = false 
	takeHostage.type = ""
	DetachEntity(cache.ped, true, false)
	lib.requestAnimDict("reaction@shove", 10000)
	TaskPlayAnim(cache.ped, "reaction@shove", "shoved_back", 8.0, -8.0, -1, 0, 0, false, false, false)
	Wait(250)
	ClearPedSecondaryTask(cache.ped)
end)

RegisterNetEvent("TakeHostage:killHostage")
AddEventHandler("TakeHostage:killHostage", function()
	takeHostage.InProgress = false 
	takeHostage.type = ""
	SetEntityHealth(cache.ped,0)
	DetachEntity(cache.ped, true, false)
	lib.requestAnimDict("anim@gangops@hostage@", 10000)
	TaskPlayAnim(cache.ped, "anim@gangops@hostage@", "victim_fail", 8.0, -8.0, -1, 168, 0, false, false, false)
end)

RegisterNetEvent("TakeHostage:cl_stop")
AddEventHandler("TakeHostage:cl_stop", function()
	takeHostage.InProgress = false
	takeHostage.type = "" 
	ClearPedSecondaryTask(cache.ped)
	DetachEntity(cache.ped, true, false)
end)

CreateThread(function()
	while true do
		local sleep = 500
		if takeHostage.type == "agressor" then
			sleep = 0
			if not IsEntityPlayingAnim(cache.ped, takeHostage.agressor.animDict, takeHostage.agressor.anim, 3) then
				TaskPlayAnim(cache.ped, takeHostage.agressor.animDict, takeHostage.agressor.anim, 8.0, -8.0, 100000, takeHostage.agressor.flag, 0, false, false, false)
			end
		elseif takeHostage.type == "hostage" then
			sleep = 0
			if not IsEntityPlayingAnim(cache.ped, takeHostage.hostage.animDict, takeHostage.hostage.anim, 3) then
				TaskPlayAnim(cache.ped, takeHostage.hostage.animDict, takeHostage.hostage.anim, 8.0, -8.0, 100000, takeHostage.hostage.flag, 0, false, false, false)
			end
		end
		Wait(sleep)
	end
end)

CreateThread(function()
	local showingHostageUI = false
	while true do 
		local sleep = 500
		if takeHostage.type == "agressor" then
			sleep = 0
			DisableControlAction(0,24,true) -- disable attack
			DisableControlAction(0,25,true) -- disable aim
			DisableControlAction(0,47,true) -- disable weapon
			DisableControlAction(0,58,true) -- disable weapon
			DisableControlAction(0,21,true) -- disable sprint
			DisablePlayerFiring(cache.ped,true)

			if not showingHostageUI then
				lib.showTextUI('[G] Release  |  [H] Kill', {
					position = 'top-center',
					icon = 'gun'
				})
				showingHostageUI = true
			end

			if Player(cache.serverId).state.dead then	
				takeHostage.type = ""
				takeHostage.InProgress = false
				lib.requestAnimDict("reaction@shove")
				TaskPlayAnim(cache.ped, "reaction@shove", "shove_var_a", 8.0, -8.0, -1, 168, 0, false, false, false)
				TriggerServerEvent("TakeHostage:releaseHostage", takeHostage.targetSrc)
			end 
			if IsDisabledControlJustPressed(0,47) then -- release	
				takeHostage.type = ""
				takeHostage.InProgress = false 
				lib.requestAnimDict("reaction@shove")
				TaskPlayAnim(cache.ped, "reaction@shove", "shove_var_a", 8.0, -8.0, -1, 168, 0, false, false, false)
				TriggerServerEvent("TakeHostage:releaseHostage", takeHostage.targetSrc)
			elseif IsDisabledControlJustPressed(0,74) then -- kill 			
				takeHostage.type = ""
				takeHostage.InProgress = false 		
				lib.requestAnimDict("anim@gangops@hostage@")
				TaskPlayAnim(cache.ped, "anim@gangops@hostage@", "perp_fail", 8.0, -8.0, -1, 168, 0, false, false, false)
				TriggerServerEvent("TakeHostage:killHostage", takeHostage.targetSrc)
				TriggerServerEvent("TakeHostage:stop",takeHostage.targetSrc)
				Wait(100)
				SetPedShootsAtCoord(cache.ped, 0.0, 0.0, 0.0, 0)
			end
		elseif takeHostage.type == "hostage" then 
			sleep = 0
			DisableControlAction(0,21,true) -- disable sprint
			DisableControlAction(0,24,true) -- disable attack
			DisableControlAction(0,25,true) -- disable aim
			DisableControlAction(0,47,true) -- disable weapon
			DisableControlAction(0,58,true) -- disable weapon
			DisableControlAction(0,263,true) -- disable melee
			DisableControlAction(0,264,true) -- disable melee
			DisableControlAction(0,257,true) -- disable melee
			DisableControlAction(0,140,true) -- disable melee
			DisableControlAction(0,141,true) -- disable melee
			DisableControlAction(0,142,true) -- disable melee
			DisableControlAction(0,143,true) -- disable melee
			DisableControlAction(0,75,true) -- disable exit vehicle
			DisableControlAction(27,75,true) -- disable exit vehicle  
			DisableControlAction(0,22,true) -- disable jump
			DisableControlAction(0,32,true) -- disable move up
			DisableControlAction(0,268,true)
			DisableControlAction(0,33,true) -- disable move down
			DisableControlAction(0,269,true)
			DisableControlAction(0,34,true) -- disable move left
			DisableControlAction(0,270,true)
			DisableControlAction(0,35,true) -- disable move right
			DisableControlAction(0,271,true)
		else
			if showingHostageUI then
				lib.hideTextUI()
				showingHostageUI = false
			end
		end
		Wait(sleep)
	end
end)