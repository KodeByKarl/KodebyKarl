

-- Start of Check Identification --
function GetPlayerIdentity(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        return false
    end

    local dob, sex
    pcall(function()
        dob = xPlayer.get('dateofbirth')
        sex = xPlayer.get('sex')
    end)

    if not dob or not sex then
        local row = MySQL.single.await(
            'SELECT firstname, lastname, dateofbirth, sex FROM users WHERE identifier = ? LIMIT 1',
            { xPlayer.identifier }
        )
        if row then
            dob = dob or row.dateofbirth
            sex = sex or row.sex
            if (not xPlayer.name or xPlayer.name == '') and row.firstname then
                xPlayer.name = ('%s %s'):format(row.firstname or '', row.lastname or ''):gsub('%s+$', '')
            end
        end
    end

    local licenses = {}
    pcall(function()
        licenses = xPlayer.getMeta('licenses') or {}
    end)

    local sexLabel = false
    if sex == 'm' or sex == 'M' or sex == 0 or sex == 'male' then
        sexLabel = 'Male'
    elseif sex == 'f' or sex == 'F' or sex == 1 or sex == 'female' then
        sexLabel = 'Female'
    end

    return {
        name = xPlayer.name,
        job = xPlayer.job and xPlayer.job.label or 'Unemployed',
        position = xPlayer.job and xPlayer.job.grade_label or 'N/A',
        dob = dob or false,
        sex = sexLabel,
        licenses = licenses,
    }
end

ESX.RegisterServerCallback('cfx-cs-police:checkPlayerId', function(source, cb, target)
    local src = source
    if not target or not ESX.VerifyDistance(src, target, 8.0, 'cfx-cs-police:checkPlayerId') then
        return cb(false)
    end
    if not HasGroup(src) then
        return cb(false)
    end
    local identity = GetPlayerIdentity(target)
    if identity and PoliceLogs and PoliceLogs.Action then
        local name, identifier = PoliceLogs.FromSource(src)
        local tName, tId = PoliceLogs.FromSource(target)
        PoliceLogs.Action({
            kind = 'id',
            src = src,
            name = name,
            identifier = identifier,
            targetSrc = target,
            targetName = tName,
            targetIdentifier = tId,
            detail = ('Checked ID of %s'):format(identity.name or tName),
        })
    end
    cb(identity)
end)

RegisterNetEvent('cfx-cs-police:revokeLicense', function(playerId, license)
    local src = source
    if playerId == -1 then  return end
    if not ESX.VerifyDistance(src, playerId, 3.5, 'cfx-cs-police:revokeLicense') then return end
    if not HasGroup(src) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(playerId)
    if not xTarget then return end

    if license == 'weapon' and GetResourceState('cfx-keydi-utils') == 'started' then
        exports['cfx-keydi-utils']:SetGunLicense(playerId, false)
    else
        local licenses = xTarget.getMeta('licenses') or {}
        if licenses[license] then
            licenses[license].has = false
        end
        xTarget.setMeta('licenses', licenses)
    end

    local label = (license == 'weapon' and 'Weapon license') or ((license or 'License'):gsub('^%l', string.upper) .. ' license')
    TriggerClientEvent('esx:Notify', xTarget.source, 'POLICE', label .. ' revoked.', 'error', 10000)
    if PoliceLogs and PoliceLogs.License then
        PoliceLogs.License({
            action = 'revoke',
            src = src,
            name = xPlayer and xPlayer.name,
            identifier = xPlayer and xPlayer.identifier,
            targetSrc = playerId,
            targetName = xTarget.name,
            targetIdentifier = xTarget.identifier,
            license = license,
        })
    end
end)
-- End of Check Identification --

local function playerHasWeaponLicense(xTarget)
    if not xTarget then return false end
    local licenses = xTarget.getMeta('licenses') or {}
    local entry = licenses.weapon
    if type(entry) == 'table' and entry.has == true then
        return true
    end
    local ok, hasDb = pcall(function()
        return MySQL.scalar.await(
            'SELECT 1 FROM `user_licenses` WHERE `type` = ? AND `owner` = ? LIMIT 1',
            { 'weapon', xTarget.identifier }
        )
    end)
    return ok and hasDb and true or false
end

-- Start of Grant License --

ESX.RegisterServerCallback('cfx-cs-police:grantLicense', function(source, cb, id)
    local src = source
    if not id or id == -1 then return cb(false) end
    if not ESX.VerifyDistance(src, id, 5.0, 'callback:cfx-cs-police:grantLicense') then return cb(false) end
    if not HasGroup(src) then return cb(false) end
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(id)
    if not xTarget then return cb(false) end

    if playerHasWeaponLicense(xTarget) then
        return cb(false)
    end

    local granted = false
    if GetResourceState('cfx-keydi-utils') == 'started' then
        granted = exports['cfx-keydi-utils']:SetGunLicense(id, true) == true
    else
        local licenses = xTarget.getMeta('licenses') or {}
        if type(licenses['weapon']) ~= 'table' then
            licenses['weapon'] = { has = false, label = 'Weapon License' }
        end
        licenses['weapon'].has = true
        xTarget.setMeta('licenses', licenses)
        granted = true
    end

    if not granted then return cb(false) end

    TriggerClientEvent('esx:Notify', xTarget.source, 'POLICE', 'Weapon license received.', 'success', 5000)
    if PoliceLogs and PoliceLogs.License then
        PoliceLogs.License({
            action = 'grant',
            src = src,
            name = xPlayer and xPlayer.name,
            identifier = xPlayer and xPlayer.identifier,
            targetSrc = id,
            targetName = xTarget.name,
            targetIdentifier = xTarget.identifier,
            license = 'weapon',
        })
    end
    return cb(xTarget.name)
end)
-- End of Grant License --

-- Start of Revoke Weapon License --
ESX.RegisterServerCallback('cfx-cs-police:revokeWeaponLicense', function(source, cb, id)
    local src = source
    if not id or id == -1 then return cb(false) end
    if not ESX.VerifyDistance(src, id, 5.0, 'callback:cfx-cs-police:revokeWeaponLicense') then return cb(false) end
    if not HasGroup(src) then return cb(false) end

    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(id)
    if not xTarget then return cb(false) end

    if not playerHasWeaponLicense(xTarget) then
        return cb(false)
    end

    local revoked = false
    if GetResourceState('cfx-keydi-utils') == 'started' then
        revoked = exports['cfx-keydi-utils']:SetGunLicense(id, false) == true
    else
        local licenses = xTarget.getMeta('licenses') or {}
        if type(licenses.weapon) ~= 'table' then
            licenses.weapon = { has = false, label = 'Weapon License' }
        end
        licenses.weapon.has = false
        xTarget.setMeta('licenses', licenses)
        revoked = true
    end

    if not revoked then return cb(false) end

    TriggerClientEvent('esx:Notify', xTarget.source, 'POLICE', 'Weapon license revoked.', 'error', 10000)
    if PoliceLogs and PoliceLogs.License then
        PoliceLogs.License({
            action = 'revoke',
            src = src,
            name = xPlayer and xPlayer.name,
            identifier = xPlayer and xPlayer.identifier,
            targetSrc = id,
            targetName = xTarget.name,
            targetIdentifier = xTarget.identifier,
            license = 'weapon',
        })
    end
    return cb(xTarget.name)
end)
-- End of Revoke Weapon License --

-- Start of Grant Hunting License --
lib.callback.register('cfx-cs-police:grantHuntingLicense', function(source, id)
    local src = source
    if id == -1 then return end
    if not ESX.VerifyDistance(src, id, 3.5, 'callback:cfx-cs-police:grantHuntingLicense') then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(id)
    local licenses = xTarget.getMeta('licenses')
    if licenses['hunting'] then
        licenses['hunting'].has = true
        xTarget.setMeta('licenses', licenses)
        if PoliceLogs and PoliceLogs.License then
            PoliceLogs.License({
                action = 'grant',
                src = src,
                name = xPlayer and xPlayer.name,
                identifier = xPlayer and xPlayer.identifier,
                targetSrc = id,
                targetName = xTarget.name,
                targetIdentifier = xTarget.identifier,
                license = 'hunting',
            })
        end
        return xTarget.name
    end
    return false
end)
-- End of Grant Hunting License --

-- Start of Handcuff --
-- Police target cuff/uncuff: no handcuff item required
RegisterNetEvent('cfx-cs-police:CuffPlayer', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == -1 or target == src then return end
    if not ESX.VerifyDistance(src, target, 8.0, 'cfx-cs-police:CuffPlayer') then return end
    if not HasGroup(src) then return end

    local alreadyCuffed = cuffedPlayers[target] == true or Player(target).state.cuffed == true
    if alreadyCuffed then return end

    cuffedPlayers[target] = true
    Player(target).state:set('cuffed', true, true)
    TriggerClientEvent('cfx-cs-police:cuffAnim', target, src)
    TriggerClientEvent('cfx-cs-police:cuff', src)

    if PoliceLogs and PoliceLogs.Action then
        local name, identifier = PoliceLogs.FromSource(src)
        local tName, tId = PoliceLogs.FromSource(target)
        PoliceLogs.Action({
            kind = 'cuff',
            src = src,
            name = name,
            identifier = identifier,
            targetSrc = target,
            targetName = tName,
            targetIdentifier = tId,
        })
    end
end)

RegisterNetEvent('cfx-cs-police:UncuffPlayer', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == -1 or target == src then return end
    if not ESX.VerifyDistance(src, target, 5.0, 'cfx-cs-police:UncuffPlayer') then return end
    if not HasGroup(src) then return end

    local isCuffed = cuffedPlayers[target] == true or Player(target).state.cuffed == true
    if not isCuffed then return end

    TriggerClientEvent('cfx-cs-police:uncuffAnim', src, target)
    Wait(5500)
    cuffedPlayers[target] = false
    Player(target).state:set('cuffed', false, true)
    TriggerClientEvent('cfx-cs-police:uncuff', target)

    if PoliceLogs and PoliceLogs.Action then
        local name, identifier = PoliceLogs.FromSource(src)
        local tName, tId = PoliceLogs.FromSource(target)
        PoliceLogs.Action({
            kind = 'uncuff',
            src = src,
            name = name,
            identifier = identifier,
            targetSrc = target,
            targetName = tName,
            targetIdentifier = tId,
        })
    end
end)

RegisterNetEvent('cfx-cs-police:setCuff', function(isCuffed)
    local src = source
    if type(isCuffed) ~= 'boolean' then return end
    cuffedPlayers[src] = isCuffed
    Player(src).state:set('cuffed', isCuffed, true)
end)
-- End of Handcuff --

-- Start of Escort --
RegisterNetEvent('cfx-cs-police:escortPlayer', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not targetId or targetId == -1 or targetId == src then return end
    if not ESX.VerifyDistance(src, targetId, 5.0, 'cfx-cs-police:escortPlayer') then return end
    if not HasGroup(src) then return end
    if not Player(targetId).state.cuffed then return end

    TriggerClientEvent('cfx-cs-police:setEscort', src, targetId)
    TriggerClientEvent('cfx-cs-police:escortedPlayer', targetId, src)
end)
-- End of Escort --

-- Start of In Vehicle --
RegisterNetEvent('cfx-cs-police:inVehiclePlayer', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not targetId or targetId == -1 or targetId == src then return end
    if not ESX.VerifyDistance(src, targetId, 5.0, 'cfx-cs-police:inVehiclePlayer') then return end
    if not HasGroup(src) then return end
    TriggerClientEvent('cfx-cs-police:stopEscorting', src)
    TriggerClientEvent('cfx-cs-police:putInVehicle', targetId)
end)
-- End of In Vehicle --

-- Start of Out Vehicle --
RegisterNetEvent('cfx-cs-police:outVehiclePlayer', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not targetId or targetId == -1 or targetId == src then return end
    if not ESX.VerifyDistance(src, targetId, 5.0, 'cfx-cs-police:outVehiclePlayer') then return end
    if not HasGroup(src) then return end
    TriggerClientEvent('cfx-cs-police:takeFromVehicle', targetId)
end)
-- End of Out Vehicle --

-- Start of Place Object --
local Objects = {}
local function CreateObjectId()
    if Objects then
        local objectId = math.random(10000, 99999)
        while Objects[objectId] do
            objectId = math.random(10000, 99999)
        end
        return objectId
    else
        local objectId = math.random(10000, 99999)
        return objectId
    end
end
RegisterNetEvent('cfx-cs-police:server:spawnObject', function(type)
    local src = source
    if not HasGroup(src) then return end
    local objectId = CreateObjectId()
    Objects[objectId] = type
    TriggerClientEvent("cfx-cs-police:client:spawnObject", src, objectId, type, src)
end)

RegisterNetEvent('cfx-cs-police:server:deleteObject', function(objectId)
    local src = source
    if not HasGroup(src) then return end
    TriggerClientEvent('cfx-cs-police:client:removeObject', -1, objectId)
end)

RegisterNetEvent('cfx-cs-police:server:SyncSpikes', function(table)
    local src = source
    if not HasGroup(src) then return end
    TriggerClientEvent('cfx-cs-police:client:SyncSpikes', -1, table)
end)
-- End of Place Object

-- Start of Vehicle Info --
function _GetVehicleOwner(plate)
    local owner
    local response = MySQL.query.await('SELECT `owner` FROM `owned_vehicles` WHERE `plate` = ?', {plate})
    if response[1] then
        local identifier = response[1].owner
        local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            owner = xPlayer.name
        else
            local result = MySQL.query.await('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?', {identifier})
            if result[1] then
                owner = result[1].firstname..' '..result[1].lastname
            else
                owner = false
            end
        end
    else
        owner = false
    end
    return owner
end

ESX.RegisterServerCallback('cfx-cs-police:getVehicleOwner', function(source, cb, plate)
    local src = source
    if not HasGroup(src) then return cb(false) end
    local owner = _GetVehicleOwner(plate)
    cb({
        owner = owner or false,
        plate = plate,
    })
end)
-- End of Vehicle Info --

-- Start of GSR Test --
local GSRTest = {}

RegisterNetEvent('cfx-cs-police:RegisterGSR', function(gsr)
    local src = source
    GSRTest[src] = gsr == true
end)

AddEventHandler('playerDropped', function()
    GSRTest[source] = nil
end)

lib.callback.register('cfx-cs-police:GSRTest', function(source, playerId)
    local src = source
    playerId = tonumber(playerId)
    if not playerId or playerId == -1 then
        return { success = false, positive = false, reason = 'invalid_target' }
    end
    if not HasGroup(src) then
        return { success = false, positive = false, reason = 'not_police' }
    end
    if ESX.VerifyDistance and not ESX.VerifyDistance(src, playerId, 5.0, 'callback:cfx-cs-police:GSRTest') then
        return { success = false, positive = false, reason = 'too_far' }
    end

    local positive = GSRTest[playerId] == true
    if PoliceLogs and PoliceLogs.Action then
        local name, identifier = PoliceLogs.FromSource(src)
        local tName, tId = PoliceLogs.FromSource(playerId)
        PoliceLogs.Action({
            kind = 'gsr',
            src = src,
            name = name,
            identifier = identifier,
            targetSrc = playerId,
            targetName = tName,
            targetIdentifier = tId,
            detail = positive and 'Result: **POSITIVE**' or 'Result: **NEGATIVE**',
        })
    end

    return {
        success = true,
        positive = positive,
        reason = positive and 'positive' or 'negative'
    }
end)

-- Keep legacy ESX callback working too
ESX.RegisterServerCallback('cfx-cs-police:GSRTest', function(source, cb, playerId)
    playerId = tonumber(playerId)
    if not playerId or playerId == -1 then return cb(false) end
    if not HasGroup(source) then return cb(false) end
    if ESX.VerifyDistance and not ESX.VerifyDistance(source, playerId, 5.0, 'callback:cfx-cs-police:GSRTest') then
        return cb(false)
    end
    local positive = GSRTest[playerId] == true
    if PoliceLogs and PoliceLogs.Action then
        local name, identifier = PoliceLogs.FromSource(source)
        local tName, tId = PoliceLogs.FromSource(playerId)
        PoliceLogs.Action({
            kind = 'gsr',
            src = source,
            name = name,
            identifier = identifier,
            targetSrc = playerId,
            targetName = tName,
            targetIdentifier = tId,
            detail = positive and 'Result: **POSITIVE**' or 'Result: **NEGATIVE**',
        })
    end
    cb(positive)
end)
-- End of GSR Test --

-- Start of Priority Status --
local function getPriorityJobFromPlayer(xPlayer)
    if xPlayer and xPlayer.job and xPlayer.job.name == 'sheriff' then
        return 'sheriff'
    end
    return 'police'
end

local function canChangePriorityStatus(xPlayer)
    local cfg = Config.PriorityStatus
    if not cfg or not cfg.enabled then
        return false
    end
    if not xPlayer or not xPlayer.job or not xPlayer.job.name then
        return false
    end
    local minGrade = cfg.authorized and cfg.authorized[xPlayer.job.name]
    if minGrade == nil then
        return false
    end
    return (xPlayer.job.grade or 0) >= minGrade
end

local function notifyJobPriority(job, title, message, nType)
    local players = ESX.GetExtendedPlayers('job', job)
    if type(players) ~= 'table' then return end
    for _, xTarget in pairs(players) do
        if xTarget and xTarget.source then
            TriggerClientEvent('esx:Notify', xTarget.source, title, message, nType or 'warning', 8000)
        end
    end
end

RegisterNetEvent('cfx-cs-police:setPriorityStatus', function(status, targetJob)
    local src = source
    if not HasGroup(src) then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if not canChangePriorityStatus(xPlayer) then
        TriggerClientEvent('esx:Notify', src, 'PRIORITY', 'Your rank cannot change priority status.', 'error', 5000)
        return
    end

    local normalized = type(status) == 'string' and status:lower():gsub('%s+', '') or ''
    if normalized ~= 'safe' and normalized ~= 'hold' and normalized ~= 'cooldown'
        and normalized ~= 'inprogress'
        -- legacy aliases
        and normalized ~= 'active' and normalized ~= 'lockdown' then
        return
    end

    local scoreboardRes = nil
    if GetResourceState('kodebykarl-ui') == 'started' then
        scoreboardRes = 'kodebykarl-ui'
    elseif GetResourceState('cfx-keydi-ui') == 'started' then
        scoreboardRes = 'cfx-keydi-ui'
    elseif GetResourceState('cfx-cs-scoreboard') == 'started' then
        scoreboardRes = 'cfx-cs-scoreboard'
    end

    if not scoreboardRes then
        TriggerClientEvent('esx:Notify', src, 'PRIORITY', 'Scoreboard is not available.', 'error', 5000)
        return
    end

    local displayMap = {
        safe = 'Safe',
        hold = 'Hold',
        cooldown = 'Cooldown',
        inprogress = 'InProgress',
        -- legacy → Hold
        active = 'Hold',
        lockdown = 'Hold',
    }
    local display = displayMap[normalized] or 'Safe'
    local target = targetJob
    if type(target) ~= 'string' or target == '' then
        target = getPriorityJobFromPlayer(xPlayer)
    end
    target = target:lower()
    if target ~= 'police' and target ~= 'sheriff' and target ~= 'all' then
        target = getPriorityJobFromPlayer(xPlayer)
    end

    local ok = pcall(function()
        exports[scoreboardRes]:SetPriorityStatus(target, display)
    end)
    if not ok then
        TriggerClientEvent('esx:Notify', src, 'PRIORITY', 'Failed to update priority status.', 'error', 5000)
        return
    end

    local notifyLabel = (display == 'InProgress' or display == 'inprogress') and 'In Progress' or display
    local notificationType = display == 'Safe' and 'success' or (display == 'InProgress' and 'warning' or 'error')
    local deptLabel = target == 'sheriff' and 'Paleto Sheriff'
        or (target == 'police' and 'LS Police' or 'City')
    local notificationMessage = ('%s priority is now %s (Updated by %s)'):format(deptLabel, notifyLabel, xPlayer.name)

    if target == 'all' then
        notifyJobPriority('police', 'PRIORITY', notificationMessage, notificationType)
        notifyJobPriority('sheriff', 'PRIORITY', notificationMessage, notificationType)
    else
        notifyJobPriority(target, 'PRIORITY', notificationMessage, notificationType)
    end

    if PoliceLogs and PoliceLogs.Action then
        local name, identifier = PoliceLogs.FromSource(src)
        PoliceLogs.Action({
            kind = 'priority',
            src = src,
            name = name,
            identifier = identifier,
            detail = ('Set %s Priority to **%s**'):format(deptLabel, notifyLabel),
        })
    end
end)
-- End of Priority Status --

RegisterNetEvent('cfx-cs-police:logSearch', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not targetId or targetId == -1 then return end
    if not HasGroup(src) then return end
    if ESX.VerifyDistance and not ESX.VerifyDistance(src, targetId, 5.0, 'cfx-cs-police:logSearch') then return end
    if PoliceLogs and PoliceLogs.Action then
        local name, identifier = PoliceLogs.FromSource(src)
        local tName, tId = PoliceLogs.FromSource(targetId)
        PoliceLogs.Action({
            kind = 'search',
            src = src,
            name = name,
            identifier = identifier,
            targetSrc = targetId,
            targetName = tName,
            targetIdentifier = tId,
        })
    end
end)