local fulfilledOrderLocks = {}

lib.callback.register("jg-mechanic:server:get-orders", function(source, page, limit)
  local player = Player(source)
  local mechanicId = player.state.mechanicId
  if not mechanicId then return {} end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return {}
  end

  local offset = page * limit
  local orders = MySQL.query.await("SELECT * FROM mechanic_orders WHERE mechanic = ? AND fulfilled = 0 ORDER BY date DESC LIMIT ? OFFSET ?", {
    mechanicId,
    limit,
    offset
  })

  for i, order in ipairs(orders) do
    local recipientInfo = Framework.Server.GetPlayerInfoFromIdentifier(order.identifier)
    orders[i].recipient = recipientInfo and recipientInfo.name or "-"
  end

  local totalOrders = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_orders WHERE mechanic = ? AND fulfilled = 0", { mechanicId })
  local pageCount = math.ceil(totalOrders / limit)

  return {
    orders = orders,
    pageCount = pageCount,
    totalOrders = totalOrders,
  }
end)

lib.callback.register("jg-mechanic:server:can-apply-order", function(source, orderId)
  local player = Player(source)
  local mechanicId = player.state.mechanicId
  if not mechanicId then return false end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local order = MySQL.single.await("SELECT * FROM mechanic_orders WHERE id = ? AND mechanic = ? AND fulfilled = 0", {
    orderId,
    mechanicId
  })

  return order or false
end)

lib.callback.register("jg-mechanic:server:pay-for-order-installation", function(source, modCategory, itemCount)
  local player = Player(source)
  local mechanicId = player.state.mechanicId
  local partConfig = Config.Mods.ItemsRequired[modCategory]
  local paymentType = Config.Mods.PaymentType or 'item'

  if not partConfig or not mechanicId then return false end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  if paymentType == 'item' then
    if not partConfig.itemName then return false end
    local wasItemRemoved = Framework.Server.RemoveItem(source, partConfig.itemName, itemCount or 1)
    if not wasItemRemoved then
      Framework.Server.Notify(source, "No tienes la pieza necesaria en el inventario.", "error")
      return false
    end
  else
    if not partConfig.price or partConfig.price <= 0 then return false end
    local price = partConfig.price * (itemCount or 1)
    local hasPaid = Framework.Server.PlayerRemoveMoney(source, price, paymentType)
    if not hasPaid then
      Framework.Server.Notify(source, "No tienes suficiente dinero.", "error")
      return false
    end
  end

  FgMechanicSession(source, 'apply', true, 15000)
  FgMechanicSession(source, 'repair', true, 15000)
  return true
end)

lib.callback.register("jg-mechanic:server:mark-category-installed", function(source, orderId, category)
  local player = Player(source)
  local mechanicId = player.state.mechanicId
  if not mechanicId then return false end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local progressJson = MySQL.scalar.await("SELECT installation_progress FROM mechanic_orders WHERE id = ? AND mechanic = ? AND fulfilled = 0", {
    orderId,
    mechanicId
  })

  local installationProgress = json.decode(progressJson or "{}")
  if type(installationProgress) ~= "table" then
    installationProgress = {}
  end

  installationProgress[category] = true

  MySQL.update.await("UPDATE mechanic_orders SET installation_progress = ? WHERE id = ? AND mechanic = ?", {
    json.encode(installationProgress),
    orderId,
    mechanicId
  })

  return true
end)

lib.callback.register("jg-mechanic:server:mark-order-fulfilled", function(source, orderId)
  if fulfilledOrderLocks[orderId] then return false end
  fulfilledOrderLocks[orderId] = true

  local player = Player(source)
  local mechanicId = player.state.mechanicId
  if not mechanicId then
    fulfilledOrderLocks[orderId] = nil
    return false
  end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    fulfilledOrderLocks[orderId] = nil
    return false
  end

  local mechanicLocation = Config.MechanicLocations[mechanicId]
  if not mechanicLocation then
    fulfilledOrderLocks[orderId] = nil
    return false
  end

  local amountPaid = MySQL.scalar.await("SELECT amount_paid FROM mechanic_orders WHERE id = ? AND fulfilled = 0", { orderId })
  if not amountPaid then
    fulfilledOrderLocks[orderId] = nil
    return false
  end

  local commissionPercentage = mechanicLocation.commission or 0
  local commissionAmount = math.floor((amountPaid * commissionPercentage) / 100)

  if commissionAmount > 0 then
    removeFromSocietyFund(source, mechanicId, commissionAmount)
    Framework.Server.PlayerAddMoney(source, commissionAmount, "bank")
    Framework.Server.Notify(source, "Comisión pagada.", "success")
  end

  MySQL.update.await("UPDATE mechanic_orders SET fulfilled = 1 WHERE mechanic = ? AND id = ?", {
    mechanicId,
    orderId
  })

  sendWebhook(source, Webhooks.Orders, "Orden marcada como completada", "default", {
    { key = "Taller", value = mechanicId },
    { key = "Orden #", value = orderId },
    { key = "Comisión ganada", value = commissionAmount },
  })

  fulfilledOrderLocks[orderId] = nil
  return true
end)

lib.callback.register("jg-mechanic:server:delete-order", function(source, orderId)
  local player = Player(source)
  local mechanicId = player.state.mechanicId
  if not mechanicId then return false end

  local requiredRoles = Config.RequireManagementForOrderDeletion and { "manager" } or { "mechanic", "manager" }

  if not isEmployee(source, mechanicId, requiredRoles, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local orderData = MySQL.single.await("SELECT identifier, amount_paid FROM mechanic_orders WHERE fulfilled = 0 AND id = ?", { orderId })
  if not orderData then
    Framework.Server.Notify(source, "No se encontró una orden sin completar.", "error")
    return false
  end

  if not removeFromSocietyFund(source, mechanicId, orderData.amount_paid) then
    return false
  end

  Framework.Server.PlayerAddMoneyOffline(orderData.identifier, orderData.amount_paid)
  MySQL.update.await("UPDATE mechanic_orders SET fulfilled = 1 WHERE mechanic = ? AND id = ?", {
    mechanicId,
    orderId
  })

  sendWebhook(source, Webhooks.Orders, "Orden eliminada", "default", {
    { key = "Taller", value = mechanicId },
    { key = "Orden #", value = orderId },
    { key = "Cantidad devuelta", value = orderData.amount_paid },
  })

  return true
end)
