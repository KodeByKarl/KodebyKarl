ConfigSheriff = {}

ConfigSheriff.Job = 'sheriff'
ConfigSheriff.OffDutyJob = 'offsheriff'
ConfigSheriff.Label = "Sheriff's Office"
ConfigSheriff.ShortLabel = 'BCSO'

-- Sandy Shores Sheriff Station (Sandy Sheriff / Hospital MLO)
ConfigSheriff.Station = {
    Location = {
        coords = vector3(1886.3198, 3661.4883, 37.3998),
        heading = 294.5282,
    },
    Blip = {
        Coords = vector3(1886.3198, 3661.4883, 37.3998),
        Sprite = 60,
        Display = 4,
        Scale = 0.8,
        Colour = 5,
        Label = "Sheriff's Office",
        Category = 1,
        HighDetail = true,
    },
    Documents = {
        coords = vector3(1886.3198, 3661.4883, 37.3998),
        radius = 1.5,
        label = 'Open Documents',
        icon = 'fa-solid fa-file-lines',
    },
    Wardrobe = {
        coords = vector3(1881.2179, 3661.3215, 34.1129),
        heading = 291.0265,
        length = 1.2,
        width = 1.8,
        minZ = 33.1,
        maxZ = 35.5,
        label = 'Sheriff Wardrobe',
        icon = 'fa-solid fa-shirt',
    },
    Armoury = {
        coords = vector3(1891.7761, 3660.1177, 34.1130),
        heading = 178.0177,
        label = 'Sheriff Armoury',
    },
    Evidence = {
        coords = vector3(1888.1609, 3663.3677, 34.1130),
        heading = 28.5636,
        label = 'Sheriff Evidence',
    },
    PublicStash = {
        coords = vector3(1890.9138, 3663.4829, 34.1129),
        heading = 304.5840,
        label = 'Sheriff Shared Locker',
    },
    PersonalStash = {
        coords = vector3(1891.9514, 3661.7656, 34.1129),
        heading = 277.9326,
        label = 'Sheriff Personal Locker',
    },
    BossStash = {
        coords = vector3(1877.5516, 3659.5029, 37.3998),
        heading = 119.8286,
        label = 'Sheriff Boss Locker',
    },
    Helipad = {
        access = vector3(1883.4827, 3659.4534, 40.8335),
        heading = 297.0320,
        spawn = vector4(1893.0033, 3666.2625, 40.8335, 190.9078),
        label = 'Sheriff Helipad',
        garageId = 'Sheriff Helipad',
    },
    Garage = {
        access = vector3(1909.2863, 3662.5608, 33.5966),
        heading = 219.0533,
        spawn = vector4(1912.4501, 3663.4399, 33.5944, 204.4072),
        label = 'Sheriff Garage',
        garageId = 'Sheriff Garage',
    },
}

-- Minimum grade for /givescs (boss = 6)
ConfigSheriff.CallsignBossGradeName = 'boss'

-- Sheriff Coin Harvesting / Auto-Farm (same as PD) --
ConfigSheriff.CoinHarvest = {
    enabled = true,
    job = 'sheriff',
    locations = {
        vector4(1890.1949, 3662.1943, 37.3998, 332.5623),
        vector4(1887.0532, 3660.3557, 37.3998, 341.7905),
        vector4(1887.0150, 3665.8650, 37.3998, 331.6042),
        vector4(1883.6233, 3663.9050, 37.3998, 358.9586),
    },
    interactDistance = 1.5,
    drawDistance = 6.0,
    duration = 10000, -- 10 seconds progress bar
    reward = {
        item = 'sheriff_coin',
        min = 1,
        max = 10,
    },
    anim = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        clip = 'cop_b_idle',
        flag = 1,
    },
}
