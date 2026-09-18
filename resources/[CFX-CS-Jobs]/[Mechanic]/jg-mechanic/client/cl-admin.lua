RegisterNetEvent("jg-mechanic:client:open-admin", function()
  local adminData = lib.callback.await("jg-mechanic:server:get-admin-data", false)
  if not adminData then
    return
  end

  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "show-mechanic-admin",
    mechanics = adminData,
    config = Config,
    locale = Locale
  })
end)

RegisterNUICallback("delete-mechanic-data", function(data, cb)
  local mechanicId = data.mechanicId
  local success = lib.callback.await("jg-mechanic:server:delete-mechanic-data", false, mechanicId)

  if not success then
    return cb({ error = true })
  end

  TriggerEvent("jg-mechanic:client:open-admin")
  cb(true)
end)

RegisterNUICallback("set-mechanic-owner", function(data, cb)
  local mechanicId = data.mechanicId
  local player = data.player
  local success = lib.callback.await("jg-mechanic:server:set-mechanic-owner", false, mechanicId, player)

  if not success then
    return cb({ error = true })
  end

  TriggerEvent("jg-mechanic:client:open-admin")
  cb(true)
end)
