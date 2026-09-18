ConfigWelcomeBanner = {
    Debug = false,
    Command = "wcb",
    VolumeCommand = "wcbv", -- all players: local listen volume for join banners
    DefaultListenerVolume = 1.0, -- 0.0 mute · 1.0 original banner volume
    Duration = 8, -- seconds
    Delay = 5000, -- ms after spawn before the join banner shows
    Offset = {
        bottom = 64,
        right = 24,
    },

    -- Only these ESX groups can open .wcb
    AllowedGroups = {
        owner = true,
        developer = true,
    },

    -- Image display limits. gif / png / jpg / jpeg / webp are all allowed.
    Image = {
        Formats = { "gif", "png", "jpg", "jpeg", "webp" },
        Width = 350,
        Height = 200,
        MaxWidth = 480,
        MaxHeight = 270,
        MaxFileSizeKB = 1200,
    },
}
