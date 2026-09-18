-- Private Garages Server Script - Deobfuscated

-- Function to check if a garage name is available (not already taken)
function isGarageNameAvailable(playerId, garageName)
    local allGarageNames = tableKeys(getAllGaragesAndImpounds())
    local nameExists = lib.table.contains(allGarageNames, garageName)
    
    if nameExists then
        Framework.Server.Notify(playerId, "GARAGE_NAME_TAKEN", "error")
        print("^1[ERROR] Garage name has already been taken. Every garage name, including public, job, gang in the config have to be uniquely named")
        return false
    end
    
    return true
end

-- Function to check if a player can create private garages
function canCreatePrivateGarage(playerId)
    local playerJob = Framework.Server.GetPlayerJob(playerId)
    if not playerJob then
        return false
    end
    
    local hasJobPermission = isItemInList(Config.PrivGarageCreateJobRestriction, playerJob.name)
    if not hasJobPermission then
        local isAdmin = Framework.Server.IsAdmin(playerId)
        if not isAdmin then
            Framework.Server.Notify(playerId, Locale.actionNotAllowedError, "error")
            return false
        end
    end
    
    return true
end

-- Register callback to check if garage name is available
lib.callback.register("jg-advancedgarages:server:is-garage-name-available", isGarageNameAvailable)

-- Register callback to check if player can create private garages
lib.callback.register("jg-advancedgarages:server:can-create-priv-garage", canCreatePrivateGarage)

-- Register callback to create a new private garage
lib.callback.register("jg-advancedgarages:server:create-private-garage", function(playerId, garageData)
    -- Check if player has permission to create private garages
    local hasPermission = canCreatePrivateGarage(playerId)
    if not hasPermission then
        return false
    end
    
    -- Check if garage name is available
    local nameAvailable = isGarageNameAvailable(playerId, garageData.name)
    if not nameAvailable then
        return false
    end
    
    -- Insert new private garage into database
    local insertId = MySQL.insert.await(
        "INSERT INTO player_priv_garages SET owners = ?, name = ?, type = ?, x = ?, y = ?, z = ?, h = ?, distance = ?",
        {
            json.encode(garageData.owners),
            garageData.name,
            garageData.type,
            garageData.x,
            garageData.y,
            garageData.z,
            garageData.h,
            garageData.distance
        }
    )
    
    -- Update blips and UIs for all garage owners
    for _, ownerData in pairs(garageData.owners) do
        local ownerSource = Framework.Server.GetSrcFromIdentifier(ownerData.identifier)
        if ownerSource then
            TriggerClientEvent("jg-advancedgarages:client:update-blips-text-uis", ownerSource)
        end
    end
    
    -- Notify success
    Framework.Server.Notify(playerId, Locale.garageCreatedSuccess, "success")
    
    -- Send webhook notification
    local webhookFields = {
        {key = "Name", value = garageData.name},
        {key = "Type", value = garageData.type},
        {key = "Owners", value = json.encode(garageData.owners)},
        {
            key = "Location",
            value = table.concat({
                math.ceil(garageData.x),
                math.ceil(garageData.y),
                math.ceil(garageData.z),
                math.ceil(garageData.h)
            }, ", ") .. " / dist: " .. garageData.distance
        }
    }
    
    sendWebhook(playerId, Webhooks.PrivateGarages, "Private Garage Created", "success", webhookFields)
    
    return {id = insertId}
end)

-- Register callback to edit an existing private garage
lib.callback.register("jg-advancedgarages:server:edit-private-garage", function(playerId, garageData)
    -- Check if player has permission to edit private garages
    local hasPermission = canCreatePrivateGarage(playerId)
    if not hasPermission then
        return false
    end
    
    -- Get existing garage data
    local existingGarage = MySQL.single.await(
        "SELECT * FROM player_priv_garages WHERE id = ?",
        {garageData.id}
    )
    
    if not existingGarage then
        return false
    end
    
    -- Update garage in database
    MySQL.update.await(
        "UPDATE player_priv_garages SET owners = ?, type = ?, x = ?, y = ?, z = ?, h = ?, distance = ? WHERE id = ?",
        {
            json.encode(garageData.owners),
            garageData.type,
            garageData.x,
            garageData.y,
            garageData.z,
            garageData.h,
            garageData.distance,
            garageData.id
        }
    )
    
    -- Update blips and UIs for all affected owners (old + new)
    local allAffectedOwners = lib.table.merge(json.decode(existingGarage.owners), garageData.owners)
    for _, ownerData in pairs(allAffectedOwners) do
        local ownerSource = Framework.Server.GetSrcFromIdentifier(ownerData.identifier)
        if ownerSource then
            TriggerClientEvent("jg-advancedgarages:client:update-blips-text-uis", ownerSource)
        end
    end
    
    -- Notify success
    Framework.Server.Notify(playerId, Locale.garageUpdatedSuccess, "success")
    
    -- Send webhook notification
    local webhookFields = {
        {key = "Name", value = garageData.name},
        {key = "Type", value = garageData.type},
        {key = "Owners", value = json.encode(garageData.owners)},
        {
            key = "Location",
            value = table.concat({
                math.ceil(garageData.x),
                math.ceil(garageData.y),
                math.ceil(garageData.z),
                math.ceil(garageData.h)
            }, ", ") .. " / dist: " .. garageData.distance
        }
    }
    
    sendWebhook(playerId, Webhooks.PrivateGarages, "Private Garage Edited", "warn", webhookFields)
    
    return true
end)

-- Register callback to delete a private garage
lib.callback.register("jg-advancedgarages:server:delete-private-garage", function(playerId, garageData)
    -- Check if player has permission to delete private garages
    local hasPermission = canCreatePrivateGarage(playerId)
    if not hasPermission then
        return false
    end
    
    -- Delete garage from database
    MySQL.update.await(
        "DELETE FROM player_priv_garages WHERE id = ?",
        {garageData.id}
    )
    
    -- Update blips and UIs for all garage owners
    for _, ownerData in pairs(garageData.owners) do
        local ownerSource = Framework.Server.GetSrcFromIdentifier(ownerData.identifier)
        if ownerSource then
            TriggerClientEvent("jg-advancedgarages:client:update-blips-text-uis", ownerSource)
        end
    end
    
    -- Send webhook notification
    local webhookFields = {
        {key = "Name", value = garageData.name}
    }
    
    sendWebhook(playerId, Webhooks.PrivateGarages, "Private Garage Deleted", "danger", webhookFields)
    
    return true
end)

-- Register callback to get all private garages (for admin dashboard)
lib.callback.register("jg-advancedgarages:server:get-all-private-garages", function(playerId, requestData)
    -- Check if player has permission to view private garages
    local hasPermission = canCreatePrivateGarage(playerId)
    if not hasPermission then
        return false
    end
    
    -- Get all private garages from database
    local allPrivateGarages = MySQL.query.await("SELECT * FROM player_priv_garages ORDER BY id DESC")
    local allPlayers = Framework.Server.GetPlayers()
    
    return {
        garages = allPrivateGarages,
        allPlayers = allPlayers
    }
end)

-- Add command to open private garages dashboard
lib.addCommand(Config.PrivGarageCreateCommand, false, function(playerId)
    local hasPermission = canCreatePrivateGarage(playerId)
    if not hasPermission then
        return
    end
    
    TriggerClientEvent("jg-advancedgarages:client:show-private-garages-dashboard", playerId)
end)