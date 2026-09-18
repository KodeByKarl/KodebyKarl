--[[
    cfx-keydi-deathscreen (client)
    PvP death UI: killer profile | killer ped (camera) | combat recap
]]

if not ConfigDeathScreen or not ConfigDeathScreen.Enabled then return end

local ESX = exports["es_extended"]:getSharedObject()

local isVisible = false
local isOpening = false
local holdWhileAlive = false -- /testdeathscreen preview while alive
local clonePed = nil
local deathCam = nil
local displayToken = 0
local lastAttackerPed = 0
local lastAttackerSid = 0

--- Prefer framework / ambulance death flags. Ped natives alone can false-positive
--- during spawn / SetPlayerModel, so they are only used as a last resort when
--- the player is already loaded and not reviving.
local function isActuallyDead()
    if LocalPlayer.state and LocalPlayer.state.isReviving then
        return false
    end
    if GetResourceState('kodebykarl-ambulance') == 'started' then
        local ok, dead = pcall(function()
            return exports['kodebykarl-ambulance']:isDead()
        end)
        if ok and dead == true then
            return true
        end
        -- Ambulance started but not dead yet — keep checking other sources below
    end
    if ESX then
        local pd = (ESX.GetPlayerData and ESX.GetPlayerData()) or ESX.PlayerData
        if pd and pd.dead == true then
            return true
        end
    end
    if LocalPlayer.state and LocalPlayer.state.dead == true then
        return true
    end
    -- Fallback: ped is down and character is loaded (covers delayed ESX dead flag)
    if ESX and ESX.PlayerLoaded then
        local ped = PlayerPedId()
        if ped and ped ~= 0 and (IsPedDeadOrDying(ped, true) or IsPedFatallyInjured(ped) or IsEntityDead(ped)) then
            return true
        end
    end
    return false
end

--- Wait until death is confirmed (ESX / ambulance often lag gameEvent by a few hundred ms).
local function waitUntilDead(timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 2000)
    while GetGameTimer() < deadline do
        if isActuallyDead() then
            return true
        end
        Wait(50)
    end
    return isActuallyDead()
end

-- Engagement tracking vs other players
-- [serverId] = { dealt = number, received = number, zones = { head=n, neck=n, ... }, lastBone = number, headshot = bool }
local engagement = {}
local localHealth = 200
local localArmor = 0
local lastHitZones = { head = 0, neck = 0, torso = 0, arm = 0, leg = 0 }
local lastBone = -1
local wasHeadshot = false
local lastRecap = nil

local ZONE_LABELS = {
    head = "Head",
    neck = "Neck",
    torso = "Upper Torso",
    arm = "Arms",
    leg = "Legs",
}

local function resolveBoneZone(boneId)
    boneId = tonumber(boneId) or -1
    if boneId < 0 then return "torso", false end
    if DeathScreenBones and DeathScreenBones.ZoneFromBone then
        local zone = DeathScreenBones.ZoneFromBone(boneId)
        if zone == "arms" then zone = "arm" end
        if zone == "legs" then zone = "leg" end
        return zone, zone == "head"
    end
    local zones = ConfigDeathScreen.BoneZones or {}
    local heads = ConfigDeathScreen.HeadBones or {}
    local zone = zones[boneId]
    local isHead = heads[boneId] == true or zone == "head"
    if isHead then
        return "head", true
    end
    if zone then
        return zone, false
    end
    return "torso", false
end

local function normalizeBoneId(ped, bone)
    bone = tonumber(bone) or -1
    if bone < 0 then return bone end
    -- GetPedLastDamageBone may return a bone INDEX; GetPedBoneCoords / zone maps use bone IDs
    local indexToId = {
        [97] = 39317, [98] = 31086, [99] = 12844, [102] = 65068,
        [103] = 58331, [104] = 45750, [105] = 25260, [106] = 21550,
        [107] = 29868, [108] = 43536, [109] = 27474, [110] = 19336,
        [111] = 1356, [112] = 11174, [113] = 37193, [114] = 20178,
        [115] = 61839, [116] = 20279, [117] = 17719, [118] = 46240,
        [119] = 17188, [120] = 20623, [121] = 47419, [122] = 49979,
        [123] = 47495, [124] = 35731, [125] = 64654,
    }
    if indexToId[bone] then
        return indexToId[bone]
    end
    local zones = ConfigDeathScreen.BoneZones or {}
    local heads = ConfigDeathScreen.HeadBones or {}
    if zones[bone] or heads[bone] then return bone end
    if ped and ped ~= 0 then
        for tag in pairs(zones) do
            if tag > 200 and GetPedBoneIndex(ped, tag) == bone then
                return tag
            end
        end
    end
    return bone
end

local function zoneDisplayName(zone)
    return ZONE_LABELS[zone] or "Unknown"
end

local function pickFatalZone(eng, isSuicide)
    if isSuicide then return "Self" end
    local bone = (eng and eng.lastBone) or lastBone
    if bone and bone >= 0 then
        local zone = resolveBoneZone(bone)
        return zoneDisplayName(zone)
    end
    local zones = (eng and eng.zones) or lastHitZones
    local best, bestN = "torso", -1
    if type(zones) == "table" then
        for z, n in pairs(zones) do
            local count = tonumber(n) or 0
            if count > bestN then
                best, bestN = z, count
            end
        end
    end
    if bestN <= 0 then
        if wasHeadshot or (eng and eng.headshot) then return "Head" end
        return "Unknown"
    end
    return zoneDisplayName(best)
end

local function registerReceivedHit(sid, boneId)
    local zone, isHead = resolveBoneZone(boneId)
    engagement[sid] = engagement[sid] or { dealt = 0, received = 0, zones = {}, lastBone = -1, headshot = false }
    local eng = engagement[sid]
    eng.zones = eng.zones or {}
    eng.zones[zone] = (eng.zones[zone] or 0) + 1
    eng.lastBone = boneId
    if isHead then
        eng.headshot = true
    end
    lastHitZones = {
        head = eng.zones.head or 0,
        neck = eng.zones.neck or 0,
        torso = eng.zones.torso or 0,
        arm = eng.zones.arm or 0,
        leg = eng.zones.leg or 0,
    }
    lastBone = boneId
    wasHeadshot = eng.headshot == true
end

local function healthPercent(ped)
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    if health <= 100 then return 0 end
    if maxHealth > 100 then
        return math.max(0, math.min(100, math.floor(((health - 100) / (maxHealth - 100)) * 100)))
    end
    return math.max(0, math.min(100, math.floor((health / maxHealth) * 100)))
end

local function weaponLabel(hash)
    if not hash or hash == 0 then return "Unknown" end
    local mapped = ConfigDeathScreen.Weapons[hash]
    if mapped then return mapped end
    local name = GetWeaponNameFromHash and GetWeaponNameFromHash(hash)
    if name and name ~= "" then return name end
    return "Unknown"
end

local function destroyPreview()
    if deathCam and DoesCamExist(deathCam) then
        RenderScriptCams(false, true, 400, true, true)
        DestroyCam(deathCam, false)
        deathCam = nil
    end
    if clonePed and DoesEntityExist(clonePed) then
        DeleteEntity(clonePed)
        clonePed = nil
    end
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        ResetEntityAlpha(ped)
        SetEntityVisible(ped, true, false)
        pcall(function()
            SetEntityLocallyVisible(ped)
        end)
    end
end

local function hideDeathScreen()
    isOpening = false
    holdWhileAlive = false
    displayToken = displayToken + 1
    if not isVisible then
        destroyPreview()
        SendNUIMessage({ action = "deathscreen:hide" })
        return
    end
    isVisible = false
    destroyPreview()
    SendNUIMessage({ action = "deathscreen:hide" })
end

local function standAnims(_)
    return "amb@world_human_stand_guard@male@base", "base"
end

local function forceCloneStanding(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    local maxH = GetEntityMaxHealth(ped)
    if not maxH or maxH < 100 then
        maxH = 200
        SetEntityMaxHealth(ped, maxH)
    end

    if IsPedDeadOrDying(ped, true) or IsEntityDead(ped) or GetEntityHealth(ped) <= 100 then
        pcall(ResurrectPed, ped)
        pcall(ReviveInjuredPed, ped)
        SetEntityHealth(ped, maxH)
    end

    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedRagdollOnCollision(ped, false)
    ResetPedRagdollTimer(ped)
    SetPedConfigFlag(ped, 166, false)
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    SetEntityRotation(ped, 0.0, 0.0, GetEntityHeading(ped), 2, true)
end

local function resolveKillerPed(serverId, fallbackPed)
    if fallbackPed and fallbackPed ~= 0 and DoesEntityExist(fallbackPed) then
        return fallbackPed
    end
    if lastAttackerSid == serverId and lastAttackerPed and lastAttackerPed ~= 0 and DoesEntityExist(lastAttackerPed) then
        return lastAttackerPed
    end
    if not serverId or serverId <= 0 then return 0 end

    for _ = 1, 15 do
        local player = GetPlayerFromServerId(serverId)
        if player and player ~= -1 then
            local ped = GetPlayerPed(player)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                return ped
            end
        end
        Wait(40)
    end
    return 0
end

local function getTopEngagementSid()
    local bestSid, bestDmg = nil, 0
    for sid, eng in pairs(engagement) do
        local rec = tonumber(eng.received) or 0
        if rec > bestDmg then
            bestDmg, bestSid = rec, sid
        end
    end
    return bestSid
end

local function startPreviewHold(token)
    CreateThread(function()
        while displayToken == token and clonePed and DoesEntityExist(clonePed) do
            SetEntityLocallyInvisible(PlayerPedId())
            Wait(0)
        end
    end)

    CreateThread(function()
        while displayToken == token and clonePed and DoesEntityExist(clonePed) do
            if IsPedDeadOrDying(clonePed, true) or IsEntityDead(clonePed) or GetEntityHealth(clonePed) <= 100 then
                forceCloneStanding(clonePed)
            else
                SetPedCanRagdoll(clonePed, false)
                ResetPedRagdollTimer(clonePed)
            end
            local dict, clip = standAnims(clonePed)
            if not IsEntityPlayingAnim(clonePed, dict, clip, 3) then
                TaskPlayAnim(clonePed, dict, clip, 8.0, 8.0, -1, 1, 0.0, false, false, false)
            end
            FreezeEntityPosition(clonePed, true)
            Wait(400)
        end
    end)
end

local function spawnKillerPreview(killerPed)
    destroyPreview()
    if not killerPed or killerPed == 0 or not DoesEntityExist(killerPed) then
        return false
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(killerPed)
    if heading == 0.0 then
        heading = GetEntityHeading(playerPed)
    end

    -- Place clone in front of the dead player so the center NUI gap frames them
    local rad = math.rad(heading)
    local spawnX = coords.x - math.sin(rad) * 1.35
    local spawnY = coords.y + math.cos(rad) * 1.35
    local spawnZ = coords.z

    -- Detect true ground elevation so ped feet stand on the road surface rather than sinking
    local foundGround, gZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 2.5, false)
    if not foundGround then
        foundGround, gZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 15.0, false)
    end
    if foundGround then
        spawnZ = gZ + 0.98 -- GTA V ped root origin sits ~0.98m above bottom of feet
    else
        spawnZ = spawnZ + 0.92
    end

    -- Create a living ped, then copy the killer's appearance.
    -- ClonePed() from a dead/ragdolled source stays lying down and cannot play idle.
    local model = GetEntityModel(killerPed)
    if not model or model == 0 then return false end

    lib.requestModel(model, 3000)
    clonePed = CreatePed(4, model, spawnX, spawnY, spawnZ, heading, false, true)
    SetModelAsNoLongerNeeded(model)

    if not clonePed or clonePed == 0 or not DoesEntityExist(clonePed) then
        clonePed = ClonePed(killerPed, false, false, true)
    end
    if not clonePed or clonePed == 0 or not DoesEntityExist(clonePed) then
        return false
    end

    SetEntityAsMissionEntity(clonePed, true, true)
    SetEntityVisible(clonePed, false, false)
    pcall(ClonePedToTarget, killerPed, clonePed)

    SetEntityCoordsNoOffset(clonePed, spawnX, spawnY, spawnZ, false, false, false)
    SetEntityHeading(clonePed, heading)
    SetEntityInvincible(clonePed, true)
    SetBlockingOfNonTemporaryEvents(clonePed, true)
    SetEntityCollision(clonePed, false, false)
    FreezeEntityPosition(clonePed, true)
    forceCloneStanding(clonePed)

    local dict, clip = standAnims(clonePed)
    lib.requestAnimDict(dict, 3000)
    TaskPlayAnim(clonePed, dict, clip, 8.0, 8.0, -1, 1, 0.0, false, false, false)
    Wait(50)
    forceCloneStanding(clonePed)
    TaskPlayAnim(clonePed, dict, clip, 8.0, 8.0, -1, 1, 0.0, false, false, false)

    SetEntityVisible(clonePed, true, false)
    ResetEntityAlpha(clonePed)

    local camCfg = ConfigDeathScreen.Cam or {}
    local offset = camCfg.offset or vector3(0.0, 4.6, 1.15)
    local pointOffset = camCfg.pointOffset or vector3(0.0, 0.0, 0.05)

    local camCoords = GetOffsetFromEntityInWorldCoords(clonePed, offset.x, offset.y, offset.z)
    local lookAt = GetOffsetFromEntityInWorldCoords(clonePed, pointOffset.x, pointOffset.y, pointOffset.z)

    deathCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(deathCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(deathCam, lookAt.x, lookAt.y, lookAt.z)
    SetCamFov(deathCam, camCfg.fov or 48.0)
    SetCamActive(deathCam, true)
    RenderScriptCams(true, true, 500, true, true)

    startPreviewHold(displayToken)
    return true
end

local function showDeathScreen(payload)
    isVisible = true
    SendNUIMessage({
        action = "deathscreen:show",
        data = payload,
    })
end

local function buildLocalCombat(killerServerId, killerPed, isSuicide)
    local playerPed = PlayerPedId()
    local eng = engagement[killerServerId] or { dealt = 0, received = 0 }

    local weaponHash = GetPedCauseOfDeath(playerPed)
    if (not weaponHash or weaponHash == 0 or weaponHash == `WEAPON_FALL` or weaponHash == `WEAPON_DROWNING` or weaponHash == `WEAPON_RUN_OVER_BY_CAR`)
        and not isSuicide and killerPed and DoesEntityExist(killerPed) then
        weaponHash = GetSelectedPedWeapon(killerPed)
    end
    if (not weaponHash or weaponHash == 0) and killerPed and DoesEntityExist(killerPed) then
        weaponHash = GetSelectedPedWeapon(killerPed)
    end

    local distance = 0.0
    if not isSuicide and killerPed and DoesEntityExist(killerPed) then
        local raw = #(GetEntityCoords(playerPed) - GetEntityCoords(killerPed))
        distance = math.floor(raw * 10 + 0.5) / 10
    end

    local dealt = math.floor(eng.dealt or 0)
    local received = math.floor(eng.received or 0)

    if isSuicide then
        -- Self damage only
        if received <= 0 then
            received = math.max(0, localHealth - 100)
            if received <= 0 then received = 100 end
        end
        dealt = 0
    elseif received <= 0 then
        received = math.max(received, 100)
    end

    local total = dealt + received
    local outPct = total > 0 and math.floor((dealt / total) * 100 + 0.5) or 0
    local inPct = 100 - outPct

    return {
        weapon = weaponLabel(weaponHash),
        weaponHash = weaponHash,
        distance = distance,
        damageDealt = dealt,
        damageReceived = received,
        damageOutPercent = outPct,
        damageInPercent = inPct,
        headshot = isSuicide and false or (eng.headshot == true or wasHeadshot),
        fatalBone = eng.lastBone or lastBone,
        fatalZone = pickFatalZone(eng, isSuicide),
        hitZones = {
            head = (eng.zones and eng.zones.head) or lastHitZones.head or 0,
            neck = (eng.zones and eng.zones.neck) or lastHitZones.neck or 0,
            torso = (eng.zones and eng.zones.torso) or lastHitZones.torso or 0,
            arm = (eng.zones and eng.zones.arm) or lastHitZones.arm or 0,
            leg = (eng.zones and eng.zones.leg) or lastHitZones.leg or 0,
        },
    }
end

local function openForKiller(killerServerId, killerPed, isSuicide)
    if isVisible or isOpening then return end
    if not waitUntilDead(2000) then return end
    isOpening = true
    isSuicide = isSuicide == true
    local openToken = displayToken

    local myServerId = GetPlayerServerId(PlayerId())
    if not killerServerId or killerServerId <= 0 then
        killerServerId = myServerId
        isSuicide = true
    end
    if killerServerId == myServerId then
        isSuicide = true
        killerPed = PlayerPedId()
    elseif not isSuicide then
        killerPed = resolveKillerPed(killerServerId, killerPed)
    else
        killerPed = PlayerPedId()
    end

    local combat = buildLocalCombat(killerServerId, killerPed, isSuicide)

    -- Capture vitals before dead ped reports 0 (especially suicide)
    local killerHealth = 0
    local killerArmor = 0
    if isSuicide then
        local maxH = GetEntityMaxHealth(PlayerPedId())
        if maxH > 100 then
            killerHealth = math.max(0, math.min(100, math.floor(((localHealth - 100) / (maxH - 100)) * 100)))
        end
        killerArmor = math.max(0, math.min(100, math.floor(localArmor)))
    elseif killerPed and DoesEntityExist(killerPed) then
        killerHealth = healthPercent(killerPed)
        killerArmor = math.floor(GetPedArmour(killerPed))
    end

    -- Preview is best-effort; UI must still open even if clone/cam fails (suicide dead ped).
    pcall(spawnKillerPreview, killerPed)

    ESX.TriggerServerCallback("cfx-keydi-deathscreen:getKillerData", function(data)
        -- Only abort if this open was cancelled (token bump). Stay open while still dead.
        if openToken ~= displayToken then
            isOpening = false
            return
        end
        if not isActuallyDead() then
            isOpening = false
            hideDeathScreen()
            return
        end
        if not data then
            isOpening = false
            hideDeathScreen()
            return
        end

        local payload = {
            brand = ConfigDeathScreen.Brand,
            brandUrl = ConfigDeathScreen.BrandUrl,
            killer = {
                name = data.name,
                id = data.id,
                ping = data.ping,
                avatarUrl = data.avatarUrl,
                playTime = data.playTime,
                rank = isSuicide and "Suicide" or (data.rank or "#—"),
                kills = data.kills,
                kd = data.kd,
                health = killerHealth,
                armor = killerArmor,
                achievements = data.achievements or {},
            },
            combat = {
                weapon = combat.weapon,
                streak = isSuicide and 0 or (data.streak or 0),
                distance = combat.distance,
                damageDealt = combat.damageDealt,
                damageReceived = combat.damageReceived,
                damageOutPercent = combat.damageOutPercent,
                damageInPercent = combat.damageInPercent,
                headshot = combat.headshot == true,
                hitZones = combat.hitZones or {},
                fatalZone = combat.fatalZone,
                recentKills = data.recentKills or {},
            },
        }

        lastRecap = {
            killer = {
                name = payload.killer.name,
                id = payload.killer.id,
            },
            combat = {
                weapon = payload.combat.weapon,
                distance = payload.combat.distance,
                damageReceived = payload.combat.damageReceived,
                damageDealt = payload.combat.damageDealt,
                headshot = payload.combat.headshot == true,
                fatalZone = payload.combat.fatalZone,
                hitZones = payload.combat.hitZones or {},
            },
            isSuicide = isSuicide,
        }

        showDeathScreen(payload)
        isOpening = false

        local token = displayToken
        local duration = ConfigDeathScreen.DisplayDuration or 0
        if duration > 0 then
            SetTimeout(duration, function()
                if displayToken == token then
                    hideDeathScreen()
                end
            end)
        end
    end, killerServerId)
end

-- Keep local vitals for accurate damage diffs
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            localHealth = GetEntityHealth(ped)
            localArmor = GetPedArmour(ped)
        end
        Wait(100)
    end
end)

AddEventHandler("gameEventTriggered", function(eventName, data)
    if eventName ~= "CEventNetworkEntityDamage" then return end

    local victim = data[1]
    local attacker = data[2]
    local isDead = data[6] == 1
    local playerPed = PlayerPedId()

    -- Track damage taken from other players
    if victim == playerPed and attacker and attacker ~= playerPed and IsPedAPlayer(attacker) then
        local idx = NetworkGetPlayerIndexFromPed(attacker)
        if idx and NetworkIsPlayerActive(idx) then
            local sid = GetPlayerServerId(idx)
            lastAttackerPed = attacker
            lastAttackerSid = sid
            engagement[sid] = engagement[sid] or { dealt = 0, received = 0, zones = {}, lastBone = -1, headshot = false }

            local curH = GetEntityHealth(playerPed)
            local curA = GetPedArmour(playerPed)
            local dmg = 0
            if localArmor > curA then dmg = dmg + (localArmor - curA) end
            if localHealth > curH then dmg = dmg + (localHealth - curH) end
            if dmg > 0 then
                engagement[sid].received = engagement[sid].received + dmg
            end

            -- Capture bone ASAP (before other scripts clear head bone)
            local found, bone = GetPedLastDamageBone(playerPed)
            if found and bone then
                registerReceivedHit(sid, normalizeBoneId(playerPed, bone))
            elseif isDead then
                -- Fatal hit with no bone yet — retry next frame
                CreateThread(function()
                    Wait(0)
                    local retryPed = PlayerPedId()
                    local ok2, bone2 = GetPedLastDamageBone(retryPed)
                    if ok2 and bone2 then
                        registerReceivedHit(sid, normalizeBoneId(retryPed, bone2))
                    end
                end)
            end

            localHealth = curH
            localArmor = curA
        end
    end

    -- Track damage dealt to other players
    if attacker == playerPed and victim and victim ~= playerPed and IsPedAPlayer(victim) then
        local idx = NetworkGetPlayerIndexFromPed(victim)
        if idx and NetworkIsPlayerActive(idx) then
            local sid = GetPlayerServerId(idx)
            engagement[sid] = engagement[sid] or { dealt = 0, received = 0, zones = {}, lastBone = -1, headshot = false }
            -- Approximate tick damage; exact value is hard without pre-cache, use 10–25 estimate from event
            engagement[sid].dealt = engagement[sid].dealt + 15
        end
    end

    -- Local player died — data[6] also fires on spawn/SetPlayerModel. Confirm after ambulance/ESX catch up.
    if isDead and victim == playerPed then
        local attackerPed = attacker
        CreateThread(function()
            if not waitUntilDead(2500) then return end
            if isVisible or isOpening then return end

            local myId = GetPlayerServerId(PlayerId())
            local ped = PlayerPedId()

            -- Fall / world damage often reports the victim as attacker. Prefer last PvP hitter
            -- only when that engagement is recent (not stale leftover from earlier fights).
            local pvpSid = lastAttackerSid
            local pvpPed = lastAttackerPed
            if (not pvpSid or pvpSid <= 0 or pvpSid == myId) then
                pvpSid = getTopEngagementSid()
            end

            local attackerIsSelf = (not attackerPed or attackerPed == 0 or attackerPed == ped)
            local lookLikeSuicide = attackerIsSelf or (attackerPed and attackerPed ~= 0 and not IsPedAPlayer(attackerPed))

            if pvpSid and pvpSid > 0 and pvpSid ~= myId and not lookLikeSuicide then
                openForKiller(pvpSid, resolveKillerPed(pvpSid, pvpPed), false)
                return
            end

            if ConfigDeathScreen.ShowOnSuicide and lookLikeSuicide then
                openForKiller(myId, ped, true)
                return
            end

            if attackerPed and attackerPed ~= 0 and attackerPed ~= ped and IsPedAPlayer(attackerPed) then
                local idx = NetworkGetPlayerIndexFromPed(attackerPed)
                if idx and NetworkIsPlayerActive(idx) then
                    local killerServerId = GetPlayerServerId(idx)
                    if killerServerId and killerServerId > 0 then
                        openForKiller(killerServerId, attackerPed, killerServerId == myId)
                        return
                    end
                end
            end

            -- Final fallback: any death with ShowOnSuicide should still show self-recap
            if ConfigDeathScreen.ShowOnSuicide then
                openForKiller(myId, ped, true)
            end
        end)
    end
end)

-- Also hook ESX death (covers edge cases where gameEvent misses killer ped)
AddEventHandler("esx:onPlayerDeath", function(data)
    CreateThread(function()
        -- gameEvent has the live killer ped; give it a chance to open first
        Wait(450)
        if isVisible or isOpening then return end
        if not waitUntilDead(2000) then return end
        if type(data) ~= "table" then
            if ConfigDeathScreen.ShowOnSuicide then
                openForKiller(GetPlayerServerId(PlayerId()), PlayerPedId(), true)
            end
            return
        end

        local myId = GetPlayerServerId(PlayerId())
        local killerServerId = tonumber(data.killerServerId)
        local killedByPlayer = data.killedByPlayer == true

        -- Prefer live attacker only for true PvP (ESX Natural / suicide must not reuse stale engagement)
        if killedByPlayer and killerServerId and killerServerId > 0 and killerServerId ~= myId then
            local killerPed = resolveKillerPed(killerServerId, lastAttackerSid == killerServerId and lastAttackerPed or 0)
            openForKiller(killerServerId, killerPed, false)
            return
        end

        -- Self-kill / natural death
        if ConfigDeathScreen.ShowOnSuicide then
            openForKiller(myId, PlayerPedId(), true)
        end
    end)
end)

local function clearDeathUi()
    engagement = {}
    lastHitZones = { head = 0, neck = 0, torso = 0, arm = 0, leg = 0 }
    lastBone = -1
    wasHeadshot = false
    lastAttackerPed = 0
    lastAttackerSid = 0
    hideDeathScreen()
end

AddEventHandler("esx:onPlayerSpawn", clearDeathUi)
AddEventHandler("playerSpawned", clearDeathUi)

RegisterNetEvent("cfx-keydi-ambulance:revive", clearDeathUi)

AddStateBagChangeHandler("isReviving", ("player:%s"):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    if value then
        hideDeathScreen()
    end
end)

AddStateBagChangeHandler("dead", ("player:%s"):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    if value == false then
        hideDeathScreen()
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        -- Never tear down mid-open; only hide after UI is shown and player is alive again.
        if isVisible and not isOpening and not holdWhileAlive and not isActuallyDead() then
            hideDeathScreen()
        end
    end
end)

RegisterNUICallback("closeDeathScreen", function(_, cb)
    cb("ok")
    hideDeathScreen()
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    hideDeathScreen()
end)

-- Manual open for testing (works while alive)
RegisterCommand("testdeathscreen", function()
    local ped = PlayerPedId()
    local sid = GetPlayerServerId(PlayerId())
    if isVisible or isOpening then
        hideDeathScreen()
        Wait(100)
    end
    isOpening = true
    holdWhileAlive = true
    local openToken = displayToken
    local combat = buildLocalCombat(sid, ped, true)
    pcall(spawnKillerPreview, ped)
    ESX.TriggerServerCallback("cfx-keydi-deathscreen:getKillerData", function(data)
        if openToken ~= displayToken then
            isOpening = false
            return
        end
        if not data then
            isOpening = false
            holdWhileAlive = false
            destroyPreview()
            return
        end
        showDeathScreen({
            brand = ConfigDeathScreen.Brand,
            brandUrl = ConfigDeathScreen.BrandUrl,
            killer = {
                name = data.name,
                id = data.id,
                ping = data.ping,
                avatarUrl = data.avatarUrl,
                playTime = data.playTime,
                rank = "Suicide",
                kills = data.kills,
                kd = data.kd,
                health = 100,
                armor = math.floor(GetPedArmour(ped)),
                achievements = data.achievements or {},
            },
            combat = combat,
        })
        isOpening = false
    end, sid)
end, false)

exports("HideDeathScreen", hideDeathScreen)
exports("IsDeathScreenVisible", function()
    return isVisible
end)
exports("GetLastRecap", function()
    return lastRecap
end)
