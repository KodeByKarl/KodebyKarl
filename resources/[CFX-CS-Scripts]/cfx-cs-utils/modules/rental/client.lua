local Rental = require 'configs.rental'
local CurrentRental = nil

---Find nearest rental location based on player distance.
---@return string
local function GetNearestRentalLocation()
    local pedCoords = GetEntityCoords(cache.ped)
    local closestKey = 'airport'
    local closestDist = 999999.0

    for key, loc in pairs(Rental.Locations) do
        local dist = #(pedCoords - vec3(loc.pedCoords.x, loc.pedCoords.y, loc.pedCoords.z))
        if dist < closestDist then
            closestDist = dist
            closestKey = key
        end
    end

    return closestKey
end

---Return the current rented vehicle.
---@param locationKey string
local function ReturnRentalVehicle(locationKey)
    if not CurrentRental or not DoesEntityExist(CurrentRental.entity) then
        CurrentRental = nil
        return ESX.Notify('RENTAL', 'No active rented vehicle found.', 'error', 5000)
    end

    local pedCoords = GetEntityCoords(cache.ped)
    local vehCoords = GetEntityCoords(CurrentRental.entity)
    if #(pedCoords - vehCoords) > 40.0 then
        return ESX.Notify('RENTAL', 'Bring the rented vehicle closer to the rental station to return it.', 'error', 5000)
    end

    if GetVehiclePedIsIn(cache.ped, false) == CurrentRental.entity then
        TaskLeaveVehicle(cache.ped, CurrentRental.entity, 0)
        Wait(1500)
    end

    local plate = CurrentRental.plate
    local deposit = CurrentRental.deposit or 0
    local method = CurrentRental.paymentMethod or 'cash'

    SetEntityAsMissionEntity(CurrentRental.entity, true, true)
    DeleteVehicle(CurrentRental.entity)

    TriggerServerEvent('cfx-keydi-utils:rental:refund', deposit, method, plate)

    pcall(function()
        if exports['kodebykarl-ui'] and exports['kodebykarl-ui'].RemoveKey then
            exports['kodebykarl-ui']:RemoveKey(plate)
        end
    end)

    CurrentRental = nil
    ESX.Notify('RENTAL', ('Vehicle returned! Your deposit of $%s has been refunded.'):format(ESX.Math.GroupDigits(deposit)), 'success', 5000)
end

---Spawn and initialize rented vehicle.
---@param locationKey string
---@param veh table
local function RentVehicle(locationKey, veh)
    local cfg = Rental.Locations[locationKey] or Rental.Locations['airport']

    if CurrentRental and DoesEntityExist(CurrentRental.entity) then
        return ESX.Notify('RENTAL', ('You already have an active rental (%s). Return it first.'):format(CurrentRental.label or 'Vehicle'), 'error', 5000)
    end

    local ok, paymentMethod = lib.callback.await('cfx-keydi-utils:rental:pay', false, veh.price, veh.deposit, veh.model, veh.label, locationKey)
    if not ok then
        local total = (veh.price or 0) + (veh.deposit or 0)
        return ESX.Notify('RENTAL', ('Insufficient funds! You need $%s ($%s rental + $%s deposit).'):format(
            ESX.Math.GroupDigits(total),
            ESX.Math.GroupDigits(veh.price),
            ESX.Math.GroupDigits(veh.deposit)
        ), 'error', 5000)
    end

    local spawn = cfg.spawnCoords
    if IsPositionOccupied(spawn.x, spawn.y, spawn.z, 2.5, false, true, false, false, false, 0, false) then
        ClearAreaOfVehicles(spawn.x, spawn.y, spawn.z, 3.5, false, false, false, false, false)
    end

    lib.requestModel(veh.model)

    local vehicle = CreateVehicle(veh.model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)

    local plate = ('RENT%04d'):format(math.random(1000, 9999))
    SetVehicleNumberPlateText(vehicle, plate)

    Entity(vehicle).state.fuel = 100
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleHandbrake(vehicle, false)
    FreezeEntityPosition(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)

    -- Give keys
    TriggerServerEvent('cfx-keydi-carlock:server:giveKey', plate)
    pcall(function()
        if exports['kodebykarl-ui'] and exports['kodebykarl-ui'].GiveKey then
            exports['kodebykarl-ui']:GiveKey(plate)
        end
    end)

    -- Warp player into driver seat
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)

    CurrentRental = {
        entity = vehicle,
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        plate = plate,
        model = veh.model,
        label = veh.label,
        deposit = veh.deposit,
        location = locationKey,
        paymentMethod = paymentMethod,
    }

    TriggerServerEvent('cfx-keydi-utils:rental:registered', CurrentRental.netId, plate, veh.deposit, paymentMethod)

    ESX.Notify('RENTAL', ('You rented a %s! Keys received. Return it to reclaim your $%s deposit.'):format(
        veh.label,
        ESX.Math.GroupDigits(veh.deposit)
    ), 'success', 6000)
end

---Open the rental context menu for a specific location.
---@param locationKey string?
function OpenRentalMenu(locationKey)
    if not locationKey or not Rental.Locations[locationKey] then
        locationKey = GetNearestRentalLocation()
    end

    local cfg = Rental.Locations[locationKey]
    if not cfg then return end

    local options = {}

    -- Option: Return existing rental if active
    if CurrentRental and DoesEntityExist(CurrentRental.entity) then
        table.insert(options, {
            title = ('Return %s'):format(CurrentRental.label or 'Vehicle'),
            description = ('Return your vehicle to reclaim your deposit of $%s'):format(ESX.Math.GroupDigits(CurrentRental.deposit or 0)),
            icon = 'fa-solid fa-rotate-left',
            iconColor = '#10b981',
            onSelect = function()
                ReturnRentalVehicle(locationKey)
            end
        })
    elseif CurrentRental and not DoesEntityExist(CurrentRental.entity) then
        table.insert(options, {
            title = 'Clear Lost Vehicle (Deposit Forfeited)',
            description = 'Your previous rental is no longer active. Click to clear record.',
            icon = 'fa-solid fa-trash-can',
            iconColor = '#ef4444',
            onSelect = function()
                CurrentRental = nil
                ESX.Notify('RENTAL', 'Rental status cleared.', 'info', 4000)
            end
        })
    end

    -- List available vehicles
    local vehicles = Rental.Vehicles[cfg.category] or Rental.Vehicles.land
    for _, veh in ipairs(vehicles) do
        table.insert(options, {
            title = veh.label,
            description = ('Fee: $%s  ·  Deposit: $%s'):format(
                ESX.Math.GroupDigits(veh.price),
                ESX.Math.GroupDigits(veh.deposit)
            ),
            icon = veh.icon or 'fa-solid fa-car',
            metadata = {
                { label = 'Model', value = veh.model },
                { label = 'Rental Fee', value = ('$%s'):format(ESX.Math.GroupDigits(veh.price)) },
                { label = 'Refundable Deposit', value = ('$%s'):format(ESX.Math.GroupDigits(veh.deposit)) },
                { label = 'About', value = veh.description or 'Rental vehicle' },
            },
            onSelect = function()
                RentVehicle(locationKey, veh)
            end
        })
    end

    lib.registerContext({
        id = 'kodebykarl_rental_' .. tostring(locationKey),
        title = cfg.label or 'Rental',
        options = options
    })

    lib.showContext('kodebykarl_rental_' .. tostring(locationKey))
end

-- Net event & exports
RegisterNetEvent('cfx-keydi-utils:rental:open', OpenRentalMenu)
exports('OpenRentalMenu', OpenRentalMenu)
