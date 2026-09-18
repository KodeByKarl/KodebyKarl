-- police store (Los Santos): west_mirror_drive
Config.Heist = Config.Heist or {}

Config.Heist['west_mirror_drive'] = {
        label = 'LTD Gasoline (Mirror Park, West Mirror Drive)',
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
            coords = vec3(1164.6459960938, -322.67001342773, 69.205001831055),
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
