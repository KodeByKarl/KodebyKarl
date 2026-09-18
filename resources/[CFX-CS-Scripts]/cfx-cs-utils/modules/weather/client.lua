--[[
  Extra Sunny weather with a normal day / night clock.
  jg-hud reads GetClockHours — do not freeze time unless FreezeTime is true.
]]

local Config = require 'configs.weather'

if not Config or not Config.Enabled then
    return
end

local weather = (Config.Weather or 'EXTRASUNNY'):upper()
local hour = math.floor(tonumber(Config.Hour) or 12) % 24
local minute = math.floor(tonumber(Config.Minute) or 0) % 60
-- Only freeze when explicitly enabled (day + night cycle by default)
local freezeTime = Config.FreezeTime == true
local interval = math.max(1000, tonumber(Config.RefreshInterval) or 15000)

local function applyWeather()
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeOvertimePersist(weather, 0.0)
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
end

local function applyTime()
    if freezeTime then
        NetworkOverrideClockTime(hour, minute, 0)
        PauseClock(true)
        return
    end

    -- Day / night must keep moving
    PauseClock(false)
end

CreateThread(function()
    Wait(2500)
    PauseClock(false)
    applyWeather()
    applyTime()

    while true do
        applyWeather()
        applyTime()
        Wait(interval)
    end
end)

AddEventHandler('cfx-cs-weather:client:EnableSync', function()
    SetTimeout(100, function()
        applyWeather()
        applyTime()
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    PauseClock(false)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
end)
