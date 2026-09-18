-- sheriff store (Paleto / Sandy / Blaine): panorama_dr_gsd
Config.Heist = Config.Heist or {}

Config.Heist['panorama_dr_gsd'] = {
        label = 'Robs Liquor (Panorama Dr, Grand Senora Desert)',
        require = {
            ['sheriff'] = 2
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
            coords = vec3(1982.376953125, 3053.4140625, 47.215000152588),
            distance = 10
        },
        settings = {
            autoTemplate = false,
            autoPriority = false,
            autoBlip = true,
            autoAnnounce = true,
        },
        dispatch = {
            enable = true,
            jobs = {'sheriff', 'ambulance', 'pambulance'}
        },
    }
