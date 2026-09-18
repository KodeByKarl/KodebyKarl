return {
    Enabled = true,
    NotifyTitle = 'PLAYTIME REWARD',
    DistanceCheck = 5.0,
    PedCoords = vec3(-260.5113, -965.4332, 31.2244),

    -- Legion Playtime Reward NPC:
    -- neon    = immediate Neon + starter pack (stash_car + food box)
    -- sunrise = separate 6h playtime car only (no starter pack)
    -- Airport New Player Kit stays on its own ped (money/food/phone/etc).
    Rewards = {
        neon = {
            Label = 'Pfister Neon + Starter Pack',
            RequiredSeconds = 0,
            VehicleModel = 'neon',
            GarageId = 'Legion Square',
            NicknamePrefix = 'STARTER-NEON',
            OneTime = true,
            Items = {
                { item = 'stash_car', amount = 1 },
                { item = 'food_drinks_box', amount = 1 }, -- 5x grim_tea + 5x grim_peas
            },
        },
        sunrise = {
            Label = 'Sunrise',
            RequiredSeconds = 6 * 60 * 60, -- 6 hours total playtime
            VehicleModel = 'sunrise1',
            GarageId = 'Legion Square',
            NicknamePrefix = 'PLAYTIME-SUNRISE',
            OneTime = true,
        },
    },
}
