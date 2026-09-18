local Vars = require 'helpers.vars'
local menu = require 'shared.menu'
local helpers = require 'helpers.client'

local Revive = {}

local function getItemLabel(name)
    if Vars.oxItems and Vars.oxItems[name] and Vars.oxItems[name].label then
        return Vars.oxItems[name].label
    end
    local ok, item = pcall(function() return exports.ox_inventory:Items(name) end)
    if ok and item and item.label then return item.label end
    return (name == 'ems_medikit' and 'EMS Medikit') or 'Medikit'
end

local function GetAvailableReviveKit(isCivilian)
    local emsItem = (menu.revive.require and menu.revive.require.item) or 'ems_medikit'
    local emsAmount = (menu.revive.require and menu.revive.require.amount) or 1
    local civItem = (menu.revive.civilian and menu.revive.civilian.item) or 'medikit'
    local civAmount = (menu.revive.civilian and menu.revive.civilian.amount) or 1

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

Revive.Target = function(targetId, civilian)
    if Vars.isBusy then
        return ESX.Notify('AMBULANCE', 'You are already busy.', 'error', 4000)
    end

    lib.requestAnimDict(Vars.ReviveAnim.cpr_a_1, 10000)
    lib.requestAnimDict(Vars.ReviveAnim.cpr_a_2, 10000)
    lib.requestAnimDict(Vars.ReviveAnim.cpr_b_1, 10000)
    lib.requestAnimDict(Vars.ReviveAnim.cpr_b_2, 10000)
    local ped = cache.ped
    if not targetId or targetId <= 0 then
        local playerId = lib.getClosestPlayer(GetEntityCoords(ped), 3.0, false)
        if not playerId then
            return ESX.Notify('AMBULANCE', 'No nearby player.', 'error', 5000)
        end
        targetId = GetPlayerServerId(playerId)
    end

    local itemName, itemAmount, itemLabel = GetAvailableReviveKit(civilian)
    if not itemName then
        return ESX.Notify('AMBULANCE', ('You must have %sx %s'):format(itemAmount, itemLabel), 'error', 5000)
    end

    if not Player(targetId).state.dead then
        return ESX.Notify('AMBULANCE', 'The player is not dead.', 'error', 5000)
    end

    exports.ox_target:disableTargeting(true)
    Vars.isBusy = true
    TriggerEvent('ox_inventory:disarm')
    TriggerServerEvent('cfx-keydi-ambulance:playCPR', targetId, GetEntityForwardVector(ped))
    local cpr = true
	CreateThread(function()
		while cpr do
			Wait(0)
			EnableControlAction(0, 1, true)
		end
	end)
	ClampGameplayCamPitch(0.0, -90.0)
	TaskPlayAnim(ped, Vars.ReviveAnim.cpr_a_1, Vars.ReviveAnim.start, 8.0, 8.0, -1, 0, 0, false, false, false)
	Wait(15800 - 900)
	for i=1, 15, 1 do
		Wait(900)
		TaskPlayAnim(ped, Vars.ReviveAnim.cpr_a_2, Vars.ReviveAnim.pump, 8.0, 8.0, -1, 0, 0, false, false, false)
	end
	cpr = false
	TaskPlayAnim(ped, Vars.ReviveAnim.cpr_a_2, Vars.ReviveAnim.success, 8.0, 8.0, -1, 0, 0, false, false, false)
	Wait(3590)
    ClampGameplayCamPitch(-90.0, 90.0)
    ClearPedTasksImmediately(ped)
    TriggerServerEvent('cfx-keydi-ambulance:reviveTarget', targetId)
    Vars.isBusy = false
    exports.ox_target:disableTargeting(false)
end

RegisterNetEvent('cfx-keydi-ambulance:syncCPR', function(playerheading, playercoords, playerlocation)
    if source ~= 65535 then return end
    lib.requestAnimDict(Vars.ReviveAnim.cpr_a_1, 10000)
    lib.requestAnimDict(Vars.ReviveAnim.cpr_a_2, 10000)
    lib.requestAnimDict(Vars.ReviveAnim.cpr_b_1, 10000)
    lib.requestAnimDict(Vars.ReviveAnim.cpr_b_2, 10000)
	local ped = cache.ped
    local cpr = true
    CreateThread(function()
        while cpr do
            Wait(0)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
        end
    end)
    ClampGameplayCamPitch(0.0, -90.0)

    -- Place on medic XY + forward (ignore forward Z — looking down pushed victims under the map)
    local mx = playercoords.x or playercoords[1]
    local my = playercoords.y or playercoords[2]
    local mz = playercoords.z or playercoords[3]
    local fx = (playerlocation and (playerlocation.x or playerlocation[1])) or 0.0
    local fy = (playerlocation and (playerlocation.y or playerlocation[2])) or 0.0
    local x = mx + fx
    local y = my + fy
    local z = mz

    RequestCollisionAtCoord(x, y, z)
    x, y, z = helpers.SafeReviveCoords(x, y, z, ped)

    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    NetworkResurrectLocalPlayer(x, y, z, playerheading, true, false)
    Wait(50)
    ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, playerheading - 270.0)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, true)

    TaskPlayAnim(ped, Vars.ReviveAnim.cpr_b_1, Vars.ReviveAnim.start, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(15800 - 900)
    for i=1, 15, 1 do
        Wait(900)
        TaskPlayAnim(ped, Vars.ReviveAnim.cpr_b_2, Vars.ReviveAnim.pump, 8.0, 8.0, -1, 0, 0, false, false, false)
    end
    cpr = false
    TaskPlayAnim(ped, Vars.ReviveAnim.cpr_b_2, Vars.ReviveAnim.success, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(3590)
    -- Always reset camera / controls after CPR victim sequence
    cpr = false
    ClampGameplayCamPitch(-90.0, 90.0)
    ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    -- Stay frozen until revive RespawnPed — prevents falling under map in the gap
    FreezeEntityPosition(ped, true)

    -- Safety: if revive never arrives after 35 seconds, snap to ground and unfreeze
    CreateThread(function()
        Wait(35000)
        if Vars.isDead then
            local p = PlayerPedId()
            local c = GetEntityCoords(p)
            local sx, sy, sz = helpers.SafeReviveCoords(c.x, c.y, c.z, p)
            SetEntityCoordsNoOffset(p, sx, sy, sz, false, false, false)
            FreezeEntityPosition(p, false)
        end
    end)
end)

return Revive