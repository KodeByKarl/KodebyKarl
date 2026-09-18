PreviewingNewStance = false
local hasStancingKit = false

local function isVehicleStanceable(vehicle)
  local model = GetEntityModel(vehicle)
  return IsThisModelACar(model) or IsThisModelAQuadbike(model)
end

local function applyStance(vehicle, stanceData)
  if DoesEntityExist(vehicle) and stanceData and isVehicleStanceable(vehicle) then
    SetVehicleSuspensionHeight(vehicle, -(stanceData.height + 0.0))
    SetVehicleWheelXOffset(vehicle, 0, -(stanceData.xOffset[1] + 0.0))
    SetVehicleWheelXOffset(vehicle, 1, stanceData.xOffset[2] + 0.0)
    SetVehicleWheelXOffset(vehicle, 2, -(stanceData.xOffset[3] + 0.0))
    SetVehicleWheelXOffset(vehicle, 3, stanceData.xOffset[4] + 0.0)
    SetVehicleWheelYRotation(vehicle, 0, -(stanceData.yRot[1] + 0.0))
    SetVehicleWheelYRotation(vehicle, 1, stanceData.yRot[2] + 0.0)
    SetVehicleWheelYRotation(vehicle, 2, -(stanceData.yRot[3] + 0.0))
    SetVehicleWheelYRotation(vehicle, 3, stanceData.yRot[4] + 0.0)
  end
end

function getVehicleDefaultStance(vehicle)
  if DoesEntityExist(vehicle) and isVehicleStanceable(vehicle) then
    return {
      height = round(GetVehicleSuspensionHeight(vehicle), 4),
      xOffset = {
        -round(GetVehicleWheelXOffset(vehicle, 0), 4),
        round(GetVehicleWheelXOffset(vehicle, 1), 4),
        -round(GetVehicleWheelXOffset(vehicle, 2), 4),
        round(GetVehicleWheelXOffset(vehicle, 3), 4)
      },
      yRot = {
        -round(GetVehicleWheelYRotation(vehicle, 0), 4),
        round(GetVehicleWheelYRotation(vehicle, 1), 4),
        -round(GetVehicleWheelYRotation(vehicle, 2), 4),
        round(GetVehicleWheelYRotation(vehicle, 3), 4)
      }
    }
  end
  return false
end

function previewVehicleStance(vehicle, enableStance, defaultStance, newStance)
  if not vehicle or not isVehicleStanceable(vehicle) then return end
  if enableStance then
    applyStance(vehicle, newStance)
  else
    applyStance(vehicle, defaultStance)
  end
end

function setStanceState(vehicle, enableStance, wheelsAdjIndv, defaultStance, newStance)
  if not vehicle or not isVehicleStanceable(vehicle) then return end
  local vehicleState = Entity(vehicle).state
  vehicleState:set("enableStance", enableStance, true)
  if enableStance then
    vehicleState:set("wheelsAdjIndv", wheelsAdjIndv, true)
    vehicleState:set("stance", newStance, true)
  end
  if not vehicleState.defaultStance then
    vehicleState:set("defaultStance", defaultStance, true)
  end
end

local stancedVehicles = {}
local vehicleStanceData = {}
local vehicleUpdateCounter = {}
local vehicleStanceHash = {}
local playerVehicle = nil
local isPlayerVehicleThreadRunning = false
local isNearbyVehicleThreadRunning = false
local nearbyVehiclesFrequency = Config and Config.StanceNearbyVehiclesFreqMs or 500
local nearbyVehiclesDistance = 80.0

local function getVehicleFromStateBag(bagName)
  local vehicle = GetEntityFromStateBagName(bagName)
  if vehicle ~= 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
    return vehicle
  end
  return nil
end

local function calculateStanceHash(stanceData)
  if not stanceData then return 0 end
  local hash = (stanceData.height or 0) * 131.0
  if stanceData.xOffset then
    for i = 1, #stanceData.xOffset do
      hash = hash * 31.0 + (stanceData.xOffset[i] or 0)
    end
  end
  if stanceData.yRot then
    for i = 1, #stanceData.yRot do
      hash = hash * 37.0 + (stanceData.yRot[i] or 0)
    end
  end
  return math.floor(hash * 1000.0)
end

local function incrementVehicleUpdateCount(vehicle)
  vehicleUpdateCounter[vehicle] = (vehicleUpdateCounter[vehicle] or 0) + 1
end

local function clearVehicleStanceCache(vehicle)
  stancedVehicles[vehicle] = nil
  vehicleStanceData[vehicle] = nil
  vehicleUpdateCounter[vehicle] = nil
  vehicleStanceHash[vehicle] = nil
end

local function applyCachedStance(vehicle, force)
  local data = vehicleStanceData[vehicle]
  if not (data and data.stance) then return end

  local newHash = calculateStanceHash(data.stance)
  if not force and vehicleStanceHash[vehicle] == newHash then return end

  applyStance(vehicle, data.stance)
  vehicleStanceHash[vehicle] = newHash
end

local function cacheVehicleStanceFromState(vehicle)
  local state = Entity(vehicle).state
  if not state then return end

  if state.enableStance then
    stancedVehicles[vehicle] = true
    vehicleStanceData[vehicle] = vehicleStanceData[vehicle] or {}
    vehicleStanceData[vehicle].stance = state.stance
    vehicleStanceData[vehicle].defaultStance = state.defaultStance
    incrementVehicleUpdateCount(vehicle)
  end
end

local function playerVehicleThread()
  if isPlayerVehicleThreadRunning or not (playerVehicle and stancedVehicles[playerVehicle]) then return end
  isPlayerVehicleThreadRunning = true
  CreateThread(function()
    while playerVehicle and stancedVehicles[playerVehicle] and DoesEntityExist(playerVehicle) do
      if not PreviewingNewStance then
        -- Direct apply (skip hash calc); game resets wheel offsets while driving
        local data = vehicleStanceData[playerVehicle]
        if data and data.stance then
          applyStance(playerVehicle, data.stance)
        end
      end
      -- Every frame while moving; relax when nearly parked
      local sleep = 0
      if GetEntitySpeed(playerVehicle) < 0.1 then
        sleep = 50
      end
      Wait(sleep)
    end
    isPlayerVehicleThreadRunning = false
  end)
end

local function nearbyVehiclesThread()
  if isNearbyVehicleThreadRunning or not next(stancedVehicles) then return end
  isNearbyVehicleThreadRunning = true
  CreateThread(function()
    while true do
      local playerPed = cache and cache.ped or PlayerPedId()
      local playerCoords = GetEntityCoords(playerPed)
      local currentVehicle = cache and cache.vehicle or GetVehiclePedIsIn(playerPed, false)
      for _, vehicle in ipairs(GetGamePool("CVehicle")) do
        if vehicle ~= currentVehicle and DoesEntityExist(vehicle) and #(GetEntityCoords(vehicle) - playerCoords) <= nearbyVehiclesDistance then
          local state = Entity(vehicle).state
          if state and state.enableStance and not stancedVehicles[vehicle] then
            stancedVehicles[vehicle] = true
            vehicleStanceData[vehicle] = {
              stance = state.stance,
              defaultStance = state.defaultStance
            }
            incrementVehicleUpdateCount(vehicle)
          end
        end
      end
      for vehicle in pairs(stancedVehicles) do
        if not DoesEntityExist(vehicle) then
          clearVehicleStanceCache(vehicle)
        elseif vehicle ~= currentVehicle and #(GetEntityCoords(vehicle) - playerCoords) <= nearbyVehiclesDistance then
          applyCachedStance(vehicle, true)
        end
      end
      if not next(stancedVehicles) then break end
      Wait(nearbyVehiclesFrequency)
    end
    isNearbyVehicleThreadRunning = false
  end)
end

AddStateBagChangeHandler("enableStance", "", function(bagName, key, value)
  local vehicle = getVehicleFromStateBag(bagName)
  if not vehicle then return end
  if value then
    local state = Entity(vehicle).state
    stancedVehicles[vehicle] = true
    vehicleStanceData[vehicle] = vehicleStanceData[vehicle] or {}
    vehicleStanceData[vehicle].stance = state and state.stance or (vehicleStanceData[vehicle] and vehicleStanceData[vehicle].stance)
    vehicleStanceData[vehicle].defaultStance = state and state.defaultStance or (vehicleStanceData[vehicle] and vehicleStanceData[vehicle].defaultStance)
    vehicleStanceHash[vehicle] = nil
    vehicleUpdateCounter[vehicle] = (vehicleUpdateCounter[vehicle] or 0) + 1
    if vehicle == playerVehicle then
      playerVehicleThread()
      if not PreviewingNewStance then
        applyCachedStance(vehicle, true)
      end
    end
  else
    if vehicleStanceData[vehicle] and vehicleStanceData[vehicle].defaultStance then
      applyStance(vehicle, vehicleStanceData[vehicle].defaultStance)
      vehicleStanceHash[vehicle] = calculateStanceHash(vehicleStanceData[vehicle].defaultStance)
    end
    stancedVehicles[vehicle] = nil
  end
  nearbyVehiclesThread()
end)

AddStateBagChangeHandler("stance", "", function(bagName, key, value)
  local vehicle = getVehicleFromStateBag(bagName)
  if not vehicle then return end
  stancedVehicles[vehicle] = true
  vehicleStanceData[vehicle] = vehicleStanceData[vehicle] or {}
  vehicleStanceData[vehicle].stance = value
  incrementVehicleUpdateCount(vehicle)
end)

AddStateBagChangeHandler("defaultStance", "", function(bagName, key, value)
  local vehicle = getVehicleFromStateBag(bagName)
  if not vehicle then return end
  vehicleStanceData[vehicle] = vehicleStanceData[vehicle] or {}
  vehicleStanceData[vehicle].defaultStance = value
end)

local function onVehicleChange(vehicle)
  playerVehicle = vehicle
  if vehicle and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
    cacheVehicleStanceFromState(vehicle)
  end
  playerVehicleThread()
end

lib.onCache("vehicle", onVehicleChange)
if cache.vehicle then
  onVehicleChange(cache.vehicle)
end

CreateThread(function()
  Wait(0)
  for _, vehicle in ipairs(GetGamePool("CVehicle")) do
    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
      cacheVehicleStanceFromState(vehicle)
    end
  end
  nearbyVehiclesThread()
end)

RegisterNUICallback("save-kit-stance", function(data, cb)
  if not hasStancingKit then
    return cb({ error = true })
  end
  if not cache.vehicle then
    return cb({ error = true })
  end
  PreviewingNewStance = false
  setVehicleStatebag(cache.vehicle, "defaultStance", data.defaultStance)
  setVehicleStatebag(cache.vehicle, "wheelsAdjIndv", data.wheelsAdjIndv)
  setVehicleStatebag(cache.vehicle, "stance", data.stance)
  setVehicleStatebag(cache.vehicle, "enableStance", data.enableStance, true)
  return cb(true)
end)

RegisterNUICallback("preview-kit-stance", function(data, cb)
  if not hasStancingKit then
    return cb({ error = true })
  end
  if not cache.vehicle then
    return cb({ error = true })
  end
  PreviewingNewStance = true
  previewVehicleStance(cache.vehicle, data.enableStance, data.defaultStance, data.stance)
  return cb(true)
end)

RegisterNetEvent("jg-mechanic:client:show-stancer-kit", function()
  hasStancingKit = lib.callback.await("jg-mechanic:server:has-item", false, "stancing_kit")
  if not hasStancingKit then return end

  if not cache.vehicle then
    return Framework.Client.Notify(Locale.notInsideVehicle, "error")
  end
  if not isVehicleStanceable(cache.vehicle) then
    return Framework.Client.Notify(Locale.cannotStanceVehicleType or "VEHICLE_INCOMPATIBLE", "error")
  end

  local state = Entity(cache.vehicle).state
  setupVehicleCamera(cache.vehicle)
  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "show-stancing-menu",
    enableStance = state.enableStance or false,
    wheelsAdjIndv = state.wheelsAdjIndv or false,
    stance = state.stance or getVehicleDefaultStance(cache.vehicle),
    defaultStance = state.defaultStance or getVehicleDefaultStance(cache.vehicle),
    config = Config,
    locale = Locale
  })
end)
