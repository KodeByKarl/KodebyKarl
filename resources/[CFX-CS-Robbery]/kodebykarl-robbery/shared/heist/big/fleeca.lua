--[[
  Fleeca Bank Heists (Los Santos + Sandy)
  Trigger: 1x pendrive
  Require: 7 police online (Sandy = 7 sheriff)
  Rewards: $250,000 clean + $250,000 dirty
]]

Config.Heist = Config.Heist or {}

local FLEECA_REWARDS = {
    { item = 'money', min = 250000, max = 250000 },
    { item = 'black_money', min = 250000, max = 250000 },
}

local FLEECA_SETTINGS = {
    autoTemplate = true,
    autoPriority = true,
    autoBlip = true,
    autoAnnounce = false,
}

local function fleecaPed(model, coords)
    return {
        entity = 0,
        model = model or 'g_m_m_chicold_01',
        coords = coords,
    }
end

-- Legion Square (Downtown LS)
Config.Heist['fleeca_legion'] = {
    label = 'Fleeca Bank — Legion Square',
    require = {
        ['police'] = 7,
    },
    requireItem = {
        ['pendrive'] = 1,
    },
    reset = 7200,
    timer = 600,
    distanceToCancel = 15,
    rewards = FLEECA_REWARDS,
    ped = fleecaPed(nil, vec4(149.4113, -1042.0449, 29.3680, 342.9182)),
    settings = FLEECA_SETTINGS,
    dispatch = {
        enable = true,
        jobs = { 'police', 'ambulance' },
    },
}

-- Rockford Hills
Config.Heist['fleeca_rockford'] = {
    label = 'Fleeca Bank — Rockford Hills',
    require = {
        ['police'] = 7,
    },
    requireItem = {
        ['pendrive'] = 1,
    },
    reset = 7200,
    timer = 600,
    distanceToCancel = 15,
    rewards = FLEECA_REWARDS,
    ped = fleecaPed(nil, vec4(-1211.8585, -331.9854, 37.7809, 28.5983)),
    settings = FLEECA_SETTINGS,
    dispatch = {
        enable = true,
        jobs = { 'police', 'ambulance' },
    },
}

-- Great Ocean Highway (Chumash)
Config.Heist['fleeca_greatocean'] = {
    label = 'Fleeca Bank — Great Ocean Hwy',
    require = {
        ['police'] = 7,
    },
    requireItem = {
        ['pendrive'] = 1,
    },
    reset = 7200,
    timer = 600,
    distanceToCancel = 15,
    rewards = FLEECA_REWARDS,
    ped = fleecaPed(nil, vec4(-2961.0720, 483.1107, 15.6970, 88.1986)),
    settings = FLEECA_SETTINGS,
    dispatch = {
        enable = true,
        jobs = { 'police', 'ambulance' },
    },
}

-- Pillbox Hill / Alta
Config.Heist['fleeca_pillbox'] = {
    label = 'Fleeca Bank — Pillbox Hill',
    require = {
        ['police'] = 7,
    },
    requireItem = {
        ['pendrive'] = 1,
    },
    reset = 7200,
    timer = 600,
    distanceToCancel = 15,
    rewards = FLEECA_REWARDS,
    ped = fleecaPed(nil, vec4(313.8176, -280.5338, 54.1647, 339.1609)),
    settings = FLEECA_SETTINGS,
    dispatch = {
        enable = true,
        jobs = { 'police', 'ambulance' },
    },
}

-- Burton / Hawick
Config.Heist['fleeca_burton'] = {
    label = 'Fleeca Bank — Burton',
    require = {
        ['police'] = 7,
    },
    requireItem = {
        ['pendrive'] = 1,
    },
    reset = 7200,
    timer = 600,
    distanceToCancel = 15,
    rewards = FLEECA_REWARDS,
    ped = fleecaPed(nil, vec4(-351.3247, -51.3466, 49.0365, 339.3305)),
    settings = FLEECA_SETTINGS,
    dispatch = {
        enable = true,
        jobs = { 'police', 'ambulance' },
    },
}

-- Sandy Shores Fleeca (sheriff territory)
Config.Heist['fleeca_sandy'] = {
    label = 'Fleeca Bank — Sandy Shores',
    require = {
        ['sheriff'] = 7,
    },
    requireItem = {
        ['pendrive'] = 1,
    },
    reset = 7200,
    timer = 600,
    distanceToCancel = 15,
    rewards = FLEECA_REWARDS,
    ped = fleecaPed(nil, vec4(1174.9718, 2708.2034, 38.0879, 178.2974)),
    settings = FLEECA_SETTINGS,
    dispatch = {
        enable = true,
        jobs = { 'sheriff', 'ambulance' },
    },
}
