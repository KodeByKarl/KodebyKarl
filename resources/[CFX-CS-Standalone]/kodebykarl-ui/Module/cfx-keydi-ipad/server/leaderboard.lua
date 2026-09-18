--[[
    iPad Leaderboards — persistent standings
    turfwar (gang claims) · traphouse · party teams · top players
    PvP stays on kodebykarl-pvp:getLeaderboard
]]

local ESX = exports['es_extended']:getSharedObject()

local CACHE = {
    turf = {},
    trap = {},
    party = {},
    players = {},
}

local DEBOUNCE = {} -- ["killer:victim:kind"] = os.time()

local function Kd(kills, deaths)
    kills = tonumber(kills) or 0
    deaths = tonumber(deaths) or 0
    if deaths > 0 then
        return math.floor((kills / deaths) * 100 + 0.5) / 100
    end
    return kills + 0.0
end

local function inPvpMatch(src)
    if not src or GetResourceState('kodebykarl-pvp') ~= 'started' then
        return false
    end
    local ok, inside = pcall(function()
        return exports['kodebykarl-pvp']:IsInMatch(src)
    end)
    return ok and inside == true
end

local function playerParty(src)
    local ok, party = pcall(function()
        return exports[GetCurrentResourceName()]:GetPlayerParty(src)
    end)
    if ok and type(party) == 'table' and party.id then
        return { id = party.id, name = party.name }
    end
    return nil
end

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_lb_turfwar` (
            `gang_name` VARCHAR(64) NOT NULL,
            `gang_label` VARCHAR(96) NOT NULL DEFAULT '',
            `claims` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`gang_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_lb_traphouse` (
            `identifier` VARCHAR(72) NOT NULL,
            `name` VARCHAR(96) NOT NULL DEFAULT '',
            `kills` INT NOT NULL DEFAULT 0,
            `deaths` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_lb_party` (
            `party_id` INT NOT NULL,
            `party_name` VARCHAR(64) NOT NULL DEFAULT '',
            `kills` INT NOT NULL DEFAULT 0,
            `deaths` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`party_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_lb_players` (
            `identifier` VARCHAR(72) NOT NULL,
            `name` VARCHAR(96) NOT NULL DEFAULT '',
            `kills` INT NOT NULL DEFAULT 0,
            `deaths` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

local function loadCache()
    CACHE.turf = {}
    for _, row in ipairs(MySQL.query.await('SELECT gang_name, gang_label, claims FROM grim_lb_turfwar', {}) or {}) do
        CACHE.turf[row.gang_name] = {
            gang = row.gang_name,
            label = row.gang_label or row.gang_name,
            claims = tonumber(row.claims) or 0,
        }
    end

    CACHE.trap = {}
    for _, row in ipairs(MySQL.query.await('SELECT identifier, name, kills, deaths FROM grim_lb_traphouse', {}) or {}) do
        CACHE.trap[row.identifier] = {
            identifier = row.identifier,
            name = row.name or 'Unknown',
            kills = tonumber(row.kills) or 0,
            deaths = tonumber(row.deaths) or 0,
        }
    end

    CACHE.party = {}
    for _, row in ipairs(MySQL.query.await('SELECT party_id, party_name, kills, deaths FROM grim_lb_party', {}) or {}) do
        CACHE.party[tonumber(row.party_id)] = {
            id = tonumber(row.party_id),
            name = row.party_name or ('Party #' .. row.party_id),
            kills = tonumber(row.kills) or 0,
            deaths = tonumber(row.deaths) or 0,
        }
    end

    CACHE.players = {}
    for _, row in ipairs(MySQL.query.await('SELECT identifier, name, kills, deaths FROM grim_lb_players', {}) or {}) do
        CACHE.players[row.identifier] = {
            identifier = row.identifier,
            name = row.name or 'Unknown',
            kills = tonumber(row.kills) or 0,
            deaths = tonumber(row.deaths) or 0,
        }
    end
end

local function debounced(kind, killer, victim)
    local key = ('%s:%s:%s'):format(kind, tostring(killer or 0), tostring(victim or 0))
    local now = os.time()
    if DEBOUNCE[key] and (now - DEBOUNCE[key]) < 2 then
        return true
    end
    DEBOUNCE[key] = now
    return false
end

local function ensurePlayerRow(bucket, identifier, name)
    if not identifier then return nil end
    local store = CACHE[bucket]
    if not store[identifier] then
        store[identifier] = {
            identifier = identifier,
            name = name or 'Unknown',
            kills = 0,
            deaths = 0,
        }
        local tableName = bucket == 'trap' and 'grim_lb_traphouse' or 'grim_lb_players'
        MySQL.insert.await(
            ('INSERT INTO `%s` (identifier, name, kills, deaths) VALUES (?, ?, 0, 0) ON DUPLICATE KEY UPDATE name = VALUES(name)'):format(tableName),
            { identifier, name or 'Unknown' }
        )
    elseif name and name ~= '' and store[identifier].name ~= name then
        store[identifier].name = name
        local tableName = bucket == 'trap' and 'grim_lb_traphouse' or 'grim_lb_players'
        MySQL.update.await(('UPDATE `%s` SET name = ? WHERE identifier = ?'):format(tableName), { name, identifier })
    end
    return store[identifier]
end

local function bumpPlayerStat(bucket, identifier, name, field, amount)
    local row = ensurePlayerRow(bucket, identifier, name)
    if not row then return end
    amount = tonumber(amount) or 0
    if amount == 0 then return end
    row[field] = (row[field] or 0) + amount
    local tableName = bucket == 'trap' and 'grim_lb_traphouse' or 'grim_lb_players'
    MySQL.update.await(
        ('UPDATE `%s` SET `%s` = `%s` + ? WHERE identifier = ?'):format(tableName, field, field),
        { amount, identifier }
    )
end

local function ensurePartyRow(partyId, partyName)
    partyId = tonumber(partyId)
    if not partyId then return nil end
    if not CACHE.party[partyId] then
        CACHE.party[partyId] = {
            id = partyId,
            name = partyName or ('Party #' .. partyId),
            kills = 0,
            deaths = 0,
        }
        MySQL.insert.await(
            'INSERT INTO grim_lb_party (party_id, party_name, kills, deaths) VALUES (?, ?, 0, 0) ON DUPLICATE KEY UPDATE party_name = VALUES(party_name)',
            { partyId, partyName or ('Party #' .. partyId) }
        )
    elseif partyName and partyName ~= '' and CACHE.party[partyId].name ~= partyName then
        CACHE.party[partyId].name = partyName
        MySQL.update.await('UPDATE grim_lb_party SET party_name = ? WHERE party_id = ?', { partyName, partyId })
    end
    return CACHE.party[partyId]
end

local function bumpPartyStat(partyId, partyName, field, amount)
    local row = ensurePartyRow(partyId, partyName)
    if not row then return end
    amount = tonumber(amount) or 0
    if amount == 0 then return end
    row[field] = (row[field] or 0) + amount
    MySQL.update.await(
        ('UPDATE grim_lb_party SET `%s` = `%s` + ? WHERE party_id = ?'):format(field, field),
        { amount, partyId }
    )
end

local function buildKdBoard(store, source, limit)
    local list = {}
    for _, data in pairs(store) do
        if (data.kills or 0) > 0 or (data.deaths or 0) > 0 then
            list[#list + 1] = data
        end
    end
    table.sort(list, function(a, b)
        if (a.kills or 0) == (b.kills or 0) then
            return Kd(a.kills, a.deaths) > Kd(b.kills, b.deaths)
        end
        return (a.kills or 0) > (b.kills or 0)
    end)

    local xPlayer = source and ESX.GetPlayerFromId(source)
    local myId = xPlayer and xPlayer.identifier or nil
    local rows = {}
    local mine = nil
    limit = limit or 50

    for i = 1, math.min(limit, #list) do
        local data = list[i]
        local row = {
            rank = i,
            name = data.name or 'Unknown',
            gang = data.gang or data.label or nil,
            kills = data.kills or 0,
            deaths = data.deaths or 0,
            kd = Kd(data.kills, data.deaths),
            score = ('%d K / %d D'):format(data.kills or 0, data.deaths or 0),
            subtitle = ('KDA %.2f'):format(Kd(data.kills, data.deaths)),
        }
        rows[#rows + 1] = row
        if myId and data.identifier == myId then
            mine = row
        end
    end

    if myId and not mine and store[myId] then
        local data = store[myId]
        mine = {
            rank = nil,
            name = data.name or (xPlayer and xPlayer.getName()) or 'You',
            kills = data.kills or 0,
            deaths = data.deaths or 0,
            kd = Kd(data.kills, data.deaths),
            score = ('%d K / %d D'):format(data.kills or 0, data.deaths or 0),
            subtitle = ('KDA %.2f'):format(Kd(data.kills, data.deaths)),
        }
    end

    return { ok = true, rows = rows, mine = mine }
end

-- ── Public record APIs ─────────────────────────────────────────────────────

exports('LeaderboardRecordTurfClaim', function(gangName, gangLabel)
    if type(gangName) ~= 'string' or gangName == '' or gangName == 'none' or gangName == 'unemployed' then
        return
    end
    gangLabel = (type(gangLabel) == 'string' and gangLabel ~= '') and gangLabel or gangName
    if not CACHE.turf[gangName] then
        CACHE.turf[gangName] = { gang = gangName, label = gangLabel, claims = 0 }
        MySQL.insert.await(
            'INSERT INTO grim_lb_turfwar (gang_name, gang_label, claims) VALUES (?, ?, 0) ON DUPLICATE KEY UPDATE gang_label = VALUES(gang_label)',
            { gangName, gangLabel }
        )
    else
        CACHE.turf[gangName].label = gangLabel
        MySQL.update.await('UPDATE grim_lb_turfwar SET gang_label = ? WHERE gang_name = ?', { gangLabel, gangName })
    end
    CACHE.turf[gangName].claims = (CACHE.turf[gangName].claims or 0) + 1
    MySQL.update.await('UPDATE grim_lb_turfwar SET claims = claims + 1 WHERE gang_name = ?', { gangName })
end)

exports('LeaderboardRecordTrapKill', function(killerSrc, victimSrc)
    local xKiller = killerSrc and ESX.GetPlayerFromId(killerSrc)
    local xVictim = victimSrc and ESX.GetPlayerFromId(victimSrc)
    if xKiller then
        bumpPlayerStat('trap', xKiller.identifier, xKiller.getName and xKiller.getName() or xKiller.name, 'kills', 1)
    end
    if xVictim then
        bumpPlayerStat('trap', xVictim.identifier, xVictim.getName and xVictim.getName() or xVictim.name, 'deaths', 1)
    end
end)

local function recordCityKill(killerSrc, victimSrc)
    if debounced('city', killerSrc, victimSrc) then return end
    if inPvpMatch(victimSrc) or inPvpMatch(killerSrc) then return end

    local xVictim = victimSrc and ESX.GetPlayerFromId(victimSrc)
    local xKiller = killerSrc and ESX.GetPlayerFromId(killerSrc)

    if xVictim then
        bumpPlayerStat('players', xVictim.identifier, xVictim.getName and xVictim.getName() or xVictim.name, 'deaths', 1)
        local victimParty = playerParty(victimSrc)
        if victimParty then
            bumpPartyStat(victimParty.id, victimParty.name, 'deaths', 1)
        end
    end

    if xKiller and killerSrc ~= victimSrc then
        bumpPlayerStat('players', xKiller.identifier, xKiller.getName and xKiller.getName() or xKiller.name, 'kills', 1)
        local killerParty = playerParty(killerSrc)
        if killerParty then
            bumpPartyStat(killerParty.id, killerParty.name, 'kills', 1)
        end
    end
end

RegisterNetEvent('esx:onPlayerDeath', function(data)
    local victim = source
    local killer = data and data.killerServerId
    if type(killer) ~= 'number' or killer <= 0 then
        killer = nil
    end
    recordCityKill(killer, victim)
end)

RegisterNetEvent('baseevents:onPlayerKilled', function(killerId)
    local victim = source
    local killer = tonumber(killerId)
    if not killer or killer <= 0 then return end
    recordCityKill(killer, victim)
end)

-- ── Leaderboard getters ────────────────────────────────────────────────────

local function buildTurfBoard()
    local list = {}
    for _, data in pairs(CACHE.turf) do
        if (data.claims or 0) > 0 then
            list[#list + 1] = data
        end
    end
    table.sort(list, function(a, b) return (a.claims or 0) > (b.claims or 0) end)

    local rows = {}
    for i = 1, math.min(50, #list) do
        local data = list[i]
        rows[#rows + 1] = {
            rank = i,
            name = data.label or data.gang,
            gang = data.gang,
            claims = data.claims or 0,
            score = ('%d claims'):format(data.claims or 0),
            subtitle = 'Turf wins',
        }
    end
    return { ok = true, rows = rows, mine = nil }
end

lib.callback.register('cfx-keydi-ipad:leaderboard:turfwar', function()
    return buildTurfBoard()
end)

lib.callback.register('cfx-keydi-ipad:leaderboard:traphouse', function(source)
    return buildKdBoard(CACHE.trap, source, 50)
end)

lib.callback.register('cfx-keydi-ipad:leaderboard:party', function(source)
    local list = {}
    for _, data in pairs(CACHE.party) do
        if (data.kills or 0) > 0 or (data.deaths or 0) > 0 then
            list[#list + 1] = data
        end
    end
    table.sort(list, function(a, b)
        if (a.kills or 0) == (b.kills or 0) then
            return Kd(a.kills, a.deaths) > Kd(b.kills, b.deaths)
        end
        return (a.kills or 0) > (b.kills or 0)
    end)

    local myParty = playerParty(source)
    local rows = {}
    local mine = nil
    for i = 1, math.min(50, #list) do
        local data = list[i]
        local row = {
            rank = i,
            name = data.name or ('Party #' .. tostring(data.id)),
            gang = 'Party team',
            kills = data.kills or 0,
            deaths = data.deaths or 0,
            kd = Kd(data.kills, data.deaths),
            score = ('%d K / %d D'):format(data.kills or 0, data.deaths or 0),
            subtitle = ('Team KDA %.2f'):format(Kd(data.kills, data.deaths)),
        }
        rows[#rows + 1] = row
        if myParty and myParty.id == data.id then
            mine = row
        end
    end

    if myParty and not mine then
        local data = CACHE.party[myParty.id]
        if data then
            mine = {
                rank = nil,
                name = data.name,
                kills = data.kills or 0,
                deaths = data.deaths or 0,
                kd = Kd(data.kills, data.deaths),
                score = ('%d K / %d D'):format(data.kills or 0, data.deaths or 0),
                subtitle = ('Team KDA %.2f'):format(Kd(data.kills, data.deaths)),
            }
        end
    end

    return { ok = true, rows = rows, mine = mine }
end)

lib.callback.register('cfx-keydi-ipad:leaderboard:topplayer', function(source)
    return buildKdBoard(CACHE.players, source, 50)
end)

MySQL.ready(function()
    ensureTables()
    loadCache()
end)
