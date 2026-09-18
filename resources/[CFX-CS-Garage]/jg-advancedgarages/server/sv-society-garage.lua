local function notify(playerId, message, messageType)
    Framework.Server.Notify(playerId, message, messageType)
end

local function ensureAdmin(playerId)
    if Framework.Server.IsAdmin(playerId) then
        return true
    end

    notify(playerId, "INSUFFICIENT_PERMISSIONS", "error")
    return false
end

local function getPlayerOwnedCurrentVehiclePlate(playerId)
    local playerPed = GetPlayerPed(playerId)
    local currentVehicle = GetVehiclePedIsIn(playerPed, false)
    if not currentVehicle or currentVehicle == 0 then
        notify(playerId, Locale.notInsideVehicleError, "error")
        return nil
    end

    local plate = Framework.Server.GetPlate(currentVehicle)
    if not plate then
        debugPrint("Framework.Server.GetPlate returned nil.", "warning")
        return nil
    end

    local vehicleData = getVehicleData(playerId, false, plate)
    if not vehicleData then
        notify(playerId, Locale.vehicleNotOwnedByPlayerError, "error")
        return nil
    end

    return plate
end

local function getSocietyDefinitions(societyType)
    if societyType == "gang" then
        local gangs = Framework.Server.GetGangs()
        if gangs then
            return gangs
        end
    end

    return Framework.Server.GetJobs() or {}
end

local function addCurrentVehicleToSocietyGarage(playerId, societyType, societyName, minimumGrade)
    local societyDefinitions = getSocietyDefinitions(societyType)
    if not societyName or not societyDefinitions[societyName] then
        local invalidMessage = societyType == "job" and Locale.invalidJobError or Locale.invalidGangError or invalidGangError
        notify(playerId, invalidMessage, "error")
        return
    end

    local plate = getPlayerOwnedCurrentVehiclePlate(playerId)
    if not plate then
        return
    end

    local queryTemplate = Framework.Queries.SetJobVehicle
    if societyType == "gang" then
        queryTemplate = Framework.Queries.SetGangVehicle or Framework.Queries.SetJobVehicle
    end

    local query = queryTemplate:format(Framework.VehiclesTable, Framework.PlayerIdentifier)
    MySQL.update.await(query, {
        societyName,
        minimumGrade,
        plate
    })

    local successMessageTemplate = societyType == "gang"
        and Locale.vehicleAddedToGangGarageSuccess
        or Locale.vehicleAddedToJobGarageSuccess

    local successMessage = string.gsub(successMessageTemplate, "%%{value}", societyName)
    notify(playerId, successMessage, "success")
end

local function removeCurrentVehicleFromSocietyGarage(playerId, targetPlayerId)
    local plate = getPlayerOwnedCurrentVehiclePlate(playerId)
    if not plate then
        return
    end

    local targetIdentifier = Framework.Server.GetPlayerIdentifier(targetPlayerId)
    if not targetIdentifier then
        notify(playerId, Locale.playerNotOnlineError, "error")
        return
    end

    local query = Framework.Queries.SetSocietyVehicleAsPlayerOwned:format(
        Framework.VehiclesTable,
        Framework.PlayerIdentifier
    )

    MySQL.update.await(query, {
        targetIdentifier,
        plate
    })

    local targetPlayerInfo = Framework.Server.GetPlayerInfo(targetPlayerId)
    local targetName = targetPlayerInfo and targetPlayerInfo.name or tostring(targetPlayerId)

    notify(
        playerId,
        string.gsub(Locale.vehicleTransferSuccess, "%%{value}", targetName),
        "success"
    )

    notify(
        targetPlayerId,
        string.gsub(Locale.vehicleReceived, "%%{value}", plate),
        "success"
    )
end

local function registerSetSocietyVehicleCommand(commandName, helpText, societyType, societyArgName, societyArgHelp, minGradeHelp)
    lib.addCommand(commandName, {
        help = helpText,
        params = {
            {
                name = societyArgName,
                type = "string",
                help = societyArgHelp
            },
            {
                name = "grade",
                type = "number",
                help = minGradeHelp,
                optional = true
            }
        }
    }, function(playerId, args)
        if not ensureAdmin(playerId) then
            return
        end

        if societyType == "gang"
            and Config.Framework ~= "QBCore"
            and Config.Gangs ~= "rcore_gangs"
            and not Config.GangEnableCustomESXIntegration then
            notify(playerId, "Gangs are only compatible with QBCore & Qbox", "error")
            return
        end

        addCurrentVehicleToSocietyGarage(
            playerId,
            societyType,
            args[societyArgName],
            args.grade or 0
        )
    end)
end

local function registerRemoveSocietyVehicleCommand(commandName, helpText)
    lib.addCommand(commandName, {
        help = helpText,
        params = {
            {
                name = "id",
                type = "playerId",
                help = Locale.cmdArgPlayerId
            }
        }
    }, function(playerId, args)
        if not ensureAdmin(playerId) then
            return
        end

        removeCurrentVehicleFromSocietyGarage(playerId, tonumber(args.id) or 0)
    end)
end

registerSetSocietyVehicleCommand(
    Config.JobGarageSetVehicleCommand,
    Locale.cmdSetJobVehicle,
    "job",
    "job",
    Locale.cmdArgJobName,
    Locale.cmgArgMinJobRank
)

registerSetSocietyVehicleCommand(
    Config.GangGarageSetVehicleCommand,
    Locale.cmdSetGangVehicle,
    "gang",
    "gang",
    Locale.cmdArgGangName,
    Locale.cmgArgMinGangRank
)

registerRemoveSocietyVehicleCommand(
    Config.JobGarageRemoveVehicleCommand,
    Locale.cmdRemoveJobVehicle
)

registerRemoveSocietyVehicleCommand(
    Config.GangGarageRemoveVehicleCommand,
    Locale.cmdRemoveGangVehicle
)
