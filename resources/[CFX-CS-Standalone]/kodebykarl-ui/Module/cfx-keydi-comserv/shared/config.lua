ConfigComServ = {}

ConfigComServ.Enabled = true
ConfigComServ.Debug = false

-- Staff groups that can open the panel / assign / end community service
ConfigComServ.StaffGroups = {
    moderator = true,
    admin = true,
    superadmin = true,
    owner = true,
    developer = true,
}

-- Only command left — opens the ComServ management panel
ConfigComServ.Commands = {
    open = "comserv",
}

-- Default actions when amount is omitted / UI default
ConfigComServ.DefaultActions = 10
ConfigComServ.MaxActions = 5000

-- How far the player can wander from the service zone before being pulled back
ConfigComServ.MaxDistance = 80.0

-- Community service area (Legion Square park by default)
ConfigComServ.Center = vector3(170.0, -990.0, 30.0)
ConfigComServ.Spawn = vector4(170.0, -990.0, 30.0, 160.0)

--[[
    Random task system:
    - Only ONE marker is active at a time
    - After each completed action it relocates to a different spot
    - Task type (broom / trash / sponge) is also randomized
]]
ConfigComServ.TaskLocations = {
    vector3(204.8629, -1016.9213, 29.3062),
    vector3(196.7194, -1017.0979, 29.3513),
    vector3(189.4563, -1009.1854, 29.3164),
    vector3(190.6470, -1001.7178, 29.2905),
    vector3(182.5409, -997.3342, 29.2918),
    vector3(175.0622, -996.5317, 29.2918),
    vector3(164.4274, -999.1773, 29.3438),
    vector3(158.8117, -1005.6859, 29.4605),
    vector3(152.7382, -997.6301, 29.3564),
    vector3(152.5687, -990.5843, 29.3621),
}

ConfigComServ.TaskTypes = {
    {
        id = "sweep",
        label = "Sweep litter",
        anim = {
            dict = "anim@amb@drug_field_workers@rake@male_a@base",
            clip = "base",
            flag = 1,
        },
        prop = {
            model = "prop_tool_broom",
            bone = 28422,
            pos = vector3(-0.01, 0.04, -0.03),
            rot = vector3(0.0, 0.0, 0.0),
        },
        groundProp = "prop_rub_litter_03",
    },
    {
        id = "sweep2",
        label = "Sweep sidewalk",
        anim = {
            dict = "anim@amb@drug_field_workers@rake@male_b@base",
            clip = "base",
            flag = 1,
        },
        prop = {
            model = "prop_tool_broom",
            bone = 28422,
            pos = vector3(-0.01, 0.04, -0.03),
            rot = vector3(0.0, 0.0, 0.0),
        },
        groundProp = "prop_rub_litter_01",
    },
    {
        id = "trash",
        label = "Pick up trash",
        anim = {
            dict = "missfbi4prepp1",
            clip = "_idle_garbage_man",
            flag = 49,
        },
        prop = {
            model = "prop_cs_street_binbag_01",
            bone = 28422,
            pos = vector3(0.0, 0.04, -0.02),
            rot = vector3(0.0, 0.0, 0.0),
        },
        groundProp = "prop_rub_binbag_sd_01",
    },
    {
        id = "clean",
        label = "Clean area",
        anim = {
            dict = "timetable@floyd@clean_kitchen@base",
            clip = "base",
            flag = 1,
        },
        prop = {
            model = "prop_sponge_01",
            bone = 28422,
            pos = vector3(0.0, 0.0, -0.01),
            rot = vector3(90.0, 0.0, 0.0),
        },
        groundProp = "prop_rub_litter_02",
    },
    {
        id = "clean2",
        label = "Wipe surfaces",
        anim = {
            dict = "amb@world_human_maid_clean@",
            clip = "base",
            flag = 1,
        },
        prop = {
            model = "prop_sponge_01",
            bone = 28422,
            pos = vector3(0.0, 0.0, -0.01),
            rot = vector3(90.0, 0.0, 0.0),
        },
        groundProp = nil,
    },
}

ConfigComServ.TaskInteractDistance = 2.0
ConfigComServ.TaskDurationMs = 5000
ConfigComServ.TaskCooldownMs = 2000
ConfigComServ.TaskCancelMoveDistance = 0.4 -- cancel progress if player moves this far
ConfigComServ.ShowTaskBlip = true

--[[
    Anti mass-comserv exploit:
    If a player (or cheated client) triggers sentence too many times in a short window,
    they are auto-banned. Staff assigning a few people normally is fine.
]]
ConfigComServ.SentenceRateLimit = {
    Max = 3,                -- max sentence attempts
    WindowMs = 5000,        -- within this many ms
    BanOnExceed = true,     -- true = ban, false = only block + notify
}

-- Non-staff triggering sentence/end events → instant ban
ConfigComServ.BanOnUnauthorized = true

-- Temporary inventory while serving (old items saved & restored after)
ConfigComServ.InventorySwap = {
    Enabled = true,
    TemporaryItems = {
        water = 50,
        burger = 50,
    },
}

-- Outfit applied while serving (restored when sentence ends)
-- Same orange prison clothes as xt-prison jail outfit
ConfigComServ.Outfit = {
    Enabled = true,
    male = {
        ["torso_1"] = 146, ["torso_2"] = 7,   -- Jackets
        ["tshirt_1"] = 15, ["tshirt_2"] = 0,  -- Shirt
        ["bproof_1"] = 0,  ["bproof_2"] = 0,  -- Body armor
        ["bags_1"] = 0,    ["bags_2"] = 0,    -- Bags
        ["arms"] = 0,      ["arms_2"] = 0,    -- Hands
        ["pants_1"] = 5,   ["pants_2"] = 7,   -- Legs
        ["shoes_1"] = 5,   ["shoes_2"] = 1,   -- Shoes
        ["decals_1"] = 0,  ["decals_2"] = 0,  -- Decals
    },
    female = {
        ["torso_1"] = 15, ["torso_2"] = 0,
        ["tshirt_1"] = 15, ["tshirt_2"] = 0,
        ["bproof_1"] = 0,  ["bproof_2"] = 0,
        ["bags_1"] = 0,    ["bags_2"] = 0,
        ["arms"] = 15,     ["arms_2"] = 0,
        ["pants_1"] = 15,  ["pants_2"] = 0,
        ["shoes_1"] = 35,  ["shoes_2"] = 0,
        ["decals_1"] = 0,  ["decals_2"] = 0,
    },
}

ConfigComServ.Brand = "GRIM CITY"
ConfigComServ.OfflineSearchLimit = 30

-- City-wide chat banner when someone is sentenced (same card as EMS bodybag).
ConfigComServ.ChatAnnounce = {
    Enabled = true,
    Job = "police", -- uses the GCPD chat banner
    Header = "FEED • COMSERV | SYSTEM",
}

--[[
    Discord logs (same bot as cfx-keydi-utils disconnectlogs).
    Create a text channel named COMSERV in guild 1536684358935650435
    (or set ChannelIDs manually).
]]
ConfigComServ.Logs = {
    Enabled = true,
    Debug = false,
    BotToken = "MTUzNjM2NDUyMjc5MTUwNjA0Mg.GfAaOT.pXdZcrMv-0yl2Blw9cESfKGSbv56AvD5C6-jTo",
    GuildID = "1536358290777444397",

    ChannelNames = {
        sent = "COMSERV",
        finish = "COMSERV",
        action = "COMSERV",
    },

    -- Optional manual overrides (leave empty to auto-find by ChannelNames)
    ChannelIDs = {
        sent = "1536684358935650435",
        finish = "1536684358935650435",
        action = "1536684358935650435",
    },

    LogTypes = {
        sent = true,
        finish = true,
        action = true,
    },

    EmbedColors = {
        sent = 15105570,   -- orange
        action = 3447003,  -- blue
        finish = 5763719,  -- green
        ended = 15158332,  -- red (staff ended early)
    },

    PostCooldownMs = 500,
}

ConfigComServ.Locale = {
    started = "You have been sentenced to community service (%d actions).",
    finished = "Community service completed. You are free to go.",
    reduced = "Task completed. %d action(s) remaining. Next location marked.",
    escaped = "You cannot leave the community service area.",
    alreadyServing = "That player is already serving community service.",
    notServing = "That player is not on community service.",
    invalidTarget = "Invalid player.",
    noPermission = "You do not have permission to use this command.",
    sentencedOffline = "Offline sentence saved. It will apply when they join.",
    endedByStaff = "Your community service was ended by staff.",
    endedOk = "Community service ended.",
    sentOk = "Player sent to community service.",
    newTask = "New task: %s — go to the marked location.",
    chatAnnounce = "%s has been sentenced to community service. Reason: %s",
}
