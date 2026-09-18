-- police store (Los Santos): san_andreas_ave
Config.Heist = Config.Heist or {}

Config.Heist['san_andreas_ave'] = {
        label = 'Robs Liquor (Vespucci Canais, San Andreas Avenue)',
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
            coords = vec3(-1222.0140380859, -908.29901123047, 12.326000213623),
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
