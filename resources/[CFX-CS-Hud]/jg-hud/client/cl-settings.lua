IsSettingsOpen = false
local cachedPerformanceMode = nil

local function getKvpPrefix()
    return Config.DefaultSettingsKvpPrefix or "hud-"
end

local function getLayoutKvpKey()
    return ("%slayout"):format(getKvpPrefix())
end

local function getSettingsKvpKey()
    return ("%ssettings"):format(getKvpPrefix())
end

local function decodeJsonOrDefault(raw, fallback)
    if not raw then
        return fallback
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then
        return fallback
    end

    return decoded
end

local function getCurrentRadarStyle()
    return (UserSettingsData and UserSettingsData.radarStyle) or "rounded"
end

local function getStyleMinimapLayout(layoutData, radarStyle)
    return layoutData and layoutData[("%sMinimap"):format(radarStyle or "rounded")]
end

local function applyRadarFromLayout(layoutData, radarStyle, ignoreAspectRatioLimit, showNorthBlip)
    local minimapLayout = getStyleMinimapLayout(layoutData, radarStyle)

    local left, top, width, height = SetRadarMaskAndPos(
        radarStyle or "rounded",
        minimapLayout and minimapLayout.offset and minimapLayout.offset.offsetX,
        minimapLayout and minimapLayout.offset and minimapLayout.offset.offsetY,
        minimapLayout and minimapLayout.dimensions and minimapLayout.dimensions.width,
        minimapLayout and minimapLayout.dimensions and minimapLayout.dimensions.height,
        ignoreAspectRatioLimit,
        showNorthBlip
    )

    return left, top, width, height
end

function GetAllHudSettings()
    local defaultSettingsData = nil
    local defaultSettingsRaw = LoadResourceFile(GetCurrentResourceName(), Config.DefaultSettingsData)
    if defaultSettingsRaw then
        defaultSettingsData = decodeJsonOrDefault(defaultSettingsRaw, nil)
    else
        print(("Default settings error: Could not find %s file"):format(Config.DefaultSettingsData))
    end

    local defaultLayout = {}
    local defaultSettings = {}
    if type(defaultSettingsData) == "table" then
        defaultLayout = defaultSettingsData.layout or {}
        defaultSettings = defaultSettingsData.settings or {}
    end

    if Config.DevDeleteAllUserSettingsOnStart then
        DeleteResourceKvp(getLayoutKvpKey())
        DeleteResourceKvp(getSettingsKvpKey())
    end

    local layoutKvpData = decodeJsonOrDefault(GetResourceKvpString(getLayoutKvpKey()) or "{}", {})
    local finalLayout = defaultLayout
    if Config.AllowUsersToEditLayout and next(layoutKvpData) ~= nil then
        finalLayout = layoutKvpData
    end
    UserLayoutData = finalLayout

    local settingsKvpData = decodeJsonOrDefault(GetResourceKvpString(getSettingsKvpKey()) or "{}", {})
    local finalSettings = defaultSettings
    if Config.AllowPlayersToEditSettings and next(settingsKvpData) ~= nil then
        finalSettings = settingsKvpData
    end

    -- Preserve legacy behavior: if performance mode exists in user KVP, apply it.
    local performanceModeFromKvp = settingsKvpData and settingsKvpData.performanceMode
    if performanceModeFromKvp then
        finalSettings.performanceMode = performanceModeFromKvp
        cachedPerformanceMode = performanceModeFromKvp
    end

    UserSettingsData = finalSettings
    return finalLayout, finalSettings, defaultSettingsData
end
GetAllHudSettings = GetAllHudSettings

RegisterCommand(Config.OpenSettingsCommand or "settings", function()
    ToggleVehicleControl(false)
    DisplayRadar(false)
    TriggerScreenblurFadeIn(500)
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "showSettings" })
    IsSettingsOpen = true
end)

RegisterNUICallback("close-settings", function(_, cb)
    IsSettingsOpen = false
    TriggerScreenblurFadeOut(500)
    SetNuiFocus(false, false)
    DisplayRadarConditionally()
    cb(true)
end)

RegisterNUICallback("save-hud-layout", function(data, cb)
    if not IsHudRunning or not data then
        return cb(false)
    end

    local radarStyle = getCurrentRadarStyle()
    local left, top, width, height = applyRadarFromLayout(
        data,
        radarStyle,
        UserSettingsData and UserSettingsData.ignoreAspectRatioLimit,
        UserSettingsData and UserSettingsData.showNorthBlip
    )

    SetResourceKvp(getLayoutKvpKey(), json.encode(data))
    UserLayoutData = data

    cb({
        bounds = {
            left = left,
            top = top,
            width = width,
            height = height
        }
    })
end)

RegisterNUICallback("save-hud-settings", function(data, cb)
    if not IsHudRunning or not data then
        return cb(false)
    end

    local hasRadarVisualChanges =
        data.radarStyle ~= UserSettingsData.radarStyle
        or data.ignoreAspectRatioLimit ~= UserSettingsData.ignoreAspectRatioLimit
        or data.showNorthBlip ~= UserSettingsData.showNorthBlip

    if hasRadarVisualChanges then
        local left, top, width, height = applyRadarFromLayout(
            UserLayoutData,
            data.radarStyle or "rounded",
            data.ignoreAspectRatioLimit or false,
            data.showNorthBlip or false
        )

        cb({
            bounds = {
                left = left,
                top = top,
                width = width,
                height = height
            }
        })
    end

    SetResourceKvp(getSettingsKvpKey(), json.encode(data))
    UserSettingsData = data

    if IsHudRunning and data.performanceMode ~= cachedPerformanceMode then
        cachedPerformanceMode = data.performanceMode
        IsHudRunning = false
        Wait(100)
        StartThreads()

        if IsSettingsOpen then
            DisplayRadar(false)
        end
    end

    cb(false)
end)
