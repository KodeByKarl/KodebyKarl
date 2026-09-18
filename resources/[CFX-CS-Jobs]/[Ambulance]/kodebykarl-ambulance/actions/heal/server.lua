local helpers = require 'helpers.game'
local menu = require 'shared.menu'
local Vars = require 'helpers.vars'

local function FormatSentry(xPlayer, xTarget, targetId)
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR HEAL SYSTEM'),
        ('Source Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Target Name: %s [%s]'):format(xTarget.name, xTarget.source),
        ('targetId Provided: %s'):format(targetId),
        ('Source Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Target Coords: %s'):format('vec3('..targetCoords.x..', '..targetCoords.y..', '..targetCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords))
    }
    return table.concat(text, ' | ')
end

local function ResolveHealKit(xPlayer)
    local src = xPlayer.source
    local isEms = helpers.HasJob(menu.heal.access, xPlayer)
    local emsItem = (menu.heal.require and menu.heal.require.item) or 'ems_medikit'
    local emsAmount = tonumber(menu.heal.require and menu.heal.require.amount) or 1
    local civ = menu.heal.civilian
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

local function ValidateHeal(xPlayer, xTarget, targetId)
    if not xPlayer or not xTarget then
        return false, 'INVALID TARGET ID'
    end
    local playerCoords = xPlayer.getCoords(true)
    local targetCoords = xTarget.getCoords(true)
    if targetId == -1 then
        return false, 'INVALID TARGET ID'
    end
    if Player(targetId).state.dead then
        return false, 'TARGET DEAD'
    end
    if #(playerCoords - targetCoords) > 5.0 then
        return false, 'INVALID DISTANCE'
    end
    local hasKit = ResolveHealKit(xPlayer)
    if not hasKit then
        return false, 'ITEM CHECK'
    end
    return true
end


RegisterNetEvent('cfx-keydi-ambulance:healTarget', function(playerId)
    local targetId = tonumber(playerId)
    if not targetId or targetId == -1 then return end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end
    local success, reason = ValidateHeal(xPlayer, xTarget, targetId)
    if not success then
        lib.logger(xPlayer.source, 'cfx-keydi-sentry', FormatSentry(xPlayer, xTarget, targetId), 'ERROR')
        print(("^0[^3cfx-keydi-ambulance^0] [HEAL]: Validation failed for %s: %s"):format(xPlayer.name, reason or 'No reason provided'))
        if AmbulanceLogs and AmbulanceLogs.Sentry then
            AmbulanceLogs.Sentry({
                system = 'HEAL',
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
    local hasKit, kitItem, kitAmount, payEms = ResolveHealKit(xPlayer)
    if not hasKit then return end

    Vars.ox:RemoveItem(xPlayer.source, kitItem, kitAmount)
    TriggerClientEvent('esx:Notify', xPlayer.source, 'AMBULANCE', 'Heal Complete.', 'success', 5000)

    if payEms then
        local rewardItem = menu.heal.reward.item
        local rewardLabel = (Vars.oxItems and Vars.oxItems[rewardItem] and Vars.oxItems[rewardItem].label) or 'Money'
        Vars.ox:AddItem(xPlayer.source, rewardItem, menu.heal.reward.amount)
        TriggerClientEvent('esx:Notify', xPlayer.source, 'AMBULANCE', ('You received %sx %s'):format(ESX.Math.GroupDigits(menu.heal.reward.amount), rewardLabel), 'success', 5000)
    end
    pcall(function()
        exports['es_extended']:MarkRespawn(xTarget.source, 6000)
        exports['es_extended']:GrantHealthArmorBudget(xTarget.source, 300, 0, 8000)
    end)
    TriggerClientEvent('cfx-keydi-ambulance:syncHeal', xTarget.source)
    TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', xTarget.source)
    TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', xTarget.source)
    exports['es_extended']:SecureSetStatus(xTarget.source, { hunger = 100, thirst = 100, stress = 0 })

    if AmbulanceLogs and AmbulanceLogs.Heal then
        local job = xPlayer.job and (('%s — %s'):format(xPlayer.job.label or xPlayer.job.name, xPlayer.job.grade_label or '')) or nil
        AmbulanceLogs.Heal({
            src = src,
            name = xPlayer.name,
            identifier = xPlayer.identifier,
            job = job,
            targetSrc = targetId,
            targetName = xTarget.name,
            targetIdentifier = xTarget.identifier,
            requireItem = kitItem,
            requireAmount = kitAmount,
            rewardItem = payEms and menu.heal.reward.item or nil,
            rewardAmount = payEms and menu.heal.reward.amount or 0,
            coords = xPlayer.getCoords(true),
            targetCoords = xTarget.getCoords(true),
        })
    end
end)