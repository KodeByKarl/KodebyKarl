local Config = require 'configs.freecam'

if not Config.Enabled then return end

local active = false
local cam = nil
local camCoords = vector3(0.0, 0.0, 0.0)
local camRot = vector3(0.0, 0.0, 0.0)
local speed = 1.0

local TEXTUI_STYLE = {
    borderRadius = '0px',
    backgroundColor = 'rgba(10, 15, 26, 0.82)',
    borderBottom = 'none',
    boxShadow = 'none',
    fontSize = '14px',
    padding = '8px 20px',
}

local toggleFreecam

local function hideTextUI()
    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
end

local function showHud(currentSpeed, mult)
    local text = string.format(
        '[W/A/S/D] Move   [Q/E] Down/Up   [Shift] Fast   [Alt] Slow   [Scroll] Speed: %.1fx   [BACKSPACE] Exit',
        currentSpeed * mult
    )
    lib.showTextUI(text, {
        position = 'bottom-center',
        style = TEXTUI_STYLE,
    })
end

local function restorePlayer()
    local ped = PlayerPedId()

    if DoesCamExist(cam) then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
    end

    ClearFocus()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    NetworkSetFriendlyFireOption(true)
    SetEntityCollision(ped, true, true)
    hideTextUI()
end

local function freecamThread()
    local sensitivity = 4.0
    local minSpeed = 0.1
    local maxSpeed = 10.0

    while active and DoesCamExist(cam) do
        DisableAllControlActions(0)
        EnableControlAction(0, 249, true) -- Voice (N)
        EnableControlAction(0, 245, true) -- Chat (T)
        EnableControlAction(0, 200, true) -- Pause (ESC)
        EnableControlAction(0, 199, true) -- Pause (P)

        local mouseX = GetDisabledControlNormal(0, 1) * sensitivity
        local mouseY = GetDisabledControlNormal(0, 2) * sensitivity

        local newPitch = math.max(-88.0, math.min(88.0, camRot.x - mouseY))
        local newYaw = (camRot.z - mouseX) % 360.0
        camRot = vector3(newPitch, 0.0, newYaw)
        SetCamRot(cam, camRot.x, 0.0, camRot.z, 2)

        local radZ = math.rad(camRot.z)
        local radX = math.rad(camRot.x)
        local cosX = math.cos(radX)

        local forward = vector3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
        local right = vector3(math.cos(radZ), math.sin(radZ), 0.0)
        local up = vector3(0.0, 0.0, 1.0)

        if IsDisabledControlJustPressed(0, 241) then
            speed = math.min(maxSpeed, speed + 0.2)
        elseif IsDisabledControlJustPressed(0, 242) then
            speed = math.max(minSpeed, speed - 0.2)
        end

        local mult = 1.0
        if IsDisabledControlPressed(0, 21) then
            mult = 3.0
        elseif IsDisabledControlPressed(0, 19) or IsDisabledControlPressed(0, 36) then
            mult = 0.25
        end

        local moveSpeed = speed * mult

        if IsDisabledControlPressed(0, 32) then
            camCoords = camCoords + (forward * moveSpeed)
        end
        if IsDisabledControlPressed(0, 33) then
            camCoords = camCoords - (forward * moveSpeed)
        end
        if IsDisabledControlPressed(0, 34) then
            camCoords = camCoords - (right * moveSpeed)
        end
        if IsDisabledControlPressed(0, 35) then
            camCoords = camCoords + (right * moveSpeed)
        end
        if IsDisabledControlPressed(0, 38) or IsDisabledControlPressed(0, 22) then
            camCoords = camCoords + (up * moveSpeed)
        end
        if IsDisabledControlPressed(0, 44) then
            camCoords = camCoords - (up * moveSpeed)
        end

        SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
        SetFocusPosAndVel(camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0)

        if IsDisabledControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 202) then
            toggleFreecam()
            break
        end

        showHud(speed, mult)
        Wait(0)
    end

    hideTextUI()
end

toggleFreecam = function()
    local ped = PlayerPedId()

    active = not active

    if active then
        local gameplayCamCoord = GetGameplayCamCoord()
        local gameplayCamRot = GetGameplayCamRot(2)

        camCoords = gameplayCamCoord
        camRot = vector3(gameplayCamRot.x, 0.0, gameplayCamRot.z)
        speed = 1.0

        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
        SetCamRot(cam, camRot.x, 0.0, camRot.z, 2)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)

        FreezeEntityPosition(ped, true)
        if Config.KeepPlayerVisible == false then
            SetEntityVisible(ped, false, false)
            SetEntityCollision(ped, false, false)
        else
            SetEntityVisible(ped, true, false)
            SetEntityCollision(ped, true, true)
        end
        NetworkSetFriendlyFireOption(false)

        CreateThread(freecamThread)
        lib.notify({
            title = 'FREECAM',
            description = 'Freecam enabled',
            type = 'success',
            duration = 3000,
        })
    else
        restorePlayer()
        TriggerServerEvent('kodebykarl-utils:freecam:stopped')
        lib.notify({
            title = 'FREECAM',
            description = 'Freecam disabled',
            type = 'error',
            duration = 3000,
        })
    end
end

RegisterNetEvent('cfx-keydi-utils:freecam', function()
    toggleFreecam()
end)

exports('IsFreecamActive', function()
    return active
end)

exports('ToggleFreecam', function()
    toggleFreecam()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not active then return end
    active = false
    restorePlayer()
end)
