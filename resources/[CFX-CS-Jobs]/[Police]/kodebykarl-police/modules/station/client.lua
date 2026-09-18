local function isPoliceStaff()
    local job = PlayerData and PlayerData.job and PlayerData.job.name
    if not job and ESX.GetPlayerData then
        local pd = ESX.GetPlayerData()
        job = pd and pd.job and pd.job.name
    end
    return job == 'police' or job == (Config.OffDutyJob or 'offpolice')
end

local function openWardrobe()
    if not isPoliceStaff() then
        ESX.Notify('POLICE', 'Only police personnel can access this wardrobe.', 'error', 4000)
        return
    end
    if GetResourceState('illenium-appearance') == 'started' then
        TriggerEvent('illenium-appearance:client:openOutfitMenu')
        return
    end
    ESX.Notify('POLICE', 'Wardrobe is unavailable.', 'error', 4000)
end

local function setupWardrobe()
    local cfg = Config.Station and Config.Station.Wardrobe
    if not cfg or not cfg.coords then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    exports.ox_target:addBoxZone({
        coords = cfg.coords,
        size = vector3(1.4, 1.8, 2.4),
        rotation = cfg.heading or 0.0,
        debug = false,
        options = {
            {
                name = 'police_wardrobe',
                icon = cfg.icon or 'fa-solid fa-shirt',
                label = cfg.label or 'Police Wardrobe',
                groups = { ['police'] = 0, [Config.OffDutyJob or 'offpolice'] = 0 },
                onSelect = openWardrobe,
                distance = 2.0,
            },
            {
                name = 'police_documents_desk',
                icon = 'fa-solid fa-file-lines',
                label = 'Open Documents',
                groups = { ['police'] = 0 },
                onSelect = function()
                    if OpenDocuments then
                        OpenDocuments()
                    end
                end,
                distance = 2.0,
            },
        },
    })
end

local function setupDuty()
    local cfg = Config.Station and Config.Station.Duty
    if not cfg or not cfg.coords then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    exports.ox_target:addBoxZone({
        coords = cfg.coords,
        size = vector3(1.4, 1.4, 2.2),
        rotation = cfg.heading or 0.0,
        debug = false,
        options = {
            {
                name = 'police_duty_toggle',
                icon = cfg.icon or 'fa-solid fa-user-clock',
                label = cfg.label or 'On / Off Duty',
                groups = { ['police'] = 0, [Config.OffDutyJob or 'offpolice'] = 0 },
                onSelect = function()
                    TriggerServerEvent('cfx-cs-police:toggleDuty')
                end,
                distance = 2.0,
            },
        },
    })
end

local function setupGarage()
    local cfg = Config.Station and Config.Station.Garage
    if not cfg or not cfg.access then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    local garageId = cfg.garageId or 'Police Garage'
    exports.ox_target:addBoxZone({
        coords = cfg.access,
        size = vector3(2.0, 2.0, 2.0),
        rotation = cfg.heading or 0.0,
        debug = false,
        options = {
            {
                name = 'police_garage_access',
                icon = 'fa-solid fa-warehouse',
                label = cfg.label or 'Police Garage',
                groups = { ['police'] = 0, [Config.OffDutyJob or 'offpolice'] = 0 },
                onSelect = function()
                    TriggerEvent('jg-advancedgarages:client:open-garage', garageId, 'car', false)
                end,
                distance = 3.5,
            },
            {
                name = 'police_garage_store',
                icon = 'fa-solid fa-parking',
                label = 'Store Patrol Vehicle',
                groups = { ['police'] = 0, [Config.OffDutyJob or 'offpolice'] = 0 },
                canInteract = function()
                    return cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped
                end,
                onSelect = function()
                    TriggerEvent('jg-advancedgarages:client:store-vehicle', garageId, 'car', false)
                end,
                distance = 20.0,
            },
        },
    })
end

local function setupHelipad()
    local cfg = Config.Station and Config.Station.Helipad
    if not cfg or not cfg.access then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    local garageId = cfg.garageId or 'Police Helipad'
    local policeGroups = { ['police'] = 0, [Config.OffDutyJob or 'offpolice'] = 0 }

    exports.ox_target:addBoxZone({
        coords = cfg.access,
        size = vector3(1.6, 1.6, 2.0),
        rotation = cfg.heading or 0.0,
        debug = false,
        options = {
            {
                name = 'police_helipad_access',
                icon = 'fa-solid fa-helicopter',
                label = cfg.label or 'Police Helipad',
                groups = policeGroups,
                onSelect = function()
                    TriggerEvent('jg-advancedgarages:client:open-garage', garageId, 'air', false)
                end,
                distance = 3.0,
            },
        },
    })

    local storePos = cfg.store or cfg.spawn
    if not storePos then return end

    local storeCoords = vector3(storePos.x, storePos.y, storePos.z)
    local storePrompt = false

    local function isHeliDriver()
        return cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped
    end

    local function hideStorePrompt()
        if storePrompt then
            lib.hideTextUI()
            storePrompt = false
        end
    end

    local point = lib.points.new({
        coords = storeCoords,
        distance = 12.0,
    })

    function point:onEnter()
        if isPoliceStaff() and isHeliDriver() then
            lib.showTextUI('[E] Store Helicopter', { icon = 'helicopter', position = 'right-center' })
            storePrompt = true
        end
    end

    function point:onExit()
        hideStorePrompt()
    end

    function point:nearby()
        DrawMarker(36, storeCoords.x, storeCoords.y, storeCoords.z + 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 1.2, 59, 130, 246, 180, false, true, 2, false, nil, nil, false)

        if not isPoliceStaff() then
            hideStorePrompt()
            return
        end

        local driving = isHeliDriver()
        if driving and not storePrompt then
            lib.showTextUI('[E] Store Helicopter', { icon = 'helicopter', position = 'right-center' })
            storePrompt = true
        elseif not driving and storePrompt then
            hideStorePrompt()
        end

        if driving and IsControlJustReleased(0, 38) then
            TriggerEvent('jg-advancedgarages:client:store-vehicle', garageId, 'air', false)
        end
    end
end

CreateThread(function()
    while not ESX or not ESX.IsPlayerLoaded or not ESX.IsPlayerLoaded() do
        Wait(200)
    end
    setupWardrobe()
    setupDuty()
    setupGarage()
    setupHelipad()
end)
