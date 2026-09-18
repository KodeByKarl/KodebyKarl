local ESX = exports["es_extended"]:getSharedObject()
local announced = {}
local bannerPlayers = {}

local DATA_FILE = "Module/welcomebanner/data/players.json"

local function Debug(msg, ...)
    if not ConfigWelcomeBanner or not ConfigWelcomeBanner.Debug then return end
    print(("[welcomebanner] " .. msg):format(...))
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
    return id
end

local function IsAllowed(xPlayer)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or "user"
    local allowed = ConfigWelcomeBanner.AllowedGroups or {}
    return allowed[group] == true
end

local function IsVipBannerEditor(src)
    if GetResourceState("kodebykarl-ui") ~= "started" then return false end
    local ok, allowed = pcall(function()
        return exports["kodebykarl-ui"]:CanEditWelcomeBanner(src)
    end)
    return ok and allowed == true
end

local function GetVipLicense(src)
    if GetResourceState("kodebykarl-ui") ~= "started" then return nil end
    local ok, license = pcall(function()
        return exports["kodebykarl-ui"]:GetVipLicense(src)
    end)
    if ok and type(license) == "string" then
        return NormalizeLicense(license)
    end
    return nil
end

local function BuildSelfPanelData(xPlayer, src)
    LoadPlayers()
    local license = NormalizeLicense(GetVipLicense(src) or (xPlayer and xPlayer.identifier))
    local own = nil
    if license then
        for _, entry in ipairs(bannerPlayers) do
            if NormalizeLicense(entry.identifier) == license then
                own = entry
                break
            end
        end
    end

    return {
        staffName = GetCharacterName(xPlayer, src),
        staffGroup = "vip",
        selfEdit = true,
        selfIdentifier = license,
        players = own and { own } or {},
        online = {},
        duration = ConfigWelcomeBanner.Duration or 8,
    }
end

local function SanitizeEntry(entry)
    if type(entry) ~= "table" then return nil end

    local identifier = type(entry.identifier) == "string" and entry.identifier:match("^%s*(.-)%s*$") or ""
    if identifier == "" then return nil end

    local gif = entry.gif or entry.image or ""
    if type(gif) ~= "string" then gif = "" end
    gif = gif:match("^%s*(.-)%s*$") or ""

    local sound = entry.sound or ""
    if type(sound) ~= "string" then sound = "" end
    sound = sound:match("^%s*(.-)%s*$") or ""

    return {
        identifier = identifier,
        name = type(entry.name) == "string" and entry.name or "",
        gif = gif,
        sound = sound,
        volume = tonumber(entry.volume) or 0.6,
        width = tonumber(entry.width),
        height = tonumber(entry.height),
        duration = tonumber(entry.duration),
        addedBy = type(entry.addedBy) == "string" and entry.addedBy or "",
        addedAt = type(entry.addedAt) == "string" and entry.addedAt or "",
    }
end

local function SavePlayers()
    local payload = { players = bannerPlayers }
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, json.encode(payload), -1)
end

local function LoadPlayers()
    bannerPlayers = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if raw and raw ~= "" then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == "table" then
            local list = data.players or data
            if type(list) == "table" then
                for _, entry in ipairs(list) do
                    local clean = SanitizeEntry(entry)
                    if clean then
                        bannerPlayers[#bannerPlayers + 1] = clean
                    end
                end
            end
        else
            print("^1[welcomebanner] Failed to parse players.json^7")
        end
    end
    Debug("loaded %s banner player(s)", tostring(#bannerPlayers))
end

local function CollectPlayerTokens(src, xPlayer)
    local tokens = {}

    local function add(raw)
        local normalized = NormalizeLicense(raw)
        if normalized then
            tokens[normalized] = true
        end
    end

    if src then
        for _, id in ipairs(GetPlayerIdentifiers(src)) do
            add(id)
        end
    end

    if xPlayer then
        add(xPlayer.identifier)
        add(xPlayer.license)
        if xPlayer.get then
            add(xPlayer.get("identifier"))
        end
    end

    return tokens
end

local function GetCharacterName(xPlayer, src)
    if xPlayer then
        local firstName = xPlayer.get and (xPlayer.get("firstName") or "") or ""
        local lastName = xPlayer.get and (xPlayer.get("lastName") or "") or ""
        local name = (firstName .. " " .. lastName):match("^%s*(.-)%s*$")

        if name and name ~= "" then
            return name
        end

        if xPlayer.getName then
            name = xPlayer.getName()
            if name and name ~= "" then
                return name
            end
        end
    end

    return GetPlayerName(src) or "Citizen"
end

local function GetLicenseLabel(src, xPlayer)
    if src then
        for _, id in ipairs(GetPlayerIdentifiers(src)) do
            if type(id) == "string" and (id:sub(1, 8) == "license:" or id:sub(1, 9) == "license2:") then
                return id
            end
        end
    end
    if xPlayer then
        if xPlayer.license and xPlayer.license ~= "" then
            return xPlayer.license
        end
        if xPlayer.identifier then
            return xPlayer.identifier
        end
    end
    return ""
end

local function FindBannerEntry(src, xPlayer)
    local tokens = CollectPlayerTokens(src, xPlayer)
    if not next(tokens) then
        Debug("no identifiers for src %s", tostring(src))
        return nil
    end

    for _, entry in ipairs(bannerPlayers) do
        local wanted = NormalizeLicense(entry.identifier)
        if wanted and tokens[wanted] then
            return entry, wanted
        end
    end

    local found = {}
    for token in pairs(tokens) do
        found[#found + 1] = token
    end
    Debug("no json match for src %s | player tokens: %s", tostring(src), table.concat(found, ", "))
    return nil
end

local function GetOnlinePlayers()
    local list = {}
    for _, xTarget in ipairs(ESX.GetExtendedPlayers()) do
        list[#list + 1] = {
            id = xTarget.source,
            name = GetCharacterName(xTarget, xTarget.source),
            identifier = GetLicenseLabel(xTarget.source, xTarget),
        }
    end
    table.sort(list, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
    return list
end

local function BuildPanelData(xPlayer)
    return {
        staffName = GetCharacterName(xPlayer, xPlayer.source),
        staffGroup = xPlayer.getGroup and xPlayer.getGroup() or "",
        players = bannerPlayers,
        online = GetOnlinePlayers(),
        image = ConfigWelcomeBanner.Image,
        duration = ConfigWelcomeBanner.Duration,
    }
end

local function AnnounceWelcome(src)
    if announced[src] then
        Debug("already announced for src %s", tostring(src))
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    local entry, matched = FindBannerEntry(src, xPlayer)
    if not entry then return end

    announced[src] = true
    Debug("showing banner for src %s license %s", tostring(src), matched or "?")

    TriggerClientEvent("cfx-keydi-welcomebanner:show", -1, {
        playerName = GetCharacterName(xPlayer, src),
        gif = entry.gif or "",
        sound = entry.sound or "",
        volume = entry.volume,
        duration = entry.duration,
        width = entry.width,
        height = entry.height,
    })
end

CreateThread(function()
    Wait(0)
    LoadPlayers()
end)

AddEventHandler("playerDropped", function()
    announced[source] = nil
end)

RegisterNetEvent("cfx-keydi-welcomebanner:announce", function()
    AnnounceWelcome(source)
end)

ESX.RegisterServerCallback("cfx-keydi-welcomebanner:open", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if IsAllowed(xPlayer) then
        LoadPlayers()
        return cb(BuildPanelData(xPlayer))
    end
    if IsVipBannerEditor(source) then
        return cb(BuildSelfPanelData(xPlayer, source))
    end
    return cb(false)
end)

ESX.RegisterServerCallback("cfx-keydi-welcomebanner:add", function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    local staff = IsAllowed(xPlayer)
    local vip = IsVipBannerEditor(source)
    if not staff and not vip then
        return cb({ ok = false, message = "No permission." })
    end

    payload = type(payload) == "table" and payload or {}
    local clean = SanitizeEntry(payload)
    if not clean then
        return cb({ ok = false, message = "Identifier is required." })
    end
    if clean.gif == "" then
        return cb({ ok = false, message = "GIF / image URL is required." })
    end

    local wanted = NormalizeLicense(clean.identifier)
    if not wanted then
        return cb({ ok = false, message = "Invalid identifier." })
    end

    -- VIP self-edit: lock to own license only
    if vip and not staff then
        local own = NormalizeLicense(GetVipLicense(source))
        if not own or wanted ~= own then
            return cb({ ok = false, message = "You can only edit your own welcome banner." })
        end
        clean.identifier = own
        wanted = own
        if clean.name == "" then
            clean.name = GetCharacterName(xPlayer, source)
        end
    end

    if clean.name == "" then
        for _, online in ipairs(GetOnlinePlayers()) do
            if NormalizeLicense(online.identifier) == wanted then
                clean.name = online.name
                break
            end
        end
    end

    clean.addedBy = GetCharacterName(xPlayer, source)
    clean.addedAt = os.date("!%Y-%m-%dT%H:%M:%SZ")

    for index, existing in ipairs(bannerPlayers) do
        if NormalizeLicense(existing.identifier) == wanted then
            bannerPlayers[index] = clean
            SavePlayers()
            if vip and not staff then
                return cb({
                    ok = true,
                    updated = true,
                    players = { clean },
                    online = {},
                    selfEdit = true,
                    selfIdentifier = wanted,
                })
            end
            return cb({ ok = true, updated = true, players = bannerPlayers, online = GetOnlinePlayers() })
        end
    end

    bannerPlayers[#bannerPlayers + 1] = clean
    SavePlayers()
    if vip and not staff then
        return cb({
            ok = true,
            updated = false,
            players = { clean },
            online = {},
            selfEdit = true,
            selfIdentifier = wanted,
        })
    end
    cb({ ok = true, updated = false, players = bannerPlayers, online = GetOnlinePlayers() })
end)

ESX.RegisterServerCallback("cfx-keydi-welcomebanner:remove", function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    local staff = IsAllowed(xPlayer)
    local vip = IsVipBannerEditor(source)
    if not staff and not vip then
        return cb({ ok = false, message = "No permission." })
    end

    payload = type(payload) == "table" and payload or {}
    local wanted = NormalizeLicense(payload.identifier)
    if not wanted then
        return cb({ ok = false, message = "Invalid identifier." })
    end

    if vip and not staff then
        local own = NormalizeLicense(GetVipLicense(source))
        if not own or wanted ~= own then
            return cb({ ok = false, message = "You can only remove your own welcome banner." })
        end
    end

    local removed = false
    for index = #bannerPlayers, 1, -1 do
        if NormalizeLicense(bannerPlayers[index].identifier) == wanted then
            table.remove(bannerPlayers, index)
            removed = true
        end
    end

    if not removed then
        return cb({ ok = false, message = "Banner not found." })
    end

    SavePlayers()
    if vip and not staff then
        return cb({ ok = true, players = {}, online = {}, selfEdit = true, selfIdentifier = wanted })
    end
    cb({ ok = true, players = bannerPlayers, online = GetOnlinePlayers() })
end)
