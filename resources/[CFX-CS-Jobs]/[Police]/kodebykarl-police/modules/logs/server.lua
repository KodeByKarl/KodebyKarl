--[[
    kodebykarl-police Discord logs via kodebykarl-logs
    Channels: #police-license #police-docs #police-action
]]

PoliceLogs = PoliceLogs or {}

local PREFIX = '[kodebykarl-police:Logs]'

local function cfg()
    return Config and Config.Logs or nil
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
    license = 'police-license',
    docs = 'police-docs',
    action = 'police-action',
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

function PoliceLogs.FromSource(src)
    src = tonumber(src)
    local name = (src and src > 0) and (GetPlayerName(src) or 'Unknown') or 'Unknown'
    local identifier = nil
    if src and src > 0 and GetResourceState('es_extended') == 'started' then
        local ok, ESX = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok and ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                name = xPlayer.name or (xPlayer.getName and xPlayer.getName()) or name
                identifier = xPlayer.identifier
            end
        end
    end
    return name, identifier
end

local function targetField(data)
    if data.targetSrc and tonumber(data.targetSrc) and tonumber(data.targetSrc) > 0 then
        return {
            name = 'Target',
            value = ('Name: %s\nID: `%s`\nIdentifier: `%s`'):format(
                data.targetName or 'Unknown',
                data.targetSrc,
                data.targetIdentifier or 'n/a'
            ),
            inline = false,
        }
    end
    return {
        name = 'Target',
        value = offlineBlock(data.targetName, data.targetIdentifier),
        inline = false,
    }
end

function PoliceLogs.License(data)
    data = data or {}
    local granted = data.action == 'grant'
    local fields = {
        targetField(data),
        { name = 'License', value = ('`%s`'):format(tostring(data.license or '?')), inline = true },
        { name = 'Action', value = granted and '`Grant`' or '`Revoke`', inline = true },
        { name = 'Department', value = ('`%s`'):format(data.department or data.job or 'LEO'), inline = true },
    }

    write('license', {
        title = granted and 'License Granted' or 'License Revoked',
        player = data.src,
        playerLabel = 'Officer',
        color = granted and 5763719 or 15158332,
        fields = fields,
    })
end

function PoliceLogs.Document(data)
    data = data or {}
    local fields = {
        {
            name = 'Target',
            value = data.targetSrc
                and ('Name: %s\nID: `%s`\nIdentifier: `%s`'):format(
                    data.targetName or 'Unknown',
                    data.targetSrc,
                    data.targetIdentifier or 'n/a'
                )
                or '`self`',
            inline = false,
        },
        { name = 'Document', value = ('`%s`'):format(tostring(data.docName or 'Unknown'):sub(1, 100)), inline = true },
        { name = 'Action', value = ('`%s`'):format(data.action or 'create'), inline = true },
        { name = 'Department', value = ('`%s`'):format(data.department or data.job or 'LEO'), inline = true },
    }

    write('docs', {
        title = data.action == 'give' and 'Document Copy Given' or 'Document Created',
        player = data.src,
        playerLabel = 'Officer',
        color = 3447003,
        fields = fields,
    })
end

function PoliceLogs.Action(data)
    data = data or {}
    local kind = tostring(data.kind or 'action')
    local colorMap = {
        search = 10181046,
        id = 3066993,
        cuff = 15105570,
        uncuff = 5763719,
        gsr = 15844367,
        priority = 15105570,
    }
    local titles = {
        search = 'Player Search',
        id = 'ID Check',
        cuff = 'Suspect Cuffed',
        uncuff = 'Suspect Uncuffed',
        gsr = 'GSR Test',
        priority = 'Priority Status',
    }

    local fields = {}
    if data.targetSrc or data.targetName then
        fields[#fields + 1] = targetField(data)
    end
    if data.detail then
        fields[#fields + 1] = { name = 'Detail', value = tostring(data.detail):sub(1, 300), inline = false }
    end
    fields[#fields + 1] = {
        name = 'Department',
        value = ('`%s`'):format(data.department or data.job or 'LEO'),
        inline = true,
    }

    write('action', {
        title = titles[kind] or 'Police Action',
        player = data.src,
        playerLabel = 'Officer',
        color = colorMap[kind] or 9807270,
        fields = fields,
    })
end

CreateThread(function()
    Wait(2000)
    if isEnabled() then
        print(('^2%s^0 Using kodebykarl-logs → POLICE channels.'):format(PREFIX))
    else
        print(('^3%s^0 Disabled or kodebykarl-logs not started.'):format(PREFIX))
    end
end)
