Config = {}

-- General Settings
Config.RotationMinutes = 15        -- Active TrapHouse rotates every 15 minutes (1 at a time)
Config.AntiFarmCooldown = 180      -- Cooldown in seconds before same killer can get loot from same victim
Config.DeleteVehiclesInZone = true  -- Auto-remove vehicles left unoccupied inside TrapHouse zones
Config.WebhookURL = ''             -- Discord Webhook URL for logs (optional)

-- TrapHouse / RedZone Locations
Config.TrapZones = {
    {
        id = 'mirror_park',
        label = 'Mirror Park TrapHouse',
        coords = vec3(1204.89, -557.81, 69.62),
        radius = 200.0,
        blip = { enable = true, color = 1, alpha = 110 }
    },
    {
        id = 'golf_course',
        label = 'Golf Course (GWC) TrapHouse',
        coords = vec3(-1116.84, 304.53, 66.52),
        radius = 250.0,
        blip = { enable = true, color = 1, alpha = 110 }
    },
    {
        id = 'playa_hotel',
        label = 'Playa Hotel TrapHouse',
        coords = vec3(-1868.55, -364.87, 49.46),
        radius = 200.0,
        blip = { enable = true, color = 1, alpha = 110 }
    },
    {
        id = 'elysian_docks',
        label = 'Elysian Docks TrapHouse',
        coords = vec3(-48.65, -2508.78, 7.40),
        radius = 200.0,
        blip = { enable = true, color = 1, alpha = 110 }
    }
}

-- Kill reward: Traphouse Coins only (granted 100% server-side)
Config.CoinReward = {
    item = 'traphouse_coin',
    label = 'Traphouse Coin',
    min = 1,
    max = 1,
}
