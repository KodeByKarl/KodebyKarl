local menu = require 'shared.menu'
local helpers = require 'helpers.game'
local Vars = require 'helpers.vars'
local configs = require 'shared.config'

local function GetRecoveryDurations(xTarget)
    local recovery = configs.General and configs.General.Recovery or {}
    local jobName = xTarget and xTarget.job and xTarget.job.name
    local duration = (jobName and recovery[jobName]) or recovery['all'] or 120
    local crutch = recovery.crutch or duration
    if crutch > duration then
        crutch = duration
    end
    return duration, crutch
end

local function FormatSentry(xPlayer, xTarget, targetId, forwardVector)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR REVIVE SYSTEM'),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('targetId Provided: %s'):format(targetId),
        ('forwardVector Provided: %s'):format('vec3('..forwardVector.x..', '..forwardVector.y..', '..forwardVector.z..')'),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(text, ' | ')
end

local function FormatReviveTarget(xPlayer, xTarget, targetId)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR REVIVE SYSTEM'),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('targetId Provided: %s'):format(targetId),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(text, ' | ')
end

local function ResolveReviveKit(xPlayer)
    local src = xPlayer.source
    local isEms = helpers.HasJob(menu.revive.access, xPlayer)
    local emsItem = (menu.revive.require and menu.revive.require.item) or 'ems_medikit'
    local emsAmount = tonumber(menu.revive.require and menu.revive.require.amount) or 1
    local civ = menu.revive.civilian
    local civItem = (civ and civ.item) or 'medikit'
    local civAmount = tonumber(civ and civ.amount) or 1

    if isEms then
        local emsCount = Vars.ox:Search(src, 'count', emsItem) or 0
        if emsCount >= emsAmount then
            return true, emsItem, emsAmount, true
        end
        local civCount = Vars.ox:Search(src, 'count', civItem) or 0
        if civCount >= civAmount then
            return true, civItem, civAmount, true
        end
    else
        local civCount = Vars.ox:Search(src, 'count', civItem) or 0
        if civCount >= civAmount then
            return true, civItem, civAmount, false
        end
        local emsCount = Vars.ox:Search(src, 'count', emsItem) or 0
        if emsCount >= emsAmount then
            return true, emsItem, emsAmount, false
        end
    end

    return false, nil, 0, false
end

local function ValidateCPR(xPlayer, xTarget, targetId)
    if not xPlayer or not xTarget then
        return false, 'INVALID PLAYER OR TARGET'
    end
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    if targetId == -1 then
        return false, 'INVALID TARGET ID'
    end
    if #(playerCoords - targetCoords) > 5.0 then
        return false, 'INVALID DISTANCE'
    end
    local hasKit = ResolveReviveKit(xPlayer)
    if not hasKit then
        return false, 'ITEM CHECK'
    end
    return true
end

local function ValidateRevive(xPlayer, xTarget, targetId)
    if not xTarget or not xPlayer then return false, 'INVALID PLAYER OR TARGET' end
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    if targetId == -1 then
        return false, 'INVALID TARGET ID'
    end
    if #(playerCoords - targetCoords) > 5.0 then
        return false, 'INVALID DISTANCE'
    end
    local hasKit = ResolveReviveKit(xPlayer)
    if not hasKit then
        return false, 'ITEM CHECK'
    end
    return true
end


RegisterNetEvent('cfx-keydi-ambulance:playCPR', function(targetId, forwardVector)
    local src = source
    local targetSource = tonumber(targetId)
    if not targetSource or targetSource == -1 then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xPlayer or not xTarget then return end
    local success, reason = ValidateCPR(xPlayer, xTarget, targetSource)
    if not success then
        lib.logger(xPlayer.source, 'cfx-keydi-sentry', FormatSentry(xPlayer, xTarget, targetSource, forwardVector), 'ERROR')
        print(("^0[^3cfx-keydi-ambulance^0] [REVIVE]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        if AmbulanceLogs and AmbulanceLogs.Sentry then
            AmbulanceLogs.Sentry({
                system = 'CPR',
                src = src,
                name = xPlayer and xPlayer.name,
                identifier = xPlayer and xPlayer.identifier,
                targetSrc = targetSource,
                targetName = xTarget and xTarget.name,
                targetIdentifier = xTarget and xTarget.identifier,
                reason = reason,
                coords = xPlayer and xPlayer.getCoords(true),
                targetCoords = xTarget and xTarget.getCoords(true),
            })
        end
        return
    end
    local ped = GetPlayerPed(src)
    local playerHeading = GetEntityHeading(ped)
    local playerCoords = GetEntityCoords(ped)
    TriggerClientEvent("cfx-keydi-ambulance:syncCPR", xTarget.source, playerHeading, playerCoords, forwardVector)
end)

RegisterNetEvent('cfx-keydi-ambulance:reviveTarget', function(playerId)
    local src = source
	local targetId = tonumber(playerId)
    if not targetId or targetId == -1 then return end
	local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end
    local success, reason = ValidateRevive(xPlayer, xTarget, targetId)
    if not success then
        lib.logger(xPlayer.source, 'cfx-keydi-sentry', FormatReviveTarget(xPlayer, xTarget, targetId), 'ERROR')
        print(("^0[^3cfx-keydi-ambulance^0] [REVIVE]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        if AmbulanceLogs and AmbulanceLogs.Sentry then
            AmbulanceLogs.Sentry({
                system = 'REVIVE',
                src = src,
                name = xPlayer and xPlayer.name,
                identifier = xPlayer and xPlayer.identifier,
                targetSrc = targetId,
                targetName = xTarget and xTarget.name,
                targetIdentifier = xTarget and xTarget.identifier,
                reason = reason,
                coords = xPlayer and xPlayer.getCoords(true),
                targetCoords = xTarget and xTarget.getCoords(true),
            })
        end
        return
    end
	if not xTarget then
        return TriggerClientEvent('esx:Notify', xPlayer.source, 'AMBULANCE', 'That player is no longer online.', 'error', 5000)
	end

	if not Vars.cacheDeads[targetId] and not Player(targetId).state.dead then return end

    local hasKit, kitItem, kitAmount, payEms = ResolveReviveKit(xPlayer)
    if not hasKit then return end

    Vars.ox:RemoveItem(xPlayer.source, kitItem, kitAmount)
    TriggerClientEvent('esx:Notify', xPlayer.source, 'AMBULANCE', 'Revive Complete.', 'success', 5000)

    if payEms then
        local rewardItem = menu.revive.reward.item
        local rewardLabel = (Vars.oxItems and Vars.oxItems[rewardItem] and Vars.oxItems[rewardItem].label) or 'Money'
        Vars.ox:AddItem(xPlayer.source, rewardItem, menu.revive.reward.amount)
        TriggerClientEvent('esx:Notify', xPlayer.source, 'AMBULANCE', ('You received %sx %s'):format(ESX.Math.GroupDigits(menu.revive.reward.amount), rewardLabel), 'success', 5000)
    end

	pcall(function()
		exports['es_extended']:MarkRespawn(xTarget.source, 8000)
	end)
	pcall(function()
		exports['es_extended']:GrantHealthArmorBudget(xTarget.source, 300, 0, 10000)
	end)
	-- Clear death + unmute pma-voice immediately (don't wait for client event)
	pcall(function()
		exports[GetCurrentResourceName()]:AdminClearDeath(xTarget.source)
	end)
	TriggerClientEvent('cfx-keydi-ambulance:revive', xTarget.source)
	local recoverySecs, crutchSecs = GetRecoveryDurations(xTarget)
	TriggerClientEvent('cfx-keydi-ambulance:SetRecoveryState', xTarget.source, recoverySecs, crutchSecs)
	TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', xTarget.source)
	TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', xTarget.source)

	pcall(function()
		exports['es_extended']:SecureSetStatus(xTarget.source, { hunger = 100, thirst = 100, stress = 0 })
	end)
	pcall(function()
		local xT = ESX.GetPlayerFromId(xTarget.source)
		if xT and xT.setMeta then
			xT.setMeta('health', 200)
		end
	end)
	SetTimeout(500, function()
		if GetResourceState('kodebykarl-ui') == 'started' then
			pcall(function()
				exports['kodebykarl-ui']:RestorePlayerBucket(xTarget.source)
			end)
		end
	end)
    if AmbulanceLogs and AmbulanceLogs.Revive then
        local job = xPlayer.job and (('%s — %s'):format(xPlayer.job.label or xPlayer.job.name, xPlayer.job.grade_label or '')) or nil
        AmbulanceLogs.Revive({
            src = src,
            name = xPlayer.name,
            identifier = xPlayer.identifier,
            job = job,
            targetSrc = targetId,
            targetName = xTarget.name,
            targetIdentifier = xTarget.identifier,
            requireItem = kitItem,
            requireAmount = kitAmount,
            rewardItem = payEms and menu.revive.reward.item or nil,
            rewardAmount = payEms and menu.revive.reward.amount or 0,
            recovery = recoverySecs,
            coords = xPlayer.getCoords(true),
            targetCoords = xTarget.getCoords(true),
        })
    end
    if GetResourceState('kodebykarl-logs') == 'started' then
        pcall(function()
            exports['kodebykarl-logs']:LogRevive({
                src = targetId,
                revivedBy = src,
                method = 'ems',
                item = kitItem,
                itemAmount = kitAmount,
                targetCoords = xTarget.getCoords(true),
            })
        end)
    end
end)