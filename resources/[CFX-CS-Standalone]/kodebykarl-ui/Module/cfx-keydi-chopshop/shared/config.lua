Config = Config or {}

--[[
  Illegal Chop — dismantle owned vehicles for dirty cash.
  Starts a police dispatch the moment a chop begins.

  Chopped vehicles are NOT deleted from owned_vehicles.
  They are disabled in-memory until server restart (alon), then usable again.
]]
Config.ChopShop = {
    Label = "Illegal Chop",
    -- Total dismantle time across all progress segments (skill checks add extra time on top)
    ProgressDuration = 45000,
    Cooldown = 120000, -- 2 min between chops
    InteractionDistance = 3.2,
    ZoneRadius = 8.0,
    DrawDistance = 50.0,
    MaxVehicleSpeed = 1.2,

    -- Chop sequence: skill check → progress segment → repeat
    -- Progress percents are display labels; durations split ProgressDuration evenly unless set.
    Sequence = {
        {
            skillCheck = { 'easy', 'hard', 'hard' },
            progressFrom = 1,
            progressTo = 25,
            label = 'Dismantling body…',
        },
        {
            skillCheck = { 'easy', 'hard', 'hard' },
            progressFrom = 25,
            progressTo = 50,
            label = 'Stripping parts…',
        },
        {
            skillCheck = { 'easy', 'hard', 'hard' },
            progressFrom = 50,
            progressTo = 75,
            label = 'Cutting frame…',
        },
        {
            skillCheck = { 'medium', 'hard', 'hard', 'medium', 'hard', 'hard', 'medium' },
            progressFrom = 75,
            progressTo = 100,
            label = 'Crushing remains…',
        },
    },
    SkillCheckKeys = { 'w', 'a', 's', 'd' },

    -- Police / sheriff alert when a chop starts
    Dispatch = {
        enabled = true,
        jobs = { "police", "sheriff" },
        message = "Illegal vehicle chop in progress",
        duration = 15000,
        blipSprite = 380,
        blipColor = 1,
        blipScale = 1.0,
        blipTime = 180000, -- 3 minutes on map for LEO
    },

    -- Minimum LEO online to start (0 = always allow, still alerts if any are on)
    RequirePolice = 0,

    Marker = {
        enabled = true,
        type = 1,
        size = vector3(5.2, 5.2, 0.55),
        color = { r = 196, g = 30, b = 45, a = 150 },
        zOffset = -0.95,
        carIcon = true,
        carIconZ = 1.15,
        carIconSize = 1.15,
        text = "Illegal Chop — Park vehicle",
        textZ = 1.55,
    },

    Blip = {
        enabled = true,
        sprite = 380,
        color = 1,
        scale = 0.75,
        label = "Illegal Chop Yard",
    },

    Locations = {
        {
            id = "lapuerta",
            label = "La Puerta Illegal Chop",
            coords = vector3(-425.2028, -1687.5762, 19.0291),
            heading = 156.9552,
        },
    },

    AllowedClasses = {
        [0] = true,  -- Compacts
        [1] = true,  -- Sedans
        [2] = true,  -- SUVs
        [3] = true,  -- Coupes
        [4] = true,  -- Muscle
        [5] = true,  -- Sports Classics
        [6] = true,  -- Sports
        [7] = true,  -- Super
        [8] = true,  -- Motorcycles
        [9] = true,  -- Off-road
        [11] = true, -- Utility
        [12] = true, -- Vans
    },

    BlockedPlates = {
        PREVIEW = true,
        TESTDRIVE = true,
        TEST = true,
        ADMINTST = true,
        ADMIN = true,
    },

    BlockJobVehicles = true,

    -- Dirty-money payout scales with the chopped vehicle (dealership / vehicles price).
    -- Super cars (~250k list) hit the 500k cap; cheaper cars pay less.
    MoneyReward = {
        item = "black_money",
        pricePercent = 200, -- % of list price
        min = 25000,
        max = 500000,
        -- Used when the model has no listed price
        amount = 75000,
        classAmounts = {
            [0] = 40000,   -- Compacts
            [1] = 60000,   -- Sedans
            [2] = 80000,   -- SUVs
            [3] = 120000,  -- Coupes
            [4] = 100000,  -- Muscle
            [5] = 200000,  -- Sports Classics
            [6] = 180000,  -- Sports
            [7] = 500000,  -- Super
            [8] = 35000,   -- Motorcycles
            [9] = 70000,   -- Off-road
            [11] = 50000,  -- Utility
            [12] = 55000,  -- Vans
        },
    },

    -- Optional scrap leftovers (on top of dirty cash)
    Rewards = {
        { item = "scrapmetal", min = 4, max = 10, chance = 70 },
        { item = "door", min = 1, max = 1, chance = 35 },
        { item = "tire", min = 1, max = 2, chance = 40 },
        { item = "engine", min = 1, max = 1, chance = 25 },
        { item = "window", min = 1, max = 2, chance = 30 },
    },
}
