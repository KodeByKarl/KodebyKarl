-- sheriff store (Paleto / Sandy / Blaine): senora_fwy
Config.Heist = Config.Heist or {}

Config.Heist['senora_fwy'] = {
        label = '24/7 (Mount Chiliad, Senora Fwy)',
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
            coords = vec3(1728.8990478516, 6417.3032226562, 35.036998748779),
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
