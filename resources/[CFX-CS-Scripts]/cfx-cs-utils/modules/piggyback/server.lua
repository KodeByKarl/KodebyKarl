local Vars = require 'helpers.vars'

local function FormatSentry(xPlayer, xTarget, targetSrc)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR PIGGYBACK SYSTEM'),
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
	if Vars.piggybacking[xPlayer.source] then
		return false, 'ADVANCED CHECK'
	end
	return true
end


RegisterNetEvent("cfx-cs-utils:Piggyback:Sync", function(targetSrc)
	local src = source
	if Vars.beingPiggybacked[src] and Vars.piggybacking[targetSrc] then return end
	local xPlayer = ESX.GetPlayerFromId(src)
	local xTarget = ESX.GetPlayerFromId(targetSrc)
	local success, reason = ValidateCarry(xPlayer, xTarget, targetSrc)
	if not success then
		lib.logger(src, 'cfx-cs-sentry', FormatSentry(xPlayer, xTarget, targetSrc), 'ERROR')
        print(("^0[^3cfx-cs-utils^0] [PIGGYBACK]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        -- DropPlayer(xPlayer.source, ('%s: %s'):format('cfx-cs-utils-piggyback', reason))
		return
	end
	TriggerClientEvent("cfx-cs-utils:Piggyback:syncTarget", targetSrc, src)
	Vars.piggybacking[src] = targetSrc
	Vars.beingPiggybacked[targetSrc] = src
end)

RegisterNetEvent("cfx-cs-utils:Piggyback:Stop", function(targetSrc)
	local src = source
	if Vars.piggybacking[src] then
		TriggerClientEvent("cfx-cs-utils:Piggyback:Stop", targetSrc)
		Vars.piggybacking[src] = nil
		Vars.beingPiggybacked[targetSrc] = nil
	elseif Vars.beingPiggybacked[src] then
		TriggerClientEvent("cfx-cs-utils:Piggyback:Stop", Vars.beingPiggybacked[src])
		Vars.beingPiggybacked[src] = nil
		Vars.piggybacking[Vars.beingPiggybacked[src]] = nil
	end
end)