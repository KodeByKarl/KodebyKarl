local ESX = exports["es_extended"]:getSharedObject()
local isVisible = false
local currentSettings = {}
local victimCache = {}

-- Load settings from client key-value store (persistent local storage)
local function LoadSettings()
    local kvp = GetResourceKvpString("cfx-keydi-indicator:settings")
    if kvp then
        currentSettings = json.decode(kvp)
    else
        currentSettings = {
            deadText = ConfigIndicator.DefaultSettings.deadText,
            deadIcon = ConfigIndicator.DefaultSettings.deadIcon,
            fontFamily = ConfigIndicator.DefaultSettings.fontFamily,
            fontSize = ConfigIndicator.DefaultSettings.fontSize,
            duration = ConfigIndicator.DefaultSettings.duration,
            healthColor = ConfigIndicator.DefaultSettings.healthColor,
            armorColor = ConfigIndicator.DefaultSettings.armorColor
        }
    end
end

-- Open/Close Settings Config UI
local function ToggleConfig(state)
    isVisible = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "indicator:showConfig" or "indicator:hideConfig",
        settings = currentSettings
    })
end

-- Sync settings update from UI
RegisterNUICallback('indicator:updateSettings', function(data, cb)
    cb('ok')
    currentSettings = data
    SetResourceKvp("cfx-keydi-indicator:settings", json.encode(currentSettings))
end)

-- Close configuration callback
RegisterNUICallback('indicator:closeConfig', function(data, cb)
    cb('ok')
    ToggleConfig(false)
end)

-- Initialize settings on load
CreateThread(function()
    LoadSettings()
    RequestNamedPtfxAsset("core")
end)

-- Global function to allow opening config from other client scripts in the same resource
function OpenIndicatorConfig()
    ToggleConfig(true)
end

-- Keep last-frame vitals so CEventNetworkEntityDamage (often 1+ frames late) still sees pre-hit HP.
-- A 100ms poll was overwriting pInfo after one-shot headshots, so those hits never registered.
local pInfo = {
    health = 0,
    armor = 0,
    lastAliveHealth = 200,
    lastAliveArmor = 0
}

CreateThread(function()
    local prevHealth, prevArmor
    while true do
        local playerPed = PlayerPedId()
        if playerPed and playerPed ~= 0 then
            local h = GetEntityHealth(playerPed)
            local a = GetPedArmour(playerPed)
            pInfo.health = prevHealth or h
            pInfo.armor = prevArmor or a
            prevHealth = h
            prevArmor = a
            if h > 100 then
                pInfo.lastAliveHealth = h
            end
            pInfo.lastAliveArmor = a
        end
        Wait(0)
    end
end)

-- Background Scanner: Keeps track of nearby NPC (non-player) peds health & armor states 
-- so that we can accurately calculate damage differentials on hit.
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local now = GetGameTimer()

        -- Scan peds in proximity (filtering out players)
        local handle, ped = FindFirstPed()
        local success
        repeat
            if ped and ped ~= playerPed and not IsPedAPlayer(ped) and #(coords - GetEntityCoords(ped)) < 100.0 then
                if not victimCache[ped] then
                    victimCache[ped] = {
                        health = GetEntityHealth(ped),
                        armor = GetPedArmour(ped),
                        time = now
                    }
                end
            end
            success, ped = FindNextPed(handle)
        until not success
        EndFindPed(handle)
    end
end)

-- Cleanup cache entries that haven't been damaged/scanned in 10 seconds
CreateThread(function()
    while true do
        Wait(5000)
        local now = GetGameTimer()
        for id, data in pairs(victimCache) do
            if now - data.time > 10000 then
                victimCache[id] = nil
            end
        end
    end
end)

------------------------------------------------------------------
-- Bone zone helpers (shared DeathScreenBones map + zone colors)
------------------------------------------------------------------
local ZONE_PROJECT = {
    head = 31086,  -- SKEL_Head
    neck = 39317,  -- SKEL_Neck_1
    torso = 24818, -- SKEL_Spine3
    arms = 45509,  -- SKEL_L_UpperArm
    legs = 58271,  -- SKEL_L_Thigh
}

local function ResolveZone(bonehash)
    if DeathScreenBones and DeathScreenBones.ZoneFromBone then
        return DeathScreenBones.ZoneFromBone(bonehash)
    end
    bonehash = tonumber(bonehash) or -1
    if bonehash == 31086 or bonehash == 12844 or bonehash == 65068
        or bonehash == 39317 or bonehash == 97 or bonehash == 98 or bonehash == 99
        or (bonehash >= 98 and bonehash <= 123) then
        return "head"
    end
    return "torso"
end

local function ZoneColor(zone)
    local colors = ConfigIndicator.ZoneColors or {}
    return colors[zone] or colors.torso or "#f59e0b"
end

local function ZoneLabel(zone)
    local labels = ConfigIndicator.ZoneLabels or {}
    return labels[zone] or "B"
end

local function ReadDamageBone(ped)
    local found, bone = GetPedLastDamageBone(ped)
    local bonehash = (found and tonumber(bone)) or -1
    local zone = ResolveZone(bonehash)
    -- Delay clear so deathscreen / helmet / other hit readers can still use this bone
    SetTimeout(400, function()
        if DoesEntityExist(ped) then
            pcall(ClearPedLastDamageBone, ped)
        end
    end)
    if ConfigIndicator.Debug then
        local id = DeathScreenBones and DeathScreenBones.NormalizeBoneId(bonehash) or bonehash
        print(("[cfx-keydi-indicator] bone raw=%s id=%s zone=%s"):format(tostring(bonehash), tostring(id), zone))
    end
    return bonehash, zone
end

local function projectHitToScreen(ped, bonehash, zone)
    zone = zone or ResolveZone(bonehash)
    local boneId = ZONE_PROJECT[zone] or 24818
    if DeathScreenBones and DeathScreenBones.ProjectBoneForZone then
        boneId = DeathScreenBones.ProjectBoneForZone(zone)
    end

    local coords = GetPedBoneCoords(ped, boneId, 0.0, 0.0, 0.0)
    if not coords or (coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0) then
        coords = GetEntityCoords(ped)
        if zone == "head" then
            coords = vector3(coords.x, coords.y, coords.z + 0.75)
        elseif zone == "neck" then
            coords = vector3(coords.x, coords.y, coords.z + 0.62)
        elseif zone == "legs" then
            coords = vector3(coords.x, coords.y, coords.z + 0.25)
        else
            coords = vector3(coords.x, coords.y, coords.z + 0.45)
        end
    elseif zone == "head" then
        coords = vector3(coords.x, coords.y, coords.z - 0.02)
    end

    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not screenX or not screenY then
        screenX, screenY = 0.5, 0.4
    end
    screenX = math.max(0.04, math.min(0.96, screenX))
    screenY = math.max(0.04, math.min(0.96, screenY))
    return true, screenX, screenY, zone
end

local function PushDamageNui(dmgType, amount, screenX, screenY, zone)
    SendNUIMessage({
        action = "indicator:triggerDamage",
        data = {
            id = GetGameTimer() .. math.random(100, 999),
            type = dmgType,
            amount = amount,
            x = screenX,
            y = screenY,
            zone = zone,
            zoneLabel = ZoneLabel(zone),
            zoneColor = ZoneColor(zone),
        }
    })
end

-- Damage event listener
AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName == 'CEventNetworkEntityDamage' then
        local victim = data[1]
        local attacker = data[2]
        local isDead = data[6] == 1

        local playerPed = PlayerPedId()

        -- Debug print to check entity type in F8 console
        if ConfigIndicator and ConfigIndicator.Debug and attacker == playerPed then
            print(("[cfx-keydi-indicator] Attacked entity: %s | IsPed: %s | IsVehicle: %s"):format(victim, tostring(IsEntityAPed(victim)), tostring(IsEntityAVehicle(victim))))
        end

        -- CASE A: Local player is the victim, and attacker is another player
        if victim == playerPed and attacker ~= playerPed then
            if IsPedAPlayer(attacker) then
                local attackerPlayer = NetworkGetPlayerIndexFromPed(attacker)
                if NetworkIsPlayerActive(attackerPlayer) then
                    local attackerServerId = GetPlayerServerId(attackerPlayer)
                    
                    local currentHealth = GetEntityHealth(playerPed)
                    local currentArmor = GetPedArmour(playerPed)
                    local fatallyInjured = isDead == true
                        or IsPedFatallyInjured(playerPed)
                        or IsEntityDead(playerPed)
                        or currentHealth <= 100

                    local hit = {
                        health = 0,
                        armor = 0
                    }

                    if pInfo.armor > currentArmor then
                        hit.armor = pInfo.armor - currentArmor
                    end

                    if pInfo.health > currentHealth then
                        hit.health = pInfo.health - currentHealth
                        if hit.health > pInfo.health then
                            hit.health = pInfo.health
                        end
                    elseif fatallyInjured and (pInfo.lastAliveHealth or 0) > currentHealth then
                        hit.health = math.max(hit.health, (pInfo.lastAliveHealth or 0) - currentHealth)
                    end

                    -- Update pInfo immediately to prevent consecutive hits desync
                    pInfo.health = currentHealth
                    pInfo.armor = currentArmor

                    -- Trigger server event to relay the hit info to the attacker
                    if hit.health > 0 or hit.armor > 0 or fatallyInjured then
                        local bonehash = ReadDamageBone(playerPed)
                        TriggerServerEvent('cfx-keydi-indicator:server:registerHit', attackerServerId, hit, fatallyInjured, bonehash)
                    end
                end
            end
        end

        -- CASE B: Local player is the attacker, and victim is an NPC (non-player ped)
        if attacker == playerPed and victim ~= playerPed then
            if IsEntityAPed(victim) and not IsPedAPlayer(victim) then
                local currentHealth = GetEntityHealth(victim)
                local currentArmor = GetPedArmour(victim)
                
                local cached = victimCache[victim]
                local healthDiff = 0
                local armorDiff = 0

                if cached then
                    healthDiff = cached.health - currentHealth
                    armorDiff = cached.armor - currentArmor
                else
                    -- Fallback baseline if not cached
                    local maxHealth = GetEntityMaxHealth(victim)
                    healthDiff = maxHealth - currentHealth
                end

                -- Update cache with current values
                victimCache[victim] = {
                    health = currentHealth,
                    armor = currentArmor,
                    time = GetGameTimer()
                }

                local bonehash, zone = ReadDamageBone(victim)
                local onScreen, screenX, screenY = projectHitToScreen(victim, bonehash, zone)

                if onScreen then
                    if isDead then
                        PushDamageNui("dead", currentSettings.deadText or "Dead", screenX, screenY, zone)
                    else
                        if armorDiff > 0 then
                            PushDamageNui("armor", armorDiff, screenX, screenY, zone)
                        end
                        if healthDiff > 0 then
                            PushDamageNui("health", healthDiff, screenX, screenY, zone)
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('cfx-keydi-indicator:client:onHit', function(victimServerId, hit, victimDied, bonehash)
    local victimPlayer = GetPlayerFromServerId(victimServerId)
    if NetworkIsPlayerActive(victimPlayer) then
        local victimPed = GetPlayerPed(victimPlayer)
        if victimPed and victimPed ~= 0 then
            local zone = ResolveZone(bonehash)
            local onScreen, screenX, screenY = projectHitToScreen(victimPed, bonehash, zone)

            if onScreen then
                if victimDied then
                    PushDamageNui("dead", currentSettings.deadText or "Dead", screenX, screenY, zone)
                else
                    if hit.armor and hit.armor > 0 then
                        PushDamageNui("armor", hit.armor, screenX, screenY, zone)
                    end
                    if hit.health and hit.health > 0 then
                        PushDamageNui("health", hit.health, screenX, screenY, zone)
                    end
                end
            end
        end
    end
end)
