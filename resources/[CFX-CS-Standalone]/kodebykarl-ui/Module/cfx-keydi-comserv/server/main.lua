--[[
    cfx-keydi-comserv (server)
    Staff panel + persistent online/offline community service
]]

if not ConfigComServ or not ConfigComServ.Enabled then return end

local ESX = exports["es_extended"]:getSharedObject()

-- identifier -> sentence entry
local sentences = {}
-- source -> identifier (online only)
local sourceToIdentifier = {}
-- source -> last task complete game timer
local taskCooldown = {}
-- source -> { t, n } sentence rate tracker
local sentenceRate = {}

-- Electron AC: always invoke on "ElectronAC" even if the folder was renamed.
-- https://docs.electron-services.com/exports/punishments
local function banPlayer(src, reason)
    local ok = pcall(function()
        exports["ElectronAC"]:banPlayer(src, reason, "cfx-keydi-comserv", true)
    end)
    if not ok then
        DropPlayer(src, reason)
    end
end

--- Returns false if over limit (and may ban). Counts every attempt including failed ones.
local function checkSentenceRate(src)
    local cfg = ConfigComServ.SentenceRateLimit or {}
    local maxN = cfg.Max or 3
    local window = cfg.WindowMs or 5000
    local now = GetGameTimer()
    local entry = sentenceRate[src]
    if not entry or (now - entry.t) > window then
        sentenceRate[src] = { t = now, n = 1 }
        return true
    end
    entry.n = entry.n + 1
    if entry.n > maxN then
        print(("[cfx-keydi-comserv] Mass sentence spam by %s [%s] (%d in %dms)")
            :format(GetPlayerName(src) or "?", src, entry.n, window))
        if cfg.BanOnExceed ~= false then
            banPlayer(src, "Comserv mass sentence exploit")
        end
        return false
    end
    return true
end

local function debugPrint(...)
    if ConfigComServ.Debug then
        print("[cfx-keydi-comserv]", ...)
    end
end

local function isStaff(xPlayer)
    if not xPlayer then return false end

    local group = xPlayer.getGroup and xPlayer.getGroup() or "user"
    if ConfigComServ.StaffGroups[group] == true then
        return true
    end

    local src = xPlayer.source
    if src and IsPlayerAceAllowed(src, "command") then
        return true
    end

    if xPlayer.isAdmin and xPlayer.isAdmin() then
        return true
    end

    return false
end

local function notify(src, msg, msgType)
    if not src or src <= 0 then return end
    TriggerClientEvent("esx:showNotification", src, msg, msgType or "info")
end

local function clampActions(actions)
    actions = tonumber(actions) or ConfigComServ.DefaultActions
    return math.max(1, math.min(math.floor(actions), ConfigComServ.MaxActions))
end

local function getPlayerNameFromRow(row)
    if not row then return "Unknown" end
    local first = row.firstname or ""
    local last = row.lastname or ""
    local full = (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
    if full ~= "" then return full end
    return row.identifier or "Unknown"
end

local function getOnlineName(xPlayer)
    if not xPlayer then return "Unknown" end
    if xPlayer.getName then
        local n = xPlayer.getName()
        if n and n ~= "" then return n end
    end
    return GetPlayerName(xPlayer.source) or "Unknown"
end

--- Full identity bundle for staff UI (online source preferred)
local function getPlayerDetails(src, fallbackIdentifier)
    local details = {
        discord = "N/A",
        steam = "N/A",
        license = "N/A",
        license2 = "N/A",
        fivem = "N/A",
        xbl = "N/A",
        live = "N/A",
        ip = "N/A",
        ping = nil,
    }

    if fallbackIdentifier and fallbackIdentifier ~= "" then
        local id = fallbackIdentifier
        if id:sub(1, 8) == "license:" then
            details.license = id:sub(9)
        elseif id:sub(1, 9) == "license2:" then
            details.license2 = id:sub(10)
        elseif id:sub(1, 5) == "char" and id:find(":") then
            -- ESX multichar: char1:licensehash
            local hash = id:match(":(.+)$")
            details.license = hash or id
        else
            details.license = id
        end
    end

    if not src then
        return details
    end

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id then
            if id:sub(1, 8) == "discord:" then
                details.discord = id:sub(9)
            elseif id:sub(1, 6) == "steam:" then
                details.steam = id
            elseif id:sub(1, 9) == "license2:" then
                details.license2 = id:sub(10)
            elseif id:sub(1, 8) == "license:" then
                details.license = id:sub(9)
            elseif id:sub(1, 6) == "fivem:" then
                details.fivem = id:sub(7)
            elseif id:sub(1, 4) == "xbl:" then
                details.xbl = id:sub(5)
            elseif id:sub(1, 5) == "live:" then
                details.live = id:sub(6)
            end
        end
    end

    local endpoint = GetPlayerEndpoint(src)
    if endpoint and endpoint ~= "" then
        details.ip = endpoint:match("^([^:]+)") or endpoint
    end

    details.ping = GetPlayerPing(src)
    return details
end

local function findSourceByIdentifier(identifier)
    if not identifier then return nil end
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then return xTarget.source, xTarget end
    return nil, nil
end

local function sentenceClientPayload(entry)
    return {
        remaining = entry.remaining,
        total = entry.total,
        reason = entry.reason or "",
    }
end

local function sentenceUiPayload(entry)
    local src = findSourceByIdentifier(entry.identifier)
    local details = getPlayerDetails(src, entry.identifier)
    return {
        identifier = entry.identifier,
        name = entry.playerName or "Unknown",
        remaining = entry.remaining,
        total = entry.total,
        reason = entry.reason or "",
        adminName = entry.adminName or "Unknown",
        adminIdentifier = entry.adminIdentifier or "",
        createdAt = entry.createdAt or 0,
        online = src ~= nil,
        source = src,
        discord = details.discord,
        steam = details.steam,
        license = details.license,
        license2 = details.license2,
        fivem = details.fivem,
        ip = details.ip,
        ping = details.ping,
    }
end

local function getActiveList()
    local list = {}
    for _, entry in pairs(sentences) do
        list[#list + 1] = sentenceUiPayload(entry)
    end
    table.sort(list, function(a, b)
        if a.online ~= b.online then
            return a.online and not b.online
        end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

local function getOnlinePlayers(_excludeSrc)
    local list = {}
    for _, xPlayer in ipairs(ESX.GetExtendedPlayers()) do
        local src = xPlayer.source
        if src then
            local identifier = xPlayer.getIdentifier()
            local details = getPlayerDetails(src, identifier)
            list[#list + 1] = {
                source = src,
                identifier = identifier,
                name = getOnlineName(xPlayer),
                group = xPlayer.getGroup and xPlayer.getGroup() or "user",
                online = true,
                serving = sentences[identifier] ~= nil,
                discord = details.discord,
                steam = details.steam,
                license = details.license,
                license2 = details.license2,
                fivem = details.fivem,
                ip = details.ip,
                ping = details.ping,
            }
        end
    end
    table.sort(list, function(a, b) return (a.source or 0) < (b.source or 0) end)
    return list
end

local function persistSentence(entry)
    MySQL.update([[
        INSERT INTO `cfx-keydi-comserv`
            (`identifier`, `player_name`, `remaining`, `total`, `reason`, `admin_identifier`, `admin_name`, `created_at`, `items_json`, `items_taken`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `player_name` = VALUES(`player_name`),
            `remaining` = VALUES(`remaining`),
            `total` = VALUES(`total`),
            `reason` = VALUES(`reason`),
            `admin_identifier` = VALUES(`admin_identifier`),
            `admin_name` = VALUES(`admin_name`),
            `created_at` = VALUES(`created_at`),
            `items_json` = VALUES(`items_json`),
            `items_taken` = VALUES(`items_taken`)
    ]], {
        entry.identifier,
        entry.playerName,
        entry.remaining,
        entry.total,
        entry.reason,
        entry.adminIdentifier,
        entry.adminName,
        entry.createdAt,
        entry.itemsJson or "[]",
        entry.itemsTaken and 1 or 0,
    })
end

local function deletePersisted(identifier)
    MySQL.update("DELETE FROM `cfx-keydi-comserv` WHERE `identifier` = ?", { identifier })
end

local function updatePersistedRemaining(entry)
    MySQL.update(
        "UPDATE `cfx-keydi-comserv` SET `remaining` = ?, `items_json` = ?, `items_taken` = ? WHERE `identifier` = ?",
        { entry.remaining, entry.itemsJson or "[]", entry.itemsTaken and 1 or 0, entry.identifier }
    )
end

local function snapshotInventory(src)
    local items = exports.ox_inventory:GetInventoryItems(src)
    local saved = {}
    if type(items) ~= "table" then return saved end

    for _, item in pairs(items) do
        if item and item.name and (item.count or 0) > 0 then
            saved[#saved + 1] = {
                name = item.name,
                count = item.count,
                metadata = item.metadata,
            }
        end
    end
    return saved
end

local function giveTemporaryItems(src)
    local cfg = ConfigComServ.InventorySwap
    if not cfg or not cfg.Enabled then return end
    local temps = cfg.TemporaryItems or {}
    for itemName, count in pairs(temps) do
        count = tonumber(count) or 0
        if count > 0 then
            exports.ox_inventory:AddItem(src, itemName, count)
        end
    end
end

--- Confiscate player items once, then give temporary comserv supplies
local function confiscateAndGiveTemp(src, entry)
    if not src or not entry then return end
    local cfg = ConfigComServ.InventorySwap
    if not cfg or not cfg.Enabled then return end
    if entry.itemsTaken then return end

    local saved = snapshotInventory(src)
    entry.itemsJson = json.encode(saved)
    entry.itemsTaken = true
    persistSentence(entry)

    exports.ox_inventory:ClearInventory(src)
    Wait(100)
    giveTemporaryItems(src)

    debugPrint(("Confiscated %d item stack(s) from %s"):format(#saved, entry.identifier))
end

--- Clear temp inventory and restore confiscated items
local function restoreConfiscatedInventory(src, entry)
    if not src or not entry then return end
    local cfg = ConfigComServ.InventorySwap
    if not cfg or not cfg.Enabled then return end
    if not entry.itemsTaken then return end

    exports.ox_inventory:ClearInventory(src)
    Wait(100)

    local saved = {}
    if entry.itemsJson and entry.itemsJson ~= "" then
        local ok, decoded = pcall(json.decode, entry.itemsJson)
        if ok and type(decoded) == "table" then
            saved = decoded
        end
    end

    for _, info in pairs(saved) do
        if info and info.name and (tonumber(info.count) or 0) > 0 then
            exports.ox_inventory:AddItem(src, info.name, tonumber(info.count), info.metadata)
        end
    end

    entry.itemsTaken = false
    entry.itemsJson = "[]"
    debugPrint(("Restored inventory for %s"):format(entry.identifier))
end

local function applyToClient(src, entry)
    if not src or not entry then return end
    confiscateAndGiveTemp(src, entry)
    TriggerClientEvent("cfx-keydi-comserv:client:start", src, sentenceClientPayload(entry))
end

local function endSentenceByIdentifier(identifier, completed, notifyTarget, endedByName)
    local entry = sentences[identifier]
    if not entry then return false, ConfigComServ.Locale.notServing end

    local src = findSourceByIdentifier(identifier)
    local remainingAtEnd = entry.remaining

    if src then
        restoreConfiscatedInventory(src, entry)
        sourceToIdentifier[src] = nil
        taskCooldown[src] = nil
        TriggerClientEvent("cfx-keydi-comserv:client:end", src, completed == true)
        if notifyTarget and not completed then
            notify(src, ConfigComServ.Locale.endedByStaff, "info")
        end
    elseif entry.itemsTaken and entry.itemsJson and entry.itemsJson ~= "" and entry.itemsJson ~= "[]" then
        -- Offline end — queue original items for restore on next login
        MySQL.update([[
            INSERT INTO `cfx-keydi-comserv-restore` (`identifier`, `items_json`)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE `items_json` = VALUES(`items_json`)
        ]], { identifier, entry.itemsJson })
    end

    if ComServLogs and ComServLogs.Finish then
        ComServLogs.Finish({
            targetSrc = src,
            targetName = entry.playerName,
            identifier = entry.identifier,
            adminName = entry.adminName,
            total = entry.total,
            remaining = remainingAtEnd,
            reason = entry.reason,
            completed = completed == true,
            endedBy = endedByName or (completed and "Player" or "Staff"),
        })
    end

    sentences[identifier] = nil
    deletePersisted(identifier)

    debugPrint(("Sentence ended for %s (completed=%s)"):format(identifier, tostring(completed == true)))
    return true
end

local function reduceSentenceByIdentifier(identifier, amount)
    local entry = sentences[identifier]
    if not entry then return false end

    amount = math.max(1, tonumber(amount) or 1)
    entry.remaining = math.max(0, entry.remaining - amount)

    local src = findSourceByIdentifier(identifier)

    if ComServLogs and ComServLogs.Action then
        ComServLogs.Action({
            targetSrc = src,
            targetName = entry.playerName,
            identifier = entry.identifier,
            remaining = entry.remaining,
            total = entry.total,
            reason = entry.reason,
        })
    end

    if entry.remaining <= 0 then
        endSentenceByIdentifier(identifier, true, false)
        return true, 0
    end

    updatePersistedRemaining(entry)

    if src then
        TriggerClientEvent("cfx-keydi-comserv:client:update", src, {
            remaining = entry.remaining,
            total = entry.total,
            reason = entry.reason,
            notifyReduce = true,
        })
    end

    return true, entry.remaining
end

local function escapeChatText(text)
    return tostring(text or "")
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
end

--- City-wide chat card, same style as EMS bodybag (FEED banner + name + reason).
local function broadcastComservChat(playerName, reason)
    local cfg = ConfigComServ.ChatAnnounce
    if cfg and cfg.Enabled == false then return end

    local name = escapeChatText(playerName or "Unknown")
    local why = escapeChatText(reason or "Community Service")
    local locale = ConfigComServ.Locale and ConfigComServ.Locale.chatAnnounce
    local message = locale and locale:format(name, why)
        or ("%s has been sentenced to community service. Reason: %s"):format(name, why)

    local jobName = (cfg and cfg.Job) or "police"
    local header = (cfg and cfg.Header) or "FEED • COMSERV | SYSTEM"

    if type(JobTemplateWithoutID) == "function" then
        JobTemplateWithoutID(jobName, message, header)
        return
    end

    pcall(function()
        exports["kodebykarl-ui"]:JobTemplateWithoutID(jobName, message, header)
    end)
end

local function startSentence(opts)
    opts = opts or {}
    local actions = clampActions(opts.actions)
    local reason = tostring(opts.reason or "Community Service")
    if reason == "" then reason = "Community Service" end
    if #reason > 180 then reason = reason:sub(1, 180) end

    local adminSrc = opts.adminSrc or 0
    local xAdmin = adminSrc > 0 and ESX.GetPlayerFromId(adminSrc) or nil
    local adminName = xAdmin and getOnlineName(xAdmin) or (adminSrc == 0 and "Console" or "Staff")
    local adminIdentifier = xAdmin and xAdmin.getIdentifier() or "console"

    local identifier = opts.identifier
    local playerName = opts.playerName
    local xTarget = nil
    local targetSrc = tonumber(opts.targetSource)

    if targetSrc then
        xTarget = ESX.GetPlayerFromId(targetSrc)
        if not xTarget then
            return false, ConfigComServ.Locale.invalidTarget
        end
        identifier = xTarget.getIdentifier()
        playerName = getOnlineName(xTarget)
    elseif identifier and identifier ~= "" then
        xTarget = ESX.GetPlayerFromIdentifier(identifier)
        if xTarget then
            targetSrc = xTarget.source
            playerName = getOnlineName(xTarget)
        end
    else
        return false, ConfigComServ.Locale.invalidTarget
    end

    if not identifier or identifier == "" then
        return false, ConfigComServ.Locale.invalidTarget
    end

    if sentences[identifier] then
        return false, ConfigComServ.Locale.alreadyServing
    end

    if not playerName or playerName == "" then
        local row = MySQL.single.await(
            "SELECT firstname, lastname, identifier FROM users WHERE identifier = ? LIMIT 1",
            { identifier }
        )
        playerName = getPlayerNameFromRow(row)
    end

    local entry = {
        identifier = identifier,
        playerName = playerName,
        remaining = actions,
        total = actions,
        reason = reason,
        adminIdentifier = adminIdentifier,
        adminName = adminName,
        createdAt = os.time(),
        itemsJson = "[]",
        itemsTaken = false,
    }

    sentences[identifier] = entry
    persistSentence(entry)

    local mode = "offline"
    if targetSrc and xTarget then
        sourceToIdentifier[targetSrc] = identifier
        applyToClient(targetSrc, entry)
        notify(targetSrc, (ConfigComServ.Locale.started):format(actions), "warning")
        debugPrint(("Online sentence: %s (%d) -> %d actions"):format(playerName, targetSrc, actions))
        mode = "online"
    else
        debugPrint(("Offline sentence saved for %s -> %d actions"):format(identifier, actions))
    end

    if ComServLogs and ComServLogs.Sent then
        ComServLogs.Sent({
            targetSrc = targetSrc,
            targetName = playerName,
            identifier = identifier,
            adminSrc = adminSrc,
            adminName = adminName,
            adminIdentifier = adminIdentifier,
            actions = actions,
            reason = reason,
            mode = mode,
        })
    end

    broadcastComservChat(playerName, reason)

    return true, mode
end

local function loadSentencesFromDb()
    local rows = MySQL.query.await("SELECT * FROM `cfx-keydi-comserv`") or {}
    sentences = {}
    for _, row in ipairs(rows) do
        local remaining = tonumber(row.remaining) or 0
        if remaining > 0 then
            sentences[row.identifier] = {
                identifier = row.identifier,
                playerName = row.player_name or "Unknown",
                remaining = remaining,
                total = tonumber(row.total) or remaining,
                reason = row.reason or "Community Service",
                adminIdentifier = row.admin_identifier or "",
                adminName = row.admin_name or "Staff",
                createdAt = tonumber(row.created_at) or 0,
                itemsJson = row.items_json or "[]",
                itemsTaken = tonumber(row.items_taken) == 1,
            }
        else
            deletePersisted(row.identifier)
        end
    end
    debugPrint(("Loaded %d comserv sentence(s) from DB"):format(#rows))
end

local function tryRestorePendingInventory(playerId, identifier)
    local row = MySQL.single.await(
        "SELECT items_json FROM `cfx-keydi-comserv-restore` WHERE identifier = ? LIMIT 1",
        { identifier }
    )
    if not row or not row.items_json then return end

    exports.ox_inventory:ClearInventory(playerId)
    Wait(100)

    local ok, saved = pcall(json.decode, row.items_json)
    if ok and type(saved) == "table" then
        for _, info in pairs(saved) do
            if info and info.name and (tonumber(info.count) or 0) > 0 then
                exports.ox_inventory:AddItem(playerId, info.name, tonumber(info.count), info.metadata)
            end
        end
    end

    MySQL.update("DELETE FROM `cfx-keydi-comserv-restore` WHERE identifier = ?", { identifier })
    debugPrint(("Pending inventory restored for %s"):format(identifier))
end

local function tryApplyOnJoin(playerId, xPlayer)
    xPlayer = xPlayer or ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()

    -- Restore items if sentence was ended while they were offline
    SetTimeout(2000, function()
        if not ESX.GetPlayerFromId(playerId) then return end
        tryRestorePendingInventory(playerId, identifier)
    end)

    local entry = sentences[identifier]
    if not entry then return end

    sourceToIdentifier[playerId] = identifier
    entry.playerName = getOnlineName(xPlayer)
    persistSentence(entry)

    SetTimeout(2500, function()
        if not ESX.GetPlayerFromId(playerId) then return end
        if not sentences[identifier] then return end
        applyToClient(playerId, entry)
        notify(playerId, (ConfigComServ.Locale.started):format(entry.remaining), "warning")
    end)
end

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `cfx-keydi-comserv` (
            `identifier` VARCHAR(60) NOT NULL,
            `player_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `remaining` INT NOT NULL DEFAULT 0,
            `total` INT NOT NULL DEFAULT 0,
            `reason` VARCHAR(255) NOT NULL DEFAULT 'Community Service',
            `admin_identifier` VARCHAR(60) NOT NULL DEFAULT '',
            `admin_name` VARCHAR(100) NOT NULL DEFAULT 'Staff',
            `created_at` INT NOT NULL DEFAULT 0,
            `items_json` LONGTEXT NULL,
            `items_taken` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        -- Migrate older tables that predate inventory columns
        pcall(function()
            MySQL.query.await("ALTER TABLE `cfx-keydi-comserv` ADD COLUMN `items_json` LONGTEXT NULL")
        end)
        pcall(function()
            MySQL.query.await("ALTER TABLE `cfx-keydi-comserv` ADD COLUMN `items_taken` TINYINT(1) NOT NULL DEFAULT 0")
        end)
        pcall(function()
            MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `cfx-keydi-comserv-restore` (
                    `identifier` VARCHAR(60) NOT NULL,
                    `items_json` LONGTEXT NOT NULL,
                    PRIMARY KEY (`identifier`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ]])
        end)

        loadSentencesFromDb()

        -- Re-apply to anyone already online after resource restart
        SetTimeout(1500, function()
            for _, xPlayer in ipairs(ESX.GetExtendedPlayers()) do
                tryApplyOnJoin(xPlayer.source, xPlayer)
            end
        end)
    end)
end)

ESX.RegisterServerCallback("cfx-keydi-comserv:open", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isStaff(xPlayer) then
        cb(nil)
        return
    end

    cb({
        brand = ConfigComServ.Brand or "GRIM CITY",
        defaultActions = ConfigComServ.DefaultActions,
        maxActions = ConfigComServ.MaxActions,
        staffName = getOnlineName(xPlayer),
        staffId = source,
        online = getOnlinePlayers(source),
        active = getActiveList(),
    })
end)

ESX.RegisterServerCallback("cfx-keydi-comserv:refresh", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isStaff(xPlayer) then
        cb(nil)
        return
    end

    cb({
        online = getOnlinePlayers(source),
        active = getActiveList(),
    })
end)

ESX.RegisterServerCallback("cfx-keydi-comserv:searchOffline", function(source, cb, query)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isStaff(xPlayer) then
        cb({})
        return
    end

    query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #query < 2 then
        cb({})
        return
    end

    local limit = tonumber(ConfigComServ.OfflineSearchLimit) or 30
    local like = "%" .. query .. "%"
    local rows = MySQL.query.await([[
        SELECT identifier, firstname, lastname
        FROM users
        WHERE firstname LIKE ?
           OR lastname LIKE ?
           OR CONCAT(IFNULL(firstname, ''), ' ', IFNULL(lastname, '')) LIKE ?
           OR identifier LIKE ?
        LIMIT ?
    ]], { like, like, like, like, limit }) or {}

    local onlineIds = {}
    for _, xp in ipairs(ESX.GetExtendedPlayers()) do
        onlineIds[xp.getIdentifier()] = true
    end

    local results = {}
    for _, row in ipairs(rows) do
        if not onlineIds[row.identifier] then
            local details = getPlayerDetails(nil, row.identifier)
            results[#results + 1] = {
                identifier = row.identifier,
                name = getPlayerNameFromRow(row),
                online = false,
                serving = sentences[row.identifier] ~= nil,
                discord = details.discord,
                steam = details.steam,
                license = details.license,
                license2 = details.license2,
                fivem = details.fivem,
                ip = details.ip,
            }
        end
    end

    cb(results)
end)

-- Secure staff actions (server validates everything)
RegisterNetEvent("cfx-keydi-comserv:server:sentence", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not isStaff(xPlayer) then
        print(("[cfx-keydi-comserv] Unauthorized sentence from %s [%s]"):format(GetPlayerName(src) or "?", src))
        if ConfigComServ.BanOnUnauthorized ~= false then
            banPlayer(src, "Unauthorized comserv sentence (cheat)")
        else
            notify(src, ConfigComServ.Locale.noPermission, "error")
        end
        return
    end

    if not checkSentenceRate(src) then
        notify(src, "Too many comserv actions too fast. Slow down.", "error")
        return
    end

    if type(data) ~= "table" then
        notify(src, ConfigComServ.Locale.invalidTarget, "error")
        return
    end

    local ok, modeOrErr = startSentence({
        targetSource = data.source,
        identifier = data.identifier,
        playerName = data.name,
        actions = data.actions,
        reason = data.reason,
        adminSrc = src,
    })

    if not ok then
        notify(src, modeOrErr or "Failed", "error")
        return
    end

    if modeOrErr == "offline" then
        notify(src, ConfigComServ.Locale.sentencedOffline, "success")
    else
        notify(src, ConfigComServ.Locale.sentOk, "success")
    end

    TriggerClientEvent("cfx-keydi-comserv:client:panelRefresh", src)
end)

RegisterNetEvent("cfx-keydi-comserv:server:end", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not isStaff(xPlayer) then
        print(("[cfx-keydi-comserv] Unauthorized end from %s [%s]"):format(GetPlayerName(src) or "?", src))
        if ConfigComServ.BanOnUnauthorized ~= false then
            banPlayer(src, "Unauthorized comserv end (cheat)")
        else
            notify(src, ConfigComServ.Locale.noPermission, "error")
        end
        return
    end

    if not checkSentenceRate(src) then
        notify(src, "Too many comserv actions too fast. Slow down.", "error")
        return
    end

    if type(data) ~= "table" then
        notify(src, ConfigComServ.Locale.invalidTarget, "error")
        return
    end

    local identifier = data.identifier
    if (not identifier or identifier == "") and data.source then
        local xTarget = ESX.GetPlayerFromId(tonumber(data.source))
        identifier = xTarget and xTarget.getIdentifier() or nil
    end

    if not identifier or identifier == "" then
        notify(src, ConfigComServ.Locale.invalidTarget, "error")
        return
    end

    local ok, err = endSentenceByIdentifier(identifier, false, true, getOnlineName(xPlayer))
    if not ok then
        notify(src, err or "Failed", "error")
        return
    end

    notify(src, ConfigComServ.Locale.endedOk, "success")
    TriggerClientEvent("cfx-keydi-comserv:client:panelRefresh", src)
end)

RegisterNetEvent("cfx-keydi-comserv:server:completeTask", function()
    local src = source
    local identifier = sourceToIdentifier[src]
    if not identifier or not sentences[identifier] then return end

    local now = GetGameTimer()
    local cooldown = ConfigComServ.TaskCooldownMs or 2000
    if taskCooldown[src] and (now - taskCooldown[src]) < cooldown then
        return
    end
    taskCooldown[src] = now

    reduceSentenceByIdentifier(identifier, 1)
end)

RegisterCommand(ConfigComServ.Commands.open or "comserv", function(source)
    local src = source
    if src <= 0 then
        print("[cfx-keydi-comserv] Use the in-game /comserv panel.")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not isStaff(xPlayer) then
        notify(src, ConfigComServ.Locale.noPermission, "error")
        return
    end

    TriggerClientEvent("cfx-keydi-comserv:client:openPanel", src)
end, false)

AddEventHandler("esx:playerLoaded", function(playerId, xPlayer)
    tryApplyOnJoin(playerId, xPlayer)
end)

AddEventHandler("playerDropped", function()
    local src = source
    sourceToIdentifier[src] = nil
    taskCooldown[src] = nil
    sentenceRate[src] = nil
end)

-- Exports (identifier-aware where possible)
exports("StartComServ", function(target, actions, reason, adminSrc)
    return startSentence({
        targetSource = target,
        actions = actions,
        reason = reason,
        adminSrc = adminSrc or 0,
    })
end)

exports("StartComServOffline", function(identifier, actions, reason, adminSrc, playerName)
    return startSentence({
        identifier = identifier,
        playerName = playerName,
        actions = actions,
        reason = reason,
        adminSrc = adminSrc or 0,
    })
end)

exports("EndComServ", function(targetOrIdentifier, completed)
    if type(targetOrIdentifier) == "number" then
        local xTarget = ESX.GetPlayerFromId(targetOrIdentifier)
        if not xTarget then return false, ConfigComServ.Locale.invalidTarget end
        return endSentenceByIdentifier(xTarget.getIdentifier(), completed == true, false)
    end
    return endSentenceByIdentifier(tostring(targetOrIdentifier), completed == true, false)
end)

exports("ReduceComServ", function(target, amount)
    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return false end
    return reduceSentenceByIdentifier(xTarget.getIdentifier(), amount)
end)

exports("IsOnComServ", function(src)
    local identifier = sourceToIdentifier[src]
    return identifier ~= nil and sentences[identifier] ~= nil
end)

exports("GetComServData", function(src)
    local identifier = sourceToIdentifier[src]
    local entry = identifier and sentences[identifier] or nil
    if not entry then return nil end
    return sentenceClientPayload(entry)
end)

exports("GetActiveComServ", function()
    return getActiveList()
end)
