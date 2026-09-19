local Config = require 'configs.massimpound'

local Vote = nil
local lastRequestAt = 0

local NOTIFY_ID = 'massimpound_vote'
local TITLE = Config.NotifyTitle or 'MASS IMPOUND'

--- ox_lib only — no chat:addMessage
local function notifyPlayer(src, data)
    data = data or {}
    data.title = data.title or TITLE
    data.position = data.position or 'top-right'
    TriggerClientEvent('ox_lib:notify', src, data)
end

local function notifyAll(data)
    data = data or {}
    data.title = data.title or TITLE
    data.position = data.position or 'top-right'
    TriggerClientEvent('ox_lib:notify', -1, data)
end

--- Shared live tally card (same id = replaces instead of stacking)
local function pushTallyNotify(description, nType, duration)
    notifyAll({
        id = NOTIFY_ID,
        description = description,
        type = nType or 'inform',
        duration = duration or 10000,
        showDuration = false,
    })
end

local function normalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    return string.upper((plate:gsub('%s+', '')))
end

local function occupiedPlates()
    local occupied = {}
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped ~= 0 then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                local plate = normalizePlate(GetVehicleNumberPlateText(veh) or '')
                if plate ~= '' then occupied[plate] = true end
            end
        end
    end
    return occupied
end

--- Mark owned cars as stored and repaired. JG garage shows "left out" when in_garage ~= 1,
--- and take-out spawned wrecks when engine/body/damage were left at destroyed values.
local function returnPlateToGarage(plate)
    plate = normalizePlate(plate)
    if plate == '' then return false end

    if GetResourceState('jg-advancedgarages') == 'started' then
        local ok, result = pcall(function()
            return exports['jg-advancedgarages']:returnUnoccupiedVehicleToGarage(plate, true)
        end)
        if ok and result then
            return true
        end
    end

    local ok, affected = pcall(function()
        return MySQL.update.await(
            [[UPDATE owned_vehicles
              SET in_garage = 1,
                  stored = 1,
                  engine = 1000,
                  body = 1000,
                  damage = NULL,
                  garage_id = COALESCE(NULLIF(garage_id, ''), 'Legion Square')
              WHERE REPLACE(UPPER(plate), ' ', '') = ?
                AND (impound IS NULL OR impound = 0)]],
            { plate }
        )
    end)

    return ok and (affected or 0) >= 0
end

local function clearGarageOutsidePlate(plate)
    if GetResourceState('jg-advancedgarages') ~= 'started' then return end
    plate = normalizePlate(plate)
    if plate == '' then return end

    pcall(function()
        exports['jg-advancedgarages']:deleteOutsideVehicle(plate)
    end)
end

local function parseVote(message)
    if type(message) ~= 'string' then return nil end
    local msg = message:lower():gsub('^%s+', ''):gsub('%s+$', '')
    if msg == 'yes' or msg == 'y' then return 'yes' end
    if msg == 'no' or msg == 'n' then return 'no' end
    return nil
end

local function isVehicleOccupied(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return true end

    for seat = -1, 16 do
        local ped = GetPedInVehicleSeat(veh, seat)
        if ped and ped ~= 0 then
            return true
        end
    end

    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped ~= 0 and DoesEntityExist(ped) and GetVehiclePedIsIn(ped, false) == veh then
            return true
        end
    end

    return false
end

local function storeAndDeleteVehicle(veh, skipOccupied)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return false end
    if isVehicleOccupied(veh) then return false end

    local plate = normalizePlate(GetVehicleNumberPlateText(veh) or '')
    if skipOccupied and plate ~= '' and skipOccupied[plate] then
        return false
    end

    if plate ~= '' then
        returnPlateToGarage(plate)
        clearGarageOutsidePlate(plate)
        pcall(function()
            MySQL.update.await(
                "UPDATE owned_vehicles SET stored = 1 WHERE REPLACE(UPPER(plate), ' ', '') = ?",
                { plate }
            )
        end)
    end

    if DoesEntityExist(veh) and not isVehicleOccupied(veh) then
        DeleteEntity(veh)
    end

    return true
end

--- Also return leftover "left out" rows that have no spawned entity
--- (streamed-out / already deleted cars still show as left out in JG garage).
local function returnUnoccupiedLeftOutVehicles(occupied)
    occupied = occupied or occupiedPlates()
    local rows = 0

    local ok, result = pcall(function()
        return MySQL.query.await(
            [[SELECT plate FROM owned_vehicles
              WHERE (in_garage IS NULL OR in_garage = 0)
                AND (impound IS NULL OR impound = 0)]]
        )
    end)

    if ok and type(result) == 'table' then
        for i = 1, #result do
            local plate = normalizePlate(result[i] and result[i].plate or '')
            if plate ~= '' and not occupied[plate] then
                if returnPlateToGarage(plate) then
                    rows = rows + 1
                end
            end
        end
    end

    -- Catch anything the SELECT missed (boolean/string in_garage values),
    -- but never mark a car that's currently being driven as stored.
    pcall(function()
        local occupiedList = {}
        for plate in pairs(occupied) do
            occupiedList[#occupiedList + 1] = plate
        end

        local sql = [[UPDATE owned_vehicles
              SET in_garage = 1,
                  stored = 1,
                  engine = 1000,
                  body = 1000,
                  damage = NULL,
                  garage_id = COALESCE(NULLIF(garage_id, ''), 'Legion Square')
              WHERE (in_garage IS NULL OR in_garage = 0)
                AND (impound IS NULL OR impound = 0)]]
        local params = {}

        if #occupiedList > 0 then
            local placeholders = {}
            for i = 1, #occupiedList do
                placeholders[i] = '?'
                params[i] = occupiedList[i]
            end
            sql = sql .. (' AND REPLACE(UPPER(plate), \' \', \'\') NOT IN (%s)'):format(table.concat(placeholders, ','))
        end

        local extra = MySQL.update.await(sql, params)
        if type(extra) == 'number' and extra > rows then
            rows = extra
        end
    end)

    return rows
end

local function runMassImpound()
    local occupied = occupiedPlates()
    local deleted = 0
    local vehicles = GetAllVehicles()
    for i = 1, #vehicles do
        local veh = vehicles[i]
        if storeAndDeleteVehicle(veh, occupied) then
            deleted = deleted + 1
        end
    end

    local returned = returnUnoccupiedLeftOutVehicles(occupied)
    return deleted, returned
end

local function tally()
    local yes, no = 0, 0
    if not Vote then return 0, 0 end
    for _, choice in pairs(Vote.votes) do
        if choice == 'yes' then
            yes = yes + 1
        elseif choice == 'no' then
            no = no + 1
        end
    end
    return yes, no
end

local function remainingMs()
    if not Vote or not Vote.endsAt then return 8000 end
    local left = math.max(1, Vote.endsAt - os.time())
    return left * 1000
end

local function publishVoteCard()
    if not Vote or Vote.phase ~= 'voting' then return end
    local yes, no = tally()
    local left = math.max(0, Vote.endsAt - os.time())
    pushTallyNotify(
        ('Mass impound vote — type /yes or /no\nYES %s  |  NO %s\n%ss left · majority wins'):format(yes, no, left),
        'warning',
        remainingMs()
    )
end

local function endVote()
    if not Vote or Vote.phase ~= 'voting' then return end
    Vote.phase = 'result'

    local yes, no = tally()
    local yesWins = yes > no

    pushTallyNotify(
        ('Vote closed — YES %s  |  NO %s'):format(yes, no),
        yesWins and 'success' or 'error',
        8000
    )

    if not yesWins then
        SetTimeout(400, function()
            pushTallyNotify('Mass impound cancelled. Majority voted NO (or tie).', 'error', 8000)
        end)
        Vote = nil
        return
    end

    local delay = math.max(5, tonumber(Config.ImpoundDelaySeconds) or 120)
    Vote.phase = 'countdown'
    Vote.impoundAt = os.time() + delay

    SetTimeout(400, function()
        pushTallyNotify(
            ('YES wins. Empty vehicles return to garage in %ss.\nGet in your car or store it.'):format(delay),
            'success',
            12000
        )
    end)

    CreateThread(function()
        local warned = {}
        while Vote and Vote.phase == 'countdown' do
            local left = Vote.impoundAt - os.time()
            if left <= 0 then break end
            if (left == 60 or left == 30 or left == 10) and not warned[left] then
                warned[left] = true
                pushTallyNotify(
                    ('Mass impound in %ss.\nEmpty cars will be deleted and sent to garage.'):format(left),
                    'warning',
                    7000
                )
            end
            Wait(1000)
        end

        if not Vote or Vote.phase ~= 'countdown' then return end
        Vote.phase = 'running'
        local deleted, returned = runMassImpound()
        pushTallyNotify(
            ('Mass impound complete.\n%s empty vehicle(s) deleted.\n%s left-out vehicle(s) returned to garage.'):format(
                deleted or 0,
                returned or 0
            ),
            'success',
            10000
        )
        Vote = nil
    end)
end

local function startVote(src)
    local now = os.time()
    local cooldown = tonumber(Config.CommandCooldown) or 600
    if lastRequestAt > 0 and (now - lastRequestAt) < cooldown then
        local wait = cooldown - (now - lastRequestAt)
        notifyPlayer(src, {
            description = ('Wait %ss before requesting again.'):format(wait),
            type = 'error',
            duration = 5000,
        })
        return
    end

    if Vote then
        notifyPlayer(src, {
            description = 'A mass impound vote is already running.',
            type = 'error',
            duration = 5000,
        })
        return
    end

    local players = GetPlayers()
    local minPlayers = tonumber(Config.MinPlayers) or 1
    if #players < minPlayers then
        notifyPlayer(src, {
            description = ('Need at least %s players online.'):format(minPlayers),
            type = 'error',
            duration = 5000,
        })
        return
    end

    lastRequestAt = now
    local duration = math.max(10, tonumber(Config.VoteSeconds) or 45)

    Vote = {
        phase = 'voting',
        requester = src,
        votes = {},
        endsAt = now + duration,
    }

    -- Anonymous start + live tally card (no player names)
    pushTallyNotify(
        ('Mass impound vote started — type /yes or /no\nYES 0  |  NO 0\n%ss left · majority wins'):format(duration),
        'warning',
        duration * 1000
    )

    CreateThread(function()
        while Vote and Vote.phase == 'voting' do
            Wait(5000)
            if Vote and Vote.phase == 'voting' then
                publishVoteCard()
            end
        end
    end)

    CreateThread(function()
        Wait(duration * 1000)
        if Vote and Vote.phase == 'voting' then
            endVote()
        end
    end)
end

function IsMassImpoundVoting()
    return Vote ~= nil and Vote.phase == 'voting'
end

exports('IsMassImpoundVoting', IsMassImpoundVoting)

local function tryRecordVote(src, message)
    if not Vote or Vote.phase ~= 'voting' then return false end
    local choice = parseVote(message)
    if not choice then return false end

    if Vote.votes[src] then
        notifyPlayer(src, {
            id = 'massimpound_personal',
            description = ('You already voted %s.'):format(Vote.votes[src]:upper()),
            type = 'error',
            duration = 4000,
        })
        return true
    end

    Vote.votes[src] = choice
    -- Personal confirm only — never broadcast voter name
    notifyPlayer(src, {
        id = 'massimpound_personal',
        description = ('Your vote: %s'):format(choice:upper()),
        type = 'success',
        duration = 3500,
    })
    publishVoteCard()

    local online = #GetPlayers()
    local yes, no = tally()
    if (yes + no) >= online then
        endVote()
    end
    return true
end

AddEventHandler('_cfx-keydi-chat:messageEntered', function(_, _, message)
    tryRecordVote(source, message)
end)

RegisterCommand(Config.Command or 'reqmassimpound', function(source)
    if source == 0 then
        print('[massimpound] Use this command in-game.')
        return
    end
    startVote(source)
end, false)

RegisterCommand('yes', function(source)
    if source == 0 then return end
    if not tryRecordVote(source, 'yes') then
        notifyPlayer(source, {
            description = 'No mass impound vote is open.',
            type = 'error',
            duration = 4000,
        })
    end
end, false)

RegisterCommand('no', function(source)
    if source == 0 then return end
    if not tryRecordVote(source, 'no') then
        notifyPlayer(source, {
            description = 'No mass impound vote is open.',
            type = 'error',
            duration = 4000,
        })
    end
end, false)

----------------------------------------------------------------
-- Auto mass impound (no vote) — starts counting on resource start
----------------------------------------------------------------
local AUTO_NOTIFY_ID = 'massimpound_auto'

local function pushAutoNotify(description, nType, duration)
    notifyAll({
        id = AUTO_NOTIFY_ID,
        description = description,
        type = nType or 'warning',
        duration = duration or 8000,
        showDuration = false,
    })
end

local function isVoteBusy()
    if not Vote then return false end
    return Vote.phase == 'voting'
        or Vote.phase == 'result'
        or Vote.phase == 'countdown'
        or Vote.phase == 'running'
end

local function runAutoMassImpoundCycle()
    local auto = Config.Auto
    if not auto or auto.Enabled == false then return end
    if auto.SkipIfVoteActive ~= false and isVoteBusy() then
        pushAutoNotify(
            'Auto mass impound skipped — a player vote is already running.',
            'inform',
            8000
        )
        return
    end

    local deleted, returned = runMassImpound()
    pushAutoNotify(
        ('Auto mass impound complete.\n%s empty vehicle(s) deleted.\n%s left-out vehicle(s) returned to garage.\nNext run in %s minutes.'):format(
            deleted or 0,
            returned or 0,
            tonumber(auto.IntervalMinutes) or 25
        ),
        'success',
        10000
    )
end

CreateThread(function()
    local auto = Config.Auto
    if not auto or auto.Enabled == false then return end

    local intervalSec = math.max(60, math.floor((tonumber(auto.IntervalMinutes) or 25) * 60))
    local warns = auto.WarnSeconds or { 60, 30, 10 }

    while true do
        local nextAt = os.time() + intervalSec
        local warned = {}

        while os.time() < nextAt do
            local left = nextAt - os.time()
            for i = 1, #warns do
                local w = tonumber(warns[i])
                if w and left == w and not warned[w] then
                    warned[w] = true
                    pushAutoNotify(
                        ('Auto mass impound in %ss.\nEmpty cars will be deleted and sent to garage.'):format(w),
                        'warning',
                        7000
                    )
                end
            end
            Wait(1000)
        end

        runAutoMassImpoundCycle()
    end
end)
