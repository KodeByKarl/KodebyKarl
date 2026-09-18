-- police store (Los Santos): prosperity_st
Config.Heist = Config.Heist or {}

Config.Heist['prosperity_st'] = {
        label = 'Robs Liquor (Morningwood, Prosperity St)',
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
            coords = vec3(-1486.2469482422, -378.04998779297, 40.162998199463),
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
