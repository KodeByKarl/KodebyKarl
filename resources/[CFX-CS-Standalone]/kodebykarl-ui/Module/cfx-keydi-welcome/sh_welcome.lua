ConfigWelcome = {
	serverName = "Grim City",
	home = {
		intro = "We're glad to have you back on the server. Take a moment to review the essentials below before you continue your journey in Los Santos.",
		points = {
			"Don't forget to read our server rules — they keep the community fair and fun for everyone.",
			"Respect other players and staff at all times, both in-character and out-of-character.",
			"Use /report or the appropriate channels if you need help or want to report an issue.",
			"Check Server Updates for the latest changes, fixes, and new features.",
		},
	},
	links = {
		discord = {
			label = "discord.gg/JWZ9YWPB",
			url = "https://discord.gg/JWZ9YWPB",
		},
		website = nil,
		praryo = {
			label = "Keydi",
			url = nil,
		},
	},
	-- Edit this list to post new changelogs (Welcome → Server Updates + Modules → Patch Notes)
	updates = {
		{
			version = "v1.1.0",
			date = "September 6, 2026",
			title = "Jobs Rebrand, Live Leaderboards & Campus Portal",
			tag = "Major Update",
			notes = {
				"Live iPad Leaderboards — Turfwar (gang claim wins), Traphouse (K/D/KDA), PvP arena stats, Party team K/D/KDA, and citywide Top Player. Mock rows removed; boards fill as you play.",
				"University Campus Portal rework — brighter tablet UI, avatar profile dropdown, readable text on FiveM CEF (no more white-on-white).",
				"Job resources renamed — kodebykarl-ambulance, kodebykarl-business, kodebykarl-police (old cfx-* folders replaced).",
				"Robbery merge — cfx-cs-robbery + cfx-cs-interior combined into kodebykarl-robbery with interior shells included.",
				"Business crafting hardened — server-owned recipes only (no client item/money exploits). World cashier/boss menus removed.",
				"iPad Business Boss app — society funds, sales chart, hire/fire/grades, invoice logs for UWU / EM / Taco / MBOTG / Burgershot bosses.",
				"Discord log spam cleaned — ambulance, police, prison, lockscript, and gang no longer dump channel IDs on every restart.",
			},
		},
		{
			version = "v1.0.31",
			date = "September 5, 2026",
			title = "PD / EMS Shops, Melee Decay & Clothing Coins",
			tag = "Feature",
			notes = {
				"Police store, stashes, evidence locker, firing-squad coins, and clothing system items configured.",
				"EMS / PD ox_inventory shops, stashes, custom items, and grinding activities updated.",
				"All melee weapons now last 3 days (4320 minutes) with durability decay.",
				"Death Recap removed from Module Control menu.",
				"Chat text wrapping scoped so module cards no longer stretch.",
			},
		},
		{
			version = "v1.0.30",
			date = "September 5, 2026",
			title = "iPad Apps, VIP, Gang System & Regions",
			tag = "Major Update",
			notes = {
				"Apple-style iPad shell with Dynamic Island — Party, PvP, Leaderboards, Economy, Police Boss / MDT, University, and more.",
				"VIP system, death recap, and zone-colored damage indicators added.",
				"Playtime shop, society module, and Grim autofarm HUD shipped.",
				"kodebykarl-gangsystem — bases, stashes, claim car, and Discord hire hooks.",
				"Server Locations reworked into Regions (farm / school / turf split).",
				"TrapHouse — secured redzone resource with 15-minute rotating zones and sleek TextUI.",
				"Turf War — strict gang requirement, claim flow, and compact chat templates.",
			},
		},
	},
}

return ConfigWelcome
