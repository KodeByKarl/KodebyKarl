local ESX = exports['es_extended']:getSharedObject()

local privateMeta = {}

local function registerStashes()
    if GetResourceState('ox_inventory') ~= 'started' then
        print('[kodebykarl-gangsystem] ox_inventory not started — stashes skipped')
        return
    end

    local ox = exports.ox_inventory

    for gangName, cfg in pairs(Config.Gangs) do
        if cfg.stashes then
            local pub = cfg.stashes.public
            if pub and pub.id then
                local label = pub.label or (cfg.label .. ' Public Stash')
                local slots = pub.slots or 300
                local weight = pub.maxWeight or 1000000
                ox:RegisterStash(pub.id, label, slots, weight, false)
                -- Alias legacy share stash ID
                if pub.id ~= ('gang_%s_share'):format(gangName) then
                    ox:RegisterStash(('gang_%s_share'):format(gangName), label, slots, weight, false)
                end
            end

            local boss = cfg.stashes.boss
            if boss and boss.id then
                local label = boss.label or (cfg.label .. ' Boss Stash')
                local slots = boss.slots or 300
                local weight = boss.maxWeight or 1000000
                ox:RegisterStash(boss.id, label, slots, weight, false)
                -- Alias legacy boss stash ID
                if boss.id ~= ('gang_%s_boss'):format(gangName) then
                    ox:RegisterStash(('gang_%s_boss'):format(gangName), label, slots, weight, false)
                end
            end

            local priv = cfg.stashes.private
            if priv then
                privateMeta[gangName] = {
                    id = priv.id or ('gang_%s_private'):format(gangName),
                    slots = priv.slots or 100,
                    maxWeight = priv.maxWeight or 3000000,
                    label = priv.label or (cfg.label .. ' Private Stash'),
                }
            end
        else
            local slots = (cfg.stash and cfg.stash.slots) or 100
            local maxWeight = (cfg.stash and cfg.stash.maxWeight) or 500000
            local bossSlots = (cfg.stash and cfg.stash.bossSlots) or 80
            local bossWeight = (cfg.stash and cfg.stash.bossMaxWeight) or 400000

            ox:RegisterStash(('gang_%s_share'):format(gangName), ('%s Shared Stash'):format(cfg.label), slots, maxWeight, false)
            ox:RegisterStash(('gang_%s_boss'):format(gangName), ('%s Boss Stash'):format(cfg.label), bossSlots, bossWeight, false)

            privateMeta[gangName] = {
                id = ('gang_%s_private'):format(gangName),
                slots = (cfg.stash and cfg.stash.privateSlots) or 50,
                maxWeight = (cfg.stash and cfg.stash.privateMaxWeight) or 200000,
                label = ('%s Private Stash'):format(cfg.label),
            }
        end
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
    local slots = (meta and meta.slots) or 100
    local maxWeight = (meta and meta.maxWeight) or 3000000
    local label = (meta and meta.label) or ((cfg and cfg.label or 'Gang') .. ' Private Stash')
    local baseId = (meta and meta.id) or (cfg and cfg.stashes and cfg.stashes.private and cfg.stashes.private.id) or ('gang_%s_private'):format(gangName)

    local id = ('%s_%s'):format(baseId, xPlayer.identifier)
    exports.ox_inventory:RegisterStash(id, label, slots, maxWeight, true)
    return id
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() and resource ~= 'ox_inventory' then return end
    SetTimeout(500, registerStashes)
end)
