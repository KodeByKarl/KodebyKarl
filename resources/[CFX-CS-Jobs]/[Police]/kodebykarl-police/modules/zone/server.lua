local CreatedZones = {}
function getTableLength()
    local count = 0
    for k,v in pairs(CreatedZones) do
        count += 1
    end
    return count
end

local playersChecked = {}

RegisterNetEvent('ESX:Client:PlayerLoaded', function()
    local src = source
    if playersChecked[src] then return end
    playersChecked[src] = true
    if next(CreatedZones) then
        for k,v in pairs(CreatedZones) do
            TriggerClientEvent('cfx-cs-police:CreateZone', src, v.coords, v.index)
        end
    end
end)

function getClosestZone(playerId)
    local coords = GetEntityCoords(GetPlayerPed(playerId))
    for k,v in pairs(CreatedZones) do
        if #(coords - v.coords) <= 150 then
            return v.index, k
        end
    end
    return false
end

RegisterCommand('redzone', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not HasGroup(src) then return end
    local ZoneID = ESX.GetRandomString(5) 
    local ZoneCoords = GetEntityCoords(GetPlayerPed(src))
    if getClosestZone(src) then return end
    if getTableLength() >= 3 then return end
    TriggerClientEvent('cfx-cs-police:CreateZone', -1 , ZoneCoords, 'POLICE-'..ZoneID:upper())
    CreatedZones['POLICE-'..ZoneID:upper()] = {
        coords = ZoneCoords,
        index = 'POLICE-'..ZoneID:upper()
    }
    -- Add Log
end)

RegisterCommand('greenzone', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not HasGroup(src) then return end
    local Zone, ZoneId = getClosestZone(src)
    if not Zone then return end
    if not CreatedZones[ZoneId] then return end
    TriggerClientEvent('cfx-cs-police:DeleteCreatedZone', -1, Zone)
    CreatedZones[ZoneId] = nil
    -- Add Log
end)

AddEventHandler('esx:playerDropped', function(playerId)
	if playersChecked[playerId] then
		playersChecked[playerId] = nil
	end
end)
