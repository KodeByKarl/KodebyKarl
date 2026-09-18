-- sheriff store (Paleto / Sandy / Blaine): grand_senora_fwy
Config.Heist = Config.Heist or {}

Config.Heist['grand_senora_fwy'] = {
        label = '24/7 (Grand Senora Desert, Senora Fwy)',
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
            coords = vec3(2675.9699707031, 3280.5759277344, 55.24100112915),
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
