--[[
  VIP membership — ped menu /reskin + welcome banner + grind bonus.
  Identifier key = normalized license:xxx.
]]

local function DebugLog(msg)
    if ConfigVip and ConfigVip.Debug then
        print(("[cfx-keydi-vip] %s"):format(msg))
    end
end

local function NormalizeLicense(id)
    if type(id) ~= "string" or id == "" then return nil end

    id = id:lower():gsub("%s+", "")

    local prev
    repeat
        prev = id
        id = id:gsub("^char%d+:", "")
        id = id:gsub("^license2:", "")
        id = id:gsub("^license:", "")
        id = id:gsub("^discord:", "")
        id = id:gsub("^steam:", "")
        id = id:gsub("^fivem:", "")
        id = id:gsub("^live:", "")
        id = id:gsub("^xbl:", "")
        id = id:gsub("^ip:", "")
    until id == prev

    if id == "" then return nil end
    return "license:" .. id
end

local function LicenseFromSource(src)
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        local normalized = NormalizeLicense(v)
        if normalized then
            return normalized
        end
    end
    return nil
end

local function EnsureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_vip` (
            `identifier` VARCHAR(72) NOT NULL,
            `name` VARCHAR(64) DEFAULT NULL,
            `tier` VARCHAR(16) NOT NULL DEFAULT 'vip1',
            `label` VARCHAR(64) DEFAULT NULL,
            `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `expires_at` TIMESTAMP NOT NULL,
            `auto_renew` TINYINT(1) NOT NULL DEFAULT 0,
            `granted_by` VARCHAR(64) DEFAULT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    pcall(function()
        MySQL.query.await("ALTER TABLE `grim_vip` ADD COLUMN IF NOT EXISTS `name` VARCHAR(64) DEFAULT NULL AFTER `identifier`")
    end)
end

CreateThread(function()
    Wait(500)
    pcall(EnsureTable)
end)

local function PlayerGroup(xPlayer)
    if not xPlayer then return "user" end
    local group = xPlayer.getGroup and xPlayer.getGroup() or "user"
    return tostring(group or "user"):lower():gsub("%s+", "")
end

local function IsStaff(xPlayer)
    if not xPlayer then return false end
    local allowed = ConfigVip.StaffGroups or {}
    return allowed[PlayerGroup(xPlayer)] == true
end

local function HasPedMenuGroup(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local allowed = ConfigVip.PedMenuGroups or {}
    return allowed[PlayerGroup(xPlayer)] == true
end

local function TierMeta(tier)
    local tiers = ConfigVip.Tiers or {}
    return tiers[tier] or {
        label = tier or "VIP",
        perks = {},
        characterSlots = 1,
        pedMenu = false,
        welcomeBanner = false,
    }
end

local function RemainingFromExpires(expiresAt)
    if not expiresAt then
        return 0, 0, false
    end

    local expiresUnix
    if type(expiresAt) == "number" then
        expiresUnix = expiresAt
    else
        local y, m, d, H, M, S = tostring(expiresAt):match("^(%d+)%-(%d+)%-(%d+)[%sT](%d+):(%d+):(%d+)")
        if y then
            expiresUnix = os.time({
                year = tonumber(y),
                month = tonumber(m),
                day = tonumber(d),
                hour = tonumber(H),
                min = tonumber(M),
                sec = tonumber(S),
            })
        else
            return 0, 0, false
        end
    end

    local diff = expiresUnix - os.time()
    if diff <= 0 then
        return 0, 0, false
    end

    return math.floor(diff / 86400), math.floor((diff % 86400) / 3600), true
end

local function IsoFromDb(expiresAt)
    if not expiresAt then return nil end
    if type(expiresAt) == "number" then
        return os.date("!%Y-%m-%dT%H:%M:%SZ", expiresAt)
    end
    local s = tostring(expiresAt):gsub(" ", "T")
    if not s:find("Z") and not s:find("%+") then
        s = s .. "Z"
    end
    return s
end

local function GetActiveVipRow(identifier)
    identifier = NormalizeLicense(identifier)
    if not identifier then return nil end
    EnsureTable()

    local row = MySQL.single.await(
        "SELECT tier, label, expires_at, auto_renew, started_at FROM grim_vip WHERE identifier = ?",
        { identifier }
    )
    if not row then return nil end

    local days, hours, stillActive = RemainingFromExpires(row.expires_at)
    if not stillActive then
        MySQL.update.await("DELETE FROM grim_vip WHERE identifier = ?", { identifier })
        return nil
    end

    row._days = days
    row._hours = hours
    return row
end

local function BuildStatus(identifier)
    identifier = NormalizeLicense(identifier)
    local empty = {
        active = false,
        tier = "none",
        label = "No VIP",
        daysRemaining = 0,
        hoursRemaining = 0,
        renewsAt = nil,
        expiresAt = nil,
        autoRenew = false,
        perks = {},
        characterSlots = 1,
        pedMenu = false,
        welcomeBanner = false,
    }

    if not identifier then return empty end

    local row = GetActiveVipRow(identifier)
    if not row then return empty end

    local tier = row.tier or "vip1"
    local meta = TierMeta(tier)
    local expiresIso = IsoFromDb(row.expires_at)
    local slots = tonumber(meta.characterSlots) or 1

    return {
        active = true,
        tier = tier,
        label = row.label or meta.label or tier,
        daysRemaining = row._days or 0,
        hoursRemaining = row._hours or 0,
        renewsAt = expiresIso,
        expiresAt = expiresIso,
        autoRenew = tonumber(row.auto_renew) == 1,
        perks = meta.perks or {},
        characterSlots = slots,
        pedMenu = meta.pedMenu == true,
        welcomeBanner = meta.welcomeBanner == true,
        grindBonus = tonumber(meta.grindBonus) or 0,
    }
end

local function CanOpenPedMenu(src)
    if HasPedMenuGroup(src) then
        return true
    end
    local status = BuildStatus(LicenseFromSource(src))
    return status.active and status.pedMenu == true
end

local MAX_VIP_DAYS = 3650
local MAX_VIP_MONTHS = 120

local function ComputeExpiresSql(amount, unit)
    amount = math.floor(tonumber(amount) or 0)
    if unit == "months" then
        if amount < 1 or amount > MAX_VIP_MONTHS then
            return nil, ("Months must be 1-%s"):format(MAX_VIP_MONTHS)
        end
        local t = os.date("*t")
        t.month = t.month + amount
        t.isdst = nil
        return os.date("%Y-%m-%d %H:%M:%S", os.time(t))
    end
    if amount < 1 or amount > MAX_VIP_DAYS then
        return nil, ("Days must be 1-%s"):format(MAX_VIP_DAYS)
    end
    return os.date("%Y-%m-%d %H:%M:%S", os.time() + (amount * 86400))
end

local function FormatExpiresForSql(expiresAt)
    if not expiresAt then return nil end
    if type(expiresAt) == "number" then
        return os.date("%Y-%m-%d %H:%M:%S", expiresAt)
    end
    local s = tostring(expiresAt):gsub("T", " "):gsub("Z$", "")
    local y, m, d, H, M, S = s:match("^(%d+)%-(%d+)%-(%d+)[%s](%d+):(%d+):(%d+)")
    if y then
        return ("%s-%s-%s %s:%s:%s"):format(y, m, d, H, M, S)
    end
    return s
end

local function UpsertVip(identifier, tier, expires, autoRenew, grantedBy, playerName)
    identifier = NormalizeLicense(identifier)
    if not identifier or not expires then return false end

    tier = tier or "vip1"
    if not ConfigVip.Tiers[tier] then
        tier = "vip1"
    end
    local meta = TierMeta(tier)

    EnsureTable()
    MySQL.insert.await([[
        INSERT INTO grim_vip (identifier, name, tier, label, expires_at, auto_renew, granted_by)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            name = COALESCE(VALUES(name), name),
            tier = VALUES(tier),
            label = VALUES(label),
            expires_at = VALUES(expires_at),
            auto_renew = VALUES(auto_renew),
            granted_by = VALUES(granted_by)
    ]], {
        identifier,
        playerName,
        tier,
        meta.label,
        expires,
        autoRenew and 1 or 0,
        grantedBy or "system",
    })

    return true
end

local function GrantVipDuration(identifier, tier, amount, unit, autoRenew, grantedBy, playerName)
    local expires, err = ComputeExpiresSql(amount, unit == "months" and "months" or "days")
    if not expires then return false, err end
    if not UpsertVip(identifier, tier, expires, autoRenew, grantedBy, playerName) then
        return false, "Could not save VIP"
    end
    return true, expires
end

local function GrantVip(identifier, tier, days, autoRenew, grantedBy, playerName)
    local ok = GrantVipDuration(identifier, tier, days or 30, "days", autoRenew, grantedBy, playerName)
    return ok
end

local function RevokeVip(identifier)
    identifier = NormalizeLicense(identifier)
    if not identifier then return false end
    EnsureTable()
    MySQL.update.await("DELETE FROM grim_vip WHERE identifier = ?", { identifier })
    return true
end

--- Public helpers for other resources (illenium / welcomebanner / autofarm)
exports("GetVipStatus", function(src)
    local license = LicenseFromSource(src)
    if not license then return nil end
    return BuildStatus(license)
end)

exports("IsPlayerVip", function(src)
    if not src then return false end
    local license = LicenseFromSource(src)
    if not license then return false end
    local status = BuildStatus(license)
    return status.active == true
end)

exports("GetPlayerVipTier", function(src)
    if not src then return "none" end
    local license = LicenseFromSource(src)
    if not license then return "none" end
    local status = BuildStatus(license)
    return status.active and status.tier or "none"
end)

exports("GetVipSlotsForIdentifier", function(identifier)
    local row = GetActiveVipRow(identifier)
    if not row then return 1 end
    local meta = TierMeta(row.tier)
    return tonumber(meta.characterSlots) or 1
end)

exports("CanUsePedMenu", function(src)
    return CanOpenPedMenu(src)
end)

exports("CanEditWelcomeBanner", function(src)
    local status = BuildStatus(LicenseFromSource(src))
    return status.active and status.welcomeBanner == true
end)

exports("GetVipGrindBonus", function(src)
    if not src then return 0 end
    local license = LicenseFromSource(src)
    if not license then return 0 end
    local status = BuildStatus(license)
    if not status.active then return 0 end
    local meta = TierMeta(status.tier)
    return tonumber(meta.grindBonus) or 0
end)

exports("GetVipLicense", function(src)
    return LicenseFromSource(src)
end)

exports("GrantVip", GrantVip)
exports("GrantVipDuration", GrantVipDuration)
exports("RevokeVip", RevokeVip)

local function CollectTiers()
    local tiers = {}
    for id, meta in pairs(ConfigVip.Tiers or {}) do
        tiers[#tiers + 1] = {
            id = id,
            label = meta.label or id,
            characterSlots = tonumber(meta.characterSlots) or 1,
        }
    end
    table.sort(tiers, function(a, b)
        return a.id < b.id
    end)
    return tiers
end

local function CollectOnlinePlayers()
    local list = {}
    for _, sid in ipairs(GetPlayers()) do
        local id = tonumber(sid)
        if id then
            list[#list + 1] = {
                id = id,
                name = GetPlayerName(id) or ("ID " .. id),
                vip = BuildStatus(LicenseFromSource(id)),
            }
        end
    end
    table.sort(list, function(a, b)
        return a.id < b.id
    end)
    return list
end

local function StaffDenied()
    return { ok = false, canManage = false, error = "No permission" }
end

lib.callback.register("cfx-keydi-vip:getStatus", function(source)
    return {
        vip = BuildStatus(LicenseFromSource(source)),
        canManage = IsStaff(ESX.GetPlayerFromId(source)),
    }
end)

lib.callback.register("cfx-keydi-vip:staffRoster", function(source)
    if not IsStaff(ESX.GetPlayerFromId(source)) then
        return StaffDenied()
    end
    return {
        ok = true,
        canManage = true,
        tiers = CollectTiers(),
        players = CollectOnlinePlayers(),
    }
end)

lib.callback.register("cfx-keydi-vip:staffLookup", function(source, targetId)
    if not IsStaff(ESX.GetPlayerFromId(source)) then
        return StaffDenied()
    end
    targetId = tonumber(targetId)
    if not targetId then
        return { ok = false, error = "Enter a player ID" }
    end
    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        return { ok = false, error = "Player offline" }
    end
    return {
        ok = true,
        player = {
            id = targetId,
            name = GetPlayerName(targetId) or ("ID " .. targetId),
            vip = BuildStatus(LicenseFromSource(targetId)),
        },
    }
end)

lib.callback.register("cfx-keydi-vip:staffSet", function(source, data)
    if not IsStaff(ESX.GetPlayerFromId(source)) then
        return StaffDenied()
    end

    data = type(data) == "table" and data or {}
    local targetId = tonumber(data.targetId)
    if not targetId then
        return { ok = false, error = "Enter a player ID" }
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        return { ok = false, error = "Player offline" }
    end

    local tier = tostring(data.tier or "vip1")
    if not ConfigVip.Tiers[tier] then
        return { ok = false, error = "Invalid VIP tier" }
    end

    local license = LicenseFromSource(targetId)
    local staffName = GetPlayerName(source) or "staff"
    local playerName = GetPlayerName(targetId)
    local autoRenew = data.autoRenew == true
    local keepExpiry = data.keepExpiry == true
    local meta = TierMeta(tier)

    if keepExpiry then
        local row = GetActiveVipRow(license)
        if not row then
            return { ok = false, error = "No VIP to edit. Use Set New and pick a duration." }
        end
        local expires = FormatExpiresForSql(row.expires_at)
        if not UpsertVip(license, tier, expires, autoRenew, staffName, playerName) then
            return { ok = false, error = "Could not update VIP" }
        end
        TriggerClientEvent("esx:showNotification", targetId, ("VIP updated · %s"):format(meta.label), "success")
        TriggerClientEvent("esx:showNotification", source, ("Updated %s for ID %s"):format(meta.label, targetId), "success")
    else
        local unit = data.unit == "months" and "months" or "days"
        local ok, expiresOrErr = GrantVipDuration(license, tier, data.amount, unit, autoRenew, staffName, playerName)
        if not ok then
            return { ok = false, error = expiresOrErr or "Could not save VIP" }
        end
        local amount = math.floor(tonumber(data.amount) or 0)
        local unitLabel = amount == 1 and (unit == "months" and "month" or "day") or unit
        TriggerClientEvent(
            "esx:showNotification",
            targetId,
            ("%s · %s %s"):format(meta.label, amount, unitLabel),
            "success"
        )
        TriggerClientEvent(
            "esx:showNotification",
            source,
            ("Granted %s to ID %s · %s %s"):format(meta.label, targetId, amount, unitLabel),
            "success"
        )
    end

    return {
        ok = true,
        vip = BuildStatus(license),
        players = CollectOnlinePlayers(),
    }
end)

lib.callback.register("cfx-keydi-vip:staffRevoke", function(source, targetId)
    if not IsStaff(ESX.GetPlayerFromId(source)) then
        return StaffDenied()
    end
    targetId = tonumber(targetId)
    if not targetId then
        return { ok = false, error = "Enter a player ID" }
    end
    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        return { ok = false, error = "Player offline" }
    end

    RevokeVip(LicenseFromSource(targetId))
    TriggerClientEvent("esx:showNotification", targetId, "Your VIP was revoked", "error")
    TriggerClientEvent("esx:showNotification", source, ("Revoked VIP for ID %s"):format(targetId), "success")

    return {
        ok = true,
        vip = BuildStatus(LicenseFromSource(targetId)),
        players = CollectOnlinePlayers(),
    }
end)

lib.callback.register("cfx-keydi-vip:getAllVipMembers", function(source)
    if not IsStaff(ESX.GetPlayerFromId(source)) then
        return StaffDenied()
    end
    EnsureTable()

    local rows = MySQL.query.await([[
        SELECT
            v.identifier,
            COALESCE(
                NULLIF(v.name, ''),
                (
                    SELECT NULLIF(TRIM(CONCAT(COALESCE(u.firstname, ''), ' ', COALESCE(u.lastname, ''))), '')
                    FROM users u
                    WHERE u.identifier = v.identifier
                       OR u.identifier LIKE CONCAT('char%:', v.identifier)
                    LIMIT 1
                ),
                'Unknown Player'
            ) as name,
            v.tier,
            v.label,
            v.expires_at,
            v.auto_renew,
            v.granted_by,
            v.started_at
        FROM grim_vip v
        ORDER BY v.expires_at DESC
    ]]) or {}

    local list = {}
    local onlineMap = {}
    for _, sid in ipairs(GetPlayers()) do
        local sId = tonumber(sid)
        if sId then
            local lic = LicenseFromSource(sId)
            if lic then onlineMap[lic] = sId end
        end
    end

    for _, row in ipairs(rows) do
        local days, hours, active = RemainingFromExpires(row.expires_at)
        local meta = TierMeta(row.tier)
        local onlineId = onlineMap[row.identifier]

        list[#list + 1] = {
            identifier = row.identifier,
            name = row.name or "Unknown Player",
            onlineId = onlineId,
            isOnline = onlineId ~= nil,
            tier = row.tier,
            label = meta.label or row.label or row.tier,
            characterSlots = meta.characterSlots or 1,
            expiresAt = IsoFromDb(row.expires_at),
            startedAt = IsoFromDb(row.started_at),
            autoRenew = row.auto_renew == 1 or row.auto_renew == true,
            grantedBy = row.granted_by or "system",
            daysRemaining = days,
            hoursRemaining = hours,
            active = active,
        }
    end

    return {
        ok = true,
        members = list,
        tiers = CollectTiers(),
        players = CollectOnlinePlayers(),
    }
end)

lib.callback.register("cfx-keydi-vip:staffEditVip", function(source, data)
    if not IsStaff(ESX.GetPlayerFromId(source)) then
        return StaffDenied()
    end

    data = type(data) == "table" and data or {}
    local identifier = NormalizeLicense(data.identifier)
    if not identifier and data.targetId then
        identifier = LicenseFromSource(tonumber(data.targetId))
    end
    if not identifier then
        return { ok = false, error = "Invalid player or identifier" }
    end

    local tier = tostring(data.tier or "vip1")
    if not ConfigVip.Tiers[tier] then
        return { ok = false, error = "Invalid VIP tier" }
    end

    local staffName = GetPlayerName(source) or "staff"
    local autoRenew = data.autoRenew == true
    local meta = TierMeta(tier)
    local expires = nil

    if data.customExpires and tostring(data.customExpires) ~= "" then
        expires = FormatExpiresForSql(data.customExpires)
    elseif data.addDays and tonumber(data.addDays) then
        local addSec = tonumber(data.addDays) * 86400
        local currentRow = GetActiveVipRow(identifier)
        local baseUnix = os.time()
        if currentRow and currentRow.expires_at then
            local _, _, stillActive = RemainingFromExpires(currentRow.expires_at)
            if stillActive then
                local y, m, d, H, M, S = tostring(currentRow.expires_at):match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
                if y then
                    baseUnix = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = tonumber(H), min = tonumber(M), sec = tonumber(S) })
                end
            end
        end
        expires = os.date("%Y-%m-%d %H:%M:%S", baseUnix + addSec)
    elseif data.keepExpiry then
        local currentRow = GetActiveVipRow(identifier)
        if not currentRow then
            return { ok = false, error = "Player has no active VIP to keep expiration for." }
        end
        expires = FormatExpiresForSql(currentRow.expires_at)
    else
        local unit = data.unit == "months" and "months" or "days"
        local ok, expOrErr = ComputeExpiresSql(data.amount or 30, unit)
        if not ok then return { ok = false, error = expOrErr } end
        expires = expOrErr
    end

    if not expires then
        return { ok = false, error = "Could not calculate expiration date." }
    end

    local playerName = data.name or nil
    if not playerName then
        local targetXPlayer = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier)
        if targetXPlayer then
            playerName = targetXPlayer.getName and targetXPlayer.getName() or GetPlayerName(targetXPlayer.source)
        end
    end

    if not UpsertVip(identifier, tier, expires, autoRenew, staffName, playerName) then
        return { ok = false, error = "Could not update VIP database record." }
    end

    for _, sid in ipairs(GetPlayers()) do
        local sId = tonumber(sid)
        if sId and LicenseFromSource(sId) == identifier then
            TriggerClientEvent("esx:showNotification", sId, ("VIP updated · %s"):format(meta.label), "success")
            break
        end
    end

    TriggerClientEvent("esx:showNotification", source, ("Updated %s for %s"):format(meta.label, playerName or identifier), "success")

    return {
        ok = true,
        member = {
            identifier = identifier,
            tier = tier,
            expiresAt = IsoFromDb(expires),
            label = meta.label,
        }
    }
end)

lib.callback.register("cfx-keydi-vip:staffRevokeByIdentifier", function(source, identifier)
    if not IsStaff(ESX.GetPlayerFromId(source)) then
        return StaffDenied()
    end
    identifier = NormalizeLicense(identifier)
    if not identifier then
        return { ok = false, error = "Invalid identifier" }
    end

    RevokeVip(identifier)

    for _, sid in ipairs(GetPlayers()) do
        local sId = tonumber(sid)
        if sId and LicenseFromSource(sId) == identifier then
            TriggerClientEvent("esx:showNotification", sId, "Your VIP was revoked", "error")
            break
        end
    end

    TriggerClientEvent("esx:showNotification", source, ("Revoked VIP for %s"):format(identifier), "success")
    return { ok = true }
end)

lib.callback.register("cfx-keydi-vip:canPedMenu", function(source)
    return CanOpenPedMenu(source)
end)

lib.callback.register("cfx-keydi-vip:canWelcomeBanner", function(source)
    local status = BuildStatus(LicenseFromSource(source))
    return status.active and status.welcomeBanner == true
end)

RegisterCommand("setvip", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not IsStaff(xPlayer) then
            TriggerClientEvent("esx:showNotification", src, "No permission", "error")
            return
        end
    end

    local targetId = tonumber(args[1])
    local tier = args[2] or "vip3"
    local days = tonumber(args[3]) or 30
    local autoRenew = args[4] == "1" or args[4] == "true"

    if not targetId then
        if src > 0 then
            TriggerClientEvent("esx:showNotification", src, "Usage: /setvip [id] [tier] [days] [autorenew 0/1]", "error")
        end
        return
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        if src > 0 then
            TriggerClientEvent("esx:showNotification", src, "Player offline", "error")
        end
        return
    end

    local license = LicenseFromSource(targetId)
    local staffName = src > 0 and GetPlayerName(src) or "console"
    local playerName = GetPlayerName(targetId)
    GrantVip(license, tier, days, autoRenew, staffName, playerName)

    local meta = TierMeta(tier)
    TriggerClientEvent(
        "esx:showNotification",
        targetId,
        ("VIP %s · %sd"):format(meta.label, days),
        "success"
    )
    if src > 0 then
        TriggerClientEvent("esx:showNotification", src, ("Granted %s to ID %s"):format(tier, targetId), "success")
    end
end, false)

RegisterCommand("revokevip", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not IsStaff(xPlayer) then
            TriggerClientEvent("esx:showNotification", src, "No permission", "error")
            return
        end
    end

    local targetId = tonumber(args[1])
    if not targetId then
        if src > 0 then
            TriggerClientEvent("esx:showNotification", src, "Usage: /revokevip [id]", "error")
        end
        return
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        if src > 0 then
            TriggerClientEvent("esx:showNotification", src, "Player offline", "error")
        end
        return
    end

    RevokeVip(LicenseFromSource(targetId))
    TriggerClientEvent("esx:showNotification", targetId, "Your VIP was revoked", "error")
    if src > 0 then
        TriggerClientEvent("esx:showNotification", src, ("Revoked VIP for ID %s"):format(targetId), "success")
    end
end, false)
