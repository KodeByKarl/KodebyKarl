ESX = exports['es_extended']:getSharedObject()

local PlayerInjuries = {}
local tempInjuries = {}
function GetCharsInjuriesBySource(source)
    if PlayerInjuries[source] then
        return PlayerInjuries[source]
    end
    return {}
end

exports('GetCharsInjuriesBySource', GetCharsInjuriesBySource)

function GetInjuriesByIdentifier(identifier)
    if tempInjuries[identifier] then
        return tempInjuries[identifier]
    end
    return {}
end

exports('GetInjuriesByIdentifier', GetInjuriesByIdentifier)

RegisterServerEvent('cfx-keydi-ambulance:server:SyncInjuries')
AddEventHandler('cfx-keydi-ambulance:server:SyncInjuries', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        tempInjuries[xPlayer.identifier] = data
    end
    PlayerInjuries[src] = data
end)

AddEventHandler('playerDropped', function(reason)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if xPlayer and PlayerInjuries[xPlayer.source] then
        xPlayer.setMeta('injuries', PlayerInjuries[xPlayer.source])
        PlayerInjuries[xPlayer.source] = nil
	end
end)