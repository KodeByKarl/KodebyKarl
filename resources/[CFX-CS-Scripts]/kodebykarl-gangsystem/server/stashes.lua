local ESX = exports['es_extended']:getSharedObject()

local privateMeta = {}

local function registerStashes()
    if GetResourceState('ox_inventory') ~= 'started' then
        print('[kodebykarl-gangsystem] ox_inventory not started — stashes skipped')
        return
    end

    local ox = exports.ox_inventory

    for gangName, cfg in pairs(Config.Gangs) do
        local slots = (cfg.stash and cfg.stash.slots) or 100
        local maxWeight = (cfg.stash and cfg.stash.maxWeight) or 500000
        local bossSlots = (cfg.stash and cfg.stash.bossSlots) or 80
        local bossWeight = (cfg.stash and cfg.stash.bossMaxWeight) or 400000

        ox:RegisterStash(('gang_%s_share'):format(gangName), ('%s Shared Stash'):format(cfg.label), slots, maxWeight, false)
        ox:RegisterStash(('gang_%s_boss'):format(gangName), ('%s Boss Stash'):format(cfg.label), bossSlots, bossWeight, false)

        privateMeta[gangName] = {
            slots = (cfg.stash and cfg.stash.privateSlots) or 50,
            maxWeight = (cfg.stash and cfg.stash.privateMaxWeight) or 200000,
            label = ('%s Private Stash'):format(cfg.label),
        }

        print(('[kodebykarl-gangsystem] Registered stashes for %s'):format(gangName))
    end
end

lib.callback.register('kodebykarl-gangsystem:getPrivateStashId', function(source, gangName)
    local gang = GangServer.GetPlayerGang(source)
    gangName = tostring(gangName or ''):lower()
    if not gang or gang.name ~= gangName then return nil end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local meta = privateMeta[gangName]
    local cfg = Config.Gangs[gangName]
    local slots = meta and meta.slots or 50
    local maxWeight = meta and meta.maxWeight or 200000
    local label = meta and meta.label or ((cfg and cfg.label or 'Gang') .. ' Private Stash')

    local id = ('gang_%s_private_%s'):format(gangName, xPlayer.identifier)
    exports.ox_inventory:RegisterStash(id, label, slots, maxWeight, true)
    return id
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() and resource ~= 'ox_inventory' then return end
    SetTimeout(500, registerStashes)
end)
