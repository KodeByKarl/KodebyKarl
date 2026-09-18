local MODEL_REQUEST_TIMEOUT = 3000
local CONFIRM_CONTROL = 201
local CANCEL_CONTROL = 202

local function isNearVehicleBones(vehicle, boneNames)
  local playerPed = cache.ped
  local playerCoords = GetEntityCoords(playerPed)
  for _, boneName in ipairs(boneNames) do
    local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
    if boneIndex == -1 then
      return true
    else
      local boneCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
      if #(playerCoords - boneCoords) <= 3.0 then
        return true
      end
    end
  end
  return false
end

local function playContextualAnimation(ped, context, vehicle)
  if not ped or not vehicle then
    return
  end
  local vehicleCoords = GetEntityCoords(vehicle)
  local pedCoords = GetEntityCoords(ped)
  if (vehicleCoords.z - pedCoords.z) > 1.0 then
    playAnimation(ped, "missheist_agency2aig_3", "chat_a_worker2")
  elseif context == "engine" then
    playAnimation(ped, "mini@repair", "fixing_a_ped")
  elseif context == "kneeling" then
    playAnimation(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", true)
  end
end

local function createEngineHoist(coords)
  local engineModel = joaat("prop_car_engine_01")
  local hoistModel = joaat("prop_engine_hoist")

  lib.requestModel(engineModel, MODEL_REQUEST_TIMEOUT)
  lib.requestModel(hoistModel, MODEL_REQUEST_TIMEOUT)

  local hoist = CreateObject(hoistModel, coords.x, coords.y, coords.z, true, true, false)
  NetworkSetObjectForceStaticBlend(hoist, true)
  while not HasCollisionLoadedAroundEntity(hoist) do
    Wait(1)
  end
  PlaceObjectOnGroundProperly(hoist)

  local engine = CreateObject(engineModel, coords.x, coords.y, coords.z, true, true, false)
  NetworkSetObjectForceStaticBlend(engine, true)
  while not HasCollisionLoadedAroundEntity(engine) do
    Wait(1)
  end

  AttachEntityToEntity(engine, hoist, 0, 0.0, -1.1, 1.25, 0.0, 0.0, 0.0, false, false, true, false, 2, true)
  SetEntityCollision(hoist, false, false)
  SetEntityCanBeDamaged(hoist, false)
  SetEntityCollision(engine, false, true)
  return hoist, engine
end

local function deleteEngineHoist(hoist, engine)
  if hoist then
    DeleteEntity(hoist)
  end
  if engine then
    DeleteEntity(engine)
  end
end

function swapEngineMinigame(vehicle, options, callback)
  local playerPed = cache.ped
  local playerCoords = GetEntityCoords(playerPed)
  local offset = vector3(1.5, 0.0, 0.0)

  TaskLeaveVehicle(playerPed, vehicle, 16)
  Entity(vehicle).state:set("vehicleBonnetDeleted", true, true)

  local hoist, engine = createEngineHoist(playerCoords)

  PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
  SetNuiFocus(false, false)
  hideTabletToShowInteractionPrompt(Locale.takeEngineHoistToVehicle)

  CreateThread(function()
    while true do
      if IsControlJustPressed(0, CONFIRM_CONTROL) then
        break
      end
      if IsControlJustReleased(0, CANCEL_CONTROL) then
        break
      end

      local currentCoords = GetEntityCoords(playerPed)
      local forwardVector = GetEntityForwardVector(playerPed)
      local rightVector = vector3(forwardVector.y, -forwardVector.x, forwardVector.z)
      local targetCoords = currentCoords + (forwardVector * offset.x) + (rightVector * offset.y) + vector3(0.0, 0.0, offset.z)

      local foundGround, groundZ = GetGroundZFor_3dCoord(targetCoords.x, targetCoords.y, targetCoords.z, true)
      SetEntityCoords(hoist, targetCoords.x, targetCoords.y, groundZ, true, true, true, false)

      local heading = math.deg(math.atan((targetCoords.y - currentCoords.y) / (targetCoords.x - currentCoords.x))) - 270.0
      if targetCoords.x < currentCoords.x then
        heading = heading - 180.0
      end
      SetEntityRotation(hoist, 0.0, 0.0, heading, 2, true)
      Wait(0)
    end

    if IsControlJustReleased(0, CANCEL_CONTROL) then
      showTabletAfterInteractionPrompt()
      stopAnimation(playerPed)
      deleteEngineHoist(hoist, engine)
      Entity(vehicle).state:set("vehicleBonnetDeleted", false, true)
      return callback(false)
    end

    hideTabletToShowInteractionPrompt(Locale.goToEngineToInstall)
    Wait(100)
    PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)

    while true do
      if IsControlJustPressed(0, CONFIRM_CONTROL) and isNearVehicleBones(vehicle, { "engine" }) then
        break
      end
      if IsControlJustPressed(0, CONFIRM_CONTROL) then
        Framework.Client.Notify(Locale.notNearbyToEngine, "error")
        Wait(100)
      end
      Wait(0)
    end

    playContextualAnimation(playerPed, "engine", vehicle)
    local soundId = Framework.Client.PlaySound("repair", playerCoords)

    Framework.Client.SkillCheck(function()
      showTabletAfterInteractionPrompt()
      stopAnimation(playerPed)
      Framework.Client.StopSound(soundId)
      deleteEngineHoist(hoist, engine)
      Entity(vehicle).state:set("vehicleBonnetDeleted", false, true)
      callback(true)
    end, function()
      showTabletAfterInteractionPrompt()
      stopAnimation(playerPed)
      Framework.Client.StopSound(soundId)
      deleteEngineHoist(hoist, engine)
      Entity(vehicle).state:set("vehicleBonnetDeleted", false, true)
      Framework.Client.Notify(Locale.installationFailed, "error")
      callback(false)
    end)
  end)
end

AddStateBagChangeHandler("vehicleBonnetDeleted", "", function(bagName, key, value)
  local vehicle = GetEntityFromStateBagName(bagName)
  if not vehicle or not DoesEntityExist(vehicle) then
    return
  end

  if value then
    SetVehicleDoorBroken(vehicle, 4, true)
  else
    SetVehicleFixed(vehicle)
  end
end)

local function createProp(propName, coords)
  if type(propName) ~= "string" or propName == "" then
    return 0
  end
  local propHash = joaat(propName)
  lib.requestModel(propHash, MODEL_REQUEST_TIMEOUT)
  local prop = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, false)
  NetworkSetObjectForceStaticBlend(prop, true)
  while not HasCollisionLoadedAroundEntity(prop) do
    Wait(1)
  end
  return prop
end

function propBasedMinigame(vehicle, options, callback)
  local propName = options.prop
  if not propName then
    return callback(false)
  end

  local playerPed = cache.ped
  local playerCoords = GetEntityCoords(playerPed)
  TaskLeaveVehicle(playerPed, vehicle, 16)

  local prop = 0
  local targetBones = {}
  local errorMsg = "ERROR"
  local animContext = "kneeling"

  if propName == "wheel" then
    targetBones = { "wheel_lf", "wheel_rf", "wheel_lr", "wheel_rr" }
    errorMsg = Locale.notNearWheel
    prop = createProp("prop_wheel_01", playerCoords)
    AttachEntityToEntity(prop, playerPed, 62, 0.0754, 0.0936, 0.2814, -172.34, 0, 0, true, true, false, true, 1, true)
    playAnimation(playerPed, "anim@heists@box_carry@", "idle")
    hideTabletToShowInteractionPrompt(Locale.takeWheel)
  elseif propName == "canister" then
    targetBones = { "engine" }
    errorMsg = Locale.notNearbyToEngine
    animContext = "engine"
    prop = createProp("prop_gascyl_01a", playerCoords)
    AttachEntityToEntity(prop, playerPed, 62, 0.0394, 0.1178, 0.1243, -157.12, 0, 37.73, true, true, false, true, 1, true)
    playAnimation(playerPed, "anim@heists@box_carry@", "idle")
    SetVehicleDoorOpen(vehicle, 4, false, false)
    hideTabletToShowInteractionPrompt(Locale.takeCanisterToEngine)
  elseif propName == "spanner" then
    targetBones = { "engine" }
    errorMsg = Locale.notNearbyToEngine
    animContext = "engine"
    prop = createProp("prop_tool_spanner01", playerCoords)
    AttachEntityToEntity(prop, playerPed, 62, 0.0841, -0.0059, 0.0119, -93.95, -79.54, 21.94, true, true, false, true, 1, true)
    SetVehicleDoorOpen(vehicle, 4, false, false)
    hideTabletToShowInteractionPrompt(Locale.goToEngineToInstallOrCancel)
  end

  if prop == 0 then
    showTabletAfterInteractionPrompt()
    return callback(false)
  end

  CreateThread(function()
    SetNuiFocus(false, false)
    Wait(200)
    PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)

    while true do
      if IsControlJustPressed(0, CONFIRM_CONTROL) or IsControlJustReleased(0, CANCEL_CONTROL) then
        break
      end
      Wait(0)
    end

    while true do
      if IsControlJustReleased(0, CANCEL_CONTROL) then
        break
      end
      if IsControlJustPressed(0, CONFIRM_CONTROL) and isNearVehicleBones(vehicle, targetBones) then
        break
      end
      if IsControlJustPressed(0, CONFIRM_CONTROL) then
        Framework.Client.Notify(errorMsg, "error")
        Wait(100)
      end
      Wait(0)
    end

    DeleteEntity(prop)
    stopAnimation(playerPed)

    if IsControlJustReleased(0, CANCEL_CONTROL) then
      SetVehicleDoorsShut(vehicle, false)
      showTabletAfterInteractionPrompt()
      return callback(false)
    end

    Wait(200)
    playContextualAnimation(playerPed, animContext, vehicle)
    local soundId = Framework.Client.PlaySound("repair", playerCoords)

    Framework.Client.SkillCheck(function()
      showTabletAfterInteractionPrompt()
      stopAnimation(playerPed)
      DeleteEntity(prop)
      SetVehicleDoorsShut(vehicle, false)
      Framework.Client.StopSound(soundId)
      callback(true)
    end, function()
      showTabletAfterInteractionPrompt()
      stopAnimation(playerPed)
      DeleteEntity(prop)
      SetVehicleDoorsShut(vehicle, false)
      Framework.Client.StopSound(soundId)
      Framework.Client.Notify(Locale.installationFailed, "error")
      callback(false)
    end)
  end)
end

function paintSprayMinigame(vehicle, options, callback)
  local playerPed = cache.ped
  local playerCoords = GetEntityCoords(playerPed)
  TaskLeaveVehicle(playerPed, vehicle, 16)

  CreateThread(function()
    local animDict = "switch@franklin@cleaning_car"
    local animName = "001946_01_gc_fras_v2_ig_5_base"
    local propName = "prop_paint_spray01b"
    local pfxAsset = "core"
    local pfxName = "ent_sht_steam"

    lib.requestAnimDict(animDict)
    lib.requestModel(propName, MODEL_REQUEST_TIMEOUT)
    lib.requestNamedPtfxAsset(pfxAsset)

    local sprayCan = CreateObject(GetHashKey(propName), playerCoords.x, playerCoords.y, playerCoords.z, true, true, true)
    AttachEntityToEntity(sprayCan, playerPed, 71, 0.05, 0.0, -0.02, 0.0, 90.0, 90.0, true, true, false, true, 1, true)
    SetNuiFocus(false, false)
    hideTabletToShowInteractionPrompt(Locale.pressToRespray)
    Wait(200)
    PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)

    while true do
      if IsControlJustPressed(0, CONFIRM_CONTROL) or IsControlJustReleased(0, CANCEL_CONTROL) then
        break
      end
      Wait(0)
    end

    while true do
      if IsControlJustReleased(0, CANCEL_CONTROL) then
        break
      end
      if IsControlJustPressed(0, CONFIRM_CONTROL) then
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(vehicle))
        if not (dist > 4.0) then
          break
        end
      end
      if IsControlJustPressed(0, CONFIRM_CONTROL) then
        Framework.Client.Notify(Locale.tooFarFromVehicle, "error")
        Wait(100)
      end
      Wait(0)
    end

    if IsControlJustReleased(0, CANCEL_CONTROL) then
      DeleteObject(sprayCan)
      ClearPedTasksImmediately(playerPed)
      showTabletAfterInteractionPrompt()
      return callback(false)
    end

    Wait(200)
    hideTabletToShowInteractionPrompt(Locale.paintEvenlyMsg)
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8, -1, 49, 0, false, false, false)

    CreateThread(function()
      for i = 0, 2 do
        UseParticleFxAssetNextCall(pfxAsset)
        local pfx = StartParticleFxLoopedOnEntity(pfxName, sprayCan, 0.0, 0.0, 0.15, 0.0, 0.0, 0.0, 1.0, false, false, false)
        Citizen.Wait(5000)
        StopParticleFxLooped(pfx, false)
      end
    end)

    Framework.Client.ProgressBar(Locale.resprayingVehicleProgress, 15000, false, false, function()
      showTabletAfterInteractionPrompt()
      DeleteObject(sprayCan)
      ClearPedTasksImmediately(playerPed)
      callback(true)
    end, function()
      showTabletAfterInteractionPrompt()
      DeleteObject(sprayCan)
      ClearPedTasksImmediately(playerPed)
      callback(false)
    end)
  end)
end

function playMinigame(vehicle, minigameType, options, callback)
  if not vehicle or vehicle == 0 then
    return callback(false)
  end

  local minigameFunc = propBasedMinigame
  if minigameType == "respray" then
    minigameFunc = paintSprayMinigame
  elseif minigameType == "engineSwap" then
    minigameFunc = swapEngineMinigame
  end

  if DoesEntityExist(vehicle) then
    Entity(vehicle).state:set("isMechanicServicing", true, true)
  end

  minigameFunc(vehicle, options, function(...)
    if DoesEntityExist(vehicle) then
      Entity(vehicle).state:set("isMechanicServicing", nil, true)
    end
    callback(...)
  end)
end

