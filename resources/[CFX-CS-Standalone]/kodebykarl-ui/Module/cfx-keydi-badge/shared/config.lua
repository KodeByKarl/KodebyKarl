ConfigBadge = ConfigBadge or {}

ConfigBadge.Debug = false

-- Command to trigger showing badge
ConfigBadge.Command = "badge"

-- Allowed Police / Sheriff jobs that can show the badge
ConfigBadge.AllowedJobs = {
    ["police"] = true,
    ["sheriff"] = true,
    ["lspd"] = true,
    ["bcso"] = true,
    ["sasp"] = true,
    ["state"] = true,
}

-- Department display labels based on job name
ConfigBadge.Departments = {
    ["police"] = "LOS SANTOS POLICE DEPT",
    ["sheriff"] = "BLAINE COUNTY SHERIFF",
    ["lspd"] = "LOS SANTOS POLICE DEPT",
    ["bcso"] = "BLAINE COUNTY SHERIFF",
    ["sasp"] = "SA STATE POLICE",
    ["state"] = "SA STATE POLICE",
}

-- Badge Emote Animation Settings
ConfigBadge.Emote = {
    dict = "paper_1_rcm_alt1-9",
    anim = "player_one_dual-9",
    prop = "prop_fib_badge", -- Badge prop attached to hand
    bone = 28422,
    pos = { x = 0.06, y = 0.021, z = -0.04 },
    rot = { x = -90.0, y = 0.0, z = -10.0 },
    duration = 4500 -- Emote duration in milliseconds
}
