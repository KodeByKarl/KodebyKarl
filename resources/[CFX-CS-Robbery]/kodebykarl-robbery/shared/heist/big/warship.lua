-- big heist: warship
Config.Heist = Config.Heist or {}

Config.Heist['warship'] = {
        label = 'USS Ranger',
        require = {
            ['police'] = 0 --12
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
            {item = 'WEAPON_PISTOL50', min = 3, max = 3},
            {item = 'WEAPON_CERAMICPISTOL', min = 3, max = 3},
            {item = 'WEAPON_PISTOL', min = 5, max = 5},
            {item = 'at_clip_extended_pistol', min = 3, max = 3},
            {item = 'at_suppressor_light', min = 2, max = 2},
            {item = 'ammo-box1', min = 5, max = 5},
            {item = 'ammo-box4', min = 2, max = 2},
            {item = 'black_money', min = 200000, max = 200000},
        },
        ped = {
            entity = 0,
            model = 'g_m_m_chicold_01',
            coords = vec4(3082.947, -4686.693, 27.252, 207.313)
        },
        settings = {
            autoTemplate = true,
            autoPriority = true,
            autoBlip = true,
            autoAnnounce = false,
        },
        dispatch = {
            enable = false, --true,
            jobs = {'police'}
        },
    }
