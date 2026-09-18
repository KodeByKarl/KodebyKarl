-- Vehicle Spawn Server Script - Deobfuscated

-- Tracking variables for vehicle spawning
local vehicleSpawnAttempts = {}
local maxDistanceFromPlayer = 10.0
local maxRetryAttempts = 3

-- Function to create vehicle using server setter with retry mechanism
function createVehicleWithServerSetter(playerId, vehicleModel, vehicleType, targetPlate, spawnCoords, shouldPutPlayerInVehicle, vehicleProps)
    local currentAttempts = vehicleSpawnAttempts[playerId]
    
    -- Check if maximum retry attempts reached
    if currentAttempts then
        if currentAttempts == maxRetryAttempts then
            print("^3[WARNING] Vehicle props failed to set after trying several times. First check if the plate within the vehicle props JSON does not match the plate column. If they match, and you see this message regularly, try setting Config.SpawnVehiclesWithServerSetter = false")
            vehicleSpawnAttempts[playerId] = 0
            return false
        end
    end
    
    -- Increment attempt counter
    vehicleSpawnAttempts[playerId] = (vehicleSpawnAttempts[playerId] or 0) + 1
    
    -- Create vehicle using server setter
    local vehicleEntity = CreateVehicleServerSetter(
        vehicleModel,
        vehicleType,
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z,
        spawnCoords.w
    )
    
    -- Wait for vehicle entity to exist
    lib.waitFor(function()
        return DoesEntityExist(vehicleEntity) or nil
    end, "Timed out while trying to spawn in vehicle (server)", 10000)
    
    -- Wait for vehicle plate text to be set
    lib.waitFor(function()
        local plateText = GetVehicleNumberPlateText(vehicleEntity)
        return plateText ~= "" or plateText
    end, "Vehicle number plate text is nil", 5000)
    
    -- Set vehicle to player's routing bucket
    local playerRoutingBucket = GetPlayerRoutingBucket(playerId)
    SetEntityRoutingBucket(vehicleEntity, playerRoutingBucket)
    
    -- Set entity orphan mode if available
    if SetEntityOrphanMode then
        SetEntityOrphanMode(vehicleEntity, 2)
    end
    
    -- Remove any existing peds from vehicle seats
    for seatIndex = -1, 6, 1 do
        local pedInSeat = GetPedInVehicleSeat(vehicleEntity, seatIndex)
        if pedInSeat ~= 0 then
            DeleteEntity(pedInSeat)
        end
    end
    
    -- Put player in vehicle if requested
    if shouldPutPlayerInVehicle then
        local playerPed = GetPlayerPed(playerId)
        pcall(function()
            lib.waitFor(function()
                local driverPed = GetPedInVehicleSeat(vehicleEntity, -1)
                if driverPed == playerPed then
                    return true
                end
                SetPedIntoVehicle(playerPed, vehicleEntity, -1)
            end, nil, 1000)
        end)
    end
    
    -- Wait for vehicle to have a network owner
    lib.waitFor(function()
        local entityOwner = NetworkGetEntityOwner(vehicleEntity)
        return entityOwner ~= -1 or entityOwner
    end, "Timed out waiting for server-setter entity to have an owner (owner is -1)", 5000)
    
    -- Set vehicle initialization state
    local vehicleState = Entity(vehicleEntity).state
    vehicleState:set("vehInit", true, true)
    
    -- Apply vehicle properties if provided
    if vehicleProps then
        if type(vehicleProps) == "table" then
            local vehicleEntityState = Entity(vehicleEntity).state
            vehicleEntityState:set("vehCreatedApplyProps", vehicleProps, true)
        end
    end
    
    -- Wait for properties to be applied or plate to match
    local propsApplied = pcall(function()
        lib.waitFor(function()
            local vehicleEntityState = Entity(vehicleEntity).state
            if not vehicleEntityState.vehCreatedApplyProps then
                if targetPlate and targetPlate ~= "" then
                    local currentPlate = Framework.Server.GetPlate(vehicleEntity)
                    if currentPlate ~= targetPlate then
                        return false
                    end
                end
                return true
            end
        end, nil, 2000)
    end)
    
    -- If properties failed to apply, retry the spawn
    if not propsApplied then
        DeleteEntity(vehicleEntity)
        deleteVehicle(vehicleEntity)
        return createVehicleWithServerSetter(playerId, vehicleModel, vehicleType, targetPlate, spawnCoords, shouldPutPlayerInVehicle, vehicleProps)
    end
    
    -- Reset attempt counter on success
    vehicleSpawnAttempts[playerId] = 0
    
    -- Return network ID of spawned vehicle
    return NetworkGetNetworkIdFromEntity(vehicleEntity)
end

-- Main function to spawn vehicle on server
function spawnVehicleServer(playerId, garageData, vehicleData, targetPlate, spawnCoords, shouldPutPlayerInVehicle, vehicleProps, additionalData)
    -- Request vehicle spawn details from client
    local vehicleModel, vehicleType, putPlayerInVehicle = lib.callback.await(
        "jg-advancedgarages:client:req-vehicle-and-get-spawn-details",
        playerId,
        vehicleData
    )
    
    if not vehicleModel then
        return false
    end
    
    -- Get player position
    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local playerWasTeleported = false
    
    -- Check if player is too far from spawn location
    local distanceToSpawn = #(playerCoords - spawnCoords.xyz)
    if distanceToSpawn > maxDistanceFromPlayer then
        -- Teleport player closer to spawn location
        SetEntityCoords(
            playerPed,
            spawnCoords.x + 3.0,
            spawnCoords.y + 3.0,
            spawnCoords.z,
            false, false, false, false
        )
        playerWasTeleported = true
    end
    
    -- Create vehicle using server setter
    local vehicleNetworkId = createVehicleWithServerSetter(
        playerId,
        vehicleModel,
        vehicleType,
        targetPlate,
        spawnCoords,
        putPlayerInVehicle and (putPlayerInVehicle or shouldPutPlayerInVehicle),
        vehicleProps
    )
    
    if not vehicleNetworkId then
        return false
    end
    
    -- Notify client that vehicle was created
    local clientResponse = lib.callback.await(
        "jg-advancedgarages:client:on-server-vehicle-created",
        playerId,
        vehicleNetworkId,
        playerWasTeleported and (playerWasTeleported or playerCoords),
        putPlayerInVehicle and (putPlayerInVehicle or shouldPutPlayerInVehicle),
        vehicleModel,
        garageData,
        targetPlate,
        vehicleProps,
        additionalData
    )
    
    -- If client failed to process vehicle, clean up
    if not clientResponse then
        if NetworkDoesEntityExistWithNetworkId(vehicleNetworkId) then
            local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetworkId)
            DeleteEntity(vehicleEntity)
            debugPrint("Failed to create vehicle, deleted entity.", "warning", vehicleNetworkId)
        end
        return false
    end
    
    return vehicleNetworkId, clientResponse
end