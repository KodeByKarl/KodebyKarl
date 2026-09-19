--[[
  /givecar [playerId] [carModel]
  Adds an owned vehicle to the target's garage (owned_vehicles).
]]

local GiveCar = require 'configs.givecar'

if not GiveCar or not GiveCar.Enabled then return end

local function groupsToList(groups)
    local list, seen = {}, {}
    local function add(name)
        if type(name) ~= 'string' or name == '' then return end
        name = name:lower()
        if seen[name] then return end
        seen[name] = true
        list[#list + 1] = name
    end

    if type(groups) == 'string' then
        add(groups)
    elseif type(groups) == 'table' then
        if #groups > 0 then
            for i = 1, #groups do add(groups[i]) end
        else
            for name, allowed in pairs(groups) do
                if allowed then add(name) end
            end
        end
    end

    if Config and Config.CommandPermissions and Config.CommandPermissions.givecar then
        local extra = Config.CommandPermissions.givecar
        if type(extra) == 'table' then
            if #extra > 0 then
                for i = 1, #extra do add(extra[i]) end
            else
                for name, allowed in pairs(extra) do
                    if allowed then add(name) end
                end
            end
        end
    end

    if #list == 0 then
        add('owner')
        add('developer')
        add('superadmin')
    end
    return list
end

local AllowedGroups = groupsToList(GiveCar.AllowedGroups)

local function notify(src, message, msgType)
    TriggerClientEvent('esx:Notify', src, GiveCar.NotifyTitle or 'GIVE CAR', message, msgType or 'info', 7000)
end

local function isAllowed(xPlayer)
    if not xPlayer or not xPlayer.getGroup then return false end
    if not Core or not Core.CommandAllowsGroup then
        local group = tostring(xPlayer.getGroup() or ''):lower()
        for i = 1, #AllowedGroups do
            if AllowedGroups[i] == group then return true end
        end
        return false
    end
    return Core.CommandAllowsGroup(AllowedGroups, xPlayer.getGroup())
end

local function generatePlate()
    if GetResourceState('jg-dealerships-v2') == 'started' then
        local ok, plate = pcall(function()
            return exports['jg-dealerships-v2']:generatePlate(nil, true)
        end)
        if ok and type(plate) == 'string' and plate ~= '' then
            return plate:upper()
        end
    end

    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = ''
    for _ = 1, 8 do
        local i = math.random(1, #chars)
        plate = plate .. chars:sub(i, i)
    end
    return plate
end

local function insertOwnedVehicle(owner, plate, model, garageId, nick)
    local vehicleJson = json.encode({ model = joaat(model), plate = plate })
    local attempts = {
        {
            [[
                INSERT INTO owned_vehicles
                    (`owner`, `plate`, `vehicle`, `stored`, `in_garage`, `garage_id`, `nickname`, `fuel`, `engine`, `body`)
                VALUES (?, ?, ?, 1, 1, ?, ?, 100, 1000, 1000)
            ]],
            { owner, plate, vehicleJson, garageId, nick },
        },
        {
            'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`, `in_garage`, `garage_id`, `nickname`) VALUES (?, ?, ?, 1, 1, ?, ?)',
            { owner, plate, vehicleJson, garageId, nick },
        },
        {
            'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`, `nickname`) VALUES (?, ?, ?, 1, ?)',
            { owner, plate, vehicleJson, nick },
        },
        {
            'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`) VALUES (?, ?, ?, 1)',
            { owner, plate, vehicleJson },
        },
    }

    local lastErr
    for i = 1, #attempts do
        local ok, err = pcall(function()
            MySQL.insert.await(attempts[i][1], attempts[i][2])
        end)
        if ok then
            return true
        end
        lastErr = err
    end
    return false, lastErr
end

ESX.RegisterCommand('givecar', AllowedGroups, function(xPlayer, args)
    if not isAllowed(xPlayer) then
        notify(xPlayer.source, 'Owner / developer access only.', 'error')
        return
    end

    local targetId = tonumber(args.playerId or args.id)
    local model = args.carmodel or args.model

    if not targetId or type(model) ~= 'string' or model == '' then
        notify(xPlayer.source, 'Usage: /givecar [id] [carmodel]', 'error')
        return
    end

    model = model:lower():gsub('%s+', '')
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        notify(xPlayer.source, 'Player not online.', 'error')
        return
    end

    local plate = generatePlate()
    local garageId = GiveCar.DefaultGarage or 'Legion Square'
    local nick = ('%s-%s'):format(GiveCar.NicknamePrefix or 'ADMIN-GIVE', plate)

    local ok, err = insertOwnedVehicle(xTarget.identifier, plate, model, garageId, nick)
    if not ok then
        print(('[givecar] insert failed: %s'):format(tostring(err)))
        notify(xPlayer.source, 'Failed to insert vehicle into database.', 'error')
        return
    end

    pcall(function()
        if GetResourceState('kodebykarl-ui') == 'started' then
            exports['kodebykarl-ui']:GiveKey(targetId, plate)
        end
    end)

    notify(xPlayer.source, ('Gave %s to ID %s (plate %s → %s).'):format(model, targetId, plate, garageId), 'success')
    notify(targetId, ('You received a %s (plate %s). Pick it up at %s.'):format(model, plate, garageId), 'success')

    lib.logger(xPlayer.source, 'cfx-keydi-utils-givecar', ('%s gave %s plate %s to %s [%s]'):format(
        xPlayer.name, model, plate, xTarget.name, targetId
    ))
end, true, {
    help = 'Give an owned garage vehicle to a player (owner/developer)',
    validate = false,
    arguments = {
        { name = 'playerId', help = 'Player server ID', type = 'number' },
        { name = 'carmodel', help = 'Vehicle spawn name (e.g. sultan)', type = 'any' },
    },
})
