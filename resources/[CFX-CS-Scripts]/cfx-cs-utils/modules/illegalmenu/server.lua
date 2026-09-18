local config = require 'configs.illegalmenu'
if not config.enable then return end

local Vars = require 'helpers.vars'
local Region = require 'helpers.region'

local cuffed = {}
local dragging = {} -- [dragger] = target

local function notify(src, msg, nType)
    TriggerClientEvent('esx:Notify', src, 'ILLEGAL MENU', msg, nType or 'error', 5000)
end

local function getPlayers(src, targetId)
    targetId = tonumber(targetId)
    if not targetId or targetId < 1 or targetId == src then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end
    return xPlayer, xTarget, targetId
end

local function tooFar(xPlayer, xTarget, maxDist)
    return #(xPlayer.getCoords(true) - xTarget.getCoords(true)) > (maxDist or config.distance)
end

local function blockedJob(xPlayer)
    return xPlayer.job and config.blockedJobs[xPlayer.job.name] == true
end

local function takeItem(src, item)
    if not item or item == '' then return true end
    local count = Vars.ox:Search(src, 'count', item) or 0
    if count < 1 then return false end
    return Vars.ox:RemoveItem(src, item, 1)
end

RegisterNetEvent('cfx-keydi-utils:illegal:cuff', function(targetId)
    local src = source
    local xPlayer, xTarget, target = getPlayers(src, targetId)
    if not xPlayer then return end
    if not Region.Allowed('illegal', src) then
        return notify(src, Region.Message('illegal'))
    end
    if blockedJob(xPlayer) then return end
    if tooFar(xPlayer, xTarget, config.cuffDistance) then
        return notify(src, 'Not close enough to cuff.')
    end
    if cuffed[target] or Player(target).state.cuffed then
        return notify(src, 'That person is already cuffed.')
    end
    if not takeItem(src, config.items.cuff) then
        return notify(src, 'You need a handcuff.')
    end

    cuffed[target] = src
    Player(target).state:set('cuffed', true, true)
    TriggerClientEvent('cfx-keydi-utils:illegal:setCuffed', target, true)
end)

RegisterNetEvent('cfx-keydi-utils:illegal:uncuff', function(targetId)
    local src = source
    local xPlayer, xTarget, target = getPlayers(src, targetId)
    if not xPlayer then return end
    if not Region.Allowed('illegal', src) then
        return notify(src, Region.Message('illegal'))
    end
    if blockedJob(xPlayer) then return end
    if tooFar(xPlayer, xTarget, config.cuffDistance) then
        return notify(src, 'Not close enough to uncuff.')
    end
    if not (cuffed[target] or Player(target).state.cuffed) then
        return notify(src, 'That person is not cuffed.')
    end
    if not takeItem(src, config.items.uncuff) then
        return notify(src, 'You need a handcuff key.')
    end

    if dragging[src] == target then
        dragging[src] = nil
        TriggerClientEvent('cfx-keydi-utils:illegal:setDrag', target, src, false)
    end

    cuffed[target] = nil
    Player(target).state:set('cuffed', false, true)
    TriggerClientEvent('cfx-keydi-utils:illegal:setCuffed', target, false)
end)

RegisterNetEvent('cfx-keydi-utils:illegal:drag', function(targetId)
    local src = source
    local xPlayer, xTarget, target = getPlayers(src, targetId)
    if not xPlayer then return end
    if not Region.Allowed('illegal', src) then
        return notify(src, Region.Message('illegal'))
    end
    if blockedJob(xPlayer) then return end
    if tooFar(xPlayer, xTarget, config.distance) then
        return notify(src, 'No players nearby.')
    end

    if dragging[src] == target then
        dragging[src] = nil
        TriggerClientEvent('cfx-keydi-utils:illegal:setDrag', target, src, false)
        return
    end

    if config.requireCuffedToDrag and not (cuffed[target] or Player(target).state.cuffed) then
        return notify(src, 'You need to cuff first.')
    end
    if config.items.drag and config.items.drag ~= '' then
        local count = Vars.ox:Search(src, 'count', config.items.drag) or 0
        if count < 1 then
            return notify(src, 'You need a rope.')
        end
    end

    dragging[src] = target
    TriggerClientEvent('cfx-keydi-utils:illegal:setDrag', target, src, true)
end)

RegisterNetEvent('cfx-keydi-utils:illegal:removeClothes', function(targetId, clothingType)
    local src = source
    local xPlayer, xTarget, target = getPlayers(src, targetId)
    if not xPlayer then return end
    if not Region.Allowed('illegal', src) then
        return notify(src, Region.Message('illegal'))
    end
    if blockedJob(xPlayer) then return end
    if type(clothingType) ~= 'string' then return end
    if tooFar(xPlayer, xTarget, config.distance) then
        return notify(src, 'No players nearby.')
    end
    if config.requireCuffedToStrip and not (cuffed[target] or Player(target).state.cuffed) then
        return notify(src, 'You need to cuff first.')
    end

    TriggerClientEvent('cfx-keydi-utils:Clothing:RemoveAction', target, {
        value = clothingType,
        robber = src,
    })
end)

AddEventHandler('playerDropped', function()
    local src = source
    cuffed[src] = nil
    dragging[src] = nil
    for dragger, target in pairs(dragging) do
        if target == src then
            dragging[dragger] = nil
        end
    end
end)
