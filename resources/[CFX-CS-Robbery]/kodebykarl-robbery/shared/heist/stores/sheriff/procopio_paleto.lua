-- sheriff store (Paleto / Sandy / Blaine): procopio_paleto
Config.Heist = Config.Heist or {}

Config.Heist['procopio_paleto'] = {
        label = 'Bayview Store (Procopio Promenade, Paleto Forest)',
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
            coords = vec3(-676.47198486328, 5840.169921875, 17.440000534058),
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
