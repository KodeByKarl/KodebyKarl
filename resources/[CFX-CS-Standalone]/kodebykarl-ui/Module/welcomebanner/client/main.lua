local requested = false
local panelOpen = false
local volumeOpen = false
local listenerVolume = 1.0
local ESX = ESX or exports["es_extended"]:getSharedObject()

local LISTENER_KVP = "cfx-keydi-welcomebanner:listenerVolume"

local function Clamp01(value, fallback)
    value = tonumber(value)
    if not value then
        return fallback or 1.0
    end
    if value < 0 then return 0.0 end
    if value > 1 then return 1.0 end
    return value
end

local function PushListenerVolume()
    SendNUIMessage({
        action = "cfx-keydi-welcomebanner:listenerVolume",
        volume = listenerVolume,
    })
end

local function LoadListenerVolume()
    local saved = GetResourceKvpString(LISTENER_KVP)
    if saved and saved ~= "" then
        listenerVolume = Clamp01(tonumber(saved), ConfigWelcomeBanner.DefaultListenerVolume or 1.0)
    else
        listenerVolume = Clamp01(ConfigWelcomeBanner.DefaultListenerVolume, 1.0)
    end
    PushListenerVolume()
end

local function SaveListenerVolume(volume)
    listenerVolume = Clamp01(volume, listenerVolume)
    SetResourceKvp(LISTENER_KVP, tostring(listenerVolume))
    PushListenerVolume()
end

local function SyncNuiFocus()
    local focused = panelOpen or volumeOpen
    SetNuiFocus(focused, focused)
end

local function IsRemotePath(path)
    return path:find("^https?://") or path:find("^nui://") or path:find("^https://cfx%-nui%-")
end

local function ResolveAsset(name, folders)
    if type(name) ~= "string" or name == "" then
        return ""
    end

    if IsRemotePath(name) then
        return name
    end

    local resource = GetCurrentResourceName()
    local ext = name:match("%.([%w]+)$")
    ext = ext and ext:lower() or ""

    local isAudio = (ext == "mp3" or ext == "ogg" or ext == "wav" or ext == "webm")
    local search = folders
    if not search then
        search = isAudio and { "sounds", "images" } or { "images", "sounds" }
    end

    for _, folder in ipairs(search) do
        local path = ("Module/welcomebanner/%s/%s"):format(folder, name)
        if LoadResourceFile(resource, path) then
            return ("https://cfx-nui-%s/%s"):format(resource, path)
        end
    end

    local fallbackFolder = isAudio and "sounds" or "images"
    return ("https://cfx-nui-%s/Module/welcomebanner/%s/%s"):format(resource, fallbackFolder, name)
end

local hideToken = 0

local function HideWelcomeBanner()
    SendNUIMessage({
        action = "cfx-keydi-welcomebanner:hide",
    })
end

local function ClampBannerSize(width, height)
    local gifCfg = ConfigWelcomeBanner.Image or ConfigWelcomeBanner.Gif or {}
    local w = tonumber(width) or tonumber(gifCfg.Width) or 350
    local h = tonumber(height) or tonumber(gifCfg.Height) or 200
    local maxW = tonumber(gifCfg.MaxWidth) or 480
    local maxH = tonumber(gifCfg.MaxHeight) or 270

    if w > maxW then w = maxW end
    if h > maxH then h = maxH end
    if w < 64 then w = 64 end
    if h < 48 then h = 48 end

    return math.floor(w), math.floor(h)
end

local function ShowWelcomeBanner(payload)
    payload = type(payload) == "table" and payload or {}

    hideToken = hideToken + 1
    local token = hideToken
    local duration = math.max(1, tonumber(payload.duration) or tonumber(ConfigWelcomeBanner.Duration) or 8)
    local imageCfg = ConfigWelcomeBanner.Image or ConfigWelcomeBanner.Gif or {}
    local width, height = ClampBannerSize(payload.width, payload.height)
    local offset = ConfigWelcomeBanner.Offset or {}

    SendNUIMessage({
        action = "cfx-keydi-welcomebanner:show",
        data = {
            duration = duration,
            width = width,
            height = height,
            maxWidth = tonumber(imageCfg.MaxWidth) or 480,
            maxHeight = tonumber(imageCfg.MaxHeight) or 270,
            bottom = offset.bottom or 24,
            right = offset.right or 24,
            image = ResolveAsset(payload.gif or payload.image or ""),
            sound = ResolveAsset(payload.sound),
            volume = tonumber(payload.volume) or 0.6,
            listenerVolume = listenerVolume,
            playerName = payload.playerName or "",
        },
    })

    SetTimeout(duration * 1000, function()
        if token == hideToken then
            HideWelcomeBanner()
        end
    end)
end

local function RequestBanner()
    if requested then return end
    requested = true
    TriggerServerEvent("cfx-keydi-welcomebanner:announce")
end

local function RequestBannerAfterSpawn()
    CreateThread(function()
        local deadline = GetGameTimer() + 60000
        while GetGameTimer() < deadline do
            if NetworkIsPlayerActive(PlayerId()) and not IsScreenFadedOut() then
                break
            end
            Wait(200)
        end

        Wait(tonumber(ConfigWelcomeBanner.Delay) or 3000)
        RequestBanner()
    end)
end

local function SetVolumePanel(state)
    volumeOpen = state
    SendNUIMessage({
        action = state and "cfx-keydi-welcomebanner:volume:show" or "cfx-keydi-welcomebanner:volume:hide",
        data = state and { volume = listenerVolume } or nil,
    })
    SyncNuiFocus()
end

local function CloseVolumePanel()
    if not volumeOpen then return end
    SetVolumePanel(false)
end

local function OpenVolumePanel()
    if volumeOpen then
        CloseVolumePanel()
        return
    end

    if panelOpen then
        panelOpen = false
        SendNUIMessage({
            action = "cfx-keydi-welcomebanner:panel:hide",
        })
    end

    SetVolumePanel(true)
end

local function SetPanel(state, data)
    panelOpen = state
    SendNUIMessage({
        action = state and "cfx-keydi-welcomebanner:panel:show" or "cfx-keydi-welcomebanner:panel:hide",
        data = data,
    })
    SyncNuiFocus()
end

local function ClosePanel()
    if not panelOpen then return end
    SetPanel(false, nil)
end

local function OpenPanel()
    if panelOpen then
        ClosePanel()
        return
    end

    ESX.TriggerServerCallback("cfx-keydi-welcomebanner:open", function(data)
        if not data then
            lib.notify({
                title = "Welcome Banner",
                description = "No access. Need staff or active VIP.",
                type = "error",
                position = "top-center",
            })
            return
        end
        CloseVolumePanel()
        SetPanel(true, data)
    end)
end

RegisterNetEvent("esx:playerLoaded", function(_, isNew)
    if isNew then return end
    RequestBannerAfterSpawn()
end)

RegisterNetEvent("cfx-keydi-welcome:show", function()
    SetTimeout(1500, RequestBanner)
end)

RegisterNetEvent("cfx-keydi-welcomebanner:show", function(payload)
    ShowWelcomeBanner(payload)
end)

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    LoadListenerVolume()
    if not NetworkIsPlayerActive(PlayerId()) then return end
    requested = false
    RequestBannerAfterSpawn()
end)

CreateThread(function()
    Wait(500)
    LoadListenerVolume()
end)

RegisterCommand(ConfigWelcomeBanner.Command or "wcb", function()
    OpenPanel()
end, false)

RegisterCommand(ConfigWelcomeBanner.VolumeCommand or "wcbv", function()
    OpenVolumePanel()
end, false)

CreateThread(function()
    local command = ConfigWelcomeBanner.Command or "wcb"
    local volumeCommand = ConfigWelcomeBanner.VolumeCommand or "wcbv"
    TriggerEvent("chat:addSuggestion", "/" .. command, "Open the Welcome Banner manager (Owner / Developer)")
    TriggerEvent("chat:addSuggestion", "." .. command, "Open the Welcome Banner manager (Owner / Developer)")
    TriggerEvent("chat:addSuggestion", "/" .. volumeCommand, "Set how loud Welcome Banner sounds are for you")
    TriggerEvent("chat:addSuggestion", "." .. volumeCommand, "Set how loud Welcome Banner sounds are for you")
end)

RegisterNUICallback("cfx-keydi-welcomebanner:close", function(_, cb)
    ClosePanel()
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("cfx-keydi-welcomebanner:volume:close", function(_, cb)
    CloseVolumePanel()
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("cfx-keydi-welcomebanner:volume:set", function(data, cb)
    data = type(data) == "table" and data or {}
    SaveListenerVolume(data.volume)
    if cb then cb({ ok = true, volume = listenerVolume }) end
end)

RegisterNUICallback("cfx-keydi-welcomebanner:add", function(data, cb)
    ESX.TriggerServerCallback("cfx-keydi-welcomebanner:add", function(result)
        if result and result.ok then
            SendNUIMessage({
                action = "cfx-keydi-welcomebanner:panel:update",
                data = { players = result.players, online = result.online },
            })
            lib.notify({
                title = "Welcome Banner",
                description = result.updated and "Banner updated." or "Banner added.",
                type = "success",
                position = "top-center",
            })
        else
            lib.notify({
                title = "Welcome Banner",
                description = result and result.message or "Failed to save banner.",
                type = "error",
                position = "top-center",
            })
        end
        if cb then cb(result or { ok = false }) end
    end, data)
end)

RegisterNUICallback("cfx-keydi-welcomebanner:remove", function(data, cb)
    ESX.TriggerServerCallback("cfx-keydi-welcomebanner:remove", function(result)
        if result and result.ok then
            SendNUIMessage({
                action = "cfx-keydi-welcomebanner:panel:update",
                data = { players = result.players, online = result.online },
            })
            lib.notify({
                title = "Welcome Banner",
                description = "Banner removed.",
                type = "success",
                position = "top-center",
            })
        else
            lib.notify({
                title = "Welcome Banner",
                description = result and result.message or "Failed to remove banner.",
                type = "error",
                position = "top-center",
            })
        end
        if cb then cb(result or { ok = false }) end
    end, data)
end)
