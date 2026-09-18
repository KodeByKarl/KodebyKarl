-- Unique project-car parts. Item name = `{prefix}_{suffix}` (charger_engine, civic_tires, …)
local CARS = {
    { prefix = 'charger', short = 'Charger' },
    { prefix = 'topcar', short = 'Top Car' },
    { prefix = 'm760i', short = 'M760i' },
    { prefix = 'mansory', short = 'Mansory' },
    { prefix = 'silvia', short = 'Silvia' },
    { prefix = 'performante', short = 'Performante' },
    { prefix = 'rs7', short = 'RS7' },
    { prefix = 'velar', short = 'Velar' },
    { prefix = 'gv80', short = 'GV80' },
    { prefix = 'xb7', short = 'XB7' },
    { prefix = 'rsq8', short = 'RSQ8' },
    { prefix = 'sierra', short = 'Sierra' },
    { prefix = 'artura', short = 'Artura' },
    { prefix = 'g63', short = 'G63' },
    { prefix = 'm5', short = 'M5' },
    { prefix = 'bmwm8', short = 'BMW M8' },
    { prefix = 'x7', short = 'X7' },
    { prefix = 'dragg', short = 'Dragg' },
    { prefix = 'civic', short = 'Civic' },
    { prefix = 'odyssey', short = 'Odyssey' },
    { prefix = 'gts', short = 'GTS' },
    { prefix = 'mk4', short = 'MK4' },
    { prefix = 'wrx', short = 'WRX' },
    { prefix = 'mle7', short = 'MLE7' },
    { prefix = 'r34', short = 'R34' },
    { prefix = 'gtrr34', short = 'GTR R34' },
    { prefix = 'rx7', short = 'RX7' },
    { prefix = 'mits', short = 'Mits' },
    { prefix = 'tahoe', short = 'Tahoe' },
    { prefix = 'ghispo', short = 'Ghispo' },
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
