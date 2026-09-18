-- Vehicle Customization System for FiveM Advanced Garages
-- Deobfuscated from cl-vehicle.lua

local previewCamera = nil
local previewVehicle = nil
local originalVehicleHeading = 0

-- Function to show vehicle plate change form
function showVehiclePlateForm()
    -- Check if player is inside a vehicle
    if not cache.vehicle then
        Framework.Client.Notify(Locale.notInsideVehicleError, "error")
        return false
    end
    
    -- Get current vehicle plate and archetype
    local currentPlate = Framework.Client.GetPlate(cache.vehicle)
    local vehicleArchetype = GetEntityArchetypeName(cache.vehicle)
    
    -- Check if vehicle exists in database
    local vehicleData = lib.callback.await("jg-advancedgarages:server:get-vehicle", false, vehicleArchetype, currentPlate)
    
    if not vehicleData then
        return false
    end
    
    -- Show UI for plate change
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    
    SendNUIMessage({
        type = "show-vplate-form",
        plate = currentPlate,
        locale = Locale,
        config = Config
    })
end

-- Function to change vehicle plate
function changeVehiclePlate(newPlate)
    newPlate = newPlate:upper()
    
    -- Check if player is inside a vehicle
    if not cache.vehicle then
        Framework.Client.Notify(Locale.notInsideVehicleError, "error")
        return false
    end
    
    -- Get current plate
    local currentPlate = Framework.Client.GetPlate(cache.vehicle)
    
    if not currentPlate then
        debugPrint("Framework.Client.GetPlate returned nil.", "warning", "Plate: " .. currentPlate)
        return false
    end
    
    -- Update plate on server
    local plateUpdateResult = lib.callback.await("jg-advancedgarages:server:vehicle-update-plate", false, currentPlate, newPlate)
    
    if not plateUpdateResult then
        debugPrint("jg-advancedgarages:server:vehicle-update-plate returned nil.", "warning", currentPlate, newPlate)
        return false
    end
    
    -- Handle fake plates integration if available
    local fakePlatesState = GetResourceState("brazzers-fakeplates")
    if fakePlatesState == "started" then
        local fakePlate = lib.callback.await("jg-advancedgarages:server:brazzers-get-fakeplate-from-plate", false, currentPlate)
        if fakePlate then
            currentPlate = fakePlate
        end
    end
    
    -- Remove old keys and set new plate
    Framework.Client.VehicleRemoveKeys(currentPlate, cache.vehicle, "personal")
    setVehiclePlateText(cache.vehicle, newPlate)
    Framework.Client.VehicleGiveKeys(newPlate, cache.vehicle, "personal")
    
    return true
end

-- Function to exit livery/extras preview mode
function exitLiveryExtrasPreview()
    -- Check if preview vehicle exists
    if not previewVehicle or not DoesEntityExist(previewVehicle) then
        return false
    end
    
    -- Restore vehicle to normal state
    SetEntityHeading(previewVehicle, originalVehicleHeading)
    SetEntityVisible(previewVehicle, true, false)
    FreezeEntityPosition(previewVehicle, false)
    
    -- Clean up camera
    if previewCamera and IsCamActive(previewCamera) then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(previewCamera, false)
        previewCamera = nil
    end
    
    return true
end

-- Function to apply livery to preview vehicle
function applyVehicleLivery(liveryId)
    -- Check if preview vehicle exists
    if not previewVehicle or not DoesEntityExist(previewVehicle) then
        return false
    end
    
    -- Apply livery modifications
    SetVehicleModKit(previewVehicle, 0)
    SetVehicleMod(previewVehicle, 48, liveryId, false)
    SetVehicleLivery(previewVehicle, liveryId)
    
    return true
end

-- Function to toggle vehicle extra
function toggleVehicleExtra(extraId, isDisabled)
    -- Check if preview vehicle exists
    if not previewVehicle or not DoesEntityExist(previewVehicle) then
        return false
    end
    
    -- Check if extra exists on vehicle
    local extraExists = DoesExtraExist(previewVehicle, extraId)
    if not extraExists then
        Framework.Client.Notify("EXTRA_NOT_AVAILABLE", "error")
        return false
    end
    
    -- Toggle the extra (0 = on, 1 = off)
    SetVehicleExtra(previewVehicle, extraId, isDisabled)
    SetVehicleFixed(previewVehicle) -- Fix vehicle after modifying extras
    
    return true
end

-- Function to show liveries and extras customization menu
function showLiveriesExtrasMenu(vehicle)
    previewVehicle = vehicle
    
    -- Check if vehicle exists
    if not previewVehicle or not DoesEntityExist(previewVehicle) then
        return false
    end
    
    -- Get vehicle position and setup camera
    local vehicleCoords = GetEntityCoords(previewVehicle)
    
    -- Hide and freeze vehicle for preview
    SetEntityVisible(previewVehicle, false, false)
    FreezeEntityPosition(previewVehicle, true)
    
    -- Store original heading
    originalVehicleHeading = GetEntityHeading(previewVehicle)
    
    -- Create preview camera
    previewCamera = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        vehicleCoords.x - 6,  -- Position camera to the left of vehicle
        vehicleCoords.y,
        vehicleCoords.z + 2,  -- Elevated view
        0.0,                  -- Rotation X
        0.0,                  -- Rotation Y
        270.0,                -- Rotation Z (facing right)
        0.0,                  -- Field of view (will be set separately)
        false,                -- Unknown parameter
        0                     -- Unknown parameter
    )
    
    -- Configure camera
    SetCamActive(previewCamera, true)
    SetCamFov(previewCamera, 60.0)
    PointCamAtCoord(previewCamera, vehicleCoords.x, vehicleCoords.y + 1, vehicleCoords.z)
    
    -- Enable script camera rendering
    RenderScriptCams(true, true, 1, true, true)
    
    -- Build extras information
    local vehicleExtras = {}
    for extraId = 1, 14 do
        vehicleExtras[#vehicleExtras + 1] = {
            id = extraId,
            available = DoesExtraExist(previewVehicle, extraId),
            enabled = IsVehicleExtraTurnedOn(previewVehicle, extraId)
        }
    end
    
    -- Show UI
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = "show-liveries-extras-menu",
        extras = vehicleExtras,
        currentLivery = GetVehicleLivery(previewVehicle),
        liveriesCount = GetVehicleLiveryCount(previewVehicle),
        locale = Locale,
        config = Config
    })
    
    -- Create rotation thread for vehicle preview
    CreateThread(function()
        Wait(500) -- Initial delay
        local rotationHeading = originalVehicleHeading
        
        while previewCamera do
            -- Check if we should continue rotating
            if not Config.DoNotSpawnInsideVehicle then
                if not cache.vehicle then
                    break
                end
            end
            
            -- Rotate vehicle slowly
            rotationHeading = rotationHeading + 0.25
            SetEntityLocallyVisible(previewVehicle)
            SetEntityHeading(previewVehicle, rotationHeading)
            
            Wait(0)
        end
        
        -- Clean up if player exited vehicle during preview
        if not Config.DoNotSpawnInsideVehicle then
            if not cache.vehicle then
                exitLiveryExtrasPreview()
            end
        end
    end)
end

-- NUI Callback: Change vehicle plate
RegisterNUICallback("change-vehicle-plate", function(data, callback)
    local plateChangeResult = changeVehiclePlate(data.newPlate)
    
    if not plateChangeResult then
        return callback({ error = true })
    end
    
    callback(plateChangeResult)
end)

-- NUI Callback: Exit liveries and extras menu
RegisterNuiCallback("exit-liveries-extras-menu", function(data, callback)
    local exitResult = exitLiveryExtrasPreview()
    
    if not exitResult then
        return callback({ error = true })
    end
    
    callback(exitResult)
end)

-- NUI Callback: Toggle vehicle livery
RegisterNUICallback("toggle-livery", function(data, callback)
    local liveryResult = applyVehicleLivery(data.livery_id)
    
    if not liveryResult then
        return callback({ error = true })
    end
    
    callback(liveryResult)
end)

-- NUI Callback: Toggle vehicle extra
RegisterNUICallback("toggle-extra", function(data, callback)
    local extraResult = toggleVehicleExtra(data.extra_id, data.disabled)
    
    if not extraResult then
        return callback({ error = true })
    end
    
    callback(extraResult)
end)

-- Network Event: Show vehicle plate form
RegisterNetEvent("jg-advancedgarages:client:show-vplate-form", showVehiclePlateForm)