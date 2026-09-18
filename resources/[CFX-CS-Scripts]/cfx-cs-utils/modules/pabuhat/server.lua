local Vars = require 'helpers.vars'

local function FormatSentry(xPlayer, xTarget, targetSrc)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR BUHAT SYSTEM'),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('playerId Provided: %s'):format(targetSrc),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(text, ' | ')
end

local function notify(src, msg, nType)
    TriggerClientEvent('esx:Notify', src, 'BUHAT', msg, nType or 'error', 5000)
end

--- Clear carry pairing using server state, not the client-provided id.
local function clearBuhat(src)
    local carried = Vars.buhating[src]
    local carrier = Vars.nakabuhat[src]

    if carried then
        TriggerClientEvent("cfx-keydi-utils:Buhat:Stop", carried)
        Vars.nakabuhat[carried] = nil
        Vars.buhating[src] = nil
    end

    if carrier then
        TriggerClientEvent("cfx-keydi-utils:Buhat:Stop", carrier)
        Vars.buhating[carrier] = nil
        Vars.nakabuhat[src] = nil
    end
end

--- Drop leftover "being carried" flags when the other player is gone or the pair is broken.
local function clearStale(src)
    local carrier = Vars.nakabuhat[src]
    if carrier then
        if not GetPlayerName(carrier) or Vars.buhating[carrier] ~= src then
            Vars.nakabuhat[src] = nil
            if Vars.buhating[carrier] == src then
                Vars.buhating[carrier] = nil
            end
            carrier = nil
        end
    end

    local carried = Vars.buhating[src]
    if carried then
        if not GetPlayerName(carried) or Vars.nakabuhat[carried] ~= src then
            Vars.buhating[src] = nil
            if Vars.nakabuhat[carried] == src then
                Vars.nakabuhat[carried] = nil
            end
            carried = nil
        end
    end

    return carrier, carried
end

local function ValidateBuhat(xPlayer, xTarget, targetSrc)
    local src = xPlayer.source
    local sourceCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)

    if not targetSrc or targetSrc == -1 or targetSrc == src then
        return false, 'ALL PLAYERS CHECK'
    end
    if Player(src).state.dead then
        return false, 'CARRIER DEAD'
    end
    if #(sourceCoords - targetCoords) > 5.0 then
        return false, 'DISTANCE CHECK'
    end

    local carrier = clearStale(src)
    if carrier then
        return false, 'ADVANCED CHECK'
    end

    clearStale(targetSrc)
    if Vars.isCarryBusy(src) then
        return false, 'SOURCE BUSY'
    end
    if Vars.isCarryBusy(targetSrc) then
        return false, 'TARGET BUSY'
    end

    return true
end

RegisterNetEvent("cfx-keydi-utils:Buhat:Sync", function(targetSrc)
    local src = source
    targetSrc = tonumber(targetSrc)
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = targetSrc and ESX.GetPlayerFromId(targetSrc)
    if not xPlayer or not xTarget then return end

    -- Already carrying this same person: ignore duplicate sync
    if Vars.buhating[src] == targetSrc and Vars.nakabuhat[targetSrc] == src then
        return
    end

    local success, reason = ValidateBuhat(xPlayer, xTarget, targetSrc)
    if not success then
        lib.logger(src, 'cfx-keydi-sentry', FormatSentry(xPlayer, xTarget, targetSrc), 'ERROR')
        print(("^0[^3cfx-keydi-utils^0] [BUHAT]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        TriggerClientEvent("cfx-keydi-utils:Buhat:Stop", src)

        if reason == 'ADVANCED CHECK' then
            notify(src, 'You cannot carry while you are being carried.')
        elseif reason == 'SOURCE BUSY' then
            notify(src, 'You are already in a carry.')
        elseif reason == 'TARGET BUSY' then
            notify(src, 'That person is already in a carry.')
        elseif reason == 'DISTANCE CHECK' then
            notify(src, 'You are too far away.')
        elseif reason == 'CARRIER DEAD' then
            notify(src, 'You cannot carry while dead.')
        end
        return
    end

    TriggerClientEvent("cfx-keydi-utils:Buhat:syncTarget", targetSrc, src)
    Vars.buhating[src] = targetSrc
    Vars.nakabuhat[targetSrc] = src
end)

RegisterNetEvent("cfx-keydi-utils:Buhat:Stop", function()
    clearBuhat(source)
end)
