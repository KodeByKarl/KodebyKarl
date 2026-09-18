local createdProps = {}



---@param playerPed number
---@param serverId number
---@return number object
local function createRadioProp(playerPed, serverId)
    lib.requestModel(`prop_cs_hand_radio`)

    local coords = GetEntityCoords(playerPed)
    local object = CreateObject(`prop_cs_hand_radio`, coords.x, coords.y, coords.z, false, false, false)

    AttachEntityToEntity(object, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 0, true)
    SetModelAsNoLongerNeeded(`prop_cs_hand_radio`)

    createdProps[serverId] = object

    return object
end

---@param serverId number
local function removeRadioProp(serverId)
    local object = createdProps[serverId]

    if object then
        if DoesEntityExist(object) then
            DeleteObject(object)
        end

        createdProps[serverId] = nil
    end
end



---@param bagName string
---@return number? serverId
---@return number? playerPed
local function getPlayerFromStateBagName(bagName)
    local serverId = tonumber(string.match(bagName, 'player:(%d+)'))
    local playerId = GetPlayerFromStateBagName(bagName)
    if not playerId or playerId == 0 then
        return serverId, nil
    end

    if playerId == cache.playerId then
        return cache.serverId, cache.ped
    end

    if not NetworkIsPlayerActive(playerId) then
        return serverId, nil
    end

    local ped = GetPlayerPed(playerId)
    if not ped or ped <= 0 or not DoesEntityExist(ped) then
        return serverId, nil
    end

    return serverId or GetPlayerServerId(playerId), ped
end



---@param bagName string
---@param value boolean
---@param replicated boolean
AddStateBagChangeHandler('ac:hasRadioProp', '', function(bagName, _, value, _, replicated)
    if replicated then return end

    local serverId, playerPed = getPlayerFromStateBagName(bagName)
    if not serverId then return end

    if value then
        if playerPed then
            removeRadioProp(serverId)
            createRadioProp(playerPed, serverId)
        end
    else
        removeRadioProp(serverId)
    end
end)

---@param serverId number
RegisterNetEvent('onPlayerDropped', function(serverId)
    removeRadioProp(serverId)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        for _, object in pairs(createdProps) do
            if DoesEntityExist(object) then
                DeleteObject(object)
            end
        end
    end
end)
