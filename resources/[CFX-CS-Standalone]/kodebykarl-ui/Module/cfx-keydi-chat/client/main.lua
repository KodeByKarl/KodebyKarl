local chatInputActive = false
local chatLoaded = false
local chatHidden = true

RegisterNetEvent('chat:addMessage')
RegisterNetEvent('chat:addTemplate')
RegisterNetEvent('chat:addSuggestion')
RegisterNetEvent('chat:addSuggestions')
RegisterNetEvent('chat:removeSuggestion')
RegisterNetEvent('chat:clear')

RegisterNetEvent('__cfx_internal:serverPrint')

-- Helper function to send NUI messages
local function sendNUIMessage(data)
    SendNUIMessage(data)
end

-- Bridge standard message event
AddEventHandler('chat:addMessage', function(message)
    if type(message) == 'string' then
        message = { args = { message } }
    end
    sendNUIMessage({
        type = 'ON_MESSAGE',
        message = message
    })
end)

AddEventHandler('__cfx_internal:serverPrint', function(msg)
    sendNUIMessage({
        type = 'ON_MESSAGE',
        message = {
            templateId = 'print',
            args = { msg }
        }
    })
end)

local function addSuggestionToChat(name, help, params)
    sendNUIMessage({
        type = 'ON_SUGGESTION_ADD',
        suggestion = {
            name = name,
            help = help or '',
            params = params or {}
        }
    })
end

local function isHiddenSuggestion(name)
    local hidden = ConfigChat and ConfigChat.hiddenSuggestions
    if not hidden or not name then return false end
    local lower = name:lower()
    for i = 1, #hidden do
        if hidden[i]:lower() == lower then
            return true
        end
    end
    return false
end

AddEventHandler('chat:addSuggestion', function(name, help, params)
    if isHiddenSuggestion(name) then return end
    addSuggestionToChat(name, help, params)
end)

AddEventHandler('chat:addSuggestions', function(suggestions)
    for _, suggestion in ipairs(suggestions) do
        if suggestion and suggestion.name and not isHiddenSuggestion(suggestion.name) then
            sendNUIMessage({
                type = 'ON_SUGGESTION_ADD',
                suggestion = suggestion
            })
        end
    end
end)

AddEventHandler('chat:removeSuggestion', function(name)
    sendNUIMessage({
        type = 'ON_SUGGESTION_REMOVE',
        name = name
    })
end)

RegisterNetEvent('chat:resetSuggestions')
AddEventHandler('chat:resetSuggestions', function()
    sendNUIMessage({
        type = 'ON_COMMANDS_RESET'
    })
end)

AddEventHandler('chat:addTemplate', function(id, html)
    sendNUIMessage({
        type = 'ON_TEMPLATE_ADD',
        template = {
            id = id,
            html = html
        }
    })
end)

AddEventHandler('chat:clear', function()
    sendNUIMessage({
        type = 'ON_CLEAR'
    })
end)

-- Open Chat Functionality
local function openChatInput()
    -- Block chat while identity registration owns the NUI
    if isIdentityOpen then return end

    if not chatInputActive and not IsPauseMenuActive() and not IsScreenFadedOut() then
        chatInputActive = true
        sendNUIMessage({ type = 'ON_OPEN' })
        SetNuiFocus(true, true)
    end
end

-- Register Command & Keymapping (T key)
RegisterCommand('openchat', function()
    openChatInput()
end, false)

RegisterKeyMapping('openchat', 'Open Chat Input', 'keyboard', 'T')

-- NUI Callbacks
RegisterNUICallback('chatResult', function(data, cb)
    chatInputActive = false
    if not isIdentityOpen then
        SetNuiFocus(false, false)
    end

    if not data.canceled and data.message and data.message ~= '' then
        local message = data.message:match('^%s*(.-)%s*$') or ''

        local prefix = message:sub(1, 1)
        if prefix == '/' or prefix == '.' then
            ExecuteCommand(message:sub(2))
        elseif ConfigChat.allowPersonalChat then
            local id = PlayerId()
            TriggerServerEvent('_cfx-keydi-chat:messageEntered', GetPlayerName(id), {0, 153, 255}, message)
        else
            TriggerEvent('chat:addMessage', {
                template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px; border: 1px solid rgba(255,0,0,0.3); margin-bottom: 5px;">{0}</div>',
                args = { ConfigChat.personalChatBlockedMessage or '[SYSTEM] Personal chat is disabled. Use commands only.' }
            })
        end
    end

    cb('ok')
end)

-- Backwards compatibility callback name
RegisterNUICallback('CoreDev_ChatResult', function(data, cb)
    chatInputActive = false
    if not isIdentityOpen then
        SetNuiFocus(false, false)
    end

    if not data.canceled and data.message and data.message ~= '' then
        local message = data.message:match('^%s*(.-)%s*$') or ''

        local prefix = message:sub(1, 1)
        if prefix == '/' or prefix == '.' then
            ExecuteCommand(message:sub(2))
        elseif ConfigChat.allowPersonalChat then
            local id = PlayerId()
            TriggerServerEvent('_cfx-keydi-chat:messageEntered', GetPlayerName(id), {0, 153, 255}, message)
        else
            TriggerEvent('chat:addMessage', {
                template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px; border: 1px solid rgba(255,0,0,0.3); margin-bottom: 5px;">{0}</div>',
                args = { ConfigChat.personalChatBlockedMessage or '[SYSTEM] Personal chat is disabled. Use commands only.' }
            })
        end
    end

    cb('ok')
end)

local function applyConfiguredSuggestions()
    local hidden = ConfigChat and ConfigChat.hiddenSuggestions
    if hidden then
        for i = 1, #hidden do
            TriggerEvent('chat:removeSuggestion', hidden[i])
        end
    end

    local suggestions = ConfigChat and ConfigChat.commandSuggestions
    if not suggestions then return end
    for i = 1, #suggestions do
        local s = suggestions[i]
        if s and s.name then
            addSuggestionToChat(s.name, s.help, s.params)
        end
    end
end

local function refreshCommands()
    if GetRegisteredCommands then
        local registeredCommands = GetRegisteredCommands()
        local suggestions = {}

        for _, command in ipairs(registeredCommands) do
            local name = '/' .. command.name
            if not isHiddenSuggestion(name) and IsAceAllowed(('command.%s'):format(command.name)) then
                table.insert(suggestions, {
                    name = name,
                    help = ''
                })
            end
        end

        TriggerEvent('chat:addSuggestions', suggestions)
    end

    applyConfiguredSuggestions()
end

RegisterNUICallback('chatLoaded', function(data, cb)
    TriggerServerEvent('cfx-keydi-chat:init')
    refreshCommands()
    chatLoaded = true
    sendNUIMessage({
        type = 'ON_CHAT_CONFIG',
        fadeTimeout = (ConfigChat and ConfigChat.fadeTimeout) or 10000
    })
    cb('ok')
end)

-- Backwards compatibility loaded callback
RegisterNUICallback('loaded', function(data, cb)
    TriggerServerEvent('cfx-keydi-chat:init')
    refreshCommands()
    chatLoaded = true
    sendNUIMessage({
        type = 'ON_CHAT_CONFIG',
        fadeTimeout = (ConfigChat and ConfigChat.fadeTimeout) or 10000
    })
    cb('ok')
end)

-- Command refresh triggers
local refreshScheduled = false
CreateThread(function()
    while true do
        Wait(1000)
        if refreshScheduled then
            refreshScheduled = false
            refreshCommands()
        end
    end
end)

AddEventHandler('onClientResourceStart', function()
    refreshScheduled = true
end)

AddEventHandler('onClientResourceStop', function()
    refreshScheduled = true
end)

-- ============================================
-- Grim City 3D /me (NUI overlay above the ped)
-- ============================================
local meConfig = ConfigChat.Me3D or {}
local meLanguage = ConfigChat.Me3DLanguage or meConfig.language or 'en'
local meLang = ConfigChat.Me3DLanguages and ConfigChat.Me3DLanguages[meLanguage] or {}
local peds = {}
local nuiDirty = false

local function drawNative3dText(coords, text)
    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)
    local scale = 200 / (GetGameplayCamFov() * dist)

    SetTextColour(230, 230, 230, 255)
    SetTextScale(0.0, 0.42 * scale)
    SetTextFont(4)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function displayText(ped, text, serverId)
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local targetPos = GetEntityCoords(ped)
    local dist = #(playerPos - targetPos)
    local los = HasEntityClearLosToEntity(playerPed, ped, 17)

    if dist <= (meConfig.dist or 22.0) and los then
        peds[ped] = {
            time = GetGameTimer() + (meConfig.time or 5500),
            text = text,
            serverId = serverId,
        }
        nuiDirty = true
    end
end

local function onShareDisplay(text, target)
    if not meConfig.enabled then return end
    if not text or not target then return end

    local player = GetPlayerFromServerId(target)
    local serverId = GetPlayerServerId(PlayerId())
    if player ~= -1 or target == serverId then
        local ped = GetPlayerPed(player)
        if DoesEntityExist(ped) then
            displayText(ped, text, target)
        end
    end
end

AddStateBagChangeHandler("SlashMe", 'global', function(_, _, value)
    if type(value) == 'table' then
        onShareDisplay(value.text, value.target)
    end
end)

RegisterNetEvent('cfx-keydi-chat:me3d', function(target, text)
    onShareDisplay(text, target)
end)

CreateThread(function()
    local lastPayload = ''
    while true do
        if next(peds) == nil then
            if nuiDirty then
                SendNUIMessage({ action = 'me3d:sync', bubbles = {} })
                lastPayload = ''
                nuiDirty = false
            end
            Wait(400)
        else
            Wait(0)
            local now = GetGameTimer()
            local myPed = PlayerPedId()
            local myPos = GetEntityCoords(myPed)
            local maxDist = meConfig.dist or 22.0
            local fadeStart = meConfig.fadeStart or 14.0
            local headOffset = meConfig.headOffset or 1.08
            local bubbles = {}

            for ped, data in pairs(peds) do
                if not DoesEntityExist(ped) or now > data.time then
                    peds[ped] = nil
                    nuiDirty = true
                else
                    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, headOffset)
                    local dist = #(myPos - coords)
                    if dist > maxDist or not HasEntityClearLosToEntity(myPed, ped, 17) then
                        goto continue
                    end

                    local opacity = 1.0
                    if dist > fadeStart then
                        opacity = 1.0 - ((dist - fadeStart) / math.max(0.01, maxDist - fadeStart))
                    end

                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
                    if onScreen and sx and sy then
                        local scale = math.max(0.78, math.min(1.12, 9.5 / math.max(dist, 2.0)))
                        bubbles[#bubbles + 1] = {
                            id = ('me-%s'):format(data.serverId or ped),
                            text = data.text,
                            x = sx,
                            y = sy,
                            scale = scale,
                            opacity = math.max(0.0, math.min(1.0, opacity)),
                        }
                    end

                    if meConfig.useNativeFallback then
                        drawNative3dText(coords, data.text)
                    end
                    ::continue::
                end
            end

            local encoded = json.encode(bubbles)
            if encoded ~= lastPayload then
                lastPayload = encoded
                SendNUIMessage({ action = 'me3d:sync', bubbles = bubbles })
            end
        end
    end
end)

if meLang and meLang.commandName then
    TriggerEvent('chat:addSuggestion', '/' .. meLang.commandName, meLang.commandDescription or 'Display an action above your head.', meLang.commandSuggestion)
end

-- Fallback Key Listener & Pause/Faded out detector
CreateThread(function()
    SetTextChatEnabled(false)
    SetNuiFocus(false, false)

    while true do
        Wait(50)
        -- Fallback key handler in case key mapping isn't binded yet
        if not chatInputActive and IsControlJustPressed(0, 245) then
            openChatInput()
        end

        if chatLoaded then
            local shouldBeHidden = IsScreenFadedOut() or IsPauseMenuActive()
            if (shouldBeHidden ~= chatHidden) then
                chatHidden = shouldBeHidden
                sendNUIMessage({ type = 'ON_SCREEN_STATE_CHANGE', shouldHide = shouldBeHidden })
            end
        end
    end
end)
