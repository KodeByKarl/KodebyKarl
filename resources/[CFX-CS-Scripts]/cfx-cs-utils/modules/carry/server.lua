local Vars = require 'helpers.vars'

local function FormatSentry(xPlayer, xTarget, targetSrc)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR CARRY SYSTEM'),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('playerId Provided: %s'):format(targetSrc),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(text, ' | ')
end

local function ValidateCarry(xPlayer, xTarget, targetSrc)
	local sourceCoords = xPlayer.getCoords(true)
	local targetCoords = xTarget.getCoords(true)
	if targetSrc == -1 then
		return false, 'ALL PLAYERS CHECK'
	end
	if #(sourceCoords - targetCoords) > 5.0 then
		return false, 'DISTANCE CHECK'
	end
	if Vars.carrying[xPlayer.source] then
		return false, 'ADVANCED CHECK'
	end
	return true
end

RegisterNetEvent("cfx-cs-utils:Carry:Sync", function(targetSrc)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local xTarget = ESX.GetPlayerFromId(targetSrc)
	if Vars.carried[src] and Vars.carrying[targetSrc] then return end
	local success, reason = ValidateCarry(xPlayer, xTarget, targetSrc)
	if not success then
		lib.logger(src, 'cfx-cs-sentry', FormatSentry(xPlayer, xTarget, targetSrc), 'ERROR')
        print(("^0[^3cfx-cs-utils^0] [CARRY]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        -- DropPlayer(xPlayer.source, ('%s: %s'):format('cfx-cs-utils-carry', reason))
		return
	end
	TriggerClientEvent("cfx-cs-utils:Carry:SyncTarget", targetSrc, src)
	Vars.carrying[src] = targetSrc
	Vars.carried[targetSrc] = src
end)

RegisterNetEvent("cfx-cs-utils:Carry:Stop", function(targetSrc)
	local src = source
	if Vars.carrying[src] then
		TriggerClientEvent("cfx-cs-utils:Carry:Stop", targetSrc)
		Vars.carrying[src] = nil
		Vars.carried[targetSrc] = nil
	elseif Vars.carried[src] then
		TriggerClientEvent("cfx-cs-utils:Carry:Stop", Vars.carried[src])
		Vars.carrying[Vars.carried[src]] = nil
		Vars.carried[src] = nil
	end
end)