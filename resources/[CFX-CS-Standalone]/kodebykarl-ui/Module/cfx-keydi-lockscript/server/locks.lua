--[[
    cfx-keydi-lockscript (server/locks.lua)
    CRUD + auto-migrate for `keydi_locks` via oxmysql.
]]

LockDB = {}

local TABLE = "keydi_locks"

local function debugPrint(...)
    if ConfigLockScript and ConfigLockScript.Debug then
        print("[cfx-keydi-lockscript:db]", ...)
    end
end

local function decodeJsonList(raw)
    if type(raw) == "table" then return raw end
    if type(raw) ~= "string" or raw == "" then return {} end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then return decoded end
    return {}
end

local function encodeJsonList(list)
    if type(list) ~= "table" then return "[]" end
    local clean = {}
    for i = 1, #list do
        local id = list[i]
        if type(id) == "string" and id ~= "" then
            clean[#clean + 1] = id
        end
    end
    return json.encode(clean)
end

local function isExpired(expiresAt)
    if not expiresAt or expiresAt == "" or expiresAt == "null" then return false end
    -- MySQL DATETIME / unix
    if type(expiresAt) == "number" then
        return expiresAt > 0 and os.time() >= expiresAt
    end
    local y, m, d, H, M, S = tostring(expiresAt):match("^(%d+)%-(%d+)%-(%d+)[%sT]+(%d+):(%d+):(%d+)")
    if not y then
        y, m, d = tostring(expiresAt):match("^(%d+)%-(%d+)%-(%d+)")
        H, M, S = 23, 59, 59
    end
    if not y then return false end
    local ts = os.time({
        year = tonumber(y), month = tonumber(m), day = tonumber(d),
        hour = tonumber(H) or 0, min = tonumber(M) or 0, sec = tonumber(S) or 0,
    })
    return ts and os.time() >= ts
end

function LockDB.Normalize(row)
    if not row then return nil end
    local shared = decodeJsonList(row.shared_identifiers)
    local jobs = decodeJsonList(row.shared_jobs)
    local anyTexture = row.any_texture == true or row.any_texture == 1 or row.any_texture == "1"
    return {
        id = tonumber(row.id),
        category = row.category,
        componentId = tostring(row.component_id),
        drawable = tonumber(row.drawable) or 0,
        texture = tonumber(row.texture) or 0,
        anyTexture = anyTexture,
        gender = row.gender or "male",
        ownerIdentifier = row.owner_identifier,
        ownerName = row.owner_name or "Unknown",
        sharedIdentifiers = shared,
        sharedJobs = jobs,
        sharedCount = #shared,
        expiresAt = row.expires_at,
        expired = isExpired(row.expires_at),
        createdAt = row.created_at,
    }
end

function LockDB.EnsureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `keydi_locks` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `category` VARCHAR(50) NOT NULL,
            `component_id` VARCHAR(64) NOT NULL,
            `drawable` INT NOT NULL DEFAULT 0,
            `texture` INT NOT NULL DEFAULT 0,
            `any_texture` TINYINT(1) NOT NULL DEFAULT 0,
            `gender` VARCHAR(10) NOT NULL DEFAULT 'male',
            `owner_identifier` VARCHAR(64) NOT NULL,
            `owner_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `shared_identifiers` TEXT NULL,
            `shared_jobs` TEXT NULL,
            `expires_at` DATETIME NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_keydi_locks_lookup` (`category`, `component_id`, `drawable`, `gender`),
            KEY `idx_keydi_locks_owner` (`owner_identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Migrate older installs
    local cols = {
        { name = "any_texture", sql = "ADD COLUMN `any_texture` TINYINT(1) NOT NULL DEFAULT 0" },
        { name = "shared_jobs", sql = "ADD COLUMN `shared_jobs` TEXT NULL" },
        { name = "expires_at", sql = "ADD COLUMN `expires_at` DATETIME NULL DEFAULT NULL" },
    }
    for i = 1, #cols do
        local col = cols[i]
        local exists = MySQL.single.await(
            "SELECT COUNT(*) AS c FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?",
            { TABLE, col.name }
        )
        if not exists or tonumber(exists.c) == 0 then
            pcall(function()
                MySQL.query.await(("ALTER TABLE `%s` %s"):format(TABLE, col.sql))
            end)
        end
    end

    debugPrint("Table ready:", TABLE)
end

function LockDB.GetAll(includeExpired)
    local rows = MySQL.query.await(("SELECT * FROM `%s` ORDER BY `id` DESC"):format(TABLE)) or {}
    local out = {}
    for i = 1, #rows do
        local n = LockDB.Normalize(rows[i])
        if n and (includeExpired or not n.expired) then
            out[#out + 1] = n
        end
    end
    return out
end

function LockDB.GetByCategory(category)
    if type(category) ~= "string" or category == "" then return {} end
    local rows = MySQL.query.await(
        ("SELECT * FROM `%s` WHERE `category` = ? ORDER BY `id` DESC"):format(TABLE),
        { category }
    ) or {}
    local out = {}
    for i = 1, #rows do
        local n = LockDB.Normalize(rows[i])
        if n and not n.expired then
            out[#out + 1] = n
        end
    end
    return out
end

function LockDB.GetById(lockId)
    lockId = tonumber(lockId)
    if not lockId then return nil end
    local row = MySQL.single.await(
        ("SELECT * FROM `%s` WHERE `id` = ? LIMIT 1"):format(TABLE),
        { lockId }
    )
    return LockDB.Normalize(row)
end

--- Find lock matching category/component/drawable/(texture unless any_texture)
function LockDB.FindLock(category, componentId, drawable, texture, gender)
    category = tostring(category or "")
    componentId = tostring(componentId or "")
    drawable = tonumber(drawable) or 0
    texture = tonumber(texture) or 0
    gender = tostring(gender or "male")

    local rows = MySQL.query.await(([[
        SELECT * FROM `%s`
        WHERE `category` = ?
          AND `component_id` = ?
          AND `drawable` = ?
          AND (`gender` = ? OR `gender` = 'any')
          AND (`expires_at` IS NULL OR `expires_at` > NOW())
          AND (
                `any_texture` = 1
             OR `texture` = ?
          )
        ORDER BY `any_texture` ASC, `id` DESC
        LIMIT 1
    ]]):format(TABLE), { category, componentId, drawable, gender, texture }) or {}

    if rows[1] then
        return LockDB.Normalize(rows[1])
    end
    return nil
end

function LockDB.FindDuplicate(category, componentId, drawable, texture, gender, anyTexture)
    category = tostring(category or "")
    componentId = tostring(componentId or "")
    drawable = tonumber(drawable) or 0
    texture = tonumber(texture) or 0
    gender = tostring(gender or "male")
    anyTexture = anyTexture and 1 or 0

    local row = MySQL.single.await(([[
        SELECT * FROM `%s`
        WHERE `category` = ?
          AND `component_id` = ?
          AND `drawable` = ?
          AND `gender` = ?
          AND `any_texture` = ?
          AND (`any_texture` = 1 OR `texture` = ?)
          AND (`expires_at` IS NULL OR `expires_at` > NOW())
        LIMIT 1
    ]]):format(TABLE), { category, componentId, drawable, gender, anyTexture, texture })

    return LockDB.Normalize(row)
end

function LockDB.Add(data)
    if type(data) ~= "table" then return false, nil, "invalid" end

    local category = tostring(data.category or "")
    local componentId = tostring(data.componentId or data.component_id or "")
    local drawable = tonumber(data.drawable)
    local texture = tonumber(data.texture) or 0
    local anyTexture = data.anyTexture == true or data.any_texture == true or data.anyTexture == 1
    local gender = tostring(data.gender or "male")
    local ownerIdentifier = tostring(data.ownerIdentifier or data.owner_identifier or "")
    local ownerName = tostring(data.ownerName or data.owner_name or "Unknown")
    local shared = data.sharedIdentifiers or data.shared_identifiers or {}
    local jobs = data.sharedJobs or data.shared_jobs or {}
    local expiresAt = data.expiresAt or data.expires_at or nil

    if category == "" or componentId == "" or drawable == nil or ownerIdentifier == "" then
        return false, nil, "invalid"
    end
    if not ConfigLockScript.CategoryById[category] then
        return false, nil, "invalid"
    end
    if gender ~= "male" and gender ~= "female" and gender ~= "any" then
        gender = "male"
    end

    local existing = LockDB.FindDuplicate(category, componentId, drawable, texture, gender, anyTexture)
    if existing then
        return false, existing.id, "duplicate"
    end

    if expiresAt == "" then expiresAt = nil end

    local insertId = MySQL.insert.await(([[
        INSERT INTO `%s`
            (`category`, `component_id`, `drawable`, `texture`, `any_texture`, `gender`,
             `owner_identifier`, `owner_name`, `shared_identifiers`, `shared_jobs`, `expires_at`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]):format(TABLE), {
        category,
        componentId,
        drawable,
        anyTexture and 0 or texture,
        anyTexture and 1 or 0,
        gender,
        ownerIdentifier,
        ownerName:sub(1, 100),
        encodeJsonList(shared),
        encodeJsonList(jobs),
        expiresAt,
    })

    if not insertId then return false, nil, "failed" end
    return true, insertId, nil
end

function LockDB.Remove(lockId)
    lockId = tonumber(lockId)
    if not lockId then return false end
    local affected = MySQL.update.await(
        ("DELETE FROM `%s` WHERE `id` = ?"):format(TABLE),
        { lockId }
    )
    return (affected or 0) > 0
end

function LockDB.DeleteExpired()
    local affected = MySQL.update.await(
        ("DELETE FROM `%s` WHERE `expires_at` IS NOT NULL AND `expires_at` <= NOW()"):format(TABLE)
    )
    return affected or 0
end

function LockDB.GrantAccess(lockId, identifier)
    lockId = tonumber(lockId)
    identifier = tostring(identifier or "")
    if not lockId or identifier == "" then return false end

    local lock = LockDB.GetById(lockId)
    if not lock then return false end
    if lock.ownerIdentifier == identifier then return true end

    for i = 1, #lock.sharedIdentifiers do
        if lock.sharedIdentifiers[i] == identifier then
            return true
        end
    end

    lock.sharedIdentifiers[#lock.sharedIdentifiers + 1] = identifier
    MySQL.update.await(
        ("UPDATE `%s` SET `shared_identifiers` = ? WHERE `id` = ?"):format(TABLE),
        { encodeJsonList(lock.sharedIdentifiers), lockId }
    )
    return true
end

function LockDB.RevokeAccess(lockId, identifier)
    lockId = tonumber(lockId)
    identifier = tostring(identifier or "")
    if not lockId or identifier == "" then return false end

    local lock = LockDB.GetById(lockId)
    if not lock then return false end

    local nextShared = {}
    for i = 1, #lock.sharedIdentifiers do
        if lock.sharedIdentifiers[i] ~= identifier then
            nextShared[#nextShared + 1] = lock.sharedIdentifiers[i]
        end
    end

    MySQL.update.await(
        ("UPDATE `%s` SET `shared_identifiers` = ? WHERE `id` = ?"):format(TABLE),
        { encodeJsonList(nextShared), lockId }
    )
    return true
end

function LockDB.SetShared(lockId, sharedIdentifiers, sharedJobs)
    lockId = tonumber(lockId)
    if not lockId then return false end
    local lock = LockDB.GetById(lockId)
    if not lock then return false end

    MySQL.update.await(
        ("UPDATE `%s` SET `shared_identifiers` = ?, `shared_jobs` = ? WHERE `id` = ?"):format(TABLE),
        { encodeJsonList(sharedIdentifiers or {}), encodeJsonList(sharedJobs or {}), lockId }
    )
    return true
end

local function identifierAllowed(lock, identifier)
    if type(identifier) == "table" then
        for i = 1, #identifier do
            if identifierAllowed(lock, identifier[i]) then
                return true
            end
        end
        return false
    end
    identifier = tostring(identifier or "")
    if identifier == "" then return false end
    local match = ConfigLockScript.IdentifiersMatch
    if match(lock.ownerIdentifier, identifier) then return true end
    for i = 1, #lock.sharedIdentifiers do
        if match(lock.sharedIdentifiers[i], identifier) then
            return true
        end
    end
    return false
end

--- True if identifier (or their job) may use this lock row
function LockDB.IdentifierCanUse(lock, identifier, jobName)
    if not lock then return true end
    if lock.expired then return true end -- treat expired as unlocked
    if identifierAllowed(lock, identifier) then return true end
    if jobName and jobName ~= "" and type(lock.sharedJobs) == "table" then
        local j = tostring(jobName):lower()
        for i = 1, #lock.sharedJobs do
            if tostring(lock.sharedJobs[i]):lower() == j then
                return true
            end
        end
    end
    return false
end
