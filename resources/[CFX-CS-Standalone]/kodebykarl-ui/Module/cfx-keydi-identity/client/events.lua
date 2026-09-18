RegisterNetEvent("esx_identity:showRegisterIdentity", function()
    IdentityUtils.Debug("Received event esx_identity:showRegisterIdentity")
    ToggleUI(true)
end)

RegisterNetEvent("esx_identity:alreadyRegistered", function()
    IdentityUtils.Debug("Player is already registered. Triggering skin load.")
    TriggerEvent("esx_skin:playerRegistered")
end)

RegisterNetEvent('esx:onPlayerSpawn', function()
    TriggerServerEvent('esx_identity:checkIdentity')
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('esx_identity:checkIdentity')
end)

CreateThread(function()
    Wait(1500)
    if ESX.IsPlayerLoaded and ESX.IsPlayerLoaded() then
        TriggerServerEvent('esx_identity:checkIdentity')
    end
end)
