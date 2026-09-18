-- Advanced Garages Client Script
local isStoringVehicle = false
local cachedVehicles = {}

-- Filter garage locations by type and vehicle category
function filterGarageLocationsByType(locationType, garageCategory, vehicleType)
    local filteredGarages = {}
    local availableLocations = getAvailableGarageLocations()
    
    for garageId, garageData in pairs(availableLocations) do
        if garageData.type == locationType then
            local shouldInclude = false
            
            if garageCategory == "job" or garageCategory == "gang" then
                if vehicleType == garageData.vehiclesType then
                    shouldInclude = true
                end
            elseif garageCategory == "personal" then
                if garageData.garageType == "personal" then
                    shouldInclude = true
                end
            end
            
            if shouldInclude then
                table.insert(filteredGarages, garageId)
            end
        end
    end
    
    return filteredGarages
end

-- Get and cache vehicles from server
function getAndCacheVehicles(garageId, vehicleType)
    local serverVehicles = lib.callback.await("jg-advancedgarages:server:get-garage-vehicles", 2000, garageId)
    if not serverVehicles then
        -- Never reuse stale vehicle lists after a failed fetch (especially for impound actions).
        serverVehicles = {}
    end
    
    local filteredVehicles = filterVehiclesByType(serverVehicles, vehicleType)
    cachedVehicles = filteredVehicles
    
    -- Process each vehicle to get proper model names and labels
    for index, vehicleData in ipairs(cachedVehicles) do
        if vehicleData.model then
            local modelName
            
            if type(vehicleData.model) == "string" and vehicleData.model then
                modelName = vehicleData.model
            else
                modelName = getModelNameFromHash(vehicleData.hash)
            end
            
            cachedVehicles[index].model = modelName
            cachedVehicles[index].vehicleLabel = Framework.Client.GetVehicleLabel(vehicleData.model)
        else
            print(string.format("^1Vehicle with plate %s does not have a model.", vehicleData.plate))
        end
    end
    
    return cachedVehicles
end

-- Main function to open garage menu
function openGarageMenu(garageId, vehicleType, spawnCoords)
    if not vehicleType then
        vehicleType = "car"
    end
    
    -- Check if player is dead
    if Framework.Client.IsPlayerDead() then
        Framework.Client.Notify(Locale.playerIsDead, "error")
        return
    end
    
    -- Get garage data
    local availableLocations = getAvailableGarageLocations()
    local garageData = availableLocations and availableLocations[garageId]
    
    -- Check distance if garage has registered location
    if garageData and garageData.coords then
        local maxDistance = garageData.distance or 15.0
        local playerPed = cache.ped or PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distanceToGarage = #(playerCoords - garageData.coords.xyz)
        
        if maxDistance < distanceToGarage then
            print(string.format("^1The garage you are trying to open '%s' is a registered garage, and you are not at it's registered location.", garageId))
            print("^1If you were expecting to open a location via housing or another third-party integration, please note that this script is trying to open a garage with a name that is already registered.")
            print("^1Therefore, you will need to use a unique garageId in order to be able to open this garage.^0")
            Framework.Client.Notify("You are too far away from the garage", "error")
            return false
        end
    end
    
    -- Set default garage data if not found
    if not garageData then
        garageData = {
            garageType = "personal",
            checkVehicleGarageId = Config.GarageUniqueLocations,
            enableInteriors = false,
            unknown = true
        }
    end
    
    -- Get nearby players
    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlayers = lib.callback.await("jg-advancedgarages:server:nearby-players", false, playerCoords, 20.0, false)
    
    -- Get available transfer garages
    local transferGarages = filterGarageLocationsByType(vehicleType, garageData.garageType, garageData.vehiclesType)
    
    -- Add current garage to transfer list if it's unknown
    if garageData.unknown then
        table.insert(transferGarages, garageId)
    end
    
    -- Load vehicles
    getAndCacheVehicles(garageId, vehicleType)
    
    -- Check for vehicle mileage integration
    if GetResourceState("jg-vehiclemileage") == "started" then
        Config.MileageUnit = exports["jg-vehiclemileage"]:GetUnit()
    end
    
    -- Check for dealerships integration
    if GetResourceState("jg-dealerships") == "started" then
        local success = pcall(function()
            local dealershipLocale = exports["jg-dealerships"]:locale() or {}
            Locale = lib.table.merge(dealershipLocale, Locale, false)
        end)
        
        if not success then
            print("^3[WARNING] You are running jg-dealerships, but you need to be using v1.2 or newer to use it with Advanced Garages v3. Some functionality may not work as expected.")
        end
    end
    
    -- Open NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "show-garage",
        garageId = garageId,
        vehicleType = vehicleType,
        vehicles = cachedVehicles,
        checkVehicleGarageId = garageData.checkVehicleGarageId,
        enableInteriors = false,
        isSpawnerGarage = garageData.vehiclesType == "spawner",
        isJobGarage = garageData.garageType == "job",
        transferGarages = transferGarages,
        onlinePlayers = nearbyPlayers,
        isImpound = garageData.garageType == "impound",
        hasWhitelistedJob = garageData.hasImpoundJob,
        spawnCoords = spawnCoords,
        config = Config,
        locale = Locale
    })
end

-- Drive vehicle out of garage
function driveVehicleOut(vehiclePlate, garageId, spawnerIndex, spawnCoords)
    local availableLocations = getAvailableGarageLocations()
    local garageData = availableLocations and availableLocations[garageId] or {}
    
    -- Request vehicle spawn from server
    local success, vehicleNetId, vehicleHash, vehicleData, vehicleConfig, finalSpawnCoords = lib.callback.await(
        "jg-advancedgarages:server:drive-vehicle-out", 
        false, 
        vehiclePlate, 
        garageId, 
        spawnerIndex, 
        spawnCoords
    )
    
    local vehicle = vehicleNetId and NetToVeh(vehicleNetId) or false
    
    if not success then
        return false
    end
    
    -- Check if vehicle spawned properly when using server setter
    if Config.SpawnVehiclesWithServerSetter and not vehicle then
        print("^1There was a problem spawning in your vehicle")
        return false
    end
    
    -- Spawn vehicle client-side if not using server setter
    if not vehicle and not Config.SpawnVehiclesWithServerSetter then
        local shouldEnterVehicle = not Config.DoNotSpawnInsideVehicle
        local vehicleId = vehicleData and vehicleData.id or 0
        local spawnPos = finalSpawnCoords or (garageData and garageData.spawn) or GetEntityCoords(cache.ped)
        
        vehicle = spawnVehicleClient(
            vehicleId,
            vehicleHash,
            vehiclePlate,
            spawnPos,
            shouldEnterVehicle,
            vehicleConfig,
            garageData.garageType
        )
    end
    
    if not vehicle then
        debugPrint("Value of `vehicle` is false", "warning")
        return false
    end
    
    -- Update vehicle status on server (unless it's a spawner garage)
    if garageData.vehiclesType ~= "spawner" then
        local vehicleNetworkId = VehToNet(vehicle)
        local inGarageAlready = vehicleData and (
            vehicleData.in_garage == 1
            or vehicleData.in_garage == true
            or vehicleData.in_garage == "1"
            or tonumber(vehicleData.in_garage) == 1
        )
        local wasInGarage = vehicleData and not inGarageAlready
        
        success = lib.callback.await(
            "jg-advancedgarages:server:vehicle-driven-out",
            false,
            garageId,
            vehicleNetworkId,
            vehiclePlate,
            wasInGarage
        )
        
        if not success then
            deleteVehicle(vehicle)
        end
    end
    
    -- Trigger take out event
    TriggerEvent("jg-advancedgarages:client:TakeOutVehicle:config", vehicle, vehicleData, garageData.garageType)
    
    -- Show liveries/extras menu if enabled
    if garageData.showLiveriesExtrasMenu then
        showLiveriesExtrasMenu(vehicle)
        return { noClose = true }
    end
    
    return true
end

-- Store vehicle in garage
function storeVehicleInGarage(garageId, vehicleType)
    if isStoringVehicle then
        return false
    end
    
    if not vehicleType then
        vehicleType = "car"
    end
    
    -- Check if player is dead
    if Framework.Client.IsPlayerDead() then
        Framework.Client.Notify(Locale.playerIsDead, "error")
        return false
    end
    
    local currentVehicle = cache.vehicle
    local vehiclePlate = Framework.Client.GetPlate(currentVehicle)
    
    -- Check if player is in a vehicle
    if not currentVehicle or not vehiclePlate then
        Framework.Client.Notify(Locale.notInsideVehicleError, "error")
        return false
    end
    
    -- Check vehicle type matches
    local actualVehicleType = getVehicleType(GetEntityModel(currentVehicle))
    if actualVehicleType ~= vehicleType then
        Framework.Client.Notify(string.gsub(Locale.insertVehicleTypeError, "%%{value}", vehicleType), "error")
        return
    end
    
    -- Get garage data
    local availableLocations = getAvailableGarageLocations()
    local garageData = availableLocations and availableLocations[garageId]
    local garageType = garageData and garageData.garageType
    
    -- Don't allow storing in impound
    if garageType == "impound" then
        return false
    end
    
    isStoringVehicle = true
    
    local vehicleModel = GetEntityArchetypeName(currentVehicle)
    local targetGarageId = garageId
    
    -- Handle spawner garages
    if garageData and garageData.vehiclesType == "spawner" then
        targetGarageId = nil
    elseif not garageId then
        targetGarageId = nil
    end
    
    -- Get vehicle data from server
    local existingVehicle = lib.callback.await(
        "jg-advancedgarages:server:get-vehicle",
        false,
        vehicleModel,
        vehiclePlate,
        targetGarageId
    )
    
    -- Check if vehicle can be stored
    local isSpawnerGarage = garageData and garageData.vehiclesType == "spawner"
    if not isSpawnerGarage and not existingVehicle then
        Framework.Client.Notify(Locale.vehicleStoreError, "error")
        isStoringVehicle = false
        return false
    end
    
    -- Get vehicle properties and damage
    local vehicleProperties = Framework.Client.GetVehicleProperties(currentVehicle)
    vehicleProperties.plate = vehiclePlate
    local vehicleFuel = Framework.Client.VehicleGetFuel(currentVehicle)
    local bodyDamage, engineDamage, fuelTankDamage = getVehicleDamage(currentVehicle)

    -- Keep props in sync so SetVehicleProperties on take-out does not restore full health/fuel
    if type(vehicleProperties) == "table" then
        vehicleProperties.fuelLevel = tonumber(vehicleFuel) or vehicleProperties.fuelLevel
        if type(bodyDamage) == "number" then
            vehicleProperties.bodyHealth = bodyDamage + 0.0
        end
        if type(engineDamage) == "number" then
            vehicleProperties.engineHealth = engineDamage + 0.0
        end
    end
    
    -- Run verification event
    local verificationPassed = false
    local success = pcall(function()
        TriggerEvent(
            "jg-advancedgarages:client:insert-vehicle-verification",
            currentVehicle,
            vehiclePlate,
            garageId,
            existingVehicle,
            vehicleProperties,
            vehicleFuel,
            bodyDamage,
            engineDamage,
            fuelTankDamage,
            function(result)
                verificationPassed = result
            end
        )
    end)
    
    if not success or not verificationPassed then
        isStoringVehicle = false
        debugPrint("jg-advancedgarages:client:insert-vehicle-verification returned false or pcall failed: " .. (error or ""), "debug")
        return false
    end
    
    -- Store vehicle on server
    local storeSuccess = lib.callback.await(
        "jg-advancedgarages:server:store-vehicle",
        false,
        garageId,
        VehToNet(currentVehicle),
        vehiclePlate,
        vehicleProperties,
        vehicleFuel,
        bodyDamage,
        engineDamage,
        fuelTankDamage
    )
    
    if not storeSuccess then
        isStoringVehicle = false
        return false
    end
    
    -- Remove vehicle keys
    Framework.Client.VehicleRemoveKeys(vehiclePlate, currentVehicle, garageData and garageData.garageType)
    
    -- Only warp air/sea players if they would fall after the vehicle is deleted
    if garageData and garageData.coords and (vehicleType == "air" or vehicleType == "sea") then
        local playerPed = cache.ped or PlayerPedId()
        local height = GetEntityHeightAboveGround(playerPed)
        if height > 8.0 then
            local garageCoords = garageData.coords
            SetEntityCoords(playerPed, garageCoords.x, garageCoords.y, garageCoords.z, false, false, false, false)
        end
    end
    
    -- Trigger insert event
    TriggerEvent("jg-advancedgarages:client:InsertVehicle:config", currentVehicle, existingVehicle, garageData and garageData.garageType)
    
    -- Handle Wasabi Ambulance integration
    if GetResourceState("wasabi_ambulance") == "started" and garageData and garageData.garageType == "job" then
        local success = pcall(function()
            exports.wasabi_ambulance:deleteStretcherFromVehicle(currentVehicle)
        end)
        
        if not success then
            debugPrint("Wasabi Ambulance integration did not delete stretcher", "warning")
        end
    end
    
    Framework.Client.Notify(Locale.vehicleParkedSuccess, "success")
    isStoringVehicle = false
    return true
end

-- Transfer vehicle between garages or players
function transferVehicle(transferType, garageId, vehiclePlate, playerId, targetGarageId, fromGarageId)
    if transferType == "garage" and targetGarageId then
        return lib.callback.await(
            "jg-advancedgarages:server:transfer-vehicle-garage",
            false,
            vehiclePlate,
            garageId,
            fromGarageId,
            targetGarageId
        )
    elseif transferType == "player" and playerId then
        local success = lib.callback.await(
            "jg-advancedgarages:server:transfer-vehicle-to-player",
            false,
            vehiclePlate,
            garageId,
            playerId
        )
        
        if not success then
            return false
        end
        
        TriggerEvent("jg-advancedgarages:client:TransferVehicle:config", vehiclePlate, playerId)
        return true
    end
    
    print("^1[ERROR] invalid transfer type or invalid playerId/garageId")
    return false
end

-- Server callback to make players leave vehicle
lib.callback.register("jg-advancedgarages:client:leave-vehicle", function(vehicleNetId, vehicleType)
    local vehicle = NetToVeh(vehicleNetId)
    SetVehicleDoorsLocked(vehicle, 2)
    
    -- Remove all passengers
    for seatIndex = -1, 5 do
        local ped = GetPedInVehicleSeat(vehicle, seatIndex)
        if ped then
            TaskLeaveVehicle(ped, vehicle, 0)
        end
    end
    
    -- Wait based on vehicle type
    if vehicleType == "air" then
        Wait(2500)
    else
        Wait(1500)
    end
end)

-- NUI Callbacks
RegisterNUICallback("drive-vehicle", function(data, callback)
    local spawnCoords = nil
    
    if data.spawnCoords then
        spawnCoords = vec(
            data.spawnCoords.x or 0,
            data.spawnCoords.y or 0,
            data.spawnCoords.z or 0,
            data.spawnCoords.w or 0
        )
    end
    
    local ok, result = pcall(driveVehicleOut, data.plate, data.garageId, data.spawnerIndex, spawnCoords)
    
    if not ok then
        print("^1[ERROR] drive-vehicle: " .. tostring(result) .. "^0")
        Framework.Client.Notify("Could not take vehicle out (see F8).", "error")
        callback({ error = true })
        return
    end
    
    if not result then
        Framework.Client.Notify("Could not take vehicle out.", "error")
        callback({ error = true })
        return
    end
    
    callback(result)
end)

RegisterNUICallback("garage-transfer-vehicle", function(data, callback)
    local result = transferVehicle(
        data.transferType,
        data.garageId,
        data.plate,
        data.transferPlayerId,
        data.transferGarageId,
        data.fromGarageId
    )
    
    if not result then
        callback({ error = true })
        return
    end
    
    callback(result)
end)

RegisterNUICallback("vehicle-set-nickname", function(data, callback)
    local result = lib.callback.await(
        "jg-advancedgarages:server:vehicle-set-nickname",
        false,
        data.plate,
        data.nickname,
        data.garageId
    )
    
    if not result then
        callback({ error = true })
        return
    end
    
    callback(result)
end)

RegisterNUICallback("enter-garage-interior", function(data, callback)
    Framework.Client.Notify(Locale.actionNotAllowedError, "error")
    callback({ error = true })
end)

-- Network Events
RegisterNetEvent("jg-advancedgarages:client:open-garage", openGarageMenu)
RegisterNetEvent("jg-advancedgarages:client:store-vehicle", storeVehicleInGarage)

RegisterNetEvent("jg-advancedgarages:client:ShowGarage", function(garageId, unknown, vehicleType)
    openGarageMenu(garageId, vehicleType)
end)

RegisterNetEvent("jg-advancedgarages:client:ShowGangGarage", function(garageId)
    openGarageMenu(garageId, "car")
end)

RegisterNetEvent("jg-advancedgarages:client:ShowJobGarage", function(garageId)
    openGarageMenu(garageId, "car")
end)

RegisterNetEvent("jg-advancedgarages:client:InsertVehicle", function(garageId, unknown, vehicleType)
    storeVehicleInGarage(garageId, vehicleType)
end)