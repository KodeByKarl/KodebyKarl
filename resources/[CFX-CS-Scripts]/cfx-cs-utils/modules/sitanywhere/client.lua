local config = require 'configs.sitanywhere'
local models = require 'configs.sitanywheremodels'
local helpers = require 'helpers.game'
local Vars = require 'helpers.vars'

if not config.enabled then return end

local sitting = false
local sitEntity = 0
local sitKey = nil
local sitSeat = nil
local getUpBind = nil

local function rotateOffset(offset, heading)
    local rad = math.rad(heading)
    local cosH = math.cos(rad)
    local sinH = math.sin(rad)
    return vec3(
        offset.x * cosH - offset.y * sinH,
        offset.x * sinH + offset.y * cosH,
        offset.z
    )
end

local function makeSeatKey(entity)
    if NetworkGetEntityIsNetworked(entity) then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        if netId and netId ~= 0 then
            return ('net:%s'):format(netId)
        end
    end

    local coords = GetEntityCoords(entity)
    return ('local:%s:%.1f:%.1f:%.1f'):format(
        GetEntityModel(entity),
        coords.x,
        coords.y,
        coords.z
    )
end

local function canSit()
    if sitting then return false end
    if cache.vehicle then return false end
    if LocalPlayer.state.dead or IsPedDeadOrDying(cache.ped, true) then return false end
    if IsPedRagdoll(cache.ped) or IsPedFalling(cache.ped) then return false end
    if Vars.isCarrying then return false end
    return true
end

local function standUp()
    if not sitting then return end

    if sitKey and sitSeat then
        TriggerServerEvent('cfx-keydi-utils:sitanywhere:free', sitKey, sitSeat)
    end

    helpers.hideTextUI()
    if getUpBind then
        getUpBind:disable(true)
    end

    ClearPedTasks(cache.ped)
    sitting = false
    sitEntity = 0
    sitKey = nil
    sitSeat = nil
end

local function playSit(entity, seat, seatKey)
    local hash = GetEntityModel(entity)
    local model = models[hash]
    if not model then return end

    local seatOffset = model.seats[seat]
    if not seatOffset then return end

    local actionData = config.actions[model.action or 'bench']
    if not actionData then return end

    sitting = true
    sitEntity = entity
    sitKey = seatKey
    sitSeat = seat

    local entityCoords = GetEntityCoords(entity)
    local entityHeading = GetEntityHeading(entity)
    local coords = entityCoords + rotateOffset(seatOffset, entityHeading)
    local heading = entityHeading + (seatOffset.w or 180.0)

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, true, false, false, false)
    SetEntityHeading(cache.ped, heading)

    if actionData.type == 'scenario' then
        TaskStartScenarioAtPosition(cache.ped, actionData.scenario, coords.x, coords.y, coords.z, heading, 0, true, true)
    elseif actionData.type == 'anim' then
        lib.requestAnimDict(actionData.dict)
        TaskPlayAnim(cache.ped, actionData.dict, actionData.name, 8.0, -8.0, -1, 1, 0, false, false, false)
        RemoveAnimDict(actionData.dict)
    end

    if not getUpBind then
        getUpBind = lib.addKeybind({
            name = 'cfx-keydi-utils:sitanywhere:getup',
            description = 'Get up from seat',
            defaultKey = config.getUpKey,
            disabled = true,
            onReleased = function()
                standUp()
            end,
        })
    end

    helpers.createTextUI(('[%s] Get Up'):format(config.getUpKey), 'chair', 'bottom-center')
    getUpBind:disable(false)
end

local function trySit(entity)
    if not canSit() then return end
    if not entity or not DoesEntityExist(entity) then return end

    local hash = GetEntityModel(entity)
    if not models[hash] then return end

    if not NetworkGetEntityIsNetworked(entity) then
        NetworkRegisterEntityAsNetworked(entity)
        Wait(80)
    end

    local seatKey = makeSeatKey(entity)
    local seat = lib.callback.await('cfx-keydi-utils:sitanywhere:occupy', false, seatKey, hash)
    if not seat then
        ESX.Notify('SIT', 'That seat is already occupied.', 'error', 4000)
        return
    end

    playSit(entity, seat, seatKey)
end

CreateThread(function()
    local targetModels = {}
    for model in pairs(models) do
        targetModels[#targetModels + 1] = model
    end

    Vars.oxTarget:addModel(targetModels, {
        {
            name = 'cfx-keydi-utils:sitanywhere:sit',
            icon = 'fa-solid fa-chair',
            label = 'Sit',
            distance = config.targetDistance,
            canInteract = function(entity)
                return canSit() and DoesEntityExist(entity)
            end,
            onSelect = function(data)
                trySit(data.entity)
            end,
        },
    })
end)

CreateThread(function()
    while true do
        local sleep = 750
        if sitting then
            sleep = 200
            if LocalPlayer.state.dead or IsPedDeadOrDying(cache.ped, true) or IsPedRagdoll(cache.ped) then
                standUp()
            elseif sitEntity ~= 0 and not DoesEntityExist(sitEntity) then
                standUp()
            elseif cache.vehicle then
                standUp()
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if sitting then
        helpers.hideTextUI()
        ClearPedTasks(cache.ped)
    end
end)
