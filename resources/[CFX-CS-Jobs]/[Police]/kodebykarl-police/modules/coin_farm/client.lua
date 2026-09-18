local isFarming = false
local textState = nil -- nil | 'start' | 'stop'

local function getPlayerJob()
    if PlayerData and PlayerData.job and PlayerData.job.name then
        return PlayerData.job.name
    end
    local data = ESX.GetPlayerData()
    if data and data.job and data.job.name then
        PlayerData = data
        return data.job.name
    end
    return nil
end

local FARM_TEXT = {
    start = '[E] - Start Auto-Farming Police Coins',
    stop = '[E] or [X] - Stop Auto-Farming Police Coins',
}

local function updateTextUI(state)
    if textState == state then return end
    textState = state
    if state == 'start' then
        lib.showTextUI(FARM_TEXT.start, {
            icon = 'coins',
            position = 'right-center'
        })
    elseif state == 'stop' then
        lib.showTextUI(FARM_TEXT.stop, {
            icon = 'hand',
            position = 'right-center'
        })
    else
        local open, text = lib.isTextUIOpen()
        if open and (text == FARM_TEXT.start or text == FARM_TEXT.stop) then
            lib.hideTextUI()
        end
    end
end

local function stopAutoFarm(notifyUser)
    if not isFarming then return end
    isFarming = false
    if lib.progressActive and lib.progressActive() then
        lib.cancelProgress()
    end
    updateTextUI('start')
    if notifyUser then
        lib.notify({
            title = 'Police Armory',
            description = 'Auto-farming stopped.',
            type = 'inform',
            duration = 3000
        })
    end
end

local function startAutoFarm(spotIndex)
    if isFarming then return end
    local spot = Config.CoinHarvest and Config.CoinHarvest.locations and Config.CoinHarvest.locations[spotIndex]
    if not spot then return end

    local jobName = getPlayerJob()
    local allowedJob = (Config.CoinHarvest and Config.CoinHarvest.job) or 'police'
    if jobName ~= allowedJob then
        lib.notify({
            title = 'Police Armory',
            description = 'Only Police Officers can harvest police coins!',
            type = 'error',
            duration = 4000
        })
        return
    end

    isFarming = true
    updateTextUI('stop')
    lib.notify({
        title = 'Police Armory',
        description = 'Started auto-farming Grim Police Coins. Press [E] or [X] anytime to stop.',
        type = 'success',
        duration = 4000
    })

    CreateThread(function()
        local animConfig = Config.CoinHarvest.anim or {
            dict = 'anim@heists@prison_heiststation@cop_reactions',
            clip = 'cop_b_idle',
            flag = 1
        }

        if animConfig.dict then
            lib.requestAnimDict(animConfig.dict)
        end

        while isFarming do
            local ped = cache.ped or PlayerPedId()
            if IsEntityDead(ped) or (isCuffed and isCuffed == true) then
                stopAutoFarm(false)
                break
            end

            local pCoords = GetEntityCoords(ped)
            local targetCoords = vector3(spot.x, spot.y, spot.z)
            if #(pCoords - targetCoords) > ((Config.CoinHarvest.interactDistance or 1.5) + 1.2) then
                lib.notify({
                    title = 'Police Armory',
                    description = 'You moved away from the station. Auto-farming stopped.',
                    type = 'warning',
                    duration = 4000
                })
                stopAutoFarm(false)
                break
            end

            -- Face the desk/terminal heading
            if spot.w then
                SetEntityHeading(ped, spot.w)
            end

            -- 10-second progress bar
            local success = lib.progressBar({
                duration = Config.CoinHarvest.duration or 10000,
                label = 'Harvesting Grim Police Coins...',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                    sprint = true
                },
                anim = {
                    dict = animConfig.dict,
                    clip = animConfig.clip,
                    flag = animConfig.flag or 1
                }
            })

            if success and isFarming then
                -- Request coin award from server
                local awarded = lib.callback.await('kodebykarl-police:server:harvestCoins', false, spotIndex)
                if not awarded then
                    stopAutoFarm(false)
                    break
                end
                Wait(500)
            else
                -- Progress bar cancelled by player (X key or E)
                if isFarming then
                    stopAutoFarm(true)
                end
                break
            end
        end

        if not isFarming then
            updateTextUI('start')
        end
    end)
end

-- Distance check and Keybind loop
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = cache.ped or PlayerPedId()
        local jobName = getPlayerJob()
        local allowedJob = (Config.CoinHarvest and Config.CoinHarvest.job) or 'police'

        if Config.CoinHarvest and Config.CoinHarvest.enabled and jobName == allowedJob and not IsEntityDead(ped) then
            local pCoords = GetEntityCoords(ped)
            local nearestSpotIndex = nil
            local nearestDist = 999.0

            for i = 1, #Config.CoinHarvest.locations do
                local spot = Config.CoinHarvest.locations[i]
                local spotCoords = vector3(spot.x, spot.y, spot.z)
                local dist = #(pCoords - spotCoords)
                if dist < nearestDist then
                    nearestDist = dist
                    nearestSpotIndex = i
                end
            end

            local drawDist = Config.CoinHarvest.drawDistance or 6.0
            local interactDist = Config.CoinHarvest.interactDistance or 1.5

            if nearestDist <= drawDist then
                sleep = 0
                local spot = Config.CoinHarvest.locations[nearestSpotIndex]

                -- Floating golden coin marker on the floor
                DrawMarker(2, spot.x, spot.y, spot.z + 0.1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.25, 0.25, 0.25, 255, 215, 0, 160, false, true, 2, false, nil, nil, false)

                if nearestDist <= interactDist then
                    if isFarming then
                        updateTextUI('stop')
                    else
                        updateTextUI('start')
                    end

                    -- Key E (INPUT_CONTEXT)
                    if IsControlJustReleased(0, 38) then
                        if isFarming then
                            stopAutoFarm(true)
                        else
                            startAutoFarm(nearestSpotIndex)
                        end
                    end
                else
                    if not isFarming then
                        updateTextUI(nil)
                    end
                end
            else
                if not isFarming then
                    updateTextUI(nil)
                end
            end
        else
            if not isFarming then
                updateTextUI(nil)
            end
        end

        Wait(sleep)
    end
end)

-- ox_target support if active
CreateThread(function()
    if not Config.CoinHarvest or not Config.CoinHarvest.enabled then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    local allowedJob = Config.CoinHarvest.job or 'police'
    for i = 1, #Config.CoinHarvest.locations do
        local spot = Config.CoinHarvest.locations[i]
        exports.ox_target:addBoxZone({
            name = 'police_coin_harvest_' .. i,
            coords = vector3(spot.x, spot.y, spot.z),
            size = vector3(1.2, 1.2, 1.5),
            rotation = spot.w or 0.0,
            debug = false,
            options = {
                {
                    name = 'police_coin_harvest_start_' .. i,
                    icon = 'fas fa-coins',
                    label = 'Start Auto-Farming Police Coins',
                    groups = allowedJob,
                    canInteract = function()
                        return not isFarming
                    end,
                    onSelect = function()
                        startAutoFarm(i)
                    end
                },
                {
                    name = 'police_coin_harvest_stop_' .. i,
                    icon = 'fas fa-hand',
                    label = 'Stop Auto-Farming Police Coins',
                    groups = allowedJob,
                    canInteract = function()
                        return isFarming
                    end,
                    onSelect = function()
                        stopAutoFarm(true)
                    end
                }
            }
        })
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if isFarming then
            isFarming = false
            if lib.progressActive and lib.progressActive() then
                lib.cancelProgress()
            end
        end
        lib.hideTextUI()
    end
end)
