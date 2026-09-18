-- jg-advancedgarages: cleaned + fixed
-- Safe queries, no huge SELECT *, supports JSON or CSV owners column

local function getPlayerPrivateGarages(source)
    local playerIdentifier = Framework.Server.GetPlayerIdentifier(source)
    if not playerIdentifier then
        return {}
    end

    -- Only fetch small fields, never SELECT *
    local result = MySQL.query.await([[
        SELECT id, name, type, x, y, z, h, distance
        FROM player_priv_garages
        WHERE JSON_SEARCH(owners, 'one', ?) IS NOT NULL
           OR FIND_IN_SET(?, owners) > 0
           OR owners LIKE CONCAT('%', ?, '%')
        LIMIT 50
    ]], { playerIdentifier, playerIdentifier, playerIdentifier })

    return result or {}
end

function getPlayerAvailableGarageLocations(source)
    local availableGarages = {}

    -- Config garages
    for garageName, garageData in pairs(Config.GarageLocations or {}) do
        local g = table.clone and table.clone(garageData) or {}
        for k,v in pairs(garageData) do g[k] = v end

        g.checkVehicleGarageId = Config.GarageUniqueLocations
        g.enableInteriors = false
        g.uniqueBlips = Config.GarageUniqueBlips
        g.infiniteSpawns = Config.AllowInfiniteVehicleSpawns
        g.garageType = "personal"

        availableGarages[garageName] = g
    end

    -- Private garages
    for _, garage in ipairs(getPlayerPrivateGarages(source)) do
        local g = {}
        g.coords = vector3(garage.x, garage.y, garage.z)
        g.spawn = vector4(garage.x, garage.y, garage.z, garage.h)
        g.distance = garage.distance
        g.type = garage.type
        g.hideBlip = Config.PrivGarageHideBlips
        g.blip = Config.PrivGarageBlip
        g.uniqueBlips = Config.GarageUniqueBlips
        g.checkVehicleGarageId = Config.GarageUniqueLocations
        g.enableInteriors = false
        g.infiniteSpawns = Config.AllowInfiniteVehicleSpawns
        g.garageType = "personal"

        availableGarages[garage.name] = g
    end

    -- Job garages
    local playerJob = Framework.Server.GetPlayerJob(source)
    for garageName, garageData in pairs(Config.JobGarageLocations or {}) do
        if playerJob then
            local jobMatch = false
            if type(garageData.job) == "table" then
                jobMatch = isItemInList(garageData.job, playerJob.name)
            else
                jobMatch = (garageData.job == playerJob.name)
            end

            if jobMatch then
                local g = {}
                for k,v in pairs(garageData) do g[k] = v end
                g.checkVehicleGarageId = Config.JobGarageUniqueLocations and (garageData.vehiclesType ~= "spawner")
                g.enableInteriors = false
                g.uniqueBlips = Config.JobGarageUniqueBlips
                g.infiniteSpawns = Config.JobGaragesAllowInfiniteVehicleSpawns
                g.garageType = "job"

                availableGarages[garageName] = g
            end
        end
    end

    -- Gang garages
    local gangIntegration = (Config.Gangs == "rcore_gangs")
    local playerGang = nil
    if Config.Framework == "QBCore" or Config.Framework == "Qbox" or Config.GangEnableCustomESXIntegration or gangIntegration then
        playerGang = Framework.Server.GetPlayerGang(source)
    end

    for garageName, garageData in pairs(Config.GangGarageLocations or {}) do
        if playerGang then
            local gangMatch = false
            if type(garageData.gang) == "table" then
                gangMatch = isItemInList(garageData.gang, playerGang.name)
            else
                gangMatch = (garageData.gang == playerGang.name)
            end

            if gangMatch then
                local g = {}
                for k,v in pairs(garageData) do g[k] = v end
                g.checkVehicleGarageId = Config.GangGarageUniqueLocations and (garageData.vehiclesType ~= "spawner")
                g.enableInteriors = false
                g.uniqueBlips = Config.GangGarageUniqueBlips
                g.infiniteSpawns = Config.GangGaragesAllowInfiniteVehicleSpawns
                g.garageType = "gang"

                availableGarages[garageName] = g
            end
        end
    end

    -- Impound garages
    for garageName, garageData in pairs(Config.ImpoundLocations or {}) do
        local g = {}
        for k,v in pairs(garageData) do g[k] = v end
        g.uniqueBlips = Config.ImpoundUniqueBlips
        g.garageType = "impound"
        if Config.ImpoundShowBlips == false then
            g.hideBlip = true
        end

        local hasImpoundJob = false
        if playerJob then
            if type(garageData.job) == "table" then
                hasImpoundJob = isItemInList(garageData.job, playerJob.name)
            else
                hasImpoundJob = (garageData.job == playerJob.name)
            end
        end
        g.hasImpoundJob = hasImpoundJob

        availableGarages[garageName] = g
    end

    return availableGarages
end

-- Export + register
getPlayerAvailableGarageLocations = getPlayerAvailableGarageLocations

lib.callback.register(
    "jg-advancedgarages:server:get-available-garage-locations",
    getPlayerAvailableGarageLocations
)
