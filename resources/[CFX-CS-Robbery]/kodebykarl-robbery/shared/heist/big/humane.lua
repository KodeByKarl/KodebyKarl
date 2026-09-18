-- big heist: humane
Config.Heist = Config.Heist or {}

Config.Heist['humane'] = {
        label = 'Humane Labs',
        require = {
            ['sheriff'] = 0 --12
        },
        requireItem = {
            ['hacking_device'] = 1,
            ['keycard'] = 1,
            ['thermite'] = 1,
            ['drill'] = 1,
        },
        reset = 300,
        timer = 1500,
        distanceToCancel = 10,
        rewards = {
            {item = 'WEAPON_CERAMICPISTOL', min = 2, max = 2},
            {item = 'WEAPON_PISTOL', min = 5, max = 5},
            {item = 'at_clip_extended_pistol', min = 3, max = 3},
            {item = 'at_suppressor_light', min = 2, max = 2},
            {item = 'ammo-box1', min = 5, max = 5},
            {item = 'black_money', min = 100000, max = 100000},
        },
        ped = {
            entity = 0,
            model = 'g_m_m_chicold_01',
            coords = vec4(3541.647, 3667.723, 28.121, 79.396)
        },
        settings = {
            autoTemplate = true,
            autoPriority = true,
            autoBlip = true,
            autoAnnounce = false,
        },
        dispatch = {
            enable = true,
            jobs = {'sheriff', 'ambulance', 'pambulance'}
        },
    }
