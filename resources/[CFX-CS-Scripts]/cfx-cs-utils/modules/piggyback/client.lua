local piggyback = require 'configs.piggyback'
local Vars = require 'helpers.vars'


RegisterCommand("piggyback",function()
	if cache.vehicle then return end
	-- if piggyback.type == "beingPiggybacked" then return ESX.Notify('PIGGYBACK', 'tanga kaba?', 'error', 5000) end
	if not piggyback.InProgress then
		if Vars.isCarrying then return end
		if cache.weapon then return ESX.Notify('PIGGYBACK', 'You have a gun in your hand.', 'error', 5000) end
		local coords = GetEntityCoords(cache.ped)
		local closestPlayer = lib.getClosestPlayer(coords, 2.5, false)
		if closestPlayer then
			local targetSrc = GetPlayerServerId(closestPlayer)
			if targetSrc ~= -1 then
				if Player(targetSrc).state.escorted then return end
				Vars.isCarrying = true
				piggyback.InProgress = true
				piggyback.targetSrc = targetSrc
				TriggerServerEvent("cfx-cs-utils:Piggyback:Sync",targetSrc)
				lib.requestAnimDict(piggyback.personPiggybacking.animDict, 10000)
				piggyback.type = "piggybacking"
			else
				ESX.Notify('PIGGYBACK', 'No nearby player.', 'error', 5000)
			end
		else
            ESX.Notify('PIGGYBACK', 'No nearby player.', 'error', 5000)
		end
	else
		Vars.isCarrying = false
		piggyback.InProgress = false
		ClearPedSecondaryTask(cache.ped)
		DetachEntity(cache.ped, true, false)
		TriggerServerEvent("cfx-cs-utils:Piggyback:Stop",piggyback.targetSrc)
		piggyback.targetSrc = 0
	end
end,false)

RegisterNetEvent("cfx-cs-utils:Piggyback:syncTarget", function(targetSrc)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
	piggyback.InProgress = true
	lib.requestAnimDict(piggyback.personBeingPiggybacked.animDict, 10000)
	AttachEntityToEntity(cache.ped, targetPed, 0, piggyback.personBeingPiggybacked.attachX, piggyback.personBeingPiggybacked.attachY, piggyback.personBeingPiggybacked.attachZ, 0.5, 0.5, 180, false, false, false, false, 2, false)
	piggyback.type = "beingPiggybacked"
end)

RegisterNetEvent("cfx-cs-utils:Piggyback:Stop", function()
	piggyback.InProgress = false
	ClearPedSecondaryTask(cache.ped)
	DetachEntity(cache.ped, true, false)
	piggyback.type = ''
end)

CreateThread(function()
	while true do
        local sleep = 500
		if piggyback.InProgress then
            sleep = 0
			if piggyback.type == "beingPiggybacked" then
				if not IsEntityPlayingAnim(cache.ped, piggyback.personBeingPiggybacked.animDict, piggyback.personBeingPiggybacked.anim, 3) then
					TaskPlayAnim(cache.ped, piggyback.personBeingPiggybacked.animDict, piggyback.personBeingPiggybacked.anim, 8.0, -8.0, 100000, piggyback.personBeingPiggybacked.flag, 0, false, false, false)
				end
			elseif piggyback.type == "piggybacking" then
				if not IsEntityPlayingAnim(cache.ped, piggyback.personPiggybacking.animDict, piggyback.personPiggybacking.anim, 3) then
					TaskPlayAnim(cache.ped, piggyback.personPiggybacking.animDict, piggyback.personPiggybacking.anim, 8.0, -8.0, 100000, piggyback.personPiggybacking.flag, 0, false, false, false)
				end
			end
		end
        Wait(sleep)
	end
end)