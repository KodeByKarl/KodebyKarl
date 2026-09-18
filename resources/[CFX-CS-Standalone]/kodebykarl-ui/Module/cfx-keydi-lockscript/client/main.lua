--[[
    cfx-keydi-lockscript (client/main.lua)
    Opens cfx-keydi-ui VIP Lock panel and bridges NUI callbacks.
]]

if not ConfigLockScript or not ConfigLockScript.Enabled then return end

local panelOpen = false
local FrameworkName = "standalone"
local ESX, QBCore

local function debugPrint(...)
    if ConfigLockScript.Debug then
        print("[cfx-keydi-lockscript]", ...)
    end
end

local function detectFramework()
    local cfg = ConfigLockScript.Framework or "auto"
    if cfg == "esx" or cfg == "qbcore" or cfg == "standalone" then
        return cfg
    end
    if GetResourceState("es_extended") == "started" then
        return "esx"
    end
    if GetResourceState("qb-core") == "started" then
        return "qbcore"
    end
    return "standalone"
end

CreateThread(function()
    FrameworkName = detectFramework()
    if FrameworkName == "esx" then
        ESX = exports["es_extended"]:getSharedObject()
    elseif FrameworkName == "qbcore" then
        QBCore = exports["qb-core"]:GetCoreObject()
    end
    debugPrint("Framework:", FrameworkName)
end)

local function setPanel(state, data)
    panelOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "cfx-keydi-lockscript:panel:show" or "cfx-keydi-lockscript:panel:hide",
        data = data,
    })
end

local function closePanel()
    if not panelOpen then return end
    setPanel(false, nil)
end

local function openPanel()
    if FrameworkName == "esx" and ESX then
        ESX.TriggerServerCallback("cfx-keydi-lockscript:open", function(data)
            if not data then
                lib.notify({
                    title = "VIP Lock",
                    description = ConfigLockScript.Locale.noPermission,
                    type = "error",
                    position = "top-center",
                })
                return
            end
            setPanel(true, data)
        end)
    else
        local data = lib.callback.await("cfx-keydi-lockscript:open", false)
        if not data then
            lib.notify({
                title = "VIP Lock",
                description = ConfigLockScript.Locale.noPermission,
                type = "error",
                position = "top-center",
            })
            return
        end
        setPanel(true, data)
    end
end

local function refreshPanelData(cb)
    local function apply(data)
        if panelOpen and data then
            SendNUIMessage({
                action = "cfx-keydi-lockscript:panel:update",
                data = data,
            })
        end
        if cb then cb(data) end
    end

    if FrameworkName == "esx" and ESX then
        ESX.TriggerServerCallback("cfx-keydi-lockscript:refresh", function(data)
            apply(data)
        end)
    else
        apply(lib.callback.await("cfx-keydi-lockscript:refresh", false))
    end
end

RegisterNetEvent("cfx-keydi-lockscript:client:openPanel", function()
    if panelOpen then
        closePanel()
    else
        openPanel()
    end
end)

RegisterNetEvent("cfx-keydi-lockscript:client:panelRefresh", function()
    refreshPanelData()
end)

-- Command is registered server-side (ACE + staff check), then opens via event.

-- ─── NUI callbacks ───────────────────────────────────────────────────────────

RegisterNUICallback("cfx-keydi-lockscript:close", function(_, cb)
    cb("ok")
    closePanel()
end)

RegisterNUICallback("cfx-keydi-lockscript:refresh", function(_, cb)
    refreshPanelData(function(data)
        cb(data or {})
    end)
end)

RegisterNUICallback("cfx-keydi-lockscript:searchOffline", function(data, cb)
    local query = data and data.query or ""
    if FrameworkName == "esx" and ESX then
        ESX.TriggerServerCallback("cfx-keydi-lockscript:searchOffline", function(results)
            cb(results or {})
        end, query)
    else
        cb(lib.callback.await("cfx-keydi-lockscript:searchOffline", false, query) or {})
    end
end)

RegisterNUICallback("cfx-keydi-lockscript:getLocksByCategory", function(data, cb)
    local category = data and data.category or ""
    -- Client-side filter from last refresh is fine; ask server for authoritative list
    local all = lib.callback.await("cfx-keydi-lockscript:getLocks", false) or {}
    local out = {}
    for i = 1, #all do
        if all[i].category == category then
            out[#out + 1] = all[i]
        end
    end
    cb(out)
end)

RegisterNUICallback("cfx-keydi-lockscript:addLock", function(data, cb)
    cb("ok")
    if type(data) ~= "table" then return end
    TriggerServerEvent("cfx-keydi-lockscript:server:addLock", data)
end)

RegisterNUICallback("cfx-keydi-lockscript:removeLock", function(data, cb)
    cb("ok")
    if type(data) ~= "table" then return end
    TriggerServerEvent("cfx-keydi-lockscript:server:removeLock", data.lockId or data.id)
end)

RegisterNUICallback("cfx-keydi-lockscript:grantAccess", function(data, cb)
    cb("ok")
    if type(data) ~= "table" then return end
    TriggerServerEvent("cfx-keydi-lockscript:server:grantAccess", data.lockId, data.identifier)
end)

RegisterNUICallback("cfx-keydi-lockscript:revokeAccess", function(data, cb)
    cb("ok")
    if type(data) ~= "table" then return end
    TriggerServerEvent("cfx-keydi-lockscript:server:revokeAccess", data.lockId, data.identifier)
end)

RegisterNUICallback("cfx-keydi-lockscript:setShared", function(data, cb)
    cb("ok")
    if type(data) ~= "table" then return end
    TriggerServerEvent(
        "cfx-keydi-lockscript:server:setShared",
        data.lockId,
        data.sharedIdentifiers,
        data.sharedJobs
    )
end)

RegisterNUICallback("cfx-keydi-lockscript:grabFromPed", function(data, cb)
    local category = data and data.category
    local grabbed = nil
    pcall(function()
        grabbed = exports[GetCurrentResourceName()]:GrabFromPed(category)
    end)
    cb(grabbed or {})
end)

RegisterNUICallback("cfx-keydi-lockscript:checkDuplicate", function(data, cb)
    local function normalize(result)
        if type(result) == "table" and (result.id or result.duplicate) then
            return { duplicate = true, lock = result.duplicate and result.lock or result }
        end
        return { duplicate = false }
    end

    if FrameworkName == "esx" and ESX then
        ESX.TriggerServerCallback("cfx-keydi-lockscript:checkDuplicate", function(result)
            cb(normalize(result))
        end, data)
    else
        cb(normalize(lib.callback.await("cfx-keydi-lockscript:checkDuplicate", false, data)))
    end
end)

RegisterNUICallback("cfx-keydi-lockscript:importLocks", function(data, cb)
    local locks = data and data.locks or data
    local function finish(result)
        local count = tonumber(result) or (type(result) == "table" and tonumber(result.count)) or 0
        cb({ ok = count > 0, count = count })
        SetTimeout(400, function()
            refreshPanelData()
        end)
    end

    if FrameworkName == "esx" and ESX then
        ESX.TriggerServerCallback("cfx-keydi-lockscript:importLocks", function(result)
            finish(result)
        end, locks)
        return
    end
    finish(lib.callback.await("cfx-keydi-lockscript:importLocks", false, locks))
end)

RegisterNUICallback("cfx-keydi-lockscript:exportLocks", function(_, cb)
    local all = lib.callback.await("cfx-keydi-lockscript:getLocks", false) or {}
    cb(all)
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    if panelOpen then
        SetNuiFocus(false, false)
    end
end)
