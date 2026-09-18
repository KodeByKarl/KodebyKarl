RegisterNUICallback("get-mechanic-balance", function(data, cb)
    local mechanicId = data.mechanicId
    cb(lib.callback.await("jg-mechanic:server:get-mechanic-balance", false, mechanicId))
end)

RegisterNUICallback("update-mechanic-balance", function(data, cb)
    local action = data.action
    local mechanicId = data.mechanicId
    local amount = data.amount
    local source = data.source

    if action == "deposit" then
        return cb(lib.callback.await("jg-mechanic:server:mechanic-deposit", false, mechanicId, source, amount))
    elseif action == "withdraw" then
        return cb(lib.callback.await("jg-mechanic:server:mechanic-withdraw", false, mechanicId, amount))
    end

    return cb({ error = true })
end)

RegisterNUICallback("get-mechanic-employees", function(data, cb)
    local mechanicId = data.mechanicId
    cb(lib.callback.await("jg-mechanic:server:get-mechanic-employees", false, mechanicId))
end)

RegisterNUICallback("update-mechanic-settings", function(data, cb)
    local mechanicId = data.mechanicId
    cb(lib.callback.await("jg-mechanic:server:update-mechanic-settings", false, mechanicId, data))
end)
