local ox_inventory = exports.ox_inventory
local inMatch = {}
local lastReviveAt = {}
local bypassTokens = {}
local bypassTokenSeq = 0

local FG_RESOURCE_CANDIDATES = { 'grimbot', 'fiveguard', 'fg', 'FiveGuard' }
local PVP_FG_PERMS = { 'BypassTeleport' }
local PVP_EAC_MODULES = { 'antiTeleport' }

local function fgResource()
    local named = GetConvar('fiveguard_resource', '')
    if named ~= '' and GetResourceState(named) == 'started' then
        return named
    end
    for i = 1, #FG_RESOURCE_CANDIDATES do
        local name = FG_RESOURCE_CANDIDATES[i]
        if GetResourceState(name) == 'started' then
            return name
        end
    end
    return nil
end

local function fgTemp(src, enable)
    if type(src) ~= 'number' or src < 1 then return end
    local resource = fgResource()
    if not resource then return end
    pcall(function()
        for i = 1, #PVP_FG_PERMS do
            exports[resource]:SetTempPermission(src, 'Client', PVP_FG_PERMS[i], enable == true, false)
        end
    end)
end

local function eacTemp(src, enable)
    if type(src) ~= 'number' or src < 1 then return end
    pcall(function()
        for i = 1, #PVP_EAC_MODULES do
            if enable then
                exports['ElectronAC']:tempWhitelistPlayer(src, PVP_EAC_MODULES[i])
            else
                exports['ElectronAC']:tempUnWhitelistPlayer(src, PVP_EAC_MODULES[i])
            end
        end
    end)
end

local function enablePvpTeleportBypass(src)
    if type(src) ~= 'number' or src < 1 then return end
    bypassTokenSeq = bypassTokenSeq + 1
    bypassTokens[src] = bypassTokenSeq
    fgTemp(src, true)
    eacTemp(src, true)
end

local function clearPvpTeleportBypass(src, delayMs)
    if type(src) ~= 'number' or src < 1 then return end
    bypassTokenSeq = bypassTokenSeq + 1
    local token = bypassTokenSeq
    bypassTokens[src] = token

    local function revoke()
        if bypassTokens[src] ~= token then return end
        bypassTokens[src] = nil
        if inMatch[src] then return end
        fgTemp(src, false)
        eacTemp(src, false)
    end

    delayMs = tonumber(delayMs) or 0
    if delayMs <= 0 then
        revoke()
        return
    end

    SetTimeout(delayMs, function()
        if not GetPlayerName(src) then
            bypassTokens[src] = nil
            return
        end
        revoke()
    end)
end

ox_inventory:RegisterStash('deathmatch-locker', 'Deathmatch Locker', 10, 100000, true)

local function CountInMatch()
    local n = 0
    for _ in pairs(inMatch) do
        n = n + 1
    end
    return n
end

local function KeepItemsList()
    local keep = Config.KeepItems
    if type(keep) == 'table' and keep[1] then
        return keep
    end
    return false
end

local function RemoveLoadoutItems(src)
    local items = Config.LoadoutItems
    if type(items) ~= 'table' then
        items = { Config.WeaponName, Config.AmmoName }
    end
    for i = 1, #items do
        local name = items[i]
        if type(name) == 'string' and name ~= '' then
            local count = ox_inventory:GetItemCount(src, name) or 0
            if count > 0 then
                ox_inventory:RemoveItem(src, name, count)
            end
        end
    end
    -- Equipped weapon slot (not always in items until disarmed)
end

local function ClearPvpInventory(src)
    -- Disarm first so the equipped arena gun is back in a slot, then wipe.
    pcall(function()
        TriggerClientEvent('ox_inventory:disarm', src, true)
    end)
    local keep = KeepItemsList()
    ox_inventory:ClearInventory(src, keep)
    RemoveLoadoutItems(src)
end

local function Notify(src, msg, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'PvP',
        description = msg,
        type = nType or 'inform',
        position = 'center-left',
    })
end

local function LeaveMatch(src, notifyClient)
    local data = inMatch[src]
    if not data then return end

    inMatch[src] = nil
    ClearPvpInventory(src)

    local state = Player(src).state
    if state then
        state:set('inPvp', false, true)
        state:set('isInPvp', false, true)
    end

    SetPlayerRoutingBucket(src, data.bucket or 0)
    lastReviveAt[src] = nil

    if notifyClient then
        TriggerClientEvent('kodebykarl-pvp:endMatch', src)
        -- Leave teleport happens on the client after endMatch.
        clearPvpTeleportBypass(src, 8000)
    else
        clearPvpTeleportBypass(src, 0)
    end
end

RegisterNetEvent('kodebykarl-pvp:requestJoin', function()
    local src = source
    if inMatch[src] then return end

    local maxPlayers = tonumber(Config.MaxPlayers) or 32
    if CountInMatch() >= maxPlayers then
        TriggerClientEvent('kodebykarl-pvp:joinDenied', src, 'Deathmatch is full.')
        return
    end

    inMatch[src] = {
        bucket = GetPlayerRoutingBucket(src),
    }

    local state = Player(src).state
    if state then
        state:set('inPvp', true, true)
        state:set('isInPvp', true, true)
    end

    enablePvpTeleportBypass(src)
    SetPlayerRoutingBucket(src, Config.Bucket or 50)
    TriggerClientEvent('kodebykarl-pvp:startMatch', src)
end)

RegisterNetEvent('kodebykarl-pvp:requestLeave', function()
    local src = source
    local state = Player(src).state
    if state and (state.dead or state.isReviving) then
        pcall(function()
            exports['kodebykarl-ambulance']:AdminClearDeath(src)
        end)
        TriggerClientEvent('cfx-keydi-ambulance:revive', src)
        TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', src)
        TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', src)
        if GetResourceState('kodebykarl-logs') == 'started' then
            pcall(function()
                exports['kodebykarl-logs']:LogRevive({
                    src = src,
                    method = 'pvp',
                    revivedByName = 'PvP Leave',
                })
            end)
        end
    end
    LeaveMatch(src, true)
end)

RegisterNetEvent('kodebykarl-pvp:requestRevive', function()
    local src = source
    if not inMatch[src] then return end

    local now = GetGameTimer()
    if lastReviveAt[src] and (now - lastReviveAt[src]) < 4000 then
        return
    end
    lastReviveAt[src] = now

    pcall(function()
        exports['kodebykarl-ambulance']:AdminClearDeath(src)
    end)
    -- Resurrect at arena spawn so they never stand up at the kill spot first.
    TriggerClientEvent('cfx-keydi-ambulance:revive', src, Config.Enter)
    TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', src)
    TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', src)
    if GetResourceState('kodebykarl-logs') == 'started' then
        pcall(function()
            exports['kodebykarl-logs']:LogRevive({
                src = src,
                method = 'pvp',
                revivedByName = 'PvP Arena',
            })
        end)
    end
end)

local function GivePvpLoadout(src)
    ClearPvpInventory(src)
    if ox_inventory:CanCarryItem(src, Config.WeaponName, 1) then
        ox_inventory:AddItem(src, Config.WeaponName, 1)
    end
    if ox_inventory:CanCarryItem(src, Config.AmmoName, Config.AmmoAmmount) then
        ox_inventory:AddItem(src, Config.AmmoName, Config.AmmoAmmount)
    end
end

RegisterNetEvent('kodebykarl-pvp:giveLoadout', function()
    local src = source
    if not inMatch[src] then return end
    GivePvpLoadout(src)
end)

RegisterNetEvent('kodebykarl-pvp:AddItem', function(item, quantity, itemLabel)
    local src = source
    if not inMatch[src] then return end

    if item ~= Config.WeaponName and item ~= Config.AmmoName then return end
    if item == Config.WeaponName and quantity > 1 then return end
    if item == Config.AmmoName and quantity > Config.AmmoAmmount then return end

    if ox_inventory:CanCarryItem(src, item, quantity) then
        ox_inventory:AddItem(src, item, quantity)
        Notify(src, ('You received %dx %s'):format(quantity, itemLabel or item), 'success')
    else
        Notify(src, 'Your inventory is full!', 'error')
    end
end)

RegisterNetEvent('kodebykarl-pvp:resetItem', function()
    local src = source
    if not inMatch[src] then return end
    ClearPvpInventory(src)
end)

lib.callback.register('kodebykarl-pvp:status', function(source)
    return {
        ok = true,
        inPvp = inMatch[source] ~= nil,
        players = CountInMatch(),
        maxPlayers = tonumber(Config.MaxPlayers) or 32,
        name = Config.ArenaName or 'Deathmatch Arena',
        tags = Config.ArenaTags or {},
    }
end)

AddEventHandler('playerDropped', function()
    LeaveMatch(source, false)
end)

exports('playingPvPDeathmatch', function(src)
    src = src or source
    return inMatch[src] ~= nil
end)

exports('IsInMatch', function(src)
    return inMatch[src] ~= nil
end)
