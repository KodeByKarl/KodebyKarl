--[[
    kodebykarl-ambulance Discord logs via kodebykarl-logs
    Channels: #ems-revive #ems-money #ems-bodybag #ems-bed #ems-sentry
]]

AmbulanceLogs = AmbulanceLogs or {}

local config = require 'shared.config'
local PREFIX = '[kodebykarl-ambulance:Logs]'

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

local CHANNEL = {
    revive = 'ems-revive',
    heal = 'ems-revive',
    money = 'ems-money',
    bodybag = 'ems-bodybag',
    bed = 'ems-bed',
    sentry = 'ems-sentry',
    bleedout = 'ems-sentry',
}

local function write(logicalKey, payload)
    if not isEnabled() or not typeAllowed(logicalKey) then return false end
    local channel = CHANNEL[logicalKey] or logicalKey
    return exports['kodebykarl-logs']:Log(channel, payload)
end

local function formatMoney(amount)
    amount = math.floor(tonumber(amount) or 0)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return ('$%s'):format(formatted)
end

local function formatCoords(coords)
    if not coords then return 'n/a' end
    if type(coords) == 'vector3' or type(coords) == 'vector4' then
        return ('%.2f, %.2f, %.2f'):format(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    end
    if type(coords) == 'table' and coords.x then
        return ('%.2f, %.2f, %.2f'):format(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    end
    return tostring(coords)
end

local function personBlock(src, name, identifier, extra)
    local lines = {
        ('Name: %s'):format(name or 'Unknown'),
    }
    if src and tonumber(src) and tonumber(src) > 0 then
        lines[#lines + 1] = ('ID: `%s`'):format(src)
    else
        lines[#lines + 1] = 'ID: `offline`'
    end
    if identifier and identifier ~= '' then
        lines[#lines + 1] = ('Identifier: `%s`'):format(identifier)
    end
    if extra and extra ~= '' then
        lines[#lines + 1] = extra
    end
    return table.concat(lines, '\n')
end

function AmbulanceLogs.FromPlayer(xPlayer)
    if not xPlayer then return 'Unknown', nil, nil end
    local src = xPlayer.source
    local name = xPlayer.name or (xPlayer.getName and xPlayer.getName()) or GetPlayerName(src) or 'Unknown'
    local identifier = xPlayer.identifier
    local job = xPlayer.job and (('%s — %s'):format(xPlayer.job.label or xPlayer.job.name, xPlayer.job.grade_label or tostring(xPlayer.job.grade or 0))) or nil
    return name, identifier, src, job
end

function AmbulanceLogs.Revive(data)
    data = data or {}
    write('revive', {
        title = 'EMS Revive',
        player = data.src,
        playerLabel = 'Medic',
        color = 5763719,
        fields = {
            {
                name = 'Patient',
                value = personBlock(data.targetSrc, data.targetName, data.targetIdentifier),
                inline = false,
            },
            { name = 'Item Used', value = ('`%sx %s`'):format(tostring(data.requireAmount or 1), tostring(data.requireItem or '?')), inline = true },
            { name = 'Reward', value = ('`%sx %s`'):format(tostring(data.rewardAmount or 0), tostring(data.rewardItem or 'money')), inline = true },
            { name = 'Recovery', value = ('`%ss`'):format(tostring(data.recovery or 120)), inline = true },
            { name = 'Medic Coords', value = ('`%s`'):format(formatCoords(data.coords)), inline = false },
            { name = 'Patient Coords', value = ('`%s`'):format(formatCoords(data.targetCoords)), inline = false },
        },
        coords = false,
    })
end

function AmbulanceLogs.Heal(data)
    data = data or {}
    write('heal', {
        title = 'EMS Heal',
        player = data.src,
        playerLabel = 'Medic',
        color = 3066993,
        fields = {
            {
                name = 'Patient',
                value = personBlock(data.targetSrc, data.targetName, data.targetIdentifier),
                inline = false,
            },
            { name = 'Item Used', value = ('`%sx %s`'):format(tostring(data.requireAmount or 1), tostring(data.requireItem or '?')), inline = true },
            { name = 'Reward', value = ('`%sx %s`'):format(tostring(data.rewardAmount or 0), tostring(data.rewardItem or 'money')), inline = true },
            { name = 'Medic Coords', value = ('`%s`'):format(formatCoords(data.coords)), inline = false },
            { name = 'Patient Coords', value = ('`%s`'):format(formatCoords(data.targetCoords)), inline = false },
        },
        coords = false,
    })
end

function AmbulanceLogs.CheckIn(data)
    data = data or {}
    write('money', {
        title = 'Hospital Check-In',
        player = data.src,
        playerLabel = 'Patient',
        color = 3447003,
        fields = {
            { name = 'Price', value = ('`%s`'):format(formatMoney(data.price)), inline = true },
            { name = 'Society', value = ('`%s`'):format(data.society or 'ambulance'), inline = true },
            { name = 'Location Index', value = ('`%s`'):format(tostring(data.index or '?')), inline = true },
            { name = 'Coords', value = ('`%s`'):format(formatCoords(data.coords)), inline = false },
        },
        coords = false,
    })
end

function AmbulanceLogs.Fine(data)
    data = data or {}
    write('money', {
        title = 'Respawn / STL Fine',
        player = data.src,
        color = 15105570,
        fields = {
            { name = 'Fine', value = ('`%s`'):format(formatMoney(data.amount)), inline = true },
            { name = 'Society', value = ('`%s`'):format(data.society or 'ambulance'), inline = true },
            { name = 'Paid', value = data.paid and '`Yes`' or '`No (insufficient funds)`', inline = true },
        },
    })
end

function AmbulanceLogs.Bodybag(data)
    data = data or {}
    write('bodybag', {
        title = 'Bodybag — Declared Dead',
        description = ('**%s** was placed in a bodybag by EMS.'):format(data.targetName or 'Unknown'),
        player = data.src,
        playerLabel = 'Medic',
        color = 10038562,
        fields = {
            {
                name = 'Deceased',
                value = personBlock(data.targetSrc, data.targetName, data.targetIdentifier),
                inline = false,
            },
            { name = 'Medic Coords', value = ('`%s`'):format(formatCoords(data.coords)), inline = false },
            { name = 'Target Coords', value = ('`%s`'):format(formatCoords(data.targetCoords)), inline = false },
            { name = 'Distance', value = ('`%sm`'):format(tostring(data.distance or '?')), inline = true },
        },
        coords = false,
    })
end

function AmbulanceLogs.BedAdmit(data)
    data = data or {}
    write('bed', {
        title = 'Hospital Bed Admit',
        player = data.src,
        playerLabel = 'Medic',
        color = 10181046,
        fields = {
            {
                name = 'Patient',
                value = personBlock(data.targetSrc, data.targetName, data.targetIdentifier),
                inline = false,
            },
            { name = 'Bed #', value = ('`%s`'):format(tostring(data.bedIndex or '?')), inline = true },
            { name = 'Hospital', value = ('`%s`'):format(data.hospital or '?'), inline = true },
            { name = 'Duration', value = ('`%s`'):format(tostring(data.time or '?')), inline = true },
            { name = 'Reason', value = tostring(data.reason or '—'):sub(1, 200), inline = false },
        },
    })
end

function AmbulanceLogs.Unbed(data)
    data = data or {}
    write('bed', {
        title = 'Hospital Unbed',
        player = data.src,
        playerLabel = 'Medic',
        color = 15844367,
        fields = {
            {
                name = 'Patient',
                value = personBlock(data.targetSrc, data.targetName, data.targetIdentifier),
                inline = false,
            },
            { name = 'Bed #', value = ('`%s`'):format(tostring(data.bedIndex or '?')), inline = true },
            { name = 'Hospital', value = ('`%s`'):format(data.hospital or '?'), inline = true },
        },
    })
end

function AmbulanceLogs.Bleedout(data)
    data = data or {}
    write('bleedout', {
        title = 'Bleedout — Inventory Wiped',
        description = ('**%s** bled out. Inventory cleared.'):format(data.name or 'Unknown'),
        player = data.src,
        color = 15158332,
        fields = {
            { name = 'Coords', value = ('`%s`'):format(formatCoords(data.coords)), inline = false },
            { name = 'Items Cleared', value = ('`%s` slots'):format(tostring(data.itemCount or '?')), inline = true },
        },
        coords = false,
    })
end

function AmbulanceLogs.Sentry(data)
    data = data or {}
    write('sentry', {
        title = ('EMS Validation Failed — %s'):format(tostring(data.system or 'Unknown')),
        player = data.src,
        playerLabel = 'Medic',
        color = 15158332,
        fields = {
            {
                name = 'Target',
                value = data.targetSrc
                    and personBlock(data.targetSrc, data.targetName, data.targetIdentifier)
                    or '`n/a`',
                inline = false,
            },
            { name = 'Reason', value = ('```%s```'):format(tostring(data.reason or 'Unknown'):sub(1, 400)), inline = false },
            { name = 'Medic Coords', value = ('`%s`'):format(formatCoords(data.coords)), inline = true },
            { name = 'Target Coords', value = ('`%s`'):format(formatCoords(data.targetCoords)), inline = true },
        },
        coords = false,
    })
end

CreateThread(function()
    Wait(2000)
    if isEnabled() then
        print(('^2%s^0 Using kodebykarl-logs → AMBULANCE channels.'):format(PREFIX))
    else
        print(('^3%s^0 Disabled or kodebykarl-logs not started.'):format(PREFIX))
    end
end)
