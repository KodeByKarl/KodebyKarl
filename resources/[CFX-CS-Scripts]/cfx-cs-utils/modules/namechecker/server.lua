--[[
    NameChecker (cfx-keydi-utils)
    Blocks connecting players whose FiveM display name does not match their Discord nick/username.
]]

local Config = require 'configs.namechecker'

local DISCORD_API = 'https://discord.com/api/v10'

local function getBotToken()
    if Config.BotToken and Config.BotToken ~= '' and not Config.BotToken:find('YOUR_', 1, true) then
        return Config.BotToken
    end
    local convar = GetConvar('kodebykarl_discord_bot_token', '')
    if convar ~= '' then
        return convar
    end
    return nil
end

---Normalize a name for comparison using config toggles.
---@param name string?
---@return string
local function normalizeName(name)
    name = tostring(name or '')
    if Config.TrimSpaces then
        name = name:match('^%s*(.-)%s*$') or name
    end
    if Config.CaseInsensitive then
        name = name:lower()
    end
    return name
end

---Extract Discord snowflake from player identifiers.
---@param src number|string
---@return string?
local function getDiscordId(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == 'discord:' then
            return id:sub(9)
        end
    end
    return nil
end

---GET guild member; returns ok, dataOrNil, httpStatus
---@param discordId string
---@param cb fun(ok: boolean, data: table|nil, status: number)
local function fetchGuildMember(discordId, cb)
    local token = getBotToken()
    if not token then
        return cb(false, nil, 0)
    end

    local url = ('%s/guilds/%s/members/%s'):format(DISCORD_API, Config.GuildID, discordId)

    PerformHttpRequest(url, function(status, body)
        status = tonumber(status) or 0

        if status == 200 and body and body ~= '' then
            local ok, data = pcall(json.decode, body)
            if ok and type(data) == 'table' then
                return cb(true, data, status)
            end
            return cb(false, nil, status)
        end

        cb(false, nil, status)
    end, 'GET', '', {
        ['Authorization'] = ('Bot %s'):format(token),
        ['Content-Type'] = 'application/json',
    })
end

---Resolve the display name we expect the player to use in FiveM.
---@param member table
---@return string?
local function resolveDiscordDisplayName(member)
    local nick = member.nick
    if type(nick) == 'string' and nick ~= '' then
        return nick
    end

    if Config.FallbackToUsername and member.user then
        local globalName = member.user.global_name
        if type(globalName) == 'string' and globalName ~= '' then
            return globalName
        end
        local username = member.user.username
        if type(username) == 'string' and username ~= '' then
            return username
        end
    end

    return nil
end

local function isConfigured()
    if not getBotToken() then return false end
    if not Config.GuildID or Config.GuildID == '' or Config.GuildID:find('YOUR_', 1, true) then return false end
    return true
end

if not Config.Enabled then
    print('^3[cfx-keydi-utils]^0 NameChecker disabled in configs/namechecker.lua')
    return
end

AddEventHandler('playerConnecting', function(playerName, _setKickReason, deferrals)
    local src = source
    deferrals.defer()

    Wait(0)
    deferrals.update(Config.Messages.Checking)

    if not isConfigured() then
        print('^1[cfx-keydi-utils]^0 NameChecker: BotToken / GuildID not configured — allowing join.')
        deferrals.done()
        return
    end

    local discordId = getDiscordId(src)
    if not discordId then
        deferrals.done(Config.Messages.NoDiscord:format(Config.DiscordInvite))
        return
    end

    fetchGuildMember(discordId, function(ok, member, status)
        if status == 404 then
            if Config.RequireGuildMembership then
                deferrals.done(Config.Messages.NotInGuild:format(Config.DiscordInvite))
            else
                deferrals.done()
            end
            return
        end

        if not ok or not member then
            deferrals.done(Config.Messages.ApiError)
            return
        end

        local discordName = resolveDiscordDisplayName(member)
        if not discordName or discordName == '' then
            deferrals.done(Config.Messages.ApiError)
            return
        end

        if normalizeName(playerName) == normalizeName(discordName) then
            deferrals.done()
            return
        end

        deferrals.done(Config.Messages.Mismatch:format(discordName))
    end)
end)
