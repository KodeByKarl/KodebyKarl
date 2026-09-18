local ESX = exports['es_extended']:getSharedObject()
local ox_inventory = exports.ox_inventory

local HIRE_DISTANCE = 5.0
local MAX_TRANSFER = 1000000

local function businessJobs()
    return ConfigIpad.BusinessJobs or {}
end

local function jobInfo(jobName)
    local jobs = businessJobs()
    return jobName and jobs[jobName] or nil
end

local function invoiceJobNames(jobName)
    local names = { jobName }
    local info = jobInfo(jobName)
    if info and type(info.invoiceJobs) == 'table' then
        for i = 1, #info.invoiceJobs do
            names[#names + 1] = info.invoiceJobs[i]
        end
    end
    return names
end

local function isBusinessBoss(xPlayer)
    if not xPlayer or not xPlayer.job then return false, nil end
    local jobName = xPlayer.job.name
    if not jobInfo(jobName) then return false, nil end
    local gradeName = type(xPlayer.job.grade_name) == 'string' and xPlayer.job.grade_name:lower() or ''
    if gradeName == 'boss' or gradeName == 'owner' or gradeName == 'director' then
        return true, jobName
    end
    local minGrade = tonumber(ConfigIpad.BusinessBossMinGrade)
    if minGrade and (tonumber(xPlayer.job.grade) or 0) >= minGrade then
        return true, jobName
    end
    local jobs = ESX.GetJobs() or {}
    local job = jobs[jobName]
    local maxGrade = 0
    if job and job.grades then
        for key, grade in pairs(job.grades) do
            local g = tonumber(grade.grade) or tonumber(key) or 0
            if g > maxGrade then maxGrade = g end
        end
    end
    return (tonumber(xPlayer.job.grade) or 0) >= maxGrade and maxGrade > 0, jobName
end

local function societyReady()
    return GetResourceState('cfx-keydi-society') == 'started'
end

local function getFunds(jobName)
    if not societyReady() then return 0 end
    local ok, bal = pcall(function()
        return exports['cfx-keydi-society']:GetBalance(jobName)
    end)
    if ok then return tonumber(bal) or 0 end
    return 0
end

local function addFunds(jobName, amount, identifier, note)
    if not societyReady() then return false, 'society_offline' end
    local success, result = exports['cfx-keydi-society']:AddMoney(jobName, amount, identifier, note)
    return success, result
end

local function removeFunds(jobName, amount, identifier, note)
    if not societyReady() then return false, 'society_offline' end
    local success, result = exports['cfx-keydi-society']:RemoveMoney(jobName, amount, identifier, note)
    return success, result
end

local function getLedger(jobName)
    if not societyReady() then return {} end
    local rows = exports['cfx-keydi-society']:GetLedger(jobName, 12)
    if type(rows) ~= 'table' then return {} end
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = row.id,
            action = row.action,
            amount = tonumber(row.amount) or 0,
            note = row.note or '',
            createdAt = row.created_at,
        }
    end
    return out
end

local function placeholders(n)
    local t = {}
    for i = 1, n do t[i] = '?' end
    return table.concat(t, ',')
end

local function jobGrades(jobName)
    local jobs = ESX.GetJobs() or {}
    local job = jobs[jobName]
    local grades = {}
    if not job or not job.grades then return grades end
    for key, grade in pairs(job.grades) do
        grades[#grades + 1] = {
            grade = tonumber(grade.grade) or tonumber(key) or 0,
            name = grade.name or tostring(key),
            label = grade.label or grade.name or ('Grade ' .. tostring(key)),
        }
    end
    table.sort(grades, function(a, b) return a.grade < b.grade end)
    return grades
end

local function moneyCount(src)
    return ox_inventory:Search(src, 'count', 'money') or 0
end

local function invoiceStats(jobName)
    local names = invoiceJobNames(jobName)
    if #names == 0 then
        return { sales = 0, income = 0, pending = 0, pendingAmount = 0 }
    end

    local paid = MySQL.single.await(([[
        SELECT COUNT(*) AS sales, COALESCE(SUM(total), 0) AS income
        FROM keydi_invoices
        WHERE status = 'paid' AND sender_job IN (%s)
    ]]):format(placeholders(#names)), names) or {}

    local pending = MySQL.single.await(([[
        SELECT COUNT(*) AS pending, COALESCE(SUM(total), 0) AS amount
        FROM keydi_invoices
        WHERE status = 'unpaid' AND sender_job IN (%s)
    ]]):format(placeholders(#names)), names) or {}

    return {
        sales = tonumber(paid.sales) or 0,
        income = tonumber(paid.income) or 0,
        pending = tonumber(pending.pending) or 0,
        pendingAmount = tonumber(pending.amount) or 0,
    }
end

local function invoiceChart(jobName)
    local names = invoiceJobNames(jobName)
    local byDay = {}
    if #names > 0 then
        local rows = MySQL.query.await(([[
            SELECT DATE(COALESCE(paid_at, created_at)) AS day,
                   COUNT(*) AS sales,
                   COALESCE(SUM(total), 0) AS income
            FROM keydi_invoices
            WHERE status = 'paid'
              AND sender_job IN (%s)
              AND COALESCE(paid_at, created_at) >= DATE_SUB(NOW(), INTERVAL 13 DAY)
            GROUP BY DATE(COALESCE(paid_at, created_at))
        ]]):format(placeholders(#names)), names) or {}
        for i = 1, #rows do
            local key = tostring(rows[i].day or '')
            byDay[key] = {
                sales = tonumber(rows[i].sales) or 0,
                income = tonumber(rows[i].income) or 0,
            }
        end
    end

    local chart = {}
    for i = 13, 0, -1 do
        local stamp = os.time() - (i * 86400)
        local key = os.date('%Y-%m-%d', stamp)
        local row = byDay[key] or { sales = 0, income = 0 }
        chart[#chart + 1] = {
            day = os.date('%b %d', stamp),
            sales = row.sales,
            income = row.income,
        }
    end
    return chart
end

local function invoiceLogs(jobName)
    local names = invoiceJobNames(jobName)
    if #names == 0 then return {} end
    local rows = MySQL.query.await(([[
        SELECT id, reference, title, total, status, sender_name, receiver_name, created_at, paid_at
        FROM keydi_invoices
        WHERE sender_job IN (%s)
        ORDER BY id DESC
        LIMIT 80
    ]]):format(placeholders(#names)), names) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = row.id,
            reference = row.reference,
            title = row.title,
            total = tonumber(row.total) or 0,
            status = row.status,
            senderName = row.sender_name,
            receiverName = row.receiver_name,
            createdAt = row.created_at,
            paidAt = row.paid_at,
        }
    end
    return out
end

local function employees(jobName)
    local rows = MySQL.query.await([[
        SELECT identifier, firstname, lastname, job_grade
        FROM users
        WHERE job = ?
        ORDER BY job_grade DESC, lastname ASC
    ]], { jobName }) or {}

    local grades = jobGrades(jobName)
    local gradeLabel = {}
    for i = 1, #grades do
        gradeLabel[grades[i].grade] = grades[i].label
    end

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local xTarget = ESX.GetPlayerFromIdentifier(row.identifier)
        local grade = tonumber(row.job_grade) or 0
        if xTarget and xTarget.job and xTarget.job.name == jobName then
            grade = tonumber(xTarget.job.grade) or grade
        end
        out[#out + 1] = {
            identifier = row.identifier,
            name = (('%s %s'):format(row.firstname or '', row.lastname or '')):gsub('^%s+', ''):gsub('%s+$', ''),
            grade = grade,
            gradeLabel = gradeLabel[grade] or ('Grade ' .. grade),
            online = xTarget ~= nil,
            serverId = xTarget and xTarget.source or nil,
        }
        if out[#out].name == '' then
            out[#out].name = 'Unknown'
        end
    end
    return out, grades
end

local function applyBusinessJob(xTarget, jobName, grade, notifyMsg)
    if not xTarget then return false end
    grade = math.floor(tonumber(grade) or 0)
    if ESX.DoesJobExist and not ESX.DoesJobExist(jobName, grade) then
        return false
    end
    local onDuty = xTarget.job and xTarget.job.onDuty
    if onDuty == nil then onDuty = true end
    xTarget.setJob(jobName, grade, onDuty)

    local identifier = xTarget.identifier or (xTarget.getIdentifier and xTarget.getIdentifier())
    if identifier then
        MySQL.update.await('UPDATE `users` SET `job` = ?, `job_grade` = ? WHERE `identifier` = ?', {
            jobName, grade, identifier
        })
    end
    if Core and Core.SavePlayer then
        pcall(Core.SavePlayer, xTarget)
    end
    if notifyMsg and xTarget.source then
        TriggerClientEvent('esx:showNotification', xTarget.source, notifyMsg, 'success')
    end
    return true
end

local function isNearPlayer(src, targetId)
    local ped = GetPlayerPed(src)
    local tped = GetPlayerPed(targetId)
    if not ped or ped == 0 or not tped or tped == 0 then return false end
    return #(GetEntityCoords(ped) - GetEntityCoords(tped)) <= HIRE_DISTANCE
end

lib.callback.register('cfx-keydi-ipad:business:dashboard', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local ok, jobName = isBusinessBoss(xPlayer)
    if not ok then
        return { ok = false, error = 'denied' }
    end

    local info = jobInfo(jobName)
    local stats = { sales = 0, income = 0, pending = 0, pendingAmount = 0 }
    local chart, invoices = {}, {}
    pcall(function()
        stats = invoiceStats(jobName)
        chart = invoiceChart(jobName)
        invoices = invoiceLogs(jobName)
    end)
    local staff, grades = employees(jobName)

    return {
        ok = true,
        job = jobName,
        label = (info and info.label) or jobName,
        funds = getFunds(jobName),
        sales = stats.sales,
        income = stats.income,
        pending = stats.pending,
        pendingAmount = stats.pendingAmount,
        chart = chart,
        ledger = getLedger(jobName),
        employees = staff,
        grades = grades,
        invoices = invoices,
        yourGrade = tonumber(xPlayer.job.grade) or 0,
    }
end)

lib.callback.register('cfx-keydi-ipad:business:transfer', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local ok, jobName = isBusinessBoss(xPlayer)
    if not ok then
        return { ok = false, error = 'denied' }
    end

    local action = type(data) == 'table' and data.action or nil
    local amount = math.floor(tonumber(type(data) == 'table' and data.amount) or 0)
    if (action ~= 'deposit' and action ~= 'withdraw') or amount < 1 or amount > MAX_TRANSFER then
        return { ok = false, error = 'invalid' }
    end

    if action == 'deposit' then
        if moneyCount(source) < amount then
            return { ok = false, error = 'no_cash' }
        end
        if not ox_inventory:RemoveItem(source, 'money', amount) then
            return { ok = false, error = 'no_cash' }
        end
        local added, err = addFunds(jobName, amount, xPlayer.identifier, 'iPad deposit')
        if not added then
            ox_inventory:AddItem(source, 'money', amount)
            return { ok = false, error = err or 'failed' }
        end
    else
        local removed, err = removeFunds(jobName, amount, xPlayer.identifier, 'iPad withdraw')
        if not removed then
            return { ok = false, error = err == 'insufficient' and 'no_funds' or (err or 'failed') }
        end
        if not ox_inventory:AddItem(source, 'money', amount) then
            addFunds(jobName, amount, xPlayer.identifier, 'iPad withdraw refund')
            return { ok = false, error = 'inventory_full' }
        end
    end

    local stats = invoiceStats(jobName)
    return {
        ok = true,
        funds = getFunds(jobName),
        ledger = getLedger(jobName),
        sales = stats.sales,
        income = stats.income,
    }
end)

lib.callback.register('cfx-keydi-ipad:business:hire', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local ok, jobName = isBusinessBoss(xPlayer)
    if not ok then
        return { ok = false, error = 'denied' }
    end

    local targetId = tonumber(type(data) == 'table' and data.id)
    local grade = math.floor(tonumber(type(data) == 'table' and data.grade) or 0)
    if not targetId or targetId == source then
        return { ok = false, error = 'invalid' }
    end

    local yourGrade = tonumber(xPlayer.job.grade) or 0
    if grade < 0 or grade >= yourGrade then
        return { ok = false, error = 'grade' }
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        return { ok = false, error = 'offline' }
    end
    if not isNearPlayer(source, targetId) then
        return { ok = false, error = 'far' }
    end

    local okApply = applyBusinessJob(xTarget, jobName, grade, ('You were hired at %s.'):format(jobName))
    if not okApply then return { ok = false, error = 'failed' } end
    local staff, grades = employees(jobName)
    return { ok = true, employees = staff, grades = grades }
end)

lib.callback.register('cfx-keydi-ipad:business:setGrade', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local ok, jobName = isBusinessBoss(xPlayer)
    if not ok then
        return { ok = false, error = 'denied' }
    end

    local identifier = type(data) == 'table' and data.identifier or nil
    local grade = math.floor(tonumber(type(data) == 'table' and data.grade) or -1)
    if type(identifier) ~= 'string' or identifier == '' or grade < 0 then
        return { ok = false, error = 'invalid' }
    end
    if identifier == xPlayer.identifier then
        return { ok = false, error = 'self' }
    end

    local yourGrade = tonumber(xPlayer.job.grade) or 0
    if grade >= yourGrade then
        return { ok = false, error = 'grade' }
    end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        if xTarget.job and xTarget.job.name ~= jobName then
            return { ok = false, error = 'not_employee' }
        end
        if (tonumber(xTarget.job.grade) or 0) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        local okApply = applyBusinessJob(
            xTarget,
            jobName,
            grade,
            ('Your rank is now grade %s.'):format(grade)
        )
        if not okApply then return { ok = false, error = 'failed' } end
    else
        local row = MySQL.single.await('SELECT job, job_grade FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or row.job ~= jobName then
            return { ok = false, error = 'not_employee' }
        end
        if (tonumber(row.job_grade) or 0) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { jobName, grade, identifier })
    end

    local staff, grades = employees(jobName)
    return { ok = true, employees = staff, grades = grades }
end)

lib.callback.register('cfx-keydi-ipad:business:fire', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local ok, jobName = isBusinessBoss(xPlayer)
    if not ok then
        return { ok = false, error = 'denied' }
    end

    local identifier = type(data) == 'table' and data.identifier or nil
    if type(identifier) ~= 'string' or identifier == '' then
        return { ok = false, error = 'invalid' }
    end
    if identifier == xPlayer.identifier then
        return { ok = false, error = 'self' }
    end

    local yourGrade = tonumber(xPlayer.job.grade) or 0
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        if not xTarget.job or xTarget.job.name ~= jobName then
            return { ok = false, error = 'not_employee' }
        end
        if (tonumber(xTarget.job.grade) or 0) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        xTarget.setJob('unemployed', 0)
    else
        local row = MySQL.single.await('SELECT job, job_grade FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or row.job ~= jobName then
            return { ok = false, error = 'not_employee' }
        end
        if (tonumber(row.job_grade) or 0) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { 'unemployed', 0, identifier })
    end

    local staff, grades = employees(jobName)
    return { ok = true, employees = staff, grades = grades }
end)
