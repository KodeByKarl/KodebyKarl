--[[
    cfx-keydi-ipad — Department Boss + LEO MDT (police / sheriff / ambulance)
    Live roster, society funds, announcements, BOLOs — no mock data.
]]

if rawget(_G, '__CFX_KEYDI_IPAD_DEPT_LOADED') then
    return
end
_G.__CFX_KEYDI_IPAD_DEPT_LOADED = true

local ESX = exports['es_extended']:getSharedObject()
local ox_inventory = exports.ox_inventory

local HIRE_DISTANCE = 5.0
local MAX_TRANSFER = 1000000

local function departments()
    return ConfigIpad.Departments or {}
end

local function deptConfig(dept)
    return dept and departments()[dept] or nil
end

local function isOwnerDev(xPlayer)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local groups = ConfigIpad.EconomyGroups or { owner = true, developer = true }
    return groups[group] == true
end

local function playerDisplayName(xPlayer)
    if not xPlayer then return 'Unknown' end
    local first = xPlayer.get and (xPlayer.get('firstName') or xPlayer.get('firstname')) or nil
    local last = xPlayer.get and (xPlayer.get('lastName') or xPlayer.get('lastname')) or nil
    if first or last then
        return (('%s %s'):format(first or '', last or '')):gsub('^%s+', ''):gsub('%s+$', '')
    end
    return xPlayer.getName and xPlayer.getName() or 'Unknown'
end

local function jobInList(jobName, list)
    if not jobName or type(list) ~= 'table' then return false end
    for i = 1, #list do
        if list[i] == jobName then return true end
    end
    return false
end

local function resolvePlayerDept(xPlayer)
    if not xPlayer or not xPlayer.job then return nil end
    local jobName = xPlayer.job.name
    for key, cfg in pairs(departments()) do
        if jobInList(jobName, cfg.jobs) then
            return key, cfg
        end
    end
    return nil
end

local function isDeptBoss(xPlayer, dept)
    if not xPlayer then return false end
    if isOwnerDev(xPlayer) then return true end
    local cfg = deptConfig(dept)
    if not cfg or not xPlayer.job then return false end
    if not jobInList(xPlayer.job.name, cfg.jobs) then return false end

    local gradeName = type(xPlayer.job.grade_name) == 'string' and xPlayer.job.grade_name:lower() or ''
    local names = cfg.bossGradeNames or { boss = true, director = true, chief = true }
    if names[gradeName] then return true end

    local minGrade = tonumber(cfg.bossMinGrade) or 5
    return (tonumber(xPlayer.job.grade) or 0) >= minGrade
end

local function isDeptMember(xPlayer, dept)
    if not xPlayer then return false end
    if isOwnerDev(xPlayer) then return true end
    local cfg = deptConfig(dept)
    if not cfg or not xPlayer.job then return false end
    return jobInList(xPlayer.job.name, cfg.jobs)
end

--- DOJ shares the Police MDT (same BOLOs / units / announcements) without joining PD boss roster.
local function canAccessMdt(xPlayer, dept)
    if not xPlayer or not dept then return false end
    if isDeptMember(xPlayer, dept) then return true end
    if dept == 'police' and isDeptMember(xPlayer, 'doj') then
        return true
    end
    return false
end

local function societyReady()
    return GetResourceState('cfx-keydi-society') == 'started'
end

local function societyKey(cfg)
    return (cfg and (cfg.society or cfg.primaryJob)) or nil
end

local function getFunds(cfg)
    local key = societyKey(cfg)
    if not key or not societyReady() then return 0 end
    local ok, bal = pcall(function()
        return exports['cfx-keydi-society']:GetBalance(key)
    end)
    if ok then return tonumber(bal) or 0 end
    return 0
end

local function addFunds(cfg, amount, identifier, note)
    local key = societyKey(cfg)
    if not key or not societyReady() then return false, 'society_offline' end
    local success, result = exports['cfx-keydi-society']:AddMoney(key, amount, identifier, note)
    return success, result
end

local function removeFunds(cfg, amount, identifier, note)
    local key = societyKey(cfg)
    if not key or not societyReady() then return false, 'society_offline' end
    local success, result = exports['cfx-keydi-society']:RemoveMoney(key, amount, identifier, note)
    return success, result
end

local function getLedger(cfg)
    local key = societyKey(cfg)
    if not key or not societyReady() then return {} end
    local rows = exports['cfx-keydi-society']:GetLedger(key, 12)
    if type(rows) ~= 'table' then return {} end
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = row.id,
            action = row.action,
            amount = tonumber(row.amount) or 0,
            note = row.note or '',
            createdAt = row.created_at and tostring(row.created_at) or nil,
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

local function isNearPlayer(src, targetId)
    local ped = GetPlayerPed(src)
    local tped = GetPlayerPed(targetId)
    if not ped or ped == 0 or not tped or tped == 0 then return false end
    return #(GetEntityCoords(ped) - GetEntityCoords(tped)) <= HIRE_DISTANCE
end

--- Persist job + multijob so promote/hire apply instantly (no reconnect needed).
local function syncMultijobGrade(identifier, primaryJob, grade, isActive)
    if not identifier or not primaryJob or primaryJob == 'unemployed' then return end
    local jobs = ESX.GetJobs and ESX.GetJobs() or ESX.Jobs or {}
    local jobObj = jobs[primaryJob]
    local gradeKey = tostring(grade)
    local gradeObj = jobObj and jobObj.grades and (jobObj.grades[gradeKey] or jobObj.grades[grade])
    local label = (jobObj and jobObj.label) or primaryJob
    local gradeLabel = (gradeObj and gradeObj.label) or ('Grade ' .. tostring(grade))
    MySQL.query.await([[
        INSERT INTO `player_multijobs` (`identifier`, `job`, `grade`, `label`, `grade_label`, `is_active`)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE `grade` = VALUES(`grade`), `label` = VALUES(`label`),
            `grade_label` = VALUES(`grade_label`), `is_active` = VALUES(`is_active`)
    ]], { identifier, primaryJob, grade, label, gradeLabel, isActive and 1 or 0 })
end

--- Apply dept job grade live + DB. Keeps off-duty job name when already off duty.
local function applyDeptJob(xTarget, cfg, grade, notifyMsg)
    if not xTarget or not cfg then return false, 'offline' end
    grade = math.floor(tonumber(grade) or 0)
    local primary = cfg.primaryJob
    local current = xTarget.job and xTarget.job.name
    local jobName = primary
    local onDuty = true

    if current and jobInList(current, cfg.jobs) then
        jobName = current
        if type(current) == 'string' and current:sub(1, 3) == 'off' then
            onDuty = false
        else
            onDuty = xTarget.job.onDuty
            if onDuty == nil then onDuty = true end
        end
    end

    if ESX.DoesJobExist and not ESX.DoesJobExist(jobName, grade) then
        if jobName ~= primary and ESX.DoesJobExist(primary, grade) then
            jobName = primary
            onDuty = true
        else
            return false, 'invalid_grade'
        end
    end

    xTarget.setJob(jobName, grade, onDuty)

    local identifier = xTarget.identifier or (xTarget.getIdentifier and xTarget.getIdentifier())
    if identifier then
        MySQL.update.await('UPDATE `users` SET `job` = ?, `job_grade` = ? WHERE `identifier` = ?', {
            jobName, grade, identifier
        })
        -- Always keep the on-duty job row grade in sync (duty toggle reads this).
        syncMultijobGrade(identifier, primary, grade, jobName == primary)
        if type(current) == 'string' and current:sub(1, 3) == 'off' and jobName ~= primary then
            MySQL.update.await('UPDATE `player_multijobs` SET `is_active` = 0 WHERE `identifier` = ?', { identifier })
        end
    end

    if Core and Core.SavePlayer then
        pcall(Core.SavePlayer, xTarget)
    end

    if notifyMsg and xTarget.source then
        TriggerClientEvent('esx:showNotification', xTarget.source, notifyMsg, 'success')
    end
    return true
end

local function employees(cfg)
    local jobs = cfg.jobs or { cfg.primaryJob }
    if #jobs < 1 then return {}, jobGrades(cfg.primaryJob) end

    local rows = MySQL.query.await(([[
        SELECT identifier, firstname, lastname, job, job_grade
        FROM users
        WHERE job IN (%s)
        ORDER BY job_grade DESC, lastname ASC
    ]]):format(placeholders(#jobs)), jobs) or {}

    local grades = jobGrades(cfg.primaryJob)
    local gradeLabel = {}
    for i = 1, #grades do
        gradeLabel[grades[i].grade] = grades[i].label
    end

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local xTarget = ESX.GetPlayerFromIdentifier(row.identifier)
        -- Prefer live ESX job so roster matches promote/hire without waiting for autosave.
        local jobName = row.job
        local grade = tonumber(row.job_grade) or 0
        if xTarget and xTarget.job and jobInList(xTarget.job.name, jobs) then
            jobName = xTarget.job.name
            grade = tonumber(xTarget.job.grade) or grade
        end
        local name = (('%s %s'):format(row.firstname or '', row.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
        if name == '' then name = 'Unknown' end
        out[#out + 1] = {
            identifier = row.identifier,
            name = name,
            job = jobName,
            grade = grade,
            gradeLabel = gradeLabel[grade] or ('Grade ' .. grade),
            online = xTarget ~= nil,
            serverId = xTarget and xTarget.source or nil,
        }
    end
    return out, grades
end

local function onlineUnits(cfg)
    local units = {}
    local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}
    for _, xP in pairs(xPlayers) do
        if xP and xP.job and jobInList(xP.job.name, cfg.jobs) then
            local grade = tonumber(xP.job.grade) or 0
            local grades = jobGrades(cfg.primaryJob)
            local gradeLabel = tostring(grade)
            for i = 1, #grades do
                if grades[i].grade == grade then
                    gradeLabel = grades[i].label
                    break
                end
            end
            units[#units + 1] = {
                serverId = xP.source,
                name = playerDisplayName(xP),
                job = xP.job.name,
                grade = grade,
                gradeLabel = gradeLabel,
                callsign = ('Unit-%s'):format(xP.source),
            }
        end
    end
    table.sort(units, function(a, b) return (a.name or '') < (b.name or '') end)
    return units
end

local function EnsureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_ipad_dept_announcements` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `department` VARCHAR(32) NOT NULL,
            `title` VARCHAR(120) NOT NULL,
            `body` VARCHAR(500) NOT NULL,
            `author_name` VARCHAR(80) NOT NULL,
            `author_identifier` VARCHAR(60) NOT NULL,
            `priority` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_dept` (`department`, `id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_ipad_dept_bolos` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `department` VARCHAR(32) NOT NULL,
            `plate` VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN',
            `description` VARCHAR(400) NOT NULL,
            `author_name` VARCHAR(80) NOT NULL,
            `author_identifier` VARCHAR(60) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_dept` (`department`, `id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_mdt_cases` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `department` VARCHAR(32) NOT NULL,
            `suspect_name` VARCHAR(80) NOT NULL,
            `suspect_identifier` VARCHAR(80) DEFAULT NULL,
            `charges` VARCHAR(255) NOT NULL,
            `notes` VARCHAR(500) DEFAULT NULL,
            `officer_name` VARCHAR(80) NOT NULL,
            `officer_identifier` VARCHAR(80) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_dept` (`department`, `id`),
            KEY `idx_suspect` (`suspect_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

CreateThread(function()
    EnsureTables()
end)

local function listAnnouncements(dept, limit)
    limit = math.min(math.max(tonumber(limit) or 40, 1), 80)
    local rows = MySQL.query.await([[
        SELECT id, title, body, author_name, priority, created_at
        FROM grim_ipad_dept_announcements
        WHERE department = ?
        ORDER BY id DESC
        LIMIT ?
    ]], { dept, limit }) or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = tonumber(row.id),
            title = row.title,
            body = row.body,
            author = row.author_name,
            priority = row.priority == 1 or row.priority == true,
            createdAt = row.created_at and tostring(row.created_at) or nil,
        }
    end
    return out
end

local function listBolos(dept, limit)
    limit = math.min(math.max(tonumber(limit) or 40, 1), 80)
    local rows = MySQL.query.await([[
        SELECT id, plate, description, author_name, created_at
        FROM grim_ipad_dept_bolos
        WHERE department = ?
        ORDER BY id DESC
        LIMIT ?
    ]], { dept, limit }) or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = tonumber(row.id),
            plate = row.plate,
            description = row.description,
            author = row.author_name,
            createdAt = row.created_at and tostring(row.created_at) or nil,
        }
    end
    return out
end

------------------------------------------------------------
-- Boss
------------------------------------------------------------

lib.callback.register('cfx-keydi-ipad:dept:dashboard', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local dept = type(data) == 'table' and data.department or nil
    local cfg = deptConfig(dept)
    if not cfg or not isDeptBoss(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local staff, grades = employees(cfg)
    return {
        ok = true,
        department = dept,
        job = cfg.primaryJob,
        label = cfg.label or dept,
        funds = getFunds(cfg),
        ledger = getLedger(cfg),
        employees = staff,
        grades = grades,
        announcements = listAnnouncements(dept, 30),
        yourGrade = tonumber(xPlayer.job and xPlayer.job.grade) or 99,
        onlineCount = #onlineUnits(cfg),
    }
end)

lib.callback.register('cfx-keydi-ipad:dept:transfer', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not isDeptBoss(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local action = data.action
    local amount = math.floor(tonumber(data.amount) or 0)
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
        local added, err = addFunds(cfg, amount, xPlayer.identifier, 'iPad dept deposit')
        if not added then
            ox_inventory:AddItem(source, 'money', amount)
            return { ok = false, error = err or 'failed' }
        end
    else
        local removed, err = removeFunds(cfg, amount, xPlayer.identifier, 'iPad dept withdraw')
        if not removed then
            return { ok = false, error = err == 'insufficient' and 'no_funds' or (err or 'failed') }
        end
        if not ox_inventory:AddItem(source, 'money', amount) then
            addFunds(cfg, amount, xPlayer.identifier, 'iPad dept withdraw refund')
            return { ok = false, error = 'inventory_full' }
        end
    end

    return { ok = true, funds = getFunds(cfg), ledger = getLedger(cfg) }
end)

lib.callback.register('cfx-keydi-ipad:dept:hire', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not isDeptBoss(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local targetId = tonumber(data.id)
    local grade = math.floor(tonumber(data.grade) or 0)
    if not targetId or targetId == source then
        return { ok = false, error = 'invalid' }
    end

    local yourGrade = tonumber(xPlayer.job and xPlayer.job.grade) or 0
    if isOwnerDev(xPlayer) then yourGrade = 99 end
    if grade < 0 or grade >= yourGrade then
        return { ok = false, error = 'grade' }
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return { ok = false, error = 'offline' } end
    if not isNearPlayer(source, targetId) then return { ok = false, error = 'far' } end

    local ok, err = applyDeptJob(xTarget, cfg, grade, ('You were hired into %s.'):format(cfg.label or cfg.primaryJob))
    if not ok then return { ok = false, error = err or 'failed' } end
    local staff, grades = employees(cfg)
    return { ok = true, employees = staff, grades = grades }
end)

lib.callback.register('cfx-keydi-ipad:dept:setGrade', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not isDeptBoss(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local identifier = data.identifier
    local grade = math.floor(tonumber(data.grade) or -1)
    if type(identifier) ~= 'string' or identifier == '' or grade < 0 then
        return { ok = false, error = 'invalid' }
    end
    if identifier == xPlayer.identifier then
        return { ok = false, error = 'self' }
    end

    local yourGrade = tonumber(xPlayer.job and xPlayer.job.grade) or 0
    if isOwnerDev(xPlayer) then yourGrade = 99 end
    if grade >= yourGrade then
        return { ok = false, error = 'grade' }
    end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        if not xTarget.job or not jobInList(xTarget.job.name, cfg.jobs) then
            return { ok = false, error = 'not_employee' }
        end
        if (tonumber(xTarget.job.grade) or 0) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        local ok, err = applyDeptJob(
            xTarget,
            cfg,
            grade,
            ('Your %s rank is now grade %s.'):format(cfg.label or cfg.primaryJob, grade)
        )
        if not ok then return { ok = false, error = err or 'failed' } end
    else
        local row = MySQL.single.await('SELECT job, job_grade FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or not jobInList(row.job, cfg.jobs) then
            return { ok = false, error = 'not_employee' }
        end
        if (tonumber(row.job_grade) or 0) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        -- Keep offline players on their current on/off job; only bump grade.
        local jobName = row.job
        if ESX.DoesJobExist and not ESX.DoesJobExist(jobName, grade) then
            jobName = cfg.primaryJob
        end
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { jobName, grade, identifier })
        syncMultijobGrade(identifier, cfg.primaryJob, grade, false)
    end

    local staff, grades = employees(cfg)
    return { ok = true, employees = staff, grades = grades }
end)

lib.callback.register('cfx-keydi-ipad:dept:fire', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not isDeptBoss(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local identifier = data.identifier
    if type(identifier) ~= 'string' or identifier == '' then
        return { ok = false, error = 'invalid' }
    end
    if identifier == xPlayer.identifier then
        return { ok = false, error = 'self' }
    end

    local yourGrade = tonumber(xPlayer.job and xPlayer.job.grade) or 0
    if isOwnerDev(xPlayer) then yourGrade = 99 end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        if not xTarget.job or not jobInList(xTarget.job.name, cfg.jobs) then
            return { ok = false, error = 'not_employee' }
        end
        if (tonumber(xTarget.job.grade) or 0) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        xTarget.setJob('unemployed', 0, false)
        local tid = xTarget.identifier or (xTarget.getIdentifier and xTarget.getIdentifier())
        if tid then
            MySQL.update.await('UPDATE `users` SET `job` = ?, `job_grade` = ? WHERE `identifier` = ?', {
                'unemployed', 0, tid
            })
            MySQL.update.await('DELETE FROM `player_multijobs` WHERE `identifier` = ? AND `job` = ?', {
                tid, cfg.primaryJob
            })
        end
        if Core and Core.SavePlayer then
            pcall(Core.SavePlayer, xTarget)
        end
        TriggerClientEvent('esx:showNotification', xTarget.source, ('You were removed from %s.'):format(cfg.label or cfg.primaryJob), 'error')
    else
        local row = MySQL.single.await('SELECT job, job_grade FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or not jobInList(row.job, cfg.jobs) then
            return { ok = false, error = 'not_employee' }
        end
        if (tonumber(row.job_grade) or 0) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { 'unemployed', 0, identifier })
        MySQL.update.await('DELETE FROM `player_multijobs` WHERE `identifier` = ? AND `job` = ?', {
            identifier, cfg.primaryJob
        })
    end

    local staff, grades = employees(cfg)
    return { ok = true, employees = staff, grades = grades }
end)

lib.callback.register('cfx-keydi-ipad:dept:announce', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not isDeptBoss(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local title = type(data.title) == 'string' and data.title:gsub('^%s+', ''):gsub('%s+$', '') or ''
    local body = type(data.body) == 'string' and data.body:gsub('^%s+', ''):gsub('%s+$', '') or ''
    if #title < 2 or #body < 2 then
        return { ok = false, error = 'invalid' }
    end
    title = title:sub(1, 120)
    body = body:sub(1, 500)
    local priority = data.priority and true or false

    MySQL.insert.await(
        [[INSERT INTO grim_ipad_dept_announcements (department, title, body, author_name, author_identifier, priority)
          VALUES (?, ?, ?, ?, ?, ?)]],
        { dept, title, body, playerDisplayName(xPlayer), xPlayer.identifier, priority and 1 or 0 }
    )

    return { ok = true, announcements = listAnnouncements(dept, 30) }
end)

local function likeQuery(query)
    if type(query) ~= 'string' then return nil end
    local q = query:gsub('^%s+', ''):gsub('%s+$', '')
    if q == '' then return nil end
    q = q:gsub('[%%_]', '')
    if #q < 2 then return nil end
    return '%' .. q:sub(1, 60) .. '%'
end

local function listMdtCases(dept, query, limit)
    limit = math.min(math.max(tonumber(limit) or 40, 1), 80)
    local like = likeQuery(query)
    local okRows, rowsOrErr = pcall(function()
        if like then
            return MySQL.query.await([[
                SELECT id, suspect_name, suspect_identifier, charges, notes, officer_name, created_at
                FROM grim_mdt_cases
                WHERE department = ?
                  AND (suspect_name LIKE ? OR charges LIKE ? OR notes LIKE ? OR officer_name LIKE ?)
                ORDER BY id DESC
                LIMIT ?
            ]], { dept, like, like, like, like, limit }) or {}
        end
        return MySQL.query.await([[
            SELECT id, suspect_name, suspect_identifier, charges, notes, officer_name, created_at
            FROM grim_mdt_cases
            WHERE department = ?
            ORDER BY id DESC
            LIMIT ?
        ]], { dept, limit }) or {}
    end)
    local rows = (okRows and type(rowsOrErr) == 'table') and rowsOrErr or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = tonumber(row.id),
            source = 'mdt',
            suspectName = row.suspect_name,
            identifier = row.suspect_identifier,
            charges = row.charges,
            notes = row.notes,
            officerName = row.officer_name,
            createdAt = row.created_at and tostring(row.created_at) or nil,
        }
    end

    local needle = like and query:gsub('^%s+', ''):gsub('%s+$', ''):lower() or nil
    local ok, docs = pcall(function()
        return MySQL.query.await([[
            SELECT id, data FROM k5_documents WHERE isCopy = 0 ORDER BY id DESC LIMIT 60
        ]])
    end)
    if ok and type(docs) == 'table' then
        for i = 1, #docs do
            local decoded = docs[i].data
            local parsed
            if type(decoded) == 'string' and decoded ~= '' then
                local pok, val = pcall(json.decode, decoded)
                if pok and type(val) == 'table' then parsed = val end
            elseif type(decoded) == 'table' then
                parsed = decoded
            end
            if type(parsed) == 'table' then
                local title = parsed.documentName or parsed.name or parsed.type or 'Report'
                local suspect, charges, location
                if type(parsed.fields) == 'table' then
                    for f = 1, #parsed.fields do
                        local field = parsed.fields[f]
                        if type(field) == 'table' then
                            local fname = tostring(field.name or ''):lower()
                            local fval = tostring(field.value or '')
                            if fname:find('suspect', 1, true) or fname:find('driver', 1, true) then
                                suspect = fval
                            elseif fname:find('charge', 1, true) or fname:find('violation', 1, true) then
                                charges = fval
                            elseif fname:find('location', 1, true) then
                                location = fval
                            end
                        end
                    end
                end
                local hay = table.concat({
                    tostring(title), tostring(suspect or ''), tostring(charges or ''), tostring(location or '')
                }, ' '):lower()
                if not needle or hay:find(needle, 1, true) then
                    out[#out + 1] = {
                        id = 'doc-' .. tostring(docs[i].id),
                        source = 'document',
                        suspectName = (suspect and suspect ~= '') and suspect or 'Unknown',
                        charges = (charges and charges ~= '') and charges or title,
                        notes = location,
                        officerName = title,
                        createdAt = nil,
                    }
                end
            end
        end
    end

    return out
end

local function listMdtFines(query, limit)
    limit = math.min(math.max(tonumber(limit) or 40, 1), 80)
    local like = likeQuery(query)
    local ok, rows = pcall(function()
        if like then
            return MySQL.query.await([[
                SELECT id, reference, title, description, total, status, sender_name, sender_job,
                       receiver_name, receiver_identifier, created_at
                FROM keydi_invoices
                WHERE sender_job IN ('police', 'sheriff', 'doj')
                  AND (receiver_name LIKE ? OR title LIKE ? OR reference LIKE ? OR description LIKE ?)
                ORDER BY id DESC
                LIMIT ?
            ]], { like, like, like, like, limit })
        end
        return MySQL.query.await([[
            SELECT id, reference, title, description, total, status, sender_name, sender_job,
                   receiver_name, receiver_identifier, created_at
            FROM keydi_invoices
            WHERE sender_job IN ('police', 'sheriff', 'doj')
            ORDER BY id DESC
            LIMIT ?
        ]], { limit })
    end)
    if not ok or type(rows) ~= 'table' then
        return {}
    end

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = tonumber(row.id),
            reference = row.reference,
            title = row.title,
            description = row.description,
            total = tonumber(row.total) or 0,
            status = row.status,
            officerName = row.sender_name,
            citizenName = row.receiver_name,
            identifier = row.receiver_identifier,
            createdAt = row.created_at and tostring(row.created_at) or nil,
        }
    end
    return out
end

------------------------------------------------------------
-- MDT (police / sheriff)
------------------------------------------------------------

lib.callback.register('cfx-keydi-ipad:mdt:dashboard', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local dept = type(data) == 'table' and data.department or nil
    local cfg = deptConfig(dept)
    if not cfg or not cfg.mdt or not canAccessMdt(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local units = onlineUnits(cfg)
    local announcements = listAnnouncements(dept, 40)
    local bolos = listBolos(dept, 40)
    local cases = listMdtCases(dept, nil, 40)
    local fines = listMdtFines(nil, 40)

    return {
        ok = true,
        department = dept,
        label = cfg.label or dept,
        units = units,
        announcements = announcements,
        bolos = bolos,
        cases = cases,
        fines = fines,
        onlineCount = #units,
        canAnnounce = isDeptBoss(xPlayer, dept),
    }
end)

lib.callback.register('cfx-keydi-ipad:mdt:addBolo', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not cfg.mdt or not canAccessMdt(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local plate = type(data.plate) == 'string' and data.plate:gsub('^%s+', ''):gsub('%s+$', ''):upper() or 'UNKNOWN'
    local description = type(data.description) == 'string' and data.description:gsub('^%s+', ''):gsub('%s+$', '') or ''
    if #description < 3 then
        return { ok = false, error = 'invalid' }
    end
    if plate == '' then plate = 'UNKNOWN' end
    plate = plate:sub(1, 20)
    description = description:sub(1, 400)

    MySQL.insert.await(
        [[INSERT INTO grim_ipad_dept_bolos (department, plate, description, author_name, author_identifier)
          VALUES (?, ?, ?, ?, ?)]],
        { dept, plate, description, playerDisplayName(xPlayer), xPlayer.identifier }
    )

    return { ok = true, bolos = listBolos(dept, 40) }
end)

lib.callback.register('cfx-keydi-ipad:mdt:removeBolo', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not cfg.mdt or not canAccessMdt(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local id = tonumber(data.id)
    if not id then return { ok = false, error = 'invalid' } end

    MySQL.update.await('DELETE FROM grim_ipad_dept_bolos WHERE id = ? AND department = ?', { id, dept })
    return { ok = true, bolos = listBolos(dept, 40) }
end)

lib.callback.register('cfx-keydi-ipad:mdt:search', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not cfg.mdt or not canAccessMdt(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end
    local query = type(data.query) == 'string' and data.query or ''
    return {
        ok = true,
        cases = listMdtCases(dept, query, 40),
        fines = listMdtFines(query, 40),
    }
end)

lib.callback.register('cfx-keydi-ipad:mdt:addCase', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data = type(data) == 'table' and data or {}
    local dept = data.department
    local cfg = deptConfig(dept)
    if not cfg or not cfg.mdt or not canAccessMdt(xPlayer, dept) then
        return { ok = false, error = 'denied' }
    end

    local suspect = type(data.suspectName) == 'string' and data.suspectName:gsub('^%s+', ''):gsub('%s+$', '') or ''
    local charges = type(data.charges) == 'string' and data.charges:gsub('^%s+', ''):gsub('%s+$', '') or ''
    local notes = type(data.notes) == 'string' and data.notes:gsub('^%s+', ''):gsub('%s+$', '') or ''
    if #suspect < 2 or #charges < 2 then
        return { ok = false, error = 'invalid' }
    end
    suspect = suspect:sub(1, 80)
    charges = charges:sub(1, 255)
    notes = notes:sub(1, 500)

    MySQL.insert.await(
        [[INSERT INTO grim_mdt_cases
            (department, suspect_name, charges, notes, officer_name, officer_identifier)
          VALUES (?, ?, ?, ?, ?, ?)]],
        { dept, suspect, charges, notes, playerDisplayName(xPlayer), xPlayer.identifier }
    )

    return { ok = true, cases = listMdtCases(dept, nil, 40) }
end)

-- Session helpers for economy.lua (optional export)
exports('IsDeptBoss', function(src, dept)
    return isDeptBoss(ESX.GetPlayerFromId(src), dept)
end)

exports('IsDeptMember', function(src, dept)
    return isDeptMember(ESX.GetPlayerFromId(src), dept)
end)

exports('ResolvePlayerDept', function(src)
    return resolvePlayerDept(ESX.GetPlayerFromId(src))
end)

