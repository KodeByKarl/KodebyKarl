-- sheriff store (Paleto / Sandy / Blaine): palomino_fwy
Config.Heist = Config.Heist or {}

Config.Heist['palomino_fwy'] = {
        label = '24/7 (Tataviam Mountains, Palomino Fwy)',
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
            coords = vec3(2554.8439941406, 380.92700195312, 108.62200164795),
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
