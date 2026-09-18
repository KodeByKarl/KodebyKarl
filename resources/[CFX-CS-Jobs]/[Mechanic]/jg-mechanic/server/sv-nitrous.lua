local function hasNitrousInstalled(source, vehicleState)
  if not vehicleState.nitrousInstalledBottles or vehicleState.nitrousInstalledBottles == 0 then
    Framework.Server.Notify(source, Locale.nitrousNotInstalled, "error")
    return false
  end
  return true
end

local function canRefillBottle(source, vehicleState)
  local installedBottles = vehicleState.nitrousInstalledBottles
  local filledBottles = vehicleState.nitrousFilledBottles

  if installedBottles == filledBottles then
    if not (installedBottles - 1 == filledBottles and vehicleState.nitrousCapacity > 0) then
      Framework.Server.Notify(source, Locale.noEmptyNitrousBottlesToReplace, "error")
      return false
    end
  end
  return true
end

local function refillVehicleWithBottle(source, vehicle)
  if not vehicle or vehicle == 0 then
    return false
  end

  local vehicleState = Entity(vehicle).state
  if not hasNitrousInstalled(source, vehicleState) then
    return false
  end

  if not canRefillBottle(source, vehicleState) then
    return false
  end

  if not Framework.Server.RemoveItem(source, "nitrous_bottle") then
    Framework.Server.Notify(source, Locale.couldNotRemoveNitrousInvItem, "error")
    return false
  end

  setVehicleStatebag(vehicle, "nitrousFilledBottles", vehicleState.nitrousFilledBottles + 1, true)

  if not Framework.Server.GiveItem(source, "empty_nitrous_bottle") then
    Framework.Server.Notify(source, Locale.couldNotGiveNitrousInvItem, "error")
    return false
  end

  Framework.Server.Notify(source, Locale.nitrousBottleInstalled, "success")
  return true
end

RegisterNetEvent("jg-mechanic:server:use-nitrous-bottle", function()
  local source = source
  local playerPed = GetPlayerPed(source)
  local vehicle = GetVehiclePedIsIn(playerPed, false)

  if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
    Framework.Server.Notify(source, Locale.notInsideVehicle, "error")
    return
  end

  refillVehicleWithBottle(source, vehicle)
end)

lib.callback.register("jg-mechanic:server:can-refill-bottle-in-current-vehicle", function(source)
  local playerPed = GetPlayerPed(source)
  local vehicle = GetVehiclePedIsIn(playerPed, false)

  if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
    Framework.Server.Notify(source, Locale.notInsideVehicle, "error")
    return false
  end

  local vehicleState = Entity(vehicle).state
  if not hasNitrousInstalled(source, vehicleState) then
    return false
  end

  if not canRefillBottle(source, vehicleState) then
    return false
  end

  return true
end)

lib.callback.register("jg-mechanic:server:refill-nitrous-bottle", function(source)
  local playerState = Player(source).state
  if not playerState then
    return false
  end

  local mechanicId = playerState.mechanicId
  if not mechanicId then
    return false
  end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local netId = playerState.tabletConnectedVehicle and playerState.tabletConnectedVehicle.netId
  local vehicle = NetworkGetEntityFromNetworkId(netId)

  if not vehicle or vehicle == 0 then
    return false
  end

  return refillVehicleWithBottle(source, vehicle)
end)

lib.callback.register("jg-mechanic:server:install-new-bottle", function(source)
  local playerState = Player(source).state
  if not playerState then
    return false
  end

  local mechanicId = playerState.mechanicId
  if not mechanicId then
    return false
  end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local netId = playerState.tabletConnectedVehicle and playerState.tabletConnectedVehicle.netId
  local vehicle = NetworkGetEntityFromNetworkId(netId)
  if not vehicle or vehicle == 0 then
    return false
  end

  local vehicleState = Entity(vehicle).state
  local installedBottles = vehicleState.nitrousInstalledBottles or 0
  if installedBottles >= Config.NitrousMaxBottlesPerVehicle then
    Framework.Server.Notify(source, Locale.maxBottlesInstalled, "error")
    return false
  end

  if not Framework.Server.RemoveItem(source, "nitrous_install_kit") then
    Framework.Server.Notify(source, Locale.couldNotRemoveNitrousInstallInvItem, "error")
    return false
  end

  local newInstalledCount = (vehicleState.nitrousInstalledBottles or 0) + 1
  setVehicleStatebag(vehicle, "nitrousInstalledBottles", newInstalledCount, true)

  local newFilledCount = (vehicleState.nitrousFilledBottles or 0) + 1
  setVehicleStatebag(vehicle, "nitrousFilledBottles", newFilledCount, true)

  return true
end)
