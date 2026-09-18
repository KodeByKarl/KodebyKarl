local isNitrousActive = false
local isBoostEffectActive = false
local isPurgeEffectActive = false
local localPlayerVehicle = 0
local lastNitrousHud = nil

local function isVehicleInWater(ped, vehicle)
  if GetPedInVehicleSeat(vehicle, -1) == ped and IsEntityInWater(vehicle) then
    return true
  end
  return false
end

local function startNitrousEffects(vehicle, isRemote)
  if isVehicleElectric(GetEntityArchetypeName(vehicle)) then
    return
  end

  if isBoostEffectActive then
    return
  end

  isBoostEffectActive = true

  local tailLightBones = { "taillight_l", "taillight_r" }
  local particleEffectName = "veh_light_red_trail"
  local particleScale = 1.0
  RequestNamedPtfxAsset("veh_xs_vehicle_mods")

  while not HasNamedPtfxAssetLoaded("veh_xs_vehicle_mods") do
    Wait(1)
  end

  SetVehicleNitroEnabled(vehicle, true)
  SetVehicleRocketBoostPercentage(vehicle, 100)
  SetVehicleRocketBoostRefillTime(vehicle, 0.1)
  SetVehicleRocketBoostActive(vehicle, true)
  SetVehicleBoostActive(vehicle, true)

  if not isRemote then
    if Config.NitrousScreenEffects then
      SetTimecycleModifier("RaceTurboFlash")
      SetTimecycleModifierStrength(0.8)
      ShakeGameplayCam("SKY_DIVING_SHAKE", 0.25)
    end

    if Config.NitrousRearLightTrails then
      for _, boneName in ipairs(tailLightBones) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
        UseParticleFxAssetNextCall("core")
        local particleHandle = StartParticleFxLoopedOnEntityBone(
          particleEffectName,
          vehicle,
          0.0, 0.0, 0.0,
          0.0, 0.0, 0.0,
          boneIndex,
          particleScale,
          false, false, false
        )
        SetParticleFxLoopedEvolution(particleHandle, "speed", 2.0, false)
      end
    end
    Entity(vehicle).state:set("nitrousFx", "nitrous", true)
  end

  CreateThread(function()
    while not isRemote and isBoostEffectActive do
      local powerMultiplier = Config.NitrousPowerIncreaseMult or 2.0
      SetVehicleCheatPowerIncrease(vehicle, powerMultiplier)
      Wait(0)
    end
  end)
end

local function stopNitrousEffects(vehicle, isRemote)
  isBoostEffectActive = false
  SetVehicleNitroEnabled(vehicle, false)
  SetVehicleRocketBoostActive(vehicle, false)
  SetVehicleBoostActive(vehicle, false)
  SetVehicleCheatPowerIncrease(vehicle, 1.0)

  if not isRemote then
    if Config.NitrousScreenEffects then
      ClearTimecycleModifier()
      StopGameplayCamShaking(true)
    end

    if Config.NitrousRearLightTrails then
      RemoveParticleFxFromEntity(vehicle)
    end
    Entity(vehicle).state:set("nitrousFx", false, true)
  end
end

local function startPurgeEffects(vehicle, isRemote)
  if isPurgeEffectActive then
    return
  end
  isPurgeEffectActive = true

  RemoveParticleFxFromEntity(vehicle)

  local wheelBones = { "wheel_lf", "wheel_rf" }
  local particleScale = 1.0
  local particleEffectName = "ent_sht_steam"

  for _, boneName in ipairs(wheelBones) do
    local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
    local boneWorldPos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    local boneOffset = GetOffsetFromEntityGivenWorldCoords(vehicle, boneWorldPos.x, boneWorldPos.y, boneWorldPos.z)
    UseParticleFxAssetNextCall("core")
    StartParticleFxLoopedOnEntity(
      particleEffectName,
      vehicle,
      boneOffset.x + 0.03,
      boneOffset.y + 0.1,
      boneOffset.z + 0.2,
      20.0, 0.0, 0.5,
      particleScale,
      false, false, false
    )
  end

  SetVehicleBoostActive(vehicle, true)

  if not isRemote then
    Entity(vehicle).state:set("nitrousFx", "purge", true)
  end
end

local function stopPurgeEffects(vehicle, isRemote)
  isPurgeEffectActive = false
  RemoveParticleFxFromEntity(vehicle)
  SetVehicleBoostActive(vehicle, false)

  if not isRemote then
    Entity(vehicle).state:set("nitrousFx", false, true)
  end
end

local function updateNitrousHud(vehicle, isUsing, isCooldown, capacity)
  local vehicleState = Entity(vehicle).state
  if not vehicleState then
    return
  end

  local filledBottles = vehicleState.nitrousFilledBottles or 0
  local isEmpty = filledBottles == 0 and capacity <= 0
  local installedBottles = vehicleState.nitrousInstalledBottles
  local roundedCapacity = tonumber(string.format("%.1f", capacity or 0)) or 0

  if lastNitrousHud
    and lastNitrousHud.using == isUsing
    and lastNitrousHud.cooldown == isCooldown
    and lastNitrousHud.filledBottles == filledBottles
    and lastNitrousHud.installedBottles == installedBottles
    and lastNitrousHud.capacity == roundedCapacity
    and lastNitrousHud.empty == isEmpty
  then
    return
  end

  lastNitrousHud = {
    using = isUsing,
    cooldown = isCooldown,
    filledBottles = filledBottles,
    installedBottles = installedBottles,
    capacity = roundedCapacity,
    empty = isEmpty,
  }

  SendNUIMessage({
    nitrousHudData = {
      using = isUsing,
      cooldown = isCooldown,
      installedBottles = installedBottles,
      filledBottles = filledBottles,
      capacity = capacity,
      maxCapacity = Config.NitrousBottleDuration,
      empty = isEmpty,
    },
  })
end

RegisterCommand("+nitrousKeymap", function()
  local playerPed = cache.ped
  local vehicle = GetVehiclePedIsIn(playerPed, false)

  if not vehicle then
    return
  end

  local vehicleState = Entity(vehicle).state
  if not vehicleState.nitrousInstalledBottles or vehicleState.nitrousInstalledBottles == 0 then
    return
  end

  if vehicleState.nitrousCooldown then
    updateNitrousHud(vehicle, false, true, 0)
    return
  end

  if vehicleState.nitrousFilledBottles == 0 and vehicleState.nitrousCapacity <= 0 then
    updateNitrousHud(vehicle, false, false, 0)
    return
  end

  isNitrousActive = true
  local nitrousCapacity = vehicleState.nitrousCapacity or 0.0
  local filledBottles = vehicleState.nitrousFilledBottles

  if nitrousCapacity <= 0 and filledBottles > 0 then
    local maxCapacity = Config.NitrousBottleDuration or 10.0
    filledBottles = filledBottles - 1
    nitrousCapacity = maxCapacity
    setVehicleStatebag(vehicle, "nitrousCapacity", nitrousCapacity, false)
    setVehicleStatebag(vehicle, "nitrousFilledBottles", filledBottles, true)
  end

  CreateThread(function()
    while isNitrousActive do
      if isVehicleInWater(playerPed, vehicle) or not (nitrousCapacity > 0) then
        break
      end

      localPlayerVehicle = vehicle

      if IsControlPressed(0, 71) or GetVehicleThrottleOffset(vehicle) > 0.05 then
        if isPurgeEffectActive then
          stopPurgeEffects(vehicle, false)
        end
        startNitrousEffects(vehicle, false)
        nitrousCapacity = round(nitrousCapacity - 0.1, 2)
        updateNitrousHud(vehicle, true, false, nitrousCapacity)
      else
        if isBoostEffectActive then
          stopNitrousEffects(vehicle, false)
        end
        startPurgeEffects(vehicle, false)
        local purgeDrainRate = Config.NitrousPurgeDrainRate or 1
        nitrousCapacity = round(nitrousCapacity - (0.1 * purgeDrainRate), 2)
        updateNitrousHud(vehicle, true, false, nitrousCapacity)
      end
      Wait(100)
    end

    stopNitrousEffects(vehicle, false)
    stopPurgeEffects(vehicle, false)

    if nitrousCapacity < 0 then
      nitrousCapacity = 0
    end

    setVehicleStatebag(vehicle, "nitrousCapacity", nitrousCapacity, true)

    if nitrousCapacity <= 0 then
      setVehicleStatebag(vehicle, "nitrousCooldown", true, true)
      updateNitrousHud(vehicle, false, true, 0)

      CreateThread(function()
        local cooldownTime = (Config.NitrousBottleCooldown or 10) * 1000
        Wait(cooldownTime)
        setVehicleStatebag(vehicle, "nitrousCooldown", false, true)
        updateNitrousHud(vehicle, false, false, 0)
      end)
    end
  end)
end, false)

RegisterCommand("-nitrousKeymap", function()
  local vehicle = GetVehiclePedIsIn(cache.ped, false)

  if not vehicle then
    return
  end

  local vehicleState = Entity(vehicle).state
  if not vehicleState.nitrousInstalledBottles or vehicleState.nitrousInstalledBottles == 0 then
    return
  end

  if isNitrousActive then
    isNitrousActive = false
    stopNitrousEffects(vehicle, false)
    stopPurgeEffects(vehicle, false)
  end
end, false)

RegisterKeyMapping("+nitrousKeymap", "Use installed nitrous", "keyboard", Config.NitrousDefaultKeyMapping)

AddStateBagChangeHandler("nitrousFx", "", function(bagName, key, value)
  local entity = GetEntityFromStateBagName(bagName)
  if not entity or not DoesEntityExist(entity) then
    return
  end

  if entity == localPlayerVehicle then
    return
  end

  if value == "nitrous" then
    startNitrousEffects(entity, true)
  elseif value == "purge" then
    startPurgeEffects(entity, true)
  else
    stopNitrousEffects(entity, true)
    stopPurgeEffects(entity, true)
  end
end)

RegisterNUICallback("install-new-bottle", function(data, cb)
  local connectedVehicle = LocalPlayer.state.tabletConnectedVehicle and LocalPlayer.state.tabletConnectedVehicle.vehicleEntity
  if not connectedVehicle or not DoesEntityExist(connectedVehicle) then
    return cb(false)
  end

  local model = GetEntityModel(connectedVehicle)
  if not IsThisModelACar(model) and not IsThisModelAQuadbike(model) then
    return cb(false)
  end

  if isVehicleElectric(GetEntityArchetypeName(connectedVehicle)) then
    return cb(false)
  end

  playMinigame(connectedVehicle, "prop", { prop = "canister" }, function(success)
    showTabletAfterInteractionPrompt()
    SetNuiFocus(true, true)

    if not success then
      return cb(false)
    end

    local itemAdded = lib.callback.await("jg-mechanic:server:install-new-bottle", false)
    if not itemAdded then
      return cb(false)
    end

    Framework.Client.Notify(Locale.nitrousBottleInstalled, "success")
    cb(true)
  end)
end)

RegisterNUICallback("refill-bottle", function(data, cb)
  Framework.Client.ProgressBar(Locale.refillingBottle, 5000, false, false, function()
    cb(lib.callback.await("jg-mechanic:server:refill-nitrous-bottle", false))
  end, function()
    cb(false)
  end)
end)

RegisterNetEvent("jg-mechanic:client:use-nitrous-bottle")
AddEventHandler("jg-mechanic:client:use-nitrous-bottle", function()
  local canRefill = lib.callback.await("jg-mechanic:server:can-refill-bottle-in-current-vehicle", false)
  if not canRefill then
    return
  end

  Framework.Client.ProgressBar(Locale.refillingBottle, 2500, false, false, function()
    TriggerServerEvent("jg-mechanic:server:use-nitrous-bottle")
  end, function()
  end)
end)
