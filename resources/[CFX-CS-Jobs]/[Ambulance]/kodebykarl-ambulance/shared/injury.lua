Config = Config or {}

Config.AlertShowInfo = 2

Config.WeaponClasses = {
    ['SMALL_CALIBER'] = 1,
    ['MEDIUM_CALIBER'] = 2,
    ['HIGH_CALIBER'] = 3,
    ['SHOTGUN'] = 4,
    ['CUTTING'] = 5,
    ['LIGHT_IMPACT'] = 6,
    ['HEAVY_IMPACT'] = 7,
    ['EXPLOSIVE'] = 8,
    ['FIRE'] = 9,
    ['SUFFOCATING'] = 10,
    ['OTHER'] = 11,
    ['WILDLIFE'] = 12,
    ['NOTHING'] = 13
}

Config.WoundStates = {
    'Irritated',
    'Fairly Painful',
    'Extremely Painful',
    'Unbearably Painful',
}

Config.BleedingStates = {
    'Minor Bleeding',
    'Significant Bleeding',
    'Major Bleeding',
    'Extreme Bleeding',
}

Config.MovementRate = {
    0.98,
    0.96,
    0.94,
    0.92,
}

-- GTA often reports facial / IK bones instead of SKEL_Head (31086) on headshots.
-- Neck (39317) was the only nearby bone that registered before this map was expanded.
--
-- Two number spaces (see GetPedBoneIndex):
--   Bone ID   = SKEL_* tag, e.g. 31086 (SKEL_Head), 39317 (SKEL_Neck_1)
--   Bone index = GetPedBoneIndex(ped, boneId), e.g. 98 (head), 97 (neck)
-- GetPedLastDamageBone can return EITHER. Index 98 must map to HEAD or headshots never register.
-- https://docs.fivem.net/natives/?_0x3F428D08BE5AAE31
Config.Bones = {
    [0]     = 'NONE',
    [31085] = 'HEAD',
    [31086] = 'HEAD', -- SKEL_Head (ID)
    [12844] = 'HEAD', -- IK_Head
    [65068] = 'HEAD', -- FACIAL_facialRoot
    [24532] = 'HEAD', -- MH_Hair_Scale
    [37193] = 'HEAD', -- FB_Brow_Centre_000
    [19336] = 'HEAD', -- FB_R_CheekBone_000
    [58331] = 'HEAD', -- FB_L_Brow_Out_000
    [45750] = 'HEAD', -- FB_L_Lid_Upper_000
    [25260] = 'HEAD', -- FB_L_Eye_000
    [21550] = 'HEAD', -- FB_L_CheekBone
    [29868] = 'HEAD', -- FB_L_Lip_Corner_000
    [43536] = 'HEAD', -- FB_R_Lid_Upper_000
    [27474] = 'HEAD', -- FB_R_Eye_000
    [47419] = 'HEAD', -- FB_L_Lip_Bot_000
    [20178] = 'HEAD', -- FB_UpperLipRoot_000
    [17188] = 'HEAD', -- FB_LowerLipRoot_000
    [20623] = 'HEAD', -- FB_LowerLip_000
    [49979] = 'HEAD', -- FB_R_Lip_Bot_000
    [20279] = 'HEAD', -- FB_L_Lip_Top_000
    [17719] = 'HEAD', -- FB_R_Lip_Top_000
    [1356]  = 'HEAD', -- FB_R_Brow_Out_000
    [11174] = 'HEAD', -- FB_R_Lip_Corner_000
    [46240] = 'HEAD', -- FB_Jaw_000
    [47495] = 'HEAD', -- FB_Tongue_000
    [61839] = 'HEAD', -- FB_UpperLip_000
    [64654] = 'HEAD', -- RB_Neck_1 (skull base)
    [39317] = 'NECK', -- SKEL_Neck_1 (ID)
    [35731] = 'NECK', -- RB_Neck_1
    -- Bone INDEX (GetPedBoneIndex) — head / face / neck
    [97]  = 'NECK', -- SKEL_Neck_1
    [98]  = 'HEAD', -- SKEL_Head
    [99]  = 'HEAD', -- IK_Head
    [102] = 'HEAD', -- FACIAL_facialRoot
    [103] = 'HEAD', -- FB_L_Brow_Out_000
    [104] = 'HEAD', -- FB_L_Lid_Upper_000
    [105] = 'HEAD', -- FB_L_Eye_000
    [106] = 'HEAD', -- FB_L_CheekBone
    [107] = 'HEAD', -- FB_L_Lip_Corner_000
    [108] = 'HEAD', -- FB_R_Lid_Upper_000
    [109] = 'HEAD', -- FB_R_Eye_000
    [110] = 'HEAD', -- FB_R_CheekBone_000
    [111] = 'HEAD', -- FB_R_Brow_Out_000
    [112] = 'HEAD', -- FB_R_Lip_Corner_000
    [113] = 'HEAD', -- FB_Brow_Centre_000
    [114] = 'HEAD', -- FB_UpperLipRoot_000
    [115] = 'HEAD', -- FB_UpperLip_000
    [116] = 'HEAD', -- FB_L_Lip_Top_000
    [117] = 'HEAD', -- FB_R_Lip_Top_000
    [118] = 'HEAD', -- FB_Jaw_000
    [119] = 'HEAD', -- FB_LowerLipRoot_000
    [120] = 'HEAD', -- FB_LowerLip_000
    [121] = 'HEAD', -- FB_L_Lip_Bot_000
    [122] = 'HEAD', -- FB_R_Lip_Bot_000
    [123] = 'HEAD', -- FB_Tongue_000
    [124] = 'NECK', -- RB_Neck_1
    [125] = 'HEAD', -- skull base
    [57597] = 'SPINE',
    [23553] = 'SPINE',
    [24816] = 'SPINE',
    [24817] = 'SPINE',
    [24818] = 'SPINE',
    [10706] = 'UPPER_BODY',
    [64729] = 'UPPER_BODY',
    [11816] = 'LOWER_BODY',
    [45509] = 'LARM',
    [61163] = 'LARM',
    [18905] = 'LHAND',
    [4089] = 'LFINGER',
    [4090] = 'LFINGER',
    [4137] = 'LFINGER',
    [4138] = 'LFINGER',
    [4153] = 'LFINGER',
    [4154] = 'LFINGER',
    [4169] = 'LFINGER',
    [4170] = 'LFINGER',
    [4185] = 'LFINGER',
    [4186] = 'LFINGER',
    [26610] = 'LFINGER',
    [26611] = 'LFINGER',
    [26612] = 'LFINGER',
    [26613] = 'LFINGER',
    [26614] = 'LFINGER',
    [58271] = 'LLEG',
    [63931] = 'LLEG',
    [2108] = 'LFOOT',
    [14201] = 'LFOOT',
    [40269] = 'RARM',
    [28252] = 'RARM',
    [57005] = 'RHAND',
    [58866] = 'RFINGER',
    [58867] = 'RFINGER',
    [58868] = 'RFINGER',
    [58869] = 'RFINGER',
    [58870] = 'RFINGER',
    [64016] = 'RFINGER',
    [64017] = 'RFINGER',
    [64064] = 'RFINGER',
    [64065] = 'RFINGER',
    [64080] = 'RFINGER',
    [64081] = 'RFINGER',
    [64096] = 'RFINGER',
    [64097] = 'RFINGER',
    [64112] = 'RFINGER',
    [64113] = 'RFINGER',
    [36864] = 'RLEG',
    [51826] = 'RLEG',
    [20781] = 'RFOOT',
    [52301] = 'RFOOT',
}

Config.Weapons = {
    [`WEAPON_STUNGUN`] = Config.WeaponClasses['NONE'],

    --[[ Small Caliber ]]--
    [`WEAPON_PISTOL`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_COMBATPISTOL`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_APPISTOL`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_COMBATPDW`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_MACHINEPISTOL`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_MICROSMG`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_MINISMG`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_PISTOL_MK2`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_SNSPISTOL`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_SNSPISTOL_MK2`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_VINTAGEPISTOL`] = Config.WeaponClasses['HIGH_CALIBER'],

    --[[ Medium Caliber ]]--
    [`WEAPON_ADVANCEDRIFLE`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_ASSAULTSMG`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_BULLPUPRIFLE`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_BULLPUPRIFLE_MK2`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_CARBINERIFLE`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_CARBINERIFLE_MK2`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_COMPACTRIFLE`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_DOUBLEACTION`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_GUSENBERG`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_HEAVYPISTOL`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_MARKSMANPISTOL`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_PISTOL50`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_DEAGLE`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_REVOLVER`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_REVOLVER_MK2`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_SMG`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_SMG_MK2`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_SPECIALCARBINE`] = Config.WeaponClasses['MEDIUM_CALIBER'],
    [`WEAPON_SPECIALCARBINE_MK2`] = Config.WeaponClasses['MEDIUM_CALIBER'],

    --[[ High Caliber ]]--
    [`WEAPON_ASSAULTRIFLE`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_ASSAULTRIFLE_MK2`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_COMBATMG`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_COMBATMG_MK2`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_HEAVYSNIPER`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_HEAVYSNIPER_MK2`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_MARKSMANRIFLE`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_MARKSMANRIFLE_MK2`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_MG`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_MINIGUN`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_MUSKET`] = Config.WeaponClasses['HIGH_CALIBER'],
    [`WEAPON_RAILGUN`] = Config.WeaponClasses['HIGH_CALIBER'],

    --[[ Shotguns ]]--
    [`WEAPON_ASSAULTSHOTGUN`] = Config.WeaponClasses['SHOTGUN'],
    [`WEAPON_BULLUPSHOTGUN`] = Config.WeaponClasses['SHOTGUN'],
    [`WEAPON_DBSHOTGUN`] = Config.WeaponClasses['SHOTGUN'],
    [`WEAPON_HEAVYSHOTGUN`] = Config.WeaponClasses['SHOTGUN'],
    [`WEAPON_PUMPSHOTGUN`] = Config.WeaponClasses['SHOTGUN'],
    [`WEAPON_PUMPSHOTGUN_MK2`] = Config.WeaponClasses['SHOTGUN'],
    [`WEAPON_SAWNOFFSHOTGUN`] = Config.WeaponClasses['SHOTGUN'],
    [`WEAPON_SWEEPERSHOTGUN`] = Config.WeaponClasses['SHOTGUN'],

    --[[ Animals ]]--
    [`WEAPON_ANIMAL`] = Config.WeaponClasses['WILDLIFE'], -- Animal
    [`WEAPON_COUGAR`] = Config.WeaponClasses['WILDLIFE'], -- Cougar
    [`WEAPON_BARBED_WIRE`] = Config.WeaponClasses['WILDLIFE'], -- Barbed Wire
    
    --[[ Cutting Weapons ]]--
    [`WEAPON_BATTLEAXE`] = Config.WeaponClasses['CUTTING'],
    [`WEAPON_BOTTLE`] = Config.WeaponClasses['CUTTING'],
    [`WEAPON_DAGGER`] = Config.WeaponClasses['CUTTING'],
    [`WEAPON_HATCHET`] = Config.WeaponClasses['CUTTING'],
    [`WEAPON_KNIFE`] = Config.WeaponClasses['CUTTING'],
    [`WEAPON_MACHETE`] = Config.WeaponClasses['CUTTING'],
    [`WEAPON_SWITCHBLADE`] = Config.WeaponClasses['CUTTING'],

    --[[ Light Impact ]]--
    --[`WEAPON_GARBAGEBAG`] = Config.WeaponClasses['LIGHT_IMPACT'], -- Garbage Bag
    --[`WEAPON_BRIEFCASE`] = Config.WeaponClasses['LIGHT_IMPACT'], -- Briefcase
    --[`WEAPON_BRIEFCASE_02`] = Config.WeaponClasses['LIGHT_IMPACT'], -- Briefcase 2
    --[`WEAPON_BALL`] = Config.WeaponClasses['LIGHT_IMPACT'],
    --[`WEAPON_FLASHLIGHT`] = Config.WeaponClasses['LIGHT_IMPACT'],
    [`WEAPON_KNUCKLE`] = Config.WeaponClasses['LIGHT_IMPACT'],
    --[`WEAPON_NIGHTSTICK`] = Config.WeaponClasses['LIGHT_IMPACT'],
    --[`WEAPON_SNOWBALL`] = Config.WeaponClasses['LIGHT_IMPACT'],
    --[`WEAPON_UNARMED`] = Config.WeaponClasses['LIGHT_IMPACT'],
    --[`WEAPON_PARACHUTE`] = Config.WeaponClasses['LIGHT_IMPACT'],
    --[`WEAPON_NIGHTVISION`] = Config.WeaponClasses['LIGHT_IMPACT'],
    
    --[[ Heavy Impact ]]--
    [`WEAPON_BAT`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_CROWBAR`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_FIREEXTINGUISHER`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_FIRWORK`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_GOLFLCUB`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_HAMMER`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_PETROLCAN`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_POOLCUE`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_WRENCH`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_RAMMED_BY_CAR`] = Config.WeaponClasses['HEAVY_IMPACT'],
    [`WEAPON_RUN_OVER_BY_CAR`] = Config.WeaponClasses['HEAVY_IMPACT'],
    
    --[[ Explosives ]]--
    [`WEAPON_EXPLOSION`] = Config.WeaponClasses['EXPLOSIVE'],
    [`WEAPON_GRENADE`] = Config.WeaponClasses['EXPLOSIVE'],
    [`WEAPON_COMPACTLAUNCHER`] = Config.WeaponClasses['EXPLOSIVE'],
    [`WEAPON_HOMINGLAUNCHER`] = Config.WeaponClasses['EXPLOSIVE'],
    [`WEAPON_PIPEBOMB`] = Config.WeaponClasses['EXPLOSIVE'],
    [`WEAPON_PROXMINE`] = Config.WeaponClasses['EXPLOSIVE'],
    [`WEAPON_RPG`] = Config.WeaponClasses['EXPLOSIVE'],
    [`WEAPON_STICKYBOMB`] = Config.WeaponClasses['EXPLOSIVE'],
    [`WEAPON_HELI_CRASH`] = Config.WeaponClasses['EXPLOSIVE'],
    
    --[[ Other ]]--
    [`WEAPON_FALL`] = Config.WeaponClasses['OTHER'], -- Fall
    [`WEAPON_HIT_BY_WATER_CANNON`] = Config.WeaponClasses['OTHER'], -- Water Cannon
    
    --[[ Fire ]]--
    [`WEAPON_ELECTRIC_FENCE`] = Config.WeaponClasses['FIRE'],
    [`WEAPON_FIRE`] = Config.WeaponClasses['FIRE'],
    [`WEAPON_MOLOTOV`] = Config.WeaponClasses['FIRE'],
    [`WEAPON_FLARE`] = Config.WeaponClasses['FIRE'],
    [`WEAPON_FLAREGUN`] = Config.WeaponClasses['FIRE'],

    --[[ Suffocate ]]--
    [`WEAPON_DROWNING`] = Config.WeaponClasses['SUFFOCATING'], -- Drowning
    [`WEAPON_DROWNING_IN_VEHICLE`] = Config.WeaponClasses['SUFFOCATING'], -- Drowning Veh
    [`WEAPON_EXHAUSTION`] = Config.WeaponClasses['SUFFOCATING'], -- Exhaust
    [`WEAPON_BZGAS`] = Config.WeaponClasses['SUFFOCATING'],
    [`WEAPON_SMOKEGRENADE`] = Config.WeaponClasses['SUFFOCATING'],
}

--[[
    HealthDamage : How Much Damage To Direct HP Must Be Applied Before Checks For Damage Happens
    ArmorDamage : How Much Damage To Armor Must Be Applied Before Checks For Damage Happens | NOTE: This will in turn make stagger effect with armor happen only after that damage occurs
]]
Config.HealthDamage = 10
Config.ArmorDamage = 5

--[[
    MaxInjuryChanceMulti : How many times the HealthDamage value above can divide into damage taken before damage is forced to be applied
    ForceInjury : Maximum amount of damage a player can take before limb damage & effects are forced to occur
]]
Config.MaxInjuryChanceMulti = 3
Config.ForceInjury = 45
Config.AlwaysBleedChance = 35

--[[ 
    BleedTickRate : How much time, in seconds, between bleed ticks
]]
Config.BleedTickRate = 90

--[[
    BleedMovementTick : How many seconds is taken away from the bleed tick rate if the player is walking, jogging, or sprinting
    BleedMovementAdvance : How Much Time Moving While Bleeding Adds (This Adds This Value To The Tick Count, Meaing The Above BleedTickRate Will Be Reached Faster)
]]
Config.BleedMovementTick = 3
Config.BleedMovementAdvance = 1

--[[
    The Base Damage That Is Multiplied By Bleed Level Every Time A Bleed Tick Occurs
]]
Config.BleedTickDamage = 1

--[[
    FadeOutTimer : How many bleed ticks occur before fadeout happens
    BlackoutTimer : How many bleed ticks occur before blacking out
    AdvanceBleedTimer : How many bleed ticks occur before bleed level increases
]]
Config.FadeOutTimer = 2
Config.BlackoutTimer = 10
Config.AdvanceBleedTimer = 12

--[[
    HeadInjuryTimer : How much time, in seconds, do head injury effects chance occur
    ArmInjuryTimer : How much time, in seconds, do arm injury effects chance occur
    LegInjuryTimer : How much time, in seconds, do leg injury effects chance occur
]]
Config.HeadInjuryTimer = 50
Config.ArmInjuryTimer = 50
Config.LegInjuryTimer = 50

--[[
    The Chance, In Percent, That Certain Injury Side-Effects Get Applied
]]
Config.HeadInjuryChance = 20
Config.LegInjuryChance = {
    Running = 25,
    Walking = 5
}

--[[
    MajorArmoredBleedChance : The % Chance Someone Gets A Bleed Effect Applied When Taking Major Damage With Armor
    MajorDoubleBleed : % Chance You Have To Receive Double Bleed Effect From Major Damage, This % is halved if the player has armor
]]
Config.MajorArmoredBleedChance = 45


--[[
    DamgeMinorToMajor : How much damage would have to be applied for a minor weapon to be considered a major damage event. Put this at 100 if you want to disable it
]]
Config.DamageMinorToMajor = 45


--[[
    These following lists uses tables defined in definitions.lua, you can technically use the hardcoded values but for sake
    of ensuring future updates doesn't break it I'd highly suggest you check that file for the index you're wanting to use.

    MinorInjurWeapons : Damage From These Weapons Will Apply Only Minor Injuries
    MajorInjurWeapons : Damage From These Weapons Will Apply Only Major Injuries
    AlwaysBleedChanceWeapons : Weapons that're in the included weapon classes will roll for a chance to apply a bleed effect if the damage wasn't enough to trigger an injury chance
    CriticalAreas : 
    StaggerAreas : These are the body areas that would cause a stagger is hit by firearms,
        Table Values: Armored = Can This Cause Stagger If Wearing Armor, Major = % Chance You Get Staggered By Major Damage, Minor = % Chance You Get Staggered By Minor Damage
]]

Config.MinorInjurWeapons = {
    [Config.WeaponClasses['SMALL_CALIBER']] = true,
    [Config.WeaponClasses['MEDIUM_CALIBER']] = true,
    [Config.WeaponClasses['CUTTING']] = true,
    [Config.WeaponClasses['WILDLIFE']] = true,
    [Config.WeaponClasses['OTHER']] = true,
    [Config.WeaponClasses['LIGHT_IMPACT']] = true,
}

Config.MajorInjurWeapons = {
    [Config.WeaponClasses['HIGH_CALIBER']] = true,
    [Config.WeaponClasses['HEAVY_IMPACT']] = true,
    [Config.WeaponClasses['SHOTGUN']] = true,
    [Config.WeaponClasses['EXPLOSIVE']] = true,
}

Config.AlwaysBleedChanceWeapons = {
    [Config.WeaponClasses['SMALL_CALIBER']] = true,
    [Config.WeaponClasses['MEDIUM_CALIBER']] = true,
    [Config.WeaponClasses['CUTTING']] = true,
    [Config.WeaponClasses['WILDLIFE']] = true,
}

Config.ForceInjuryWeapons = {
    [Config.WeaponClasses['HIGH_CALIBER']] = true,
    [Config.WeaponClasses['HEAVY_IMPACT']] = true,
    [Config.WeaponClasses['EXPLOSIVE']] = true,
}

Config.CriticalAreas = {
    ['HEAD'] = { armored = false },
    ['NECK'] = { armored = false },
    ['UPPER_BODY'] = { armored = false },
    ['LOWER_BODY'] = { armored = true },
    ['SPINE'] = { armored = true },
}

function Config.IsHeadArea(bone)
    local part = Config.Bones[tonumber(bone)]
    return part == 'HEAD' or part == 'NECK'
end

-- Convert GetPedBoneIndex result (or last-damage index) back to a bone ID for natives like GetPedBoneCoords.
-- https://docs.fivem.net/natives/?_0x3F428D08BE5AAE31
Config.BoneIndexToId = {
    [97]  = 39317, -- SKEL_Neck_1
    [98]  = 31086, -- SKEL_Head
    [99]  = 12844, -- IK_Head
    [102] = 65068,
    [103] = 58331,
    [104] = 45750,
    [105] = 25260,
    [106] = 21550,
    [107] = 29868,
    [108] = 43536,
    [109] = 27474,
    [110] = 19336,
    [111] = 1356,
    [112] = 11174,
    [113] = 37193,
    [114] = 20178,
    [115] = 61839,
    [116] = 20279,
    [117] = 17719,
    [118] = 46240,
    [119] = 17188,
    [120] = 20623,
    [121] = 47419,
    [122] = 49979,
    [123] = 47495,
    [124] = 35731,
    [125] = 64654,
}

function Config.ToBoneId(bone)
    bone = tonumber(bone) or 0
    if bone <= 0 then return bone end
    return Config.BoneIndexToId[bone] or bone
end


Config.StaggerAreas = {
    ['SPINE'] = { armored = true, major = 60, minor = 30 },
    ['UPPER_BODY'] = { armored = false, major = 60, minor = 30 },
    ['LLEG'] = { armored = true, major = 100, minor = 85 },
    ['RLEG'] = { armored = true, major = 100, minor = 85 },
    ['LFOOT'] = { armored = true, major = 100, minor = 100 },
    ['RFOOT'] = { armored = true, major = 100, minor = 100 },
}

Config.Strings = {
    Blackout = ' You Suddenly Black Out',
    InjurNoRun = ' You\'re Having A Hard Time Running',
    InjurStumble = ' You\'re Having A Hard Using Your Legs',

    UseAdrenaline = ' You\'re Able To Ignore Your Body Failing',
    AdrenalineExpired = ' You\'ve Realized Doing Drugs Does Not Fix All Your Problems',

    LimbAlert = 'Your %s feels %s',
    LimbAlertSeperator = ' | ',
    LimbAlertMultiple = ' You Feel Multiple Pains',

    BleedAlert = 'You Have %s',
}