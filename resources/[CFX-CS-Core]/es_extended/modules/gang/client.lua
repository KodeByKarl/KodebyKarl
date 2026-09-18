RegisterNetEvent('ESX:Client:OnSharedUpdate', function(tableName, key, value)
    if source ~= 65535 then return end
    ESX.Shared[tableName][key] = value
    TriggerEvent('ESX:Client:UpdateObject')
end)

RegisterNetEvent('ESX:Client:OnSharedUpdateMultiple', function(tableName, values)
    if source ~= 65535 then return end
    for key, value in pairs(values) do
        ESX.Shared[tableName][key] = value
    end
    TriggerEvent('ESX:Client:UpdateObject')
end)

RegisterNetEvent('esx:setGang', function(gangInfo)
    if source ~= 65535 then return end
	ESX.SetPlayerData('gang', gangInfo)
end)

exports('GetCurrentGangs', function()
    return ESX.Shared.Gangs
end)