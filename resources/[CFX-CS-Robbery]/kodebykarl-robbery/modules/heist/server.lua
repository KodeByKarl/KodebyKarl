local BigHeist = {
    lastRobbed = {},
    onGoing = {},
    Player = {},
    activeKey = nil, -- only one heist at a time city-wide
}

local SCOREBOARD = 'kodebykarl-ui'

local function scoreboardExport()
    if GetResourceState(SCOREBOARD) ~= 'started' then
        return nil
    end
    return exports[SCOREBOARD]
end

--- police vs sheriff from heist require / dispatch
local function getHeistJob(config)
    if config.require then
        if config.require.sheriff ~= nil then
            return 'sheriff'
        end
        if config.require.police ~= nil then
            return 'police'
        end
    end
    if config.dispatch and type(config.dispatch.jobs) == 'table' then
        for i = 1, #config.dispatch.jobs do
            if config.dispatch.jobs[i] == 'sheriff' then
                return 'sheriff'
            end
        end
    end
    return 'police'
end

local function getPriorityStatus(job)
    local sb = scoreboardExport()
    if not sb then
        return 'Safe'
    end
    local ok, status = pcall(function()
        return sb:GetPriorityStatus(job)
    end)
    if ok and type(status) == 'string' then
        return status
    end
    return 'Safe'
end

local function setPriorityStatus(job, status)
    local sb = scoreboardExport()
    if not sb then return end
    pcall(function()
        sb:SetPriorityStatus(job, status)
    end)
end

local function addActiveRobbery(key, config)
    local sb = scoreboardExport()
    if not sb then return end
    pcall(function()
        sb:AddActiveRobbery(key, {
            name = config.label,
            location = config.label,
            timer = config.timer,
            sticky = true,
        })
    end)
end

local function removeActiveRobbery(key)
    local sb = scoreboardExport()
    if not sb then return end
    pcall(function()
        sb:RemoveActiveRobbery(key)
    end)
end

local function checkLawEnforcement(requireTable)
    local sb = scoreboardExport()
    if not sb or type(requireTable) ~= 'table' then
        return { enable = true, count = 0, name = '' }
    end
    local ok, result = pcall(function()
        return sb:CheckLawEnforcementByTable(requireTable)
    end)
    if ok and type(result) == 'table' then
        return result
    end
    return { enable = true, count = 0, name = '' }
end

local function getHeistDispatchCoords(config)
    if config.ped and config.ped.coords then
        local c = config.ped.coords
        return { x = c.x + 0.0, y = c.y + 0.0, z = (c.z or 0.0) + 0.0 }
    end
    if config.marker and config.marker.coords then
        local c = config.marker.coords
        return { x = c.x + 0.0, y = c.y + 0.0, z = (c.z or 0.0) + 0.0 }
    end
    return nil
end

--- Alert LEO jobs with 10-90 text + map blip (replaces old cd_dispatch).
local function notifyDispatch(jobs, message, duration, coords, label)
    if type(jobs) ~= 'table' or #jobs == 0 or type(message) ~= 'string' or message == '' then
        return
    end
    duration = duration or 14000
    local sendDispatch = type(ESX.SendDispatch) == 'function'
    if sendDispatch then
        ESX.SendDispatch(jobs, message, duration)
    end
    local payload = {
        message = message,
        duration = duration,
        showNotify = true,
        label = label or 'Robbery',
        coords = coords,
        sprite = 161,
        color = 1,
        scale = 1.2,
        radius = 55.0,
        time = 180000,
    }
    for i = 1, #jobs do
        local players = ESX.GetExtendedPlayers('job', jobs[i])
        for j = 1, #players do
            TriggerClientEvent('cfx-cs-robbery:heist:client:dispatchAlert', players[j].source, payload)
        end
    end
end

local function notifyHeistPriorityTemplate(job)
    local message = 'A priority call is in progress. Please do not interfere, otherwise you will be kicked. All calls are on hold until this one concludes.'
    local chatRes = GetResourceState('kodebykarl-ui') == 'started' and 'kodebykarl-ui'
        or (GetResourceState('cfx-cs-chat') == 'started' and 'cfx-cs-chat' or nil)
    if not chatRes then return end
    pcall(function()
        exports[chatRes]:JobTemplateWithoutID(job, message)
    end)
end

local function anyPriorityInProgress()
    local p = getPriorityStatus('police')
    local s = getPriorityStatus('sheriff')
    return p == 'In Progress' or s == 'In Progress'
end

local function clearHeistState(key, config)
    if config.marker then
        GlobalState:set(key, false, true)
    end
    if config.settings and config.settings.autoBlip then
        GlobalState:set(key .. '_blip', false, true)
    end
    if config.settings and config.settings.autoAnnounce then
        GlobalState:set(key .. '_notify', false, true)
    end
    if config.debug and config.debug.enable then
        GlobalState:set(key .. '_debug', false, true)
    end
end

local function endRobberyPriority(key, config)
    removeActiveRobbery(key)
    if BigHeist.activeKey == key then
        BigHeist.activeKey = nil
    end
    local job = getHeistJob(config)
    -- Cooldown → auto Safe after ConfigScoreboard.PriorityCooldownSeconds
    setPriorityStatus(job, 'Cooldown')
end

local function hasAnyOngoing()
    if BigHeist.activeKey then
        return true
    end
    for _, ongoing in pairs(BigHeist.onGoing) do
        if ongoing then
            return true
        end
    end
    return false
end

CreateThread(function()
    for heist, value in pairs(Config.Heist) do
        if value.marker then
            GlobalState[heist] = false
        end
    end
end)

RegisterNetEvent('cfx-cs-robbery:StartTimer', function(key)
    local src = source
    local config = Config.Heist[key]
    if not config then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local near = (config.ped and #(xPlayer.getCoords(true) - config.ped.coords.xyz) <= 5)
        or (config.marker and #(xPlayer.getCoords(true) - config.marker.coords) <= 5)
    if not near then return end

    -- Re-validate gates server-side (anti-cheat / race)
    if hasAnyOngoing() then
        TriggerClientEvent('esx:Notify', src, 'ROBBERY', 'Another robbery is already in progress.', 'error', 5000)
        return
    end
    if anyPriorityInProgress() then
        TriggerClientEvent('esx:Notify', src, 'ROBBERY', 'Priority is In Progress — wait until Safe.', 'error', 5000)
        return
    end
    local job = getHeistJob(config)
    if getPriorityStatus(job) ~= 'Safe' then
        TriggerClientEvent('esx:Notify', src, 'ROBBERY', ('%s must be Safe to start this robbery.'):format(job == 'sheriff' and 'Sheriff' or 'Police'), 'error', 5000)
        return
    end
    if config.require and next(config.require) then
        local le = checkLawEnforcement(config.require)
        if not le.enable then
            TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, ('There must be at least %s %s in town to rob.'):format(le.count, le.name), 'error', 5000)
            return
        end
    end

    if BigHeist.onGoing[key] then return end
    if BigHeist.Player[src] then return end

    -- Per-heist cooldown (server-side)
    if BigHeist.lastRobbed[key] ~= nil and (os.time() - config.reset) < BigHeist.lastRobbed[key] then
        TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, ('%s was recently robbed. Please wait %s seconds.'):format(config.label, (config.reset - (os.time() - BigHeist.lastRobbed[key]))), 'error', 5000)
        return
    end

    if config.requireItem and next(config.requireItem) then
        for itemName, need in pairs(config.requireItem) do
            local have = ox_inventory:GetItemCount(src, itemName) or 0
            if have < need then
                TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, 'Missing required items.', 'error', 5000)
                return
            end
        end
        for itemName, need in pairs(config.requireItem) do
            if not ox_inventory:RemoveItem(src, itemName, need) then
                TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, 'Could not remove required items.', 'error', 5000)
                return
            end
        end
    end

    BigHeist.onGoing[key] = true
    BigHeist.activeKey = key

    -- Scoreboard: In Progress + active robbery row
    setPriorityStatus(job, 'InProgress')
    addActiveRobbery(key, config)

    if config.settings and config.settings.autoTemplate then
        notifyHeistPriorityTemplate(job)
    end

    if config.marker then
        GlobalState:set(key, true, true)
    end

    if config.settings and config.settings.autoBlip then
        GlobalState:set(key .. '_blip', true, true)
    end

    if config.settings and config.settings.autoAnnounce then
        GlobalState:set(key .. '_notify', true, true)
    end

    if config.debug and config.debug.enable then
        GlobalState:set(key .. '_debug', true, true)
    end

    -- Alert LEO for this heist's department (sheriff = Sandy/Paleto/Blaine, police = LS).
    if not config.dispatch or config.dispatch.enable ~= false then
        local dispatchJobs = (config.dispatch and type(config.dispatch.jobs) == 'table' and #config.dispatch.jobs > 0)
            and config.dispatch.jobs
            or { job }
        local coords = getHeistDispatchCoords(config)
        notifyDispatch(dispatchJobs, ('10-90 - %s'):format(config.label), 14000, coords, config.label)
    end

    BigHeist.lastRobbed[key] = os.time()

    lib.logger(src, 'robbery_' .. key, xPlayer.name .. ' started ' .. config.label)

    TriggerClientEvent('esx:Notify', xPlayer.source, 'ROBBERY - ' .. config.label, 'You started ' .. config.label, 'warning', 10000)
    TriggerClientEvent('cfx-cs-robbery:SyncTimer', xPlayer.source, key)

    BigHeist.Player[xPlayer.source] = ESX.SetTimeout(config.timer * 1000, function()
        -- Left the zone / cancelled: do not pay after the countdown
        if not BigHeist.onGoing[key] or BigHeist.activeKey ~= key or not BigHeist.Player[src] then
            return
        end

        BigHeist.Player[src] = nil
        BigHeist.onGoing[key] = nil
        clearHeistState(key, config)
        endRobberyPriority(key, config)

        local stillOnline = GetPlayerPed(src) ~= 0
        local player = ESX.GetPlayerFromId(src)
        if stillOnline and player then
            TriggerClientEvent('cfx-cs-robbery:DestroyClient', src, key)
            if config.rewards and next(config.rewards) then
                local receivedItem = {}
                for i = 1, #config.rewards do
                    local itemData = config.rewards[i]
                    local amount = math.random(itemData.min, itemData.max)
                    if amount > 0 and ox_inventory:CanCarryItem(src, itemData.item, amount) then
                        ox_inventory:AddItem(src, itemData.item, amount)
                        local label = (ox_items[itemData.item] and ox_items[itemData.item].label) or itemData.item
                        table.insert(receivedItem, ESX.Math.GroupDigits(amount) .. 'x ' .. label)
                    end
                end
                if #receivedItem > 0 then
                    lib.logger(src, 'robbery_' .. key, player.name .. ' [' .. src .. '] received ' .. table.concat(receivedItem, ', ') .. ' in ' .. config.label)
                end
            end
        end
    end)
end)

RegisterNetEvent('cfx-cs-robbery:DestroyServer', function(key)
    local src = source
    local config = Config.Heist[key]
    if not config then return end

    if BigHeist.Player[src] and BigHeist.onGoing[key] then
        ESX.ClearTimeout(BigHeist.Player[src])
        BigHeist.Player[src] = nil
        BigHeist.onGoing[key] = nil
        clearHeistState(key, config)
        endRobberyPriority(key, config)
        TriggerClientEvent('cfx-cs-robbery:DestroyClient', src, key)
        TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, config.label .. ' has been cancelled.', 'warning', 10000)
    end
end)

lib.callback.register('cfx-cs-robbery:check', function(source, key)
    local src = source
    local config = Config.Heist[key]
    if not config then
        return false
    end

    if GetResourceState('kodebykarl-ui') == 'started' then
        local ok, allowed = pcall(function()
            return exports['kodebykarl-ui']:PlayerHasFunction(src, 'illegal')
        end)
        if not ok or not allowed then
            local msg = 'Store robberies are only available on Region 1. Open Control Center (F5) → Regions.'
            local mok, text = pcall(function()
                return exports['kodebykarl-ui']:WrongServerMessage('illegal')
            end)
            if mok and type(text) == 'string' and text ~= '' then
                msg = text
            end
            TriggerClientEvent('esx:Notify', src, 'ROBBERY', msg, 'error', 5000)
            return false
        end
    end

    -- 1 robbery at a time (any heist)
    if hasAnyOngoing() then
        local activeLabel = (BigHeist.activeKey and Config.Heist[BigHeist.activeKey] and Config.Heist[BigHeist.activeKey].label) or 'another location'
        TriggerClientEvent('esx:Notify', src, 'ROBBERY', ('A robbery is already in progress (%s).'):format(activeLabel), 'error', 5000)
        return false
    end

    if anyPriorityInProgress() then
        TriggerClientEvent('esx:Notify', src, 'ROBBERY', 'Priority is In Progress — wait until Safe.', 'error', 5000)
        return false
    end

    local job = getHeistJob(config)
    local status = getPriorityStatus(job)
    if status ~= 'Safe' then
        local dept = job == 'sheriff' and 'Sheriff' or 'Police'
        TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, ('%s status is %s. Wait until Safe.'):format(dept, status), 'error', 6000)
        return false
    end

    if config.require and next(config.require) then
        local le = checkLawEnforcement(config.require)
        if not le.enable then
            TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, ('There must be at least %s %s in town to rob.'):format(le.count, le.name), 'error', 5000)
            return false
        end
    end

    if BigHeist.onGoing[key] then
        TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, config.label .. ' is currently being robbed.', 'error', 5000)
        return false
    end

    if BigHeist.lastRobbed[key] ~= nil and (os.time() - config.reset) < BigHeist.lastRobbed[key] then
        TriggerClientEvent('esx:Notify', src, 'ROBBERY - ' .. config.label, ('%s was recently robbed. Please wait %s seconds.'):format(config.label, (config.reset - (os.time() - BigHeist.lastRobbed[key]))), 'error', 5000)
        return false
    end

    return true
end)
