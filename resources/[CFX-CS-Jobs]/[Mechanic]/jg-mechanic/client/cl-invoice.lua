local activeInvoiceData = nil

RegisterNUICallback("get-unpaid-invoices", function(data, cb)
  local invoices = lib.callback.await("jg-mechanic:server:get-unpaid-invoices", false)
  cb(invoices)
end)

RegisterNUICallback("save-invoice", function(data, cb)
  local invoiceItems = data.invoiceItems
  local invoiceTotal = data.invoiceTotal

  if not invoiceItems or not invoiceTotal then
    return cb(false)
  end

  local success = lib.callback.await("jg-mechanic:server:save-invoice", false, invoiceItems, invoiceTotal)
  cb(success)
end)

RegisterNUICallback("send-invoice", function(data, cb)
  local player = data.player
  local invoiceItems = data.invoiceItems
  local invoiceTotal = data.invoiceTotal

  if not player or not invoiceItems then
    return cb(false)
  end

  local success = lib.callback.await("jg-mechanic:server:send-invoice", false, player, invoiceItems, invoiceTotal)
  cb(success)
end)

RegisterNUICallback("resend-invoice", function(data, cb)
  local player = data.player
  local invoiceId = data.invoiceId

  if not player or not invoiceId then
    return cb(false)
  end

  local success = lib.callback.await("jg-mechanic:server:resend-invoice", false, player, invoiceId)
  cb(success)
end)

RegisterNUICallback("delete-invoice", function(data, cb)
  local invoiceId = data.invoiceId
  local success = lib.callback.await("jg-mechanic:server:delete-invoice", false, invoiceId)
  cb(success)
end)

RegisterNUICallback("pay-invoice", function(data, cb)
  local paymentMethod = data.paymentMethod

  if not activeInvoiceData then
    return cb({ error = true })
  end

  local success = lib.callback.await("jg-mechanic:server:pay-invoice", false, activeInvoiceData.invoiceId, activeInvoiceData.senderPlayerId, paymentMethod)

  if not success then
    return cb({ error = true })
  end

  activeInvoiceData = nil
  cb(true)
end)

RegisterNetEvent("jg-mechanic:client:show-invoice-to-player", function(senderPlayerId, invoiceId, invoiceItems, invoiceTotal)
  activeInvoiceData = {
    invoiceId = invoiceId,
    senderPlayerId = senderPlayerId
  }

  if cache.serverId == senderPlayerId then
    DisconnectVehicle()
    LocalPlayer.state:set("mechanicId", nil, true)
  end

  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "show-invoice",
    invoiceItems = invoiceItems,
    invoiceTotal = invoiceTotal,
    bankBalance = Framework.Client.GetBalance("bank"),
    cashBalance = Framework.Client.GetBalance("cash"),
    locale = Locale,
    config = Config
  })
end)
