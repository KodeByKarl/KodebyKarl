-- Server-side sync for /rd and /removedoors

RegisterNetEvent('cfx-keydi-utils:removedoors:sync', function(netId)
    local src = source
    if not netId or netId == 0 then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    -- Verify player is in the driver seat
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then return end

    TriggerClientEvent('cfx-keydi-utils:removedoors:apply', -1, netId)
end)
