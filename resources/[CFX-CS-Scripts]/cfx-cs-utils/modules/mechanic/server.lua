local Config = require 'configs.mechanic'
local Vars = require 'helpers.vars'

if not Config.Enabled then return end

local cooldown = {}

local function notify(src, msg, nType)
    TriggerClientEvent('esx:showNotification', src, msg, nType or 'error')
end

local function kitItemNames(cfg)
    if not cfg then return {} end
    if cfg.items then return cfg.items end
    if cfg.item then return { cfg.item } end
    return {}
end

local function consumeKit(src, action)
    local cfg = action == 'repair' and Config.Repair or Config.Clean
    if not cfg or not cfg.item then return false, 'Invalid action.' end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return false, 'Player not found.'
    end

    if Config.Job then
        local job = xPlayer.job
        local minGrade = job and Config.Job[job.name]
        if minGrade == nil or (tonumber(job.grade) or 0) < minGrade then
            return false, 'Mechanic job required.'
        end
    end

    local now = GetGameTimer()
    if cooldown[src] and (now - cooldown[src]) < 1500 then
        return false, 'Wait a moment.'
    end
    cooldown[src] = now

    local amount = cfg.amount or 1
    local names = kitItemNames(cfg)
    local usedItem
    for i = 1, #names do
        local count = Vars.ox:Search(src, 'count', names[i]) or 0
        if count >= amount then
            usedItem = names[i]
            break
        end
    end

    if not usedItem then
        local item = Vars.oxItems[cfg.item]
        local label = item and item.label or cfg.item
        return false, ('You need %sx %s'):format(amount, label)
    end

    if not Vars.ox:RemoveItem(src, usedItem, amount) then
        return false, 'Could not use the kit.'
    end

    if action == 'repair' then
        pcall(function()
            exports[GetCurrentResourceName()]:FgVehicleSession(src, 'repair', true, 8000)
        end)
    end

    return true
end

lib.callback.register('cfx-keydi-utils:mechanic:useKit', function(source, action)
    local ok, err = consumeKit(source, action)
    return ok, err
end)

AddEventHandler('playerDropped', function()
    cooldown[source] = nil
end)
