local configs = require 'shared.config'

local isFarming = false
local textState = nil -- nil | 'start' | 'stop'

local function mopCfg()
    return configs.MopGrind
end

local function getPlayerJob()
    local data = ESX and ESX.PlayerData
    if not data or not data.job then
        data = ESX and ESX.GetPlayerData and ESX.GetPlayerData() or data
    end
    return data and data.job and data.job.name
end

local function isAllowedJob(jobName)
    local cfg = mopCfg()
    if not cfg or not cfg.jobs then return false end
    return cfg.jobs[jobName] == true
end

local function resolveSpot(entry)
    if not entry then return nil end
    if type(entry) == 'vector4' or type(entry) == 'vector3' then
        return { x = entry.x, y = entry.y, z = entry.z, w = entry.w, task = 'mop' }
    end
    local coords = entry.coords or entry
    if not coords or not coords.x then return nil end
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = coords.w,
        task = entry.task or 'mop',
    }
end

local function taskData(taskName)
    local cfg = mopCfg()
    local tasks = cfg and cfg.tasks or {}
    local name = taskName or (cfg and cfg.defaultTask) or 'mop'
    return tasks[name] or tasks.mop or {}
end

local function updateTextUI(state, startLabel)
    if textState == state then return end
    textState = state
    if state == 'start' then
        lib.showTextUI(startLabel or '[E] - Start Auto-Farming EMS Coins', {
            icon = 'coins',
            position = 'right-center',
        })
    elseif state == 'stop' then
        lib.showTextUI('[E] or [X] - Stop Auto-Farming EMS Coins', {
            icon = 'hand',
            position = 'right-center',
        })
    else
        local open, text = lib.isTextUIOpen()
        local startText = startLabel or '[E] - Start Auto-Farming EMS Coins'
        if open and (text == startText or text == '[E] or [X] - Stop Auto-Farming EMS Coins') then
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
    ClearPedTasks(cache.ped or PlayerPedId())
    updateTextUI('start')
    if notifyUser then
        lib.notify({
            title = 'EMS',
            description = 'Auto-farming stopped.',
            type = 'inform',
            duration = 3000,
        })
    end
end

local function startAutoFarm(spotIndex)
    if isFarming then return end
    local cfg = mopCfg()
    local spot = resolveSpot(cfg and cfg.locations and cfg.locations[spotIndex])
    if not cfg or not cfg.enabled or not spot then return end

    if not isAllowedJob(getPlayerJob()) then
        lib.notify({
            title = 'EMS',
            description = 'Only EMS staff can farm coins here.',
            type = 'error',
            duration = 4000,
        })
        return
    end

    local task = taskData(spot.task)
    isFarming = true
    updateTextUI('stop')
    lib.notify({
        title = 'EMS',
        description = 'Started auto-farming EMS coins. Press [E] or [X] to stop.',
        type = 'success',
        duration = 4000,
    })

    CreateThread(function()
        local anim = task.anim or {
            dict = 'move_mop',
            clip = 'idle_scrub_small_player',
            flag = 1,
        }
        local prop = task.prop

        if anim.dict then
            lib.requestAnimDict(anim.dict)
        end

        while isFarming do
            local ped = cache.ped or PlayerPedId()
            if IsEntityDead(ped) then
                stopAutoFarm(false)
                break
            end

            local pCoords = GetEntityCoords(ped)
            local targetCoords = vector3(spot.x, spot.y, spot.z)
            if #(pCoords - targetCoords) > ((cfg.interactDistance or 1.5) + 1.2) then
                lib.notify({
                    title = 'EMS',
                    description = 'You walked away. Auto-farming stopped.',
                    type = 'warning',
                    duration = 4000,
                })
                stopAutoFarm(false)
                break
            end

            if spot.w then
                SetEntityHeading(ped, spot.w)
            end

            local progress = {
                duration = cfg.duration or 8000,
                label = task.progressLabel or 'Working...',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                    sprint = true,
                },
                anim = {
                    dict = anim.dict,
                    clip = anim.clip,
                    flag = anim.flag or 1,
                },
            }
            if prop and prop.model then
                progress.prop = {
                    model = prop.model,
                    bone = prop.bone or 28422,
                    pos = prop.pos or vec3(0.0, 0.0, 0.0),
                    rot = prop.rot or vec3(0.0, 0.0, 0.0),
                }
            end

            local finished = lib.progressBar(progress)
            if not finished or not isFarming then
                if isFarming then
                    stopAutoFarm(true)
                end
                break
            end

            local awarded = lib.callback.await('kodebykarl-ambulance:server:harvestCoins', false, spotIndex)
            if not awarded then
                stopAutoFarm(false)
                break
            end

            Wait(400)
        end

        if not isFarming then
            updateTextUI('start', task.startLabel)
        end
    end)
end

CreateThread(function()
    while true do
        local sleep = 1000
        local cfg = mopCfg()
        local ped = cache.ped or PlayerPedId()
        local jobName = getPlayerJob()

        if cfg and cfg.enabled and isAllowedJob(jobName) and not IsEntityDead(ped) then
            local pCoords = GetEntityCoords(ped)
            local nearestSpotIndex = nil
            local nearestDist = 999.0
            local nearestSpot = nil

            for i = 1, #cfg.locations do
                local spot = resolveSpot(cfg.locations[i])
                if spot then
                    local dist = #(pCoords - vector3(spot.x, spot.y, spot.z))
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestSpotIndex = i
                        nearestSpot = spot
                    end
                end
            end

            local drawDist = cfg.drawDistance or 8.0
            local interactDist = cfg.interactDistance or 1.5

            if nearestSpot and nearestDist <= drawDist then
                sleep = 0
                DrawMarker(2, nearestSpot.x, nearestSpot.y, nearestSpot.z + 0.12, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.22, 0.22, 0.22, 220, 40, 40, 160, false, true, 2, false, nil, nil, false)

                if nearestDist <= interactDist then
                    local task = taskData(nearestSpot.task)
                    updateTextUI(isFarming and 'stop' or 'start', task.startLabel)
                    if IsControlJustReleased(0, 38) then
                        if isFarming then
                            stopAutoFarm(true)
                        else
                            startAutoFarm(nearestSpotIndex)
                        end
                    end
                elseif not isFarming then
                    updateTextUI(nil)
                end
            elseif not isFarming then
                updateTextUI(nil)
            end
        elseif not isFarming then
            updateTextUI(nil)
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    local cfg = mopCfg()
    if not cfg or not cfg.enabled then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    for i = 1, #cfg.locations do
        local spot = resolveSpot(cfg.locations[i])
        if spot then
            exports.ox_target:addBoxZone({
                name = 'ems_coin_grind_' .. i,
                coords = vector3(spot.x, spot.y, spot.z),
                size = vector3(1.2, 1.2, 1.5),
                rotation = spot.w or 0.0,
                debug = false,
                options = {
                    {
                        name = 'ems_coin_start_' .. i,
                        icon = 'fas fa-coins',
                        label = 'Start Auto-Farming EMS Coins',
                        groups = { ambulance = 0 },
                        canInteract = function()
                            return not isFarming
                        end,
                        onSelect = function()
                            startAutoFarm(i)
                        end,
                    },
                    {
                        name = 'ems_coin_stop_' .. i,
                        icon = 'fas fa-hand',
                        label = 'Stop Auto-Farming EMS Coins',
                        groups = { ambulance = 0 },
                        canInteract = function()
                            return isFarming
                        end,
                        onSelect = function()
                            stopAutoFarm(true)
                        end,
                    },
                },
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isFarming then
        isFarming = false
        if lib.progressActive and lib.progressActive() then
            lib.cancelProgress()
        end
        ClearPedTasks(PlayerPedId())
    end
    lib.hideTextUI()
end)
