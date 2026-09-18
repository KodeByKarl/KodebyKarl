function isEmployee(source, mechanicId, requiredRole, checkAdmin)
  if checkAdmin then
    if Config.AdminsHaveEmployeePermissions and Framework.Server.IsAdmin(source) then
      return "server_admin"
    end
  end

  local role = false
  if Config.UseFrameworkJobs then
    local mechanicConfig = Config.MechanicLocations[mechanicId]
    local playerJob = Framework.Server.GetPlayerJob(source)
    if playerJob and mechanicConfig then
      if playerJob.name == mechanicConfig.job then
        role = "mechanic"
        local isBoss = false
        if playerJob.grade_name and playerJob.grade_name:lower() == "boss" then
          isBoss = true
        elseif GetResourceState("cfx-keydi-society") == "started" then
          local ok, res = pcall(function() return exports["cfx-keydi-society"]:IsSocietyBoss(source, mechanicConfig.job) end)
          if ok and res then isBoss = true end
        end

        if isBoss or (mechanicConfig.jobManagementRanks and lib.table.contains(mechanicConfig.jobManagementRanks, playerJob.grade)) then
          role = "manager"
        end
      end
    end
  else
    local identifier = Framework.Server.GetPlayerIdentifier(source)
    local isOwner = MySQL.single.await("SELECT name FROM mechanic_data WHERE name = ? AND owner_id = ?",
      { mechanicId, identifier })
    if isOwner then
      return "owner"
    end
    local employeeData = MySQL.single.await("SELECT * FROM mechanic_employees WHERE identifier = ? AND mechanic = ?",
      { identifier, mechanicId })
    if not employeeData then
      return false
    end
    role = employeeData.role
  end

  if requiredRole and role then
    if type(requiredRole) == "string" and requiredRole ~= role then
      return false
    end
    if type(requiredRole) == "table" then
      if not lib.table.contains(requiredRole, role) then
        return false
      end
    end
  end
  return role
end

lib.callback.register("jg-mechanic:server:is-mechanic-employee", function(source, mechanicId)
  return isEmployee(source, mechanicId, { "owner", "manager", "mechanic" }, true)
end)

RegisterNetEvent("jg-mechanic:server:request-hire-employee", function(data)
  local source = source
  data.requesterId = source

  local hasPermission = isEmployee(source, data.mechanicId, "manager", true)
  if not hasPermission then
    return Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
  end

  TriggerClientEvent("jg-mechanic:client:show-confirm-employment", data.playerId, data)
end)

RegisterNetEvent("jg-mechanic:server:employee-hire-rejected", function(requesterId)
  Framework.Server.Notify(requesterId, Locale.employeeRejectedMsg, "error")
end)

RegisterNetEvent("jg-mechanic:server:hire-employee", function(data)
  local source = source
  local mechanicConfig = Config.MechanicLocations[data.mechanicId]
  local identifier = Framework.Server.GetPlayerIdentifier(data.playerId)

  MySQL.insert.await("INSERT INTO mechanic_employees (identifier, mechanic, role) VALUES (?, ?, ?)", {
    identifier,
    data.mechanicId,
    data.role
  })

  if mechanicConfig.job then
    Framework.Server.PlayerSetJob(data.playerId, mechanicConfig.job, data.role)
  end

  local newEmployeeInfo = Framework.Server.GetPlayerInfo(data.playerId)
  local employeeName = newEmployeeInfo and newEmployeeInfo.name or identifier

  sendWebhook(source, Webhooks.Mechanic, "Mechanic: Employee Hired", "success", {
    { key = "mechanic", value = data.mechanicId },
    { key = "Employee", value = employeeName },
    { key = "Role",     value = data.role }
  })

  Framework.Server.Notify(data.requesterId, Locale.employeeHiredMsg, "success")
  TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", source)
end)

RegisterNetEvent("jg-mechanic:server:fire-employee", function(identifier, mechanicId)
  local source = source
  local hasPermission = isEmployee(source, mechanicId, "manager", true)
  if not hasPermission then
    return Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
  end

  MySQL.insert.await("DELETE FROM mechanic_employees WHERE identifier = ? AND mechanic = ?", {
    identifier,
    mechanicId
  })

  local targetPlayer = Framework.Server.GetPlayerFromIdentifier(identifier)
  if targetPlayer then
    Framework.Server.PlayerSetJob(targetPlayer, "unemployed", 0)
    local notification = string.gsub(Locale.firedNotification, "%%{value}", mechanicId)
    Framework.Server.Notify(targetPlayer, notification, "error")
    TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", targetPlayer)
  else
    Framework.Server.PlayerSetJobOffline(identifier, "unemployed", 0)
  end

  local firedEmployeeInfo = Framework.Server.GetPlayerInfoFromIdentifier(identifier)
  local employeeName = firedEmployeeInfo and firedEmployeeInfo.name or identifier

  sendWebhook(source, Webhooks.Mechanic, "Mechanic: Employee Fired", "danger", {
    { key = "mechanic", value = mechanicId },
    { key = "Employee", value = employeeName }
  })
end)

RegisterNetEvent("jg-mechanic:server:update-employee-role", function(identifier, mechanicId, newRole)
  local source = source
  local hasPermission = isEmployee(source, mechanicId, "manager", true)
  if not hasPermission then
    return Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
  end

  local mechanicConfig = Config.MechanicLocations[mechanicId]
  MySQL.insert.await("UPDATE mechanic_employees SET role = ? WHERE identifier = ? AND mechanic = ?", {
    newRole,
    identifier,
    mechanicId
  })

  local targetPlayer = Framework.Server.GetPlayerFromIdentifier(identifier)
  if targetPlayer then
    if mechanicConfig.job then
      Framework.Server.PlayerSetJob(targetPlayer, mechanicConfig.job, newRole)
      TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", targetPlayer)
    end
  else
    Framework.Server.PlayerSetJobOffline(identifier, mechanicConfig.job, newRole)
  end

  local updatedEmployeeInfo = Framework.Server.GetPlayerInfoFromIdentifier(identifier)
  local employeeName = updatedEmployeeInfo and updatedEmployeeInfo.name or identifier

  sendWebhook(source, Webhooks.Mechanic, "Mechanic: Employee Updated", nil, {
    { key = "mechanic", value = mechanicId },
    { key = "Employee", value = employeeName },
    { key = "New role", value = newRole }
  })
end)
