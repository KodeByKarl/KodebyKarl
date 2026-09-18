-- police store (Los Santos): great_ocean_highway
Config.Heist = Config.Heist or {}

Config.Heist['great_ocean_highway'] = {
        label = 'Robs Liquor (Banham Canyon, Great Ocean Highway)',
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
            coords = vec3(-2966.458984375, 390.82501220703, 15.043000221252),
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
