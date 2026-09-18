--[[
    xt-prison Discord logs via kodebykarl-logs
    Channels: #JAIL #prison-releas #prison-break #prison-items
]]

PrisonLogs = PrisonLogs or {}

local config = require 'configs.server'
local PREFIX = '[xt-prison:Logs]'

local function cfg()
    return config and config.Logs or nil
end

local function isEnabled()
    local c = cfg()
    if not c or c.Enabled == false then return false end
    return GetResourceState('kodebykarl-logs') == 'started'
end

local function typeAllowed(key)
    local c = cfg()
    if c and c.LogTypes and c.LogTypes[key] == false then
        return false
    end
    return true
end

--- Map logical keys to Discord channel aliases in kodebykarl-logs
local CHANNEL = {
    jail = 'JAIL',
    release = 'prison-releas',
    breakout = 'prison-break',
    items = 'prison-items',
}

local function write(logicalKey, payload)
    if not isEnabled() or not typeAllowed(logicalKey) then return false end
    local channel = CHANNEL[logicalKey] or logicalKey
    return exports['kodebykarl-logs']:Log(channel, payload)
end

local function offlineBlock(name, identifier)
    local lines = {
        ('Name: %s'):format(name or 'Unknown'),
        'ID: `offline`',
    }
    if identifier and identifier ~= '' then
        lines[#lines + 1] = ('Identifier: `%s`'):format(identifier)
    end
    return table.concat(lines, '\n')
end

local function personBlock(src, name, identifier)
    if src and tonumber(src) and tonumber(src) > 0 then
        if not name and getCharName then
            name = getCharName(src)
        end
        if not identifier and getCharID then
            identifier = getCharID(src)
        end
        return ('Name: %s\nID: `%s`\nIdentifier: `%s`'):format(
            name or GetPlayerName(src) or 'Unknown',
            src,
            identifier or 'n/a'
        )
    end
    if not name and src and getCharName then
        name = getCharName(src)
    end
    if not identifier and src and getCharID then
        identifier = getCharID(src)
    end
    return offlineBlock(name or GetPlayerName(src or 0), identifier)
end

function PrisonLogs.Jail(data)
    data = data or {}
    local isUpdate = data.updated == true

    write('jail', {
        title = isUpdate and 'Jail Time Updated' or 'Player Jailed',
        player = data.src,
        playerLabel = 'Officer',
        color = isUpdate and 3447003 or 15105570,
        fields = {
            {
                name = 'Prisoner',
                value = personBlock(data.targetSrc, data.targetName, data.targetIdentifier),
                inline = false,
            },
            { name = 'Months', value = ('`%s`'):format(tostring(data.time or '?')), inline = true },
            { name = 'Method', value = ('`%s`'):format(data.method or 'jail'), inline = true },
        },
    })
end

function PrisonLogs.Release(data)
    data = data or {}

    write('release', {
        title = 'Player Released / Unjailed',
        player = data.src,
        playerLabel = 'Officer',
        color = 5763719,
        fields = {
            {
                name = 'Prisoner',
                value = personBlock(data.targetSrc, data.targetName, data.targetIdentifier),
                inline = false,
            },
            { name = 'Method', value = ('`%s`'):format(data.method or 'unjail'), inline = true },
        },
    })
end

function PrisonLogs.Breakout(data)
    data = data or {}

    write('breakout', {
        title = 'Prison Breakout',
        description = ('**%s** escaped prison.'):format(data.name or 'Unknown'),
        player = data.src,
        playerLabel = 'Prisoner',
        color = 15158332,
        fields = {},
    })
end

function PrisonLogs.Hack(data)
    data = data or {}

    write('breakout', {
        title = data.success and 'Prison Terminal Hacked' or 'Prison Terminal Hack Attempt',
        player = data.src,
        color = 15844367,
        fields = {
            { name = 'Terminal', value = ('`%s`'):format(tostring(data.terminal or '?')), inline = true },
            { name = 'State', value = data.success and '`Hacked`' or '`Busy / Attempt`', inline = true },
        },
    })
end

function PrisonLogs.Exploit(data)
    data = data or {}
    local name = data.name
    if not name and data.src and getCharName then
        name = getCharName(data.src)
    end

    write('breakout', {
        title = 'Prison Exploit Blocked',
        description = ('**%s** was dropped for a prison exploit.'):format(
            name or GetPlayerName(data.src or 0) or 'Unknown'
        ),
        player = data.src,
        color = 10038562,
        fields = {
            { name = 'Reason', value = ('```%s```'):format(tostring(data.reason or 'Unknown'):sub(1, 500)), inline = false },
        },
    })
end

function PrisonLogs.Items(data)
    data = data or {}
    local returning = data.action == 'return'

    write('items', {
        title = returning and 'Prison Items Returned' or 'Prison Items Confiscated',
        player = data.src,
        playerLabel = 'Prisoner',
        color = returning and 3066993 or 10181046,
        fields = {
            { name = 'Item Slots', value = ('`%s`'):format(tostring(data.count or '?')), inline = true },
            { name = 'Action', value = returning and '`Return`' or '`Confiscate`', inline = true },
        },
    })
end

CreateThread(function()
    Wait(2000)
    if isEnabled() then
        print(('^2%s^0 Using kodebykarl-logs → POLICE prison channels.'):format(PREFIX))
    else
        print(('^3%s^0 Disabled or kodebykarl-logs not started.'):format(PREFIX))
    end
end)
