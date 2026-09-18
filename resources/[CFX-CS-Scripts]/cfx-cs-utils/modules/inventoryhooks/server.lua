--[[
  Block clean money (ox_inventory `money`) from:
  - stashes / temp stashes / evidence
  - vehicle trunk & glovebox
  - ground drops
  Dirty money (`black_money`) is still allowed.
  https://overextended.dev/docs/ox_inventory/Functions/Server/Hooks
]]

local BLOCKED_TYPES = {
    stash = true,
    temp = true,
    trunk = true,
    glovebox = true,
    drop = true,
    newdrop = true,
    policeevidence = true,
    dumpster = true,
}

local function isMoneySlot(slot)
    return type(slot) == 'table' and slot.name == 'money'
end

local function notifyBlocked(src)
    if type(src) ~= 'number' or src < 1 then return end
    TriggerClientEvent('esx:Notify', src,
        'INVENTORY',
        'Clean money cannot be dropped or stored in stashes / vehicle storage.',
        'error',
        4000
    )
end

local function shouldBlock(payload)
    if not payload then return false end

    local fromType = payload.fromType
    local toType = payload.toType
    local fromMoney = isMoneySlot(payload.fromSlot)
    local toMoney = isMoneySlot(payload.toSlot)

    -- Putting money into stash / trunk / glovebox / floor drop
    if fromMoney and BLOCKED_TYPES[toType] then
        return true
    end

    -- Swapping a container/drop item onto player money (would put cash into the container)
    if toMoney and BLOCKED_TYPES[fromType] then
        return true
    end

    return false
end

local hookId

local function registerMoneyHook()
    if GetResourceState('ox_inventory') ~= 'started' then return end

    if hookId then
        pcall(function()
            exports.ox_inventory:removeHooks(hookId)
        end)
        hookId = nil
    end

    hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
        if not shouldBlock(payload) then return end
        notifyBlocked(payload.source)
        return false
    end, {
        itemFilter = {
            money = true,
        },
        print = false,
    })
end

CreateThread(function()
    Wait(1000)
    registerMoneyHook()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'ox_inventory' or resource == GetCurrentResourceName() then
        CreateThread(function()
            Wait(500)
            registerMoneyHook()
        end)
    end
end)
