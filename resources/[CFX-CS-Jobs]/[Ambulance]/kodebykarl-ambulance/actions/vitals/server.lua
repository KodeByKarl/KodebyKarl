local menu = require 'shared.menu'
local helpers = require 'helpers.game'
local Vars = require 'helpers.vars'

local function FormatSentry(xPlayer, xTarget, targetId)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR VITALS SYSTEM'),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('targetId Provided: %s'):format(targetId),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(text, ' | ')
end


local function ValidateVitals(xPlayer, xTarget, targetId)
    if not xPlayer or not xTarget then
        return false, 'INVALID PLAYER OR TARGET'
    end
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    if targetId == -1 then
        return false, 'INVALID TARGET ID'
    end
    if not helpers.HasJob(menu.vitals.access, xPlayer) then
        return false, 'INVALID JOB'
    end
    if #(playerCoords - targetCoords) > 5.0 then
        return false, 'DISTANCE CHECK'
    end
    return true
end

local function VitalsLogs(xPlayer, pulseResult, areaResult, bloodResult, currentBleeding)
    local log = {
        ('MEDICAL RESULT FOR %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Pulse: %s'):format(pulseResult),
        ('Hurt Area: %s'):format(areaResult),
        ('Blood: %s'):format(bloodResult),
        ('Bleeding: %s'):format(currentBleeding),
    }
    return table.concat(log, ' | ')
end

RegisterNetEvent('cfx-keydi-ambulance:VitalsTarget', function(playerId)
    local targetId = tonumber(playerId)
    if not targetId or targetId == -1 then return end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end
    local success, reason = ValidateVitals(xPlayer, xTarget, targetId)
    if not success then
        lib.logger(xPlayer.source, 'cfx-keydi-sentry', FormatSentry(xPlayer, xTarget, targetId), 'ERROR')
        print(("^0[^3cfx-keydi-ambulance^0] [VITALS]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        -- DropPlayer(xPlayer.source, ('%s: %s'):format('cfx-keydi-ambulance-vitals', reason))
        return
    end
    ESX.TriggerClientCallback(xTarget.source, "cfx-keydi-ambulance:requestTargetVitals", function(result)
        local currentBleeding
        if Vars.bleedingData[result.bleeding] then
            currentBleeding = Vars.bleedingData[result.bleeding]
        end
        lib.logger(xTarget.source, 'cfx-keydi-ambulance-vitals', VitalsLogs(xTarget, result.pulse, result.area, result.blood, currentBleeding))
        TriggerClientEvent('cfx-keydi-ambulance:showResult', xPlayer.source, result, xTarget.getName and xTarget.getName() or xTarget.name, xTarget.source)
    end)
end)