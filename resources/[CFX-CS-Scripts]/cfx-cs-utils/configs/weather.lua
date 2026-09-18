return {
    Enabled = true,

    -- Clear / extra sunny weather (visual only)
    Weather = 'EXTRASUNNY',

    -- false = normal day & night cycle (clock moves, HUD updates)
    -- true  = lock clock to Hour:Minute below
    FreezeTime = false,
    Hour = 12,
    Minute = 0,

    -- Re-apply weather only (ms)
    RefreshInterval = 15000,
}
