local isOpen = false

local function OpenShop()
    if isOpen then return end
    local payload = lib.callback.await('cfx-keydi-playtimeshop:open', false)
    if not payload then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'cfx-keydi-playtimeshop:open',
        data = payload,
    })
end

local function CloseShop()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'cfx-keydi-playtimeshop:close' })
end

RegisterCommand(ConfigPlaytimeShop.Command or 'playtimeshop', function()
    if isOpen then
        CloseShop()
    else
        OpenShop()
    end
end, false)

if ConfigPlaytimeShop.OpenKey and ConfigPlaytimeShop.OpenKey ~= '' then
    RegisterKeyMapping(
        ConfigPlaytimeShop.Command or 'playtimeshop',
        'Open Playtime Shop',
        'keyboard',
        ConfigPlaytimeShop.OpenKey
    )
end

RegisterNUICallback('cfx-keydi-playtimeshop:close', function(_, cb)
    CloseShop()
    cb({ ok = true })
end)

RegisterNUICallback('cfx-keydi-playtimeshop:buy', function(data, cb)
    if not isOpen then
        cb({ ok = false })
        return
    end
    -- Forward only id + category — server validates product
    local result = lib.callback.await('cfx-keydi-playtimeshop:buy', false, {
        category = data and data.category,
        id = data and data.id,
    })
    cb(result or { ok = false })
end)

RegisterNUICallback('cfx-keydi-playtimeshop:top', function(_, cb)
    if not isOpen then
        cb({})
        return
    end
    local top = lib.callback.await('cfx-keydi-playtimeshop:top', false)
    cb(top or {})
end)

RegisterNetEvent('cfx-keydi-playtimeshop:coinsUpdated', function(data)
    if not isOpen then return end
    SendNUIMessage({
        action = 'cfx-keydi-playtimeshop:update',
        data = data,
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        CloseShop()
    end
end)

exports('OpenPlaytimeShop', OpenShop)
exports('ClosePlaytimeShop', CloseShop)
