-- big heist: bigbank
Config.Heist = Config.Heist or {}

Config.Heist['bigbank'] = {
        label = 'Pacific Standard',
        require = {
            ['police'] = 0 --12
        },
        requireItem = {
            ['laptop_h'] = 1,
            ['drill'] = 1,
            ['thermite'] = 1,
            ['lockpick'] = 1,
        },
        reset = 500,
        timer = 1000,
        distanceToCancel = 10,
        rewards = {
            {item = 'WEAPON_CERAMICPISTOL', min = 2, max = 2},
            {item = 'WEAPON_PISTOL', min = 5, max = 5},
            {item = 'at_clip_extended_pistol', min = 3, max = 3},
            {item = 'at_suppressor_light', min = 2, max = 2},
            {item = 'ammo-box1', min = 5, max = 5},
            {item = 'black_money', min = 150000, max = 150000},
        },
        ped = {
            entity = 0,
            model = 'g_m_m_chicold_01',
            coords = vec4(252.913, 227.470, 101.683, 252.178)
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
