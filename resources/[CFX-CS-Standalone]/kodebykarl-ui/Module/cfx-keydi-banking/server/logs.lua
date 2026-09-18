--[[
    cfx-keydi-banking Discord logs via kodebykarl-logs
    Channels: #withdraw #deposit #transfer #SOCIETY #RICHEST-PERSON
]]

BankingLogs = BankingLogs or {}

local ESX = exports['es_extended']:getSharedObject()
local PREFIX = '[cfx-keydi-banking:Logs]'

local function cfg()
    return ConfigBanking and ConfigBanking.Logs or nil
end

local function richestCfg()
    return ConfigBanking and ConfigBanking.Richest or nil
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

local function write(channel, payload)
    if not isEnabled() or not typeAllowed(channel) then return false end
    return exports['kodebykarl-logs']:Log(channel, payload)
end

local function offlinePlayerField(name, identifier)
    local lines = {
        ('Name: %s'):format(name or 'Unknown'),
        'ID: `offline`',
    }
    if identifier and identifier ~= '' then
        lines[#lines + 1] = ('Identifier: `%s`'):format(identifier)
    end
    return table.concat(lines, '\n')
end

---@param data table
function BankingLogs.Withdraw(data)
    data = data or {}
    write('withdraw', {
        title = 'Bank Withdrawal',
        player = data.src,
        fields = {
            { name = 'Amount', value = ('`%s`'):format(formatMoney(data.amount)), inline = true },
            { name = 'New Bank', value = ('`%s`'):format(formatMoney(data.bankBalance)), inline = true },
            { name = 'New Cash', value = ('`%s`'):format(formatMoney(data.cashBalance)), inline = true },
        },
    })
end

---@param data table
function BankingLogs.Deposit(data)
    data = data or {}
    write('deposit', {
        title = 'Bank Deposit',
        player = data.src,
        fields = {
            { name = 'Amount', value = ('`%s`'):format(formatMoney(data.amount)), inline = true },
            { name = 'New Bank', value = ('`%s`'):format(formatMoney(data.bankBalance)), inline = true },
            { name = 'New Cash', value = ('`%s`'):format(formatMoney(data.cashBalance)), inline = true },
        },
    })
end

---@param data table
function BankingLogs.Transfer(data)
    data = data or {}
    local fields = {
        {
            name = 'Receiver',
            value = (data.targetSrc and data.targetSrc > 0)
                and nil
                or offlinePlayerField(data.targetName, data.targetIdentifier),
            inline = false,
        },
        { name = 'Amount', value = ('`%s`'):format(formatMoney(data.amount)), inline = true },
        { name = 'Method', value = ('`%s`'):format(data.method or 'n/a'), inline = true },
        { name = 'Offline', value = data.offline and '`Yes`' or '`No`', inline = true },
    }

    -- Prefer live receiver formatting when online
    if data.targetSrc and data.targetSrc > 0 then
        fields[1] = {
            name = 'Receiver',
            value = ('Name: %s\nID: `%s`\nIdentifier: `%s`'):format(
                data.targetName or 'Unknown',
                data.targetSrc,
                data.targetIdentifier or 'n/a'
            ),
            inline = false,
        }
    end

    write('transfer', {
        title = 'Bank Transfer',
        player = data.src,
        playerLabel = 'Sender',
        fields = fields,
    })
end

---@param data table
function BankingLogs.Society(data)
    data = data or {}
    local action = tostring(data.action or 'deposit'):lower()
    local title = action == 'withdraw' and 'Society Withdrawal' or 'Society Deposit'
    local fields = {
        { name = 'Society', value = ('`%s`'):format(data.societyLabel or data.society or 'n/a'), inline = true },
        { name = 'Action', value = ('`%s`'):format(action), inline = true },
        { name = 'Amount', value = ('`%s`'):format(formatMoney(data.amount)), inline = true },
        { name = 'Society Balance', value = ('`%s`'):format(formatMoney(data.societyBalance)), inline = true },
    }
    if data.note and data.note ~= '' then
        fields[#fields + 1] = { name = 'Note', value = tostring(data.note):sub(1, 200), inline = false }
    end

    local src = tonumber(data.src)
    if not src or src <= 0 then
        table.insert(fields, 1, {
            name = 'Player',
            value = offlinePlayerField(data.name, data.identifier),
            inline = false,
        })
        write('society', {
            title = title,
            fields = fields,
            thumbnail = false,
        })
        return
    end

    write('society', {
        title = title,
        player = src,
        fields = fields,
    })
end

--- Parse ESX users.accounts JSON into cash / bank / dirty
---@param accountsJson string|table|nil
---@return number cash, number bank, number dirty
local function parseAccounts(accountsJson)
    local accounts = accountsJson
    if type(accountsJson) == 'string' and accountsJson ~= '' then
        local ok, decoded = pcall(json.decode, accountsJson)
        if ok and type(decoded) == 'table' then
            accounts = decoded
        else
            accounts = {}
        end
    elseif type(accountsJson) ~= 'table' then
        accounts = {}
    end

    local cash = tonumber(accounts.money) or 0
    local bank = tonumber(accounts.bank) or 0
    local dirty = tonumber(accounts.black_money) or 0
    return cash, bank, dirty
end

---@param rows table
local function applyOnlineOverrides(rows)
    if not rows then return end
    local byId = {}
    for i = 1, #rows do
        byId[rows[i].identifier] = rows[i]
    end

    local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}
    for _, xPlayer in pairs(xPlayers) do
        local id = xPlayer.getIdentifier and xPlayer.getIdentifier() or xPlayer.identifier
        local row = byId[id]
        if row then
            local cash = xPlayer.getMoney and xPlayer.getMoney() or 0
            local bankAcc = xPlayer.getAccount and xPlayer.getAccount('bank')
            local dirtyAcc = xPlayer.getAccount and xPlayer.getAccount('black_money')
            local bank = bankAcc and bankAcc.money or 0
            local dirty = dirtyAcc and dirtyAcc.money or 0
            row.cash = cash
            row.bank = bank
            row.dirty = dirty
            row.total_money = cash + bank + dirty
            if xPlayer.getName then
                row.full_name = xPlayer.getName()
            end
        end
    end
end

---@param limit number|nil
---@return table
function BankingLogs.FetchRichestPlayers(limit)
    local rc = richestCfg() or {}
    local includeDirty = rc.IncludeDirtyMoney ~= false
    local top = tonumber(limit) or tonumber(rc.Top) or 10
    local onlyTop = rc.OnlyTop ~= false

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

    if onlyTop then
        sql = sql .. ' LIMIT ?'
    end

    local rows
    if onlyTop then
        rows = MySQL.query.await(sql, { top })
    else
        rows = MySQL.query.await(sql, {})
    end

    rows = rows or {}

    for i = 1, #rows do
        local row = rows[i]
        if (not row.cash and not row.bank) or (row.cash == nil and row.accounts) then
            local cash, bank, dirty = parseAccounts(row.accounts)
            row.cash = cash
            row.bank = bank
            row.dirty = dirty
            row.total_money = includeDirty and (cash + bank + dirty) or (cash + bank)
        end
        row.cash = tonumber(row.cash) or 0
        row.bank = tonumber(row.bank) or 0
        row.dirty = tonumber(row.dirty) or 0
        row.total_money = tonumber(row.total_money) or (row.cash + row.bank + (includeDirty and row.dirty or 0))
        if not row.full_name or row.full_name == '' then
            row.full_name = 'Unknown'
        end
    end

    applyOnlineOverrides(rows)

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

---@param msgType string|nil
---@param rows table|nil
local function buildRichestDescription(msgType, rows)
    rows = rows or {}
    msgType = msgType or 'standard'
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

---@param msgType string|nil
function BankingLogs.SendRichest(msgType)
    if not isEnabled() or not typeAllowed('richest') then return end

    local rc = richestCfg() or {}
    msgType = msgType or rc.LogMessageType or 'standard'
    local rows = BankingLogs.FetchRichestPlayers()
    local top = tonumber(rc.Top) or 10
    local title = (rc.OnlyTop ~= false)
        and ('Top %d Richest Players'):format(top)
        or 'All Players — Wealth Report'

    write('richest', {
        title = title,
        description = buildRichestDescription(msgType, rows),
        fields = {
            { name = 'Players Listed', value = ('`%d`'):format(#rows), inline = true },
            { name = 'Includes Dirty', value = (rc.IncludeDirtyMoney ~= false) and '`Yes`' or '`No`', inline = true },
            { name = 'Format', value = ('`%s`'):format(msgType), inline = true },
        },
        thumbnail = false,
    })
end

AddEventHandler('cfx-keydi-banking:logSociety', function(data)
    BankingLogs.Society(data)
end)

CreateThread(function()
    Wait(2000)
    if not isEnabled() then
        print(('^3%s^0 Disabled or kodebykarl-logs not started.'):format(PREFIX))
        return
    end

    print(('^2%s^0 Using kodebykarl-logs → ECONOMY channels.'):format(PREFIX))

    local rc = richestCfg()
    if not rc or not rc.Enabled then
        return
    end

    local minutes = tonumber(rc.IntervalMinutes) or 30
    local interval = math.max(1, minutes) * 60 * 1000
    print(('^2%s^0 Richest report every %d minute(s).'):format(PREFIX, minutes))

    while true do
        Wait(interval)
        BankingLogs.SendRichest(rc.LogMessageType)
    end
end)

CreateThread(function()
    Wait(2500)
    local rc = richestCfg()
    if not rc or not rc.AdminCommand or rc.AdminCommand == '' then return end

    local cmd = rc.AdminCommand
    ESX.RegisterCommand(cmd, 'admin', function()
        BankingLogs.SendRichest(rc.LogMessageType)
        print(('^2%s^0 Manual richest report sent via /%s'):format(PREFIX, cmd))
    end, true, { help = 'Send top richest players log to Discord' })
end)
