-- Server-side handler for OBD-II Vehicle Diagnostic Scanner
lib.callback.register("jg-mechanic:server:get-vehicle-diagnostics", function(source, plate, netId)
  if not plate or plate == "" then return false end

  local vehicle = netId and netId ~= 0 and NetworkGetEntityFromNetworkId(netId) or 0
  local mileage = 0
  local mileageUnit = "km"

  if GetResourceState("jg-vehiclemileage") == "started" then
    local m, u = exports["jg-vehiclemileage"]:GetMileage(plate)
    mileage = tonumber(m) or 0
    mileageUnit = u or "km"
  end

  local servicingData = {}
  local tuningConfig = {}

  if vehicle ~= 0 and DoesEntityExist(vehicle) then
    local state = Entity(vehicle).state
    if state then
      servicingData = state.servicingData or {}
      tuningConfig = state.tuningConfig or {}
    end
  end

  -- Fallback to DB if statebag was empty
  if not next(servicingData) then
    local query = "SELECT " .. Framework.VehProps .. " FROM " .. Framework.VehiclesTable .. " WHERE plate = ?"
    local result = MySQL.scalar.await(query, { plate })
    if result then
      local props = json.decode(result or "{}")
      servicingData = props.servicingData or {}
      tuningConfig = props.tuningConfig or {}
    end
  end

  local serviceHistory = exports["jg-mechanic"]:getVehicleServiceHistory(plate) or {}

  return {
    plate = plate,
    mileage = mileage,
    mileageUnit = mileageUnit,
    servicingData = servicingData,
    tuningConfig = tuningConfig,
    historyCount = #serviceHistory,
    lastServiced = serviceHistory[1] and serviceHistory[1].date or nil
  }
end)

RegisterNetEvent("jg-mechanic:server:share-diagnostic-report", function(targetId, reportData)
  local src = source
  if not targetId or targetId <= 0 or not reportData then return end

  local targetPlayer = Framework.Server.GetPlayerFromId(targetId)
  if not targetPlayer then
    return Framework.Server.Notify(src, Locale.playerNotOnline or "Player not found", "error")
  end

  TriggerClientEvent("jg-mechanic:client:show-shared-diagnostic-report", targetId, reportData)
  Framework.Server.Notify(src, "Diagnostic report shared successfully!", "success")
end)
