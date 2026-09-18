ESX = exports['es_extended']:getSharedObject()
local Vars = require 'helpers.vars'
local helpers = require 'helpers.game'
local configs = require 'shared.config'
local client = require 'helpers.client'
local nui = require 'shared.nui'
local DeathCam = require 'helpers.deathcam'

-- Spawn timer UI waits for the death recap (ConfigDeathScreen.DisplayDuration)
local SPAWN_BAR_DELAY_MS = 10000
local isChecked = false
local onDeath

local newTimer = nil

function ResetDeathTimer()
  newTimer = nil
  print('[cfx-keydi-ambulance]: Resetting Spawn Timer')
end

exports('ResetDeathTimer', ResetDeathTimer)

function OverrideDeathTimer(newTime)
  newTimer = math.max(0, ESX.Math.Round(newTime / 1000))
  local sMinute, sSecond = helpers.SecondsToClock(newTimer)
  print('[cfx-keydi-ambulance]: Setting Spawn Timer to '..sMinute..':'..sSecond)
end

exports('OverrideDeathTimer', OverrideDeathTimer)

local function restoreDeathOnLoad()
    CreateThread(function()
        local timeout = GetGameTimer() + 15000
        while GetGameTimer() < timeout do
            local ped = PlayerPedId()
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                break
            end
            Wait(100)
        end

        if Vars.isReviving then return end

        Vars.CaptureDeathZone(PlayerPedId())

        TriggerServerEvent('cfx-keydi-ambulance:setPlayerDeathStatus', true, 'restore')

        Wait(400)
        if Vars.isReviving then return end

        -- Do not SetEntityHealth(0): GTA hospital-respawns to campus. Hold at last coords.
        if not Vars.isDead then
            onDeath({ restored = true })
        else
            client.StartDeathHoldWatch()
        end

        -- Rebind mumble after reconnect, then deafen (dead players cannot hear).
        if GetResourceState('pma-voice') == 'started' then
            Wait(600)
            pcall(function()
                exports['pma-voice']:startJoinHandshake('death-restore')
            end)
        end
        client.SetDeathHearing(false)
    end)
end

local function applyAliveOnLoad()
    client.StopDeathPose()
    client.StopDeathHold()
    Vars.isDead = false
    LocalPlayer.state:set('invBusy', false, true)
    client.HideNUI()
    TriggerServerEvent('cfx-keydi-ambulance:checkBed')
    TriggerServerEvent('cfx-keydi-ambulance:ensureVoiceUnmute')
    if GetResourceState('pma-voice') == 'started' then
        pcall(function()
            exports['pma-voice']:startJoinHandshake('alive-load')
        end)
    end
end

local function onDeathStatusChecked(isDead)
    if isDead or LocalPlayer.state.dead then
        restoreDeathOnLoad()
        return
    end
    applyAliveOnLoad()
end

local function requestDeathStatus(attempt)
    attempt = attempt or 1
    if isChecked then return end

    local function handle(isDead)
        if isChecked then return end
        -- State bag can arrive before the callback; never ignore a dead flag.
        if LocalPlayer.state.dead then
            isDead = true
        end
        isChecked = true
        onDeathStatusChecked(isDead and true or false)
    end

    -- Prefer ox_lib (avoids ESX callback race on resource restart)
    if lib and lib.callback and lib.callback.await then
        local ok, isDead = pcall(function()
            return lib.callback.await('cfx-keydi-ambulance:checkDeathStatus', false)
        end)
        if ok and isDead ~= nil then
            return handle(isDead)
        end
    end

    if ESX and ESX.TriggerServerCallback then
        local answered = false
        ESX.TriggerServerCallback('cfx-keydi-ambulance:checkDeathStatus', function(isDead)
            answered = true
            handle(isDead)
        end)
        SetTimeout(2500, function()
            if answered or isChecked then return end
            if attempt < 8 then
                requestDeathStatus(attempt + 1)
            elseif LocalPlayer.state.dead then
                handle(true)
            else
                handle(false)
            end
        end)
        return
    end

    if attempt < 8 then
        SetTimeout(1000, function()
            requestDeathStatus(attempt + 1)
        end)
    elseif LocalPlayer.state.dead then
        handle(true)
    else
        handle(false)
    end
end

AddEventHandler('ESX:Client:PlayerLoaded', function()
    local resource = GetInvokingResource()
    if resource == nil or resource ~= 'es_extended' then return end
    requestDeathStatus(1)
end)

-- Real ESX load event (ESX:Client:PlayerLoaded is never fired by this server's es_extended)
RegisterNetEvent('esx:playerLoaded', function()
    requestDeathStatus(1)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    client.StopDeathHold()
    client.StopDeathPose()
    isChecked = false
    Vars.isDead = false
end)

AddStateBagChangeHandler('dead', nil, function(bagName, _, value)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply ~= PlayerId() then return end
    if not value then return end
    if Vars.isReviving then return end
    if Vars.isDead then return end
    restoreDeathOnLoad()
end)

CreateThread(function()
    while true do
        local sleep = 500
        if Vars.isDead then
            sleep = 0
            DisableAllControlActions(0)
            EnableControlAction(0, 47, true)  -- G / 911 dispatch
            EnableControlAction(0, 245, true) -- F10 / screenshot
            -- Do not enable H (74): GTA can treat it as pause/map.
            -- Spawn selector still reads IsDisabledControlJustReleased(0, 74).
        end
        Wait(sleep)
    end
end)

function GetDeathTimer()
    local bankData = ESX.GetAccount('bank')
    local default = Vars.diedInRedZone
        and ESX.Math.Round((configs.General.RedZoneRespawnTimer or 60000) / 1000)
        or ESX.Math.Round((configs.General.RespawnTimer or 300000) / 1000)
    local bankNegative = ESX.Math.Round((configs.General.RespawnWithNegativeBank or 300000) / 1000)
    if newTimer ~= nil then
        return newTimer
    end
    return (bankData and bankData?.money <= -1 and bankNegative or default)
end

local function isDead()
    return Vars.isDead
end

exports('isDead', isDead)

local HideNUI = false
local displayed = false
local deathUiMode = 'full' -- 'full' | 'short'
local selectedRespawnId = nil
local spawnCfg = require 'shared.spawn'

local function buildRespawnLocationsPayload()
    local list = {}
    local defaultFine = configs.General.RespawnFine or 1000
    local preferred = Vars.SelectStlZone()
    for id, data in pairs(spawnCfg.Locations or {}) do
        if not data.hidden then
            local requiredJob = data.job
            if requiredJob then
                local job = ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
                if not job and ESX and ESX.GetPlayerData then
                    local pd = ESX.GetPlayerData()
                    job = pd and pd.job and pd.job.name
                end
                if job ~= requiredJob then
                    goto continue
                end
            end
            list[#list + 1] = {
                id = id,
                label = data.label or id,
                area = data.area or '',
                cost = tonumber(data.cost) or defaultFine,
            }
        end
        ::continue::
    end
    table.sort(list, function(a, b)
        if a.id == preferred then return true end
        if b.id == preferred then return false end
        return a.label < b.label
    end)
    return list, preferred
end

local function setDeathUiFocus(mode)
    deathUiMode = mode
    -- Never use SetNuiFocusKeepInput(true) — it hard-crashes some FiveM builds.
    if mode == 'full' then
        SetNuiFocus(true, true)
    else
        SetNuiFocus(false, false)
    end
    SetNuiFocusKeepInput(false)
end

local function HideEMSUI(bool)
    if bool then
        DeathCam.Stop()
        SendNUIMessage({ type = 'HideUI' })
        client.blurOut()
        deathUiMode = 'full'
        selectedRespawnId = nil
        displayed = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    else
        client.blurIn()
        displayed = false
        selectedRespawnId = nil
    end
    HideNUI = bool
end

exports('HideEMSUI', HideEMSUI)

local function pushSpawnTimer(_seconds)
end

local function isSpawnMenuOpen()
    return deathUiMode == 'full'
end

local function openSpawnSelector(_isDeathCam, _respawnTimer, _allowEarlySpawn, _isBleedout)
    setDeathUiFocus('full')
    SendNUIMessage({ type = 'updateDeathScreen', update = 'mode', mode = 'full' })
    return true
end

local function pushDeathBar(currentTimer, inBleedout)
    if HideNUI then return end
    if not displayed then
        local total = GetDeathTimer()
        local locs, preferred = buildRespawnLocationsPayload()
        SendNUIMessage({
            type = 'ShowUI',
            time = currentTimer,
            totalTime = total,
            locations = locs,
            selectedId = preferred,
            mode = 'full',
        })
        displayed = true
        if not selectedRespawnId then
            selectedRespawnId = preferred or (locs[1] and locs[1].id) or nil
        end
        CreateThread(function()
            Wait(50)
            if Vars.isDead and displayed and not HideNUI then
                setDeathUiFocus('full')
            end
        end)
    end
    SendNUIMessage({
        type = 'updateDeathScreen',
        update = 'text',
        bleedout = inBleedout == true,
    })
    SendNUIMessage({
        type = 'updateDeathScreen',
        update = 'time',
        time = currentTimer,
    })
end

local function DeathTimer()
    -- Shared timer upvalue — both threads read/write this same variable
    local currentTimer = GetDeathTimer()
    local bleedoutSecs = ESX.Math.Round((configs.General.BleedoutTimer or 0) / 1000)
    local spawnOpened  = false
    local lastHPress   = 0
    local inBleedout   = false
    local spawnBarReady = false
    displayed = false
    selectedRespawnId = nil
    Vars.stlUnlocked = false
    deathUiMode = 'full'
    DeathCam.Stop()

    -- ── Thread 1: death recap first, then spawn bar + bleedout ──────────────
    CreateThread(function()
        local showAt = GetGameTimer() + SPAWN_BAR_DELAY_MS

        local function revealBar()
            if spawnBarReady or not Vars.isDead then return end
            spawnBarReady = true
            pushDeathBar(currentTimer, inBleedout)
        end

        -- Countdown starts immediately; bar waits for the death recap
        while currentTimer > 0 and Vars.isDead do
            if GetGameTimer() >= showAt then
                revealBar()
            end
            Wait(1000)
            if not Vars.isDead then
                client.HideNUI()
                return
            end

            currentTimer = currentTimer - 1
            Vars.stlUnlocked = false
            if spawnBarReady then
                pushDeathBar(currentTimer, false)
            end

            if isSpawnMenuOpen() then
                spawnOpened = true
                pushSpawnTimer(currentTimer)
            end
        end

        if not Vars.isDead then
            client.HideNUI()
            return
        end

        -- STL wait over — bleedout countdown. Confirm unlocks so players can respawn.
        inBleedout = true
        currentTimer = math.max(0, bleedoutSecs)
        Vars.stlUnlocked = true
        if GetGameTimer() >= showAt then
            revealBar()
        else
            while GetGameTimer() < showAt and Vars.isDead do
                Wait(100)
            end
            if Vars.isDead then
                revealBar()
            end
        end
        if not Vars.isDead then
            client.HideNUI()
            return
        end

        pushDeathBar(currentTimer, true)
        spawnOpened = openSpawnSelector(true, currentTimer, false, true) or spawnOpened

        if currentTimer <= 0 then
            pushSpawnTimer(0)
            return
        end

        while currentTimer > 0 and Vars.isDead do
            Wait(1000)
            if not Vars.isDead then
                client.HideNUI()
                return
            end

            currentTimer = currentTimer - 1
            Vars.stlUnlocked = true
            pushDeathBar(currentTimer, true)

            -- Keep user's Full/Short choice — do not force Full back open every tick
            if isSpawnMenuOpen() then
                spawnOpened = true
                pushSpawnTimer(currentTimer)
            end
        end

        if Vars.isDead and currentTimer <= 0 then
            pushSpawnTimer(0)
            client.RemoveRPDeath()
        end
    end)

    -- ── Thread 2: Poll [G] freecam / [H] spawn while down ───────────────────
    CreateThread(function()
        while Vars.isDead do
            -- Soften when Full panel has focus (no need for per-frame poll)
            if deathUiMode == 'full' then
                Wait(200)
            else
                Wait(0)
            end

            if not Vars.isDead then break end

            -- [G] = death freecam (only after spawn timer UI is up, short mode)
            if spawnBarReady and deathUiMode ~= 'full' and IsControlJustReleased(0, 47) then
                DeathCam.Toggle()
            end

            -- [H] key (74) = reopen Full Medical Panel from short bar
            local pressedH = IsDisabledControlJustReleased(0, 74) or IsControlJustReleased(0, 74)
            if pressedH and spawnBarReady and deathUiMode ~= 'full' then
                local now = GetGameTimer()
                if now - (lastHPress or 0) >= 1200 then
                    lastHPress = now
                    openSpawnSelector(true, math.max(0, currentTimer), false, inBleedout)
                end
            end
        end

        DeathCam.Stop()
    end)
end


onDeath = function(data)
    -- Ignore death events fired while / during revive (esx death-monitor race)
    if Vars.isReviving then return end

    local inPvp = LocalPlayer.state.inPvp or LocalPlayer.state.isInPvp

    if Vars.isDead then
        if not client.IsBeingMoved() then
            client.StartDeathPose()
        end
        return
    end

    local ped = cache.ped
    -- Capture damage bone before other scripts clear it. GTA reports facial bones on headshots, not only SKEL_Head.
    local hit, bone = GetPedLastDamageBone(ped)
    if (not hit or not bone or bone == 0) and Vars.lastHitBone and (GetGameTimer() - (Vars.lastHitBoneAt or 0)) < 1500 then
        bone = Vars.lastHitBone
    end
    bone = tonumber(bone) or 0
    if bone ~= 0 then
        if Config.ToBoneId then
            bone = Config.ToBoneId(bone)
        end
        Vars.lastHitBone = bone
        Vars.lastHitBoneAt = GetGameTimer()
    end

    Vars.isDead = true
    Vars.deathToken = (Vars.deathToken or 0) + 1
    local _, deathCoords = Vars.CaptureDeathZone(PlayerPedId())
    client.StartDeathHoldWatch()
    local stlZone = Vars.SelectStlZone()
    local zoneName = stlZone == 'paleto_hospital' and 'Paleto' or (stlZone == 'sandy_hospital' and 'Sandy' or 'City')
    local zoneDesc = Vars.diedInRedZone and 'RedZone (1 Min Respawn • $15,000 Fine)' or (
        ('%s  (5 Min Respawn • $15,000 Fine | Y %.0f)'):format(zoneName, deathCoords.y)
    )
    lib.notify({
        title = 'STL Zone',
        description = zoneDesc,
        type = Vars.diedInRedZone and 'error' or (Vars.deathInSandy and 'success' or 'inform'),
        duration = 8000,
    })
    client.SetDeathHearing(false)
    TriggerServerEvent('cfx-keydi-ambulance:setPlayerDeathStatus', true)
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:closeInventory()
    end
    LocalPlayer.state:set('invBusy', true, true)
    if GetResourceState('cfx-keydi-radio') == 'started' then
        exports['cfx-keydi-radio']:leaveRadio()
    elseif GetResourceState('ac_radio') == 'started' then
        exports['ac_radio']:leaveRadio()
    end
    if GetResourceState('rryban_priority') == 'started' then
        local isVisible = exports['rryban_priority']:GetUIState()
        if isVisible then
           exports['rryban_priority']:HideUI(false)
        end
    end
    if GetResourceState('ox_target') == 'started' then
        pcall(function()
            exports.ox_target:disableTargeting(true)
        end)
    end
    if GetResourceState('jg-hud') == 'started' then
        pcall(function()
            exports['jg-hud']:toggleHud(false)
        end)
    end
    if GetResourceState('kodebykarl-ui') == 'started' then
        pcall(function()
            exports['kodebykarl-ui']:CloseIpad()
        end)
    end
    Vars.Status.multiplier = 2.0
    Vars.Status.blood = 100
    Vars.Status.health = GetEntityHealth(ped)
    Vars.Status.area = 'LEGS/ARMS'
    Vars.Status.bleeding = 1
    local part = Config.Bones and Config.Bones[bone]
    if part == 'HEAD' or part == 'NECK' or (Config.IsHeadArea and Config.IsHeadArea(bone)) then
        Vars.Status.multiplier = 0.0
        Vars.Status.bleeding = 5
        Vars.Status.area = "HEAD"
    elseif Vars.Status.bone[bone] or part == 'SPINE' or part == 'UPPER_BODY' or part == 'LOWER_BODY' then
        Vars.Status.multiplier = 1.0
        Vars.Status.bleeding = 2
        Vars.Status.area = 'BODY'
    end
    Vars.Status.pulse = ((Vars.Status.health / 4 + 20) * Vars.Status.multiplier) + math.random(0, 4)

    -- Arena PvP: stay dead for the deathscreen recap, skip ambulance spawn timer UI
    if inPvp then
        return
    end

    client.blurIn()
    DeathTimer()
end

AddEventHandler('esx:onPlayerDeath', function(data)
    onDeath(data)
end)

AddEventHandler('esx:onPlayerSpawn', function()
    -- Reconnect/appearance can fire spawn before death status is known.
    if Vars.isReviving then return end
    if Vars.isDead or LocalPlayer.state.dead then
        if not client.IsBeingMoved() then
            client.StartDeathPose()
            client.StartDeathHoldWatch()
        end
        if ESX and ESX.SetPlayerData then
            ESX.SetPlayerData('dead', true)
        end
        return
    end
    if not isChecked then
        -- Do not mark them alive until DB/state death check finishes.
        return
    end
    client.StopDeathPose()
    Vars.isDead = false
    LocalPlayer.state:set('invBusy', false, true)
    client.HideNUI()
    -- Unmute if alive; pma-voice also reinits channel on this event
    TriggerServerEvent('cfx-keydi-ambulance:ensureVoiceUnmute')
end)

RegisterNetEvent('cfx-keydi-ambulance:spawnProtect', function(duration)
    if source ~= 65535 then return end
    client.StartSpawnProtection(duration)
end)

RegisterNetEvent('cfx-keydi-ambulance:revive', function(dest)
    if source ~= 65535 then return end
    if Vars.isReviving then return end

    client.StopDeathHold()
    client.StopDeathPose()
    Vars.isReviving = true
    Vars.isDead = false
    Vars.deathInSandy = false
    Vars.deathCoords = nil
    Vars.deathToken = (Vars.deathToken or 0) + 1
    LocalPlayer.state:set('isReviving', true, false)
    LocalPlayer.state:set('dead', false, true)
    LocalPlayer.state:set('invBusy', false, true)
    if ESX and ESX.SetPlayerData then
        ESX.SetPlayerData('dead', false)
    end
    ClampGameplayCamPitch(-90.0, 90.0)
    RenderScriptCams(false, false, 0, true, true)
    client.HideNUI()
    TriggerServerEvent('cfx-keydi-ambulance:setPlayerDeathStatus', false)

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    if dest ~= nil then
        local dx = dest.x or dest[1]
        local dy = dest.y or dest[2]
        local dz = dest.z or dest[3]
        if dx and dy and dz then
            coords = vector3(dx + 0.0, dy + 0.0, dz + 0.0)
            heading = tonumber(dest.w or dest[4] or dest.heading) or heading
        end
    end
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetPedCanRagdoll(ped, false)
    ClearPedTasksImmediately(ped)

    DoScreenFadeOut(400)
    local fadeTimeout = GetGameTimer() + 3000
    while not IsScreenFadedOut() and GetGameTimer() < fadeTimeout do
        Wait(0)
    end

    -- Watchdog: if RespawnPed / appearance hangs, never leave players on a black screen.
    CreateThread(function()
        local deadline = GetGameTimer() + 8000
        while GetGameTimer() < deadline do
            if not IsScreenFadedOut() and not IsScreenFadingOut() then
                return
            end
            Wait(100)
        end
        if IsScreenFadedOut() or IsScreenFadingOut() then
            DoScreenFadeIn(0)
        end
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityCollision(PlayerPedId(), true, true)
        Vars.isReviving = false
        LocalPlayer.state:set('isReviving', false, false)
    end)

    local ok, err = pcall(client.RespawnPed, ped, { x = coords.x, y = coords.y, z = coords.z }, heading)
    if not ok then
        print(('[cfx-keydi-ambulance] RespawnPed failed during revive: %s'):format(tostring(err)))
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityCollision(PlayerPedId(), true, true)
        Vars.isReviving = false
        LocalPlayer.state:set('isReviving', false, false)
    end

    DoScreenFadeIn(400)
end)

-- AddEventHandler('cfx-keydi-ambulance:purge', function()
--     if not GlobalState.IsPurging then return end
--     local ped = cache.ped
--     local coords = GetEntityCoords(ped)
--     TriggerServerEvent('cfx-keydi-ambulance:setPlayerDeathStatus', false)
--     client.HideNUI()
--     DoScreenFadeOut(800)
--     while not IsScreenFadedOut() do Wait(50) end
--     local formattedCoords = {x = ESX.Math.Round(coords.x, 1), y = ESX.Math.Round(coords.y, 1), z = ESX.Math.Round(coords.z, 1)}
--     client.RespawnPed(ped, formattedCoords, 0.0)
--     Vars.isDead = false
--     DoScreenFadeIn(800)
-- end)

CreateThread(function()
    local blips = configs.Blips or {}
    for i = 1, #blips do
        local data = blips[i]
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, data.sprite or 61)
        SetBlipColour(blip, data.colour or 1)
        SetBlipScale(blip, data.scale or 0.8)
        SetBlipAsShortRange(blip, data.shortRange ~= false)
        SetBlipDisplay(blip, data.display or 4)
        SetBlipHighDetail(blip, true)
        SetBlipCategory(blip, data.category or 1)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(data.label or 'Hospital')
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    local function getJobCount(jobName)
        return GlobalState[('%s:count'):format(jobName)] or 0
    end

    local function requestPedModel(preferred)
        local candidates = {
            preferred,
            's_m_m_paramedic_01',
            's_m_m_doctor_01',
            's_f_y_scrubs_01',
        }
        local seen = {}
        for i = 1, #candidates do
            local name = candidates[i]
            if name and not seen[name] then
                seen[name] = true
                local model = joaat(name)
                local ok = pcall(function()
                    lib.requestModel(model, 5000)
                end)
                if ok and HasModelLoaded(model) then
                    return model
                end
                if HasModelLoaded(model) then
                    SetModelAsNoLongerNeeded(model)
                end
            end
        end
        return nil
    end

    local function spawnCheckInPed(checkIn)
        if not checkIn.ped or not checkIn.ped.model then return nil end
        local model = requestPedModel(checkIn.ped.model)
        if not model then
            warn(('[kodebykarl-ambulance] check-in ped failed to load (%s) — using zone only'):format(tostring(checkIn.ped.model)))
            return nil
        end
        local heading = checkIn.heading or 0.0
        local ped = CreatePed(0, model, checkIn.coords.x, checkIn.coords.y, checkIn.coords.z - 1.0, heading, false, true)
        SetModelAsNoLongerNeeded(model)
        if not ped or ped == 0 then
            return nil
        end
        SetEntityAsMissionEntity(ped, true, true)
        SetPedFleeAttributes(ped, 0, false)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        if checkIn.ped.scenario then
            TaskStartScenarioInPlace(ped, checkIn.ped.scenario, 0, true)
        end
        return ped
    end

    local function doCheckIn(index, checkIn)
        if getJobCount(checkIn.job) >= checkIn.onDuty then
            ESX.Notify(
                'AMBULANCE',
                'There are plenty of medics in the city! Distress for help!',
                'error',
                5000
            )
            return
        end

        local progress = lib.progressBar({
            duration = 1000,
            label = 'Please Wait . . .',
            useWhileDead = true,
            canCancel = false,
            disable = {
                car = true,
            },
            anim = {
                scenario = 'WORLD_HUMAN_CLIPBOARD'
            }
        })

        if not progress then
            ESX.Notify('AMBULANCE', 'Failed to check in.', 'error', 5000)
            return
        end

        ESX.TriggerServerCallback(
            'cfx-keydi-ambulance:checkIn',
            function(success)
                if success then
                    ESX.Notify(
                        'AMBULANCE',
                        'You have been successfully treated by the hospital staff',
                        'success',
                        5000
                    )
                else
                    ESX.Notify(
                        'AMBULANCE',
                        'You should have money in your bank account.',
                        'error',
                        5000
                    )
                end
            end,
            index
        )
    end

    while GetResourceState('ox_target') ~= 'started' do
        Wait(200)
    end

    local function makeCheckInOption(index, checkIn, suffix)
        local price = checkIn.price or 1000
        local priceLabel = (ESX and ESX.Math and ESX.Math.GroupDigits and ESX.Math.GroupDigits(price)) or tostring(price)
        return {
            name = ('ems_checkin_%s_%s'):format(checkIn.job or index, suffix),
            label = ('Self Check In - $%s'):format(priceLabel),
            icon = 'fa-solid fa-hospital',
            distance = 2.5,
            onSelect = function()
                doCheckIn(index, checkIn)
            end,
        }
    end

    for i = 1, #configs.CheckIn do
        local checkIn = configs.CheckIn[i]
        local radius = (checkIn.distance and checkIn.distance.interact) or 2.0

        exports.ox_target:addSphereZone({
            coords = checkIn.coords,
            radius = math.max(radius, 1.4),
            debug = false,
            options = { makeCheckInOption(i, checkIn, 'zone') },
        })

        local ped = spawnCheckInPed(checkIn)
        if ped and DoesEntityExist(ped) then
            SetEntityCollision(ped, true, true)
            exports.ox_target:addLocalEntity(ped, { makeCheckInOption(i, checkIn, 'ped') })
        end
    end

    -- Death disables ox_target globally. Re-enable it at check-in desks so downed players can still use them.
    CreateThread(function()
        local targetingAllowed = false
        while true do
            local sleep = 1000
            local nearDesk = false
            if Vars.isDead then
                local coords = GetEntityCoords(cache.ped or PlayerPedId())
                for i = 1, #configs.CheckIn do
                    local desk = configs.CheckIn[i].coords
                    if #(coords - vector3(desk.x, desk.y, desk.z)) <= 3.0 then
                        nearDesk = true
                        break
                    end
                end
                sleep = nearDesk and 200 or 500
            end

            if nearDesk and not targetingAllowed then
                targetingAllowed = true
                pcall(function()
                    exports.ox_target:disableTargeting(false)
                end)
            elseif not nearDesk and targetingAllowed then
                targetingAllowed = false
                if Vars.isDead then
                    pcall(function()
                        exports.ox_target:disableTargeting(true)
                    end)
                end
            end

            Wait(sleep)
        end
    end)

    -- City HP Surgery NPC desks
    local surgery = configs.Surgery or {}
    for i = 1, #surgery do
        local desk = surgery[i]
        local preferred = (desk.ped and desk.ped.model) or 's_m_m_doctor_01'
        local model = requestPedModel(preferred)
        if not model then
            warn(('[kodebykarl-ambulance] surgery ped failed to load (%s)'):format(tostring(preferred)))
        else
            local ped = CreatePed(0, model, desk.coords.x, desk.coords.y, desk.coords.z - 1.0, desk.coords.w or 0.0, false, true)
            SetModelAsNoLongerNeeded(model)
            if ped and ped ~= 0 then
                SetEntityAsMissionEntity(ped, true, true)
                SetPedFleeAttributes(ped, 0, false)
                SetBlockingOfNonTemporaryEvents(ped, true)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                if desk.ped and desk.ped.scenario then
                    TaskStartScenarioInPlace(ped, desk.ped.scenario, 0, true)
                end
                exports.ox_target:addLocalEntity(ped, {
                    {
                        label = desk.label or 'Plastic Surgery',
                        icon = 'fa-solid fa-user-doctor',
                        distance = 2.5,
                        onSelect = function()
                            TriggerEvent('illenium-appearance:client:OpenSurgeonShop')
                        end,
                    }
                })
            end
        end
    end
end)


local function setTDM(bool)
    TriggerServerEvent('cfx-keydi-ambulance:setPlayerDeathStatus', bool)
    Vars.isDead = bool
end

exports('setTDM', setTDM)

local function isEmsDummyUi()
    return LocalPlayer.state.emsUiDummy == true
end

RegisterNUICallback('ems:setDeathUiMode', function(data, cb)
    local mode = data and data.mode
    if mode == 'full' or mode == 'short' then
        if isEmsDummyUi() then
            TriggerEvent('cfx-keydi-ambulance:dummy:setMode', mode)
            SendNUIMessage({ type = 'updateDeathScreen', update = 'mode', mode = mode })
        else
            setDeathUiFocus(mode)
            SendNUIMessage({ type = 'updateDeathScreen', update = 'mode', mode = mode })
        end
    end
    cb({ ok = true })
end)

RegisterNUICallback('ems:selectRespawn', function(data, cb)
    if not isEmsDummyUi() and not Vars.isDead then
        cb({ ok = false })
        return
    end
    if type(data) == 'table' and type(data.id) == 'string' then
        selectedRespawnId = data.id
        if isEmsDummyUi() then
            TriggerEvent('cfx-keydi-ambulance:dummy:select', data.id)
        end
    end
    cb({ ok = true })
end)

RegisterNUICallback('ems:sendDistress', function(_, cb)
    if isEmsDummyUi() then
        TriggerEvent('cfx-keydi-ambulance:dummy:distress')
        cb({ ok = true })
        return
    end
    if not Vars.isDead then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('cfx-keydi-ambulance:request911')
    Vars.IsDispatched = true
    SendNUIMessage({ type = 'updateDeathScreen', update = 'dispatch', dispatched = true })
    cb({ ok = true })
end)

RegisterNUICallback('ems:confirmRespawn', function(data, cb)
    if isEmsDummyUi() then
        local id = type(data) == 'table' and data.id or selectedRespawnId
        cb({ ok = true })
        TriggerEvent('cfx-keydi-ambulance:dummy:confirm', id)
        return
    end
    if not Vars.isDead then
        cb({ ok = false })
        return
    end
    if not Vars.stlUnlocked then
        ESX.Notify('AMBULANCE', 'Respawn is not ready yet.', 'error', 3000)
        cb({ ok = false })
        return
    end
    if type(data) == 'table' and type(data.id) == 'string' then
        selectedRespawnId = data.id
    end
    cb({ ok = true })
    CreateThread(function()
        client.RemoveRPDeath()
    end)
end)

exports('GetSelectedRespawnId', function()
    return selectedRespawnId
end)

local stuckCooldownUntil = 0

RegisterCommand('stuck', function()
    local now = GetGameTimer()
    if now < stuckCooldownUntil then return end
    if not Vars.isDead then return end
    if client.IsBeingMoved() then return end

    local ped = PlayerPedId()
    local coords = Vars.deathCoords or GetEntityCoords(ped)
    local x, y, z = client.SafeReviveCoords(coords.x, coords.y, coords.z, ped)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    client.StartDeathPose()
    stuckCooldownUntil = now + 30000
end)

-- 911 dispatch blip for on-duty EMS
local active911Blips = {}

RegisterNetEvent('cfx-keydi-ambulance:911Dispatch', function(data)
    if type(data) ~= 'table' or not data.coords then return end

    local dispatchCfg = configs.General.Dispatch911 or {}
    local coords = data.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, dispatchCfg.blipSprite or 153)
    SetBlipColour(blip, dispatchCfg.blipColor or 1)
    SetBlipScale(blip, dispatchCfg.blipScale or 1.1)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('911: %s [%s]'):format(data.callerName or 'Unknown', data.callerId or '?'))
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, dispatchCfg.blipColor or 1)

    active911Blips[#active911Blips + 1] = blip

    ESX.Notify(
        '911 DISPATCH',
        ('Downed civilian: %s [%s] — marked on your map.'):format(data.callerName or 'Unknown', data.callerId or '?'),
        'error',
        10000
    )
    PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', true)

    SetTimeout(dispatchCfg.blipDuration or 300000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for i = 1, #active911Blips do
        if DoesBlipExist(active911Blips[i]) then
            RemoveBlip(active911Blips[i])
        end
    end
end)
