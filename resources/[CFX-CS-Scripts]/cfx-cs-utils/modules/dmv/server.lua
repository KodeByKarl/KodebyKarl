local Config = require 'configs.dmv'
local ox_inventory = exports.ox_inventory
local cacheVehicle = {}
local successCoords = vec3(235.283, -1398.329, 28.921)
local cachePaid = {}
local allowedVehicles = {
    [`blista`] = true,
    [`sanchez`] = true
}

local dbLicenseType = {
    therotical = 'dmv',
    car = 'drive',
    motorcycle = 'drive_bike',
}

local function PayHandler(source, price, method)
    local src = source
    local has = ox_inventory:Search(src, 'count', 'money')
    if has >= price then
        cachePaid[src] = method or true
        ox_inventory:RemoveItem(src, 'money', price)
        if method == 'car' or method == 'motorcycle' then
            pcall(function()
                exports[GetCurrentResourceName()]:FgVehicleSession(src, 'plate', true, 15000)
            end)
        end
        return true
    end
    return false
end

lib.callback.register('cfx-cs-dmv:pay', PayHandler)
lib.callback.register('cfx-keydi-utils:dmv:pay', PayHandler)

local function ValidatedDrivingSchool(xPlayer, method)
    local paid = cachePaid[xPlayer.source]
    if not paid then
        return false, 'ADVANCED CHECK 2'
    end
    if type(paid) == 'string' and method and paid ~= method then
        return false, 'METHOD MISMATCH'
    end

    -- entityCreating / NetworkGetEntityOwner is unreliable with OneSync, so
    -- missing cacheVehicle is logged but no longer blocks a paid practical test.
    if cacheVehicle[xPlayer.source] and not allowedVehicles[cacheVehicle[xPlayer.source].vehicle] then
        return false, 'ADVANCED CHECK 1'
    end

    -- Last checkpoint forces the player out of the car (~3m trigger + exit),
    -- so 5m was rejecting real passes.
    local playerCoords = xPlayer.getCoords(true)
    if #(playerCoords - successCoords) > 30.0 then
        return false, 'DISTANCE CHECK'
    end
    return true
end

local function PersistUserLicense(identifier, method)
    local licenseType = dbLicenseType[method]
    if not licenseType or not identifier or not MySQL then return end
    pcall(function()
        local exists = MySQL.scalar.await(
            'SELECT 1 FROM `user_licenses` WHERE `type` = ? AND `owner` = ? LIMIT 1',
            { licenseType, identifier }
        )
        if not exists then
            MySQL.insert.await(
                'INSERT INTO `user_licenses` (`type`, `owner`) VALUES (?, ?)',
                { licenseType, identifier }
            )
        end
    end)
end

local function FormatLogs(name, playerId, reason, coords)
    local coordsText = 'unknown'
    if coords then
        coordsText = ('vec3(%.2f, %.2f, %.2f)'):format(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
    end
    local text = {
        'SENTRY DETECTION FOR DRIVING SCHOOL',
        ('Player: %s [%s]'):format(name, playerId),
        ('Reason: %s'):format(reason or 'unknown'),
        ('Coords: %s'):format(coordsText),
    }
    return table.concat(text, ' | ')
end

local licenseLabels = {
    therotical = 'Theoretical License',
    car = 'Drivers License',
    motorcycle = 'Motorcycle License',
}

local function EnsureLicenseEntry(licenses, key)
    if type(licenses[key]) ~= 'table' then
        licenses[key] = { has = false, label = licenseLabels[key] or key }
    end
    if not licenses[key].label then
        licenses[key].label = licenseLabels[key] or key
    end
    return licenses[key]
end

local function CompleteHandler(data)
    if type(data) ~= 'table' or type(data.zxc) ~= 'string' then return end
    local method = data.zxc
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if method ~= 'therotical' and method ~= 'car' and method ~= 'motorcycle' then return end

    local licenses = xPlayer.getMeta('licenses') or {}
    if method ~= 'therotical' then
        local success, reason = ValidatedDrivingSchool(xPlayer, method)
        if not success then
            lib.logger(xPlayer.source, 'cfx-keydi-sentry', FormatLogs(xPlayer.name, xPlayer.source, reason, xPlayer.getCoords(true)), 'ERROR')
            print(("^0[^3cfx-keydi-utils:dmv^0]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
            return
        end
    end

    local entry = EnsureLicenseEntry(licenses, method)
    entry.has = true
    xPlayer.setMeta('licenses', licenses)
    PersistUserLicense(xPlayer.identifier, method)

    if method == 'car' and GetResourceState('ox_inventory') == 'started' then
        local count = ox_inventory:Search(src, 'count', 'driver_license') or 0
        if count < 1 then
            ox_inventory:AddItem(src, 'driver_license', 1, {
                owner = xPlayer.identifier,
                issuedBy = 'DMV',
            })
        end
    end

    if cacheVehicle[src] ~= nil then cacheVehicle[src] = nil end
    if cachePaid[src] ~= nil then cachePaid[src] = nil end
end

RegisterNetEvent('cfx-cs-dmv:Complete', CompleteHandler)
RegisterNetEvent('cfx-keydi-utils:dmv:Complete', CompleteHandler)

AddEventHandler('entityCreating', function(entity)
    if not Config or not Config.DrivingSchool or not Config.DrivingSchool.Coords or not Config.DrivingSchool.Coords.vehicleSpawn then return end
    local src = NetworkGetEntityOwner(entity)
    local sourceEntity = tonumber(src)
    if sourceEntity == -1 or sourceEntity == 0 then return end
    local entityModel = GetEntityModel(entity)
    local targetCoords = GetEntityCoords(entity)
    local sourceCoords = Config.DrivingSchool.Coords.vehicleSpawn
    if #(targetCoords - sourceCoords.xyz) < 3.0 and allowedVehicles[entityModel] then
        cacheVehicle[src] = {vehicle = entityModel}
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if cacheVehicle[src] ~= nil then cacheVehicle[src] = nil end
    if cachePaid[src] ~= nil then cachePaid[src] = nil end
end)

local function decodeMetadata(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) == 'string' and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then return decoded end
    end
    return {}
end

local function applyDrivingLicensesToMeta(metadata)
    metadata = type(metadata) == 'table' and metadata or {}
    local licenses = metadata.licenses
    if type(licenses) ~= 'table' then
        licenses = {}
        metadata.licenses = licenses
    end
    EnsureLicenseEntry(licenses, 'therotical').has = true
    EnsureLicenseEntry(licenses, 'car').has = true
    return metadata
end

local function grantOnlinePlayerLicense(xPlayer)
    if not xPlayer or not xPlayer.getMeta then return end
    local licenses = xPlayer.getMeta('licenses') or {}
    EnsureLicenseEntry(licenses, 'therotical').has = true
    EnsureLicenseEntry(licenses, 'car').has = true
    xPlayer.setMeta('licenses', licenses)
    PersistUserLicense(xPlayer.identifier, 'therotical')
    PersistUserLicense(xPlayer.identifier, 'car')
end

---Grants theoretical + car licenses to every character in `users`.
---@return integer updated, integer online
local function GrantAllDrivingLicenses()
    local onlineIds = {}
    local onlineCount = 0
    local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}
    for _, xPlayer in pairs(xPlayers) do
        if xPlayer and xPlayer.identifier then
            onlineIds[xPlayer.identifier] = true
            grantOnlinePlayerLicense(xPlayer)
            onlineCount += 1
        end
    end

    local users = MySQL.query.await('SELECT identifier, metadata FROM users') or {}
    local metaUpdates = {}
    local licenseInserts = {}
    local haveLicense = {}

    local existing = MySQL.query.await(
        'SELECT type, owner FROM user_licenses WHERE type IN (?, ?)',
        { 'dmv', 'drive' }
    ) or {}
    for i = 1, #existing do
        local row = existing[i]
        haveLicense[('%s:%s'):format(row.type, row.owner)] = true
    end

    for i = 1, #users do
        local user = users[i]
        local identifier = user.identifier
        if identifier then
            if not onlineIds[identifier] then
                local metadata = applyDrivingLicensesToMeta(decodeMetadata(user.metadata))
                metaUpdates[#metaUpdates + 1] = { json.encode(metadata), identifier }
            end
            if not haveLicense[('dmv:%s'):format(identifier)] then
                licenseInserts[#licenseInserts + 1] = { 'dmv', identifier }
            end
            if not haveLicense[('drive:%s'):format(identifier)] then
                licenseInserts[#licenseInserts + 1] = { 'drive', identifier }
            end
        end
    end

    if #metaUpdates > 0 then
        MySQL.prepare.await('UPDATE users SET metadata = ? WHERE identifier = ?', metaUpdates)
    end
    if #licenseInserts > 0 then
        MySQL.prepare.await('INSERT INTO user_licenses (`type`, `owner`) VALUES (?, ?)', licenseInserts)
    end

    local updated = #users
    print(('^0[^3cfx-keydi-utils:dmv^0]: Granted driving licenses to %s users (%s online).'):format(updated, onlineCount))
    return updated, onlineCount
end

CreateThread(function()
    while GetResourceState('es_extended') ~= 'started' or not ESX do
        Wait(500)
    end
    Wait(2500)
    if GetResourceKvpInt('dmv_granted_all_v1') == 1 then
        return
    end
    GrantAllDrivingLicenses()
    SetResourceKvpInt('dmv_granted_all_v1', 1)
end)

RegisterCommand('grantdmvall', function(source)
    if source ~= 0 then
        return
    end
    GrantAllDrivingLicenses()
    SetResourceKvpInt('dmv_granted_all_v1', 1)
end, true)
