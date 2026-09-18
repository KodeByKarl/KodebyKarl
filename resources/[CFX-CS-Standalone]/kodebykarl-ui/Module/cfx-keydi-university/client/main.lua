local ESX = exports['es_extended']:getSharedObject()

local registrarPed = nil
local isOpen = false

local function cfg()
    return ConfigUniversity or {}
end

local function closeRegistrar()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'cfx-keydi-university:registrar:hide' })
end

local function openRegistrar()
    local c = cfg()
    if c.Enabled == false then return end
    if isOpen then return end
    if not canUseSchool() then
        lib.notify({
            title = c.Label or 'ULS Registrar',
            description = (ConfigServerLocations and ConfigServerLocations.WrongServerMessage)
                and ConfigServerLocations.WrongServerMessage('school')
                or 'University is only available on Region 2.',
            type = 'error',
        })
        return
    end

    local payload = lib.callback.await('cfx-keydi-university:registrar:open', false)
    if not payload or not payload.ok then
        lib.notify({
            title = c.Label or 'ULS Registrar',
            description = 'Registrar is unavailable right now.',
            type = 'error',
        })
        return
    end

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'cfx-keydi-university:registrar:show',
        data = payload,
    })
end

local function canUseSchool()
    if not ConfigServerLocations or not ConfigServerLocations.CanUseFunction then
        return false
    end
    return ConfigServerLocations.CanUseFunction('school')
end

local function deleteRegistrar()
    if registrarPed and DoesEntityExist(registrarPed) then
        if GetResourceState('ox_target') == 'started' then
            pcall(function()
                exports.ox_target:removeLocalEntity(registrarPed)
            end)
        end
        DeleteEntity(registrarPed)
        registrarPed = nil
    end
end

local function spawnRegistrar()
    local c = cfg()
    local reg = c.Registrar
    if not reg or reg.enabled == false then return end
    if not canUseSchool() then return end
    if registrarPed and DoesEntityExist(registrarPed) then return end

    local model = reg.model or `a_f_y_business_02`
    lib.requestModel(model, 5000)
    if not HasModelLoaded(model) then return end

    local coords = reg.coords
    registrarPed = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w or 0.0, false, true)
    SetEntityAsMissionEntity(registrarPed, true, true)
    SetPedFleeAttributes(registrarPed, 0, false)
    SetBlockingOfNonTemporaryEvents(registrarPed, true)
    SetEntityInvincible(registrarPed, true)
    FreezeEntityPosition(registrarPed, true)
    if reg.scenario then
        TaskStartScenarioInPlace(registrarPed, reg.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(registrarPed, {
            {
                name = 'uls_registrar',
                icon = reg.targetIcon or 'fa-solid fa-graduation-cap',
                label = reg.targetLabel or 'Talk to Registrar',
                distance = reg.targetDistance or 2.4,
                onSelect = openRegistrar,
            },
        })
    end
end

local function syncRegistrarForRegion()
    if canUseSchool() then
        spawnRegistrar()
    else
        deleteRegistrar()
    end
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
    Wait(1500)
    if cfg().Enabled ~= false then
        syncRegistrarForRegion()
    end
end)

AddEventHandler('cfx-keydi-serverlocations:changed', function()
    Wait(200)
    syncRegistrarForRegion()
end)

RegisterNUICallback('cfx-keydi-university:registrar:close', function(_, cb)
    closeRegistrar()
    cb({ ok = true })
end)

RegisterNUICallback('cfx-keydi-university:registrar:apply', function(data, cb)
    local result = lib.callback.await('cfx-keydi-university:registrar:apply', false, data or {})
    cb(result or { ok = false })
end)

RegisterNUICallback('cfx-keydi-university:registrar:cancel', function(_, cb)
    local result = lib.callback.await('cfx-keydi-university:registrar:cancel', false)
    cb(result or { ok = false })
end)

-- iPad portal bridges
RegisterNUICallback('cfx-keydi-university:portal:pending', function(_, cb)
    local result = lib.callback.await('cfx-keydi-university:portal:pending', false)
    cb(result or { ok = false, rows = {} })
end)

RegisterNUICallback('cfx-keydi-university:portal:review', function(data, cb)
    local result = lib.callback.await('cfx-keydi-university:portal:review', false, data or {})
    cb(result or { ok = false })
end)

RegisterNUICallback('cfx-keydi-university:portal:myApplication', function(_, cb)
    local result = lib.callback.await('cfx-keydi-university:portal:myApplication', false)
    cb(result or { ok = false })
end)

RegisterNetEvent('cfx-keydi-university:client:enrollmentUpdated', function()
    -- Session refresh happens next iPad open; optional soft notify already server-side
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeRegistrar()
    if registrarPed and DoesEntityExist(registrarPed) then
        if GetResourceState('ox_target') == 'started' then
            pcall(function()
                exports.ox_target:removeLocalEntity(registrarPed)
            end)
        end
        DeleteEntity(registrarPed)
    end
    registrarPed = nil
end)

exports('OpenRegistrar', openRegistrar)
exports('CloseRegistrar', closeRegistrar)
