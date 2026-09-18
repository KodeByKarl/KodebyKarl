--[[
    esx_society compatibility shims for lb-phone / legacy ESX scripts.
    Uses cfx-keydi-society DB balances instead of esx_addonaccount.
]]

local Societies = {} -- [jobName] = { name, label, account, ... }
local RES = GetCurrentResourceName()

local function GetBalance(account)
    return exports[RES]:GetBalance(account)
end

local function AddMoney(account, amount, identifier, note)
    return exports[RES]:AddMoney(account, amount, identifier, note)
end

local function RemoveMoney(account, amount, identifier, note)
    return exports[RES]:RemoveMoney(account, amount, identifier, note)
end

local function SetMoney(account, amount, identifier, note)
    return exports[RES]:SetMoney(account, amount, identifier, note)
end

local function EnsureAccount(account, label)
    return exports[RES]:EnsureAccount(account, label)
end

local function ResolveAccount(name)
    return exports[RES]:ResolveAccount(name)
end

local function AccountForJob(jobName)
    return exports[RES]:AccountForJob(jobName)
end

local function GetJobObject(jobName)
    if not jobName or jobName == '' then return nil end
    return ESX.Jobs and ESX.Jobs[jobName] or nil
end

---@param jobName string
---@return number
local function GetBossGrade(jobName)
    if Config.BossGrades and Config.BossGrades[jobName] ~= nil then
        return tonumber(Config.BossGrades[jobName]) or 0
    end

    local job = GetJobObject(jobName)
    if not job or not job.grades then return 0 end

    local maxGrade = 0
    for gradeKey, gradeData in pairs(job.grades) do
        local g = tonumber(gradeData and gradeData.grade) or tonumber(gradeKey) or 0
        if gradeData and type(gradeData.name) == 'string' and gradeData.name:lower() == 'boss' then
            return g
        end
        if g > maxGrade then maxGrade = g end
    end
    return maxGrade
end

---@param src number
---@param jobName? string
---@return boolean
local function IsBossOf(src, jobName)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
    if not job then return false end
    if jobName and jobName ~= '' and job.name ~= jobName then
        return false
    end

    local gradeName = job.grade_name or job.gradeName
    if type(gradeName) == 'string' and gradeName:lower() == 'boss' then
        return true
    end

    local bossGrade = GetBossGrade(job.name)
    return (tonumber(job.grade) or 0) >= bossGrade
end

---@param jobName string
---@return table grades as array
local function GetJobGradesArray(jobName)
    local job = GetJobObject(jobName)
    if not job or not job.grades then return {} end

    local list = {}
    for _, gradeData in pairs(job.grades) do
        list[#list + 1] = {
            grade = tonumber(gradeData.grade) or 0,
            name = gradeData.name,
            label = gradeData.label,
            salary = gradeData.salary,
        }
    end

    table.sort(list, function(a, b)
        return a.grade < b.grade
    end)

    return list
end

---@param societyName string
---@return string account
local function SocietyAccount(societyName)
    return ResolveAccount(societyName) or AccountForJob(societyName) or societyName
end

-- Server export (other server scripts) + callback for clients (lb-phone)
exports('GetBossGrade', GetBossGrade)

lib.callback.register('cfx-keydi-society:getBossGrade', function(_, jobName)
    return GetBossGrade(jobName)
end)

lib.callback.register('cfx-keydi-society:isBoss', function(source, jobName)
    return IsBossOf(source, jobName)
end)

-- lb-phone does not load ox_lib; use ESX callbacks from its client scripts
ESX.RegisterServerCallback('cfx-keydi-society:isBoss', function(source, cb, jobName)
    cb(IsBossOf(source, jobName))
end)

-- ---------------------------------------------------------------------------
-- Society registry (esx_society:registerSociety / getSociety)
-- ---------------------------------------------------------------------------

AddEventHandler('esx_society:registerSociety', function(name, label, account, datastore, inventory, data)
    if not name then return end
    local accountName = account or ('society_%s'):format(name)
    Societies[name] = {
        name = name,
        label = label or name,
        account = accountName,
        datastore = datastore,
        inventory = inventory,
        data = data,
    }
    EnsureAccount(accountName, label or name)
end)

AddEventHandler('esx_society:getSociety', function(name, cb)
    if type(cb) ~= 'function' then return end
    local society = Societies[name]
    if not society then
        local account = SocietyAccount(name)
        if account then
            EnsureAccount(account, name)
            society = { name = name, label = name, account = account }
        end
    end
    cb(society)
end)

-- Minimal addonaccount bridge so legacy getSharedAccount callers keep working
AddEventHandler('esx_addonaccount:getSharedAccount', function(accountName, cb)
    if type(cb) ~= 'function' then return end
    local account = SocietyAccount(accountName)
    EnsureAccount(account)

    cb({
        name = account,
        money = GetBalance(account),
        addMoney = function(amount)
            AddMoney(account, amount)
        end,
        removeMoney = function(amount)
            RemoveMoney(account, amount)
        end,
        setMoney = function(amount)
            SetMoney(account, amount)
        end,
    })
end)

-- ---------------------------------------------------------------------------
-- Callbacks used by lb-phone (Companies / boss app)
-- ---------------------------------------------------------------------------

ESX.RegisterServerCallback('esx_society:getSocietyMoney', function(source, cb, societyName)
    if not societyName then return cb(0) end
    cb(GetBalance(SocietyAccount(societyName)))
end)

ESX.RegisterServerCallback('esx_society:getEmployees', function(source, cb, society)
    if not society then return cb({}) end
    if not IsBossOf(source, society) then return cb({}) end

    local job = GetJobObject(society)
    local jobLabel = job and job.label or society

    local rows = MySQL.query.await([[
        SELECT identifier, firstname, lastname, job, job_grade
        FROM users
        WHERE job = ?
        ORDER BY job_grade DESC
    ]], { society }) or {}

    local employees = {}
    for i = 1, #rows do
        local row = rows[i]
        local grade = tostring(row.job_grade or 0)
        local gradeData = job and job.grades and job.grades[grade] or nil
        local first = row.firstname or ''
        local last = row.lastname or ''
        local displayName = (first ~= '' or last ~= '') and (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', '') or row.identifier

        employees[#employees + 1] = {
            name = displayName,
            identifier = row.identifier,
            job = {
                name = society,
                label = jobLabel,
                grade = tonumber(row.job_grade) or 0,
                grade_name = gradeData and gradeData.name or 'unknown',
                grade_label = gradeData and gradeData.label or ('Grade ' .. grade),
            },
        }
    end

    cb(employees)
end)

ESX.RegisterServerCallback('esx_society:getJob', function(source, cb, society)
    local job = GetJobObject(society)
    if not job then
        return cb({ name = society, label = society or 'Unknown', grades = {} })
    end

    cb({
        name = job.name,
        label = job.label,
        grades = GetJobGradesArray(society),
    })
end)

ESX.RegisterServerCallback('esx_society:getOnlinePlayers', function(source, cb)
    local players = {}
    local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}

    for _, xPlayer in pairs(xPlayers) do
        players[#players + 1] = {
            source = xPlayer.source,
            identifier = xPlayer.identifier,
            name = (xPlayer.getName and xPlayer.getName()) or xPlayer.name or GetPlayerName(xPlayer.source),
            job = xPlayer.job,
        }
    end

    cb(players)
end)

ESX.RegisterServerCallback('esx_society:setJob', function(source, cb, identifier, job, grade, actionType)
    cb = cb or function() end
    if not identifier or not job then return cb() end

    if actionType == 'hire' or actionType == 'promote' then
        if not IsBossOf(source, job) then return cb() end
    else
        if not IsBossOf(source) then return cb() end
    end

    grade = tonumber(grade) or 0

    local xTarget = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        xTarget.setJob(job, grade)
    else
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {
            job, grade, identifier
        })
    end

    cb()
end)

-- ---------------------------------------------------------------------------
-- Deposit / withdraw society funds
-- ---------------------------------------------------------------------------

RegisterNetEvent('esx_society:depositMoney', function(societyName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not societyName then return end
    if not IsBossOf(src, societyName) then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    if xPlayer.getMoney() < amount then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Society',
            description = 'Not enough cash to deposit.',
            type = 'error',
        })
    end

    xPlayer.removeMoney(amount, 'society_deposit')
    local ok = AddMoney(SocietyAccount(societyName), amount, xPlayer.identifier, 'boss_deposit')
    if not ok then
        xPlayer.addMoney(amount, 'society_deposit_refund')
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Society',
            description = 'Deposit failed.',
            type = 'error',
        })
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Society',
        description = ('Deposited $%s'):format(amount),
        type = 'success',
    })
end)

RegisterNetEvent('esx_society:withdrawMoney', function(societyName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not societyName then return end
    if not IsBossOf(src, societyName) then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    local ok = RemoveMoney(SocietyAccount(societyName), amount, xPlayer.identifier, 'boss_withdraw')
    if not ok then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Society',
            description = 'Insufficient society funds.',
            type = 'error',
        })
    end

    xPlayer.addMoney(amount, 'society_withdraw')
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Society',
        description = ('Withdrew $%s'):format(amount),
        type = 'success',
    })
end)
