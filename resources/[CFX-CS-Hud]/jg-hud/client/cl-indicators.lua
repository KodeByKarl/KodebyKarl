local DEFAULT_INDICATOR_STATE = { false, false }

local function cloneDefaultIndicatorState()
    return { DEFAULT_INDICATOR_STATE[1], DEFAULT_INDICATOR_STATE[2] }
end

function GetIndicatingState(vehicle)
    if not vehicle or vehicle == 0 then
        return cloneDefaultIndicatorState()
    end

    local state = Entity(vehicle).state
    local indicate = state and state.indicate
    if not indicate then
        return cloneDefaultIndicatorState()
    end

    return indicate
end

function IsVehicleIndicating(vehicle, side)
    if not vehicle or vehicle == 0 then
        return false
    end

    local indicate = Entity(vehicle).state.indicate
    if not indicate then
        return false
    end

    local right = indicate[1]
    local left = indicate[2]

    if side == "hazards" then
        return right and left
    end

    if side == "right" then
        return right and not left
    end

    if side == "left" then
        return (not right) and left
    end

    return false
end

local function canToggleIndicators()
    return cache.vehicle
        and cache.seat == -1
        and not IsPauseMenuActive()
end

function Indicate(side)
    if not canToggleIndicators() then
        return false
    end

    local indicatorState = cloneDefaultIndicatorState()
    local vehicle = cache.vehicle

    if side == "left" then
        if not IsVehicleIndicating(vehicle, "left") then
            indicatorState = { false, true }
        end
    elseif side == "right" then
        if not IsVehicleIndicating(vehicle, "right") then
            indicatorState = { true, false }
        end
    elseif side == "hazards" then
        if not IsVehicleIndicating(vehicle, "hazards") then
            indicatorState = { true, true }
        end
    end

    Entity(vehicle).state:set("indicate", indicatorState, true)
end

AddStateBagChangeHandler("indicate", "", function(bagName, _, value)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 then
        return
    end

    local indicate = value or cloneDefaultIndicatorState()
    for indicatorIndex, enabled in ipairs(indicate) do
        SetVehicleIndicatorLights(vehicle, indicatorIndex - 1, enabled)
    end

    SendNUIMessage({
        type = "vehicleStatusUpdate",
        data = {
            indicators = indicate
        }
    })
end)

if Config.IndicatorLeftKeybind then
    RegisterCommand("indicate_left", function()
        Indicate("left")
    end)

    RegisterKeyMapping(
        "indicate_left",
        "Vehicle indicate left",
        "keyboard",
        Config.IndicatorLeftKeybind or "LEFT"
    )
end

if Config.IndicatorRightKeybind then
    RegisterCommand("indicate_right", function()
        Indicate("right")
    end)

    RegisterKeyMapping(
        "indicate_right",
        "Vehicle indicate right",
        "keyboard",
        Config.IndicatorRightKeybind or "RIGHT"
    )
end

if Config.IndicatorHazardsKeybind then
    RegisterCommand("hazards", function()
        Indicate("hazards")
    end)

    RegisterKeyMapping(
        "hazards",
        "Vehicle hazards",
        "keyboard",
        Config.IndicatorHazardsKeybind or "UP"
    )
end
