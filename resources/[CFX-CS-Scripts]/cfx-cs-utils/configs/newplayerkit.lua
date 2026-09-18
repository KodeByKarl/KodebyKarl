return {
    Enabled = true,
    -- Airport NPC kit (one-time). Separate from Legion Neon/Sunrise rewards.
    Rewards = {
        { item = 'money', amount = 50000 },
        { item = 'burgershot_food1', amount = 5 },
        { item = 'water', amount = 5 },
        { item = 'phone', amount = 1 },
        { item = 'lockpick', amount = 5 },
        { item = 'reskin_card', amount = 1 },
        { item = 'new_player_card', amount = 1 },
    },
    OneTime = true,
    NotifyTitle = 'NEW PLAYER KIT',
    DistanceCheck = 5.0,
    PedCoords = vec3(-1038.838, -2730.971, 20.169),
}
