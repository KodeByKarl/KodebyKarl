-- sheriff store (Paleto / Sandy / Blaine): grapeseed_mainst
Config.Heist = Config.Heist or {}

Config.Heist['grapeseed_mainst'] = {
        label = '24/7 (Grapeseed, Grapeseed Main Street)',
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
            coords = vec3(1698.0620117188, 4922.9599609375, 42.062999725342),
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
