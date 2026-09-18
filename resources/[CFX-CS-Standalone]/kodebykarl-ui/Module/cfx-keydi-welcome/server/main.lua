local ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('cfx-keydi-welcome:getWelcomeData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return cb(nil)
    end

    local firstName = xPlayer.get('firstName') or ""
    local lastName = xPlayer.get('lastName') or ""

    cb({
        firstName = firstName,
        lastName = lastName
    })
end)
