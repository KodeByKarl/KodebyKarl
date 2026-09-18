local ESX = exports['es_extended']:getSharedObject()

local jobsCache = nil
local jobsCacheAt = 0
local JOBS_CACHE_MS = 15000

local function isOwnerDev(xPlayer)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local groups = ConfigIpad.EconomyGroups or { owner = true, developer = true }
    return groups[group] == true
end

local function isPoliceJob(jobName)
    local map = ConfigIpad.PoliceJobs or { police = true, offpolice = true }
    return jobName and map[jobName] == true
end

local function isPoliceBoss(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    if not isPoliceJob(xPlayer.job.name) then return false end
    local gradeName = xPlayer.job.grade_name
    if gradeName == 'boss' or gradeName == 'director' or gradeName == 'chief' then
        return true
    end
    local minGrade = tonumber(ConfigIpad.PoliceBossMinGrade) or 5
    return (tonumber(xPlayer.job.grade) or 0) >= minGrade
end

local function orgGangAllowed(gangName)
    if not gangName or gangName == '' or gangName == 'none' then return false end
    gangName = tostring(gangName):lower()
    if GetResourceState('kodebykarl-gangsystem') ~= 'started' then return false end
    local ok, gangs = pcall(function()
        return exports['kodebykarl-gangsystem']:GetGangs()
    end)
    return ok and type(gangs) == 'table' and gangs[gangName] ~= nil
end

local function isOrgBoss(xPlayer)
    if not xPlayer then return false end
    local gang = xPlayer.getGang and xPlayer.getGang() or xPlayer.gang
    if type(gang) ~= 'table' or not gang.name then return false end
    if not orgGangAllowed(gang.name) then return false end

    if GetResourceState('kodebykarl-gangsystem') == 'started' then
        local ok, result = pcall(function()
            return exports['kodebykarl-gangsystem']:IsBoss(xPlayer.source, gang.name)
        end)
        if ok then return result == true end
    end

    local gradeName = type(gang.grade_name) == 'string' and gang.grade_name:lower():gsub('%s+', '_') or ''
    if gradeName == 'boss' or gradeName == 'underboss' or gradeName == 'patron' then
        return true
    end
    return (tonumber(gang.grade) or 0) >= 3
end

local function isBusinessBoss(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    local jobs = ConfigIpad.BusinessJobs or {}
    if not jobs[xPlayer.job.name] then return false end
    local gradeName = type(xPlayer.job.grade_name) == 'string' and xPlayer.job.grade_name:lower() or ''
    if gradeName == 'boss' or gradeName == 'owner' or gradeName == 'director' then
        return true
    end
    local minGrade = tonumber(ConfigIpad.BusinessBossMinGrade)
    if minGrade and (tonumber(xPlayer.job.grade) or 0) >= minGrade then
        return true
    end
    local allJobs = ESX.GetJobs() or {}
    local job = allJobs[xPlayer.job.name]
    local maxGrade = 0
    if job and job.grades then
        for key, grade in pairs(job.grades) do
            local g = tonumber(grade.grade) or tonumber(key) or 0
            if g > maxGrade then maxGrade = g end
        end
    end
    return maxGrade > 0 and (tonumber(xPlayer.job.grade) or 0) >= maxGrade
end

local function resolveUniversityRole(xPlayer)
    if not xPlayer or not xPlayer.job then return 'visitor' end
    local jobName = xPlayer.job.name
    local jobs = ConfigIpad.UniversityJobs or { school = true, student = true, teacher = true }
    if not jobs[jobName] then
        return 'visitor'
    end

    local gradeName = type(xPlayer.job.grade_name) == 'string' and xPlayer.job.grade_name:lower() or ''
    local map = ConfigIpad.UniversityGradeRoles or {}
    if map[gradeName] then
        return map[gradeName]
    end

    if jobName == 'student' then return 'student' end
    if jobName == 'teacher' then
        local grade = tonumber(xPlayer.job.grade) or 0
        return grade >= 1 and 'dean' or 'teacher'
    end

    -- school job fallback by numeric grade (install SQL: 0 student, 1 professor, 2 director)
    local grade = tonumber(xPlayer.job.grade) or 0
    if grade >= 2 then return 'director' end
    if grade >= 1 then return 'teacher' end
    return 'student'
end

local function serializeJobs()
    local now = GetGameTimer()
    if jobsCache and (now - jobsCacheAt) < JOBS_CACHE_MS then
        return jobsCache
    end

    local jobs = ESX.GetJobs() or {}
    local list = {}

    for name, job in pairs(jobs) do
        local grades = {}
        for gradeKey, grade in pairs(job.grades or {}) do
            grades[#grades + 1] = {
                grade = tonumber(grade.grade) or tonumber(gradeKey) or 0,
                name = grade.name or tostring(gradeKey),
                label = grade.label or grade.name or ('Grade ' .. tostring(gradeKey)),
                salary = tonumber(grade.salary) or 0,
            }
        end
        table.sort(grades, function(a, b)
            return a.grade < b.grade
        end)

        list[#list + 1] = {
            name = name,
            label = job.label or name,
            grades = grades,
        }
    end

    table.sort(list, function(a, b)
        return (a.label or a.name):lower() < (b.label or b.name):lower()
    end)

    jobsCache = list
    jobsCacheAt = now
    return list
end

local function invalidateJobsCache()
    jobsCache = nil
    jobsCacheAt = 0
end

local function syncOnlineJobPlayers(jobName, grade)
    local gradeNum = tonumber(grade)
    local players = ESX.GetExtendedPlayers('job', jobName) or {}
    for i = 1, #players do
        local xP = players[i]
        if xP and xP.job and tonumber(xP.job.grade) == gradeNum then
            local onDuty = xP.job.onDuty
            if onDuty == nil then onDuty = true end
            local ok, err = pcall(function()
                xP.setJob(jobName, gradeNum, onDuty)
            end)
            if not ok then
                print(('[kodebykarl-ui] economy sync setJob failed: %s'):format(tostring(err)))
            end
        end
    end
end

local function isDeptBossFor(xPlayer, dept)
    if not xPlayer then return false end
    if isOwnerDev(xPlayer) then return true end
    local cfg = ConfigIpad.Departments and ConfigIpad.Departments[dept]
    if not cfg or not xPlayer.job then return false end
    local jobName = xPlayer.job.name
    local jobs = cfg.jobs or {}
    local matched = false
    for i = 1, #jobs do
        if jobs[i] == jobName then matched = true break end
    end
    if not matched then return false end
    local gradeName = type(xPlayer.job.grade_name) == 'string' and xPlayer.job.grade_name:lower() or ''
    local names = cfg.bossGradeNames or { boss = true, director = true, chief = true }
    if names[gradeName] then return true end
    local minGrade = tonumber(cfg.bossMinGrade) or tonumber(ConfigIpad.PoliceBossMinGrade) or 5
    return (tonumber(xPlayer.job.grade) or 0) >= minGrade
end

local function isDeptMemberFor(xPlayer, dept)
    if not xPlayer then return false end
    if isOwnerDev(xPlayer) then return true end
    local cfg = ConfigIpad.Departments and ConfigIpad.Departments[dept]
    if not cfg or not xPlayer.job then return false end
    local jobName = xPlayer.job.name
    local jobs = cfg.jobs or {}
    for i = 1, #jobs do
        if jobs[i] == jobName then return true end
    end
    return false
end

--- Single lightweight open-session payload (permissions only — client fills cash/job locally)
lib.callback.register('cfx-keydi-ipad:session', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return {
            canEditEconomy = false,
            canPoliceBoss = false,
            canSheriffBoss = false,
            canAmbulanceBoss = false,
            canPambulanceBoss = false,
            canSambulanceBoss = false,
            canDojBoss = false,
            canPoliceMdt = false,
            canSheriffMdt = false,
            canBusinessBoss = false,
            canOrgBoss = false,
            universityRole = 'visitor',
        }
    end

    -- Owner / Developer: full iPad app visibility (boss/business/org removed)
    if isOwnerDev(xPlayer) then
        local uni = resolveUniversityRole(xPlayer)
        if uni == 'visitor' then uni = 'director' end
        return {
            canEditEconomy = true,
            canPoliceBoss = false,
            canSheriffBoss = false,
            canAmbulanceBoss = false,
            canPambulanceBoss = false,
            canSambulanceBoss = false,
            canDojBoss = false,
            canPoliceMdt = true,
            canSheriffMdt = true,
            canBusinessBoss = false,
            canOrgBoss = false,
            universityRole = uni,
        }
    end

    local jobName = xPlayer.job and xPlayer.job.name or nil
    return {
        canEditEconomy = false,
        canPoliceBoss = false,
        canSheriffBoss = false,
        canAmbulanceBoss = false,
        canPambulanceBoss = false,
        canSambulanceBoss = false,
        canDojBoss = false,
        canPoliceMdt = isDeptMemberFor(xPlayer, 'police') or isDeptMemberFor(xPlayer, 'doj'),
        canSheriffMdt = isDeptMemberFor(xPlayer, 'sheriff'),
        canBusinessBoss = false,
        canOrgBoss = false,
        universityRole = resolveUniversityRole(xPlayer),
        jobName = jobName,
    }
end)

lib.callback.register('cfx-keydi-ipad:economy:canAccess', function(source)
    return isOwnerDev(ESX.GetPlayerFromId(source))
end)

lib.callback.register('cfx-keydi-ipad:economy:getJobs', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isOwnerDev(xPlayer) then
        return { ok = false, error = 'denied', jobs = {} }
    end
    return { ok = true, jobs = serializeJobs() }
end)

lib.callback.register('cfx-keydi-ipad:economy:setSalary', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isOwnerDev(xPlayer) then
        return { ok = false, error = 'denied' }
    end

    if type(data) ~= 'table' then
        return { ok = false, error = 'invalid' }
    end

    local jobName = data.job or data.jobName
    if type(jobName) ~= 'string' or jobName == '' then
        return { ok = false, error = 'invalid' }
    end

    local grade = tonumber(data.grade)
    local salary = tonumber(data.salary)
    if grade == nil or salary == nil then
        return { ok = false, error = 'invalid' }
    end

    if salary < 0 then salary = 0 end
    -- INT column hard limit (signed)
    if salary > 2147483647 then salary = 2147483647 end
    salary = math.floor(salary + 0.0)

    local jobs = ESX.GetJobs() or {}
    local job = jobs[jobName]
    if not job or not job.grades then
        return { ok = false, error = 'job_not_found' }
    end

    local gradeKey = tostring(grade)
    local gradeData = job.grades[gradeKey]
    if not gradeData then
        -- fallback: match by numeric grade field
        for key, row in pairs(job.grades) do
            if tonumber(row.grade) == grade or tonumber(key) == grade then
                gradeData = row
                gradeKey = tostring(key)
                break
            end
        end
    end
    if not gradeData then
        return { ok = false, error = 'grade_not_found' }
    end

    local okUpdate, affectedOrErr = pcall(function()
        if gradeData.id then
            return MySQL.update.await(
                'UPDATE job_grades SET salary = ? WHERE id = ?',
                { salary, gradeData.id }
            )
        end
        return MySQL.update.await(
            'UPDATE job_grades SET salary = ? WHERE job_name = ? AND grade = ?',
            { salary, jobName, grade }
        )
    end)

    if not okUpdate then
        print(('[kodebykarl-ui] economy setSalary MySQL error: %s'):format(tostring(affectedOrErr)))
        return { ok = false, error = 'db_failed' }
    end

    -- Verify persisted value (don't trust affected-rows alone — 0 when value unchanged)
    local dbSalary = MySQL.scalar.await(
        'SELECT salary FROM job_grades WHERE job_name = ? AND grade = ? LIMIT 1',
        { jobName, grade }
    )
    if tonumber(dbSalary) ~= salary then
        -- retry by id if present
        if gradeData.id then
            dbSalary = MySQL.scalar.await(
                'SELECT salary FROM job_grades WHERE id = ? LIMIT 1',
                { gradeData.id }
            )
        end
    end
    if tonumber(dbSalary) ~= salary then
        print(('[kodebykarl-ui] economy setSalary verify failed job=%s grade=%s want=%s got=%s'):format(
            jobName, tostring(grade), tostring(salary), tostring(dbSalary)
        ))
        return { ok = false, error = 'db_failed' }
    end

    -- Reload ESX job table from DB so paycheck + other resources see the new salary
    if ESX.RefreshJobs then
        ESX.RefreshJobs()
    else
        gradeData.salary = salary
    end

    invalidateJobsCache()

    -- Sync online players after responding — never block / fail the save on setJob issues
    CreateThread(function()
        syncOnlineJobPlayers(jobName, grade)
    end)

    return {
        ok = true,
        job = jobName,
        grade = grade,
        salary = salary,
        jobs = serializeJobs(),
    }
end)

------------------------------------------------------------
-- Load Department Boss + MDT (dept.lua) — guaranteed with economy
------------------------------------------------------------
do
    local path = 'Module/cfx-keydi-ipad/server/dept.lua'
    local src = LoadResourceFile(GetCurrentResourceName(), path)
    if not src then
        print('^1[cfx-keydi-ipad]^0 FATAL: missing ' .. path)
    else
        local chunk, err = load(src, ('@%s/%s'):format(GetCurrentResourceName(), path))
        if not chunk then
            print('^1[cfx-keydi-ipad]^0 dept.lua compile error: ' .. tostring(err))
        else
            local ok, runtimeErr = xpcall(chunk, function(e)
                return tostring(e) .. '\n' .. tostring(debug and debug.traceback and debug.traceback() or '')
            end)
            if not ok then
                print('^1[cfx-keydi-ipad]^0 dept.lua runtime error: ' .. tostring(runtimeErr))
            end
        end
    end
end
