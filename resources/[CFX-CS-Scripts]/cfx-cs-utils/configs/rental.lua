local Rental = {}

Rental.Vehicles = {
    land = {
        {
            model = 'cruiser',
            label = 'Cruiser Bicycle',
            price = 100,
            deposit = 50,
            icon = 'fa-solid fa-bicycle',
            description = 'Eco-friendly bicycle for fast and silent city navigation.'
        },
        {
            model = 'faggio',
            label = 'Pegassi Faggio',
            price = 250,
            deposit = 100,
            icon = 'fa-solid fa-motorcycle',
            description = 'Classic, light scooter. Perfect for weaving through heavy traffic.'
        },
        {
            model = 'blista',
            label = 'Dinka Blista',
            price = 500,
            deposit = 200,
            icon = 'fa-solid fa-car-side',
            description = 'Compact 2-door hatchback with great agility and fuel economy.'
        },
        {
            model = 'panto',
            label = 'Benefactor Panto',
            price = 500,
            deposit = 200,
            icon = 'fa-solid fa-car-side',
            description = 'Ultra-compact microcar that parks virtually anywhere.'
        },
        {
            model = 'primo',
            label = 'Albany Primo',
            price = 750,
            deposit = 250,
            icon = 'fa-solid fa-car',
            description = 'Comfortable 4-door sedan with plenty of legroom and trunk space.'
        },
        {
            model = 'seminole',
            label = 'Canis Seminole',
            price = 1200,
            deposit = 400,
            icon = 'fa-solid fa-truck-pickup',
            description = 'Rugged 4-door SUV offering high road clearance and reliability.'
        },
    },

    boat = {
        {
            model = 'seashark',
            label = 'Speedophile Seashark',
            price = 500,
            deposit = 200,
            icon = 'fa-solid fa-water',
            description = 'Fast and maneuverable 2-seat watercraft / jet ski.'
        },
        {
            model = 'dinghy',
            label = 'Nagasaki Dinghy',
            price = 1000,
            deposit = 400,
            icon = 'fa-solid fa-ship',
            description = 'Durable inflatable boat with high-powered outboard motor.'
        },
        {
            model = 'speeder',
            label = 'Pegassi Speeder',
            price = 2500,
            deposit = 1000,
            icon = 'fa-solid fa-sailboat',
            description = 'Sleek luxury speedboat capable of high speeds across open waters.'
        },
        {
            model = 'toro',
            label = 'Lampadati Toro',
            price = 3500,
            deposit = 1500,
            icon = 'fa-solid fa-ship',
            description = 'Classic twin-engine wooden runabout combining speed and prestige.'
        },
        {
            model = 'marquis',
            label = 'Dinka Marquis',
            price = 4500,
            deposit = 2000,
            icon = 'fa-solid fa-anchor',
            description = 'Spacious cruising yacht designed for leisurely open-sea trips.'
        },
    }
}

Rental.Locations = {
    ['airport'] = {
        label = 'Airport Vehicle Rental',
        category = 'land',
        pedCoords = vec4(-1038.838, -2730.971, 20.169, 237.722),
        spawnCoords = vec4(-1034.62, -2729.85, 20.04, 240.0),
    },
    ['rockford'] = {
        label = 'Rockford Hills Vehicle Rental',
        category = 'land',
        pedCoords = vec4(-1673.3219, -301.4520, 51.8120, 141.9751),
        spawnCoords = vec4(-1678.50, -310.20, 51.75, 140.0),
    },
    ['boat_lsia'] = {
        label = 'LSIA Marina Boat Rental',
        category = 'boat',
        pedCoords = vec4(113.543, -3341.364, 6.007, 356.812),
        spawnCoords = vec4(118.50, -3348.00, 0.0, 180.0),
    },
    ['boat_terminal'] = {
        label = 'Ocean Terminal Boat Rental',
        category = 'boat',
        pedCoords = vec4(-491.9571, -2928.2600, 6.0047, 49.3564),
        spawnCoords = vec4(-484.00, -2934.00, 0.0, 50.0),
    },
    ['boat_delperro'] = {
        label = 'Del Perro Pier Boat Rental',
        category = 'boat',
        pedCoords = vec4(-1796.238, -971.344, 2.174, 29.734),
        spawnCoords = vec4(-1794.50, -962.00, 0.0, 30.0),
    },
    ['boat_paleto'] = {
        label = 'Paleto Bay Boat Rental',
        category = 'boat',
        pedCoords = vec4(-269.385, 6645.973, 7.427, 130.537),
        spawnCoords = vec4(-277.00, 6652.00, 0.0, 130.0),
    },
}

return Rental
