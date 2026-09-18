return {
    Jobs = {
        ['police'] = vec4(58.6221, -385.7598, 42.3345, 249.0612),
        ['sheriff'] = vec4(1853.21, 3689.51, 34.27, 210.0),
        ['ambulance'] = vec4(-1038.44, -1356.31, 5.9474, 170.0),
        ['sambulance'] = vec4(1822.8940, 3627.2034, 34.5672, 39.4560),
        ['pambulance'] = vec4(-262.6513, 6330.7432, 32.4261, 48.4872),
    },
    Gangs = {},
    -- zone = 'city' | 'sandy' | 'blaine' — default pick is where they died; death UI lets them choose.
    Locations = {
        ['integrity_way'] = {
            label = 'Integrity Way',
            area = 'Los Santos',
            zone = 'city',
            cost = 15000,
            coords = vec4(-0.1553, -585.9371, 37.7451, 250.0412),
        },
        ['carson_ave'] = {
            label = 'Carson Ave',
            area = 'Los Santos',
            zone = 'city',
            cost = 15000,
            coords = vec4(-6.6761, -573.6871, 37.7451, 334.6148),
        },
        ['murrieta'] = {
            label = 'City Hospital',
            area = 'Los Santos',
            zone = 'city',
            cost = 15000,
            coords = vec4(-1038.44, -1356.31, 5.9474, 170.0),
        },
        ['police_station'] = {
            label = 'Police Department',
            area = 'Los Santos',
            zone = 'city',
            cost = 0,
            job = 'police',
            coords = vec4(58.6221, -385.7598, 42.3345, 249.0612),
        },
        ['sandy_hospital'] = {
            label = 'Sandy Hospital',
            area = 'Sandy Shores',
            zone = 'sandy',
            cost = 15000,
            coords = vec4(1822.8940, 3627.2034, 34.5672, 39.4560),
        },
        ['paleto_hospital'] = {
            label = 'Paleto Ambulance',
            area = 'Paleto Bay',
            zone = 'blaine',
            cost = 15000,
            coords = vec4(-262.6513, 6330.7432, 32.4261, 48.4872),
        },
        -- Fallback / STL
        ['morgue'] = {
            label = 'STL Spawn (Morgue)',
            area = 'Morgue',
            cost = 15000,
            coords = vec4(-1679.9622, -291.5636, 51.8834, 151.5166),
            hidden = true,
        },
    },
}
