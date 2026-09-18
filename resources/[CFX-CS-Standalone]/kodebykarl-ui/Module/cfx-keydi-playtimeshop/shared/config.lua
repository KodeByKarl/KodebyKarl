ConfigPlaytimeShop = {}

ConfigPlaytimeShop.Command = 'playtimeshop'
ConfigPlaytimeShop.OpenKey = 'F7'

-- Every 35 minutes online → +3 Grim Coins
ConfigPlaytimeShop.RewardIntervalMinutes = 35
ConfigPlaytimeShop.RewardCoins = 3

-- Server tick interval (seconds) — keep high for 0.00 idle feel
ConfigPlaytimeShop.TickSeconds = 60

ConfigPlaytimeShop.GarageId = 'Legion Square'
-- Fallback only if kodebykarl-projectcars is down. Live shop rolls a random pack car per item.
ConfigPlaytimeShop.ProjectModel = 'ody18'

-- Items that get per-vehicle unique parts (Charger Engine, Civic Tires, etc.)
ConfigPlaytimeShop.ProjectPartItems = {
    vehicle_shell = true,
    project_parts_box = true,
    car_blueprint = true,
    engine = true,
    transmission = true,
    suspension = true,
    bodyframe = true,
    tire = true,
    door = true,
    window = true,
}

-- Street kit (Items tab)
ConfigPlaytimeShop.Items = {
    { id = 'bandage', label = 'BANDAGE', item = 'bandage', amount = 5, price = 15, image = 'bandage' },
    { id = 'lockpick', label = 'LOCKPICK', item = 'lockpick', amount = 1, price = 35, image = 'lockpick' },
    { id = 'armor', label = 'ARMOR', item = 'armour', amount = 1, price = 80, image = 'armour' },
    { id = 'repairkit', label = 'REPAIR KIT', item = 'repairkit', amount = 1, price = 45, image = 'repairkit' },
    { id = 'phone', label = 'PHONE', item = 'phone', amount = 1, price = 60, image = 'phone' },
    { id = 'radio', label = 'RADIO', item = 'radio', amount = 1, price = 50, image = 'radio' },
    { id = 'water', label = 'WATER', item = 'water', amount = 5, price = 10, image = 'water' },
    { id = 'burger', label = 'BURGER', item = 'burger', amount = 5, price = 12, image = 'burger' },
}

-- Car parts catalog (Cars tab) — kind 'part' = inventory item, kind 'vehicle' = garage car
ConfigPlaytimeShop.Cars = {
    {
        id = 'vehicle_shell',
        label = 'VEHICLE SHELL',
        kind = 'part',
        item = 'vehicle_shell',
        amount = 1,
        price = 10,
        stock = 5,
        image = 'vehicle_shell',
    },
    {
        id = 'project_parts_box',
        label = 'PROJECT PARTS BOX',
        kind = 'part',
        item = 'project_parts_box',
        amount = 1,
        price = 10,
        stock = 2,
        image = 'project_parts_box',
    },
    {
        id = 'car_blueprint',
        label = 'PROJECT VEHICLE BLUEPRINT',
        kind = 'part',
        item = 'car_blueprint',
        amount = 1,
        price = 500,
        stock = 100,
        image = 'car_blueprint',
    },
    { id = 'engine', label = 'ENGINE', kind = 'part', item = 'engine', amount = 1, price = 10, stock = 3, image = 'car_engine_part' },
    { id = 'transmission', label = 'TRANSMISSION', kind = 'part', item = 'transmission', amount = 1, price = 10, stock = 5, image = 'car_transmission' },
    { id = 'suspension', label = 'SUSPENSION', kind = 'part', item = 'suspension', amount = 1, price = 10, stock = 4, image = 'car_wheel' },
    { id = 'bodyframe', label = 'BODY FRAME', kind = 'part', item = 'bodyframe', amount = 1, price = 10, stock = 3, image = 'vehicle_shell' },
    { id = 'tire', label = 'TIRES SET', kind = 'part', item = 'tire', amount = 4, price = 10, stock = 6, image = 'car_wheel' },
    { id = 'door', label = 'DOORS SET', kind = 'part', item = 'door', amount = 4, price = 10, stock = 5, image = 'car_door' },
    { id = 'window', label = 'WINDOWS SET', kind = 'part', item = 'window', amount = 4, price = 10, stock = 6, image = 'glass' },
}

ConfigPlaytimeShop.PageSize = 6
ConfigPlaytimeShop.TopLimit = 10
