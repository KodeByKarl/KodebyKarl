-- big heist: cluckin_bell
Config.Heist = Config.Heist or {}

Config.Heist['cluckin_bell'] = {
        label = 'Cluckin Bell',
        require = {
            ['police'] = 0 --4
        },
        reset = 3600,
        timer = 300,
        distanceToCancel = 10,
        rewards = {
            {item = 'black_money', min = 25000, max = 25000}
        },
        ped = {
            entity = 0,
            model = `g_m_m_chicold_01`,
            coords = vec4(-509.900, -700.400, 33.168, 92.05)
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
