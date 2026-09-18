local activeTabletConnections = {}

function HasActiveTabletConnection(src, vehicleNetId)
  local connection = activeTabletConnections[vehicleNetId]
  if connection then
    return connection.src == src
  end
  return false
end

lib.callback.register("jg-mechanic:server:connect-vehicle", function(src, vehicleNetId, netId)
  local existingConnection = activeTabletConnections[vehicleNetId]
  if existingConnection and existingConnection.netId == netId then
    return false
  end

  activeTabletConnections[vehicleNetId] = {
    netId = netId,
    src = src
  }
  return true
end)

lib.callback.register("jg-mechanic:server:disconnect-vehicle", function(src, vehicleNetId)
  local connection = activeTabletConnections[vehicleNetId]
  if not connection then
    return true
  end

  if connection.src ~= src then
    return false
  end

  activeTabletConnections[vehicleNetId] = nil
  return true
end)

lib.callback.register("jg-mechanic:server:get-player-mechanics", function(src)
  local accessibleMechanics = {}
  local isAdmin = Framework.Server.IsAdmin(src)

  if Config.UseFrameworkJobs then
    local playerJob = Framework.Server.GetPlayerJob(src)
    local mechanicShops = MySQL.query.await("SELECT name, label FROM mechanic_data")

    for _, shopData in pairs(mechanicShops) do
      local mechanicConfig = Config.MechanicLocations[shopData.name]
      if mechanicConfig then
        if Config.AdminsHaveEmployeePermissions and isAdmin or mechanicConfig.job == playerJob.name then
          if mechanicConfig.type == "owned" then
            local shopLabel = (shopData.label and shopData.label ~= "") and shopData.label or shopData.name
            accessibleMechanics[shopData.name] = shopLabel
          end
        end
      end
    end
  else
    local identifier = Framework.Server.GetPlayerIdentifier(src)
    local query = "SELECT d.*, e.identifier, e.role FROM mechanic_data d LEFT JOIN mechanic_employees e ON d.name = e.mechanic AND e.identifier = ?"
    local employeeData = MySQL.query.await(query, { identifier })

    for _, shopData in pairs(employeeData) do
      local mechanicConfig = Config.MechanicLocations[shopData.name]
      if mechanicConfig then
        if Config.AdminsHaveEmployeePermissions and isAdmin or shopData.owner_id == identifier or shopData.role == "manager" or shopData.role == "mechanic" then
          if mechanicConfig.type == "owned" then
            local shopLabel = (shopData.label and shopData.label ~= "") and shopData.label or shopData.name
            accessibleMechanics[shopData.name] = shopLabel
          end
        end
      end
    end
  end

  return accessibleMechanics
end)

lib.callback.register("jg-mechanic:server:get-tablet-mechanic-data", function(src, mechanicName)
  local employeeRole = isEmployee(src, mechanicName, { "mechanic", "manager" }, true)
  if not employeeRole then
    Framework.Server.Notify(src, Locale.employeePermissionsError, "error")
    return false
  end

  local mechanicData = MySQL.single.await("SELECT * FROM mechanic_data WHERE name = ?", { mechanicName })
  if not mechanicData then
    return false
  end

  local totalOrders = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_orders WHERE mechanic = ?", { mechanicName })
  local pendingOrders = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_orders WHERE mechanic = ? AND fulfilled = 0", { mechanicName })
  local totalInvoices = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_invoices WHERE mechanic = ?", { mechanicName })
  local unpaidInvoices = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_invoices WHERE paid = 0 AND mechanic = ?", { mechanicName })
  local totalEmployees = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_employees WHERE mechanic = ?", { mechanicName })

  return {
    label = mechanicData.label,
    balance = mechanicData.balance,
    ownerId = mechanicData.owner_id,
    ordersCount = pendingOrders or 0,
    unpaidInvoicesCount = unpaidInvoices or 0,
    employeeRole = employeeRole,
    stats = {
      totalOrders = totalOrders or 0,
      totalInvoices = totalInvoices or 0,
      totalEmployees = totalEmployees or 0
    }
  }
end)

lib.callback.register("jg-mechanic:server:get-vehicle-mileage", function(src, vehicleNetId)
  return exports["jg-vehiclemileage"]:GetMileage(vehicleNetId)
end)

lib.callback.register("jg-mechanic:server:toggle-on-duty", function(src, onDuty)
  local playerState = Player(src).state
  if not playerState or not playerState.mechanicId then
    return false
  end

  local hasPermission = isEmployee(src, playerState.mechanicId, { "mechanic", "manager" }, true)
  if not hasPermission then
    Framework.Server.Notify(src, Locale.employeePermissionsError, "error")
    return false
  end

  local mechanicsOnDuty = GlobalState.mechanicsOnDuty or {}
  mechanicsOnDuty[tostring(src)] = onDuty and playerState.mechanicId or false
  GlobalState:set("mechanicsOnDuty", mechanicsOnDuty, true)

  return true
end)

lib.callback.register("jg-mechanic:server:is-on-duty", function(src, mechanicName)
  if not GlobalState.mechanicsOnDuty then
    return false
  end
  return GlobalState.mechanicsOnDuty[tostring(src)] == mechanicName
end)

lib.callback.register("jg-mechanic:server:get-tablet-preferences", function(src)
  local identifier = Framework.Server.GetPlayerIdentifier(src)
  local preferencesJson = MySQL.scalar.await("SELECT preferences FROM mechanic_settings WHERE identifier = ?", { identifier })

  if preferencesJson then
    local preferences = json.decode(preferencesJson)
    if preferences then
      return preferences
    end
  end
  return false
end)

lib.callback.register("jg-mechanic:server:save-tablet-settings", function(src, preferences)
  local playerState = Player(src).state
  if not playerState or not playerState.mechanicId then
    return false
  end

  local hasPermission = isEmployee(src, playerState.mechanicId, { "mechanic", "manager" }, true)
  if not hasPermission then
    Framework.Server.Notify(src, Locale.employeePermissionsError, "error")
    return false
  end

  local identifier = Framework.Server.GetPlayerIdentifier(src)
  local encodedPreferences = json.encode(preferences)
  local query = "INSERT INTO mechanic_settings (identifier, preferences) VALUES(?, ?) ON DUPLICATE KEY UPDATE preferences = ?"
  MySQL.insert.await(query, { identifier, encodedPreferences, encodedPreferences })

  return true
end)

if Config.UseTabletCommand then
  lib.addCommand(Config.UseTabletCommand == true and "tablet" or Config.UseTabletCommand, {
    help = "Open mechanic tablet"
  }, function(source, args, raw)
    TriggerClientEvent("jg-mechanic:client:use-tablet", source)
  end)
end
