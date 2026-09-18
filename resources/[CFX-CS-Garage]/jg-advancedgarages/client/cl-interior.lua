local INTERIOR_CAMERA_FOV = 40.0
local EXIT_POINT_DISTANCE = 3.0

local interiorCameras = {}
local spawnedInteriorVehicles = {}
local interiorActive = false
local interiorPoints = {}
local previousPlayerCoords = nil
local cutsceneActive = false
local currentGarageType = nil

local function stopInteriorCutscene()
  if #interiorCameras == 0 then
    return
  end

  for _, camera in ipairs(interiorCameras) do
    DestroyCam(camera, true)
  end

  interiorCameras = {}
  RenderScriptCams(false, true, 1000, true, true)
  cutsceneActive = false
end

local function playInteriorCutscene()
  local cutscene = Config.GarageInteriorCameraCutscene
  if not cutscene or not cutscene[1] or not cutscene[2] then
    return
  end

  local from = cutscene[1]
  local to = cutscene[2]

  local fromCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", from.x, from.y, from.z, 0.0, 0.0, from.w, INTERIOR_CAMERA_FOV, true, 2)
  local toCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", to.x, to.y, to.z, 0.0, 0.0, to.w, INTERIOR_CAMERA_FOV, true, 2)

  interiorCameras = { fromCam, toCam }
  cutsceneActive = true

  SetCamActive(fromCam, true)
  RenderScriptCams(true, false, 0, true, true)
  SetCamActiveWithInterp(toCam, fromCam, 3000, 0, 0)
  Wait(3000)

  stopInteriorCutscene()
end

local function clearInteriorState(onExit)
  local garageTypeForKeyRemoval = currentGarageType or "personal"
  interiorActive = false
  stopInteriorCutscene()

  SendNUIMessage({ type = "hide" })

  DoScreenFadeOut(500)
  Wait(500)

  for _, vehicleInfo in ipairs(spawnedInteriorVehicles) do
    if vehicleInfo.vehicle then
      DeleteEntity(vehicleInfo.vehicle)
      Framework.Client.VehicleRemoveKeys(
        vehicleInfo.plate,
        vehicleInfo.veh,
        garageTypeForKeyRemoval
      )
    end
  end

  spawnedInteriorVehicles = {}

  for _, point in ipairs(interiorPoints) do
    point:remove()
  end

  interiorPoints = {}
  Framework.Client.HideTextUI()

  if previousPlayerCoords then
    SetEntityCoords(cache.ped, previousPlayerCoords.x, previousPlayerCoords.y, previousPlayerCoords.z, false, false, false, false)
    previousPlayerCoords = nil
  end

  lib.callback.await("jg-advancedgarages:server:exit-interior")
  currentGarageType = nil

  if onExit then
    onExit()
  end

  Wait(500)
  DoScreenFadeIn(500)
end

local function setupInteriorExitPoints(garageId)
  local exitPoint = lib.points.new({
    coords = Config.GarageInteriorEntrance,
    distance = EXIT_POINT_DISTANCE
  })

  exitPoint.onEnter = function()
    local vehicle = cache.vehicle

    if not vehicle then
      Framework.Client.ShowTextUI(Config.ExitInteriorPrompt)
      return
    end

    local plate = Framework.Client.GetPlate(vehicle)
    local model = GetEntityModel(vehicle)
    if not model or not plate then
      return
    end

    CreateThread(function()
      while vehicle == cache.vehicle do
        SetVehicleForwardSpeed(vehicle, 0)
        Wait(0)
      end
    end)

    local spawnerIndex = nil
    for _, interiorVehicle in ipairs(spawnedInteriorVehicles) do
      if interiorVehicle.vehicle == vehicle then
        spawnerIndex = interiorVehicle.spawnerIndex
        break
      end
    end

    clearInteriorState(function()
      driveVehicleOut(plate, garageId, spawnerIndex)
    end)
  end

  exitPoint.onExit = function()
    Framework.Client.HideTextUI()
  end

  exitPoint.nearby = function()
    if cutsceneActive and IsControlJustPressed(0, Config.ExitInteriorKeyBind) then
      stopInteriorCutscene()
    end

    if not cache.vehicle and not cutsceneActive and IsControlJustPressed(0, Config.ExitInteriorKeyBind) then
      clearInteriorState()
    end
  end

  interiorPoints[#interiorPoints + 1] = exitPoint

  local markerPoint = lib.points.new({
    coords = Config.GarageInteriorEntrance,
    distance = 20.0
  })

  markerPoint.nearby = function()
    drawMarkerOnFrame(Config.GarageInteriorEntrance, {
      id = 21,
      size = { x = 0.3, y = 0.3, z = 0.3 },
      color = { r = 255, g = 255, b = 255, a = 120 },
      bobUpAndDown = 0,
      faceCamera = 0,
      rotate = 1,
      drawOnEnts = 0
    })
  end

  interiorPoints[#interiorPoints + 1] = markerPoint
end

local function startInteriorVehicleEntryAssist()
  CreateThread(function()
    while interiorActive do
      local sleep = 500
      local tryingVehicle = GetVehiclePedIsTryingToEnter(cache.ped)

      if tryingVehicle ~= 0 then
        sleep = 0
        SetVehicleEngineOn(tryingVehicle, true, true, true)
        SetVehicleNeedsToBeHotwired(tryingVehicle, false)
        SetVehicleDoorsLocked(tryingVehicle, 1)
        EnableControlAction(0, 23, true)
      end

      Wait(sleep)
    end
  end)
end

local function getGarageDataForInterior(garageId)
  local availableLocations = getAvailableGarageLocations()
  local garageData = availableLocations and availableLocations[garageId]

  if garageData then
    return garageData
  end

  return {
    garageType = "personal",
    checkVehicleGarageId = Config.GarageUniqueLocations,
    enableInteriors = Config.PrivGarageEnableInteriors
  }
end

local function filterInteriorVehicles(garageId, vehicles)
  local garageData = getGarageDataForInterior(garageId)
  currentGarageType = garageData.garageType

  local filtered = {}
  for _, vehicleData in ipairs(vehicles) do
    if IsModelInCdimage(vehicleData.hash) then
      local wrongGarage = garageData.checkVehicleGarageId and vehicleData.garageId ~= garageId
      local canShowVehicle = not wrongGarage and not vehicleData.impound and vehicleData.inGarage and not vehicleData.isSpawned

      if canShowVehicle then
        filtered[#filtered + 1] = vehicleData
      end
    end
  end

  return filtered
end

local function enterInterior(garageId, vehicles)
  interiorActive = true

  local interiorVehicles = filterInteriorVehicles(garageId, vehicles or {})
  if #interiorVehicles == 0 then
    Framework.Client.Notify(Locale.noVehiclesAvailableToDrive, "error")
    clearInteriorState()
    return
  end

  CreateThread(function()
    DoScreenFadeOut(500)
    Wait(500)

    for index, spawnPos in ipairs(Config.GarageInteriorVehiclePositions) do
      local vehicleData = interiorVehicles[index]
      if not vehicleData then
        break
      end

      local vehicle = createClientVehicle(vehicleData.hash, spawnPos, vehicleData.plate, false)

      if vehicleData.props and type(vehicleData.props) == "table" then
        Framework.Client.SetVehicleProperties(vehicle, vehicleData.props)
      end

      spawnedInteriorVehicles[#spawnedInteriorVehicles + 1] = {
        vehicle = vehicle,
        spawnerIndex = vehicleData.spawnerIndex,
        plate = vehicleData.plate,
        veh = vehicleData
      }
    end

    previousPlayerCoords = GetEntityCoords(cache.ped)

    SetEntityCoords(
      cache.ped,
      Config.GarageInteriorEntrance.x,
      Config.GarageInteriorEntrance.y,
      Config.GarageInteriorEntrance.z,
      false,
      false,
      false,
      false
    )
    SetEntityHeading(cache.ped, Config.GarageInteriorEntrance.w)

    setupInteriorExitPoints(garageId)

    DoScreenFadeIn(500)
    playInteriorCutscene()
    startInteriorVehicleEntryAssist()
  end)
end

lib.onCache("vehicle", function(vehicle)
  if not interiorActive then
    return
  end

  if not vehicle or vehicle == 0 then
    SendNUIMessage({ type = "hide" })
    return
  end

  local plate = Framework.Client.GetPlate(vehicle)
  if not plate then
    return
  end

  local modelName = GetEntityArchetypeName(vehicle)
  local vehicleData = lib.callback.await("jg-advancedgarages:server:get-vehicle", false, modelName, plate)
  if not vehicleData then
    return false
  end

  local model = type(vehicleData.model) == "string" and vehicleData.model or getModelNameFromHash(vehicleData.hash)
  vehicleData.model = model
  vehicleData.vehicleLabel = Framework.Client.GetVehicleLabel(model)

  SendNUIMessage({
    type = "show-interior-vehicle",
    vehicle = vehicleData,
    config = Config,
    locale = Locale
  })
end)

RegisterNetEvent("jg-advancedgarages:client:enter-interior", enterInterior)
