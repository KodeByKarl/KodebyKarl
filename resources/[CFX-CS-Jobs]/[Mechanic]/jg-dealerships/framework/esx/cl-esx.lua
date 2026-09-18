if (Config.Framework == "auto" and GetResourceState("es_extended") == "started") or Config.Framework == "ESX" then
  -- Player data
  Globals.PlayerData = ESX.GetPlayerData()
  Framework.Client.SetPlayerLoggedIn(type(Globals.PlayerData) == "table" and Globals.PlayerData.identifier ~= nil)

  local function onPlayerLoad(xPlayer)
    if xPlayer then Globals.PlayerData = xPlayer end

    lib.waitFor(function()
      return Globals.PlayerData and cache.ped
    end, "Ped has not loaded or GetPlayerData returned false (waited 30 seconds)", 30000)

    Framework.Client.SetPlayerLoggedIn(true)
    TriggerServerEvent("jg-dealerships:server:framework-employment-refresh")
  end

  RegisterNetEvent("esx:playerLoaded", onPlayerLoad)
  RegisterNetEvent("esx:onPlayerSpawn", onPlayerLoad)
  RegisterNetEvent("esx:onPlayerLogout", function()
    Framework.Client.SetPlayerLoggedIn(false)
  end)

  RegisterNetEvent("esx:setJob")
  AddEventHandler("esx:setJob", function(job)
    Globals.PlayerData.job = job
    Locations.Client.RecreatePermissionRestrictedInteractions()
    TriggerServerEvent("jg-dealerships:server:framework-employment-refresh")
  end)
end
