ESX = ESX or exports["es_extended"]:getSharedObject()

local activeChops = {} -- [src] = session
local plateLocks = {} -- [plate] = src
local cooldowns = {} -- [src] = unix
-- Plates disabled until server/resource restart (row stays in owned_vehicles).
local choppedUntilRestart = {} -- [normalizedPlate] = { plate, owner, at }

local function Notify(src, msg, nType)
    TriggerClientEvent("ox_lib:notify", src, {
        title = Config.ChopShop.Label or "Illegal Chop",
        description = msg,
        type = nType or "inform",
    })
end

local function NormalizePlate(plate)
    if not plate or plate == "" then return "" end
    return (string.gsub(tostring(plate), "%s+", "")):upper()
end

local function IsBlockedPlate(plate)
    local blocked = Config.ChopShop.BlockedPlates
    return blocked and blocked[plate] == true
end

local function InChopZone(coords)
    local radius = (Config.ChopShop.ZoneRadius or 22.0) + 4.0
    for i = 1, #Config.ChopShop.Locations do
        if #(coords - Config.ChopShop.Locations[i].coords) <= radius then
            return true
        end
    end
    return false
end

local function SessionElapsed(session)
    if not session then return false end
    local startAt = tonumber(session.startAt)
    local durationMs = tonumber(session.durationMs)
    if not startAt or not durationMs then return false end
    return (GetGameTimer() - startAt) >= math.max(0, durationMs - 400)
end

local function NormalizeModelName(modelName)
    return tostring(modelName or ""):lower():gsub("%s+", "")
end

local function LookupVehicleListPrice(modelName)
    modelName = NormalizeModelName(modelName)
    if modelName == "" then return nil end

    local queries = {
        "SELECT price FROM dealership_stock WHERE LOWER(vehicle) = ? ORDER BY price DESC LIMIT 1",
        "SELECT price FROM dealership_vehicles WHERE LOWER(spawn_code) = ? LIMIT 1",
        "SELECT price FROM vehicles WHERE LOWER(model) = ? LIMIT 1",
    }

    for i = 1, #queries do
        local ok, row = pcall(function()
            return MySQL.single.await(queries[i], { modelName })
        end)
        local price = ok and row and tonumber(row.price)
        if price and price > 0 then
            return price
        end
    end

    return nil
end

local function GetChopPayout(modelName, vehicleClass)
    local cfg = Config.ChopShop.MoneyReward or {}
    local minAmt = tonumber(cfg.min) or 25000
    local maxAmt = tonumber(cfg.max) or 500000
    local percent = (tonumber(cfg.pricePercent) or 200) / 100.0

    local listPrice = LookupVehicleListPrice(modelName)
    local amount

    if listPrice then
        amount = listPrice * percent
    else
        local classAmounts = cfg.classAmounts or {}
        amount = classAmounts[tonumber(vehicleClass)] or cfg.amount or minAmt
    end

    amount = math.floor((tonumber(amount) or minAmt) / 1000) * 1000
    if amount < minAmt then amount = minAmt end
    if amount > maxAmt then amount = maxAmt end
    return amount
end

local function RollRewards()
    local rewards = {}
    local list = Config.ChopShop.Rewards or {}
    for i = 1, #list do
        local entry = list[i]
        if math.random(100) <= (entry.chance or 100) then
            local minAmt = entry.min or 1
            local maxAmt = entry.max or minAmt
            if maxAmt < minAmt then maxAmt = minAmt end
            rewards[#rewards + 1] = {
                item = entry.item,
                count = math.random(minAmt, maxAmt),
            }
        end
    end
    return rewards
end

local function CountOnlineJobs(jobs)
    local total = 0
    if type(jobs) ~= "table" then return 0 end
    for i = 1, #jobs do
        local players = ESX.GetExtendedPlayers("job", jobs[i])
        if players then
            total = total + #players
        end
    end
    return total
end

local function AlertPoliceChop(src, locationLabel, coords)
    local dispatch = Config.ChopShop.Dispatch
    if not dispatch or dispatch.enabled == false then return end

    local jobs = dispatch.jobs or { "police", "sheriff" }
    local spot = locationLabel or "Illegal Chop Yard"
    local msg = ("%s at %s"):format(dispatch.message or "Illegal vehicle chop in progress", spot)

    if ESX.SendDispatch then
        ESX.SendDispatch(jobs, msg, dispatch.duration or 15000)
    else
        for i = 1, #jobs do
            local players = ESX.GetExtendedPlayers("job", jobs[i])
            for j = 1, #players do
                TriggerClientEvent("esx:Notify", players[j].source, "Dispatch", msg, "police", dispatch.duration or 15000)
            end
        end
    end

    -- LEO map blip (everyone on those jobs)
    if coords then
        for i = 1, #jobs do
            local players = ESX.GetExtendedPlayers("job", jobs[i])
            for j = 1, #players do
                local leoSrc = players[j].source
                if leoSrc ~= src then
                    TriggerClientEvent("cfx-keydi-chopshop:client:policeAlert", leoSrc, {
                        coords = { x = coords.x, y = coords.y, z = coords.z },
                        label = spot,
                        sprite = dispatch.blipSprite or 380,
                        color = dispatch.blipColor or 1,
                        scale = dispatch.blipScale or 1.0,
                        time = dispatch.blipTime or 180000,
                    })
                end
            end
        end
    end

    -- Optional scoreboard sticky robbery
    if GetResourceState("kodebykarl-ui") == "started" then
        pcall(function()
            exports["kodebykarl-ui"]:AddActiveRobbery("illegal_chop_" .. tostring(src), {
                name = "Illegal Chop",
                location = spot,
                timer = math.floor((Config.ChopShop.ProgressDuration or 45000) / 1000),
                sticky = true,
            })
        end)
    end
end

local function ClearPoliceRobberyTrack(src)
    if GetResourceState("kodebykarl-ui") == "started" then
        pcall(function()
            exports["kodebykarl-ui"]:RemoveActiveRobbery("illegal_chop_" .. tostring(src))
        end)
    end
end

local function ResolveLocationLabel(coords)
    local bestLabel = "Illegal Chop Yard"
    local bestDist = 9999.0
    for i = 1, #Config.ChopShop.Locations do
        local loc = Config.ChopShop.Locations[i]
        local d = #(coords - loc.coords)
        if d < bestDist then
            bestDist = d
            bestLabel = loc.label or bestLabel
        end
    end
    return bestLabel
end

local function IsProjectPartReward(item)
    item = tostring(item or "")
    if item == "" then return false end
    if GetResourceState("kodebykarl-projectcars") == "started" then
        local ok, isType = pcall(function()
            return exports["kodebykarl-projectcars"]:IsProjectPartType(item)
        end)
        if ok and isType then return true end
        local okType, partType = pcall(function()
            return exports["kodebykarl-projectcars"]:GetPartTypeFromItem(item)
        end)
        if okType and partType then return true end
    end
    return false
end

local function ResolveChopPartModel(choppedModel)
    choppedModel = tostring(choppedModel or ""):lower():gsub("%s+", "")
    if GetResourceState("kodebykarl-projectcars") == "started" then
        local ok, isLoot = pcall(function()
            local vehicles = exports["kodebykarl-projectcars"]:GetProjectVehicles()
            local data = vehicles and vehicles[choppedModel]
            return data ~= nil and data.loot ~= false
        end)
        if ok and isLoot then
            return choppedModel
        end
        local rolled, model = pcall(function()
            return exports["kodebykarl-projectcars"]:PickRandomProjectModel()
        end)
        if rolled and type(model) == "string" and model ~= "" then
            return model
        end
    end
    if choppedModel ~= "" then
        return choppedModel
    end
    return nil
end

local function ResolveChopPartItem(item, modelName)
    if GetResourceState("kodebykarl-projectcars") == "started" then
        local ok, uniqueName = pcall(function()
            return exports["kodebykarl-projectcars"]:ResolvePartItem(item, modelName)
        end)
        if ok and type(uniqueName) == "string" and uniqueName ~= "" then
            return uniqueName
        end
    end
    return item
end

local function BuildChopPartMetadata(item, modelName)
    if not IsProjectPartReward(item) then return nil end
    modelName = tostring(modelName or ""):lower():gsub("%s+", "")
    if modelName == "" then return nil end

    if GetResourceState("kodebykarl-projectcars") == "started" then
        local ok, meta = pcall(function()
            return exports["kodebykarl-projectcars"]:BuildPartMetadata(item, modelName)
        end)
        if ok and type(meta) == "table" then
            return meta
        end
    end

    return {
        model = modelName,
        vehicle = modelName:upper(),
        label = "Project Vehicle Part",
        description = ("Fits %s project cars only."):format(modelName:upper()),
    }
end

local function AddItem(src, item, amount, metadata)
    if GetResourceState("ox_inventory") ~= "started" then return false end
    local ok, res = pcall(function()
        return exports.ox_inventory:AddItem(src, item, amount, metadata)
    end)
    return ok and res
end

local function LookupOwnedVehicle(plate)
    local ok, row = pcall(function()
        return MySQL.single.await([[
            SELECT owner, plate, job_vehicle, garage_id
            FROM owned_vehicles
            WHERE UPPER(REPLACE(TRIM(plate), ' ', '')) = ?
            LIMIT 1
        ]], { plate })
    end)
    if ok then return row end

    return MySQL.single.await([[
        SELECT owner, plate
        FROM owned_vehicles
        WHERE UPPER(REPLACE(TRIM(plate), ' ', '')) = ?
        LIMIT 1
    ]], { plate })
end

local function IsPlateChopped(plate)
    plate = NormalizePlate(plate)
    return plate ~= "" and choppedUntilRestart[plate] ~= nil
end

--- Disable vehicle until server restart. Does NOT delete the owned_vehicles row.
local function DisableChoppedVehicle(dbPlate, owner)
    local plateKey = NormalizePlate(dbPlate)
    if plateKey == "" then return false end

    choppedUntilRestart[plateKey] = {
        plate = dbPlate,
        owner = owner,
        at = os.time(),
    }

    -- Keep ownership; just mark it parked so garage lists it as stored.
    pcall(function()
        MySQL.update.await([[
            UPDATE owned_vehicles
            SET in_garage = 1, stored = 1
            WHERE plate = ?
        ]], { dbPlate })
    end)

    return true
end

exports("IsPlateChopped", IsPlateChopped)
exports("GetChoppedPlates", function()
    local list = {}
    for plate in pairs(choppedUntilRestart) do
        list[#list + 1] = plate
    end
    return list
end)

local function ClearVehicleInventories(plate)
    if GetResourceState("ox_inventory") ~= "started" then return end

    local variants = {
        plate,
        NormalizePlate(plate),
    }

    for i = 1, #variants do
        local p = variants[i]
        if p and p ~= "" then
            pcall(function()
                exports.ox_inventory:RemoveInventory("trunk" .. p)
            end)
            pcall(function()
                exports.ox_inventory:RemoveInventory("glove" .. p)
            end)
        end
    end
end

local function DeleteWorldVehicle(netId)
    netId = tonumber(netId)
    if not netId then return end

    TriggerClientEvent("cfx-keydi-chopshop:client:deleteVehicle", -1, netId)

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        if GetResourceState("AdvancedParking") == "started" then
            pcall(function()
                exports.AdvancedParking:DeleteVehicle(entity, false)
            end)
        end
        DeleteEntity(entity)
    end
end

local function ClearSession(src, unlockClient)
    local session = activeChops[src]
    if session and session.plate then
        if plateLocks[session.plate] == src then
            plateLocks[session.plate] = nil
        end
    end
    activeChops[src] = nil
    ClearPoliceRobberyTrack(src)
    if unlockClient then
        TriggerClientEvent("cfx-keydi-chopshop:client:unlock", src)
    end
end

local function GetSpeed(entity)
    local vel = GetEntityVelocity(entity)
    if not vel then return 0.0 end
    return math.sqrt((vel.x * vel.x) + (vel.y * vel.y) + (vel.z * vel.z))
end

local function VehicleOccupiedByOther(entity, src)
    local players = GetPlayers()
    for i = 1, #players do
        local id = tonumber(players[i])
        if id and id ~= src then
            local otherPed = GetPlayerPed(id)
            if otherPed and otherPed ~= 0 and GetVehiclePedIsIn(otherPed, false) == entity then
                return true
            end
        end
    end
    return false
end

local function ReadPlate(entity)
    local ok, plate = pcall(GetVehicleNumberPlateText, entity)
    if ok and type(plate) == "string" then
        return NormalizePlate(plate)
    end
    return ""
end

local function ValidateChopVehicle(src, netId, clientPlate, vehicleClass)
    netId = tonumber(netId)
    if not netId then return nil, "denied" end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return nil, "denied"
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil, "denied" end

    local pCoords = GetEntityCoords(ped)
    local vCoords = GetEntityCoords(entity)
    if not InChopZone(pCoords) or not InChopZone(vCoords) then
        return nil, "zone"
    end

    if #(pCoords - vCoords) > ((Config.ChopShop.InteractionDistance or 3.2) + 4.0) then
        return nil, "zone"
    end

    if GetSpeed(entity) > ((Config.ChopShop.MaxVehicleSpeed or 1.2) + 1.0) then
        return nil, "speed"
    end

    vehicleClass = tonumber(vehicleClass)
    if vehicleClass and not Config.ChopShop.AllowedClasses[vehicleClass] then
        return nil, "class"
    end

    if VehicleOccupiedByOther(entity, src) then
        return nil, "occupied"
    end

    local plate = ReadPlate(entity)
    if plate == "" then
        plate = NormalizePlate(clientPlate)
    end

    local sent = NormalizePlate(clientPlate)
    if plate == "" or (sent ~= "" and sent ~= plate) then
        return nil, "denied"
    end

    if IsBlockedPlate(plate) then
        return nil, "blocked"
    end

    return {
        entity = entity,
        netId = netId,
        plate = plate,
        coords = vCoords,
    }, nil
end

lib.callback.register("cfx-keydi-chopshop:server:request", function(src, netId, clientPlate, vehicleClass, modelName)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return { ok = false, reason = "denied" } end

    if ConfigServerLocations and ConfigServerLocations.CanUseFunction then
        if not ConfigServerLocations.CanUseFunction("illegal", src) then
            TriggerClientEvent("ox_lib:notify", src, {
                title = (Config.ChopShop and Config.ChopShop.Label) or "Illegal Chop",
                description = ConfigServerLocations.WrongServerMessage("illegal"),
                type = "error",
            })
            return { ok = false, reason = "region" }
        end
    end

    if activeChops[src] then
        return { ok = false, reason = "busy" }
    end

    local now = os.time()
    if cooldowns[src] and now < cooldowns[src] then
        return { ok = false, reason = "cooldown" }
    end

    local needLeo = tonumber(Config.ChopShop.RequirePolice) or 0
    if needLeo > 0 then
        local jobs = (Config.ChopShop.Dispatch and Config.ChopShop.Dispatch.jobs) or { "police", "sheriff" }
        if CountOnlineJobs(jobs) < needLeo then
            return { ok = false, reason = "cops" }
        end
    end

    local veh, reason = ValidateChopVehicle(src, netId, clientPlate, vehicleClass)
    if not veh then
        return { ok = false, reason = reason or "denied" }
    end

    if plateLocks[veh.plate] then
        return { ok = false, reason = "in_use" }
    end

    if IsPlateChopped(veh.plate) then
        return { ok = false, reason = "already_chopped" }
    end

    -- Must exist in owned_vehicles BEFORE any progress bar.
    local row = LookupOwnedVehicle(veh.plate)
    if not row or not row.owner then
        return { ok = false, reason = "not_owned" }
    end

    if Config.ChopShop.BlockJobVehicles then
        local jobFlag = tonumber(row.job_vehicle) or 0
        if jobFlag == 1 then
            return { ok = false, reason = "job" }
        end
    end

    local duration = Config.ChopShop.ProgressDuration or 45000
    local rewards = RollRewards()
    modelName = NormalizeModelName(modelName)
    local locationLabel = ResolveLocationLabel(veh.coords)
    local moneyAmount = GetChopPayout(modelName, vehicleClass)

    plateLocks[veh.plate] = src
    activeChops[src] = {
        plate = veh.plate,
        dbPlate = row.plate,
        owner = row.owner,
        netId = veh.netId,
        vehicleClass = tonumber(vehicleClass),
        modelName = modelName,
        moneyAmount = moneyAmount,
        startAt = GetGameTimer(),
        durationMs = duration,
        rewards = rewards,
        isOwner = row.owner == xPlayer.identifier,
        locationLabel = locationLabel,
    }

    -- Alert LEO immediately when illegal chop starts
    AlertPoliceChop(src, locationLabel, veh.coords)

    return {
        ok = true,
        duration = duration,
        isOwner = row.owner == xPlayer.identifier,
    }
end)

RegisterNetEvent("cfx-keydi-chopshop:server:complete", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local session = activeChops[src]
    if not session then
        KeydiElectron.Flag(src, "Chop shop exploit (no session)", "cfx-keydi-chopshop")
        return
    end

    if not SessionElapsed(session) then
        ClearSession(src, true)
        KeydiElectron.Flag(src, "Chop shop exploit (skipped wait)", "cfx-keydi-chopshop")
        return
    end

    local veh, reason = ValidateChopVehicle(src, session.netId, session.plate, session.vehicleClass)
    if not veh then
        ClearSession(src, true)
        Notify(src, "Chop failed — vehicle left the yard.", "error")
        return
    end

    if veh.plate ~= session.plate then
        ClearSession(src, true)
        KeydiElectron.Flag(src, "Chop shop exploit (plate mismatch)", "cfx-keydi-chopshop")
        return
    end

    -- Re-check DB so a spawn car cannot sneak through after the request.
    local row = LookupOwnedVehicle(session.plate)
    if not row or not row.owner then
        ClearSession(src, true)
        Notify(src, "Spawn / test cars cannot be chopped.", "error")
        return
    end

    local dbPlate = row.plate or session.dbPlate
    -- Do not delete from DB — disable until server restart only.
    DisableChoppedVehicle(dbPlate, row.owner or session.owner)
    ClearVehicleInventories(dbPlate)
    ClearVehicleInventories(session.plate)
    DeleteWorldVehicle(session.netId)

    local given = {}

    -- Dirty cash scales with the chopped vehicle (dealership / class)
    local moneyCfg = Config.ChopShop.MoneyReward
    local moneyAmount = tonumber(session.moneyAmount) or GetChopPayout(session.modelName, session.vehicleClass)
    if moneyCfg and moneyCfg.item and moneyAmount > 0 then
        if AddItem(src, moneyCfg.item, moneyAmount) then
            given[#given + 1] = ("$%s %s"):format(moneyAmount, moneyCfg.item)
        end
    end

    local rewards = session.rewards or {}
    local choppedIsProject = false
    if GetResourceState("kodebykarl-projectcars") == "started" then
        local ok, isLoot = pcall(function()
            local vehicles = exports["kodebykarl-projectcars"]:GetProjectVehicles()
            local data = vehicles and vehicles[tostring(session.modelName or ""):lower():gsub("%s+", "")]
            return data ~= nil and data.loot ~= false
        end)
        choppedIsProject = ok and isLoot == true
    end

    for i = 1, #rewards do
        local reward = rewards[i]
        if reward.item and reward.count and reward.count > 0 then
            if IsProjectPartReward(reward.item) then
                -- Project car chop = matching unique parts. Anything else = each part rolls a random pack car.
                if choppedIsProject then
                    local modelName = tostring(session.modelName or ""):lower():gsub("%s+", "")
                    local uniqueItem = ResolveChopPartItem(reward.item, modelName)
                    local meta = BuildChopPartMetadata(uniqueItem, modelName)
                    if AddItem(src, uniqueItem, reward.count, meta) then
                        given[#given + 1] = ("%sx %s"):format(reward.count, uniqueItem)
                    end
                else
                    local added = 0
                    local lastItem
                    for _ = 1, reward.count do
                        local modelName = ResolveChopPartModel(session.modelName)
                        local uniqueItem = ResolveChopPartItem(reward.item, modelName)
                        local meta = BuildChopPartMetadata(uniqueItem, modelName)
                        if AddItem(src, uniqueItem, 1, meta) then
                            added = added + 1
                            lastItem = uniqueItem
                        end
                    end
                    if added > 0 then
                        given[#given + 1] = ("%sx %s"):format(added, lastItem or reward.item)
                    end
                end
            else
                if AddItem(src, reward.item, reward.count) then
                    given[#given + 1] = ("%sx %s"):format(reward.count, reward.item)
                end
            end
        end
    end

    local cooldownMs = Config.ChopShop.Cooldown or 120000
    cooldowns[src] = os.time() + math.floor(cooldownMs / 1000)
    ClearSession(src, false)

    if #given > 0 then
        Notify(src, ("Illegal chop done. Loot: %s. Vehicle disabled until server restart."):format(table.concat(given, ", ")), "success")
    else
        Notify(src, "Vehicle chopped (disabled until restart). Inventory was full — payout lost.", "error")
    end

    if session.owner then
        local xOwner = ESX.GetPlayerFromIdentifier(session.owner)
        if xOwner and xOwner.source ~= src then
            Notify(xOwner.source, ("Your vehicle %s was chopped. It is disabled until server restart."):format(session.plate), "error")
        elseif xOwner and xOwner.source == src then
            Notify(src, ("Your vehicle %s is disabled until server restart."):format(session.plate), "inform")
        end
    end
end)

RegisterNetEvent("cfx-keydi-chopshop:server:cancel", function()
    local src = source
    if type(src) ~= "number" or src < 1 then return end
    ClearSession(src, false)
end)

AddEventHandler("playerDropped", function()
    ClearSession(source, false)
end)
