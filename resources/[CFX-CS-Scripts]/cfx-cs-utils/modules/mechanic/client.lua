local Config = require 'configs.mechanic'
local Vars = require 'helpers.vars'
local helpers = require 'helpers.game'

if not Config.Enabled then return end

local busy = false

local function notify(msg, nType)
    ESX.Notify('MECHANIC', msg, nType or 'info', 4000)
end

local function kitItemNames(cfg)
    if not cfg then return {} end
    if cfg.items then return cfg.items end
    if cfg.item then return { cfg.item } end
    return {}
end

local function hasKit(cfg)
    local amount = cfg and cfg.amount or 1
    local names = kitItemNames(cfg)
    for i = 1, #names do
        if (Vars.ox:Search('count', names[i]) or 0) >= amount then
            return true
        end
    end
    return false
end

local function kitLabel(cfg)
    local names = kitItemNames(cfg)
    for i = 1, #names do
        local item = Vars.oxItems[names[i]]
        if item then return item.label end
    end
    return (cfg and cfg.item) or 'kit'
end

local function ensureControl(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end
    NetworkRequestControlOfEntity(entity)
    local timeout = GetGameTimer() + 2000
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
end

local function repairVehicle(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleFixed(vehicle)
    if GetResourceState('VehicleDeformation') == 'started' then
        exports['VehicleDeformation']:FixVehicleDeformation(vehicle)
    end
end

local function cleanVehicle(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
end

local function runAction(action, entity)
    if busy then
        return notify('You are already busy.', 'error')
    end

    local cfg = action == 'repair' and Config.Repair or Config.Clean
    if not cfg then return end

    if Config.Job and not helpers.HasJob(Config.Job) then
        return notify('Mechanic job required.', 'error')
    end

    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return notify('No vehicle nearby.', 'error')
    end

    if cache.vehicle then
        return notify('Get out of the vehicle first.', 'error')
    end

    local itemAmount = cfg.amount or 1
    local itemData = Vars.oxItems[cfg.item]
    if not itemData then
        for _, name in ipairs(kitItemNames(cfg)) do
            itemData = Vars.oxItems[name]
            if itemData then break end
        end
    end
    if not itemData then
        return notify('INVALID REQUIRED ITEM | CONTACT THE SERVER DEVELOPER', 'error')
    end
    if not hasKit(cfg) then
        return notify(('You must have %sx %s'):format(itemAmount, kitLabel(cfg)), 'error')
    end

    busy = true
    if Vars.oxTarget then
        Vars.oxTarget:disableTargeting(true)
    end

    local anim = cfg.anim or {}
    local progress = {
        duration = cfg.duration or 5000,
        label = cfg.label or 'Working…',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = anim.dict,
            clip = anim.clip,
            flag = 1,
        },
    }
    if cfg.prop then
        progress.prop = cfg.prop
    end

    local success = lib.progressBar(progress)
    busy = false
    if Vars.oxTarget then
        Vars.oxTarget:disableTargeting(false)
    end

    if not success then
        return notify('Cancelled.', 'error')
    end

    if not DoesEntityExist(entity) then
        return notify('The vehicle is gone.', 'error')
    end

    local ok, err = lib.callback.await('cfx-keydi-utils:mechanic:useKit', false, action)
    if not ok then
        return notify(err or 'Could not use the kit.', 'error')
    end

    ensureControl(entity)
    if action == 'repair' then
        repairVehicle(entity)
        notify('Vehicle repaired.', 'success')
    else
        cleanVehicle(entity)
        notify('Vehicle cleaned.', 'success')
    end
end

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(200)
    end

    Vars.oxTarget = Vars.oxTarget or exports.ox_target

    Vars.oxTarget:addGlobalVehicle({
        {
            name = 'cfx_keydi_mechanic_repair',
            icon = 'fa-solid fa-wrench',
            label = 'Use Repair Kit',
            distance = Config.Distance or 2.5,
            groups = Config.Job,
            canInteract = function(entity)
                if busy then return false end
                if cache.vehicle then return false end
                if not entity or not DoesEntityExist(entity) then return false end
                if Config.Job and not helpers.HasJob(Config.Job) then return false end
                if not hasKit(Config.Repair) then return false end
                return true
            end,
            onSelect = function(data)
                runAction('repair', data.entity)
            end,
        },
        {
            name = 'cfx_keydi_mechanic_clean',
            icon = 'fa-solid fa-soap',
            label = 'Use Cleaning Kit',
            distance = Config.Distance or 2.5,
            groups = Config.Job,
            items = Config.Clean.item,
            canInteract = function(entity)
                if busy then return false end
                if cache.vehicle then return false end
                if not entity or not DoesEntityExist(entity) then return false end
                if Config.Job and not helpers.HasJob(Config.Job) then return false end
                return true
            end,
            onSelect = function(data)
                runAction('clean', data.entity)
            end,
        },
    })
end)
