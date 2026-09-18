-- Injury Client Module for cfx-keydi-ambulance
ESX = exports['es_extended']:getSharedObject()
local Vars = require 'helpers.vars'

-- General
isInHospitalBed = false

-- Hospital
bedOccupying = nil
bedObject = nil
bedOccupyingData = nil
currentTp = nil
usedHiddenRev = false

-- Wound
isBleeding = 0
bleedTickTimer, advanceBleedTimer = 0, 0
fadeOutTimer, blackoutTimer = 0, 0
applyingBleedDamage = false

legCount = 0
armcount = 0
headCount = 0

playerHealth = nil
playerArmour = nil

limbNotifId = 'MHOS_LIMBS'
bleedNotifId = 'MHOS_BLEED'
bleedMoveNotifId = 'MHOS_BLEEDMOVE'

BodyParts = {
    ['HEAD'] = { label = 'Head', causeLimp = false, isDamaged = false, severity = 0 },
    ['NECK'] = { label = 'Neck', causeLimp = false, isDamaged = false, severity = 0 },
    ['SPINE'] = { label = 'Spine', causeLimp = true, isDamaged = false, severity = 0 },
    ['UPPER_BODY'] = { label = 'Upper Body', causeLimp = false, isDamaged = false, severity = 0 },
    ['LOWER_BODY'] = { label = 'Lower Body', causeLimp = true, isDamaged = false, severity = 0 },
    ['LARM'] = { label = 'Left Arm', causeLimp = false, isDamaged = false, severity = 0 },
    ['LHAND'] = { label = 'Left Hand', causeLimp = false, isDamaged = false, severity = 0 },
    ['LFINGER'] = { label = 'Left Hand Fingers', causeLimp = false, isDamaged = false, severity = 0 },
    ['LLEG'] = { label = 'Left Leg', causeLimp = true, isDamaged = false, severity = 0 },
    ['LFOOT'] = { label = 'Left Foot', causeLimp = true, isDamaged = false, severity = 0 },
    ['RARM'] = { label = 'Right Arm', causeLimp = false, isDamaged = false, severity = 0 },
    ['RHAND'] = { label = 'Right Hand', causeLimp = false, isDamaged = false, severity = 0 },
    ['RFINGER'] = { label = 'Right Hand Fingers', causeLimp = false, isDamaged = false, severity = 0 },
    ['RLEG'] = { label = 'Right Leg', causeLimp = true, isDamaged = false, severity = 0 },
    ['RFOOT'] = { label = 'Right Foot', causeLimp = true, isDamaged = false, severity = 0 },
}

injured = {}

-- GetPedLastDamageBone sometimes returns a skeleton index instead of a bone tag (31086).
local boneIndexToTag = {}
local boneIndexPed = 0

local function refreshBoneIndexMap(ped)
    if not ped or ped == 0 then return end
    if boneIndexPed == ped and next(boneIndexToTag) then return end
    boneIndexToTag = {}
    boneIndexPed = ped
    for tag, part in pairs(Config.Bones) do
        if tag ~= 0 and part ~= 'NONE' then
            local idx = GetPedBoneIndex(ped, tag)
            if idx and idx ~= -1 then
                boneIndexToTag[idx] = tag
            end
        end
    end
end

local function resolveDamageBone(ped, bone)
    bone = tonumber(bone)
    if not bone or bone == 0 then return nil end
    -- GetPedLastDamageBone may return a bone INDEX; convert to bone ID first
    if Config.ToBoneId then
        bone = Config.ToBoneId(bone)
    end
    if Config.Bones[bone] then return bone end
    refreshBoneIndexMap(ped)
    local tag = boneIndexToTag[bone]
    if tag then return tag end
    return bone
end

local function cacheHitBone(ped, bone)
    bone = resolveDamageBone(ped, bone)
    if not bone then return end
    Vars.lastHitBone = bone
    Vars.lastHitBoneAt = GetGameTimer()
end

AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName ~= 'CEventNetworkEntityDamage' then return end
    local victim = data[1]
    local ped = cache.ped
    if victim ~= ped then return end
    local found, bone = GetPedLastDamageBone(ped)
    if found and bone and bone ~= 0 then
        cacheHitBone(ped, bone)
    end
end)

-- Functions
function IsDamagingEvent(damageDone, weapon)
    math.randomseed(GetGameTimer())
    local luck = math.random(100)
    local multi = damageDone / Config.HealthDamage
    return luck < (Config.HealthDamage * multi) or (damageDone >= Config.ForceInjury or multi > Config.MaxInjuryChanceMulti or Config.ForceInjuryWeapons[weapon])
end

function IsInjuryCausingLimp()
    for k, v in pairs(BodyParts) do
        if v.causeLimp and v.isDamaged then
            return true
        end
    end
    return false
end

function IsInjuredOrBleeding()
    if isBleeding > 0 then
        return true
    else
        for k, v in pairs(BodyParts) do
            if v.isDamaged then
                return true
            end
        end
    end
    return false
end

function GetDamagingWeapon(ped)
    for k, v in pairs(Config.Weapons) do
        if HasPedBeenDamagedByWeapon(ped, k, 0) then
            ClearEntityLastDamageEntity(ped)
            return v
        end
    end
    return nil
end

function ResetAll()
    isBleeding = 0
    bleedTickTimer = 0
    advanceBleedTimer = 0
    fadeOutTimer = 0
    blackoutTimer = 0
    injured = {}
    for k, v in pairs(BodyParts) do
        v.isDamaged = false
        v.severity = 0
    end
    TriggerServerEvent('cfx-keydi-ambulance:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })
    TriggerServerEvent('cfx-keydi-ambulance:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })
    DoBleedAlert()
end

function CheckDamage(ped, bone, weapon, damageDone)
    if weapon == nil then return end
    bone = resolveDamageBone(ped, bone)
    if not bone or not Config.Bones[bone] or Config.Bones[bone] == 'NONE' then return end
    cacheHitBone(ped, bone)

    -- Record the killing blow too — one-shot headshots used to skip HEAD because state.dead was already true
    if Config.Bones[bone] ~= nil then
        if not Player(cache.serverId).state.dead then
            ApplyImmediateEffects(ped, bone, weapon, damageDone)
        end

        if not BodyParts[Config.Bones[bone]].isDamaged then
            BodyParts[Config.Bones[bone]].isDamaged = true
            BodyParts[Config.Bones[bone]].severity = 1
            injured[#injured + 1] = {
                part = Config.Bones[bone],
                label = BodyParts[Config.Bones[bone]].label,
                severity = BodyParts[Config.Bones[bone]].severity
            }
        else
            if BodyParts[Config.Bones[bone]].severity < 4 then
                BodyParts[Config.Bones[bone]].severity = BodyParts[Config.Bones[bone]].severity + 1
                for i = 1, #injured do
                    local v = injured[i]
                    if v.part == Config.Bones[bone] then
                        v.severity = BodyParts[Config.Bones[bone]].severity
                    end
                end
            end
        end

        TriggerServerEvent('cfx-keydi-ambulance:server:SyncInjuries', {
            limbs = BodyParts,
            isBleeding = tonumber(isBleeding)
        })
        TriggerServerEvent('cfx-keydi-ambulance:server:SyncInjuries', {
            limbs = BodyParts,
            isBleeding = tonumber(isBleeding)
        })
        DoBleedAlert()
    end
end

function ApplyImmediateEffects(ped, bone, weapon, damageDone)
    local armor = GetPedArmour(ped)
    if Config.MinorInjurWeapons[weapon] and damageDone < Config.DamageMinorToMajor then
        if Config.CriticalAreas[Config.Bones[bone]] then
            if armor <= 0 then
                ApplyBleed(1)
            end
        end
    elseif Config.MajorInjurWeapons[weapon] or (Config.MinorInjurWeapons[weapon] and damageDone >= Config.DamageMinorToMajor) then
        if Config.CriticalAreas[Config.Bones[bone]] ~= nil then
            if armor > 0 and Config.CriticalAreas[Config.Bones[bone]].armored then
                if math.random(100) <= math.ceil(Config.MajorArmoredBleedChance) then
                    ApplyBleed(1)
                end
            else
                ApplyBleed(1)
            end
        else
            if armor > 0 then
                if math.random(100) < (Config.MajorArmoredBleedChance) then
                    ApplyBleed(1)
                end
            else
                if math.random(100) < (Config.MajorArmoredBleedChance * 2) then
                    ApplyBleed(1)
                end
            end
        end
    end
end

function ApplyBleed(level)
    level = tonumber(level) or 1
    local current = tonumber(isBleeding) or 0
    if current >= 4 then
        isBleeding = 4
        return
    end
    isBleeding = math.min(4, current + level)
    DoBleedAlert()
end

function DoBleedAlert()
    local bleedLevel = tonumber(isBleeding) or 0
    if not Player(cache.serverId).state.dead and bleedLevel > 0 then
        local stateLabel = Config.BleedingStates[bleedLevel] or 'Bleeding'
        if ESX.PersistentAlert then
            ESX.PersistentAlert('start', bleedNotifId, 'error', string.format(Config.Strings.BleedAlert, stateLabel), 'STATUS')
        else
            ESX.Notify('STATUS', string.format(Config.Strings.BleedAlert, stateLabel), 'error')
        end
    else
        if ESX.PersistentAlert then
            ESX.PersistentAlert('end', bleedNotifId)
        end
    end
end

-- Net Events
local function SyncLimbsHandler(limbs)
    BodyParts = limbs
    injured = {}
    for k, v in pairs(BodyParts) do
        if v.isDamaged then
            injured[#injured + 1] = {
                part = k,
                label = v.label,
                severity = v.severity
            }
        end
    end
end
RegisterNetEvent('cfx-keydi-ambulance:client:SyncLimbs', SyncLimbsHandler)
RegisterNetEvent('cfx-keydi-ambulance:client:SyncLimbs', SyncLimbsHandler)

local function SyncBleedHandler(bleedStatus)
    isBleeding = tonumber(bleedStatus)
    DoBleedAlert()
end
RegisterNetEvent('cfx-keydi-ambulance:client:SyncBleed', SyncBleedHandler)
RegisterNetEvent('cfx-keydi-ambulance:client:SyncBleed', SyncBleedHandler)

local function ResetLimbsHandler()
    injured = {}
    for k, v in pairs(BodyParts) do
        v.isDamaged = false
        v.severity = 0
    end
    TriggerServerEvent('cfx-keydi-ambulance:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })
    TriggerServerEvent('cfx-keydi-ambulance:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })
end
RegisterNetEvent('cfx-keydi-ambulance:client:ResetLimbs', ResetLimbsHandler)
RegisterNetEvent('cfx-keydi-ambulance:client:ResetLimbs', ResetLimbsHandler)

local function RemoveBleedHandler()
    local wasBleeding = (tonumber(isBleeding) or 0) > 0
    isBleeding = 0
    bleedTickTimer = 0
    advanceBleedTimer = 0
    fadeOutTimer = 0
    blackoutTimer = 0
    applyingBleedDamage = false

    local ped = cache.ped
    if ped and DoesEntityExist(ped) then
        ClearEntityLastDamageEntity(ped)
        ClearPedLastDamageBone(ped)
        playerHealth = GetEntityHealth(ped)
        playerArmor = GetPedArmour(ped)
    end

    TriggerServerEvent('cfx-keydi-ambulance:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = 0
    })
    DoBleedAlert()
    if wasBleeding then
        ESX.Notify('STATUS', 'Bleeding has been stopped.', 'success', 5000)
    end
end
RegisterNetEvent('cfx-keydi-ambulance:client:RemoveBleed', RemoveBleedHandler)

-- Recovery / crutches (prop + walk-only; cannot cancel until timer ends)
local isRecovering = false
local recoveryGen = 0
local crutchActive = false
local crutchObject = nil
local CRUTCH_MODEL = `v_med_crutch01`
local CRUTCH_CLIPSET = 'move_lester_CaneUp'
local recoveryActivities = {
    { check = IsPedJumping, chance = 60, rate = 50 },
    { check = IsPedRunning, chance = 8, rate = 30 },
    { check = IsPedShooting, chance = 45, rate = 25 },
    { check = IsPedClimbing, chance = 60, rate = 50 },
    { check = IsPedBeingStunned, chance = 60, rate = 50 },
    { check = function(ped) return IsPlayerFreeAiming(cache.playerId) end, chance = 5, rate = 15 }
}

local function setEmoteLimited(limited)
    if limited then
        pcall(function()
            exports['scully_emotemenu']:cancelEmote()
        end)
        pcall(function()
            exports['cfx-keydi-ui']:StopEmote()
        end)
        pcall(function()
            exports['scully_emotemenu']:resetWalk()
        end)
        pcall(function()
            exports['scully_emotemenu']:setLimitation(true)
        end)
    else
        pcall(function()
            exports['scully_emotemenu']:setLimitation(false)
        end)
    end
end

local function deleteCrutchProp()
    if crutchObject and DoesEntityExist(crutchObject) then
        DetachEntity(crutchObject, true, true)
        DeleteEntity(crutchObject)
    end
    crutchObject = nil
end

local function createCrutchProp(ped)
    deleteCrutchProp()
    if not ped or ped == 0 then return end
    lib.requestModel(CRUTCH_MODEL, 5000)
    local coords = GetEntityCoords(ped)
    crutchObject = CreateObject(CRUTCH_MODEL, coords.x, coords.y, coords.z, true, false, false)
    if not crutchObject or crutchObject == 0 then return end
    -- Bone 70 / offsets from mh-crutches (v_med_crutch01)
    AttachEntityToEntity(crutchObject, ped, 70, 1.18, -0.36, -0.20, -20.0, -87.0, -20.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(CRUTCH_MODEL)
end

local function applyCrutchClipset(ped)
    if not HasAnimSetLoaded(CRUTCH_CLIPSET) then
        lib.requestAnimSet(CRUTCH_CLIPSET, 5000)
    end
    SetPedMovementClipset(ped, CRUTCH_CLIPSET, 1.0)
end

local function setCrutchState(active)
    LocalPlayer.state:set('crutches', active == true, true)
end

local function stopCrutches()
    if not crutchActive and not crutchObject then
        setCrutchState(false)
        setEmoteLimited(false)
        return
    end
    crutchActive = false
    setCrutchState(false)
    deleteCrutchProp()
    local ped = PlayerPedId()
    ResetPedMovementClipset(ped, 0.0)
    SetPedMaxMoveBlendRatio(ped, 10.0)
    SetPedMoveRateOverride(ped, 1.0)
    SetPlayerSprint(PlayerId(), true)
    setEmoteLimited(false)
end

local function startCrutches()
    if crutchActive then
        setEmoteLimited(true)
        setCrutchState(true)
        return
    end

    -- Cancel emotes / walk styles before locking crutches
    setEmoteLimited(true)

    crutchActive = true
    setCrutchState(true)
    local ped = PlayerPedId()
    applyCrutchClipset(ped)
    createCrutchProp(ped)

    -- Frame loop: walk only — Shift / analog run / jump / X-cancel stay locked
    CreateThread(function()
        while crutchActive do
            local ped = PlayerPedId()
            local playerId = PlayerId()

            DisableControlAction(0, 21, true)  -- sprint (Shift)
            DisableControlAction(0, 22, true)  -- jump
            DisableControlAction(0, 36, true)  -- stealth / ctrl
            DisableControlAction(0, 44, true)  -- cover
            DisableControlAction(0, 73, true)  -- X cancel anim
            DisableControlAction(0, 137, true) -- bike sprint
            DisableControlAction(0, 170, true) -- F3 emote
            DisableControlAction(0, 323, true) -- X (alt)

            SetPlayerSprint(playerId, false)
            SetPedMaxMoveBlendRatio(ped, 1.0)
            SetPedMoveRateOverride(ped, 0.85)

            Wait(0)
        end
    end)

    -- Maintain prop + clipset (emotes / walk styles / respawn try to clear these)
    CreateThread(function()
        while crutchActive do
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, true) and not IsEntityDead(ped) then
                applyCrutchClipset(ped)
                if not crutchObject or not DoesEntityExist(crutchObject) or not IsEntityAttachedToEntity(crutchObject, ped) then
                    createCrutchProp(ped)
                end
            elseif crutchObject and DoesEntityExist(crutchObject) then
                deleteCrutchProp()
            end
            Wait(100)
        end
    end)
end

function SetRecoveryState(duration, crutchDuration)
    duration = tonumber(duration) or 0
    crutchDuration = tonumber(crutchDuration) or 0
    if duration <= 0 then return end

    -- STL / EMS revive must restart crutches even if a previous recovery is still running
    recoveryGen = recoveryGen + 1
    local myGen = recoveryGen
    isRecovering = false
    stopCrutches()
    Wait(50)

    isRecovering = true

    -- Wait for EMS/STL revive RespawnPed to finish before attaching crutches
    local waitDeadline = GetGameTimer() + 8000
    while LocalPlayer.state.isReviving and GetGameTimer() < waitDeadline do
        Wait(100)
    end
    Wait(400)
    if myGen ~= recoveryGen then return end

    local PlayerData = ESX.GetPlayerData()
    if PlayerData and PlayerData.identifier then
        SetResourceKvpInt(('recovery_state_%s'):format(PlayerData.identifier), duration)
    end
    local recoveryTime = duration * 1000
    local timeStarted = GetGameTimer()
    local lastNotify = 0

    if crutchDuration > 0 then
        startCrutches()
        ESX.Notify('Injuries', 'You need crutches while recovering — no running.', 'warning', 7000)
    end

    while isRecovering and myGen == recoveryGen do
        local currentTime = GetGameTimer()
        local elapsedSec = (currentTime - timeStarted) / 1000
        local playerPed = PlayerPedId()

        if crutchActive and elapsedSec >= crutchDuration then
            stopCrutches()
            ESX.Notify('Injuries', 'You can walk normally now, but stay cautious while recovering.', 'inform', 7000)
        end

        -- Skip activity checks while crutches enforce walk (running is already blocked)
        if not crutchActive then
            for i = 1, #recoveryActivities do
                local activity = recoveryActivities[i]
                if activity.check(playerPed) and math.random(100) < activity.chance then
                    RecoveryFailed(activity.rate)
                    isRecovering = false
                    break
                end
            end
        end

        if currentTime - timeStarted > recoveryTime then
            if PlayerData and PlayerData.identifier then
                SetResourceKvpInt(('recovery_state_%s'):format(PlayerData.identifier), 0)
            end
            isRecovering = false
        end
        if currentTime - lastNotify > 7000 then
            if crutchActive then
                ESX.Notify('Injuries', 'Still on crutches — you can only walk until the timer ends.', 'warning', 7000)
            else
                ESX.Notify('Injuries', 'You are currently recovering from your previous injuries.', 'warning', 7000)
            end
            lastNotify = currentTime
        end
        Wait(500)
    end

    if myGen == recoveryGen then
        stopCrutches()
        isRecovering = false
    end
end
RegisterNetEvent("cfx-keydi-ambulance:SetRecoveryState", SetRecoveryState)
exports('SetRecoveryState', SetRecoveryState)
exports('IsOnCrutches', function()
    return crutchActive == true
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    isRecovering = false
    stopCrutches()
end)

exports('IsBleeding', function()
    return (isBleeding or 0) > 0
end)

function RecoveryFailed(rate)
    local ped = cache.ped
    local curHealth = GetEntityHealth(ped)
    local newHealth = curHealth - rate
    ApplyBleed(1)
    Wait(2500)
    SetPedToRagdollWithFall(ped, 4500, 2000, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    Wait(2500)
    SetEntityHealth(ped, newHealth)
end

-- Injury Threads
local prevPos = nil
CreateThread(function()
    Wait(2500)
    prevPos = GetEntityCoords(cache.ped, true)
    while true do
        if isBleeding > 0 and not LocalPlayer.state.spawnProtect then
            local player = cache.ped
            if bleedTickTimer >= Config.BleedTickRate then
                if not Player(cache.serverId).state.dead and isBleeding > 0 then
                    local bleedDamage = tonumber(isBleeding) * Config.BleedTickDamage
                    applyingBleedDamage = true
                    ApplyDamageToPed(player, bleedDamage, false)
                    Wait(100)
                    playerHealth = GetEntityHealth(player)
                    applyingBleedDamage = false
                    if advanceBleedTimer >= Config.AdvanceBleedTimer then
                        ApplyBleed(1)
                        advanceBleedTimer = 0
                    else
                        advanceBleedTimer = advanceBleedTimer + 1
                    end
                end
                bleedTickTimer = 0
            else
                local movedFaster = false
                if bleedTickTimer > 0 and bleedTickTimer % math.max(1, math.floor(Config.BleedTickRate / 10)) == 0 then
                    local currPos = GetEntityCoords(player, true)
                    local moving = #(vector2(prevPos.x, prevPos.y) - vector2(currPos.x, currPos.y))
                    if (moving > 1 and not IsPedInAnyVehicle(player)) and isBleeding > 2 then
                        ESX.Notify('STATUS', 'You notice blood oozing from your wounds faster when you\'re moving', 'warning', 5000)
                        advanceBleedTimer = advanceBleedTimer + Config.BleedMovementAdvance
                        bleedTickTimer = bleedTickTimer + Config.BleedMovementTick
                        prevPos = currPos
                        movedFaster = true
                    else
                        prevPos = currPos
                    end
                end
                if not movedFaster then
                    bleedTickTimer = bleedTickTimer + 1
                end
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local ped = cache.ped
        local health = GetEntityHealth(ped)
        local armor = GetPedArmour(ped)
        if not playerHealth then
            playerHealth = health
        end
        if not playerArmor then
            playerArmor = armor
        end

        -- Bleed-tick HP loss must not re-apply / escalate bleeding
        if applyingBleedDamage or LocalPlayer.state.spawnProtect then
            playerHealth = health
            playerArmor = armor
            Wait(100)
        else
            local armorDamaged = (playerArmor ~= armor and armor < (playerArmor - Config.ArmorDamage) and armor > 0)
            local healthDamaged = (playerHealth ~= health)
            local damageDone = (playerHealth - health)
            if (armorDamaged or healthDamaged) and damageDone > 0 then
                local hit, bone = GetPedLastDamageBone(ped)
                if (not hit or not bone or bone == 0) and Vars.lastHitBone and (GetGameTimer() - (Vars.lastHitBoneAt or 0)) < 500 then
                    hit, bone = true, Vars.lastHitBone
                end
                bone = resolveDamageBone(ped, bone)
                if bone then cacheHitBone(ped, bone) end
                local bodypart = bone and Config.Bones[bone]
                local weapon = GetDamagingWeapon(ped)
                -- Weapon native is often already cleared on one-shot headshots; still record the limb
                if not weapon and (bodypart == 'HEAD' or bodypart == 'NECK') and damageDone >= Config.HealthDamage then
                    weapon = Config.WeaponClasses['HIGH_CALIBER']
                end
                if hit and bodypart and bodypart ~= 'NONE' then
                    if damageDone >= Config.HealthDamage then
                        local checkDamage = true
                        if weapon ~= nil then
                            if armorDamaged and (bodypart == 'SPINE' or bodypart == 'UPPER_BODY') or weapon == Config.WeaponClasses['NOTHING'] then
                                checkDamage = false
                            end
                            if checkDamage then
                                if IsDamagingEvent(damageDone, weapon) then
                                    CheckDamage(ped, bone, weapon, damageDone)
                                end
                            end
                        end
                    elseif weapon and Config.AlwaysBleedChanceWeapons[weapon] then
                        if math.random(100) < Config.AlwaysBleedChance then
                            ApplyBleed(1)
                        end
                    end
                end
            end
            playerHealth = health
            playerArmor = armor
            Wait(100)
        end
    end
end)
