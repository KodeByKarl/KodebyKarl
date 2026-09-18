local ESX = exports["es_extended"]:getSharedObject()

-- Session playtime tracking & combat reports
local sessionStart = {}
local playerAvatars = {}
local playerKDA = {}

local function GetDiscordBotToken()
    if ConfigScoreboard.DiscordBotToken and ConfigScoreboard.DiscordBotToken ~= "" then
        return ConfigScoreboard.DiscordBotToken
    end
    local convar = GetConvar("kodebykarl_discord_bot_token", "")
    if convar ~= "" then
        return convar
    end
    return nil
end

local function DefaultDiscordAvatar(discordId)
    local last = tonumber(discordId:sub(-1)) or 0
    return ("https://cdn.discordapp.com/embed/avatars/%d.png"):format(last % 5)
end

local function GetPlayerDiscordId(playerId)
    for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
        if string.sub(id, 1, 8) == "discord:" then
            return string.sub(id, 9)
        end
    end
    return nil
end

-- Discord CDN avatar (bot token optional — falls back to default Discord avatar)
local function FetchDiscordAvatar(playerId, cb)
    local discordId = GetPlayerDiscordId(playerId)
    if not discordId then
        return cb(nil)
    end

    local token = GetDiscordBotToken()
    if not token then
        return cb(DefaultDiscordAvatar(discordId))
    end

    PerformHttpRequest("https://discord.com/api/v10/users/" .. discordId, function(statusCode, response)
        if statusCode == 200 and response then
            local data = json.decode(response)
            if data and data.avatar and data.avatar ~= "" then
                local ext = data.avatar:sub(1, 2) == "a_" and "gif" or "png"
                cb(("https://cdn.discordapp.com/avatars/%s/%s.%s?size=128"):format(discordId, data.avatar, ext))
                return
            end
        end
        cb(DefaultDiscordAvatar(discordId))
    end, "GET", "", { ["Authorization"] = "Bot " .. token })
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    sessionStart[xPlayer.identifier] = os.time()
    playerKDA[xPlayer.identifier] = { kills = 0, deaths = 0, kd = "0.00" }
    
    FetchDiscordAvatar(playerId, function(avatarUrl)
        if avatarUrl then
            playerAvatars[xPlayer.identifier] = avatarUrl
        else
            playerAvatars[xPlayer.identifier] = string.format("https://api.dicebear.com/7.x/adventurer/svg?seed=%s", xPlayer.getName())
        end
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        sessionStart[xPlayer.identifier] = nil
        playerAvatars[xPlayer.identifier] = nil
        playerKDA[xPlayer.identifier] = nil
    end
end)

-- Sync Kkills/deaths from client
RegisterNetEvent('cfx-keydi-scoreboard:updateKDA', function(kills, deaths)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local kd = 0.00
        if deaths > 0 then
            kd = kills / deaths
        else
            kd = kills
        end
        playerKDA[xPlayer.identifier] = {
            kills = kills,
            deaths = deaths,
            kd = string.format("%.2f", kd)
        }
    end
end)

-- Initialize join times, KDA records, and avatars for players already loaded (if resource is restarted)
CreateThread(function()
    local players = ESX.GetExtendedPlayers()
    for _, xPlayer in ipairs(players) do
        local identifier = xPlayer.identifier
        if not sessionStart[identifier] then
            sessionStart[identifier] = os.time()
        end
        if not playerKDA[identifier] then
            playerKDA[identifier] = { kills = 0, deaths = 0, kd = "0.00" }
        end
        if not playerAvatars[identifier] then
            FetchDiscordAvatar(xPlayer.source, function(avatarUrl)
                if avatarUrl then
                    playerAvatars[identifier] = avatarUrl
                else
                    playerAvatars[identifier] = string.format("https://api.dicebear.com/7.x/adventurer/svg?seed=%s", xPlayer.getName())
                end
            end)
        end
    end
end)

-- Priority bags used by kodebykarl-robbery
-- Safe = can rob | Hold = blocked | Cooldown = 15m then Safe | In Progress = robbery running
local PRIORITY_BAGS = {
    { bag = 'rb_prio_police', name = 'LS Police', job = 'police' },
    { bag = 'rb_prio_sheriff', name = 'Paleto Sheriff', job = 'sheriff' },
}

local PRIORITY_COOLDOWN = tonumber(ConfigScoreboard.PriorityCooldownSeconds) or (15 * 60)

local priorityStatuses = {
    { name = "LS Police", status = "Safe" },
    { name = "Paleto Sheriff", status = "Safe" },
}

local function normalizePrioKey(status)
    return type(status) == 'string' and status:lower():gsub('%s+', '') or ''
end

local function formatCooldownLeft(seconds)
    local secs = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format('%d:%02d', math.floor(secs / 60), secs % 60)
end

local function cooldownRemaining(state)
    if not state then return 0 end
    if state.cooldownEndsAt then
        return math.max(0, (tonumber(state.cooldownEndsAt) or 0) - os.time())
    end
    return math.max(0, tonumber(state.cooldown) or 0)
end

local function prioUiStatus(state)
    if not state or state.active then
        return 'Safe'
    end
    local status = normalizePrioKey(state.status)
    if status == 'inprogress' then
        return 'In Progress'
    end
    if status == 'cooldown' then
        local left = cooldownRemaining(state)
        if left <= 0 then
            return 'Safe'
        end
        return ('Cooldown (%s)'):format(formatCooldownLeft(left))
    end
    -- Hold (legacy Lockdown / Active map here too)
    if status == 'hold' or status == 'lockdown' or status == 'active' then
        return 'Hold'
    end
    return 'Hold'
end

local function defaultPrioState(job)
    return {
        active = true,
        status = 'safe',
        name = 'SYSTEM',
        job = job,
        cooldown = 0,
        cooldownEndsAt = 0,
    }
end

local function syncPriorityStatuses()
    for i, entry in ipairs(PRIORITY_BAGS) do
        priorityStatuses[i] = {
            name = entry.name,
            status = prioUiStatus(GlobalState[entry.bag])
        }
    end
end

local function ensurePriorityBags()
    for _, entry in ipairs(PRIORITY_BAGS) do
        if GlobalState[entry.bag] == nil then
            GlobalState:set(entry.bag, defaultPrioState(entry.job), true)
        end
    end
    syncPriorityStatuses()
end

CreateThread(function()
    ensurePriorityBags()
end)

-- Auto Safe when Cooldown expires
CreateThread(function()
    while true do
        Wait(1000)
        local changed = false
        for _, entry in ipairs(PRIORITY_BAGS) do
            local state = GlobalState[entry.bag]
            if state and not state.active and normalizePrioKey(state.status) == 'cooldown' then
                if cooldownRemaining(state) <= 0 then
                    GlobalState:set(entry.bag, defaultPrioState(entry.job), true)
                    changed = true
                end
            end
        end
        if changed then
            syncPriorityStatuses()
        end
    end
end)

AddStateBagChangeHandler('rb_prio_police', 'global', function()
    syncPriorityStatuses()
end)

AddStateBagChangeHandler('rb_prio_sheriff', 'global', function()
    syncPriorityStatuses()
end)

-- Default World Events status (loaded from config)
local worldEvents = {}
for _, event in ipairs(ConfigScoreboard.WorldEvents) do
    worldEvents[#worldEvents + 1] = {
        name = event.name,
        location = event.location,
        status = event.status,
        endsAt = 0,
    }
end

-- Active Robberies keyed by heist id
local activeRobberies = {}

local function formatTimeLeft(endsAt)
    local remaining = math.max(0, (endsAt or 0) - os.time())
    return string.format('%d:%02d', math.floor(remaining / 60), remaining % 60)
end

local function getFormattedWorldEvents()
    local list = {}
    for _, event in ipairs(worldEvents) do
        local isActive = tostring(event.status or ''):upper() == 'ACTIVE'
        local timeLeft = nil
        if event.endsAt and event.endsAt > os.time() then
            timeLeft = formatTimeLeft(event.endsAt)
        elseif event.endsAt and event.endsAt > 0 and event.endsAt <= os.time() then
            timeLeft = '0:00'
        end

        -- Location stays location; timer is always timeLeft (shown as status in UI)
        local location = event.location
        if not location or location == '' then
            location = '—'
        end

        list[#list + 1] = {
            name = event.name,
            location = location,
            status = isActive and 'ACTIVE' or 'INACTIVE',
            timeLeft = timeLeft,
        }
    end
    return list
end

local function getFormattedRobberies()
    local list = {}
    for key, rob in pairs(activeRobberies) do
        if not rob.sticky and rob.endsAt and rob.endsAt <= os.time() then
            activeRobberies[key] = nil
        else
            list[#list + 1] = {
                name = rob.name,
                location = rob.location,
                timeLeft = formatTimeLeft(rob.endsAt)
            }
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

local function getJobDisplayName(job)
    for _, jobConf in ipairs(ConfigScoreboard.Jobs) do
        if jobConf.job == job then
            return jobConf.name
        end
    end
    return job
end

local function countJobOnline(job)
    local players = ESX.GetExtendedPlayers('job', job)
    return type(players) == 'table' and #players or 0
end

--- Used by kodebykarl-robbery: { ['police'] = 10 } -> { enable, count, name }
local function CheckLawEnforcementByTable(requireTable)
    if type(requireTable) ~= 'table' then
        return { enable = true, count = 0, name = '' }
    end

    for job, required in pairs(requireTable) do
        local need = tonumber(required) or 0
        if countJobOnline(job) < need then
            return {
                enable = false,
                count = need,
                name = getJobDisplayName(job)
            }
        end
    end

    return { enable = true, count = 0, name = '' }
end

lib.callback.register('cfx-keydi-scoreboard:checkLawEnforcement', function(_, requireTable)
    return CheckLawEnforcementByTable(requireTable)
end)

exports('CheckLawEnforcementByTable', CheckLawEnforcementByTable)

---@param key string heist key
---@param data { name: string, location?: string, timer?: number, endsAt?: number, sticky?: boolean }
local function AddActiveRobbery(key, data)
    if type(key) ~= 'string' or type(data) ~= 'table' then return false end
    local timer = tonumber(data.timer) or 0
    -- sticky by default so the entry stays until RemoveActiveRobbery (heist end)
    local sticky = data.sticky
    if sticky == nil then sticky = true end
    activeRobberies[key] = {
        name = data.name or key,
        location = data.location or 'Unknown',
        endsAt = data.endsAt or (os.time() + math.max(timer, 1)),
        sticky = sticky == true,
    }
    return true
end

local function RemoveActiveRobbery(key)
    if key then
        activeRobberies[key] = nil
    end
end

---@param name string world event name (e.g. "Traphouse")
---@param data { status?: string, location?: string, endsAt?: number, timer?: number, remaining?: number }
local function SetWorldEvent(name, data)
    if type(name) ~= 'string' or name == '' then return false end
    data = type(data) == 'table' and data or {}

    for _, event in ipairs(worldEvents) do
        if event.name:lower() == name:lower() then
            if data.status ~= nil then
                event.status = tostring(data.status):upper()
            end
            if data.location ~= nil then
                event.location = tostring(data.location)
            end

            if data.endsAt ~= nil then
                event.endsAt = tonumber(data.endsAt) or 0
            elseif data.timer ~= nil then
                local t = math.max(tonumber(data.timer) or 0, 0)
                event.endsAt = t > 0 and (os.time() + t) or 0
            elseif data.remaining ~= nil then
                local t = math.max(tonumber(data.remaining) or 0, 0)
                event.endsAt = t > 0 and (os.time() + t) or 0
            end

            return true
        end
    end

    return false
end

---@param job 'police'|'sheriff'|'all'|nil
---@param status 'Safe'|'Hold'|'Cooldown'|'InProgress'|string
local function SetPriorityStatus(job, status)
    local normalized = normalizePrioKey(status)
    if normalized == '' and type(job) == 'string' then
        -- If single argument was passed (e.g. SetPriorityStatus(nil, 'hold') or SetPriorityStatus('hold'))
        local testStatus = normalizePrioKey(job)
        if testStatus == 'safe' or testStatus == 'hold' or testStatus == 'cooldown' or testStatus == 'inprogress' or testStatus == 'lockdown' or testStatus == 'active' then
            normalized = testStatus
            job = 'all'
        end
    end

    -- Legacy aliases
    if normalized == 'lockdown' or normalized == 'active' then
        normalized = 'hold'
    end

    local targetJobs = {}
    if not job or job == 'all' or job == '*' or job == '' then
        targetJobs = { 'police', 'sheriff' }
    elseif job == 'sheriff' or tostring(job):lower():find('sheriff') or tostring(job):lower():find('paleto') then
        targetJobs = { 'sheriff' }
    else
        targetJobs = { 'police' }
    end

    for _, targetJob in ipairs(targetJobs) do
        local bag = targetJob == 'sheriff' and 'rb_prio_sheriff' or 'rb_prio_police'
        local state

        if normalized == 'safe' then
            state = defaultPrioState(targetJob)
        elseif normalized == 'inprogress' then
            state = {
                active = false,
                status = 'inprogress',
                name = 'SYSTEM',
                job = targetJob,
                cooldown = 0,
                cooldownEndsAt = 0,
            }
        elseif normalized == 'cooldown' then
            local endsAt = os.time() + PRIORITY_COOLDOWN
            state = {
                active = false,
                status = 'cooldown',
                name = 'SYSTEM',
                job = targetJob,
                cooldown = PRIORITY_COOLDOWN,
                cooldownEndsAt = endsAt,
            }
        else
            -- Hold (manual block — no auto-expire)
            state = {
                active = false,
                status = 'hold',
                name = 'SYSTEM',
                job = targetJob,
                cooldown = 0,
                cooldownEndsAt = 0,
            }
        end

        GlobalState:set(bag, state, true)
    end

    syncPriorityStatuses()
    return true
end

---@param job 'police'|'sheriff'|nil
---@return string
local function GetPriorityStatus(job)
    local bag = job == 'sheriff' and 'rb_prio_sheriff' or 'rb_prio_police'
    ensurePriorityBags()
    return prioUiStatus(GlobalState[bag])
end

exports('AddActiveRobbery', AddActiveRobbery)
exports('RemoveActiveRobbery', RemoveActiveRobbery)
exports('SetWorldEvent', SetWorldEvent)
exports('SetPriorityStatus', SetPriorityStatus)
exports('GetPriorityStatus', GetPriorityStatus)
exports('GetPlayerKDA', function(identifier)
    if not identifier then return { kills = 0, deaths = 0, kd = "0.00" } end
    return playerKDA[identifier] or { kills = 0, deaths = 0, kd = "0.00" }
end)

-- Server Callback to aggregate scoreboard details
ESX.RegisterServerCallback('cfx-keydi-scoreboard:getServerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    ensurePriorityBags()
    syncPriorityStatuses()

    -- 1. Total playtime (ESX metadata + GetPlayerTimeOnline — same as /playtime / tx session tracking)
    local playSeconds = 0
    if xPlayer.getPlayTime then
        playSeconds = tonumber(xPlayer.getPlayTime()) or 0
    end
    local days = math.floor(playSeconds / 86400)
    local hours = math.floor((playSeconds % 86400) / 3600)
    local mins = math.floor((playSeconds % 3600) / 60)
    local playtimeStr
    if days > 0 then
        playtimeStr = string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        playtimeStr = string.format("%dh %dm", hours, mins)
    else
        playtimeStr = string.format("%dm", math.max(0, mins))
    end

    -- 2. Count jobs
    local jobCounts = {}
    for _, jobConf in ipairs(ConfigScoreboard.Jobs) do
        jobCounts[jobConf.job] = 0
    end

    local players = ESX.GetExtendedPlayers()
    for _, targetPlayer in ipairs(players) do
        local targetJob = targetPlayer.job and targetPlayer.job.name
        if targetJob then
            if jobCounts[targetJob] ~= nil then
                jobCounts[targetJob] = jobCounts[targetJob] + 1
            elseif (targetJob == 'sheriff' or targetJob == 'bcso') and jobCounts['police'] ~= nil then
                jobCounts['police'] = jobCounts['police'] + 1
            end
        end
    end

    -- Format jobs list for UI
    local formattedJobs = {}
    for _, jobConf in ipairs(ConfigScoreboard.Jobs) do
        table.insert(formattedJobs, {
            name = jobConf.name,
            online = jobCounts[jobConf.job] or 0
        })
    end

    local kda = playerKDA[xPlayer.identifier] or { kills = 0, deaths = 0, kd = "0.00" }
    local avatar = playerAvatars[xPlayer.identifier] or string.format("https://api.dicebear.com/7.x/adventurer/svg?seed=%s", xPlayer.getName())

    -- 3. Prepare response
    local serverData = {
        serverName = ConfigScoreboard.ServerName,
        enablePriorityStatus = ConfigScoreboard.EnablePriorityStatus,
        playerDetails = {
            name = xPlayer.getName(),
            ping = GetPlayerPing(source),
            playTime = playtimeStr,
            rank = "Player",
            kills = kda.kills,
            kd = kda.kd,
            avatarUrl = avatar
        },
        population = {
            current = #players,
            max = GetConvarInt('sv_maxclients', 128)
        },
        jobs = formattedJobs,
        priorities = priorityStatuses,
        worldEvents = getFormattedWorldEvents(),
        robberies = getFormattedRobberies()
    }

    cb(serverData)
end)

-- Admin commands to toggle priorities or events (works from console or admin)
RegisterCommand('setprio', function(source, args, rawCommand)
    local isAdmin = false
    if source == 0 then
        isAdmin = true
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.getGroup() ~= 'user' then
            isAdmin = true
        end
    end

    if not isAdmin then
        if source ~= 0 then
            TriggerClientEvent('esx:showNotification', source, "You do not have permission to use this command.")
        end
        return
    end

    local arg1 = args[1]
    local arg2 = args[2]
    if not arg1 then
        local usage = "Usage: /setprio [Safe|Hold|Cooldown|InProgress] OR /setprio [police|sheriff|all] [Safe|Hold|Cooldown|InProgress]"
        if source == 0 then print(usage) else TriggerClientEvent('esx:showNotification', source, usage) end
        return
    end

    local targetJob = 'all'
    local targetStatus = arg1

    if arg2 then
        targetJob = arg1:lower()
        targetStatus = arg2
    else
        -- If 1 arg, check if it's status or job
        local norm = normalizePrioKey(arg1)
        if norm ~= 'safe' and norm ~= 'hold' and norm ~= 'cooldown' and norm ~= 'inprogress' and norm ~= 'lockdown' and norm ~= 'active' then
            targetJob = norm
            targetStatus = 'Safe'
        end
    end

    SetPriorityStatus(targetJob, targetStatus)
    local msg = ("Priority updated: %s is now %s"):format(targetJob:upper(), targetStatus)
    if source == 0 then
        print(msg)
    else
        TriggerClientEvent('esx:showNotification', source, msg)
    end
end, false)

RegisterCommand('setevent', function(source, args, rawCommand)
    local isAdmin = false
    if source == 0 then
        isAdmin = true
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.getGroup() ~= 'user' then
            isAdmin = true
        end
    end

    if not isAdmin then return end

    local eventName = args[1] -- e.g. "Airdrop"
    local eventStatus = args[2] -- e.g. "ACTIVE" or "INACTIVE"
    if eventName and eventStatus then
        for _, event in ipairs(worldEvents) do
            if event.name:lower() == eventName:lower() then
                event.status = eventStatus:upper()
                local msg = ("Event updated: %s is now %s"):format(event.name, event.status)
                if source == 0 then print(msg) else TriggerClientEvent('esx:showNotification', source, msg) end
                break
            end
        end
    end
end, false)

