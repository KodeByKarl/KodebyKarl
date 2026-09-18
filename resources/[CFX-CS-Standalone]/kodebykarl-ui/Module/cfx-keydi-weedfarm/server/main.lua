ESX = ESX or exports["es_extended"]:getSharedObject()

local plantCooldowns = {}
-- Per-player collect cooldown (allows multiple players to use the same spot at once)
local collectCooldowns = {} -- [src] = unix expiry
local activeHarvesters = {}
local activeCollectors = {}
local activeProcessors = {}
local activeMethHarvesters = {}
local activeMethProcessors = {}

local function GetItemCount(src, item)
    if item == 'black_money' then
        local oxCount = 0
        if GetResourceState('ox_inventory') == 'started' then
            pcall(function()
                oxCount = exports.ox_inventory:GetItemCount(src, 'black_money') or 0
            end)
        end
        if type(oxCount) == 'number' and oxCount > 0 then return oxCount end
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.getAccount then
            local acc = xPlayer.getAccount('black_money')
            if acc and acc.money then return acc.money end
        end
        return 0
    end
    if item == 'paper_bags' then
        if GetResourceState('ox_inventory') ~= 'started' then return 0 end
        local count1 = 0
        local count2 = 0
        pcall(function() count1 = exports.ox_inventory:GetItemCount(src, 'paper_bags') or 0 end)
        pcall(function() count2 = exports.ox_inventory:GetItemCount(src, 'paperbag') or 0 end)
        return (type(count1) == 'number' and count1 or 0) + (type(count2) == 'number' and count2 or 0)
    end
    if GetResourceState('ox_inventory') ~= 'started' then return 0 end
    local ok, count = pcall(function()
        return exports.ox_inventory:GetItemCount(src, item)
    end)
    if ok and type(count) == 'number' then return count end
    return 0
end

local function RemoveItem(src, item, amount)
    if item == 'black_money' then
        if GetResourceState('ox_inventory') == 'started' then
            local ok, res = pcall(function()
                return exports.ox_inventory:RemoveItem(src, 'black_money', amount)
            end)
            if ok and res then return true end
        end
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.getAccount then
            local acc = xPlayer.getAccount('black_money')
            if acc and acc.money and acc.money >= amount then
                xPlayer.removeAccountMoney('black_money', amount)
                return true
            end
        end
        return false
    end
    if item == 'paper_bags' then
        if GetResourceState('ox_inventory') ~= 'started' then return false end
        local count1 = 0
        pcall(function() count1 = exports.ox_inventory:GetItemCount(src, 'paper_bags') or 0 end)
        if count1 >= amount then
            local ok, res = pcall(function() return exports.ox_inventory:RemoveItem(src, 'paper_bags', amount) end)
            if ok and res then return true end
        else
            local from1 = math.min(count1, amount)
            local remaining = amount - from1
            if from1 > 0 then
                pcall(function() exports.ox_inventory:RemoveItem(src, 'paper_bags', from1) end)
            end
            local ok2, res2 = pcall(function() return exports.ox_inventory:RemoveItem(src, 'paperbag', remaining) end)
            if ok2 and res2 then return true end
            if from1 > 0 then
                pcall(function() exports.ox_inventory:AddItem(src, 'paper_bags', from1) end)
            end
            return false
        end
    end
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    local ok, res = pcall(function()
        return exports.ox_inventory:RemoveItem(src, item, amount)
    end)
    return ok and res
end

local function AddItem(src, item, amount)
    if item == 'black_money' then
        if GetResourceState('ox_inventory') == 'started' then
            local ok, res = pcall(function()
                return exports.ox_inventory:AddItem(src, 'black_money', amount)
            end)
            if ok and res then return true end
        end
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.addAccountMoney then
            xPlayer.addAccountMoney('black_money', amount)
            return true
        end
        return false
    end
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    local ok, res = pcall(function()
        return exports.ox_inventory:AddItem(src, item, amount)
    end)
    return ok and res
end

local function IsPlayerBusy(src)
    return activeHarvesters[src] or activeCollectors[src] or activeProcessors[src]
        or activeMethHarvesters[src] or activeMethProcessors[src]
end

local function CanUseWeedfarm(src)
    return true
end

local function SessionElapsed(session)
    if not session then return false end
    local startAt = tonumber(session.startAt)
    local durationMs = tonumber(session.durationMs)
    if not startAt or not durationMs then return false end
    return (GetGameTimer() - startAt) >= math.max(0, durationMs - 400)
end

-- ── Weed plant harvest ──────────────────────────────────────────
RegisterNetEvent("cfx-keydi-weedfarm:server:startHarvest", function(plantIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    plantIndex = tonumber(plantIndex) or 1
    local plantLoc = Config.WeedFarm.Locations[plantIndex]
    if not plantLoc then return end

    local pPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(pPed)

    if #(pCoords - plantLoc) > 4.0 then
        print(("[cfx-keydi-weedfarm] Distance check failed for player %s at plant #%s"):format(src, plantIndex))
        return
    end

    if IsPlayerBusy(src) then
        return
    end

    if not CanUseWeedfarm(src) then
        TriggerClientEvent("esx:showNotification", src, ConfigServerLocations.WrongServerMessage("grind"))
        return
    end

    local duration = Config.WeedFarm.HarvestDuration or 4000

    activeHarvesters[src] = {
        plantIndex = plantIndex,
        startTime = os.time(),
        startAt = GetGameTimer(),
        durationMs = duration,
        durationSecs = math.floor(duration / 1000)
    }

    TriggerClientEvent("cfx-keydi-weedfarm:client:harvestStarted", src, plantIndex, duration)
end)

RegisterNetEvent("cfx-keydi-weedfarm:server:completeHarvest", function(plantIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local session = activeHarvesters[src]
    if not session then
        KeydiElectron.Flag(src, "Weed harvest exploit (no session)", "cfx-keydi-weedfarm")
        return
    end

    plantIndex = tonumber(plantIndex)
    if not plantIndex or plantIndex ~= session.plantIndex then
        activeHarvesters[src] = nil
        KeydiElectron.Flag(src, "Weed harvest exploit (invalid plant)", "cfx-keydi-weedfarm")
        return
    end

    if not SessionElapsed(session) then
        KeydiElectron.Flag(src, "Weed harvest exploit (skipped wait)", "cfx-keydi-weedfarm")
        return
    end

    activeHarvesters[src] = nil

    local plantLoc = Config.WeedFarm.Locations[plantIndex]
    local pPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(pPed)

    if not plantLoc or #(pCoords - plantLoc) > 6.0 then
        print(("[cfx-keydi-weedfarm] Player %s walked away during harvest (#%s)"):format(src, plantIndex))
        return
    end

    local minAmt = Config.WeedFarm.MinReward or 2
    local maxAmt = Config.WeedFarm.MaxReward or 5
    local rewardAmount = math.random(minAmt, maxAmt)
    local itemName = Config.WeedFarm.ItemName or "weed_bud"
    local itemLabel = Config.WeedFarm.ItemLabel or "Weed Bud"

    local grindBonus = 0
    pcall(function()
        if exports["kodebykarl-ui"] and exports["kodebykarl-ui"].GetVipGrindBonus then
            grindBonus = exports["kodebykarl-ui"]:GetVipGrindBonus(src) or 0
        end
    end)
    if grindBonus > 0 then
        rewardAmount = rewardAmount + grindBonus
    end

    if not AddItem(src, itemName, rewardAmount) then
        TriggerClientEvent('esx:showNotification', src, "~r~Inventory full — harvest cancelled.")
        return
    end

    TriggerClientEvent('esx:showNotification', src, ("~g~Successfully harvested +%s %s!"):format(rewardAmount, itemLabel))
end)

-- ── Collect stations ────────────────────────────────────────────
RegisterNetEvent("cfx-keydi-weedfarm:server:startCollect", function(stationIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    stationIndex = tonumber(stationIndex)
    local station = stationIndex and Config.WeedFarm.CollectStations[stationIndex]
    if not station then return end

    if IsPlayerBusy(src) then
        TriggerClientEvent("cfx-keydi-weedfarm:client:collectDenied", src, "busy")
        return
    end

    if not CanUseWeedfarm(src) then
        TriggerClientEvent("cfx-keydi-weedfarm:client:collectDenied", src, "wrong_server")
        return
    end

    local currentTime = os.time()
    if collectCooldowns[src] and currentTime < collectCooldowns[src] then
        TriggerClientEvent("cfx-keydi-weedfarm:client:collectDenied", src, "cooldown")
        return
    end

    local c = station.coords
    local stationPos = vector3(c.x, c.y, c.z)
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    local range = (station.interactionDistance or 2.0) + 2.0
    if #(pCoords - stationPos) > range then
        TriggerClientEvent("cfx-keydi-weedfarm:client:collectDenied", src, "distance")
        return
    end

    local duration = Config.WeedFarm.CollectDuration or 4000
    local cooldownMs = Config.WeedFarm.CollectCooldown or 15000
    local totalCooldownSecs = math.floor((duration + cooldownMs) / 1000)

    -- Per-player only — other players can collect/process at the same time
    collectCooldowns[src] = currentTime + totalCooldownSecs
    TriggerClientEvent("cfx-keydi-weedfarm:client:syncCollectCooldown", src, stationIndex, true)

    SetTimeout(duration + cooldownMs, function()
        if collectCooldowns[src] and os.time() >= collectCooldowns[src] then
            collectCooldowns[src] = nil
            TriggerClientEvent("cfx-keydi-weedfarm:client:syncCollectCooldown", src, stationIndex, false)
        end
    end)

    activeCollectors[src] = {
        stationIndex = stationIndex,
        startTime = currentTime,
        startAt = GetGameTimer(),
        durationMs = duration,
        durationSecs = math.floor(duration / 1000)
    }

    TriggerClientEvent(
        "cfx-keydi-weedfarm:client:collectStarted",
        src,
        stationIndex,
        duration,
        station.progressLabel or station.label or "COLLECTING",
        station.itemLabel or station.item or "Item"
    )
end)

RegisterNetEvent("cfx-keydi-weedfarm:server:completeCollect", function(stationIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local session = activeCollectors[src]
    if not session then
        KeydiElectron.Flag(src, "Drug collect exploit (no session)", "cfx-keydi-weedfarm")
        return
    end

    stationIndex = tonumber(stationIndex)
    if not stationIndex or stationIndex ~= session.stationIndex then
        activeCollectors[src] = nil
        KeydiElectron.Flag(src, "Drug collect exploit (invalid station)", "cfx-keydi-weedfarm")
        return
    end

    if not SessionElapsed(session) then
        KeydiElectron.Flag(src, "Drug collect exploit (skipped wait)", "cfx-keydi-weedfarm")
        return
    end

    activeCollectors[src] = nil

    local station = Config.WeedFarm.CollectStations[stationIndex]
    if not station then return end

    local c = station.coords
    local stationPos = vector3(c.x, c.y, c.z)
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    if #(pCoords - stationPos) > 6.0 then
        TriggerClientEvent("cfx-keydi-weedfarm:client:collectDenied", src, "distance")
        return
    end

    local minAmt = station.minAmount or 5
    local maxAmt = station.maxAmount or 10
    local rewardAmount = math.random(minAmt, maxAmt)
    local itemName = station.item
    local itemLabel = station.itemLabel or itemName

    local grindBonus = 0
    pcall(function()
        if exports["kodebykarl-ui"] and exports["kodebykarl-ui"].GetVipGrindBonus then
            grindBonus = exports["kodebykarl-ui"]:GetVipGrindBonus(src) or 0
        end
    end)
    if grindBonus > 0 then
        rewardAmount = rewardAmount + grindBonus
    end

    if not itemName then return end

    if not AddItem(src, itemName, rewardAmount) then
        TriggerClientEvent('esx:showNotification', src, "~r~Inventory full — collect cancelled.")
        return
    end

    TriggerClientEvent('esx:showNotification', src, ("~g~Collected +%s %s!"):format(rewardAmount, itemLabel))
end)

-- ── Process stations ────────────────────────────────────────────
local function GetStationRequires(station)
    if not station then return {} end
    if type(station.requires) == "table" and #station.requires > 0 then
        return station.requires
    elseif station.require and station.require.item then
        return { station.require }
    end
    return {}
end

RegisterNetEvent("cfx-keydi-weedfarm:server:startProcess", function(stationIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    stationIndex = tonumber(stationIndex)
    local station = stationIndex and Config.WeedFarm.ProcessStations[stationIndex]
    if not station then return end

    if IsPlayerBusy(src) then
        TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "busy")
        return
    end

    if not CanUseWeedfarm(src) then
        TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "wrong_server")
        return
    end

    local c = station.coords
    local stationPos = vector3(c.x, c.y, c.z)
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    local range = (station.interactionDistance or 2.0) + 2.0
    if #(pCoords - stationPos) > range then
        TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "distance")
        return
    end

    local input = station.input
    local reqList = GetStationRequires(station)
    if not input or not input.item or not input.amount then return end

    if GetItemCount(src, input.item) < input.amount then
        TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "missing_input", input.label or input.item, input.amount)
        return
    end

    for _, req in ipairs(reqList) do
        local needAmt = req.amount or 1
        if GetItemCount(src, req.item) < needAmt then
            TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "missing_require", req.label or req.item, needAmt)
            return
        end
    end

    local duration = Config.WeedFarm.ProcessDuration or 5000
    activeProcessors[src] = {
        stationIndex = stationIndex,
        startTime = os.time(),
        startAt = GetGameTimer(),
        durationMs = duration,
        durationSecs = math.floor(duration / 1000)
    }

    TriggerClientEvent(
        "cfx-keydi-weedfarm:client:processStarted",
        src,
        stationIndex,
        duration,
        station.progressLabel or station.label or "PROCESSING",
        (station.output and station.output.label) or "Item"
    )
end)

RegisterNetEvent("cfx-keydi-weedfarm:server:completeProcess", function(stationIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local session = activeProcessors[src]
    if not session then
        KeydiElectron.Flag(src, "Drug process exploit (no session)", "cfx-keydi-weedfarm")
        return
    end

    stationIndex = tonumber(stationIndex)
    if not stationIndex or stationIndex ~= session.stationIndex then
        activeProcessors[src] = nil
        KeydiElectron.Flag(src, "Drug process exploit (invalid station)", "cfx-keydi-weedfarm")
        return
    end

    if not SessionElapsed(session) then
        KeydiElectron.Flag(src, "Drug process exploit (skipped wait)", "cfx-keydi-weedfarm")
        return
    end

    activeProcessors[src] = nil

    local station = Config.WeedFarm.ProcessStations[stationIndex]
    if not station then return end

    local c = station.coords
    local stationPos = vector3(c.x, c.y, c.z)
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    if #(pCoords - stationPos) > 6.0 then
        TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "distance")
        return
    end

    local input = station.input
    local reqList = GetStationRequires(station)
    local output = station.output
    if not input or not output then return end

    if GetItemCount(src, input.item) < input.amount then
        TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "missing_input", input.label or input.item, input.amount)
        return
    end

    for _, req in ipairs(reqList) do
        local needAmt = req.amount or 1
        if GetItemCount(src, req.item) < needAmt then
            TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "missing_require", req.label or req.item, needAmt)
            return
        end
    end

    if not RemoveItem(src, input.item, input.amount) then
        TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "missing_input", input.label or input.item, input.amount)
        return
    end

    local removedReqs = {}
    local reqFailed = false
    for _, req in ipairs(reqList) do
        local needAmt = req.amount or 1
        if not RemoveItem(src, req.item, needAmt) then
            reqFailed = true
            break
        end
        table.insert(removedReqs, { item = req.item, amount = needAmt })
    end

    if reqFailed then
        AddItem(src, input.item, input.amount)
        for _, rem in ipairs(removedReqs) do
            AddItem(src, rem.item, rem.amount)
        end
        TriggerClientEvent("cfx-keydi-weedfarm:client:processDenied", src, "missing_require")
        return
    end

    if not AddItem(src, output.item, output.amount) then
        AddItem(src, input.item, input.amount)
        for _, rem in ipairs(removedReqs) do
            AddItem(src, rem.item, rem.amount)
        end
        TriggerClientEvent('esx:showNotification', src, "~r~Inventory full — process cancelled.")
        return
    end

    TriggerClientEvent(
        'esx:showNotification',
        src,
        ("~g~Processed %sx %s into %sx %s"):format(
            input.amount,
            input.label or input.item,
            output.amount,
            output.label or output.item
        )
    )
end)

RegisterNetEvent("cfx-keydi-weedfarm:server:cancelAction", function()
    local src = source
    if type(src) ~= "number" or src < 1 then return end

    activeHarvesters[src] = nil
    activeCollectors[src] = nil
    activeProcessors[src] = nil
    activeMethHarvesters[src] = nil
    activeMethProcessors[src] = nil
end)

AddEventHandler("playerDropped", function()
    local src = source
    activeHarvesters[src] = nil
    activeCollectors[src] = nil
    activeProcessors[src] = nil
    activeMethHarvesters[src] = nil
    activeMethProcessors[src] = nil
    collectCooldowns[src] = nil
end)

-- ── Meth harvest ────────────────────────────────────────────────
RegisterNetEvent("cfx-keydi-methfarm:server:startHarvest", function(plantIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local meth = Config.MethFarm
    if not meth then return end

    plantIndex = tonumber(plantIndex) or 1
    local plantLoc = meth.Locations and meth.Locations[plantIndex]
    if not plantLoc then return end

    local pPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(pPed)

    if #(pCoords - plantLoc) > 4.0 then
        return
    end

    if IsPlayerBusy(src) then
        return
    end

    if not CanUseWeedfarm(src) then
        TriggerClientEvent("esx:showNotification", src, ConfigServerLocations.WrongServerMessage("grind"))
        return
    end

    local duration = meth.HarvestDuration or 4000

    activeMethHarvesters[src] = {
        plantIndex = plantIndex,
        startTime = os.time(),
        startAt = GetGameTimer(),
        durationMs = duration,
        durationSecs = math.floor(duration / 1000)
    }

    TriggerClientEvent("cfx-keydi-methfarm:client:harvestStarted", src, plantIndex, duration)
end)

RegisterNetEvent("cfx-keydi-methfarm:server:completeHarvest", function(plantIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local session = activeMethHarvesters[src]
    if not session then
        KeydiElectron.Flag(src, "Meth harvest exploit (no session)", "cfx-keydi-weedfarm")
        return
    end

    plantIndex = tonumber(plantIndex)
    if not plantIndex or plantIndex ~= session.plantIndex then
        activeMethHarvesters[src] = nil
        KeydiElectron.Flag(src, "Meth harvest exploit (invalid plant)", "cfx-keydi-weedfarm")
        return
    end

    if not SessionElapsed(session) then
        KeydiElectron.Flag(src, "Meth harvest exploit (skipped wait)", "cfx-keydi-weedfarm")
        return
    end

    activeMethHarvesters[src] = nil

    local meth = Config.MethFarm
    local plantLoc = meth and meth.Locations and meth.Locations[plantIndex]
    local pPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(pPed)

    if not plantLoc or #(pCoords - plantLoc) > 6.0 then
        return
    end

    local minAmt = meth.MinReward or 2
    local maxAmt = meth.MaxReward or 5
    local rewardAmount = math.random(minAmt, maxAmt)
    local itemName = meth.ItemName or "stoned_meth"
    local itemLabel = meth.ItemLabel or "Stoned Meth"

    local grindBonus = 0
    pcall(function()
        if exports["kodebykarl-ui"] and exports["kodebykarl-ui"].GetVipGrindBonus then
            grindBonus = exports["kodebykarl-ui"]:GetVipGrindBonus(src) or 0
        end
    end)
    if grindBonus > 0 then
        rewardAmount = rewardAmount + grindBonus
    end

    if not AddItem(src, itemName, rewardAmount) then
        TriggerClientEvent('esx:showNotification', src, "~r~Inventory full — harvest cancelled.")
        return
    end

    TriggerClientEvent('esx:showNotification', src, ("~g~Successfully harvested +%s %s!"):format(rewardAmount, itemLabel))
end)

RegisterNetEvent("cfx-keydi-methfarm:server:startProcess", function(stationIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local meth = Config.MethFarm
    if not meth then return end

    stationIndex = tonumber(stationIndex)
    local station = stationIndex and meth.ProcessStations and meth.ProcessStations[stationIndex]
    if not station then return end

    if IsPlayerBusy(src) then
        TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "busy")
        return
    end

    if not CanUseWeedfarm(src) then
        TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "wrong_server")
        return
    end

    local c = station.coords
    local stationPos = vector3(c.x, c.y, c.z)
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    local range = (station.interactionDistance or 2.0) + 2.0
    if #(pCoords - stationPos) > range then
        TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "distance")
        return
    end

    local input = station.input
    local reqList = GetStationRequires(station)
    if not input or not input.item or not input.amount then return end

    if GetItemCount(src, input.item) < input.amount then
        TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "missing_input", input.label or input.item, input.amount)
        return
    end

    for _, req in ipairs(reqList) do
        local needAmt = req.amount or 1
        if GetItemCount(src, req.item) < needAmt then
            TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "missing_require", req.label or req.item, needAmt)
            return
        end
    end

    local duration = meth.ProcessDuration or 5000
    activeMethProcessors[src] = {
        stationIndex = stationIndex,
        startTime = os.time(),
        startAt = GetGameTimer(),
        durationMs = duration,
        durationSecs = math.floor(duration / 1000)
    }

    TriggerClientEvent(
        "cfx-keydi-methfarm:client:processStarted",
        src,
        stationIndex,
        duration,
        station.progressLabel or station.label or "PROCESSING",
        (station.output and station.output.label) or "Item"
    )
end)

RegisterNetEvent("cfx-keydi-methfarm:server:completeProcess", function(stationIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local session = activeMethProcessors[src]
    if not session then
        KeydiElectron.Flag(src, "Meth process exploit (no session)", "cfx-keydi-weedfarm")
        return
    end

    stationIndex = tonumber(stationIndex)
    if not stationIndex or stationIndex ~= session.stationIndex then
        activeMethProcessors[src] = nil
        KeydiElectron.Flag(src, "Meth process exploit (invalid station)", "cfx-keydi-weedfarm")
        return
    end

    if not SessionElapsed(session) then
        KeydiElectron.Flag(src, "Meth process exploit (skipped wait)", "cfx-keydi-weedfarm")
        return
    end

    activeMethProcessors[src] = nil

    local meth = Config.MethFarm
    local station = meth and meth.ProcessStations and meth.ProcessStations[stationIndex]
    if not station then return end

    local c = station.coords
    local stationPos = vector3(c.x, c.y, c.z)
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    if #(pCoords - stationPos) > 6.0 then
        TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "distance")
        return
    end

    local input = station.input
    local reqList = GetStationRequires(station)
    local output = station.output
    if not input or not output then return end

    if GetItemCount(src, input.item) < input.amount then
        TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "missing_input", input.label or input.item, input.amount)
        return
    end

    for _, req in ipairs(reqList) do
        local needAmt = req.amount or 1
        if GetItemCount(src, req.item) < needAmt then
            TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "missing_require", req.label or req.item, needAmt)
            return
        end
    end

    if not RemoveItem(src, input.item, input.amount) then
        TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "missing_input", input.label or input.item, input.amount)
        return
    end

    local removedReqs = {}
    local reqFailed = false
    for _, req in ipairs(reqList) do
        local needAmt = req.amount or 1
        if not RemoveItem(src, req.item, needAmt) then
            reqFailed = true
            break
        end
        table.insert(removedReqs, { item = req.item, amount = needAmt })
    end

    if reqFailed then
        AddItem(src, input.item, input.amount)
        for _, rem in ipairs(removedReqs) do
            AddItem(src, rem.item, rem.amount)
        end
        TriggerClientEvent("cfx-keydi-methfarm:client:processDenied", src, "missing_require")
        return
    end

    if not AddItem(src, output.item, output.amount) then
        AddItem(src, input.item, input.amount)
        for _, rem in ipairs(removedReqs) do
            AddItem(src, rem.item, rem.amount)
        end
        TriggerClientEvent('esx:showNotification', src, "~r~Inventory full — process cancelled.")
        return
    end

    TriggerClientEvent(
        'esx:showNotification',
        src,
        ("~g~Processed %sx %s into %sx %s"):format(
            input.amount,
            input.label or input.item,
            output.amount,
            output.label or output.item
        )
    )
end)
