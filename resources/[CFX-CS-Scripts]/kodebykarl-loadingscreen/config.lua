Config = {}

Config.ServerName = 'Grim City'

--[[
  Artwork lives in web/src/assets (built into html/assets):
  - grim-city-logo.png
  - grim-loading-banner.png
  - music.mp3
]]

-- Hide default FiveM busy spinner: setr sv_showBusySpinnerOnLoadingScreen false (server.cfg)

Config.Music = {
    youtubeId = 'k5ri3jyGPNQ',
    title = 'Loading Theme',
    artist = 'Grim City',
}

-- Discord bot token: set kodebykarl_discord_bot_token in server.cfg (do not hardcode here)
-- Bot needs Server Members Intent enabled.
-- Staff sidebar lists everyone; role badge order prefers earlier entries if multi-role.
Config.Discord = {
    GuildId = '1240677650348118148',
    Roles = {
        { key = 'owner',           id = '1539591207674581082', label = 'Owner' },
        { key = 'developer',       id = '1542801586932420679', label = 'Developer' },
        { key = 'gods',            id = '1540359804298461254', label = 'Gods' },
        { key = 'city_management', id = '1530001184142786631', label = 'City Management' },
    },
    RefreshMinutes = 15,
}
