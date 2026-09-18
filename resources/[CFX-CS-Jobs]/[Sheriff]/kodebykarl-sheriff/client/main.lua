local ESX = exports['es_extended']:getSharedObject()

local function createStationBlip()
    -- Blip is also created by kodebykarl-police when LawEnforcement.sheriff is enabled.
    -- Skip duplicate if police already owns it.
    if GetResourceState('kodebykarl-police') == 'started' then
        return
    end

    local blipCfg = ConfigSheriff.Station and ConfigSheriff.Station.Blip
    if not blipCfg or not blipCfg.Coords then return end

    local blip = AddBlipForCoord(blipCfg.Coords.x, blipCfg.Coords.y, blipCfg.Coords.z)
    SetBlipSprite(blip, blipCfg.Sprite or 60)
    SetBlipColour(blip, blipCfg.Colour or 5)
    SetBlipScale(blip, blipCfg.Scale or 0.8)
    SetBlipAsShortRange(blip, true)
    SetBlipDisplay(blip, blipCfg.Display or 4)
    SetBlipHighDetail(blip, true)
    SetBlipCategory(blip, blipCfg.Category or 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipCfg.Label or ConfigSheriff.Label)
    EndTextCommandSetBlipName(blip)
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

local function isSheriff()
    local job = (ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name)
    if not job then
        local pd = ESX.GetPlayerData()
        job = pd and pd.job and pd.job.name
    end
    return job == 'sheriff' or job == 'offsheriff'
end

local function openSheriffWardrobe()
    if not isSheriff() then
        ESX.ShowNotification('Only Sheriff personnel can access this wardrobe.', 'error')
        return
    end

    if GetResourceState('illenium-appearance') == 'started' then
        TriggerEvent('illenium-appearance:client:openOutfitMenu')
    else
        ESX.ShowNotification('Wardrobe opened.', 'info')
    end
end

local function setupWardrobe()
    local wardrobeCfg = ConfigSheriff.Station and ConfigSheriff.Station.Wardrobe
    if not wardrobeCfg or not wardrobeCfg.coords then return end

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addBoxZone({
            coords = wardrobeCfg.coords,
            size = wardrobeCfg.size or vector3(1.2, 2.0, 2.5),
            rotation = wardrobeCfg.heading or 0.0,
            debug = false,
            options = {
                {
                    name = 'sheriff_wardrobe',
                    icon = (wardrobeCfg.target and wardrobeCfg.target.icon) or wardrobeCfg.icon or 'fa-solid fa-shirt',
                    label = (wardrobeCfg.target and wardrobeCfg.target.label) or wardrobeCfg.label or 'Sheriff Wardrobe',
                    groups = { ['sheriff'] = 0, ['offsheriff'] = 0 },
                    onSelect = function()
                        openSheriffWardrobe()
                    end,
                    distance = (wardrobeCfg.target and wardrobeCfg.target.distance) or wardrobeCfg.distance or 2.0
                }
            }
        })
    end

    local wardrobePrompt = '[E] - Sheriff Wardrobe'

    local function hideWardrobeText()
        local open, text = lib.isTextUIOpen()
        if open and text == wardrobePrompt then
            lib.hideTextUI()
        end
    end

    local point = lib.points.new({
        coords = wardrobeCfg.coords,
        distance = 2.4,
    })

    function point:onEnter()
        if isSheriff() then
            lib.showTextUI(wardrobePrompt, { icon = 'tshirt', position = 'right-center' })
        end
    end

    function point:onExit()
        hideWardrobeText()
    end

    function point:nearby()
        if not isSheriff() then return end
        local open, text = lib.isTextUIOpen()
        if not open or text ~= wardrobePrompt then
            lib.showTextUI(wardrobePrompt, { icon = 'tshirt', position = 'right-center' })
        end
        if IsControlJustReleased(0, 38) then
            openSheriffWardrobe()
        end
    end
end

local function setupHelipad()
    local heliCfg = ConfigSheriff.Station and ConfigSheriff.Station.Helipad
    if not heliCfg or not heliCfg.access then return end

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addBoxZone({
            coords = heliCfg.access,
            size = vector3(1.5, 1.5, 2.0),
            rotation = heliCfg.heading or 0.0,
            debug = false,
            options = {
                {
                    name = 'sheriff_helipad_access',
                    icon = 'fa-solid fa-helicopter',
                    label = heliCfg.label or 'Sheriff Helipad',
                    groups = { ['sheriff'] = 0, ['offsheriff'] = 0, ['police'] = 0 },
                    onSelect = function()
                        if cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped then
                            TriggerEvent('jg-advancedgarages:client:store-vehicle', heliCfg.garageId or 'Sheriff Helipad', 'air', false)
                        else
                            TriggerEvent('jg-advancedgarages:client:open-garage', heliCfg.garageId or 'Sheriff Helipad', 'air', false)
                        end
                    end,
                    distance = 3.0
                },
                {
                    name = 'sheriff_helipad_store',
                    icon = 'fa-solid fa-warehouse',
                    label = 'Store Helicopter',
                    groups = { ['sheriff'] = 0, ['offsheriff'] = 0, ['police'] = 0 },
                    canInteract = function()
                        return cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped
                    end,
                    onSelect = function()
                        TriggerEvent('jg-advancedgarages:client:store-vehicle', heliCfg.garageId or 'Sheriff Helipad', 'air', false)
                    end,
                    distance = 15.0
                }
            }
        })
    end
end

local function setupGarage()
    local garageCfg = ConfigSheriff.Station and ConfigSheriff.Station.Garage
    if not garageCfg or not garageCfg.access then return end

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addBoxZone({
            coords = garageCfg.access,
            size = vector3(2.0, 2.0, 2.0),
            rotation = garageCfg.heading or 0.0,
            debug = false,
            options = {
                {
                    name = 'sheriff_garage_access',
                    icon = 'fa-solid fa-warehouse',
                    label = garageCfg.label or 'Sheriff Garage',
                    groups = { ['sheriff'] = 0, ['offsheriff'] = 0, ['police'] = 0 },
                    onSelect = function()
                        if cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped then
                            TriggerEvent('jg-advancedgarages:client:store-vehicle', garageCfg.garageId or 'Sheriff Garage', 'car', false)
                        else
                            TriggerEvent('jg-advancedgarages:client:open-garage', garageCfg.garageId or 'Sheriff Garage', 'car', false)
                        end
                    end,
                    distance = 3.5
                },
                {
                    name = 'sheriff_garage_store',
                    icon = 'fa-solid fa-parking',
                    label = 'Store Patrol Vehicle',
                    groups = { ['sheriff'] = 0, ['offsheriff'] = 0, ['police'] = 0 },
                    canInteract = function()
                        return cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped
                    end,
                    onSelect = function()
                        TriggerEvent('jg-advancedgarages:client:store-vehicle', garageCfg.garageId or 'Sheriff Garage', 'car', false)
                    end,
                    distance = 12.0
                }
            }
        })
    end
end

local isFarming = false
local farmTextState = nil

local FARM_TEXT = {
    start = '[E] - Start Auto-Farming Sheriff Coins',
    stop = '[E] or [X] - Stop Auto-Farming Sheriff Coins',
}

local function updateCoinFarmText(state)
    if farmTextState == state then return end
    farmTextState = state
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
    updateCoinFarmText('start')
    if notifyUser then
        lib.notify({
            title = 'Sheriff Station',
            description = 'Auto-farming stopped.',
            type = 'inform',
            duration = 3000
        })
    end
end

local function startAutoFarm(spotIndex)
    if isFarming then return end
    local harvestCfg = ConfigSheriff.CoinHarvest
    local spot = harvestCfg and harvestCfg.locations and harvestCfg.locations[spotIndex]
    if not harvestCfg or not harvestCfg.enabled or not spot then return end

    if not isSheriff() then
        lib.notify({
            title = 'Sheriff Station',
            description = 'Only Sheriff personnel can harvest Sheriff Coins!',
            type = 'error',
            duration = 4000
        })
        return
    end

    isFarming = true
    updateCoinFarmText('stop')
    lib.notify({
        title = 'Sheriff Station',
        description = 'Started auto-farming Sheriff Coins. Press [E] or [X] anytime to stop.',
        type = 'success',
        duration = 4000
    })

    CreateThread(function()
        local animConfig = harvestCfg.anim or {
            dict = 'anim@heists@prison_heiststation@cop_reactions',
            clip = 'cop_b_idle',
            flag = 1
        }

        if animConfig.dict then
            lib.requestAnimDict(animConfig.dict)
        end

        while isFarming do
            local ped = cache.ped or PlayerPedId()
            if IsEntityDead(ped) then
                stopAutoFarm(false)
                break
            end

            local pCoords = GetEntityCoords(ped)
            local targetCoords = vector3(spot.x, spot.y, spot.z)
            if #(pCoords - targetCoords) > ((harvestCfg.interactDistance or 1.5) + 1.2) then
                lib.notify({
                    title = 'Sheriff Station',
                    description = 'You moved away from the station. Auto-farming stopped.',
                    type = 'warning',
                    duration = 4000
                })
                stopAutoFarm(false)
                break
            end

            if spot.w then
                SetEntityHeading(ped, spot.w)
            end

            local success = lib.progressBar({
                duration = harvestCfg.duration or 10000,
                label = 'Harvesting Sheriff Coins...',
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
                local awarded = lib.callback.await('kodebykarl-sheriff:server:harvestCoins', false, spotIndex)
                if not awarded then
                    stopAutoFarm(false)
                    break
                end
                Wait(500)
            else
                if isFarming then
                    stopAutoFarm(true)
                end
                break
            end
        end

        if not isFarming then
            updateCoinFarmText('start')
        end
    end)
end

local function setupCoinHarvest()
    local harvestCfg = ConfigSheriff.CoinHarvest
    if not harvestCfg or not harvestCfg.enabled or not harvestCfg.locations then return end

    if GetResourceState('ox_target') == 'started' then
        for i = 1, #harvestCfg.locations do
            local loc = harvestCfg.locations[i]
            exports.ox_target:addBoxZone({
                name = 'sheriff_coin_harvest_' .. i,
                coords = vector3(loc.x, loc.y, loc.z),
                size = vector3(1.2, 1.2, 1.5),
                rotation = loc.w or 0.0,
                debug = false,
                options = {
                    {
                        name = 'sheriff_coin_harvest_start_' .. i,
                        icon = 'fas fa-coins',
                        label = 'Start Auto-Farming Sheriff Coins',
                        groups = { ['sheriff'] = 0 },
                        canInteract = function()
                            return not isFarming
                        end,
                        onSelect = function()
                            startAutoFarm(i)
                        end,
                        distance = harvestCfg.interactDistance or 1.5
                    },
                    {
                        name = 'sheriff_coin_harvest_stop_' .. i,
                        icon = 'fas fa-hand',
                        label = 'Stop Auto-Farming Sheriff Coins',
                        groups = { ['sheriff'] = 0 },
                        canInteract = function()
                            return isFarming
                        end,
                        onSelect = function()
                            stopAutoFarm(true)
                        end,
                        distance = harvestCfg.interactDistance or 1.5
                    }
                }
            })
        end
    end

    CreateThread(function()
        local drawDist = harvestCfg.drawDistance or 6.0
        local interactDist = harvestCfg.interactDistance or 1.5

        while true do
            local sleep = 1000
            local ped = cache.ped or PlayerPedId()

            if isSheriff() and not IsEntityDead(ped) then
                local pCoords = GetEntityCoords(ped)
                local nearestSpotIndex = nil
                local nearestDist = 999.0

                for i = 1, #harvestCfg.locations do
                    local loc = harvestCfg.locations[i]
                    local dist = #(pCoords - vector3(loc.x, loc.y, loc.z))
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestSpotIndex = i
                    end
                end

                if nearestSpotIndex and nearestDist <= drawDist then
                    sleep = 0
                    local loc = harvestCfg.locations[nearestSpotIndex]
                    DrawMarker(2, loc.x, loc.y, loc.z + 0.1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.25, 0.25, 0.25, 255, 215, 0, 160, false, true, 2, false, nil, nil, false)

                    if nearestDist <= interactDist then
                        if isFarming then
                            updateCoinFarmText('stop')
                        else
                            updateCoinFarmText('start')
                        end

                        if IsControlJustReleased(0, 38) then
                            if isFarming then
                                stopAutoFarm(true)
                            else
                                startAutoFarm(nearestSpotIndex)
                            end
                        end
                    elseif not isFarming then
                        updateCoinFarmText(nil)
                    end
                elseif not isFarming then
                    updateCoinFarmText(nil)
                end
            elseif not isFarming then
                updateCoinFarmText(nil)
            end

            Wait(sleep)
        end
    end)
end

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

CreateThread(function()
    while not ESX.IsPlayerLoaded() do Wait(200) end
    ESX.PlayerData = ESX.GetPlayerData()
    createStationBlip()
    setupWardrobe()
    setupHelipad()
    setupGarage()
    setupCoinHarvest()
end)

-- F6 / LEO tools live on kodebykarl-police (HasGroup includes sheriff).
-- Alias so other scripts can open the sheriff menu the same way.
RegisterNetEvent('cfx-cs-sheriff:client:openQuickMenu', function()
    TriggerEvent('cfx-cs-police:client:openQuickMenu')
end)

exports('OpenQuickMenu', function()
    TriggerEvent('cfx-cs-police:client:openQuickMenu')
end)

RegisterNetEvent('cfx-cs-sheriff:client:openWardrobe', function()
    openSheriffWardrobe()
end)

exports('OpenWardrobe', openSheriffWardrobe)
