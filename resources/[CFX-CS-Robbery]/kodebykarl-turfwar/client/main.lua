local ESX = exports['es_extended']:getSharedObject()
local RewardProps = {}
local isBusy = false
local currentTextUiTurf = nil

-- Helper: Format Seconds into MM:SS Clock
local function formatClock(seconds)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then return '00:00' end
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return ('%02d:%02d'):format(mins, secs)
end

-- Announce Message Event
RegisterNetEvent('kodebykarl-turfwar:client:announce', function(msg, msgType)
    lib.notify({
        title = 'TURF WAR ANNOUNCEMENT',
        description = msg,
        type = msgType or 'info',
        duration = 8000
    })
end)

local function CanUseTurf(data)
    local fn = (data and data.requireFunction) or 'turfwar'
    if GetResourceState('kodebykarl-ui') ~= 'started' then
        return false
    end
    local ok, allowed = pcall(function()
        return exports['kodebykarl-ui']:HasFunction(fn)
    end)
    return ok and allowed == true
end

-- Main Rendering Loop: White 3D Markers & Key Interaction
CreateThread(function()
    while true do
        local sleep = 700
        local ped = PlayerPedId()

        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            local pCoords = GetEntityCoords(ped)
            local nearestTurf = nil
            local nearestDist = 999.0

            for id, data in pairs(Config.TurfWars) do
                if CanUseTurf(data) then
                    local dist = #(pCoords - data.coords)

                    -- Draw White 3D Marker on Ground when within 25 meters
                    if dist <= 25.0 then
                        sleep = 0

                        -- White MarkerTypeVerticalCylinder (Marker Type 1)
                        DrawMarker(
                            1,                                -- MarkerTypeVerticalCylinder (1)
                            data.coords.x, data.coords.y, data.coords.z - 1.0, -- Coords (z adjusted)
                            0.0, 0.0, 0.0,                    -- Direction
                            0.0, 0.0, 0.0,                    -- Rotation
                            2.5, 2.5, 1.0,                    -- Scale (Width, Length, Height)
                            255, 255, 255, 200,               -- Color (Pure White 255, 255, 255, 200 Alpha)
                            false, true, 2, false, nil, nil, false
                        )

                        if dist < nearestDist then
                            nearestDist = dist
                            nearestTurf = { id = id, data = data }
                        end
                    end
                end
            end

            -- Handle Nearby Key Prompt & Interaction (when within 2.0 meters)
            if nearestTurf and nearestDist <= (nearestTurf.data.interactDistance or 2.0) then
                local id = nearestTurf.id
                local data = nearestTurf.data
                local state = GlobalState[('turf_state_%s'):format(id)] or 'IDLE'
                local claimable = GlobalState[('turf_claimable_%s'):format(id)] == true

                if not isBusy then
                    if state == 'IDLE' and not claimable then
                        if currentTextUiTurf ~= ('start_%s'):format(id) then
                            currentTextUiTurf = ('start_%s'):format(id)
                            lib.showTextUI(('[E] Initiate %s'):format(data.label), {
                                position = 'bottom-center',
                                icon = 'fa-solid fa-flag-checkered',
                                style = { backgroundColor = '#140d11', color = '#ffffff', border = '1px solid #ffffff' }
                            })
                        end

                        if IsControlJustPressed(0, 38) then -- Key E
                            -- Check weapon restriction if enabled
                            if data.weapon and data.weapon.enable then
                                local _, currentWeapon = GetCurrentPedWeapon(ped, true)
                                if not data.weapon.list[currentWeapon] then
                                    lib.notify({
                                        title = 'WEAPON RESTRICTED',
                                        description = data.weapon.restrictMessage or 'You are not holding an allowed weapon for this Turf War.',
                                        type = 'error'
                                    })
                                    goto skip_action
                                end
                            end

                            if type(Config.RequiredItems) == 'table' then
                                for itemName, need in pairs(Config.RequiredItems) do
                                    local have = exports.ox_inventory:GetItemCount(itemName) or 0
                                    if have < need then
                                        local itemData = exports.ox_inventory:Items(itemName)
                                        local label = (itemData and itemData.label) or itemName
                                        lib.notify({
                                            title = 'TURF WAR',
                                            description = ('You need x%d %s to trigger this Turf War (%d/%d).'):format(need, label, have, need),
                                            type = 'error'
                                        })
                                        goto skip_action
                                    end
                                end
                            end

                            isBusy = true
                            lib.hideTextUI()
                            currentTextUiTurf = nil

                            local ok = lib.progressBar({
                                duration = 4000,
                                label = ('Initiating %s...'):format(data.label),
                                useWhileDead = false,
                                canCancel = true,
                                disable = { move = true, car = true, combat = true },
                                anim = { dict = 'missheistdockssetup1clipboard@base', clip = 'base', flag = 49 }
                            })

                            if ok then
                                TriggerServerEvent('kodebykarl-turfwar:server:startTurf', id)
                            end
                            isBusy = false
                        end

                    elseif claimable then
                        if currentTextUiTurf ~= ('claim_%s'):format(id) then
                            currentTextUiTurf = ('claim_%s'):format(id)
                            lib.showTextUI(('[E] Claim %s Rewards'):format(data.label), {
                                position = 'bottom-center',
                                icon = 'fa-solid fa-box-open',
                                style = { backgroundColor = '#140d11', color = '#2ecc71', border = '1px solid #2ecc71' }
                            })
                        end

                        if IsControlJustPressed(0, 38) then -- Key E
                            isBusy = true
                            lib.hideTextUI()
                            currentTextUiTurf = nil

                            local ok = lib.progressBar({
                                duration = data.claimTime or 8000,
                                label = ('Securing %s Rewards...'):format(data.label),
                                useWhileDead = false,
                                canCancel = true,
                                disable = { move = true, car = true, combat = true },
                                anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mecheckbox', flag = 49 }
                            })

                            if ok then
                                TriggerServerEvent('kodebykarl-turfwar:server:claimTurf', id)
                            end
                            isBusy = false
                        end

                    elseif state == 'ACTIVE' then
                        local remainingSecs = GlobalState[('turf_timer_%s'):format(id)] or 0
                        local prompt = ('TURF WAR IN PROGRESS: %s | Time Left: %s'):format(data.label, formatClock(remainingSecs))
                        currentTextUiTurf = ('active_%s'):format(id)
                        lib.showTextUI(prompt, {
                            position = 'bottom-center',
                            icon = 'fa-solid fa-stopwatch',
                            style = { backgroundColor = '#140d11', color = '#ff3a3a', border = '1px solid #ff3a3a' }
                        })

                    elseif state == 'COOLDOWN' then
                        local cooldownSecs = GlobalState[('turf_cooldown_%s'):format(id)] or 0
                        local prompt = ('TURF ON COOLDOWN: %s | Ready in: %s'):format(data.label, formatClock(cooldownSecs))
                        currentTextUiTurf = ('cd_%s'):format(id)
                        lib.showTextUI(prompt, {
                            position = 'bottom-center',
                            icon = 'fa-solid fa-clock-rotate-left',
                            style = { backgroundColor = '#140d11', color = '#a08890', border = '1px solid #a08890' }
                        })
                    end

                    ::skip_action::
                end
            else
                if currentTextUiTurf then
                    lib.hideTextUI()
                    currentTextUiTurf = nil
                end
            end
        elseif currentTextUiTurf then
            lib.hideTextUI()
            currentTextUiTurf = nil
        end

        Wait(sleep)
    end
end)

-- Claim Reward Bag Prop Spawning Thread (Region 3 / 4 only)
CreateThread(function()
    local rewardBagModel = Config.RewardBag.model or `prop_cs_heist_bag_02`

    while true do
        Wait(500)
        for id, data in pairs(Config.TurfWars) do
            if not CanUseTurf(data) then
                if RewardProps[id] and DoesEntityExist(RewardProps[id]) then
                    DeleteObject(RewardProps[id])
                    RewardProps[id] = nil
                end
            else
                local claimable = GlobalState[('turf_claimable_%s'):format(id)] == true

                if claimable then
                    if not RewardProps[id] or not DoesEntityExist(RewardProps[id]) then
                        lib.requestModel(rewardBagModel, 5000)
                        if HasModelLoaded(rewardBagModel) then
                            local zOff = Config.RewardBag.zOffset or -0.98
                            local prop = CreateObject(rewardBagModel, data.coords.x, data.coords.y, data.coords.z + zOff, false, false, false)
                            SetEntityHeading(prop, Config.RewardBag.heading or 0.0)
                            FreezeEntityPosition(prop, true)
                            SetEntityInvincible(prop, true)
                            SetModelAsNoLongerNeeded(rewardBagModel)
                            RewardProps[id] = prop
                        end
                    end
                else
                    if RewardProps[id] and DoesEntityExist(RewardProps[id]) then
                        DeleteObject(RewardProps[id])
                        RewardProps[id] = nil
                    end
                end
            end
        end
    end
end)

-- Resource Stop Cleanup
AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    for id, prop in pairs(RewardProps) do
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
    end
    if currentTextUiTurf then
        lib.hideTextUI()
    end
end)
