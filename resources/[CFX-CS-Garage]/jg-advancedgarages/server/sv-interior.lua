-- Store player interior data (garage info, routing buckets)
local playerInteriorData = {}

-- Server callback for entering garage interior
lib.callback.register("jg-advancedgarages:server:enter-interior", function(playerId, garageData, interiorData)
    -- Interior garage feature is disabled.
    return false
end)

-- Server callback for exiting garage interior
lib.callback.register("jg-advancedgarages:server:exit-interior", function(playerId)
    -- Get player identifier
    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)
    if not playerIdentifier then
        return false
    end
    
    -- Get stored interior data for this player
    local interiorData = playerInteriorData[playerIdentifier]
    
    if interiorData then
        -- Return to original bucket if configured
        if Config.ReturnToPreviousRoutingBucket then
            SetPlayerRoutingBucket(playerId, interiorData.originalBucket)
        end
    else
        -- Return to the player's region bucket (bucket 0 is Region 2, not "world")
        if GetResourceState('kodebykarl-ui') == 'started' then
            local restored = false
            pcall(function()
                restored = exports['kodebykarl-ui']:RestorePlayerBucket(playerId) == true
            end)
            if not restored then
                SetPlayerRoutingBucket(playerId, 0)
            end
        else
            SetPlayerRoutingBucket(playerId, 0)
        end
    end
    
    -- Clean up stored data
    playerInteriorData[playerIdentifier] = nil
    
    return true
end)