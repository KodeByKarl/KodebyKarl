--[[
  Accurate ped bone → body zone mapping for death screen anatomy.
  Bone IDs from ePedBoneId (uint16). GetPedLastDamageBone may also return
  bone INDEX values — those are remapped via BONE_INDEX_TO_ID below.
]]

DeathScreenBones = DeathScreenBones or {}

local HEAD = "head"
local NECK = "neck"
local TORSO = "torso"
local ARMS = "arms"
local LEGS = "legs"

-- Decimal bone IDs (from hex ePedBoneId)
local BONE_ZONE = {
    -- HEAD
    [31086] = HEAD, -- SKEL_Head 0x796E
    [12844] = HEAD, -- IK_Head 0x322C
    [65068] = HEAD, -- FACIAL_facialRoot 0xFE2C
    [58331] = HEAD, -- FB_L_Brow_Out_000 0xE3DB
    [45750] = HEAD, -- FB_L_Lid_Upper_000 0xB2B6
    [25260] = HEAD, -- FB_L_Eye_000 0x62AC
    [21550] = HEAD, -- FB_L_CheekBone_000 0x542E
    [29868] = HEAD, -- FB_L_Lip_Corner_000 0x74AC
    [43536] = HEAD, -- FB_R_Lid_Upper_000 0xAA10
    [27474] = HEAD, -- FB_R_Eye_000 0x6B52
    [19336] = HEAD, -- FB_R_CheekBone_000 0x4B88
    [1356] = HEAD,  -- FB_R_Brow_Out_000 0x054C
    [11174] = HEAD, -- FB_R_Lip_Corner_000 0x2BA6
    [37193] = HEAD, -- FB_Brow_Centre_000 0x9149
    [20178] = HEAD, -- FB_UpperLipRoot_000 0x4ED2
    [61839] = HEAD, -- FB_UpperLip_000 0xF18F
    [20279] = HEAD, -- FB_L_Lip_Top_000 0x4F37
    [17719] = HEAD, -- FB_R_Lip_Top_000 0x4537
    [46240] = HEAD, -- FB_Jaw_000 0xB4A0
    [17188] = HEAD, -- FB_LowerLipRoot_000 0x4324
    [20623] = HEAD, -- FB_LowerLip_000 0x508F
    [47419] = HEAD, -- FB_L_Lip_Bot_000 0xB93B
    [49979] = HEAD, -- FB_R_Lip_Bot_000 0xC33B
    [47495] = HEAD, -- FB_Tongue_000 0xB987
    [1598] = HEAD,  -- MH_MulletRoot 0x3E73
    [41410] = HEAD, -- MH_MulletScaler 0xA1C2
    [50788] = HEAD, -- MH_Hair_Scale 0xC664
    [5749] = HEAD,  -- MH_Hair_Crown 0x1675
    [27780] = HEAD, -- FB_R_Ear_000 0x6CDF
    [25526] = HEAD, -- SPR_R_Ear 0x63B6
    [25657] = HEAD, -- FB_L_Ear_000 0x6439
    [23312] = HEAD, -- SPR_L_Ear 0x5B10

    -- NECK — GTA reports SKEL_Neck_1 / index 97 on most headshots, so treat as HEAD
    [39317] = HEAD, -- SKEL_Neck_1 0x9995 (game headshot bone)
    [24532] = HEAD, -- SKEL_Neck_2 / skull base
    [35731] = NECK, -- RB_Neck_1 0x8B93

    -- TORSO / spine / pelvis / bags / skirts torso
    [0] = TORSO,      -- SKEL_ROOT
    [11816] = TORSO,  -- SKEL_Pelvis 0x2E28
    [57597] = TORSO,  -- SKEL_Spine_Root 0xE0FD
    [23553] = TORSO,  -- SKEL_Spine0 0x5C01
    [24816] = TORSO,  -- SKEL_Spine1 0x60F0
    [24817] = TORSO,  -- SKEL_Spine2 0x60F1
    [24818] = TORSO,  -- SKEL_Spine3 0x60F2
    [53294] = TORSO,  -- SKEL_Pelvis1 0xD003
    [17916] = TORSO,  -- SKEL_PelvisRoot 0x45FC
    [38180] = TORSO,  -- SKEL_SADDLE 0x9524
    [64654] = TORSO,  -- SPR_L_Breast 0xFC8E
    [34911] = TORSO,  -- SPR_R_Breast 0x885F
    [56604] = TORSO,  -- IK_Root 0xDD1C
    [34569] = TORSO,  -- MH_L_ShoulderBladeRoot 0x8711
    [20143] = TORSO,  -- MH_L_ShoulderBlade 0x4EAF
    [14858] = TORSO,  -- MH_R_ShoulderBladeRoot 0x3A0A
    [21679] = TORSO,  -- MH_R_ShoulderBlade 0x54AF
    [44297] = TORSO,  -- BagRoot 0xAD09
    [47158] = TORSO,  -- BagPivotROOT 0xB836
    [19729] = TORSO,  -- BagPivot 0x4D11
    [43885] = TORSO,  -- BagBody 0xAB6D
    [2359] = TORSO,   -- BagBone_R 0x0937
    [2449] = TORSO,   -- BagBone_L 0x0991
    [35104] = TORSO,  -- SM_LifeSaver_Front 0x9420
    [8487] = TORSO,   -- SM_LifeSaver_Back 0x2127
    [55853] = TORSO,  -- SM_Suit_Back_Flapper 0xDA2D
    [33349] = TORSO,  -- SPR_CopRadio 0x8245
    [41166] = TORSO,  -- MH_BlushSlider 0xA0CE
    [50829] = TORSO,  -- SM_CockNBalls_ROOT 0xC67D
    [40244] = TORSO,  -- SM_CockNBalls 0x9D34
    [49118] = TORSO,  -- SPR_Gonads_ROOT 0xBFDE
    [7168] = TORSO,   -- SPR_Gonads 0x1C00

    -- ARMS (L)
    [64729] = ARMS, -- SKEL_L_Clavicle 0xFCD9
    [45509] = ARMS, -- SKEL_L_UpperArm 0xB1C5
    [61163] = ARMS, -- SKEL_L_Forearm 0xEEEB
    [18905] = ARMS, -- SKEL_L_Hand 0x49D9
    [26610] = ARMS, -- SKEL_L_Finger00 0x67F2
    [4089] = ARMS,  -- SKEL_L_Finger01 0x0FF9
    [4090] = ARMS,  -- SKEL_L_Finger02 0x0FFA
    [26611] = ARMS, -- SKEL_L_Finger10 0x67F3
    [4169] = ARMS,  -- SKEL_L_Finger11 0x1049
    [4170] = ARMS,  -- SKEL_L_Finger12 0x104A
    [26612] = ARMS, -- SKEL_L_Finger20 0x67F4
    [4185] = ARMS,  -- SKEL_L_Finger21 0x1059
    [4186] = ARMS,  -- SKEL_L_Finger22 0x105A
    [26613] = ARMS, -- SKEL_L_Finger30 0x67F5
    [4137] = ARMS,  -- SKEL_L_Finger31 0x1029
    [4138] = ARMS,  -- SKEL_L_Finger32 0x102A
    [26614] = ARMS, -- SKEL_L_Finger40 0x67F6
    [4153] = ARMS,  -- SKEL_L_Finger41 0x1039
    [4154] = ARMS,  -- SKEL_L_Finger42 0x103A
    [60309] = ARMS, -- PH_L_Hand 0xEB95
    [36029] = ARMS, -- IK_L_Hand 0x8CBD
    [61007] = ARMS, -- RB_L_ForeArmRoll 0xEE4F
    [5232] = ARMS,  -- RB_L_ArmRoll 0x1470
    [22711] = ARMS, -- MH_L_Elbow 0x58B7
    [35939] = ARMS, -- MH_L_Finger00 0x8C63
    [24504] = ARMS, -- MH_L_FingerBulge00 0x5FB8
    [35923] = ARMS, -- MH_L_Finger10 0x8C53
    [41540] = ARMS, -- MH_L_FingerTop00 0xA244
    [51082] = ARMS, -- MH_L_HandSide 0xC78A
    [10040] = ARMS, -- MH_Watch 0x2738
    [37692] = ARMS, -- MH_L_Sleeve 0x933C
    [51592] = ARMS, -- MH_L_Concertina_B 0xC988
    [51591] = ARMS, -- MH_L_Concertina_A 0xC987
    [10614] = ARMS, -- SM_L_Pouches_ROOT 0x2A02
    [19265] = ARMS, -- SM_L_Pouches 0x4B41

    -- ARMS (R)
    [10706] = ARMS, -- SKEL_R_Clavicle 0x29D2
    [40269] = ARMS, -- SKEL_R_UpperArm 0x9D4D
    [28252] = ARMS, -- SKEL_R_Forearm 0x6E5C
    [57005] = ARMS, -- SKEL_R_Hand 0xDEAD
    [58866] = ARMS, -- SKEL_R_Finger00 0xE5F2
    [64016] = ARMS, -- SKEL_R_Finger01 0xFA10
    [64017] = ARMS, -- SKEL_R_Finger02 0xFA11
    [58867] = ARMS, -- SKEL_R_Finger10 0xE5F3
    [64096] = ARMS, -- SKEL_R_Finger11 0xFA60
    [64097] = ARMS, -- SKEL_R_Finger12 0xFA61
    [58868] = ARMS, -- SKEL_R_Finger20 0xE5F4
    [64112] = ARMS, -- SKEL_R_Finger21 0xFA70
    [64113] = ARMS, -- SKEL_R_Finger22 0xFA71
    [58869] = ARMS, -- SKEL_R_Finger30 0xE5F5
    [64064] = ARMS, -- SKEL_R_Finger31 0xFA40
    [64065] = ARMS, -- SKEL_R_Finger32 0xFA41
    [58870] = ARMS, -- SKEL_R_Finger40 0xE5F6
    [64080] = ARMS, -- SKEL_R_Finger41 0xFA50
    [64081] = ARMS, -- SKEL_R_Finger42 0xFA51
    [28422] = ARMS, -- PH_R_Hand 0x6F06
    [6286] = ARMS,  -- IK_R_Hand 0x188E
    [43810] = ARMS, -- RB_R_ForeArmRoll 0xAB22
    [37119] = ARMS, -- RB_R_ArmRoll 0x90FF
    [2992] = ARMS,  -- MH_R_Elbow 0x0BB0
    [11363] = ARMS, -- MH_R_Finger00 0x2C63
    [27064] = ARMS, -- MH_R_FingerBulge00 0x69B8
    [11347] = ARMS, -- MH_R_Finger10 0x2C53
    [61259] = ARMS, -- MH_R_FingerTop00 0xEF4B
    [26875] = ARMS, -- MH_R_HandSide 0x68FB
    [37596] = ARMS, -- MH_R_Sleeve 0x92DC
    [51432] = ARMS, -- MH_R_Concertina_B 0xC8E8
    [51431] = ARMS, -- MH_R_Concertina_A 0xC8E7
    [10594] = ARMS, -- SM_R_Pouches_ROOT 0x2962
    [16705] = ARMS, -- SM_R_Pouches 0x4141

    -- LEGS (L)
    [58271] = LEGS, -- SKEL_L_Thigh 0xE39F
    [63931] = LEGS, -- SKEL_L_Calf 0xF9BB
    [14201] = LEGS, -- SKEL_L_Foot 0x3779
    [2108] = LEGS,  -- SKEL_L_Toe0 0x083C
    [33989] = LEGS, -- EO_L_Foot 0x84C5
    [26813] = LEGS, -- EO_L_Toe 0x68BD
    [65245] = LEGS, -- IK_L_Foot 0xFEDD
    [57717] = LEGS, -- PH_L_Foot 0xE175
    [46078] = LEGS, -- MH_L_Knee 0xB3FE
    [23639] = LEGS, -- RB_L_ThighRoll 0x5C57
    [4115] = LEGS,  -- MH_L_CalfBack 0x1013
    [24589] = LEGS, -- MH_L_ThighBack 0x600D
    [50199] = LEGS, -- SM_L_Skirt 0xC419
    [16562] = LEGS, -- SM_L_BackSkirtRoll 0x40B2
    [39785] = LEGS, -- SM_L_FrontSkirtRoll 0x9B69
    [7531] = LEGS,  -- SKEL_L_Toe1 0x1D6B

    -- LEGS (R)
    [51826] = LEGS, -- SKEL_R_Thigh 0xCA72
    [36864] = LEGS, -- SKEL_R_Calf 0x9000
    [52301] = LEGS, -- SKEL_R_Foot 0xCC4D
    [20781] = LEGS, -- SKEL_R_Toe0 0x512D
    [4246] = LEGS,  -- EO_R_Foot 0x1096
    [29027] = LEGS, -- EO_R_Toe 0x7163
    [35502] = LEGS, -- IK_R_Foot 0x8AAE
    [24806] = LEGS, -- PH_R_Foot 0x60E6
    [16335] = LEGS, -- MH_R_Knee 0x3FCF
    [6442] = LEGS,  -- RB_R_ThighRoll 0x192A
    [45075] = LEGS, -- MH_R_CalfBack 0xB013
    [20899] = LEGS, -- MH_R_ThighBack 0x51A3
    [30482] = LEGS, -- SM_R_Skirt 0x7712
    [49473] = LEGS, -- SM_R_BackSkirtRoll 0xC141
    [34545] = LEGS, -- SM_R_FrontSkirtRoll 0x86F1
    [45503] = LEGS, -- SKEL_R_Toe1 0xB23F
    [3515] = LEGS,  -- SM_M_BackSkirtRoll 0x0DBB
    [52667] = LEGS, -- SM_M_FrontSkirtRoll 0xCDBB
}

-- GetPedLastDamageBone often returns bone INDEX (not ID)
local BONE_INDEX_TO_ID = {
    [0] = 0,
    [11816] = 11816,
    -- Common indices (docs.fivem.net)
    [57] = 58271,  -- L thigh-ish
    [58] = 63931,
    [59] = 14201,
    [60] = 2108,
    [8] = 23553,   -- spine
    [7] = 24816,
    [6] = 24817,
    [5] = 24818,
    [4] = 11816,   -- pelvis
    [3] = 39317,   -- neck
    [1] = 0,
    [2] = 11816,
    [11] = 64729,  -- L clavicle
    [12] = 45509,
    [13] = 61163,
    [14] = 18905,
    [15] = 10706,  -- R clavicle
    [16] = 40269,
    [17] = 28252,
    [18] = 57005,
    [97] = 39317,  -- neck
    [98] = 31086,  -- head
    [99] = 12844,  -- ik head
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
    [41] = 58271,
    [42] = 63931,
    [43] = 14201,
    [44] = 2108,
    [45] = 51826,
    [46] = 36864,
    [47] = 52301,
    [48] = 20781,
}

function DeathScreenBones.NormalizeBoneId(bone)
    bone = tonumber(bone) or -1
    if bone < 0 then
        bone = bone + 65536
    end
    if bone < 0 then return -1 end
    if BONE_ZONE[bone] then return bone end
    if BONE_INDEX_TO_ID[bone] then return BONE_INDEX_TO_ID[bone] end
    return bone
end

function DeathScreenBones.ZoneFromBone(bone)
    local id = DeathScreenBones.NormalizeBoneId(bone)
    if id < 0 then return TORSO end
    local zone = BONE_ZONE[id]
    if zone then return zone end
    -- Fallback: treat unknown facial-ish high indices as head, else torso
    if id == 97 or (id >= 98 and id <= 123) then
        return HEAD
    end
    if id == 124 then
        return NECK
    end
    return TORSO
end

--- Bone ID used for GetPedBoneCoords projection per zone
function DeathScreenBones.ProjectBoneForZone(zone)
    if zone == HEAD then return 31086 end -- SKEL_Head
    if zone == NECK then return 39317 end -- SKEL_Neck_1
    if zone == ARMS then return 45509 end -- SKEL_L_UpperArm
    if zone == LEGS then return 58271 end -- SKEL_L_Thigh
    return 24818 -- SKEL_Spine3 (torso / body)
end

function DeathScreenBones.EmptyHits()
    return { head = 0, neck = 0, torso = 0, arms = 0, legs = 0 }
end

function DeathScreenBones.TotalHits(hits)
    if not hits then return 0 end
    return (hits.head or 0) + (hits.neck or 0) + (hits.torso or 0) + (hits.arms or 0) + (hits.legs or 0)
end
