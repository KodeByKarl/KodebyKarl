local ESX = exports['es_extended']:getSharedObject()

local cache = {} -- [accountName] = balance (number)

local function Debug(msg)
    if Config.Debug then
        print(('[cfx-keydi-society] %s'):format(msg))
    end
end

local isReady = false

local function EnsureTables()
    if isReady then return end
    local ok1 = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `cfx_society_accounts` (
                `name` VARCHAR(64) NOT NULL,
                `label` VARCHAR(64) NOT NULL,
                `balance` BIGINT NOT NULL DEFAULT 0,
                `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`name`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)

    local ok2 = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `cfx_society_ledger` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `account` VARCHAR(64) NOT NULL,
                `action` VARCHAR(16) NOT NULL,
                `amount` BIGINT NOT NULL,
                `balance_after` BIGINT NOT NULL,
                `identifier` VARCHAR(64) DEFAULT NULL,
                `note` VARCHAR(255) DEFAULT NULL,
                `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                KEY `account` (`account`),
                KEY `created_at` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)

    if ok1 and ok2 then
        isReady = true
    end
end

local function WaitForReady()
    if isReady then return end
    EnsureTables()
end

local function LoadCache()
    cache = {}
    local ok, rows = pcall(function()
        return MySQL.query.await('SELECT name, balance FROM cfx_society_accounts') or {}
    end)
    if ok and rows then
        for i = 1, #rows do
            cache[rows[i].name] = tonumber(rows[i].balance) or 0
        end
        Debug(('Loaded %s society accounts'):format(#rows))
    end
end

local function SeedAccounts()
    for i = 1, #(Config.Accounts or {}) do
        local acc = Config.Accounts[i]
        if acc and acc.name then
            local exists = false
            pcall(function()
                exists = MySQL.scalar.await(
                    'SELECT 1 FROM cfx_society_accounts WHERE name = ? LIMIT 1',
                    { acc.name }
                )
            end)
            if not exists then
                local startBal = math.floor(tonumber(acc.startingBalance) or 0)
                pcall(function()
                    MySQL.insert.await(
                        'INSERT INTO cfx_society_accounts (name, label, balance) VALUES (?, ?, ?)',
                        { acc.name, acc.label or acc.name, startBal }
                    )
                end)
                cache[acc.name] = startBal
                Debug(('Created account %s (%s)'):format(acc.name, startBal))
            end
        end
    end
end

local function WriteLedger(account, action, amount, balanceAfter, identifier, note)
    if not Config.EnableLedger then return end
    MySQL.insert.await(
        'INSERT INTO cfx_society_ledger (account, action, amount, balance_after, identifier, note) VALUES (?, ?, ?, ?, ?, ?)',
        { account, action, amount, balanceAfter, identifier, note }
    )
end

local function ResolveAccount(nameOrJob)
    if not nameOrJob or nameOrJob == '' then return nil end
    if cache[nameOrJob] ~= nil then return nameOrJob end
    if Config.JobAccounts and Config.JobAccounts[nameOrJob] then
        return Config.JobAccounts[nameOrJob]
    end
    if Config.GangAccounts and Config.GangAccounts[nameOrJob] then
        return Config.GangAccounts[nameOrJob]
    end
    -- Allow shorthand: "police" → "society_police"
    local societyName = ('society_%s'):format(nameOrJob)
    if cache[societyName] ~= nil then return societyName end
    return nameOrJob
end

--- Ensure an account row exists (creates with 0 if missing).
---@param account string
---@param label? string
---@return boolean
local function EnsureAccount(account, label)
    account = ResolveAccount(account)
    if not account then return false end
    if cache[account] ~= nil then return true end

    WaitForReady()

    local row
    pcall(function()
        row = MySQL.single.await(
            'SELECT name, balance FROM cfx_society_accounts WHERE name = ? LIMIT 1',
            { account }
        )
    end)

    if row then
        cache[account] = tonumber(row.balance) or 0
        return true
    end

    pcall(function()
        MySQL.insert.await(
            'INSERT INTO cfx_society_accounts (name, label, balance) VALUES (?, ?, 0)',
            { account, label or account, 0 }
        )
    end)
    cache[account] = 0
    return true
end

---@param account string
---@return number
local function GetBalance(account)
    account = ResolveAccount(account)
    if not account then return 0 end
    EnsureAccount(account)
    if cache[account] ~= nil then
        return cache[account]
    end
    local bal = MySQL.scalar.await(
        'SELECT balance FROM cfx_society_accounts WHERE name = ? LIMIT 1',
        { account }
    )
    bal = tonumber(bal) or 0
    cache[account] = bal
    return bal
end

---@param account string
---@param amount number
---@param identifier? string
---@param note? string
---@return boolean, number|string
local function AddMoney(account, amount, identifier, note)
    account = ResolveAccount(account)
    amount = math.floor(tonumber(amount) or 0)
    if not account or amount <= 0 then
        return false, 'invalid'
    end
    EnsureAccount(account)

    local affected = MySQL.update.await(
        'UPDATE cfx_society_accounts SET balance = balance + ? WHERE name = ?',
        { amount, account }
    )
    if not affected or affected < 1 then
        return false, 'db_failed'
    end

    local dbBal = MySQL.scalar.await(
        'SELECT balance FROM cfx_society_accounts WHERE name = ? LIMIT 1',
        { account }
    )
    local newBal = tonumber(dbBal) or ((cache[account] or 0) + amount)
    cache[account] = newBal
    WriteLedger(account, 'deposit', amount, newBal, identifier, note)
    Debug(('+%s → %s (balance %s)'):format(amount, account, newBal))

    local src, name
    if identifier and identifier ~= '' then
        local xPlayer = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            src = xPlayer.source
            name = xPlayer.getName and xPlayer.getName() or xPlayer.name
        end
    end
    TriggerEvent('cfx-keydi-banking:logSociety', {
        src = src,
        name = name,
        identifier = identifier,
        society = account,
        societyLabel = account,
        action = 'deposit',
        amount = amount,
        societyBalance = newBal,
        note = note,
    })

    return true, newBal
end

---@param account string
---@param amount number
---@param identifier? string
---@param note? string
---@return boolean, number|string
local function RemoveMoney(account, amount, identifier, note)
    account = ResolveAccount(account)
    amount = math.floor(tonumber(amount) or 0)
    if not account or amount <= 0 then
        return false, 'invalid'
    end
    EnsureAccount(account)

    local current = GetBalance(account)
    if current < amount then
        return false, 'insufficient'
    end

    local affected = MySQL.update.await(
        'UPDATE cfx_society_accounts SET balance = balance - ? WHERE name = ? AND balance >= ?',
        { amount, account, amount }
    )
    if not affected or affected < 1 then
        return false, 'insufficient'
    end

    local dbBal = MySQL.scalar.await(
        'SELECT balance FROM cfx_society_accounts WHERE name = ? LIMIT 1',
        { account }
    )
    local newBal = tonumber(dbBal) or (current - amount)
    cache[account] = newBal
    WriteLedger(account, 'withdraw', amount, newBal, identifier, note)
    Debug(('-%s → %s (balance %s)'):format(amount, account, newBal))

    local src, name
    if identifier and identifier ~= '' then
        local xPlayer = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            src = xPlayer.source
            name = xPlayer.getName and xPlayer.getName() or xPlayer.name
        end
    end
    TriggerEvent('cfx-keydi-banking:logSociety', {
        src = src,
        name = name,
        identifier = identifier,
        society = account,
        societyLabel = account,
        action = 'withdraw',
        amount = amount,
        societyBalance = newBal,
        note = note,
    })

    return true, newBal
end

---@param account string
---@param amount number
---@return boolean, number|string
local function SetMoney(account, amount, identifier, note)
    account = ResolveAccount(account)
    amount = math.floor(tonumber(amount) or 0)
    if not account or amount < 0 then
        return false, 'invalid'
    end
    EnsureAccount(account)

    MySQL.update.await(
        'UPDATE cfx_society_accounts SET balance = ? WHERE name = ?',
        { amount, account }
    )
    cache[account] = amount
    WriteLedger(account, 'set', amount, amount, identifier, note)
    return true, amount
end

---@param account string
---@param limit? number
---@return table
local function GetLedger(account, limit)
    account = ResolveAccount(account)
    if not account then return {} end
    limit = math.min(math.floor(tonumber(limit) or Config.LedgerLimit or 50), 200)
    return MySQL.query.await(
        'SELECT id, account, action, amount, balance_after, identifier, note, created_at FROM cfx_society_ledger WHERE account = ? ORDER BY id DESC LIMIT ?',
        { account, limit }
    ) or {}
end

---@return table
local function GetAllAccounts()
    local rows = MySQL.query.await(
        'SELECT name, label, balance, updated_at FROM cfx_society_accounts ORDER BY label ASC'
    ) or {}
    for i = 1, #rows do
        rows[i].balance = tonumber(rows[i].balance) or 0
        cache[rows[i].name] = rows[i].balance
    end
    return rows
end

local function AccountForJob(jobName)
    if not jobName then return nil end
    return Config.JobAccounts and Config.JobAccounts[jobName] or ResolveAccount(jobName)
end

local function AccountForGang(gangId)
    if not gangId then return nil end
    return Config.GangAccounts and Config.GangAccounts[gangId] or ResolveAccount(gangId)
end

CreateThread(function()
    EnsureTables()
    SeedAccounts()
    LoadCache()
    print('[cfx-keydi-society] Ready — society funds stored in database')
end)

---@param src number
---@param jobName? string
---@return boolean
local function IsSocietyBoss(src, jobName)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local job = xPlayer.getJob and xPlayer.getJob()
    if not job then return false end
    if jobName and jobName ~= '' and job.name ~= jobName then
        return false
    end
    local gradeName = job.grade_name or job.gradeName
    return type(gradeName) == 'string' and gradeName:lower() == 'boss'
end

-- Exports
exports('GetBalance', GetBalance)
exports('AddMoney', AddMoney)
exports('RemoveMoney', RemoveMoney)
exports('SetMoney', SetMoney)
exports('EnsureAccount', EnsureAccount)
exports('GetLedger', GetLedger)
exports('GetAllAccounts', GetAllAccounts)
exports('AccountForJob', AccountForJob)
exports('AccountForGang', AccountForGang)
exports('ResolveAccount', ResolveAccount)

-- Aliases used by invoice, garages, dealerships, mechanic (tgg-banking / qb-management names)
exports('AddSocietyMoney', AddMoney)
exports('RemoveSocietyMoney', RemoveMoney)
exports('GetSocietyMoney', GetBalance)
exports('GetMoney', GetBalance)
exports('IsSocietyBoss', IsSocietyBoss)

-- Optional ESX-style event bridges (other scripts may TriggerEvent these)
AddEventHandler('cfx-keydi-society:getBalance', function(account, cb)
    if cb then cb(GetBalance(account)) end
end)

RegisterNetEvent('cfx-keydi-society:server:getBalance', function(account)
    local src = source
    TriggerClientEvent('cfx-keydi-society:client:balance', src, account, GetBalance(account))
end)

lib.callback.register('cfx-keydi-society:getBalance', function(_, account)
    return GetBalance(account)
end)

lib.callback.register('cfx-keydi-society:getAll', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return {} end
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    if group ~= 'owner' and group ~= 'developer' and group ~= 'admin' then
        return {}
    end
    return GetAllAccounts()
end)
