local ESX = exports['es_extended']:getSharedObject()
local ox_inventory = exports.ox_inventory

local ERR = {
    denied = 'Gang boss access only.',
    invalid = 'Invalid request.',
    offline = 'That player is offline.',
    far = 'Player is too far away.',
    grade = 'You cannot set that rank.',
    self = 'You cannot edit yourself.',
    not_member = 'Not in this organization.',
    already = 'Already in your gang.',
    no_cash = 'Not enough cash.',
    no_funds = 'Not enough society funds.',
    inventory_full = 'Inventory full.',
}

local function err(code, message)
    return { ok = false, error = code, message = message or ERR[code] or 'Failed.' }
end

local function requireBoss(src, gangName)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil, nil, err('offline') end

    local gang = GangServer.GetPlayerGang(src)
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    local staff = group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin'

    if gangName then
        gangName = tostring(gangName):lower()
    elseif gang then
        gangName = gang.name
    end

    if not gangName or not GangServer.GetGangDef(gangName) then
        return nil, nil, err('invalid')
    end

    if not staff and not GangServer.IsBoss(src, gangName) then
        return nil, nil, err('denied')
    end

    return xPlayer, gangName, nil, staff
end

lib.callback.register('kodebykarl-gangsystem:bossDashboard', function(source)
    local xPlayer, gangName, fail = requireBoss(source)
    if fail then return fail end
    return GangServer.BuildDashboard(source, gangName)
end)

lib.callback.register('kodebykarl-gangsystem:getHireGrades', function(source, gangName)
    local xPlayer, name, fail, staff = requireBoss(source, gangName)
    if fail then return {} end

    local yourGrade = 99
    if not staff then
        local gang = GangServer.GetPlayerGang(source)
        yourGrade = GangServer.GetGradeLevel(gang)
    end

    local grades = GangServer.GradeList(name)
    local out = {}
    for i = 1, #grades do
        if grades[i].grade < yourGrade then
            out[#out + 1] = grades[i]
        end
    end
    return out
end)

lib.callback.register('kodebykarl-gangsystem:getMembers', function(source, gangName)
    local _, name, fail = requireBoss(source, gangName)
    if fail then return {} end
    local members = GangServer.GetMembers(name)
    return members
end)

lib.callback.register('kodebykarl-gangsystem:hire', function(source, data)
    data = type(data) == 'table' and data or {}
    local xPlayer, gangName, fail, staff = requireBoss(source, data.gang)
    if fail then return fail end

    local targetId = tonumber(data.id)
    local grade = math.floor(tonumber(data.grade) or 0)
    if not targetId or targetId == source then
        return err('invalid')
    end

    local yourGrade = 99
    if not staff then
        yourGrade = GangServer.GetGradeLevel(GangServer.GetPlayerGang(source))
    end
    if grade < 0 or grade >= yourGrade then
        return err('grade')
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return err('offline') end
    if not GangServer.IsNear(source, targetId) then return err('far') end

    local existing = xTarget.getGang and xTarget.getGang() or xTarget.gang
    if type(existing) == 'table' and existing.name == gangName then
        return err('already')
    end

    local cfg = GangServer.GetGangDef(gangName)
    local label = GangServer.GradeLabel(gangName, grade)
    local ok = GangServer.SetPlayerGang(
        xTarget,
        gangName,
        grade,
        ('You were hired into %s as %s.'):format(cfg.label, label)
    )
    if not ok then return err('invalid', 'Failed to set gang.') end

    GangServer.Notify(source, 'GANG', ('Hired %s.'):format(GangServer.DisplayName(xTarget)), 'success')
    return { ok = true }
end)

lib.callback.register('kodebykarl-gangsystem:setGrade', function(source, data)
    data = type(data) == 'table' and data or {}
    local xPlayer, gangName, fail, staff = requireBoss(source, data.gang)
    if fail then return fail end

    local identifier = data.identifier
    local grade = math.floor(tonumber(data.grade) or -1)
    if type(identifier) ~= 'string' or identifier == '' or grade < 0 then
        return err('invalid')
    end
    if identifier == xPlayer.identifier then
        return err('self')
    end

    local yourGrade = 99
    if not staff then
        yourGrade = GangServer.GetGradeLevel(GangServer.GetPlayerGang(source))
    end
    if grade >= yourGrade then
        return err('grade')
    end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        local gang = xTarget.getGang and xTarget.getGang() or xTarget.gang
        if type(gang) ~= 'table' or gang.name ~= gangName then
            return err('not_member')
        end
        if GangServer.GetGradeLevel(gang) >= yourGrade then
            return err('grade')
        end
        local label = GangServer.GradeLabel(gangName, grade)
        GangServer.SetPlayerGang(xTarget, gangName, grade, ('Your rank is now %s.'):format(label))
    else
        local row = MySQL.single.await('SELECT gang FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or not row.gang then return err('not_member') end
        local decoded = json.decode(row.gang)
        if type(decoded) ~= 'table' or decoded.name ~= gangName then
            return err('not_member')
        end
        if GangServer.GetGradeLevel(decoded) >= yourGrade then
            return err('grade')
        end
        if not GangServer.SetOfflineGang(identifier, gangName, grade) then
            return err('invalid')
        end
    end

    return { ok = true }
end)

lib.callback.register('kodebykarl-gangsystem:fire', function(source, data)
    data = type(data) == 'table' and data or {}
    local xPlayer, gangName, fail, staff = requireBoss(source, data.gang)
    if fail then return fail end

    local identifier = data.identifier
    if type(identifier) ~= 'string' or identifier == '' then
        return err('invalid')
    end
    if identifier == xPlayer.identifier then
        return err('self')
    end

    local yourGrade = 99
    if not staff then
        yourGrade = GangServer.GetGradeLevel(GangServer.GetPlayerGang(source))
    end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        local gang = xTarget.getGang and xTarget.getGang() or xTarget.gang
        if type(gang) ~= 'table' or gang.name ~= gangName then
            return err('not_member')
        end
        if GangServer.GetGradeLevel(gang) >= yourGrade then
            return err('grade')
        end
        GangServer.SetPlayerGang(xTarget, 'none', 0, 'You were removed from the gang.')
    else
        local row = MySQL.single.await('SELECT gang FROM users WHERE identifier = ? LIMIT 1', { identifier })
        if not row or not row.gang then return err('not_member') end
        local decoded = json.decode(row.gang)
        if type(decoded) ~= 'table' or decoded.name ~= gangName then
            return err('not_member')
        end
        if GangServer.GetGradeLevel(decoded) >= yourGrade then
            return err('grade')
        end
        GangServer.ClearOfflineGang(identifier)
    end

    return { ok = true }
end)

local moneyBusy = {}

lib.callback.register('kodebykarl-gangsystem:money', function(source, data)
    if moneyBusy[source] then
        return err('invalid', 'Transaction in progress.')
    end

    data = type(data) == 'table' and data or {}
    local xPlayer, gangName, fail = requireBoss(source, data.gang)
    if fail then return fail end

    local action = data.action
    local amount = math.floor(tonumber(data.amount) or 0)
    if (action ~= 'deposit' and action ~= 'withdraw') or amount < 1 or amount > (Config.MaxTransfer or 1000000) then
        return err('invalid')
    end

    local account = GangServer.SocietyAccount(gangName)
    if not account then return err('invalid', 'Society account missing.') end

    moneyBusy[source] = true

    local ok, result = pcall(function()
        local society = exports['cfx-keydi-society']

        if action == 'deposit' then
            -- Server-side cash only — never trust client inventory state
            local cash = ox_inventory:GetItemCount(source, 'money') or 0
            if cash < amount then
                return err('no_cash')
            end
            local removed = ox_inventory:RemoveItem(source, 'money', amount)
            if not removed then
                return err('no_cash')
            end
            local added = society:AddMoney(account, amount, xPlayer.identifier, ('Gang %s deposit'):format(gangName))
            if not added then
                ox_inventory:AddItem(source, 'money', amount)
                return err('invalid', 'Deposit failed.')
            end
        else
            local balance = tonumber(society:GetBalance(account)) or 0
            if balance < amount then
                return err('no_funds')
            end
            local removed = society:RemoveMoney(account, amount, xPlayer.identifier, ('Gang %s withdraw'):format(gangName))
            if not removed then
                return err('no_funds')
            end
            -- Give cash only after society debit succeeds
            local given = ox_inventory:AddItem(source, 'money', amount)
            if not given then
                society:AddMoney(account, amount, xPlayer.identifier, ('Gang %s withdraw refund'):format(gangName))
                return err('inventory_full')
            end
        end

        return { ok = true, funds = GangServer.GetFunds(gangName) }
    end)

    moneyBusy[source] = nil

    if not ok then
        print(('[kodebykarl-gangsystem] money error src=%s: %s'):format(source, tostring(result)))
        return err('invalid', 'Transaction failed.')
    end
    return result
end)

AddEventHandler('playerDropped', function()
    moneyBusy[source] = nil
end)
