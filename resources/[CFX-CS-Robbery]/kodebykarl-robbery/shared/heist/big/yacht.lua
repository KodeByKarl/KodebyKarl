-- big heist: yacht
Config.Heist = Config.Heist or {}

Config.Heist['yacht'] = {
        label = 'Yacht',
        require = {
            ['police'] = 0 --10
        },
        -- Boat is required to reach the yacht (vehicle), not consumed as an item.
        requireItem = {
            ['hacking_device'] = 1,
            ['lockpick'] = 1,
            ['drill'] = 1,
        },
        reset = 300,
        timer = 1500,
        distanceToCancel = 10,
        rewards = {
            {item = 'WEAPON_CERAMICPISTOL', min = 3, max = 3},
            {item = 'WEAPON_PISTOL', min = 5, max = 5},
            {item = 'at_clip_extended_pistol', min = 2, max = 2},
            {item = 'at_suppressor_light', min = 2, max = 2},
            {item = 'ammo-box1', min = 5, max = 5},
            {item = 'black_money', min = 120000, max = 120000},
        },
        ped = {
            entity = 0,
            model = 'g_m_m_chicold_01',
            coords = vec4(-2085.762, -1017.880, 12.781, 252.985)
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
