local options = {}
local respawnLocations = {}
local respawn = require 'shared.spawn'
local Vars = require 'helpers.vars'

local function selectRespawn()
    local selectedId
    local ok, result = pcall(function()
        return exports[GetCurrentResourceName()]:GetSelectedRespawnId()
    end)
    if ok then
        selectedId = result
    end

    if type(selectedId) == 'string' and respawnLocations[selectedId] then
        return respawnLocations[selectedId]
    end

    local zoneId = Vars.SelectStlZone()
    return respawnLocations[zoneId] or respawnLocations['integrity_way'] or respawnLocations['murrieta'] or false
end

CreateThread(function()
    for key, data in pairs(respawn.Locations) do
        if not data.hidden then
            local requiredJob = data.job
            if requiredJob then
                local job = ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
                if job == requiredJob then
                    options[#options + 1] = { value = key, label = data.label }
                end
            else
                options[#options + 1] = { value = key, label = data.label }
            end
        end
        respawnLocations[key] = data.coords
    end

    for key, data in pairs(respawn.Gangs) do
        respawnLocations[key] = data.coords
    end
end)

exports('SelectRespawn', selectRespawn)
