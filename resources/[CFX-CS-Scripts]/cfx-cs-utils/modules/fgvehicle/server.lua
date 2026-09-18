local fg = require 'helpers.fiveguard'

local SESSIONS = {
    repair = {
        Vehicle = { 'BypassVehicleFixAndGodMode' },
    },
    plate = {
        Vehicle = { 'BypassVehiclePlateChanger' },
    },
    apply = {
        Vehicle = {
            'BypassVehicleModifier',
            'BypassVehicleHandlingEdit',
            'BypassBulletproofTires',
            'BypassVehiclePlateChanger',
            'BypassVehicleFixAndGodMode',
        },
    },
    mods = {
        Vehicle = {
            'BypassVehicleFixAndGodMode',
            'BypassVehiclePlateChanger',
            'BypassVehicleHandlingEdit',
            'BypassVehicleModifier',
            'BypassBulletproofTires',
        },
        Client = { 'BypassNoclip', 'BypassInvisible', 'BypassFreecam' },
    },
    showroom = {
        Vehicle = {
            'BypassVehiclePlateChanger',
            'BypassVehicleFixAndGodMode',
            'BypassVehicleModifier',
        },
        Client = { 'BypassNoclip', 'BypassInvisible', 'BypassFreecam' },
    },
    testdrive = {
        Vehicle = { 'BypassVehiclePlateChanger', 'BypassVehicleFixAndGodMode' },
        Client = { 'BypassNoclip', 'BypassInvisible' },
    },
    display = {
        Vehicle = {
            'BypassVehiclePlateChanger',
            'BypassVehicleFixAndGodMode',
            'BypassVehicleModifier',
        },
        Client = { 'BypassNoclip', 'BypassInvisible' },
    },
}

local counts = {}
local tokens = {}
local nextToken = 0

local function bump(src, grants, delta)
    counts[src] = counts[src] or {}
    for category, perms in pairs(grants) do
        counts[src][category] = counts[src][category] or {}
        for i = 1, #perms do
            local perm = perms[i]
            local nextCount = (counts[src][category][perm] or 0) + delta
            if nextCount < 0 then nextCount = 0 end
            counts[src][category][perm] = nextCount
            if delta > 0 and nextCount == 1 then
                fg.set(src, category, perm, true)
            elseif delta < 0 and nextCount == 0 then
                fg.set(src, category, perm, false)
            end
        end
    end
end

local function revokeAll(src)
    local playerCounts = counts[src]
    if playerCounts then
        for category, perms in pairs(playerCounts) do
            for perm, n in pairs(perms) do
                if n > 0 then
                    fg.set(src, category, perm, false)
                end
            end
        end
    end
    counts[src] = nil
    tokens[src] = nil
end

---@param src number
---@param session string
---@param enable boolean
---@param ttl number|nil
local function setSession(src, session, enable, ttl)
    src = tonumber(src)
    local grants = SESSIONS[session]
    if not src or not grants then return false end

    tokens[src] = tokens[src] or {}

    if enable then
        if tokens[src][session] then
            return true
        end
        nextToken = nextToken + 1
        local token = nextToken
        tokens[src][session] = token
        bump(src, grants, 1)
        if ttl and ttl > 0 then
            SetTimeout(ttl, function()
                if tokens[src] and tokens[src][session] == token then
                    tokens[src][session] = nil
                    bump(src, grants, -1)
                end
            end)
        end
        return true
    end

    if not tokens[src][session] then
        return true
    end
    tokens[src][session] = nil
    bump(src, grants, -1)
    return true
end

exports('FgVehicleSession', setSession)

AddEventHandler('playerDropped', function()
    revokeAll(source)
end)
