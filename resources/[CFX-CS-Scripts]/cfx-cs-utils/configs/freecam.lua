return {
    -- Disabled: freecam is death-only via kodebykarl-ambulance [G] while downed.
    -- Do not re-enable — /freecam must stay off for everyone (staff/streamer included).
    Enabled = false,
    Command = 'freecam',
    -- ESX staff groups allowed to use /freecam (unused while Enabled = false)
    Groups = { 'admin', 'gangmod', 'superadmin', 'mod', 'developer', 'owner' },

    -- Streamer / Content Creator Discord Role Access (Auto-synced live from Discord)
    DiscordRoles = {
        Enabled = true,
        BotToken = 'MTUzNTMwMzIxMTA2ODY5NDUyOQ.GGvn6j.OBVZ2DlCdGNS4R1IzAwF9URZbnL-0R_WJGSsWk',
        GuildID = '1526937565926654065',
        -- Allowed Discord Streamer Role IDs
        Roles = {
            '1526937566002286722', -- PANDORA CITY STREAMERS
        },
    },

    -- Keep player body visible and rendered while in freecam
    KeepPlayerVisible = true,

    -- Notification message when player has no access
    NoPermissionMessage = 'Wala kang Streamer Discord role (PANDORA CITY STREAMERS) para mag-freecam.',
}