local function getMechanicIdAndCheckPerms(source)
  local mechanicId = Player(source).state.mechanicId
  if not mechanicId then return false end
  local hasPermission = isEmployee(source, mechanicId, { "mechanic", "manager" }, true)
  if not hasPermission then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end
  return mechanicId
end

local function createInvoice(identifier, mechanicId, total, data)
  return MySQL.insert.await("INSERT INTO mechanic_invoices (identifier, mechanic, total, data) VALUES(?, ?, ?, ?)", {
    identifier,
    mechanicId,
    total,
    json.encode(data)
  })
end

lib.callback.register("jg-mechanic:server:get-unpaid-invoices", function(source)
  local mechanicId = getMechanicIdAndCheckPerms(source)
  if not mechanicId then return false end
  local unpaidInvoices = MySQL.query.await("SELECT * FROM mechanic_invoices WHERE mechanic = ? AND paid = 0 ORDER BY date DESC", { mechanicId })

  for i, invoice in ipairs(unpaidInvoices) do
    local recipientInfo = Framework.Server.GetPlayerInfoFromIdentifier(invoice.identifier)
    unpaidInvoices[i].recipient = recipientInfo and recipientInfo.name or "-"
  end
  return unpaidInvoices
end)

lib.callback.register("jg-mechanic:server:send-invoice", function(source, targetPlayerId, invoiceItems, invoiceTotal)
  local mechanicId = getMechanicIdAndCheckPerms(source)
  if not mechanicId then return false end

  local identifier = Framework.Server.GetPlayerIdentifier(targetPlayerId)
  if not identifier then return false end

  local targetPlayer = Player(targetPlayerId)
  if targetPlayer.state and targetPlayer.state.isBusy and source ~= targetPlayerId then
    Framework.Server.Notify(source, Locale.playerIsBusy, "error")
    return false
  end

  local invoiceId = createInvoice(identifier, mechanicId, invoiceTotal, invoiceItems)
  if not invoiceId then return false end

  local breakdown = {}
  for _, item in ipairs(invoiceItems) do
    breakdown[#breakdown + 1] = ("%s (%d)"):format(item.title, item.amount)
  end

  TriggerClientEvent("jg-mechanic:client:show-invoice-to-player", targetPlayerId, source, invoiceId, invoiceItems, invoiceTotal)
  local recipientInfo = Framework.Server.GetPlayerInfo(targetPlayerId)
  sendWebhook(source, Webhooks.Invoices, "Invoices: Invoice Sent", "success", {
    { key = "Mechanic", value = mechanicId },
    { key = "Invoice #", value = invoiceId },
    { key = "Recipient", value = recipientInfo and recipientInfo.name or targetPlayerId },
    { key = "Total", value = invoiceTotal },
    { key = "Breakdown", value = table.concat(breakdown, ", ") }
  })

  return true
end)

lib.callback.register("jg-mechanic:server:resend-invoice", function(source, targetPlayerId, invoiceId)
  local mechanicId = getMechanicIdAndCheckPerms(source)
  if not mechanicId then return false end

  local identifier = Framework.Server.GetPlayerIdentifier(targetPlayerId)
  if not identifier then return false end

  local targetPlayer = Player(targetPlayerId)
  if targetPlayer.state and targetPlayer.state.isBusy then
    Framework.Server.Notify(source, Locale.playerIsBusy, "error")
    return false
  end

  local invoiceData = MySQL.single.await("SELECT * FROM mechanic_invoices WHERE id = ? AND mechanic = ?", {
    invoiceId,
    mechanicId
  })
  if not invoiceData then return false end

  MySQL.update.await("UPDATE mechanic_invoices SET identifier = ? WHERE id = ? AND mechanic = ?", {
    identifier,
    invoiceId,
    mechanicId
  })
  local invoiceItems = json.decode(invoiceData.data)
  TriggerClientEvent("jg-mechanic:client:show-invoice-to-player", targetPlayerId, source, invoiceId, invoiceItems, invoiceData.total)

  local breakdown = {}
  for _, item in ipairs(invoiceItems) do
    breakdown[#breakdown + 1] = ("%s (%d)"):format(item.title, item.amount)
  end

  local recipientInfo = Framework.Server.GetPlayerInfo(targetPlayerId)
  sendWebhook(source, Webhooks.Invoices, "Invoices: Invoice Re-sent", "success", {
    { key = "Mechanic", value = mechanicId },
    { key = "Invoice #", value = invoiceId },
    { key = "Recipient", value = recipientInfo and recipientInfo.name or targetPlayerId },
    { key = "Total", value = invoiceData.total },
    { key = "Breakdown", value = table.concat(breakdown, ", ") }
  })
  return true
end)

lib.callback.register("jg-mechanic:server:save-invoice", function(source, invoiceItems, invoiceTotal)
  local mechanicId = getMechanicIdAndCheckPerms(source)
  if not mechanicId then return false end
  return createInvoice(nil, mechanicId, invoiceTotal, invoiceItems)
end)

lib.callback.register("jg-mechanic:server:delete-invoice", function(source, invoiceId)
  local mechanicId = getMechanicIdAndCheckPerms(source)
  if not mechanicId then return false end

  MySQL.update.await("DELETE FROM mechanic_invoices WHERE id = ? AND mechanic = ?", {
    invoiceId,
    mechanicId
  })
  sendWebhook(source, Webhooks.Invoices, "Invoices: Invoice Deleted", "danger", {
    { key = "Mechanic", value = mechanicId },
    { key = "Invoice #", value = invoiceId }
  })
  return true
end)

lib.callback.register("jg-mechanic:server:pay-invoice", function(source, invoiceId, senderPlayerId, paymentMethod)
  local identifier = Framework.Server.GetPlayerIdentifier(source)
  if not identifier then
    return false
  end

  local invoice = MySQL.single.await("SELECT * FROM mechanic_invoices WHERE id = ? AND identifier = ?", {
    invoiceId,
    identifier
  })
  if not invoice or invoice.total <= 0 then
    return false
  end

  if paymentMethod ~= "bank" and paymentMethod ~= "cash" then
    Framework.Server.Notify(source, "INVALID_PAYMENT_METHOD", "error")
    return false
  end

  local playerBalance = Framework.Server.GetPlayerBalance(source, paymentMethod)
  if playerBalance < invoice.total then
    Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
    return false
  end

  Framework.Server.PlayerRemoveMoney(source, invoice.total, paymentMethod)
  local mechanicConfig = Config.MechanicLocations[invoice.mechanic] or {}
  local commissionRate = mechanicConfig.commission or 0
  local commissionAmount = math.floor(invoice.total * (commissionRate / 100)) or 0
  local societyAmount = invoice.total

  if commissionAmount > 0 and senderPlayerId and senderPlayerId ~= source then
    societyAmount = invoice.total - commissionAmount
    Framework.Server.PlayerAddMoney(senderPlayerId, commissionAmount, "bank")
  end

  addToSocietyFund(source, invoice.mechanic, societyAmount)
  MySQL.update.await("UPDATE mechanic_invoices SET paid = 1 WHERE id = ? AND identifier = ?", {
    invoiceId,
    identifier
  })
  Framework.Server.Notify(senderPlayerId, Locale.invoicePaid, "success")
  sendWebhook(source, Webhooks.Invoices, "Invoices: Invoice Paid", "success", {
    { key = "Mechanic", value = invoice.mechanic },
    { key = "Invoice #", value = invoiceId },
    { key = "Total", value = invoice.total },
    { key = "Commission", value = commissionAmount },
    { key = "Payment Method", value = paymentMethod }
  })
  return true
end)
