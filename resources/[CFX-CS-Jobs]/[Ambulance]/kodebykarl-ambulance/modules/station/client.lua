local configs = require 'shared.config'

local EMS_GROUPS = {
    ambulance = 0,
    offambulance = 0,
    pambulance = 0,
    offpambulance = 0,
    sambulance = 0,
    offsambulance = 0,
}

local function jobName()
    local data = ESX and ESX.PlayerData
    if not data or not data.job then
        data = ESX and ESX.GetPlayerData and ESX.GetPlayerData() or data
    end
    return data and data.job and data.job.name
end

local function jobGrade()
    local data = ESX and ESX.PlayerData
    if not data or not data.job then
        data = ESX and ESX.GetPlayerData and ESX.GetPlayerData() or data
    end
    return tonumber(data and data.job and data.job.grade) or 0
end

local function isEmsStaff()
    local name = jobName()
    return name and EMS_GROUPS[name] ~= nil
end

local function jobInList(jobs)
    local name = jobName()
    if not name or type(jobs) ~= 'table' then return false end
    return jobs[name] ~= nil
end

local function openWardrobe(station)
    local jobs = station.wardrobeJobs or EMS_GROUPS
    if not jobInList(jobs) then
        ESX.Notify('AMBULANCE', ('Only %s personnel can use this wardrobe.'):format(station.label or 'EMS'), 'error', 3000)
        return
    end

    if GetResourceState('illenium-appearance') == 'started' then
        TriggerEvent('illenium-appearance:client:openOutfitMenu')
        return
    end

    ESX.Notify('AMBULANCE', 'Wardrobe is unavailable.', 'error', 3000)
end

local function openBossMenu(station)
    local cfg = station.BossMenu
    local minGrade = cfg and cfg.minGrade or 5
    if not jobInList(station.wardrobeJobs or { [station.job] = 0 }) or jobGrade() < minGrade then
        ESX.Notify(station.label or 'EMS', 'Boss access only.', 'error', 3000)
        return
    end

    if Vars.isDead then
        ESX.Notify(station.label or 'EMS', 'Cannot open boss menu while unconscious.', 'error', 3000)
        return
    end

    if GetResourceState('kodebykarl-ui') == 'started' then
        exports['kodebykarl-ui']:OpenIpad()
        return
    end

    ESX.Notify(station.label or 'EMS', 'Department boss is managed from the iPad.', 'inform', 4000)
end

local function openJobGarage(garageId, vehicleType)
    if cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped then
        TriggerEvent('jg-advancedgarages:client:store-vehicle', garageId, vehicleType, false)
    else
        TriggerEvent('jg-advancedgarages:client:open-garage', garageId, vehicleType, false)
    end
end

local function addBox(coords, heading, size, options)
    if GetResourceState('ox_target') ~= 'started' then return end
    if not coords then return end
    exports.ox_target:addBoxZone({
        coords = coords,
        size = size or vector3(1.2, 1.2, 2.2),
        rotation = heading or 0.0,
        debug = false,
        options = options,
    })
end

local function setupWardrobe(id, station)
    local cfg = station.Wardrobe
    if not cfg or not cfg.coords then return end

    addBox(cfg.coords, cfg.heading, cfg.size or vector3(1.2, 2.0, 2.5), {
        {
            name = ('ems_wardrobe_%s'):format(id),
            icon = cfg.icon or 'fa-solid fa-shirt',
            label = cfg.label or 'EMS Wardrobe',
            groups = station.wardrobeJobs or EMS_GROUPS,
            onSelect = function()
                openWardrobe(station)
            end,
            distance = 2.0,
        },
    })
end

local function setupBossMenu(id, station)
    local cfg = station.BossMenu
    if not cfg or not cfg.coords then return end
    local minGrade = cfg.minGrade or 5
    local groups = {}
    if station.job then groups[station.job] = minGrade end
    if station.wardrobeJobs then
        for name in pairs(station.wardrobeJobs) do
            groups[name] = minGrade
        end
    end

    addBox(cfg.coords, cfg.heading, vector3(1.4, 1.4, 2.2), {
        {
            name = ('ems_boss_%s'):format(id),
            icon = cfg.icon or 'fa-solid fa-briefcase',
            label = cfg.label or 'Boss Menu',
            groups = groups,
            onSelect = function()
                openBossMenu(station)
            end,
            distance = 2.0,
        },
    })
end

local function setupGarage(id, station)
    local cfg = station.Garage
    if not cfg or not cfg.access then return end

    local garageId = cfg.garageId or 'EMS Garage'
    addBox(cfg.access, cfg.heading, vector3(2.0, 2.0, 2.0), {
        {
            name = ('ems_garage_access_%s'):format(id),
            icon = 'fa-solid fa-warehouse',
            label = cfg.label or 'EMS Garage',
            groups = EMS_GROUPS,
            onSelect = function()
                openJobGarage(garageId, 'car')
            end,
            distance = 3.5,
        },
        {
            name = ('ems_garage_store_%s'):format(id),
            icon = 'fa-solid fa-parking',
            label = 'Store Ambulance',
            groups = EMS_GROUPS,
            canInteract = function()
                return cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped
            end,
            onSelect = function()
                TriggerEvent('jg-advancedgarages:client:store-vehicle', garageId, 'car', false)
            end,
            distance = 12.0,
        },
    })
end

local function setupHelipad(id, station)
    local cfg = station.Helipad
    if not cfg or not cfg.access then return end

    local garageId = cfg.garageId or 'EMS Helipad'
    addBox(cfg.access, cfg.heading, vector3(1.8, 1.8, 2.2), {
        {
            name = ('ems_helipad_access_%s'):format(id),
            icon = 'fa-solid fa-helicopter',
            label = cfg.label or 'EMS Helipad',
            groups = EMS_GROUPS,
            onSelect = function()
                openJobGarage(garageId, 'air')
            end,
            distance = 3.0,
        },
    })

    local point = lib.points.new({
        coords = cfg.access,
        distance = 2.2,
    })
    local helipadPrompt = '[E] ' .. (cfg.label or 'EMS Helipad')

    function point:onEnter()
        if not isEmsStaff() then return end
        lib.showTextUI(helipadPrompt)
    end

    function point:onExit()
        local open, text = lib.isTextUIOpen()
        if open and text == helipadPrompt then
            lib.hideTextUI()
        end
    end

    function point:nearby()
        if not isEmsStaff() then return end
        if IsControlJustReleased(0, 38) then
            openJobGarage(garageId, 'air')
        end
    end
end

local function setupStations()
    local stations = configs.Stations
    if type(stations) ~= 'table' then return end

    for id, station in pairs(stations) do
        if type(station) == 'table' then
            setupWardrobe(id, station)
            setupBossMenu(id, station)
            setupGarage(id, station)
            setupHelipad(id, station)
        end
    end
end

CreateThread(function()
    while ESX == nil do Wait(200) end
    while not ESX.IsPlayerLoaded or not ESX.IsPlayerLoaded() do Wait(200) end
    setupStations()
end)
