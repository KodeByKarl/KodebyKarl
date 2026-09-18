--[[
    Gun Trade-In Shop (Server)
    Validates distance, removes one firearm slot, grants random 1–5 parts.
]]

local Config = require 'configs.guntrade'
local Vars = require 'helpers.vars'

local cooldown = {}

local function isWeaponName(name)
    return type(name) == 'string' and name:sub(1, 7) == 'WEAPON_'
end

local function isBlockedWeapon(name)
    if not isWeaponName(name) then return true end
    if Config.blockedWeapons and Config.blockedWeapons[name] then
        return true
    end

    -- Prefer firearms that use ammo (matches weapon license logic)
    local item = Vars.ox:Items(name)
    if type(item) == 'table' then
        if item.weapon and not item.ammoname then
            return true
        end
    end

    return false
end

local function isPoliceIssued(metadata)
    if not Config.blockPoliceSerial then return false end
    if type(metadata) ~= 'table' then return false end

    local serial = metadata.serial
    if type(serial) ~= 'string' or serial == '' then return false end

    local upper = serial:upper()
    local prefixes = Config.policeSerials or {}
    for prefix in pairs(prefixes) do
        if upper:sub(1, #prefix) == prefix:upper() then
            return true
        end
    end
    return false
end

local function isNearShop(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    local c = Config.coords
    local maxDist = (Config.interactDistance or 2.5) + 3.0
    return #(coords - vec3(c.x, c.y, c.z)) <= maxDist
end

local function itemLabel(name)
    local item = Vars.ox:Items(name)
    if type(item) == 'table' and item.label then
        return item.label
    end
    return name
end

local function listTradeableWeapons(src)
    local inv = Vars.ox:GetInventory(src)
    if not inv or type(inv.items) ~= 'table' then
        return {}
    end

    local out = {}
    for slot, item in pairs(inv.items) do
        if item and isWeaponName(item.name) and not isBlockedWeapon(item.name) and not isPoliceIssued(item.metadata) then
            out[#out + 1] = {
                slot = item.slot or slot,
                name = item.name,
                label = item.label or itemLabel(item.name),
                serial = item.metadata and item.metadata.serial or nil,
            }
        end
    end

    table.sort(out, function(a, b)
        if a.label == b.label then
            return (a.slot or 0) < (b.slot or 0)
        end
        return a.label < b.label
    end)

    return out
end

local function rollParts()
    local pool = Config.parts or {}
    if #pool == 0 then return {} end

    local minParts = tonumber(Config.minParts) or 1
    local maxParts = tonumber(Config.maxParts) or 5
    if maxParts < minParts then maxParts = minParts end

    local amount = math.random(minParts, maxParts)
    local stacked = {}
    local order = {}

    for _ = 1, amount do
        local part = pool[math.random(1, #pool)]
        if not stacked[part] then
            stacked[part] = 0
            order[#order + 1] = part
        end
        stacked[part] = stacked[part] + 1
    end

    local rewards = {}
    for i = 1, #order do
        local name = order[i]
        rewards[#rewards + 1] = {
            item = name,
            count = stacked[name],
            label = itemLabel(name),
        }
    end
    return rewards
end

local function summarizeRewards(rewards)
    local bits = {}
    for i = 1, #rewards do
        local r = rewards[i]
        bits[#bits + 1] = ('x%d %s'):format(r.count, r.label)
    end
    return table.concat(bits, ', ')
end

lib.callback.register('cfx-keydi-utils:guntrade:getWeapons', function(source)
    if not isNearShop(source) then
        return {}
    end
    return listTradeableWeapons(source)
end)

lib.callback.register('cfx-keydi-utils:guntrade:trade', function(source, slot, weaponName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return false, 'Player not found.'
    end

    if not isNearShop(src) then
        return false, 'Too far from the trade shop.'
    end

    slot = tonumber(slot)
    if not slot or type(weaponName) ~= 'string' then
        return false, 'Invalid trade request.'
    end

    local now = os.time()
    local cd = Config.cooldown or 3
    if cooldown[src] and (now - cooldown[src]) < cd then
        return false, 'Wait a moment before trading again.'
    end

    if isBlockedWeapon(weaponName) then
        return false, 'That item cannot be traded in.'
    end

    local inv = Vars.ox:GetInventory(src)
    local item = inv and inv.items and inv.items[slot]
    if not item or item.name ~= weaponName then
        return false, 'Weapon no longer in that inventory slot.'
    end

    if isPoliceIssued(item.metadata) then
        return false, 'Department-issued firearms cannot be traded here.'
    end

    local rewards = rollParts()
    if #rewards == 0 then
        return false, 'Trade shop has no parts configured.'
    end

    -- Ensure capacity for all rewards before removing the gun
    for i = 1, #rewards do
        local r = rewards[i]
        if Vars.ox:CanCarryItem(src, r.item, r.count) == false then
            return false, 'Not enough inventory space for the trade parts.'
        end
    end

    local removed = Vars.ox:RemoveItem(src, weaponName, 1, nil, slot)
    if not removed then
        return false, 'Could not take the firearm.'
    end

    for i = 1, #rewards do
        local r = rewards[i]
        if not Vars.ox:AddItem(src, r.item, r.count) then
            -- Refund gun + any parts already given
            Vars.ox:AddItem(src, weaponName, 1, item.metadata)
            for j = 1, i - 1 do
                local given = rewards[j]
                Vars.ox:RemoveItem(src, given.item, given.count)
            end
            return false, 'Failed to deliver parts. Firearm refunded.'
        end
    end

    cooldown[src] = now
    local gunLabel = item.label or itemLabel(weaponName)
    return true, gunLabel, summarizeRewards(rewards)
end)

AddEventHandler('playerDropped', function()
    cooldown[source] = nil
end)
