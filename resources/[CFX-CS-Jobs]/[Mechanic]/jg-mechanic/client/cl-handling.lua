local function getVehicleSubhandlingClass(vehicle)
  local vehicleModel = GetEntityModel(vehicle)
  local vehicleSubHandlingClass = (
    (IsThisModelACar(vehicleModel)) and "CCarHandlingData" or
    (IsThisModelABike(vehicleModel) or IsThisModelAQuadbike(vehicleModel)) and "CBikeHandlingData" or
    (IsThisModelABoat(vehicleModel) or IsThisModelAJetski(vehicleModel)) and "CBoatHandlingData" or
    (IsThisModelAHeli(vehicleModel) or IsThisModelAPlane(vehicleModel)) and "CFlyingHandlingData" or false
  )

  return vehicleSubHandlingClass or "CHandlingData"
end

function getVehicleHandlingValue(vehicle, class, fieldName)
  if string.sub(fieldName, 1, 3) == "vec" then -- is vec
    return GetVehicleHandlingVector(vehicle, class or "CHandlingData", fieldName)
  elseif string.sub(fieldName, 1, 1) == "f" then
    return tonumber(string.format("%.6f", GetVehicleHandlingFloat(vehicle, class or "CHandlingData", fieldName)))
  else
    return GetVehicleHandlingInt(vehicle, class or "CHandlingData", fieldName)
  end
end

function setVehicleHandlingValue(vehicle, class, fieldName, value)
  local prevValue = fieldName == "nInitialDriveGears" and getVehicleHandlingValue(vehicle, class, fieldName) or nil
  
  if fieldName == "fDriveBiasFront" then
    local numOfWheels = GetVehicleNumberOfWheels(vehicle)

    if numOfWheels >= 4 then
      SetVehicleWheelIsPowered(vehicle, 0, value > 0) -- FWD
      SetVehicleWheelIsPowered(vehicle, 1, value > 0) -- FWD
      SetVehicleWheelIsPowered(vehicle, 2, value < 1) -- AWD/RWD
      SetVehicleWheelIsPowered(vehicle, 3, value < 1) -- AWD/RWD
      SetVehicleWheelIsPowered(vehicle, 4, value < 1) -- AWD/RWD
    end
  end

  if string.sub(fieldName, 1, 3) == "vec" then -- is vec
    SetVehicleHandlingVector(vehicle, class or "CHandlingData", fieldName, vector3(value.x, value.y, value.z))
  elseif string.sub(fieldName, 1, 1) == "f" then
    SetVehicleHandlingFloat(vehicle, class or "CHandlingData", fieldName, value)
  else -- is int
    SetVehicleHandlingInt(vehicle, class or "CHandlingData", fieldName, value)
  end

  if fieldName == "nInitialDriveGears" and prevValue ~= value then
    SetVehicleHighGear(vehicle, value)
    Citizen.InvokeNative(`SET_VEHICLE_CURRENT_GEAR` & 0xFFFFFFFF, vehicle, value)
    Citizen.InvokeNative(`SET_VEHICLE_NEXT_GEAR` & 0xFFFFFFFF, vehicle, value)
    
    SetTimeout(11, function()
      Citizen.InvokeNative(`SET_VEHICLE_CURRENT_GEAR` & 0xFFFFFFFF, vehicle, 1)
    end)
  end

  local tsm = GetVehicleTopSpeedModifier(vehicle)
  ModifyVehicleTopSpeed(vehicle, tsm == -1.0 and 1.0 or tsm)
end

function getBaseVehicleHandling(vehicle)
  local subHandlingClass = getVehicleSubhandlingClass(vehicle)
  local handling = {}

  for handlingKey, class in pairs(HANDLING_KEY_CLASS_MAP) do
    if class == "CHandlingData" or class == subHandlingClass then
      local value = getVehicleHandlingValue(vehicle, class, handlingKey)

      if handlingKey == "AIHandling" then
        handling["AIHandling"] = AI_HANDLING_HASH_MAP[value] -- hash lookup for string
      elseif handlingKey == "handlingName" then
        handling["handlingName"] = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
      else
        handling[handlingKey] = value
      end
    end
  end

  handling["audioNameHash"] = GetEntityArchetypeName(vehicle)

  if GetResourceState("wizating_laptop") == "started" then
    local wizatingHandling = exports["wizating_laptop"]:getHandlingData(vehicle) or {}
    handling = tableConcat(handling, wizatingHandling)
  end
  
  return handling
end

local function calculateFlagForSmoothFirstGear(advancedFlags)
  if hasFlag(advancedFlags, ADV_HANDLING_FLAGS.ELECTRIC) then -- Ignore if the vehicle has an electric gearbox flag
    return advancedFlags
  end

  advancedFlags = addFlag(advancedFlags, ADV_HANDLING_FLAGS.SMOOTH_FIRST_GEAR)

  return advancedFlags
end

local function calculateFlagForManualGearbox(advancedFlags, toggle)
  if hasFlag(advancedFlags, ADV_HANDLING_FLAGS.ELECTRIC) then -- Ignore if the vehicle has an electric gearbox flag
    return advancedFlags
  end

  if toggle then
    advancedFlags = removeFlag(advancedFlags, ADV_HANDLING_FLAGS.FULL_AUTO)
    advancedFlags = removeFlag(advancedFlags, ADV_HANDLING_FLAGS.DIRECT_SHIFT)
    advancedFlags = addFlag(advancedFlags, ADV_HANDLING_FLAGS.MANUAL)
  else
    advancedFlags = removeFlag(advancedFlags, ADV_HANDLING_FLAGS.MANUAL)
  end

  return advancedFlags
end

local function getGTAPerformanceMods(vehicle)
  if not vehicle or vehicle == 0 then return false end

  return {
    modEngine = GetVehicleMod(vehicle, 11),
    modBrakes = GetVehicleMod(vehicle, 12),
    modTransmission = GetVehicleMod(vehicle, 13),
    modTurbo = IsToggleModOn(vehicle, 18)
  }
end

local function reapplyGTAPerformanceMods(vehicle, data)
  if not data or type(data) ~= "table" then return end

  SetVehicleModKit(vehicle, 0)
  if data.modEngine then SetVehicleMod(vehicle, 11, data.modEngine, false) end
  if data.modBrakes then SetVehicleMod(vehicle, 12, data.modBrakes, false) end
  if data.modTransmission then SetVehicleMod(vehicle, 13, data.modTransmission, false) end
  if data.modTurbo ~= nil then ToggleVehicleMod(vehicle, 18, data.modTurbo) end
end

local function calculateTuningHandling(handling, tuningConfig)
  local tuningsToApply = {}

  for tune, option in pairs(tuningConfig) do
    if option then
      local tuneConfig = Config.Tuning[tune]?[option]

      if tuneConfig then
        tuningsToApply[#tuningsToApply + 1] = {
          order = tuneConfig.handlingApplyOrder or 1,
          config = tuneConfig
        }
      end
    end
  end

  table.sort(tuningsToApply, function(a, b) return a.order < b.order end)

  local hasManualGearboxTune = false
  for _, tune in ipairs(tuningsToApply) do
    local tuneConfig = tune.config
    if tuneConfig then
      if tuneConfig.manualGearbox then
        hasManualGearboxTune = true
        handling.strAdvancedFlags = calculateFlagForManualGearbox(handling.strAdvancedFlags, true)
      end

      if tuneConfig.audioNameHash then
        handling.audioNameHash = tuneConfig.audioNameHash
      end

      if tuneConfig.handling then
        for key, value in pairs(tuneConfig.handling) do
          if tuneConfig.handlingOverwritesValues then
            handling[key] = value
          else
            handling[key] = (handling[key] or 0) + value
          end
        end
      end
    end
  end

  if not hasManualGearboxTune then
    handling.strAdvancedFlags = calculateFlagForManualGearbox(handling.strAdvancedFlags, false)
  end

  return handling
end

local function calcServicingHandlingValue(val, minVal, damage)
  return minVal + ((val - minVal) * damage)
end

local function isServicingBlacklisted(vehicle)
  if not Config.ServicingBlacklist or type(Config.ServicingBlacklist) ~= "table" then
    return false
  end
  local archetypeName = GetEntityArchetypeName(vehicle)
  return lib.table.contains(Config.ServicingBlacklist, archetypeName)
end

local function calculateServicingHandling(vehicle, handling, servicingHealth)
  local hash = GetEntityModel(vehicle)
  local isSupportedVeh = IsThisModelACar(hash) or IsThisModelABike(hash) or IsThisModelAQuadbike(hash)
  if not isSupportedVeh then return handling end
  -- Job / emergency vehicles: never apply worn-service handling penalties
  if isServicingBlacklisted(vehicle) then return handling end

  local isElectric = isVehicleElectric(GetEntityArchetypeName(vehicle))

  local suspensionDamage = round(servicingHealth.suspension / 100, 3)
  handling.fCamberStiffnesss = calcServicingHandlingValue(handling.fCamberStiffnesss, 0.0, suspensionDamage)
  handling.fSuspensionForce = calcServicingHandlingValue(handling.fSuspensionForce, 0.0, suspensionDamage)
  handling.fAntiRollBarForce = calcServicingHandlingValue(handling.fAntiRollBarForce, 0.0, suspensionDamage)
  SetVehicleAudioBodyDamageFactor(vehicle, 1.0 - suspensionDamage)

  local tyresDamage = round(servicingHealth.tyres / 100, 3)
  handling.fTractionCurveMin = calcServicingHandlingValue(handling.fTractionCurveMin, 0.5, tyresDamage)
  handling.fTractionCurveMax = calcServicingHandlingValue(handling.fTractionCurveMax, 0.5, tyresDamage)

  local brakesDamage = round(servicingHealth.brakePads / 100, 3)
  handling.fBrakeForce = calcServicingHandlingValue(handling.fBrakeForce, 0.01, brakesDamage)

  local clutchDamage = round(servicingHealth.clutch / 100, 3)
  handling.fClutchChangeRateScaleUpShift = calcServicingHandlingValue(handling.fClutchChangeRateScaleUpShift, 0.0, clutchDamage)
  handling.fClutchChangeRateScaleDownShift = calcServicingHandlingValue(handling.fClutchChangeRateScaleDownShift, 0.0, clutchDamage)

  local accelerationDamage = round((isElectric and (servicingHealth.evBattery or 1) or servicingHealth.sparkPlugs) / 100, 3)
  handling.fDriveInertia = calcServicingHandlingValue(handling.fDriveInertia, 0.01, accelerationDamage)
  
  local engineDamage = round((isElectric and (math.min(servicingHealth.evCoolant, servicingHealth.evMotor) or 1) or math.min(servicingHealth.airFilter, servicingHealth.engineOil)) / 100, 3)
  handling.fInitialDriveForce = calcServicingHandlingValue(handling.fInitialDriveForce, 0.1, engineDamage)
  SetVehicleAudioEngineDamageFactor(vehicle, 1.0 - engineDamage)

  return handling
end

local function applyVehicleTuningHandling(vehicle, tuningConfig)
  if not DoesEntityExist(vehicle) then return error("Vehicle does not exist") end

  local state = Entity(vehicle).state
  if not state then return end

  if state.editorHandlingApplied then return end -- JG Handling overwrite in effect

  local baseHandling, servicingData = state.baseHandling, state.servicingData

  if not baseHandling then
    baseHandling = getBaseVehicleHandling(vehicle)
    Entity(vehicle).state:set("baseHandling", baseHandling, true)
  end

  local handling = {}
  for k, v in pairs(baseHandling) do handling[k] = v end

  local performanceMods = getGTAPerformanceMods(vehicle)

  if tuningConfig then
    handling = calculateTuningHandling(handling, tuningConfig)
  else
    handling.strAdvancedFlags = calculateFlagForManualGearbox(handling.strAdvancedFlags, false)
  end

  if servicingData then
    handling = calculateServicingHandling(vehicle, handling, servicingData)
  end

  if Config.SmoothFirstGear then
    handling.strAdvancedFlags = calculateFlagForSmoothFirstGear(handling.strAdvancedFlags)
  end

  for key, value in pairs(handling) do
    if key == "audioNameHash" then
      if baseHandling and value ~= baseHandling.audioNameHash then
        ForceUseAudioGameObject(vehicle, value)
      end
    else
      setVehicleHandlingValue(vehicle, HANDLING_KEY_CLASS_MAP[key], key, value)
    end
  end

  if NetworkGetEntityOwner(vehicle) == cache.playerId and performanceMods then
    reapplyGTAPerformanceMods(vehicle, performanceMods)
  end
end

AddStateBagChangeHandler("tuningConfig", "", function(bagName, _, value)
  local vehicle = GetEntityFromStateBagName(bagName)
  if vehicle == 0 then return end
  if not value then return end

  applyVehicleTuningHandling(vehicle, value)
end)

local function applyVehicleServicingHandling(vehicle, servicingData)
  if not DoesEntityExist(vehicle) then return error("Vehicle does not exist") end

  local state = Entity(vehicle).state
  if not state then return end

  if state.editorHandlingApplied then return end -- JG Handling overwrite in effect

  local baseHandling, tuningConfig = state.baseHandling, state.tuningConfig

  if not baseHandling then
    baseHandling = getBaseVehicleHandling(vehicle)
    Entity(vehicle).state:set("baseHandling", baseHandling, true)
  end

  local handling = {}
  for k, v in pairs(baseHandling) do handling[k] = v end

  local performanceMods = getGTAPerformanceMods(vehicle)

  if tuningConfig then
    handling = calculateTuningHandling(handling, tuningConfig)
  else
    handling.strAdvancedFlags = calculateFlagForManualGearbox(handling.strAdvancedFlags, false)
  end

  if servicingData then
    handling = calculateServicingHandling(vehicle, handling, servicingData)
  end

  if Config.SmoothFirstGear then
    handling.strAdvancedFlags = calculateFlagForSmoothFirstGear(handling.strAdvancedFlags)
  end

  for key, value in pairs(handling) do
    if key ~= "audioNameHash" then
      setVehicleHandlingValue(vehicle, HANDLING_KEY_CLASS_MAP[key], key, value)
    end
  end

  if NetworkGetEntityOwner(vehicle) == cache.playerId and performanceMods then
    reapplyGTAPerformanceMods(vehicle, performanceMods)
  end
end

AddStateBagChangeHandler("servicingData", "", function(bagName, _, value)
  local vehicle = GetEntityFromStateBagName(bagName)
  if vehicle == 0 then return end
  if not value then return end
  
  applyVehicleServicingHandling(vehicle, value)
end)

local function onEnterVehicle(vehicle)
  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
  
  local hash = GetEntityModel(vehicle)
  if not (IsThisModelACar(hash) or IsThisModelABike(hash) or IsThisModelAQuadbike(hash)) then return end
  if GetResourceState("wizating_laptop") == "started" then return end

  if Config.SmoothFirstGear then
    local advancedFlags = getVehicleHandlingValue(vehicle, "CCarHandlingData", "strAdvancedFlags") 
    setVehicleHandlingValue(vehicle, "CCarHandlingData", "strAdvancedFlags", calculateFlagForSmoothFirstGear(advancedFlags))
  end

  local state = Entity(vehicle).state or {}
  if state.tuningConfig then 
    applyVehicleTuningHandling(vehicle, state.tuningConfig) 
  end
  if state.servicingData then 
    applyVehicleServicingHandling(vehicle, state.servicingData) 
  end
end

CreateThread(function()
  local wait = 5000
  local timeAtHighRpm = 0

  if not Config.ManualHighRPMNotifications then
    return
  end

  while true do
    if cache.vehicle then
      local hasManualGearbox = Entity(cache.vehicle).state.tuningConfig?.gearboxes == 1
      if not hasManualGearbox then
        wait = 5000
        goto continue
      end

      local rpm = GetVehicleCurrentRpm(cache.vehicle)
      if rpm < 0.99 then
        timeAtHighRpm = 0
        wait = 2000
        goto continue
      end

      local currentGear = GetVehicleCurrentGear(cache.vehicle)
      local highGear = GetVehicleHighGear(cache.vehicle)
      if currentGear < 1 or currentGear == highGear then
        timeAtHighRpm = 0
        wait = 2000
        goto continue
      end

      wait = 100
      timeAtHighRpm += 100
      
      if timeAtHighRpm >= 2000 then
        SendNUIMessage({
          type = "manual-gearbox-keybinds",
          upBind = parseControlBinding(363),
          downBind = parseControlBinding(364),
          locale = Locale,
          config = Config,
        })
        timeAtHighRpm = 0
      end
    end

    ::continue::
    Wait(wait)
  end
end)

lib.onCache("vehicle", onEnterVehicle)
if cache.vehicle then onEnterVehicle(cache.vehicle) end

exports("calculateTuningHandling", calculateTuningHandling)
exports("calculateServicingHandling", calculateServicingHandling)
exports("applyVehicleTuningHandling", applyVehicleTuningHandling)
