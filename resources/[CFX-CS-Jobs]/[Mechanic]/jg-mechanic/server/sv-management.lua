function getSocietyFund(source, mechanicName)
  local locationConfig = Config.MechanicLocations[mechanicName]
  local jobName = (locationConfig and locationConfig.job) or mechanicName

  if GetResourceState("cfx-keydi-society") == "started" then
    return exports["cfx-keydi-society"]:GetMoney(jobName) or 0
  end

  if Config.UseFrameworkJobs then
    return Framework.Server.GetSocietyBalance(jobName, "job") or 0
  else
    return MySQL.scalar.await("SELECT balance FROM mechanic_data WHERE name = ?", { mechanicName }) or 0
  end
end

function addToSocietyFund(source, mechanicName, amount)
  amount = tonumber(amount) or 0
  if not amount or amount <= 0 then
    return false
  end

  local locationConfig = Config.MechanicLocations[mechanicName]
  local jobName = (locationConfig and locationConfig.job) or mechanicName

  if GetResourceState("cfx-keydi-society") == "started" then
    return exports["cfx-keydi-society"]:AddMoney(jobName, amount)
  end

  if Config.UseFrameworkJobs then
    Framework.Server.PayIntoSocietyFund(jobName, "job", amount)
  else
    MySQL.update.await("UPDATE mechanic_data SET balance = balance + ? WHERE name = ?", {
      amount,
      mechanicName
    })
  end

  return true
end

function removeFromSocietyFund(source, mechanicName, amount)
  amount = tonumber(amount) or 0
  if not amount or amount <= 0 then
    return false
  end

  local locationConfig = Config.MechanicLocations[mechanicName]
  local jobName = (locationConfig and locationConfig.job) or mechanicName

  if GetResourceState("cfx-keydi-society") == "started" then
    local societyBalance = exports["cfx-keydi-society"]:GetMoney(jobName) or 0
    if amount > societyBalance then
      if source and source > 0 then
        Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
      end
      return false
    end
    return exports["cfx-keydi-society"]:RemoveMoney(jobName, amount)
  end

  if Config.UseFrameworkJobs then
    local societyBalance = Framework.Server.GetSocietyBalance(jobName, "job")

    if amount > societyBalance then
      if source and source > 0 then
        Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
      end
      return false
    end

    Framework.Server.RemoveFromSocietyFund(jobName, "job", amount)
  else
    local balance = MySQL.scalar.await("SELECT balance FROM mechanic_data WHERE name = ?", { mechanicName }) or 0

    if amount > balance then
      if source and source > 0 then
        Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
      end
      return false
    end

    MySQL.update.await("UPDATE mechanic_data SET balance = balance - ? WHERE name = ?", {
      amount,
      mechanicName
    })
  end

  return true
end

lib.callback.register("jg-mechanic:server:get-mechanic-balance", function(source, mechanicName)
  local hasPermission = isEmployee(source, mechanicName, { "mechanic", "manager" }, true)

  if not hasPermission then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  return getSocietyFund(source, mechanicName)
end)

lib.callback.register("jg-mechanic:server:get-mechanic-employees", function(source, mechanicName)
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(source)

  if Config.UseFrameworkJobs then
    return {}
  end

  local hasPermission = isEmployee(source, mechanicName, "manager", true)
  if not hasPermission then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local employees = MySQL.query.await("SELECT * FROM mechanic_employees WHERE mechanic = ?", { mechanicName })

  for index, employeeData in ipairs(employees) do
    local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(employeeData.identifier)
    local playerName = (playerInfo and playerInfo.name) or "-"

    employees[index] = {
      id = employeeData.player,
      identifier = employeeData.identifier,
      name = playerName,
      role = employeeData.role,
      joined = employeeData.joined,
      me = (playerIdentifier == employeeData.identifier)
    }
  end

  return employees
end)

lib.callback.register("jg-mechanic:server:mechanic-deposit", function(source, mechanicName, accountType, amount)
  local hasPermission = isEmployee(source, mechanicName, { "mechanic", "manager" }, true)
  if not hasPermission then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  amount = tonumber(amount) or 0
  if amount <= 0 then
    Framework.Server.Notify(source, "Stop trying to exploit the script", "error")
    return false
  end

  local playerBalance = Framework.Server.GetPlayerBalance(source, accountType)
  if amount > playerBalance then
    Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
    return false
  end

  Framework.Server.PlayerRemoveMoney(source, amount, accountType)
  addToSocietyFund(source, mechanicName, amount)

  Framework.Server.Notify(source, Locale.depositSuccess, "success")
  sendWebhook(source, Webhooks.Mechanic, "Mechanic: Money Deposited", nil, {
    { key = "Mechanic", value = mechanicName },
    { key = "Amount", value = amount }
  })

  return true
end)

lib.callback.register("jg-mechanic:server:mechanic-withdraw", function(source, mechanicName, amount)
  local hasPermission = isEmployee(source, mechanicName, "manager", true)
  if not hasPermission then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  amount = tonumber(amount) or 0
  if amount <= 0 then
    Framework.Server.Notify(source, "Stop trying to exploit the script", "error")
    return false
  end

  local success = removeFromSocietyFund(source, mechanicName, amount)
  if not success then
    return false
  end

  Framework.Server.PlayerAddMoney(source, amount, "bank")

  Framework.Server.Notify(source, Locale.withdrawSuccess, "success")
  sendWebhook(source, Webhooks.Mechanic, "Mechanic: Money Withdrawn", nil, {
    { key = "Mechanic", value = mechanicName },
    { key = "Amount", value = amount }
  })

  return true
end)

lib.callback.register("jg-mechanic:server:update-mechanic-settings", function(source, mechanicName, settings)
  local hasPermission = isEmployee(source, mechanicName, "manager", true)
  if not hasPermission then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  MySQL.update.await("UPDATE mechanic_data SET label = ? WHERE name = ?", {
    settings.label,
    mechanicName
  })

  TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", -1)

  sendWebhook(source, Webhooks.Mechanic, "Mechanic: Name Updated", nil, {
    { key = "Mechanic", value = mechanicName },
    { key = "New name", value = settings.label }
  })

  return true
end)
