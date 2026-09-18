-- police store (Los Santos): clinton_ave
Config.Heist = Config.Heist or {}

Config.Heist['clinton_ave'] = {
        label = '24/7 (Downtown Vinewood, Clinton Avenue)',
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
            coords = vec3(373.15301513672, 328.67098999023, 103.56600189209),
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
