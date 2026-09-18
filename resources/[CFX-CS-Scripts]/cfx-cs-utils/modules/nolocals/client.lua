--[[
    Disables ambient local peds and vehicles (population).
    Based on: https://github.com/stratolark/nolocals
]]

local Config = require 'configs.nolocals'

if not Config or not Config.Enabled then
    return
end

local dispatchDisabled = false

CreateThread(function()
    while true do
        local sleep = 0
        local ped = cache.ped or PlayerPedId()
        local playerId = cache.playerId or PlayerId()

        if Config.ClearVehicleGenerators then
            local pos = GetEntityCoords(ped)
            local r = Config.GeneratorRadius or 500.0
            RemoveVehiclesFromGeneratorsInArea(
                pos.x - r, pos.y - r, pos.z - r,
                pos.x + r, pos.y + r, pos.z + r
            )
        end

        if Config.DisableDispatch then
            if not dispatchDisabled then
                for i = 1, 15 do
                    EnableDispatchService(i, false)
                end
                dispatchDisabled = true
            end
        end

        if Config.IgnoreWanted then
            SetPlayerWantedLevel(playerId, 0, false)
            SetPlayerWantedLevelNow(playerId, false)
            SetPlayerWantedLevelNoDrop(playerId, 0, false)
            SetPoliceIgnorePlayer(playerId, true)
            SetDispatchCopsForPlayer(playerId, false)
        end

        if Config.DisablePeds then
            SetPedPopulationBudget(0)
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        end

        if Config.DisableVehicles then
            SetVehiclePopulationBudget(0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            SetGarbageTrucks(false)
            SetRandomBoats(false)
            SetCreateRandomCops(false)
            SetCreateRandomCopsNotOnScenarios(false)
            SetCreateRandomCopsOnScenarios(false)
        end

        Wait(sleep)
    end
end)
