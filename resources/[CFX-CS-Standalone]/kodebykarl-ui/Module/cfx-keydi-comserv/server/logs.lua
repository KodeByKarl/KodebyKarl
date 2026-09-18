--[[
    cfx-keydi-comserv Discord logs
    Uses same bot token pattern as cfx-keydi-utils disconnectlogs.
]]

ComServLogs = ComServLogs or {}

local DISCORD_API = "https://discord.com/api/v10"
local PREFIX = "[cfx-keydi-comserv:Logs]"

local resolvedChannels = {}
local channelsReady = false
local postQueue = {}
local posting = false

local function cfg()
    return ConfigComServ and ConfigComServ.Logs or nil
end

local function isEnabled()
    local c = cfg()
    if not c or not c.Enabled then return false end
    if not c.BotToken or c.BotToken == "" or tostring(c.BotToken):find("YOUR_", 1, true) then
        return false
    end
    if not c.GuildID or c.GuildID == "" or tostring(c.GuildID):find("YOUR_", 1, true) then
        return false
    end
    return true
end

local function botHeaders()
    local c = cfg()
    return {
        ["Authorization"] = ("Bot %s"):format(c.BotToken),
        ["Content-Type"] = "application/json",
    }
end

local function discordRequest(method, path, body, cb)
    PerformHttpRequest(DISCORD_API .. path, function(status, response)
        status = tonumber(status) or 0
        local data = nil
        if response and response ~= "" then
            local ok, decoded = pcall(json.decode, response)
            if ok and type(decoded) == "table" then
                data = decoded
            end
        end
        cb(status, data)
    end, method, body and json.encode(body) or "", botHeaders())
end

local function collectIdentifiers(src)
    local out = { discord = nil, license = nil, steam = nil, fivem = nil, ip = nil }
    if not src or src <= 0 then return out end

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id then
            if id:sub(1, 8) == "discord:" then
                out.discord = id:sub(9)
            elseif id:sub(1, 8) == "license:" then
                out.license = id
            elseif id:sub(1, 6) == "steam:" then
                out.steam = id
            elseif id:sub(1, 6) == "fivem:" then
                out.fivem = id
            elseif id:sub(1, 3) == "ip:" then
                out.ip = id:sub(4)
            end
        end
    end
    return out
end

local function processQueue()
    if posting then return end
    posting = true

    CreateThread(function()
        local c = cfg()
        while #postQueue > 0 do
            local item = table.remove(postQueue, 1)
            if item.channelId and item.channelId ~= "" then
                local done = false
                discordRequest("POST", ("/channels/%s/messages"):format(item.channelId), item.payload, function(status)
                    if status ~= 200 and status ~= 201 then
                        print(("^1%s^0 Failed to post (HTTP %s) → %s"):format(PREFIX, status, item.channelId))
                    end
                    done = true
                end)
                local timeout = GetGameTimer() + 10000
                while not done and GetGameTimer() < timeout do
                    Wait(50)
                end
            end
            Wait(tonumber(c and c.PostCooldownMs) or 500)
        end
        posting = false
    end)
end

local function enqueuePost(channelKey, payload)
    local channelId = resolvedChannels[channelKey]
    if not channelId or channelId == "" then
        -- fallback: try any resolved channel
        for _, id in pairs(resolvedChannels) do
            channelId = id
            break
        end
    end
    if not channelId or channelId == "" then return end

    postQueue[#postQueue + 1] = { channelId = channelId, payload = payload }
    processQueue()
end

local function mapGuildChannels(channels)
    local c = cfg()
    local byName = {}
    for i = 1, #channels do
        local ch = channels[i]
        if ch and ch.id and ch.name and (ch.type == 0 or ch.type == nil) then
            byName[ch.name:lower()] = tostring(ch.id)
        end
    end

    local names = c.ChannelNames or {}
    local ids = c.ChannelIDs or {}
    local missing = {}

    for key, channelName in pairs(names) do
        local override = ids[key]
        if type(override) == "string" and override ~= "" and not override:find("YOUR_", 1, true) then
            resolvedChannels[key] = override:gsub("%s+", "")
        else
            local found = byName[tostring(channelName):lower()]
            if found then
                resolvedChannels[key] = found
            else
                missing[#missing + 1] = ("%s (#%s)"):format(key, channelName)
            end
        end
    end

    local c = cfg()
    if c and c.Debug then
        for key, channelId in pairs(resolvedChannels) do
            print(("^2%s^0 %s → %s"):format(PREFIX, key:upper(), channelId))
        end

        if #missing > 0 then
            print(("^1%s^0 Missing channels: %s"):format(PREFIX, table.concat(missing, ", ")))
            print(("^3%s^0 Create a #COMSERV channel (or set ChannelIDs in config)."):format(PREFIX))
        end
    end

    channelsReady = next(resolvedChannels) ~= nil
end

local function resolveChannels()
    local c = cfg()
    if not isEnabled() then return end

    local names = c.ChannelNames or {}
    local ids = c.ChannelIDs or {}
    local allOverride = true
    for key in pairs(names) do
        local override = ids[key]
        if type(override) ~= "string" or override == "" or override:find("YOUR_", 1, true) then
            allOverride = false
            break
        end
    end

    if allOverride then
        for key, override in pairs(ids) do
            resolvedChannels[key] = tostring(override):gsub("%s+", "")
        end
        channelsReady = true
        if c and c.Debug then
            for key, channelId in pairs(resolvedChannels) do
                print(("^2%s^0 %s → %s (manual)"):format(PREFIX, key:upper(), channelId))
            end
        end
        return
    end

    discordRequest("GET", ("/guilds/%s/channels"):format(c.GuildID), nil, function(status, data)
        if status == 200 and type(data) == "table" then
            mapGuildChannels(data)
            return
        end
        if status == 403 then
            print(("^1%s^0 Bot cannot list guild channels (HTTP 403)."):format(PREFIX))
        elseif status == 404 then
            print(("^1%s^0 GuildID not found (HTTP 404)."):format(PREFIX))
        else
            print(("^1%s^0 Failed to list guild channels (HTTP %s)."):format(PREFIX, status))
        end
    end)
end

local function postEmbed(channelKey, embed)
    if not isEnabled() then return end
    local c = cfg()
    if c.LogTypes and c.LogTypes[channelKey] == false then return end

    embed.footer = { text = "Grim City • Community Service" }
    embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    enqueuePost(channelKey, {
        embeds = { embed },
    })
end

local function playerField(src, name, identifier)
    local lines = {}
    lines[#lines + 1] = ("**Name:** %s"):format(name or "Unknown")
    if src and src > 0 then
        lines[#lines + 1] = ("**ID:** `%s`"):format(src)
    else
        lines[#lines + 1] = "**ID:** `offline`"
    end
    if identifier and identifier ~= "" then
        lines[#lines + 1] = ("**Identifier:** `%s`"):format(identifier)
    end
    if src and src > 0 then
        local ids = collectIdentifiers(src)
        if ids.discord then
            lines[#lines + 1] = ("**Discord:** <@%s> (`%s`)"):format(ids.discord, ids.discord)
        end
        if ids.steam then
            lines[#lines + 1] = ("**Steam:** `%s`"):format(ids.steam)
        end
        if ids.license then
            lines[#lines + 1] = ("**License:** `%s`"):format(ids.license)
        end
        if ids.ip then
            lines[#lines + 1] = ("**IP:** `%s`"):format(ids.ip)
        end
    end
    return table.concat(lines, "\n")
end

---@param data table
function ComServLogs.Sent(data)
    data = data or {}
    local c = cfg()
    local color = (c and c.EmbedColors and c.EmbedColors.sent) or 15105570

    postEmbed("sent", {
        title = "Sent to Community Service",
        color = color,
        fields = {
            {
                name = "Player",
                value = playerField(data.targetSrc, data.targetName, data.identifier),
                inline = false,
            },
            {
                name = "Staff",
                value = playerField(data.adminSrc, data.adminName, data.adminIdentifier),
                inline = false,
            },
            { name = "Actions", value = ("`%s`"):format(tostring(data.actions or "?")), inline = true },
            { name = "Mode", value = data.mode == "offline" and "`Offline`" or "`Online`", inline = true },
            { name = "Reason", value = tostring(data.reason or "Community Service"):sub(1, 200), inline = false },
        },
    })
end

---@param data table
function ComServLogs.Action(data)
    data = data or {}
    local c = cfg()
    local color = (c and c.EmbedColors and c.EmbedColors.action) or 3447003
    local remaining = tonumber(data.remaining) or 0
    local total = tonumber(data.total) or 0
    local done = math.max(0, total - remaining)

    postEmbed("action", {
        title = ("Comserv Progress — %d/%d"):format(remaining, total),
        description = ("**%s** completed a task.\nProgress: **%d done** · **%d/%d remaining**"):format(
            data.targetName or "Unknown",
            done,
            remaining,
            total
        ),
        color = color,
        fields = {
            {
                name = "Player",
                value = playerField(data.targetSrc, data.targetName, data.identifier),
                inline = false,
            },
            { name = "Remaining", value = ("`%d / %d`"):format(remaining, total), inline = true },
            { name = "Completed", value = ("`%d / %d`"):format(done, total), inline = true },
            { name = "Reason", value = tostring(data.reason or "—"):sub(1, 200), inline = false },
        },
    })
end

---@param data table
function ComServLogs.Finish(data)
    data = data or {}
    local c = cfg()
    local completed = data.completed == true
    local color = completed
        and ((c and c.EmbedColors and c.EmbedColors.finish) or 5763719)
        or ((c and c.EmbedColors and c.EmbedColors.ended) or 15158332)

    postEmbed("finish", {
        title = completed and "Community Service Completed" or "Community Service Ended by Staff",
        color = color,
        fields = {
            {
                name = "Player",
                value = playerField(data.targetSrc, data.targetName, data.identifier),
                inline = false,
            },
            {
                name = "Originally Sent By",
                value = ("%s"):format(data.adminName or "Unknown"),
                inline = true,
            },
            {
                name = "Sentence",
                value = ("`%s` actions"):format(tostring(data.total or "?")),
                inline = true,
            },
            {
                name = "Remaining When Ended",
                value = ("`%s`"):format(tostring(data.remaining or 0)),
                inline = true,
            },
            { name = "Reason", value = tostring(data.reason or "—"):sub(1, 200), inline = false },
            {
                name = "Ended By",
                value = completed and "`Player finished tasks`" or ("`%s`"):format(data.endedBy or "Staff"),
                inline = false,
            },
        },
    })
end

CreateThread(function()
    Wait(1500)
    local c = cfg()
    if isEnabled() then
        resolveChannels()
    else
        if c and c.Debug then
            print(("^3%s^0 Disabled or missing BotToken/GuildID."):format(PREFIX))
        end
    end
end)
