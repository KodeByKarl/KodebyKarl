--[[
    cfx-keydi-lockscript (server/main.lua)
    Commands, callbacks, permission checks, exports, appearance enforcement.
    Lua 5.4 — server-authoritative VIP appearance locks via LockDB.
]]

if not ConfigLockScript or not ConfigLockScript.Enabled then return end

local FrameworkName = "standalone"
local ESX, QBCore

-- ─────────────────────────────────────────────────────────────────────────────
-- Logging (Discord via LockScriptLogs when present)
-- ─────────────────────────────────────────────────────────────────────────────

local function logLock(kind, title, desc, fields)
    if LockScriptLogs and LockScriptLogs.Log then
        LockScriptLogs.Log(kind, title, desc, fields)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Framework helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function debugPrint(...)
    if ConfigLockScript.Debug then
        print("[cfx-keydi-lockscript]", ...)
    end
end

local function detectFramework()
    local cfg = ConfigLockScript.Framework or "auto"
    if cfg == "esx" or cfg == "qbcore" or cfg == "standalone" then
        return cfg
    end
    if GetResourceState("es_extended") == "started" then
        return "esx"
    end
    if GetResourceState("qb-core") == "started" then
        return "qbcore"
    end
    return "standalone"
end

local function initFramework()
    FrameworkName = detectFramework()
    if FrameworkName == "esx" then
        ESX = exports["es_extended"]:getSharedObject()
    elseif FrameworkName == "qbcore" then
        QBCore = exports["qb-core"]:GetCoreObject()
    end
    debugPrint("Framework:", FrameworkName)
end

local function notify(src, msg, nType)
    TriggerClientEvent("ox_lib:notify", src, {
        title = "VIP Lock",
        description = msg,
        type = nType or "inform",
        position = "top-center",
    })
end

--- Notify player that a locked piece is exclusive to someone else.
local function notifyDenied(src, denied)
    if not denied then return end
    local cat = ConfigLockScript.CategoryById[denied.category]
    local label = cat and cat.label or denied.category
    local piece = ("%s #%s"):format(label, denied.drawable or 0)
    notify(src, (ConfigLockScript.Locale.exclusive):format(piece, denied.ownerName or "another player"), "error")
end

local function getIdentifier(src)
    if FrameworkName == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then return xPlayer.getIdentifier() end
    elseif FrameworkName == "qbcore" and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData then
            return Player.PlayerData.citizenid
        end
    end

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find("license:") == 1 then
            return id
        end
    end
    return GetPlayerIdentifier(src, 0)
end

local function collectIdentifierAliases(src)
    local list, seen = {}, {}
    local function add(value)
        if type(value) ~= "string" or value == "" or seen[value] then return end
        seen[value] = true
        list[#list + 1] = value
        local norm = ConfigLockScript.NormalizeIdentifier(value)
        if norm ~= "" and not seen[norm] then
            seen[norm] = true
            list[#list + 1] = norm
        end
    end

    add(getIdentifier(src))
    if src then
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            add(GetPlayerIdentifier(src, i))
        end
    end
    return list
end

local function getPlayerName(src)
    if FrameworkName == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            local name = xPlayer.getName and xPlayer.getName()
            if name and name ~= "" then return name end
        end
    elseif FrameworkName == "qbcore" and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            local c = Player.PlayerData.charinfo
            return (("%s %s"):format(c.firstname or "", c.lastname or "")):gsub("%s+$", "")
        end
    end
    return GetPlayerName(src) or "Unknown"
end

--- Returns the player's current job name (ESX / QBCore) or nil.
local function getPlayerJob(src)
    if FrameworkName == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.job and xPlayer.job.name then
            return xPlayer.job.name
        end
    elseif FrameworkName == "qbcore" and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name then
            return Player.PlayerData.job.name
        end
    end
    return nil
end

local function getGroup(src)
    if FrameworkName == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.getGroup then
            return xPlayer.getGroup()
        end
    elseif FrameworkName == "qbcore" and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.permission then
            return Player.PlayerData.permission
        end
        if QBCore.Functions.HasPermission then
            if QBCore.Functions.HasPermission(src, "admin") then return "admin" end
            if QBCore.Functions.HasPermission(src, "god") then return "god" end
        end
    end
    return "user"
end

local function isStaff(src)
    local ace = ConfigLockScript.AcePermission
    if type(ace) == "string" and ace ~= "" and IsPlayerAceAllowed(src, ace) then
        return true
    end
    local group = getGroup(src)
    if group and ConfigLockScript.StaffGroups[group] then
        return true
    end
    return false
end

--- Online players for the VIP lock picker (includes the staff who opened the panel).
local function getOnlinePlayers()
    local list = {}
    local seen = {}

    local function push(sid, identifier, name)
        if not sid or not identifier or identifier == "" or seen[identifier] then
            return
        end
        seen[identifier] = true
        list[#list + 1] = {
            source = sid,
            identifier = identifier,
            name = (name and name ~= "" and name) or GetPlayerName(sid) or "Unknown",
            online = true,
        }
    end

    if FrameworkName == "esx" and ESX then
        local xPlayers = ESX.GetExtendedPlayers()
        for _, xPlayer in pairs(xPlayers) do
            if type(xPlayer) == "table" and xPlayer.source then
                push(
                    xPlayer.source,
                    xPlayer.getIdentifier and xPlayer.getIdentifier(),
                    (xPlayer.getName and xPlayer.getName()) or nil
                )
            end
        end
    elseif FrameworkName == "qbcore" and QBCore then
        for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
            local sid = Player.PlayerData.source
            local c = Player.PlayerData.charinfo or {}
            push(sid, Player.PlayerData.citizenid, (("%s %s"):format(c.firstname or "", c.lastname or "")):gsub("%s+$", ""))
        end
    end

    -- Fallback / fill anyone GetExtendedPlayers missed (includes the staff themselves)
    for _, sid in ipairs(GetPlayers()) do
        local id = tonumber(sid)
        if id then
            push(id, getIdentifier(id), getPlayerName(id))
        end
    end

    return list
end

local function searchOffline(query)
    query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #query < 2 then return {} end

    local limit = tonumber(ConfigLockScript.OfflineSearchLimit) or 30
    local like = "%" .. query .. "%"
    local results = {}

    if FrameworkName == "esx" or FrameworkName == "standalone" then
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
        for _, p in ipairs(getOnlinePlayers()) do
            onlineIds[p.identifier] = true
        end

        for _, row in ipairs(rows) do
            if not onlineIds[row.identifier] then
                local name = (("%s %s"):format(row.firstname or "", row.lastname or "")):gsub("%s+$", "")
                if name == "" then name = row.identifier end
                results[#results + 1] = {
                    identifier = row.identifier,
                    name = name,
                    online = false,
                }
            end
        end
    elseif FrameworkName == "qbcore" then
        local rows = MySQL.query.await([[
            SELECT citizenid, charinfo
            FROM players
            WHERE citizenid LIKE ?
               OR charinfo LIKE ?
            LIMIT ?
        ]], { like, like, limit }) or {}

        local onlineIds = {}
        for _, p in ipairs(getOnlinePlayers()) do
            onlineIds[p.identifier] = true
        end

        for _, row in ipairs(rows) do
            if not onlineIds[row.citizenid] then
                local name = row.citizenid
                if row.charinfo then
                    local ok, info = pcall(json.decode, row.charinfo)
                    if ok and type(info) == "table" then
                        name = (("%s %s"):format(info.firstname or "", info.lastname or "")):gsub("%s+$", "")
                        if name == "" then name = row.citizenid end
                    end
                end
                results[#results + 1] = {
                    identifier = row.citizenid,
                    name = name,
                    online = false,
                }
            end
        end
    end

    return results
end

local function broadcastLocksChanged()
    TriggerClientEvent("cfx-keydi-lockscript:client:locksChanged", -1)
end

local function panelPayload(src)
    return {
        brand = ConfigLockScript.Brand or "GRIM CITY",
        staffName = getPlayerName(src),
        staffId = src,
        staffIdentifier = getIdentifier(src),
        categories = ConfigLockScript.Categories,
        genders = ConfigLockScript.Genders,
        online = getOnlinePlayers(),
        locks = LockDB.GetAll(),
    }
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Core permission API (also exposed as exports)
-- ─────────────────────────────────────────────────────────────────────────────

local function IsLocked(category, componentId, drawable, texture, gender)
    local lock = LockDB.FindLock(category, componentId, drawable, texture, gender)
    return lock ~= nil, lock
end

--- jobName optional — shared job access is checked when provided.
local function CanUse(identifier, category, componentId, drawable, texture, gender, jobName)
    local lock = LockDB.FindLock(category, componentId, drawable, texture, gender)
    if not lock then return true end
    return LockDB.IdentifierCanUse(lock, identifier, jobName)
end

local function AddLock(data)
    local ok, id, err = LockDB.Add(data)
    if ok then
        broadcastLocksChanged()
        logLock("lockAdd", "Lock Added", ("Lock #%s created."):format(id), {
            { name = "Category", value = tostring(data.category or ""), inline = true },
            { name = "Drawable", value = tostring(data.drawable or ""), inline = true },
            { name = "Owner", value = tostring(data.ownerName or "Unknown"), inline = true },
        })
    end
    return ok, id, err
end

local function RemoveLock(lockId)
    lockId = tonumber(lockId)
    local existing = lockId and LockDB.GetById(lockId) or nil
    local ok = LockDB.Remove(lockId)
    if ok then
        broadcastLocksChanged()
        logLock("lockRemove", "Lock Removed", ("Lock #%s removed."):format(lockId), {
            { name = "Category", value = existing and existing.category or "?", inline = true },
            { name = "Owner", value = existing and existing.ownerName or "?", inline = true },
        })
    end
    return ok
end

local function GrantAccess(lockId, identifier)
    local ok = LockDB.GrantAccess(lockId, identifier)
    if ok then
        broadcastLocksChanged()
        logLock("access", "Access Granted", ("Lock #%s shared with %s."):format(tostring(lockId), identifier), {})
    end
    return ok
end

local function RevokeAccess(lockId, identifier)
    local ok = LockDB.RevokeAccess(lockId, identifier)
    if ok then
        broadcastLocksChanged()
        logLock("access", "Access Revoked", ("Lock #%s revoked from %s."):format(tostring(lockId), identifier), {})
    end
    return ok
end

local function GetLocksByCategory(category)
    return LockDB.GetByCategory(category)
end

local function GetAllLocks()
    return LockDB.GetAll()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Appearance validation / sanitization
-- ─────────────────────────────────────────────────────────────────────────────

local function genderFromModel(model)
    if not model then return "male" end
    local m = type(model) == "string" and model:lower() or tostring(model)
    if m:find("female") or m == "mp_f_freemode_01" then
        return "female"
    end
    return "male"
end

local function formatDeniedLock(denied)
    if not denied then return nil end
    return {
        ownerName = denied.ownerName,
        id = denied.id,
        category = denied.category,
        drawable = denied.drawable,
    }
end

--- Walk an illenium appearance table and return first denied lock (if any).
local function findDeniedInAppearance(identifier, appearance, gender, jobName)
    if type(appearance) ~= "table" then return nil end
    gender = gender or genderFromModel(appearance.model)

    if type(appearance.components) == "table" then
        for i = 1, #appearance.components do
            local c = appearance.components[i]
            if c then
                local compId = tostring(c.component_id)
                for _, cat in ipairs(ConfigLockScript.Categories) do
                    if cat.type == "component" and cat.componentId == compId then
                        if not CanUse(identifier, cat.id, compId, c.drawable, c.texture or 0, gender, jobName) then
                            local _, lock = IsLocked(cat.id, compId, c.drawable, c.texture or 0, gender)
                            return lock
                        end
                    end
                end
            end
        end
    end

    if type(appearance.props) == "table" then
        for i = 1, #appearance.props do
            local p = appearance.props[i]
            if p and (tonumber(p.drawable) or -1) >= 0 then
                local propId = tostring(p.prop_id)
                for _, cat in ipairs(ConfigLockScript.Categories) do
                    if cat.type == "prop" and cat.componentId == propId then
                        if not CanUse(identifier, cat.id, propId, p.drawable, p.texture or 0, gender, jobName) then
                            local _, lock = IsLocked(cat.id, propId, p.drawable, p.texture or 0, gender)
                            return lock
                        end
                    end
                end
            end
        end
    end

    if type(appearance.hair) == "table" then
        local style = appearance.hair.style or appearance.hair.drawable
        local tex = appearance.hair.texture or 0
        if style ~= nil and not CanUse(identifier, "hair", "hair", style, tex, gender, jobName) then
            local _, lock = IsLocked("hair", "hair", style, tex, gender)
            return lock
        end
    end

    if appearance.eyeColor ~= nil then
        if not CanUse(identifier, "eye_color", "eyeColor", appearance.eyeColor, 0, gender, jobName) then
            local _, lock = IsLocked("eye_color", "eyeColor", appearance.eyeColor, 0, gender)
            return lock
        end
    end

    if type(appearance.headOverlays) == "table" then
        for _, cat in ipairs(ConfigLockScript.Categories) do
            if cat.type == "headOverlay" then
                local overlay = appearance.headOverlays[cat.componentId]
                if overlay and overlay.style ~= nil then
                    local style = overlay.style
                    local color = overlay.color or 0
                    if not CanUse(identifier, cat.id, cat.componentId, style, color, gender, jobName) then
                        local _, lock = IsLocked(cat.id, cat.componentId, style, color, gender)
                        return lock
                    end
                end
            end
        end
    end

    if type(appearance.tattoos) == "table" then
        for _, cat in ipairs(ConfigLockScript.Categories) do
            if cat.type == "tattoo" then
                local zoneList = appearance.tattoos[cat.componentId]
                if type(zoneList) == "table" then
                    for i = 1, #zoneList do
                        local tat = zoneList[i]
                        local tatName = type(tat) == "table" and (tat.name or tat.hashMale or tat.hashFemale) or tostring(tat)
                        if tatName and tatName ~= "" then
                            if not CanUse(identifier, cat.id, tostring(tatName), 0, 0, gender, jobName) then
                                local _, lock = IsLocked(cat.id, tostring(tatName), 0, 0, gender)
                                return lock
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

--- Validate an appearance payload for a player. Returns ok, deniedLock|nil
local function ValidateAppearance(src, appearance)
    local identifiers = collectIdentifierAliases(src)
    if not identifiers[1] then return true, nil end
    local gender = genderFromModel(appearance and appearance.model)
    local jobName = getPlayerJob(src)
    local denied = findDeniedInAppearance(identifiers, appearance, gender, jobName)
    return denied == nil, denied
end

local FALLBACK_COMPONENT = {
    ["1"] = 0, ["3"] = 0, ["4"] = 0, ["5"] = 0, ["6"] = 0,
    ["7"] = 0, ["8"] = 0, ["9"] = 0, ["10"] = 0, ["11"] = 0,
}

--- Strip locked components/props/hair/eyeColor to fallbacks. Returns appearance, deniedLock|nil
local function sanitizeAppearanceData(identifier, appearance, jobName)
    if type(appearance) ~= "table" or not identifier then return appearance, nil end
    local gender = genderFromModel(appearance.model)
    local denied = nil

    if type(appearance.components) == "table" then
        for i = 1, #appearance.components do
            local c = appearance.components[i]
            if c then
                local compId = tostring(c.component_id)
                for _, cat in ipairs(ConfigLockScript.Categories) do
                    if cat.type == "component" and cat.componentId == compId then
                        if not CanUse(identifier, cat.id, compId, c.drawable, c.texture or 0, gender, jobName) then
                            local _, lock = IsLocked(cat.id, compId, c.drawable, c.texture or 0, gender)
                            c.drawable = FALLBACK_COMPONENT[compId] or 0
                            c.texture = 0
                            denied = denied or lock
                        end
                    end
                end
            end
        end
    end

    if type(appearance.props) == "table" then
        for i = 1, #appearance.props do
            local p = appearance.props[i]
            if p and (tonumber(p.drawable) or -1) >= 0 then
                local propId = tostring(p.prop_id)
                for _, cat in ipairs(ConfigLockScript.Categories) do
                    if cat.type == "prop" and cat.componentId == propId then
                        if not CanUse(identifier, cat.id, propId, p.drawable, p.texture or 0, gender, jobName) then
                            local _, lock = IsLocked(cat.id, propId, p.drawable, p.texture or 0, gender)
                            p.drawable = -1
                            p.texture = -1
                            denied = denied or lock
                        end
                    end
                end
            end
        end
    end

    if type(appearance.hair) == "table" then
        local style = appearance.hair.style or appearance.hair.drawable
        local tex = appearance.hair.texture or 0
        if style ~= nil and not CanUse(identifier, "hair", "hair", style, tex, gender, jobName) then
            local _, lock = IsLocked("hair", "hair", style, tex, gender)
            appearance.hair.style = 0
            appearance.hair.texture = 0
            denied = denied or lock
        end
    end

    if appearance.eyeColor ~= nil then
        if not CanUse(identifier, "eye_color", "eyeColor", appearance.eyeColor, 0, gender, jobName) then
            local _, lock = IsLocked("eye_color", "eyeColor", appearance.eyeColor, 0, gender)
            appearance.eyeColor = 0
            denied = denied or lock
        end
    end

    return appearance, denied
end

--- Sanitize outfit components/props only (saveOutfit / updateOutfit). Mutates tables in-place.
local function sanitizeOutfitPieces(identifier, model, components, props, jobName)
    if not identifier then return nil end
    local appearance = { model = model, components = components, props = props }
    local _, denied = sanitizeAppearanceData(identifier, appearance, jobName)
    return denied
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Exports (resource name is cfx-keydi-ui when embedded)
-- ─────────────────────────────────────────────────────────────────────────────

exports("IsLocked", IsLocked)
exports("CanUse", CanUse)
exports("AddLock", AddLock)
exports("RemoveLock", RemoveLock)
exports("GrantAccess", GrantAccess)
exports("RevokeAccess", RevokeAccess)
exports("GetLocksByCategory", GetLocksByCategory)
exports("GetAllLocks", GetAllLocks)
exports("ValidateAppearance", ValidateAppearance)

-- Last appearance that passed CanUse checks (per identifier). Used to revert bad saves.
local lastValidAppearance = {}

local function persistAppearance(identifier, appearance)
    if not identifier or type(appearance) ~= "table" then return end
    local encoded = json.encode(appearance)
    if FrameworkName == "qbcore" then
        local model = appearance.model or "mp_m_freemode_01"
        MySQL.update.await("UPDATE playerskins SET active = 0 WHERE citizenid = ?", { identifier })
        MySQL.query.await("DELETE FROM playerskins WHERE citizenid = ? AND model = ?", { identifier, model })
        MySQL.insert.await(
            "INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, 1)",
            { identifier, model, encoded }
        )
    else
        MySQL.update.await("UPDATE users SET skin = ? WHERE identifier = ?", { encoded, identifier })
    end
end

local function loadStoredAppearance(identifier)
    if not identifier then return nil end
    if FrameworkName == "qbcore" then
        local row = MySQL.single.await(
            "SELECT skin FROM playerskins WHERE citizenid = ? AND active = 1 LIMIT 1",
            { identifier }
        )
        if row and row.skin then
            local ok, decoded = pcall(json.decode, row.skin)
            if ok then return decoded end
        end
    else
        local row = MySQL.single.await("SELECT skin FROM users WHERE identifier = ? LIMIT 1", { identifier })
        if row and row.skin then
            local ok, decoded = pcall(json.decode, type(row.skin) == "string" and row.skin or json.encode(row.skin))
            if ok then return decoded end
        end
    end
    return nil
end

local function logBlockedSave(src, identifier, denied, context)
    if not denied then return end
    logLock("blocked", "Blocked Appearance Save", context or "Player tried to save locked appearance.", {
        { name = "Player", value = getPlayerName(src), inline = true },
        { name = "Identifier", value = identifier or "?", inline = true },
        { name = "Piece", value = denied.category or "?", inline = true },
        { name = "Owner", value = denied.ownerName or "?", inline = true },
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Enforcement: reject exclusive looks on illenium save (server-authoritative)
-- Strip locked pieces immediately — no delay for the player to keep wearing them.
-- Note: handler order vs illenium is not guaranteed; client Sanitize on wear helps.
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNetEvent("illenium-appearance:server:saveAppearance", function(appearance)
    local src = source
    if type(appearance) ~= "table" then return end

    local identifier = getIdentifier(src)
    local aliases = collectIdentifierAliases(src)
    local jobName = getPlayerJob(src)
    local cleaned, denied = sanitizeAppearanceData(aliases, appearance, jobName)

    if not denied then
        lastValidAppearance[identifier] = cleaned
        return
    end

    notifyDenied(src, denied)
    logBlockedSave(src, identifier, denied, "Blocked full appearance save.")

    TriggerClientEvent("cfx-keydi-lockscript:client:deniedLook", src, {
        ownerName = denied.ownerName,
        lock = formatDeniedLock(denied),
    })
    TriggerClientEvent("cfx-keydi-lockscript:client:applyAppearance", src, cleaned)

    persistAppearance(identifier, cleaned)
    lastValidAppearance[identifier] = cleaned
end)

RegisterNetEvent("illenium-appearance:server:saveOutfit", function(name, model, components, props)
    local src = source
    if type(components) ~= "table" or type(props) ~= "table" then return end

    local aliases = collectIdentifierAliases(src)
    local jobName = getPlayerJob(src)
    local denied = sanitizeOutfitPieces(aliases, model, components, props, jobName)

    if denied then
        notifyDenied(src, denied)
        logBlockedSave(src, aliases[1], denied, ("Blocked outfit save: %s."):format(tostring(name or "")))
        TriggerClientEvent("cfx-keydi-lockscript:client:deniedLook", src, {
            ownerName = denied.ownerName,
            lock = formatDeniedLock(denied),
        })
        -- components/props mutated in-place; illenium may still persist if its handler runs after.
        -- Client SanitizeAppearance on wear covers remaining edge cases.
    end
end)

RegisterNetEvent("illenium-appearance:server:updateOutfit", function(id, model, components, props)
    local src = source
    if type(components) ~= "table" or type(props) ~= "table" then return end

    local aliases = collectIdentifierAliases(src)
    local jobName = getPlayerJob(src)
    local denied = sanitizeOutfitPieces(aliases, model, components, props, jobName)

    if denied then
        notifyDenied(src, denied)
        logBlockedSave(src, aliases[1], denied, ("Blocked outfit update #%s."):format(tostring(id or "")))
        TriggerClientEvent("cfx-keydi-lockscript:client:deniedLook", src, {
            ownerName = denied.ownerName,
            lock = formatDeniedLock(denied),
        })
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    local identifier = nil
    pcall(function()
        identifier = getIdentifier(src)
    end)
    if identifier then
        lastValidAppearance[identifier] = nil
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- ox_lib callbacks
-- ─────────────────────────────────────────────────────────────────────────────

lib.callback.register("cfx-keydi-lockscript:canUse", function(source, category, componentId, drawable, texture, gender)
    local identifiers = collectIdentifierAliases(source)
    local jobName = getPlayerJob(source)
    return CanUse(identifiers, category, componentId, drawable, texture, gender, jobName)
end)

lib.callback.register("cfx-keydi-lockscript:validateAppearance", function(source, appearance)
    local ok, denied = ValidateAppearance(source, appearance)
    if ok then
        return true, nil
    end
    return false, formatDeniedLock(denied)
end)

lib.callback.register("cfx-keydi-lockscript:getLocks", function(_source)
    return LockDB.GetAll()
end)

lib.callback.register("cfx-keydi-lockscript:getMyIdentifier", function(source)
    return collectIdentifierAliases(source)
end)

lib.callback.register("cfx-keydi-lockscript:getMyJob", function(source)
    return getPlayerJob(source)
end)

local function checkDuplicateLock(data)
    if type(data) ~= "table" then return nil end

    local category = tostring(data.category or "")
    local catDef = ConfigLockScript.CategoryById[category]
    if not catDef then return nil end

    local componentId = tostring(data.componentId or catDef.componentId)
    local drawable = tonumber(data.drawable)
    if drawable == nil then return nil end

    local texture = tonumber(data.texture) or 0
    local gender = tostring(data.gender or "male")
    local anyTexture = data.anyTexture == true or data.any_texture == true

    return LockDB.FindDuplicate(category, componentId, drawable, texture, gender, anyTexture)
end

local function importLockRows(source, locks)
    if type(locks) ~= "table" then return 0 end

    local imported = 0
    for i = 1, #locks do
        local row = locks[i]
        if type(row) == "table" then
            local ok = select(1, AddLock({
                category = row.category,
                componentId = row.componentId or row.component_id,
                drawable = row.drawable,
                texture = row.texture,
                anyTexture = row.anyTexture or row.any_texture,
                gender = row.gender,
                ownerIdentifier = row.ownerIdentifier or row.owner_identifier,
                ownerName = row.ownerName or row.owner_name,
                sharedIdentifiers = row.sharedIdentifiers or row.shared_identifiers,
                sharedJobs = row.sharedJobs or row.shared_jobs,
                expiresAt = row.expiresAt or row.expires_at,
            }))
            if ok then
                imported = imported + 1
            end
        end
    end

    if imported > 0 then
        logLock("import", "Locks Imported", ("Staff imported %d lock(s)."):format(imported), {
            { name = "Staff", value = getPlayerName(source), inline = true },
            { name = "Count", value = tostring(imported), inline = true },
        })
        TriggerClientEvent("cfx-keydi-lockscript:client:panelRefresh", source)
    end

    return imported
end

lib.callback.register("cfx-keydi-lockscript:checkDuplicate", function(source, data)
    if not isStaff(source) then return nil end
    return checkDuplicateLock(data)
end)

lib.callback.register("cfx-keydi-lockscript:importLocks", function(source, locks)
    if not isStaff(source) then return 0 end
    return importLockRows(source, locks)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Admin panel callbacks / events
-- ─────────────────────────────────────────────────────────────────────────────

local function registerOpenCallback()
    if FrameworkName == "esx" and ESX then
        ESX.RegisterServerCallback("cfx-keydi-lockscript:open", function(source, cb)
            if not isStaff(source) then
                cb(nil)
                return
            end
            cb(panelPayload(source))
        end)

        ESX.RegisterServerCallback("cfx-keydi-lockscript:refresh", function(source, cb)
            if not isStaff(source) then
                cb(nil)
                return
            end
            cb({
                online = getOnlinePlayers(),
                locks = LockDB.GetAll(),
                staffIdentifier = getIdentifier(source),
                staffName = getPlayerName(source),
                staffId = source,
            })
        end)

        ESX.RegisterServerCallback("cfx-keydi-lockscript:searchOffline", function(source, cb, query)
            if not isStaff(source) then
                cb({})
                return
            end
            cb(searchOffline(query))
        end)

        ESX.RegisterServerCallback("cfx-keydi-lockscript:checkDuplicate", function(source, cb, data)
            if not isStaff(source) then
                cb(nil)
                return
            end
            cb(checkDuplicateLock(data))
        end)

        ESX.RegisterServerCallback("cfx-keydi-lockscript:importLocks", function(source, cb, locks)
            if not isStaff(source) then
                cb(0)
                return
            end
            cb(importLockRows(source, locks))
        end)
    else
        lib.callback.register("cfx-keydi-lockscript:open", function(source)
            if not isStaff(source) then return nil end
            return panelPayload(source)
        end)

        lib.callback.register("cfx-keydi-lockscript:refresh", function(source)
            if not isStaff(source) then return nil end
            return {
                online = getOnlinePlayers(),
                locks = LockDB.GetAll(),
                staffIdentifier = getIdentifier(source),
                staffName = getPlayerName(source),
                staffId = source,
            }
        end)

        lib.callback.register("cfx-keydi-lockscript:searchOffline", function(source, query)
            if not isStaff(source) then return {} end
            return searchOffline(query)
        end)

        -- checkDuplicate + importLocks already registered above for all frameworks
    end
end

RegisterNetEvent("cfx-keydi-lockscript:server:addLock", function(data)
    local src = source
    if not isStaff(src) then
        notify(src, ConfigLockScript.Locale.noPermission, "error")
        return
    end
    if type(data) ~= "table" then
        notify(src, ConfigLockScript.Locale.invalidInput, "error")
        return
    end

    local category = tostring(data.category or "")
    if not ConfigLockScript.CategoryById[category] then
        notify(src, ConfigLockScript.Locale.invalidInput, "error")
        return
    end

    local ownerIdentifier = tostring(data.ownerIdentifier or "")
    local ownerName = tostring(data.ownerName or "Unknown")
    if ownerIdentifier == "" then
        notify(src, ConfigLockScript.Locale.invalidInput, "error")
        return
    end

    local catDef = ConfigLockScript.CategoryById[category]
    local componentId = tostring(data.componentId or catDef.componentId)
    local drawable = tonumber(data.drawable)
    if drawable == nil then
        notify(src, ConfigLockScript.Locale.invalidInput, "error")
        return
    end

    local shared = data.sharedIdentifiers
    if type(shared) ~= "table" then shared = {} end

    local sharedJobs = data.sharedJobs
    if type(sharedJobs) ~= "table" then sharedJobs = {} end

    local anyTexture = data.anyTexture == true or data.any_texture == true
    local expiresAt = data.expiresAt or data.expires_at
    if expiresAt == "" then expiresAt = nil end

    local ok, id, err = AddLock({
        category = category,
        componentId = componentId,
        drawable = drawable,
        texture = tonumber(data.texture) or 0,
        anyTexture = anyTexture,
        gender = tostring(data.gender or "male"),
        ownerIdentifier = ownerIdentifier,
        ownerName = ownerName,
        sharedIdentifiers = shared,
        sharedJobs = sharedJobs,
        expiresAt = expiresAt,
    })

    if ok then
        notify(src, ConfigLockScript.Locale.lockAdded, "success")
        TriggerClientEvent("cfx-keydi-lockscript:client:panelRefresh", src)
    elseif err == "duplicate" then
        notify(src, ConfigLockScript.Locale.alreadyLocked, "error")
    elseif err == "invalid" then
        notify(src, ConfigLockScript.Locale.invalidInput, "error")
    else
        notify(src, ConfigLockScript.Locale.lockFailed, "error")
    end
end)

RegisterNetEvent("cfx-keydi-lockscript:server:removeLock", function(lockId)
    local src = source
    if not isStaff(src) then
        notify(src, ConfigLockScript.Locale.noPermission, "error")
        return
    end
    if RemoveLock(lockId) then
        notify(src, ConfigLockScript.Locale.lockRemoved, "success")
        TriggerClientEvent("cfx-keydi-lockscript:client:panelRefresh", src)
    else
        notify(src, ConfigLockScript.Locale.notFound, "error")
    end
end)

RegisterNetEvent("cfx-keydi-lockscript:server:grantAccess", function(lockId, identifier)
    local src = source
    if not isStaff(src) then
        notify(src, ConfigLockScript.Locale.noPermission, "error")
        return
    end
    if GrantAccess(lockId, identifier) then
        notify(src, ConfigLockScript.Locale.accessGranted, "success")
        TriggerClientEvent("cfx-keydi-lockscript:client:panelRefresh", src)
    else
        notify(src, ConfigLockScript.Locale.notFound, "error")
    end
end)

RegisterNetEvent("cfx-keydi-lockscript:server:revokeAccess", function(lockId, identifier)
    local src = source
    if not isStaff(src) then
        notify(src, ConfigLockScript.Locale.noPermission, "error")
        return
    end
    if RevokeAccess(lockId, identifier) then
        notify(src, ConfigLockScript.Locale.accessRevoked, "success")
        TriggerClientEvent("cfx-keydi-lockscript:client:panelRefresh", src)
    else
        notify(src, ConfigLockScript.Locale.notFound, "error")
    end
end)

RegisterNetEvent("cfx-keydi-lockscript:server:setShared", function(lockId, sharedIdentifiers, sharedJobs)
    local src = source
    if not isStaff(src) then
        notify(src, ConfigLockScript.Locale.noPermission, "error")
        return
    end
    lockId = tonumber(lockId)
    if not lockId or type(sharedIdentifiers) ~= "table" then
        notify(src, ConfigLockScript.Locale.invalidInput, "error")
        return
    end
    if type(sharedJobs) ~= "table" then sharedJobs = {} end

    local lock = LockDB.GetById(lockId)
    if not lock then
        notify(src, ConfigLockScript.Locale.notFound, "error")
        return
    end

    local cleanIds = {}
    for i = 1, #sharedIdentifiers do
        local id = sharedIdentifiers[i]
        if type(id) == "string" and id ~= "" and id ~= lock.ownerIdentifier then
            cleanIds[#cleanIds + 1] = id
        end
    end

    local cleanJobs = {}
    for i = 1, #sharedJobs do
        local job = sharedJobs[i]
        if type(job) == "string" and job ~= "" then
            cleanJobs[#cleanJobs + 1] = job
        end
    end

    if LockDB.SetShared(lockId, cleanIds, cleanJobs) then
        broadcastLocksChanged()
        logLock("access", "Shared Access Updated", ("Lock #%s shared list updated."):format(lockId), {
            { name = "Identifiers", value = tostring(#cleanIds), inline = true },
            { name = "Jobs", value = tostring(#cleanJobs), inline = true },
        })
        notify(src, ConfigLockScript.Locale.accessGranted, "success")
        TriggerClientEvent("cfx-keydi-lockscript:client:panelRefresh", src)
    else
        notify(src, ConfigLockScript.Locale.notFound, "error")
    end
end)

RegisterCommand(ConfigLockScript.Commands.open, function(source)
    local src = source
    if src == 0 then
        print("[cfx-keydi-lockscript] Use /viplock in-game.")
        return
    end
    if not isStaff(src) then
        notify(src, ConfigLockScript.Locale.noPermission, "error")
        return
    end
    TriggerClientEvent("cfx-keydi-lockscript:client:openPanel", src)
end, false)

-- Grant with: add_ace group.admin command.viplock allow

-- ─────────────────────────────────────────────────────────────────────────────
-- Player join: push lock cache + enforce ped
-- ─────────────────────────────────────────────────────────────────────────────

local function onPlayerReady(src)
    if not src or src <= 0 then return end
    TriggerClientEvent("cfx-keydi-lockscript:client:locksChanged", src)
    TriggerClientEvent("cfx-keydi-lockscript:client:playerReady", src)
end

local function registerPlayerJoinHandlers()
    if FrameworkName == "esx" then
        AddEventHandler("esx:playerLoaded", function(playerId)
            onPlayerReady(playerId)
        end)
    elseif FrameworkName == "qbcore" then
        AddEventHandler("QBCore:Server:PlayerLoaded", function(Player)
            if Player and Player.PlayerData then
                onPlayerReady(Player.PlayerData.source)
            end
        end)
    else
        AddEventHandler("playerJoining", function()
            local src = source
            CreateThread(function()
                Wait(5000)
                if GetPlayerPing(src) > 0 then
                    onPlayerReady(src)
                end
            end)
        end)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Startup + expired lock cleanup (every 10 minutes)
-- ─────────────────────────────────────────────────────────────────────────────

CreateThread(function()
    initFramework()
    LockDB.EnsureTable()
    registerOpenCallback()
    registerPlayerJoinHandlers()

    CreateThread(function()
        while true do
            Wait(600000) -- 10 minutes
            local removed = LockDB.DeleteExpired()
            if removed > 0 then
                broadcastLocksChanged()
                print(("[cfx-keydi-lockscript] %s"):format(
                    (ConfigLockScript.Locale.expiredCleaned):format(removed)
                ))
            end
        end
    end)
end)
