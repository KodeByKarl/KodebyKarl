local ESX = exports['es_extended']:getSharedObject()

GangServer = GangServer or {}

local function society()
    return exports['cfx-keydi-society']
end

function GangServer.GetGangDef(gangName)
    if not gangName then return nil end
    return Config.Gangs[tostring(gangName):lower()]
end

function GangServer.GetPlayerGang(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end
    local gang = xPlayer.getGang and xPlayer.getGang() or xPlayer.gang
    if type(gang) ~= 'table' or not gang.name or gang.name == 'none' then
        return nil
    end
    return gang
end

function GangServer.GetGradeLevel(gang)
    if type(gang) ~= 'table' then return 0 end
    if type(gang.grade) == 'table' then
        return tonumber(gang.grade.level) or 0
    end
    return tonumber(gang.grade) or 0
end

function GangServer.IsBoss(src, gangName)
    local gang = GangServer.GetPlayerGang(src)
    if not gang then return false end
    if gangName and gang.name ~= tostring(gangName):lower() then
        return false
    end
    if gang.isboss then return true end

    local cfg = GangServer.GetGangDef(gang.name)
    if not cfg then return false end
    local level = GangServer.GetGradeLevel(gang)
    for i = 1, #cfg.grades do
        local g = cfg.grades[i]
        if g.isboss and tonumber(g.grade) == level then
            return true
        end
    end
    return false
end

function GangServer.GetGangsMap()
    local out = {}
    for name, cfg in pairs(Config.Gangs) do
        out[name] = {
            name = name,
            label = cfg.label,
            color = cfg.color,
            society = cfg.society,
        }
    end
    return out
end

function GangServer.SocietyAccount(gangName)
    local cfg = GangServer.GetGangDef(gangName)
    if cfg and cfg.society then
        return cfg.society
    end
    return society():AccountForGang(gangName)
end

function GangServer.GetFunds(gangName)
    local account = GangServer.SocietyAccount(gangName)
    if not account then return 0 end
    return tonumber(society():GetBalance(account)) or 0
end

function GangServer.GradeList(gangName)
    local cfg = GangServer.GetGangDef(gangName)
    if not cfg then return {} end
    local out = {}
    for i = 1, #cfg.grades do
        local g = cfg.grades[i]
        out[#out + 1] = {
            grade = g.grade,
            name = g.name,
            label = g.label,
            isboss = g.isboss == true,
        }
    end
    table.sort(out, function(a, b) return a.grade < b.grade end)
    return out
end

function GangServer.GradeLabel(gangName, grade)
    local grades = GangServer.GradeList(gangName)
    grade = tonumber(grade) or 0
    for i = 1, #grades do
        if grades[i].grade == grade then
            return grades[i].label
        end
    end
    return ('Grade %s'):format(grade)
end

function GangServer.Notify(src, title, msg, nType)
    TriggerClientEvent('kodebykarl-gangsystem:client:notify', src, title or 'GANG', msg, nType or 'info')
end

function GangServer.SavePlayer(xPlayer)
    if not xPlayer then return end
    if Core and Core.SavePlayer then
        pcall(Core.SavePlayer, xPlayer)
    elseif ESX.SavePlayer then
        pcall(ESX.SavePlayer, xPlayer)
    end
end

function GangServer.EncodeGang(gangName, grade)
    gangName = tostring(gangName):lower()
    grade = tostring(grade or 0)
    local shared = ESX.Shared and ESX.Shared.Gangs and ESX.Shared.Gangs[gangName]
    if not shared or not shared.grades or not shared.grades[grade] then
        return nil
    end
    local g = shared.grades[grade]
    return {
        name = gangName,
        label = shared.label,
        isboss = g.isboss or false,
        grade = {
            name = g.name,
            level = tonumber(grade) or 0,
        },
    }
end

function GangServer.SetPlayerGang(xPlayer, gangName, grade, notifyMsg)
    if not xPlayer or not xPlayer.setGang then return false, 'invalid' end
    local ok = xPlayer.setGang(gangName, grade)
    if not ok then return false, 'failed' end
    GangServer.SavePlayer(xPlayer)
    if notifyMsg then
        GangServer.Notify(xPlayer.source, 'GANG', notifyMsg, 'success')
    end
    return true
end

function GangServer.SetOfflineGang(identifier, gangName, grade)
    local payload = GangServer.EncodeGang(gangName, grade)
    if not payload then return false end
    MySQL.update.await('UPDATE users SET gang = ? WHERE identifier = ?', {
        json.encode(payload),
        identifier,
    })
    return true
end

function GangServer.ClearOfflineGang(identifier)
    local payload = {
        name = 'none',
        label = 'No Gang',
        isboss = false,
        grade = { name = 'Unaffiliated', level = 0 },
    }
    MySQL.update.await('UPDATE users SET gang = ? WHERE identifier = ?', {
        json.encode(payload),
        identifier,
    })
    return true
end

function GangServer.IsNear(src, targetId, maxDist)
    maxDist = maxDist or Config.HireDistance or 5.0
    local pedA = GetPlayerPed(src)
    local pedB = GetPlayerPed(targetId)
    if not pedA or pedA == 0 or not pedB or pedB == 0 then return false end
    return #(GetEntityCoords(pedA) - GetEntityCoords(pedB)) <= maxDist
end

function GangServer.DisplayName(xPlayer, row)
    if xPlayer then
        local first = xPlayer.get and xPlayer.get('firstName')
        local last = xPlayer.get and xPlayer.get('lastName')
        if first or last then
            return (('%s %s'):format(first or '', last or '')):gsub('^%s+', ''):gsub('%s+$', '')
        end
        return xPlayer.getName and xPlayer.getName() or GetPlayerName(xPlayer.source) or 'Unknown'
    end
    if row then
        local name = (('%s %s'):format(row.firstname or '', row.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
        if name ~= '' then return name end
    end
    return 'Unknown'
end

function GangServer.GetMembers(gangName)
    gangName = tostring(gangName):lower()
    local rows = MySQL.query.await([[
        SELECT identifier, firstname, lastname, gang
        FROM users
        WHERE gang IS NOT NULL
          AND gang != ''
          AND JSON_UNQUOTE(JSON_EXTRACT(gang, '$.name')) = ?
        ORDER BY CAST(JSON_UNQUOTE(JSON_EXTRACT(gang, '$.grade.level')) AS UNSIGNED) DESC, lastname ASC
    ]], { gangName }) or {}

    local out = {}
    local onlineCount = 0

    for i = 1, #rows do
        local row = rows[i]
        local xTarget = ESX.GetPlayerFromIdentifier(row.identifier)
        local grade = 0
        local gradeLabel = 'Member'

        if xTarget then
            local gang = xTarget.getGang and xTarget.getGang() or xTarget.gang
            if type(gang) == 'table' and gang.name == gangName then
                grade = GangServer.GetGradeLevel(gang)
                gradeLabel = (gang.grade and gang.grade.name) or GangServer.GradeLabel(gangName, grade)
            else
                -- Live gang no longer matches — skip
                goto continue
            end
            onlineCount = onlineCount + 1
        else
            local decoded = type(row.gang) == 'string' and json.decode(row.gang) or row.gang
            if type(decoded) == 'table' then
                grade = GangServer.GetGradeLevel(decoded)
                gradeLabel = (decoded.grade and decoded.grade.name) or GangServer.GradeLabel(gangName, grade)
            end
        end

        out[#out + 1] = {
            identifier = row.identifier,
            name = GangServer.DisplayName(xTarget, row),
            grade = grade,
            gradeLabel = gradeLabel,
            online = xTarget ~= nil,
            serverId = xTarget and xTarget.source or nil,
        }
        ::continue::
    end

    -- Include online members whose DB row may lag behind setGang
    local xPlayers = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or {}
    local seen = {}
    for i = 1, #out do
        seen[out[i].identifier] = true
    end
    for _, xP in pairs(xPlayers) do
        if xP and xP.identifier and not seen[xP.identifier] then
            local gang = xP.getGang and xP.getGang() or xP.gang
            if type(gang) == 'table' and gang.name == gangName then
                local grade = GangServer.GetGradeLevel(gang)
                out[#out + 1] = {
                    identifier = xP.identifier,
                    name = GangServer.DisplayName(xP),
                    grade = grade,
                    gradeLabel = (gang.grade and gang.grade.name) or GangServer.GradeLabel(gangName, grade),
                    online = true,
                    serverId = xP.source,
                }
                onlineCount = onlineCount + 1
            end
        end
    end

    return out, onlineCount
end

function GangServer.BuildDashboard(src, gangName)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return { ok = false, error = 'offline' } end

    local gang = GangServer.GetPlayerGang(src)
    local staff = false
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    if group == 'admin' or group == 'owner' or group == 'developer' or group == 'superadmin' then
        staff = true
    end

    if staff and gangName and GangServer.GetGangDef(gangName) then
        -- staff can view selected gang
    elseif gang and GangServer.IsBoss(src, gang.name) then
        gangName = gang.name
    elseif staff then
        local list = {}
        for name, cfg in pairs(Config.Gangs) do
            list[#list + 1] = { name = name, label = cfg.label }
        end
        return {
            ok = true,
            staff = true,
            gangs = list,
            members = {},
            grades = {},
            memberCount = 0,
            onlineCount = 0,
        }
    else
        return { ok = false, error = 'denied', message = 'Gang boss access only.' }
    end

    gangName = tostring(gangName):lower()
    local cfg = GangServer.GetGangDef(gangName)
    if not cfg then
        return { ok = false, error = 'invalid', message = 'Unknown gang.' }
    end

    if not staff and not GangServer.IsBoss(src, gangName) then
        return { ok = false, error = 'denied', message = 'Gang boss access only.' }
    end

    local members, onlineCount = GangServer.GetMembers(gangName)
    local grades = GangServer.GradeList(gangName)
    local yourGrade = gang and gang.name == gangName and GangServer.GetGradeLevel(gang) or 99
    if staff then yourGrade = 99 end

    return {
        ok = true,
        gang = gangName,
        label = cfg.label,
        yourGrade = yourGrade,
        members = members,
        grades = grades,
        memberCount = #members,
        onlineCount = onlineCount or 0,
        staff = staff,
        funds = GangServer.GetFunds(gangName),
    }
end

-- Exports expected by iPad / turfwar
exports('GetGangs', function()
    return GangServer.GetGangsMap()
end)

exports('IsBoss', function(src, gangName)
    return GangServer.IsBoss(src, gangName)
end)

exports('GetPlayerGang', function(src)
    local gang = GangServer.GetPlayerGang(src)
    if not gang then
        return { name = 'none', label = 'No Gang' }
    end
    return gang
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for gangName, cfg in pairs(Config.Gangs) do
        if cfg.society and GetResourceState('cfx-keydi-society') == 'started' then
            pcall(function()
                society():EnsureAccount(cfg.society, cfg.label)
            end)
        end
        -- Ensure ESX shared gang exists
        if ESX.Shared and ESX.Shared.Gangs and not ESX.Shared.Gangs[gangName] then
            local grades = {}
            for i = 1, #cfg.grades do
                local g = cfg.grades[i]
                grades[tostring(g.grade)] = {
                    name = g.label,
                    isboss = g.isboss == true,
                }
            end
            pcall(function()
                exports.es_extended:AddGang(gangName, {
                    label = cfg.label,
                    grades = grades,
                })
            end)
        end
    end
    print('[kodebykarl-gangsystem] Ready')
end)
