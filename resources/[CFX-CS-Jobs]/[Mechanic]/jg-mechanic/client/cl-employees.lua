RegisterNetEvent("jg-mechanic:client:show-confirm-employment", function(data)
  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "show-confirm-employment",
    data = data,
    config = Config,
    locale = Locale
  })
end)

RegisterNUICallback("accept-hire-request", function(data, cb)
  TriggerServerEvent("jg-mechanic:server:hire-employee", data)
  cb(true)
end)

RegisterNUICallback("deny-hire-request", function(data, cb)
  TriggerServerEvent("jg-mechanic:server:employee-hire-rejected", data.requesterId)
  cb(true)
end)

RegisterNUICallback("request-hire-employee", function(data, cb)
  local playerId = data.playerId
  if not playerId then
    return cb({ error = true })
  end

  local targetPlayer = Player(playerId)
  if targetPlayer.state and targetPlayer.state.isBusy then
    Framework.Client.Notify(Locale.playerIsBusy, "error")
    return cb(true)
  end

  TriggerServerEvent("jg-mechanic:server:request-hire-employee", data)
  cb(true)
end)

RegisterNUICallback("fire-employee", function(data, cb)
  local identifier = data.identifier
  local mechanicId = data.mechanicId
  TriggerServerEvent("jg-mechanic:server:fire-employee", identifier, mechanicId)
  cb(true)
end)

RegisterNUICallback("update-employee-role", function(data, cb)
  local identifier = data.identifier
  local mechanicId = data.mechanicId
  local newRole = data.newRole
  TriggerServerEvent("jg-mechanic:server:update-employee-role", identifier, mechanicId, newRole)
  cb(true)
end)
