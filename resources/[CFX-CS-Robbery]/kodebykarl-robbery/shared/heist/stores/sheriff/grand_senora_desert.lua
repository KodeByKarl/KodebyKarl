-- sheriff store (Paleto / Sandy / Blaine): grand_senora_desert
Config.Heist = Config.Heist or {}

Config.Heist['grand_senora_desert'] = {
        label = 'Robs Liquor (Grand Senora Desert, Route 68)',
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
            coords = vec3(1166.0, 2710.7729492188, 38.157001495361),
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
