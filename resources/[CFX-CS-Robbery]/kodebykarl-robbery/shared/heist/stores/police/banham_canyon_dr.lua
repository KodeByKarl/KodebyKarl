-- police store (Los Santos): banham_canyon_dr
Config.Heist = Config.Heist or {}

Config.Heist['banham_canyon_dr'] = {
        label = 'LTD Gasoline (Richman Glen, Banham Canyon Dr)',
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
            coords = vec3(-1820.2270507812, 794.28698730469, 138.0890045166),
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
