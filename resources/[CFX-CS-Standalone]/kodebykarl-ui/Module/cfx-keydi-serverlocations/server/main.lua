ESX = ESX or exports["es_extended"]:getSharedObject()

ServerLocations = ServerLocations or {}

local playerLocations = {} -- [src] = locationId
local previousPublicId = {} -- [src] = last public realm before a job instance
local lastSwitchAt = {} -- [src] = os.time()

local TABLE_READY = false

local function DebugLog(msg)
    if ConfigServerLocations.Debug then
        print(("[ServerLocations] %s"):format(msg))
    end
end

local function EnsureRegionTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `grim_player_regions` (
            `identifier` VARCHAR(60) NOT NULL,
            `region_id` VARCHAR(64) NOT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    TABLE_READY = true
end

local function GetIdentifier(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.identifier then
        return xPlayer.identifier
    end
    return nil
end

local function SavePlayerRegion(src, regionId)
    regionId = ConfigServerLocations.NormalizeId(regionId)
    if not regionId or not ConfigServerLocations.GetById(regionId) then return end

    local identifier = GetIdentifier(src)
    if not identifier then return end

    if not TABLE_READY then
        EnsureRegionTable()
    end

    MySQL.insert.await([[
        INSERT INTO `grim_player_regions` (`identifier`, `region_id`)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `region_id` = VALUES(`region_id`)
    ]], { identifier, regionId })
end

local function LoadPlayerRegionId(src)
    local identifier = GetIdentifier(src)
    if not identifier then
        return ConfigServerLocations.DefaultId
    end

    if not TABLE_READY then
        EnsureRegionTable()
    end

    local row = MySQL.single.await(
        "SELECT `region_id` FROM `grim_player_regions` WHERE `identifier` = ? LIMIT 1",
        { identifier }
    )

    local id = row and ConfigServerLocations.NormalizeId(row.region_id)
    if id and ConfigServerLocations.GetById(id) then
        return id
    end

    return ConfigServerLocations.DefaultId
end

local function Notify(src, msg, nType)
    TriggerClientEvent("esx:showNotification", src, msg, nType or "info")
end

local function GetMaxClients()
    local max = tonumber(GetConvarInt("sv_maxclients", 0)) or 0
    if max < 1 then
        max = tonumber(GetConvarInt("sv_maxClients", 0)) or 0
    end
    if max < 1 then
        max = 32
    end
    return max
end

--- Public locations use the whole-server slot cap. Job instances may be smaller, never larger.
local function GetLocationMaxPlayers(loc, kind)
    local serverMax = GetMaxClients()
    if kind ~= "job" then
        return serverMax
    end
    local configured = tonumber(loc and loc.maxPlayers) or serverMax
    if configured < 1 then
        return serverMax
    end
    if configured > serverMax then
        return serverMax
    end
    return configured
end

local function CountPlayersInBucket(bucket)
    local n = 0
    local players = GetPlayers()
    for i = 1, #players do
        local id = tonumber(players[i])
        if id and GetPlayerRoutingBucket(id) == bucket then
            n = n + 1
        end
    end
    return n
end

local function GetLockReason(src)
    local state = Player(src).state
    if not state then return "Unknown status" end

    if ConfigServerLocations.LockInJail and (state.isJailed or state.inJail or state.comserv or (tonumber(state.jailTime) or 0) > 0) then
        return "In Jail / Community Service"
    end
    if ConfigServerLocations.LockInArena and state.inArena then
        return "Inside Arena Instance"
    end
    if ConfigServerLocations.LockInPvp ~= false and (state.inPvp or state.isInPvp) then
        return "Inside Deathmatch Arena"
    end
    if state.dead or state.isDead then
        return "Downed"
    end
    if state.cuffed or state.isHandcuffed then
        return "Restrained"
    end
    if ConfigServerLocations.LockInCombat ~= false and state.inCombat then
        return "In combat"
    end
    if state.inHouseRobbery then
        return "Inside a house robbery"
    end

    if ConfigServerLocations.LockInInstance ~= false then
        local currentLoc = ServerLocations.GetPlayerLocation(src)
        if currentLoc then
            local expected = tonumber(currentLoc.bucket) or 0
            local actual = GetPlayerRoutingBucket(src)
            if actual ~= expected then
                return "Inside an active instance"
            end
        end
        if GetResourceState('kodebykarl-robbery') == 'started' then
            local ok, inside = pcall(function()
                return exports['kodebykarl-robbery']:IsInsideHouse(src)
            end)
            if ok and inside then
                return "Inside a house robbery"
            end
        end
    end
    return nil
end

local function IsInSafezone(src)
    local state = Player(src).state
    if not state then return false end
    if state.inSafeZone == true or state.inSafezone == true then
        return true
    end
    return false
end

function ServerLocations.GetPlayerId(src)
    local fallback = ConfigServerLocations.DefaultId or "region1"
    local id = playerLocations[src] or fallback
    return ConfigServerLocations.NormalizeId(id) or fallback
end

function ServerLocations.GetPlayerLocation(src)
    return ConfigServerLocations.GetById(ServerLocations.GetPlayerId(src))
end

function ServerLocations.PlayerHasFunction(src, fn)
    return ConfigServerLocations.CanUseFunction(fn, src)
end

local function BuildLocationPayload(loc, kind, src)
    local isCurrent = loc.id == ServerLocations.GetPlayerId(src)
    local online = CountPlayersInBucket(loc.bucket or 0)
    local maxPlayers = GetLocationMaxPlayers(loc, kind)
    local status = loc.status or "ONLINE"
    if online >= maxPlayers then
        status = "FULL"
    end
    return {
        id = loc.id,
        name = loc.name,
        tag = loc.tag,
        type = loc.type,
        description = loc.description,
        maxPlayers = maxPlayers,
        status = status,
        functions = loc.functions or {},
        isCurrent = isCurrent,
        onlinePlayers = online,
        ping = isCurrent and "16 ms" or "18 ms",
        kind = kind,
    }
end

function ServerLocations.GetServersData(src)
    local publicServers = {}
    local sideJobServers = {}

    for i = 1, #ConfigServerLocations.PublicServers do
        publicServers[#publicServers + 1] = BuildLocationPayload(ConfigServerLocations.PublicServers[i], "public", src)
    end

    for i = 1, #ConfigServerLocations.SideJobServers do
        sideJobServers[#sideJobServers + 1] = BuildLocationPayload(ConfigServerLocations.SideJobServers[i], "job", src)
    end

    local current = ServerLocations.GetPlayerLocation(src)
    local lockReason = GetLockReason(src)
    local inSafezone = IsInSafezone(src)
    local requireSafezone = ConfigServerLocations.RequiresSafezoneToSwitch(src)

    return {
        publicServers = publicServers,
        sideJobServers = sideJobServers,
        currentServerId = ServerLocations.GetPlayerId(src),
        currentType = current and current.type or "main",
        maxClients = GetMaxClients(),
        inSafezone = inSafezone,
        requireSafezone = requireSafezone,
        isLocked = lockReason ~= nil,
        lockReason = lockReason or (requireSafezone and not inSafezone and "Outside Safezone" or nil),
    }
end

local function ApplyRouting(src, loc)
    local bucket = tonumber(loc.bucket) or 0
    SetPlayerRoutingBucket(src, bucket)

    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            SetEntityRoutingBucket(veh, bucket)
        end
    end

    local state = Player(src).state
    state:set("grimServerId", loc.id, true)
    state:set("grimServerType", loc.type or "main", true)
    state:set("inJobInstance", loc.type == "job", true)
end

local function TeleportPlayer(src, loc)
    if not ConfigServerLocations.TeleportOnSwitch then return end
    local spawn = loc.spawn
    if not spawn then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    if KeydiElectron and KeydiElectron.Allow then
        KeydiElectron.Allow(src, { "AntiTeleport", "Teleport", "Noclip" }, 6000)
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then
        SetEntityCoords(veh, spawn.x, spawn.y, spawn.z, false, false, false, false)
        SetEntityHeading(veh, spawn.w or 0.0)
    else
        SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
        SetEntityHeading(ped, spawn.w or 0.0)
    end
end

local function ApplyLocation(src, loc, opts)
    opts = opts or {}
    playerLocations[src] = loc.id
    ApplyRouting(src, loc)

    if opts.teleport then
        TeleportPlayer(src, loc)
    end

    if opts.persist ~= false and loc.type ~= "job" then
        SavePlayerRegion(src, loc.id)
    elseif opts.persist == true then
        SavePlayerRegion(src, loc.id)
    end

    TriggerClientEvent("cfx-keydi-serverlocations:client:applied", src, {
        id = loc.id,
        name = loc.name,
        tag = loc.tag,
        type = loc.type,
        bucket = loc.bucket,
        functions = loc.functions or {},
    })

    DebugLog(("%s [%s] -> %s (bucket %s)"):format(GetPlayerName(src) or "?", src, loc.id, tostring(loc.bucket)))
end

local function ValidateSwitch(src, locationId, opts)
    opts = opts or {}
    local loc, kind = ConfigServerLocations.GetById(locationId)
    if not loc then
        return false, "Unknown region."
    end

    local currentId = ServerLocations.GetPlayerId(src)
    if not opts.allowSame and currentId == loc.id then
        return false, "You are already in this region."
    end

    if not opts.skipCooldown then
        local now = os.time()
        if lastSwitchAt[src] and (now - lastSwitchAt[src]) < (ConfigServerLocations.SwitchCooldown or 8) then
            return false, "Please wait a moment before switching again."
        end
    end

    local lockReason = GetLockReason(src)
    if lockReason then
        return false, ("Region switching locked while %s."):format(lockReason)
    end

    if ConfigServerLocations.RequiresSafezoneToSwitch(src) and not opts.skipSafezone and not IsInSafezone(src) then
        return false, "Region switching locked! You must be inside a Safezone."
    end

    local online = CountPlayersInBucket(loc.bucket or 0)
    local maxPlayers = GetLocationMaxPlayers(loc, kind)
    if online >= maxPlayers then
        return false, "That region is full."
    end

    return true, loc, kind
end

function ServerLocations.SwitchPlayer(src, locationId, opts)
    local ok, locOrMsg, kind = ValidateSwitch(src, locationId, opts)
    if not ok then
        return false, locOrMsg
    end

    local currentId = ServerLocations.GetPlayerId(src)
    local currentLoc = ConfigServerLocations.GetById(currentId)
    if currentLoc and currentLoc.type ~= "job" and kind == "job" then
        previousPublicId[src] = currentId
    elseif kind == "public" then
        previousPublicId[src] = locOrMsg.id
    end

    lastSwitchAt[src] = os.time()
    return true, locOrMsg
end

exports("GetPlayerId", ServerLocations.GetPlayerId)
exports("GetPlayerLocation", ServerLocations.GetPlayerLocation)
exports("PlayerHasFunction", ServerLocations.PlayerHasFunction)
exports("GetServersData", ServerLocations.GetServersData)
exports("SwitchPlayer", ServerLocations.SwitchPlayer)
exports("WrongServerMessage", function(fn)
    return ConfigServerLocations.WrongServerMessage(fn)
end)
exports("RequiresSafezoneToSwitch", function(src)
    return ConfigServerLocations.RequiresSafezoneToSwitch(src)
end)

local function GetPublicBucketOwners()
    local map = {}
    for i = 1, #ConfigServerLocations.PublicServers do
        local loc = ConfigServerLocations.PublicServers[i]
        map[tonumber(loc.bucket) or 0] = loc.id
    end
    return map
end

--- If the player is sitting in a different PUBLIC region bucket than assigned
--- (hospital / appearance / scripts that SetPlayerRoutingBucket(src, 0)), snap back.
--- Private instances (appearance = player id, garage interiors, PvP) are left alone.
function ServerLocations.VerifyPlayerBucket(src)
    src = tonumber(src)
    if not src or src < 1 or not GetPlayerName(src) then
        return false
    end

    local loc = ServerLocations.GetPlayerLocation(src)
    if not loc or loc.type == "job" then
        return false
    end

    local expected = tonumber(loc.bucket) or 0
    local actual = GetPlayerRoutingBucket(src)
    if actual == expected then
        return true
    end

    local owners = GetPublicBucketOwners()
    if owners[actual] and owners[actual] ~= loc.id then
        DebugLog(("verify: %s [%s] was in public bucket %s (%s), restoring %s bucket %s"):format(
            GetPlayerName(src) or "?", src, tostring(actual), owners[actual], loc.id, tostring(expected)
        ))
        return ServerLocations.RestorePlayerBucket(src) == true
    end

    return false
end

--- Return the player to their saved region bucket.
--- Region 1 is bucket 0 (default world) so scripts that reset to 0 keep Main together.
function ServerLocations.RestorePlayerBucket(src, opts)
    src = tonumber(src)
    if not src or src < 1 or not GetPlayerName(src) then
        return false
    end

    opts = opts or {}
    if not opts.force then
        local state = Player(src).state
        if state then
            if state.inPvp or state.isInPvp then return false end
            if state.inArena then return false end
            if state.inHouseRobbery then return false end
        end

        if GetResourceState('kodebykarl-robbery') == 'started' then
            local ok, inside = pcall(function()
                return exports['kodebykarl-robbery']:IsInsideHouse(src)
            end)
            if ok and inside then
                return false
            end
        end
    end

    local loc = ServerLocations.GetPlayerLocation(src)
    if not loc then return false end

    ApplyRouting(src, loc)
    return true
end

exports("RestorePlayerBucket", ServerLocations.RestorePlayerBucket)
exports("VerifyPlayerBucket", ServerLocations.VerifyPlayerBucket)
exports("GetExpectedBucket", function(src)
    local loc = ServerLocations.GetPlayerLocation(src)
    return loc and tonumber(loc.bucket) or 0
end)

RegisterNetEvent("cfx-keydi-serverlocations:server:restoreBucket", function()
    local src = source
    if type(src) ~= "number" or src < 1 then return end
    ServerLocations.RestorePlayerBucket(src)
end)

RegisterNetEvent("cfx-keydi-serverlocations:server:verifyBucket", function()
    local src = source
    if type(src) ~= "number" or src < 1 then return end
    ServerLocations.VerifyPlayerBucket(src)
end)

ESX.RegisterServerCallback("cfx-keydi-serverlocations:server:getServersData", function(source, cb)
    cb(ServerLocations.GetServersData(source))
end)

RegisterNetEvent("cfx-keydi-serverlocations:server:requestSwitch", function(locationId)
    local src = source
    if type(src) ~= "number" or src < 1 then return end

    local ok, locOrMsg = ValidateSwitch(src, locationId)
    if not ok then
        TriggerClientEvent("cfx-keydi-serverlocations:client:switchFailed", src, locOrMsg)
        return
    end

    TriggerClientEvent("cfx-keydi-serverlocations:client:prepareSwitch", src, {
        id = locOrMsg.id,
        name = locOrMsg.name,
        type = locOrMsg.type,
        bucket = locOrMsg.bucket,
    })
end)

RegisterNetEvent("cfx-keydi-serverlocations:server:finishSwitch", function(locationId)
    local src = source
    if type(src) ~= "number" or src < 1 then return end

    local ok, locOrMsg = ServerLocations.SwitchPlayer(src, locationId)
    if not ok then
        TriggerClientEvent("cfx-keydi-serverlocations:client:switchFailed", src, locOrMsg)
        return
    end

    ApplyLocation(src, locOrMsg, { teleport = ConfigServerLocations.TeleportOnSwitch })
end)

local function AssignSavedOrDefault(src, teleport)
    local regionId = LoadPlayerRegionId(src)
    local loc = ConfigServerLocations.GetById(regionId)
    if not loc then
        loc = ConfigServerLocations.GetById(ConfigServerLocations.DefaultId)
    end
    if not loc then return end

    playerLocations[src] = loc.id
    previousPublicId[src] = loc.id
    ApplyRouting(src, loc)

    if teleport then
        TeleportPlayer(src, loc)
    end

    -- Persist default for brand-new players so next login stays consistent
    if loc.type ~= "job" then
        SavePlayerRegion(src, loc.id)
    end

    TriggerClientEvent("cfx-keydi-serverlocations:client:sync", src, {
        id = loc.id,
        name = loc.name,
        tag = loc.tag,
        type = loc.type,
        bucket = loc.bucket,
        functions = loc.functions or {},
    })
end

AddEventHandler("esx:playerLoaded", function(playerId)
    CreateThread(function()
        Wait(750)
        if GetPlayerName(playerId) then
            AssignSavedOrDefault(playerId, false)
        end
        -- Other scripts (hospital / spawn) may overwrite the bucket right after load.
        Wait(2500)
        if GetPlayerName(playerId) then
            ServerLocations.VerifyPlayerBucket(playerId)
        end
        Wait(4000)
        if GetPlayerName(playerId) then
            ServerLocations.VerifyPlayerBucket(playerId)
        end
    end)
end)

AddEventHandler("playerDropped", function()
    local src = source
    local currentId = playerLocations[src]
    if currentId then
        local loc = ConfigServerLocations.GetById(currentId)
        -- Save last public region (if they quit inside orange job, keep previous public)
        if loc and loc.type == "job" then
            currentId = previousPublicId[src] or ConfigServerLocations.DefaultId
        end
        SavePlayerRegion(src, currentId)
    end
    playerLocations[src] = nil
    previousPublicId[src] = nil
    lastSwitchAt[src] = nil
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        EnsureRegionTable()
        Wait(1000)
        local players = GetPlayers()
        for i = 1, #players do
            local id = tonumber(players[i])
            if id then
                AssignSavedOrDefault(id, false)
            end
        end
        Wait(3000)
        players = GetPlayers()
        for i = 1, #players do
            local id = tonumber(players[i])
            if id then
                ServerLocations.VerifyPlayerBucket(id)
            end
        end
    end)
end)

-- Keep Region 1 players in the same bucket so they always see each other.
-- Only corrects drift into another PUBLIC region (not garage / PvP / appearance).
CreateThread(function()
    while true do
        Wait(5000)
        local players = GetPlayers()
        for i = 1, #players do
            local id = tonumber(players[i])
            if id then
                ServerLocations.VerifyPlayerBucket(id)
            end
        end
    end
end)
