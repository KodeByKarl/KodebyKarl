-- sheriff store (Paleto / Sandy / Blaine): pryite_ave_paleto
Config.Heist = Config.Heist or {}

Config.Heist['pryite_ave_paleto'] = {
        label = 'Robs Liquor (Pryite Ave, Paleto Bay)',
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
            coords = vec3(-161.00300598145, 6321.4047851562, 31.594999313354),
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
