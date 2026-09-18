ESX = ESX or exports["es_extended"]:getSharedObject()

local spawnedPlants = {}
local spawnedMethProps = {}
local harvestedPlants = {}
-- Personal cooldown only (does not block other players at the same spot)
local collectCooldowns = {} -- [index] = true while YOU are cooling down
local isHarvesting = false
local isProcessing = false
local isCollecting = false

local function IsBusy()
    return isHarvesting or isProcessing or isCollecting
end

local function CanUseWeedfarm()
    return true
end

-- Helper Function for 3D Text Render
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (#text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 120)
    ClearDrawOrigin()
end

local function RunProgress(duration, label, anim)
    return lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = anim,
    })
end

-- Spawn Weed Plant Props at locations
local function SpawnPlantProps()
    local modelHash = Config.WeedFarm.PlantModel
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    for i, loc in ipairs(Config.WeedFarm.Locations) do
        local existingObj = GetClosestObjectOfType(loc.x, loc.y, loc.z, 1.0, modelHash, false, false, false)
        if existingObj == 0 then
            local obj = CreateObject(modelHash, loc.x, loc.y, loc.z - 1.0, false, false, false)
            SetEntityHeading(obj, math.random(0, 360))
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            table.insert(spawnedPlants, obj)
        else
            table.insert(spawnedPlants, existingObj)
        end
    end
end

local function DeletePlantProps()
    for _, obj in ipairs(spawnedPlants) do
        if obj and DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
    spawnedPlants = {}
end

local function SpawnMethProps()
    local meth = Config.MethFarm
    if not meth or not meth.Locations then return end

    local modelHash = meth.PlantModel
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    for i, loc in ipairs(meth.Locations) do
        local existingObj = GetClosestObjectOfType(loc.x, loc.y, loc.z, 1.0, modelHash, false, false, false)
        if existingObj == 0 then
            local obj = CreateObject(modelHash, loc.x, loc.y, loc.z - 1.0, false, false, false)
            SetEntityHeading(obj, math.random(0, 360))
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            table.insert(spawnedMethProps, obj)
        else
            table.insert(spawnedMethProps, existingObj)
        end
    end
end

local function DeleteMethProps()
    for _, obj in ipairs(spawnedMethProps) do
        if obj and DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
    spawnedMethProps = {}
end

-- Proximity & 3D Text Loop (plants + collect + process)
CreateThread(function()
    Wait(500)
    SpawnPlantProps()
    SpawnMethProps()

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        -- 1. Weed Plant Harvest Spots
        for i, loc in ipairs(Config.WeedFarm.Locations) do
            local dist = #(pCoords - loc)
            if dist <= 6.0 then
                sleep = 0
                if IsBusy() then
                    DrawText3D(loc.x, loc.y, loc.z + 0.6, "~y~Harvesting...")
                else
                    DrawText3D(loc.x, loc.y, loc.z + 0.6, "~g~[E]~s~ Harvest Weed")

                    if dist <= 2.2 and IsControlJustReleased(0, 38) then
                        TriggerServerEvent("cfx-keydi-weedfarm:server:startHarvest", i)
                        Wait(500)
                    end
                end
            end
        end

        -- 2. Collect Stations (if any configured)
        for i, station in ipairs(Config.WeedFarm.CollectStations or {}) do
            local c = station.coords
            local stationPos = vector3(c.x, c.y, c.z)
            local dist = #(pCoords - stationPos)
            if dist <= 6.0 then
                sleep = 0
                local zPos = c.z + 0.95
                if collectCooldowns[i] then
                    DrawText3D(c.x, c.y, zPos, "~r~Cooling down...")
                elseif IsBusy() then
                    DrawText3D(c.x, c.y, zPos, "~y~Busy...")
                else
                    DrawText3D(c.x, c.y, zPos, ("~g~[E]~s~ %s"):format(station.label or "Collect"))

                    if dist <= 2.2 and IsControlJustReleased(0, 38) then
                        TriggerServerEvent("cfx-keydi-weedfarm:server:startCollect", i)
                        Wait(500)
                    end
                end
            end
        end

        -- 3. Process Stations (Packaging & Rolling Benches)
        for i, station in ipairs(Config.WeedFarm.ProcessStations or {}) do
            local c = station.coords
            local stationPos = vector3(c.x, c.y, c.z)
            local dist = #(pCoords - stationPos)
            if dist <= 8.0 then
                sleep = 0
                local zPos = c.z + 0.95
                if IsBusy() then
                    DrawText3D(c.x, c.y, zPos, "~y~Processing...")
                else
                    local hint
                    local reqList = station.requires or (station.require and { station.require }) or {}
                    if #reqList > 0 then
                        local reqLabels = {}
                        for _, r in ipairs(reqList) do
                            local amt = r.amount or 1
                            if r.isMoney or r.item == "black_money" then
                                table.insert(reqLabels, ("$%s %s"):format(amt >= 1000 and (math.floor(amt / 1000) .. "K") or amt, r.label or "Dirty Money"))
                            else
                                table.insert(reqLabels, (amt > 1 and (amt .. "x ") or "") .. (r.label or r.item))
                            end
                        end
                        hint = ("~g~[E]~s~ %s ~c~(need %s)"):format(station.label or "Process", table.concat(reqLabels, ", "))
                    else
                        hint = ("~g~[E]~s~ %s"):format(station.label or "Process")
                    end
                    DrawText3D(c.x, c.y, zPos, hint)

                    if dist <= 2.5 and IsControlJustReleased(0, 38) then
                        TriggerServerEvent("cfx-keydi-weedfarm:server:startProcess", i)
                        Wait(500)
                    end
                end
            end
        end

        -- 4. Meth harvest trays
        local meth = Config.MethFarm
        if meth and meth.Locations then
            for i, loc in ipairs(meth.Locations) do
                local dist = #(pCoords - loc)
                if dist <= 6.0 then
                    sleep = 0
                    if IsBusy() then
                        DrawText3D(loc.x, loc.y, loc.z + 0.6, "~y~Harvesting...")
                    else
                        DrawText3D(loc.x, loc.y, loc.z + 0.6, "~g~[E]~s~ Harvest Meth")

                        if dist <= 2.2 and IsControlJustReleased(0, 38) then
                            TriggerServerEvent("cfx-keydi-methfarm:server:startHarvest", i)
                            Wait(500)
                        end
                    end
                end
            end
        end

        -- 5. Meth process benches
        if meth and meth.ProcessStations then
            for i, station in ipairs(meth.ProcessStations) do
                local c = station.coords
                local stationPos = vector3(c.x, c.y, c.z)
                local dist = #(pCoords - stationPos)
                if dist <= 8.0 then
                    sleep = 0
                    local zPos = c.z + 0.95
                    if IsBusy() then
                        DrawText3D(c.x, c.y, zPos, "~y~Processing...")
                    else
                        local hint
                        local reqList = station.requires or (station.require and { station.require }) or {}
                        if #reqList > 0 then
                            local reqLabels = {}
                            for _, r in ipairs(reqList) do
                                local amt = r.amount or 1
                                table.insert(reqLabels, (amt > 1 and (amt .. "x ") or "") .. (r.label or r.item))
                            end
                            hint = ("~g~[E]~s~ %s ~c~(need %s)"):format(station.label or "Process", table.concat(reqLabels, ", "))
                        else
                            hint = ("~g~[E]~s~ %s"):format(station.label or "Process")
                        end
                        DrawText3D(c.x, c.y, zPos, hint)

                        if dist <= 2.5 and IsControlJustReleased(0, 38) then
                            TriggerServerEvent("cfx-keydi-methfarm:server:startProcess", i)
                            Wait(500)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Weed plant harvest (No HUD popup container, instant repeat harvest)
RegisterNetEvent("cfx-keydi-weedfarm:client:harvestStarted", function(plantIndex, duration)
    if IsBusy() then return end
    isHarvesting = true

    duration = duration or Config.WeedFarm.HarvestDuration or 4000
    local itemLabel = Config.WeedFarm.ItemLabel or "Weed Bud"

    local success = RunProgress(duration, ("Harvesting %s…"):format(itemLabel), {
        dict = "amb@world_human_gardener_plant@male@base",
        clip = "base",
    })

    if not success then
        isHarvesting = false
        TriggerServerEvent("cfx-keydi-weedfarm:server:cancelAction")
        return
    end

    isHarvesting = false
    TriggerServerEvent("cfx-keydi-weedfarm:server:completeHarvest", plantIndex)
end)

-- Collect station
RegisterNetEvent("cfx-keydi-weedfarm:client:collectStarted", function(stationIndex, duration, progressLabel, itemLabel)
    if IsBusy() then return end
    isCollecting = true
    collectCooldowns[stationIndex] = true

    duration = duration or Config.WeedFarm.CollectDuration or 4000
    local success = RunProgress(duration, progressLabel or ("Collecting %s…"):format(itemLabel or "Item"), {
        dict = "amb@prop_human_parking_meter@male@base",
        clip = "base",
    })

    if not success then
        isCollecting = false
        collectCooldowns[stationIndex] = nil
        TriggerServerEvent("cfx-keydi-weedfarm:server:cancelAction")
        return
    end

    isCollecting = false
    TriggerServerEvent("cfx-keydi-weedfarm:server:completeCollect", stationIndex)
end)

RegisterNetEvent("cfx-keydi-weedfarm:client:syncCollectCooldown", function(stationIndex, state)
    if state then
        collectCooldowns[stationIndex] = true
    else
        collectCooldowns[stationIndex] = nil
    end
end)

RegisterNetEvent("cfx-keydi-weedfarm:client:collectDenied", function(reason)
    isCollecting = false
    if reason == "cooldown" then
        ESX.ShowNotification("~r~This spot is cooling down.")
    elseif reason == "busy" then
        ESX.ShowNotification("~r~Already busy.")
    elseif reason == "distance" then
        ESX.ShowNotification("~r~Too far from the collect spot.")
    elseif reason == "wrong_server" then
        ESX.ShowNotification("~r~" .. ((ConfigServerLocations and ConfigServerLocations.WrongServerMessage)
            and ConfigServerLocations.WrongServerMessage("grind")
            or "Weed farm is only available on Server #2 · Grind."))
    else
        ESX.ShowNotification("~r~Cannot collect right now.")
    end
end)

-- Process station progress
RegisterNetEvent("cfx-keydi-weedfarm:client:processStarted", function(stationIndex, duration, progressLabel, itemLabel)
    if IsBusy() then return end
    isProcessing = true

    duration = duration or Config.WeedFarm.ProcessDuration or 5000

    local success = RunProgress(duration, progressLabel or ("Processing %s…"):format(itemLabel or "Item"), {
        dict = "amb@prop_human_parking_meter@male@base",
        clip = "base",
    })

    if not success then
        isProcessing = false
        TriggerServerEvent("cfx-keydi-weedfarm:server:cancelAction")
        return
    end

    isProcessing = false
    TriggerServerEvent("cfx-keydi-weedfarm:server:completeProcess", stationIndex)
end)

RegisterNetEvent("cfx-keydi-weedfarm:client:processDenied", function(reason, itemLabel, amount)
    isProcessing = false
    if reason == "missing_input" then
        if itemLabel and amount then
            ESX.ShowNotification(("~r~Missing required material: %sx %s."):format(amount, itemLabel))
        else
            ESX.ShowNotification("~r~Not enough materials to process.")
        end
    elseif reason == "missing_require" then
        if itemLabel and amount then
            if itemLabel == "Dirty Money" or itemLabel == "black_money" then
                ESX.ShowNotification(("~r~Missing required $%s %s."):format(amount, itemLabel))
            else
                ESX.ShowNotification(("~r~Missing required item: %sx %s."):format(amount, itemLabel))
            end
        else
            ESX.ShowNotification("~r~Missing required item.")
        end
    elseif reason == "busy" then
        ESX.ShowNotification("~r~Already processing.")
    elseif reason == "distance" then
        ESX.ShowNotification("~r~Too far from the process station.")
    elseif reason == "wrong_server" then
        ESX.ShowNotification("~r~" .. ((ConfigServerLocations and ConfigServerLocations.WrongServerMessage)
            and ConfigServerLocations.WrongServerMessage("grind")
            or "Weed farm is only available on Server #2 · Grind."))
    else
        ESX.ShowNotification("~r~Cannot process right now.")
    end
end)

-- Server Sync for Plant Regrow Cooldown (disabled for unli harvest)
RegisterNetEvent("cfx-keydi-weedfarm:client:syncCooldown", function(plantIndex, state)
    -- unli harvest enabled: plants do not lock out
end)

RegisterNetEvent("cfx-keydi-methfarm:client:harvestStarted", function(plantIndex, duration)
    if IsBusy() then return end
    isHarvesting = true

    local meth = Config.MethFarm or {}
    duration = duration or meth.HarvestDuration or 4000
    local itemLabel = meth.ItemLabel or "Stoned Meth"

    local success = RunProgress(duration, ("Harvesting %s…"):format(itemLabel), {
        dict = "amb@world_human_gardener_plant@male@base",
        clip = "base",
    })

    if not success then
        isHarvesting = false
        TriggerServerEvent("cfx-keydi-weedfarm:server:cancelAction")
        return
    end

    isHarvesting = false
    TriggerServerEvent("cfx-keydi-methfarm:server:completeHarvest", plantIndex)
end)

RegisterNetEvent("cfx-keydi-methfarm:client:processStarted", function(stationIndex, duration, progressLabel, itemLabel)
    if IsBusy() then return end
    isProcessing = true

    local meth = Config.MethFarm or {}
    duration = duration or meth.ProcessDuration or 5000

    local success = RunProgress(duration, progressLabel or ("Processing %s…"):format(itemLabel or "Item"), {
        dict = "amb@prop_human_parking_meter@male@base",
        clip = "base",
    })

    if not success then
        isProcessing = false
        TriggerServerEvent("cfx-keydi-weedfarm:server:cancelAction")
        return
    end

    isProcessing = false
    TriggerServerEvent("cfx-keydi-methfarm:server:completeProcess", stationIndex)
end)

RegisterNetEvent("cfx-keydi-methfarm:client:processDenied", function(reason, itemLabel, amount)
    isProcessing = false
    if reason == "missing_input" then
        if itemLabel and amount then
            ESX.ShowNotification(("~r~Missing required material: %sx %s."):format(amount, itemLabel))
        else
            ESX.ShowNotification("~r~Not enough materials to process.")
        end
    elseif reason == "missing_require" then
        if itemLabel and amount then
            ESX.ShowNotification(("~r~Missing required item: %sx %s."):format(amount, itemLabel))
        else
            ESX.ShowNotification("~r~Missing required item.")
        end
    elseif reason == "busy" then
        ESX.ShowNotification("~r~Already processing.")
    elseif reason == "distance" then
        ESX.ShowNotification("~r~Too far from the process station.")
    elseif reason == "wrong_server" then
        ESX.ShowNotification("~r~" .. ((ConfigServerLocations and ConfigServerLocations.WrongServerMessage)
            and ConfigServerLocations.WrongServerMessage("grind")
            or "Meth farm is only available on Region 1."))
    else
        ESX.ShowNotification("~r~Cannot process right now.")
    end
end)

-- Clean up on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, obj in ipairs(spawnedPlants) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
    DeleteMethProps()
end)

AddEventHandler("cfx-keydi-serverlocations:changed", function(location)
    SpawnPlantProps()
    SpawnMethProps()
end)

RegisterNetEvent("esx:playerLoaded", function()
    Wait(1000)
    SpawnPlantProps()
    SpawnMethProps()
end)
