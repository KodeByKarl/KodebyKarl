local function getMileageInKmByPlate(plate)
  if not plate or plate == "" then return false end
  
  local mileageKm = MySQL.scalar.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
  return mileageKm or 0
end

lib.callback.register("jg-vehiclemileage:server:get-mileage", function(_, plate)
  return getMileageInKmByPlate(plate)
end)

RegisterNetEvent("jg-vehiclemileage:server:update-mileage", function(plate, mileage)
  if not plate or plate == "" then return end
  MySQL.update("UPDATE " .. Framework.VehiclesTable .. " SET mileage = ? WHERE plate = ?", {mileage, plate})
end)

exports("getMileageByEntity", function(ent)
  if not ent or ent == 0 then return false end
  if not DoesEntityExist(ent) then return false end

  return Entity(ent).state?.vehicleMileage or 0
end)

exports("getMileageByPlate", function(plate)
  return getMileageInKmByPlate(plate)
end)

exports("getUnit", function() return Config.Unit end)

exports("GetMileage", function(plate)
  local vehicle = MySQL.single.await("SELECT mileage FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
  if not vehicle then return false end
  return vehicle.mileage, Config.Unit
end)
