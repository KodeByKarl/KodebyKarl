return {
    enable = true,

    command = 'illegal_menu',
    keyMapping = 'F6',
    keyMappingLabel = 'Illegal Menu',

    -- On-duty jobs that should use their own F6 menu instead of Illegal Menu
    blockedJobs = {
        police = true,
        sheriff = true,
        ambulance = true,
        sambulance = true,
        pambulance = true,
    },

    distance = 3.0,
    cuffDistance = 2.0,

    items = {
        cuff = 'handcuff',
        uncuff = 'handcuff_keys',
        drag = 'rope',
    },

    progress = {
        cuff = 3760,
        uncuff = 5500,
        search = 5000,
        clothes = 5000,
    },

    requireCuffedToSearch = true,
    requireCuffedToStrip = true,
    requireCuffedToDrag = true,
}
