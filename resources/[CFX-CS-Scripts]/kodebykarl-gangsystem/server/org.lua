local ESX = exports['es_extended']:getSharedObject()

--[[
    iPad Organization app bridge
    Callbacks: cfx-keydi-gang:org:dashboard | hire | setGrade | fire
    Event: cfx-keydi-gang:server:hireByDiscord
]]

local function mapDashboard(dash)
    return dash
end

lib.callback.register('cfx-keydi-gang:org:dashboard', function(source, data)
    data = type(data) == 'table' and data or {}
    local gang = data.gang
    return mapDashboard(GangServer.BuildDashboard(source, gang))
end)

lib.callback.register('cfx-keydi-gang:org:hire', function(source, data)
    data = type(data) == 'table' and data or {}
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'offline' } end

    local gangName = data.gang and tostring(data.gang):lower() or nil
    local gang = GangServer.GetPlayerGang(source)
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local staff = group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin'

    if not gangName and gang then gangName = gang.name end
    if not gangName or not GangServer.GetGangDef(gangName) then
        return { ok = false, error = 'invalid' }
    end
    if not staff and not GangServer.IsBoss(source, gangName) then
        return { ok = false, error = 'denied' }
    end

    local targetId = tonumber(data.id)
    local grade = math.floor(tonumber(data.grade) or 0)
    if not targetId or targetId == source then
        return { ok = false, error = 'invalid' }
    end

    local yourGrade = staff and 99 or GangServer.GetGradeLevel(gang)
    if grade < 0 or grade >= yourGrade then
        return { ok = false, error = 'grade' }
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return { ok = false, error = 'offline' } end
    if not GangServer.IsNear(source, targetId) then return { ok = false, error = 'far' } end

    local existing = xTarget.getGang and xTarget.getGang() or xTarget.gang
    if type(existing) == 'table' and existing.name == gangName then
        return { ok = false, error = 'already' }
    end

    local cfg = GangServer.GetGangDef(gangName)
    local label = GangServer.GradeLabel(gangName, grade)
    local ok = GangServer.SetPlayerGang(
        xTarget,
        gangName,
        grade,
        ('You were hired into %s as %s.'):format(cfg.label, label)
    )
    if not ok then return { ok = false, error = 'failed' } end

    return GangServer.BuildDashboard(source, gangName)
end)

lib.callback.register('cfx-keydi-gang:org:setGrade', function(source, data)
    data = type(data) == 'table' and data or {}
    -- Delegate through shared helpers by simulating boss callback response shape
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'offline' } end

    local gangName = data.gang and tostring(data.gang):lower() or nil
    local gang = GangServer.GetPlayerGang(source)
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local staff = group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin'
    if not gangName and gang then gangName = gang.name end
    if not gangName or not GangServer.GetGangDef(gangName) then
        return { ok = false, error = 'invalid' }
    end
    if not staff and not GangServer.IsBoss(source, gangName) then
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

    local yourGrade = staff and 99 or GangServer.GetGradeLevel(gang)
    if grade >= yourGrade then
        return { ok = false, error = 'grade' }
    end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        local tGang = xTarget.getGang and xTarget.getGang() or xTarget.gang
        if type(tGang) ~= 'table' or tGang.name ~= gangName then
            return { ok = false, error = 'not_member' }
        end
        if GangServer.GetGradeLevel(tGang) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        local label = GangServer.GradeLabel(gangName, grade)
        GangServer.SetPlayerGang(xTarget, gangName, grade, ('Your rank is now %s.'):format(label))
    else
        local row = MySQL.single.await('SELECT gang FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or not row.gang then return { ok = false, error = 'not_member' } end
        local decoded = json.decode(row.gang)
        if type(decoded) ~= 'table' or decoded.name ~= gangName then
            return { ok = false, error = 'not_member' }
        end
        if GangServer.GetGradeLevel(decoded) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        if not GangServer.SetOfflineGang(identifier, gangName, grade) then
            return { ok = false, error = 'failed' }
        end
    end

    return GangServer.BuildDashboard(source, gangName)
end)

lib.callback.register('cfx-keydi-gang:org:fire', function(source, data)
    data = type(data) == 'table' and data or {}
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, error = 'offline' } end

    local gangName = data.gang and tostring(data.gang):lower() or nil
    local gang = GangServer.GetPlayerGang(source)
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local staff = group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin'
    if not gangName and gang then gangName = gang.name end
    if not gangName or not GangServer.GetGangDef(gangName) then
        return { ok = false, error = 'invalid' }
    end
    if not staff and not GangServer.IsBoss(source, gangName) then
        return { ok = false, error = 'denied' }
    end

    local identifier = data.identifier
    if type(identifier) ~= 'string' or identifier == '' then
        return { ok = false, error = 'invalid' }
    end
    if identifier == xPlayer.identifier then
        return { ok = false, error = 'self' }
    end

    local yourGrade = staff and 99 or GangServer.GetGradeLevel(gang)

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        local tGang = xTarget.getGang and xTarget.getGang() or xTarget.gang
        if type(tGang) ~= 'table' or tGang.name ~= gangName then
            return { ok = false, error = 'not_member' }
        end
        if GangServer.GetGradeLevel(tGang) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        GangServer.SetPlayerGang(xTarget, 'none', 0, 'You were removed from the gang.')
    else
        local row = MySQL.single.await('SELECT gang FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or not row.gang then return { ok = false, error = 'not_member' } end
        local decoded = json.decode(row.gang)
        if type(decoded) ~= 'table' or decoded.name ~= gangName then
            return { ok = false, error = 'not_member' }
        end
        if GangServer.GetGradeLevel(decoded) >= yourGrade then
            return { ok = false, error = 'grade' }
        end
        GangServer.ClearOfflineGang(identifier)
    end

    return GangServer.BuildDashboard(source, gangName)
end)

RegisterNetEvent('cfx-keydi-gang:server:hireByDiscord', function(gangName, discord)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    gangName = tostring(gangName or ''):lower()
    if not GangServer.GetGangDef(gangName) then return end
    if not GangServer.IsBoss(src, gangName) then
        GangServer.Notify(src, 'GANG', 'Boss access only.', 'error')
        return
    end
    -- Hook point for Discord bot / role sync — stub notifies pending
    GangServer.Notify(src, 'GANG', ('Discord hire queued for %s.'):format(tostring(discord)), 'info')
    print(('[kodebykarl-gangsystem] hireByDiscord gang=%s discord=%s by=%s'):format(gangName, tostring(discord), xPlayer.identifier))
end)
