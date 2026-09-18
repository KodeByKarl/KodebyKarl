--
-- Custom code for common events
--

---@param vehicle integer Vehicle entity
---@param vehicleDbData table Vehicle row from the database
---@param type "personal" | "job" | "gang"
RegisterNetEvent("jg-advancedgarages:client:InsertVehicle:config", function(vehicle, vehicleDbData, type)
  -- Code placed in here will be run when the player inserts their vehicle (if the vehicle is owned; and passes all the checks)
end)

---@param vehicle integer Vehicle entity
RegisterNetEvent("jg-advancedgarages:client:ImpoundVehicle:config", function(vehicle)
  -- Code placed in here will be run just before the vehicle is set to impounded in the DB, and before the entity is deleted
end)

---@param vehicle integer Vehicle entity
---@param vehicleDbData table Vehicle row from the database
---@param type "personal" | "job" | "gang"
RegisterNetEvent("jg-advancedgarages:client:TakeOutVehicle:config", function(vehicle, vehicleDbData, garageType)
  if not vehicle or vehicle == 0 then return end
  if GetResourceState("jg-mechanic") ~= "started" then return end

  local function servicingIsBroken(data)
    if type(data) ~= "table" then return true end
    local any, allZero = false, true
    for _, value in pairs(data) do
      any = true
      if (tonumber(value) or 0) > 1 then
        allZero = false
        break
      end
    end
    return (not any) or allZero
  end

  local fresh = {
    suspension = 100,
    tyres = 100,
    brakePads = 100,
    engineOil = 100,
    clutch = 100,
    airFilter = 100,
    sparkPlugs = 100,
    evMotor = 100,
    evBattery = 100,
    evCoolant = 100,
  }

  local function applyIfBroken()
    if not DoesEntityExist(vehicle) then return end
    local plate = Framework.Client.GetPlate(vehicle)
    local current = Entity(vehicle).state and Entity(vehicle).state.servicingData
    -- Job spawners share plates and always need a reset. Personal cars only
    -- reset when mechanic data is missing or all parts are 0 (glitched).
    if garageType == "job" or servicingIsBroken(current) then
      lib.callback.await("jg-mechanic:server:set-vehicle-statebag", false, VehToNet(vehicle), "servicingData", fresh, true, plate)
    end
  end

  SetTimeout(0, function()
    if garageType == "job" then applyIfBroken() end
  end)
  -- Re-apply after jg-mechanic's delayed retrieve-and-apply on enter (~2s)
  SetTimeout(2500, applyIfBroken)
end)

---@param plate string
---@param newOwnerPlayerId integer
RegisterNetEvent("jg-advancedgarages:client:TransferVehicle:config", function(plate, newOwnerPlayerId)
  -- Code placed in here will be fired when a vehicle is transferred to another player via a public garage
end)

---@param vehicle integer Vehicle entity
---@param plate string
---@param garageId string
---@param vehicleDbData table Vehicle row from the database
---@param props table Vehicle properties
---@param fuel integer Fuel level
---@param body integer Body health
---@param engine integer Engine health
---@param damageModel table Damage model
RegisterNetEvent('jg-advancedgarages:client:insert-vehicle-verification', function(vehicle, plate, garageId, vehicleDbData, props, fuel, body, engine, damageModel, cb)
  cb(true)
end)

---@param plate string
---@param vehicleDbData table Vehicle row from the database
---@param garageId string
lib.callback.register("jg-advancedgarages:client:takeout-vehicle-verification", function(plate, vehicleDbData, garageId)
  return true
end)

-- Check whether a vehicle can be transferred between players, return false to prevent
---@param fromPlayerSrc integer
---@param toPlayerSrc integer
---@param plate string
---@return boolean allowTransfer
lib.callback.register("jg-advancedgarages:client:transfer-vehicle-verification", function(fromPlayerSrc, toPlayerSrc, plate)
  return true
end)

-- Check whether a vehicle can be transferred between garages, return false to prevent
---@param currentGarageId string
---@param fromGarageId string
---@param toGarageId string
---@param plate string
---@return boolean allowTransfer
lib.callback.register("jg-advancedgarages:client:transfer-garage-verification", function(currentGarageId, fromGarageId, toGarageId, plate)
  return true
end)