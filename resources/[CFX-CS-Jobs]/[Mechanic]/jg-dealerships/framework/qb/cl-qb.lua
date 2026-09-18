if (Config.Framework == "auto" and GetResourceState("qb-core") == "started") or Config.Framework == "QBCore" then
  -- Player data
  Globals.PlayerData = QBCore.Functions.GetPlayerData()
  Framework.Client.SetPlayerLoggedIn(type(Globals.PlayerData) == "table" and Globals.PlayerData.citizenid ~= nil)

  RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Globals.PlayerData = QBCore.Functions.GetPlayerData()
    Framework.Client.SetPlayerLoggedIn(true)
    TriggerServerEvent("jg-dealerships:server:framework-employment-refresh")
  end)

  RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    Framework.Client.SetPlayerLoggedIn(false)
  end)

  RegisterNetEvent("QBCore:Client:OnJobUpdate")
  AddEventHandler("QBCore:Client:OnJobUpdate", function(job)
    Globals.PlayerData.job = job
    Locations.Client.RecreatePermissionRestrictedInteractions()
    TriggerServerEvent("jg-dealerships:server:framework-employment-refresh")
  end)

  RegisterNetEvent("QBCore:Client:OnGangUpdate")
  AddEventHandler("QBCore:Client:OnGangUpdate", function(gang)
    Globals.PlayerData.gang = gang
    Locations.Client.RecreatePermissionRestrictedInteractions()
  end)

  -- For jacksam's job creator
  RegisterNetEvent("jobs_creator:injectJobs", function(jobs)
    QBCore.Jobs = jobs
  end)
end
