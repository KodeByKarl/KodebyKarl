local utils         = require 'modules.server.utils'
local resources     = require 'bridge.compat.resources'

-- When setJailTime is called, compat for other resources is called
function syncJailCompatibility(src, time)
    if resources.randol_medical then
        exports.randol_medical:SetJailState(src, (time > 0))
    end

    -- Add other compat here (Medical, etc)
end

-- Compat for QB/QBX Prison Original Event --
RegisterNetEvent('prison:server:SetJailStatus', function(jailTime)
    local src = source
    setJailTime(src, ((jailTime < 0) and 0 or jailTime))
end)

-- Compat for police job jail (callback — not a raw TriggerServerEvent)
local function jailPlayerHandler(src, playerId, time)
    local dist = utils.playerDistanceCheck(src, playerId)
    if not dist then return false end

    if not utils.isCop(src) then return false end

    time = tonumber(time)
    if not time or time < 1 then return false end

    local jailed = lib.callback.await('xt-prison:client:enterJail', playerId, time)
    if jailed then
        lib.notify(src, { title = ('Sent to Jail for %s Months'):format(time), type = 'success' })
        if PrisonLogs and PrisonLogs.Jail then
            PrisonLogs.Jail({
                updated = false,
                src = src,
                name = getCharName(src),
                identifier = getCharID(src),
                targetSrc = playerId,
                targetName = getCharName(playerId),
                targetIdentifier = getCharID(playerId),
                time = time,
                method = 'police menu',
            })
        end
    end
    return jailed and true or false
end

lib.callback.register('xt-prison:server:JailPlayer', function(source, playerId, time)
    return jailPlayerHandler(source, playerId, time)
end)