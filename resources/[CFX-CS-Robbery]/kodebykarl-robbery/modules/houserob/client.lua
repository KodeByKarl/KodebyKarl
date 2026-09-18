local RESOURCE = GetCurrentResourceName()
local inside = false
local currentHouse = nil
local closestHouse
local inRange
local IsLockpicking = false
local houseObj = {}
local POIOffsets = nil
local usingAdvanced = false
local soundLevel = 0.0
local soundTriggered = false
local soundThreadActive = false
local leaveRobberyHouse, isPlayerPolice, enterRobberyHouse

local function CanUseHouseRob()
    -- Police can always enter a house (respond / clear).
    if isPlayerPolice and isPlayerPolice() then
        return true
    end
    -- House doors sit in the city. Region 1 (Main) only.
    if GetResourceState('kodebykarl-ui') ~= 'started' then
        return true
    end
    local ok, allowed = pcall(function()
        local exp = exports['kodebykarl-ui']
        return exp:HasFunction('illegal')
            or exp:HasFunction('houserob')
            or exp:HasFunction('housing')
            or exp:HasFunction('main')
    end)
    if not ok then
        return true
    end
    return allowed == true
end

local function HouseRobWrongRegion()
    local msg = 'House robbery is only available on Region 1. Open Control Center (F5) → Regions.'
    if GetResourceState('kodebykarl-ui') == 'started' then
        local ok, text = pcall(function()
            return exports['kodebykarl-ui']:WrongServerMessage('illegal')
        end)
        if ok and type(text) == 'string' and text ~= '' then
            msg = text
        end
    end
    ESX.Notify('House Robbery', msg, 'error', 5000)
end

-- Functions

local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x,y,z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do Wait(5) end
end

local function openHouseAnim()
    loadAnimDict("anim@heists@keycard@")
    TaskPlayAnim( cache.ped, "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, 0, 0, 0 )
    Wait(400)
    ClearPedTasks(cache.ped)
end

local function playDoorSound()
    if GetResourceState('InteractSound') == 'started' then
        pcall(function() exports['InteractSound']:PlayOnSource('houses_door_open', 0.25) end)
    end
end

local function resetSoundMeter()
    soundLevel = 0.0
    soundTriggered = false
end

local function isFiringWeapon()
    local ped = cache.ped
    if IsPedShooting(ped) then return true, true end
    if IsPedArmed(ped, 4) and (IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24)) then
        return true, false
    end
    return false, false
end

local function getDoorStreetLabel(house)
    local h = house and Config.HouseRob.Houses[house]
    if not h or not h.coords then
        return tostring(house or 'Unknown house')
    end
    local c = h.coords
    local streetHash, crossingHash = GetStreetNameAtCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    local street = GetStreetNameFromHashKey(streetHash) or ''
    local crossing = GetStreetNameFromHashKey(crossingHash) or ''
    local zone = GetNameOfZone(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    local area = zone and GetLabelText(zone) or ''
    if area == 'NULL' or area == 'null' then area = '' end
    if street ~= '' and crossing ~= '' then
        return ('%s / %s%s'):format(street, crossing, area ~= '' and (' — ' .. area) or '')
    end
    if street ~= '' then
        return area ~= '' and (street .. ' — ' .. area) or street
    end
    if area ~= '' then return area end
    return tostring(house)
end

local function drawSoundMeter(level)
    local pct = math.max(0.0, math.min(100.0, level)) / 100.0
    local boxW, boxH = 0.18, 0.034
    local x, y = 0.5, 0.905
    local pad = 0.004

    -- container
    DrawRect(x, y, boxW, boxH, 12, 12, 14, 210)
    DrawRect(x, y - (boxH * 0.5) + 0.0012, boxW, 0.0024, 180, 40, 40, 220)

    -- fill track
    local trackW = boxW - (pad * 2)
    local trackH = 0.012
    local trackY = y + 0.004
    DrawRect(x, trackY, trackW, trackH, 30, 30, 34, 230)

    local fillW = trackW * pct
    if fillW > 0.001 then
        local r, g, b = 70, 200, 90
        if pct >= 0.75 then
            r, g, b = 220, 55, 55
        elseif pct >= 0.45 then
            r, g, b = 230, 170, 40
        end
        DrawRect(x - (trackW * 0.5) + (fillW * 0.5), trackY, fillW, trackH, r, g, b, 245)
    end

    SetTextFont(4)
    SetTextScale(0.28, 0.28)
    SetTextColour(230, 230, 230, 240)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    local status = 'SOUND'
    if isFiringWeapon() then
        status = 'GUNFIRE'
    end
    AddTextComponentSubstringPlayerName(('%s  %.0f%%'):format(status, level))
    EndTextCommandDisplayText(x, y - 0.016)
end

local function alertPoliceNoise(house, reason)
    TriggerServerEvent('cfx-cs-robbery:houserob:server:soundAlert', house, getDoorStreetLabel(house), reason)
end

local function startSoundDetection(house)
    local cfg = Config.HouseRob.SoundDetection
    if not cfg or not cfg.enabled then return end
    if isPlayerPolice() then return end
    if soundThreadActive then return end

    resetSoundMeter()
    soundThreadActive = true
    ESX.Notify('House Robbery', 'Keep quiet — footsteps and gunfire will alert neighbors.', 'info', 6000)

    CreateThread(function()
        local lastTick = GetGameTimer()
        while inside and currentHouse == house and soundThreadActive do
            local now = GetGameTimer()
            local dt = (now - lastTick) / 1000.0
            lastTick = now
            if dt <= 0.0 then dt = 0.001 end
            if dt > 0.25 then dt = 0.25 end

            local ped = cache.ped
            local speed = GetEntitySpeed(ped)
            local moving = speed > (cfg.moveThreshold or 0.45)
            local firing, justShot = isFiringWeapon()
            local searching = IsLockpicking

            if justShot then
                soundLevel = math.min(100.0, soundLevel + (cfg.shotSpike or 60.0))
            elseif firing then
                soundLevel = math.min(100.0, soundLevel + (cfg.shotNoise or 40.0) * dt)
            elseif searching then
                soundLevel = math.max(0.0, soundLevel - (cfg.idleDecay or 5.0) * dt)
            elseif moving then
                local rate = cfg.walkNoise or 7.5
                if IsPedSprinting(ped) then
                    rate = cfg.sprintNoise or 28.0
                elseif IsPedRunning(ped) then
                    rate = cfg.runNoise or 18.0
                end
                soundLevel = math.min(100.0, soundLevel + rate * dt)
            else
                soundLevel = math.max(0.0, soundLevel - (cfg.idleDecay or 5.0) * dt)
            end

            drawSoundMeter(soundLevel)

            if soundLevel >= 100.0 and not soundTriggered then
                soundTriggered = true
                soundThreadActive = false
                local exitHouse = currentHouse
                ESX.Notify('House Robbery', 'Too loud — neighbors heard you. Getting out!', 'error', 7000)
                alertPoliceNoise(exitHouse, firing and 'gunfire' or 'noise')
                if exitHouse then
                    leaveRobberyHouse(exitHouse)
                end
                break
            end

            Wait(0)
        end
        soundThreadActive = false
        resetSoundMeter()
    end)
end

leaveRobberyHouse = function(house)
    soundThreadActive = false
    resetSoundMeter()
    TriggerServerEvent('cfx-cs-robbery:houserob:server:leaveHouse', house)
    local ped = cache.ped
    playDoorSound()
    openHouseAnim()
    Wait(250)
    DoScreenFadeOut(250)
    Wait(500)
    exports[RESOURCE]:DespawnInterior(houseObj, function()
        local coords = vec3(Config.HouseRob.Houses[house]["coords"]["x"], Config.HouseRob.Houses[house]["coords"]["y"], Config.HouseRob.Houses[house]["coords"]["z"] + 0.3)
        TriggerEvent('cfx-cs-weather:client:EnableSync')
        Wait(250)
        DoScreenFadeIn(250)
        if Player(cache.serverId).state.dead then
            coords = vec3(Config.HouseRob.Houses[house]["coords"]["x"] + math.random(1,5), Config.HouseRob.Houses[house]["coords"]["y"] - math.random(1, 5), Config.HouseRob.Houses[house]["coords"]["z"] + 0.3)
        end
        SetEntityCoords(ped, coords.x, coords.y, coords.z)
        SetEntityHeading(ped, Config.HouseRob.Houses[house]["coords"]["h"])
    end)
    houseObj = {}
    POIOffsets = nil
    inside = false
    currentHouse = nil
    LocalPlayer.state:set('inHouseRobbery', false, true)
end

enterRobberyHouse = function(house)
    -- Server sets routing bucket; client only builds interior after enter event
    playDoorSound()
    openHouseAnim()
    Wait(250)
    local coords = { x = Config.HouseRob.Houses[house].coords.x, y = Config.HouseRob.Houses[house].coords.y, z= Config.HouseRob.Houses[house].coords.z - Config.HouseRob.MinZOffset}
    local data = exports[RESOURCE]:CreateHouseRobbery(coords)
    if not data then
        print('[^3kodebykarl-robbery^0]: [House Robbery]: Error Creating House — shell model missing (furnitured_midapart)')
        TriggerServerEvent('cfx-cs-robbery:houserob:server:leaveHouse', house)
        if IsScreenFadedOut() then DoScreenFadeIn(500) end
        ESX.Notify('House Robbery', 'Interior failed to load. Restart kodebykarl-robbery so furnitured_midapart streams.', 'error', 8000)
        return
    end
    houseObj = data[1]
    POIOffsets = data[2]
    print('[^3kodebykarl-robbery^0]: [House Robbery]: Teleporting to vec3('..coords.x + POIOffsets.exit.x..', '..coords.y + POIOffsets.exit.y..', '..coords.z + POIOffsets.exit.z..')')
    SetEntityCoords(cache.ped, coords.x + POIOffsets.exit.x, coords.y + POIOffsets.exit.y, coords.z + POIOffsets.exit.z)
    inside = true
    currentHouse = house
    LocalPlayer.state:set('inHouseRobbery', true, true)
    Wait(500)
    TriggerEvent('cfx-cs-weather:client:DisableSync')
    startSoundDetection(house)
    CreateThread(function()
        while true do
            Wait(500)
            if Player(cache.serverId).state.dead then
                leaveRobberyHouse(currentHouse)
            end
            if not inside then break end
            if currentHouse == nil then break end
        end
    end)
end

--- Emergency unstuck (black screen / failed shell)
local function forceExitHouseRobbery()
    soundThreadActive = false
    resetSoundMeter()
    local house = currentHouse
    inside = false
    currentHouse = nil
    POIOffsets = nil
    LocalPlayer.state:set('inHouseRobbery', false, true)
    TriggerServerEvent('cfx-cs-robbery:houserob:server:leaveHouse', house)
    TriggerEvent('cfx-cs-weather:client:EnableSync')
    if houseObj and next(houseObj) then
        exports[RESOURCE]:DespawnInterior(houseObj, function() end)
    end
    houseObj = {}
    if IsScreenFadedOut() then DoScreenFadeIn(0) end
    local ped = cache.ped
    if house and Config.HouseRob.Houses[house] then
        local c = Config.HouseRob.Houses[house].coords
        SetEntityCoords(ped, c.x, c.y, c.z + 0.5, false, false, false, false)
        SetEntityHeading(ped, c.h or 0.0)
    else
        -- fallback: put player slightly above current coords so they aren't underground
        local pos = GetEntityCoords(ped)
        SetEntityCoords(ped, pos.x, pos.y, pos.z + 50.0, false, false, false, false)
        local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 100.0, false)
        if found then
            SetEntityCoords(ped, pos.x, pos.y, groundZ + 1.0, false, false, false, false)
        end
    end
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    ESX.Notify('House Robbery', 'Forced exit from house robbery.', 'info', 5000)
end

RegisterCommand('exithouserob', function()
    forceExitHouseRobbery()
end, false)

local lastDispatchHouse = nil

local function tryLeoEnterHouse(preferredHouse)
    if not isPlayerPolice() then
        return ESX.Notify('House Robbery', 'Police / Sheriff only.', 'error', 5000)
    end
    if inside then
        return ESX.Notify('House Robbery', 'You are already inside a house.', 'info', 4000)
    end

    local maxDist = tonumber(Config.HouseRob.LeoEnterDistance) or 50.0
    local pos = GetEntityCoords(cache.ped)
    local targetHouse = nil
    local targetDist = nil

    local function consider(houseKey)
        local h = Config.HouseRob.Houses[houseKey]
        if not h or not h.opened or not h.coords then return end
        local c = h.coords
        local dist = #(pos - vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0))
        if dist <= maxDist and (not targetDist or dist < targetDist) then
            targetHouse = houseKey
            targetDist = dist
        end
    end

    if preferredHouse then
        consider(preferredHouse)
    end

    if not targetHouse and lastDispatchHouse then
        consider(lastDispatchHouse)
    end

    if not targetHouse then
        local opened = lib.callback.await('cfx-cs-robbery:houserob:server:getOpenedHouses', false) or {}
        for i = 1, #opened do
            local entry = opened[i]
            if entry and entry.house then
                -- Keep client opened flag in sync for prompts
                if Config.HouseRob.Houses[entry.house] then
                    Config.HouseRob.Houses[entry.house].opened = true
                end
                consider(entry.house)
            end
        end
    end

    if not targetHouse then
        return ESX.Notify('House Robbery', 'No ongoing house robbery nearby. Go to the dispatch blip, then /hrob.', 'error', 6000)
    end

    closestHouse = targetHouse
    TriggerServerEvent('cfx-cs-robbery:houserob:server:leoEnterHouse', targetHouse)
end

RegisterCommand('hrob', function()
    tryLeoEnterHouse(nil)
end, false)

TriggerEvent('chat:addSuggestion', '/hrob', 'Police/Sheriff: enter nearest ongoing house robbery')
TriggerEvent('chat:addSuggestion', '/exithouserob', 'Force exit a house robbery interior')

RegisterNetEvent('cfx-cs-robbery:houserob:client:forceExit', forceExitHouseRobbery)

local function lockpickFinish(success)
    ClearPedTasks(cache.ped)
    if not closestHouse then return end
    TriggerServerEvent('cfx-cs-robbery:houserob:server:finishLockpick', closestHouse, success == true, usingAdvanced == true, getDoorStreetLabel(closestHouse))
end

isPlayerPolice = function()
    local pData = ESX.GetPlayerData()
    if pData and pData.job then
        local jName = tostring(pData.job.name):lower()
        if jName == 'police' or jName == 'sheriff' then
            return true
        end
    end
    return false
end

local paletoCooldownUntil = 0

local function formatCooldownLeft(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return ('%dh %dm'):format(hours, minutes)
    end
    if minutes > 0 then
        return ('%dm'):format(minutes)
    end
    return ('%ds'):format(math.max(1, seconds))
end

local function isPaletoHouseKey(house)
    if type(house) ~= 'string' then return false end
    local cfg = Config.HouseRob and Config.HouseRob.PaletoGlobalCooldown
    local prefixes = cfg and cfg.prefixes or { 'paleto', 'emhouseRobbery' }
    local key = house:lower()
    for i = 1, #prefixes do
        local prefix = tostring(prefixes[i] or ''):lower()
        if prefix ~= '' and key:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

RegisterNetEvent('cfx-cs-robbery:houserob:client:paletoCooldown', function(untilAt)
    paletoCooldownUntil = tonumber(untilAt) or 0
end)

local function startLockpicking(house, isAdvanced)
    if not house then return end
    if IsLockpicking then return end
    if not CanUseHouseRob() then
        return HouseRobWrongRegion()
    end

    if Config.HouseRob.LimitTime then
        if GetClockHours() < Config.HouseRob.MinimumTime or GetClockHours() > Config.HouseRob.MaximumTime then
            ESX.Notify('House Robbery', 'You can\'t do that at this time of day.', 'error', 5000)
            return
        end
    end

    if Config.HouseRob.Houses[house]["opened"] then
        return ESX.Notify('House Robbery', 'The door is already open.', 'info', 5000)
    end

    local leoCheck = lib.callback.await('cfx-cs-robbery:houserob:server:canStartRobbery', false)
    if leoCheck and leoCheck.allowed == false then
        return ESX.Notify('House Robbery',
            ('Need %s on-duty Police/Sheriff to start a house robbery. Currently online: %s.'):format(
                leoCheck.required or 3,
                leoCheck.online or 0
            ),
            'error', 7000)
    end

    local cdCfg = Config.HouseRob.PaletoGlobalCooldown
    if cdCfg and cdCfg.enabled ~= false and isPaletoHouseKey(house) then
        local info = lib.callback.await('cfx-cs-robbery:houserob:server:getPaletoCooldown', false, house)
        local remaining = info and tonumber(info.remaining) or 0
        if info and info.untilAt then
            paletoCooldownUntil = tonumber(info.untilAt) or paletoCooldownUntil
        end
        if remaining > 0 then
            return ESX.Notify('House Robbery',
                ('Paleto houses are on cooldown. Try again in %s.'):format(formatCooldownLeft(remaining)),
                'error', 7000)
        end
    end

    if isAdvanced == nil then
        local countAdv = ox_inventory:Search('count', 'advancedlockpick') or 0
        local countNorm = ox_inventory:Search('count', 'lockpick') or 0
        if countAdv > 0 then
            isAdvanced = true
        elseif countNorm > 0 then
            isAdvanced = false
        else
            return ESX.Notify('House Robbery', 'You need a lockpick to break into this house.', 'error', 5000)
        end
    end

    usingAdvanced = isAdvanced
    IsLockpicking = true

    RequestAnimDict("veh@break_in@0h@p_m_one@")
    while not HasAnimDictLoaded("veh@break_in@0h@p_m_one@") do Wait(10) end
    TaskPlayAnim(cache.ped, "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 3.0, 3.0, -1, 16, 0, false, false, false)

    local checks = {}
    if usingAdvanced then
        for i = 1, 10 do
            checks[i] = i <= 6 and 'easy' or 'medium'
        end
    else
        for i = 1, 10 do
            if i <= 3 then
                checks[i] = 'easy'
            elseif i <= 7 then
                checks[i] = 'medium'
            else
                checks[i] = 'hard'
            end
        end
    end
    local success = lib.skillCheck(checks, {'w', 'a', 's', 'd'})

    ClearPedTasks(cache.ped)
    IsLockpicking = false
    lockpickFinish(success)
end

local function searchCabin(cabin)
    local ped = cache.ped
    if math.random(1, 100) <= 85 then
        local pos = GetEntityCoords(cache.ped)
        TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
    end

    local duration = math.floor(tonumber(Config.HouseRob.SearchDuration) or (2 * 60 * 1000))
    if duration < 1000 then duration = 1000 end
    local label = Config.HouseRob.SearchLabel or 'Searching furniture...'
    local animCfg = Config.HouseRob.SearchAnim or {}
    local animDict = animCfg.dict or 'creatures@rottweiler@tricks@'
    local animClip = animCfg.clip or 'petting_franklin'
    local animFlag = tonumber(animCfg.flag) or 17

    loadAnimDict(animDict)
    TaskPlayAnim(cache.ped, animDict, animClip, 8.0, 8.0, -1, animFlag, 0, false, false, false)

    TriggerServerEvent('cfx-cs-robbery:houserob:server:SetBusyState', cabin, currentHouse, true)
    FreezeEntityPosition(ped, true)
    IsLockpicking = true

    local success = lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = animDict,
            clip = animClip,
            flag = animFlag,
        },
    })

    ClearPedTasks(cache.ped)
    TriggerServerEvent('cfx-cs-robbery:houserob:server:SetBusyState', cabin, currentHouse, false)
    FreezeEntityPosition(ped, false)

    if success then
        TriggerServerEvent('cfx-cs-robbery:houserob:server:searchFurniture', cabin, currentHouse)
        Config.HouseRob.Houses[currentHouse]["furniture"][cabin]["searched"] = true
    else
        ESX.Notify('House Robbery', 'Search canceled.', 'error', 5000)
    end

    SetTimeout(500, function()
        IsLockpicking = false
    end)
end

-- Events

local houseTargetIds = {}

local function refreshHouses()
    local houses = lib.callback.await('cfx-cs-robbery:houserob:server:GetHouseConfig', false)
    if type(houses) == 'table' then
        Config.HouseRob.Houses = houses
    end
end

local function clearHouseTargets()
    if GetResourceState('ox_target') ~= 'started' then
        houseTargetIds = {}
        return
    end
    for i = 1, #houseTargetIds do
        pcall(function()
            exports.ox_target:removeZone(houseTargetIds[i])
        end)
    end
    houseTargetIds = {}
end

local function setupHouseTargets()
    if GetResourceState('ox_target') ~= 'started' then return end
    local houses = Config.HouseRob and Config.HouseRob.Houses
    if type(houses) ~= 'table' then return end

    clearHouseTargets()
    for id, house in pairs(houses) do
        local c = house and house.coords
        if c and c.x and c.y and c.z then
            local zoneId = exports.ox_target:addSphereZone({
                coords = vec3(c.x + 0.0, c.y + 0.0, c.z + 0.0),
                radius = 1.7,
                debug = false,
                options = {
                    {
                        name = ('houserob_enter_%s'):format(id),
                        icon = 'fa-solid fa-door-open',
                        label = 'Enter house',
                        distance = 2.2,
                        canInteract = function()
                            return house.opened == true and not inside
                        end,
                        onSelect = function()
                            closestHouse = id
                            if isPlayerPolice() then
                                TriggerServerEvent('cfx-cs-robbery:houserob:server:leoEnterHouse', id)
                                return
                            end
                            if not CanUseHouseRob() then
                                return HouseRobWrongRegion()
                            end
                            TriggerServerEvent('cfx-cs-robbery:houserob:server:enterHouse', id)
                        end,
                    },
                    {
                        name = ('houserob_lockpick_%s'):format(id),
                        icon = 'fa-solid fa-unlock',
                        label = 'Lockpick door',
                        distance = 2.2,
                        canInteract = function()
                            if house.opened == true or isPlayerPolice() or inside then
                                return false
                            end
                            local cdCfg = Config.HouseRob.PaletoGlobalCooldown
                            if cdCfg and cdCfg.enabled ~= false and isPaletoHouseKey(id) and paletoCooldownUntil > 0 then
                                if os.time() < paletoCooldownUntil then
                                    return false
                                end
                            end
                            return true
                        end,
                        onSelect = function()
                            closestHouse = id
                            startLockpicking(id)
                        end,
                    },
                },
            })
            if zoneId then
                houseTargetIds[#houseTargetIds + 1] = zoneId
            end
        end
    end
end

RegisterNetEvent('esx:playerLoaded', function()
    refreshHouses()
    setupHouseTargets()
end)

CreateThread(function()
    Wait(1500)
    refreshHouses()
    setupHouseTargets()
end)

RegisterNetEvent('cfx-cs-robbery:houserob:client:ResetHouseState', function(house)
    Config.HouseRob.Houses[house]["opened"] = false
    for _, v in pairs(Config.HouseRob.Houses[house]["furniture"]) do
        v["searched"] = false
    end
    if lastDispatchHouse == house then
        lastDispatchHouse = nil
    end
    if currentHouse ~= nil then
        leaveRobberyHouse(currentHouse)
    end
end)

RegisterNetEvent('cfx-cs-robbery:houserob:client:enterHouse', function(house)
    enterRobberyHouse(house)
end)

RegisterNetEvent('cfx-cs-robbery:houserob:client:setHouseState', function(house, state)
    Config.HouseRob.Houses[house]["opened"] = state
end)

RegisterNetEvent('cfx-cs-robbery:houserob:client:setCabinState', function(house, cabin, state)
    Config.HouseRob.Houses[house]["furniture"][cabin]["searched"] = state
end)

RegisterNetEvent('cfx-cs-robbery:houserob:client:SetBusyState', function(cabin, house, bool)
    Config.HouseRob.Houses[house]["furniture"][cabin]["isBusy"] = bool
end)

RegisterNetEvent('cfx-cs-robbery:houserob:client:policeAlert', function(data)
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then return end
    local c = data.coords
    local x, y, z = (c.x or 0) + 0.0, (c.y or 0) + 0.0, (c.z or 0) + 0.0
    local duration = tonumber(data.time) or 180000

    if type(data.house) == 'string' and data.house ~= '' then
        lastDispatchHouse = data.house
        if Config.HouseRob.Houses[data.house] then
            Config.HouseRob.Houses[data.house].opened = true
        end
    end

    ESX.Notify('Dispatch', data.message or 'House robbery in progress. Use /hrob at the door.', 'police', data.notifyDuration or 14000)
    PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', true)

    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, data.sprite or 411)
    SetBlipColour(blip, data.color or 1)
    SetBlipScale(blip, data.scale or 1.1)
    SetBlipFlashes(blip, true)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.label or 'House Robbery')
    EndTextCommandSetBlipName(blip)
    SetNewWaypoint(x, y)

    local radius = AddBlipForRadius(x, y, z, data.radius or 60.0)
    SetBlipHighDetail(radius, true)
    SetBlipColour(radius, 1)
    SetBlipAlpha(radius, 110)

    CreateThread(function()
        Wait(duration)
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        if DoesBlipExist(radius) then RemoveBlip(radius) end
    end)
end)

RegisterNetEvent('cfx-cs-robbery:houserob:UseLockpick', function(isAdvanced)
    if not CanUseHouseRob() then
        return HouseRobWrongRegion()
    end
    if closestHouse == nil then
        return ESX.Notify('House Robbery', 'You are not near any house door.', 'error', 5000)
    end
    startLockpicking(closestHouse, isAdvanced)
end)

-- Threads

CreateThread(function()
    Wait(500)
    while true do
        inRange = false
        local PlayerPed = cache.ped
        local PlayerPos = GetEntityCoords(PlayerPed)
        closestHouse = nil
        local houses = Config.HouseRob and Config.HouseRob.Houses
        if not inside and type(houses) == 'table' then
            for k, house in pairs(houses) do
                local c = house and house.coords
                if c and c.x and c.y and c.z then
                local houseCoords = vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0)
                local dist = #(PlayerPos - houseCoords)
                if dist <= 2.2 then
                    closestHouse = k
                    inRange = true
                    local isCop = isPlayerPolice()

                    if house.opened then
                        if isCop then
                            DrawText3Ds(houseCoords.x, houseCoords.y, houseCoords.z, '~b~[E]~w~ / ~b~/hrob~w~ - Enter Robbery')
                        else
                            DrawText3Ds(houseCoords.x, houseCoords.y, houseCoords.z, '~g~[E]~w~ - To Enter')
                        end
                        if IsControlJustPressed(0, 38) then
                            if isCop then
                                TriggerServerEvent('cfx-cs-robbery:houserob:server:leoEnterHouse', k)
                            elseif not CanUseHouseRob() then
                                HouseRobWrongRegion()
                            elseif Config.HouseRob.LimitTime and (GetClockHours() < Config.HouseRob.MinimumTime or GetClockHours() > Config.HouseRob.MaximumTime) then
                                ESX.Notify('House Robbery', 'You can\'t do that at this time of day.', 'error', 5000)
                            else
                                TriggerServerEvent('cfx-cs-robbery:houserob:server:enterHouse', k)
                            end
                        end
                    else
                        if not isCop then
                            DrawText3Ds(houseCoords.x, houseCoords.y, houseCoords.z, '~r~[Locked]~w~ Press ~y~[E]~w~ to Lockpick')
                            if IsControlJustPressed(0, 38) then
                                startLockpicking(k)
                            end
                        end
                    end
                end
                end
            end
        end
        if inside then
            Wait(0)
        elseif not inRange then
            Wait(500)
        else
            Wait(0)
        end
    end
end)

CreateThread(function()
    while true do
        local ped = cache.ped
        local pos = GetEntityCoords(ped)
        if inside then
            if #(pos - vector3(Config.HouseRob.Houses[currentHouse]["coords"]["x"] + POIOffsets.exit.x, Config.HouseRob.Houses[currentHouse]["coords"]["y"] + POIOffsets.exit.y, Config.HouseRob.Houses[currentHouse]["coords"]["z"] - Config.HouseRob.MinZOffset + POIOffsets.exit.z)) < 1.5 then
                DrawText3Ds(Config.HouseRob.Houses[currentHouse]["coords"]["x"] + POIOffsets.exit.x, Config.HouseRob.Houses[currentHouse]["coords"]["y"] + POIOffsets.exit.y, Config.HouseRob.Houses[currentHouse]["coords"]["z"] - Config.HouseRob.MinZOffset + POIOffsets.exit.z, '~g~E~w~ - To leave house')
                if IsControlJustPressed(0, 38) then
                    leaveRobberyHouse(currentHouse)
                end
            end
            if inside then
                for k, _ in pairs(Config.HouseRob.Houses[currentHouse]["furniture"]) do
                    if #(pos - vector3(Config.HouseRob.Houses[currentHouse]["coords"]["x"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["x"], Config.HouseRob.Houses[currentHouse]["coords"]["y"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["y"], Config.HouseRob.Houses[currentHouse]["coords"]["z"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["z"] - Config.HouseRob.MinZOffset)) < 1 then
                        if not Config.HouseRob.Houses[currentHouse]["furniture"][k]["searched"] then
                            if not Config.HouseRob.Houses[currentHouse]["furniture"][k]["isBusy"] then
                                DrawText3Ds(Config.HouseRob.Houses[currentHouse]["coords"]["x"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["x"], Config.HouseRob.Houses[currentHouse]["coords"]["y"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["y"], Config.HouseRob.Houses[currentHouse]["coords"]["z"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["z"] - Config.HouseRob.MinZOffset, 'E '..Config.HouseRob.Houses[currentHouse]["furniture"][k]["text"])
                                if not IsLockpicking then
                                    if IsControlJustReleased(0, 38) then
                                        searchCabin(k)
                                    end
                                end
                            else
                                DrawText3Ds(Config.HouseRob.Houses[currentHouse]["coords"]["x"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["x"], Config.HouseRob.Houses[currentHouse]["coords"]["y"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["y"], Config.HouseRob.Houses[currentHouse]["coords"]["z"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["z"] - Config.HouseRob.MinZOffset, 'Searching...')
                            end
                        else
                            DrawText3Ds(Config.HouseRob.Houses[currentHouse]["coords"]["x"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["x"], Config.HouseRob.Houses[currentHouse]["coords"]["y"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["y"], Config.HouseRob.Houses[currentHouse]["coords"]["z"] + Config.HouseRob.Houses[currentHouse]["furniture"][k]["coords"]["z"] - Config.HouseRob.MinZOffset, 'Empty.')
                        end
                    end
                end
            end
        end

        if inside then
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Util Command (can be commented out - used for setting new spots in the config)

-- RegisterCommand('gethroffset', function()
--     local coords = GetEntityCoords(cache.ped)
--     local houseCoords = vector3(
--         Config.HouseRob.Houses[currentHouse]["coords"]["x"],
--         Config.HouseRob.Houses[currentHouse]["coords"]["y"],
--         Config.HouseRob.Houses[currentHouse]["coords"]["z"] - Config.HouseRob.MinZOffset
--     )
--     if inside then
--         local xdist = coords.x - houseCoords.x
--         local ydist = coords.y - houseCoords.y
--         local zdist = coords.z - houseCoords.z
--         print('X: '..xdist)
--         print('Y: '..ydist)
--         print('Z: '..zdist)
--     end
-- end, false)
