local function getOffsetSpawnPointByHeading(spawnPoint)
    local x = spawnPoint.x
    local y = spawnPoint.y
    local heading = spawnPoint.w

    if (heading >= 0 and heading <= 45) or (heading >= 315 and heading <= 360) then
        y = y + 5
    elseif heading >= 46 and heading <= 135 then
        x = x - 5
    elseif heading >= 136 and heading <= 225 then
        y = y - 5
    elseif heading >= 226 and heading <= 314 then
        x = x + 5
    end

    return vector4(x, y, spawnPoint.z, spawnPoint.w)
end

function findVehicleSpawnCoords(spawnPoints)
    if type(spawnPoints) == "table" then
        for _, spawnPoint in pairs(spawnPoints) do
            local closestVehicle = lib.getClosestVehicle(spawnPoint.xyz, 2.5)
            if not closestVehicle then
                return spawnPoint
            end
        end

        -- Fallback to offset attempts around the first configured point.
        return findVehicleSpawnCoords(spawnPoints[1])
    end

    local attempts = 1
    local currentSpawnPoint = spawnPoints

    while attempts <= 10 do
        local closestVehicle = lib.getClosestVehicle(currentSpawnPoint.xyz, 2.5)
        if not closestVehicle then
            return currentSpawnPoint
        end

        currentSpawnPoint = getOffsetSpawnPointByHeading(currentSpawnPoint)
        attempts = attempts + 1
    end

    return currentSpawnPoint
end

function deleteVehicle(vehicleEntity, vehicleData, vehiclePlate, forceDelete)
    if GetResourceState("AdvancedParking") == "started" then
        if vehicleData or vehiclePlate then
            exports.AdvancedParking:DeleteVehicleUsingData(nil, vehicleData, vehiclePlate, false)
            return
        end

        exports.AdvancedParking:DeleteVehicle(vehicleEntity, false)
        return
    end

    DeleteEntity(vehicleEntity)
end

function getNearbyPlayers(excludePlayerId, playerCoords, maxDistance, includeSelf)
    local playersInfo = {}

    -- All online players (transfer by ID/name) unless nearby-only is enabled
    if not Config.TransferRequireNearbyPlayer then
        for _, playerId in ipairs(GetPlayers()) do
            local id = tonumber(playerId)
            if includeSelf or id ~= excludePlayerId then
                local playerInfo = {
                    id = id,
                    identifier = Framework.Server.GetPlayerIdentifier(id)
                }

                local details = Framework.Server.GetPlayerInfo(id)
                if details then
                    playerInfo.name = details.name
                end

                playersInfo[#playersInfo + 1] = playerInfo
            end
        end

        return playersInfo
    end

    local nearbyPlayers = lib.getNearbyPlayers(playerCoords, maxDistance or Config.TransferNearbyDistance or 20.0)

    for _, playerData in ipairs(nearbyPlayers) do
        if not includeSelf and excludePlayerId == playerData.id then
            goto continue
        end

        local playerInfo = {
            id = playerData.id,
            identifier = Framework.Server.GetPlayerIdentifier(playerData.id)
        }

        local details = Framework.Server.GetPlayerInfo(playerData.id)
        if details then
            playerInfo.name = details.name
        end

        playersInfo[#playersInfo + 1] = playerInfo
        ::continue::
    end

    return playersInfo
end

function getAllGaragesAndImpounds()
    local publicGarages = lib.table.deepclone(Config.GarageLocations)
    local jobGarages = lib.table.deepclone(Config.JobGarageLocations)
    local gangGarages = lib.table.deepclone(Config.GangGarageLocations)
    local impoundGarages = lib.table.deepclone(Config.ImpoundLocations)
    local privateGarages = {}

    local privateGarageRows = MySQL.query.await("SELECT * FROM player_priv_garages")
    for _, row in ipairs(privateGarageRows) do
        privateGarages[row.name] = {
            coords = vector3(row.x, row.y, row.z),
            spawn = vector4(row.x, row.y, row.z, row.h),
            distance = row.distance,
            type = row.type,
            hideBlip = Config.PrivGarageHideBlips,
            blip = Config.PrivGarageBlip
        }
    end

    local allGarages = lib.table.merge(
        lib.table.merge(
            lib.table.merge(
                lib.table.merge(impoundGarages, privateGarages),
                gangGarages
            ),
            jobGarages
        ),
        publicGarages
    )

    return allGarages or {}
end

-- Client calls: nearby-players(playerCoords, maxDistance, includeSelf)
-- Use source as excludePlayerId so the transferring player is not listed
lib.callback.register("jg-advancedgarages:server:nearby-players", function(source, playerCoords, maxDistance, includeSelf)
    return getNearbyPlayers(source, playerCoords, maxDistance, includeSelf)
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    initSQL()
end)