local ESX = exports['es_extended']:getSharedObject()

local tableReady = false

local function cfg()
    return ConfigUniversity or {}
end

local function notify(src, msg, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = (cfg().Label or 'ULS Registrar'),
        description = msg,
        type = nType or 'inform',
    })
end

local function ensureTable()
    if tableReady then return true end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `university_applications` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `identifier` VARCHAR(72) NOT NULL,
          `citizen_name` VARCHAR(128) NOT NULL DEFAULT '',
          `program_id` VARCHAR(32) NOT NULL,
          `program_code` VARCHAR(16) NOT NULL,
          `program_label` VARCHAR(128) NOT NULL,
          `status` ENUM('pending','approved','denied','cancelled') NOT NULL DEFAULT 'pending',
          `reviewed_by` VARCHAR(72) DEFAULT NULL,
          `reviewed_name` VARCHAR(128) DEFAULT NULL,
          `note` VARCHAR(255) DEFAULT NULL,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_university_apps_identifier` (`identifier`),
          KEY `idx_university_apps_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    tableReady = true
    return true
end

MySQL.ready(function()
    ensureTable()
end)

local function getProgram(programId)
    local list = cfg().Programs or {}
    for i = 1, #list do
        if list[i].id == programId then
            return list[i]
        end
    end
end

local function playerName(xPlayer)
    if xPlayer.getName then return xPlayer.getName() end
    return xPlayer.name or 'Unknown'
end

local function isAlreadyStudent(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    local job = xPlayer.job.name
    local studentJob = cfg().StudentJob or 'school'
    if job == studentJob or job == 'student' then
        return true
    end
    return false
end

local function getPending(identifier)
    ensureTable()
    return MySQL.single.await(
        'SELECT * FROM university_applications WHERE identifier = ? AND status = ? ORDER BY id DESC LIMIT 1',
        { identifier, 'pending' }
    )
end

local function serializeApp(row)
    if not row then return nil end
    return {
        id = row.id,
        identifier = row.identifier,
        citizenName = row.citizen_name,
        programId = row.program_id,
        programCode = row.program_code,
        programLabel = row.program_label,
        status = row.status,
        reviewedBy = row.reviewed_name,
        note = row.note,
        createdAt = row.created_at and tostring(row.created_at) or nil,
    }
end

local function canApprove(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    local jobs = ConfigIpad and ConfigIpad.UniversityJobs or { school = true, teacher = true }
    local jobName = xPlayer.job.name
    if not jobs[jobName] and jobName ~= 'school' and jobName ~= 'teacher' then
        -- still allow via grade map if school-ish
    end

    local gradeName = type(xPlayer.job.grade_name) == 'string' and xPlayer.job.grade_name:lower() or ''
    local roleMap = ConfigIpad and ConfigIpad.UniversityGradeRoles or {}
    local role = roleMap[gradeName]
    if not role then
        local grade = tonumber(xPlayer.job.grade) or 0
        if jobName == 'teacher' and grade >= 1 then role = 'dean'
        elseif jobName == 'school' and grade >= 2 then role = 'director'
        elseif gradeName == 'dean' then role = 'dean'
        elseif gradeName == 'director' or gradeName == 'boss' then role = 'director'
        end
    end

    local allowed = cfg().ApproverRoles or { dean = true, director = true }
    return role and allowed[role] == true
end

lib.callback.register('cfx-keydi-university:registrar:open', function(source)
    if cfg().Enabled == false then
        return { ok = false, error = 'disabled' }
    end

    if ConfigServerLocations and ConfigServerLocations.CanUseFunction then
        if not ConfigServerLocations.CanUseFunction('school', source) then
            notify(source, ConfigServerLocations.WrongServerMessage('school'), 'error')
            return { ok = false, error = 'region' }
        end
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'no_player' } end

    ensureTable()
    local pending = getPending(xPlayer.identifier)
    local programs = {}
    for _, p in ipairs(cfg().Programs or {}) do
        programs[#programs + 1] = { id = p.id, code = p.code, label = p.label }
    end

    return {
        ok = true,
        brand = cfg().Brand or 'Keydi.dev',
        label = cfg().Label or 'ULS Registrar',
        citizenName = playerName(xPlayer),
        alreadyStudent = isAlreadyStudent(xPlayer),
        application = serializeApp(pending),
        programs = programs,
    }
end)

lib.callback.register('cfx-keydi-university:registrar:apply', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'no_player' } end
    if ConfigServerLocations and ConfigServerLocations.CanUseFunction then
        if not ConfigServerLocations.CanUseFunction('school', source) then
            return { ok = false, error = 'region', message = ConfigServerLocations.WrongServerMessage('school') }
        end
    end
    if isAlreadyStudent(xPlayer) then
        return { ok = false, error = 'already_student', message = cfg().Notify.alreadyStudent }
    end

    ensureTable()
    if getPending(xPlayer.identifier) then
        return { ok = false, error = 'already_pending', message = cfg().Notify.alreadyPending }
    end

    local programId = type(data) == 'table' and data.programId or nil
    local program = getProgram(programId)
    if not program then
        return { ok = false, error = 'bad_program', message = 'Select a valid course / program.' }
    end

    local id = MySQL.insert.await([[
        INSERT INTO university_applications
            (identifier, citizen_name, program_id, program_code, program_label, status)
        VALUES (?, ?, ?, ?, ?, 'pending')
    ]], {
        xPlayer.identifier,
        playerName(xPlayer),
        program.id,
        program.code,
        program.label,
    })

    if not id then
        return { ok = false, error = 'db', message = 'Could not save application.' }
    end

    notify(source, cfg().Notify.applied or 'Application submitted.', 'success')

    local pending = getPending(xPlayer.identifier)
    return { ok = true, application = serializeApp(pending) }
end)

lib.callback.register('cfx-keydi-university:registrar:cancel', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'no_player' } end

    ensureTable()
    local pending = getPending(xPlayer.identifier)
    if not pending then
        return { ok = false, error = 'none', message = 'No pending application to cancel.' }
    end

    MySQL.update.await(
        'UPDATE university_applications SET status = ? WHERE id = ? AND identifier = ?',
        { 'cancelled', pending.id, xPlayer.identifier }
    )

    notify(source, cfg().Notify.cancelled or 'Application cancelled.', 'inform')
    return { ok = true, application = nil }
end)

lib.callback.register('cfx-keydi-university:portal:pending', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not canApprove(xPlayer) then
        return { ok = false, error = 'denied', rows = {} }
    end

    ensureTable()
    local rows = MySQL.query.await([[
        SELECT * FROM university_applications
        WHERE status = 'pending'
        ORDER BY created_at ASC
        LIMIT 50
    ]]) or {}

    local list = {}
    for i = 1, #rows do
        list[#list + 1] = serializeApp(rows[i])
    end
    return { ok = true, rows = list }
end)

lib.callback.register('cfx-keydi-university:portal:review', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not canApprove(xPlayer) then
        return { ok = false, error = 'denied' }
    end

    data = type(data) == 'table' and data or {}
    local appId = tonumber(data.id)
    local decision = data.decision == 'deny' and 'denied' or 'approved'
    if not appId then return { ok = false, error = 'bad_id' } end

    ensureTable()
    local row = MySQL.single.await('SELECT * FROM university_applications WHERE id = ?', { appId })
    if not row or row.status ~= 'pending' then
        return { ok = false, error = 'not_pending', message = 'Application is no longer pending.' }
    end

    MySQL.update.await([[
        UPDATE university_applications
        SET status = ?, reviewed_by = ?, reviewed_name = ?, note = ?
        WHERE id = ?
    ]], {
        decision,
        xPlayer.identifier,
        playerName(xPlayer),
        type(data.note) == 'string' and data.note:sub(1, 250) or nil,
        appId,
    })

    local target = ESX.GetPlayerFromIdentifier(row.identifier)
    if decision == 'approved' then
        if target then
            local job = cfg().StudentJob or 'school'
            local grade = tonumber(cfg().StudentGrade) or 0
            target.setJob(job, grade)

            if cfg().GiveStudentId ~= false and cfg().StudentIdItem then
                pcall(function()
                    exports.ox_inventory:AddItem(target.source, cfg().StudentIdItem, 1)
                end)
            end

            notify(target.source, cfg().Notify.approved or 'Enrollment approved.', 'success')
            TriggerClientEvent('cfx-keydi-university:client:enrollmentUpdated', target.source, {
                role = 'student',
                program = row.program_label,
            })
        end
    else
        if target then
            notify(target.source, cfg().Notify.denied or 'Application denied.', 'error')
        end
    end

    local rows = MySQL.query.await([[
        SELECT * FROM university_applications WHERE status = 'pending' ORDER BY created_at ASC LIMIT 50
    ]]) or {}
    local list = {}
    for i = 1, #rows do
        list[#list + 1] = serializeApp(rows[i])
    end

    return { ok = true, decision = decision, rows = list }
end)

lib.callback.register('cfx-keydi-university:portal:myApplication', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false } end
    ensureTable()
    local pending = getPending(xPlayer.identifier)
    local latest = pending or MySQL.single.await(
        'SELECT * FROM university_applications WHERE identifier = ? ORDER BY id DESC LIMIT 1',
        { xPlayer.identifier }
    )
    return {
        ok = true,
        alreadyStudent = isAlreadyStudent(xPlayer),
        application = serializeApp(latest),
    }
end)
