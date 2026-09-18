function OnEnteredVehicle(vehicle)
    SendNUIMessage({
        type = "enteredVehicle",
        vehicleType = GetVehicleType(vehicle)
    })
    
    DisplayRadarConditionally()
end

function OnExitedVehicle()
    SendNUIMessage({
        type = "exitedVehicle"
    })
    
    DisplayRadarConditionally()
end

local GetIsVehicleEngineRunning = GetIsVehicleEngineRunning
local GetEntitySpeed = GetEntitySpeed
local GetVehicleCurrentGear = GetVehicleCurrentGear
local GetEntityVelocity = GetEntityVelocity
local GetEntityForwardVector = GetEntityForwardVector
local GetVehicleCurrentRpm = GetVehicleCurrentRpm
local GetEntityCoords = GetEntityCoords
local GetEntityRotation = GetEntityRotation
local GetVehicleLightsState = GetVehicleLightsState
local GetVehicleEngineHealth = GetVehicleEngineHealth
local GetLandingGearState = GetLandingGearState
local GetTrainDoorCount = GetTrainDoorCount
local GetTrainDoorOpenRatio = GetTrainDoorOpenRatio
local IsBoatAnchored = IsBoatAnchored
local GetEntityModel = GetEntityModel

function GetTelemetryUpdateInterval()
    local performanceMode = UserSettingsData and UserSettingsData.performanceMode
    
    if performanceMode == "ultra" then
        return 200
    elseif performanceMode == "performance" then
        return 300
    elseif performanceMode == "lowResmon" then
        return 500
    end
    
    return 250
end

local isTelemetryThreadRunning = false

function StartVehicleTelemetryThread(vehicle)
    if isTelemetryThreadRunning then
        return
    end
    
    local vehicleType = GetVehicleType(vehicle)
    local isElectric = (vehicleType == "land") and (IsVehicleElectric and IsVehicleElectric(vehicle) or false)
    local updateInterval = GetTelemetryUpdateInterval()
    
    isTelemetryThreadRunning = true
    
    CreateThread(function()
        local lastSpeed = 0
        local lastGear = nil
        local lastRpm = 0
        local lastAltitude = 0
        
        while true do
            if not cache or not cache.vehicle or not IsHudRunning then
                isTelemetryThreadRunning = false
                break
            end
            
            local currentVehicle = cache.vehicle
            if currentVehicle ~= vehicle then
                isTelemetryThreadRunning = false
                break
            end
            
            local isEngineOn = GetIsVehicleEngineRunning(currentVehicle)
            local speed = GetEntitySpeed(currentVehicle)
            local convertedSpeed = Framework.Client.ConvertSpeed and Framework.Client.ConvertSpeed(speed, UserSettingsData and UserSettingsData.speedMeasurement) or speed
            
            local shouldSendUpdate = false
            local telemetryData = {speed = convertedSpeed, isElectric = isElectric}
            
            if math.abs(convertedSpeed - lastSpeed) >= 1 then
                lastSpeed = convertedSpeed
                shouldSendUpdate = true
            end
            
            if vehicleType == "land" then
                local currentGear = GetVehicleCurrentGear(currentVehicle)
                local velocity = GetEntityVelocity(currentVehicle)
                local forwardVector = GetEntityForwardVector(currentVehicle)
                local dotProduct = velocity.x * forwardVector.x + velocity.y * forwardVector.y
                
                if currentGear == 0 then
                    currentGear = "N"
                else
                    if isElectric then
                        currentGear = "D"
                    end
                end
                
                if dotProduct < 0 then
                    currentGear = "R"
                end
                
                if currentGear ~= lastGear then
                    lastGear = currentGear
                    telemetryData.gear = currentGear
                    shouldSendUpdate = true
                end
                
                local isBraking = false
                if isElectric and dotProduct > 0 then
                    isBraking = IsControlPressed and IsControlPressed(0, 72) or false
                end
                telemetryData.isBraking = isBraking
                
                if isEngineOn then
                    local rpm = math.floor(math.min(1.0, GetVehicleCurrentRpm(currentVehicle) - 0.05) * 8500)
                    if rpm ~= lastRpm then
                        lastRpm = rpm
                        telemetryData.rpm = {currentRpm = rpm, redline = 6000, maxRpm = 8000}
                        shouldSendUpdate = true
                    end
                else
                    if lastRpm ~= 0 then
                        lastRpm = 0
                        telemetryData.rpm = {currentRpm = 0, redline = 6000, maxRpm = 8000}
                        shouldSendUpdate = true
                    end
                end
                
            elseif vehicleType == "bicycle" or vehicleType == "air" then
                local coords = GetEntityCoords(currentVehicle)
                local altitude = Framework.Client.ConvertDistance and Framework.Client.ConvertDistance(coords.z, UserSettingsData and UserSettingsData.distanceMeasurement) or coords.z
                if math.abs(altitude - lastAltitude) > 5 then
                    lastAltitude = altitude
                    telemetryData.altitude = altitude
                    shouldSendUpdate = true
                end
                
                if vehicleType == "air" then
                    telemetryData.heading = GetEntityHeading and GetEntityHeading(currentVehicle) or 0
                    shouldSendUpdate = true
                end
            end
            
            if shouldSendUpdate then
                SendNUIMessage({
                    type = "vehicleTelemetryData",
                    data = telemetryData
                })
            end
            
            Wait(updateInterval)
        end
    end)
end

function GetStatusUpdateInterval()
    local performanceMode = UserSettingsData and UserSettingsData.performanceMode
    
    if performanceMode == "ultra" then
        return 500
    elseif performanceMode == "performance" then
        return 750
    elseif performanceMode == "lowResmon" then
        return 1500
    end
    
    return 1000
end

function SendVehicleStatusUpdate(statusData)
    SendNUIMessage({
        type = "vehicleStatusUpdate",
        data = statusData
    })
end

local isStatusThreadRunning = false

function StartVehicleStatusThread(vehicle)
    if isStatusThreadRunning then
        return
    end
    
    local vehicleType = GetVehicleType(vehicle)
    local updateInterval = GetStatusUpdateInterval()
    
    isStatusThreadRunning = true
    
    CreateThread(function()
        local lastEngineHealth = -1
        local lastFuel = -1
        local lastIndicators = nil
        local lastLights = -1
        local lastMileage = -1
        
        while true do
            if not cache.vehicle or not IsHudRunning then
                isStatusThreadRunning = false
                break
            end
            
            local currentVehicle = cache.vehicle
            if currentVehicle ~= vehicle then
                isStatusThreadRunning = false
                break
            end
            
            local isEngineOn = GetIsVehicleEngineRunning(currentVehicle)
            local _, lightsState, highBeamsOn = GetVehicleLightsState(currentVehicle)
            
            local engineHealth = 0
            if isEngineOn then
                engineHealth = math.floor((GetVehicleEngineHealth(currentVehicle) / 1000) * 100)
            end
            
            local fuel = Framework.Client.VehicleGetFuel(currentVehicle)
            local indicators = GetIndicatingState(currentVehicle)
            
            local sendUpdate = false
            local statusData = {
                engineOn = isEngineOn,
                headlights = lightsState,
                highBeams = highBeamsOn,
                anchored = IsBoatAnchored(currentVehicle),
                indicators = indicators,
                cruiseControl = IsCruiseControlEnabled,
                seatbelt = IsSeatbeltOn
            }
            
            if engineHealth ~= lastEngineHealth then
                lastEngineHealth = engineHealth
                statusData.engineHealth = engineHealth
                sendUpdate = true
            end
            
            if math.floor(fuel) ~= lastFuel then
                lastFuel = math.floor(fuel)
                statusData.fuel = fuel
                sendUpdate = true
            end
            
            if indicators ~= lastIndicators then
                lastIndicators = indicators
                sendUpdate = true
            end
            
            if lightsState ~= lastLights then
                lastLights = lightsState
                sendUpdate = true
            end
            
            if vehicleType == "train" then
                local doorsOpen = false
                for doorIndex = 0, GetTrainDoorCount(currentVehicle) - 1 do
                    if GetTrainDoorOpenRatio(currentVehicle, doorIndex) > 0.1 then
                        doorsOpen = true
                        break
                    end
                end
                statusData.isMetroTrain = true
                statusData.doorsOpen = doorsOpen
                sendUpdate = true
            end
            
            if vehicleType ~= "train" then
                local mileageKm = Framework.Client.GetVehicleMileageInKm(currentVehicle)
                if mileageKm then
                    local convertedMileage = mileageKm
                    if UserSettingsData and UserSettingsData.speedMeasurement == "mph" then
                        convertedMileage = Framework.Client.ConvertKmToMiles and Framework.Client.ConvertKmToMiles(mileageKm) or mileageKm
                    end
                    local mileage = math.floor(convertedMileage)
                    if mileage ~= lastMileage then
                        lastMileage = mileage
                        statusData.mileage = mileage
                        sendUpdate = true
                    end
                end
            end
            
            if sendUpdate then
                SendVehicleStatusUpdate(statusData)
            end
            
            Wait(updateInterval)
        end
    end)
end

function HandleVehicleChange(vehicle)
    if not vehicle or vehicle == 0 then
        OnExitedVehicle()
        return
    end
    
    StartVehicleStatusThread(vehicle)
    Wait(100)
    OnEnteredVehicle(vehicle)
    StartVehicleTelemetryThread(vehicle)
end

lib.onCache("vehicle", HandleVehicleChange)

function CheckVehicleOnLoad()
    if cache.vehicle then
        HandleVehicleChange(cache.vehicle)
    end
end

local lastRadarState = nil
CreateThread(function()
    while true do
        if cache and cache.vehicle and IsHudRunning then
            local inVehicle = true
            local showMinimapInVehicle = Config.ShowMinimapInVehicle
            local showMinimapOnFoot = Config.ShowMinimapOnFoot
            
            if showMinimapInVehicle == nil then
                showMinimapInVehicle = true
            end
            
            if showMinimapOnFoot == nil then
                showMinimapOnFoot = true
            end
            
            if UserSettingsData then
                if UserSettingsData.showMinimapInVehicle ~= nil then
                    showMinimapInVehicle = UserSettingsData.showMinimapInVehicle
                end
                if UserSettingsData.showMinimapOnFoot ~= nil then
                    showMinimapOnFoot = UserSettingsData.showMinimapOnFoot
                end
            end
            
            local shouldShow = IsHudVisible and showMinimapInVehicle
            if shouldShow ~= lastRadarState then
                lastRadarState = shouldShow
                DisplayRadar(shouldShow)
            end
        elseif not cache.vehicle then
            local showMinimapOnFoot = Config.ShowMinimapOnFoot
            if showMinimapOnFoot == nil then
                showMinimapOnFoot = true
            end
            
            if UserSettingsData and UserSettingsData.showMinimapOnFoot ~= nil then
                showMinimapOnFoot = UserSettingsData.showMinimapOnFoot
            end
            
            local shouldShow = IsHudVisible and showMinimapOnFoot
            if shouldShow ~= lastRadarState then
                lastRadarState = shouldShow
                DisplayRadar(shouldShow)
            end
        end
        Wait(1000)
    end
end)