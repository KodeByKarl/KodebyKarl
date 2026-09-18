--[[
    Gun Trade-In Shop (Ammu-Nation)
    Trade 1 firearm → random 1–5 gun crafting materials from items.lua
]]

return {
    label = 'Gun Trade-In',
    coords = vec4(22.2645, -1106.7292, 29.7970, 159.7594),
    interactDistance = 2.5,
    cooldown = 3,

    -- Random reward count per traded gun
    minParts = 1,
    maxParts = 5,

    -- Existing items.lua materials used for gun crafting / scrap
    parts = {
        'copper',
        'iron',
        'aluminum',
        'steel',
        'plastic',
        'rubber',
        'gunpowder',
        'ammo_shells',
        'gun_blueprint_pistol',
        'gun_blueprint_glock22',
        'gun_blueprint_deagle',
        'gun_blueprint_appistol',
        'gun_blueprint_assaultrifle',
        'gun_blueprint_smg',
    },

    -- Never accept these (melee / tools / less-lethal / throwables)
    blockedWeapons = {
        WEAPON_UNARMED = true,
        WEAPON_STUNGUN = true,
        WEAPON_STUNGUN_MP = true,
        WEAPON_TASER = true,
        WEAPON_FLASHLIGHT = true,
        WEAPON_NIGHTSTICK = true,
        WEAPON_FIREEXTINGUISHER = true,
        WEAPON_PETROLCAN = true,
        WEAPON_HAZARDCAN = true,
        WEAPON_FERTILIZERCAN = true,
        WEAPON_SNOWBALL = true,
        WEAPON_BALL = true,
        WEAPON_FLARE = true,
        WEAPON_FLAREGUN = true,
        WEAPON_KNIFE = true,
        WEAPON_BAT = true,
        WEAPON_CROWBAR = true,
        WEAPON_GOLFCLUB = true,
        WEAPON_BOTTLE = true,
        WEAPON_DAGGER = true,
        WEAPON_HATCHET = true,
        WEAPON_MACHETE = true,
        WEAPON_SWITCHBLADE = true,
        WEAPON_BATTLEAXE = true,
        WEAPON_POOLCUE = true,
        WEAPON_WRENCH = true,
        WEAPON_HAMMER = true,
        WEAPON_KNUCKLE = true,
        WEAPON_STONE_HATCHET = true,
        WEAPON_MOLOTOV = true,
        WEAPON_GRENADE = true,
        WEAPON_STICKYBOMB = true,
        WEAPON_PROXMINE = true,
        WEAPON_PIPEBOMB = true,
        WEAPON_BZGAS = true,
        WEAPON_SMOKEGRENADE = true,
        WEAPON_FIREWORK = true,
        WEAPON_SNOWLAUNCHER = true,
        WEAPON_METALDETECTOR = true,
        WEAPON_GADGETPISTOL = true,
    },

    -- Refuse PD / BCSO armoury-issued guns (serial metadata)
    blockPoliceSerial = true,
    policeSerials = {
        POL = true,
        BCSO = true,
    },

    progress = {
        duration = 4500,
        label = 'Trading in firearm…',
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a',
            flag = 49,
        },
    },
}
