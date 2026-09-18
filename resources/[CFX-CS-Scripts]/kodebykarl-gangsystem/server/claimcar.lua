local ESX = exports['es_extended']:getSharedObject()

local spawnedByOwner = {} -- [identifier] = entity
local plateBusy = {}

local function EnsureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `gang_car_claims` (
            `identifier` VARCHAR(60) NOT NULL,
            `gang` VARCHAR(50) DEFAULT NULL,
            `plate` VARCHAR(12) DEFAULT NULL,
            `model` VARCHAR(50) DEFAULT NULL,
            `stored` TINYINT(1) NOT NULL DEFAULT 1,
            `banned` TINYINT(1) NOT NULL DEFAULT 0,
            `claimed_at` TIMESTAMP NULL DEFAULT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    EnsureTable()
end)

local function GetLivePlaytime(xPlayer)
    if not xPlayer then return 0 end
    local identifier = xPlayer.identifier
    local base = 0
    if Core and Core.PlayTimeData and Core.PlayTimeData[identifier] ~= nil then
        base = tonumber(Core.PlayTimeData[identifier]) or 0
    else
        base = tonumber(xPlayer.playtime) or 0
    end
    local session = 0
    if Core and Core.CachePlayerPlayTime and Core.CachePlayerPlayTime[identifier] then
        session = math.max(0, os.time() - Core.CachePlayerPlayTime[identifier])
    end
    return base + session
end

local function GetRow(identifier)
    return MySQL.single.await('SELECT * FROM gang_car_claims WHERE identifier = ? LIMIT 1', { identifier })
end

local function EnsureRow(identifier)
    local row = GetRow(identifier)
    if row then return row end
    MySQL.insert.await(
        'INSERT INTO gang_car_claims (identifier, banned, stored) VALUES (?, 0, 1)',
        { identifier }
    )
    return GetRow(identifier)
end

local function GeneratePlate(prefix)
    prefix = tostring(prefix or 'GANG'):upper():gsub('%W', ''):sub(1, 4)
    for _ = 1, 30 do
        local plate = ('%s%04d'):format(prefix, math.random(0, 9999))
        plate = plate:sub(1, 8)
        local exists = MySQL.scalar.await('SELECT 1 FROM gang_car_claims WHERE plate = ? LIMIT 1', { plate })
        if not exists then
            return plate
        end
    end
    return nil
end

local function DeleteSpawned(identifier)
    local ent = spawnedByOwner[identifier]
    if ent and DoesEntityExist(ent) then
        DeleteEntity(ent)
    end
    spawnedByOwner[identifier] = nil
end

local function BanPlayer(identifier, reason)
    EnsureRow(identifier)
    MySQL.update.await('UPDATE gang_car_claims SET banned = 1 WHERE identifier = ?', { identifier })
    DeleteSpawned(identifier)
    MySQL.update.await('UPDATE gang_car_claims SET stored = 1 WHERE identifier = ? AND plate IS NOT NULL', { identifier })
    if Config.Debug then
        print(('[kodebykarl-gangsystem] gang car banned %s (%s)'):format(identifier, reason or 'switch'))
    end
end

--- Leaving / switching gangs permanently bans gang-car claims.
AddEventHandler('esx:setGang', function(src, newGang, oldGang)
    if type(oldGang) ~= 'table' or not oldGang.name or oldGang.name == 'none' then
        return
    end
    local newName = type(newGang) == 'table' and newGang.name or 'none'
    if newName == oldGang.name then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    BanPlayer(xPlayer.identifier, ('%s -> %s'):format(oldGang.name, newName))
end)

lib.callback.register('kodebykarl-gangsystem:claimPed:status', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false } end

    local gang = GangServer.GetPlayerGang(source)
    local row = GetRow(xPlayer.identifier)
    local playtime = GetLivePlaytime(xPlayer)
    local required = (Config.ClaimPed and Config.ClaimPed.requiredPlaytime) or (2 * 60 * 60)

    local claimed = row and row.plate and row.plate ~= ''
    local banned = row and tonumber(row.banned) == 1
    local stored = not claimed or tonumber(row.stored) == 1
    local sameGang = claimed and gang and row.gang == gang.name

    return {
        ok = true,
        inGang = gang ~= nil,
        gang = gang and gang.name or nil,
        gangLabel = gang and gang.label or nil,
        playtime = playtime,
        required = required,
        playtimeOk = playtime >= required,
        claimed = claimed == true,
        banned = banned == true,
        stored = stored,
        canClaim = (not claimed) and (not banned) and gang ~= nil and playtime >= required,
        canTakeOut = claimed and (not banned) and sameGang and stored,
        canStore = claimed and (not banned) and sameGang and (not stored),
        plate = row and row.plate or nil,
        model = row and row.model or nil,
    }
end)

lib.callback.register('kodebykarl-gangsystem:claimPed:claim', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, message = 'Player not found.' } end
    if plateBusy[xPlayer.identifier] then
        return { ok = false, message = 'Please wait.' }
    end

    local gang = GangServer.GetPlayerGang(source)
    if not gang then
        return { ok = false, message = 'You must be in a gang to claim a car.' }
    end

    local cfg = GangServer.GetGangDef(gang.name)
    if not cfg or not cfg.vehicle or not cfg.vehicle.model then
        return { ok = false, message = 'This gang has no claim vehicle.' }
    end

    local required = (Config.ClaimPed and Config.ClaimPed.requiredPlaytime) or (2 * 60 * 60)
    local playtime = GetLivePlaytime(xPlayer)
    if playtime < required then
        local left = required - playtime
        local hrs = math.floor(left / 3600)
        local mins = math.floor((left % 3600) / 60)
        return { ok = false, message = ('Need %dh %dm more playtime.'):format(hrs, mins) }
    end

    plateBusy[xPlayer.identifier] = true
    local row = EnsureRow(xPlayer.identifier)

    if tonumber(row.banned) == 1 then
        plateBusy[xPlayer.identifier] = nil
        return { ok = false, message = 'You can never claim a gang car (left/switched gangs).' }
    end
    if row.plate and row.plate ~= '' then
        plateBusy[xPlayer.identifier] = nil
        return { ok = false, message = 'You already claimed your one gang car.' }
    end

    local prefix = (cfg.vehicle.platePrefix or Config.ClaimPed.platePrefix or 'GANG')
    local plate = GeneratePlate(prefix)
    if not plate then
        plateBusy[xPlayer.identifier] = nil
        return { ok = false, message = 'Could not generate plate.' }
    end

    local model = tostring(cfg.vehicle.model):lower()
    MySQL.update.await([[
        UPDATE gang_car_claims
        SET gang = ?, plate = ?, model = ?, stored = 1, banned = 0, claimed_at = CURRENT_TIMESTAMP
        WHERE identifier = ?
    ]], { gang.name, plate, model, xPlayer.identifier })

    plateBusy[xPlayer.identifier] = nil
    GangServer.Notify(source, 'GANG CAR', ('Claimed %s [%s]. Take it out here anytime.'):format(model, plate), 'success')
    return { ok = true, plate = plate, model = model }
end)

lib.callback.register('kodebykarl-gangsystem:claimPed:takeOut', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, message = 'Player not found.' } end

    local gang = GangServer.GetPlayerGang(source)
    local row = GetRow(xPlayer.identifier)
    if not row or not row.plate or row.plate == '' then
        return { ok = false, message = 'You have not claimed a gang car.' }
    end
    if tonumber(row.banned) == 1 then
        return { ok = false, message = 'Gang car access locked (you left/switched gangs).' }
    end
    if not gang or gang.name ~= row.gang then
        return { ok = false, message = 'You must be in your original gang to take this car out.' }
    end
    if tonumber(row.stored) ~= 1 then
        return { ok = false, message = 'Your gang car is already out.' }
    end

    local pedCfg = Config.ClaimPed
    if not pedCfg or not pedCfg.spawn then
        return { ok = false, message = 'Spawn not configured.' }
    end

    local spawn = pedCfg.spawn
    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        local pcoords = GetEntityCoords(ped)
        if #(pcoords - vector3(pedCfg.coords.x, pedCfg.coords.y, pedCfg.coords.z)) > 8.0 then
            return { ok = false, message = 'Too far from the claim ped.' }
        end
    end

    DeleteSpawned(xPlayer.identifier)

    -- Clear vehicles blocking spawn
    local vehicles = GetAllVehicles()
    for i = 1, #vehicles do
        local veh = vehicles[i]
        if DoesEntityExist(veh) then
            local vcoords = GetEntityCoords(veh)
            if #(vcoords - vector3(spawn.x, spawn.y, spawn.z)) < 3.5 then
                DeleteEntity(veh)
            end
        end
    end

    local hash = joaat(row.model)
    local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w or 0.0, true, true)
    if not veh or veh == 0 then
        return { ok = false, message = 'Failed to spawn vehicle.' }
    end

    local timeout = GetGameTimer() + 3000
    while not DoesEntityExist(veh) and GetGameTimer() < timeout do
        Wait(0)
    end

    SetVehicleNumberPlateText(veh, row.plate)
    SetVehicleDoorsLocked(veh, 1)
    Entity(veh).state:set('gangClaimVehicle', xPlayer.identifier, true)
    spawnedByOwner[xPlayer.identifier] = veh

    MySQL.update.await('UPDATE gang_car_claims SET stored = 0 WHERE identifier = ?', { xPlayer.identifier })

    local netId = NetworkGetNetworkIdFromEntity(veh)
    pcall(function()
        if GetResourceState('kodebykarl-ui') == 'started' then
            exports['kodebykarl-ui']:GiveKey(source, row.plate)
        end
    end)

    return { ok = true, netId = netId, plate = row.plate }
end)

lib.callback.register('kodebykarl-gangsystem:claimPed:store', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, message = 'Player not found.' } end

    local gang = GangServer.GetPlayerGang(source)
    local row = GetRow(xPlayer.identifier)
    if not row or not row.plate or row.plate == '' then
        return { ok = false, message = 'No claimed gang car.' }
    end
    if tonumber(row.banned) == 1 then
        return { ok = false, message = 'Gang car access locked.' }
    end
    if not gang or gang.name ~= row.gang then
        return { ok = false, message = 'Wrong gang.' }
    end
    if tonumber(row.stored) == 1 then
        return { ok = false, message = 'Car is already stored.' }
    end

    local pedCfg = Config.ClaimPed
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return { ok = false, message = 'Invalid ped.' } end
    local pcoords = GetEntityCoords(ped)
    if #(pcoords - vector3(pedCfg.coords.x, pedCfg.coords.y, pedCfg.coords.z)) > 12.0 then
        return { ok = false, message = 'Too far from the claim ped.' }
    end

    -- Prefer vehicle player is driving with matching plate, else tracked entity
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh = spawnedByOwner[xPlayer.identifier]
    end

    if not veh or veh == 0 or not DoesEntityExist(veh) then
        -- Force-store if entity missing (despawned / crashed)
        MySQL.update.await('UPDATE gang_car_claims SET stored = 1 WHERE identifier = ?', { xPlayer.identifier })
        spawnedByOwner[xPlayer.identifier] = nil
        return { ok = true, message = 'Gang car stored.' }
    end

    local plate = (GetVehicleNumberPlateText(veh) or ''):gsub('%s+', '')
    local expect = (row.plate or ''):gsub('%s+', '')
    if plate:upper() ~= expect:upper() then
        return { ok = false, message = 'That is not your claimed gang car.' }
    end

    DeleteEntity(veh)
    spawnedByOwner[xPlayer.identifier] = nil
    MySQL.update.await('UPDATE gang_car_claims SET stored = 1 WHERE identifier = ?', { xPlayer.identifier })
    return { ok = true, message = 'Gang car stored.' }
end)

AddEventHandler('playerDropped', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    -- Auto-store on disconnect if vehicle was out
    local row = GetRow(xPlayer.identifier)
    if row and row.plate and tonumber(row.stored) == 0 then
        DeleteSpawned(xPlayer.identifier)
        MySQL.update.await('UPDATE gang_car_claims SET stored = 1 WHERE identifier = ?', { xPlayer.identifier })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for identifier, ent in pairs(spawnedByOwner) do
        if ent and DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        spawnedByOwner[identifier] = nil
    end
end)
