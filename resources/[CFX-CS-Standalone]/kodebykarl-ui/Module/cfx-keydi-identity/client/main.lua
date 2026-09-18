ESX = exports["es_extended"]:getSharedObject()
isIdentityOpen = false

local identityCam = nil
local focusThreadActive = false

function IsIdentityOpen()
    return isIdentityOpen
end

exports('IsIdentityOpen', IsIdentityOpen)
exports('OpenIdentity', function()
    ToggleUI(true)
end)

local function DestroyIdentityCam()
    if identityCam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(identityCam, false)
        identityCam = nil
    end
end

local function CreateIdentityCam()
    DestroyIdentityCam()

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local rad = math.rad(heading)
    local camCoords = vector3(
        coords.x - math.sin(rad) * 1.6,
        coords.y + math.cos(rad) * 1.6,
        coords.z + 0.45
    )

    identityCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(identityCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtEntity(identityCam, ped, 0.0, 0.0, 0.55, true)
    SetCamFov(identityCam, 40.0)
    SetCamActive(identityCam, true)
    RenderScriptCams(true, true, 750, true, true)
end

local function StartIdentityLockThread()
    if focusThreadActive then return end
    focusThreadActive = true

    CreateThread(function()
        while isIdentityOpen do
            local ped = PlayerPedId()

            -- Re-assert NUI focus every tick in case another resource clears it
            if not IsNuiFocused() then
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(false)
            end

            FreezeEntityPosition(ped, true)
            SetPedCanRagdoll(ped, false)
            NetworkSetFriendlyFireOption(false)
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            EnableControlAction(0, 249, true) -- N (push to talk) if needed
            DisplayRadar(false)

            if LocalPlayer.state then
                LocalPlayer.state.invBusy = true
                LocalPlayer.state.invHotkeys = false
            end

            Wait(0)
        end

        focusThreadActive = false
    end)
end

function ToggleUI(state)
    isIdentityOpen = state == true

    if isIdentityOpen then
        local ped = PlayerPedId()

        -- Ensure loading screen / fade is fully done before locking focus
        if IsScreenFadedOut() then
            DoScreenFadeIn(250)
            local deadline = GetGameTimer() + 3000
            while IsScreenFadedOut() and GetGameTimer() < deadline do
                Wait(0)
            end
        end

        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()

        FreezeEntityPosition(ped, true)
        NetworkSetFriendlyFireOption(false)
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        DisplayRadar(false)

        if LocalPlayer.state then
            LocalPlayer.state.invBusy = true
            LocalPlayer.state.invHotkeys = false
        end

        CreateIdentityCam()
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = "show" })
        StartIdentityLockThread()

        -- Extra focus pulses — spawn/HUD scripts often clear focus right after load
        CreateThread(function()
            for _ = 1, 10 do
                if not isIdentityOpen then break end
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(false)
                Wait(200)
            end
        end)
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = "hide" })
        DestroyIdentityCam()

        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        NetworkSetFriendlyFireOption(true)
        SetPedCanRagdoll(ped, true)
        DisplayRadar(true)

        if LocalPlayer.state then
            LocalPlayer.state.invBusy = false
            LocalPlayer.state.invHotkeys = true
        end
    end

    IdentityUtils.Debug("NUI Visibility set to: %s", state)
end

function RegisterCharacter(data)
    ESX.TriggerServerCallback("esx_identity:registerIdentity", function(success)
        if success then
            ToggleUI(false)
            ESX.ShowNotification("Character registered successfully!", "success")

            local function onCreationFinished()
                IdentityUtils.Debug("Appearance creation finished")
                TriggerEvent("cfx-keydi-welcome:show")
                -- Backup: illenium also fires this after routing-bucket reset.
                SetTimeout(1800, function()
                    TriggerEvent("pma-voice:client:creationFinished")
                end)
            end

            IdentityUtils.Debug("illenium-appearance state: %s | fadedIn: %s | switch: %s",
                GetResourceState("illenium-appearance"),
                tostring(IsScreenFadedIn()),
                tostring(IsPlayerSwitchInProgress()))

            if not IsScreenFadedIn() then
                DoScreenFadeIn(500)
                local deadline = GetGameTimer() + 5000
                while not IsScreenFadedIn() and GetGameTimer() < deadline do
                    Wait(0)
                end
            end

            TriggerEvent("esx_skin:openSaveableMenu", onCreationFinished, onCreationFinished)
            IdentityUtils.Debug("openSaveableMenu dispatched")
        else
            ESX.ShowNotification("Identity registration failed. Try again.", "error")
        end
    end, data)
end

function ToggleScoreboard(state, data)
    -- Never steal focus from identity registration
    if isIdentityOpen and state then return end

    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "scoreboard:show" or "scoreboard:hide",
        data = data
    })
    IdentityUtils.Debug("Scoreboard visibility set to: %s", state)
end

exports('ToggleScoreboard', ToggleScoreboard)
