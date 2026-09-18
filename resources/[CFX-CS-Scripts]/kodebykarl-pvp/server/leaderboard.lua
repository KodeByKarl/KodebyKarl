local cacheData = {}
local topPlayers = {}

local TABLE = 'pvp_stats'
local ALLOWED_STATS = {
    kills = true,
    deaths = true,
    th = true,
}

local function sortAndRank()
    topPlayers = {}
    for _, data in pairs(cacheData) do
        topPlayers[#topPlayers + 1] = data
    end
    table.sort(topPlayers, function(a, b) return (a.kills or 0) > (b.kills or 0) end)
    for i, v in ipairs(topPlayers) do
        if v.identifier and cacheData[v.identifier] then
            cacheData[v.identifier].rank = 'Top: ' .. i
        end
    end
end

local function loadDataFromDb()
    local rows = MySQL.query.await(('SELECT identifier, name, kills, deaths, th FROM `%s`'):format(TABLE), {})
    local data = {}
    if rows then
        for i = 1, #rows do
            local row = rows[i]
            local identifier = row.identifier
            if identifier then
                data[identifier] = {
                    identifier = identifier,
                    name = row.name or '',
                    kills = tonumber(row.kills) or 0,
                    deaths = tonumber(row.deaths) or 0,
                    th = tonumber(row.th) or 0,
                }
            end
        end
    end
    return data
end

local function fetchPlayerRow(identifier)
    if not identifier then return nil end
    local rows = MySQL.query.await(
        ('SELECT identifier, name, kills, deaths, th FROM `%s` WHERE identifier = ? LIMIT 1'):format(TABLE),
        { identifier }
    )
    local row = rows and rows[1]
    if not row then return nil end
    return {
        identifier = row.identifier,
        name = row.name or '',
        kills = tonumber(row.kills) or 0,
        deaths = tonumber(row.deaths) or 0,
        th = tonumber(row.th) or 0,
    }
end

local function ensurePlayerRow(identifier, name)
    if not identifier then return end
    local playerName = name or ''

    if cacheData[identifier] then
        if playerName ~= '' and cacheData[identifier].name ~= playerName then
            cacheData[identifier].name = playerName
            MySQL.update.await(('UPDATE `%s` SET name = ? WHERE identifier = ?'):format(TABLE), { playerName, identifier })
        end
        return
    end

    local existing = fetchPlayerRow(identifier)
    if existing then
        cacheData[identifier] = existing
        if playerName ~= '' and existing.name ~= playerName then
            cacheData[identifier].name = playerName
            MySQL.update.await(('UPDATE `%s` SET name = ? WHERE identifier = ?'):format(TABLE), { playerName, identifier })
        end
        return
    end

    MySQL.update.await(
        ('INSERT INTO `%s` (identifier, name, kills, deaths, th) VALUES (?, ?, 0, 0, 0) ON DUPLICATE KEY UPDATE name = VALUES(name)'):format(TABLE),
        { identifier, playerName }
    )

    cacheData[identifier] = {
        identifier = identifier,
        name = playerName,
        kills = 0,
        deaths = 0,
        th = 0,
    }
end

local function updateStat(identifier, stat, amount, name)
    if not identifier or not ALLOWED_STATS[stat] then return end
    amount = tonumber(amount)
    if not amount or amount == 0 then return end

    ensurePlayerRow(identifier, name or 'Unknown')
    cacheData[identifier][stat] = (cacheData[identifier][stat] or 0) + amount
    MySQL.update.await(
        ('UPDATE `%s` SET `%s` = `%s` + ?, updated_at = CURRENT_TIMESTAMP WHERE identifier = ?'):format(TABLE, stat, stat),
        { amount, identifier }
    )
    sortAndRank()
end

exports('updateStat', updateStat)

local function Kd(kills, deaths)
    kills = tonumber(kills) or 0
    deaths = tonumber(deaths) or 0
    if deaths > 0 then
        return math.floor((kills / deaths) * 10 + 0.5) / 10
    end
    return kills + 0.0
end

local function BuildLeaderboard(source)
    local list = {}
    for _, data in pairs(cacheData) do
        if (data.kills or 0) > 0 or (data.deaths or 0) > 0 then
            list[#list + 1] = data
        end
    end
    table.sort(list, function(a, b) return (a.kills or 0) > (b.kills or 0) end)

    local rows = {}
    local mine = nil
    local xPlayer = source and ESX.GetPlayerFromId(source)
    local myId = xPlayer and xPlayer.identifier or nil

    for i = 1, math.min(50, #list) do
        local data = list[i]
        local row = {
            rank = i,
            name = data.name or 'Unknown',
            kills = data.kills or 0,
            deaths = data.deaths or 0,
            kd = Kd(data.kills, data.deaths),
        }
        rows[#rows + 1] = row
        if myId and data.identifier == myId then
            mine = row
        end
    end

    if myId and not mine and cacheData[myId] then
        local data = cacheData[myId]
        mine = {
            rank = nil,
            name = data.name or (xPlayer and xPlayer.getName()) or 'You',
            kills = data.kills or 0,
            deaths = data.deaths or 0,
            kd = Kd(data.kills, data.deaths),
        }
    end

    return { ok = true, rows = rows, mine = mine }
end

lib.callback.register('kodebykarl-pvp:getLeaderboard', function(source)
    return BuildLeaderboard(source)
end)

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `pvp_stats` (
            `identifier` VARCHAR(60) NOT NULL,
            `name` VARCHAR(100) NOT NULL DEFAULT '',
            `kills` INT NOT NULL DEFAULT 0,
            `deaths` INT NOT NULL DEFAULT 0,
            `th` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    cacheData = loadDataFromDb()
    sortAndRank()
end)

AddEventHandler('esx:playerLoaded', function(_, xPlayer)
    local identifier = xPlayer and xPlayer.identifier
    if not identifier then return end
    ensurePlayerRow(identifier, xPlayer.getName())
    sortAndRank()
end)

RegisterNetEvent('kodebykarl-pvp:OnDeath', function(data)
    local src = source
    if GetResourceState(GetCurrentResourceName()) == 'started' then
        if not exports[GetCurrentResourceName()]:IsInMatch(src) then return end
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    updateStat(xPlayer.identifier, 'deaths', 1, xPlayer.getName())

    if data and data.killedByPlayer and type(data.killerServerId) == 'number' and data.killerServerId > 0 then
        local xKiller = ESX.GetPlayerFromId(data.killerServerId)
        if xKiller then
            updateStat(xKiller.identifier, 'kills', 1, xKiller.getName())
        end
    end
end)

lib.cron.new('*/5 * * * *', function()
    if next(cacheData) then
        sortAndRank()
    end
end)
