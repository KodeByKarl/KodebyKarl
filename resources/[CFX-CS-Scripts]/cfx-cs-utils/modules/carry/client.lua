local carry = require 'configs.carry'
local Vars = require 'helpers.vars'

RegisterCommand("carry",function()
	if cache.vehicle then return end
	if Vars.isDead then return ESX.Notify('CARRY', 'You are dead.', 'error', 5000) end
	-- if carry._type == "beingcarried" then return ESX.Notify('CARRY', 'tanga kaba?', 'error', 5000) end
	if not carry.IsCarrying then
		if Vars.isCarrying then return end
		if cache.weapon then return ESX.Notify('CARRY', 'You have a gun in your hand.', 'error', 5000) end
		local coords = GetEntityCoords(cache.ped)
		local playerId, playerPed = lib.getClosestPlayer(coords, 2.5, false)
		if playerId then
			local target = GetPlayerServerId(playerId)
			if target ~= -1 then
				if Player(target).state.escorted then return end
				Vars.isCarrying = true
				carry.IsCarrying = true
				carry.targetId = target
				TriggerServerEvent("cfx-cs-utils:Carry:Sync", target)
				lib.requestAnimDict(carry.sourceAnim.animDict, 10000)
				carry._type = "carrying"
			else
				ESX.Notify('CARRY', 'No nearby player.', 'error', 5000)
			end
		else
			ESX.Notify('CARRY', 'No nearby player.', 'error', 5000)
		end
	else
		Vars.isCarrying = false
		carry.IsCarrying = false
		ClearPedSecondaryTask(cache.ped)
		DetachEntity(cache.ped, true, false)
		TriggerServerEvent("cfx-cs-utils:Carry:Stop", carry.targetId)
		carry.targetId = 0
	end
end, false)

RegisterNetEvent("cfx-cs-utils:Carry:SyncTarget", function(targetSrc)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
	carry.IsCarrying = true
	lib.requestAnimDict(carry.targetAnim.animDict, 10000)
	AttachEntityToEntity(cache.ped, targetPed, 0, carry.targetAnim.attachX, carry.targetAnim.attachY, carry.targetAnim.attachZ, 0.5, 0.5, 180, false, false, false, false, 2, false)
	carry._type = "beingcarried"
end)

RegisterNetEvent("cfx-cs-utils:Carry:Stop", function()
	carry.IsCarrying = false
	ClearPedSecondaryTask(cache.ped)
	DetachEntity(cache.ped, true, false)
	carry._type = ''
end)

CreateThread(function()
	while true do
		local sleep = 500
		if carry.IsCarrying then
			sleep = 0
			if carry._type == "beingcarried" then
				if not IsEntityPlayingAnim(cache.ped, carry.targetAnim.animDict, carry.targetAnim.anim, 3) then
					TaskPlayAnim(cache.ped, carry.targetAnim.animDict, carry.targetAnim.anim, 8.0, -8.0, 100000, carry.targetAnim.flag, 0, false, false, false)
				end
			elseif carry._type == "carrying" then
				if not IsEntityPlayingAnim(cache.ped, carry.sourceAnim.animDict, carry.sourceAnim.anim, 3) then
					TaskPlayAnim(cache.ped, carry.sourceAnim.animDict, carry.sourceAnim.anim, 8.0, -8.0, 100000, carry.sourceAnim.flag, 0, false, false, false)
				end
			end
		end
		Wait(sleep)
	end
end)