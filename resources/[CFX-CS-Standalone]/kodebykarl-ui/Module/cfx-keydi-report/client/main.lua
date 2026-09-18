local ESX = exports["es_extended"]:getSharedObject()
local isVisible = false

local function ToggleReport(state, openReport, isAdmin, allReports, adminDutyStatus)
    if isIdentityOpen then return end
    isVisible = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "cfx-keydi-report:show" or "cfx-keydi-report:hide",
        openReport = openReport,
        isAdmin = isAdmin,
        allReports = allReports,
        adminDutyStatus = adminDutyStatus,
        categories = ConfigReport.Categories,
        maxDescription = ConfigReport.MaxDescriptionLength,
        maxTitle = ConfigReport.MaxTitleLength,
    })
end

local function OpenReportMenu()
    ESX.TriggerServerCallback("cfx-keydi-report:getInitialData", function(data)
        if data then
            ToggleReport(true, data.openReport, data.isAdmin, data.allReports, data.adminDutyStatus)
        else
            ToggleReport(true, nil, false, {}, false)
        end
    end)
end

exports("ToggleReport", function(state)
    if state then
        OpenReportMenu()
    else
        ToggleReport(false)
    end
end)

RegisterNUICallback("cfx-keydi-report:close", function(_, cb)
    ToggleReport(false)
    cb("ok")
end)

RegisterNUICallback("cfx-keydi-report:submit", function(data, cb)
    TriggerServerEvent("cfx-keydi-report:submitReport", data)
    cb("ok")
end)

RegisterNUICallback("cfx-keydi-report:sendMessage", function(data, cb)
    TriggerServerEvent("cfx-keydi-report:server:sendMessage", data.playerIdentifier, data.messageText)
    cb("ok")
end)

RegisterNUICallback("cfx-keydi-report:toggleDuty", function(data, cb)
    TriggerServerEvent("cfx-keydi-report:server:toggleDuty", data.status)
    cb("ok")
end)

RegisterNUICallback("cfx-keydi-report:resolveReport", function(data, cb)
    TriggerServerEvent("cfx-keydi-report:server:resolveReport", data.playerIdentifier)
    cb("ok")
end)

RegisterNetEvent("cfx-keydi-report:client:reportSaved", function(report)
    SendNUIMessage({
        action = "cfx-keydi-report:update",
        openReport = report,
    })
end)

RegisterNetEvent("cfx-keydi-report:client:updateReport", function(report)
    SendNUIMessage({
        action = "cfx-keydi-report:updateReport",
        openReport = report,
    })
end)

RegisterNetEvent("cfx-keydi-report:client:reportClosed", function()
    SendNUIMessage({
        action = "cfx-keydi-report:reportClosed",
    })
end)

RegisterNetEvent("cfx-keydi-report:client:adminUpdateReports", function(playerIdentifier, report)
    SendNUIMessage({
        action = "cfx-keydi-report:adminUpdateReport",
        playerIdentifier = playerIdentifier,
        report = report,
    })
end)

RegisterNetEvent("cfx-keydi-report:client:adminRemoveReport", function(playerIdentifier)
    SendNUIMessage({
        action = "cfx-keydi-report:adminRemoveReport",
        playerIdentifier = playerIdentifier,
    })
end)

local function playStaffAlertSound()
    local cfg = ConfigReport.StaffAlert or {}
    if cfg.enabled == false then return end

    local soundName = cfg.soundName or 'Event_Message_Purple'
    local soundSet = cfg.soundSet or 'GTAO_FM_Events_Soundset'
    local repeats = math.max(1, math.floor(tonumber(cfg.repeats) or 3))
    local delayMs = math.max(100, math.floor(tonumber(cfg.repeatDelayMs) or 450))

    CreateThread(function()
        for i = 1, repeats do
            PlaySoundFrontend(-1, soundName, soundSet, true)
            -- Backup beep if the first set fails to load on some clients
            PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            if i < repeats then
                Wait(delayMs)
            end
        end
    end)
end

RegisterNetEvent('cfx-keydi-report:client:staffAlert', function(data)
    data = type(data) == 'table' and data or {}
    local cfg = ConfigReport.StaffAlert or {}
    local duration = math.floor(tonumber(cfg.notifyDuration) or 10000)
    local title = data.title or 'NEW REPORT'
    local message = data.message or 'A player submitted a report. Open /report.'

    playStaffAlertSound()

    if lib and lib.notify then
        lib.notify({
            title = title,
            description = message,
            type = 'warning',
            duration = duration,
            position = 'top',
            icon = 'triangle-exclamation',
        })
    else
        TriggerEvent('esx:showNotification', message, 'warning', duration)
    end

    -- Also ping the report NUI if it's open
    SendNUIMessage({
        action = 'cfx-keydi-report:staffAlert',
        title = title,
        message = message,
        kind = data.kind or 'new',
    })
end)

RegisterCommand(ConfigReport.OpenCommand, function()
    if isVisible then
        ToggleReport(false)
    else
        OpenReportMenu()
    end
end, false)

if ConfigReport.ToggleKey and ConfigReport.ToggleKey ~= "" then
    RegisterKeyMapping(ConfigReport.OpenCommand, "Toggle Player Report Menu", "keyboard", ConfigReport.ToggleKey)
end
