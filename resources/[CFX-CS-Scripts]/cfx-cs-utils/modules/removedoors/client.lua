-- Client-side handler for /rd and /removedoors

-- Side door indices only (0: Front Left, 1: Front Right, 2: Rear Left, 3: Rear Right)
-- Hood (4) and Trunk (5/6) are intentionally excluded!
local SIDE_DOORS = { 0, 1, 2, 3 }

local function removeVehicleSideDoors(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    for _, doorIndex in ipairs(SIDE_DOORS) do
        -- Check if door exists before breaking
        if GetIsDoorValid(vehicle, doorIndex) then
            SetVehicleDoorBroken(vehicle, doorIndex, false)
        end
    end
end

-- Broadcasted sync from server
RegisterNetEvent('cfx-keydi-utils:removedoors:apply', function(netId)
    if not netId or netId == 0 then return end
    local vehicle = NetToVeh(netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        removeVehicleSideDoors(vehicle)
    end
end)

local function handleRemoveDoorsCommand()
    local ped = cache.ped or PlayerPedId()
    local vehicle = cache.vehicle or GetVehiclePedIsIn(ped, false)

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return lib.notify({
            title = 'Vehicle Doors',
            description = 'Kailangan mong nasa loob ng sasakyan para tanggalin ang pinto.',
            type = 'error'
        })
    end

    -- Check if player is in the driver seat (-1)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return lib.notify({
            title = 'Vehicle Doors',
            description = 'Driver lamang ang maaaring magtanggal ng mga pinto ng sasakyan.',
            type = 'error'
        })
    end

    -- Remove doors locally
    removeVehicleSideDoors(vehicle)

    -- Network sync to all nearby players
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId and netId ~= 0 then
        TriggerServerEvent('cfx-keydi-utils:removedoors:sync', netId)
    end

    lib.notify({
        title = 'Vehicle Doors',
        description = 'Matagumpay na natanggal ang mga pinto ng sasakyan.',
        type = 'success'
    })
end

-- Register /doors, /rd, and /removedoors
RegisterCommand('doors', function()
    handleRemoveDoorsCommand()
end, false)

RegisterCommand('rd', function()
    handleRemoveDoorsCommand()
end, false)

RegisterCommand('removedoors', function()
    handleRemoveDoorsCommand()
end, false)

RegisterCommand('removedoor', function()
    handleRemoveDoorsCommand()
end, false)

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/doors', 'Remove all side doors from the vehicle you are driving')
    TriggerEvent('chat:addSuggestion', '/rd', 'Remove all side doors from the vehicle you are driving')
    TriggerEvent('chat:addSuggestion', '/removedoors', 'Remove all side doors from the vehicle you are driving')
end)
