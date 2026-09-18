local ESX = exports["es_extended"]:getSharedObject()
local welcomeShown = false
local welcomeAcked = false
local nuiReady = false
local pendingShow = false
local showToken = 0
-- Set while a brand-new character is in appearance creation.
local suppressAutomaticWelcome = false

local function playerDisplayName(data)
    local first = data and (data.firstName or data.firstname) or ""
    local last = data and (data.lastName or data.lastname) or ""
    local name = (tostring(first) .. " " .. tostring(last)):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return "Citizen"
    end
    return name
end

local function pushWelcomeNui(playerName)
    SendNUIMessage({
        action = "cfx-keydi-welcome:show",
        data = {
            serverName = ConfigWelcome and ConfigWelcome.serverName or "Grim City",
            playerName = playerName or "Citizen",
            home = ConfigWelcome and ConfigWelcome.home or {},
            links = ConfigWelcome and ConfigWelcome.links or {},
            updates = ConfigWelcome and ConfigWelcome.updates or {},
        }
    })
end

local function pingWelcomeNui()
    SendNUIMessage({
        action = "cfx-keydi-welcome:ping",
    })
end

local function releaseWelcomeFocus()
    welcomeShown = false
    welcomeAcked = false
    pendingShow = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = "cfx-keydi-welcome:hide"
    })
end

local function applyWelcome(playerName)
    if suppressAutomaticWelcome and not pendingShow then
        return
    end

    showToken = showToken + 1
    local token = showToken

    welcomeShown = true
    pendingShow = false
    suppressAutomaticWelcome = false
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    pushWelcomeNui(playerName)

    -- NUI can miss the first message while the React bundle boots.
    CreateThread(function()
        local name = playerName
        for _ = 1, 40 do
            if token ~= showToken or not welcomeShown then
                return
            end
            if welcomeAcked then
                return
            end
            SetNuiFocus(true, true)
            pingWelcomeNui()
            pushWelcomeNui(name)
            Wait(500)
        end

        -- Still no UI after retries — release focus so the player can move.
        if token == showToken and welcomeShown and not welcomeAcked then
            print("[kodebykarl-ui] Welcome UI did not acknowledge; releasing focus. Use /welcome to retry.")
            releaseWelcomeFocus()
        end
    end)
end

local function showWelcomeScreen(force)
    if welcomeShown and welcomeAcked then
        return
    end

    if not force then
        if suppressAutomaticWelcome or IsNuiFocused() then
            pendingShow = true
            return
        end
    end

    pendingShow = true

    local function openWith(data)
        if not force and suppressAutomaticWelcome then
            pendingShow = true
            return
        end
        applyWelcome(playerDisplayName(data))
    end

    local function requestAndOpen()
        local opened = false
        ESX.TriggerServerCallback('cfx-keydi-welcome:getWelcomeData', function(data)
            if opened then return end
            opened = true
            openWith(data)
        end)
        SetTimeout(2500, function()
            if opened or (not pendingShow and welcomeShown) then return end
            opened = true
            openWith(nil)
        end)
    end

    if not nuiReady then
        CreateThread(function()
            local deadline = GetGameTimer() + 20000
            while not nuiReady and GetGameTimer() < deadline do
                pingWelcomeNui()
                Wait(250)
            end
            if not pendingShow and welcomeShown then
                return
            end
            requestAndOpen()
        end)
        return
    end

    requestAndOpen()
end

local function hideWelcomeScreen()
    showToken = showToken + 1
    releaseWelcomeFocus()
end

-- Returning players only. New characters (isNew == true) go through appearance first.
RegisterNetEvent('esx:playerLoaded', function(_, isNew)
    if isNew == true or LocalPlayer.state.isNew == true then
        suppressAutomaticWelcome = true
        hideWelcomeScreen()
        return
    end

    CreateThread(function()
        -- Wait for identity spawn to finish fading in, then show.
        local deadline = GetGameTimer() + 8000
        while GetGameTimer() < deadline do
            if not IsScreenFadedOut() and NetworkIsPlayerActive(PlayerId()) then
                break
            end
            Wait(100)
        end
        Wait(600)
        if suppressAutomaticWelcome and LocalPlayer.state.isNew == true then
            return
        end
        showWelcomeScreen(true)
    end)
end)

local function onWelcomeShow()
    welcomeShown = false
    welcomeAcked = false
    suppressAutomaticWelcome = false
    pendingShow = true
    showWelcomeScreen(true)
end

local function onWelcomeHide()
    suppressAutomaticWelcome = true
    hideWelcomeScreen()
end

-- Identity uses TriggerEvent (local). RegisterNetEvent so server can also open it.
RegisterNetEvent('cfx-keydi-welcome:show')
AddEventHandler('cfx-keydi-welcome:show', onWelcomeShow)

RegisterNetEvent('cfx-keydi-welcome:hide')
AddEventHandler('cfx-keydi-welcome:hide', onWelcomeHide)

RegisterNUICallback("cfx-keydi-welcome:nuiReady", function(_, cb)
    local firstReady = not nuiReady
    nuiReady = true
    cb({ ok = true })
    if firstReady and pendingShow and not welcomeAcked then
        showWelcomeScreen(true)
    end
end)

RegisterNUICallback("cfx-keydi-welcome:shown", function(_, cb)
    welcomeAcked = true
    nuiReady = true
    cb({ ok = true })
end)

RegisterNUICallback("cfx-keydi-welcome:close", function(_, cb)
    hideWelcomeScreen()
    cb({ ok = true })
end)

RegisterCommand("welcome", function()
    welcomeShown = false
    welcomeAcked = false
    suppressAutomaticWelcome = false
    pendingShow = true
    showWelcomeScreen(true)
end, false)

CreateThread(function()
    while true do
        if not nuiReady then
            pingWelcomeNui()
        end
        Wait(nuiReady and 4000 or 400)
    end
end)
