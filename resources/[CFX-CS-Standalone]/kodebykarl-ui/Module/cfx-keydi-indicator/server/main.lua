local ESX = exports["es_extended"]:getSharedObject()

-- Server-side file for cfx-keydi-indicator
-- Combat settings are saved client-side via KVP for local persistent customization.

RegisterNetEvent('cfx-keydi-indicator:server:registerHit', function(attackerServerId, hit, victimDied, bonehash)
    local victimServerId = source
    TriggerClientEvent('cfx-keydi-indicator:client:onHit', attackerServerId, victimServerId, hit, victimDied, bonehash)
end)
