local ESX = exports['es_extended']:getSharedObject()
local Webhook = require 'server.webhook'

local ActiveTurfs = {}
local CooldownTurfs = {}
local ClaimableTurfs = {}

-- Scoreboard & HUD World Event Synchronization
local updateScoreboardEvents

updateScoreboardEvents = function()
    if GetResourceState('kodebykarl-ui') ~= 'started' then return end

    local activeLabels = {}
    local activeRemaining = 0
    for id, data in pairs(Config.TurfWars) do
        if ActiveTurfs[id] then
            activeLabels[#activeLabels + 1] = data.label
            local rem = ActiveTurfs[id] or 0
            if rem > activeRemaining then
                activeRemaining = rem
            end
        elseif ClaimableTurfs[id] then
            activeLabels[#activeLabels + 1] = data.label
        end
    end

    if #activeLabels == 0 then
        local maxCooldown = 0
        for _, remaining in pairs(CooldownTurfs) do
            if remaining and remaining > maxCooldown then
                maxCooldown = remaining
            end
        end
        pcall(function()
            exports['kodebykarl-ui']:SetWorldEvent('Turf Wars', {
                status = 'INACTIVE',
                location = '—',
                timer = maxCooldown,
            })
        end)
    else
        table.sort(activeLabels)
        pcall(function()
            exports['kodebykarl-ui']:SetWorldEvent('Turf Wars', {
                status = 'ACTIVE',
                location = table.concat(activeLabels, ', '),
                timer = activeRemaining,
            })
        end)
    end
end

-- Initialize GlobalState on startup
CreateThread(function()
    Wait(1000)
    for id, _ in pairs(Config.TurfWars) do
        GlobalState:set(('turf_state_%s'):format(id), 'IDLE', true)
        GlobalState:set(('turf_timer_%s'):format(id), 0, true)
        GlobalState:set(('turf_cooldown_%s'):format(id), 0, true)
        GlobalState:set(('turf_claimable_%s'):format(id), false, true)
        ClaimableTurfs[id] = false
        ActiveTurfs[id] = nil
        CooldownTurfs[id] = nil
    end
    updateScoreboardEvents()
end)

-- Re-sync scoreboard if UI restarts after Turf War
AddEventHandler('onResourceStart', function(resource)
    if resource == 'kodebykarl-ui' then
        updateScoreboardEvents()
    end
end)

local function addScoreboardRobbery(id, label, remainingSecs)
    if GetResourceState('kodebykarl-ui') ~= 'started' then return end
    pcall(function()
        exports['kodebykarl-ui']:AddActiveRobbery(('turfwar_%s'):format(id), {
            name = label or 'Turf War',
            location = label or 'Turf Zone',
            timer = math.max(remainingSecs or 0, 1),
            sticky = true,
        })
    end)
    updateScoreboardEvents()
end

local function removeScoreboardRobbery(id)
    if GetResourceState('kodebykarl-ui') ~= 'started' then return end
    pcall(function()
        exports['kodebykarl-ui']:RemoveActiveRobbery(('turfwar_%s'):format(id))
    end)
    updateScoreboardEvents()
end

-- Helper: Get Player Gang Data
local function getPlayerGang(xPlayer)
    if not xPlayer then return 'none', 'Unemployed' end

    -- Prefer kodebykarl-gangsystem
    if GetResourceState('kodebykarl-gangsystem') == 'started' then
        local ok, gang = pcall(function()
            return exports['kodebykarl-gangsystem']:GetPlayerGang(xPlayer.source)
        end)
        if ok and type(gang) == 'table' and gang.name then
            return gang.name, gang.label or gang.name
        end
    end

    local gang = nil
    if xPlayer.getGang then
        gang = xPlayer.getGang()
    elseif xPlayer.gang then
        gang = xPlayer.gang
    end

    if type(gang) == 'table' then
        return gang.name or 'none', gang.label or 'Unemployed'
    elseif type(gang) == 'string' then
        return gang, gang:gsub('^%l', string.upper)
    end

    return 'none', 'Unemployed'
end

-- Helper: Count online gang members
local function countOnlineGangMembers(gangName)
    if not gangName or gangName == '' or Config.IgnoreGangs[gangName] then return 0 end
    local count = 0
    local players = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(players) do
        local gName = getPlayerGang(xPlayer)
        if gName == gangName then
            count += 1
        end
    end
    return count
end

-- Helper: Build Fit-To-Text Chat Templates (Gang Name Only)
local function SendTurfStartChatTemplate(turfLabel, gangLabel)
    local messageStr = ('TURF WAR HAS BEEN INITIATED AT %s BY %s'):format(
        turfLabel:upper(), gangLabel:upper()
    )
    local template = '<div style="background: linear-gradient(135deg, rgba(28, 14, 18, 0.85) 0%, rgba(15, 10, 14, 0.92) 100%); border-radius: 8px; padding: 8px 12px; margin-bottom: 6px; border-left: 3px solid #ff3a3a; border-top: 1px solid rgba(255, 58, 58, 0.15); box-shadow: 0 4px 15px rgba(0,0,0,0.5); text-align: left; font-family: \'Outfit\', sans-serif; word-break: break-word; overflow-wrap: anywhere; white-space: pre-wrap; max-width: 100%; box-sizing: border-box; flex-shrink: 0; min-height: min-content; line-height: 1.4;">'
        .. '<b style="color: #ff8080; letter-spacing: 0.3px;">[TURF WAR]</b>'
        .. '<span style="color: rgba(255,255,255,0.4); margin: 0 6px;">•</span>'
        .. '<span style="color: #ffffff; font-weight: 600;">' .. messageStr .. '</span>'
        .. '</div>'

    TriggerClientEvent('chat:addMessage', -1, { template = template })
end

local function SendTurfClaimChatTemplate(turfLabel, gangLabel)
    local messageStr = ('TURF WAR AT %s HAS BEEN CLAIMED BY %s'):format(
        turfLabel:upper(), gangLabel:upper()
    )
    local template = '<div style="background: linear-gradient(135deg, rgba(14, 28, 18, 0.85) 0%, rgba(10, 15, 12, 0.92) 100%); border-radius: 8px; padding: 8px 12px; margin-bottom: 6px; border-left: 3px solid #2ecc71; border-top: 1px solid rgba(46, 204, 113, 0.15); box-shadow: 0 4px 15px rgba(0,0,0,0.5); text-align: left; font-family: \'Outfit\', sans-serif; word-break: break-word; overflow-wrap: anywhere; white-space: pre-wrap; max-width: 100%; box-sizing: border-box; flex-shrink: 0; min-height: min-content; line-height: 1.4;">'
        .. '<b style="color: #2ecc71; letter-spacing: 0.3px;">[TURF WAR]</b>'
        .. '<span style="color: rgba(255,255,255,0.4); margin: 0 6px;">•</span>'
        .. '<span style="color: #ffffff; font-weight: 600;">' .. messageStr .. '</span>'
        .. '</div>'

    TriggerClientEvent('chat:addMessage', -1, { template = template })
end

-- Server Main Loop: Timer countdowns & Cooldown handling
CreateThread(function()
    while true do
        Wait(1000)

        -- Handle Active Turfs Timer
        for id, remaining in pairs(ActiveTurfs) do
            if remaining > 0 then
                local nextSec = remaining - 1
                ActiveTurfs[id] = nextSec
                GlobalState:set(('turf_timer_%s'):format(id), nextSec, true)

                -- Countdown finished -> Enters CLAIMABLE state at trigger spot!
                if nextSec <= 0 then
                    ActiveTurfs[id] = nil
                    ClaimableTurfs[id] = true
                    GlobalState:set(('turf_state_%s'):format(id), 'CLAIMABLE', true)
                    GlobalState:set(('turf_claimable_%s'):format(id), true, true)

                    local data = Config.TurfWars[id]
                    if data then
                        addScoreboardRobbery(id, data.label, 0)
                    end
                end
            end
        end

        -- Handle Cooldown Timers
        for id, remaining in pairs(CooldownTurfs) do
            if remaining > 0 then
                local nextCd = remaining - 1
                CooldownTurfs[id] = nextCd
                GlobalState:set(('turf_cooldown_%s'):format(id), nextCd, true)

                if nextCd <= 0 then
                    CooldownTurfs[id] = nil
                    GlobalState:set(('turf_state_%s'):format(id), 'IDLE', true)
                    GlobalState:set(('turf_cooldown_%s'):format(id), 0, true)
                end
            end
        end

        updateScoreboardEvents()
    end
end)

-- Register Event: Start Turf War Sequence
RegisterNetEvent('kodebykarl-turfwar:server:startTurf', function(turfId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local data = Config.TurfWars[turfId]
    if not data then return end

    if GetResourceState('kodebykarl-ui') == 'started' then
        local fn = data.requireFunction or 'turfwar'
        local ok, allowed = pcall(function()
            return exports['kodebykarl-ui']:PlayerHasFunction(src, fn)
        end)
        if not ok or not allowed then
            return TriggerClientEvent('ox_lib:notify', src, {
                title = 'TURF WAR',
                description = (fn == 'schoolwar')
                    and 'School War is only available on Region 2. Open Control Center (F5) → Regions.'
                    or 'Turf / gang war is only available on Region 1, 3, or 4. Open Control Center (F5) → Regions.',
                type = 'error',
            })
        end
    end

    -- Distance Anti-Exploit Check
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if #(coords - data.coords) > 10.0 then
        return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = 'You are too far from the trigger location.', type = 'error' })
    end

    -- State Checks
    if ActiveTurfs[turfId] or ClaimableTurfs[turfId] then
        return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = 'This Turf War is already active or claimable!', type = 'error' })
    end

    if CooldownTurfs[turfId] and CooldownTurfs[turfId] > 0 then
        local secs = CooldownTurfs[turfId]
        local mins = math.floor(secs / 60)
        return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = ('Turf is on cooldown (%dm remaining).'):format(mins), type = 'error' })
    end

    if not Config.AllowMultipleTurfwars and next(ActiveTurfs) then
        local myFn = data.requireFunction or 'turfwar'
        for activeId in pairs(ActiveTurfs) do
            local other = Config.TurfWars[activeId]
            local otherFn = (other and other.requireFunction) or 'turfwar'
            if otherFn == myFn then
                return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = 'Another Turf War is currently in progress.', type = 'error' })
            end
        end
    end

    -- Gang Validation
    local gangName, gangLabel = getPlayerGang(xPlayer)
    local jobName = (xPlayer.job and xPlayer.job.name) or (xPlayer.getJob and xPlayer.getJob().name) or 'unemployed'
    local isAllowedTestPlayer = Config.AllowAllJobsForTesting or (Config.AllowTestJobs and Config.AllowTestJobs[jobName])
    if type(data.allowJobs) == 'table' and data.allowJobs[jobName] then
        isAllowedTestPlayer = true
    end

    if not isAllowedTestPlayer and (Config.IgnoreGangs[gangName] or gangName == 'none' or gangName == 'unemployed') then
        return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = 'You must belong to an active Gang to initiate a Turf War.', type = 'error' })
    end

    -- Online Members Check
    if not isAllowedTestPlayer and Config.MinGangMembersOnline > 0 then
        local onlineCount = countOnlineGangMembers(gangName)
        if onlineCount < Config.MinGangMembersOnline then
            return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = ('At least %d members of your gang must be online (%d/%d).'):format(Config.MinGangMembersOnline, onlineCount, Config.MinGangMembersOnline), type = 'error' })
        end
    end

    -- Required items to trigger (e.g. lockpicks)
    if type(Config.RequiredItems) == 'table' and next(Config.RequiredItems) then
        for itemName, need in pairs(Config.RequiredItems) do
            local have = exports.ox_inventory:GetItemCount(src, itemName) or 0
            if have < need then
                local itemData = exports.ox_inventory:Items(itemName)
                local label = (itemData and itemData.label) or itemName
                return TriggerClientEvent('ox_lib:notify', src, {
                    title = 'TURF WAR',
                    description = ('You need x%d %s to trigger this Turf War (%d/%d).'):format(need, label, have, need),
                    type = 'error'
                })
            end
        end
        for itemName, need in pairs(Config.RequiredItems) do
            if not exports.ox_inventory:RemoveItem(src, itemName, need) then
                return TriggerClientEvent('ox_lib:notify', src, {
                    title = 'TURF WAR',
                    description = 'Could not remove required items.',
                    type = 'error'
                })
            end
        end
    end

    -- Start War Sequence
    ActiveTurfs[turfId] = data.timer
    CooldownTurfs[turfId] = data.cooldown
    ClaimableTurfs[turfId] = false

    GlobalState:set(('turf_state_%s'):format(turfId), 'ACTIVE', true)
    GlobalState:set(('turf_timer_%s'):format(turfId), data.timer, true)
    GlobalState:set(('turf_cooldown_%s'):format(turfId), data.cooldown, true)
    GlobalState:set(('turf_claimable_%s'):format(turfId), false, true)

    addScoreboardRobbery(turfId, data.label, data.timer)

    -- Send Chat Template Announcement with Gang Name Only
    SendTurfStartChatTemplate(data.label, gangLabel)

    -- Webhook Log
    local logMsg = ('**Initiated By:** %s (ID: %d)\n**Gang:** %s\n**Location:** %s\n**Timer:** %d seconds'):format(
        xPlayer.name, src, gangLabel, data.label, data.timer
    )
    Webhook.SendLog('TURF WAR - INITIATED', 16744192, logMsg)
end)

-- Register Event: Claim Rewards Right Where Triggered
RegisterNetEvent('kodebykarl-turfwar:server:claimTurf', function(turfId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local data = Config.TurfWars[turfId]
    if not data then return end

    if GetResourceState('kodebykarl-ui') == 'started' then
        local fn = data.requireFunction or 'turfwar'
        local ok, allowed = pcall(function()
            return exports['kodebykarl-ui']:PlayerHasFunction(src, fn)
        end)
        if not ok or not allowed then
            return TriggerClientEvent('ox_lib:notify', src, {
                title = 'TURF WAR',
                description = (fn == 'schoolwar')
                    and 'School War is only available on Region 2. Open Control Center (F5) → Regions.'
                    or 'Turf / gang war is only available on Region 1, 3, or 4. Open Control Center (F5) → Regions.',
                type = 'error',
            })
        end
    end

    -- Verify Turf is Claimable
    if not ClaimableTurfs[turfId] or GlobalState[('turf_claimable_%s'):format(turfId)] ~= true then
        return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = 'Rewards for this Turf War are not claimable.', type = 'error' })
    end

    -- Strict Distance Check (Must be standing right at the trigger coordinates)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if #(coords - data.coords) > 6.0 then
        return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = 'You must be right at the trigger spot to claim rewards.', type = 'error' })
    end

    -- Gang Check
    local gangName, gangLabel = getPlayerGang(xPlayer)
    local jobName = (xPlayer.job and xPlayer.job.name) or (xPlayer.getJob and xPlayer.getJob().name) or 'unemployed'
    local isAllowedTestPlayer = Config.AllowAllJobsForTesting or (Config.AllowTestJobs and Config.AllowTestJobs[jobName])
    if type(data.allowJobs) == 'table' and data.allowJobs[jobName] then
        isAllowedTestPlayer = true
    end

    if not isAllowedTestPlayer and (Config.IgnoreGangs[gangName] or gangName == 'none' or gangName == 'unemployed') then
        return TriggerClientEvent('ox_lib:notify', src, { title = 'TURF WAR', description = 'Only active gang members can claim Turf War rewards.', type = 'error' })
    end

    -- Lock Claim to prevent duplicate payouts
    ClaimableTurfs[turfId] = false
    GlobalState:set(('turf_claimable_%s'):format(turfId), false, true)
    GlobalState:set(('turf_state_%s'):format(turfId), 'COOLDOWN', true)

    removeScoreboardRobbery(turfId)

    -- Distribute Item Rewards directly via ox_inventory
    local claimedSummary = {}
    for _, reward in ipairs(data.rewards) do
        local count = math.random(reward.min, reward.max)
        if count > 0 then
            exports.ox_inventory:AddItem(src, reward.item, count)
            claimedSummary[#claimedSummary + 1] = ('x%d %s'):format(count, reward.label or reward.item)
        end
    end

    local itemsListStr = table.concat(claimedSummary, ', ')

    -- Send Chat Template Announcement with Gang Name Only
    SendTurfClaimChatTemplate(data.label, gangLabel)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'REWARDS CLAIMED',
        description = ('Received: %s'):format(itemsListStr),
        type = 'success',
        duration = 8000
    })

    -- Webhook Log
    local logMsg = ('**Claimed By:** %s (ID: %d)\n**Gang:** %s\n**Location:** %s\n**Items Claimed:** %s'):format(
        xPlayer.name, src, gangLabel, data.label, itemsListStr
    )
    Webhook.SendLog('TURF WAR - REWARDS CLAIMED', 65280, logMsg)

    if GetResourceState('kodebykarl-ui') == 'started' then
        pcall(function()
            exports['kodebykarl-ui']:LeaderboardRecordTurfClaim(gangName, gangLabel)
        end)
    end
end)
