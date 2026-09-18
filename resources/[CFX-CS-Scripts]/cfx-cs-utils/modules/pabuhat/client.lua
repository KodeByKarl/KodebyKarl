local buhat = require 'configs.buhat'
local Vars = require 'helpers.vars'

local function setBeingCarried(value)
    LocalPlayer.state:set('beingCarried', value and true or false, true)
end

local function attachToCarrier(targetSrc)
    local player = GetPlayerFromServerId(targetSrc)
    if not player or player == -1 then return false end
    local targetPed = GetPlayerPed(player)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then return false end
    local ped = cache.ped
    if not ped or ped == 0 then return false end

    AttachEntityToEntity(
        ped, targetPed, 0,
        buhat.personCarried.attachX, buhat.personCarried.attachY, buhat.personCarried.attachZ,
        0.5, 0.5, 180,
        false, false, false, false, 2, false
    )
    return true
end

local function playCarriedAnim()
    lib.requestAnimDict(buhat.personCarried.animDict, 10000)
    TaskPlayAnim(
        cache.ped,
        buhat.personCarried.animDict,
        buhat.personCarried.anim,
        8.0, -8.0, 100000,
        buhat.personCarried.flag,
        0, false, false, false
    )
end

local function resetLocal()
    Vars.isCarrying = false
    buhat.InProgress = false
    buhat.targetSrc = 0
    buhat.type = ''
    setBeingCarried(false)
    ClearPedSecondaryTask(cache.ped)
    DetachEntity(cache.ped, true, false)
end

local function toggleBuhat()
    if cache.vehicle then return end

    if buhat.InProgress then
        TriggerServerEvent("cfx-keydi-utils:Buhat:Stop")
        resetLocal()
        return
    end

    if Vars.isCarrying then
        return ESX.Notify('BUHAT', 'You are already in a carry.', 'error', 5000)
    end
    if LocalPlayer.state.dead or IsPedDeadOrDying(cache.ped, true) then
        return ESX.Notify('BUHAT', 'You cannot carry while dead.', 'error', 5000)
    end
    if cache.weapon then
        return ESX.Notify('BUHAT', 'You have a gun in your hand.', 'error', 5000)
    end

    local playerId = lib.getClosestPlayer(GetEntityCoords(cache.ped), 2.5, false)
    if not playerId then
        return ESX.Notify('BUHAT', 'No nearby player.', 'error', 5000)
    end

    local targetSrc = GetPlayerServerId(playerId)
    if not targetSrc or targetSrc == -1 then
        return ESX.Notify('BUHAT', 'No nearby player.', 'error', 5000)
    end
    if Player(targetSrc).state.escorted then return end

    Vars.isCarrying = true
    buhat.InProgress = true
    buhat.targetSrc = targetSrc
    buhat.type = "carrying"
    TriggerServerEvent("cfx-keydi-utils:Buhat:Sync", targetSrc)
end

RegisterCommand("buhat", toggleBuhat, false)
RegisterCommand("buhatkita", toggleBuhat, false)

RegisterNetEvent("cfx-keydi-utils:Buhat:syncTarget", function(targetSrc)
    Vars.isCarrying = true
    buhat.InProgress = true
    buhat.targetSrc = targetSrc
    buhat.type = "beingcarried"
    setBeingCarried(true)

    CreateThread(function()
        local timeout = GetGameTimer() + 3000
        while GetGameTimer() < timeout do
            if attachToCarrier(targetSrc) then
                playCarriedAnim()
                return
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent("cfx-keydi-utils:Buhat:Stop", function()
    resetLocal()
end)

-- CFX: only the carried player loops anim. Carrier walks normally with target attached.
CreateThread(function()
    while true do
        local sleep = 500
        if buhat.InProgress then
            sleep = 0
            if buhat.type == "carrying" and (LocalPlayer.state.dead or IsPedDeadOrDying(cache.ped, true)) then
                TriggerServerEvent("cfx-keydi-utils:Buhat:Stop")
                resetLocal()
            elseif buhat.type == "beingcarried" then
                attachToCarrier(buhat.targetSrc)
                if not IsEntityPlayingAnim(cache.ped, buhat.personCarried.animDict, buhat.personCarried.anim, 3) then
                    playCarriedAnim()
                end
            end
        end
        Wait(sleep)
    end
end)
