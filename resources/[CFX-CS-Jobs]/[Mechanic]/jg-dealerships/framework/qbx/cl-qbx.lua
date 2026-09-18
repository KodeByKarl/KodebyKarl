if (Config.Framework == "auto" and GetResourceState("qbx_core") == "started") or Config.Framework == "Qbox" then
  local function syncLoginState(loggedIn)
    loggedIn = loggedIn == true

    if loggedIn then
      Globals.PlayerData = exports.qbx_core:GetPlayerData()
    else
      Globals.PlayerData = {}
    end

    if Globals.PlayerLoggedIn == loggedIn then return end

    DebugPrint("[QBX] Synchronising dealership login state: " .. tostring(loggedIn))
    Framework.Client.SetPlayerLoggedIn(loggedIn)
  end

  Globals.PlayerData = exports.qbx_core:GetPlayerData()

  AddStateBagChangeHandler("isLoggedIn", ("player:%s"):format(cache.serverId), function(_, _, loggedIn)
    syncLoginState(loggedIn)
    if loggedIn then
      TriggerServerEvent("jg-dealerships:server:framework-employment-refresh")
    end
  end)

  RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    syncLoginState(true)
  end)

  RegisterNetEvent("qbx_core:client:playerLoggedOut", function()
    syncLoginState(false)
  end)

  RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
    Globals.PlayerData = Globals.PlayerData or {}
    Globals.PlayerData.job = job
    Locations.Client.RecreatePermissionRestrictedInteractions()
    TriggerServerEvent("jg-dealerships:server:framework-employment-refresh")
  end)

  RegisterNetEvent("QBCore:Client:OnGangUpdate", function(gang)
    Globals.PlayerData = Globals.PlayerData or {}
    Globals.PlayerData.gang = gang
    Locations.Client.RecreatePermissionRestrictedInteractions()
  end)

  CreateThread(function()
    Wait(0)
    local playerData = exports.qbx_core:GetPlayerData()
    syncLoginState(type(playerData) == "table" and playerData.citizenid ~= nil)
  end)
end
