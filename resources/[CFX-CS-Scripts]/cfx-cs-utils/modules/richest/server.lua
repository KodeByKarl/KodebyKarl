--[[
  Richest player logger for Grim City.
  Sends the #1 richest account to Discord (webhook first, kodebykarl-logs fallback).
]]

local Config = require 'configs.richest'

if not Config or not Config.Enabled then return end

local PREFIX = '[cfx-keydi-utils:richest]'
local busy = false

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

local function parseAccounts(raw)
    local cash, bank, dirty = 0, 0, 0
    if type(raw) == 'string' and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            cash = tonumber(decoded.money) or 0
            bank = tonumber(decoded.bank) or 0
            dirty = tonumber(decoded.black_money) or 0
        end
    elseif type(raw) == 'table' then
        cash = tonumber(raw.money) or 0
        bank = tonumber(raw.bank) or 0
        dirty = tonumber(raw.black_money) or 0
    end
    return cash, bank, dirty
end

local function playerName(xPlayer, fallback)
    if xPlayer and xPlayer.getName then
        local name = xPlayer.getName()
        if type(name) == 'string' and name ~= '' then
            return name
        end
    end
    return fallback or 'Unknown'
end

local function applyOnlineOverrides(rows, includeDirty)
    local byId = {}
    for i = 1, #rows do
        byId[rows[i].identifier] = rows[i]
    end

    local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}
    for _, xPlayer in pairs(xPlayers) do
        local identifier = xPlayer.getIdentifier and xPlayer.getIdentifier() or xPlayer.identifier
        if identifier then
            local cashAcc = xPlayer.getAccount and xPlayer.getAccount('money')
            local bankAcc = xPlayer.getAccount and xPlayer.getAccount('bank')
            local dirtyAcc = xPlayer.getAccount and xPlayer.getAccount('black_money')
            local cash = cashAcc and tonumber(cashAcc.money) or (xPlayer.getMoney and xPlayer.getMoney()) or 0
            local bank = bankAcc and tonumber(bankAcc.money) or 0
            local dirty = dirtyAcc and tonumber(dirtyAcc.money) or 0
            local total = includeDirty and (cash + bank + dirty) or (cash + bank)
            local row = byId[identifier]
            if row then
                row.cash, row.bank, row.dirty, row.total_money = cash, bank, dirty, total
                row.full_name = playerName(xPlayer, row.full_name)
                row.online = true
            else
                local added = {
                    identifier = identifier,
                    full_name = playerName(xPlayer, 'Unknown'),
                    cash = cash,
                    bank = bank,
                    dirty = dirty,
                    total_money = total,
                    online = true,
                }
                rows[#rows + 1] = added
                byId[identifier] = added
            end
        end
    end
end

local function normalizeRows(rows, includeDirty)
    for i = 1, #rows do
        local row = rows[i]
        if row.cash == nil and row.accounts then
            local cash, bank, dirty = parseAccounts(row.accounts)
            row.cash, row.bank, row.dirty = cash, bank, dirty
        end
        row.cash = tonumber(row.cash) or 0
        row.bank = tonumber(row.bank) or 0
        row.dirty = tonumber(row.dirty) or 0
        row.total_money = tonumber(row.total_money)
            or (row.cash + row.bank + (includeDirty and row.dirty or 0))
        if not row.full_name or row.full_name == '' then
            row.full_name = 'Unknown'
        end
    end
end

local function fetchPlayersLua()
    local includeDirty = Config.BlackMoney ~= false
    local rows = MySQL.query.await([[
        SELECT
            `identifier`,
            `accounts`,
            TRIM(CONCAT(COALESCE(`firstname`, ''), ' ', COALESCE(`lastname`, ''))) AS `full_name`
        FROM `users`
    ]]) or {}

    normalizeRows(rows, includeDirty)
    applyOnlineOverrides(rows, includeDirty)

    table.sort(rows, function(a, b)
        return (a.total_money or 0) > (b.total_money or 0)
    end)

    local onlyTop = Config.OnlyTopRichest and Config.OnlyTopRichest.enable ~= false
    local top = math.max(1, tonumber(Config.OnlyTopRichest and Config.OnlyTopRichest.top) or 10)
    if onlyTop and #rows > top then
        local trimmed = {}
        for i = 1, top do
            trimmed[i] = rows[i]
        end
        rows = trimmed
    end

    return rows
end

local function fetchPlayers()
    local includeDirty = Config.BlackMoney ~= false
    local onlyTop = Config.OnlyTopRichest and Config.OnlyTopRichest.enable ~= false
    local top = math.max(1, tonumber(Config.OnlyTopRichest and Config.OnlyTopRichest.top) or 10)

    local sql
    if includeDirty then
        sql = [[
            SELECT
                `identifier`,
                `accounts`,
                TRIM(CONCAT(COALESCE(`firstname`, ''), ' ', COALESCE(`lastname`, ''))) AS `full_name`,
                CAST(COALESCE(JSON_VALUE(`accounts`, '$.money'), 0) AS SIGNED) AS `cash`,
                CAST(COALESCE(JSON_VALUE(`accounts`, '$.bank'), 0) AS SIGNED) AS `bank`,
                CAST(COALESCE(JSON_VALUE(`accounts`, '$.black_money'), 0) AS SIGNED) AS `dirty`,
                (
                    CAST(COALESCE(JSON_VALUE(`accounts`, '$.money'), 0) AS SIGNED)
                    + CAST(COALESCE(JSON_VALUE(`accounts`, '$.bank'), 0) AS SIGNED)
                    + CAST(COALESCE(JSON_VALUE(`accounts`, '$.black_money'), 0) AS SIGNED)
                ) AS `total_money`
            FROM `users`
            ORDER BY `total_money` DESC
        ]]
    else
        sql = [[
            SELECT
                `identifier`,
                `accounts`,
                TRIM(CONCAT(COALESCE(`firstname`, ''), ' ', COALESCE(`lastname`, ''))) AS `full_name`,
                CAST(COALESCE(JSON_VALUE(`accounts`, '$.money'), 0) AS SIGNED) AS `cash`,
                CAST(COALESCE(JSON_VALUE(`accounts`, '$.bank'), 0) AS SIGNED) AS `bank`,
                CAST(COALESCE(JSON_VALUE(`accounts`, '$.black_money'), 0) AS SIGNED) AS `dirty`,
                (
                    CAST(COALESCE(JSON_VALUE(`accounts`, '$.money'), 0) AS SIGNED)
                    + CAST(COALESCE(JSON_VALUE(`accounts`, '$.bank'), 0) AS SIGNED)
                ) AS `total_money`
            FROM `users`
            ORDER BY `total_money` DESC
        ]]
    end

    local ok, rows = pcall(function()
        if onlyTop then
            return MySQL.query.await(sql .. ' LIMIT ?', { math.max(top, 50) }) or {}
        end
        return MySQL.query.await(sql, {}) or {}
    end)

    if not ok or type(rows) ~= 'table' then
        print(('^3%s^0 JSON_VALUE ranking failed, using Lua fallback.'):format(PREFIX))
        return fetchPlayersLua()
    end

    normalizeRows(rows, includeDirty)
    applyOnlineOverrides(rows, includeDirty)

    table.sort(rows, function(a, b)
        return (a.total_money or 0) > (b.total_money or 0)
    end)

    if onlyTop and #rows > top then
        local trimmed = {}
        for i = 1, top do
            trimmed[i] = rows[i]
        end
        rows = trimmed
    end

    return rows
end

local function buildLeaderboard(msgType, rows)
    rows = rows or {}
    msgType = msgType or Config.LogMessageType or 'standard'
    local lines = {}

    for i = 1, #rows do
        local row = rows[i]
        local name = row.full_name or 'Unknown'
        local total = formatMoney(row.total_money)
        local cash = formatMoney(row.cash)
        local bank = formatMoney(row.bank)
        local dirty = formatMoney(row.dirty)

        if msgType == 'full' then
            lines[#lines + 1] = ('`%d.` **%s**\nIdentifier: `%s`\nCash: `%s` · Bank: `%s` · Dirty: `%s` · **Total: %s**')
                :format(i, name, row.identifier or 'n/a', cash, bank, dirty, total)
        elseif msgType == 'short' then
            lines[#lines + 1] = ('`%d.` %s — **%s**'):format(i, name, total)
        else
            lines[#lines + 1] = ('`%d.` **%s** — Cash `%s` · Bank `%s` · Dirty `%s` · **Total %s**')
                :format(i, name, cash, bank, dirty, total)
        end
    end

    if #lines == 0 then
        return '_No players found in database._'
    end

    local text = table.concat(lines, '\n')
    if #text > 4000 then
        text = text:sub(1, 3990) .. '\n…'
    end
    return text
end

local function sendWebhook(embed)
    local url = Config.WebHook
    if type(url) ~= 'string' or url == '' or url:find('YOUR_', 1, true) then
        return false
    end

    PerformHttpRequest(url, function(status, body)
        status = tonumber(status) or 0
        if status ~= 204 and status ~= 200 then
            print(('^1%s^0 Discord webhook failed (HTTP %s): %s'):format(PREFIX, status, tostring(body or ''):sub(1, 200)))
        end
    end, 'POST', json.encode({
        username = Config.ServerName or 'Grim City',
        embeds = { embed },
    }), { ['Content-Type'] = 'application/json' })
    return true
end

local function sendReport(msgType)
    if busy then return end
    busy = true

    local ok, err = pcall(function()
        local rows = fetchPlayers()
        local richest = rows[1]
        local onlyTop = Config.OnlyTopRichest and Config.OnlyTopRichest.enable ~= false
        local top = math.max(1, tonumber(Config.OnlyTopRichest and Config.OnlyTopRichest.top) or 10)
        local time = os.date('*t')
        local footer = ('%04d/%02d/%02d %02d:%02d'):format(time.year, time.month, time.day, time.hour, time.min)

        local embed
        if richest then
            local listTitle = onlyTop and ('**Top %d**'):format(top) or '**Leaderboard**'
            embed = {
                color = tonumber(Config.LogColour) or 10181046,
                author = {
                    name = Config.ServerName or 'Grim City',
                    icon_url = (Config.AvatarURL ~= '' and Config.AvatarURL) or nil,
                },
                title = Config.LogTitle or 'Richest Player',
                description = ('**%s** is currently the richest player.\nIdentifier: `%s`%s\n\n%s\n%s')
                    :format(
                        richest.full_name or 'Unknown',
                        richest.identifier or 'n/a',
                        richest.online and '\nStatus: `Online`' or '\nStatus: `Offline`',
                        listTitle,
                        buildLeaderboard(msgType, rows)
                    ),
                fields = {
                    { name = 'Total', value = ('`%s`'):format(formatMoney(richest.total_money)), inline = true },
                    { name = 'Cash', value = ('`%s`'):format(formatMoney(richest.cash)), inline = true },
                    { name = 'Bank', value = ('`%s`'):format(formatMoney(richest.bank)), inline = true },
                    { name = 'Dirty', value = ('`%s`'):format(formatMoney(richest.dirty)), inline = true },
                },
                footer = { text = footer },
            }
        else
            embed = {
                color = tonumber(Config.LogColour) or 10181046,
                title = Config.LogTitle or 'Richest Player',
                description = '_No players found in database._',
                footer = { text = footer },
            }
        end

        local logged = sendWebhook(embed)

        if not logged and GetResourceState('kodebykarl-logs') == 'started' then
            local success = pcall(function()
                exports['kodebykarl-logs']:Log(Config.LogsChannel or 'richest', {
                    title = embed.title,
                    description = embed.description,
                    color = embed.color,
                    thumbnail = false,
                    fields = embed.fields,
                })
            end)
            logged = success == true
        end


    end)

    if not ok then
        print(('^1%s^0 Failed to send richest report: %s'):format(PREFIX, tostring(err)))
    end

    busy = false
end

CreateThread(function()
    Wait(5000)

    local cmd = Config.AdminCommand or 'topmoney'
    ESX.RegisterCommand(cmd, 'admin', function()
        sendReport(Config.LogMessageType)
    end, true, { help = 'Send richest player log to Discord' })

    if Config.SendOnStart ~= false then
        sendReport(Config.LogMessageType)
    end

    local auto = Config.SendLogByTime
    if not auto or auto.enable == false then return end

    local minutes = math.max(1, tonumber(auto.time) or 60)

    while true do
        Wait(minutes * 60 * 1000)
        sendReport(Config.LogMessageType)
    end
end)

exports('SendRichestReport', function(msgType)
    sendReport(msgType or Config.LogMessageType)
end)

exports('FetchRichestPlayers', function()
    return fetchPlayers()
end)
