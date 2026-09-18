-- Vehicle Spawning System for FiveM Advanced Garages
-- Deobfuscated from cl-spawn.lua

-- Function to determine vehicle type for spawning (different from garage type)
function getVehicleSpawnType(vehicleModel)
    local spawnType = nil
    local vehicleClass = GetVehicleClassFromName(vehicleModel)
    
    -- Check vehicle type in order of specificity
    local isCar = IsThisModelACar(vehicleModel)
    if isCar then
        spawnType = "automobile"
    else
        local isBicycle = IsThisModelABicycle(vehicleModel)
        if isBicycle then
            spawnType = "bike"
        else
            local isMotorcycle = IsThisModelABike(vehicleModel)
            if isMotorcycle then
                spawnType = "bike"
            else
                local isBoat = IsThisModelABoat(vehicleModel)
                if isBoat then
                    spawnType = "boat"
                else
                    local isHelicopter = IsThisModelAHeli(vehicleModel)
                    if isHelicopter then
                        spawnType = "heli"
                    else
                        local isPlane = IsThisModelAPlane(vehicleModel)
                        if isPlane then
                            spawnType = "plane"
                        else
                            local isQuadbike = IsThisModelAQuadbike(vehicleModel)
                            if isQuadbike then
                                spawnType = "automobile"
                            else
                                local isTrain = IsThisModelATrain(vehicleModel)
                                if isTrain then
                                    spawnType = "train"
                                elseif vehicleClass == 5 then -- Sports Classic
                                    spawnType = "automobile"
                                elseif vehicleClass == 14 then -- Boats
                                    spawnType = "submarine"
                                elseif vehicleClass == 16 then -- Planes
                                    spawnType = "heli"
                                else
                                    spawnType = "trailer"
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return spawnType
end

-- Re-apply smashable parts after any SetVehicleFixed. That native is networked (other
-- players see a repaired car) while SetVehicleDamage deformation is local to this client.
local DAMAGE_PROP_KEYS = {
    "engineHealth", "bodyHealth", "tankHealth", "fuelLevel", "oilLevel",
    "doorsBroken", "windowsBroken", "tyreBurst",
    "doorStatus", "windowStatus", "tireBurstState", "tireBurstCompletely", "tireHealth"
}

local function stripDamageProps(props)
    if type(props) ~= "table" then return end
    for i = 1, #DAMAGE_PROP_KEYS do
        props[DAMAGE_PROP_KEYS[i]] = nil
    end
end

local function hasMeaningfulDeformation(damage)
    if type(damage) ~= "table" then return false end
    local points = damage.deformation
    return type(points) == "table" and #points > 0
end

local function applyVehicleBrokenParts(vehicle, props)
    if not props or type(props) ~= "table" then return end

    if props.doorsBroken then
        for doorId, broken in pairs(props.doorsBroken) do
            if broken then
                SetVehicleDoorBroken(vehicle, tonumber(doorId), true)
            end
        end
    end

    if props.windowsBroken then
        for windowId, broken in pairs(props.windowsBroken) do
            if broken then
                SmashVehicleWindow(vehicle, tonumber(windowId))
            end
        end
    end

    if props.tyreBurst then
        for tyreId, burst in pairs(props.tyreBurst) do
            if burst then
                SetVehicleTyreBurst(vehicle, tonumber(tyreId), true, 1000.0)
            end
        end
    end
end

-- Function to apply vehicle properties and customization
function applyVehicleProperties(vehicle, vehicleData)
    -- Validate input parameters
    if not vehicleData or type(vehicleData) ~= "table" then
        return false
    end

    local vehicleProperties = vehicleData.props
    local engineHealth = 1000.0
    local bodyHealth = 1000.0
    if Config.SaveVehicleDamage then
        engineHealth = tonumber(vehicleData.engine) or 1000.0
        bodyHealth = tonumber(vehicleData.body) or 1000.0
        -- 0/0 is almost always a deleted or exploded entity read, not a parked wreck
        if engineHealth <= 0 and bodyHealth <= 0 then
            engineHealth = 1000.0
            bodyHealth = 1000.0
        end
    end

    -- Healthy garage cars must spawn repaired. Presence of a damage JSON (often
    -- empty/dirt-only) used to skip SetVehicleFixed, then jg-mechanic props
    -- smashed windows/doors that GetVehicleProperties falsely marked broken.
    local visuallyHealthy = bodyHealth >= 990.0 and engineHealth >= 990.0

    -- Apply vehicle properties if they exist
    if vehicleProperties and type(vehicleProperties) == "table" then
        if visuallyHealthy then
            stripDamageProps(vehicleProperties)
            SetVehicleFixed(vehicle)
        else
            vehicleProperties.fuelLevel = nil
            vehicleProperties.engineHealth = nil
            vehicleProperties.bodyHealth = nil
            vehicleProperties.tankHealth = nil
        end
        -- Never let bad vehicle props abort the whole take-out flow
        local ok, err = pcall(Framework.Client.SetVehicleProperties, vehicle, vehicleProperties)
        if not ok then
            print("^1[jg-advancedgarages] SetVehicleProperties failed: " .. tostring(err) .. "^0")
        end
        if visuallyHealthy then
            SetVehicleFixed(vehicle)
            ok, err = pcall(Framework.Client.SetVehicleProperties, vehicle, vehicleProperties)
            if not ok then
                print("^1[jg-advancedgarages] SetVehicleProperties (retry) failed: " .. tostring(err) .. "^0")
            end
        end
    elseif visuallyHealthy then
        SetVehicleFixed(vehicle)
    end

    -- Set vehicle fuel level (after props so they cannot wipe it)
    local fuelLevel = tonumber(vehicleData.fuel)
    if not fuelLevel then fuelLevel = 100.0 end
    Framework.Client.VehicleSetFuel(vehicle, fuelLevel)

    -- Set engine health
    SetVehicleEngineHealth(vehicle, engineHealth + 0.0)

    -- Set body health
    SetVehicleBodyHealth(vehicle, bodyHealth + 0.0)
    if not visuallyHealthy and bodyHealth < 1000.0 then
        SetVehiclePetrolTankHealth(vehicle, math.max(100.0, bodyHealth + 0.0))
    else
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
    end

    -- Set vehicle mod kit for customization
    SetVehicleModKit(vehicle, 0)

    -- Apply livery if specified (livery 0 is valid; do not treat it as falsy)
    if type(vehicleData.livery) == "number" then
        SetVehicleMod(vehicle, 48, vehicleData.livery, false)
        SetVehicleLivery(vehicle, vehicleData.livery)
    end

    -- Apply vehicle extras WITHOUT SetVehicleFixed (that native undoes extras + damage
    -- on other clients while this client then re-dents the car locally).
    if vehicleData.extras and type(vehicleData.extras) == "table" then
        for extraId = 1, 14 do
            local extraExists = DoesExtraExist(vehicle, extraId)
            if extraExists then
                local isExtraEnabled = isItemInList(vehicleData.extras, extraId)
                local extraState = isExtraEnabled and 0 or 1 -- 0 = on, 1 = off
                SetVehicleExtra(vehicle, extraId, extraState)
            end
        end
    end

    if not visuallyHealthy then
        applyVehicleBrokenParts(vehicle, vehicleProperties)

        -- Apply advanced damage last. Replicate via state bag so streamed-in players
        -- apply the same visual dents (SetVehicleDamage does not sync by itself).
        if hasMeaningfulDeformation(vehicleData.damage) and Config.AdvancedVehicleDamage then
            if NetworkGetEntityIsNetworked(vehicle) then
                Entity(vehicle).state:set("jgAgDeform", vehicleData.damage, true)
            else
                setVehicleDeformation(vehicle, vehicleData.damage)
            end
        end
    end

    -- Clean vehicle if specified
    if vehicleData.clean then
        SetVehicleDirtLevel(vehicle, 0.0)
    end

    -- Return whether vehicle is networked
    local isNetworked = NetworkGetEntityIsNetworked(vehicle)
    return not isNetworked
end

-- Function to validate and prepare vehicle model for spawning
function validateAndPrepareVehicleModel(vehicleModel)
    local modelHash = convertModelToHash(vehicleModel)
    local spawnType = getVehicleSpawnType(modelHash)
    
    -- Check if model exists in game files
    local modelExists = IsModelInCdimage(modelHash)
    if not modelExists then
        Framework.Client.Notify("Vehicle model does not exist - contact an admin", "error")
        print(("^1Vehicle model %s does not exist"):format(vehicleModel))
        return false
    end
    
    -- Check if vehicle has valid seats
    local seatCount = GetVehicleModelNumberOfSeats(modelHash)
    local hasValidSeats = seatCount > 0
    
    -- Validate plate if provided
    if plate and plate ~= "" then
        local isValidPlate = isValidGTAPlate(plate)
        if not isValidPlate then
            Framework.Client.Notify("This vehicle's plate is invalid (hit F8 for more details)", "error")
            print(("^1This vehicle is trying to spawn with the plate '%s' which is invalid for a GTA vehicle plate"):format(plate:upper()))
            print("^1Vehicle plates must be 8 characters long maximum, and can contain ONLY numbers, letters and spaces")
            return false
        end
    end
    
    -- Request model with timeout
    lib.requestModel(modelHash, 60000)
    
    -- Check if player is in ragdoll state
    local isPlayerRagdoll = IsPedRagdoll(cache.ped)
    if isPlayerRagdoll then
        Framework.Client.Notify("You are currently in a ragdoll state", "error")
        SetModelAsNoLongerNeeded(modelHash)
        return false
    end
    
    return modelHash, spawnType, hasValidSeats
end

-- Function to finalize vehicle spawning (post-spawn setup)
function finalizeVehicleSpawn(vehicle, vehicleId, shouldEnterVehicle, plateText, vehicleData, keyType)
    -- Validate vehicle exists
    if not vehicle or vehicle == 0 then
        Framework.Client.Notify("Could not spawn vehicle - hit F8 for details", "error")
        print("^1Vehicle does not exist (vehicle = 0)")
        return false
    end
    
    -- Check if player is still in ragdoll state
    local isPlayerRagdoll = IsPedRagdoll(cache.ped)
    if isPlayerRagdoll then
        Framework.Client.Notify("You are currently in a ragdoll state", "error")
        local vehicleModel = GetEntityModel(vehicle)
        SetModelAsNoLongerNeeded(vehicleModel)
        return false
    end
    
    -- Enter vehicle if requested
    if shouldEnterVehicle then
        ClearPedTasks(cache.ped)
        
        local warpSuccess = pcall(function()
            lib.waitFor(function()
                local driverPed = GetPedInVehicleSeat(vehicle, -1)
                if driverPed == cache.ped then
                    return true
                end
                TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
            end, nil, 5000)
        end)
        
        if not warpSuccess then
            print("^1[ERROR] Could not warp you into the vehicle^0")
            return false
        end
    end
    
    -- Set vehicle plate if provided
    if plateText and plateText ~= "" then
        SetVehicleNumberPlateText(vehicle, plateText)
    end
    
    -- Apply vehicle data if provided
    if vehicleData and type(vehicleData) == "table" then
        applyVehicleProperties(vehicle, vehicleData)
    end
    
    -- Handle fake plates integration if available
    local fakePlatesState = GetResourceState("brazzers-fakeplates")
    if fakePlatesState == "started" then
        local fakePlate = lib.callback.await("jg-advancedgarages:server:brazzers-get-fakeplate-from-plate", false, plateText)
        if fakePlate then
            plateText = fakePlate
            SetVehicleNumberPlateText(vehicle, fakePlate)
        end
    end
    
    -- Ensure vehicle has a valid plate
    if not plateText or plateText == "" then
        plateText = Framework.Client.GetPlate(vehicle)
    end
    
    if not plateText or plateText == "" then
        print("^1[ERROR] The game thinks the vehicle has no plate - absolutely no idea how you've managed this")
        return false
    end
    
    -- Set vehicle ID in entity state
    Entity(vehicle).state:set("vehicleid", vehicleId, true)
    
    -- Give vehicle keys to player
    Framework.Client.VehicleGiveKeys(plateText, vehicle, keyType)
    
    return true
end

-- Function to handle server-spawned vehicle (with network ID)
function handleServerSpawnedVehicle(networkId, playerCoords, shouldEnterVehicle, modelHash, vehicleId, plateText, vehicleData, keyType)
    -- Clean up model from memory
    SetModelAsNoLongerNeeded(modelHash)
    
    -- Validate network ID
    if not networkId then
        Framework.Client.Notify("Could not spawn vehicle - hit F8 for details", "error")
        print("^1Server returned false for netId")
        return false
    end
    
    -- Wait for network entity to exist
    lib.waitFor(function()
        local networkIdExists = NetworkDoesNetworkIdExist(networkId)
        local entityExists = NetworkDoesEntityExistWithNetworkId(networkId)
        return networkIdExists and entityExists or nil
    end, "Timed out while waiting for a server-setter netId to exist on client", 10000)
    
    -- Convert network ID to vehicle entity
    vehicle = NetToVeh(networkId)
    
    -- Wait for vehicle entity to exist
    lib.waitFor(function()
        local vehicleExists = DoesEntityExist(vehicle)
        return vehicleExists or nil
    end, "Timed out while waiting for a server-setter vehicle to exist on client", 10000)
    
    -- Teleport player to vehicle if coordinates provided
    if playerCoords then
        SetEntityCoords(cache.ped, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false, false)
    end
    
    -- Finalize vehicle spawn
    local spawnSuccess = finalizeVehicleSpawn(vehicle, vehicleId, shouldEnterVehicle, plateText, vehicleData, keyType)
    
    if not spawnSuccess then
        DeleteEntity(vehicle)
        return false
    end
    
    return vehicle
end

-- Function to create a vehicle on the client side
function createClientVehicle(modelHash, spawnCoords, plateText, isNetworked)
    -- Request model
    lib.requestModel(modelHash, 60000)
    
    -- Create vehicle
    local vehicle = CreateVehicle(
        modelHash,
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z,
        spawnCoords.w,
        isNetworked or false,
        true
    )
    
    -- Wait for vehicle to exist
    lib.waitFor(function()
        local vehicleExists = DoesEntityExist(vehicle)
        return vehicleExists or nil
    end, "Timed out while trying to spawn in vehicle (client)", 10000)
    
    -- Clean up model
    SetModelAsNoLongerNeeded(modelHash)
    
    -- Set plate if provided
    if plateText and plateText ~= "" then
        SetVehicleNumberPlateText(vehicle, plateText)
    end
    
    return vehicle
end

-- Main function to spawn vehicle on client side
function spawnVehicleClient(vehicleId, vehicleModel, plateText, spawnCoords, shouldEnterVehicle, vehicleData, keyType)
    -- Check if client spawning is disabled
    if Config.SpawnVehiclesWithServerSetter then
        print("^1This function is disabled as client spawning is enabled")
        return false
    end
    
    -- Validate and prepare vehicle model
    local modelHash, spawnType, hasValidSeats = validateAndPrepareVehicleModel(vehicleModel)
    if not modelHash then
        return false
    end
    
    -- Create vehicle on client
    local vehicle = createClientVehicle(modelHash, spawnCoords, plateText, true)
    if not vehicle then
        return false
    end
    
    -- Finalize vehicle spawn
    local shouldEnter = hasValidSeats and shouldEnterVehicle
    local spawnSuccess = finalizeVehicleSpawn(vehicle, vehicleId, shouldEnter, plateText, vehicleData, keyType)
    
    if not spawnSuccess then
        DeleteEntity(vehicle)
        return false
    end
    
    return vehicle
end

-- State bag handler for vehicle initialization
AddStateBagChangeHandler("vehInit", "", function(bagName, key, value)
    if not value then
        return
    end
    
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 then
        return
    end
    
    -- Wait for entity to settle
    lib.waitFor(function()
        local isWaitingForCollision = IsEntityWaitingForWorldCollision(entity)
        return not isWaitingForCollision
    end)
    
    -- Check if we own this entity
    local entityOwner = NetworkGetEntityOwner(entity)
    if entityOwner ~= cache.playerId then
        return
    end
    
    local entityState = Entity(entity).state
    
    -- Set vehicle on ground properly
    SetVehicleOnGroundProperly(entity)
    
    -- Clear the state after processing
    SetTimeout(0, function()
        entityState:set("vehInit", nil, true)
    end)
end)

-- State bag handler for applying vehicle properties after creation
AddStateBagChangeHandler("vehCreatedApplyProps", "", function(bagName, key, vehicleProperties)
    if not vehicleProperties then
        return
    end
    
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 then
        return
    end
    
    SetTimeout(0, function()
        local entityState = Entity(entity).state
        local attempts = 0
        
        while attempts < 10 do
            local entityOwner = NetworkGetEntityOwner(entity)
            if entityOwner == cache.playerId then
                local propertiesApplied = applyVehicleProperties(entity, vehicleProperties)
                if propertiesApplied then
                    entityState:set("vehCreatedApplyProps", nil, true)
                    break
                end
            end
            attempts = attempts + 1
            Wait(100)
        end
    end)
end)

-- Register callbacks for server communication
lib.callback.register("jg-advancedgarages:client:req-vehicle-and-get-spawn-details", validateAndPrepareVehicleModel)
lib.callback.register("jg-advancedgarages:client:on-server-vehicle-created", handleServerSpawnedVehicle)