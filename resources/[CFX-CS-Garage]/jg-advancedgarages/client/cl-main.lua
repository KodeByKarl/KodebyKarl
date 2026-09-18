local function deleteVehicleEntity(vehicle)
  if GetResourceState("AdvancedParking") == "started" then
    exports.AdvancedParking:DeleteVehicle(vehicle, false)
    return
  end

  DeleteEntity(vehicle)
end
deleteVehicle = deleteVehicleEntity

local function getModelName(hash)
  local displayName = GetDisplayNameFromVehicleModel(hash)
  local label = GetLabelText(displayName)

  if label and label ~= "NULL" and label ~= "CARNOTFOUND" then
    return string.lower(label)
  end

  return string.lower(displayName)
end
getModelNameFromHash = getModelName

local function createTargetPed(coords)
  local pedModel = Config.TargetPed
  local pedHash = joaat(pedModel)

  lib.requestModel(pedModel)

  local ped = CreatePed(
    GetPedType(pedHash),
    pedHash,
    coords.x,
    coords.y,
    coords.z,
    coords.w or 0.0,
    false,
    false
  )

  lib.waitFor(function()
    return DoesEntityExist(ped) and ped or nil
  end)

  SetEntityInvincible(ped, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetPedFleeAttributes(ped, 0, false)
  SetPedCombatAttributes(ped, 17, true)
  FreezeEntityPosition(ped, true)
  SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, false)
  SetPedCanRagdoll(ped, false)
  SetEntityProofs(ped, true, true, true, true, true, true, true, true)
  SetModelAsNoLongerNeeded(pedHash)

  return ped
end
createPedForTarget = createTargetPed

local function resolveVehicleType(model)
  local modelHash = convertModelToHash(model)
  local class = GetVehicleClassFromName(modelHash)

  if IsThisModelABoat(modelHash) or class == 14 then
    return "sea"
  end

  if IsThisModelAHeli(modelHash) or IsThisModelAPlane(modelHash) or class == 16 then
    return "air"
  end

  return "car"
end
getVehicleType = resolveVehicleType

local function filterVehiclesByVehicleType(vehicles, vehicleType)
  local filteredVehicles = {}

  for _, vehicle in ipairs(vehicles) do
    if getVehicleType(vehicle.hash) == vehicleType then
      filteredVehicles[#filteredVehicles + 1] = vehicle
    end
  end

  return filteredVehicles
end
filterVehiclesByType = filterVehiclesByVehicleType

local function getVehicleDamageData(vehicle)
  if not vehicle or vehicle == 0 then
    return false
  end

  local body = 1000
  local engine = 1000
  local deformation = nil

  if Config.SaveVehicleDamage then
    body = math.ceil(GetVehicleBodyHealth(vehicle))
    if type(body) ~= "number" or body < 0 then
      body = 0
    end

    engine = math.ceil(GetVehicleEngineHealth(vehicle))
    if type(engine) ~= "number" or engine < 0 then
      engine = 0
    end

    if Config.AdvancedVehicleDamage then
      deformation = getVehicleDeformation(vehicle)
      if deformation and (not deformation.deformation or #deformation.deformation == 0) then
        deformation = nil
      end
    end
  end

  return body, engine, deformation
end
getVehicleDamage = getVehicleDamageData

RegisterNUICallback("close", function(_, cb)
  SetNuiFocus(false, false)
  cb(true)
end)
