--[[
    Death freecam — G toggle after spawn timer UI.
    Player body stays visible. Max 100m from death origin;
    exceeding the leash resets and disables the cam.
]]

local MAX_RANGE = 100.0
local active = false
local cam = nil
local camCoords = vector3(0.0, 0.0, 0.0)
local camRot = vector3(0.0, 0.0, 0.0)
local origin = vector3(0.0, 0.0, 0.0)
local speed = 0.8

local function notifyNui(isActive)
    SendNUIMessage({
        type = 'updateDeathScreen',
        update = 'freecam',
        freecam = isActive == true,
    })
end

local function destroyCam()
    if cam and DoesCamExist(cam) then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(cam, false)
    end
    cam = nil
    ClearFocus()
    ClampGameplayCamPitch(-90.0, 90.0)
end

local function keepBodyVisible()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    pcall(function()
        SetEntityLocallyVisible(ped)
    end)
end

local function stopDeathFreecam(resetToBody)
    if not active and not cam then
        notifyNui(false)
        return
    end
    active = false
    if resetToBody then
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            local coords = GetEntityCoords(ped)
            origin = coords
        end
    end
    destroyCam()
    keepBodyVisible()
    notifyNui(false)
    TriggerServerEvent('kodebykarl-ambulance:server:deathFreecam', false)
end

local function startDeathFreecam()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return false end

    keepBodyVisible()
    origin = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local rad = math.rad(heading)

    -- Start behind + above the corpse so the player sees their own body
    camCoords = vector3(
        origin.x + (math.sin(rad) * 3.2),
        origin.y - (math.cos(rad) * 3.2),
        origin.z + 1.35
    )
    camRot = vector3(-8.0, 0.0, heading)

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(cam, camRot.x, 0.0, camRot.z, 2)
    SetCamFov(cam, 50.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 250, true, true)

    active = true
    speed = 0.8
    notifyNui(true)
    TriggerServerEvent('kodebykarl-ambulance:server:deathFreecam', true)

    CreateThread(function()
        local sensitivity = 4.0
        while active and cam and DoesCamExist(cam) do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 36, true)
            DisableControlAction(0, 44, true)
            EnableControlAction(0, 47, true) -- G toggle
            EnableControlAction(0, 245, true)

            keepBodyVisible()

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

            local mult = 1.0
            if IsDisabledControlPressed(0, 21) then
                mult = 2.2
            elseif IsDisabledControlPressed(0, 36) then
                mult = 0.35
            end
            local move = speed * mult

            if IsDisabledControlPressed(0, 32) then
                camCoords = camCoords + (forward * move)
            end
            if IsDisabledControlPressed(0, 33) then
                camCoords = camCoords - (forward * move)
            end
            if IsDisabledControlPressed(0, 34) then
                camCoords = camCoords - (right * move)
            end
            if IsDisabledControlPressed(0, 35) then
                camCoords = camCoords + (right * move)
            end
            if IsDisabledControlPressed(0, 38) or IsDisabledControlPressed(0, 22) then
                camCoords = camCoords + (up * move)
            end
            if IsDisabledControlPressed(0, 44) then
                camCoords = camCoords - (up * move)
            end

            local pedNow = PlayerPedId()
            if pedNow and pedNow ~= 0 then
                origin = GetEntityCoords(pedNow)
            end

            local dist = #(camCoords - origin)
            if dist > MAX_RANGE then
                stopDeathFreecam(true)
                break
            end

            SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
            SetFocusPosAndVel(camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0)
            Wait(0)
        end
    end)

    return true
end

local DeathCam = {}

function DeathCam.Toggle()
    if active then
        stopDeathFreecam(false)
        return false
    end
    return startDeathFreecam()
end

function DeathCam.Stop()
    stopDeathFreecam(false)
end

function DeathCam.IsActive()
    return active == true
end

return DeathCam
