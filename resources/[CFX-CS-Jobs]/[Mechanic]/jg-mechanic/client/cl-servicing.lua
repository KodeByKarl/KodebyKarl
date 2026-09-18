local defaultServicingData = {
  suspension = 100,
  tyres = 100,
  brakePads = 100,
  engineOil = 100,
  clutch = 100,
  airFilter = 100,
  sparkPlugs = 100,
  evMotor = 100,
  evBattery = 100,
  evCoolant = 100
}

local function getVehicleServicingData(vehicle)
  local state = Entity(vehicle).state
  local data = state.servicingData
  if data and type(data) == "table" then
    return lib.table.clone(data)
  end
  return lib.table.clone(defaultServicingData)
end

AddStateBagChangeHandler("vehicleMileage", "", function(bagName, key, value)
  if not Config.EnableVehicleServicing then
    return
  end

  local vehicle = GetEntityFromStateBagName(bagName)
  if vehicle == 0 or not DoesEntityExist(vehicle) then
    return
  end

  if not (cache.vehicle == vehicle and cache.seat == -1) then
    return
  end

  local archetypeName = GetEntityArchetypeName(vehicle)
  if Config.ServicingBlacklist and type(Config.ServicingBlacklist) == "table" and lib.table.contains(Config.ServicingBlacklist, archetypeName) then
    return
  end

  if value % 1 ~= 0 or value < 1 then
    return
  end

  local model = GetEntityModel(vehicle)
  local isElectric = isVehicleElectric(archetypeName)
  local isSupportedVehicle = IsThisModelACar(model) or IsThisModelABike(model) or IsThisModelAQuadbike(model)

  if not isSupportedVehicle then
    return
  end

  local currentServicingData = getVehicleServicingData(vehicle)

  for part, partConfig in pairs(Config.Servicing) do
    if not (partConfig.restricted == "electric" and not isElectric) and not (partConfig.restricted == "combustion" and isElectric) then
      local wearRate = 100 / (partConfig.lifespanInKm or 0)
      local newHealth = round(math.max(0, currentServicingData[part] - wearRate), 5)
      currentServicingData[part] = newHealth
    end
  end

  setVehicleStatebag(vehicle, "servicingData", currentServicingData, true)

  local serviceRequired = false
  for part, health in pairs(currentServicingData) do
    if health <= Config.ServiceRequiredThreshold then
      serviceRequired = true
    end
  end

  if serviceRequired then
    Framework.Client.Notify(Locale.serviceVehicleSoon, "error")
  end
end)

--
-- Collision / Crash Damage to Servicing Parts
--
CreateThread(function()
  local lastVehicle = 0
  local lastBodyHealth = 1000.0
  local lastEngineHealth = 1000.0

  while true do
    local wait = 1000
    local vehicle = cache.vehicle

    if vehicle and vehicle ~= 0 and cache.seat == -1 and Config.EnableVehicleServicing and (Config.CrashDamageToServicing and Config.CrashDamageToServicing.enabled) then
      wait = 100
      
      local bodyHealth = GetVehicleBodyHealth(vehicle)
      local engineHealth = GetVehicleEngineHealth(vehicle)

      if vehicle ~= lastVehicle then
        lastVehicle = vehicle
        lastBodyHealth = bodyHealth
        lastEngineHealth = engineHealth
      else
        local bodyDelta = lastBodyHealth - bodyHealth
        local engineDelta = lastEngineHealth - engineHealth

        -- If vehicle was repaired or healed, update tracking health without applying damage
        if bodyDelta < 0 then
          lastBodyHealth = bodyHealth
          bodyDelta = 0
        end
        if engineDelta < 0 then
          lastEngineHealth = engineHealth
          engineDelta = 0
        end

        local totalDamage = math.max(bodyDelta, engineDelta)
        local minThreshold = (Config.CrashDamageToServicing and Config.CrashDamageToServicing.minDamageThreshold) or 25.0

        if totalDamage >= minThreshold then
          local archetypeName = GetEntityArchetypeName(vehicle)
          local isBlacklisted = Config.ServicingBlacklist and type(Config.ServicingBlacklist) == "table" and lib.table.contains(Config.ServicingBlacklist, archetypeName)
          
          if not isBlacklisted then
            local model = GetEntityModel(vehicle)
            local isSupportedVehicle = IsThisModelACar(model) or IsThisModelABike(model) or IsThisModelAQuadbike(model)
            
            if isSupportedVehicle then
              local isElectric = isVehicleElectric(archetypeName)
              local currentServicingData = getVehicleServicingData(vehicle)
              local baseMult = (Config.CrashDamageToServicing and Config.CrashDamageToServicing.damageMultiplier) or 0.05
              local partMults = (Config.CrashDamageToServicing and Config.CrashDamageToServicing.partMultipliers) or {}

              local changed = false
              for part, partConfig in pairs(Config.Servicing) do
                if not (partConfig.restricted == "electric" and not isElectric) and not (partConfig.restricted == "combustion" and isElectric) then
                  local mult = partMults[part] or 1.0
                  local damageLoss = totalDamage * baseMult * mult
                  if damageLoss > 0 then
                    local newHealth = round(math.max(0, (currentServicingData[part] or 100) - damageLoss), 2)
                    if newHealth ~= currentServicingData[part] then
                      currentServicingData[part] = newHealth
                      changed = true
                    end
                  end
                end
              end

              if changed then
                setVehicleStatebag(vehicle, "servicingData", currentServicingData, true)

                local serviceRequired = false
                for part, health in pairs(currentServicingData) do
                  if health <= Config.ServiceRequiredThreshold then
                    serviceRequired = true
                  end
                end

                if serviceRequired then
                  Framework.Client.Notify(Locale.serviceVehicleSoon, "error")
                end
              end
            end
          end
        end

        lastBodyHealth = bodyHealth
        lastEngineHealth = engineHealth
      end
    else
      lastVehicle = 0
    end

    Wait(wait)
  end
end)

RegisterNUICallback("service-vehicle", function(data, cb)
  local partName = data.name
  local partStats = data.stats
  local partConfig = Config.Servicing[partName]

  if not partConfig or not partStats then
    return cb(false)
  end

  local vehicle = LocalPlayer.state.tabletConnectedVehicle and LocalPlayer.state.tabletConnectedVehicle.vehicleEntity
  if not vehicle or not DoesEntityExist(vehicle) then
    return cb(false)
  end

  local vehiclePlate = Framework.Client.GetPlate(vehicle)
  local vehicleState = Entity(vehicle).state
  local servicingData = vehicleState.servicingData
  local minigameProp = "spanner"

  if partName == "tyres" or partName == "brakePads" then
    minigameProp = "wheel"
  end

  playMinigame(vehicle, "prop", { prop = minigameProp }, function(success)
    showTabletAfterInteractionPrompt()
    SetNuiFocus(true, true)

    if not success then
      return cb(false)
    end

    local paymentSuccess = lib.callback.await("jg-mechanic:server:pay-for-service", false, vehiclePlate, partName)
    if not paymentSuccess then
      return cb(false)
    end

    Framework.Client.Notify(Locale.partServiced:format(Locale[partName] or partName), "success")
    servicingData[partName] = 100
    setVehicleStatebag(vehicle, "servicingData", servicingData, true)
    cb(true)
  end)
end)

RegisterNUICallback("get-service-history", function(data, cb)
  local vehicle = LocalPlayer.state.tabletConnectedVehicle and LocalPlayer.state.tabletConnectedVehicle.vehicleEntity
  if not vehicle or not DoesEntityExist(vehicle) then
    return cb(false)
  end
  local plate = Framework.Client.GetPlate(vehicle)
  local history = lib.callback.await("jg-mechanic:server:get-servicing-history", false, plate)
  cb(history)
end)
