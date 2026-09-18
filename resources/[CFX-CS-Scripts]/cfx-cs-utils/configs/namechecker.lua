--[[
    NameChecker — require FiveM display name to match Discord nickname/username.
    See modules/namechecker/README.md for bot setup.
]]
return {
    Enabled = true,

    -- Discord bot (enable Server Members Intent). Prefer convar kodebykarl_discord_bot_token.
    BotToken = '',
    GuildID = '1240677650348118148',

    -- Comparison
    CaseInsensitive = true,
    TrimSpaces = true,
    FallbackToUsername = true,
    RequireGuildMembership = true,

    DiscordInvite = 'https://discord.gg/your-invite',

    Messages = {
        Checking = 'Checking Discord name…',
        NoDiscord = 'You must link Discord to FiveM (Settings → Linked Accounts) before joining.\nJoin our Discord: %s',
        NotInGuild = 'You must join our Discord server before connecting.\nInvite: %s',
        ApiError = 'Could not verify your Discord membership right now. Please try again in a moment.',
        Mismatch = 'Your FiveM name does not match your Discord name.\n\nSet your FiveM name to: %s\n(FiveM → Settings → Display Name)\n\nThen reconnect.',
        Accepted = 'Name check passed. Welcome!',
        NotConfigured = 'NameChecker is not configured. Contact staff.',
    },
}
