local DISCORD_API = 'https://discord.com/api/v10'

local StaffCache = {}
local RoleOrder = {}

local function GetDiscordBotToken()
    local convar = GetConvar('kodebykarl_discord_bot_token', '')
    if convar ~= '' then
        return convar
    end
    return nil
end

local function GetRoleList()
    local roles = Config.Discord and Config.Discord.Roles
    if type(roles) ~= 'table' then
        return {}
    end
    return roles
end

local function EmptyStaff()
    local staff = {}
    for _, roleCfg in ipairs(GetRoleList()) do
        if roleCfg.key then
            staff[roleCfg.key] = {}
        end
    end
    return staff
end

local function BuildRoleMeta()
    local order = {}
    local labels = {}
    for _, roleCfg in ipairs(GetRoleList()) do
        if roleCfg.key then
            order[#order + 1] = roleCfg.key
            labels[roleCfg.key] = roleCfg.label or roleCfg.key
        end
    end
    return order, labels
end

local function AvatarUrl(userId, avatarHash)
    if avatarHash and avatarHash ~= '' then
        local ext = avatarHash:sub(1, 2) == 'a_' and 'gif' or 'png'
        return ('https://cdn.discordapp.com/avatars/%s/%s.%s?size=128'):format(userId, avatarHash, ext)
    end
    local last = tonumber(tostring(userId):sub(-1)) or 0
    return ('https://cdn.discordapp.com/embed/avatars/%d.png'):format(last % 5)
end

local function MemberDisplayName(member)
    if member.nick and member.nick ~= '' then
        return member.nick
    end
    local user = member.user
    if not user then return 'Unknown' end
    if user.global_name and user.global_name ~= '' then
        return user.global_name
    end
    return user.username or 'Unknown'
end

local function MemberHasRole(member, roleId)
    if not roleId or roleId == '' or not member.roles then
        return false
    end
    for i = 1, #member.roles do
        if tostring(member.roles[i]) == tostring(roleId) then
            return true
        end
    end
    return false
end

local function FetchGuildMembersPage(guildId, token, after, cb)
    local url = ('%s/guilds/%s/members?limit=1000'):format(DISCORD_API, guildId)
    if after and after ~= '' then
        url = url .. '&after=' .. after
    end

    PerformHttpRequest(url, function(status, body)
        if status ~= 200 or not body then
            cb(status, nil)
            return
        end
        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' then
            cb(status, nil)
            return
        end
        cb(status, data)
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. token,
        ['Content-Type'] = 'application/json',
    })
end

local function BuildStaffFromMembers(members)
    local staff = EmptyStaff()
    local roles = GetRoleList()

    for _, member in ipairs(members) do
        local user = member.user
        if user and not user.bot then
            local entry = {
                id = tostring(user.id),
                name = MemberDisplayName(member),
                avatar = AvatarUrl(user.id, user.avatar),
            }

            for _, roleCfg in ipairs(roles) do
                local key = roleCfg.key
                if key and staff[key] and MemberHasRole(member, roleCfg.id) then
                    staff[key][#staff[key] + 1] = entry
                end
            end
        end
    end

    return staff
end

local function RefreshStaffCache()
    StaffCache = EmptyStaff()
    RoleOrder = select(1, BuildRoleMeta())

    local token = GetDiscordBotToken()
    local guildId = Config.Discord and Config.Discord.GuildId

    if not token then
        print('^3[kodebykarl-loadingscreen]^0 Discord bot token missing (convar kodebykarl_discord_bot_token). Staff slider will be empty.')
        return
    end

    if not guildId or guildId == '' then
        print('^3[kodebykarl-loadingscreen]^0 Config.Discord.GuildId is empty. Staff slider will be empty.')
        return
    end

    local hasAnyRole = false
    for _, roleCfg in ipairs(GetRoleList()) do
        if roleCfg.id and roleCfg.id ~= '' then
            hasAnyRole = true
            break
        end
    end

    if not hasAnyRole then
        print('^3[kodebykarl-loadingscreen]^0 No Discord role IDs configured yet. Fill Config.Discord.Roles.')
        return
    end

    local allMembers = {}

    local function fetchNext(after)
        FetchGuildMembersPage(guildId, token, after, function(status, page)
            if status == 401 or status == 403 then
                print(('^1[kodebykarl-loadingscreen]^0 Discord auth/guild access failed (HTTP %s). Check bot token + Server Members Intent.'):format(tostring(status)))
                StaffCache = EmptyStaff()
                return
            end

            if status ~= 200 or not page then
                print(('^1[kodebykarl-loadingscreen]^0 Discord members fetch failed (HTTP %s).'):format(tostring(status)))
                StaffCache = EmptyStaff()
                return
            end

            for i = 1, #page do
                allMembers[#allMembers + 1] = page[i]
            end

            if #page >= 1000 then
                local last = page[#page]
                local lastId = last and last.user and last.user.id
                if lastId then
                    fetchNext(lastId)
                    return
                end
            end

            StaffCache = BuildStaffFromMembers(allMembers)
            local parts = {}
            for _, key in ipairs(RoleOrder) do
                parts[#parts + 1] = ('%s:%s'):format(key, #(StaffCache[key] or {}))
            end
            print(('^2[kodebykarl-loadingscreen]^0 Staff cache refreshed — %s'):format(table.concat(parts, ' ')))
        end)
    end

    fetchNext(nil)
end

local function HandoverPayload()
    local order, labels = BuildRoleMeta()
    return {
        serverName = Config.ServerName or 'Grim City',
        music = {
            youtubeId = Config.Music and Config.Music.youtubeId or 'k5ri3jyGPNQ',
            title = Config.Music and Config.Music.title or 'Loading Theme',
            artist = Config.Music and Config.Music.artist or 'Grim City',
        },
        staff = StaffCache,
        roleOrder = order,
        roles = labels,
    }
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    deferrals.handover(HandoverPayload())
end)

CreateThread(function()
    RefreshStaffCache()
    local minutes = tonumber(Config.Discord and Config.Discord.RefreshMinutes) or 15
    local waitMs = math.max(1, minutes) * 60 * 1000
    while true do
        Wait(waitMs)
        RefreshStaffCache()
    end
end)

exports('GetStaffCache', function()
    return StaffCache
end)

exports('RefreshStaff', function()
    RefreshStaffCache()
end)
