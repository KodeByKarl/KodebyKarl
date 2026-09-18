--[[
    Paste this AFTER the `data.items` loop in:

      ox_inventory/modules/items/shared.lua

    Only needed if you use install/ox_inventory/project_car_items.lua
    as a separate data file (option A in that file).
]]

for k, v in pairs(lib.load('data.project_car_items') or {}) do
    v.name = k
    local success, response = pcall(newItem, v)
    if not success then
        warn(('An error occurred while creating item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(k, response))
    end
end
