return {
    coords = vec3(1978.3276, 3819.7681, 33.5359),
    distance = { marker = 5, interact = 0.5 },

    -- Conversion rates (output = input * rate)
    rates = {
        dm_to_money = 0.8,  -- dirty → clean (20% cut)
        money_to_dm = 1.0,  -- clean → dirty (1:1)
    },

    -- Police tip after a successful exchange
    policeAlert = {
        enable = true,
        chance = 100, -- % chance to notify PD
        jobs = { 'police', 'sheriff' },
        title = '10-90 Money Laundering',
        message = 'Suspicious cash exchange reported. Flashing area marked on GPS.',
        blipSprite = 500,
        blipColour = 1,
        blipScale = 1.2,
        blipDuration = 90000, -- ms
        radius = 80.0,
    },
}
