local Config = require 'configs.whitelistedblips'

if not Config or not Config.Enabled then return end

local onDutyPlayers = {}

local function getJobGroup(jobName)
    if not jobName then return nil end
    for groupKey, jobConfig in pairs(Config.Jobs) do
        for _, name in ipairs(jobConfig.jobs) do
            if name == jobName then
                return groupKey, jobConfig
            end
        end
    end
    return nil
end

RegisterNetEvent('cfx-keydi-utils:whitelistedblips:update', function(coords, heading, vehState)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local jobName = xPlayer.job and xPlayer.job.name
    local groupKey, jobConfig = getJobGroup(jobName)
    if not groupKey then
        if onDutyPlayers[src] then
            onDutyPlayers[src] = nil
            TriggerClientEvent('cfx-keydi-utils:whitelistedblips:clear', src)
        end
        return
    end

    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then return end

    local charName = (xPlayer.getName and xPlayer.getName()) or xPlayer.name or GetPlayerName(src) or ('ID %s'):format(src)

    local color = jobConfig.color
    if jobConfig.jobColors and jobConfig.jobColors[jobName] ~= nil then
        color = jobConfig.jobColors[jobName]
    end

    local label = jobConfig.label
    if jobConfig.jobLabels and jobConfig.jobLabels[jobName] then
        label = jobConfig.jobLabels[jobName]
    end

    onDutyPlayers[src] = {
        src = src,
        group = groupKey,
        label = label,
        color = color,
        defaultSprite = jobConfig.sprite,
        name = charName,
        coords = vector3(coords.x, coords.y, coords.z),
        heading = tonumber(heading) or 0.0,
        vehState = vehState or 'foot',
        lastUpdate = os.time(),
    }
end)

AddEventHandler('esx:setJob', function(source, job, lastJob)
    local src = source
    local groupKey = getJobGroup(job and job.name)
    if not groupKey then
        if onDutyPlayers[src] then
            onDutyPlayers[src] = nil
            TriggerClientEvent('cfx-keydi-utils:whitelistedblips:clear', src)
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if onDutyPlayers[src] then
        onDutyPlayers[src] = nil
    end
end)

AddEventHandler('esx:playerDropped', function(source, reason)
    local src = source
    if onDutyPlayers[src] then
        onDutyPlayers[src] = nil
    end
end)

local function packBlip(src, data)
    return {
        src = src,
        group = data.group,
        label = data.label,
        color = data.color,
        defaultSprite = data.defaultSprite,
        name = data.name,
        coords = data.coords,
        heading = data.heading,
        vehState = data.vehState,
    }
end

-- One payload per department (O(n)), not a nested rebuild per officer (O(n²)).
CreateThread(function()
    while true do
        Wait(Config.RefreshInterval or 2000)

        local now = os.time()
        local byGroup = {}

        for src, data in pairs(onDutyPlayers) do
            if not GetPlayerName(src) or (now - data.lastUpdate > 10) then
                onDutyPlayers[src] = nil
            else
                local group = data.group
                if not byGroup[group] then byGroup[group] = {} end
                byGroup[group][#byGroup[group] + 1] = packBlip(src, data)
            end
        end

        if next(onDutyPlayers) ~= nil then
            if Config.ShareAll then
                local all = {}
                for _, list in pairs(byGroup) do
                    for i = 1, #list do
                        all[#all + 1] = list[i]
                    end
                end
                for src in pairs(onDutyPlayers) do
                    TriggerClientEvent('cfx-keydi-utils:whitelistedblips:sync', src, all)
                end
            else
                for src, data in pairs(onDutyPlayers) do
                    TriggerClientEvent('cfx-keydi-utils:whitelistedblips:sync', src, byGroup[data.group] or {})
                end
            end
        end
    end
end)
