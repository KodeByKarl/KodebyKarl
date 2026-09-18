local ESX = exports["es_extended"]:getSharedObject()
local openReports = {}
local adminDuty = {}

-- oxmysql may return messages as a JSON string or an already-decoded table (array or {["1"]=...}).
local function NormalizeMessages(raw)
    local list = {}

    if type(raw) == "string" and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if not ok then return list end
        raw = decoded
    end

    if type(raw) ~= "table" then
        return list
    end

    local function push(m)
        if type(m) ~= "table" then return end
        list[#list + 1] = {
            sender = (m.sender == "admin") and "admin" or "player",
            name = tostring(m.name or "Unknown"),
            text = tostring(m.text or ""),
            time = tonumber(m.time) or 0,
        }
    end

    if raw[1] ~= nil then
        for i = 1, #raw do
            push(raw[i])
        end
        return list
    end

    local numbered = {}
    for k, m in pairs(raw) do
        local idx = tonumber(k)
        if idx then
            numbered[#numbered + 1] = { i = idx, m = m }
        else
            push(m)
        end
    end
    table.sort(numbered, function(a, b) return a.i < b.i end)
    for i = 1, #numbered do
        push(numbered[i].m)
    end
    return list
end

local function EncodeMessages(raw)
    local messages = NormalizeMessages(raw)
    if #messages == 0 then
        return "[]"
    end
    return json.encode(messages)
end

local function CloneReport(identifier, report)
    if not report then return nil end
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    local isOnline = xTarget ~= nil
    local messages = NormalizeMessages(report.messages)
    return {
        identifier = identifier,
        category = report.category,
        title = report.title,
        description = report.description,
        createdAt = report.createdAt,
        updatedAt = report.updatedAt,
        messages = messages,
        messagesJson = EncodeMessages(messages),
        playerName = report.playerName,
        playerSource = isOnline and xTarget.source or (report.playerSource or -1),
        isOnline = isOnline,
    }
end

local function GetConvarWebhook()
    return GetConvar(ConfigReport.WebhookConvar, "")
end

local function NotifyStaff(category, playerName, src, kind)
    kind = kind or 'new'
    local title = kind == 'reply' and 'REPORT REPLY' or 'NEW REPORT'
    local message = kind == 'reply'
        and ('%s (ID %d) replied on their report [%s]. Open /report.'):format(playerName, src, category)
        or ('New [%s] report from %s (ID %d). Open /report.'):format(category, playerName, src)

    local xPlayers = ESX.GetExtendedPlayers()
    for _, xAdmin in ipairs(xPlayers) do
        if ConfigReport.StaffGroups[xAdmin.getGroup()] then
            TriggerClientEvent('cfx-keydi-report:client:staffAlert', xAdmin.source, {
                title = title,
                message = message,
                kind = kind,
                category = category,
                playerName = playerName,
                playerId = src,
            })
        end
    end
end

local function SendDiscordWebhook(xPlayer, src, category, title, desc)
    local webhook = GetConvarWebhook()
    if webhook == "" then return end

    local embed = {
        {
            ["color"] = 11163355,
            ["title"] = "**New Server Report Ticket**",
            ["description"] = ("**Submitted by:** %s (ID: %d)\n**Identifier:** %s\n\n**Category:** %s\n**Title:** %s\n\n**Description:**\n%s"):format(
                xPlayer.getName(), src, xPlayer.getIdentifier(), category, title, desc
            ),
            ["footer"] = { ["text"] = "cfx-keydi-report" },
            ["timestamp"] = os.date("!Y-%m-%dT%H:%M:%SZ"),
        },
    }

    PerformHttpRequest(webhook, function() end, "POST", json.encode({
        username = "Keydi Support Report",
        embeds = embed,
    }), { ["Content-Type"] = "application/json" })
end

-- Load active reports from DB
local function LoadReportsFromDatabase()
    MySQL.query('SELECT * FROM `cfx-keydi-report`', {}, function(results)
        if results then
            local count = 0
            for _, row in ipairs(results) do
                openReports[row.identifier] = {
                    category = row.category,
                    title = row.title,
                    description = row.description,
                    createdAt = row.createdAt,
                    updatedAt = row.updatedAt,
                    playerName = row.playerName,
                    playerSource = row.playerSource,
                    messages = NormalizeMessages(row.messages)
                }
                count = count + 1
            end
        end
    end)
end

-- Initialize database table
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `cfx-keydi-report` (
            `identifier` VARCHAR(60) NOT NULL,
            `category` VARCHAR(50) NOT NULL,
            `title` VARCHAR(255) NOT NULL,
            `description` TEXT NOT NULL,
            `createdAt` INT(11) NOT NULL,
            `updatedAt` INT(11) NOT NULL,
            `playerName` VARCHAR(100) NOT NULL,
            `playerSource` INT(11) NOT NULL,
            `messages` LONGTEXT NOT NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        LoadReportsFromDatabase()
    end)
end)

ESX.RegisterServerCallback("cfx-keydi-report:getInitialData", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(nil)
        return
    end

    local identifier = xPlayer.getIdentifier()
    local group = xPlayer.getGroup()
    local isAdmin = ConfigReport.StaffGroups[group] == true

    local allReportsList = {}
    local dutyStatus = false

    -- Sync and update target source ID on NUI load if online
    if openReports[identifier] then
        openReports[identifier].playerSource = source
        MySQL.update('UPDATE `cfx-keydi-report` SET playerSource = ? WHERE identifier = ?', { source, identifier })
    end

    if isAdmin then
        dutyStatus = adminDuty[identifier] == true
        for playerIdentifier, report in pairs(openReports) do
            local xTarget = ESX.GetPlayerFromIdentifier(playerIdentifier)
            local isOnline = xTarget ~= nil
            local activeSource = isOnline and xTarget.source or -1

            if isOnline then
                report.playerSource = activeSource
            end

            table.insert(allReportsList, CloneReport(playerIdentifier, report))
        end
    end

    cb({
        openReport = CloneReport(identifier, openReports[identifier]),
        isAdmin = isAdmin,
        allReports = allReportsList,
        adminDutyStatus = dutyStatus,
    })
end)

RegisterNetEvent("cfx-keydi-report:submitReport", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local category = data.category or "other"
    local title = (data.title or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local description = (data.description or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if title == "" or description == "" then
        TriggerClientEvent("esx:showNotification", src, "Please fill in both title and description.", "error")
        return
    end

    if #title > ConfigReport.MaxTitleLength then
        TriggerClientEvent("esx:showNotification", src, ("Title must be under %d characters."):format(ConfigReport.MaxTitleLength), "error")
        return
    end

    if #description > ConfigReport.MaxDescriptionLength then
        TriggerClientEvent("esx:showNotification", src, ("Description must be under %d characters."):format(ConfigReport.MaxDescriptionLength), "error")
        return
    end

    local existing = openReports[identifier]
    local isUpdate = existing ~= nil
    local initialMessages = NormalizeMessages(existing and existing.messages)
    if #initialMessages == 0 then
        initialMessages = {
            { sender = "player", name = xPlayer.getName(), text = description, time = os.time() }
        }
    end

    openReports[identifier] = {
        category = category,
        title = title,
        description = description,
        createdAt = existing and existing.createdAt or os.time(),
        updatedAt = os.time(),
        playerName = xPlayer.getName(),
        playerSource = src,
        messages = initialMessages,
    }

    -- Save to SQL database
    MySQL.update([[
        REPLACE INTO `cfx-keydi-report` (identifier, category, title, description, createdAt, updatedAt, playerName, playerSource, messages)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        identifier,
        category,
        title,
        description,
        openReports[identifier].createdAt,
        openReports[identifier].updatedAt,
        openReports[identifier].playerName,
        openReports[identifier].playerSource,
        EncodeMessages(openReports[identifier].messages)
    })

    print("\n==================================================")
    print(("[REPORT SYSTEM] %s by: %s (ID: %d)"):format(isUpdate and "Ticket Updated" or "New Ticket", xPlayer.getName(), src))
    print(("[Category]: %s"):format(category))
    print(("[Title]: %s"):format(title))
    print(("[Description]: %s"):format(description))
    print("==================================================\n")

    if not isUpdate then
        NotifyStaff(category, xPlayer.getName(), src, 'new')
        SendDiscordWebhook(xPlayer, src, category, title, description)
    end

    TriggerClientEvent("esx:showNotification", src,
        isUpdate and "Your open report was updated. Staff will review it soon." or "Your report has been submitted to active staff. Thank you!",
        "success")

    TriggerClientEvent("cfx-keydi-report:client:reportSaved", src, CloneReport(identifier, openReports[identifier]))

    -- Also notify admins of the new report immediately
    local reportData = CloneReport(identifier, openReports[identifier])

    local xPlayers = ESX.GetExtendedPlayers()
    for _, xAdmin in ipairs(xPlayers) do
        if ConfigReport.StaffGroups[xAdmin.getGroup()] then
            TriggerClientEvent("cfx-keydi-report:client:adminUpdateReports", xAdmin.source, identifier, reportData)
        end
    end
end)

RegisterNetEvent("cfx-keydi-report:server:sendMessage", function(playerIdentifier, messageText)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if type(messageText) ~= "string" then return end

    messageText = messageText:gsub("^%s+", ""):gsub("%s+$", "")
    if messageText == "" then return end
    if #messageText > (ConfigReport.MaxDescriptionLength or 500) then
        messageText = messageText:sub(1, ConfigReport.MaxDescriptionLength)
    end

    local identifier = xPlayer.getIdentifier()
    local group = xPlayer.getGroup()
    local isAdmin = ConfigReport.StaffGroups[group] == true

    -- Players always chat on their own ticket. Empty identifier used to drop the message.
    if not isAdmin or type(playerIdentifier) ~= "string" or playerIdentifier == "" then
        playerIdentifier = identifier
    end

    local report = openReports[playerIdentifier]
    if not report then return end

    if not isAdmin and playerIdentifier ~= identifier then
        return
    end

    local senderType = isAdmin and "admin" or "player"

    local messageData = {
        sender = senderType,
        name = xPlayer.getName(),
        text = messageText,
        time = os.time()
    }

    report.messages = NormalizeMessages(report.messages)
    table.insert(report.messages, messageData)
    report.updatedAt = os.time()

    -- Save messages to SQL database
    MySQL.update('UPDATE `cfx-keydi-report` SET messages = ?, updatedAt = ? WHERE identifier = ?', {
        EncodeMessages(report.messages),
        report.updatedAt,
        playerIdentifier
    })

    local payload = CloneReport(playerIdentifier, report)

    -- Always push the full ticket (with identifier + messages) to the player
    local xTarget = ESX.GetPlayerFromIdentifier(playerIdentifier)
    if xTarget then
        TriggerClientEvent("cfx-keydi-report:client:updateReport", xTarget.source, payload)
        if senderType == "admin" and xTarget.source ~= src then
            TriggerClientEvent("esx:showNotification", xTarget.source, "Staff replied to your report. Open /report to read it.", "info", 8000)
        end
    end

    -- Broadcast to admins (+ sound when the player replies)
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xAdmin in ipairs(xPlayers) do
        if ConfigReport.StaffGroups[xAdmin.getGroup()] then
            TriggerClientEvent("cfx-keydi-report:client:adminUpdateReports", xAdmin.source, playerIdentifier, payload)
        end
    end

    if senderType == "player" then
        NotifyStaff(report.category or "other", xPlayer.getName(), src, 'reply')
    end
end)

RegisterNetEvent("cfx-keydi-report:server:toggleDuty", function(status)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local group = xPlayer.getGroup()
    local isAdmin = ConfigReport.StaffGroups[group] == true

    if not isAdmin then return end

    adminDuty[identifier] = status
    local adminName = xPlayer.getName()

    if status then
        TriggerClientEvent("esx:showNotification", -1, ("Admin %s is now On Duty and will take care of your reports!"):format(adminName), "info", 6000)
    else
        TriggerClientEvent("esx:showNotification", -1, ("Admin %s is now Off Duty."):format(adminName), "info", 6000)
    end
end)

RegisterNetEvent("cfx-keydi-report:server:resolveReport", function(playerIdentifier)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local group = xPlayer.getGroup()
    local isAdmin = ConfigReport.StaffGroups[group] == true
    if not isAdmin then return end

    local report = openReports[playerIdentifier]
    if not report then return end

    -- Check online target before notifying and closing NUI
    local xTarget = ESX.GetPlayerFromIdentifier(playerIdentifier)
    if xTarget then
        TriggerClientEvent("esx:showNotification", xTarget.source, "Your report has been resolved by active staff. Thank you!", "success")
        TriggerClientEvent("cfx-keydi-report:client:reportClosed", xTarget.source)
    end

    openReports[playerIdentifier] = nil

    -- Delete from SQL database
    MySQL.update('DELETE FROM `cfx-keydi-report` WHERE identifier = ?', { playerIdentifier })

    -- Broadcast remove event to all admins
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xAdmin in ipairs(xPlayers) do
        if ConfigReport.StaffGroups[xAdmin.getGroup()] then
            TriggerClientEvent("cfx-keydi-report:client:adminRemoveReport", xAdmin.source, playerIdentifier)
        end
    end
end)

exports("ClosePlayerReport", function(identifier)
    openReports[identifier] = nil
    MySQL.update('DELETE FROM `cfx-keydi-report` WHERE identifier = ?', { identifier })
end)

exports("GetOpenReport", function(identifier)
    return openReports[identifier]
end)
