local ox_inventory = exports.ox_inventory
local activeRentals = {}

lib.callback.register('cfx-keydi-utils:rental:pay', function(source, price, deposit, model, label, locationKey)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    price = tonumber(price) or 0
    deposit = tonumber(deposit) or 0
    local total = price + deposit
    if total <= 0 then return false end

    -- Check cash first
    local cash = ox_inventory:Search(src, 'count', 'money') or 0
    if cash >= total then
        ox_inventory:RemoveItem(src, 'money', total)
        pcall(function()
            exports[GetCurrentResourceName()]:FgVehicleSession(src, 'plate', true, 10000)
        end)
        return true, 'cash'
    end

    -- Check bank account
    local bankAccount = xPlayer.getAccount('bank')
    local bank = bankAccount and bankAccount.money or 0
    if bank >= total then
        xPlayer.removeAccountMoney('bank', total)
        pcall(function()
            exports[GetCurrentResourceName()]:FgVehicleSession(src, 'plate', true, 10000)
        end)
        return true, 'bank'
    end

    return false
end)

RegisterNetEvent('cfx-keydi-utils:rental:registered', function(netId, plate, deposit, method)
    local src = source
    activeRentals[src] = {
        netId = netId,
        plate = plate,
        deposit = tonumber(deposit) or 0,
        method = method or 'cash'
    }
end)

RegisterNetEvent('cfx-keydi-utils:rental:refund', function(deposit, method, plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    deposit = tonumber(deposit) or 0
    if deposit <= 0 then return end

    -- Refund according to original payment method
    if method == 'bank' then
        xPlayer.addAccountMoney('bank', deposit)
    else
        ox_inventory:AddItem(src, 'money', deposit)
    end

    activeRentals[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    activeRentals[src] = nil
end)
