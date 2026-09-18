Config = {}

Config.ArenaName = 'Deathmatch Arena'
Config.ArenaTags = { 'Pistols', 'Safe zone', 'Public' }
Config.MaxPlayers = 32
-- Isolated from Farm / School / Turf region buckets.
Config.Bucket = 50

Config.Locker = {
    [1] = { label = '[E] Locker', pos = vec3(3213.12, 413.42, 615.7028), heading = 264.7 },
}

Config.WeaponName = 'WEAPON_PISTOL'
Config.AmmoName = 'ammo-9'
Config.AmmoAmmount = 999
Config.ReviveCooldown = 1500
-- Death recap, then ambulance revive + arena spawn
Config.DeathScreenMs = 5000

-- Kept when entering/leaving deathmatch. Empty table is NOT valid for ox_inventory:ClearInventory
-- (it skips slot sync and players walk out with the arena gun).
Config.KeepItems = {
    'money',
    'black_money',
}

-- Always stripped on leave (arena loadout).
Config.LoadoutItems = {
    'WEAPON_PISTOL',
    'ammo-9',
}

-- Arena spawn (cfx-bwd-pvp map). Stream/map files are not copied.
Config.Enter = vector4(3215.4917, 412.0584, 615.7003, 264.7095)
Config.Leave = vector4(-279.1385, -1926.8918, 29.9460, 314.7706)

-- City enter ped is unused: iPad is the join. Kept for reference.
Config.EnterPed = {
    [1] = {
        ModelName = 'ig_orleans',
        ModelPosition = vector4(-287.1443, -1920.1984, 29.9460, 321.5466),
        ModelScenario = 'WORLD_HUMAN_GUARD_STAND',
        EnableBlip = true,
    },
}

Config.ExitPed = {
    [1] = {
        ModelName = 'cs_orleans',
        ModelPosition = vector4(3215.1147, 411.3063, 615.7026, 301.9744),
        ModelScenario = 'WORLD_HUMAN_GUARD_STAND',
        EnableBlip = false,
    },
}

Config.Points = {
    vec3(3244.7351, 441.1645, 625.6199),
    vec3(3185.9851, 441.3175, 625.6207),
    vec3(3185.9736, 382.5980, 625.6198),
    vec3(3244.7175, 382.5280, 625.6204),
}

Config.Safe = {
    vec3(3211.5613, 411.2367, 615.7028),
    vec3(3212.4805, 409.6609, 615.7028),
    vec3(3213.5793, 408.4280, 615.7028),
    vec3(3216.2380, 408.2317, 615.7028),
    vec3(3217.9807, 409.0218, 615.7028),
    vec3(3219.2820, 411.7058, 615.7028),
    vec3(3218.5051, 414.1818, 615.7028),
    vec3(3216.2212, 415.5721, 615.7028),
    vec3(3214.0549, 415.5981, 615.7028),
    vec3(3211.9370, 413.5837, 615.7028),
    vec3(3211.7437, 410.7224, 615.7028),
}

Config.Thickness = 10
