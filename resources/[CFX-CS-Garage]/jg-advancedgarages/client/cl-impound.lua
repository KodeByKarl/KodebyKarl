local closestVehicleDistance = 5.0
local selectedVehicle = nil

local function getImpoundLocations(vehicleType)
  local impoundLocations = lib.callback.await("jg-advancedgarages:server:get-impound-locations", false, vehicleType)
  return impoundLocations or {}
end

local function showImpoundForm()
  if Framework.Client.IsPlayerDead() then
    Framework.Client.Notify(Locale.playerIsDead, "error")
    return false
  end

  local playerCoords = GetEntityCoords(cache.ped)
  selectedVehicle = lib.getClosestVehicle(playerCoords, closestVehicleDistance, true)

  if not selectedVehicle or selectedVehicle == 0 then
    Framework.Client.Notify(Locale.moveCloserToVehicleError, "error")
    return false
  end

  local vehicleType = getVehicleType(GetEntityModel(selectedVehicle))
  local impoundLocations = getImpoundLocations(vehicleType)
  if #impoundLocations == 0 then
    Framework.Client.Notify(Locale.actionNotAllowedError, "error")
    return false
  end

  local plate = Framework.Client.GetPlate(selectedVehicle)
  local archetype = GetEntityArchetypeName(selectedVehicle)
  local vehicleData = lib.callback.await("jg-advancedgarages:server:get-vehicle", false, archetype, plate)

  -- NPC vehicle can be deleted immediately without DB impound flow.
  if not vehicleData then
    deleteVehicle(selectedVehicle)
    Framework.Client.Notify(Locale.vehicleImpoundSuccess .. " (NPC)", "success")
    return true
  end

  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(false)
  SendNUIMessage({
    type = "show-impound-form",
    impoundLocations = impoundLocations,
    plate = plate,
    config = Config,
    locale = Locale
  })
end

local function impoundSelectedVehicle(impoundData)
  if not selectedVehicle or not DoesEntityExist(selectedVehicle) then
    return false
  end

  local plate = Framework.Client.GetPlate(selectedVehicle)
  local vehicleProps = Framework.Client.GetVehicleProperties(selectedVehicle)
  local fuel = Framework.Client.VehicleGetFuel(selectedVehicle)
  local body, engine, deformation = getVehicleDamage(selectedVehicle)

  local success = lib.callback.await(
    "jg-advancedgarages:server:impound-vehicle",
    false,
    impoundData,
    VehToNet(selectedVehicle),
    plate,
    vehicleProps,
    fuel,
    body,
    engine,
    deformation
  )

  if not success then
    return false
  end

  TriggerEvent("jg-advancedgarages:client:ImpoundVehicle:config", selectedVehicle)
  return true
end

local function driveVehicleOutOfImpound(impoundId, originalGarageId, plate)
  local success, networkId, vehicleData, spawnData, spawnCoords = lib.callback.await(
    "jg-advancedgarages:server:impound-remove-vehicle",
    false,
    impoundId,
    originalGarageId,
    plate,
    true
  )

  local vehicle = networkId and NetToVeh(networkId) or false
  if not success then
    return false
  end

  if Config.SpawnVehiclesWithServerSetter and not vehicle then
    print("^1There was a problem spawning in your vehicle")
    return false
  end

  if not vehicle and not Config.SpawnVehiclesWithServerSetter then
    local spawnInside = not Config.DoNotSpawnInsideVehicle
    vehicle = spawnVehicleClient(
      (vehicleData and vehicleData.id) or 0,
      vehicleData.model,
      plate,
      spawnCoords,
      spawnInside,
      spawnData,
      "personal"
    )

    if not vehicle then
      print("^1There was a problem spawning in your vehicle")
      return false
    end
  end

  if not vehicle then
    debugPrint("Value of `vehicle` is false", "warning")
    return false
  end

  lib.callback.await("jg-advancedgarages:server:impound-vehicle-driven-out", false, plate, VehToNet(vehicle))
  return true
end

RegisterNUICallback("impound-vehicle", function(data, cb)
  local ok = impoundSelectedVehicle(data)
  if not ok then
    return cb({ error = true })
  end

  cb(ok)
end)

RegisterNUICallback("impound-return-vehicle", function(data, cb)
  local success = lib.callback.await(
    "jg-advancedgarages:server:impound-remove-vehicle",
    false,
    data.impoundId,
    data.originalGarageId,
    data.plate,
    false
  )

  if not success then
    return cb({ error = true })
  end

  -- Server already sends a success notification for this path.
  -- Refresh current impound menu so the returned vehicle disappears immediately.
  local refreshGarageId = data.garageId or data.impoundId
  if refreshGarageId then
    local refreshVehicleType = data.vehicleType or "car"
    CreateThread(function()
      Wait(100)
      openGarageMenu(refreshGarageId, refreshVehicleType)
    end)
  end

  cb(success)
end)

RegisterNUICallback("impound-drive-vehicle", function(data, cb)
  local success = driveVehicleOutOfImpound(data.impoundId, data.originalGarageId, data.plate)
  if not success then
    return cb({ error = true })
  end

  cb(success)
end)

RegisterNetEvent("jg-advancedgarages:client:show-impound-form", showImpoundForm)
RegisterNetEvent("jg-advancedgarages:client:ImpoundVehicle", showImpoundForm)
