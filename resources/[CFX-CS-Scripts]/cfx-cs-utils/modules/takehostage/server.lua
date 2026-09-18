local Vars = require 'helpers.vars'
local takeHostage = require 'configs.takehostage'
if not takeHostage.enable then return end


local function FormatSentry(xPlayer, xTarget, targetSrc)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR TAKE HOSTAGE'),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('playerId Provided: %s'):format(targetSrc),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(text, ' | ')
end


local function ValidateTakehostage(xPlayer, xTarget, targetSrc)
	local sourceCoords = xPlayer.getCoords(true)
	local targetCoords = xTarget.getCoords(true)
	if targetSrc == -1 then
		return false, 'ALL PLAYERS CHECK'
	end
	if #(sourceCoords - targetCoords) > 3.0 then
		return false, 'DISTANCE CHECK'
	end
	if Vars.takingHostage[xPlayer.source] then
		return false, 'ADVANCED CHECK'
	end
	return true
end

RegisterNetEvent("TakeHostage:sync", function(targetSrc)
	local src = source
	if targetSrc == -1 then return end
	local xPlayer = ESX.GetPlayerFromId(src)
	local xTarget = ESX.GetPlayerFromId(targetSrc)
	if Vars.takenHostage[src] and Vars.takingHostage[targetSrc] then return end
	local success, reason = ValidateTakehostage(xPlayer, xTarget, targetSrc)
	if not success then
		lib.logger(src, 'cfx-keydi-sentry', FormatSentry(xPlayer, xTarget, targetSrc), 'ERROR')
        print(("^0[^3cfx-keydi-utils^0] [TAKEHOSTAGE]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        -- DropPlayer(xPlayer.source, ('%s: %s'):format('cfx-keydi-utils-takehostage', reason))
		return
	end
	TriggerClientEvent("TakeHostage:syncTarget", targetSrc, src)
	Vars.takingHostage[src] = targetSrc
	Vars.takenHostage[targetSrc] = src
	lib.logger(xPlayer.source, 'take_hostage', xPlayer.name..' ['..xPlayer.source..'] take hostage '..xTarget.name..' ['..xTarget.source..']')
	lib.logger(xTarget.source, 'take_hostage', xPlayer.name..' ['..xPlayer.source..'] take hostage '..xTarget.name..' ['..xTarget.source..']')
end)

RegisterNetEvent("TakeHostage:releaseHostage", function(targetSrc)
	local src = source
	if targetSrc == -1 then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(targetSrc)
	local sourceCoords = xPlayer.getCoords(true)
	local targetCoords = xTarget.getCoords(true)
	if not Vars.takenHostage[targetSrc] or #(sourceCoords - targetCoords) > 3.0 or targetSrc == -1 then
		lib.logger(src, 'cfx-keydi-sentry', FormatSentry(xPlayer, xTarget, targetSrc), 'ERROR')
        print(("^0[^3cfx-keydi-utils^0] [TAKEHOSTAGE]: Validation failed for %s: %s"):format(xPlayer.name, 'ADVANCED CHECK'))
        -- DropPlayer(xPlayer.source, ('%s: %s'):format('cfx-keydi-utils-takehostage', 'ADVANCED CHECK'))
		return
	end
	TriggerClientEvent("TakeHostage:releaseHostage", targetSrc, src)
	Vars.takingHostage[src] = nil
	Vars.takenHostage[targetSrc] = nil
	lib.logger(xPlayer.source, 'take_hostage', 'hostage taker '..xPlayer.name..' ['..xPlayer.source..'] released '..xTarget.name..' ['..xTarget.source..']')
	lib.logger(xTarget.source, 'take_hostage', 'hostage taker '..xPlayer.name..' ['..xPlayer.source..'] released '..xTarget.name..' ['..xTarget.source..']')
end)

RegisterNetEvent("TakeHostage:killHostage", function(targetSrc)
	local src = source
	if targetSrc == -1 then return end
	local xPlayer = ESX.GetPlayerFromId(src)
	local xTarget = ESX.GetPlayerFromId(targetSrc)
	local sourceCoords = xPlayer.getCoords(true)
	local targetCoords = xTarget.getCoords(true)
	if not Vars.takenHostage[targetSrc] or #(sourceCoords - targetCoords) > 3.0 or targetSrc == -1 then
		lib.logger(src, 'cfx-keydi-sentry', FormatSentry(xPlayer, xTarget, targetSrc), 'ERROR')
        print(("^0[^3cfx-keydi-utils^0] [TAKEHOSTAGE]: Validation failed for %s: %s"):format(xPlayer.name, 'ADVANCED CHECK'))
        -- DropPlayer(xPlayer.source, ('%s: %s'):format('cfx-keydi-utils-takehostage', 'ADVANCED CHECK'))
		return
	end
	TriggerClientEvent("TakeHostage:killHostage", targetSrc, src)
	Vars.takingHostage[src] = nil
	Vars.takenHostage[targetSrc] = nil
	lib.logger(xPlayer.source, 'take_hostage', 'hostage taker '..xPlayer.name..' ['..xPlayer.source..'] killed '..xTarget.name..' ['..xTarget.source..']')
	lib.logger(xTarget.source, 'take_hostage', 'hostage taker '..xPlayer.name..' ['..xPlayer.source..'] killed '..xTarget.name..' ['..xTarget.source..']')
end)

RegisterNetEvent("TakeHostage:stop", function(targetSrc)
	local source = source
	if Vars.takingHostage[source] then
		TriggerClientEvent("TakeHostage:cl_stop", targetSrc)
		Vars.takingHostage[source] = nil
		Vars.takenHostage[targetSrc] = nil
	elseif Vars.takenHostage[source] then
		TriggerClientEvent("TakeHostage:cl_stop", targetSrc)
		Vars.takenHostage[source] = nil
		Vars.takingHostage[targetSrc] = nil
	end
end)