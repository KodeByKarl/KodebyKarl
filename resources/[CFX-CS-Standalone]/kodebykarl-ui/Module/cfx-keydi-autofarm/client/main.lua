local ESX = exports["es_extended"]:getSharedObject()

local isVisible = false
local isFarming = false
local itemCount = 0
local cycleProgress = 0.0
local activeFarmIndex = nil
local activeLocationIndex = nil
local inventoryWeight = 0
local inventoryMaxWeight = 0
local itemData = nil
local activeItemName = nil
local itemErrorShown = false
local inventoryFull = false
local farmBlips = {}
local spawnedProps = {}
local cycleStartAt = 0
local pendingStart = false
local activeTargetEntity = nil
local activeTargetCoords = nil
local registeredTargetModels = {}

-- Session stats (for cancel report + live forecast)
local sessionStartedAt = 0
local sessionGathered = 0
local sessionWeightGained = 0
local sessionActive = false

local function GetActiveFarm()
    return activeFarmIndex and ConfigAutofarm.Farms[activeFarmIndex] or nil
end

local function GetFarmZone(farm)
    if not farm then return "Unknown Zone" end
    if type(farm.zone) == "string" and farm.zone ~= "" then
        return farm.zone
    end
    if farm.blip and type(farm.blip.label) == "string" and farm.blip.label ~= "" then
        return farm.blip.label
    end
    return "Farm Zone"
end

local function GetFarmRarity(farm)
    if not farm then return "common" end
    if type(farm.rarity) == "string" and farm.rarity ~= "" then
        return string.lower(farm.rarity)
    end
    -- Auto-tag farms with rare drop tables
    if farm.drops then
        for _, drop in ipairs(farm.drops) do
            local item = drop.item
            if item == "diamond" or item == "emerald" or item == "kevlar" or item == "titanium" then
                return "rare"
            end
        end
        return "uncommon"
    end
    return "common"
end

local function ResetSessionStats()
    sessionStartedAt = 0
    sessionGathered = 0
    sessionWeightGained = 0
    sessionActive = false
end

local function BeginSessionStats()
    sessionStartedAt = GetGameTimer()
    sessionGathered = 0
    sessionWeightGained = 0
    sessionActive = true
end

local function GetAvgPerCycle(farm)
    local minAmount = (farm and farm.minAmount) or ConfigAutofarm.Farming.minAmount or 1
    local maxAmount = (farm and farm.maxAmount) or ConfigAutofarm.Farming.maxAmount or minAmount
    if maxAmount < minAmount then
        maxAmount = minAmount
    end
    return (minAmount + maxAmount) / 2.0
end

---Estimate how many more items fit + seconds until inventory weight is full.
local function GetYieldForecast()
    local farm = GetActiveFarm()
    local itemWeight = (itemData and itemData.weight) or 0
    if not farm or itemWeight <= 0 or inventoryMaxWeight <= 0 then
        return 0, 0
    end

    -- Free carry capacity (ox weight units) → how many of this item still fit
    local freeWeight = math.max(0, inventoryMaxWeight - inventoryWeight)
    local untilFull = math.floor(freeWeight / itemWeight)
    if untilFull < 0 then untilFull = 0 end

    -- Bag already full
    if untilFull < 1 then
        return 0, 0
    end

    local avgPerCycle = GetAvgPerCycle(farm)
    if avgPerCycle < 0.1 then avgPerCycle = 1.0 end

    local cycleMs = ConfigAutofarm.Farming.cycleTime or 10000
    -- Cycles needed to fill remaining bag space at average yield
    local cyclesNeeded = math.ceil(untilFull / avgPerCycle)
    local etaSeconds = 0

    if cyclesNeeded > 0 then
        -- If currently farming, count remaining time on this cycle first
        local remainingCycleFrac = 1.0
        if isFarming then
            remainingCycleFrac = math.max(0.0, 1.0 - cycleProgress)
        end
        local etaMs = (remainingCycleFrac * cycleMs) + (math.max(0, cyclesNeeded - 1) * cycleMs)
        etaSeconds = math.max(1, math.ceil(etaMs / 1000.0))
    end

    return untilFull, etaSeconds
end

local function GetPlayerJobName()
    local playerData = ESX and ESX.GetPlayerData and ESX.GetPlayerData()
    return playerData and playerData.job and playerData.job.name
end

local function PlayerCanUseFarm(farm)
    if not farm or not farm.job then return true end

    local playerJob = GetPlayerJobName()
    if not playerJob then return false end

    if type(farm.job) == "table" then
        for key, value in pairs(farm.job) do
            if type(key) == "number" then
                if playerJob == value then return true end
            elseif playerJob == key and value then
                return true
            end
        end
        return false
    end

    return playerJob == farm.job
end

local function GetLocationCoords(location)
    return vector3(location.x, location.y, location.z)
end

local function GetActiveCoords()
    if activeTargetCoords then
        return activeTargetCoords
    end

    local farm = GetActiveFarm()
    if not farm or not activeLocationIndex then return nil end
    local location = farm.locations and farm.locations[activeLocationIndex]
    if not location then return nil end
    return GetLocationCoords(location)
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.015 + factor, 0.03, 5, 25, 47, 190)
    ClearDrawOrigin()
end

local function SpawnFarmProps()
    for farmIndex, farm in ipairs(ConfigAutofarm.Farms) do
        if farm.prop and farm.locations then
            local modelHash = type(farm.prop) == "number" and farm.prop or joaat(farm.prop)
            RequestModel(modelHash)

            local timeout = GetGameTimer() + 5000
            while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
                Wait(50)
            end

            if not HasModelLoaded(modelHash) then
                print(("[Autofarm] Failed to load prop model '%s'"):format(tostring(farm.prop)))
            else
                spawnedProps[farmIndex] = spawnedProps[farmIndex] or {}

                for locationIndex, loc in ipairs(farm.locations) do
                    local existingObj = GetClosestObjectOfType(loc.x, loc.y, loc.z, 1.0, modelHash, false, false, false)
                    local obj = existingObj

                    if obj == 0 or not DoesEntityExist(obj) then
                        obj = CreateObject(modelHash, loc.x, loc.y, loc.z - 1.0, false, false, false)
                        SetEntityHeading(obj, loc.w or 0.0)
                        PlaceObjectOnGroundProperly(obj)
                        FreezeEntityPosition(obj, true)
                    end

                    spawnedProps[farmIndex][locationIndex] = obj
                end

                SetModelAsNoLongerNeeded(modelHash)
            end
        end
    end
end

local function DeleteFarmProps()
    for _, props in pairs(spawnedProps) do
        for _, obj in pairs(props) do
            if obj and DoesEntityExist(obj) then
                DeleteEntity(obj)
            end
        end
    end
    spawnedProps = {}
end

local function RefreshInventoryStats()
    local farm = GetActiveFarm()
    if not farm or not itemData then return end

    inventoryWeight = exports.ox_inventory:GetPlayerWeight() or 0
    inventoryMaxWeight = exports.ox_inventory:GetPlayerMaxWeight() or 0
    itemCount = tonumber(exports.ox_inventory:Search("count", activeItemName or farm.item)) or 0
    inventoryFull = inventoryMaxWeight > 0
        and (inventoryWeight + itemData.weight) > inventoryMaxWeight
end

local function SetDisplayedItem(itemName)
    local farm = GetActiveFarm()
    if not farm then return false end

    itemName = itemName or farm.item
    local item = exports.ox_inventory:Items(itemName)

    activeItemName = itemName
    itemData = {
        label = (item and item.label) or itemName,
        weight = (item and item.weight) or 0,
        image = item and item.client and item.client.image
            or ("nui://ox_inventory/web/images/%s.png"):format(itemName),
    }
    RefreshInventoryStats()
    return item ~= nil
end

local function RefreshOxData()
    local farm = GetActiveFarm()
    if not farm then return false end
    return SetDisplayedItem(activeItemName or farm.item)
end

local function GetStatus()
    if inventoryFull then
        return "full"
    end
    return isFarming and "farming" or "idle"
end

local function SendHudState(action)
    local farm = GetActiveFarm()
    if not farm then return end

    local untilFull, etaSeconds = GetYieldForecast()

    SendNUIMessage({
        action = action or "cfx-keydi-autofarm:update",
        data = {
            status = GetStatus(),
            label = itemData and itemData.label or farm.item,
            image = itemData and itemData.image or nil,
            itemWeight = itemData and itemData.weight or 0,
            collected = itemCount,
            weight = inventoryWeight,
            maxWeight = inventoryMaxWeight,
            progress = cycleProgress,
            zone = GetFarmZone(farm),
            rarity = GetFarmRarity(farm),
            untilFull = untilFull,
            etaSeconds = etaSeconds,
        },
    })
end

local function ShowSessionReport()
    ResetSessionStats()
end

local function ShowHud(force)
    local farm = GetActiveFarm()
    if not farm then return end

    local hasItem = RefreshOxData()
    if not hasItem then
        -- Still show the apple/mango Autofarm container with a fallback label.
        if not itemData then
            itemData = {
                label = farm.item,
                weight = 0,
                image = ("nui://ox_inventory/web/images/%s.png"):format(farm.item),
            }
            activeItemName = farm.item
        end
        if not itemErrorShown then
            itemErrorShown = true
            ESX.ShowNotification(("[Auto Farm] Item '%s' is not registered in ox_inventory"):format(farm.item), "error")
        end
    else
        itemErrorShown = false
    end

    if isVisible and not force then
        SendHudState()
        return
    end

    isVisible = true
    SendHudState("cfx-keydi-autofarm:show")
end

local function HideHud()
    if not isVisible then return end
    isVisible = false
    SendNUIMessage({ action = "cfx-keydi-autofarm:hide" })
end

local function PlayFarmAnim()
    local farm = GetActiveFarm()
    local ped = PlayerPedId()
    if farm and farm.scenario then
        TaskStartScenarioInPlace(ped, farm.scenario, 0, true)
        return
    end

    local settings = ConfigAutofarm.Farming
    local animDict = (farm and farm.animDict) or settings.animDict
    local animName = (farm and farm.animName) or settings.animName
    if not animDict or animDict == "" then return end

    RequestAnimDict(animDict)
    local timeout = GetGameTimer() + 2000
    while not HasAnimDictLoaded(animDict) and GetGameTimer() < timeout do
        Wait(10)
    end

    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(ped, animDict, animName, 4.0, -4.0, -1, 1, 0, false, false, false)
    end
end

local function StopFarmAnim()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
end

local function ResetFarmingVisuals()
    isFarming = false
    pendingStart = false
    cycleProgress = 0.0
    cycleStartAt = 0
    StopFarmAnim()
end

---silent: no toast. isCancel: show session report (X), not pause (E).
local function RequestStopFarming(silent, isCancel)
    if not isFarming and not pendingStart then return end

    local wasFarming = isFarming or sessionActive
    TriggerServerEvent("cfx-keydi-autofarm:stop")
    ResetFarmingVisuals()

    if isCancel and wasFarming then
        ShowSessionReport()
    end

    SendHudState()

    if not silent and not isCancel then
        ESX.ShowNotification("[Auto Farm] Paused", "info")
    elseif not silent and isCancel then
        ESX.ShowNotification("[Auto Farm] Cancelled", "info")
    end
end

local function ClearActiveTarget(hideHud)
    activeTargetEntity = nil
    activeTargetCoords = nil

    if hideHud then
        HideHud()
        activeFarmIndex = nil
        activeLocationIndex = nil
        itemData = nil
        activeItemName = nil
        itemErrorShown = false
        inventoryFull = false
    end
end

local function RequestStartFarming()
    RefreshOxData()
    if isFarming or pendingStart or inventoryFull then return end
    if not activeFarmIndex then return end

    if ConfigServerLocations and ConfigServerLocations.CanUseFunction then
        if not (ConfigServerLocations.CanUseFunction("grind") or ConfigServerLocations.CanUseFunction("autofarm")) then
            ESX.ShowNotification(ConfigServerLocations.WrongServerMessage("grind"), "error")
            return
        end
    end

    local farm = GetActiveFarm()
    if not farm then return end

    if farm.targetModel then
        if not activeTargetCoords then return end
    elseif not activeLocationIndex then
        return
    end

    if not PlayerCanUseFarm(farm) then
        ESX.ShowNotification("[Auto Farm] Only authorized staff can do this activity", "error")
        return
    end

    if farm.requireTool then
        local haveTool = tonumber(exports.ox_inventory:Search("count", farm.requireTool)) or 0
        if haveTool < 1 and farm.requireTool == "battleaxe" then
            haveTool = tonumber(exports.ox_inventory:Search("count", "WEAPON_BATTLEAXE")) or 0
        end
        if haveTool < 1 then
            local label = farm.requireTool
            local toolItem = exports.ox_inventory:Items(farm.requireTool) or exports.ox_inventory:Items("WEAPON_BATTLEAXE")
            if toolItem and toolItem.label then
                label = toolItem.label
            end
            ESX.ShowNotification(("[Auto Farm] You need a %s to harvest"):format(label), "error")
            return
        end
    end

    pendingStart = true
    if farm.targetModel then
        TriggerServerEvent("cfx-keydi-autofarm:start", activeFarmIndex, 0, activeTargetCoords)
    else
        TriggerServerEvent("cfx-keydi-autofarm:start", activeFarmIndex, activeLocationIndex)
    end
end

local function BeginTargetFarm(farmIndex, entity)
    farmIndex = tonumber(farmIndex) or 0
    local farm = ConfigAutofarm.Farms[farmIndex]
    if not farm or not farm.targetModel then return end
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    if activeFarmIndex and activeFarmIndex ~= farmIndex then
        RequestStopFarming(true)
        ClearActiveTarget(true)
    elseif isFarming or pendingStart then
        RequestStopFarming(true)
    end

    activeFarmIndex = farmIndex
    activeLocationIndex = 0
    activeTargetEntity = entity
    activeTargetCoords = GetEntityCoords(entity)
    itemData = nil
    activeItemName = nil
    inventoryFull = false
    itemErrorShown = false

    ShowHud(true)
    RequestStartFarming()
end

RegisterNetEvent("cfx-keydi-autofarm:started", function(farmIndex, locationIndex)
    farmIndex = tonumber(farmIndex) or 0
    locationIndex = tonumber(locationIndex) or 0
    pendingStart = false

    local farm = ConfigAutofarm.Farms[farmIndex]
    local isTargetFarm = farm and farm.targetModel ~= nil

    if activeFarmIndex ~= farmIndex then
        TriggerServerEvent("cfx-keydi-autofarm:stop")
        return
    end

    if not isTargetFarm and activeLocationIndex ~= locationIndex then
        TriggerServerEvent("cfx-keydi-autofarm:stop")
        return
    end

    isFarming = true
    inventoryFull = false
    cycleProgress = 0.0
    cycleStartAt = GetGameTimer()
    if not sessionActive then
        BeginSessionStats()
    end
    PlayFarmAnim()
    ShowHud(true)
    SendHudState()
end)

RegisterNetEvent("cfx-keydi-autofarm:startDenied", function(reason, requireItem)
    pendingStart = false
    ResetFarmingVisuals()
    SendHudState()

    if reason == "distance" then
        ESX.ShowNotification("[Auto Farm] Move closer to the marker", "error")
    elseif reason == "missing_input" then
        local label = requireItem or "required item"
        local item = requireItem and exports.ox_inventory:Items(requireItem)
        if item and item.label then
            label = item.label
        end
        ESX.ShowNotification(("[Auto Farm] You need %s"):format(label), "error")
    elseif reason == "missing_tool" then
        local label = requireItem or "required tool"
        local item = requireItem and exports.ox_inventory:Items(requireItem)
        if item and item.label then
            label = item.label
        end
        ESX.ShowNotification(("[Auto Farm] You need a %s to harvest"):format(label), "error")
    elseif reason == "job_required" then
        ESX.ShowNotification(("[Auto Farm] Only authorized %s staff can do this activity"):format(string.upper(tostring(requireItem or "service"))), "error")
    elseif reason == "wrong_server" then
        local msg = (ConfigServerLocations and ConfigServerLocations.WrongServerMessage)
            and ConfigServerLocations.WrongServerMessage("grind")
            or "Autofarm is only available on Server #2 · Grind."
        ESX.ShowNotification(msg, "error")
    end
end)

RegisterNetEvent("cfx-keydi-autofarm:stopped", function()
    ResetFarmingVisuals()
    SendHudState()
end)

RegisterNetEvent("cfx-keydi-autofarm:collected", function(farmIndex, itemName, amount)
    if activeFarmIndex ~= (tonumber(farmIndex) or 0) then return end

    amount = tonumber(amount) or 0
    if amount > 0 and sessionActive then
        sessionGathered = sessionGathered + amount
        local unitWeight = (itemData and itemData.weight) or 0
        -- Prefer weight of the item that was just granted
        local granted = exports.ox_inventory:Items(itemName)
        if granted and granted.weight then
            unitWeight = granted.weight
        end
        sessionWeightGained = sessionWeightGained + (unitWeight * amount)
    end

    -- Presentation-only ring reset; the server owns the real reward timer.
    cycleStartAt = GetGameTimer()
    cycleProgress = 0.0
    SetDisplayedItem(itemName)
    SendHudState()
end)

RegisterNetEvent("cfx-keydi-autofarm:missingInput", function(farmIndex, requireItem)
    ResetFarmingVisuals()
    local label = requireItem or "required item"
    local item = requireItem and exports.ox_inventory:Items(requireItem)
    if item and item.label then
        label = item.label
    end
    ESX.ShowNotification(("[Auto Farm] Out of %s"):format(label), "error")

    if activeFarmIndex == (tonumber(farmIndex) or 0) then
        SendHudState()
    end
end)

RegisterNetEvent("cfx-keydi-autofarm:inventoryFull", function(farmIndex)
    RefreshInventoryStats()
    inventoryFull = true
    ResetFarmingVisuals()
    ESX.ShowNotification("[Auto Farm] You cannot carry any more", "error")

    if activeFarmIndex == (tonumber(farmIndex) or 0) then
        SendHudState()
    end
end)

exports("IsAutofarming", function()
    return isFarming
end)

local function CanShowFarmBlips()
    return not ConfigServerLocations or not ConfigServerLocations.CanUseFunction
        or ConfigServerLocations.CanUseFunction("grind")
        or ConfigServerLocations.CanUseFunction("autofarm")
end

local function ClearFarmBlips()
    for _, blip in ipairs(farmBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    farmBlips = {}
end

local function CreateFarmBlips()
    ClearFarmBlips()

    if not CanShowFarmBlips() then return end

    local defaults = ConfigAutofarm.BlipDefaults or {}

    for _, farm in ipairs(ConfigAutofarm.Farms) do
        if farm.targetModel or not PlayerCanUseFarm(farm) then
            goto continue
        end

        local settings = farm.blip
        local firstLocation = farm.locations and farm.locations[1]
        if settings and firstLocation then
            local blip = AddBlipForCoord(firstLocation.x, firstLocation.y, firstLocation.z)
            SetBlipSprite(blip, settings.sprite or 1)
            SetBlipColour(blip, settings.color or 0)
            SetBlipScale(blip, settings.scale or defaults.scale or 0.8)
            SetBlipAsShortRange(blip, (settings.shortRange ~= false) and (defaults.shortRange ~= false))
            SetBlipDisplay(blip, settings.display or defaults.display or 4)
            SetBlipHighDetail(blip, true)
            SetBlipCategory(blip, settings.category or defaults.category or 1)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(settings.label or farm.item)
            EndTextCommandSetBlipName(blip)

            farmBlips[#farmBlips + 1] = blip
        end

        ::continue::
    end

    for _, settings in ipairs(ConfigAutofarm.ExtraBlips or {}) do
        local coords = settings.coords
        if coords then
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, settings.sprite or 478)
            SetBlipColour(blip, settings.color or 2)
            SetBlipScale(blip, settings.scale or defaults.scale or 0.8)
            SetBlipAsShortRange(blip, (settings.shortRange ~= false) and (defaults.shortRange ~= false))
            SetBlipDisplay(blip, settings.display or defaults.display or 4)
            SetBlipHighDetail(blip, true)
            SetBlipCategory(blip, settings.category or defaults.category or 1)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(settings.label or "Auto Farm")
            EndTextCommandSetBlipName(blip)

            farmBlips[#farmBlips + 1] = blip
        end
    end
end

local function OnJobChanged()
    local farm = GetActiveFarm()
    if farm and not PlayerCanUseFarm(farm) then
        RequestStopFarming(true)
        ResetSessionStats()
        ClearActiveTarget(true)
    end
    CreateFarmBlips()
end

CreateThread(function()
    CreateFarmBlips()
end)

RegisterNetEvent("esx:playerLoaded", function()
    CreateFarmBlips()
end)

RegisterNetEvent("esx:setJob", function()
    OnJobChanged()
end)

local function RegisterTargetFarms()
    if GetResourceState("ox_target") ~= "started" then
        print("[Autofarm] ox_target is not started — target-model grind farms disabled.")
        return
    end

    for farmIndex, farm in ipairs(ConfigAutofarm.Farms) do
        if farm.targetModel then
            local model = farm.targetModel
            local optionName = ("cfx_keydi_autofarm_target_%s"):format(farmIndex)
            local label = (farm.blip and farm.blip.label) or ("Harvest %s"):format(farm.item)

            exports.ox_target:addModel(model, {
                {
                    name = optionName,
                    icon = "fa-solid fa-seedling",
                    label = label,
                    distance = farm.interactionDistance or 2.5,
                    canInteract = function(entity)
                        if not DoesEntityExist(entity) then return false end
                        if isFarming or pendingStart then
                            return activeFarmIndex == farmIndex and activeTargetEntity == entity
                        end
                        return true
                    end,
                    onSelect = function(data)
                        local entity = data and data.entity
                        if isFarming or pendingStart then
                            if activeFarmIndex == farmIndex and activeTargetEntity == entity then
                                RequestStopFarming(false, true)
                                ClearActiveTarget(true)
                            end
                            return
                        end
                        BeginTargetFarm(farmIndex, entity)
                    end,
                },
            })

            registeredTargetModels[#registeredTargetModels + 1] = {
                model = model,
                name = optionName,
            }
        end
    end
end

CreateThread(function()
    Wait(1000)
    local canGrind = not ConfigServerLocations or not ConfigServerLocations.CanUseFunction
        or ConfigServerLocations.CanUseFunction("grind")
        or ConfigServerLocations.CanUseFunction("autofarm")
    if canGrind then
        SpawnFarmProps()
    end
    RegisterTargetFarms()
end)

-- Keep target-model sessions alive while near the prop (HUD + distance).
CreateThread(function()
    while true do
        local sleep = 500
        local farm = GetActiveFarm()

        if farm and farm.targetModel and activeTargetCoords then
            sleep = 0
            local playerCoords = GetEntityCoords(PlayerPedId())

            if activeTargetEntity and DoesEntityExist(activeTargetEntity) then
                activeTargetCoords = GetEntityCoords(activeTargetEntity)
            end

            local interactDistance = farm.interactionDistance or ConfigAutofarm.Marker.interactionDistance
            local distance = #(playerCoords - activeTargetCoords)
            local label = (itemData and itemData.label) or farm.item

            if distance <= interactDistance then
                ShowHud()

                if inventoryFull then
                    DrawText3D(activeTargetCoords.x, activeTargetCoords.y, activeTargetCoords.z + 1.0, "~r~Inventory Full")
                elseif isFarming then
                    DrawText3D(activeTargetCoords.x, activeTargetCoords.y, activeTargetCoords.z + 1.0, ("~y~Farming %s..."):format(label))
                else
                    DrawText3D(activeTargetCoords.x, activeTargetCoords.y, activeTargetCoords.z + 1.0, ("~g~[E]~s~ Harvest %s"):format(label))
                end

                if IsControlJustPressed(0, ConfigAutofarm.Controls.start) then
                    if isFarming or pendingStart then
                        RequestStopFarming()
                    else
                        RequestStartFarming()
                    end
                elseif IsControlJustPressed(0, ConfigAutofarm.Controls.cancel) then
                    RequestStopFarming(false, true)
                    ClearActiveTarget(true)
                end
            else
                RequestStopFarming(true)
                ResetSessionStats()
                ClearActiveTarget(true)
            end
        end

        Wait(sleep)
    end
end)

-- Live inventory sync while the panel is open.
CreateThread(function()
    while true do
        if isVisible then
            RefreshInventoryStats()

            if isFarming and cycleStartAt > 0 then
                local elapsed = GetGameTimer() - cycleStartAt
                cycleProgress = math.min(elapsed / ConfigAutofarm.Farming.cycleTime, 1.0)
            end

            SendHudState()
        end
        Wait(isVisible and 250 or 1000)
    end
end)

CreateThread(function()
    local marker = ConfigAutofarm.Marker
    local drawDistance = marker.drawDistance

    while true do
        local sleep = 500
        local canGrind = not ConfigServerLocations or not ConfigServerLocations.CanUseFunction
            or ConfigServerLocations.CanUseFunction("grind")
            or ConfigServerLocations.CanUseFunction("autofarm")

        if not canGrind then
            Wait(1500)
        else
        local playerCoords = GetEntityCoords(PlayerPedId())
        local insideFarmIndex = nil
        local insideLocationIndex = nil
        local nearestDistance = drawDistance + 1.0
        local nearestInteractDistance = nil

        for farmIndex, farm in ipairs(ConfigAutofarm.Farms) do
            if farm.targetModel or not PlayerCanUseFarm(farm) then
                goto continue_farm
            end

            local interactDistance = farm.interactionDistance or marker.interactionDistance
            local hasProp = farm.prop ~= nil
            local locations = farm.locations or {}
            local markerZOffset = tonumber(farm.markerZOffset) or 0.0

            for locationIndex, location in ipairs(locations) do
                local markerCoords = GetLocationCoords(location)
                local drawCoords = vector3(markerCoords.x, markerCoords.y, markerCoords.z + markerZOffset)
                local distance = #(playerCoords - markerCoords)

                if distance < nearestDistance then
                    nearestDistance = distance
                end

                if distance <= interactDistance then
                    if not nearestInteractDistance or distance < nearestInteractDistance then
                        nearestInteractDistance = distance
                        insideFarmIndex = farmIndex
                        insideLocationIndex = locationIndex
                    end

                    sleep = 0
                    local isActiveSpot = activeFarmIndex == farmIndex and activeLocationIndex == locationIndex
                    local label = (itemData and itemData.label) or farm.item

                    if inventoryFull and isActiveSpot then
                        DrawText3D(drawCoords.x, drawCoords.y, drawCoords.z + 0.35, "~r~Inventory Full")
                    elseif isFarming and isActiveSpot then
                        DrawText3D(drawCoords.x, drawCoords.y, drawCoords.z + 0.35, ("~y~Farming %s..."):format(label))
                    elseif not isFarming then
                        DrawText3D(drawCoords.x, drawCoords.y, drawCoords.z + 0.35, ("~g~[E]~s~ Harvest %s"):format(label))
                    end
                end

                -- Markers for normal farms; prop farms (cocoa) use 3D text only
                if not hasProp and distance <= drawDistance then
                    sleep = 0
                    DrawMarker(
                        marker.type,
                        drawCoords.x, drawCoords.y, drawCoords.z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, location.w,
                        marker.scale.x, marker.scale.y, marker.scale.z,
                        marker.color.r, marker.color.g, marker.color.b, marker.color.a,
                        marker.bobUpAndDown,
                        marker.faceCamera,
                        2,
                        marker.rotate,
                        nil, nil, false
                    )
                elseif hasProp and distance <= drawDistance and sleep ~= 0 then
                    sleep = 150
                end
            end

            ::continue_farm::
        end

        if nearestDistance <= (drawDistance + 15.0) and sleep ~= 0 then
            sleep = 150
        end

        if insideFarmIndex then
            sleep = 0

            -- Entering a marker farm cancels any active target-model grind.
            if activeTargetEntity or activeTargetCoords then
                RequestStopFarming(true)
                ClearActiveTarget(true)
            end

            if activeFarmIndex ~= insideFarmIndex then
                RequestStopFarming(true)
                HideHud()
                activeFarmIndex = insideFarmIndex
                itemData = nil
                activeItemName = nil
                inventoryFull = false
            elseif activeLocationIndex ~= insideLocationIndex then
                RequestStopFarming(true)
            end

            activeLocationIndex = insideLocationIndex
            ShowHud()

            if IsControlJustPressed(0, ConfigAutofarm.Controls.start) then
                if isFarming or pendingStart then
                    RequestStopFarming()
                else
                    RequestStartFarming()
                end
            elseif IsControlJustPressed(0, ConfigAutofarm.Controls.cancel) then
                RequestStopFarming(false, true)
            end
        elseif activeFarmIndex then
            local activeFarm = ConfigAutofarm.Farms[activeFarmIndex]
            -- Target-model farms are owned by the ox_target proximity thread.
            if not (activeFarm and activeFarm.targetModel) then
                RequestStopFarming(true)
                ResetSessionStats()
                HideHud()
                activeFarmIndex = nil
                activeLocationIndex = nil
                itemData = nil
                activeItemName = nil
                itemErrorShown = false
            end
        end

        Wait(sleep)
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, blip in ipairs(farmBlips) do
        RemoveBlip(blip)
    end

    DeleteFarmProps()

    for _, entry in ipairs(registeredTargetModels) do
        pcall(function()
            exports.ox_target:removeModel(entry.model, entry.name)
        end)
    end
    registeredTargetModels = {}

    if isFarming or pendingStart then
        TriggerServerEvent("cfx-keydi-autofarm:stop")
        StopFarmAnim()
    end
end)

AddEventHandler("cfx-keydi-serverlocations:changed", function(location)
    local enabled = ConfigServerLocations.LocationAllows
        and ConfigServerLocations.LocationAllows(location, "autofarm")
        or ConfigServerLocations.CanUseFunction("grind")
        or ConfigServerLocations.CanUseFunction("autofarm")

    CreateFarmBlips()

    if enabled then
        SpawnFarmProps()
    else
        if isFarming or pendingStart then
            RequestStopFarming(true)
        end
        DeleteFarmProps()
        HideHud()
    end
end)
