local Vars = require 'helpers.vars'
local client = require 'helpers.client'
local config = require 'shared.config'
local Bodybag = {}
local entity = 0
local attached = false

local function resolveTargetId(targetId)
    if targetId and targetId > 0 then
        return targetId
    end
    local playerId = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)
    if not playerId then return nil end
    return GetPlayerServerId(playerId)
end

local function bodybagRespawnCoords()
    local bag = config.Bodybag or {}
    local c = bag.respawn
    if not c then return nil end
    return {
        x = c.x + 0.0,
        y = c.y + 0.0,
        z = c.z + 0.0,
        w = (c.w or c.heading or 0.0) + 0.0,
    }
end

Bodybag.Target = function(targetId)
    if Vars.isBusy then
        return ESX.Notify('AMBULANCE', 'You are already busy.', 'error', 4000)
    end

    targetId = resolveTargetId(targetId)
    if not targetId then
        return ESX.Notify('AMBULANCE', 'No nearby player.', 'error', 5000)
    end
    if not Player(targetId).state.dead then
        return ESX.Notify('AMBULANCE', 'The player is not dead.', 'error', 5000)
    end

    Vars.isBusy = true
    local status = lib.progressBar({
        duration = 4000,
        label = 'Placing bodybag',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'anim@gangops@facility@servers@bodysearch@',
            clip = 'player_search',
            flag = 49,
        }
    })
    Vars.isBusy = false
    if not status then
        return ESX.Notify('AMBULANCE', 'You cancelled.', 'error', 5000)
    end
    if not Player(targetId).state.dead then
        return ESX.Notify('AMBULANCE', 'The player is no longer deceased.', 'error', 5000)
    end
    TriggerServerEvent('cfx-keydi-ambulance:bodybagTarget', targetId)
end

RegisterNetEvent('cfx-keydi-ambulance:syncBodyBag', function()
    if source ~= 65535 then return end
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    if Vars.isDead and not attached then
        SetEntityVisible(ped, false, false)
        lib.requestModel('xm_prop_body_bag', 10000)
        entity = CreateObject(`xm_prop_body_bag`, playerCoords.x, playerCoords.y, playerCoords.z, true, true, true)
        AttachEntityToEntity(entity, ped, 0, -0.2, 0.75, -0.2, 0.0, 0.0, 0.0, false, false, false, false, 20, false)
        attached = true
        Wait(10000)
        client.RemoveRPDeath(bodybagRespawnCoords())
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = cache.ped
        local sleep = true
        if not Vars.isDead and attached then
            sleep = false
            DetachEntity(playerPed, true, false)
            SetEntityVisible(playerPed, true, true)
            SetEntityAsMissionEntity(entity, false, false)
            SetEntityVisible(entity, false)
            SetModelAsNoLongerNeeded(entity)
            DeleteObject(entity)
            DeleteEntity(entity)
            entity = 0
            attached = false
        end
        if sleep then
            Wait(500)
        end
        Wait(1000)
    end
end)

return Bodybag
