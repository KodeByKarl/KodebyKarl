local models = require 'configs.sitanywheremodels'

local occupied = {} -- [seatKey] = { [seatIndex] = source }
local sitting = {} -- [source] = { key = seatKey, seat = index }

local function freeSeat(src)
    local info = sitting[src]
    if not info then return end

    local slots = occupied[info.key]
    if slots and slots[info.seat] == src then
        slots[info.seat] = nil
        if next(slots) == nil then
            occupied[info.key] = nil
        end
    end

    sitting[src] = nil
end

lib.callback.register('cfx-keydi-utils:sitanywhere:occupy', function(source, seatKey, hash)
    if type(seatKey) ~= 'string' or seatKey == '' then return false end
    if sitting[source] then return false end

    hash = tonumber(hash)
    local model = hash and models[hash]
    if not model then return false end

    local max = model.maxSeats or 1
    occupied[seatKey] = occupied[seatKey] or {}

    for i = 1, max do
        if not occupied[seatKey][i] then
            occupied[seatKey][i] = source
            sitting[source] = { key = seatKey, seat = i }
            return i
        end
    end

    return false
end)

RegisterNetEvent('cfx-keydi-utils:sitanywhere:free', function(seatKey, seat)
    local src = source
    local info = sitting[src]
    if not info then return end
    if info.key ~= seatKey or info.seat ~= seat then return end
    freeSeat(src)
end)

AddEventHandler('playerDropped', function()
    freeSeat(source)
end)
