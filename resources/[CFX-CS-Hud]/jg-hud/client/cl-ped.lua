local getGameplayCamRot = GetGameplayCamRot
local getEntityHeading = GetEntityHeading
local getEntityCoords = GetEntityCoords
local getStreetNameAtCoord = GetStreetNameAtCoord
local getStreetNameFromHashKey = GetStreetNameFromHashKey
local getNameOfZone = GetNameOfZone
local getLabelText = GetLabelText
local getEntityHealth = GetEntityHealth
local getPedArmour = GetPedArmour
local getPlayerSprintStaminaRemaining = GetPlayerSprintStaminaRemaining
local isEntityInWater = IsEntityInWater
local getPlayerUnderwaterTimeRemaining = GetPlayerUnderwaterTimeRemaining
local networkIsPlayerTalking = NetworkIsPlayerTalking
local getClockHours = GetClockHours
local getClockMinutes = GetClockMinutes
local getPlayerMaxStamina = GetPlayerMaxStamina

local function getFormattedHudTime()
    local timeSource = UserSettingsData and UserSettingsData.playerInfoTime

    if timeSource == "local" then
        local _, _, _, hour, minute = GetLocalTime()
        return string.format("%s:%s", string.format("%02d", hour), string.format("%02d", minute))
    end

    return string.format(
        "%s:%s",
        string.format("%02d", getClockHours()),
        string.format("%02d", getClockMinutes())
    )
end

local function getHudHeading()
    if UserSettingsData and UserSettingsData.compassFollowCamera then
        local cameraRotation = getGameplayCamRot(0)
        return (cameraRotation.z + 360.0) % 360.0
    end

    return getEntityHeading(cache.ped)
end

local function getStreetNameByHash(streetHash)
    local customStreetNames = Config.CustomStreetNames
    local streetName = customStreetNames and customStreetNames[(streetHash & 0xFFFFFFFF)]

    if not streetName then
        streetName = getStreetNameFromHashKey(streetHash) or "Unknown"
    end

    return streetName
end

local function getStreetDataFromCoords(coords)
    local primaryStreetHash, crossingStreetHash = getStreetNameAtCoord(coords.x, coords.y, coords.z)
    if primaryStreetHash == 0 and crossingStreetHash == 0 then
        return false
    end

    local primaryStreetName = getStreetNameByHash(primaryStreetHash)
    local fullStreetName = primaryStreetName

    if crossingStreetHash > 0 then
        fullStreetName = ("%s / %s"):format(primaryStreetName, getStreetNameByHash(crossingStreetHash))
    end

    return primaryStreetName, fullStreetName
end

local function getConfiguredSpeedLimitForStreet(streetName)
    if not streetName or type(Config.SpeedLimits) ~= "table" then
        return false
    end

    return Config.SpeedLimits[streetName] or false
end

local function getCompassDirectionAndHeading()
    local heading = getHudHeading()
    local directions = { "N", "NW", "W", "SW", "S", "SE", "E", "NE" }

    local directionIndex = math.floor((heading + 22.5) / 45) + 1
    if directionIndex > #directions then
        directionIndex = 1
    end

    return directions[directionIndex], heading
end

local function getZoneName(zoneCode)
    local customZoneName = Config.CustomZoneNames and Config.CustomZoneNames[zoneCode]
    if customZoneName then
        return customZoneName
    end

    return getLabelText(zoneCode)
end

local function getAreaNameFromCoords(coords)
    local zoneCode = getNameOfZone(coords.x, coords.y, coords.z)
    local zoneName = getZoneName(zoneCode)

    if zoneName == "NULL" or not zoneName then
        return zoneCode
    end

    return zoneName
end

function GeneratePedHeadshot()
    if not (Config.ShowComponents and Config.ShowComponents.pedAvatar) then
        return false
    end

    local hasPedReady = pcall(function()
        lib.waitFor(function()
            return cache.ped and DoesEntityExist(cache.ped) and true or nil
        end, nil, 5000)
    end)

    if not hasPedReady then
        return false
    end

    for _ = 1, 2 do
        local headshotHandle = RegisterPedheadshot(cache.ped)
        if headshotHandle and headshotHandle ~= -1 then
            local headshotReady = pcall(function()
                lib.waitFor(function()
                    return IsPedheadshotReady(headshotHandle) and IsPedheadshotValid(headshotHandle) and true or nil
                end, nil, 8000)
            end)

            if headshotReady then
                local txd = GetPedheadshotTxdString(headshotHandle)
                if txd and txd ~= "" then
                    UnregisterPedheadshot(headshotHandle)
                    return string.format("https://nui-img/%s/%s", txd, txd)
                end
            end

            UnregisterPedheadshot(headshotHandle)
        end

        Wait(100)
    end

    return false
end

local function getPedUpdateInterval()
    local performanceMode = UserSettingsData and UserSettingsData.performanceMode

    if performanceMode == "ultra" then
        return 500
    elseif performanceMode == "performance" then
        return 1000
    elseif performanceMode == "lowResmon" then
        return 2000
    end

    return 1500
end

local isTalkingThreadRunning = false
function CreateIsTalkingThread()
    if isTalkingThreadRunning then
        return
    end

    isTalkingThreadRunning = true

    CreateThread(function()
        local lastTalkingState = false
        
        while IsHudRunning do
            local isTalking = networkIsPlayerTalking(cache.playerId)
            
            if isTalking ~= lastTalkingState then
                lastTalkingState = isTalking
                SendNUIMessage({
                    type = "isTalking",
                    isTalking = isTalking
                })
            end

            Wait(500)
        end

        isTalkingThreadRunning = false
    end)
end

local playerThreadRunning = false
local isPlayerDeadCached = false
local deathRefreshTick = 0
local lastPedData = {}

local function getCurrentPedOxygen(playerId, ped, isDead)
    if isDead then
        return 0
    end

    if isEntityInWater(ped) then
        if IsPedSwimmingUnderWater(ped) then
            return getPlayerUnderwaterTimeRemaining(playerId) * 10
        end

        return GetPlayerStamina(playerId)
    end

    if not cache.vehicle then
        local remainingSprintStamina = math.max(0, getPlayerSprintStaminaRemaining(playerId))
        local maxStamina = getPlayerMaxStamina(playerId)
        local depletion = 1 - (remainingSprintStamina / maxStamina)
        return depletion * 100
    end

    return 100
end

local function hasSignificantPedDataChanged(newData)
    if not lastPedData then return true end
    
    if math.abs((newData.health or 0) - (lastPedData.health or 0)) > 2 then return true end
    if (newData.armour or 0) ~= (lastPedData.armour or 0) then return true end
    if math.abs((newData.oxygen or 0) - (lastPedData.oxygen or 0)) > 5 then return true end
    if newData.job ~= lastPedData.job then return true end
    if newData.gang ~= lastPedData.gang then return true end
    if newData.streetName ~= lastPedData.streetName then return true end
    if newData.areaName ~= lastPedData.areaName then return true end
    if newData.nearestPostal ~= lastPedData.nearestPostal then return true end
    if newData.cardinalDirection ~= lastPedData.cardinalDirection then return true end
    if newData.cash ~= lastPedData.cash then return true end
    if newData.bank ~= lastPedData.bank then return true end
    if newData.dirtyMoney ~= lastPedData.dirtyMoney then return true end
    
    return false
end

function CreatePlayerThread()
    if playerThreadRunning then
        return
    end

    playerThreadRunning = true
    Framework.Client.CreateEventListeners()

    local interval = getPedUpdateInterval()

    CreateThread(function()
        while IsHudRunning and cache.ped do
            if deathRefreshTick == 0 then
                isPlayerDeadCached = Framework.Client.IsPlayerDead()
                deathRefreshTick = 5
            else
                deathRefreshTick = deathRefreshTick - 1
            end

            local health = isPlayerDeadCached and 0 or (getEntityHealth(cache.ped) - 100)
            local armour = getPedArmour(cache.ped)
            local oxygen = getCurrentPedOxygen(cache.playerId, cache.ped, isPlayerDeadCached)
            local formattedTime = getFormattedHudTime()
            local coords = getEntityCoords(cache.ped)

            local cardinalDirection, heading = getCompassDirectionAndHeading()
            local primaryStreet, fullStreet = getStreetDataFromCoords(coords)
            local areaName = getAreaNameFromCoords(coords)

            local pedData = {
                health = health,
                armour = armour,
                food = Framework.CachedPlayerData.hunger or false,
                water = Framework.CachedPlayerData.thirst or false,
                oxygen = oxygen or false,
                stress = Framework.CachedPlayerData.stress or false,
                job = Framework.CachedPlayerData.job,
                gang = Framework.CachedPlayerData.gang,
                time = formattedTime,
                playerId = cache.serverId,
                cash = Framework.CachedPlayerData.cash,
                bank = Framework.CachedPlayerData.bank,
                dirtyMoney = Framework.CachedPlayerData.dirtyMoney,
                micRange = Framework.CachedPlayerData.micRange,
                radioActive = Framework.CachedPlayerData.radioActive,
                radioChannel = LocalPlayer.state.radioChannel or 0,
                voiceModes = Framework.CachedPlayerData.voiceModes,
                cardinalDirection = cardinalDirection,
                heading = heading,
                streetName = fullStreet or areaName,
                areaName = areaName,
                nearestPostal = GetNearestPostal(coords),
                speedLimit = getConfiguredSpeedLimitForStreet(primaryStreet)
            }

            if hasSignificantPedDataChanged(pedData) then
                lastPedData = pedData
                SendNUIMessage({
                    type = "pedData",
                    pedData = pedData
                })
            end

            Wait(interval)
        end

        playerThreadRunning = false
    end)
end
