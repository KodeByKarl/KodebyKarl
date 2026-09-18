-- police store (Los Santos): palomino_ave
Config.Heist = Config.Heist or {}

Config.Heist['palomino_ave'] = {
        label = 'LTD Gasoline (Little Seoul, Palomino Avenue)',
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
            coords = vec3(-706.15899658203, -913.54901123047, 19.215000152588),
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
