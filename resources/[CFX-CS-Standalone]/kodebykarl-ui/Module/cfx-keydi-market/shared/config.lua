ConfigMarket = {
    Enabled = true,
    Debug = false,

    -- Ped-only open (ox_target). No /market command.
    OpenCommand = false,

    -- lb-phone app: live prices only (no selling)
    PhoneApp = {
        Enabled = true,
        DefaultApp = true, -- home screen, no App Store download
        Identifier = 'grim-market',
        Name = 'Grim Market',
        Description = 'Live sell prices for autofarm & raven loot. View only — sell at the market NPC.',
        Developer = 'Grim City',
    },

    -- Server rolls a new sell price per item in [minPrice, maxPrice] on this interval
    PriceUpdate = {
        IntervalMinutes = 120, -- every 2 hours
        Announce = true,
        AnnounceMessage = 'Sell Market prices have been updated! Check the market for new rates.',
        AnnounceSender = 'Sell Market',
    },

    -- NPC + blip live in cfx-keydi-utils/configs/peds.lua (server-wide ped system).
    -- Keep coords here so the server can verify the seller is at the stall.
    Locations = {
        {
            coords = vec4(162.0263, 6636.6411, 31.5562, 134.3263),
            ped = 'a_m_m_business_01',
            scenario = false,
            blip = {
                label = 'Market',
                sprite = 78,
                color = 2,
                scale = 0.8,
                shortRange = true,
                display = 4,
                category = 1,
                highDetail = true,
            },
        },
    },

    -- Sell catalog seed (copied into grim_market_items DB on first boot).
    -- Live min/max are edited from iPad Market app (owner/developer) — not only here.
    Items = {
        { item = 'orange',   label = 'Orange',   category = 'Farming', minPrice = 30, maxPrice = 80 },
        { item = 'wood',     label = 'Wood',     category = 'Lumber',  minPrice = 35, maxPrice = 85 },
        { item = 'raw_meat', label = 'Raw Meat', category = 'Hunting', minPrice = 50, maxPrice = 100 },
    },
}
