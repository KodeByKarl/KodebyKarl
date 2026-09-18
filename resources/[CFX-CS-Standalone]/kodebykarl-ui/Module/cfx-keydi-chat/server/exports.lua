local ESX = exports['es_extended']:getSharedObject()

local function getJobLabel(jobName)
    if ESX.GetJobs then
        local jobs = ESX.GetJobs()
        if jobs[jobName] and jobs[jobName].label then
            return jobs[jobName].label
        end
    end

    return jobName and jobName:gsub('^%l', string.upper) or 'JOB'
end

local function resolveSystemJobData(jobName, jobLabel)
    if type(ResolveJobTemplate) == 'function' then
        return ResolveJobTemplate(jobName, jobLabel)
    end

    local cfg = ConfigChat.jobTemplate
    local data = cfg and cfg.jobs and cfg.jobs[jobName]
    if data then return data end

    local fallback = cfg and cfg.default or {}
    return {
        gif = fallback.gif,
        background = fallback.background or '#111111',
        color = fallback.color or '#ffffff',
        headerColor = fallback.headerColor or '#cfcfcf',
    }
end

local function resolvePlayerGang(xPlayer)
    local gangName, gangLabel = nil, nil

    if xPlayer.gang then
        if type(xPlayer.gang) == 'table' then
            gangName = xPlayer.gang.name
            gangLabel = xPlayer.gang.label
        elseif type(xPlayer.gang) == 'string' then
            gangName = xPlayer.gang
        end
    elseif xPlayer.getGang then
        local gangObj = xPlayer.getGang()
        if type(gangObj) == 'table' then
            gangName = gangObj.name
            gangLabel = gangObj.label
        elseif type(gangObj) == 'string' then
            gangName = gangObj
        end
    end

    if not gangLabel or gangLabel == '' then
        gangLabel = gangName and gangName:gsub('^%l', string.upper) or 'GANG'
    end

    return gangName, gangLabel
end

--- System job announcement without a player source (drop-in for cfx-cs-chat JobTemplateWithoutID)
---@param jobName string job banner to use (police, ambulance, …)
---@param message string body text
---@param headerLeft string|nil override FEED header (e.g. FEED • COMSERV | SYSTEM)
function JobTemplateWithoutID(jobName, message, headerLeft)
    if type(jobName) ~= 'string' or jobName == '' or type(message) ~= 'string' or message == '' then
        return
    end

    local jobLabel = getJobLabel(jobName)
    local jobData = resolveSystemJobData(jobName, jobLabel)
    local time = os.date('%H:%M')
    local header = headerLeft
    if type(header) ~= 'string' or header == '' then
        header = 'FEED • ' .. jobLabel .. ' | SYSTEM'
    end
    local template = BuildAnnouncementHtml(jobData, header)

    TriggerClientEvent('chat:addMessage', -1, {
        template = template,
        args = { 'SYSTEM', message, time }
    })
end

--- Post a gang announcement as a player (same look as /gang)
---@param source number
---@param message string
---@return boolean success, string|nil error
function GangTemplateFromSource(source, message)
    if type(message) ~= 'string' or message == '' then
        return false, 'empty'
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return false, 'no_player'
    end

    if not ConfigChat.gangTemplate or not ConfigChat.gangTemplate.enabled then
        return false, 'disabled'
    end

    local gangName, gangLabel = resolvePlayerGang(xPlayer)
    gangName = type(gangName) == 'string' and gangName:lower() or nil
    local gangData = ResolveGangTemplate(gangName, gangLabel)
    if not gangData then
        return false, 'unauthorized'
    end

    gangLabel = gangData.label or gangLabel or gangName:upper()
    local headerLeft = 'FEED • ' .. gangLabel .. ' | {0}'

    local time = os.date('%H:%M')
    local speaker = xPlayer.getName and xPlayer.getName() or xPlayer.name or 'Unknown'
    local template = BuildAnnouncementHtml(gangData, headerLeft)

    TriggerClientEvent('chat:addMessage', -1, {
        template = template,
        args = { speaker, message:upper(), time }
    })

    if GetResourceState('discord-logs') == 'started' then
        pcall(function()
            exports['discord-logs']:LogChatMessage(source, '[' .. gangLabel .. '] ' .. message)
        end)
    end

    return true
end

--- Show a 3D /me above a player (same as the /me command).
---@param source number
---@param text string
---@return boolean
function DisplayMe(source, text)
    if type(BroadcastMe3D) ~= 'function' then return false end
    return BroadcastMe3D(source, text) == true
end

exports('JobTemplateWithoutID', JobTemplateWithoutID)
exports('GangTemplateFromSource', GangTemplateFromSource)
exports('DisplayMe', DisplayMe)

-- Event fallback (same-server) if export isn't refreshed yet
AddEventHandler('cfx-keydi-ui:GangTemplateFromSource', function(src, message, cb)
    local ok, err = GangTemplateFromSource(src, message)
    if cb then cb(ok, err) end
end)
