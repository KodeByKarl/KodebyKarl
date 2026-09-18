Config = {}

Config.Debug = false
Config.HireDistance = 5.0
Config.MaxTransfer = 1000000

--[[
    Gang definitions used by kodebykarl-gangsystem.
    Keys must match ESXShared.Gangs and cfx-keydi-society GangAccounts.
]]
Config.Gangs = {
    deuscartel = {
        label = 'DEUS CARTEL',
        -- Brown brand color (markers / UI)
        color = { r = 139, g = 90, b = 43 },
        blip = {
            enabled = true,
            sprite = 84,
            colour = 21, -- brown
            scale = 0.5, -- fixed like robbery map blips
            label = 'DEUS CARTEL',
        },
        grades = {
            { grade = 0, name = 'member', label = 'Member' },
            { grade = 1, name = 'soldier', label = 'Soldier' },
            { grade = 2, name = 'lieutenant', label = 'Lieutenant' },
            { grade = 3, name = 'boss', label = 'Boss', isboss = true },
        },
        society = 'society_deuscartel',
        stash = {
            slots = 100,
            maxWeight = 500000,
            bossSlots = 80,
            bossMaxWeight = 400000,
            privateSlots = 50,
            privateMaxWeight = 200000,
        },
        vehicle = {
            model = 'sultan',
            platePrefix = 'DEUS',
        },
        -- vector4(x, y, z, heading)
        locations = {
            bossStash = vector4(-1535.4612, -581.0501, 25.7078, 222.4925),
            shareStash = vector4(-1539.0490, -578.9200, 25.7077, 127.9400),
            clothing = vector4(-1537.5172, -574.1053, 25.7079, 313.1573),
            gunCrafting = vector4(-1557.0992, -568.8114, 25.7078, 40.8447),
            pressE = vector4(-1539.6759, -560.8541, 25.7077, 224.0734),
            privateStash = vector4(-1537.1360, -581.7250, 25.7078, 144.6485),
        },
    },
}

--[[
    Gang car claim ped (one car per player, ped-only take-out/store).
    Leaving / switching gangs permanently bans future claims.
]]
Config.ClaimPed = {
    enabled = true,
    model = 'g_m_y_mexgoon_02',
    coords = vector4(-1549.2260, -571.6039, 25.7079, 210.2311),
    -- Where the claimed car spawns when taken out
    spawn = vector4(-1545.50, -574.80, 25.71, 210.0),
    interactDistance = 2.5,
    requiredPlaytime = 2 * 60 * 60, -- 2 hours (seconds)
    platePrefix = 'GANG',
}
