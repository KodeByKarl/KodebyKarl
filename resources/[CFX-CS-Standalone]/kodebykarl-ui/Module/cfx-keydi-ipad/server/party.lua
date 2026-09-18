local ESX = exports['es_extended']:getSharedObject()

local MAX = (ConfigIpad.Party and ConfigIpad.Party.MaxMembers) or 4
local Parties = {}
local ByIdentifier = {}
local Live = {} -- identifier -> { src, health, armor }

local function cfg()
    return ConfigIpad.Party or {}
end

local function playerName(xPlayer, src)
    if xPlayer and xPlayer.getName then
        local n = xPlayer.getName()
        if n and n ~= '' then return n end
    end
    return GetPlayerName(src) or 'Player'
end

local function identifierOf(xPlayer)
    if not xPlayer then return nil end
    return xPlayer.identifier or (xPlayer.getIdentifier and xPlayer.getIdentifier())
end

local function getX(src)
    return ESX.GetPlayerFromId(src)
end

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_parties` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(32) NOT NULL,
            `leader_identifier` VARCHAR(72) NOT NULL,
            `password` VARCHAR(32) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_grim_parties_leader` (`leader_identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_party_members` (
            `party_id` INT NOT NULL,
            `identifier` VARCHAR(72) NOT NULL,
            `name` VARCHAR(64) NOT NULL DEFAULT '',
            `is_leader` TINYINT(1) NOT NULL DEFAULT 0,
            `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`),
            INDEX `idx_grim_party_members_party` (`party_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

local function loadParties()
    Parties = {}
    ByIdentifier = {}
    local rows = MySQL.query.await('SELECT id, name, leader_identifier, password FROM grim_parties', {}) or {}
    for i = 1, #rows do
        local r = rows[i]
        Parties[r.id] = {
            id = r.id,
            name = r.name,
            leader = r.leader_identifier,
            password = (r.password and r.password ~= '') and r.password or nil,
            members = {},
        }
    end
    local members = MySQL.query.await(
        'SELECT party_id, identifier, name, is_leader FROM grim_party_members ORDER BY is_leader DESC, joined_at ASC',
        {}
    ) or {}
    for i = 1, #members do
        local m = members[i]
        local p = Parties[m.party_id]
        if p then
            p.members[#p.members + 1] = {
                identifier = m.identifier,
                name = m.name or 'Player',
                leader = m.is_leader == 1 or m.is_leader == true,
            }
            ByIdentifier[m.identifier] = m.party_id
        end
    end
end

local function partyOfIdentifier(identifier)
    local id = ByIdentifier[identifier]
    if not id then return nil end
    return Parties[id]
end

local function findMember(party, identifier)
    for i = 1, #party.members do
        if party.members[i].identifier == identifier then
            return party.members[i], i
        end
    end
    return nil, nil
end

local function hudPayload(party)
    if not party then
        return { visible = false, members = {}, count = 0, max = MAX, name = '' }
    end
    local list = {}
    for i = 1, #party.members do
        local m = party.members[i]
        local live = Live[m.identifier]
        list[#list + 1] = {
            slot = i,
            name = m.name,
            leader = m.leader == true,
            online = live ~= nil,
            serverId = live and live.src or nil,
            health = live and live.health or 0,
            armor = live and live.armor or 0,
        }
    end
    return {
        visible = true,
        id = party.id,
        name = party.name,
        count = #party.members,
        max = MAX,
        locked = party.password ~= nil,
        members = list,
    }
end

local function pushHud(party)
    local payload = hudPayload(party)
    if not party then return end
    for i = 1, #party.members do
        local live = Live[party.members[i].identifier]
        if live and live.src then
            TriggerClientEvent('cfx-keydi-ipad:party:hud', live.src, payload)
        end
    end
end

local function hideHud(src)
    TriggerClientEvent('cfx-keydi-ipad:party:hud', src, { visible = false, members = {}, count = 0, max = MAX })
end

local function serializeParty(party, forIdentifier)
    if not party then return nil end
    local members = {}
    for i = 1, #party.members do
        local m = party.members[i]
        local live = Live[m.identifier]
        members[#members + 1] = {
            identifier = m.identifier,
            name = m.name,
            leader = m.leader == true,
            online = live ~= nil,
            serverId = live and live.src or nil,
            you = m.identifier == forIdentifier,
        }
    end
    local you = findMember(party, forIdentifier)
    return {
        id = party.id,
        name = party.name,
        locked = party.password ~= nil,
        count = #party.members,
        max = MAX,
        youLeader = you and you.leader == true or false,
        members = members,
    }
end

local function listParties()
    local out = {}
    for _, party in pairs(Parties) do
        local online = 0
        local leaderName = party.name
        for i = 1, #party.members do
            if Live[party.members[i].identifier] then
                online += 1
            end
            if party.members[i].leader then
                leaderName = party.members[i].name
            end
        end
        out[#out + 1] = {
            id = party.id,
            name = party.name,
            leader = leaderName,
            count = #party.members,
            online = online,
            max = MAX,
            locked = party.password ~= nil,
            full = #party.members >= MAX,
        }
    end
    table.sort(out, function(a, b) return a.id > b.id end)
    return out
end

local function setLive(src, xPlayer)
    local ident = identifierOf(xPlayer)
    if not ident then return end
    Live[ident] = Live[ident] or { src = src, health = 100, armor = 0 }
    Live[ident].src = src
end

local function restore(src, xPlayer)
    local ident = identifierOf(xPlayer)
    if not ident then return end
    setLive(src, xPlayer)
    local party = partyOfIdentifier(ident)
    if not party then
        hideHud(src)
        return
    end
    local member = findMember(party, ident)
    if member then
        member.name = playerName(xPlayer, src)
        MySQL.update.await('UPDATE grim_party_members SET name = ? WHERE identifier = ?', { member.name, ident })
    end
    pushHud(party)
end

CreateThread(function()
    Wait(800)
    pcall(ensureTables)
    pcall(loadParties)
    Wait(700)
    for _, sid in ipairs(GetPlayers()) do
        local src = tonumber(sid)
        local xPlayer = src and getX(src)
        if src and xPlayer then
            restore(src, xPlayer)
        end
    end
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    CreateThread(function()
        Wait(500)
        restore(playerId, xPlayer or getX(playerId))
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local xPlayer = getX(src)
    local ident = xPlayer and identifierOf(xPlayer)
    if not ident then
        for id, live in pairs(Live) do
            if live.src == src then
                ident = id
                break
            end
        end
    end
    if not ident then return end
    Live[ident] = nil
    local party = partyOfIdentifier(ident)
    if party then
        pushHud(party)
    end
end)

lib.callback.register('cfx-keydi-ipad:party:state', function(src)
    local xPlayer = getX(src)
    if not xPlayer then return { ok = false, list = {}, mine = nil } end
    setLive(src, xPlayer)
    local ident = identifierOf(xPlayer)
    local party = ident and partyOfIdentifier(ident)
    if party then
        pushHud(party)
    end
    return {
        ok = true,
        max = MAX,
        list = listParties(),
        mine = serializeParty(party, ident),
    }
end)

lib.callback.register('cfx-keydi-ipad:party:create', function(src, data)
    local xPlayer = getX(src)
    if not xPlayer then return { ok = false, error = 'Not loaded.' } end
    local ident = identifierOf(xPlayer)
    if not ident then return { ok = false, error = 'No identifier.' } end
    if partyOfIdentifier(ident) then
        return { ok = false, error = 'Leave your current party first.' }
    end

    data = type(data) == 'table' and data or {}
    local name = tostring(data.name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local minLen = cfg().MinNameLength or 3
    local maxLen = cfg().MaxNameLength or 24
    if #name < minLen then
        name = (playerName(xPlayer, src) .. "'s Team"):sub(1, maxLen)
    end
    if #name > maxLen then name = name:sub(1, maxLen) end

    local password = tostring(data.password or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if password == '' then password = nil end
    local maxPw = cfg().MaxPasswordLength or 16
    if password and #password > maxPw then
        return { ok = false, error = ('Password max %d characters.'):format(maxPw) }
    end

    local insertId = MySQL.insert.await(
        'INSERT INTO grim_parties (name, leader_identifier, password) VALUES (?, ?, ?)',
        { name, ident, password }
    )
    if not insertId then return { ok = false, error = 'Could not create party.' } end

    MySQL.insert.await(
        'INSERT INTO grim_party_members (party_id, identifier, name, is_leader) VALUES (?, ?, ?, 1)',
        { insertId, ident, playerName(xPlayer, src) }
    )

    Parties[insertId] = {
        id = insertId,
        name = name,
        leader = ident,
        password = password,
        members = {
            { identifier = ident, name = playerName(xPlayer, src), leader = true },
        },
    }
    ByIdentifier[ident] = insertId
    setLive(src, xPlayer)
    pushHud(Parties[insertId])

    return { ok = true, mine = serializeParty(Parties[insertId], ident), list = listParties() }
end)

lib.callback.register('cfx-keydi-ipad:party:join', function(src, data)
    local xPlayer = getX(src)
    if not xPlayer then return { ok = false, error = 'Not loaded.' } end
    local ident = identifierOf(xPlayer)
    if not ident then return { ok = false, error = 'No identifier.' } end
    if partyOfIdentifier(ident) then
        return { ok = false, error = 'Leave your current party first.' }
    end

    data = type(data) == 'table' and data or {}
    local partyId = tonumber(data.id)
    local party = partyId and Parties[partyId]
    if not party then return { ok = false, error = 'Party not found.' } end
    if #party.members >= MAX then return { ok = false, error = 'Party is full (4/4).' } end
    if party.password then
        local pw = tostring(data.password or '')
        if pw ~= party.password then
            return { ok = false, error = 'Wrong password.' }
        end
    end

    MySQL.insert.await(
        'INSERT INTO grim_party_members (party_id, identifier, name, is_leader) VALUES (?, ?, ?, 0)',
        { party.id, ident, playerName(xPlayer, src) }
    )
    party.members[#party.members + 1] = {
        identifier = ident,
        name = playerName(xPlayer, src),
        leader = false,
    }
    ByIdentifier[ident] = party.id
    setLive(src, xPlayer)
    pushHud(party)
    return { ok = true, mine = serializeParty(party, ident), list = listParties() }
end)

local function promoteFirst(party)
    if #party.members == 0 then return end
    party.members[1].leader = true
    party.leader = party.members[1].identifier
    MySQL.update.await('UPDATE grim_parties SET leader_identifier = ? WHERE id = ?', { party.leader, party.id })
    MySQL.update.await('UPDATE grim_party_members SET is_leader = 1 WHERE identifier = ?', { party.leader })
end

local function deleteParty(party)
    local id = party.id
    for i = 1, #party.members do
        local m = party.members[i]
        ByIdentifier[m.identifier] = nil
        local live = Live[m.identifier]
        if live and live.src then
            hideHud(live.src)
        end
    end
    Parties[id] = nil
    MySQL.query.await('DELETE FROM grim_party_members WHERE party_id = ?', { id })
    MySQL.query.await('DELETE FROM grim_parties WHERE id = ?', { id })
end

local function removeMember(party, identifier, dissolveIfEmpty)
    local _, idx = findMember(party, identifier)
    if not idx then return end
    local wasLeader = party.members[idx].leader
    table.remove(party.members, idx)
    ByIdentifier[identifier] = nil
    MySQL.query.await('DELETE FROM grim_party_members WHERE identifier = ?', { identifier })
    local live = Live[identifier]
    if live and live.src then
        hideHud(live.src)
    end
    if #party.members == 0 then
        if dissolveIfEmpty then
            deleteParty(party)
        end
        return
    end
    if wasLeader then
        MySQL.update.await('UPDATE grim_party_members SET is_leader = 0 WHERE party_id = ?', { party.id })
        promoteFirst(party)
    end
    pushHud(party)
end

lib.callback.register('cfx-keydi-ipad:party:leave', function(src)
    local xPlayer = getX(src)
    if not xPlayer then return { ok = false, error = 'Not loaded.' } end
    local ident = identifierOf(xPlayer)
    local party = ident and partyOfIdentifier(ident)
    if not party then return { ok = false, error = 'You are not in a party.' } end
    removeMember(party, ident, true)
    return { ok = true, mine = nil, list = listParties() }
end)

lib.callback.register('cfx-keydi-ipad:party:kick', function(src, data)
    local xPlayer = getX(src)
    if not xPlayer then return { ok = false, error = 'Not loaded.' } end
    local ident = identifierOf(xPlayer)
    local party = ident and partyOfIdentifier(ident)
    if not party then return { ok = false, error = 'You are not in a party.' } end
    local you = findMember(party, ident)
    if not you or not you.leader then return { ok = false, error = 'Only the leader can kick.' } end
    data = type(data) == 'table' and data or {}
    local target = tostring(data.identifier or '')
    if target == '' or target == ident then return { ok = false, error = 'Invalid member.' } end
    if not findMember(party, target) then return { ok = false, error = 'Member not found.' } end
    removeMember(party, target, false)
    return { ok = true, mine = serializeParty(party, ident), list = listParties() }
end)

lib.callback.register('cfx-keydi-ipad:party:disband', function(src)
    local xPlayer = getX(src)
    if not xPlayer then return { ok = false, error = 'Not loaded.' } end
    local ident = identifierOf(xPlayer)
    local party = ident and partyOfIdentifier(ident)
    if not party then return { ok = false, error = 'You are not in a party.' } end
    local you = findMember(party, ident)
    if not you or not you.leader then return { ok = false, error = 'Only the leader can disband.' } end
    deleteParty(party)
    return { ok = true, mine = nil, list = listParties() }
end)

RegisterNetEvent('cfx-keydi-ipad:party:vitals', function(health, armor)
    local src = source
    local xPlayer = getX(src)
    if not xPlayer then return end
    local ident = identifierOf(xPlayer)
    if not ident then return end
    local hp = math.max(0, math.min(100, tonumber(health) or 0))
    local ar = math.max(0, math.min(100, tonumber(armor) or 0))
    local live = Live[ident]
    if not live then
        Live[ident] = { src = src, health = hp, armor = ar }
        live = Live[ident]
    else
        live.src = src
        if live.health == hp and live.armor == ar then return end
        live.health = hp
        live.armor = ar
    end
    local party = partyOfIdentifier(ident)
    if party then
        pushHud(party)
    end
end)

exports('GetPlayerParty', function(src)
    local xPlayer = getX(src)
    local ident = xPlayer and identifierOf(xPlayer)
    return ident and serializeParty(partyOfIdentifier(ident), ident) or nil
end)
