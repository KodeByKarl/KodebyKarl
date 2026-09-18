return {
    Enabled = true,
    RefreshInterval = 2000, -- Milliseconds between blip location/status updates
    BlipScale = 0.8,
    ShowHeading = true,     -- Show rotation/heading arrow indicator on blip
    ShowOwnBlip = false,    -- Show duplicate blip for own player (false recommended as minimap already shows player)
    ShareAll = false,       -- False: PD only sees PD, EMS only sees EMS (separated department GPS)

    -- Vehicle specific sprites
    VehicleSprites = {
        car = 42,           -- When driving a car/ground vehicle
        air = 15,           -- When using an air vehicle (helicopter / plane)
    },

    -- Whitelisted Job Configurations
    -- Same group key = see each other when ShareAll = false.
    -- Optional jobColors / jobLabels override per job name.
    Jobs = {
        police = {
            label = 'Police',
            jobs = { 'police', 'sheriff' },
            sprite = 60,    -- Standard foot blip sprite
            color = 38,     -- Default / Police blue
            jobColors = {
                police = 38,  -- Blue
                sheriff = 17, -- Orange
            },
            jobLabels = {
                police = 'Police',
                sheriff = 'Sheriff',
            },
        },
        ambulance = {
            label = 'EMS',
            jobs = { 'ambulance', 'sambulance', 'pambulance' },
            sprite = 60,    -- Standard foot blip sprite
            color = 1,      -- Default / EMS red
            jobColors = {
                ambulance = 1,   -- Red
                sambulance = 1,  -- Red
                pambulance = 1,  -- Red
            },
        },
    },
}
