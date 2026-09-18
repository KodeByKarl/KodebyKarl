--- ESX fires `esx:loadingScreenOff` after spawn. Export + event for manual fallbacks.

local shutDown = false

local function RequestShutdown()
    if shutDown then return end
    shutDown = true
    pcall(ShutdownLoadingScreenNui)
    pcall(ShutdownLoadingScreen)
end

exports('RequestShutdown', RequestShutdown)

AddEventHandler('esx:loadingScreenOff', function()
    RequestShutdown()
end)

AddEventHandler('playerSpawned', function()
    if shutDown then return end
    Wait(2500)
    RequestShutdown()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    if shutDown then return end
    Wait(2500)
    RequestShutdown()
end)

RegisterNetEvent('kodebykarl-loadingscreen:shutdown', function()
    RequestShutdown()
end)

RegisterCommand('closeloading', function()
    RequestShutdown()
end, false)
