local isBadgeUIOpen = false
local currentBadgeHeadshotHandle = nil
local currentBadgeProp = nil

local function ClearBadgeHeadshot()
    if currentBadgeHeadshotHandle and IsPedheadshotValid(currentBadgeHeadshotHandle) then
        UnregisterPedheadshot(currentBadgeHeadshotHandle)
    end
    currentBadgeHeadshotHandle = nil
end

local function ClearBadgeProp()
    if currentBadgeProp and DoesEntityExist(currentBadgeProp) then
        DeleteEntity(currentBadgeProp)
    end
    currentBadgeProp = nil
end

-- Pedheadshot TXDs are local to each client. Never reuse another player's nui-img URL.
local function GetPedFromServerId(serverId)
    local sid = tonumber(serverId)
    if not sid then return PlayerPedId() end
    if sid == GetPlayerServerId(PlayerId()) then
        return PlayerPedId()
    end

    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerServerId(player) == sid then
            local ped = GetPlayerPed(player)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                return ped
            end
        end
    end

    return nil
end

local function GetPedHeadshotUrl(ped)
    ClearBadgeHeadshot()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return "" end

    for _ = 1, 2 do
        local handle = RegisterPedheadshot(ped)
        if not handle or handle == 0 then
            handle = RegisterPedheadshotTransparent(ped)
        end

        if handle and handle ~= 0 then
            local timeout = 2500
            while not IsPedheadshotReady(handle) and timeout > 0 do
                Wait(50)
                timeout = timeout - 50
            end

            if IsPedheadshotValid(handle) and IsPedheadshotReady(handle) then
                local txd = GetPedheadshotTxdString(handle)
                if txd and txd ~= "" then
                    currentBadgeHeadshotHandle = handle
                    -- Cache-bust so NUI does not reuse a HUD mugshot with the same TXD name
                    return ("https://nui-img/%s/%s?t=%s"):format(txd, txd, GetGameTimer())
                end
            end

            UnregisterPedheadshot(handle)
        end

        Wait(100)
    end

    return ""
end

local function PlayBadgeEmote()
    local ped = PlayerPedId()
    local emote = ConfigBadge.Emote

    RequestAnimDict(emote.dict)
    local timeout = 1000
    while not HasAnimDictLoaded(emote.dict) and timeout > 0 do
        Wait(50)
        timeout = timeout - 50
    end

    TaskPlayAnim(ped, emote.dict, emote.anim, 8.0, -8.0, emote.duration, 49, 0, false, false, false)

    -- Attach badge prop
    local propHash = GetHashKey(emote.prop)
    RequestModel(propHash)
    timeout = 1000
    while not HasModelLoaded(propHash) and timeout > 0 do
        Wait(50)
        timeout = timeout - 50
    end

    ClearBadgeProp()
    local boneIndex = GetPedBoneIndex(ped, emote.bone)
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(propHash, coords.x, coords.y, coords.z + 0.2, true, true, true)
    AttachEntityToEntity(prop, ped, boneIndex, emote.pos.x, emote.pos.y, emote.pos.z, emote.rot.x, emote.rot.y, emote.rot.z, true, true, false, true, 1, true)
    currentBadgeProp = prop

    -- Auto clean prop after emote duration
    CreateThread(function()
        Wait(emote.duration)
        ClearBadgeProp()
        StopAnimTask(ped, emote.dict, emote.anim, 1.0)
    end)
end

local function DisplayBadgeUI(data)
    if not data then return end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "cfx-keydi-badge:show",
        data = data
    })
    isBadgeUIOpen = true
end

local function CloseBadgeUI()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "cfx-keydi-badge:hide"
    })
    isBadgeUIOpen = false
    ClearBadgeHeadshot()
    ClearBadgeProp()
end

RegisterNUICallback("cfx-keydi-badge:close", function(data, cb)
    CloseBadgeUI()
    if cb then cb("ok") end
end)

local function TriggerShowBadge()
    ESX.TriggerServerCallback('cfx-keydi-badge:getBadgeData', function(result)
        if not result or not result.success then
            if ESX and ESX.ShowNotification then
                ESX.ShowNotification(result and result.message or "Cannot show badge.", "error")
            end
            return
        end

        -- Play realistic badge holding emote
        PlayBadgeEmote()

        -- Do not send a local nui-img URL. Each nearby client captures the officer ped.
        result.photoUrl = nil
        TriggerServerEvent("cfx-keydi-badge:server:showBadgeToNearby", result)
    end)
end

-- Command /badge
RegisterCommand(ConfigBadge.Command or "badge", function()
    if isBadgeUIOpen then
        CloseBadgeUI()
    else
        TriggerShowBadge()
    end
end, false)

-- Client events
RegisterNetEvent("cfx-keydi-badge:client:displayBadgeUI", function(badgeData, officerServerId)
    if type(badgeData) ~= "table" then return end
    local officerPed = GetPedFromServerId(officerServerId)
    badgeData.photoUrl = GetPedHeadshotUrl(officerPed)
    DisplayBadgeUI(badgeData)
end)

RegisterNetEvent("cfx-keydi-badge:client:closeBadgeUI", function()
    CloseBadgeUI()
end)

-- Exports
exports("OpenBadgeCard", TriggerShowBadge)
exports("CloseBadgeCard", CloseBadgeUI)
