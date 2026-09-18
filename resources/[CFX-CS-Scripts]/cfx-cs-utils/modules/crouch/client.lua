local crouched = false
LocalPlayer.state:set('Crouch', false, false)

local function loadAnimSet(anim)
    RequestAnimSet(anim)
    while not HasAnimSetLoaded(anim) do
        Wait(50)
    end
end

CreateThread(function()
    while true do
        Wait(1)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            DisableControlAction(0, 36, true)
            if not IsPauseMenuActive() and IsDisabledControlJustPressed(0, 36) then
                loadAnimSet("move_ped_crouched")
                if crouched then
                    local currentWalk = exports['scully_emotemenu']:getCurrentWalk()
                    if currentWalk ~= nil then
                        lib.requestAnimSet(currentWalk, 10000)
					    SetPedMovementClipset(ped, currentWalk, 0.2)
                    end
                    ResetPedStrafeClipset(ped)
                    ResetPedMovementClipset(ped, 0.25)
                    crouched = false
                    LocalPlayer.state.Crouch = false
                else
                    SetPedMovementClipset(ped, "move_ped_crouched", 0.25)
                    SetPedStrafeClipset(ped, "move_ped_crouched_strafing")
                    crouched = true
                    LocalPlayer.state.Crouch = true
                end
            end
        else
            crouched = false
        end
    end
end)