--[[
    Server-authoritative autofarm.
    Clients may only request start/stop. Item selection, amounts, timing,
    distance checks, and inventory mutations all happen here.
]]

local ESX = exports['es_extended']:getSharedObject()
local sessions = {}       -- [src] = { farmIndex, locationIndex, nextRewardAt }
local requestTracker = {} -- [src] = { lastRequestAt, windowStart, count }
local dropCache = {}      -- [farmIndex] = { totalChance, entries }

local function DebugLog(message)
    if ConfigAutofarm.Debug then
        print(("[Autofarm] %s"):format(message))
    end
end

local function PlayerHasFarmJob(src, farm)
    if not farm or not farm.job then return true end

    local xPlayer = ESX.GetPlayerFromId(src)
    local playerJob = xPlayer and xPlayer.job and xPlayer.job.name
    if not playerJob then return false end

    if type(farm.job) == 'table' then
        for key, value in pairs(farm.job) do
            if type(key) == 'number' then
                if playerJob == value then return true end
            elseif playerJob == key and value then
                return true
            end
        end
        return false
    end

    return playerJob == farm.job
end

local function GetFarm(farmIndex)
    farmIndex = tonumber(farmIndex)
    if not farmIndex then return nil end
    return ConfigAutofarm.Farms[farmIndex], farmIndex
end

local function GetLocation(farm, locationIndex)
    locationIndex = tonumber(locationIndex)
    if not farm or not locationIndex then return nil end
    return farm.locations[locationIndex], locationIndex
end

local function BuildDropCache(farmIndex, farm)
    if not farm.drops or #farm.drops == 0 then
        dropCache[farmIndex] = nil
        return
    end

    local totalChance = 0
    local entries = {}

    for _, drop in ipairs(farm.drops) do
        local chance = math.max(tonumber(drop.chance) or 0, 0)
        if chance > 0 and type(drop.item) == "string" and drop.item ~= "" then
            totalChance = totalChance + chance
            entries[#entries + 1] = { item = drop.item, chance = chance }
        end
    end

    if totalChance <= 0 or #entries == 0 then
        dropCache[farmIndex] = nil
        return
    end

    dropCache[farmIndex] = {
        totalChance = totalChance,
        entries = entries,
    }
end

CreateThread(function()
    for farmIndex, farm in ipairs(ConfigAutofarm.Farms) do
        BuildDropCache(farmIndex, farm)
    end
end)

local function SelectFarmDrop(farmIndex, farm)
    local cache = dropCache[farmIndex]
    if not cache then
        return farm.item
    end

    local roll = math.random() * cache.totalChance
    local cumulativeChance = 0

    for _, drop in ipairs(cache.entries) do
        cumulativeChance = cumulativeChance + drop.chance
        if roll <= cumulativeChance then
            return drop.item
        end
    end

    return cache.entries[#cache.entries].item
end

local function ResolveSessionCoords(session, farm)
    if session.coords then
        return session.coords
    end

    local location = farm and GetLocation(farm, session.locationIndex)
    if not location then return nil end
    return vector3(location.x, location.y, location.z)
end

local function IsPlayerNearCoords(src, coords, farm)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    if not coords then return false end

    local playerCoords = GetEntityCoords(ped)
    local interactDistance = (farm and farm.interactionDistance) or ConfigAutofarm.Marker.interactionDistance
    local maxDistance = interactDistance + ConfigAutofarm.Security.maxDistanceGrace
    return #(playerCoords - coords) <= maxDistance
end

local function IsPlayerNearLocation(src, location, farm)
    if not location then return false end
    return IsPlayerNearCoords(src, vector3(location.x, location.y, location.z), farm)
end

local function IsRateLimited(src)
    local security = ConfigAutofarm.Security
    local now = GetGameTimer()
    local tracker = requestTracker[src]

    if not tracker then
        requestTracker[src] = { lastRequestAt = now, windowStart = now, count = 1 }
        return false
    end

    if (now - tracker.lastRequestAt) < security.requestCooldown then
        DebugLog(("rate-limit cooldown src=%s"):format(src))
        return true
    end

    if (now - tracker.windowStart) > security.requestWindow then
        tracker.windowStart = now
        tracker.count = 0
    end

    tracker.count = tracker.count + 1
    tracker.lastRequestAt = now

    if tracker.count > security.maxRequestsPerWindow then
        DebugLog(("rate-limit window src=%s count=%s"):format(src, tracker.count))
        if tracker.count >= (security.maxRequestsPerWindow + 6) then
            KeydiElectron.Flag(src, "Autofarm start exploit (spam)", "cfx-keydi-autofarm")
        end
        return true
    end

    return false
end

local function ClearSession(src)
    sessions[src] = nil
end

local function StopSession(src, reason, farmIndex)
    if not sessions[src] then return end

    ClearSession(src)
    TriggerClientEvent("cfx-keydi-autofarm:stopped", src, farmIndex or 0, reason or "stopped")
    DebugLog(("stopped src=%s reason=%s"):format(src, reason or "stopped"))
end

local function GetPlayerItemCount(src, itemName)
    return tonumber(exports.ox_inventory:Search(src, "count", itemName)) or 0
end

---Find a usable tool slot (durability > 0, or legacy time-based durability still valid).
local function GetUsableToolSlot(src, itemName)
    local slots = exports.ox_inventory:Search(src, "slots", itemName)
    if (type(slots) ~= "table" or next(slots) == nil) and itemName == "battleaxe" then
        slots = exports.ox_inventory:Search(src, "slots", "WEAPON_BATTLEAXE")
    end
    if type(slots) ~= "table" then return nil end

    local now = os.time()
    for _, slot in pairs(slots) do
        if type(slot) == "table" and slot.slot then
            local dur = slot.metadata and slot.metadata.durability
            if dur == nil then
                return slot
            end
            if type(dur) == "number" then
                if dur > 100 then
                    -- Legacy time-based expiry timestamp
                    if dur > now then
                        return slot
                    end
                elseif dur > 0 then
                    return slot
                end
            end
        end
    end

    return nil
end

---Drain tool durability by one pickup. Returns ok, broken.
local function WearTool(src, itemName)
    local slot = GetUsableToolSlot(src, itemName)
    if not slot then return false, false end

    local uses = tonumber(ConfigAutofarm.Farming.toolUses) or 800
    if uses < 1 then uses = 800 end
    local drain = 100 / uses

    local dur = slot.metadata and slot.metadata.durability

    -- Convert legacy time-based tools to percentage durability on first wear
    if type(dur) ~= "number" or dur > 100 then
        dur = 100
    end

    dur = dur - drain

    local actualItem = slot.name or itemName
    if dur <= 0 then
        exports.ox_inventory:RemoveItem(src, actualItem, 1, nil, slot.slot)
        return true, true
    end

    exports.ox_inventory:SetDurability(src, slot.slot, dur)
    return true, false
end

local function GrantReward(src, session)
    local farm, farmIndex = GetFarm(session.farmIndex)
    if not farm then
        StopSession(src, "invalid", session.farmIndex)
        return
    end

    if not PlayerHasFarmJob(src, farm) then
        StopSession(src, "job_required", farmIndex)
        return
    end

    local coords = ResolveSessionCoords(session, farm)
    if not coords then
        StopSession(src, "invalid", session.farmIndex)
        return
    end

    if not IsPlayerNearCoords(src, coords, farm) then
        StopSession(src, "distance", farmIndex)
        return
    end

    if farm.requireTool then
        local toolSlot = GetUsableToolSlot(src, farm.requireTool)
        if not toolSlot then
            ClearSession(src)
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "missing_tool", farm.requireTool)
            return
        end
    end

    local itemName = SelectFarmDrop(farmIndex, farm)
    local item = exports.ox_inventory:Items(itemName)
    if not item then
        DebugLog(("missing item '%s'"):format(itemName))
        StopSession(src, "missing_item", farmIndex)
        return
    end

    local inventory = exports.ox_inventory:GetInventory(src)
    if not inventory then
        StopSession(src, "no_inventory", farmIndex)
        return
    end

    local minAmount = farm.minAmount or ConfigAutofarm.Farming.minAmount
    local maxAmount = farm.maxAmount or ConfigAutofarm.Farming.maxAmount
    if maxAmount < minAmount then
        maxAmount = minAmount
    end
    local amount = math.random(minAmount, maxAmount)

    -- Processing steps consume an input item 1:1 with the output amount.
    local requireItem = farm.requireItem
    if requireItem then
        local have = GetPlayerItemCount(src, requireItem)
        if have < 1 then
            ClearSession(src)
            TriggerClientEvent("cfx-keydi-autofarm:missingInput", src, farmIndex, requireItem)
            return
        end
        if amount > have then
            amount = have
        end
    end

    -- VIP Harvest Perk (+5 / +10 / +15 All Grindings based on VIP tier)
    local grindBonus = 0
    pcall(function()
        if exports["kodebykarl-ui"] and exports["kodebykarl-ui"].GetVipGrindBonus then
            grindBonus = exports["kodebykarl-ui"]:GetVipGrindBonus(src) or 0
        end
    end)
    if grindBonus > 0 then
        amount = amount + grindBonus
    end

    local carryable = exports.ox_inventory:CanCarryAmount(src, itemName) or 0
    if carryable < 1 then
        ClearSession(src)
        TriggerClientEvent("cfx-keydi-autofarm:inventoryFull", src, farmIndex)
        return
    end

    if amount > carryable then
        amount = carryable
    end

    -- Advance the next reward timestamp before inventory mutations so a slow
    -- call cannot cause overlapping grants for the same session tick.
    session.nextRewardAt = GetGameTimer() + ConfigAutofarm.Farming.cycleTime

    if requireItem then
        local removed = exports.ox_inventory:RemoveItem(src, requireItem, amount)
        if not removed then
            ClearSession(src)
            TriggerClientEvent("cfx-keydi-autofarm:missingInput", src, farmIndex, requireItem)
            return
        end
    end

    local success = exports.ox_inventory:AddItem(src, itemName, amount)
    if not success then
        -- Refund consumed input if the output could not be added.
        if requireItem then
            exports.ox_inventory:AddItem(src, requireItem, amount)
        end
        ClearSession(src)
        TriggerClientEvent("cfx-keydi-autofarm:inventoryFull", src, farmIndex)
        return
    end

    if farm.requireTool then
        local worn, broken = WearTool(src, farm.requireTool)
        if not worn or broken then
            ClearSession(src)
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "missing_tool", farm.requireTool)
            TriggerClientEvent("cfx-keydi-autofarm:collected", src, farmIndex, itemName, amount)
            DebugLog(("%s processed %dx %s (tool broke)"):format(GetPlayerName(src) or src, amount, itemName))
            return
        end
    end

    TriggerClientEvent("cfx-keydi-autofarm:collected", src, farmIndex, itemName, amount)
    DebugLog(("%s processed %dx %s"):format(GetPlayerName(src) or src, amount, itemName))

    if farm.rewardCoins then
        local coinAmount = 1
        if type(farm.rewardCoins) == "table" then
            local cMin = tonumber(farm.rewardCoins.min or farm.rewardCoins[1]) or 1
            local cMax = tonumber(farm.rewardCoins.max or farm.rewardCoins[2]) or cMin
            coinAmount = math.random(cMin, cMax)
        else
            coinAmount = tonumber(farm.rewardCoins) or 1
        end

        local ok, err = pcall(function()
            if type(AddCoins) == 'function' then
                return AddCoins(src, coinAmount, farm.zone or 'Activity')
            elseif type(AddPlaytimeCoins) == 'function' then
                return AddPlaytimeCoins(src, coinAmount, farm.zone or 'Activity')
            elseif exports['kodebykarl-ui'] and exports['kodebykarl-ui'].AddCoins then
                return exports['kodebykarl-ui']:AddCoins(src, coinAmount, farm.zone or 'Activity')
            elseif exports['cfx-keydi-playtimeshop'] and exports['cfx-keydi-playtimeshop'].AddCoins then
                return exports['cfx-keydi-playtimeshop']:AddCoins(src, coinAmount, farm.zone or 'Activity')
            end
        end)
        if not ok then
            print(('[Autofarm] Error awarding coins to player %s: %s'):format(src, tostring(err)))
        end
    end
end

RegisterNetEvent("cfx-keydi-autofarm:start", function(farmIndex, locationIndex, coords)
    local src = source
    if type(src) ~= "number" or src < 1 then return end
    if IsRateLimited(src) then return end

    if ConfigServerLocations and ConfigServerLocations.CanUseFunction then
        if not (ConfigServerLocations.CanUseFunction("grind", src) or ConfigServerLocations.CanUseFunction("autofarm", src)) then
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "wrong_server")
            return
        end
    end

    local farm, resolvedFarmIndex = GetFarm(farmIndex)
    if not farm then
        DebugLog(("invalid start farm src=%s farm=%s"):format(src, tostring(farmIndex)))
        return
    end

    if not PlayerHasFarmJob(src, farm) then
        TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "job_required", type(farm.job) == "table" and "EMS" or tostring(farm.job))
        return
    end

    local sessionCoords = nil
    local resolvedLocationIndex = 0

    -- Location farms never trust client coords (Probe can send fake tables).
    if farm.targetModel then
        if type(coords) ~= "vector3" and type(coords) ~= "table" then
            DebugLog(("target farm missing coords src=%s"):format(src))
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "distance")
            return
        end

        local x = tonumber(coords.x or coords[1])
        local y = tonumber(coords.y or coords[2])
        local z = tonumber(coords.z or coords[3])
        if not x or not y or not z then
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "distance")
            return
        end

        sessionCoords = vector3(x, y, z)
        if not IsPlayerNearCoords(src, sessionCoords, farm) then
            DebugLog(("start rejected distance src=%s"):format(src))
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "distance")
            return
        end
    else
        local location
        location, resolvedLocationIndex = GetLocation(farm, locationIndex)
        if not location then
            DebugLog(("invalid start indices src=%s farm=%s loc=%s"):format(src, tostring(farmIndex), tostring(locationIndex)))
            return
        end

        if not IsPlayerNearLocation(src, location, farm) then
            DebugLog(("start rejected distance src=%s"):format(src))
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "distance")
            return
        end
    end

    local inventory = exports.ox_inventory:GetInventory(src)
    if not inventory then
        TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "no_inventory")
        return
    end

    if farm.requireItem then
        local have = GetPlayerItemCount(src, farm.requireItem)
        if have < 1 then
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "missing_input", farm.requireItem)
            return
        end
    end

    if farm.requireTool then
        local toolSlot = GetUsableToolSlot(src, farm.requireTool)
        if not toolSlot then
            TriggerClientEvent("cfx-keydi-autofarm:startDenied", src, "missing_tool", farm.requireTool)
            return
        end
    end

    -- Block start when the output item (or primary farm item) cannot be carried.
    local carryCheckItem = farm.item
    if farm.drops and farm.drops[1] and farm.drops[1].item then
        carryCheckItem = farm.drops[1].item
    end
    local carryable = exports.ox_inventory:CanCarryAmount(src, carryCheckItem) or 0
    if carryable < 1 then
        TriggerClientEvent("cfx-keydi-autofarm:inventoryFull", src, resolvedFarmIndex)
        return
    end

    sessions[src] = {
        farmIndex = resolvedFarmIndex,
        locationIndex = resolvedLocationIndex,
        coords = sessionCoords,
        nextRewardAt = GetGameTimer() + ConfigAutofarm.Farming.cycleTime,
    }

    TriggerClientEvent("cfx-keydi-autofarm:started", src, resolvedFarmIndex, resolvedLocationIndex)
    DebugLog(("started src=%s farm=%s loc=%s"):format(src, resolvedFarmIndex, resolvedLocationIndex))
end)

RegisterNetEvent("cfx-keydi-autofarm:stop", function()
    local src = source
    if type(src) ~= "number" or src < 1 then return end

    -- Stops are always accepted when a session exists so leaving a marker
    -- cannot get stuck behind the start-request cooldown.
    local session = sessions[src]
    if not session then return end

    StopSession(src, "player", session.farmIndex)
end)

-- Single lightweight scheduler owns every active farming session.
CreateThread(function()
    local interval = ConfigAutofarm.Security.schedulerInterval or 250

    while true do
        local now = GetGameTimer()

        for src, session in pairs(sessions) do
            local ped = GetPlayerPed(src)
            if not ped or ped == 0 then
                ClearSession(src)
            elseif now >= session.nextRewardAt then
                GrantReward(src, session)
            end
        end

        Wait(interval)
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    sessions[src] = nil
    requestTracker[src] = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for src in pairs(sessions) do
        TriggerClientEvent("cfx-keydi-autofarm:stopped", src, 0, "resource_stop")
    end

    sessions = {}
    requestTracker = {}
end)
