-- police store (Los Santos): el_rancho_blvd
Config.Heist = Config.Heist or {}

Config.Heist['el_rancho_blvd'] = {
        label = 'Robs Liquor (Murrieta Heights, El Rancho Blvd)',
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
            coords = vec3(1134.2449951172, -982.44500732422, 46.415000915527),
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
