local utils = require 'modules.server.utils'
local prisonJob = require 'configs.prisonjob'
local db = require 'modules.server.db'

-- View Jail Roster --
lib.callback.register('xt-prison:server:getJailRoster', function(source)
    return utils.generateJailRoster()
end)

-- Unjails Player via Roster --
lib.callback.register('xt-prison:server:unjailPlayerByRoster', function(source, targetSource)
    local isCop = utils.isCop(source)
    if not isCop then return false end

    local officer = getPlayer(source)
    local grade = officer and officer.job and (tonumber(officer.job.grade) or 0) or 0
    local gradeName = officer and officer.job and tostring(officer.job.grade_name or ''):lower() or ''
    local canUnjail = grade >= 1 or gradeName == 'boss' or gradeName == 'director' or gradeName == 'chief'
    if not canUnjail then return false end

    local state = Player(targetSource).state
    local stillJailed = state and (state.inJail or (tonumber(state.jailTime) or 0) > 0)
    if stillJailed then
        setJailTime(targetSource, 0)

        lib.notify(targetSource, {
            title = locale('notify.freedom'),
            description = locale('notify.unjailed_by_roster')
        })
        Wait(500)
        local released = lib.callback.await('xt-prison:client:exitJail', targetSource, true)
        if released and PrisonLogs and PrisonLogs.Release then
            PrisonLogs.Release({
                src = source,
                name = getCharName(source),
                identifier = getCharID(source),
                targetSrc = targetSource,
                targetName = getCharName(targetSource),
                targetIdentifier = getCharID(targetSource),
                method = 'roster unjail',
            })
        end
        return released
    end

    return false
end)

local workCooldown = {}

local function getReduceRange()
    local reduce = prisonJob.Welding.reduceTime
    if type(reduce) == 'table' then
        local minCut = math.max(1, math.floor(tonumber(reduce.min) or 1))
        local maxCut = math.max(minCut, math.floor(tonumber(reduce.max) or minCut))
        return minCut, maxCut
    end
    local fixed = math.max(1, math.floor(tonumber(reduce) or 1))
    return fixed, fixed
end

lib.callback.register('xt-prison:server:completeWork', function(source, id)
    local src = source
    local xPlayer = getPlayer(src)
    if not xPlayer then return { ok = false, error = 'invalid' } end

    local location = prisonJob.Welding.locations[id]
    if not location then return { ok = false, error = 'invalid' } end

    local state = Player(src).state
    local jailTime = state and tonumber(state.jailTime) or 0
    if not state or (not state.inJail and jailTime <= 0) then
        return { ok = false, error = 'not_jailed' }
    end

    local cooldown = tonumber(prisonJob.Welding.cooldown) or 0
    local now = os.time()
    if cooldown > 0 then
        local last = workCooldown[src] or 0
        local remain = (last + cooldown) - now
        if remain > 0 then
            return { ok = false, error = 'cooldown', remain = remain }
        end
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return { ok = false, error = 'invalid' } end
    local coords = GetEntityCoords(ped)
    if #(coords - location.coords.xyz) > 8.0 then
        return { ok = false, error = 'range' }
    end

    local minCut, maxCut = getReduceRange()
    local reduced = math.random(minCut, maxCut)
    local jailTime = math.max(0, (tonumber(state.jailTime) or 0) - reduced)
    setJailTime(src, jailTime)
    local cid = getCharID(src)
    if cid then
        MySQL.insert.await(db.UPDATE_JAILTIME, { cid, jailTime })
    end

    local rewards = prisonJob.Welding.rewards or {}
    for i = 1, #rewards do
        local reward = rewards[i]
        if reward and reward.item then
            exports.ox_inventory:AddItem(src, reward.item, reward.count or 1)
        end
    end

    if cooldown > 0 then
        workCooldown[src] = now
    end

    if jailTime <= 0 then
        CreateThread(function()
            Wait(750)
            lib.callback.await('xt-prison:client:exitJail', src, true)
        end)
    end

    return { ok = true, reduced = reduced, jailTime = jailTime }
end)

AddEventHandler('playerDropped', function()
    workCooldown[source] = nil
end)


-- Set Player Jail Time via Roster --
lib.callback.register('xt-prison:server:changePlayerJailTimeByRoster', function(source, targetSource, newTime)
    local isCop = utils.isCop(source)
    if not isCop then return false end

    local state = Player(targetSource).state
    if state and state.jailTime > 0 then
        setJailTime(targetSource, newTime)

        lib.notify(targetSource, {
            title = locale('notify.new_time_by_roster'),
            description = (locale('notify.new_time_by_roster_description')):format(newTime)
        })

        if PrisonLogs and PrisonLogs.Jail then
            PrisonLogs.Jail({
                updated = true,
                src = source,
                name = getCharName(source),
                identifier = getCharID(source),
                targetSrc = targetSource,
                targetName = getCharName(targetSource),
                targetIdentifier = getCharID(targetSource),
                time = newTime,
                method = 'roster time change',
            })
        end
    end

    return state and (state.jailTime == newTime) or false
end)