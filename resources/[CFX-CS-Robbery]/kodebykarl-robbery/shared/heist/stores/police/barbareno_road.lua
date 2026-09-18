-- police store (Los Santos): barbareno_road
Config.Heist = Config.Heist or {}

Config.Heist['barbareno_road'] = {
        label = '24/7 (Chumash, Barbareno Road)',
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
            coords = vec3(-3244.5749511719, 1000.1920166016, 12.829999923706),
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
