ConfigIndicator = {}

ConfigIndicator.Debug = false

-- Default settings that will be sent to the React UI and loaded on player join.
-- These are fully modifiable in-game via the style control settings menu.
ConfigIndicator.DefaultSettings = {
    deadText = "Dead",
    deadIcon = "skull", -- skull, crossbones, heart-crack, ghost, danger, sick, x-mark, skull-io, ban
    fontFamily = "JetBrains Mono",
    fontSize = 18,
    duration = 3.0,
    -- Fallback when zone is unknown (legacy)
    healthColor = "#f87171",
    armorColor = "#60a5fa",
}

--[[
  Hitmarker colors by damage bone zone (shared with deathscreen bone map).
  Head = blue, Neck = red, Body (torso+arms) = amber, Legs = green.
]]
ConfigIndicator.ZoneColors = {
    head = "#3b82f6", -- blue
    neck = "#ef4444", -- red
    torso = "#f59e0b", -- body / amber
    arms = "#f59e0b", -- body (same as torso)
    legs = "#22c55e", -- green
}

ConfigIndicator.ZoneLabels = {
    head = "H",
    neck = "N",
    torso = "B",
    arms = "B",
    legs = "L",
}
