--[[
    kodebykarl-projectcars — unique per-vehicle parts

    Item name = `{prefix}_{suffix}`  e.g. charger_engine, civic_tires

    INSTALL (pick one):

    A) Drop this file into ox_inventory/data/project_car_items.lua
       then add this to ox_inventory/modules/items/shared.lua
       AFTER the data.items loop:

         for k, v in pairs(lib.load('data.project_car_items') or {}) do
             v.name = k
             local success, response = pcall(newItem, v)
             if not success then
                 warn(('An error occurred while creating item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(k, response))
             end
         end

    B) Merge the generated table into ox_inventory/data/items.lua instead.

    Keep prefixes in sync with kodebykarl-projectcars/config.lua (Config.Vehicles).
]]

local CARS = {
    { prefix = 'odyssey', short = 'Odyssey' },
    { prefix = 'civic', short = 'Civic' },
    { prefix = 'charger', short = 'Charger' },
    { prefix = 'silvia', short = 'Silvia' },
    { prefix = 'sierra', short = 'Sierra' },
    { prefix = 'dragg', short = 'Dragg' },
    { prefix = 'topcar', short = 'Top Car' },
    { prefix = 'mansory', short = 'Mansory' },
    { prefix = 'velar', short = 'Velar' },
    { prefix = 'gv80', short = 'GV80' },
    { prefix = 'g63', short = 'G63' },
    { prefix = 'rs7', short = 'RS7' },
    { prefix = 'rsq8', short = 'RSQ8' },
    { prefix = 'm760i', short = 'M760i' },
    { prefix = 'xb7', short = 'XB7' },
    { prefix = 'm5', short = 'M5' },
    { prefix = 'x7', short = 'X7' },
    { prefix = 'bmwm8', short = 'BMW M8' },
    { prefix = 'performante', short = 'Performante' },
    { prefix = 'artura', short = 'Artura' },
    { prefix = 'tahoe', short = 'Tahoe' },
    { prefix = 'ghispo', short = 'Ghispo' },
    { prefix = 'gtrr34', short = 'GTR R34' },
    { prefix = 'gts', short = 'GTS' },
    { prefix = 'mk4', short = 'MK4' },
    { prefix = 'mle7', short = 'MLE7' },
    { prefix = 'wrx', short = 'WRX' },
    { prefix = 'r34', short = 'R34' },
    { prefix = 'rx7', short = 'RX7' },
    { prefix = 'mits', short = 'Mits' },
}

local PARTS = {
    { suffix = 'engine', label = 'Engine', weight = 400, image = 'car_engine_part.png' },
    { suffix = 'transmission', label = 'Transmission', weight = 400, image = 'car_transmission.png' },
    { suffix = 'suspension', label = 'Suspension', weight = 300, image = 'car_wheel.png' },
    { suffix = 'body_frame', label = 'Body Frame', weight = 500, image = 'vehicle_shell.png' },
    { suffix = 'tires', label = 'Tires', weight = 400, image = 'car_wheel.png' },
    { suffix = 'doors', label = 'Doors', weight = 350, image = 'car_door.png' },
    { suffix = 'windows', label = 'Windows', weight = 150, image = 'glass.png' },
}

local ITEMS = {}

for i = 1, #CARS do
    local car = CARS[i]
    for p = 1, #PARTS do
        local part = PARTS[p]
        ITEMS[('%s_%s'):format(car.prefix, part.suffix)] = {
            label = ('%s %s'):format(car.short, part.label),
            weight = part.weight,
            stack = true,
            close = true,
            description = ('Fits %s project cars only.'):format(car.short),
            client = {
                image = part.image,
            },
        }
    end
end

return ITEMS
