local Config = require 'configs.freecam'

if not Config.Enabled then return end

local DISCORD_API = 'https://discord.com/api/v10'

local function getDiscordId(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == 'discord:' then
            return id:sub(9)
        end
    end
    local discordId = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'discord')
    if discordId then
        if discordId:sub(1, 8) == 'discord:' then
            return discordId:sub(9)
        end
        return discordId
    end
    return nil
end

local function isDiscordConfigured()
    local dc = Config.DiscordRoles
    if not dc or not dc.Enabled then return false end
    if not dc.BotToken or dc.BotToken == '' or dc.BotToken:find('YOUR_', 1, true) then return false end
    if not dc.GuildID or dc.GuildID == '' or dc.GuildID:find('YOUR_', 1, true) then return false end
    return true
end

local function isStaff(xPlayer)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    if Config.Groups then
        for _, g in ipairs(Config.Groups) do
            if group == g then
                return true
            end
        end
    end
    if IsPlayerAceAllowed(xPlayer.source, 'command.freecam') or IsPlayerAceAllowed(xPlayer.source, 'group.admin') or IsPlayerAceAllowed(xPlayer.source, 'group.superadmin') or IsPlayerAceAllowed(xPlayer.source, 'group.developer') then
        return true
    end
    return false
end

--- Live Discord member role verification (real-time, zero reload needed)
local function checkStreamerDiscordRoleLive(src, cb)
    local dc = Config.DiscordRoles
    if not isDiscordConfigured() or not dc.Roles or #dc.Roles == 0 then
        return cb(false)
    end

    local discordId = getDiscordId(src)
    if not discordId then
        return cb(false)
    end

    local url = ('%s/guilds/%s/members/%s'):format(DISCORD_API, dc.GuildID, discordId)
    PerformHttpRequest(url, function(status, body)
        status = tonumber(status) or 0
        if status == 200 and body and body ~= '' then
            local ok, data = pcall(json.decode, body)
            if ok and type(data) == 'table' and data.roles then
                local userRoles = {}
                for _, rId in ipairs(data.roles) do
                    userRoles[tostring(rId)] = true
                end

                for _, allowed in ipairs(dc.Roles) do
                    if userRoles[tostring(allowed)] then
                        return cb(true)
                    end
                end
            end
        end

        return cb(false)
    end, 'GET', '', {
        ['Authorization'] = ('Bot %s'):format(dc.BotToken),
        ['Content-Type'] = 'application/json',
    })
end

local function checkFreecamAccess(src, cb)
    if src == 0 then return cb(true) end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(false) end

    -- 1. Check ESX Staff Groups
    if isStaff(xPlayer) then
        return cb(true)
    end

    -- 2. Check Live Streamer Discord Role
    checkStreamerDiscordRoleLive(src, function(allowed)
        return cb(allowed)
    end)
end

RegisterCommand(Config.Command or 'freecam', function(source, args, rawCommand)
    local src = source
    if src == 0 then
        print('^3[cfx-keydi-utils]^0 /freecam can only be used by players in-game.')
        return
    end

    checkFreecamAccess(src, function(hasAccess)
        if hasAccess then
            pcall(function()
                exports['ElectronAC']:tempWhitelistPlayer(src, 'antiFreecam')
                exports['ElectronAC']:tempWhitelistPlayer(src, 'antiNoclip')
                exports['ElectronAC']:tempWhitelistPlayer(src, 'antiGodmode')
                exports['ElectronAC']:tempWhitelistPlayer(src, 'antiInvisible')
            end)
            local fgName = GetConvar('fiveguard_resource', '')
            if fgName == '' then
                for _, name in ipairs({ 'grimbot', 'fiveguard', 'fg', 'FiveGuard' }) do
                    if GetResourceState(name) == 'started' then
                        fgName = name
                        break
                    end
                end
            end
            if fgName ~= '' and GetResourceState(fgName) == 'started' then
                pcall(function()
                    exports[fgName]:SetTempPermission(src, 'Client', 'BypassFreecam', true, false)
                    exports[fgName]:SetTempPermission(src, 'Client', 'BypassNoclip', true, false)
                    exports[fgName]:SetTempPermission(src, 'Client', 'BypassInvisible', true, false)
                    exports[fgName]:SetTempPermission(src, 'Client', 'BypassTeleport', true, false)
                end)
            end
            -- Streamers can leave freecam with Backspace (client-only). Expire the exception.
            SetTimeout(30 * 60 * 1000, function()
                if not GetPlayerName(src) then return end
                pcall(function()
                    exports['ElectronAC']:tempUnWhitelistPlayer(src, 'antiFreecam')
                    exports['ElectronAC']:tempUnWhitelistPlayer(src, 'antiNoclip')
                    exports['ElectronAC']:tempUnWhitelistPlayer(src, 'antiGodmode')
                    exports['ElectronAC']:tempUnWhitelistPlayer(src, 'antiInvisible')
                end)
                if fgName ~= '' and GetResourceState(fgName) == 'started' then
                    pcall(function()
                        exports[fgName]:SetTempPermission(src, 'Client', 'BypassFreecam', false, false)
                        exports[fgName]:SetTempPermission(src, 'Client', 'BypassNoclip', false, false)
                        exports[fgName]:SetTempPermission(src, 'Client', 'BypassInvisible', false, false)
                        exports[fgName]:SetTempPermission(src, 'Client', 'BypassTeleport', false, false)
                    end)
                end
            end)
            TriggerClientEvent('cfx-keydi-utils:freecam', src)
        else
            local msg = Config.NoPermissionMessage or 'Wala kang Streamer Discord role para mag-freecam.'
            TriggerClientEvent('esx:showNotification', src, msg)
        end
    end)
end, false)

RegisterNetEvent('kodebykarl-utils:freecam:stopped', function()
    local src = source
    local fgName = GetConvar('fiveguard_resource', '')
    if fgName == '' then
        for _, name in ipairs({ 'grimbot', 'fiveguard', 'fg', 'FiveGuard' }) do
            if GetResourceState(name) == 'started' then
                fgName = name
                break
            end
        end
    end
    pcall(function()
        exports['ElectronAC']:tempUnWhitelistPlayer(src, 'antiFreecam')
        exports['ElectronAC']:tempUnWhitelistPlayer(src, 'antiNoclip')
        exports['ElectronAC']:tempUnWhitelistPlayer(src, 'antiGodmode')
        exports['ElectronAC']:tempUnWhitelistPlayer(src, 'antiInvisible')
    end)
    if fgName ~= '' and GetResourceState(fgName) == 'started' then
        pcall(function()
            exports[fgName]:SetTempPermission(src, 'Client', 'BypassFreecam', false, false)
            exports[fgName]:SetTempPermission(src, 'Client', 'BypassNoclip', false, false)
            exports[fgName]:SetTempPermission(src, 'Client', 'BypassInvisible', false, false)
            exports[fgName]:SetTempPermission(src, 'Client', 'BypassTeleport', false, false)
        end)
    end
end)

exports('CanUseFreecam', function(src, cb)
    if not cb then
        local xPlayer = ESX.GetPlayerFromId(src)
        return isStaff(xPlayer)
    end
    checkFreecamAccess(src, cb)
end)
