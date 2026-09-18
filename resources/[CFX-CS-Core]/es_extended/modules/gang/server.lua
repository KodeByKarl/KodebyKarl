ESX.Gang = {}

local function escapeQuotes(str)
	str = str.gsub(str, '([%c%z\\"\'])', {
		['\\'] = '\\\\',
		['"'] = '\\"',
		['\''] = '\\\'',
		['\b'] = '\\b',
		['\f'] = '\\f',
		['\n'] = '\\n',
		['\r'] = '\\r',
		['\t'] = '\\t',
		['\0'] = '\\0'
	})
	return str
end

local function convertGroupsToPlainText(groupTable, type)
    local lines = {
        'ESXShared = ESXShared or {}',
        'ESXShared.Gangs = {'
    }

    -- Iterate through job table and format them according to QBox structure
    for groupName, groupData in pairs(groupTable) do
        -- Add group entry (convert to lower case for group name)
        local groupLine = string.format("    ['%s'] = {", groupName:lower())
        table.insert(lines, groupLine)

        -- Add group label
        local labelLine = string.format("        label = '%s',", escapeQuotes(groupData.label))
        table.insert(lines, labelLine)

        if type == 'Job' then
            -- Add defaultDuty and offDutyPay
            if groupData.defaultDuty ~= nil then
                local defaultDutyLine = string.format("        defaultDuty = %s,", tostring(groupData.defaultDuty))
                table.insert(lines, defaultDutyLine)
            end
            if groupData.offDutyPay ~= nil then
                local offDutyPayLine = string.format("        offDutyPay = %s,", tostring(groupData.offDutyPay))
                table.insert(lines, offDutyPayLine)
            end
        end

        -- Add grades table
        table.insert(lines, "        grades = {")
        for gradeIndex, gradeData in pairs(groupData.grades) do
            -- Start the grade entry
            local gradeLine = string.format("            ['%d'] = { name = '%s'", gradeIndex, escapeQuotes(gradeData.name))

            if type == 'Job' then
                gradeLine = string.format(gradeLine .. ', payment = %d', gradeData.payment)
            end

            -- Add isBoss if true
            if gradeData.isboss then
                gradeLine = gradeLine .. ", isboss = true"
            end

            -- Add bankAuth if true
            if gradeData.bankAuth then
                gradeLine = gradeLine .. ", bankAuth = true"
            end

            -- Close the grade entry
            gradeLine = gradeLine .. " },"
            table.insert(lines, gradeLine)
        end
        table.insert(lines, "        },")

        -- Close the group entry
        table.insert(lines, "    },")
    end

    -- Close the groups table
    table.insert(lines, '}')
    return table.concat(lines, '\n')
end

local function AddGang(gangName, gang)
    if type(gangName) ~= "string" then
        return false, "invalid_gang_name"
    end

    if ESX.Shared.Gangs[gangName] then
        return false, "gang_exists"
    end

    ESX.Shared.Gangs[gangName] = gang

    TriggerClientEvent('ESX:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
    TriggerEvent('ESX:Server:UpdateObject')

    local modifiedData = convertGroupsToPlainText(ESX.Shared.Gangs, 'Gangs')
    SaveResourceFile(GetCurrentResourceName(), 'shared/modules/gangs.lua', modifiedData, -1)
    return true, "success"
end

ESX.Gang.AddGang = AddGang
exports('AddGang', AddGang)


-- Multiple Add Gangs
local function AddGangs(gangs)
    local shouldContinue = true
    local message = "success"
    local errorItem = nil

    for key, value in pairs(gangs) do
        if type(key) ~= "string" then
            message = "invalid_gang_name"
            shouldContinue = false
            errorItem = gangs[key]
            break
        end

        if ESX.Shared.Gangs[key] then
            message = "gang_exists"
            shouldContinue = false
            errorItem = gangs[key]
            break
        end

        ESX.Shared.Gangs[key] = value
    end

    if not shouldContinue then return false, message, errorItem end
    TriggerClientEvent('ESX:Client:OnSharedUpdateMultiple', -1, 'Gangs', gangs)
    TriggerEvent('ESX:Server:UpdateObject')
    local modifiedData = convertGroupsToPlainText(ESX.Shared.Gangs, 'Gangs')
    SaveResourceFile(GetCurrentResourceName(), 'shared/modules/gangs.lua', modifiedData, -1)
    return true, message, nil
end

ESX.Gang.AddGangs = AddGangs
exports('AddGangs', AddGangs)

-- Single Remove Gang
local function RemoveGang(gangName)
    if type(gangName) ~= "string" then
        return false, "invalid_gang_name"
    end

    if not ESX.Shared.Gangs[gangName] then
        return false, "gang_not_exists"
    end

    ESX.Shared.Gangs[gangName] = nil

    TriggerClientEvent('ESX:Client:OnSharedUpdate', -1, 'Gangs', gangName, nil)
    TriggerEvent('ESX:Server:UpdateObject')
    local modifiedData = convertGroupsToPlainText(ESX.Shared.Gangs, 'Gangs')
    SaveResourceFile(GetCurrentResourceName(), 'shared/modules/gangs.lua', modifiedData, -1)
    return true, "success"
end

ESX.Gang.RemoveGang = RemoveGang
exports('RemoveGang', RemoveGang)

-- Single Update Gang
local function UpdateGang(gangName, gang)
    if type(gangName) ~= "string" then
        return false, "invalid_gang_name"
    end

    if not ESX.Shared.Gangs[gangName] then
        return false, "gang_not_exists"
    end

    ESX.Shared.Gangs[gangName] = gang

    TriggerClientEvent('ESX:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
    TriggerEvent('ESX:Server:UpdateObject')
    local modifiedData = convertGroupsToPlainText(ESX.Shared.Gangs, 'Gangs')
    SaveResourceFile(GetCurrentResourceName(), 'shared/modules/gangs.lua', modifiedData, -1)
    return true, "success"
end

ESX.Gang.UpdateGang = UpdateGang
exports('UpdateGang', UpdateGang)


exports('GetCurrentGangs', function()
    return ESX.Shared.Gangs
end)


RegisterCommand('gang', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    local gang = xPlayer.gang
    if not gang or not gang.name then
        xPlayer.triggerEvent('esx:Notify', 'You are not in a gang.', 'error', 5000)
        return
    end
    local formatted = {
        ('Gang: %s\n'):format(gang.label),
        ('Grade: %s\n'):format(gang.grade.name),
    }
    xPlayer.triggerEvent('esx:Notify', table.concat(formatted), 'info', 5000)
end, false)


ESX.RegisterCommand('setgang', {'superadmin', 'developer', 'admin'}, function(xPlayer, args, showError)
    local gangData = ESX.Shared.Gangs[args.gang]
    if not gangData then
        if showError then
            return showError('Invalid gang name')
        elseif xPlayer then
            return xPlayer.triggerEvent('esx:Notify', 'SYSTEM', 'Invalid gang name', 'error', 5000)
        else
            return print('[setgang] Invalid gang name')
        end
    end

    local gradeStr = tostring(args.grade)
    local gradeData = gangData.grades and gangData.grades[gradeStr]
    if not gradeData then
        if showError then
            return showError('Invalid gang grade')
        elseif xPlayer then
            return xPlayer.triggerEvent('esx:Notify', 'SYSTEM', 'Invalid gang grade', 'error', 5000)
        else
            return print('[setgang] Invalid gang grade')
        end
    end

    local success = args.playerId.setGang(args.gang, args.grade)
    local gradeLabel = gradeData.name or gradeStr
    local msg = ('You set %s to %s - %s'):format(args.playerId.name, gangData.label, gradeLabel)

    if success then
        if xPlayer then
            xPlayer.triggerEvent('esx:showNotification', msg, 'info', 5000)
        else
            print(('[setgang] %s'):format(msg))
        end
    else
        if xPlayer then
            xPlayer.triggerEvent('esx:showNotification', 'Failed to setgang.', 'error', 5000)
        else
            print('[setgang] Failed to setgang.')
        end
    end

    if Config.AdminLogging then
        ESX.DiscordLogFields("UserActions", "Set Gang /setgang Triggered!", "pink", {
            { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
            { name = "ID",     value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
            { name = "Target", value = args.playerId.name, inline = true },
            { name = "Gang name",  value = args.gang,  inline = true },
            { name = "Gang grade", value = args.grade, inline = true },
        })
    end
end, true, {
	help = 'Set A Players Gang',
	validate = true,
	arguments = {
		{ name = 'playerId', help = 'Player ID', type = 'player' },
		{ name = 'gang',      help = 'Gang name',      type = 'string' },
		{ name = 'grade',    help = 'Gang grade',    type = 'number' }
	}
})