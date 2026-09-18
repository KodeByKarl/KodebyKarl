ConfigVip = ConfigVip or {}

ConfigVip.Debug = false

--[[
  Tier features (connected systems):
    pedMenu         → /reskin /ped /pedmenu via illenium-appearance (VIP 2 & 3)
    welcomeBanner   → /wcb self-edit welcome banner with audio
    grindBonus      → bonus amount added to all grindings (+5 / +10 / +15)
]]
ConfigVip.Tiers = {
    vip1 = {
        label = "VIP 1",
        pedMenu = false,
        welcomeBanner = true,
        grindBonus = 5,
        perks = {
            "+ 5 ALL GRINDINGS",
            "DISCORD ROLE",
            "WELCOME BANNER WITH AUDIO",
        },
    },
    vip2 = {
        label = "IMMORTAL",
        pedMenu = true,
        welcomeBanner = true,
        grindBonus = 10,
        perks = {
            "/RESKIN CHARACTER LOOK",
            "1 MONTH ACCESS /PED",
            "+ 10 ALL GRINDINGS",
            "WELCOME BANNER WITH AUDIO",
            "DISCORD ROLE",
            "VIP CAR  ( CARDEALER)",
        },
    },
    vip3 = {
        label = "SUPREME",
        pedMenu = true,
        welcomeBanner = true,
        grindBonus = 15,
        perks = {
            "/RESKIN CHARACTER LOOK",
            "1 MONTH ACCESS /PED",
            "+ 15 ALL GRINDINGS",
            "WELCOME BANNER WITH AUDIO",
            "1 EXCLUSIVE CAR  OWN SCRIPT",
            "DEATH CAM AUDIO/Banner",
            "1 FREE CLOTHES w/ 2 variant",
            "DISCORD ROLE",
        },
    },
}

-- Staff groups that can Set / Edit / Revoke VIP from Control Center
ConfigVip.StaffGroups = {
    owner = true,
    developer = true,
}

-- ESX groups that can open /pedmenu without VIP 2+
ConfigVip.PedMenuGroups = {
    developer = true,
    owner = true,
    superadmin = true,
    admin = true,
}
