local ESX = exports["es_extended"]:getSharedObject()

-- Format identifiers to a consistent account number formatted as XXX-XX-XXXX
local function GetAccountNumber(identifier)
    local hash = 0
    for i = 1, #identifier do
        hash = (hash * 31 + string.byte(identifier, i)) % 1000000000
    end
    local s = string.format("%09d", hash)
    return s:sub(1,3) .. "-" .. s:sub(4,5) .. "-" .. s:sub(6,9)
end

-- Insert transaction logs
local function AddTransaction(identifier, type, label, amount)
    local txnId = ("TXN-%d-%d"):format(math.random(100000000, 999999999), math.random(100000, 999999))
    local dateStr = os.date("%Y-%m-%d %H:%M:%S")
    MySQL.update([[
        INSERT INTO `cfx-keydi-transactions` (identifier, type, label, amount, date, txnId)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { identifier, type, label, amount, dateStr, txnId })
end

-- Fetch transactions
local function GetTransactions(identifier, cb)
    MySQL.query('SELECT type, label, amount, date, txnId FROM `cfx-keydi-transactions` WHERE identifier = ? ORDER BY id DESC LIMIT ?', {
        identifier, ConfigBanking.MaxTransactionsStored
    }, function(results)
        local list = {}
        if results then
            for _, row in ipairs(results) do
                table.insert(list, {
                    type = row.type,
                    label = row.label,
                    amount = row.amount,
                    date = row.date,
                    id = row.txnId
                })
            end
        end
        cb(list)
    end)
end

-- Always compare/store PIN as a 4-digit string (oxmysql may return 1234 or 0 for "1234"/"0000")
local function NormalizePin(pin, pad)
    if pin == nil then return nil end
    local s = tostring(pin):gsub("[^0-9]", "")
    if s == "" then return nil end
    if pad and #s < 4 then
        s = string.rep("0", 4 - #s) .. s
    end
    if #s ~= 4 then return nil end
    return s
end

-- Fetch PIN code. Missing row = default 1234 (do not INSERT here; that raced with first-time setup).
local function GetPlayerPin(identifier, cb)
    MySQL.single('SELECT pin FROM `cfx-keydi-banking-pins` WHERE identifier = ?', { identifier }, function(row)
        if row and row.pin ~= nil then
            cb(NormalizePin(row.pin, true) or "1234")
        else
            cb("1234")
        end
    end)
end

-- Assemble full state packet for banking UI
local function BuildBankingData(xPlayer, cb)
    local identifier = xPlayer.getIdentifier()
    MySQL.single('SELECT firstname, lastname FROM users WHERE identifier = ?', { identifier }, function(user)
        local name = nil
        if user then
            local first = user.firstname
            local last = user.lastname
            if type(first) == 'string' and first ~= '' and type(last) == 'string' and last ~= '' then
                name = first .. ' ' .. last
            elseif type(first) == 'string' and first ~= '' then
                name = first
            elseif type(last) == 'string' and last ~= '' then
                name = last
            end
        end

        if not name or name == '' then
            name = (xPlayer.getName and xPlayer.getName()) or xPlayer.name or 'Unknown'
        end

        local cash = xPlayer.getMoney()
        local bank = xPlayer.getAccount('bank').money
        local accNum = GetAccountNumber(identifier)

        GetTransactions(identifier, function(txs)
            cb({
                playerName = name,
                accountNumber = accNum,
                bankBalance = bank,
                cashBalance = cash,
                transactions = txs
            })
        end)
    end)
end

-- Setup database tables on startup
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `cfx-keydi-transactions` (
            `id` INT AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `type` VARCHAR(20) NOT NULL,
            `label` VARCHAR(100) NOT NULL,
            `amount` INT NOT NULL,
            `date` VARCHAR(30) NOT NULL,
            `txnId` VARCHAR(50) NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
    end)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `cfx-keydi-banking-pins` (
            `identifier` VARCHAR(60) NOT NULL,
            `pin` VARCHAR(4) NOT NULL DEFAULT '1234',
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
    end)
end)

-- CALLBACKS

ESX.RegisterServerCallback("cfx-keydi-banking:getBankingData", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(nil)
        return
    end
    BuildBankingData(xPlayer, cb)
end)

ESX.RegisterServerCallback("cfx-keydi-banking:verifyPin", function(source, cb, enteredPin)
    local xPlayer = ESX.GetPlayerFromId(source)
    local pin = NormalizePin(enteredPin, false)
    if not xPlayer or not pin then
        cb(false)
        return
    end

    GetPlayerPin(xPlayer.getIdentifier(), function(actualPin)
        cb(actualPin == pin)
    end)
end)

ESX.RegisterServerCallback("cfx-keydi-banking:changePin", function(source, cb, newPin)
    local xPlayer = ESX.GetPlayerFromId(source)
    local pin = NormalizePin(newPin, false)
    if not xPlayer or not pin then
        cb(false)
        return
    end

    local identifier = xPlayer.getIdentifier()
    MySQL.update([[
        INSERT INTO `cfx-keydi-banking-pins` (identifier, pin)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE pin = ?
    ]], { identifier, pin, pin }, function()
        cb(true)
    end)
end)

ESX.RegisterServerCallback("cfx-keydi-banking:depositMoney", function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not amount or amount <= 0 then
        cb(false)
        return
    end

    if xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
        xPlayer.addAccountMoney('bank', amount)
        AddTransaction(xPlayer.getIdentifier(), "deposit", "Cash deposit", amount)

        if BankingLogs and BankingLogs.Deposit then
            BankingLogs.Deposit({
                src = source,
                name = xPlayer.getName and xPlayer.getName() or xPlayer.name,
                identifier = xPlayer.getIdentifier(),
                amount = amount,
                bankBalance = xPlayer.getAccount('bank').money,
                cashBalance = xPlayer.getMoney(),
            })
        end

        -- Build updated data
        BuildBankingData(xPlayer, function(updated)
            cb(true, updated)
        end)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback("cfx-keydi-banking:withdrawMoney", function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not amount or amount <= 0 then
        cb(false)
        return
    end

    local bankMoney = xPlayer.getAccount('bank').money
    if bankMoney >= amount then
        xPlayer.removeAccountMoney('bank', amount)
        xPlayer.addMoney(amount)
        AddTransaction(xPlayer.getIdentifier(), "withdraw", "Cash withdrawal", amount)

        if BankingLogs and BankingLogs.Withdraw then
            BankingLogs.Withdraw({
                src = source,
                name = xPlayer.getName and xPlayer.getName() or xPlayer.name,
                identifier = xPlayer.getIdentifier(),
                amount = amount,
                bankBalance = xPlayer.getAccount('bank').money,
                cashBalance = xPlayer.getMoney(),
            })
        end

        -- Build updated data
        BuildBankingData(xPlayer, function(updated)
            cb(true, updated)
        end)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback("cfx-keydi-banking:transferMoney", function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not data or not data.amount or data.amount <= 0 then
        cb(false, nil, "Invalid amount.")
        return
    end

    local bankMoney = xPlayer.getAccount('bank').money
    if bankMoney < data.amount then
        cb(false, nil, "Insufficient bank balance.")
        return
    end

    local amount = data.amount
    local targetType = data.targetType
    local targetVal = data.targetVal

    if targetType == "id" then
        local targetSrc = tonumber(targetVal)
        if not targetSrc or targetSrc == source then
            cb(false, nil, "Invalid player ID.")
            return
        end

        local xTarget = ESX.GetPlayerFromId(targetSrc)
        if not xTarget then
            cb(false, nil, "Player is offline or not found.")
            return
        end

        -- Execute Transfer
        xPlayer.removeAccountMoney('bank', amount)
        xTarget.addAccountMoney('bank', amount)

        local senderName = xPlayer.getName()
        local receiverName = xTarget.getName()

        AddTransaction(xPlayer.getIdentifier(), "withdraw", ("Transfer to %s"):format(receiverName), amount)
        AddTransaction(xTarget.getIdentifier(), "deposit", ("Transfer from %s"):format(senderName), amount)

        if BankingLogs and BankingLogs.Transfer then
            BankingLogs.Transfer({
                src = source,
                name = senderName,
                identifier = xPlayer.getIdentifier(),
                targetSrc = xTarget.source,
                targetName = receiverName,
                targetIdentifier = xTarget.getIdentifier(),
                amount = amount,
                method = "player id",
                offline = false,
            })
        end

        TriggerClientEvent("esx:showNotification", xTarget.source, ("Received transfer of $%s from %s"):format(amount, senderName), "success")

        BuildBankingData(xPlayer, function(updated)
            cb(true, updated, ("Transferred $%s to %s successfully."):format(amount, receiverName))
        end)

    elseif targetType == "account" then
        local foundOnlineTarget = nil
        local xPlayers = ESX.GetExtendedPlayers()
        for _, xp in ipairs(xPlayers) do
            if GetAccountNumber(xp.getIdentifier()) == targetVal then
                foundOnlineTarget = xp
                break
            end
        end

        if foundOnlineTarget then
            if foundOnlineTarget.source == source then
                cb(false, nil, "Cannot transfer to yourself.")
                return
            end

            -- Online account transfer
            xPlayer.removeAccountMoney('bank', amount)
            foundOnlineTarget.addAccountMoney('bank', amount)

            local senderName = xPlayer.getName()
            local receiverName = foundOnlineTarget.getName()

            AddTransaction(xPlayer.getIdentifier(), "withdraw", ("Transfer to %s"):format(receiverName), amount)
            AddTransaction(foundOnlineTarget.getIdentifier(), "deposit", ("Transfer from %s"):format(senderName), amount)

            if BankingLogs and BankingLogs.Transfer then
                BankingLogs.Transfer({
                    src = source,
                    name = senderName,
                    identifier = xPlayer.getIdentifier(),
                    targetSrc = foundOnlineTarget.source,
                    targetName = receiverName,
                    targetIdentifier = foundOnlineTarget.getIdentifier(),
                    amount = amount,
                    method = "account number",
                    offline = false,
                })
            end

            TriggerClientEvent("esx:showNotification", foundOnlineTarget.source, ("Received transfer of $%s from %s"):format(amount, senderName), "success")

            BuildBankingData(xPlayer, function(updated)
                cb(true, updated, ("Transferred $%s to %s successfully."):format(amount, receiverName))
            end)
        else
            -- Check database for matching offline user
            MySQL.query('SELECT identifier, firstname, lastname FROM users', {}, function(usersList)
                local targetIdentifier = nil
                local targetName = "Unknown"
                if usersList then
                    for _, u in ipairs(usersList) do
                        if GetAccountNumber(u.identifier) == targetVal then
                            targetIdentifier = u.identifier
                            local first = u.firstname or ''
                            local last = u.lastname or ''
                            local full = (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', '')
                            targetName = (full ~= '' and full) or 'Unknown'
                            break
                        end
                    end
                end

                if targetIdentifier then
                    if targetIdentifier == xPlayer.getIdentifier() then
                        cb(false, nil, "Cannot transfer to yourself.")
                        return
                    end

                    -- Offline SQL transfer: we decrement sender in ESX and increment receiver in DB users accounts!
                    -- Fetch receiver's accounts JSON
                    MySQL.single('SELECT accounts FROM users WHERE identifier = ?', { targetIdentifier }, function(receiverRow)
                        if receiverRow and receiverRow.accounts then
                            local accounts = json.decode(receiverRow.accounts)
                            if accounts and accounts.bank then
                                accounts.bank = accounts.bank + amount
                                
                                -- Execute
                                xPlayer.removeAccountMoney('bank', amount)
                                MySQL.update('UPDATE users SET accounts = ? WHERE identifier = ?', {
                                    json.encode(accounts),
                                    targetIdentifier
                                }, function(rowsAffected)
                                    if rowsAffected > 0 then
                                        AddTransaction(xPlayer.getIdentifier(), "withdraw", ("Transfer to %s"):format(targetName), amount)
                                        AddTransaction(targetIdentifier, "deposit", ("Transfer from %s"):format(xPlayer.getName()), amount)

                                        if BankingLogs and BankingLogs.Transfer then
                                            BankingLogs.Transfer({
                                                src = source,
                                                name = xPlayer.getName(),
                                                identifier = xPlayer.getIdentifier(),
                                                targetSrc = nil,
                                                targetName = targetName,
                                                targetIdentifier = targetIdentifier,
                                                amount = amount,
                                                method = "account number",
                                                offline = true,
                                            })
                                        end

                                        BuildBankingData(xPlayer, function(updated)
                                            cb(true, updated, ("Transferred $%s to %s successfully (Offline)."):format(amount, targetName))
                                        end)
                                    else
                                        cb(false, nil, "Transfer failed during database update.")
                                    end
                                end)
                            else
                                cb(false, nil, "Target account format invalid.")
                            end
                        else
                            cb(false, nil, "Target user accounts could not be read.")
                        end
                    end)
                else
                    cb(false, nil, "Account number does not exist.")
                end
            end)
        end
    else
        cb(false, nil, "Invalid transfer method.")
    end
end)
