return {
    -- Only these jobs can use the listed consumables and pistols.
    jobs = {
        police = true,
        sheriff = true,
    },

    -- Department consumables. Citizens cannot use these.
    consumables = {
        police_vitamins = true,
        police_drink = true,
        police_vest = true,
        police_bandage = true,
        pd_ammo_box_9 = true,
        pd_ammo_box_rifle = true,
        pd_ammo_box_rifle2 = true,
        pd_ammo_box_shotgun = true,
        pd_ammo_box_45 = true,
        riot_shield = true,
        sheriff_vitamins = true,
        sheriff_drink = true,
        sheriff_vest = true,
        sheriff_bandage = true,
        sheriff_ammo_box_9 = true,
        sheriff_ammo_box_rifle = true,
        sheriff_ammo_box_rifle2 = true,
        sheriff_ammo_box_shotgun = true,
        sheriff_ammo_box_45 = true,
    },

    -- Armoury sidearms. Locked to police / sheriff even if stolen or given.
    pistols = {
        WEAPON_HEAVYPISTOL = true,
        WEAPON_PISTOL_MK2 = true,
    },

    notifyTitle = 'DEPARTMENT',
    notifyMessage = 'Only Police and Sheriff can use this.',
    notifyCooldown = 4000,
}
