--[[
  House robbery — all rewards / item changes are server-authoritative.
  Clients only request actions; every handler re-validates source, distance, and state.
]]

local HouseRob = {
    inside = {}, -- [src] = houseKey
    lockpickBusy = {}, -- [src] = true
    searchBusy = {}, -- [src] = true
    soundAlertAt = {}, -- [src] = gameTimer
    paletoCooldownUntil = 0, -- os.time() unix; shared by all Paleto houses
}

local function getHouse(house)
    return house and Config.HouseRob.Houses[house] or nil
end

local function isPaletoHouse(house)
    if type(house) ~= 'string' or house == '' then return false end
    local cfg = Config.HouseRob.PaletoGlobalCooldown
    local prefixes = cfg and cfg.prefixes or { 'paleto', 'emhouseRobbery' }
    local key = house:lower()
    for i = 1, #prefixes do
        local prefix = tostring(prefixes[i] or ''):lower()
        if prefix ~= '' and key:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function formatCooldownLeft(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return ('%dh %dm'):format(hours, minutes)
    end
    if minutes > 0 then
        return ('%dm'):format(minutes)
    end
    return ('%ds'):format(math.max(1, seconds))
end

--- Returns remaining seconds (0 if ready). Only applies to Paleto houses when enabled.
local function getPaletoCooldownRemaining(house)
    local cfg = Config.HouseRob.PaletoGlobalCooldown
    if not cfg or cfg.enabled == false then return 0 end
    if not isPaletoHouse(house) then return 0 end
    local left = (HouseRob.paletoCooldownUntil or 0) - os.time()
    return left > 0 and left or 0
end

local function startPaletoGlobalCooldown(house)
    local cfg = Config.HouseRob.PaletoGlobalCooldown
    if not cfg or cfg.enabled == false then return end
    if not isPaletoHouse(house) then return end
    local duration = math.floor(tonumber(cfg.seconds) or (3 * 60 * 60))
    if duration < 1 then return end
    HouseRob.paletoCooldownUntil = os.time() + duration
    TriggerClientEvent('cfx-cs-robbery:houserob:client:paletoCooldown', -1, HouseRob.paletoCooldownUntil)
    print(('[houserob] Paleto global cooldown started (%ss) after %s'):format(duration, tostring(house)))
end

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function nearHouseDoor(src, house, maxDist)
    local h = getHouse(house)
    if not h or not h.coords then return false end
    local pos = playerCoords(src)
    if not pos then return false end
    local door = vec3(h.coords.x, h.coords.y, h.coords.z)
    return #(pos - door) <= (maxDist or 3.0)
end

local function isPlayerPolice(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then return false end
    local name = tostring(xPlayer.job.name):lower()
    return name == 'police' or name == 'sheriff'
end

--- Count on-duty police + sheriff (job name must be the on-duty job, not offpolice/offsheriff).
local function countOnDutyLeo()
    local jobs = Config.HouseRob.RequiredLeoJobs or { 'police', 'sheriff' }
    local total = 0
    local seen = {}

    for i = 1, #jobs do
        local jobName = tostring(jobs[i] or ''):lower()
        if jobName ~= '' and not seen[jobName] then
            seen[jobName] = true
            local players = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers('job', jobName) or {}
            total = total + #players
        end
    end

    return total
end

local function hasRequiredLeo()
    local required = math.floor(tonumber(Config.HouseRob.RequiredLeo) or 0)
    if required < 1 then
        return true, 0, 0
    end
    local online = countOnDutyLeo()
    return online >= required, online, required
end

local function CanUseHouseRob(src)
    if isPlayerPolice(src) then
        return true
    end
    if GetResourceState('kodebykarl-ui') ~= 'started' then
        return true
    end
    local ok, allowed = pcall(function()
        local exp = exports['kodebykarl-ui']
        return exp:PlayerHasFunction(src, 'illegal')
            or exp:PlayerHasFunction(src, 'houserob')
            or exp:PlayerHasFunction(src, 'housing')
            or exp:PlayerHasFunction(src, 'main')
    end)
    if not ok then
        return true
    end
    return allowed == true
end

local function NotifyWrongHouseRegion(src)
    local msg = 'House robbery is only available on Region 1. Open Control Center (F5) → Regions.'
    if GetResourceState('kodebykarl-ui') == 'started' then
        local ok, text = pcall(function()
            return exports['kodebykarl-ui']:WrongServerMessage('illegal')
        end)
        if ok and type(text) == 'string' and text ~= '' then
            msg = text
        end
    end
    TriggerClientEvent('esx:Notify', src, 'House Robbery', msg, 'error', 5000)
end

local function setInside(src, house)
    HouseRob.inside[src] = house
end

local function clearInside(src)
    HouseRob.inside[src] = nil
end

exports('IsInsideHouse', function(src)
    src = tonumber(src)
    return src ~= nil and HouseRob.inside[src] ~= nil
end)

local function readableHouseArea(house)
    local key = tostring(house or '')
    local area = key:gsub('%d+$', ''):gsub('_', ' ')
    if area == '' then return 'Unknown area' end
    return area:sub(1, 1):upper() .. area:sub(2)
end

local function sanitizeStreet(label)
    if type(label) ~= 'string' then return nil end
    local s = label:gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then return nil end
    return s:sub(1, 120)
end

local function houseAlertJobs(house, coords)
    local soundCfg = Config.HouseRob.SoundDetection or {}
    local jobs = {}
    local seen = {}

    local function addJobs(list)
        if type(list) ~= 'table' then return end
        for i = 1, #list do
            local job = list[i]
            if type(job) == 'string' and job ~= '' and not seen[job] then
                seen[job] = true
                jobs[#jobs + 1] = job
            end
        end
    end

    -- Always notify police + sheriff unless alertBothDepartments is explicitly false.
    if soundCfg.alertBothDepartments == false then
        local houseKey = type(house) == 'string' and house:lower() or ''
        local y = coords and (coords.y or coords['y'])
        local sheriffMinY = tonumber(soundCfg.sheriffMinY) or 2500.0
        if houseKey:find('paleto', 1, true) or (type(y) == 'number' and y >= sheriffMinY) then
            addJobs(soundCfg.sheriffJobs or { 'sheriff' })
        else
            addJobs(soundCfg.alertJobs or { 'police' })
        end
    else
        addJobs(soundCfg.alertJobs or { 'police' })
        addJobs(soundCfg.sheriffJobs or { 'sheriff' })
    end

    if #jobs == 0 then
        jobs = { 'police', 'sheriff' }
    end
    return jobs
end

local function resolveProjectModel()
    if GetResourceState('kodebykarl-projectcars') == 'started' then
        local ok, model = pcall(function()
            return exports['kodebykarl-projectcars']:PickRandomProjectModel()
        end)
        if ok and type(model) == 'string' and model ~= '' then
            return model
        end
    end
    return 'ody18'
end

local function buildProjectMetadata(itemName, model)
    model = tostring(model or ''):lower():gsub('%s+', '')
    if model == '' then
        model = resolveProjectModel()
    end
    if GetResourceState('kodebykarl-projectcars') == 'started' then
        local ok, meta = pcall(function()
            return exports['kodebykarl-projectcars']:BuildPartMetadata(itemName, model)
        end)
        if ok and type(meta) == 'table' then
            return meta, model
        end
    end
    return {
        model = model,
        vehicle = model:upper(),
        label = itemName,
        description = ('Fits %s project cars only.'):format(model:upper()),
    }, model
end

local function giveTaggedProjectItem(src, itemName, count, model)
    count = math.floor(tonumber(count) or 1)
    if count < 1 or not itemName then return false, nil, itemName end
    model = model or resolveProjectModel()
    local resolved = itemName
    if GetResourceState('kodebykarl-projectcars') == 'started' then
        local okResolve, uniqueName = pcall(function()
            return exports['kodebykarl-projectcars']:ResolvePartItem(itemName, model)
        end)
        if okResolve and type(uniqueName) == 'string' and uniqueName ~= '' then
            resolved = uniqueName
        end
        local ok, given = pcall(function()
            return exports['kodebykarl-projectcars']:GivePart(src, itemName, count, model)
        end)
        if ok and given then
            return true, model, resolved
        end
    end
    local meta = buildProjectMetadata(resolved, model)
    return ox_inventory:AddItem(src, resolved, count, meta) and true or false, model, resolved
end

local function shuffleCopy(list)
    local copy = {}
    for i = 1, #list do
        copy[i] = list[i]
    end
    for i = #copy, 2, -1 do
        local j = math.random(i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    return copy
end

local function itemLabel(itemName)
    return (ox_items[itemName] and ox_items[itemName].label) or itemName
end

--- Build the full reward pile for one house open, then split across furniture.
local function buildHouseLootPile()
    local rewards = Config.HouseRob.Rewards
    local pile = {}
    if not rewards then return pile end

    local dirty = rewards.dirtyMoney
    if dirty and dirty.item and (tonumber(dirty.amount) or 0) > 0 then
        pile[#pile + 1] = {
            kind = 'item',
            item = dirty.item,
            amount = math.floor(tonumber(dirty.amount) or 0),
            summary = ('$%s dirty money'):format(dirty.amount),
        }
    end

    local tools = rewards.heistTools
    if type(tools) == 'table' then
        for i = 1, #tools do
            local entry = tools[i]
            local amount = entry and math.floor(tonumber(entry.amount) or 0) or 0
            if entry and entry.item and amount > 0 then
                pile[#pile + 1] = {
                    kind = 'item',
                    item = entry.item,
                    amount = amount,
                    summary = ('%sx %s'):format(amount, itemLabel(entry.item)),
                }
            end
        end
    end

    local ammoCraft = rewards.ammoCraft
    if type(ammoCraft) == 'table' then
        for i = 1, #ammoCraft do
            local entry = ammoCraft[i]
            local amount = entry and math.floor(tonumber(entry.amount) or 0) or 0
            if entry and entry.item and amount > 0 then
                pile[#pile + 1] = {
                    kind = 'item',
                    item = entry.item,
                    amount = amount,
                    summary = ('%sx %s'):format(amount, itemLabel(entry.item)),
                }
            end
        end
    end

    local gunBp = rewards.gunBlueprints
    local gunPool = gunBp and gunBp.pool
    if type(gunPool) == 'table' and #gunPool > 0 then
        local gunCount = math.max(1, math.floor(tonumber(gunBp.amount) or 5))
        local gunItem = gunPool[math.random(1, #gunPool)]
        if gunItem and gunCount > 0 then
            pile[#pile + 1] = {
                kind = 'item',
                item = gunItem,
                amount = gunCount,
                summary = ('%sx %s'):format(gunCount, itemLabel(gunItem)),
            }
        end
    end

    local recycling = rewards.recycling
    if recycling and recycling.item then
        local recMin = math.floor(tonumber(recycling.min) or 1)
        local recMax = math.floor(tonumber(recycling.max) or recMin)
        if recMax < recMin then recMax = recMin end
        local recAmount = math.random(recMin, recMax)
        if recAmount > 0 then
            pile[#pile + 1] = {
                kind = 'item',
                item = recycling.item,
                amount = recAmount,
                summary = ('%sx recycling materials'):format(recAmount),
            }
        end
    end

    local parts = rewards.projectParts
    local pool = parts and parts.pool
    if type(pool) == 'table' and #pool > 0 then
        local rollsCfg = parts.rolls or {}
        local rollMin = math.max(1, math.floor(tonumber(rollsCfg.min) or 1))
        local rollMax = math.max(rollMin, math.floor(tonumber(rollsCfg.max) or rollMin))
        local rolls = math.min(#pool, math.random(rollMin, rollMax))
        local shuffled = shuffleCopy(pool)
        for i = 1, rolls do
            local entry = shuffled[i]
            if entry and entry.item then
                local pMin = math.floor(tonumber(entry.min) or 1)
                local pMax = math.floor(tonumber(entry.max) or pMin)
                if pMax < pMin then pMax = pMin end
                local pCount = math.random(pMin, pMax)
                local partModel = resolveProjectModel()
                pile[#pile + 1] = {
                    kind = 'project',
                    item = entry.item,
                    amount = pCount,
                    model = partModel,
                    summary = ('%sx %s'):format(pCount, itemLabel(entry.item)),
                }
            end
        end
    end

    local bp = rewards.blueprints
    if bp and bp.item then
        local bpMin = math.floor(tonumber(bp.min) or 5)
        local bpMax = math.floor(tonumber(bp.max) or 10)
        if bpMax < bpMin then bpMax = bpMin end
        local bpCount = math.random(bpMin, bpMax)
        local bpModel = resolveProjectModel()
        pile[#pile + 1] = {
            kind = 'project',
            item = bp.item,
            amount = bpCount,
            model = bpModel,
            summary = ('%sx %s (%s)'):format(bpCount, itemLabel(bp.item), tostring(bpModel):upper()),
        }
    end

    return pile
end

local function assignLootToFurniture(house)
    local h = getHouse(house)
    if not h or not h.furniture then return end

    h.furnitureLoot = {}
    local furnitureKeys = {}
    for cabinId in pairs(h.furniture) do
        furnitureKeys[#furnitureKeys + 1] = cabinId
        h.furnitureLoot[cabinId] = {}
    end

    if #furnitureKeys == 0 then return end

    table.sort(furnitureKeys, function(a, b)
        return tonumber(a) < tonumber(b)
    end)

    local pile = shuffleCopy(buildHouseLootPile())
    if #pile == 0 then return end

    -- Round-robin so loot is spread across furniture (not dumped on the first search).
    local slot = 1
    for i = 1, #pile do
        local cabinId = furnitureKeys[slot]
        local bag = h.furnitureLoot[cabinId]
        bag[#bag + 1] = pile[i]
        slot = slot + 1
        if slot > #furnitureKeys then
            slot = 1
        end
    end
end

local function alertHouseRobbery(src, house, reason, streetLabel)
    local h = getHouse(house)
    if not h or not h.coords then return end

    local chance = Config.HouseRob.ChanceToAlertPolice or 100
    if math.random(1, 100) > chance then return end

    local now = GetGameTimer()
    local cooldownKey = tostring(src) .. ':' .. tostring(house) .. ':' .. tostring(reason or 'noise')
    if HouseRob.soundAlertAt[cooldownKey] and (now - HouseRob.soundAlertAt[cooldownKey]) < 30000 then
        return
    end
    HouseRob.soundAlertAt[cooldownKey] = now

    local coords = h.coords
    local jobs = houseAlertJobs(house, coords)
    local street = sanitizeStreet(streetLabel)
    local area = readableHouseArea(house)
    local location = street or area
    local msg
    if reason == 'break-in' then
        msg = ('10-90 House burglary in progress at %s'):format(location)
    elseif reason == 'gunfire' then
        msg = ('10-71 Shots fired during a house burglary at %s'):format(location)
    else
        msg = ('10-90 House burglary — neighbors reported noise at %s'):format(location)
    end

    if ESX.SendDispatch then
        ESX.SendDispatch(jobs, msg, 14000)
    end

    for i = 1, #jobs do
        local players = ESX.GetExtendedPlayers('job', jobs[i])
        for j = 1, #players do
            local leoSrc = players[j].source
            if leoSrc ~= src then
                TriggerClientEvent('cfx-cs-robbery:houserob:client:policeAlert', leoSrc, {
                    house = house,
                    coords = { x = coords.x, y = coords.y, z = coords.z },
                    label = 'House Robbery — ' .. location,
                    message = msg .. ' — Use /hrob at the door to enter.',
                    sprite = 411,
                    color = 1,
                    scale = 1.1,
                    radius = 55.0,
                    time = 180000,
                    notifyDuration = 14000,
                })
            end
        end
    end
end

local function ResetHouseStateTimer(house)
    CreateThread(function()
        Wait(Config.HouseRob.TimeToCloseDoors * 60000)
        local h = getHouse(house)
        if not h then return end
        h.opened = false
        h.rewardClaimed = false
        h.furnitureLoot = nil
        local furnitureData = h.furniture
        for i = 1, #furnitureData do
            furnitureData[i].searched = false
            furnitureData[i].isBusy = false
        end
        TriggerClientEvent('cfx-cs-robbery:houserob:client:ResetHouseState', -1, house)
    end)
end

lib.callback.register('cfx-cs-robbery:houserob:server:GetHouseConfig', function(_)
    return Config.HouseRob.Houses
end)

lib.callback.register('cfx-cs-robbery:houserob:server:getPaletoCooldown', function(_, house)
    local remaining = getPaletoCooldownRemaining(house)
    return {
        remaining = remaining,
        untilAt = HouseRob.paletoCooldownUntil or 0,
        isPaleto = isPaletoHouse(house),
    }
end)

lib.callback.register('cfx-cs-robbery:houserob:server:canStartRobbery', function(_)
    local ok, online, required = hasRequiredLeo()
    return {
        allowed = ok,
        online = online,
        required = required,
    }
end)

--- Boss/police enter or re-enter an already opened house
RegisterNetEvent('cfx-cs-robbery:houserob:server:enterHouse', function(house)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local h = getHouse(house)
    if not xPlayer or not h then return end
    if not CanUseHouseRob(src) then
        return NotifyWrongHouseRegion(src)
    end

    local leo = isPlayerPolice(src)
    local maxDist = leo and (tonumber(Config.HouseRob.LeoEnterDistance) or 50.0) or 3.5
    if not nearHouseDoor(src, house, maxDist) then
        if leo then
            TriggerClientEvent('esx:Notify', src, 'House Robbery', 'Get closer to the house door, then use /hrob.', 'error', 5000)
        end
        return
    end

    -- Civilians: already-open only. LEO: ongoing robbery only (use /hrob or Enter).
    if not h.opened then
        return
    end

    setInside(src, house)
    SetPlayerRoutingBucket(src, h.routingBucket or 0)
    if leo and xPlayer then
        lib.logger(src, 'robbery_houserob', xPlayer.name .. ' [' .. src .. '] police-entered house ' .. house)
    end
    TriggerClientEvent('cfx-cs-robbery:houserob:client:enterHouse', src, house)
end)

--- Police / Sheriff: enter nearest (or dispatch) ongoing house robbery
lib.callback.register('cfx-cs-robbery:houserob:server:getOpenedHouses', function(src)
    if not isPlayerPolice(src) then return {} end
    local list = {}
    for key, h in pairs(Config.HouseRob.Houses or {}) do
        if h and h.opened and h.coords then
            list[#list + 1] = {
                house = key,
                x = h.coords.x,
                y = h.coords.y,
                z = h.coords.z,
            }
        end
    end
    return list
end)

RegisterNetEvent('cfx-cs-robbery:houserob:server:leoEnterHouse', function(house)
    local src = source
    if not isPlayerPolice(src) then
        TriggerClientEvent('esx:Notify', src, 'House Robbery', 'Police / Sheriff only.', 'error', 5000)
        return
    end
    local h = getHouse(house)
    if not h then
        TriggerClientEvent('esx:Notify', src, 'House Robbery', 'Invalid house.', 'error', 5000)
        return
    end
    if not h.opened then
        TriggerClientEvent('esx:Notify', src, 'House Robbery', 'That house robbery is no longer active.', 'error', 5000)
        return
    end

    local maxDist = tonumber(Config.HouseRob.LeoEnterDistance) or 50.0
    if not nearHouseDoor(src, house, maxDist) then
        TriggerClientEvent('esx:Notify', src, 'House Robbery', 'Get closer to the house door, then use /hrob.', 'error', 5000)
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    setInside(src, house)
    SetPlayerRoutingBucket(src, h.routingBucket or 0)
    if xPlayer then
        lib.logger(src, 'robbery_houserob', xPlayer.name .. ' [' .. src .. '] /hrob entered house ' .. house)
    end
    TriggerClientEvent('esx:Notify', src, 'House Robbery', 'Entering ongoing house robbery...', 'police', 4000)
    TriggerClientEvent('cfx-cs-robbery:houserob:client:enterHouse', src, house)
end)

RegisterNetEvent('cfx-cs-robbery:houserob:server:finishLockpick', function(house, success, usingAdvanced, streetLabel)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local h = getHouse(house)
    if not xPlayer or not h then return end
    if not CanUseHouseRob(src) then
        HouseRob.lockpickBusy[src] = nil
        return NotifyWrongHouseRegion(src)
    end
    if HouseRob.lockpickBusy[src] then return end
    if h.opened then return end
    if not nearHouseDoor(src, house, 3.5) then return end
    if isPlayerPolice(src) then return end

    local leoOk, leoOnline, leoRequired = hasRequiredLeo()
    if not leoOk then
        HouseRob.lockpickBusy[src] = nil
        TriggerClientEvent('esx:Notify', src, 'House Robbery',
            ('Need %s on-duty Police/Sheriff to start a house robbery. Currently online: %s.'):format(leoRequired, leoOnline),
            'error', 7000)
        return
    end

    local cooldownLeft = getPaletoCooldownRemaining(house)
    if cooldownLeft > 0 then
        TriggerClientEvent('esx:Notify', src, 'House Robbery',
            ('Paleto houses are on cooldown. Try again in %s.'):format(formatCooldownLeft(cooldownLeft)),
            'error', 7000)
        return
    end

    HouseRob.lockpickBusy[src] = true

    local itemName = usingAdvanced and 'advancedlockpick' or 'lockpick'
    local count = ox_inventory:GetItemCount(src, itemName) or 0
    if count < 1 then
        HouseRob.lockpickBusy[src] = nil
        TriggerClientEvent('esx:Notify', src, 'House Robbery', 'You need a lockpick.', 'error', 5000)
        return
    end

    success = success == true

    if not success then
        local breakChance = usingAdvanced and 25 or 50
        if math.random(1, 100) <= breakChance then
            ox_inventory:RemoveItem(src, itemName, 1)
            TriggerClientEvent('esx:Notify', src, 'House Robbery', 'The lockpick bent and broke...', 'error', 5000)
        else
            TriggerClientEvent('esx:Notify', src, 'House Robbery', 'Failed to pick the lock.', 'error', 5000)
        end
        HouseRob.lockpickBusy[src] = nil
        return
    end

    -- Re-check after minigame (another player may have started the global cooldown)
    cooldownLeft = getPaletoCooldownRemaining(house)
    if cooldownLeft > 0 then
        HouseRob.lockpickBusy[src] = nil
        TriggerClientEvent('esx:Notify', src, 'House Robbery',
            ('Paleto houses are on cooldown. Try again in %s.'):format(formatCooldownLeft(cooldownLeft)),
            'error', 7000)
        return
    end

    leoOk, leoOnline, leoRequired = hasRequiredLeo()
    if not leoOk then
        HouseRob.lockpickBusy[src] = nil
        TriggerClientEvent('esx:Notify', src, 'House Robbery',
            ('Need %s on-duty Police/Sheriff to start a house robbery. Currently online: %s.'):format(leoRequired, leoOnline),
            'error', 7000)
        return
    end

    -- Successful first open
    ResetHouseStateTimer(house)
    h.opened = true
    h.rewardClaimed = false
    assignLootToFurniture(house)
    startPaletoGlobalCooldown(house)
    TriggerClientEvent('cfx-cs-robbery:houserob:client:setHouseState', -1, house, true)
    lib.logger(src, 'robbery_houserob', xPlayer.name .. ' [' .. src .. '] started house robbery at ' .. house)

    setInside(src, house)
    SetPlayerRoutingBucket(src, h.routingBucket or 0)
    TriggerClientEvent('esx:Notify', src, 'House Robbery', 'Lock picked successfully!', 'success', 5000)
    TriggerClientEvent('cfx-cs-robbery:houserob:client:enterHouse', src, house)

    alertHouseRobbery(src, house, 'break-in', streetLabel)

    HouseRob.lockpickBusy[src] = nil
end)

RegisterNetEvent('cfx-cs-robbery:houserob:server:SetBusyState', function(cabin, house, bool)
    local src = source
    local h = getHouse(house)
    if not h or not h.furniture or not h.furniture[cabin] then return end
    if HouseRob.inside[src] ~= house then return end
    h.furniture[cabin].isBusy = bool and true or false
    TriggerClientEvent('cfx-cs-robbery:houserob:client:SetBusyState', -1, cabin, house, h.furniture[cabin].isBusy)
end)

RegisterNetEvent('cfx-cs-robbery:houserob:server:searchFurniture', function(cabin, house)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local h = getHouse(house)
    if not xPlayer or not h then return end
    if HouseRob.inside[src] ~= house then return end
    if HouseRob.searchBusy[src] then return end
    if not cabin or not h.furniture[cabin] then return end
    if h.furniture[cabin].searched then return end
    if not h.opened then return end

    -- Must be in the house routing bucket
    if GetPlayerRoutingBucket(src) ~= (h.routingBucket or 0) then return end

    HouseRob.searchBusy[src] = true

    -- Mark searched first to prevent double-claim races
    h.furniture[cabin].searched = true
    h.furniture[cabin].isBusy = false
    TriggerClientEvent('cfx-cs-robbery:houserob:client:setCabinState', -1, house, cabin, true)
    TriggerClientEvent('cfx-cs-robbery:houserob:client:SetBusyState', -1, cabin, house, false)

    local bag = h.furnitureLoot and h.furnitureLoot[cabin] or nil
    h.furnitureLoot = h.furnitureLoot or {}
    h.furnitureLoot[cabin] = nil

    local foundBits = {}
    if type(bag) == 'table' then
        for i = 1, #bag do
            local entry = bag[i]
            if entry and entry.item and (tonumber(entry.amount) or 0) > 0 then
                local amount = math.floor(tonumber(entry.amount) or 0)
                if entry.kind == 'project' then
                    local given, givenModel, givenItem = giveTaggedProjectItem(src, entry.item, amount, entry.model)
                    if given then
                        foundBits[#foundBits + 1] = entry.summary
                            or ('%sx %s'):format(amount, itemLabel(givenItem or entry.item))
                        lib.logger(src, 'robbery_houserob', xPlayer.name .. ' received ' .. amount .. 'x ' .. itemLabel(givenItem or entry.item) .. ' [' .. tostring(givenModel or entry.model) .. '] from house robbery [' .. house .. '] cabin ' .. tostring(cabin))
                    end
                else
                    ox_inventory:AddItem(src, entry.item, amount)
                    foundBits[#foundBits + 1] = entry.summary
                        or ('%sx %s'):format(amount, itemLabel(entry.item))
                    lib.logger(src, 'robbery_houserob', xPlayer.name .. ' received ' .. amount .. 'x ' .. itemLabel(entry.item) .. ' from house robbery [' .. house .. '] cabin ' .. tostring(cabin))
                end
            end
        end
    end

    local summary = #foundBits > 0 and table.concat(foundBits, ', ') or 'nothing'
    TriggerClientEvent('esx:Notify', src, 'House Robbery', ('Found %s.'):format(summary), #foundBits > 0 and 'success' or 'inform', 6000)

    HouseRob.searchBusy[src] = nil
end)

--- Exit / bucket reset — only 0 or this house's bucket
RegisterNetEvent('cfx-cs-robbery:houserob:setRoutingBucket', function(bucket)
    local src = source
    bucket = tonumber(bucket)
    if bucket == nil then return end

    if bucket == 0 then
        clearInside(src)
        if GetResourceState('kodebykarl-ui') == 'started' then
            local restored = false
            pcall(function()
                restored = exports['kodebykarl-ui']:RestorePlayerBucket(src, { force = true }) == true
            end)
            if not restored then
                SetPlayerRoutingBucket(src, 0)
            end
        else
            SetPlayerRoutingBucket(src, 0)
        end
        return
    end

    -- Only allow the routing bucket of a house the player is allowed to be in
    local house = HouseRob.inside[src]
    local h = house and getHouse(house) or nil
    if h and tonumber(h.routingBucket) == bucket then
        SetPlayerRoutingBucket(src, bucket)
        return
    end

    -- Reject arbitrary bucket hopping
end)

RegisterNetEvent('cfx-cs-robbery:houserob:server:leaveHouse', function(house)
    local src = source
    if house and HouseRob.inside[src] == house then
        clearInside(src)
    elseif not house then
        clearInside(src)
    end
    if GetResourceState('kodebykarl-ui') == 'started' then
        local restored = false
        pcall(function()
            restored = exports['kodebykarl-ui']:RestorePlayerBucket(src, { force = true }) == true
        end)
        if not restored then
            SetPlayerRoutingBucket(src, 0)
        end
    else
        SetPlayerRoutingBucket(src, 0)
    end
end)

RegisterNetEvent('cfx-cs-robbery:houserob:server:soundAlert', function(house, streetLabel, reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local h = getHouse(house)
    if not xPlayer or not h then return end
    if HouseRob.inside[src] ~= house then return end

    local kind = reason == 'gunfire' and 'gunfire' or 'noise'
    alertHouseRobbery(src, house, kind, streetLabel)

    lib.logger(src, 'robbery_houserob', xPlayer.name .. ' [' .. src .. '] triggered sound alert at house ' .. house)
end)

AddEventHandler('playerDropped', function()
    local src = source
    clearInside(src)
    HouseRob.lockpickBusy[src] = nil
    HouseRob.searchBusy[src] = nil
    HouseRob.soundAlertAt[src] = nil
end)
