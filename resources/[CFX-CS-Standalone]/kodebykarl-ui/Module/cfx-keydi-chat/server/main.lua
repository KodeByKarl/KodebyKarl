local ESX = exports['es_extended']:getSharedObject()
local playerCooldowns = {}

RegisterServerEvent('cfx-keydi-chat:init')
RegisterServerEvent('_cfx-keydi-chat:messageEntered')
RegisterServerEvent('__cfx_internal:commandFallback')

-- Handle chat initialization
AddEventHandler('cfx-keydi-chat:init', function()
    local src = source
    local registeredCommands = GetRegisteredCommands()
    local suggestions = {}
    local hidden = ConfigChat and ConfigChat.hiddenSuggestions

    local function isHidden(name)
        if not hidden then return false end
        local lower = name:lower()
        for i = 1, #hidden do
            if hidden[i]:lower() == lower then
                return true
            end
        end
        return false
    end

    for _, command in ipairs(registeredCommands) do
        local name = '/' .. command.name
        if not isHidden(name) and IsPlayerAceAllowed(src, ('command.%s'):format(command.name)) then
            table.insert(suggestions, {
                name = name,
                help = ''
            })
        end
    end

    TriggerClientEvent('chat:addSuggestions', src, suggestions)

    local configured = ConfigChat and ConfigChat.commandSuggestions
    if configured then
        TriggerClientEvent('chat:addSuggestions', src, configured)
    end

    if GetJobCommandSuggestions then
        TriggerClientEvent('chat:addSuggestions', src, GetJobCommandSuggestions())
    end
end)

-- Handle standard text messages
AddEventHandler('_cfx-keydi-chat:messageEntered', function(author, color, message)
    if not message or not author then return end
    
    local src = source
    local voteMsg = type(message) == 'string' and message:lower():gsub('^%s+', ''):gsub('%s+$', '') or ''
    local isImpoundVote = (voteMsg == 'yes' or voteMsg == 'no' or voteMsg == 'y' or voteMsg == 'n')
    local voteOpen = false
    if isImpoundVote then
        local ok, voting = pcall(function()
            if GetResourceState('cfx-cs-utils') == 'started' then
                return exports['cfx-cs-utils']:IsMassImpoundVoting()
            end
            return exports['kodebykarl-utils']:IsMassImpoundVoting()
        end)
        voteOpen = ok and voting == true
    end

    -- Block personal / OOC chat to prevent flooding. Commands go through ExecuteCommand.
    -- Exception: yes / no during an active mass-impound vote.
    if ConfigChat.allowPersonalChat == false and not voteOpen then
        TriggerClientEvent('chat:addMessage', src, {
            template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px; border: 1px solid rgba(255,0,0,0.3); margin-bottom: 5px;">{0}</div>',
            args = { ConfigChat.personalChatBlockedMessage or '[SYSTEM] Personal chat is disabled. Use commands only.' }
        })
        return
    end

    local now = os.time()

    -- Check message cooldown (skip for impound votes so people can vote immediately)
    if not voteOpen and playerCooldowns[src] and now - playerCooldowns[src] < (ConfigChat.cooldownSeconds or 2) then
        TriggerClientEvent('chat:addMessage', src, {
            template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px; border: 1px solid rgba(255,0,0,0.3); margin-bottom: 5px;">[SYSTEM] Please wait before sending another message!</div>'
        })
        return
    end
    
    playerCooldowns[src] = now

    -- Trigger server event so other resources can cancel or inspect the message
    TriggerEvent('chatMessage', src, author, message)
    TriggerEvent('cfx-keydi-chat:messageEntered', src, author, message)

    if not WasEventCanceled() then
        -- Default chat format fallback: "Name: Message"
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div style="background: rgba(15, 10, 25, 0.75); border-radius: 8px; padding: 10px; border-left: 3px solid rgba(171, 86, 219, 0.6); margin-bottom: 5px; color: #fff; text-shadow: 0 1px 2px rgba(0,0,0,0.5);"><b style="color: #df9eff;">{0}</b>: {1}</div>',
            args = { author, message }
        })
        
        -- Logging to discord-logs if started
        if GetResourceState('discord-logs') == 'started' then
            pcall(function()
                exports['discord-logs']:LogChatMessage(src, message)
            end)
        end
    end
end)

-- Command fallback handler for unregistered commands (do NOT broadcast — prevents /spam floods)
AddEventHandler('__cfx_internal:commandFallback', function(command)
    local src = source

    TriggerClientEvent('chat:addMessage', src, {
        template = '<div style="color: #e3a71b; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px; margin-bottom: 5px;">[SYSTEM] Unknown command: /{0}</div>',
        args = { command or '' }
    })

    if GetResourceState('discord-logs') == 'started' then
        pcall(function()
            exports['discord-logs']:LogCommandFallback(src, command)
        end)
    end

    CancelEvent()
end)

-- Helper split string
function stringsplit(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    local i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
