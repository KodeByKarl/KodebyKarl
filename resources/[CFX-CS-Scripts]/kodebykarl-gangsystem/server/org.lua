local ESX = exports['es_extended']:getSharedObject()

--[[
    iPad Organization app bridge
    Callbacks: cfx-keydi-gang:org:dashboard | hire | setGrade | fire
    Event: cfx-keydi-gang:server:hireByDiscord
]]

local roleCache = {}

local function LogToDiscord(action, data)
    local logs = Config.Logs
    if not logs or not logs.Enabled then return end
    if not logs.LogTypes or not logs.LogTypes.roster then return end

    local channelId = logs.ChannelIDs and logs.ChannelIDs.roster
    if not channelId or channelId == '' then return end

    local token = logs.BotToken ~= '' and logs.BotToken or GetConvar('kodebykarl_discord_bot_token', '')
    if not token or token == '' then return end

    local embedColor = (logs.EmbedColors and logs.EmbedColors[action]) or 3447003
    local title = ('Gang %s'):format(action:gsub('^%l', string.upper))

    local fields = {}
    if data.gang then
        fields[#fields + 1] = { name = 'Organization', value = tostring(data.gang), inline = true }
    end
    if data.actor then
        fields[#fields + 1] = { name = 'Action By', value = tostring(data.actor), inline = true }
    end
    if data.target then
        fields[#fields + 1] = { name = 'Target', value = tostring(data.target), inline = true }
    end
    if data.grade then
        fields[#fields + 1] = { name = 'Rank / Grade', value = tostring(data.grade), inline = true }
    end

    local payload = json.encode({
        embeds = {
            {
                title = title,
                color = embedColor,
                fields = fields,
                footer = { text = 'Grim City Gang System' },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            }
        }
    })

    PerformHttpRequest(('https://discord.com/api/v10/channels/%s/messages'):format(channelId), function(status, text)
        -- silent response
    end, 'POST', payload, {
        ['Authorization'] = 'Bot ' .. token,
        ['Content-Type'] = 'application/json',
    })
end

local function CheckDiscordRole(discordId, requiredRoleId, cb)
    local cfg = Config.DiscordHire or {}
    if not cfg.Enabled then
        return cb(true)
    end
    if not requiredRoleId or requiredRoleId == '' then
        if cfg.BlockIfRoleNotConfigured then
            return cb(false, 'RoleNotConfigured')
        else
            return cb(true)
        end
    end

    local cacheKey = ('%s_%s'):format(discordId, requiredRoleId)
    local cached = roleCache[cacheKey]
    local now = GetGameTimer()
    local cacheDuration = cfg.RoleCacheMs or 15000
    if cached and (now - cached.time < cacheDuration) then
        return cb(cached.hasRole, cached.reason)
    end

    local token = cfg.BotToken ~= '' and cfg.BotToken or GetConvar('kodebykarl_discord_bot_token', '')
    if not token or token == '' then
        token = Config.Logs and Config.Logs.BotToken ~= '' and Config.Logs.BotToken or ''
    end
    if token == '' then
        return cb(true)
    end

    local guildId = cfg.GuildID or '1240677650348118148'
    local endpoint = ('https://discord.com/api/v10/guilds/%s/members/%s'):format(guildId, discordId)

    PerformHttpRequest(endpoint, function(status, body)
        if status == 200 and body then
            local data = json.decode(body)
            if data and data.roles then
                for _, rId in ipairs(data.roles) do
                    if tostring(rId) == tostring(requiredRoleId) then
                        roleCache[cacheKey] = { hasRole = true, time = now }
                        return cb(true)
                    end
                end
            end
            roleCache[cacheKey] = { hasRole = false, reason = 'MissingRole', time = now }
            return cb(false, 'MissingRole')
        elseif status == 404 then
            roleCache[cacheKey] = { hasRole = false, reason = 'NotInGuild', time = now }
            return cb(false, 'NotInGuild')
        elseif status == 401 or status == 403 then
            return cb(false, 'BotCannotAccess')
        else
            return cb(false, 'ApiError')
        end
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. token,
        ['Content-Type'] = 'application/json',
    })
end

local function FindPlayerByDiscord(discordId)
    local targetTag = 'discord:' .. discordId
    local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}
    for _, xP in pairs(xPlayers) do
        for _, id in ipairs(GetPlayerIdentifiers(xP.source)) do
            if id == targetTag or id == discordId or id:sub(9) == discordId then
                return xP, true
            end
        end
    end
    return nil, false
end

local function FindOfflineIdentifierByDiscord(discordId)
    local row = MySQL.single.await([[
        SELECT identifier FROM users 
        WHERE identifier = ? OR identifier = ? OR identifier LIKE ?
        LIMIT 1
    ]], {
        discordId,
        'discord:' .. discordId,
        '%' .. discordId .. '%'
    })
    if row and row.identifier then
        return row.identifier
    end
    local ok, res = pcall(function()
        return MySQL.single.await('SELECT identifier FROM users WHERE discord = ? LIMIT 1', { discordId })
    end)
    if ok and res and res.identifier then
        return res.identifier
    end
    return nil
end

local function mapDashboard(dash)
    return dash
end

lib.callback.register('cfx-keydi-gang:org:dashboard', function(source, data)
    data = type(data) == 'table' and data or {}
    local gang = data.gang
    return mapDashboard(GangServer.BuildDashboard(source, gang))
end)

lib.callback.register('cfx-keydi-gang:org:hire', function(source, data)
    data = type(data) == 'table' and data or {}
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'offline' } end

    local gangName = data.gang and tostring(data.gang):lower() or nil
    local gang = GangServer.GetPlayerGang(source)
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local staff = group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin'

    if not gangName and gang then gangName = gang.name end
    if not gangName or not GangServer.GetGangDef(gangName) then
        return { ok = false, error = 'invalid' }
    end
    if not staff and not GangServer.IsBoss(source, gangName) then
        return { ok = false, error = 'denied' }
    end

    local targetId = tonumber(data.id)
    local grade = math.floor(tonumber(data.grade) or 0)
    if not targetId or targetId == source then
        return { ok = false, error = 'invalid' }
    end

    local yourGrade = staff and 99 or GangServer.GetGradeLevel(gang)
    if grade < 0 or grade >= yourGrade then
        return { ok = false, error = 'grade' }
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return { ok = false, error = 'offline' } end
    if not GangServer.IsNear(source, targetId) then return { ok = false, error = 'far' } end

    local existing = xTarget.getGang and xTarget.getGang() or xTarget.gang
    if type(existing) == 'table' and existing.name == gangName then
        return { ok = false, error = 'already' }
    end

    local cfg = GangServer.GetGangDef(gangName)
    local label = GangServer.GradeLabel(gangName, grade)
    local ok = GangServer.SetPlayerGang(
        xTarget,
        gangName,
        grade,
        ('You were hired into %s as %s.'):format(cfg.label, label)
    )
    if not ok then return { ok = false, error = 'failed' } end

    LogToDiscord('hire', {
        gang = cfg.label,
        actor = xPlayer.name,
        target = xTarget.name,
        grade = label,
    })

    return GangServer.BuildDashboard(source, gangName)
end)

lib.callback.register('cfx-keydi-gang:org:setGrade', function(source, data)
    data = type(data) == 'table' and data or {}
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'offline' } end

    local gangName = data.gang and tostring(data.gang):lower() or nil
    local gang = GangServer.GetPlayerGang(source)
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local staff = group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin'
    if not gangName and gang then gangName = gang.name end
    if not gangName or not GangServer.GetGangDef(gangName) then
        return { ok = false, error = 'invalid' }
    end
    if not staff and not GangServer.IsBoss(source, gangName) then
        return { ok = false, error = 'denied' }
    end

    local identifier = data.identifier
    local grade = math.floor(tonumber(data.grade) or -1)
    if type(identifier) ~= 'string' or identifier == '' or grade < 0 then
        return { ok = false, error = 'invalid' }
    end
    if identifier == xPlayer.identifier then
        return { ok = false, error = 'self' }
    end

    local yourGrade = staff and 99 or GangServer.GetGradeLevel(gang)
    if grade >= yourGrade then
        return { ok = false, error = 'grade' }
    end

    local targetName = 'Member'
    local prevGrade = 0
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        local tGang = xTarget.getGang and xTarget.getGang() or xTarget.gang
        if type(tGang) ~= 'table' or tGang.name ~= gangName then
            return { ok = false, error = 'not_member' }
        end
        prevGrade = GangServer.GetGradeLevel(tGang)
        if prevGrade >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        targetName = xTarget.name or GangServer.DisplayName(xTarget)
        local label = GangServer.GradeLabel(gangName, grade)
        GangServer.SetPlayerGang(xTarget, gangName, grade, ('Your rank is now %s.'):format(label))
    else
        local row = MySQL.single.await('SELECT gang, firstname, lastname FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or not row.gang then return { ok = false, error = 'not_member' } end
        local decoded = type(row.gang) == 'string' and json.decode(row.gang) or row.gang
        if type(decoded) ~= 'table' or decoded.name ~= gangName then
            return { ok = false, error = 'not_member' }
        end
        prevGrade = GangServer.GetGradeLevel(decoded)
        if prevGrade >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        targetName = GangServer.DisplayName(nil, row)
        if not GangServer.SetOfflineGang(identifier, gangName, grade) then
            return { ok = false, error = 'failed' }
        end
    end

    local cfg = GangServer.GetGangDef(gangName)
    local newLabel = GangServer.GradeLabel(gangName, grade)
    local actionType = grade >= prevGrade and 'promote' or 'demote'
    LogToDiscord(actionType, {
        gang = cfg and cfg.label or gangName,
        actor = xPlayer.name,
        target = targetName,
        grade = newLabel,
    })

    return GangServer.BuildDashboard(source, gangName)
end)

lib.callback.register('cfx-keydi-gang:org:fire', function(source, data)
    data = type(data) == 'table' and data or {}
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'offline' } end

    local gangName = data.gang and tostring(data.gang):lower() or nil
    local gang = GangServer.GetPlayerGang(source)
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local staff = group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin'
    if not gangName and gang then gangName = gang.name end
    if not gangName or not GangServer.GetGangDef(gangName) then
        return { ok = false, error = 'invalid' }
    end
    if not staff and not GangServer.IsBoss(source, gangName) then
        return { ok = false, error = 'denied' }
    end

    local identifier = data.identifier
    if type(identifier) ~= 'string' or identifier == '' then
        return { ok = false, error = 'invalid' }
    end
    if identifier == xPlayer.identifier then
        return { ok = false, error = 'self' }
    end

    local yourGrade = staff and 99 or GangServer.GetGradeLevel(gang)

    local targetName = 'Member'
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        local tGang = xTarget.getGang and xTarget.getGang() or xTarget.gang
        if type(tGang) ~= 'table' or tGang.name ~= gangName then
            return { ok = false, error = 'not_member' }
        end
        if GangServer.GetGradeLevel(tGang) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        targetName = xTarget.name or GangServer.DisplayName(xTarget)
        GangServer.SetPlayerGang(xTarget, 'none', 0, 'You were removed from the gang.')
    else
        local row = MySQL.single.await('SELECT gang, firstname, lastname FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or not row.gang then return { ok = false, error = 'not_member' } end
        local decoded = type(row.gang) == 'string' and json.decode(row.gang) or row.gang
        if type(decoded) ~= 'table' or decoded.name ~= gangName then
            return { ok = false, error = 'not_member' }
        end
        if GangServer.GetGradeLevel(decoded) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        targetName = GangServer.DisplayName(nil, row)
        GangServer.ClearOfflineGang(identifier)
    end

    local cfg = GangServer.GetGangDef(gangName)
    LogToDiscord('fire', {
        gang = cfg and cfg.label or gangName,
        actor = xPlayer.name,
        target = targetName,
    })

    return GangServer.BuildDashboard(source, gangName)
end)

RegisterNetEvent('cfx-keydi-gang:server:hireByDiscord', function(gangName, discord)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    gangName = tostring(gangName or ''):lower()
    local cfg = GangServer.GetGangDef(gangName)
    if not cfg then
        return GangServer.Notify(src, 'GANG', 'Unknown organization.', 'error')
    end

    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local staff = group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin'
    if not staff and not GangServer.IsBoss(src, gangName) then
        return GangServer.Notify(src, 'GANG', 'Boss access only.', 'error')
    end

    local cleanDiscord = tostring(discord or ''):gsub('%D', '')
    if cleanDiscord == '' then
        local msg = (Config.DiscordHire and Config.DiscordHire.Messages and Config.DiscordHire.Messages.InvalidDiscordId) or 'Invalid Discord ID.'
        return GangServer.Notify(src, 'GANG', msg, 'error')
    end

    local requiredRole = cfg.discordRoleId
    CheckDiscordRole(cleanDiscord, requiredRole, function(hasRole, errKey)
        if not hasRole then
            local msgs = Config.DiscordHire and Config.DiscordHire.Messages or {}
            local template = msgs[errKey] or 'Discord role verification failed.'
            local msg = template:format(cfg.label or gangName)
            return GangServer.Notify(src, 'GANG', msg, 'error')
        end

        -- Role verified: find online player or offline character
        local xTarget, isOnline = FindPlayerByDiscord(cleanDiscord)
        if xTarget then
            local tGang = xTarget.getGang and xTarget.getGang() or xTarget.gang
            if type(tGang) == 'table' and tGang.name == gangName then
                local msg = (Config.DiscordHire and Config.DiscordHire.Messages and Config.DiscordHire.Messages.AlreadyInGang) or 'That player is already in your gang.'
                return GangServer.Notify(src, 'GANG', msg, 'error')
            end

            local grade = 0
            local label = GangServer.GradeLabel(gangName, grade)
            local ok = GangServer.SetPlayerGang(
                xTarget,
                gangName,
                grade,
                ('You were hired into %s as %s.'):format(cfg.label, label)
            )
            if ok then
                GangServer.Notify(src, 'GANG', ('Hired %s into %s.'):format(xTarget.name or cleanDiscord, cfg.label), 'success')
                LogToDiscord('hire', {
                    gang = cfg.label,
                    actor = xPlayer.name,
                    target = xTarget.name,
                    grade = label,
                })
            else
                GangServer.Notify(src, 'GANG', 'Hire failed.', 'error')
            end
            return
        end

        if not Config.DiscordHire or not Config.DiscordHire.AllowOfflineHire then
            local msg = (Config.DiscordHire and Config.DiscordHire.Messages and Config.DiscordHire.Messages.OfflineDisabled) or 'Offline Discord hire is disabled.'
            return GangServer.Notify(src, 'GANG', msg, 'error')
        end

        local offlineIdentifier = FindOfflineIdentifierByDiscord(cleanDiscord)
        if not offlineIdentifier then
            local msg = (Config.DiscordHire and Config.DiscordHire.Messages and Config.DiscordHire.Messages.NoCharacter) or 'No character found for that Discord ID.'
            return GangServer.Notify(src, 'GANG', msg, 'error')
        end

        local row = MySQL.single.await('SELECT gang, firstname, lastname FROM users WHERE identifier = ? LIMIT 1', { offlineIdentifier })
        if row and row.gang then
            local decoded = type(row.gang) == 'string' and json.decode(row.gang) or row.gang
            if type(decoded) == 'table' and decoded.name == gangName then
                local msg = (Config.DiscordHire and Config.DiscordHire.Messages and Config.DiscordHire.Messages.AlreadyInGang) or 'That player is already in your gang.'
                return GangServer.Notify(src, 'GANG', msg, 'error')
            end
        end

        local grade = 0
        local label = GangServer.GradeLabel(gangName, grade)
        local ok = GangServer.SetOfflineGang(offlineIdentifier, gangName, grade)
        if ok then
            local targetName = GangServer.DisplayName(nil, row)
            GangServer.Notify(src, 'GANG', ('Hired %s (offline) into %s.'):format(targetName, cfg.label), 'success')
            LogToDiscord('hire', {
                gang = cfg.label,
                actor = xPlayer.name,
                target = ('%s (offline)'):format(targetName),
                grade = label,
            })
        else
            GangServer.Notify(src, 'GANG', 'Offline hire failed.', 'error')
        end
    end)
end)
