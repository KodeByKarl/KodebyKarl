local menu = require 'shared.menu'
local helpers = require 'helpers.game'
local config = require 'shared.config'

local function sendBodybagBill(src, targetId)
    local bag = config.Bodybag or {}
    local amount = math.floor(tonumber(bag.bill) or 0)
    if amount <= 0 or not src or not targetId or src == targetId then
        return
    end

    local payload = {
        title = bag.title or 'BODYBAG',
        price = amount,
        description = bag.description or 'EMS body bag / remains transport',
        kind = 'job',
        autoAccept = bag.autoAccept ~= false,
    }

    local sent = false
    if GetResourceState('kodebykarl-ui') == 'started' then
        local ok, result = pcall(function()
            return exports['kodebykarl-ui']:CreateInvoice(src, targetId, payload)
        end)
        sent = ok and result and result.ok == true
    end
    if not sent and GetResourceState('cfx-keydi-ui') == 'started' then
        pcall(function()
            exports['cfx-keydi-ui']:CreateInvoice(src, targetId, payload)
        end)
    end
end

local function FormatSentry(xPlayer, xTarget, targetId)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR BODYBAG SYSTEM'),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('targetId Provided: %s'):format(targetId),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(text, ' | ')
end


local function BodybagLogs(xPlayer, xTarget)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local log = {
        ('BODYBAG INFORMATION'):format(),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(log, ' | ')
end


local function ValidateBodybag(xPlayer, xTarget, targetId)
    if not xPlayer or not xTarget then
        return false, 'INVALID PLAYER OR TARGET'
    end
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    if targetId == -1 then
        return false, 'INVALID TARGET ID'
    end
    if not helpers.HasJob(menu.bodybag.access, xPlayer) then
        return false, 'INVALID JOB'
    end
    if not Player(targetId).state.dead then
        return false, 'TARGET NOT DEAD'
    end
    if #(playerCoords - targetCoords) > 5.0 then
        return false, 'DISTANCE CHECK'
    end
    return true
end

RegisterNetEvent('cfx-keydi-ambulance:bodybagTarget', function(playerId)
    local targetId = tonumber(playerId)
    if not targetId or targetId == -1 then return end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end
    local success, reason = ValidateBodybag(xPlayer, xTarget, targetId)
    if not success then
        lib.logger(xPlayer.source, 'cfx-keydi-sentry', FormatSentry(xPlayer, xTarget, targetId), 'ERROR')
        print(("^0[^3cfx-keydi-ambulance^0] [BODYBAG]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        if AmbulanceLogs and AmbulanceLogs.Sentry then
            AmbulanceLogs.Sentry({
                system = 'BODYBAG',
                src = src,
                name = xPlayer and xPlayer.name,
                identifier = xPlayer and xPlayer.identifier,
                targetSrc = targetId,
                targetName = xTarget and xTarget.name,
                targetIdentifier = xTarget and xTarget.identifier,
                reason = reason,
                coords = xPlayer and xPlayer.getCoords(true),
                targetCoords = xTarget and xTarget.getCoords(true),
            })
        end
        return
    end
    lib.logger(xTarget.source, 'cfx-keydi-ambulance-bodybag', BodybagLogs(xPlayer, xTarget))
    TriggerClientEvent('cfx-keydi-ambulance:syncBodyBag', xTarget.source)
    sendBodybagBill(src, targetId)

    -- `provide 'cfx-keydi-ui'` does not alias exports — call kodebykarl-ui by real name
    if GetResourceState('kodebykarl-ui') == 'started' then
        pcall(function()
            exports['kodebykarl-ui']:JobTemplateWithoutID(
                xPlayer.job.name,
                ('%s is declared dead. Rest in Peace.'):format(xTarget.name)
            )
        end)
    end

    if AmbulanceLogs and AmbulanceLogs.Bodybag then
        local playerCoords = xPlayer.getCoords(true)
        local targetCoords = xTarget.getCoords(true)
        local job = xPlayer.job and (('%s — %s'):format(xPlayer.job.label or xPlayer.job.name, xPlayer.job.grade_label or '')) or nil
        AmbulanceLogs.Bodybag({
            src = src,
            name = xPlayer.name,
            identifier = xPlayer.identifier,
            job = job,
            targetSrc = targetId,
            targetName = xTarget.name,
            targetIdentifier = xTarget.identifier,
            coords = playerCoords,
            targetCoords = targetCoords,
            distance = ESX.Math.Round(#(playerCoords - targetCoords), 2),
        })
    end
end)