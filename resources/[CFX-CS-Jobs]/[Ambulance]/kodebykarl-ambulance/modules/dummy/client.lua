--[[
  EMS practice dummy — spawns a downed ped you can ox_target.

  /emsdummy           spawn downed dummy in front of you
  /emsdummy alive     spawn injured (alive) dummy
  /emsdummy close     despawn
]]

local Vars = require 'helpers.vars'

local MODEL = `s_m_m_paramedic_01`
local DEATH_DICT = 'dead'
local DEATH_ANIM = 'dead_a'

local dummyPed = 0
local dummyDead = true

local function clearFocus()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

local function removeTarget()
    if dummyPed ~= 0 and DoesEntityExist(dummyPed) and GetResourceState('ox_target') == 'started' then
        pcall(function()
            exports.ox_target:removeLocalEntity(dummyPed)
        end)
    end
end

local function despawn(silent)
    removeTarget()
    if dummyPed ~= 0 and DoesEntityExist(dummyPed) then
        DeleteEntity(dummyPed)
    end
    dummyPed = 0
    dummyDead = true
    clearFocus()
    if not silent then
        lib.notify({
            title = 'EMS Dummy',
            description = 'Dummy despawned.',
            type = 'inform',
        })
    end
end

local function applyDownedPose(ped)
    lib.requestAnimDict(DEATH_DICT, 5000)
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, 0)
    -- Keep as "dead looking" but usable — SetEntityHealth 0 can delete some peds; use low HP + anim instead
    SetEntityHealth(ped, 101)
    SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
    Wait(200)
    ClearPedTasksImmediately(ped)
    TaskPlayAnim(ped, DEATH_DICT, DEATH_ANIM, 8.0, 8.0, -1, 1, 0.0, false, false, false)
    FreezeEntityPosition(ped, true)
end

local function applyAliveInjured(ped)
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityHealth(ped, 140)
    SetPedArmour(ped, 0)
    TaskStandStill(ped, -1)
    FreezeEntityPosition(ped, true)
end

local function buildDummyVitals()
    local coords = GetEntityCoords(dummyPed)
    if dummyDead then
        return {
            name = 'EMS Dummy Patient',
            sid = 0,
            dead = true,
            status = 'DECEASED',
            hr = 22,
            hrStatus = 'Agonal',
            rhythm = 'Agonal / PEA',
            bpSys = 0,
            bpDia = 0,
            bpStatus = 'No pressure',
            spo2 = 0,
            spo2Status = 'No waveform',
            rr = 0,
            rrStatus = 'Apnea',
            temp = 35.2,
            blood = 28,
            bloodStatus = 'Critical',
            bleeding = 'Significant bleeding',
            bleedLevel = 2,
            consciousness = 'Unresponsive',
            gcs = 3,
            injuries = {
                { id = 'UPPER_BODY', label = 'Torso', severity = 3, wound = 'Gunshot' },
                { id = 'LARM', label = 'Left Arm', severity = 2, wound = 'Laceration' },
            },
            area = 'Torso',
            armor = 0,
            health = 0,
            coords = coords,
            duration = 12,
        }
    end

    return {
        name = 'EMS Dummy Patient',
        sid = 0,
        dead = false,
        status = 'UNSTABLE',
        hr = 118,
        hrStatus = 'High',
        rhythm = 'Sinus tachycardia',
        bpSys = 96,
        bpDia = 58,
        bpStatus = 'Hypotension',
        spo2 = 91,
        spo2Status = 'Low',
        rr = 24,
        rrStatus = 'Tachypnea',
        temp = 36.1,
        blood = 62,
        bloodStatus = 'Low',
        bleeding = 'Minor bleeding',
        bleedLevel = 1,
        consciousness = 'Voice',
        gcs = 12,
        injuries = {
            { id = 'RLEG', label = 'Right Leg', severity = 2, wound = 'Fracture' },
            { id = 'UPPER_BODY', label = 'Torso', severity = 1, wound = 'Bruise' },
        },
        area = 'Right Leg',
        armor = 0,
        health = 42,
        coords = coords,
        duration = 12,
    }
end

local function showVitalsUi(result)
    SendNUIMessage({
        type = 'ShowVitals',
        name = result.name,
        sid = result.sid,
        dead = result.dead,
        status = result.status,
        hr = result.hr,
        hrStatus = result.hrStatus,
        rhythm = result.rhythm,
        bpSys = result.bpSys,
        bpDia = result.bpDia,
        bpStatus = result.bpStatus,
        spo2 = result.spo2,
        spo2Status = result.spo2Status,
        rr = result.rr,
        rrStatus = result.rrStatus,
        temp = result.temp,
        blood = result.blood,
        bloodStatus = result.bloodStatus,
        bleeding = result.bleeding,
        bleedLevel = result.bleedLevel,
        consciousness = result.consciousness,
        gcs = result.gcs,
        injuries = result.injuries,
        area = result.area,
        armor = result.armor,
        health = result.health,
        duration = result.duration or 12,
    })
    CreateThread(function()
        Wait((result.duration or 12) * 1000)
        SendNUIMessage({ type = 'HideVitals' })
    end)
end

local function dummyVitals()
    if Vars.isBusy then
        return ESX.Notify('AMBULANCE', 'You are already busy.', 'error', 4000)
    end
    if dummyPed == 0 or not DoesEntityExist(dummyPed) then
        return ESX.Notify('EMS Dummy', 'No dummy spawned.', 'error', 3000)
    end

    Vars.isBusy = true
    local ok = lib.progressBar({
        duration = 3000,
        label = 'Checking vital signs (dummy)',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD' },
    })
    Vars.isBusy = false
    if not ok then
        return ESX.Notify('AMBULANCE', 'You cancelled.', 'error', 3000)
    end

    showVitalsUi(buildDummyVitals())
    ESX.Notify('EMS Dummy', 'Vitals monitor open (practice only).', 'success', 4000)
end

local function dummyRevive()
    if Vars.isBusy then
        return ESX.Notify('AMBULANCE', 'You are already busy.', 'error', 4000)
    end
    if dummyPed == 0 or not DoesEntityExist(dummyPed) then
        return ESX.Notify('EMS Dummy', 'No dummy spawned.', 'error', 3000)
    end
    if not dummyDead then
        return ESX.Notify('EMS Dummy', 'Dummy is already alive.', 'error', 3000)
    end

    Vars.isBusy = true
    local ok = lib.progressBar({
        duration = 8000,
        label = 'Reviving dummy patient',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = {
            dict = Vars.ReviveAnim and Vars.ReviveAnim.cpr_a_2 or 'mini@cpr@char_a@cpr_str',
            clip = Vars.ReviveAnim and Vars.ReviveAnim.pump or 'cpr_pumpchest',
        },
    })
    Vars.isBusy = false
    if not ok then
        return ESX.Notify('AMBULANCE', 'You cancelled.', 'error', 3000)
    end

    if not DoesEntityExist(dummyPed) then return end
    dummyDead = false
    applyAliveInjured(dummyPed)
    ESX.Notify('EMS Dummy', 'Dummy revived (practice).', 'success', 4000)
end

local function dummyHeal()
    if Vars.isBusy then
        return ESX.Notify('AMBULANCE', 'You are already busy.', 'error', 4000)
    end
    if dummyPed == 0 or not DoesEntityExist(dummyPed) then
        return ESX.Notify('EMS Dummy', 'No dummy spawned.', 'error', 3000)
    end
    if dummyDead then
        return ESX.Notify('EMS Dummy', 'Revive first — patient is down.', 'error', 3000)
    end

    Vars.isBusy = true
    local ok = lib.progressBar({
        duration = 5000,
        label = 'Healing dummy patient',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD' },
    })
    Vars.isBusy = false
    if not ok then
        return ESX.Notify('AMBULANCE', 'You cancelled.', 'error', 3000)
    end

    if not DoesEntityExist(dummyPed) then return end
    SetEntityHealth(dummyPed, GetEntityMaxHealth(dummyPed))
    ESX.Notify('EMS Dummy', 'Dummy healed (practice).', 'success', 4000)
end

local function dummyBodybag()
    if Vars.isBusy then
        return ESX.Notify('AMBULANCE', 'You are already busy.', 'error', 4000)
    end
    if dummyPed == 0 or not DoesEntityExist(dummyPed) then
        return ESX.Notify('EMS Dummy', 'No dummy spawned.', 'error', 3000)
    end
    if not dummyDead then
        return ESX.Notify('EMS Dummy', 'Only downed dummies can be bagged.', 'error', 3000)
    end

    Vars.isBusy = true
    local ok = lib.progressBar({
        duration = 4000,
        label = 'Bodybagging dummy',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search' },
    })
    Vars.isBusy = false
    if not ok then
        return ESX.Notify('AMBULANCE', 'You cancelled.', 'error', 3000)
    end

    despawn(true)
    ESX.Notify('EMS Dummy', 'Dummy bodybagged / removed.', 'success', 4000)
end

local function attachTargets(ped)
    if GetResourceState('ox_target') ~= 'started' then
        lib.notify({
            title = 'EMS Dummy',
            description = 'ox_target not started — use /emsdummy vitals|revive|heal|bag',
            type = 'warning',
            duration = 6000,
        })
        return
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'ems_dummy_vitals',
            icon = 'fa-solid fa-heart-pulse',
            label = 'Check Vital Signs (Dummy)',
            distance = 2.5,
            canInteract = function()
                return not Vars.isBusy and dummyPed ~= 0
            end,
            onSelect = dummyVitals,
        },
        {
            name = 'ems_dummy_revive',
            icon = 'fa-solid fa-kit-medical',
            label = 'Revive (Dummy)',
            distance = 2.5,
            canInteract = function()
                return not Vars.isBusy and dummyDead and dummyPed ~= 0
            end,
            onSelect = dummyRevive,
        },
        {
            name = 'ems_dummy_heal',
            icon = 'fa-solid fa-hand-holding-medical',
            label = 'Heal (Dummy)',
            distance = 2.5,
            canInteract = function()
                return not Vars.isBusy and not dummyDead and dummyPed ~= 0
            end,
            onSelect = dummyHeal,
        },
        {
            name = 'ems_dummy_bodybag',
            icon = 'fa-solid fa-skull',
            label = 'Bodybag (Dummy)',
            distance = 2.5,
            canInteract = function()
                return not Vars.isBusy and dummyDead and dummyPed ~= 0
            end,
            onSelect = dummyBodybag,
        },
        {
            name = 'ems_dummy_despawn',
            icon = 'fa-solid fa-trash',
            label = 'Despawn Dummy',
            distance = 2.5,
            onSelect = function()
                despawn()
            end,
        },
    })
end

local function spawnDummy(alive)
    if Vars.isDead then
        return lib.notify({
            title = 'EMS Dummy',
            description = 'Cannot spawn while you are dead.',
            type = 'error',
        })
    end

    despawn(true)

    local playerPed = cache.ped
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.8, 0.0)
    local heading = GetEntityHeading(playerPed)

    lib.requestModel(MODEL, 5000)
    local ped = CreatePed(4, MODEL, coords.x, coords.y, coords.z, heading, false, true)
    if not ped or ped == 0 then
        return lib.notify({
            title = 'EMS Dummy',
            description = 'Failed to create ped.',
            type = 'error',
        })
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCanRagdoll(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanBeTargetted(ped, true)
    SetPedDiesWhenInjured(ped, false)

    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
    if found and groundZ then
        SetEntityCoords(ped, coords.x, coords.y, groundZ, false, false, false, false)
    end

    dummyPed = ped
    dummyDead = not alive

    if alive then
        applyAliveInjured(ped)
    else
        applyDownedPose(ped)
    end

    -- Keep death anim stuck while downed
    CreateThread(function()
        local pedRef = ped
        while dummyPed == pedRef and DoesEntityExist(pedRef) do
            if dummyDead then
                if not IsEntityPlayingAnim(pedRef, DEATH_DICT, DEATH_ANIM, 3) then
                    TaskPlayAnim(pedRef, DEATH_DICT, DEATH_ANIM, 8.0, 8.0, -1, 1, 0.0, false, false, false)
                end
            end
            Wait(1000)
        end
    end)

    attachTargets(ped)

    lib.notify({
        title = 'EMS Dummy',
        description = alive
            and 'Alive/injured dummy ready — ox_target: vitals / heal'
            or 'Downed dummy ready — ox_target: vitals / revive / bodybag',
        type = 'success',
        duration = 7000,
    })
end

RegisterCommand('emsdummy', function(_, args)
    local a1 = args[1] and string.lower(args[1]) or nil

    if a1 == 'close' or a1 == 'off' or a1 == 'stop' or a1 == 'despawn' then
        despawn()
        return
    end

    if a1 == 'vitals' then
        dummyVitals()
        return
    end
    if a1 == 'revive' then
        dummyRevive()
        return
    end
    if a1 == 'heal' then
        dummyHeal()
        return
    end
    if a1 == 'bag' or a1 == 'bodybag' then
        dummyBodybag()
        return
    end

    if a1 == 'alive' or a1 == 'injured' then
        spawnDummy(true)
        return
    end

    spawnDummy(false)
end, false)

CreateThread(function()
    Wait(500)
    TriggerEvent('chat:addSuggestion', '/emsdummy', 'Spawn EMS practice dummy ped', {
        { name = 'option', help = 'close | alive | vitals | revive | heal | bag' },
    })
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearFocus()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    despawn(true)
end)
