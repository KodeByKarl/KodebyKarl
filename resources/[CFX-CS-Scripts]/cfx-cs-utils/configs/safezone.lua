return {
    Zones = {
        {
            name = 'hospital_safezone',
            label = 'City Hospital Safezone',
            debug = false,
            thickness = 80.0,
            points = {
                vec3(-1085.0, -1330.0, 6.0),
                vec3(-1005.0, -1330.0, 6.0),
                vec3(-1005.0, -1440.0, 5.4),
                vec3(-1085.0, -1440.0, 5.4),
            },
            -- Everyone: no weapons. Police: stun gun only.
            restrictWeapons = true,
            policeJobs = { 'police', 'sheriff' },
            policeAllowedWeapons = {
                `WEAPON_STUNGUN`,
                `WEAPON_STUNGUN_MP`,
            },
        },
        {
            name = 'sandy_hospital_safezone',
            label = 'Sandy Hospital Safezone',
            debug = false,
            thickness = 50.0,
            points = {
                vec3(1798.0, 3598.0, 34.0),
                vec3(1860.0, 3598.0, 34.0),
                vec3(1860.0, 3658.0, 34.0),
                vec3(1798.0, 3658.0, 34.0),
            },
            restrictWeapons = true,
            policeJobs = { 'police', 'sheriff' },
            policeAllowedWeapons = {
                `WEAPON_STUNGUN`,
                `WEAPON_STUNGUN_MP`,
            },
        },
        {
            name = 'paleto_hospital_safezone',
            label = 'Paleto Hospital Safezone',
            debug = false,
            thickness = 50.0,
            points = {
                vec3(-285.0, 6298.0, 32.0),
                vec3(-228.0, 6298.0, 32.0),
                vec3(-228.0, 6340.0, 32.0),
                vec3(-285.0, 6340.0, 32.0),
            },
            restrictWeapons = true,
            policeJobs = { 'police', 'sheriff' },
            policeAllowedWeapons = {
                `WEAPON_STUNGUN`,
                `WEAPON_STUNGUN_MP`,
            },
        },
        {
            name = 'mechanic_safezone',
            label = 'Mechanic Safezone',
            debug = false,
            thickness = 60.0,
            points = {
                vec3(-380.7108, -99.3672, 39.0560),
                vec3(-372.4598, -69.6116, 45.6595),
                vec3(-291.0760, -97.7739, 47.0032),
                vec3(-301.5728, -134.3909, 43.7095),
                vec3(-309.7080, -167.0191, 39.9751),
                vec3(-350.2759, -180.0781, 38.1522),
                vec3(-364.4107, -156.0221, 38.2316),
            },
            -- Everyone: no weapons. Police: stun gun only.
            restrictWeapons = true,
            policeJobs = { 'police' },
            policeAllowedWeapons = {
                `WEAPON_STUNGUN`,
                `WEAPON_STUNGUN_MP`,
            },
        },
        -- Region-switch hubs (same map on every bucket). Keep these small so
        -- players cannot hop regions mid-fight / mid-robbery.
        {
            name = 'school_spawn_safezone',
            label = 'Legion Square Safezone',
            debug = false,
            thickness = 50.0,
            points = {
                vec3(195.0, -890.0, 30.0),
                vec3(250.0, -890.0, 30.0),
                vec3(250.0, -840.0, 30.0),
                vec3(195.0, -840.0, 30.0),
            },
            restrictWeapons = true,
            policeJobs = { 'police', 'sheriff' },
            policeAllowedWeapons = { `WEAPON_STUNGUN`, `WEAPON_STUNGUN_MP` },
        },
        {
            name = 'farm_spawn_safezone',
            label = 'Grapeseed Farm Safezone',
            debug = false,
            thickness = 50.0,
            points = {
                vec3(1980.0, 4880.0, 42.0),
                vec3(2030.0, 4880.0, 42.0),
                vec3(2030.0, 4925.0, 42.0),
                vec3(1980.0, 4925.0, 42.0),
            },
            restrictWeapons = true,
            policeJobs = { 'police', 'sheriff' },
            policeAllowedWeapons = { `WEAPON_STUNGUN`, `WEAPON_STUNGUN_MP` },
        },
        {
            name = 'orange_job_safezone',
            label = 'Orange Orchard Safezone',
            debug = false,
            thickness = 40.0,
            points = {
                vec3(260.0, 6510.0, 30.0),
                vec3(305.0, 6510.0, 30.0),
                vec3(305.0, 6550.0, 30.0),
                vec3(260.0, 6550.0, 30.0),
            },
            restrictWeapons = true,
            policeJobs = { 'police', 'sheriff' },
            policeAllowedWeapons = { `WEAPON_STUNGUN`, `WEAPON_STUNGUN_MP` },
        },
    },
}

