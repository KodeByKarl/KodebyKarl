local inParty = false

local function vitals()
    local ped = PlayerPedId()
    local hp = math.max(0, math.min(100, GetEntityHealth(ped) - 100))
    local ar = math.max(0, math.min(100, GetPedArmour(ped)))
    if GetEntityHealth(ped) <= 0 or IsEntityDead(ped) then
        hp = 0
    end
    return hp, ar
end

RegisterNetEvent('cfx-keydi-ipad:party:hud', function(payload)
    payload = type(payload) == 'table' and payload or { visible = false }
    inParty = payload.visible == true
    SendNUIMessage({
        action = 'cfx-keydi-ipad:party:hud',
        data = payload,
    })
    if inParty then
        local hp, ar = vitals()
        TriggerServerEvent('cfx-keydi-ipad:party:vitals', hp, ar)
    end
end)

CreateThread(function()
    Wait(2500)
    local state = lib.callback.await('cfx-keydi-ipad:party:state', false)
    if type(state) == 'table' and state.mine then
        inParty = true
    end
end)

CreateThread(function()
    local lastHp, lastAr = -1, -1
    while true do
        if inParty then
            local hp, ar = vitals()
            if hp ~= lastHp or ar ~= lastAr then
                lastHp, lastAr = hp, ar
                TriggerServerEvent('cfx-keydi-ipad:party:vitals', hp, ar)
            end
            Wait(400)
        else
            lastHp, lastAr = -1, -1
            Wait(1500)
        end
    end
end)

local function partyCb(name, data)
    local result = lib.callback.await(name, false, data or {})
    return result or { ok = false, error = 'No response' }
end

RegisterNUICallback('cfx-keydi-ipad:party:state', function(_, cb)
    cb(partyCb('cfx-keydi-ipad:party:state'))
end)

RegisterNUICallback('cfx-keydi-ipad:party:create', function(data, cb)
    cb(partyCb('cfx-keydi-ipad:party:create', data))
end)

RegisterNUICallback('cfx-keydi-ipad:party:join', function(data, cb)
    cb(partyCb('cfx-keydi-ipad:party:join', data))
end)

RegisterNUICallback('cfx-keydi-ipad:party:leave', function(_, cb)
    cb(partyCb('cfx-keydi-ipad:party:leave'))
end)

RegisterNUICallback('cfx-keydi-ipad:party:kick', function(data, cb)
    cb(partyCb('cfx-keydi-ipad:party:kick', data))
end)

RegisterNUICallback('cfx-keydi-ipad:party:disband', function(_, cb)
    cb(partyCb('cfx-keydi-ipad:party:disband'))
end)

RegisterNUICallback('cfx-keydi-ipad:party:stopDrag', function(_, cb)
    SetNuiFocus(false, false)
    if cb then cb('ok') end
end)

--- Drag / reposition squad HUD (health + armor). ESC or release finishes.
RegisterCommand(ConfigIpad.Party and ConfigIpad.Party.EditPosCommand or 'movesquad', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'cfx-keydi-ipad:party:startDrag',
        data = {},
    })
    if ESX and ESX.Notify then
        ESX.Notify('Squad', 'Drag the squad HUD. Press ESC when done.', 'info', 5000)
    end
end, false)

TriggerEvent('chat:addSuggestion', '/' .. (ConfigIpad.Party and ConfigIpad.Party.EditPosCommand or 'movesquad'), 'Move / drag the squad HUD')
