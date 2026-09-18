-- big heist: lifeinvader
Config.Heist = Config.Heist or {}

Config.Heist['lifeinvader'] = {
        label = 'Life Invader',
        require = {
            ['police'] = 0 --8
        },
        requireItem = {
            ['hacking_device'] = 1,
            ['laptop'] = 1,
            ['pendrive'] = 1,
            ['lockpick'] = 1,
        },
        reset = 500,
        timer = 800,
        distanceToCancel = 10,
        rewards = {
            {item = 'WEAPON_PISTOL', min = 5, max = 5},
            {item = 'at_clip_extended_pistol', min = 3, max = 3},
            {item = 'at_suppressor_light', min = 2, max = 2},
            {item = 'ammo-box1', min = 5, max = 5},
            {item = 'black_money', min = 50000, max = 50000},
        },
        ped = {
            entity = 0,
            model = 'g_m_m_chicold_01',
            coords = vec4(-1051.417, -231.928, 44.020, 118.716)
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
