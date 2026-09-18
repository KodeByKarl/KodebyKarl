exports("doesVehicleNeedServicing", function(plate)
  if not plate then return false end

  local query = "SELECT " .. Framework.VehProps .. " FROM " .. Framework.VehiclesTable .. " WHERE plate = ?"
  local result = MySQL.scalar.await(query, { plate })
  if not result then return false end

  local props = json.decode(result or "{}")
  local servicingData = props.servicingData
  if not servicingData or type(servicingData) ~= "table" then
    return false
  end

  for part, health in pairs(servicingData) do
    if health <= Config.ServiceRequiredThreshold then
      return true
    end
  end
  return false
end)

exports("getVehicleServiceHistory", function(plate)
  if not plate then return false end
  local query = "SELECT msh.*, COALESCE(CASE WHEN md.label IS NOT NULL AND TRIM(md.label) != '' THEN md.label ELSE msh.mechanic END, msh.mechanic) AS mechanic_label FROM mechanic_servicing_history msh LEFT JOIN mechanic_data md ON msh.mechanic = md.name WHERE msh.plate = ? ORDER BY date DESC"
  return MySQL.query.await(query, { plate })
end)

lib.callback.register("jg-mechanic:server:pay-for-service", function(source, plate, partName)
  if not HasActiveTabletConnection(source, plate) then return false end
  local playerState = Player(source).state
  local partConfig = Config.Servicing[partName]
  if not partConfig then return false end

  local itemName = partConfig.itemName
  local itemQuantity = partConfig.itemQuantity
  if not itemName then return false end

  local mechanicId = playerState.mechanicId
  if not mechanicId then return false end

  local hasPermission = isEmployee(source, mechanicId, { "mechanic", "manager" }, true)
  if not hasPermission then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local itemRemoved = Framework.Server.RemoveItem(source, itemName, itemQuantity or 1)
  if not itemRemoved then return false end

  local identifier = Framework.Server.GetPlayerIdentifier(source)
  local mileage = exports["jg-vehiclemileage"]:GetMileage(plate)
  MySQL.insert.await("INSERT INTO mechanic_servicing_history (identifier, mechanic, plate, mileage_km, serviced_part) VALUES (?, ?, ?, ?, ?)", {
    identifier,
    mechanicId,
    plate,
    mileage,
    partName
  })
  sendWebhook(source, Webhooks.Servicing, "Servicing: Vehicle Serviced", "success", {
    { key = "Mechanic", value = mechanicId },
    { key = "Vehicle Plate", value = plate },
    { key = "Part Serviced", value = Locale[partName] or partName }
  })
  return true
end)

lib.callback.register("jg-mechanic:server:get-servicing-history", function(source, plate)
  local playerState = Player(source).state
  local mechanicId = playerState.mechanicId
  if not mechanicId then return false end
  local hasPermission = isEmployee(source, mechanicId, { "mechanic", "manager" }, true)
  if not hasPermission then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end
  local history = exports["jg-mechanic"]:getVehicleServiceHistory(plate)
  local mileage, unit = exports["jg-vehiclemileage"]:GetMileage(plate)
  return {
    servicingHistory = history,
    mileageUnit = unit
  }
end)
