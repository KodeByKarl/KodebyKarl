Locale = Locales[Config.Locale or "en"]

local isNUIReady = false
local screenResolution = {}
IsHudRunning = false
IsHudVisible = true
UserSettingsData = {}
UserLayoutData = {}

function DebugPrint(message)
    if Config.Debug then
        print(("[JG HUD Debug]: %s"):format(message))
    end
end

function GetVehicleType(vehicle)
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        return nil
    end
    
    local model = GetEntityModel(vehicle)
    
    if IsThisModelABoat(model) or IsThisModelAJetski(model) then
        return "sea"
    elseif IsThisModelAHeli(model) or IsThisModelAPlane(model) then
        return "air"
    elseif IsThisModelATrain(model) then
        return "train"
    elseif IsThisModelABicycle(model) then
        return "bicycle"
    else
        return "land"
    end
end

function IsVehicleElectric(vehicle)
    if GetGameBuildNumber() >= 3258 then
        return Citizen.InvokeNative(0x1F0B79228E461EC9, GetEntityModel(vehicle)) == 1
    end
    
    return lib.table.contains(Config.ElectricVehicles, GetEntityArchetypeName(vehicle))
end

function DisplayRadarConditionally()
    local shouldShow = IsHudVisible
    local showMinimapInVehicle = Config.ShowMinimapInVehicle
    local showMinimapOnFoot = Config.ShowMinimapOnFoot
    
    if showMinimapInVehicle == nil then
        showMinimapInVehicle = true
    end
    
    if showMinimapOnFoot == nil then
        showMinimapOnFoot = true
    end
    
    if UserSettingsData then
        if UserSettingsData.showMinimapInVehicle ~= nil then
            showMinimapInVehicle = UserSettingsData.showMinimapInVehicle
        end
        
        if UserSettingsData.showMinimapOnFoot ~= nil then
            showMinimapOnFoot = UserSettingsData.showMinimapOnFoot
        end
    end
    
    if shouldShow then
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            shouldShow = showMinimapInVehicle
        else
            shouldShow = showMinimapOnFoot
        end
    end
    
    DisplayRadar(shouldShow)
    SetBigmapActive(false, false)
    
    if Config.UpdateRadarZoom then
        SetRadarZoom(1100)
    end
    
    return shouldShow
end

function GetNUIScreenResolution()
    if screenResolution and screenResolution.width and screenResolution.height then
        return screenResolution.width, screenResolution.height
    end
    
    return GetActualScreenResolution()
end

function GetNUIAspectRatio()
    if screenResolution and screenResolution.width and screenResolution.height then
        return screenResolution.width / screenResolution.height
    end
    
    return GetAspectRatio(false)
end

function SetHudVisibility(visible)
    IsHudVisible = visible
    
    if not visible then
        SetMinimapClipType(0)
        DisplayRadar(false)
        SendNUIMessage({
            type = "hideHud"
        })
    else
        local radarStyle = UserSettingsData and UserSettingsData.radarStyle
        SetMinimapClipType((radarStyle == "circular") and 1 or 0)
        DisplayRadarConditionally()
        SendNUIMessage({
            type = "showHud"
        })
    end
end

local isPauseMenuThreadRunning = false

function CreatePauseMenuThread()
    if isPauseMenuThreadRunning then
        return
    end
    
    isPauseMenuThreadRunning = true
    local wasPauseMenuActive = IsPauseMenuActive()
    
    CreateThread(function()
        while IsHudRunning do
            Wait(1000)
            
            local isPauseMenuActive = IsPauseMenuActive()
            
            if wasPauseMenuActive ~= isPauseMenuActive then
                wasPauseMenuActive = isPauseMenuActive
                SetHudVisibility(not isPauseMenuActive)
            end
        end
        
        isPauseMenuThreadRunning = false
    end)
end

function SetRadarMaskAndPosition(layoutData, settingsData)
    local radarStyle = settingsData and settingsData.radarStyle or "rounded"
    local minimapKey = ("%sMinimap"):format(settingsData and settingsData.radarStyle or "rounded")
    local minimapConfig = layoutData and layoutData[minimapKey]
    
    local left, top, width, height = SetRadarMaskAndPos(
        radarStyle,
        minimapConfig and minimapConfig.offset and minimapConfig.offset.offsetX,
        minimapConfig and minimapConfig.offset and minimapConfig.offset.offsetY,
        minimapConfig and minimapConfig.dimensions and minimapConfig.dimensions.width,
        minimapConfig and minimapConfig.dimensions and minimapConfig.dimensions.height,
        settingsData and settingsData.ignoreAspectRatioLimit,
        settingsData and settingsData.showNorthBlip
    )
    
    DisplayRadarConditionally()
    
    return left, top, width, height
end

function StartThreads()
    if IsHudRunning then
        return
    end
    
    IsHudRunning = true
    
    CreateRadarThread()
    CreateHideHudComponentsThread()
    CreateIsTalkingThread()
    CreatePlayerThread()
    CreatePauseMenuThread()
    
    CreateThread(function()
        Wait(100)
        if CheckWeaponOnLoad then CheckWeaponOnLoad() end
        if CheckVehicleOnLoad then CheckVehicleOnLoad() end
        if CheckTrainOnLoad then CheckTrainOnLoad() end
    end)
end

local isInitializing = false

function InitializeHud()
    if IsHudRunning or isInitializing then
        return
    end
    
    isInitializing = true
    
    lib.waitFor(function()
        return cache.ped and isNUIReady
    end, "NUI wasn't ready or ped wasn't available; JG HUD has aborted initialisation!", 1000000)
    
    local layoutData, settingsData, defaultAllSettings = GetAllHudSettings()
    DebugPrint("1. Settings loaded")
    
    local left, top, width, height = SetRadarMaskAndPosition(layoutData, settingsData)
    DebugPrint("2. Minimap/radar loaded")
    
    local mugshot = GeneratePedHeadshot()
    DebugPrint("3. Ped headshot loaded/skipped successfully")
    
    local weaponData = GetWeaponData()
    DebugPrint("4. Weapon data retrieved/skipped successfully")
    
    DebugPrint("5. Sending initHud NUI event...")
    
    SendNUIMessage({
        type = "initHud",
        bounds = {
            left = left,
            top = top,
            width = width,
            height = height
        },
        isMinimapShowing = not IsRadarHidden(),
        showMinimapOnFoot = Config.ShowMinimapOnFoot,
        showMinimapInVehicle = Config.ShowMinimapInVehicle,
        showCompassOnFoot = Config.ShowCompassOnFoot,
        mugshot = mugshot,
        weaponData = weaponData,
        layout = layoutData,
        settings = settingsData,
        defaultAllSettings = defaultAllSettings,
        showComponents = Config.ShowComponents,
        speedMeasurement = Config.SpeedMeasurement,
        distanceMeasurement = Config.DistanceMeasurement,
        allowLayoutEditing = Config.AllowUsersToEditLayout,
        allowSettingsEditing = Config.AllowPlayersToEditSettings,
        allowServerLogoEditing = Config.AllowServerLogoEditing,
        currency = Config.Currency,
        numberFormat = Config.NumberFormat,
        locale = Locale
    })
    
    DebugPrint("6. Sent initHud NUI event")
    
    Wait(100)
    
    isInitializing = false
    StartThreads()
    
    DebugPrint("7. Started threads")
end

function UnmountHud()
    if not IsHudRunning then
        return
    end
    
    IsHudRunning = false
    
    SendNUIMessage({
        type = "unmountHud"
    })
end

RegisterNUICallback("get-bounds", function(data, callback)
    DebugPrint(json.encode(data))
    screenResolution = data
    
    local layoutData, settingsData = GetAllHudSettings()
    local left, top, width, height = SetRadarMaskAndPosition(layoutData, settingsData)
    
    callback({
        left = left,
        top = top,
        width = width,
        height = height
    })
end)

RegisterNUICallback("on-nui-ready", function(data, callback)
    screenResolution = data
    isNUIReady = true
    
    DebugPrint("NUI ready")
    DebugPrint(json.encode(data))
    
    callback(true)
end)

CreateThread(function()
    Framework.Client.SetupPlayerLoginListeners()
    Wait(1000)
    
    if LocalPlayer.state.jgHudPlayerLoggedIn then
        InitializeHud()
    end
    
    AddStateBagChangeHandler("jgHudPlayerLoggedIn", ("player:%s"):format(cache.serverId), function(bagName, key, value)
        if value then
            InitializeHud()
        else
            UnmountHud()
        end
    end)
end)

RegisterCommand(Config.ToggleHudCommand or "togglehud", function()
    SetHudVisibility(not IsHudVisible)
end)

exports("toggleHud", function(visible)
    SetHudVisibility(visible)
end)

RegisterNetEvent("jg-hud:client:toggle-hud", function(visible)
    SetHudVisibility(visible)
end)

if Config.CustomNamesShouldUpdateGameTextEntries then
    for hash, name in pairs(Config.CustomStreetNames) do
        AddTextEntryByHash(hash, name)
    end
    
    for zoneName, displayName in pairs(Config.CustomZoneNames) do
        AddTextEntryByHash(joaat(zoneName), displayName)
    end
end