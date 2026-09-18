local menu = require 'shared.menu'
local Vars = require 'helpers.vars'
local helpers = require 'helpers.game'
local Vitals = {}

local VITALS_DISPLAY_SEC = 12

local function resolveTargetId(targetId)
    if targetId and targetId > 0 then
        return targetId
    end
    local playerId = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)
    if not playerId then return nil end
    return GetPlayerServerId(playerId)
end

local function collectInjuries()
    local list = {}
    if type(BodyParts) ~= 'table' then return list end
    for key, part in pairs(BodyParts) do
        if part.isDamaged then
            local sev = math.max(1, math.min(4, tonumber(part.severity) or 1))
            list[#list + 1] = {
                id = key,
                label = part.label,
                severity = sev,
                wound = (Config.WoundStates and Config.WoundStates[sev]) or 'Injured',
            }
        end
    end
    table.sort(list, function(a, b)
        return (a.severity or 0) > (b.severity or 0)
    end)
    return list
end

local function primaryArea(injuries)
    if injuries[1] and injuries[1].label then
        return injuries[1].label
    end
    if Vars.Status.area and Vars.Status.area ~= 'NONE' then
        return Vars.Status.area
    end
    return 'None'
end

local function bleedLabel(level)
    level = tonumber(level) or 0
    if level <= 0 then return 'None', 0 end
    if Config.BleedingStates and Config.BleedingStates[level] then
        return Config.BleedingStates[level], level
    end
    local mapped = Vars.bleedingData[level]
    if mapped == 'NONE' then return 'None', 0 end
    if mapped == 'SLOW' then return 'Minor bleeding', 1 end
    if mapped == 'MEDIUM' then return 'Significant bleeding', 2 end
    if mapped == 'FAST' then return 'Major bleeding', 3 end
    return 'Present', level
end

local function round1(n)
    return math.floor((n * 10) + 0.5) / 10
end

local function computeMonitor(dead, hpPct, blood, bleedLevel, injuries, armor, hasHead)
    blood = math.max(0, math.min(100, tonumber(blood) or 0))
    hpPct = math.max(0, math.min(100, tonumber(hpPct) or 0))
    bleedLevel = tonumber(bleedLevel) or 0
    armor = math.floor(tonumber(armor) or 0)

    if dead then
        local agonal = blood > 20 and not hasHead and (tonumber(Vars.Status.multiplier) or 1) > 0
        local hr = agonal and (18 + math.random(0, 16)) or 0
        return {
            dead = true,
            status = 'DECEASED',
            hr = hr,
            hrStatus = hr > 0 and 'Agonal' or 'Asystole',
            rhythm = hr > 0 and 'Agonal / PEA' or 'Asystole',
            bpSys = 0,
            bpDia = 0,
            bpStatus = 'No pressure',
            spo2 = 0,
            spo2Status = 'No waveform',
            rr = 0,
            rrStatus = 'Apnea',
            temp = round1(35.0 + math.random() * 0.4),
            blood = ESX.Math.Round(blood),
            bloodStatus = blood < 20 and 'Exsanguinated' or 'Critical',
            consciousness = 'Unresponsive',
            gcs = 3,
            armor = armor,
            health = ESX.Math.Round(hpPct),
        }
    end

    local hr
    if bleedLevel >= 3 or blood < 35 or hpPct < 25 then
        if math.random(100) <= 35 then
            hr = 44 + math.random(0, 14)
        else
            hr = 126 + math.random(0, 26)
        end
    elseif bleedLevel > 0 or hpPct < 50 then
        hr = 96 + math.random(0, 22)
    elseif hpPct < 80 then
        hr = 80 + math.random(0, 16)
    else
        hr = 62 + math.random(0, 16)
    end
    if hasHead then
        hr = math.max(46, hr - math.random(10, 24))
    end

    local sys = math.floor(74 + (blood * 0.48) + (hpPct * 0.08))
    if bleedLevel >= 2 then sys = sys - 14 end
    if hr > 120 then sys = sys - 8 end
    sys = math.max(68, math.min(136, sys))
    local dia = math.floor(sys * 0.64)

    local spo2 = math.floor(89 + (blood / 100) * 10)
    if bleedLevel >= 2 then spo2 = spo2 - 5 end
    if hasHead then spo2 = spo2 - 2 end
    if hpPct < 40 then spo2 = spo2 - 3 end
    spo2 = math.max(78, math.min(99, spo2))

    local rr = 14 + math.random(0, 2)
    if bleedLevel > 0 or hpPct < 60 then
        rr = 18 + bleedLevel * 3 + math.random(0, 3)
    end
    if hasHead then
        rr = 7 + math.random(0, 6)
    end
    if hpPct < 25 then
        rr = 26 + math.random(0, 8)
    end

    local temp = 36.6 + (math.random() * 0.4 - 0.1)
    if bleedLevel > 0 then
        temp = temp - 0.35 - (bleedLevel * 0.12)
    end

    local gcs, consciousness = 15, 'Alert'
    if hpPct < 30 or bleedLevel >= 3 or blood < 35 then
        gcs, consciousness = 8, 'Pain'
    elseif hpPct < 55 or bleedLevel >= 2 then
        gcs, consciousness = 12, 'Voice'
    elseif hpPct < 80 or bleedLevel > 0 then
        gcs, consciousness = 14, 'Alert'
    end

    local rhythm, hrStatus = 'NSR', 'Normal'
    if hr < 50 then
        rhythm, hrStatus = 'Sinus bradycardia', 'Low'
    elseif hr > 100 then
        rhythm, hrStatus = 'Sinus tachycardia', 'High'
    end

    local bpStatus = 'Normal'
    if sys < 90 then bpStatus = 'Hypotension'
    elseif sys > 130 then bpStatus = 'Elevated' end

    local spo2Status = 'Normal'
    if spo2 < 90 then spo2Status = 'Hypoxemia'
    elseif spo2 < 95 then spo2Status = 'Low' end

    local rrStatus = 'Normal'
    if rr < 10 then rrStatus = 'Bradypnea'
    elseif rr > 20 then rrStatus = 'Tachypnea' end

    local bloodStatus = 'Adequate'
    if blood < 40 then bloodStatus = 'Critical'
    elseif blood < 70 then bloodStatus = 'Low' end

    local status = 'STABLE'
    if hpPct < 35 or blood < 40 or bleedLevel >= 3 then
        status = 'CRITICAL'
    elseif hpPct < 70 or bleedLevel > 0 then
        status = 'UNSTABLE'
    end

    return {
        dead = false,
        status = status,
        hr = ESX.Math.Round(hr),
        hrStatus = hrStatus,
        rhythm = rhythm,
        bpSys = sys,
        bpDia = dia,
        bpStatus = bpStatus,
        spo2 = spo2,
        spo2Status = spo2Status,
        rr = rr,
        rrStatus = rrStatus,
        temp = round1(temp),
        blood = ESX.Math.Round(blood),
        bloodStatus = bloodStatus,
        consciousness = consciousness,
        gcs = gcs,
        armor = armor,
        health = ESX.Math.Round(hpPct),
    }
end

Vitals.Target = function(targetId)
    if Vars.isBusy then
        return ESX.Notify('AMBULANCE', 'You are already busy.', 'error', 4000)
    end

    targetId = resolveTargetId(targetId)
    if not targetId then
        return ESX.Notify('AMBULANCE', 'No nearby player.', 'error', 5000)
    end

    Vars.isBusy = true
    local status = lib.progressBar({
        duration = 3000,
        label = 'Checking vital signs',
        useWhileDead = false,
        allowRagdoll = false,
        allowCuffed = false,
        allowFalling = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD'
        }
    })
    Vars.isBusy = false
    if not status then
        return ESX.Notify('AMBULANCE', 'You cancelled.', 'error', 5000)
    end
    TriggerServerEvent('cfx-keydi-ambulance:VitalsTarget', targetId)
end

ESX.RegisterClientCallback('cfx-keydi-ambulance:requestTargetVitals', function(cb)
    local ped = cache.ped
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    if not maxHealth or maxHealth < 100 then maxHealth = 200 end
    local armor = GetPedArmour(ped)
    local dead = Vars.isDead == true or IsPedFatallyInjured(ped) or IsEntityDead(ped)

    local hpPct = 0
    if maxHealth > 100 then
        hpPct = math.max(0, math.min(100, ((health - 100) / (maxHealth - 100)) * 100))
    else
        hpPct = math.max(0, math.min(100, (health / maxHealth) * 100))
    end

    local injuries = collectInjuries()
    local hasHead = false
    for i = 1, #injuries do
        local label = injuries[i].label
        if label == 'Head' or label == 'Neck' then
            hasHead = true
            break
        end
    end
    if Vars.Status.area == 'HEAD' then
        hasHead = true
    end

    local bleedLevel = tonumber(isBleeding) or tonumber(Vars.Status.bleeding) or 0
    local blood = hpPct
    if dead then
        blood = tonumber(Vars.Status.blood) or 0
        bleedLevel = tonumber(Vars.Status.bleeding) or bleedLevel
    else
        if Vars.Status.blood and Vars.Status.blood < blood and bleedLevel > 0 then
            blood = Vars.Status.blood
        end
        if bleedLevel > 0 then
            blood = math.max(0, blood - (bleedLevel * 8))
        end
    end

    local bleedText = bleedLabel(bleedLevel)
    local monitor = computeMonitor(dead, hpPct, blood, bleedLevel, injuries, armor, hasHead)
    monitor.bleeding = bleedText
    monitor.bleedLevel = bleedLevel
    monitor.injuries = injuries
    monitor.area = primaryArea(injuries)
    monitor.coords = GetEntityCoords(ped)
    monitor.pulse = monitor.hr
    cb(monitor)
end)

RegisterNetEvent('cfx-keydi-ambulance:showResult', function(result, targetName, targetSid)
    if source ~= 65535 then return end
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    local targetCoords = result and result.coords
    if not targetCoords or #(targetCoords - playerCoords) >= 10 then
        SendNUIMessage({ type = 'HideVitals' })
        ESX.Notify('AMBULANCE', 'Patient is too far to read vitals.', 'error', 4000)
        return
    end

    result.name = targetName or 'Unknown'
    result.sid = tonumber(targetSid) or 0
    result.duration = VITALS_DISPLAY_SEC
    SendNUIMessage({
        type = 'ShowVitals',
        name = result.name,
        sid = result.sid,
        dead = result.dead,
        status = result.status,
        hr = result.hr or result.pulse,
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
        duration = VITALS_DISPLAY_SEC,
    })

    CreateThread(function()
        Wait(VITALS_DISPLAY_SEC * 1000)
        SendNUIMessage({ type = 'HideVitals' })
    end)
end)

CreateThread(function()
    while true do
        Wait(5000)
        if Vars.isDead and Vars.Status.blood > 0 and Vars.Status.bleeding > 0 then
            Vars.Status.blood = Vars.Status.blood - Vars.Status.bleeding
        end
    end
end)

return Vitals
