-- Check if player has impound job permissions for a garage location
local function hasImpoundPermission(playerId, garageId)
    local impoundLocation = Config.ImpoundLocations and Config.ImpoundLocations[garageId]
    if not impoundLocation then
        return false
    end

    -- If no job is configured for this impound, allow all players.
    if not impoundLocation.job then
        return true
    end

    local playerJob = Framework.Server.GetPlayerJob(playerId)
    if not playerJob or not playerJob.name then
        return false
    end

    if type(impoundLocation.job) == "table" then
        return isItemInList(impoundLocation.job, playerJob.name)
    end

    return impoundLocation.job == playerJob.name
end

local function normalizePlate(plate)
    if type(plate) ~= "string" then
        return ""
    end

    return string.upper((plate:gsub("%s+", "")))
end

local function getPlayerImpoundLocationsByType(playerId, vehicleType)
    local allowedImpounds = {}
    local impoundLocations = Config.ImpoundLocations or {}

    for impoundId, impoundLocation in pairs(impoundLocations) do
        if impoundLocation and impoundLocation.type == vehicleType and hasImpoundPermission(playerId, impoundId) then
            allowedImpounds[#allowedImpounds + 1] = impoundId
        end
    end

    return allowedImpounds
end

-- Format timestamp for impound retrieval date
local function formatRetrievalDate(hoursFromNow)
    local currentTime = os.time()
    local futureTime = currentTime + (hoursFromNow * 3600)
    local formattedDate = os.date("%a %b %d %Y %H:%M:%S GMT%z", futureTime)
    return formattedDate
end

-- Main impound vehicle function
local function impoundVehicle(playerId, vehiclePlate, impoundLocation, impoundReason, canRetrieve, retrievalDate, retrievalCost, vehicleProps, posX, posY, posZ, posHeading, damageData)
    if not vehiclePlate then
        return false
    end
    
    -- Convert hours to formatted date if retrievalDate is a number
    if type(retrievalDate) == "number" then
        retrievalDate = formatRetrievalDate(retrievalDate)
    end
    
    -- Get vehicle data from database
    local vehicleData = getVehicleData(playerId, false, vehiclePlate)
    if not vehicleData then
        return false
    end
    
    -- Get player information
    local playerInfo = Framework.Server.GetPlayerInfo(playerId)
    if not playerInfo then
        return false
    end
    
    -- Create impound data JSON
    local impoundData = {
        charname = playerInfo.name,
        reason = impoundReason,
        retrieval_date = retrievalDate,
        retrieval_cost = retrievalCost,
        original_garage_id = vehicleData.garage_id
    }
    local impoundDataJson = json.encode(impoundData)
    
    -- Prepare damage JSON if provided
    local damageJson = nil
    if damageData then
        damageJson = json.encode(damageData)
        if not damageJson then
            damageJson = nil
        end
    end
    
    -- Update vehicle in database to impounded status
    local updateQuery = Framework.Queries.ImpoundVehicle:format(Framework.VehiclesTable)
    local updateParams = {
        canRetrieve,          -- impound_retrievable
        impoundDataJson,      -- impound_data
        impoundLocation,      -- garage_id
        posX,                 -- pos_x
        posY,                 -- pos_y
        posZ,                 -- pos_z
        damageJson,           -- damage
        vehiclePlate          -- plate (WHERE condition)
    }
    
    local updateOk, updateErr = pcall(MySQL.update.await, updateQuery, updateParams)
    if not updateOk then
        print("^1[ERROR] Failed to impound vehicle:", tostring(updateErr))
        Framework.Server.Notify(playerId, "Database error while impounding vehicle", "error")
        return false
    end
    
    -- Update vehicle properties if configured and provided
    if Config.SaveVehiclePropsOnInsert and vehicleProps then
        local propsQuery = Framework.Queries.UpdateProps:format(Framework.VehiclesTable, Framework.VehProps)
        local propsParams = {
            json.encode(vehicleProps),
            vehiclePlate
        }
        MySQL.update.await(propsQuery, propsParams)
    end
    
    -- Notify player of successful impound
    Framework.Server.Notify(playerId, Locale.vehicleImpoundSuccess, "success")
    
    -- Send webhook notification
    local webhookFields = {
        {
            key = "Plate",
            value = vehiclePlate
        },
        {
            key = "Impounded by",
            value = playerInfo.name
        },
        {
            key = "Reason",
            value = impoundReason
        },
        {
            key = "Retrievable by owner?",
            value = canRetrieve and "Yes" or "No"
        },
        {
            key = "Retrieval Date",
            value = (canRetrieve and retrievalDate) and retrievalDate or "N/A"
        },
        {
            key = "Retrieval Cost",
            value = (canRetrieve and retrievalCost) and retrievalCost or "N/A"
        }
    }
    
    sendWebhook(playerId, Webhooks.Impound, "Vehicle Impounded", "success", webhookFields)
    
    return true
end

-- Export the impound function
exports("impoundVehicle", impoundVehicle)

lib.callback.register("jg-advancedgarages:server:get-impound-locations", function(playerId, vehicleType)
    return getPlayerImpoundLocationsByType(playerId, vehicleType)
end)

-- Server callback for impounding a vehicle
lib.callback.register("jg-advancedgarages:server:impound-vehicle", function(playerId, impoundData, networkId, vehiclePlate, vehicleProps, posX, posY, posZ, damageData)
    if type(impoundData) ~= "table" then
        return false
    end

    local impoundId = impoundData.impoundId
    if not impoundId or not Config.ImpoundLocations or not Config.ImpoundLocations[impoundId] then
        Framework.Server.Notify(playerId, "Invalid impound location", "error")
        return false
    end

    local vehicleEntity = NetworkGetEntityFromNetworkId(networkId)
    if not vehicleEntity or vehicleEntity == 0 or not DoesEntityExist(vehicleEntity) then
        Framework.Server.Notify(playerId, "Vehicle no longer exists", "error")
        return false
    end

    local playerPed = GetPlayerPed(playerId)
    if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then
        return false
    end

    local maxVehicleDistance = Config.ImpoundVehicleMaxDistance or 12.0
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleCoords = GetEntityCoords(vehicleEntity)
    local vehicleDistance = #(playerCoords - vehicleCoords)
    if vehicleDistance > maxVehicleDistance then
        Framework.Server.Notify(playerId, "You are too far away from the vehicle", "error")
        return false
    end

    local entityPlate = normalizePlate(GetVehicleNumberPlateText(vehicleEntity))
    if normalizePlate(vehiclePlate) ~= entityPlate then
        Framework.Server.Notify(playerId, "Vehicle plate verification failed", "error")
        return false
    end

    -- Check if player has permission to impound at this location
    local hasPermission = hasImpoundPermission(playerId, impoundId)
    if not hasPermission then
        return false
    end
    
    -- Extract impound parameters
    local reason = impoundData.reason
    local retrievalDate = impoundData.retrievalDate
    local retrievalCost = tonumber(impoundData.retrievalCost) or 0
    local retrievable = impoundData.retrievable == true
    
    -- Execute impound
    local success = impoundVehicle(
        playerId,
        vehiclePlate,
        impoundId,
        reason,
        retrievable,
        retrievalDate,
        retrievalCost,
        vehicleProps,
        posX,
        posY,
        posZ,
        damageData
    )
    
    if not success then
        return false
    end
    
    -- Remove vehicle from outside vehicles tracking
    Globals.OutsideVehicles[vehiclePlate] = nil
    
    -- Handle Qbox framework persistence
    if Config.Framework == "Qbox" then
        local vehicleEntity = NetworkGetEntityFromNetworkId(networkId)
        exports.qbx_core:DisablePersistence(vehicleEntity)
    end
    
    -- Delete the physical vehicle
    local vehicleEntity = NetworkGetEntityFromNetworkId(networkId)
    deleteVehicle(vehicleEntity, networkId, vehiclePlate)
    
    return true
end)

-- Server callback for removing/retrieving vehicle from impound
lib.callback.register("jg-advancedgarages:server:impound-remove-vehicle", function(playerId, impoundId, garageId, vehiclePlate, spawnVehicle)
    local networkId = nil
    
    -- Resolve impound location data.
    -- For "return to owner's garage" (no spawn), this can be safely nil for legacy rows
    -- where the impound key was renamed/removed in config.
    local garage = Config.ImpoundLocations and Config.ImpoundLocations[impoundId]
    if not garage then
        local garageLocations = getPlayerAvailableGarageLocations(playerId)
        if garageLocations then
            garage = garageLocations[impoundId]
        end
    end
    if spawnVehicle and not garage then
        Framework.Server.Notify(playerId, "Impound location no longer exists in config", "error")
        return false
    end
    
    -- Get vehicle data from database
    local vehicleData = getVehicleData(playerId, false, vehiclePlate)
    if not vehicleData then
        Framework.Server.Notify(playerId, "Could not get vehicle data from database", "error")
        return false
    end
    vehiclePlate = vehicleData.plate or vehiclePlate

    local impoundData = {}
    if vehicleData.impound_data and vehicleData.impound_data ~= "" then
        local decodedImpoundData = json.decode(vehicleData.impound_data)
        if type(decodedImpoundData) == "table" then
            impoundData = decodedImpoundData
        end
    end
    
    -- Prepare vehicle spawn data
    local spawnData = {}
    
    -- Parse vehicle properties
    local vehicleProps = false
    if vehicleData[Framework.VehProps] then
        vehicleProps = json.decode(vehicleData[Framework.VehProps])
        if not vehicleProps then
            vehicleProps = false
        end
    end
    spawnData.props = vehicleProps
    
    -- Set vehicle condition values with defaults
    spawnData.fuel = vehicleData.fuel or 100.0
    spawnData.engine = vehicleData.engine or 1000.0
    spawnData.body = vehicleData.body or 1000.0
    
    -- Parse damage data
    local damageData = false
    if vehicleData.damage then
        damageData = json.decode(vehicleData.damage)
        if not damageData then
            damageData = false
        end
    end
    spawnData.damage = damageData
    
    -- Check impound permissions and handle retrieval fees
    local hasPermission = hasImpoundPermission(playerId, impoundId)
    if not hasPermission then
        -- Check if vehicle is impounded and retrievable
        local isImpounded = (vehicleData.impound == true or vehicleData.impound == 1)
        local isRetrievable = (vehicleData.impound_retrievable == true or vehicleData.impound_retrievable == 1)
        
        if isImpounded and isRetrievable then
            local retrievalDate = impoundData.retrieval_date
            local retrievalCost = tonumber(impoundData.retrieval_cost) or 0
            
            -- Handle retrieval fee
            if retrievalCost > 0 then
                local paymentSuccess = Framework.Server.PlayerRemoveMoney(playerId, retrievalCost, "bank")
                if not paymentSuccess then
                    return false
                end
                
                -- Pay into society fund if configured
                if Config.ImpoundFeesSocietyFund then
                    Framework.Server.PayIntoSocietyFund(Config.ImpoundFeesSocietyFund, retrievalCost)
                end
            end
        end
    end

    local targetGarageId = garageId
    if not targetGarageId or targetGarageId == "" then
        targetGarageId = impoundData.original_garage_id
    end
    if not targetGarageId or targetGarageId == "" then
        targetGarageId = vehicleData.garage_id
    end
    if not targetGarageId or targetGarageId == "" then
        Framework.Server.Notify(playerId, "Could not determine original garage for this vehicle", "error")
        return false
    end
    
    -- Handle vehicle spawning if requested
    local spawnCoords = nil
    if spawnVehicle then
        -- Check player distance from impound location
        if garage and garage.coords then
            local maxDistance = garage.distance or 15.0
            local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
            local garageCoords = garage.coords.xyz
            local distance = #(playerCoords - garageCoords)
            
            if distance > maxDistance then
                Framework.Server.Notify(playerId, "You are too far away from the impound", "error")
                return false
            end
        end
        
        -- Find spawn coordinates
        spawnCoords = findVehicleSpawnCoords(garage.spawn)
        if not spawnCoords then
            Framework.Server.Notify(playerId, "Impound location is missing/has no valid spawn coords", "error")
            print("^1[ERROR] Impound is missing/has no valid spawn coords", impoundId)
            return false
        end
        
        -- Spawn vehicle if using server setter
        if Config.SpawnVehiclesWithServerSetter then
            local spawnInside = not Config.DoNotSpawnInsideVehicle
            
            networkId = spawnVehicleServer(
                playerId,
                vehicleData.id or 0,
                vehicleData.model,
                vehiclePlate,
                spawnCoords,
                spawnInside,
                spawnData,
                "personal"
            )
            
            if not networkId then
                Framework.Server.Notify(playerId, "Could not spawn vehicle - vehicle was not not removed from impound", "error")
                return false
            end
            
            -- Track spawned vehicle
            Globals.OutsideVehicles[vehiclePlate] = networkId
        end
    end
    
    -- Update database to remove from impound.
    -- Use canonical DB plate so this works across schemas (ESX/QB/Qbox).
    local updateQuery = Framework.Queries.ImpoundReturnToGarage:format(Framework.VehiclesTable)
    local updateParams = {
        targetGarageId,                 -- garage_id
        spawnVehicle and 0 or 1,       -- stored (0 = outside, 1 = stored)
        vehiclePlate                    -- plate (WHERE condition)
    }
    
    local returnOk, rowsUpdatedOrErr = pcall(MySQL.update.await, updateQuery, updateParams)
    if not returnOk then
        print("^1[ERROR] Failed to return vehicle from impound:", tostring(rowsUpdatedOrErr))
        Framework.Server.Notify(playerId, "Database error while returning vehicle from impound", "error")
        return false
    end
    local rowsUpdated = tonumber(rowsUpdatedOrErr) or 0
    if rowsUpdated < 1 then
        print("^1[ERROR] Impound return updated 0 rows. Plate:", tostring(vehiclePlate), "Impound:", tostring(impoundId), "TargetGarage:", tostring(targetGarageId))
        Framework.Server.Notify(playerId, "Vehicle return failed, no database rows were updated", "error")
        return false
    end

    -- Ensure retrievable flag is reset too for schemas where the shared query
    -- does not include it.
    MySQL.update.await(
        ("UPDATE %s SET impound_retrievable = 0 WHERE plate = ?"):format(Framework.VehiclesTable),
        { vehiclePlate }
    )

    -- Verify that the row is actually no longer marked as impounded.
    local updatedVehicleData = getVehicleData(playerId, false, vehiclePlate)
    if not updatedVehicleData then
        Framework.Server.Notify(playerId, "Could not verify vehicle after impound return", "error")
        return false
    end

    local stillImpounded = (updatedVehicleData.impound == true or updatedVehicleData.impound == 1 or tostring(updatedVehicleData.impound) == "1")
    if stillImpounded then
        print("^1[ERROR] Vehicle is still marked as impounded after return update. Plate:", tostring(vehiclePlate))
        Framework.Server.Notify(playerId, "Vehicle return failed, still marked as impounded", "error")
        return false
    end
    
    -- Notify if not spawning vehicle (admin action)
    if not spawnVehicle then
        Framework.Server.Notify(playerId, Locale.vehicleImpoundReturnedToOwnerSuccess, "success")
    end
    
    return true, networkId, vehicleData, spawnData, spawnCoords, targetGarageId
end)

-- Server callback for when impounded vehicle is driven out
lib.callback.register("jg-advancedgarages:server:impound-vehicle-driven-out", function(playerId, vehiclePlate, networkId)
    -- Track the vehicle as outside
    Globals.OutsideVehicles[vehiclePlate] = networkId
    
    -- Enable persistence for Qbox framework
    if Config.Framework == "Qbox" then
        local vehicleEntity = NetworkGetEntityFromNetworkId(networkId)
        exports.qbx_core:EnablePersistence(vehicleEntity)
    end
end)

-- Register impound command
lib.addCommand(Config.ImpoundCommand, false, function(playerId)
    TriggerClientEvent("jg-advancedgarages:client:show-impound-form", playerId)
end)

if Config.ImpoundCommand ~= "impound" then
    lib.addCommand("impound", false, function(playerId)
        TriggerClientEvent("jg-advancedgarages:client:show-impound-form", playerId)
    end)
end