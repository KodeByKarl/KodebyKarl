return {
    -- Off: Electron AC wants onesync_population false instead of a client no-NPC loop.
    -- https://docs.electron-services.com/advanced/tips-best-configuration
    Enabled = false,

    -- Ambient NPC pedestrians
    DisablePeds = true,

    -- Ambient / parked / random traffic
    DisableVehicles = true,

    -- Clear vehicle generators around the player
    ClearVehicleGenerators = true,
    GeneratorRadius = 500.0,

    -- Disable police/ambulance/etc dispatch services
    DisableDispatch = true,

    -- Keep wanted level cleared and cops from responding
    IgnoreWanted = true,
}
