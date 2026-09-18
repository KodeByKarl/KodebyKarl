lib.addCommand(Config.MechanicAdminCommand or "mechanicadmin", {
  help = Locale.mechanicAdminCmdDesc
}, function(source)
  if not Framework.Server.IsAdmin(source) then
    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
    return
  end
  TriggerClientEvent("jg-mechanic:client:open-admin", source)
end)

lib.callback.register("jg-mechanic:server:get-admin-data", function(source)
  if not Framework.Server.IsAdmin(source) then
    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
    return false
  end

  local mechanicsData = MySQL.query.await("SELECT * FROM mechanic_data")
  for i, mechanic in ipairs(mechanicsData) do
    local mechanicConfig = Config.MechanicLocations[mechanic.name]
    local mechanicType = "-"
    local isActive = false
    if mechanicConfig then
      mechanicType = mechanicConfig.type
      isActive = true
    end
    mechanicsData[i] = {
      name = mechanic.name,
      type = mechanicType,
      label = mechanic.label,
      balance = mechanic.balance,
      active = isActive,
      owner_id = mechanic.owner_id,
      owner_name = mechanic.owner_name,
      config = mechanicConfig
    }
  end
  return mechanicsData
end)

lib.callback.register("jg-mechanic:server:delete-mechanic-data", function(source, mechanicId)
  if not Framework.Server.IsAdmin(source) then
    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
    return false
  end

  MySQL.query.await("DELETE FROM mechanic_employees WHERE mechanic = ?", { mechanicId })
  MySQL.query.await("DELETE FROM mechanic_servicing_history WHERE mechanic = ?", { mechanicId })
  MySQL.query.await("DELETE FROM mechanic_orders WHERE mechanic = ?", { mechanicId })
  MySQL.query.await("DELETE FROM mechanic_invoices WHERE mechanic = ?", { mechanicId })
  MySQL.query.await("DELETE FROM mechanic_data WHERE name = ?", { mechanicId })

  sendWebhook(source, Webhooks.Admin, "Admin: Mechanic Data Deleted", "danger", {
    { key = "Mechanic", value = mechanicId }
  })

  return true
end)

lib.callback.register("jg-mechanic:server:set-mechanic-owner", function(source, mechanicId, targetPlayerId)
  if not Framework.Server.IsAdmin(source) then
    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
    return false
  end

  local identifier = Framework.Server.GetPlayerIdentifier(targetPlayerId)
  local targetInfo = Framework.Server.GetPlayerInfo(targetPlayerId)
  if not targetInfo or not identifier then
    Framework.Server.Notify(source, Locale.playerNotOnline, "error")
    return false
  end

  local success = MySQL.update.await("UPDATE mechanic_data SET owner_id = ?, owner_name = ? WHERE name = ?", {
    identifier,
    targetInfo.name,
    mechanicId
  })

  if not success then
    return false
  end

  TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", -1)
  sendWebhook(source, Webhooks.Admin, "Admin: Mechanic Owner Updated", nil, {
    { key = "Mechanic", value = mechanicId },
    { key = "Owner", value = targetInfo.name }
  })

  return true
end)
