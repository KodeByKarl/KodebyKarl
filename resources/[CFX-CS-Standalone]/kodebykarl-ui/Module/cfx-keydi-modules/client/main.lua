ESX = ESX or exports["es_extended"]:getSharedObject()
local isVisible = false
isIdentityOpen = false

-- Toggle visibility helper
local function ToggleModules(state)
    if isIdentityOpen then return end
    isVisible = state
    SetNuiFocus(state, state)

    local payload = {
        action = state and "cfx-keydi-modules:show" or "cfx-keydi-modules:hide"
    }

    -- Keep Modules patch notes in sync with Welcome (ConfigWelcome.updates)
    if state then
        payload.data = {
            updates = (ConfigWelcome and ConfigWelcome.updates) or {},
        }
    end

    SendNUIMessage(payload)
    
    if ConfigModules.Debug then
        print(("[Modules] Visibility set to: %s"):format(tostring(state)))
    end
end

-- Unconditionally hides the panel and releases NUI focus, bypassing the
-- isIdentityOpen guard. Only ever called from a NUI callback fired by a
-- button *inside* this already-open menu, so identity registration cannot
-- legitimately still be in progress at that point. This prevents a desynced
-- isIdentityOpen flag from leaving this panel stuck on top of / underneath
-- whatever menu we're handing off to (e.g. the Ped Menu), which otherwise
-- permanently breaks that hand-off for the rest of the session.
local function ForceCloseModules()
    isVisible = false
    isIdentityOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "cfx-keydi-modules:hide" })
end

-- Export for toggling from other resources
exports('ToggleModules', ToggleModules)

-- Rental menu fallback export delegating to cfx-cs-utils / kodebykarl-utils
exports('OpenRentalMenu', function(location)
    if GetResourceState('cfx-cs-utils') == 'started' then
        return exports['cfx-cs-utils']:OpenRentalMenu(location)
    elseif GetResourceState('kodebykarl-utils') == 'started' then
        return exports['kodebykarl-utils']:OpenRentalMenu(location)
    end
    TriggerEvent('cfx-keydi-utils:rental:open', location)
end)

-- Identification & Name change exports
exports('RequestLicense', function()
    lib.notify({
        title = 'DOJ',
        description = 'Buy a Citizen ID at the DOJ Shop ($250,000). Fees go to DOJ funds.',
        type = 'inform',
    })
end)

exports('OpenChangeNameMenu', function()
    lib.notify({
        title = 'DOJ',
        description = 'Buy a Name Change Certificate at the DOJ Shop ($500,000), then use it from your inventory.',
        type = 'inform',
    })
end)

--- Use DOJ Name Change Certificate (ox_inventory client export)
exports('UseChangeNameCertificate', function(data, slotData)
    local slot = slotData and slotData.slot
    if not slot and data and data.slot then
        slot = data.slot
    end
    if not slot then
        lib.notify({ title = 'DOJ', description = 'Certificate not found.', type = 'error' })
        return
    end

    local input = lib.inputDialog('DOJ — Legal Name Change', {
        { type = 'input', label = 'First Name', required = true, min = 2, max = 24 },
        { type = 'input', label = 'Last Name', required = true, min = 2, max = 24 },
    })
    if not input or not input[1] or not input[2] then return end

    local result = lib.callback.await('cfx-keydi-doj:useChangeNameItem', false, {
        slot = slot,
        firstName = input[1],
        lastName = input[2],
    })

    if not result or not result.ok then
        local err = result and result.error
        local msg = ({
            offline = 'Player not found.',
            no_item = 'You need a Name Change Certificate.',
            invalid = 'Invalid name. Use 2–24 letters.',
        })[err] or 'Name change failed.'
        lib.notify({ title = 'DOJ', description = msg, type = 'error' })
    end
end)

local function isOnDutyDoj()
    local data = ESX.GetPlayerData and ESX.GetPlayerData() or nil
    return data and data.job and data.job.name == 'doj'
end

local function dojErr(code, price)
    local map = {
        not_doj = 'On-duty DOJ only.',
        invalid_target = 'No valid citizen nearby.',
        offline = 'Citizen is offline.',
        far = 'Citizen is too far away.',
        has_id = 'They already have a Citizen ID.',
        no_money = ('Citizen cannot afford $%s.'):format(
            (price and ESX.Math and ESX.Math.GroupDigits and ESX.Math.GroupDigits(price)) or tostring(price or 0)
        ),
        inventory_full = 'Their inventory is full.',
        invalid = 'Invalid name provided.',
    }
    return map[code] or 'Request failed.'
end

local function openDojMenu()
    if not isOnDutyDoj() then
        lib.notify({ title = 'DOJ', description = 'On-duty DOJ only.', type = 'error' })
        return
    end

    local cfg = (ConfigModules and ConfigModules.DOJ) or {}
    local maxDist = tonumber(cfg.MaxDistance) or 3.0
    local idPrice = tonumber(cfg.CitizenIdPrice) or 250000
    local namePrice = tonumber(cfg.ChangeNamePrice) or 500000

    local playerId = lib.getClosestPlayer(GetEntityCoords(cache.ped), maxDist, false)
    if not playerId then
        lib.notify({ title = 'DOJ', description = 'No citizen nearby.', type = 'error' })
        return
    end
    local targetSid = GetPlayerServerId(playerId)

    lib.registerContext({
        id = 'doj_services_menu',
        title = 'DOJ Services',
        options = {
            {
                title = 'Issue Citizen ID',
                description = ('Charge nearby citizen $%s'):format(
                    (ESX.Math and ESX.Math.GroupDigits and ESX.Math.GroupDigits(idPrice)) or idPrice
                ),
                icon = 'id-card',
                onSelect = function()
                    local result = lib.callback.await('cfx-keydi-doj:issueCitizenId', false, targetSid)
                    if not result or not result.ok then
                        lib.notify({
                            title = 'DOJ',
                            description = dojErr(result and result.error, result and result.price or idPrice),
                            type = 'error',
                        })
                    end
                end,
            },
            {
                title = 'Process Name Change',
                description = ('Charge nearby citizen $%s'):format(
                    (ESX.Math and ESX.Math.GroupDigits and ESX.Math.GroupDigits(namePrice)) or namePrice
                ),
                icon = 'user-pen',
                onSelect = function()
                    local input = lib.inputDialog('DOJ — Legal Name Change', {
                        { type = 'input', label = 'First Name', required = true, max = 24 },
                        { type = 'input', label = 'Last Name', required = true, max = 24 },
                    })
                    if not input or not input[1] or not input[2] then return end
                    local result = lib.callback.await('cfx-keydi-doj:changeName', false, {
                        targetId = targetSid,
                        firstName = input[1],
                        lastName = input[2],
                    })
                    if not result or not result.ok then
                        lib.notify({
                            title = 'DOJ',
                            description = dojErr(result and result.error, result and result.price or namePrice),
                            type = 'error',
                        })
                    end
                end,
            },
        },
    })
    lib.showContext('doj_services_menu')
end

local dojCmd = (ConfigModules.DOJ and ConfigModules.DOJ.MenuCommand) or 'doj'
RegisterCommand(dojCmd, function()
    openDojMenu()
end, false)

if ConfigModules.DOJ and ConfigModules.DOJ.MenuKey and ConfigModules.DOJ.MenuKey ~= '' then
    lib.addKeybind({
        name = 'doj_services',
        description = 'DOJ Services Menu',
        defaultKey = ConfigModules.DOJ.MenuKey,
        onPressed = function()
            if isOnDutyDoj() then
                openDojMenu()
            end
        end,
    })
end

exports('OpenDojMenu', openDojMenu)

-- Register Command & Key Mapping
RegisterCommand(ConfigModules.OpenCommand, function()
    ToggleModules(not isVisible)
end, false)

if ConfigModules.ToggleKey and ConfigModules.ToggleKey ~= "" then
    RegisterKeyMapping(ConfigModules.OpenCommand, 'Toggle Modules Settings Menu', 'keyboard', ConfigModules.ToggleKey)
end

-- Close callback from NUI
RegisterNUICallback("cfx-keydi-modules:closeMenu", function(data, cb)
    ForceCloseModules()
    cb("ok")
end)

-- Patch notes shared with Welcome screen (single source: sh_welcome.lua)
RegisterNUICallback("cfx-keydi-modules:getPatchNotes", function(_, cb)
    cb({
        updates = (ConfigWelcome and ConfigWelcome.updates) or {},
    })
end)

-- Open damage indicator callback
RegisterNUICallback("cfx-keydi-modules:openDamageIndicator", function(data, cb)
    ForceCloseModules()
    CreateThread(function()
        Wait(300)
        OpenIndicatorConfig()
    end)
    cb("ok")
end)

-- Open report system callback
RegisterNUICallback("cfx-keydi-modules:openReport", function(data, cb)
    ForceCloseModules()
    CreateThread(function()
        Wait(300)
        local cmd = (ConfigReport and ConfigReport.OpenCommand) or "report"
        ExecuteCommand(cmd)
    end)
    cb("ok")
end)

-- Open banking console callback (only if OpenCommand is enabled)
RegisterNUICallback("cfx-keydi-modules:openBanking", function(data, cb)
    local cmd = ConfigBanking and ConfigBanking.OpenCommand
    if not cmd or cmd == "" then
        cb("ok")
        return
    end
    ForceCloseModules()
    CreateThread(function()
        Wait(300)
        ExecuteCommand(cmd)
    end)
    cb("ok")
end)

-- Open FPS Optimizer callback
RegisterNUICallback("cfx-keydi-modules:openFpsOptimizer", function(data, cb)
    ForceCloseModules()
    CreateThread(function()
        Wait(300)
        local cmd = (ConfigFps and ConfigFps.OpenCommand) or "fpsoptimizer"
        ExecuteCommand(cmd)
    end)
    cb("ok")
end)

local function isRockstarRecording()
    local ok, rec = pcall(IsRecording)
    return ok and rec == true
end

local function setRecordingHud(state)
    SendNUIMessage({
        action = "cfx-keydi-modules:recording",
        recording = state == true,
    })
end

RegisterNUICallback("cfx-keydi-modules:getRockstarState", function(_, cb)
    cb({ recording = isRockstarRecording() })
end)

-- In-game Rockstar recording (Wolf-style). ActivateRockstarEditor() leaves the server.
-- https://github.com/Sedres/Wolf-Rockstar-Editor
RegisterNUICallback("cfx-keydi-modules:rockstarAction", function(data, cb)
    local button = type(data) == "table" and data.button or nil

    if button == "record" then
        if isRockstarRecording() then
            cb({ ok = false, recording = true, message = "already_recording" })
            return
        end
        ForceCloseModules()
        cb({ ok = true, recording = true, close = true })
        CreateThread(function()
            Wait(200)
            StartRecording(1)
            setRecordingHud(true)
            ESX.ShowNotification("Recording started. Open Control Center (F5) to save or discard the clip.", "success")
        end)
        return
    end

    if button == "save" then
        if not isRockstarRecording() then
            cb({ ok = false, recording = false, message = "not_recording" })
            return
        end
        StartRecording(0)
        StopRecordingAndSaveClip()
        setRecordingHud(false)
        ESX.ShowNotification("Clip saved. Edit it later from Rockstar Editor (Single Player).", "success")
        cb({ ok = true, recording = false })
        return
    end

    if button == "delete" then
        if not isRockstarRecording() then
            cb({ ok = false, recording = false, message = "not_recording" })
            return
        end
        StartRecording(0)
        StopRecordingAndDiscardClip()
        setRecordingHud(false)
        ESX.ShowNotification("Clip discarded.", "info")
        cb({ ok = true, recording = false })
        return
    end

    if button == "photo" then
        ForceCloseModules()
        cb({ ok = true, close = true, recording = isRockstarRecording() })
        CreateThread(function()
            Wait(250)
            BeginTakeHighQualityPhoto()
            SaveHighQualityPhoto(-1)
            FreeMemoryForHighQualityPhoto()
            ESX.ShowNotification("Photo saved to your Rockstar Editor gallery.", "success")
        end)
        return
    end

    if button == "open" then
        ForceCloseModules()
        cb({ ok = true, close = true })
        CreateThread(function()
            Wait(300)
            ActivateRockstarEditor()
        end)
        return
    end

    cb({ ok = false, recording = isRockstarRecording() })
end)

CreateThread(function()
    local last = false
    while true do
        local rec = isRockstarRecording()
        if rec ~= last then
            last = rec
            setRecordingHud(rec)
        end
        Wait(rec and 500 or 2000)
    end
end)

-- Clothing trigger callback
RegisterNUICallback("cfx-keydi-modules:openClothing", function(data, cb)
    ForceCloseModules()

    -- Try to open clothing shops based on common scripts
    CreateThread(function()
        Wait(500) -- wait for NUI focus cleanup

        -- Ped menu (isPedMenu = true) so the player is not charged like a clothing shop
        if GetResourceState("illenium-appearance") == "started" then
            TriggerEvent('illenium-appearance:client:openClothingShop', true)
        elseif GetResourceState("esx_skin") == "started" or GetResourceState("esx_clothing") == "started" then
            TriggerEvent('esx_skin:openSaveableMenu')
        elseif GetResourceState("fivem-appearance") == "started" then
            TriggerEvent('fivem-appearance:client:openClothingShop')
        else
            -- Fallback client print and notify
            print("[Modules] Clothing menu requested but no standard clothing resource found!")
            ESX.ShowNotification("Unable to open clothing menu. Resource not found.", "error")
        end
    end)
    cb("ok")
end)

-- Fetch Multi-Job Roster NUI Callback
RegisterNUICallback("cfx-keydi-modules:getJobs", function(data, cb)
    ESX.TriggerServerCallback('cfx-keydi-multijob:server:getJobs', function(res)
        cb(res or {})
    end)
end)

-- Toggle Job Duty NUI Callback (Secured: 1 active duty at a time)
RegisterNUICallback("cfx-keydi-modules:toggleJobDuty", function(data, cb)
    if data and data.job then
        TriggerServerEvent('cfx-keydi-multijob:server:toggleDuty', data.job)
    end
    cb("ok")
end)

-- Helper function to check if local player is in Safezone
local function IsPlayerInSafezone()
    if LocalPlayer and LocalPlayer.state then
        if LocalPlayer.state.inSafeZone == true or LocalPlayer.state.inSafezone == true then
            return true
        end
    end
    local utilsNames = { 'kodebykarl-utils', 'cfx-keydi-utils' }
    for i = 1, #utilsNames do
        local res = utilsNames[i]
        if GetResourceState(res) == 'started' then
            local ok, inZone = pcall(function()
                return exports[res]:IsInSafezone()
            end)
            if ok and inZone == true then
                return true
            end
        end
    end
    return false
end

-- Helper function to check if player is locked (Jail, Arena, Combat, Instance)
local function IsPlayerLocked()
    if LocalPlayer and LocalPlayer.state then
        local state = LocalPlayer.state
        if ConfigModules.LockInJail ~= false and (state.isJailed or state.inJail or (tonumber(state.jailTime) or 0) > 0) then
            return true, "In Jail / Community Service"
        end
        if state.inArena then
            return true, "Inside Arena Instance"
        end
        if state.inPvp or state.isInPvp then
            return true, "Inside Deathmatch Arena"
        end
        if state.dead or state.isDead then
            return true, "Downed"
        end
        if state.cuffed or state.isHandcuffed then
            return true, "Restrained"
        end
        if state.inCombat then
            return true, "In combat"
        end
        if state.inHouseRobbery then
            return true, "Inside a house robbery"
        end
        if ConfigModules.LockInJobInstance and state.inJobInstance then
            return true, "Inside Side Job Instance"
        end
    end
    return false, nil
end

-- Fetch Designated Servers NUI Callback
RegisterNUICallback("cfx-keydi-modules:getServers", function(data, cb)
    ESX.TriggerServerCallback('cfx-keydi-modules:server:getServersData', function(serversData)
        local inSafezone = IsPlayerInSafezone()
        local isLocked, lockReason = IsPlayerLocked()

        if serversData then
            if type(serversData.inSafezone) == 'boolean' then
                inSafezone = serversData.inSafezone == true and inSafezone
            end
            if serversData.isLocked then
                isLocked = true
                lockReason = serversData.lockReason or lockReason
            end
            local requireSafezone = serversData.requireSafezone
            if requireSafezone == nil then
                requireSafezone = ConfigServerLocations and ConfigServerLocations.RequiresSafezoneToSwitch
                    and ConfigServerLocations.RequiresSafezoneToSwitch()
                    or ConfigModules.RequireSafezone
            end
            serversData.inSafezone = inSafezone
            serversData.requireSafezone = requireSafezone == true
            serversData.isLocked = isLocked
            serversData.lockReason = lockReason or (serversData.requireSafezone and not inSafezone and "Outside Safezone" or nil)
        end

        cb(serversData or {})
    end)
end)

-- In-game Server Locations switch (routing buckets — never uses `connect`)
RegisterNUICallback("cfx-keydi-modules:connectServer", function(data, cb)
    local inSafezone = IsPlayerInSafezone()
    local isLocked, lockReason = IsPlayerLocked()
    local requireSafezone
    if ConfigServerLocations and ConfigServerLocations.RequiresSafezoneToSwitch then
        requireSafezone = ConfigServerLocations.RequiresSafezoneToSwitch()
    else
        requireSafezone = (ConfigServerLocations and ConfigServerLocations.RequireSafezone)
            or ConfigModules.RequireSafezone
    end

    if requireSafezone and not inSafezone then
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification("Server switching locked! You must be inside a Safezone.", "error")
        end
        cb({ ok = false, message = "Outside Safezone" })
        return
    end

    if isLocked then
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(("Server switching locked while %s."):format(lockReason), "error")
        end
        cb({ ok = false, message = lockReason })
        return
    end

    local locationId = data and (data.id or data.serverId)
    if not locationId or locationId == "" then
        cb({ ok = false, message = "invalid_server_target" })
        return
    end

    ForceCloseModules()
    local serverName = data.name or "Destination Server"

    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(("Transferring to %s... Please wait."):format(serverName), "info")
    end

    TriggerServerEvent("cfx-keydi-serverlocations:server:requestSwitch", locationId)
    cb({ ok = true })
end)



