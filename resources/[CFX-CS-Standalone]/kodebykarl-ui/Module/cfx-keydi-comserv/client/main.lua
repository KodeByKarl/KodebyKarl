--[[
    cfx-keydi-comserv (client)
    Staff panel + community service HUD / zone / random tasks + props
]]

if not ConfigComServ or not ConfigComServ.Enabled then return end

local ESX = exports["es_extended"]:getSharedObject()

local isServing = false
local remaining = 0
local total = 0
local reason = ""
local isDoingTask = false
local shownTextUITask = nil
local panelOpen = false

-- Current random task state
local currentTask = nil -- { locationIndex, typeIndex, coords, label, type }
local lastLocationIndex = nil
local lastTypeIndex = nil
local taskBlip = nil
local groundProp = nil

local function debugPrint(...)
    if ConfigComServ.Debug then
        print("[cfx-keydi-comserv]", ...)
    end
end

local function hideTaskTextUI()
    if shownTextUITask then
        lib.hideTextUI()
        shownTextUITask = nil
    end
end

local function showTaskTextUI(key, label)
    if shownTextUITask == key then return end
    lib.showTextUI(("[E] %s"):format(label or "Complete task"))
    shownTextUITask = key
end

local function pushHud(action, extra)
    local payload = {
        action = action,
        data = {
            remaining = remaining,
            total = total,
            reason = reason,
            brand = ConfigComServ.Brand or "GRIM CITY",
        },
    }
    if extra then
        for k, v in pairs(extra) do
            payload.data[k] = v
        end
    end
    SendNUIMessage(payload)
end

local function showHud()
    pushHud("cfx-keydi-comserv:show")
end

local function updateHud()
    pushHud("cfx-keydi-comserv:update")
end

local function hideHud()
    SendNUIMessage({ action = "cfx-keydi-comserv:hide" })
end

local function setPanel(state, data)
    panelOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "cfx-keydi-comserv:panel:show" or "cfx-keydi-comserv:panel:hide",
        data = data,
    })
end

local function closePanel()
    if not panelOpen then return end
    setPanel(false, nil)
end

local function openPanel()
    ESX.TriggerServerCallback("cfx-keydi-comserv:open", function(data)
        if not data then
            ESX.ShowNotification(ConfigComServ.Locale.noPermission, "error")
            return
        end
        setPanel(true, data)
    end)
end

local function refreshPanelData(cb)
    ESX.TriggerServerCallback("cfx-keydi-comserv:refresh", function(data)
        if panelOpen and data then
            SendNUIMessage({
                action = "cfx-keydi-comserv:panel:update",
                data = data,
            })
        end
        if cb then cb(data) end
    end)
end

local function teleportToZone()
    local spawn = ConfigComServ.Spawn
    if not spawn then return end
    local ped = PlayerPedId()
    SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    SetEntityHeading(ped, spawn.w or 0.0)
end

local function clearTaskBlip()
    if taskBlip and DoesBlipExist(taskBlip) then
        RemoveBlip(taskBlip)
    end
    taskBlip = nil
end

local function clearGroundProp()
    if groundProp and DoesEntityExist(groundProp) then
        DeleteEntity(groundProp)
    end
    groundProp = nil
end

local function clearCurrentTask()
    hideTaskTextUI()
    clearTaskBlip()
    clearGroundProp()
    currentTask = nil
end

local function loadModel(model)
    local hash = type(model) == "number" and model or joaat(model)
    if not IsModelValid(hash) and not IsModelInCdimage(hash) then
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
            return nil
        end
        Wait(0)
    end
    return hash
end

local function spawnGroundProp(modelName, coords)
    clearGroundProp()
    if not modelName or not coords then return end

    local hash = loadModel(modelName)
    if not hash then return end

    local obj = CreateObject(hash, coords.x, coords.y, coords.z - 0.95, false, false, false)
    if not obj or obj == 0 then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(hash)
    groundProp = obj
end

local function createTaskBlip(coords, label)
    clearTaskBlip()
    if not ConfigComServ.ShowTaskBlip or not coords then return end

    taskBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(taskBlip, 1)
    SetBlipColour(taskBlip, 3)
    SetBlipScale(taskBlip, 0.85)
    SetBlipRoute(taskBlip, true)
    SetBlipRouteColour(taskBlip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(label or "Comserv Task")
    EndTextCommandSetBlipName(taskBlip)
end

local function pickRandomIndex(count, avoid)
    if count <= 0 then return nil end
    if count == 1 then return 1 end

    local idx = math.random(1, count)
    local guard = 0
    while idx == avoid and guard < 12 do
        idx = math.random(1, count)
        guard = guard + 1
    end
    return idx
end

local function assignRandomTask(notifyPlayer)
    local locations = ConfigComServ.TaskLocations or {}
    local types = ConfigComServ.TaskTypes or {}

    -- Backwards compat if old ConfigComServ.Tasks still exists
    if (#locations == 0) and ConfigComServ.Tasks then
        locations = {}
        for i, task in ipairs(ConfigComServ.Tasks) do
            locations[i] = task.coords
        end
    end
    if (#types == 0) and ConfigComServ.Tasks then
        types = {}
        for i, task in ipairs(ConfigComServ.Tasks) do
            types[i] = {
                id = ("legacy_%d"):format(i),
                label = task.label or "Complete task",
                anim = {
                    dict = "anim@amb@drug_field_workers@rake@male_a@base",
                    clip = "base",
                    flag = 1,
                },
                prop = {
                    model = "prop_tool_broom",
                    bone = 28422,
                    pos = vector3(-0.01, 0.04, -0.03),
                    rot = vector3(0.0, 0.0, 0.0),
                },
            }
        end
    end

    if #locations == 0 or #types == 0 then
        currentTask = nil
        return
    end

    local locIndex = pickRandomIndex(#locations, lastLocationIndex)
    local typeIndex = pickRandomIndex(#types, lastTypeIndex)
    local coords = locations[locIndex]
    local taskType = types[typeIndex]

    lastLocationIndex = locIndex
    lastTypeIndex = typeIndex

    currentTask = {
        locationIndex = locIndex,
        typeIndex = typeIndex,
        coords = coords,
        label = taskType.label or "Complete task",
        type = taskType,
    }

    createTaskBlip(coords, currentTask.label)
    spawnGroundProp(taskType.groundProp, coords)

    if notifyPlayer then
        ESX.ShowNotification((ConfigComServ.Locale.newTask or "New task: %s"):format(currentTask.label), "info")
    end

    debugPrint(("New task @ %s — %s"):format(tostring(coords), currentTask.label))
end

local function isMalePed(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01` or IsPedMale(ped)
end

local function applyComServOutfit()
    local outfitCfg = ConfigComServ.Outfit
    if not outfitCfg or not outfitCfg.Enabled then return end

    local ped = PlayerPedId()
    local clothes = isMalePed(ped) and outfitCfg.male or outfitCfg.female
    if type(clothes) ~= "table" then return end

    -- Apply via skinchanger/illenium bridge when available
    TriggerEvent("skinchanger:loadClothes", nil, clothes)

    -- Native components (matches clothing menu IDs)
    if clothes.arms ~= nil then
        SetPedComponentVariation(ped, 3, clothes.arms, clothes.arms_2 or 0, 0) -- Hands
    end
    if clothes.pants_1 ~= nil then
        SetPedComponentVariation(ped, 4, clothes.pants_1, clothes.pants_2 or 0, 0) -- Legs
    end
    if clothes.bags_1 ~= nil then
        SetPedComponentVariation(ped, 5, clothes.bags_1, clothes.bags_2 or 0, 0) -- Bags
    end
    if clothes.shoes_1 ~= nil then
        SetPedComponentVariation(ped, 6, clothes.shoes_1, clothes.shoes_2 or 0, 0) -- Shoes
    end
    if clothes.tshirt_1 ~= nil then
        SetPedComponentVariation(ped, 8, clothes.tshirt_1, clothes.tshirt_2 or 0, 0) -- Shirt
    end
    if clothes.bproof_1 ~= nil then
        SetPedComponentVariation(ped, 9, clothes.bproof_1, clothes.bproof_2 or 0, 0) -- Armor
    end
    if clothes.decals_1 ~= nil then
        SetPedComponentVariation(ped, 10, clothes.decals_1, clothes.decals_2 or 0, 0) -- Decals
    end
    if clothes.torso_1 ~= nil then
        SetPedComponentVariation(ped, 11, clothes.torso_1, clothes.torso_2 or 0, 0) -- Jacket
    end
end

local function restorePlayerOutfit()
    local outfitCfg = ConfigComServ.Outfit
    if not outfitCfg or not outfitCfg.Enabled then return end
    TriggerEvent("illenium-appearance:client:reloadSkin")
end

local function startServing(data)
    isServing = true
    remaining = tonumber(data.remaining) or 0
    total = tonumber(data.total) or remaining
    reason = data.reason or ""
    teleportToZone()
    applyComServOutfit()
    showHud()
    assignRandomTask(true)
    debugPrint(("Started — remaining=%d total=%d"):format(remaining, total))
end

local function stopServing(completed)
    isServing = false
    remaining = 0
    total = 0
    reason = ""
    isDoingTask = false
    lastLocationIndex = nil
    lastTypeIndex = nil
    clearCurrentTask()
    hideHud()
    restorePlayerOutfit()
    if completed then
        ESX.ShowNotification(ConfigComServ.Locale.finished, "success")
    end
    debugPrint("Stopped serving")
end

local function runTaskProgress(taskType, label)
    local duration = ConfigComServ.TaskDurationMs or 5000
    local anim = taskType and taskType.anim or nil
    local propCfg = taskType and taskType.prop or nil
    local startCoords = GetEntityCoords(PlayerPedId())
    local moveCancelDist = ConfigComServ.TaskCancelMoveDistance or 0.4

    local function watchMovementCancel()
        CreateThread(function()
            while isDoingTask do
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local moved = #(pos - startCoords) > moveCancelDist
                local tryingToMove =
                    IsControlPressed(0, 32) -- W
                    or IsControlPressed(0, 33) -- S
                    or IsControlPressed(0, 34) -- A
                    or IsControlPressed(0, 35) -- D
                    or IsControlPressed(0, 21) -- sprint
                    or IsControlPressed(0, 22) -- jump
                    or GetEntitySpeed(ped) > 0.2

                if moved or tryingToMove then
                    if lib and lib.progressActive and lib.progressActive() then
                        lib.cancelProgress()
                    end
                    break
                end
                Wait(0)
            end
        end)
    end

    if lib and lib.progressCircle then
        local progressData = {
            duration = duration,
            label = label or "Working...",
            position = "bottom",
            useWhileDead = false,
            canCancel = true,
            -- Allow walk so moving can cancel; block combat/vehicle only
            disable = { move = false, car = true, combat = true },
        }

        if anim and anim.dict and anim.clip then
            progressData.anim = {
                dict = anim.dict,
                clip = anim.clip,
                flag = anim.flag or 1,
            }
        end

        if propCfg and propCfg.model then
            progressData.prop = {
                model = propCfg.model,
                bone = propCfg.bone or 28422,
                pos = propCfg.pos or vector3(0.0, 0.0, 0.0),
                rot = propCfg.rot or vector3(0.0, 0.0, 0.0),
            }
        end

        watchMovementCancel()
        return lib.progressCircle(progressData)
    end

    -- Fallback without ox_lib progress
    local ped = PlayerPedId()
    local heldProp = nil
    local cancelled = false

    if anim and anim.dict and anim.clip then
        RequestAnimDict(anim.dict)
        local timeout = GetGameTimer() + 3000
        while not HasAnimDictLoaded(anim.dict) and GetGameTimer() < timeout do
            Wait(0)
        end
        if HasAnimDictLoaded(anim.dict) then
            TaskPlayAnim(ped, anim.dict, anim.clip, 2.0, 2.0, duration, anim.flag or 1, 0.0, false, false, false)
        end
    end

    if propCfg and propCfg.model then
        local hash = loadModel(propCfg.model)
        if hash then
            local coords = GetEntityCoords(ped)
            heldProp = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
            local pos = propCfg.pos or vector3(0.0, 0.0, 0.0)
            local rot = propCfg.rot or vector3(0.0, 0.0, 0.0)
            AttachEntityToEntity(
                heldProp, ped, GetPedBoneIndex(ped, propCfg.bone or 28422),
                pos.x, pos.y, pos.z, rot.x, rot.y, rot.z,
                true, true, false, true, 1, true
            )
            SetModelAsNoLongerNeeded(hash)
        end
    end

    local endAt = GetGameTimer() + duration
    while GetGameTimer() < endAt do
        local pedNow = PlayerPedId()
        local pos = GetEntityCoords(pedNow)
        local tryingToMove =
            IsControlPressed(0, 32)
            or IsControlPressed(0, 33)
            or IsControlPressed(0, 34)
            or IsControlPressed(0, 35)
            or IsControlPressed(0, 21)
            or IsControlPressed(0, 22)
            or GetEntitySpeed(pedNow) > 0.2

        if #(pos - startCoords) > moveCancelDist or tryingToMove then
            cancelled = true
            break
        end
        Wait(0)
    end

    ClearPedTasks(PlayerPedId())
    if heldProp and DoesEntityExist(heldProp) then
        DeleteEntity(heldProp)
    end
    return not cancelled
end

RegisterNetEvent("cfx-keydi-comserv:client:openPanel", function()
    if panelOpen then
        closePanel()
    else
        openPanel()
    end
end)

RegisterNetEvent("cfx-keydi-comserv:client:panelRefresh", function()
    if panelOpen then
        refreshPanelData()
    end
end)

RegisterNetEvent("cfx-keydi-comserv:client:start", function(data)
    if type(data) ~= "table" then return end
    startServing(data)
end)

RegisterNetEvent("cfx-keydi-comserv:client:update", function(data)
    if not isServing or type(data) ~= "table" then return end
    remaining = tonumber(data.remaining) or remaining
    total = tonumber(data.total) or total
    if data.reason then reason = data.reason end
    updateHud()
    if data.notifyReduce then
        ESX.ShowNotification((ConfigComServ.Locale.reduced):format(remaining), "info")
        -- If we already seeded a next spot after progress, keep it; otherwise assign one
        if remaining > 0 and not currentTask then
            assignRandomTask(true)
        elseif remaining > 0 and currentTask then
            ESX.ShowNotification((ConfigComServ.Locale.newTask or "New task: %s"):format(currentTask.label), "info")
        end
    end
end)

RegisterNetEvent("cfx-keydi-comserv:client:end", function(completed)
    stopServing(completed == true)
end)

RegisterNUICallback("cfx-keydi-comserv:close", function(_, cb)
    cb({ ok = true })
    closePanel()
end)

RegisterNUICallback("cfx-keydi-comserv:refresh", function(_, cb)
    ESX.TriggerServerCallback("cfx-keydi-comserv:refresh", function(data)
        cb(data or { online = {}, active = {} })
    end)
end)

RegisterNUICallback("cfx-keydi-comserv:searchOffline", function(data, cb)
    local query = type(data) == "table" and data.query or ""
    ESX.TriggerServerCallback("cfx-keydi-comserv:searchOffline", function(results)
        cb(results or {})
    end, query)
end)

RegisterNUICallback("cfx-keydi-comserv:sentence", function(data, cb)
    cb({ ok = true })
    if type(data) ~= "table" then return end
    TriggerServerEvent("cfx-keydi-comserv:server:sentence", {
        source = tonumber(data.source),
        identifier = data.identifier,
        name = data.name,
        actions = tonumber(data.actions),
        reason = data.reason,
    })
end)

RegisterNUICallback("cfx-keydi-comserv:end", function(data, cb)
    cb({ ok = true })
    if type(data) ~= "table" then return end
    TriggerServerEvent("cfx-keydi-comserv:server:end", {
        source = tonumber(data.source),
        identifier = data.identifier,
    })
end)

-- Keep player inside the service zone
CreateThread(function()
    while true do
        local sleep = 1000
        if isServing then
            sleep = 500
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local center = ConfigComServ.Center
            local maxDist = ConfigComServ.MaxDistance or 80.0
            if center and #(pos - center) > maxDist then
                ESX.ShowNotification(ConfigComServ.Locale.escaped, "error")
                teleportToZone()
            end

            -- Safety: never leave a serving player without a task marker
            if not isDoingTask and not currentTask and remaining > 0 then
                assignRandomTask(true)
            end
        end
        Wait(sleep)
    end
end)

-- Draw ONLY the current random task marker + interact
CreateThread(function()
    while true do
        local sleep = 1000
        if isServing and not isDoingTask and currentTask and currentTask.coords then
            sleep = 0
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local coords = currentTask.coords
            local interactDist = ConfigComServ.TaskInteractDistance or 2.0

            DrawMarker(
                2,
                coords.x, coords.y, coords.z + 0.15,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.28, 0.28, 0.28,
                53, 199, 242, 200,
                false, false, 2, false, nil, nil, false
            )

            -- Soft ground ring so the spot is easier to spot
            DrawMarker(
                1,
                coords.x, coords.y, coords.z - 0.95,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.2, 1.2, 0.35,
                53, 199, 242, 70,
                false, false, 2, false, nil, nil, false
            )

            if #(pos - coords) <= interactDist then
                showTaskTextUI("current", currentTask.label)
                if IsControlJustReleased(0, 38) then -- E
                    hideTaskTextUI()
                    isDoingTask = true

                    local taskSnapshot = currentTask
                    clearGroundProp()

                    local ok = runTaskProgress(taskSnapshot.type, taskSnapshot.label)
                    isDoingTask = false

                    if ok then
                        -- Move to a new random spot immediately (anti-abuse + props refresh)
                        clearCurrentTask()
                        TriggerServerEvent("cfx-keydi-comserv:server:completeTask")
                        if remaining > 1 then
                            -- remaining not updated yet; still seed next spot while server confirms
                            assignRandomTask(false)
                        end
                    else
                        -- Cancelled — restore ground prop on same spot
                        if taskSnapshot.type and taskSnapshot.type.groundProp then
                            spawnGroundProp(taskSnapshot.type.groundProp, taskSnapshot.coords)
                        end
                        createTaskBlip(taskSnapshot.coords, taskSnapshot.label)
                        currentTask = taskSnapshot
                    end
                end
            else
                hideTaskTextUI()
            end
        else
            hideTaskTextUI()
        end
        Wait(sleep)
    end
end)

exports("IsOnComServ", function()
    return isServing
end)

exports("GetComServRemaining", function()
    return remaining
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    if panelOpen then
        SetNuiFocus(false, false)
    end
    clearCurrentTask()
    if isServing then hideHud() end
end)
