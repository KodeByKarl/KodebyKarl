Config = {}

Config.Debug = false
Config.HireDistance = 5.0
Config.MaxTransfer = 1000000

-- Gang keys MUST match es_extended/shared/config/gang.lua (HUD + /setgang).
-- This file is stash / wardrobe / crafting / iPad Organization only.
-- Bosses of gangs listed here automatically get the iPad Organization app.
Config.Gangs = {
    ['grimgang'] = {
        name = 'grimgang',
        label = 'GrimGang',
        bossGrade = 3, -- Boss
        -- discordRoleId = '', -- set Discord role ID when ready
        rgbColor = { r = 180, g = 40, b = 40 },
        primaryColor = 1,
        secondaryColor = 1,
        stashes = {
            public = {
                coords = nil, -- set vec4(x, y, z, w) later
                label = 'GrimGang Public Stash',
                id = 'grimgang_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = nil,
                label = 'GrimGang Private Stash',
                id = 'grimgang_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = nil,
                label = 'GrimGang Boss Stash',
                id = 'grimgang_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6, -- shared: bosses only (grade >= bossGrade)
            },
        },
        -- Boss management is via iPad Organization app (no world bossMenu marker)
        wardrobe = {
            coords = nil,
        },
        vehicle = {
            coords = nil,
            model = 'sultan', -- change when location is set
        },
        -- Bench location only — recipes are shared in shared/crafting.lua
        crafting = {
            coords = nil, -- set vec4(x, y, z, w) later
        },
    },
    ['alaskador'] = {
        name = 'alaskador',
        label = 'Alaskador',
        bossGrade = 3, -- Boss
        discordRoleId = '1546543652715892768',
        rgbColor = { r = 90, g = 160, b = 210 },
        primaryColor = 3,
        secondaryColor = 3,
        stashes = {
            public = {
                coords = vec4(-596.8138, -1620.2552, 33.0106, 171.4172),
                label = 'Alaskador Public Stash',
                id = 'alaskador_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = vec4(-596.8138, -1620.2552, 33.0106, 171.4172),
                label = 'Alaskador Personal Stash',
                id = 'alaskador_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = vec4(-590.2385, -1621.2118, 33.0106, 173.5273),
                label = 'Alaskador Boss Stash',
                id = 'alaskador_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6, -- shared: bosses only (grade >= bossGrade)
            },
        },
        -- Boss roster / hire / fire is iPad Organization app (no world bossMenu marker)
        bossMenu = {
            coords = vec4(-590.2385, -1621.2118, 33.0106, 173.5273),
        },
        wardrobe = {
            coords = vec4(-592.9677, -1620.5961, 33.0106, 164.1026),
        },
        vehicle = {
            coords = nil,
            model = 'sultan',
        },
        crafting = {
            coords = vec4(-588.6056, -1618.0392, 33.0106, 269.4613),
        },
    },
    ['westside'] = {
        name = 'westside',
        label = 'Westside',
        bossGrade = 3, -- Boss
        discordRoleId = '1544358128710197339',
        rgbColor = { r = 140, g = 50, b = 160 },
        primaryColor = 27,
        secondaryColor = 27,
        stashes = {
            public = {
                coords = vec4(-1516.8973, 851.5078, 181.5947, 155.2512),
                label = 'Westside Public Stash',
                id = 'westside_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = vec4(-1516.8973, 851.5078, 181.5947, 155.2512),
                label = 'Westside Personal Stash',
                id = 'westside_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = nil,
                label = 'Westside Boss Stash',
                id = 'westside_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6,
            },
        },
        wardrobe = {
            coords = vec4(-1520.4701, 848.9008, 181.5946, 204.5862),
        },
        vehicle = {
            coords = nil,
            model = 'sultan',
        },
        garage = {
            coords = vec4(-1526.2898, 887.9648, 181.7952, 225.0311),
            spawn = vec4(-1519.6462, 880.3286, 181.7831, 294.3454),
        },
        crafting = {
            coords = vec4(-1530.0438, 836.9496, 181.5946, 291.2300),
        },
    },
    ['mellysyndicate'] = {
        name = 'mellysyndicate',
        label = 'Melly Syndicate',
        bossGrade = 3, -- Boss
        -- discordRoleId = '', -- set Discord role ID when ready
        rgbColor = { r = 255, g = 105, b = 180 },
        primaryColor = 135,
        secondaryColor = 135,
        stashes = {
            public = {
                coords = vec4(-571.6339, 289.0424, 79.1767, 255.1467),
                label = 'Melly Syndicate Public Stash',
                id = 'mellysyndicate_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = vec4(-571.6339, 289.0424, 79.1767, 255.1467),
                label = 'Melly Syndicate Personal Stash',
                id = 'mellysyndicate_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = nil,
                label = 'Melly Syndicate Boss Stash',
                id = 'mellysyndicate_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6,
            },
        },
        wardrobe = {
            coords = vec4(-558.2457, 277.6960, 82.1763, 176.6633),
        },
        vehicle = {
            coords = nil,
            model = 'sultan',
        },
        -- Docs mirror for JG public garage "Melly Syndicate" (actual zone is in jg-advancedgarages)
        garage = {
            coords = vec4(-553.5296, 272.4998, 82.9913, 230.2834),
            spawn = vec4(-556.9075, 267.4720, 82.8945, 90.3719),
        },
        crafting = {
            coords = vec4(-552.1136, 278.1699, 82.1763, 259.9539),
        },
    },
    ['npa'] = {
        name = 'npa',
        label = 'NPA',
        bossGrade = 3, -- Boss
        -- discordRoleId = '', -- set Discord role ID when ready
        rgbColor = { r = 128, g = 128, b = 128 },
        primaryColor = 4, -- grey
        secondaryColor = 4,
        stashes = {
            public = {
                coords = vec4(-1188.3608, -249.9745, 37.9458, 217.5290),
                label = 'NPA Public Stash',
                id = 'npa_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = vec4(-1188.3608, -249.9745, 37.9458, 217.5290),
                label = 'NPA Personal Stash',
                id = 'npa_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = nil,
                label = 'NPA Boss Stash',
                id = 'npa_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6,
            },
        },
        wardrobe = {
            coords = vec4(-1194.8385, -250.9622, 37.9460, 180.7632),
        },
        vehicle = {
            coords = nil,
            model = 'sultan',
        },
        -- Docs mirror for JG public garage "NPA" (actual zone is in jg-advancedgarages)
        garage = {
            coords = vec4(-1153.7690, -222.9737, 37.9230, 198.3302),
            spawn = vec4(-1146.4014, -215.4896, 37.9553, 184.2798),
        },
        crafting = {
            coords = vec4(-1182.5024, -244.1896, 37.9458, 219.9110),
        },
    },
    ['tdc'] = {
        name = 'tdc',
        label = 'Tropa de Calle',
        bossGrade = 3, -- Boss
        -- discordRoleId = '', -- set Discord role ID when ready
        rgbColor = { r = 25, g = 80, b = 210 },
        primaryColor = 3, -- blue
        secondaryColor = 3,
        stashes = {
            public = {
                coords = vec4(972.4453, -97.8487, 74.8696, 46.5527),
                label = 'Tropa de Calle Public Stash',
                id = 'tdc_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = vec4(972.4453, -97.8487, 74.8696, 46.5527),
                label = 'Tropa de Calle Personal Stash',
                id = 'tdc_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = nil,
                label = 'Tropa de Calle Boss Stash',
                id = 'tdc_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6,
            },
        },
        wardrobe = {
            coords = vec4(981.9597, -98.3096, 74.9743, 54.6362),
        },
        vehicle = {
            coords = nil,
            model = 'sultan',
        },
        -- Docs mirror for JG public garage "Tropa de Calle" (actual zone is in jg-advancedgarages)
        garage = {
            coords = vec4(969.3305, -118.2687, 74.3531, 221.2984),
            spawn = vec4(967.7197, -126.2153, 74.3584, 144.2916),
        },
        crafting = {
            coords = vec4(983.8632, -90.7798, 74.8487, 228.4446),
        },
    },
    ['tbs'] = {
        name = 'tbs',
        label = 'The Boneless',
        bossGrade = 3, -- Boss
        -- discordRoleId = '', -- set Discord role ID when ready
        rgbColor = { r = 200, g = 30, b = 30 },
        primaryColor = 1, -- red
        secondaryColor = 1,
        stashes = {
            public = {
                coords = vec4(-70.4342, 359.4677, 112.5465, 339.2917),
                label = 'The Boneless Public Stash',
                id = 'tbs_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = vec4(-70.4342, 359.4677, 112.5465, 339.2917),
                label = 'The Boneless Personal Stash',
                id = 'tbs_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = nil,
                label = 'The Boneless Boss Stash',
                id = 'tbs_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6,
            },
        },
        wardrobe = {
            coords = vec4(-77.2893, 364.4999, 112.4417, 339.8512),
        },
        vehicle = {
            coords = nil,
            model = 'sultan',
        },
        -- Docs mirror for JG public garage "The Boneless" (actual zone is in jg-advancedgarages)
        garage = {
            coords = vec4(-55.1546, 343.6687, 112.1404, 337.2166),
            spawn = vec4(-59.0989, 334.4221, 111.3442, 156.2872),
        },
        crafting = {
            coords = vec4(-75.8942, 345.2116, 112.4456, 71.7149),
        },
    },
    ['ghettosyndicate'] = {
        name = 'ghettosyndicate',
        label = 'Ghetto Syndicate',
        bossGrade = 3, -- Boss
        -- discordRoleId = '', -- set Discord role ID when ready
        rgbColor = { r = 40, g = 180, b = 60 },
        primaryColor = 2, -- green
        secondaryColor = 2,
        stashes = {
            public = {
                coords = vec4(-1201.7363, -1800.5718, 3.9086, 231.9232),
                label = 'Ghetto Syndicate Public Stash',
                id = 'ghettosyndicate_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = vec4(-1201.7363, -1800.5718, 3.9086, 231.9232),
                label = 'Ghetto Syndicate Personal Stash',
                id = 'ghettosyndicate_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = nil,
                label = 'Ghetto Syndicate Boss Stash',
                id = 'ghettosyndicate_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6,
            },
        },
        wardrobe = {
            coords = vec4(-1202.0194, -1791.5204, 3.9085, 307.1058),
        },
        vehicle = {
            coords = nil,
            model = 'sultan',
        },
        -- Docs mirror for JG public garage "Ghetto Syndicate" (actual zone is in jg-advancedgarages)
        garage = {
            coords = vec4(-1226.8237, -1791.3672, 3.4013, 35.0928),
            spawn = vec4(-1233.0583, -1781.3629, 2.6698, 321.6736),
        },
        crafting = {
            coords = vec4(-1198.3726, -1806.2639, 3.9083, 5.3512),
        },
    },
    ['deuscartel'] = {
        name = 'deuscartel',
        label = 'Deus Cartel',
        bossGrade = 3, -- Boss
        -- discordRoleId = '', -- set Discord role ID when ready
        rgbColor = { r = 139, g = 90, b = 43 }, -- brown
        primaryColor = 96, -- brown
        secondaryColor = 96,
        stashes = {
            public = {
                coords = vec4(-1539.0490, -578.9200, 25.7077, 127.9400),
                label = 'Deus Cartel Shared Stash',
                id = 'deuscartel_public_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = false,
            },
            private = {
                coords = vec4(-1537.1360, -581.7250, 25.7078, 144.6485),
                label = 'Deus Cartel Personal Stash',
                id = 'deuscartel_private_stash',
                slots = 100,
                maxWeight = 3000000,
                owner = true,
            },
            boss = {
                coords = vec4(-1535.4612, -581.0501, 25.7078, 222.4925),
                label = 'Deus Cartel Boss Stash',
                id = 'deuscartel_boss_stash',
                slots = 300,
                maxWeight = 1000000,
                owner = 6, -- shared: bosses only (grade >= bossGrade)
            },
        },
        wardrobe = {
            coords = vec4(-1537.5172, -574.1053, 25.7079, 313.1573),
        },
        vehicle = {
            coords = nil,
            model = 'sultan',
        },
        -- Docs mirror for JG public garage "Deus Cartel" (actual zone is in jg-advancedgarages)
        garage = {
            coords = vec4(-1539.6759, -560.8541, 25.7077, 224.0734),
            spawn = vec4(-1541.8776, -566.3344, 25.7079, 27.8349),
        },
        crafting = {
            coords = vec4(-1557.0992, -568.8114, 25.7078, 40.8447),
        },
    },
}


--[[
    Discord role gate for gang hire.
    Player must be in GuildID AND have that gang's discordRoleId before a boss can hire them.
    Bot needs: Server Members Intent + View Server Members permission in that Discord.
]]
Config.DiscordHire = {
    Enabled = true,
    AllowOfflineHire = true, -- Hire by Discord ID even if recruit is offline
    -- Main Grim City Discord (same guild as loadingscreen staff roles).
    -- Bot token: convar kodebykarl_discord_bot_token (must be invited here + Server Members Intent).
    GuildID = '1240677650348118148',
    -- Empty = reuse Config.Logs.BotToken, then kodebykarl_discord_bot_token convar
    BotToken = '',
    RequireDiscordLinked = true,
    RequireInGuild = true,
    -- If a gang has no discordRoleId set, block hire (safer) or allow (set false)
    -- false = demo-friendly (GrimGang has no Discord role yet)
    BlockIfRoleNotConfigured = false,
    -- Short cache so rapid re-hires don't spam Discord (roles refresh after this)
    RoleCacheMs = 15000,
    Messages = {
        NoDiscord = 'Recruit must link Discord in FiveM settings first.',
        NotInGuild = 'Recruit must join the Discord server and get the gang role first.',
        MissingRole = 'Recruit does not have the %s Discord role yet. Re-check the role, then try again.',
        RoleNotConfigured = 'Discord role is not configured for this gang yet. Ask staff to set discordRoleId.',
        BotCannotAccess = 'Discord bot cannot read that server. Invite the bot + enable Server Members Intent.',
        ApiError = 'Could not verify Discord role. Try again in a moment.',
        InvalidDiscordId = 'Invalid Discord ID. Paste the numeric ID only.',
        NoCharacter = 'No character found for that Discord. They must join the city once first.',
        AlreadyInGang = 'That player is already in your gang.',
        OfflineDisabled = 'Offline Discord hire is disabled.',
    },
}

-- Precompute vec3 so client points / server distance checks skip per-call reconstruction
do
    local function toVec3(coords)
        if not coords then return nil end
        return vec3(coords.x, coords.y, coords.z)
    end

    for _, gang in pairs(Config.Gangs) do
        if gang.stashes then
            for _, stash in pairs(gang.stashes) do
                stash.vec = toVec3(stash.coords)
            end
        end
        if gang.wardrobe then
            gang.wardrobe.vec = toVec3(gang.wardrobe.coords)
        end
        if gang.vehicle then
            gang.vehicle.vec = toVec3(gang.vehicle.coords)
            gang.vehicle.spawnVec = toVec3(gang.vehicle.spawn or gang.vehicle.coords)
        end
        if gang.crafting then
            gang.crafting.vec = toVec3(gang.crafting.coords)
        end
        if gang.bossMenu then
            gang.bossMenu.vec = toVec3(gang.bossMenu.coords)
        end
        if gang.garage then
            gang.garage.vec = toVec3(gang.garage.coords)
        end
    end
end

function GetConfiguredGangs()
    return Config.Gangs
end

exports('GetGangs', GetConfiguredGangs)

--[[
    Discord logs (roster / exploit).
]]
Config.Logs = {
    Enabled = true,
    BotToken = '',
    GuildID = "1536358290777444397",

    ChannelNames = {
        roster = "GANG-ROSTER",
        exploit = "GANG-EXPLOIT",
    },

    ChannelIDs = {
        roster = "1536366691653656609",
        exploit = "1536366696179437619",
    },

    LogTypes = {
        roster = true,
        exploit = true,
    },

    EmbedColors = {
        hire = 3447003,
        promote = 15844367,
        demote = 15105570,
        fire = 10038562,
        exploit = 15158332,
    },

    PostCooldownMs = 500,
}

--[[
    Gang car claim ped (one car per player, ped-only take-out/store).
    Leaving / switching gangs permanently bans future claims.
]]
Config.ClaimPed = {
    enabled = true,
    model = 'g_m_y_mexgoon_02',
    coords = vector4(-1549.2260, -571.6039, 25.7079, 210.2311),
    -- Where the claimed car spawns when taken out
    spawn = vector4(-1545.50, -574.80, 25.71, 210.0),
    interactDistance = 2.5,
    requiredPlaytime = 2 * 60 * 60, -- 2 hours (seconds)
    platePrefix = 'GANG',
}
