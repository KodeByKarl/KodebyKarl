ConfigDeathScreen = {}

ConfigDeathScreen.Enabled = true
ConfigDeathScreen.Debug = false

-- How long the death screen stays visible (ms). 0 = until revive / respawn.
ConfigDeathScreen.DisplayDuration = 10000

-- Show when killed by another player (PvP)
ConfigDeathScreen.PvPOnly = true

-- Also show when you kill yourself (uses your own data + character)
ConfigDeathScreen.ShowOnSuicide = true

-- Branding shown in panel footers
ConfigDeathScreen.Brand = "GRIM CITY"
ConfigDeathScreen.BrandUrl = "grim.city"

-- Killer ped camera framing — full body with feet clearly standing on road surface above labels
ConfigDeathScreen.Cam = {
    offset = vector3(0.0, 4.4, 0.35),      -- Back and elevated to center the standing killer
    pointOffset = vector3(0.0, 0.0, 0.05),  -- Aim at mid-lower torso
    fov = 46.0,
}

-- How many recent kills to show on the combat recap
ConfigDeathScreen.RecentKillLimit = 5

--[[
    Bone → hit zone (covers head / face / neck / torso / limbs).
    GTA often reports facial bones instead of SKEL_Head on headshots.
]]
ConfigDeathScreen.BoneZones = {
    -- Head / face (all count as headshot). GTA often reports these instead of SKEL_Head.
    [31085] = "head",
    [31086] = "head",   -- SKEL_Head
    [12844] = "head",   -- IK_Head
    [65068] = "head",   -- FACIAL_facialRoot
    [24532] = "head",   -- MH_Hair_Scale
    [37193] = "head",   -- FB_R_Brow_Out / brow centre
    [19336] = "head",   -- FB_R_Brow_Out_000
    [58331] = "head",   -- FB_L_Brow_Out_000
    [45750] = "head",   -- FB_L_Lid_Upper_000
    [25260] = "head",   -- FB_L_Eye_000
    [21550] = "head",   -- FB_L_CheekBone
    [29868] = "head",   -- FB_L_Lip_Corner_000
    [43536] = "head",   -- FB_R_Lid_Upper_000
    [27474] = "head",   -- FB_R_Eye_000
    [47419] = "head",   -- FB_R_CheekBone
    [20178] = "head",   -- FB_R_Lip_Corner_000
    [17188] = "head",   -- FB_Jaw_000
    [20623] = "head",   -- FB_LowerLipRoot_000
    [49979] = "head",   -- FB_LowerLip_000
    [20279] = "head",   -- FB_L_Lip_Top_000
    [17719] = "head",   -- FB_R_Lip_Top_000
    [1356]  = "head",   -- FB_UpperLipRoot_000
    [11174] = "head",   -- FB_UpperLip_000
    [46240] = "head",   -- FB_Jaw extra
    [47495] = "head",   -- FB_L_Lip_Bot
    [61839] = "head",   -- FB_Tongue_000
    [64654] = "head",   -- RB_Neck_1 (skull base)
    [39317] = "head",   -- SKEL_Neck_1 (GTA reports this on headshots)
    [35731] = "neck",   -- SKEL_Neck_1 alt
    -- Bone INDEX from GetPedBoneIndex (GetPedLastDamageBone often returns these)
    -- https://docs.fivem.net/natives/?_0x3F428D08BE5AAE31
    [97]  = "head",
    [98]  = "head",
    [99]  = "head",
    [102] = "head",
    [103] = "head",
    [104] = "head",
    [105] = "head",
    [106] = "head",
    [107] = "head",
    [108] = "head",
    [109] = "head",
    [110] = "head",
    [111] = "head",
    [112] = "head",
    [113] = "head",
    [114] = "head",
    [115] = "head",
    [116] = "head",
    [117] = "head",
    [118] = "head",
    [119] = "head",
    [120] = "head",
    [121] = "head",
    [122] = "head",
    [123] = "head",
    [124] = "neck",
    [125] = "head",

    -- Torso
    [11816] = "torso",  -- SKEL_Pelvis
    [24816] = "torso",  -- SKEL_Spine0
    [24817] = "torso",  -- SKEL_Spine1
    [24818] = "torso",  -- SKEL_Spine2
    [23553] = "torso",  -- SKEL_Spine3
    [57597] = "torso",  -- SKEL_Spine_Root
    [56604] = "torso",  -- MH_FrontUpperChest
    [64729] = "torso",  -- SKEL_L_Clavicle
    [10706] = "torso",  -- SKEL_R_Clavicle

    -- Arms
    [45509] = "arm",    -- SKEL_L_UpperArm
    [61163] = "arm",    -- SKEL_L_Forearm
    [18905] = "arm",    -- SKEL_L_Hand
    [40269] = "arm",    -- SKEL_R_UpperArm
    [28252] = "arm",    -- SKEL_R_Forearm
    [57005] = "arm",    -- SKEL_R_Hand
    [60309] = "arm",    -- PH_R_Hand
    [28422] = "arm",    -- PH_L_Hand

    -- Legs
    [58271] = "leg",    -- SKEL_L_Thigh
    [63931] = "leg",    -- SKEL_L_Calf
    [14201] = "leg",    -- SKEL_L_Foot
    [51826] = "leg",    -- SKEL_R_Thigh
    [36864] = "leg",    -- SKEL_R_Calf
    [52301] = "leg",    -- SKEL_R_Foot
    [2108]  = "leg",    -- SKEL_L_Toe0
    [20781] = "leg",    -- SKEL_R_Toe0
}

-- Bones treated as headshot (fatal / highlight)
ConfigDeathScreen.HeadBones = {
    [31085] = true,
    [31086] = true,
    [12844] = true,
    [65068] = true,
    [24532] = true,
    [37193] = true,
    [19336] = true,
    [58331] = true,
    [45750] = true,
    [25260] = true,
    [21550] = true,
    [29868] = true,
    [43536] = true,
    [27474] = true,
    [47419] = true,
    [20178] = true,
    [17188] = true,
    [20623] = true,
    [49979] = true,
    [20279] = true,
    [17719] = true,
    [1356] = true,
    [11174] = true,
    [46240] = true,
    [47495] = true,
    [61839] = true,
    [64654] = true,
    [39317] = true, -- SKEL_Neck_1 — GTA headshot bone
    [97] = true,
    -- Bone INDEX (GetPedBoneIndex)
    [98] = true,
    [99] = true,
    [102] = true,
    [103] = true,
    [104] = true,
    [105] = true,
    [106] = true,
    [107] = true,
    [108] = true,
    [109] = true,
    [110] = true,
    [111] = true,
    [112] = true,
    [113] = true,
    [114] = true,
    [115] = true,
    [116] = true,
    [117] = true,
    [118] = true,
    [119] = true,
    [120] = true,
    [121] = true,
    [122] = true,
    [123] = true,
    [125] = true,
}

-- Common weapon labels (hash -> display name)
ConfigDeathScreen.Weapons = {
    [`WEAPON_UNARMED`] = "Fists",
    [`WEAPON_KNIFE`] = "Knife",
    [`WEAPON_NIGHTSTICK`] = "Nightstick",
    [`WEAPON_HAMMER`] = "Hammer",
    [`WEAPON_BAT`] = "Bat",
    [`WEAPON_CROWBAR`] = "Crowbar",
    [`WEAPON_GOLFCLUB`] = "Golf Club",
    [`WEAPON_BOTTLE`] = "Bottle",
    [`WEAPON_DAGGER`] = "Dagger",
    [`WEAPON_HATCHET`] = "Hatchet",
    [`WEAPON_MACHETE`] = "Machete",
    [`WEAPON_SWITCHBLADE`] = "Switchblade",
    [`WEAPON_PISTOL`] = "Pistol",
    [`WEAPON_PISTOL_MK2`] = "Pistol Mk II",
    [`WEAPON_COMBATPISTOL`] = "Combat Pistol",
    [`WEAPON_APPISTOL`] = "AP Pistol",
    [`WEAPON_PISTOL50`] = "Pistol .50",
    [`WEAPON_DEAGLE`] = "Desert Eagle",
    [`WEAPON_SNSPISTOL`] = "SNS Pistol",
    [`WEAPON_HEAVYPISTOL`] = "Heavy Pistol",
    [`WEAPON_VINTAGEPISTOL`] = "Vintage Pistol",
    [`WEAPON_REVOLVER`] = "Revolver",
    [`WEAPON_REVOLVER_MK2`] = "Revolver Mk II",
    [`WEAPON_MICROSMG`] = "Micro SMG",
    [`WEAPON_SMG`] = "SMG",
    [`WEAPON_SMG_MK2`] = "SMG Mk II",
    [`WEAPON_ASSAULTSMG`] = "Assault SMG",
    [`WEAPON_COMBATPDW`] = "Combat PDW",
    [`WEAPON_MACHINEPISTOL`] = "Machine Pistol",
    [`WEAPON_MINISMG`] = "Mini SMG",
    [`WEAPON_PUMPSHOTGUN`] = "Pump Shotgun",
    [`WEAPON_SAWNOFFSHOTGUN`] = "Sawed-Off",
    [`WEAPON_ASSAULTSHOTGUN`] = "Assault Shotgun",
    [`WEAPON_BULLPUPSHOTGUN`] = "Bullpup Shotgun",
    [`WEAPON_HEAVYSHOTGUN`] = "Heavy Shotgun",
    [`WEAPON_ASSAULTRIFLE`] = "Assault Rifle",
    [`WEAPON_ASSAULTRIFLE_MK2`] = "Assault Rifle Mk II",
    [`WEAPON_CARBINERIFLE`] = "Carbine Rifle",
    [`WEAPON_CARBINERIFLE_MK2`] = "Carbine Rifle Mk II",
    [`WEAPON_ADVANCEDRIFLE`] = "Advanced Rifle",
    [`WEAPON_SPECIALCARBINE`] = "Special Carbine",
    [`WEAPON_BULLPUPRIFLE`] = "Bullpup Rifle",
    [`WEAPON_COMPACTRIFLE`] = "Compact Rifle",
    [`WEAPON_MG`] = "MG",
    [`WEAPON_COMBATMG`] = "Combat MG",
    [`WEAPON_GUSENBERG`] = "Gusenberg",
    [`WEAPON_SNIPERRIFLE`] = "Sniper Rifle",
    [`WEAPON_HEAVYSNIPER`] = "Heavy Sniper",
    [`WEAPON_MARKSMANRIFLE`] = "Marksman Rifle",
    [`WEAPON_RPG`] = "RPG",
    [`WEAPON_GRENADELAUNCHER`] = "Grenade Launcher",
    [`WEAPON_MINIGUN`] = "Minigun",
    [`WEAPON_GRENADE`] = "Grenade",
    [`WEAPON_STICKYBOMB`] = "Sticky Bomb",
    [`WEAPON_MOLOTOV`] = "Molotov",
    [`WEAPON_STUNGUN`] = "Stun Gun",
    [`WEAPON_FLAREGUN`] = "Flare Gun",
    [`WEAPON_FIREEXTINGUISHER`] = "Extinguisher",
    [`WEAPON_PETROLCAN`] = "Jerry Can",
    [`WEAPON_RUN_OVER_BY_CAR`] = "Vehicle",
    [`WEAPON_RAMMED_BY_CAR`] = "Vehicle",
    [`WEAPON_FALL`] = "Fall",
    [`WEAPON_EXPLOSION`] = "Explosion",
    [`WEAPON_FIRE`] = "Fire",
    [`WEAPON_DROWNING`] = "Drowning",
}
