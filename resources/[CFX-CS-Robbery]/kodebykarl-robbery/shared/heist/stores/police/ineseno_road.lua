-- police store (Los Santos): ineseno_road
Config.Heist = Config.Heist or {}

Config.Heist['ineseno_road'] = {
        label = '24/7 (Banham Canyon, Ineseno Road)',
        require = {
            ['police'] = 2
        },
        requireItem = {
            ['lockpick'] = 1
        },
        reset = 1800,
        timer = 200,
        distanceToCancel = 10,
        rewards = {
            {item = 'black_money', min = 5000, max = 10000}
        },
        marker = {
            coords = vec3(-3041.218, 583.836, 7.908),
            distance = 10
        },
        settings = {
            autoTemplate = false,
            autoPriority = false,
            autoBlip = true,
            autoAnnounce = true,
        },
        dispatch = {
            enable = false, --true,
            jobs = {'police', 'ambulance'}
        },
    }
