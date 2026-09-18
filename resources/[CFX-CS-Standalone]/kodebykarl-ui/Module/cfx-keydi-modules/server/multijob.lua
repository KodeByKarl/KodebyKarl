ESX = ESX or exports['es_extended']:getSharedObject()
local RateLimits = {}

-- Anti-Spam Rate Limiting (1-second cooldown)
local function isRateLimited(source)
    local now = os.time()
    if RateLimits[source] and (now - RateLimits[source]) < 1 then
        return true
    end
    RateLimits[source] = now
    return false
end

AddEventHandler('playerDropped', function()
    RateLimits[source] = nil
end)

-- Security Logger
local function logSecurityAlert(source, action, details)
    print(('[SECURITY ALERT] [cfx-keydi-multijob] Player %s (ID: %s) failed check on "%s": %s')
        :format(GetPlayerName(source) or 'Unknown', tostring(source), action, tostring(details)))
end

-- Ensure multijob DB table exists
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `player_multijobs` (
            `identifier` VARCHAR(100) NOT NULL,
            `job` VARCHAR(50) NOT NULL,
            `grade` INT NOT NULL DEFAULT 0,
            `label` VARCHAR(100) NOT NULL,
            `grade_label` VARCHAR(100) NOT NULL,
            `is_active` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`, `job`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Auto-register online players' jobs into multijob table
    if ESX and ESX.GetExtendedPlayers then
        local xPlayers = ESX.GetExtendedPlayers() or {}
        for _, xPlayer in pairs(xPlayers) do
            if xPlayer and xPlayer.job then
                local job = xPlayer.job
                local jobName = job.name
                if jobName and jobName ~= 'unemployed' and not string.find(jobName, '^off') then
                    local identifier = xPlayer.getIdentifier()
                    MySQL.query([[
                        INSERT INTO `player_multijobs` (`identifier`, `job`, `grade`, `label`, `grade_label`, `is_active`)
                        VALUES (?, ?, ?, ?, ?, 1)
                        ON DUPLICATE KEY UPDATE `grade` = ?, `label` = ?, `grade_label` = ?, `is_active` = 1
                    ]], { identifier, jobName, job.grade, job.label or jobName, job.grade_label or 'Member', job.grade, job.label or jobName, job.grade_label or 'Member' })
                end
            end
        end
    end
end)

-- Sync player's active job into database table when job changes
AddEventHandler('esx:setJob', function(source, job, lastJob)
    local xPlayer = ESX and ESX.GetPlayerFromId(source)
    if not xPlayer or not job then return end

    local identifier = xPlayer.getIdentifier()
    local jobName = job.name

    if jobName ~= 'unemployed' and not string.find(jobName, '^off') then
        -- Set active flag on current job and deactivate others
        MySQL.update('UPDATE `player_multijobs` SET `is_active` = 0 WHERE `identifier` = ?', { identifier })
        MySQL.query([[
            INSERT INTO `player_multijobs` (`identifier`, `job`, `grade`, `label`, `grade_label`, `is_active`)
            VALUES (?, ?, ?, ?, ?, 1)
            ON DUPLICATE KEY UPDATE `grade` = ?, `label` = ?, `grade_label` = ?, `is_active` = 1
        ]], { identifier, jobName, job.grade, job.label or jobName, job.grade_label or 'Member', job.grade, job.label or jobName, job.grade_label or 'Member' })
    elseif jobName and string.find(jobName, '^off') then
        -- Off-duty: keep primary job grade in sync so next clock-in uses the new rank.
        local primary = jobName:sub(4)
        if primary ~= '' then
            MySQL.update('UPDATE `player_multijobs` SET `is_active` = 0 WHERE `identifier` = ?', { identifier })
            MySQL.query([[
                INSERT INTO `player_multijobs` (`identifier`, `job`, `grade`, `label`, `grade_label`, `is_active`)
                VALUES (?, ?, ?, ?, ?, 0)
                ON DUPLICATE KEY UPDATE `grade` = VALUES(`grade`), `label` = VALUES(`label`),
                    `grade_label` = VALUES(`grade_label`), `is_active` = 0
            ]], {
                identifier,
                primary,
                job.grade,
                job.label or primary,
                job.grade_label or 'Member',
            })
        else
            MySQL.update('UPDATE `player_multijobs` SET `is_active` = 0 WHERE `identifier` = ?', { identifier })
        end
    else
        -- Unemployed
        MySQL.update('UPDATE `player_multijobs` SET `is_active` = 0 WHERE `identifier` = ?', { identifier })
    end
end)

-- Fetch Multi-Job Roster Server Callback
ESX.RegisterServerCallback('cfx-keydi-multijob:server:getJobs', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ jobs = {}, activeJob = nil, isOnDuty = false, maxJobs = 3 }) end

    local identifier = xPlayer.getIdentifier()
    local currentJob = xPlayer.job and xPlayer.job.name
    local isCurrentlyOnDuty = currentJob and currentJob ~= 'unemployed' and not string.find(currentJob, '^off')

    -- Auto sync current job into DB if missing
    if isCurrentlyOnDuty and currentJob then
        local count = MySQL.scalar.await('SELECT COUNT(*) FROM `player_multijobs` WHERE `identifier` = ? AND `job` = ?', { identifier, currentJob }) or 0
        if count == 0 then
            MySQL.query.await([[
                INSERT INTO `player_multijobs` (`identifier`, `job`, `grade`, `label`, `grade_label`, `is_active`)
                VALUES (?, ?, ?, ?, ?, 1)
                ON DUPLICATE KEY UPDATE `grade` = ?, `label` = ?, `grade_label` = ?, `is_active` = 1
            ]], { identifier, currentJob, xPlayer.job.grade, xPlayer.job.label or currentJob, xPlayer.job.grade_label or 'Member', xPlayer.job.grade, xPlayer.job.label or currentJob, xPlayer.job.grade_label or 'Member' })
        end
    end

    local dbJobs = MySQL.query.await('SELECT * FROM `player_multijobs` WHERE `identifier` = ?', { identifier }) or {}

    cb({
        jobs = dbJobs,
        activeJob = isCurrentlyOnDuty and currentJob or nil,
        isOnDuty = isCurrentlyOnDuty,
        maxJobs = 3
    })
end)

-- Toggle Duty Event with STRICT SECURITY (Max 3 Jobs & 1 Active Duty at a time)
RegisterNetEvent('cfx-keydi-multijob:server:toggleDuty', function(targetJob)
    local src = source
    if not src or src <= 0 then return end

    if isRateLimited(src) then
        return TriggerClientEvent('esx:showNotification', src, 'Please wait before toggling duty!', 'warning')
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then return end

    local identifier = xPlayer.getIdentifier()
    targetJob = tostring(targetJob or ''):lower()

    if targetJob == '' then return end

    -- Check if player owns this job in their roster
    local jobRecord = MySQL.single.await('SELECT * FROM `player_multijobs` WHERE `identifier` = ? AND `job` = ?', { identifier, targetJob })
    if not jobRecord then
        logSecurityAlert(src, 'toggleDuty', 'Player attempted to toggle duty for unowned job ' .. targetJob)
        return TriggerClientEvent('esx:showNotification', src, 'You do not hold this job position!', 'error')
    end

    local currentJob = string.lower(xPlayer.job.name)
    local isCurrentlyOnDuty = currentJob ~= 'unemployed' and not string.find(currentJob, '^off')

    -- CASE 1: Toggling OFF DUTY on current active job
    if currentJob == targetJob then
        local offJob = 'off' .. targetJob
        if ESX.DoesJobExist and ESX.DoesJobExist(offJob, jobRecord.grade) then
            xPlayer.setJob(offJob, jobRecord.grade)
        else
            xPlayer.setJob('unemployed', 0)
        end
        MySQL.update('UPDATE `player_multijobs` SET `is_active` = 0 WHERE `identifier` = ?', { identifier })
        return TriggerClientEvent('esx:showNotification', src, 'You are now OFF DUTY from ' .. (jobRecord.label or targetJob), 'warning')
    end

    -- CASE 2: Switching ON DUTY to target job in multijob roster
    local targetGrade = tonumber(jobRecord.grade) or 0
    if ESX.DoesJobExist and not ESX.DoesJobExist(targetJob, targetGrade) then
        return TriggerClientEvent('esx:showNotification', src, 'Job position does not exist on server!', 'error')
    end

    -- Clock ON DUTY to target job
    xPlayer.setJob(targetJob, targetGrade)
    MySQL.update('UPDATE `player_multijobs` SET `is_active` = 0 WHERE `identifier` = ?', { identifier })
    MySQL.update('UPDATE `player_multijobs` SET `is_active` = 1 WHERE `identifier` = ? AND `job` = ?', { identifier, targetJob })

    TriggerClientEvent('esx:showNotification', src, 'You are now ON DUTY at ' .. (jobRecord.label or targetJob), 'success')
end)
