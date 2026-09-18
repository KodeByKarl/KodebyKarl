local Vars = require 'helpers.vars'
local menu = require 'shared.menu'
local Heal = {}

local function getItemLabel(name)
    if Vars.oxItems and Vars.oxItems[name] and Vars.oxItems[name].label then
        return Vars.oxItems[name].label
    end
    local ok, item = pcall(function() return exports.ox_inventory:Items(name) end)
    if ok and item and item.label then return item.label end
    return (name == 'ems_medikit' and 'EMS Medikit') or 'Medikit'
end

local function GetAvailableHealKit(isCivilian)
    local emsItem = (menu.heal.require and menu.heal.require.item) or 'ems_medikit'
    local emsAmount = (menu.heal.require and menu.heal.require.amount) or 1
    local civItem = (menu.heal.civilian and menu.heal.civilian.item) or 'medikit'
    local civAmount = (menu.heal.civilian and menu.heal.civilian.amount) or 1

    if not isCivilian then
        local count = Vars.ox:Search('count', emsItem) or 0
        if count >= emsAmount then
            return emsItem, emsAmount, getItemLabel(emsItem)
        end
    end

    local count = Vars.ox:Search('count', civItem) or 0
    if count >= civAmount then
        return civItem, civAmount, getItemLabel(civItem)
    end

    if not isCivilian then
        return nil, emsAmount, getItemLabel(emsItem)
    end
    return nil, civAmount, getItemLabel(civItem)
end

Heal.Target = function(targetId, civilian)
    if Vars.isBusy then
        return ESX.Notify('AMBULANCE', 'You are already busy.', 'error', 4000)
    end

    local ped = cache.ped
    if not targetId or targetId <= 0 then
        local player = lib.getClosestPlayer(GetEntityCoords(ped), 3.0, false)
        if not player then
            return ESX.Notify('AMBULANCE', 'No nearby player.', 'error', 5000)
        end
        targetId = GetPlayerServerId(player)
    end

    if Player(targetId).state.dead then
        return ESX.Notify('AMBULANCE', 'That player is unconscious. Revive them first.', 'error', 5000)
    end

    local itemName, itemAmount, itemLabel = GetAvailableHealKit(civilian)
    if not itemName then
        return ESX.Notify('AMBULANCE', ('You must have %sx %s'):format(itemAmount, itemLabel), 'error', 5000)
    end

    Vars.isBusy = true
    local status = lib.progressBar({
        duration = 8000,
        label = 'Healing . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer',
            flag = 1
        }
    })
    Vars.isBusy = false
    if not status then
        return ESX.Notify('AMBULANCE', 'You cancelled.', 'error', 5000)
    end
    TriggerServerEvent('cfx-keydi-ambulance:healTarget', targetId)
end

local function applyFullHealth()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    SetPedMaxHealth(ped, 200)
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
end

RegisterNetEvent('cfx-keydi-ambulance:syncHeal', function()
    if source ~= 65535 then return end
    applyFullHealth()
    CreateThread(function()
        Wait(0)
        applyFullHealth()
        Wait(250)
        applyFullHealth()
    end)
end)

return Heal
