local clamp = lib.math.clamp

RegisterNetEvent('es_extended:status:update', function()
    local src = source
    local xPlayer = ESX.Players[src]
    if not xPlayer then return end
    local status = xPlayer.getMeta('status')
    if not status then return end
    local hunger = clamp(ESX.Math.Round((tonumber(status.hunger) or 100) - Config.Status.hunger_rate), 0, 100)
    local thirst = clamp(ESX.Math.Round((tonumber(status.thirst) or 100) - Config.Status.thirst_rate), 0, 100)
    local stress = tonumber(status.stress) or 0
    status.hunger = hunger
    status.thirst = thirst
    xPlayer.setMeta('status', status)
    TriggerClientEvent('es_extended:status:updateStatus', src, hunger, thirst, stress)
end)

local function updateStatus(src, stat, amount)
    local xPlayer = ESX.Players[src]
    if not xPlayer then return end

    local status = xPlayer.getMeta('status')
    if not status then return end

    if stat == "hunger" then
        status.hunger = clamp(status.hunger + amount, 0, 100)
    elseif stat == "thirst" then
        status.thirst = clamp(status.thirst + amount, 0, 100)
    elseif stat == "stress" then
        status.stress = clamp(status.stress + amount, 0, 100)
    end
    xPlayer.setMeta('status', status)
    TriggerClientEvent('es_extended:status:updateStatus', src, status.hunger, status.thirst, status.stress)
end

RegisterNetEvent('ESX:Status:AddHunger',    function(v) updateStatus(source, "hunger",  v) end)
RegisterNetEvent('ESX:Status:RemoveHunger', function(v) updateStatus(source, "hunger", -v) end)
RegisterNetEvent('ESX:Status:AddThirst',    function(v) updateStatus(source, "thirst",  v) end)
RegisterNetEvent('ESX:Status:RemoveThirst', function(v) updateStatus(source, "thirst", -v) end)
RegisterNetEvent('ESX:Status:AddStress',    function(v) updateStatus(source, "stress",  v) end)
RegisterNetEvent('ESX:Status:RemoveStress', function(v) updateStatus(source, "stress", -v) end)


AddEventHandler('ESX:Status:ResetStatus', function(playerId)
	local xPlayer = ESX.Players[playerId]
    if not xPlayer then return end
    local status = xPlayer.getMeta('status')
    if not status then return end
    status.hunger = 50
    status.thirst = 50
    status.stress = 0
    xPlayer.setMeta('status', status)
    TriggerClientEvent('es_extended:status:updateStatus', xPlayer.source, status.hunger, status.thirst, status.stress)
end)

AddEventHandler('esx:playerLoaded', function(_, xPlayer)
    local status = xPlayer.getMeta('status')
    local array = {
        status = status,
        gang = {
            label = xPlayer.gang.label,
            grade = {name = xPlayer.gang.grade.name}
        }
    }
    TriggerClientEvent('esx:compat:HudLoad', xPlayer.source, array)
end)

ESX.RegisterCommand('heal', {'moderator', 'admin', 'superadmin', 'developer'}, function(xPlayer, args)
    local status = args.playerId.getMeta('status')
    if not status then return end
    status.hunger = 100
    status.thirst = 100
    args.playerId.setMeta('status', status)
    args.playerId.triggerEvent('es_extended:status:updateStatus', status.hunger, status.thirst, status.stress)
end, true, {
    help = 'Restore player hunger, thirst, stress.',
    validate = true,
    arguments = {
        { name = 'playerId', help = 'Player ID', type = 'player' }
    }
})

local function secureSetStatus(targetId, newStatus)
    local xPlayer = ESX.Players[targetId] or (ESX.GetPlayerFromId and ESX.GetPlayerFromId(targetId))
    if not xPlayer then return false end

    local status = xPlayer.getMeta('status') or { hunger = 100, thirst = 100, stress = 0 }
    if type(newStatus) == 'table' then
        if newStatus.hunger ~= nil then status.hunger = clamp(tonumber(newStatus.hunger) or 100, 0, 100) end
        if newStatus.thirst ~= nil then status.thirst = clamp(tonumber(newStatus.thirst) or 100, 0, 100) end
        if newStatus.stress ~= nil then status.stress = clamp(tonumber(newStatus.stress) or 0, 0, 100) end
    end

    xPlayer.setMeta('status', status)
    TriggerClientEvent('es_extended:status:updateStatus', xPlayer.source, status.hunger, status.thirst, status.stress)
    return true
end

exports('SecureSetStatus', secureSetStatus)