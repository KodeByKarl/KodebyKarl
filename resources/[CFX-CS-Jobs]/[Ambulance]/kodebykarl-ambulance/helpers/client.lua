local Vars = require 'helpers.vars'
local configs = require 'shared.config'
local client = {}

local DEATH_DICT = 'dead'
local DEATH_ANIM = 'dead_a'
local deathPoseToken = 0
local deathHoldGen = 0

local function disableGtaDeathRestart()
    pcall(DisableAutomaticRespawn, true)
    pcall(SetFadeOutAfterDeath, false)
    pcall(SetFadeInAfterDeathArrest, false)
end

CreateThread(function()
    disableGtaDeathRestart()
end)

function client.StopDeathPose()
    deathPoseToken = deathPoseToken + 1
    local ped = PlayerPedId()
    NetworkSetFriendlyFireOption(true)
    if ped and ped ~= 0 and IsEntityPlayingAnim(ped, DEATH_DICT, DEATH_ANIM, 3) then
        StopAnimTask(ped, DEATH_DICT, DEATH_ANIM, 2.0)
    end
end

--- True when EMS / /buhat / /carry is moving this body. Death-hold must not
--- teleport them back to the kill spot or overwrite the carry animation.
function client.IsBeingMoved()
    local st = LocalPlayer.state
    if st.beingCarried or st.escorted then
        return true
    end
    local ped = PlayerPedId()
    return ped ~= 0 and IsEntityAttached(ped)
end

local deathAudioScene = 'CHARACTER_CHANGE_IN_SKY_SCENE'
local hearingToken = 0

--- Dead players cannot hear voice or world audio (anti-ghost).
function client.SetDeathHearing(canHear)
    hearingToken = hearingToken + 1
    local token = hearingToken

    if canHear then
        StopAudioScene(deathAudioScene)
        for _, pid in ipairs(GetActivePlayers()) do
            MumbleSetVolumeOverride(pid, -1.0)
        end
        return
    end

    if configs.General and configs.General.DeathMuteHearing == false then
        return
    end

    StartAudioScene(deathAudioScene)
    CreateThread(function()
        while token == hearingToken and Vars.isDead do
            StartAudioScene(deathAudioScene)
            for _, pid in ipairs(GetActivePlayers()) do
                if pid ~= PlayerId() then
                    MumbleSetVolumeOverride(pid, 0.0)
                end
            end
            Wait(200)
        end
    end)
end

local spawnProtectGen = 0

local function restrictCombat()
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 47, true)
    DisableControlAction(0, 58, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 257, true)
    DisableControlAction(0, 263, true)
    DisableControlAction(0, 264, true)
    DisablePlayerFiring(PlayerId(), true)
end

local function applySpawnProtectNatives(ped)
    SetEntityInvincible(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    SetPedCanBeTargetted(ped, false)
    SetEntityAlpha(ped, 180, false)
    SetEntityCanBeDamaged(ped, false)
end

function client.IsSpawnProtected()
    return LocalPlayer.state.spawnProtect == true
end

function client.StartSpawnProtection(duration)
    duration = math.max(1, tonumber(duration) or 60)
    spawnProtectGen = spawnProtectGen + 1
    local myGen = spawnProtectGen
    local endsAt = GetGameTimer() + (duration * 1000)

    LocalPlayer.state:set('spawnProtect', true, true)

    CreateThread(function()
        pcall(function()
            ESX.Notify('PROTECTION', ('Spawn protection active for %s seconds. You cannot take or deal damage.'):format(duration), 'inform', 8000)
        end)

        local lastShown = -1
        local lockedHealth, lockedArmor = nil, nil

        while myGen == spawnProtectGen and GetGameTimer() < endsAt do
            local ped = PlayerPedId()
            applySpawnProtectNatives(ped)
            restrictCombat()

            local hp = GetEntityHealth(ped)
            local armor = GetPedArmour(ped)
            if not lockedHealth then
                lockedHealth = hp >= 100 and hp or GetEntityMaxHealth(ped)
                if not lockedHealth or lockedHealth < 100 then
                    lockedHealth = 200
                end
                lockedArmor = armor or 0
                if hp < lockedHealth then
                    SetEntityHealth(ped, lockedHealth)
                end
            else
                if hp > lockedHealth then
                    lockedHealth = hp
                elseif hp < lockedHealth then
                    SetEntityHealth(ped, lockedHealth)
                end
                if armor > lockedArmor then
                    lockedArmor = armor
                elseif armor < lockedArmor then
                    SetPedArmour(ped, lockedArmor)
                end
            end

            local left = math.ceil((endsAt - GetGameTimer()) / 1000)
            if left ~= lastShown then
                lastShown = left
                lib.showTextUI(('Spawn protection: %ss'):format(left), {
                    position = 'top-center',
                    icon = 'shield-halved',
                })
            end
            Wait(0)
        end

        if myGen ~= spawnProtectGen then return end

        local ped = PlayerPedId()
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
        SetPedCanBeTargetted(ped, true)
        SetEntityCanBeDamaged(ped, true)
        ResetEntityAlpha(ped)
        LocalPlayer.state:set('spawnProtect', false, true)
        lib.hideTextUI()
        pcall(function()
            ESX.Notify('PROTECTION', 'Spawn protection ended.', 'inform', 4000)
        end)
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    StopAudioScene(deathAudioScene)
    lib.hideTextUI()
    local ped = PlayerPedId()
    if ped ~= 0 then
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
        ResetEntityAlpha(ped)
    end
end)

CreateThread(function()
    local remoteProtect = {}
    while true do
        local sleep = 400
        local players = GetActivePlayers()
        local seen = {}
        for i = 1, #players do
            local ply = players[i]
            if ply ~= PlayerId() then
                local sid = GetPlayerServerId(ply)
                local protected = Player(sid).state.spawnProtect
                local ped = GetPlayerPed(ply)
                if ped ~= 0 and DoesEntityExist(ped) then
                    if protected then
                        sleep = 0
                        seen[sid] = true
                        remoteProtect[sid] = true
                        SetEntityCanBeDamaged(ped, false)
                        SetEntityAlpha(ped, 180, false)
                        SetPedCanBeTargetted(ped, false)
                    elseif remoteProtect[sid] then
                        seen[sid] = true
                        ResetEntityAlpha(ped)
                        SetEntityCanBeDamaged(ped, true)
                        SetPedCanBeTargetted(ped, true)
                        remoteProtect[sid] = nil
                    end
                end
            end
        end
        for sid in pairs(remoteProtect) do
            if not seen[sid] then
                remoteProtect[sid] = nil
            end
        end
        Wait(sleep)
    end
end)

--- Keep the ped lying down while dead. Reconnect/spawn/appearance often
--- resurrects them standing even though the death timer is still running.
function client.StartDeathPose()
    deathPoseToken = deathPoseToken + 1
    local token = deathPoseToken

    CreateThread(function()
        pcall(function()
            lib.requestAnimDict(DEATH_DICT)
        end)

        while token == deathPoseToken and Vars.isDead and not Vars.isReviving do
            if client.IsBeingMoved() then
                Wait(400)
            else
                local ped = PlayerPedId()
                if ped and ped ~= 0 and DoesEntityExist(ped) then
                    local nativelyDead = IsPedFatallyInjured(ped) or IsEntityDead(ped) or GetEntityHealth(ped) <= 101

                    if nativelyDead then
                        if not IsPedRagdoll(ped) then
                            SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
                        end
                    else
                        SetPedCanRagdoll(ped, false)
                        NetworkSetFriendlyFireOption(false)
                        if not IsEntityPlayingAnim(ped, DEATH_DICT, DEATH_ANIM, 3) then
                            TaskPlayAnim(ped, DEATH_DICT, DEATH_ANIM, 8.0, 8.0, -1, 1, 0.0, false, false, false)
                        end
                    end
                end
                Wait(400)
            end
        end

        local ped = PlayerPedId()
        if ped and ped ~= 0 and IsEntityPlayingAnim(ped, DEATH_DICT, DEATH_ANIM, 3) then
            StopAnimTask(ped, DEATH_DICT, DEATH_ANIM, 2.0)
        end
    end)
end

--- Keep the body at the death spot. GTA otherwise hospital-respawns to campus (lapagan).
--- While /buhat or /carry is moving them, stay RP-dead in place — do not snap back.
function client.HoldDeathInPlace()
    if Vars.isReviving then return end
    disableGtaDeathRestart()

    local ped = PlayerPedId()
    local beingMoved = client.IsBeingMoved()
    local coords = Vars.deathCoords
    if not coords and ped and ped ~= 0 then
        coords = GetEntityCoords(ped)
        Vars.deathCoords = coords
    end
    if not coords and not beingMoved then return end

    Vars.holdingDeath = true
    local heading = (ped and ped ~= 0) and GetEntityHeading(ped) or 0.0
    local x, y, z
    if beingMoved and ped and ped ~= 0 then
        local here = GetEntityCoords(ped)
        x, y, z = here.x, here.y, here.z
        heading = GetEntityHeading(ped)
    else
        x, y, z = coords.x or coords[1], coords.y or coords[2], coords.z or coords[3]
    end

    if ped and ped ~= 0 and (IsPedFatallyInjured(ped) or IsEntityDead(ped) or GetEntityHealth(ped) <= 101) then
        NetworkResurrectLocalPlayer(x, y, z, heading, true, false)
        Wait(0)
        ped = PlayerPedId()
    end

    ped = PlayerPedId()
    if ped and ped ~= 0 then
        if not beingMoved and not client.IsBeingMoved() then
            SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
            SetEntityHeading(ped, heading)
        end
        local maxHealth = GetEntityMaxHealth(ped)
        if not maxHealth or maxHealth < 100 then
            maxHealth = 200
        end
        SetEntityHealth(ped, maxHealth)
        SetEntityInvincible(ped, true)
        SetPlayerInvincible(PlayerId(), true)
        SetPedCanRagdoll(ped, false)
    end

    if ESX and ESX.SetPlayerData then
        ESX.SetPlayerData('dead', true)
    end
    LocalPlayer.state:set('dead', true, true)
    Vars.holdingDeath = false
    if not client.IsBeingMoved() then
        client.StartDeathPose()
    end
end

function client.StartDeathHoldWatch()
    deathHoldGen = deathHoldGen + 1
    local gen = deathHoldGen
    local token = Vars.deathToken

    CreateThread(function()
        client.HoldDeathInPlace()
        while gen == deathHoldGen and token == Vars.deathToken and Vars.isDead and not Vars.isReviving do
            disableGtaDeathRestart()
            local ped = PlayerPedId()
            local deathAt = Vars.deathCoords
            if ped and ped ~= 0 and deathAt then
                local now = GetEntityCoords(ped)
                local dest = vector3(deathAt.x or deathAt[1], deathAt.y or deathAt[2], deathAt.z or deathAt[3])
                local nativelyDead = IsPedFatallyInjured(ped) or IsEntityDead(ped) or GetEntityHealth(ped) <= 101
                local beingMoved = client.IsBeingMoved()
                -- Carried bodies travel far from the kill spot on purpose.
                if beingMoved then
                    if nativelyDead then
                        client.HoldDeathInPlace()
                    end
                elseif #(now - dest) > 25.0 or nativelyDead then
                    client.HoldDeathInPlace()
                end
            end
            Wait(400)
        end
    end)
end

function client.StopDeathHold()
    deathHoldGen = deathHoldGen + 1
    Vars.holdingDeath = false
end

--- After /buhat or /carry drops the body, keep them where they were put down.
AddStateBagChangeHandler('beingCarried', nil, function(bagName, _, value)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply ~= PlayerId() then return end
    if value then return end
    if not Vars.isDead or Vars.isReviving then return end
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    Vars.deathCoords = GetEntityCoords(ped)
    client.StartDeathPose()
end)

AddEventHandler('playerSpawned', function()
    if Vars.isReviving then return end
    if client.IsBeingMoved() then return end
    if Vars.holdingDeath or Vars.isDead then
        if ESX and ESX.SetPlayerData then
            ESX.SetPlayerData('dead', true)
        end
        if not Vars.holdingDeath then
            client.HoldDeathInPlace()
        end
    end
end)

--- After NetworkResurrectLocalPlayer, unmute and rebind proximity.
--- Spawn events also reinit; a later call is OK (token-based, latest wins).
local function resetVoiceAfterRespawn()
    CreateThread(function()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)

        if Vars.isDead then return end
        TriggerServerEvent('cfx-keydi-ambulance:ensureVoiceUnmute')

        Wait(500)
        if Vars.isDead then return end
        TriggerServerEvent('cfx-keydi-ambulance:ensureVoiceUnmute')
        client.SetDeathHearing(true)
        if GetResourceState('pma-voice') == 'started' then
            pcall(function()
                exports['pma-voice']:reinitVoice('ambulance-respawn')
            end)
        end

        Wait(1500)
        if Vars.isDead then return end
        TriggerServerEvent('cfx-keydi-ambulance:ensureVoiceUnmute')
    end)
end

local function applyStlRecovery()
    local stl = configs.General and configs.General.STLRecovery
    if not stl or not stl.total then return end
    TriggerEvent('cfx-keydi-ambulance:SetRecoveryState', stl.total, stl.crutch or 0)
end

function client.GetUiResource()
    if GetResourceState('kodebykarl-ui') == 'started' then
        return 'kodebykarl-ui'
    end
    return nil
end

function client.RemoveRPDeath(customCoords)
    client.HideNUI()
    local ui = client.GetUiResource()
    if ui then
        pcall(function()
            exports[ui]:ForceCloseSpawnMenu()
        end)
    end
    CreateThread(function()
        local function doRespawn()
            TriggerServerEvent('cfx-keydi-ambulance:payFine', Vars.DiedInPaleto() and 'pambulance' or (Vars.DiedInBlaine() and 'sambulance' or 'ambulance'))
            TriggerServerEvent('cfx-keydi-ambulance:setPlayerDeathStatus', false)

            local spawnCoords = customCoords
            if not spawnCoords then
                spawnCoords = exports[GetCurrentResourceName()]:SelectRespawn()
            end
            ESX.SetPlayerData('loadout', {})
            DoScreenFadeOut(800)
            local fadeTimeout = GetGameTimer() + 5000
            while not IsScreenFadedOut() and GetGameTimer() < fadeTimeout do
                Wait(0)
            end

            local ok, err = pcall(function()
                if type(spawnCoords) == 'table' then
                    local heading = spawnCoords.heading or spawnCoords.w or 0.0
                    client.RespawnPed(cache.ped, vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z), heading)
                elseif spawnCoords and spawnCoords.xyz then
                    client.RespawnPed(cache.ped, spawnCoords.xyz, spawnCoords.w or 0.0)
                else
                    local spawn = require 'shared.spawn'
                    local zoneId = Vars.SelectStlZone()
                    local loc = spawn.Locations[zoneId] or spawn.Locations.integrity_way or spawn.Locations.murrieta
                    local c = loc.coords
                    client.RespawnPed(cache.ped, vector3(c.x, c.y, c.z), c.w or 0.0)
                end
            end)
            if not ok then
                print(('[cfx-keydi-ambulance] RespawnPed failed during RemoveRPDeath: %s'):format(tostring(err)))
                Vars.isReviving = false
                LocalPlayer.state:set('isReviving', false, false)
            end

            applyStlRecovery()
            DoScreenFadeIn(800)
        end

        ESX.TriggerServerCallback('cfx-keydi-ambulance:removeItems', function(set)
            if not set then
                ESX.Notify('AMBULANCE', 'Respawn failed to clear inventory — respawning anyway.', 'warning', 5000)
            end
            doRespawn()
        end)
    end)
end

function RespawnAtLocation(coords)
    TriggerServerEvent('cfx-keydi-ambulance:payFine', Vars.DiedInPaleto() and 'pambulance' or (Vars.DiedInBlaine() and 'sambulance' or 'ambulance'))
    client.RemoveRPDeath(coords)
end

exports('RespawnAtLocation', RespawnAtLocation)

local function isDead()
    return Vars.isDead == true
end

exports('isDead', isDead)
exports('IsSpawnProtected', client.IsSpawnProtected)

--- Keep the exact death/revive Z. GetGroundZ from +50 hits building roofs
--- and ejects players who died inside a house. Only snap if they are clearly
--- under the world mesh (void), never for interiors / nearby floors.
function client.SafeReviveCoords(x, y, z, ped)
    x, y, z = (x or 0.0) + 0.0, (y or 0.0) + 0.0, (z or 0.0) + 0.0
    RequestCollisionAtCoord(x, y, z)

    local interior = 0
    if ped and DoesEntityExist(ped) then
        interior = GetInteriorFromEntity(ped)
    end
    if interior == 0 then
        interior = GetInteriorAtCoords(x, y, z)
    end
    if interior ~= 0 then
        return x, y, z
    end

    -- Local floor only (1m above current Z). A high probe finds the roof.
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 1.0, false)
    if found and groundZ and groundZ > 0.0 then
        local below = groundZ - z
        if below > 0.15 and below < 2.5 then
            return x, y, groundZ + 0.05
        end
        return x, y, z
    end

    -- No local floor: last-resort void check. Must be far below world mesh.
    found, groundZ = GetGroundZFor_3dCoord(x, y, z + 100.0, false)
    if found and groundZ and z < (groundZ - 20.0) then
        return x, y, groundZ + 0.1
    end

    return x, y, z
end

function client.RespawnPed(ped, coords, heading)
    TriggerScreenblurFadeOut(0)
    client.blurOut()

    local x = (coords.x or coords[1]) + 0.0
    local y = (coords.y or coords[2]) + 0.0
    local z = (coords.z or coords[3]) + 0.0
    heading = heading or 0.0

    -- Block death re-entry while we resurrect (esx death monitor + death-hold race)
    client.StopDeathHold()
    client.StopDeathPose()
    Vars.isReviving = true
    Vars.isDead = false
    Vars.deathInSandy = false
    Vars.deathCoords = nil
    Vars.deathToken = (Vars.deathToken or 0) + 1
    LocalPlayer.state:set('isReviving', true, false)

    ped = PlayerPedId()

    if IsEntityAttached(ped) then
        DetachEntity(ped, true, false)
    end

    ClampGameplayCamPitch(-90.0, 90.0)
    RenderScriptCams(false, false, 0, true, true)

    -- Collision off + freeze until coords are locked (GTA ejects interiors to the roof)
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    NetworkSetEntityInvisibleToNetwork(ped, false)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetPedCanRagdoll(ped, false)
    SetPlayerControl(PlayerId(), true, 0)
    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)

    x, y, z = client.SafeReviveCoords(x, y, z, ped)
    RequestCollisionAtCoord(x, y, z)

    local timeout = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        RequestCollisionAtCoord(x, y, z)
        Wait(0)
    end
    x, y, z = client.SafeReviveCoords(x, y, z, ped)

    local function placeAtExactCoords(p)
        SetEntityCollision(p, false, false)
        FreezeEntityPosition(p, true)
        SetEntityCoordsNoOffset(p, x, y, z, false, false, false)
        SetEntityHeading(p, heading)
    end

    placeAtExactCoords(ped)
    NetworkResurrectLocalPlayer(x, y, z, heading, true, false)
    TriggerServerEvent('cfx-keydi-serverlocations:server:restoreBucket')
    pcall(NetworkSetVoiceActive, true)
    Wait(300)
    ped = PlayerPedId()
    placeAtExactCoords(ped)

    if IsPedDeadOrDying(ped, true) or IsPedFatallyInjured(ped) or IsEntityDead(ped) then
        pcall(ResurrectPed, ped)
        Wait(0)
        ped = PlayerPedId()
        NetworkResurrectLocalPlayer(x, y, z, heading, true, false)
        Wait(0)
        ped = PlayerPedId()
        placeAtExactCoords(ped)
    end

    local maxHealth = 200
    SetPedMaxHealth(ped, maxHealth)
    SetEntityMaxHealth(ped, maxHealth)
    SetEntityHealth(ped, maxHealth)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    NetworkSetFriendlyFireOption(true)
    SetPedCanBeTargetted(ped, true)
    if LocalPlayer.state.spawnProtect then
        applySpawnProtectNatives(ped)
    end

    -- Force upright at the exact revive coords (no Z lift — that ejects interiors)
    ClearPedTasksImmediately(ped)
    SetEntityRotation(ped, 0.0, 0.0, heading, 2, true)
    SetEntityHeading(ped, heading)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    Wait(50)
    ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    ResetPedMovementClipset(ped, 0.0)
    ResetPedWeaponMovementClipset(ped)
    ResetPedStrafeClipset(ped)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, heading)

    -- Restore saved walk style after revive clipset reset
    if GetResourceState('scully_emotemenu') == 'started' then
        local ok, walk = pcall(function()
            return exports['scully_emotemenu']:getCurrentWalk()
        end)
        if ok and walk and walk ~= '' and walk ~= 'default' then
            pcall(function()
                exports['scully_emotemenu']:setWalk(walk)
            end)
        end
    end

    SetEntityVisible(ped, true, false)
    if LocalPlayer.state.spawnProtect then
        applySpawnProtectNatives(ped)
    else
        ResetEntityAlpha(ped)
    end
    NetworkSetEntityInvisibleToNetwork(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, heading)
    Wait(0)
    ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    FreezeEntityPosition(ped, false)
    SetPlayerControl(PlayerId(), true, 0)

    -- Wait until engine no longer reports dead/dying before starting death monitor
    local aliveTimeout = GetGameTimer() + 2000
    while GetGameTimer() < aliveTimeout do
        ped = PlayerPedId()
        if not IsPedFatallyInjured(ped) and not IsPedDeadOrDying(ped, true) and not IsEntityDead(ped) then
            break
        end
        NetworkResurrectLocalPlayer(x, y, z, heading, true, false)
        Wait(0)
        ped = PlayerPedId()
        SetEntityHealth(ped, maxHealth)
        ClearPedTasksImmediately(ped)
        SetEntityVisible(ped, true, false)
        placeAtExactCoords(ped)
        Wait(50)
    end

    ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, heading)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)

    -- Resurrect can snap the ped back to Michael. Re-apply saved appearance with a hard timeout
    -- so a hung callback / model stream cannot leave the player on a black screen forever.
    if GetResourceState('illenium-appearance') == 'started' then
        Wait(200)
        local appearance, appearanceDone = nil, false
        CreateThread(function()
            local ok, result = pcall(function()
                return lib.callback.await('illenium-appearance:server:getAppearance', false)
            end)
            if ok then
                appearance = result
            end
            appearanceDone = true
        end)

        local appearanceDeadline = GetGameTimer() + 4000
        while not appearanceDone and GetGameTimer() < appearanceDeadline do
            Wait(0)
        end

        if appearance then
            local applyDone = false
            CreateThread(function()
                pcall(function()
                    exports['illenium-appearance']:setPlayerAppearance(appearance)
                end)
                applyDone = true
            end)

            local applyDeadline = GetGameTimer() + 5000
            while not applyDone and GetGameTimer() < applyDeadline do
                Wait(0)
            end
            if not applyDone then
                print('[cfx-keydi-ambulance] setPlayerAppearance timed out during RespawnPed; scheduling reloadSkin')
                CreateThread(function()
                    Wait(500)
                    TriggerEvent('illenium-appearance:client:reloadSkin', true)
                end)
            else
                Wait(150)
            end
        elseif not appearanceDone then
            print('[cfx-keydi-ambulance] getAppearance timed out during RespawnPed; scheduling reloadSkin')
            CreateThread(function()
                Wait(500)
                TriggerEvent('illenium-appearance:client:reloadSkin', true)
            end)
        end

        ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
        SetEntityHeading(ped, heading)
        SetPedMaxHealth(ped, 200)
        SetEntityMaxHealth(ped, 200)
        SetEntityHealth(ped, 200)
    end

    LocalPlayer.state:set('dead', false, true)
    LocalPlayer.state:set('invBusy', false, true)
    LocalPlayer.state:set('invOpen', false, false)
    if ESX and ESX.SetPlayerData then
        ESX.SetPlayerData('dead', false)
    end
    if lib.progressActive and lib.progressActive() then
        lib.cancelProgress()
    end

    TriggerEvent('esx_basicneeds:resetStatus')
    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')
    TriggerEvent('playerSpawned')
    TriggerServerEvent('cfx-keydi-serverlocations:server:restoreBucket')
    exports.ox_target:disableTargeting(false)

    -- Mic/voice often dies across NetworkResurrectLocalPlayer; reset after ped is alive
    client.SetDeathHearing(true)
    resetVoiceAfterRespawn()

    -- Keep guarding against death re-entry + force visible/standing for a short window
    CreateThread(function()
        for _ = 1, 30 do
            local p = PlayerPedId()
            SetEntityVisible(p, true, false)
            SetPedMaxHealth(p, 200)
            SetEntityMaxHealth(p, 200)
            SetEntityHealth(p, 200)
            if LocalPlayer.state.spawnProtect then
                applySpawnProtectNatives(p)
            else
                ResetEntityAlpha(p)
            end
            NetworkSetEntityInvisibleToNetwork(p, false)
            SetEntityCollision(p, true, true)
            if IsEntityPositionFrozen(p) then
                FreezeEntityPosition(p, false)
            end
            if IsPedRagdoll(p) then
                SetPedCanRagdoll(p, false)
                ClearPedTasksImmediately(p)
            end
            SetPlayerControl(PlayerId(), true, 0)
            Wait(100)
        end
        local p = PlayerPedId()
        SetPedMaxHealth(p, 200)
        SetEntityMaxHealth(p, 200)
        SetEntityHealth(p, 200)
        SetPedCanRagdoll(p, true)
        Vars.isReviving = false
        LocalPlayer.state:set('isReviving', false, false)
        if ESX and ESX.SetPlayerData then
            ESX.SetPlayerData('dead', false)
        end
        LocalPlayer.state:set('dead', false, true)
        -- Final unmute after revive guard ends (covers late mumble reconnect)
        if not Vars.isDead then
            TriggerServerEvent('cfx-keydi-ambulance:ensureVoiceUnmute')
        end
    end)
end


CreateThread(function()
	lib.zones.poly({
		points = {
			vec(4759.09, 1546.97, 0),
			vec(-5071.21, 1425.76, 0),
			vec(-4986.36, 8904.55, 0),
			vec(4795.45, 8868.18, 0)
		},
		thickness = 3000,
		debug = false,
		onEnter = function()
            Vars.inSandy = true
        end,
		onExit = function()
            Vars.inSandy = false
        end
	})
end)

local function inProvince()
    return Vars.inSandy
end

exports('inProvince', inProvince)

function client.HideNUI()
    pcall(function()
        require('helpers.deathcam').Stop()
    end)
    client.blurOut()
	Vars.IsDispatched = false
    if GetResourceState('rryban_priority') == 'started' then
        pcall(function()
            local isVisible = exports['rryban_priority']:GetUIState()
            if not isVisible then
                exports['rryban_priority']:HideUI(true)
            end
        end)
    end
    if GetResourceState('jg-hud') == 'started' then
        pcall(function()
            exports['jg-hud']:toggleHud(true)
        end)
    end
	SendNUIMessage({type = 'HideUI' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

function client.blurIn()
    -- Screen blur disabled
end

function client.blurOut()
    if IsScreenblurFadeRunning() then
        DisableScreenblurFade()
    end
    TriggerScreenblurFadeOut(0)
end


return client