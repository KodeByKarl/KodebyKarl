local ESX = exports['es_extended']:getSharedObject()

local function templateColors(data)
    local color = (data and data.color) or "#ffffff"
    local headerColor = (data and data.headerColor) or color
    return color, headerColor
end

local function templateBackground(data, fallback)
    if data and data.gif then
        -- Logo stays on the right; card height can grow with wrapped text.
        return "background-image: linear-gradient(90deg, rgba(0,0,0,0.62) 0%, rgba(0,0,0,0.35) 45%, rgba(0,0,0,0.15) 100%), url('"
            .. data.gif
            .. "'); background-size: cover; background-position: center right; background-repeat: no-repeat;"
    end
    if data and data.background and data.background ~= 'nil' then
        return "background: " .. data.background .. ";"
    end
    return "background: " .. (fallback or "#0f0f13") .. ";"
end

--- Compact for short messages; grows so long /wl /ems /gang text stays fully readable.
local ANNOUNCE_CARD_STYLE = "min-height: 40px; height: auto; max-height: none; overflow: visible; box-sizing: border-box; border-radius: 6px; padding: 5px 9px; margin-bottom: 4px; font-family: 'Outfit', sans-serif; position: relative; display: flex; flex-direction: column; justify-content: flex-start; gap: 2px; max-width: 100%; flex-shrink: 0; box-shadow: 0 3px 12px rgba(0,0,0,0.45);"

--- Freestyle job banner. Per-job colors/gifs override default.
function ResolveJobTemplate(jobName, jobLabel)
    local cfg = ConfigChat.jobTemplate
    if not cfg or not cfg.enabled then return nil end

    jobName = type(jobName) == 'string' and jobName:lower() or nil
    if not jobName or jobName == '' then
        return nil
    end

    if cfg.blockedJobs and cfg.blockedJobs[jobName] then
        return nil
    end

    local data = cfg.jobs and cfg.jobs[jobName]
    if data then
        return data
    end

    if cfg.allowAnyJob == false then
        return nil
    end

    local fallback = cfg.default or {}
    return {
        label = jobLabel or jobName:upper(),
        gif = fallback.gif,
        background = fallback.background or '#111111',
        color = fallback.color or '#ffffff',
        headerColor = fallback.headerColor or '#cfcfcf',
    }
end

--- Any assigned ESX gang can post. Custom gif/colors override the free default.
function ResolveGangTemplate(gangName, gangLabel)
    local cfg = ConfigChat.gangTemplate
    if not cfg or not cfg.enabled then return nil end

    gangName = type(gangName) == 'string' and gangName:lower() or nil
    if not gangName or gangName == '' or gangName == 'none' then
        return nil
    end

    local data = cfg.gangs and cfg.gangs[gangName]
    if data then
        return data
    end

    if cfg.allowAnyGang == false then
        return nil
    end

    local fallback = cfg.default or {}
    return {
        label = gangLabel or gangName:upper(),
        gif = fallback.gif,
        background = fallback.background or '#111111',
        color = fallback.color or '#ffffff',
        headerColor = fallback.headerColor or '#cfcfcf',
    }
end

function BuildAnnouncementHtml(data, headerLeft, fallbackBg, borderColor)
    local color, headerColor = templateColors(data)
    local backgroundStyle = templateBackground(data, fallbackBg)
    local border = borderColor or "rgba(255, 255, 255, 0.08)"
    local overlay = (data and data.gif) and "" or "box-shadow: inset 0 0 40px rgba(0,0,0,0.45), 0 4px 15px rgba(0,0,0,0.5);"
    local gifPad = (data and data.gif) and "padding-right: 54px;" or ""

    return '<div style="' .. backgroundStyle .. ' color: ' .. color .. '; border: 1px solid ' .. border .. '; ' .. ANNOUNCE_CARD_STYLE .. ' ' .. gifPad .. ' ' .. overlay .. '">'
        .. '  <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 6px; font-size: 8.5px; color: ' .. headerColor .. '; font-weight: 600; text-transform: uppercase; letter-spacing: 0.25px; line-height: 1.15;">'
        .. '    <span style="min-width: 0; flex: 1; word-break: break-word; overflow-wrap: anywhere;">' .. headerLeft .. '</span>'
        .. '    <span style="flex-shrink: 0; opacity: 0.9;">{2}</span>'
        .. '  </div>'
        .. '  <div style="color: ' .. color .. '; font-size: 10.5px; font-weight: 700; text-transform: uppercase; line-height: 1.3; white-space: pre-wrap; word-break: break-word; overflow-wrap: anywhere; overflow: visible;">{1}</div>'
        .. '</div>'
end

-- Clear command
if ConfigChat.clearCommand or true then
    RegisterCommand('clear', function(source, args, rawCommand)
        TriggerClientEvent('chat:clear', source)
    end, false)
end

-- Me Command (Grim City 3D NUI)
local meConfig = ConfigChat.Me3D or {}
local meLanguage = ConfigChat.Me3DLanguage or meConfig.language or 'en'
local meLang = ConfigChat.Me3DLanguages and ConfigChat.Me3DLanguages[meLanguage] or {}
local meCooldown = {}

local function sanitizeMeText(text)
    text = tostring(text or '')
    text = text:gsub('[%c]', ' ')
    text = text:gsub('[~¦^<>]', '')
    text = text:gsub('%s+', ' ')
    text = text:match('^%s*(.-)%s*$') or ''
    local maxLen = tonumber(meConfig.maxLength) or 140
    if #text > maxLen then
        text = text:sub(1, maxLen)
    end
    return text
end

function BroadcastMe3D(source, actionText)
    if not source or source <= 0 then return false end
    if meConfig.enabled == false then return false end

    local text = sanitizeMeText(actionText)
    if text == '' then return false end

    local now = GetGameTimer()
    local waitMs = tonumber(meConfig.cooldownMs) or 1500
    if meCooldown[source] and (now - meCooldown[source]) < waitMs then
        return false
    end
    meCooldown[source] = now

    local prefix = meLang and meLang.prefix
    local display = (type(prefix) == 'string' and prefix ~= '') and (prefix .. text) or text

    if GetResourceState('discord-logs') == 'started' then
        pcall(function()
            exports['discord-logs']:LogChatMessage(source, "/me " .. text)
        end)
    elseif GetResourceState('ox_lib') == 'started' then
        pcall(function()
            lib.logger(source, '/me Log', '"'..GetPlayerName(source)..'" ['..source..'] said: "'..text..'"')
        end)
    end

    GlobalState.SlashMe = {
        text = display,
        target = source
    }
    TriggerClientEvent('cfx-keydi-chat:me3d', -1, source, display)
    return true
end

if meLang and meLang.commandName then
    GlobalState.SlashMe = {}

    RegisterCommand(meLang.commandName, function(source, args)
        BroadcastMe3D(source, table.concat(args, ' '))
    end, false)
end

AddEventHandler('playerDropped', function()
    meCooldown[source] = nil
end)

local function getJobTemplatePaymentAmount(jobName)
    local pay = ConfigChat.jobTemplatePayment
    if not pay or not pay.enabled then return 0 end
    jobName = type(jobName) == 'string' and jobName:lower() or nil
    if not jobName or not pay.jobs or not pay.jobs[jobName] then return 0 end
    return math.floor(tonumber(pay.amount) or 0)
end

local function chargeJobTemplatePayment(xPlayer, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    local bank = 0
    local cash = 0
    if xPlayer.getAccount then
        local bankAcc = xPlayer.getAccount('bank')
        bank = bankAcc and tonumber(bankAcc.money) or 0
        local moneyAcc = xPlayer.getAccount('money')
        cash = moneyAcc and tonumber(moneyAcc.money) or 0
    end
    if cash <= 0 and xPlayer.getMoney then
        cash = tonumber(xPlayer.getMoney()) or 0
    end

    local reason = 'Job announcement template'
    if bank >= amount then
        xPlayer.removeAccountMoney('bank', amount, reason)
        return true
    end
    if cash >= amount then
        if xPlayer.removeAccountMoney then
            xPlayer.removeAccountMoney('money', amount, reason)
        elseif xPlayer.removeMoney then
            xPlayer.removeMoney(amount, reason)
        else
            return false
        end
        return true
    end
    return false
end

local function chatSystem(source, color, text)
    TriggerClientEvent('chat:addMessage', source, {
        template = '<div style="color: ' .. color .. '; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] ' .. text .. '</div>'
    })
end

local function assignedCommandForJob(jobName)
    local jobs = ConfigChat.jobTemplate and ConfigChat.jobTemplate.jobs
    local data = jobName and jobs and jobs[jobName]
    if type(data) ~= 'table' or type(data.command) ~= 'string' or data.command == '' then
        return nil
    end
    return data.command:lower()
end

--- command -> { jobName, ... } so only the assigned job can use it.
local function collectAssignedCommands()
    local map = {}
    local jobs = ConfigChat.jobTemplate and ConfigChat.jobTemplate.jobs or {}

    local function bind(cmd, jobName)
        if type(cmd) ~= 'string' or cmd == '' then return end
        cmd = cmd:lower()
        local list = map[cmd]
        if not list then
            list = {}
            map[cmd] = list
        end
        for i = 1, #list do
            if list[i] == jobName then return end
        end
        list[#list + 1] = jobName
    end

    for jobName, data in pairs(jobs) do
        if type(data) == 'table' then
            bind(data.command, jobName)
            if type(data.aliases) == 'table' then
                for i = 1, #data.aliases do
                    bind(data.aliases[i], jobName)
                end
            end
        end
    end

    return map
end

local function jobListLabel(jobNames)
    local pretty = {
        police = 'Police',
        sheriff = 'Sheriff',
        doj = 'DOJ',
        ambulance = 'EMS',
        sambulance = 'Sheriff EMS',
        pambulance = 'Paleto EMS',
        mechanic = 'Mechanic',
        uwu = 'UwU',
        tacoshop = 'Taco Shop',
        taco = 'Taco',
        burgershot = 'Burger Shot',
        ['8ball'] = '8 Ball',
        weedshop = 'Weed Shop',
        school = 'School',
        tattooshop1 = 'Tattoo Shop',
        tattooshop2 = 'Tattoo Shop',
        tattooshop3 = 'Tattoo Shop',
        vu = 'Vanilla Unicorn',
    }
    local labels = {}
    local seen = {}
    local jobs = ConfigChat.jobTemplate.jobs
    for i = 1, #jobNames do
        local name = jobNames[i]
        local data = jobs[name]
        local label = (data and data.label) or pretty[name] or name
        if not seen[label] then
            seen[label] = true
            labels[#labels + 1] = label
        end
    end
    return table.concat(labels, ', ')
end

function GetJobCommandSuggestions()
    local suggestions = {}
    local seen = {}
    local assigned = collectAssignedCommands()

    for cmd, jobNames in pairs(assigned) do
        if not seen[cmd] then
            seen[cmd] = true
            local fee = 0
            for i = 1, #jobNames do
                fee = math.max(fee, getJobTemplatePaymentAmount(jobNames[i]))
            end
            local help = jobListLabel(jobNames) .. ' announcement'
            if fee > 0 then
                help = help .. ' ($' .. fee .. ')'
            end
            suggestions[#suggestions + 1] = {
                name = '/' .. cmd,
                help = help,
                params = { { name = 'message', help = 'Your announcement' } },
            }
        end
    end

    table.sort(suggestions, function(a, b) return a.name < b.name end)
    return suggestions
end

local function postAssignedJobAnnouncement(source, args, usedCommand, allowedJobs)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local jobName = xPlayer.job and xPlayer.job.name
    jobName = type(jobName) == 'string' and jobName:lower() or nil
    local jobLabel = xPlayer.job and xPlayer.job.label or (jobName and jobName:gsub("^%l", string.upper) or "JOB")
    local message = table.concat(args, " ")

    local allowed = false
    if jobName then
        for i = 1, #allowedJobs do
            if allowedJobs[i] == jobName then
                allowed = true
                break
            end
        end
    end

    if not allowed then
        local mine = assignedCommandForJob(jobName)
        if mine then
            chatSystem(source, '#ff3b30', ('/%s is for %s. Your command is /%s.'):format(usedCommand, jobListLabel(allowedJobs), mine))
        else
            chatSystem(source, '#ff3b30', ('/%s is for %s only.'):format(usedCommand, jobListLabel(allowedJobs)))
        end
        return
    end

    if message == "" then
        chatSystem(source, '#e3a71b', 'Please enter a message! Format: /' .. usedCommand .. ' [message]')
        return
    end

    local jobData = ResolveJobTemplate(jobName, jobLabel)
    if not jobData then
        chatSystem(source, '#ff3b30', 'Your job does not have authorization to use this announcement!')
        return
    end

    local fee = getJobTemplatePaymentAmount(jobName)
    if fee > 0 and not chargeJobTemplatePayment(xPlayer, fee) then
        chatSystem(source, '#ff3b30', 'Not enough money! Announcement costs $' .. fee .. '.')
        return
    end

    local template = BuildAnnouncementHtml(jobData, 'FEED • ' .. jobLabel .. ' | {0}')
    TriggerClientEvent('chat:addMessage', -1, {
        template = template,
        args = { xPlayer.getName(), message, os.date("%H:%M") }
    })

    if fee > 0 then
        chatSystem(source, '#22c55e', 'Charged $' .. fee .. ' for this announcement.')
    end

    if GetResourceState('discord-logs') == 'started' then
        pcall(function()
            exports['discord-logs']:LogChatMessage(source, "[" .. jobLabel .. "] " .. message)
        end)
    end
end

-- Assigned job commands only. /wl is not registered.
if ConfigChat.jobTemplate and ConfigChat.jobTemplate.enabled then
    local assigned = collectAssignedCommands()
    for cmd, allowedJobs in pairs(assigned) do
        RegisterCommand(cmd, function(source, args)
            postAssignedJobAnnouncement(source, args, cmd, allowedJobs)
        end, false)
    end
end

-- Gang freestyle announcement (/gang)
if ConfigChat.gangTemplate.enabled and type(ConfigChat.gangTemplate.command) == 'string' and ConfigChat.gangTemplate.command ~= '' then
    RegisterCommand(ConfigChat.gangTemplate.command, function(source, args, rawCommand)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        local gangName = nil
        local gangLabel = nil
        local gangObj = nil

        if type(xPlayer.getGang) == 'function' then
            gangObj = xPlayer.getGang()
        end
        if type(gangObj) ~= 'table' then
            gangObj = xPlayer.gang
        end

        if type(gangObj) == 'table' then
            gangName = gangObj.name
            gangLabel = gangObj.label
        elseif type(gangObj) == 'string' then
            gangName = gangObj
        end

        gangName = type(gangName) == 'string' and gangName:lower() or nil

        local message = table.concat(args, " ")
        local time = os.date("%H:%M")

        if message == "" then
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #e3a71b; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] Please enter a message! Format: /' .. ConfigChat.gangTemplate.command .. ' [message]</div>'
            })
            return
        end

        if not gangName or gangName == '' or gangName == 'none' then
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] You are not assigned to a gang.</div>'
            })
            return
        end

        local gangData = ResolveGangTemplate(gangName, gangLabel)
        if not gangData then
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] You are not assigned to a gang.</div>'
            })
            return
        end

        gangLabel = gangData.label or gangLabel or gangName:upper()

        local template = BuildAnnouncementHtml(gangData, 'FEED • ' .. gangLabel .. ' | {0}')

        TriggerClientEvent('chat:addMessage', -1, {
            template = template,
            args = { xPlayer.getName(), message, time }
        })

        if GetResourceState('discord-logs') == 'started' then
            pcall(function()
                exports['discord-logs']:LogChatMessage(source, "[" .. gangLabel .. "] " .. message)
            end)
        end
    end, false)
end

-- Admin Command (Admin Announcement)
if ConfigChat.adminTemplate.enabled then
    RegisterCommand(ConfigChat.adminTemplate.command, function(source, args, rawCommand)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        local playerGroup = xPlayer.getGroup()
        local isAllowed = false

        for _, permission in ipairs(ConfigChat.adminTemplate.permissions) do
            if permission == "group." .. playerGroup then
                isAllowed = true
                break
            end
            if IsPlayerAceAllowed(source, permission) then
                isAllowed = true
                break
            end
        end

        if not isAllowed then
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] You do not have permission to run this command!</div>'
            })
            return
        end

        local message = table.concat(args, " ")
        local time = os.date("%H:%M")
        if message == "" then 
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #e3a71b; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] Please enter a message! Format: /' .. ConfigChat.adminTemplate.command .. ' [message]</div>'
            })
            return 
        end

        local adminData = ConfigChat.adminTemplate
        local template = BuildAnnouncementHtml(adminData, 'FEED • ADMIN ANNOUNCEMENT | {0}', "#DC143C")

        TriggerClientEvent('chat:addMessage', -1, {
            template = template,
            args = { xPlayer.getName(), message, time }
        })

        if GetResourceState('discord-logs') == 'started' then
            pcall(function()
                exports['discord-logs']:LogChatMessage(source, "[ADMIN] " .. message)
            end)
        end
    end, false)
end

------------------------------------------------------------------
-- Staff helpers
------------------------------------------------------------------
local function isStaffGroup(group, allowedGroups)
    if not group or not allowedGroups then return false end
    for _, g in ipairs(allowedGroups) do
        if g == group then return true end
    end
    return false
end

local function getStaffSources(allowedGroups)
    local list = {}
    for _, xP in ipairs(ESX.GetExtendedPlayers()) do
        if isStaffGroup(xP.getGroup(), allowedGroups) then
            list[#list + 1] = xP.source
        end
    end
    return list
end

------------------------------------------------------------------
-- /staff — public staff announcement (all players see it)
------------------------------------------------------------------
if ConfigChat.staffTemplate and ConfigChat.staffTemplate.enabled then
    RegisterCommand(ConfigChat.staffTemplate.command, function(source, args, rawCommand)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        if not isStaffGroup(xPlayer.getGroup(), ConfigChat.staffTemplate.groups) then
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] You do not have permission to use /staff!</div>'
            })
            return
        end

        local message = table.concat(args, " ")
        local time = os.date("%H:%M")
        if message == "" then
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #e3a71b; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] Format: /' .. ConfigChat.staffTemplate.command .. ' [message]</div>'
            })
            return
        end

        local data = ConfigChat.staffTemplate
        local template = BuildAnnouncementHtml(data, 'FEED • STAFF | {0}', "#7C3AED")

        TriggerClientEvent('chat:addMessage', -1, {
            template = template,
            args = { xPlayer.getName(), message, time }
        })

        if GetResourceState('discord-logs') == 'started' then
            pcall(function()
                exports['discord-logs']:LogChatMessage(source, "[STAFF] " .. message)
            end)
        end
    end, false)
end

------------------------------------------------------------------
-- /staffo — staff-only chat (only staff groups can see)
------------------------------------------------------------------
if ConfigChat.staffOnlyTemplate and ConfigChat.staffOnlyTemplate.enabled then
    RegisterCommand(ConfigChat.staffOnlyTemplate.command, function(source, args, rawCommand)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        if not isStaffGroup(xPlayer.getGroup(), ConfigChat.staffOnlyTemplate.groups) then
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #ff3b30; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] You do not have permission to use /staffo!</div>'
            })
            return
        end

        local message = table.concat(args, " ")
        local time = os.date("%H:%M")
        if message == "" then
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div style="color: #e3a71b; font-weight: bold; background: rgba(0,0,0,0.6); padding: 8px; border-radius: 6px;">[SYSTEM] Format: /' .. ConfigChat.staffOnlyTemplate.command .. ' [message]</div>'
            })
            return
        end

        local data = ConfigChat.staffOnlyTemplate
        local template = BuildAnnouncementHtml(data, 'STAFF ONLY • {0}', "#1E3A5F", "rgba(96, 165, 250, 0.35)")

        local staffSources = getStaffSources(ConfigChat.staffOnlyTemplate.groups)
        for i = 1, #staffSources do
            TriggerClientEvent('chat:addMessage', staffSources[i], {
                template = template,
                args = { xPlayer.getName(), message, time }
            })
        end

        if GetResourceState('discord-logs') == 'started' then
            pcall(function()
                exports['discord-logs']:LogChatMessage(source, "[STAFF ONLY] " .. message)
            end)
        end
    end, false)
end
