-- big heist: jewel
Config.Heist = Config.Heist or {}

Config.Heist['jewel'] = {
        label = 'Vangelico Jewelry',
        require = {
            ['police'] = 0 --6
        },
        requireItem = {
            ['glass_cutter'] = 1,
            ['lockpick'] = 1,
            ['lootbag'] = 1,
        },
        reset = 500,
        timer = 500,
        distanceToCancel = 3,
        rewards = {
            {item = 'black_money', min = 20000, max = 20000}
        },
        ped = {
            entity = 0,
            model = 'g_m_m_chicold_01',
            coords = vec4(-632.155, -230.279, 38.057, 307.703)
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
