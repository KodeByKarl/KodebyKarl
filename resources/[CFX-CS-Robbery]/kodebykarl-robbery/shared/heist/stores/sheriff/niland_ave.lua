-- sheriff store (Paleto / Sandy / Blaine): niland_ave
Config.Heist = Config.Heist or {}

Config.Heist['niland_ave'] = {
        label = '24/7 (Sandy Shores, Niland Avenue)',
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
            coords = vec3(1958.9260253906, 3742.0869140625, 32.342998504639),
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
