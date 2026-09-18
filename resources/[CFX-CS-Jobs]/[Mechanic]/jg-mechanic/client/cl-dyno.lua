local isDynoActive = false
local dynoPlaybackByVehicle = {}
local DYNO_DURATION_MS = 33500
local DYNO_TICK_MS = 50

local function setWheelRotationSpeedBasedOnDrivetrain(vehicle, speed)
  local driveBiasFront = getVehicleHandlingValue(vehicle, "CHandlingData", "fDriveBiasFront")

  if driveBiasFront >= 0.5 then
    SetVehicleWheelRotationSpeed(vehicle, 0, speed)
    SetVehicleWheelRotationSpeed(vehicle, 1, speed)
  end

  if driveBiasFront <= 0.5 then
    SetVehicleWheelRotationSpeed(vehicle, 2, speed)
    SetVehicleWheelRotationSpeed(vehicle, 3, speed)
  end
end

local function applyDynoStep(vehicle, elapsedMs, durationMs)
  local rpm = math.min(1.0, (elapsedMs + 7500) / durationMs)
  local wheelSpeed = elapsedMs / 200
  SetVehicleCurrentRpm(vehicle, rpm)
  setWheelRotationSpeedBasedOnDrivetrain(vehicle, wheelSpeed)
end

local function getDynoVehicleKey(vehicle)
  local netId = NetworkGetNetworkIdFromEntity(vehicle)
  return netId ~= 0 and netId or vehicle
end

local function stopDynoPlayback(vehicle)
  local vehicleKey = getDynoVehicleKey(vehicle)
  dynoPlaybackByVehicle[vehicleKey] = nil
  if DoesEntityExist(vehicle) then
    setWheelRotationSpeedBasedOnDrivetrain(vehicle, 0)
  end
end

local function startDynoPlayback(vehicle, durationMs)
  if not DoesEntityExist(vehicle) then
    return
  end

  local vehicleKey = getDynoVehicleKey(vehicle)
  if dynoPlaybackByVehicle[vehicleKey] then
    return
  end

  dynoPlaybackByVehicle[vehicleKey] = true

  CreateThread(function()
    local playbackStart = GetGameTimer()
    local duration = durationMs or DYNO_DURATION_MS

    while dynoPlaybackByVehicle[vehicleKey] and DoesEntityExist(vehicle) do
      local elapsed = GetGameTimer() - playbackStart
      if elapsed >= duration then
        break
      end

      applyDynoStep(vehicle, elapsed, duration)
      Wait(DYNO_TICK_MS)
    end

    stopDynoPlayback(vehicle)
  end)
end

local function startDynoRun(vehicle)
  if isDynoActive then
    return
  end

  CreateThread(function()
    local startedAt = GetGameTimer()
    isDynoActive = true
    SetVehicleGravity(vehicle, false)
    Entity(vehicle).state:set("vehicleDyno", {
      active = true,
      duration = DYNO_DURATION_MS
    }, true)

    while (GetGameTimer() - startedAt) < DYNO_DURATION_MS do
      if not isDynoActive then
        break
      end

      Wait(100)
    end

    Entity(vehicle).state:set("vehicleDyno", false, true)
    SetVehicleGravity(vehicle, true)
    isDynoActive = false
  end)
end

AddStateBagChangeHandler("vehicleDyno", "", function(bagName, key, value)
  local vehicle = GetEntityFromStateBagName(bagName)
  if vehicle ~= 0 and DoesEntityExist(vehicle) then
    if not value or not value.active then
      stopDynoPlayback(vehicle)
      return
    end

    startDynoPlayback(vehicle, value.duration)
  end
end)

RegisterNUICallback("start-dyno", function(data, cb)
  local playerPed = cache.ped
  local vehicle = LocalPlayer.state.tabletConnectedVehicle and LocalPlayer.state.tabletConnectedVehicle.vehicleEntity

  if not vehicle or not DoesEntityExist(vehicle) then
    return cb(false)
  end

  CreateThread(function()
    SetNuiFocus(false, false)

    if GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
      hideTabletToShowInteractionPrompt(Locale.enterVehicleToStartDynoMsg)
      while GetPedInVehicleSeat(vehicle, -1) ~= playerPed do
        Wait(100)
      end
    end

    hideTabletToShowInteractionPrompt(Locale.startDynoMsg)
    while not IsControlJustPressed(0, 201) do
      Wait(0)
    end

    SetNuiFocus(true, true)
    showTabletAfterInteractionPrompt()

    cb({
      maxSpeed = getVehicleHandlingValue(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel"),
      fDriveInertia = getVehicleHandlingValue(vehicle, "CHandlingData", "fDriveInertia"),
      fInitialDriveForce = getVehicleHandlingValue(vehicle, "CHandlingData", "fInitialDriveForce")
    })
    startDynoRun(vehicle)
  end)
end)

RegisterNUICallback("stop-dyno", function(data, cb)
  isDynoActive = false
  cb(true)
end)

RegisterNUICallback("dyno-share-with-player", function(data, cb)
  local player = data.player
  local results = data.results

  if not player or not results then
    return cb(false)
  end

  local success = lib.callback.await("jg-mechanic:server:dyno-share-with-player", false, player, results)
  cb(success)
end)

RegisterNetEvent("jg-mechanic:client:dyno-show-results-sheet", function(results)
  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "show-dyno-share-sheet",
    results = results,
    locale = Locale,
    config = Config
  })
end)
