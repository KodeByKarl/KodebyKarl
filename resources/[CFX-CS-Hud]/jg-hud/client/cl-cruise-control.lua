IsCruiseControlEnabled = false

local targetCruiseSpeed = 0.0

local CONTROL_GROUP_VEHICLE = 2
local CONTROL_VEH_MOVE_LR_LEFT = 63
local CONTROL_VEH_MOVE_LR_RIGHT = 64
local CONTROL_VEH_BRAKE = 72
local CONTROL_MOVE_UP_ONLY = 76
local CONTROL_CRUISE_SET_SPEED = 246

local function isSteeringOrAccelerating()
    return IsControlPressed(CONTROL_GROUP_VEHICLE, CONTROL_MOVE_UP_ONLY)
        or IsControlPressed(CONTROL_GROUP_VEHICLE, CONTROL_VEH_MOVE_LR_LEFT)
        or IsControlPressed(CONTROL_GROUP_VEHICLE, CONTROL_VEH_MOVE_LR_RIGHT)
end

local function isDrivingInDifferentDirection(vehicle, angleThresholdScale)
    angleThresholdScale = angleThresholdScale or 0.01

    local forwardVector = GetEntityForwardVector(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local speedMagnitude = math.sqrt(
        velocity.x ^ 2 + velocity.y ^ 2 + velocity.z ^ 2
    )

    if speedMagnitude < 1.0 then
        return false, 0.0
    end

    local normalizedVelocity = {
        x = velocity.x / speedMagnitude,
        y = velocity.y / speedMagnitude,
        z = velocity.z / speedMagnitude
    }

    local dot = forwardVector.x * normalizedVelocity.x
        + forwardVector.y * normalizedVelocity.y
        + forwardVector.z * normalizedVelocity.z

    local angle = math.deg(math.acos(math.max(-1, math.min(1, dot))))
    local isDifferentDirection = angle > (angleThresholdScale * 180)

    return isDifferentDirection, angle
end

local function startCruiseControlThread(initialVehicle)
    CreateThread(function()
        while cache.vehicle and IsCruiseControlEnabled and IsHudRunning do
            local currentVehicle = cache.vehicle
            local isEngineRunning = GetIsVehicleEngineRunning(initialVehicle)
            local currentSpeed = GetEntitySpeed(currentVehicle)
            local isOverriding = isSteeringOrAccelerating()

            if not isEngineRunning or isOverriding or currentSpeed < (targetCruiseSpeed - 1.5) then
                IsCruiseControlEnabled = false
                Wait(500)
                break
            end

            if not isOverriding and IsVehicleOnAllWheels(currentVehicle) and currentSpeed < targetCruiseSpeed then
                SetVehicleForwardSpeed(currentVehicle, targetCruiseSpeed)
            end

            if IsControlJustPressed(1, CONTROL_CRUISE_SET_SPEED) then
                targetCruiseSpeed = GetEntitySpeed(currentVehicle)
            end

            if IsControlJustPressed(CONTROL_GROUP_VEHICLE, CONTROL_VEH_BRAKE) then
                IsCruiseControlEnabled = false
                Wait(500)
                break
            end

            Wait(50)
        end
    end)
end

function ToggleCruiseControl(vehicle, seat)
    if not Config.EnableCruiseControl then
        return
    end

    if IsCruiseControlEnabled then
        IsCruiseControlEnabled = false
        return
    end

    if not vehicle or seat ~= -1 then
        return
    end

    if GetVehicleType(vehicle) ~= "land" then
        return
    end

    if GetEntitySpeed(vehicle) < 1.0 then
        return
    end

    if not GetIsVehicleEngineRunning(vehicle) then
        return
    end

    local reversingOrSkidding = isDrivingInDifferentDirection(vehicle)
    if reversingOrSkidding then
        return
    end

    if isSteeringOrAccelerating() then
        return
    end

    IsCruiseControlEnabled = true
    targetCruiseSpeed = GetEntitySpeed(vehicle)
    startCruiseControlThread(vehicle)
end

if Config.EnableCruiseControl and Config.CruiseControlKeybind then
    RegisterCommand("toggle_cruise", function()
        ToggleCruiseControl(cache.vehicle, cache.seat)
    end, false)

    RegisterKeyMapping(
        "toggle_cruise",
        "Toggle cruise control",
        "keyboard",
        Config.CruiseControlKeybind or "J"
    )
end
