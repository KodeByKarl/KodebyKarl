--[[
    cfx-keydi-lockscript Discord logs
    Same bot-token pattern as cfx-keydi-comserv.
]]

LockScriptLogs = LockScriptLogs or {}

local DISCORD_API = "https://discord.com/api/v10"
local PREFIX = "[cfx-keydi-lockscript:Logs]"

local resolvedChannels = {}
local postQueue = {}
local posting = false

local function cfg()
    return ConfigLockScript and ConfigLockScript.Logs or nil
end

local function isEnabled()
    local c = cfg()
    if not c or not c.Enabled then return false end
    if not c.BotToken or c.BotToken == "" or tostring(c.BotToken):find("YOUR_", 1, true) then
        return false
    end
    if not c.GuildID or c.GuildID == "" then return false end
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
            if ok and type(decoded) == "table" then data = decoded end
        end
        cb(status, data)
    end, method, body and json.encode(body) or "", botHeaders())
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
                        print(("^1%s^0 Failed to post (HTTP %s)"):format(PREFIX, status))
                    end
                    done = true
                end)
                local timeout = GetGameTimer() + 10000
                while not done and GetGameTimer() < timeout do Wait(50) end
            end
            Wait(tonumber(c and c.PostCooldownMs) or 500)
        end
        posting = false
    end)
end

local function enqueuePost(channelKey, payload)
    local channelId = resolvedChannels[channelKey]
    if not channelId or channelId == "" then
        for _, id in pairs(resolvedChannels) do
            channelId = id
            break
        end
    end
    if not channelId or channelId == "" then return end
    postQueue[#postQueue + 1] = { channelId = channelId, payload = payload }
    processQueue()
end

local function resolveChannels()
    local c = cfg()
    if not isEnabled() then return end

    if c.ChannelIDs then
        for k, v in pairs(c.ChannelIDs) do
            if type(v) == "string" and v ~= "" then
                resolvedChannels[k] = v
            end
        end
    end

    discordRequest("GET", ("/guilds/%s/channels"):format(c.GuildID), nil, function(status, channels)
        if status ~= 200 or type(channels) ~= "table" then
            return
        end
        local names = c.ChannelNames or {}
        for _, ch in ipairs(channels) do
            if ch.type == 0 and ch.name then
                local lower = string.lower(ch.name)
                for key, want in pairs(names) do
                    if want and string.lower(want) == lower and (not resolvedChannels[key] or resolvedChannels[key] == "") then
                        resolvedChannels[key] = ch.id
                    end
                end
            end
        end
    end)
end

local function embed(title, description, color, fields)
    return {
        embeds = {
            {
                title = title,
                description = description,
                color = color or 3447003,
                fields = fields or {},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = { text = "VIP Appearance Locks" },
            },
        },
    }
end

function LockScriptLogs.Log(kind, title, description, fields)
    if not isEnabled() then return end
    local c = cfg()
    local types = c.LogTypes or {}
    if types[kind] == false then return end

    local channelKey = "lock"
    if kind == "blocked" then channelKey = "blocked"
    elseif kind == "access" then channelKey = "access"
    end

    local colors = c.EmbedColors or {}
    enqueuePost(channelKey, embed(title, description, colors[kind] or 3447003, fields))
end

CreateThread(function()
    Wait(2500)
    resolveChannels()
end)
