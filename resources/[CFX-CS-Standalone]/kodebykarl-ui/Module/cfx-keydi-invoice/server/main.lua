local ESX = exports["es_extended"]:getSharedObject()

local TABLE_SQL = [[
    CREATE TABLE IF NOT EXISTS `keydi_invoices` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `reference` VARCHAR(16) NOT NULL,
        `kind` VARCHAR(16) NOT NULL DEFAULT 'personal',
        `invoice_type` VARCHAR(64) NOT NULL DEFAULT 'Personal',
        `title` VARCHAR(80) NOT NULL,
        `description` VARCHAR(255) DEFAULT NULL,
        `amount` INT NOT NULL DEFAULT 0,
        `vat` INT NOT NULL DEFAULT 0,
        `total` INT NOT NULL DEFAULT 0,
        `due_date` VARCHAR(32) DEFAULT NULL,
        `sender_identifier` VARCHAR(64) NOT NULL,
        `sender_name` VARCHAR(80) NOT NULL,
        `sender_job` VARCHAR(50) DEFAULT NULL,
        `receiver_identifier` VARCHAR(64) NOT NULL,
        `receiver_name` VARCHAR(80) NOT NULL,
        `status` VARCHAR(16) NOT NULL DEFAULT 'unpaid',
        `payment_method` VARCHAR(16) DEFAULT NULL,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `paid_at` TIMESTAMP NULL DEFAULT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `reference` (`reference`),
        KEY `receiver_identifier` (`receiver_identifier`),
        KEY `sender_identifier` (`sender_identifier`),
        KEY `status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
]]

local TABLE_NAME = "keydi_invoices"
local tableReady = false

local EXTRA_COLUMNS = {
    { name = "payment_method", def = "`payment_method` VARCHAR(16) DEFAULT NULL" },
    { name = "paid_at", def = "`paid_at` TIMESTAMP NULL DEFAULT NULL" },
}

local function invoiceTableExists()
    local row = MySQL.single.await([[
        SELECT COUNT(*) AS c
        FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = ?
    ]], { TABLE_NAME })
    return row and tonumber(row.c) and tonumber(row.c) > 0
end

local function loadInvoiceSql()
    local paths = {
        "Module/cfx-keydi-invoice/sql/keydi_invoices.sql",
        "sql/keydi_invoices.sql",
    }
    for i = 1, #paths do
        local raw = LoadResourceFile(GetCurrentResourceName(), paths[i])
        if type(raw) == "string" and raw:match("%S") then
            return raw:gsub(";%s*$", "")
        end
    end
    return TABLE_SQL
end

local function addMissingColumns()
    local rows = MySQL.query.await(([[
        SELECT COLUMN_NAME FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = '%s'
    ]]):format(TABLE_NAME)) or {}

    local have = {}
    for i = 1, #rows do
        local name = rows[i].COLUMN_NAME or rows[i].column_name
        if name then have[name] = true end
    end

    for i = 1, #EXTRA_COLUMNS do
        local col = EXTRA_COLUMNS[i]
        if not have[col.name] then
            MySQL.query.await(("ALTER TABLE `%s` ADD COLUMN %s"):format(TABLE_NAME, col.def))
        end
    end
end

local function ensureInvoiceTable()
    local sql = loadInvoiceSql()
    MySQL.query.await(sql)

    if not invoiceTableExists() then
        MySQL.query.await(TABLE_SQL)
    end

    if invoiceTableExists() then
        addMissingColumns()
        tableReady = true
        return true
    end

    print("^1[cfx-keydi-invoice]^7 could not create table `keydi_invoices`")
    return false
end

local function bootInvoiceDatabase()
    for attempt = 1, 20 do
        local ok, err = pcall(ensureInvoiceTable)
        if ok and tableReady then
            return
        end
        if not ok then
            print(("^3[cfx-keydi-invoice]^7 database seed attempt %s failed: %s"):format(attempt, tostring(err)))
        end
        Wait(500)
    end
end

MySQL.ready(function()
    CreateThread(bootInvoiceDatabase)
end)

CreateThread(function()
    Wait(2000)
    if not tableReady then
        bootInvoiceDatabase()
    end
end)

local function cfg()
    return Config.Invoice or {}
end

local function notify(src, msg, nType)
    TriggerClientEvent("cfx-keydi-invoice:client:notify", src, msg, nType or "inform")
end

local function playerName(xPlayer)
    if not xPlayer then return "Unknown" end
    if xPlayer.getName then
        return xPlayer.getName()
    end
    return xPlayer.name or "Unknown"
end

local function isOwnerDev(xPlayer)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or "user"
    local groups = cfg().OwnerDevGroups or { owner = true, developer = true }
    return groups[group] == true
end

local function isStaff(xPlayer)
    return isOwnerDev(xPlayer)
end

local function jobInvoiceInfo(jobName, grade)
    local jobs = cfg().JobInvoices or {}
    local info = jobs[jobName]
    if not info then return nil end
    local minGrade = tonumber(info.minGrade) or 0
    if (tonumber(grade) or 0) < minGrade then return nil end
    return info
end

local function canInspect(xPlayer)
    if not xPlayer then return false end
    if isOwnerDev(xPlayer) then return true end
    local job = xPlayer.job
    local jobName = job and job.name
    if not jobName then return false end
    local inspect = cfg().InspectJobs or {}
    if inspect[jobName] == true then return true end
    return jobInvoiceInfo(jobName, job.grade) ~= nil
end

local function generateReference()
    local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    for _ = 1, 12 do
        local ref = ""
        for _ = 1, 8 do
            local i = math.random(1, #chars)
            ref = ref .. chars:sub(i, i)
        end
        local exists = MySQL.scalar.await("SELECT id FROM `keydi_invoices` WHERE `reference` = ? LIMIT 1", { ref })
        if not exists then
            return ref
        end
    end
    return ("I%07d"):format(math.random(0, 9999999))
end

local function formatInvoice(row)
    if not row then return nil end
    return {
        id = row.id,
        reference = row.reference,
        kind = row.kind,
        invoiceType = row.invoice_type,
        title = row.title,
        description = row.description or "",
        amount = row.amount,
        vat = row.vat,
        total = row.total,
        dueDate = row.due_date,
        senderIdentifier = row.sender_identifier,
        senderName = row.sender_name,
        senderJob = row.sender_job,
        receiverIdentifier = row.receiver_identifier,
        receiverName = row.receiver_name,
        status = row.status,
        createdAt = row.created_at and tostring(row.created_at) or nil,
        paidAt = row.paid_at and tostring(row.paid_at) or nil,
        paymentMethod = row.payment_method or nil,
    }
end

local function addBankOffline(identifier, amount)
    local row = MySQL.single.await("SELECT accounts FROM users WHERE identifier = ?", { identifier })
    if not row then return false end
    local accounts = {}
    if type(row.accounts) == "string" and row.accounts ~= "" then
        accounts = json.decode(row.accounts) or {}
    elseif type(row.accounts) == "table" then
        accounts = row.accounts
    end
    accounts.bank = (tonumber(accounts.bank) or 0) + amount
    MySQL.update.await("UPDATE users SET accounts = ? WHERE identifier = ?", { json.encode(accounts), identifier })
    return true
end

local function societyAccountForInvoice(invoice)
    local jobName = invoice and invoice.sender_job
    if (not jobName or jobName == "") and invoice and invoice.invoice_type and invoice.invoice_type:lower() ~= "personal" then
        local societyCfg = cfg().JobInvoices or {}
        for jName, jData in pairs(societyCfg) do
            if (jData.label and jData.label:lower() == invoice.invoice_type:lower()) or jName == invoice.invoice_type:lower() then
                jobName = jName
                break
            end
        end
    end
    if not jobName or jobName == "" then return nil end

    if GetResourceState("cfx-keydi-society") == "started" then
        local account
        pcall(function()
            account = exports["cfx-keydi-society"]:AccountForJob(jobName)
        end)
        if type(account) == "string" and account ~= "" then
            return account
        end
    end
    return ("society_%s"):format(jobName)
end

local function creditSender(invoice, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if invoice.kind == "job" then
        local account = societyAccountForInvoice(invoice)
        if account and GetResourceState("cfx-keydi-society") == "started" then
            local ok = false
            pcall(function()
                local result = exports["cfx-keydi-society"]:AddMoney(
                    account,
                    amount,
                    invoice.sender_identifier,
                    ("Invoice #%s — %s"):format(invoice.id or "?", invoice.title or "billing")
                )
                ok = result ~= false and result ~= nil and result ~= "invalid" and result ~= "db_failed"
            end)
            if ok then
                return true
            end
        end
        print(("^1[cfx-keydi-invoice]^7 failed to credit society %s for invoice #%s"):format(tostring(account), tostring(invoice.id)))
        return false
    end

    local xSender = ESX.GetPlayerFromIdentifier(invoice.sender_identifier)
    if xSender then
        xSender.addAccountMoney("bank", amount)
        return true
    end

    return addBankOffline(invoice.sender_identifier, amount)
end

local function debitSender(invoice, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if invoice.kind == "job" then
        local account = societyAccountForInvoice(invoice)
        if account and GetResourceState("cfx-keydi-society") == "started" then
            pcall(function()
                exports["cfx-keydi-society"]:RemoveMoney(account, amount, invoice.sender_identifier, ("Invoice #%s rejected"):format(invoice.id or "?"))
            end)
            return true
        end
        return false
    end

    local xSender = ESX.GetPlayerFromIdentifier(invoice.sender_identifier)
    if xSender then
        xSender.removeAccountMoney("bank", amount)
        return true
    end

    return addBankOffline(invoice.sender_identifier, -amount)
end

local function tryAutoPay(row, xTarget)
    if not row or not xTarget then return false end
    local total = tonumber(row.total) or 0
    if total <= 0 then return false end

    local bank = xTarget.getAccount("bank")
    local cash = xTarget.getAccount("money")
    local bankBal = bank and tonumber(bank.money) or 0
    local cashBal = cash and tonumber(cash.money) or 0

    local account
    if bankBal >= total then
        account = "bank"
    elseif cashBal >= total then
        account = "money"
    else
        return false
    end

    xTarget.removeAccountMoney(account, total)
    creditSender(row, total)

    MySQL.update.await(
        "UPDATE `keydi_invoices` SET `status` = 'paid', `paid_at` = CURRENT_TIMESTAMP, `payment_method` = ? WHERE id = ?",
        { "auto", row.id }
    )
    row.status = "paid"
    row.payment_method = "auto"
    return true
end

local function attachPerms(invoice, identifier)
    if not invoice then return nil end
    local unpaid = invoice.status == "unpaid"
    local isReceiver = invoice.receiverIdentifier == identifier
    invoice.canPay = unpaid and isReceiver
    invoice.canCancel = unpaid and invoice.senderIdentifier == identifier
    invoice.canReject = isReceiver and (unpaid or invoice.paymentMethod == "auto")
    return invoice
end

local function listFor(identifier, column)
    local rows = MySQL.query.await(([[
        SELECT * FROM `keydi_invoices`
        WHERE `%s` = ?
        ORDER BY id DESC
        LIMIT 250
    ]]):format(column), { identifier }) or {}

    local out = {}
    for i = 1, #rows do
        out[i] = attachPerms(formatInvoice(rows[i]), identifier)
    end
    return out
end

local function societyListAll(identifier)
    local rows = MySQL.query.await([[
        SELECT * FROM `keydi_invoices`
        WHERE `kind` = 'job'
        ORDER BY id DESC
        LIMIT 250
    ]]) or {}

    local out = {}
    for i = 1, #rows do
        out[i] = attachPerms(formatInvoice(rows[i]), identifier)
    end
    return out
end

local function getInvoiceById(id)
    id = tonumber(id)
    if not id then return nil end
    return MySQL.single.await("SELECT * FROM `keydi_invoices` WHERE id = ? LIMIT 1", { id })
end

lib.callback.register("cfx-keydi-invoice:open", function(source, opts)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end

    opts = type(opts) == "table" and opts or {}
    local identifier = xPlayer.identifier
    local job = xPlayer.job or {}
    local jobName = job.name
    local jobInfo = jobInvoiceInfo(jobName, job.grade)
    local ownerDev = isOwnerDev(xPlayer)

    local nearby = {}
    if type(opts.nearby) == "table" then
        for i = 1, #opts.nearby do
            local entry = opts.nearby[i]
            local sid = tonumber(entry.id)
            local target = sid and ESX.GetPlayerFromId(sid)
            if target and target.identifier ~= identifier then
                nearby[#nearby + 1] = {
                    id = sid,
                    name = playerName(target),
                    distance = entry.distance,
                }
            end
        end
    end

    local selected = nil
    if opts.invoiceId then
        local row = getInvoiceById(opts.invoiceId)
        if row then
            local canSee = ownerDev
                or row.receiver_identifier == identifier
                or row.sender_identifier == identifier
                or (row.kind == "job" and row.sender_job == jobName)
            if canSee then
                selected = attachPerms(formatInvoice(row), identifier)
            end
        end
    elseif type(opts.reference) == "string" and opts.reference ~= "" then
        local row = MySQL.single.await("SELECT * FROM `keydi_invoices` WHERE reference = ? LIMIT 1", { opts.reference:upper() })
        if row then
            selected = attachPerms(formatInvoice(row), identifier)
        end
    end

    local incoming = opts.incoming == true
    local view = opts.view
    if incoming then
        view = "detail"
    elseif view == "city" or view == "society" then
        if not ownerDev then
            view = "create"
        end
    end

    return {
        playerName = playerName(xPlayer),
        jobName = jobName,
        jobLabel = job.label or jobName,
        canJobInvoice = jobInfo ~= nil,
        forceSocietyInvoice = jobInfo and jobInfo.forceSociety == true,
        jobInvoiceLabel = jobInfo and jobInfo.label or nil,
        isStaff = ownerDev,
        canSociety = ownerDev,
        canCity = ownerDev,
        canInspect = canInspect(xPlayer),
        incoming = incoming,
        vatPercent = tonumber(cfg().VATPercent) or 0,
        screenshotEnabled = cfg().ScreenshotEnabled ~= false,
        maxTitle = cfg().MaxTitleLength or 60,
        maxDescription = cfg().MaxDescriptionLength or 250,
        maxAmount = cfg().MaxAmount or 1000000,
        nearby = nearby,
        sent = listFor(identifier, "sender_identifier"),
        personal = listFor(identifier, "receiver_identifier"),
        society = ownerDev and societyListAll(identifier) or {},
        selected = selected,
        view = view,
    }
end)

local function createInvoice(source, data)
    if not tableReady then
        ensureInvoiceTable()
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = "Invalid player" } end

    data = type(data) == "table" and data or {}
    local targetId = tonumber(data.targetId)
    local xTarget = targetId and ESX.GetPlayerFromId(targetId)
    if not xTarget then
        return { ok = false, error = "No nearby citizen selected" }
    end
    if xTarget.identifier == xPlayer.identifier then
        return { ok = false, error = "You cannot invoice yourself" }
    end

    local title = tostring(data.title or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if title == "" then
        return { ok = false, error = "Title is required" }
    end
    local maxTitle = cfg().MaxTitleLength or 60
    if #title > maxTitle then
        title = title:sub(1, maxTitle)
    end

    local amount = math.floor(tonumber(data.price) or 0)
    local minAmount = cfg().MinAmount or 1
    local maxAmount = cfg().MaxAmount or 1000000
    if amount < minAmount or amount > maxAmount then
        return { ok = false, error = ("Price must be between $%s and $%s"):format(minAmount, maxAmount) }
    end

    local description = tostring(data.description or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local maxDesc = cfg().MaxDescriptionLength or 250
    if #description > maxDesc then
        description = description:sub(1, maxDesc)
    end
    if description == "" then
        description = nil
    end

    local dueDate = tostring(data.dueDate or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if dueDate == "" then
        dueDate = nil
    end

    local job = xPlayer.job or {}
    local info = jobInvoiceInfo(job.name, job.grade)
    local forceSociety = info and info.forceSociety == true
    local kind = "personal"
    if forceSociety or data.kind == "job" or (data.kind ~= "personal" and info ~= nil) then
        if info then
            kind = "job"
        end
    end

    local invoiceType = "Personal"
    local senderJob = (job and job.name and job.name ~= "unemployed") and job.name or nil

    if kind == "job" then
        if not info then
            return { ok = false, error = "Your job cannot issue society invoices" }
        end
        invoiceType = info.label or (job.label or job.name)
        senderJob = job.name
    end

    local vatPercent = tonumber(cfg().VATPercent) or 0
    local vat = math.floor(amount * vatPercent / 100)
    local total = amount + vat
    local reference = generateReference()

    local id = MySQL.insert.await([[
        INSERT INTO `keydi_invoices`
            (`reference`, `kind`, `invoice_type`, `title`, `description`, `amount`, `vat`, `total`, `due_date`,
             `sender_identifier`, `sender_name`, `sender_job`, `receiver_identifier`, `receiver_name`, `status`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'unpaid')
    ]], {
        reference,
        kind,
        invoiceType,
        title,
        description,
        amount,
        vat,
        total,
        dueDate,
        xPlayer.identifier,
        playerName(xPlayer),
        senderJob,
        xTarget.identifier,
        playerName(xTarget),
    })

    if not id then
        return { ok = false, error = "Could not save invoice" }
    end

    local saved = getInvoiceById(id)
    if not saved then
        return { ok = false, error = "Invoice did not save to database" }
    end

    local formatted = attachPerms(formatInvoice(saved), xTarget.identifier)
    if formatted then
        formatted.canPay = formatted.status == "unpaid"
    end

    if data.autoAccept and saved.status == "unpaid" then
        if tryAutoPay(saved, xTarget) then
            saved = getInvoiceById(id) or saved
            formatted = attachPerms(formatInvoice(saved), xTarget.identifier)
            notify(xTarget.source, ("Invoice #%s auto-paid ($%s). You can still reject it."):format(id, saved.total or total), "inform")
            notify(source, ("Invoice #%s auto-paid by %s ($%s)."):format(id, playerName(xTarget), saved.total or total), "success")
            TriggerClientEvent("cfx-keydi-invoice:client:paid", source, {
                id = id,
                total = saved.total or total,
            })
        end
    end

    TriggerClientEvent("cfx-keydi-invoice:client:received", xTarget.source, formatted)
    if not (data.autoAccept and saved.status == "paid") then
        notify(source, ("%s #%s sent to %s."):format(kind == "job" and "Invoice" or "Receipt", id, playerName(xTarget)), "success")
    end

    return { ok = true, id = id, reference = reference }
end

lib.callback.register("cfx-keydi-invoice:create", function(source, data)
    return createInvoice(source, data)
end)

lib.callback.register("cfx-keydi-invoice:pay", function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = "Invalid player" } end

    local invoiceId = data
    local account = "bank"
    if type(data) == "table" then
        invoiceId = data.id
        if data.account == "cash" then
            account = "money"
        else
            account = "bank"
        end
    end

    local row = getInvoiceById(invoiceId)
    if not row then
        return { ok = false, error = "Invoice not found" }
    end
    if row.status == "paid" then
        return { ok = false, error = "Invoice already paid" }
    end
    if row.receiver_identifier ~= xPlayer.identifier then
        return { ok = false, error = "This invoice is not yours" }
    end

    local total = tonumber(row.total) or 0
    local acc = xPlayer.getAccount(account)
    local balance = acc and tonumber(acc.money) or 0
    if balance < total then
        return { ok = false, error = account == "money" and "Not enough cash" or "Not enough bank balance" }
    end

    xPlayer.removeAccountMoney(account, total)
    creditSender(row, total)

    MySQL.update.await("UPDATE `keydi_invoices` SET `status` = 'paid', `paid_at` = CURRENT_TIMESTAMP, `payment_method` = ? WHERE id = ?", {
        account == "money" and "cash" or "bank",
        row.id,
    })

    local xSender = ESX.GetPlayerFromIdentifier(row.sender_identifier)
    if xSender then
        TriggerClientEvent("cfx-keydi-invoice:client:paid", xSender.source, {
            id = row.id,
            total = total,
        })
    end

    local isReceipt = row.kind == "personal" or row.invoice_type == "Personal"
    local docLabel = isReceipt and "receipt" or "invoice"
    local docLabelCap = isReceipt and "Receipt" or "Invoice"

    notify(source, ("Paid %s #%s ($%s) via %s."):format(docLabel, row.id, total, account == "money" and "cash" or "bank"), "success")
    return { ok = true }
end)

local function declineInvoice(source, invoiceId, asReceiver)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = "Invalid player" } end

    local row = getInvoiceById(invoiceId)
    if not row then
        return { ok = false, error = "Invoice not found" }
    end
    if row.status == "paid" then
        if not asReceiver or row.payment_method ~= "auto" or row.receiver_identifier ~= xPlayer.identifier then
            return { ok = false, error = "Invoice cannot be cancelled" }
        end

        local total = tonumber(row.total) or 0
        xPlayer.addAccountMoney("bank", total)
        debitSender(row, total)
        MySQL.update.await("DELETE FROM `keydi_invoices` WHERE id = ?", { row.id })

        local xSender = ESX.GetPlayerFromIdentifier(row.sender_identifier)
        if xSender then
            notify(xSender.source, ("Invoice #%s was rejected. $%s refunded."):format(row.id, total), "inform")
        end
        notify(source, ("Invoice rejected. $%s refunded to your bank."):format(total), "success")
        return { ok = true, refunded = total }
    end

    if row.status ~= "unpaid" then
        return { ok = false, error = "Invoice cannot be cancelled" }
    end

    if asReceiver then
        if row.receiver_identifier ~= xPlayer.identifier then
            return { ok = false, error = "This invoice is not yours" }
        end
    else
        if row.sender_identifier ~= xPlayer.identifier and not isOwnerDev(xPlayer) then
            return { ok = false, error = "You cannot cancel this invoice" }
        end
    end

    MySQL.update.await("DELETE FROM `keydi_invoices` WHERE id = ? AND status = 'unpaid'", { row.id })

    local isReceipt = row.kind == "personal" or row.invoice_type == "Personal"
    local docLabelCap = isReceipt and "Receipt" or "Invoice"

    local otherId = asReceiver and row.sender_identifier or row.receiver_identifier
    local xOther = ESX.GetPlayerFromIdentifier(otherId)
    if xOther then
        notify(xOther.source, ("%s #%s was %s."):format(docLabelCap, row.id, asReceiver and "rejected" or "cancelled"), "inform")
    end

    notify(source, asReceiver and ("%s rejected."):format(docLabelCap) or ("%s cancelled."):format(docLabelCap), "success")
    return { ok = true }
end

lib.callback.register("cfx-keydi-invoice:reject", function(source, data)
    local id = type(data) == "table" and data.id or data
    return declineInvoice(source, id, true)
end)

lib.callback.register("cfx-keydi-invoice:cancel", function(source, data)
    local id = type(data) == "table" and data.id or data
    return declineInvoice(source, id, false)
end)

lib.callback.register("cfx-keydi-invoice:inspect", function(source, targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = "Invalid player" } end
    if not canInspect(xPlayer) then
        return { ok = false, error = "No permission" }
    end

    local sid = tonumber(targetId)
    local xTarget = sid and ESX.GetPlayerFromId(sid)
    if not xTarget then
        return { ok = false, error = "Citizen not found" }
    end

    local unpaid = MySQL.scalar.await([[
        SELECT COALESCE(SUM(total), 0) FROM `keydi_invoices`
        WHERE receiver_identifier = ? AND status = 'unpaid'
    ]], { xTarget.identifier }) or 0

    return {
        ok = true,
        name = playerName(xTarget),
        id = sid,
        unpaid = tonumber(unpaid) or 0,
    }
end)

lib.callback.register("cfx-keydi-invoice:lookup", function(source, reference)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = "Invalid player" } end

    reference = tostring(reference or ""):upper():gsub("%s+", "")
    if reference == "" then
        return { ok = false, error = "Enter a reference ID" }
    end

    local row = MySQL.single.await("SELECT * FROM `keydi_invoices` WHERE reference = ? LIMIT 1", { reference })
    if not row then
        return { ok = false, error = "Invoice not found" }
    end

    local identifier = xPlayer.identifier
    local jobName = xPlayer.job and xPlayer.job.name
    local canSee = isStaff(xPlayer)
        or row.receiver_identifier == identifier
        or row.sender_identifier == identifier
        or (row.kind == "job" and row.sender_job == jobName)

    if not canSee then
        return { ok = false, error = "Invoice not found" }
    end

    return {
        ok = true,
        invoice = attachPerms(formatInvoice(row), identifier),
        receiver = row.receiver_name,
        amount = row.total,
    }
end)

lib.callback.register("cfx-keydi-invoice:city", function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not isOwnerDev(xPlayer) then
        return { ok = false, error = "No permission", invoices = {}, pending = 0, paid = 0 }
    end

    data = type(data) == "table" and data or {}
    local search = tostring(data.search or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local status = data.status
    local params = {}
    local where = {}

    if status == "unpaid" or status == "paid" then
        where[#where + 1] = "`status` = ?"
        params[#params + 1] = status
    end

    if search ~= "" then
        where[#where + 1] = "(`receiver_name` LIKE ? OR `sender_name` LIKE ? OR `reference` LIKE ? OR `title` LIKE ? OR CAST(`id` AS CHAR) LIKE ?)"
        local like = "%" .. search .. "%"
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
        params[#params + 1] = like
    end

    local sql = "SELECT * FROM `keydi_invoices`"
    if #where > 0 then
        sql = sql .. " WHERE " .. table.concat(where, " AND ")
    end
    sql = sql .. " ORDER BY id DESC LIMIT 250"

    local rows = MySQL.query.await(sql, params) or {}
    local invoices = {}
    for i = 1, #rows do
        invoices[i] = attachPerms(formatInvoice(rows[i]), xPlayer.identifier)
    end

    local pending = MySQL.scalar.await("SELECT COUNT(*) FROM `keydi_invoices` WHERE status = 'unpaid'") or 0
    local paid = MySQL.scalar.await("SELECT COUNT(*) FROM `keydi_invoices` WHERE status = 'paid'") or 0

    return {
        ok = true,
        invoices = invoices,
        pending = tonumber(pending) or 0,
        paid = tonumber(paid) or 0,
    }
end)

lib.callback.register("cfx-keydi-invoice:deletePaid", function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not isOwnerDev(xPlayer) then
        return { ok = false, error = "No permission" }
    end

    MySQL.update.await("DELETE FROM `keydi_invoices` WHERE status = 'paid'")
    return { ok = true }
end)

--- Other resources: exports['cfx-keydi-ui']:CreateInvoice(source, targetId, { title, price, description, kind, dueDate })
exports("CreateInvoice", function(source, targetId, data)
    data = type(data) == "table" and data or {}
    data.targetId = targetId
    return createInvoice(source, data)
end)
