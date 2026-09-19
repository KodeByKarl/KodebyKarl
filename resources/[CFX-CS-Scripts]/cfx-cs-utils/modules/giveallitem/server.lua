--[[
  Owner/developer only: /giveallitem [item] [count]
  Gives an item to every online player. Server-side command only (no client events).
]]

local GiveAll = require 'configs.giveallitem'
local Vars = require 'helpers.vars'

if not GiveAll or not GiveAll.Enabled then return end

local AllowedGroups = GiveAll.AllowedGroups or { 'owner', 'developer' }
local lastUsedAt = {}

local function notify(src, message, msgType)
    if src == 0 then
        print(('[giveallitem] %s'):format(message))
        return
    end
    TriggerClientEvent('esx:Notify', src, GiveAll.NotifyTitle or 'GIVE ALL ITEM', message, msgType or 'info', 7000)
end

local function isAllowed(xPlayer)
    if not xPlayer or not xPlayer.getGroup then return false end
    if not Core or not Core.CommandAllowsGroup then
        local group = tostring(xPlayer.getGroup() or ''):lower()
        for i = 1, #AllowedGroups do
            if tostring(AllowedGroups[i] or ''):lower() == group then
                return true
            end
        end
        return false
    end
    return Core.CommandAllowsGroup(AllowedGroups, xPlayer.getGroup())
end

local function staffLabel(xPlayer)
    if not xPlayer then return 'console' end
    return ('%s [%s]'):format(xPlayer.name, xPlayer.source)
end

local function giveToAll(src, xPlayer, item, amount)
    local itemDef = Vars.ox:Items(item)
    if not itemDef then
        notify(src, ('Unknown item: %s'):format(item), 'error')
        return
    end

    local label = itemDef.label or item
    local given, failed = 0, 0
    local players = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers() or nil

    if players then
        for i = 1, #players do
            local xTarget = players[i]
            local tid = xTarget.source
            local ok = Vars.ox:AddItem(tid, item, amount)
            if ok then
                given += 1
                notify(tid, ('You received %sx %s.'):format(amount, label), 'success')
            else
                failed += 1
            end
        end
    else
        local ids = GetPlayers()
        for i = 1, #ids do
            local tid = tonumber(ids[i])
            if tid then
                local ok = Vars.ox:AddItem(tid, item, amount)
                if ok then
                    given += 1
                    notify(tid, ('You received %sx %s.'):format(amount, label), 'success')
                else
                    failed += 1
                end
            end
        end
    end

    notify(src, ('Gave %sx %s to %s player(s)%s.'):format(
        amount,
        label,
        given,
        failed > 0 and (' (%s failed)'):format(failed) or ''
    ), given > 0 and 'success' or 'error')

    lib.logger(src ~= 0 and src or 'console', 'cfx-keydi-giveallitem',
        ('GIVE ALL ITEM | Staff: %s | Item: %s | Amount: %s | given=%s failed=%s'):format(
            staffLabel(xPlayer), item, amount, given, failed
        ), 'INFO')
end

ESX.RegisterCommand('giveallitem', AllowedGroups, function(xPlayer, args)
    local src = xPlayer and xPlayer.source or 0

    if src ~= 0 and not isAllowed(xPlayer) then
        lib.logger(src, 'cfx-keydi-sentry',
            ('UNAUTHORIZED GIVEALLITEM | Staff: %s | Group: %s'):format(
                staffLabel(xPlayer), xPlayer.getGroup and xPlayer.getGroup() or '?'
            ), 'ERROR')
        notify(src, 'Owner/developer access only.', 'error')
        return
    end

    local now = os.time()
    if lastUsedAt[src] and (now - lastUsedAt[src]) < 2 then
        notify(src, 'Wait a moment before using this again.', 'error')
        return
    end

    local item = args.item
    if type(item) ~= 'string' or item == '' then
        notify(src, 'Usage: /giveallitem [item] [count]', 'error')
        return
    end

    item = item:gsub('%s+', '')
    local amount = math.floor(tonumber(args.count) or 1)
    local maxAmount = GiveAll.MaxAmount or 50

    if amount < 1 or amount > maxAmount then
        notify(src, ('Amount must be between 1 and %s.'):format(maxAmount), 'error')
        return
    end

    lastUsedAt[src] = now
    giveToAll(src, xPlayer, item, amount)
end, true, {
    help = 'Give an item to all online players (owner/developer only)',
    validate = false,
    arguments = {
        { name = 'item', help = 'Item spawn name (e.g. bread)', type = 'any' },
        { name = 'count', help = 'Amount per player (default 1)', type = 'number', validate = false },
    },
})
