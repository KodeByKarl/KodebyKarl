--[[
    cfx-keydi-deathscreen (server)
    Aggregates killer profile + recent eliminations for the PvP death UI.
]]

if not ConfigDeathScreen or not ConfigDeathScreen.Enabled then return end

local sessionStart = {}
local playerAvatars = {}
local playerKDA = {}
local killStreak = {}
local recentKills = {} -- [identifier] = { { name, at }, ... }

local function formatPlayTime(identifier)
    local start = sessionStart[identifier]
    if not start then return "—" end

    local diff = math.max(0, os.time() - start)
    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local mins = math.floor((diff % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh", days, hours)
    end
    if hours > 0 then
        return string.format("%dh %dm", hours, mins)
    end
    return string.format("%dm", math.max(1, mins))
end

local function formatRelative(ts)
    local diff = math.max(0, os.time() - (ts or os.time()))
    if diff < 15 then return "just now" end
    if diff < 60 then return string.format("%ds ago", diff) end
    if diff < 3600 then return string.format("%dm ago", math.floor(diff / 60)) end
    if diff < 86400 then return string.format("%dh ago", math.floor(diff / 3600)) end
    return string.format("%dd ago", math.floor(diff / 86400))
end

local function FetchDiscordAvatar(playerId, cb)
    local discordId = nil
    for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
        if string.sub(id, 1, 8) == "discord:" then
            discordId = string.sub(id, 9)
            break
        end
    end

    if not discordId then return cb(nil) end

    local token = ConfigScoreboard and ConfigScoreboard.DiscordBotToken or ""
    if token == "" then return cb(nil) end

    PerformHttpRequest("https://discord.com/api/v10/users/" .. discordId, function(statusCode, response)
        if statusCode == 200 and response then
            local data = json.decode(response)
            if data and data.avatar then
                cb(string.format("https://cdn.discordapp.com/avatars/%s/%s.png", discordId, data.avatar))
                return
            end
        end
        cb(nil)
    end, "GET", "", { ["Authorization"] = "Bot " .. token })
end

local function ensurePlayer(xPlayer)
    if not xPlayer then return end
    local id = xPlayer.identifier
    if not sessionStart[id] then
        sessionStart[id] = os.time()
    end
    if not playerKDA[id] then
        playerKDA[id] = { kills = 0, deaths = 0, kd = "0.00" }
    end
    if not killStreak[id] then
        killStreak[id] = 0
    end
    if not recentKills[id] then
        recentKills[id] = {}
    end
    if not playerAvatars[id] then
        FetchDiscordAvatar(xPlayer.source, function(avatarUrl)
            if avatarUrl then
                playerAvatars[id] = avatarUrl
            else
                playerAvatars[id] = string.format(
                    "https://api.dicebear.com/7.x/adventurer/svg?seed=%s",
                    xPlayer.getName()
                )
            end
        end)
    end
end

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(playerId, xPlayer)
    ensurePlayer(xPlayer)
end)

AddEventHandler("playerDropped", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local id = xPlayer.identifier
    sessionStart[id] = nil
    playerAvatars[id] = nil
    -- keep KDA / recent for short reconnect window? clear for cleanliness
    playerKDA[id] = nil
    killStreak[id] = nil
    recentKills[id] = nil
end)

CreateThread(function()
    Wait(1500)
    for _, xPlayer in ipairs(ESX.GetExtendedPlayers()) do
        ensurePlayer(xPlayer)
    end
end)

-- Share KDA updates from scoreboard client tracking
RegisterNetEvent("cfx-keydi-scoreboard:updateKDA", function(kills, deaths)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    ensurePlayer(xPlayer)

    local kd = deaths > 0 and (kills / deaths) or kills
    playerKDA[xPlayer.identifier] = {
        kills = kills,
        deaths = deaths,
        kd = string.format("%.2f", kd),
    }
end)

local function pushRecentKill(killerIdentifier, victimName)
    local list = recentKills[killerIdentifier] or {}
    table.insert(list, 1, { name = victimName or "Unknown", at = os.time() })
    local limit = ConfigDeathScreen.RecentKillLimit or 5
    while #list > limit do
        table.remove(list)
    end
    recentKills[killerIdentifier] = list
end

-- Debounce duplicate getKillerData from gameEvent + esx:onPlayerDeath
local lastKillPair = {} -- ["killer:victim"] = os.time()

ESX.RegisterServerCallback("cfx-keydi-deathscreen:getKillerData", function(source, cb, killerServerId)
    local victim = ESX.GetPlayerFromId(source)
    local killer = ESX.GetPlayerFromId(tonumber(killerServerId) or -1)
    if not victim or not killer then
        return cb(nil)
    end

    ensurePlayer(victim)
    ensurePlayer(killer)

    local kId = killer.identifier
    local vId = victim.identifier
    local isSuicide = killer.source == victim.source
    local pairKey = ("%s:%s"):format(kId, vId)
    local now = os.time()
    local isFreshKill = not lastKillPair[pairKey] or (now - lastKillPair[pairKey]) > 4

    if isFreshKill then
        lastKillPair[pairKey] = now
        if isSuicide then
            -- Self-kill: reset own streak, do not add a "recent elimination"
            killStreak[vId] = 0
        else
            killStreak[kId] = (killStreak[kId] or 0) + 1
            killStreak[vId] = 0
            pushRecentKill(kId, victim.getName())
        end
        -- KDA is owned by scoreboard client sync — do not double-count here
    end

    local kda = playerKDA[kId] or { kills = 0, deaths = 0, kd = "0.00" }

    local formattedRecent = {}
    for _, entry in ipairs(recentKills[kId] or {}) do
        formattedRecent[#formattedRecent + 1] = {
            name = entry.name,
            time = formatRelative(entry.at),
        }
    end

    local achievements = {}
    if sessionStart[kId] and (now - sessionStart[kId]) > 86400 then
        achievements[#achievements + 1] = "Since Day One"
    end
    if (killStreak[kId] or 0) >= 3 then
        achievements[#achievements + 1] = "On a Tear"
    end
    if (kda.kills or 0) >= 10 then
        achievements[#achievements + 1] = "Blooded"
    end

    cb({
        name = killer.getName(),
        id = killer.source,
        ping = GetPlayerPing(killer.source),
        avatarUrl = playerAvatars[kId] or string.format(
            "https://api.dicebear.com/7.x/adventurer/svg?seed=%s",
            killer.getName()
        ),
        playTime = formatPlayTime(kId),
        rank = "#—",
        kills = kda.kills,
        kd = kda.kd,
        streak = killStreak[kId] or 0,
        recentKills = formattedRecent,
        achievements = achievements,
    })
end)
