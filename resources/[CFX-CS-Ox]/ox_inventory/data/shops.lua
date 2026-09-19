-- Shared stock for convenience stores (24/7, LTD, Robs Liquor)
local ConvenienceStock = {
	-- Food & drinks
	{ name = 'burger', price = 1500 },
	{ name = 'water', price = 1500 },
	{ name = 'cola', price = 1500 },
	{ name = 'sprunk', price = 1500 },
	{ name = 'mustard', price = 1500 },
	-- Cooking / ingredients
	{ name = 'sugar', price = 250 },
	{ name = 'dough', price = 250 },
	{ name = 'butter', price = 250 },
	{ name = 'flour', price = 250 },
	{ name = 'cream', price = 250 },
	{ name = 'milk', price = 250 },
	{ name = 'bottle_milk', price = 300 },
	{ name = 'bun', price = 150 },
	{ name = 'burger_patty', price = 450 },
	{ name = 'lettuce', price = 180 },
	{ name = 'tomato', price = 180 },
	{ name = 'soy_sauce', price = 150 },
	{ name = 'cheese', price = 150 },
	{ name = 'raw_chicken', price = 450 },
	{ name = 'rice', price = 450 },
	{ name = 'potato', price = 120 },
	{ name = 'carrot', price = 120 },
	{ name = 'onion', price = 120 },
	{ name = 'honey', price = 200 },
	{ name = 'cocoa', price = 200 },
	-- Essentials
	{ name = 'phone', price = 1500 },
	{ name = 'radio', price = 1500 },
	{ name = 'lockpick', price = 1500 },
	{ name = 'paperbag', price = 5 },
	{ name = 'parachute', price = 5000 },
	{ name = 'WEAPON_FLASHLIGHT', price = 500 },
}

return {
	-- All convenience store locations (24/7, LTD Gasoline, Robs Liquor)
	General = {
		name = '24/7 Supermarket',
		blip = {
			id = 59, colour = 69, scale = 0.8
		},
		inventory = ConvenienceStock,
		locations = {
			-- 24/7 Locations
			vec3(25.7, -1347.3, 29.49),           -- Strawberry (Innocence Blvd)
			vec3(373.55, 325.56, 103.56),         -- Downtown Vinewood (Clinton Ave)
			vec3(-3241.47, 1001.14, 12.83),       -- Chumash (Barbareno Rd)
			vec3(-3038.71, 585.9, 7.9),           -- Banham Canyon (Ineseno Rd)
			vec3(1728.66, 6414.16, 35.03),        -- Paleto / Mt Chiliad (Senora Fwy)
			vec3(547.79, 2671.79, 42.15),         -- Harmony (Route 68)
			vec3(1961.48, 3739.96, 32.34),        -- Sandy Shores (Niland Ave)
			vec3(1697.99, 4924.4, 42.06),         -- Grapeseed Main St
			vec3(2679.25, 3280.12, 55.24),        -- Grand Senora Desert (Senora Fwy)
			vec3(2557.94, 382.05, 108.62),        -- Tataviam (Palomino Fwy)
			vec3(-676.47, 5840.17, 17.44),        -- Bayview Store (Procopio / Paleto Forest)
			-- LTD Gasoline Locations
			vec3(1163.37, -323.80, 69.21),        -- Mirror Park (West Mirror Drive)
			vec3(-707.34, -913.75, 19.22),        -- Little Seoul (Palomino Ave)
			vec3(-47.35, -1757.62, 29.42),        -- Davis (Davis Ave)
			vec3(-1820.52, 792.59, 138.11),       -- Richman Glen (Banham Canyon Dr)
			-- Robs Liquor Locations
			vec3(1135.808, -982.281, 46.415),     -- Murrieta Heights (El Rancho Blvd)
			vec3(-1222.915, -906.983, 12.326),    -- Vespucci (San Andreas Ave)
			vec3(-1487.553, -379.107, 40.163),    -- Morningwood (Prosperity St)
			vec3(-2968.243, 390.910, 15.043),     -- Banham Canyon (Great Ocean Hwy)
			vec3(1166.024, 2708.930, 38.157),     -- Route 68 (Grand Senora Desert)
			vec3(1982.377, 3053.414, 47.215),     -- Panorama Dr (Grand Senora Desert)
			vec3(-160.86, 6321.47, 31.59),        -- Paleto Bay (Pryite Ave)
		},
		targets = {
			-- 24/7 Targets
			{ loc = vec3(25.06, -1347.32, 29.5), length = 0.7, width = 0.5, heading = 0.0, minZ = 29.5, maxZ = 29.9, distance = 1.5 },
			{ loc = vec3(373.13, 326.29, 103.57), length = 0.6, width = 0.5, heading = 345.0, minZ = 103.57, maxZ = 103.97, distance = 1.5 },
			{ loc = vec3(-3242.2, 1000.58, 12.83), length = 0.6, width = 0.6, heading = 175.0, minZ = 12.83, maxZ = 13.23, distance = 1.5 },
			{ loc = vec3(-3039.18, 585.13, 7.91), length = 0.6, width = 0.5, heading = 15.0, minZ = 7.91, maxZ = 8.31, distance = 1.5 },
			{ loc = vec3(1728.39, 6414.95, 35.04), length = 0.6, width = 0.6, heading = 65.0, minZ = 35.04, maxZ = 35.44, distance = 1.5 },
			{ loc = vec3(548.5, 2671.25, 42.16), length = 0.6, width = 0.5, heading = 10.0, minZ = 42.16, maxZ = 42.56, distance = 1.5 },
			{ loc = vec3(1960.54, 3740.28, 32.34), length = 0.6, width = 0.5, heading = 120.0, minZ = 32.34, maxZ = 32.74, distance = 1.5 },
			{ loc = vec3(1698.37, 4923.43, 42.06), length = 0.5, width = 0.5, heading = 235.0, minZ = 42.06, maxZ = 42.46, distance = 1.5 },
			{ loc = vec3(2678.29, 3279.94, 55.24), length = 0.6, width = 0.5, heading = 330.0, minZ = 55.24, maxZ = 55.64, distance = 1.5 },
			{ loc = vec3(2557.19, 381.4, 108.62), length = 0.6, width = 0.5, heading = 0.0, minZ = 108.62, maxZ = 109.02, distance = 1.5 },
			{ loc = vec3(-676.47, 5840.17, 17.44), length = 0.8, width = 0.8, heading = 0.0, minZ = 17.0, maxZ = 18.2, distance = 2.0 },
			-- LTD Gasoline Targets
			{ loc = vec3(1164.21, -322.92, 69.21), length = 0.6, width = 0.5, heading = 100.0, minZ = 69.21, maxZ = 69.61, distance = 1.5 },
			{ loc = vec3(-706.67, -913.66, 19.22), length = 0.6, width = 0.5, heading = 90.0, minZ = 19.22, maxZ = 19.62, distance = 1.5 },
			{ loc = vec3(-47.42, -1758.67, 29.42), length = 0.6, width = 0.6, heading = 50.0, minZ = 29.42, maxZ = 29.82, distance = 1.5 },
			{ loc = vec3(-1820.14, 794.06, 138.11), length = 0.6, width = 0.5, heading = 132.0, minZ = 138.11, maxZ = 138.51, distance = 1.5 },
			-- Robs Liquor Targets
			{ loc = vec3(1134.9, -982.34, 46.41), length = 0.5, width = 0.5, heading = 96.0, minZ = 46.4, maxZ = 46.8, distance = 1.5 },
			{ loc = vec3(-1222.33, -907.82, 12.43), length = 0.6, width = 0.5, heading = 32.7, minZ = 12.3, maxZ = 12.7, distance = 1.5 },
			{ loc = vec3(-1486.67, -378.46, 40.26), length = 0.6, width = 0.5, heading = 133.77, minZ = 40.1, maxZ = 40.5, distance = 1.5 },
			{ loc = vec3(-2967.0, 390.9, 15.14), length = 0.7, width = 0.5, heading = 85.23, minZ = 15.0, maxZ = 15.4, distance = 1.5 },
			{ loc = vec3(1165.95, 2710.20, 38.26), length = 0.6, width = 0.5, heading = 178.84, minZ = 38.1, maxZ = 38.5, distance = 1.5 },
			{ loc = vec3(1982.377, 3053.414, 47.215), length = 0.7, width = 0.7, heading = 0.0, minZ = 46.8, maxZ = 48.0, distance = 2.0 },
			{ loc = vec3(-160.86, 6321.47, 31.59), length = 0.7, width = 0.7, heading = 315.0, minZ = 31.2, maxZ = 32.4, distance = 2.0 },
		}
	},


	-- DOJ civic shop — purchase fees deposit to society_doj (see cfx-keydi-modules buyItem hook)
	DOJ = {
		name = 'DOJ Shop',
		inventory = {
			{ name = 'identification', price = 250000 },
			{ name = 'change_name', price = 5000000 },
			{ name = 'driver_license', price = 150000, metadata = { issuedBy = 'DOJ' } },
		},
		locations = {
			vec3(56.9408, -424.4329, 39.1436),
		},
		targets = {
			{ loc = vec3(56.9408, -424.4329, 39.1436), length = 1.0, width = 1.2, heading = 72.5375, minZ = 38.1, maxZ = 40.4, distance = 2.0 },
		}
	},

	PoliceArmoury = {
		name = 'Police Armoury',
		groups = { ['police'] = 0 },
		inventory = {
			{ name = 'police_vitamins', price = 2, currency = 'grimpolicecoin' },
			{ name = 'police_drink', price = 2, currency = 'grimpolicecoin' },
			{ name = 'police_vest', price = 5, currency = 'grimpolicecoin' },
			{ name = 'riot_shield', price = 8, currency = 'grimpolicecoin' },
			{ name = 'WEAPON_FLASHLIGHT', price = 1, currency = 'grimpolicecoin' },
			{ name = 'WEAPON_NIGHTSTICK', price = 1, currency = 'grimpolicecoin' },
			{ name = 'WEAPON_STUNGUN', price = 5, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_BZGAS', price = 3, currency = 'grimpolicecoin' },
			{ name = 'WEAPON_HEAVYPISTOL', price = 75, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PISTOL_MK2', price = 75, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_SMG', price = 150, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_SMG_MK2', price = 150, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_COMBATPDW', price = 150, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PUMPSHOTGUN', price = 25, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_PUMPSHOTGUN_MK2', price = 30, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_SPECIALCARBINE', price = 150, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_SPECIALCARBINE_MK2', price = 150, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'WEAPON_CARBINERIFLE_MK2', price = 150, currency = 'grimpolicecoin', metadata = { registered = true, serial = 'POL' } },
			{ name = 'pd_ammo_box_9', price = 10, currency = 'grimpolicecoin' },
			{ name = 'pd_ammo_box_rifle', price = 15, currency = 'grimpolicecoin' },
			{ name = 'pd_ammo_box_rifle2', price = 15, currency = 'grimpolicecoin' },
			{ name = 'pd_ammo_box_shotgun', price = 12, currency = 'grimpolicecoin' },
			{ name = 'pd_ammo_box_45', price = 10, currency = 'grimpolicecoin' },
			{ name = 'at_flashlight', price = 5, currency = 'grimpolicecoin' },
			{ name = 'at_suppressor_light', price = 5, currency = 'grimpolicecoin' },
			{ name = 'at_suppressor_heavy', price = 5, currency = 'grimpolicecoin' },
			{ name = 'at_grip', price = 5, currency = 'grimpolicecoin' },
			{ name = 'at_barrel', price = 5, currency = 'grimpolicecoin' },
			{ name = 'at_clip_extended_pistol', price = 5, currency = 'grimpolicecoin' },
			{ name = 'at_clip_extended_smg', price = 5, currency = 'grimpolicecoin' },
			{ name = 'at_clip_extended_shotgun', price = 5, currency = 'grimpolicecoin' },
			{ name = 'at_clip_extended_rifle', price = 5, currency = 'grimpolicecoin' }
		}, locations = {
			vec3(71.5360, -390.2930, 41.6247)
		}, targets = {
			{ loc = vec3(71.5360, -390.2930, 41.6247), length = 1.0, width = 2.0, heading = 249.4090, minZ = 40.6, maxZ = 43.1, distance = 2.5 }
		}
	},

	SheriffArmoury = {
		name = 'Sheriff Armoury',
		groups = shared.police,
		inventory = {
			{ name = 'sheriff_vitamins', price = 2, currency = 'sheriff_coin' },
			{ name = 'sheriff_drink', price = 2, currency = 'sheriff_coin' },
			{ name = 'sheriff_vest', price = 5, currency = 'sheriff_coin' },
			{ name = 'armour', price = 5, currency = 'sheriff_coin' },
			{ name = 'WEAPON_FLASHLIGHT', price = 1, currency = 'sheriff_coin' },
			{ name = 'WEAPON_NIGHTSTICK', price = 1, currency = 'sheriff_coin' },
			{ name = 'WEAPON_STUNGUN', price = 5, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_BZGAS', price = 3, currency = 'sheriff_coin' },
			{ name = 'WEAPON_HEAVYPISTOL', price = 75, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_PISTOL_MK2', price = 75, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_SMG', price = 150, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_SMG_MK2', price = 150, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_COMBATPDW', price = 150, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_PUMPSHOTGUN', price = 25, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_PUMPSHOTGUN_MK2', price = 30, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_SPECIALCARBINE', price = 150, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_SPECIALCARBINE_MK2', price = 150, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'WEAPON_CARBINERIFLE_MK2', price = 150, currency = 'sheriff_coin', metadata = { registered = true, serial = 'BCSO' } },
			{ name = 'sheriff_ammo_box_9', price = 10, currency = 'sheriff_coin' },
			{ name = 'sheriff_ammo_box_rifle', price = 15, currency = 'sheriff_coin' },
			{ name = 'sheriff_ammo_box_rifle2', price = 15, currency = 'sheriff_coin' },
			{ name = 'sheriff_ammo_box_shotgun', price = 12, currency = 'sheriff_coin' },
			{ name = 'sheriff_ammo_box_45', price = 10, currency = 'sheriff_coin' },
			{ name = 'at_flashlight', price = 3, currency = 'sheriff_coin' },
			{ name = 'radio', price = 5, currency = 'sheriff_coin' },
			{ name = 'at_scope_medium', price = 5, currency = 'sheriff_coin' },
			{ name = 'at_scope_large', price = 5, currency = 'sheriff_coin' },
			{ name = 'at_suppressor_light', price = 8, currency = 'sheriff_coin' },
			{ name = 'at_suppressor_heavy', price = 10, currency = 'sheriff_coin' },
			{ name = 'at_grip', price = 5, currency = 'sheriff_coin' },
			{ name = 'at_barrel', price = 5, currency = 'sheriff_coin' },
			{ name = 'at_clip_extended_pistol', price = 5, currency = 'sheriff_coin' },
			{ name = 'at_clip_extended_smg', price = 6, currency = 'sheriff_coin' },
			{ name = 'at_clip_extended_shotgun', price = 6, currency = 'sheriff_coin' },
			{ name = 'at_clip_extended_rifle', price = 7, currency = 'sheriff_coin' }
		}, locations = {
			vec3(1891.7761, 3660.1177, 34.1130)
		}, targets = {
			{ loc = vec3(1891.7761, 3660.1177, 34.1130), length = 1.0, width = 2.0, heading = 178.0177, minZ = 33.1, maxZ = 35.5, distance = 2.5 }
		}
	},

	Medicine = {
		name = 'EMS Shop',
		groups = {
			['ambulance'] = 0,
			['pambulance'] = 0,
			['sambulance'] = 0,
		},
		inventory = {
			{ name = 'ems_medikit', price = 15, currency = 'grimemscoin' },
			{ name = 'bandage', price = 10, currency = 'grimemscoin' },
			{ name = 'gauze', price = 10, currency = 'grimemscoin' },
		}, locations = {
			vec3(-1048.1884, -1371.6355, 5.9474), -- City
			vec3(-248.9792, 6320.2134, 32.4270), -- Paleto
			vec3(1838.1077, 3623.6799, 34.4751), -- Sandy
		}, targets = {
			{ loc = vec3(-1048.1884, -1371.6355, 5.9474), length = 1.0, width = 1.5, heading = 182.1223, minZ = 4.9, maxZ = 7.5, distance = 2.5 },
			{ loc = vec3(-248.9792, 6320.2134, 32.4270), length = 1.0, width = 1.5, heading = 321.9169, minZ = 31.4, maxZ = 34.0, distance = 2.5 },
			{ loc = vec3(1838.1077, 3623.6799, 34.4751), length = 1.0, width = 1.5, heading = 27.6548, minZ = 33.4, maxZ = 36.0, distance = 2.5 },
		}
	},

	MechanicStore = {
		name = 'Store',
		groups = { ['mechanic'] = 0 },
		inventory = {
			-- Tools
			{ name = 'duct_tape', price = 1500 },
			{ name = 'obd_scanner', price = 1500 },
			{ name = 'jumpstarter_pack', price = 1500 },
			{ name = 'tire_plug_kit', price = 1500 },
			{ name = 'ceramic_coating', price = 1500 },

			-- Performance & Cosmetics
			{ name = 'performance_part', price = 1500 },
			{ name = 'cosmetic_part', price = 1500 },
			{ name = 'stancing_kit', price = 1500 },
			{ name = 'respray_kit', price = 1500 },
			{ name = 'vehicle_wheels', price = 1500 },
			{ name = 'lighting_controller', price = 1500 },
			{ name = 'tyre_smoke_kit', price = 1500 },
			{ name = 'bulletproof_tyres', price = 1500 },
			{ name = 'extras_kit', price = 1500 },

			-- Engines & Drivetrain
			{ name = 'i4_engine', price = 1500 },
			{ name = 'v6_engine', price = 1500, grade = 3 },
			{ name = 'v8_engine', price = 1500, grade = 3 },
			{ name = 'v12_engine', price = 1500, grade = 3 },
			{ name = 'turbocharger', price = 1500 },
			{ name = 'awd_drivetrain', price = 1500 },
			{ name = 'rwd_drivetrain', price = 1500 },
			{ name = 'fwd_drivetrain', price = 1500 },
			{ name = 'slick_tyres', price = 1500 },
			{ name = 'semi_slick_tyres', price = 1500 },
			{ name = 'offroad_tyres', price = 1500 },
			{ name = 'drift_tuning_kit', price = 1500 },
			{ name = 'ceramic_brakes', price = 1500 },

			-- Servicing
			{ name = 'engine_oil', price = 1500 },
			{ name = 'spark_plug', price = 1500 },
			{ name = 'clutch_replacement', price = 1500 },
			{ name = 'air_filter', price = 1500 },
			{ name = 'suspension_parts', price = 1500 },
			{ name = 'tyre_replacement', price = 1500 },
			{ name = 'brakepad_replacement', price = 1500 },
			{ name = 'ev_motor', price = 1500 },
			{ name = 'ev_battery', price = 1500 },
			{ name = 'ev_coolant', price = 1500 },

			-- Nitrous
			{ name = 'nitrous_install_kit', price = 1500, grade = 3 },
			{ name = 'nitrous_bottle', price = 1500, grade = 3 },
			{ name = 'empty_nitrous_bottle', price = 1500, grade = 3 },
		},
		locations = {
			vec3(2714.6396, 3493.7002, 55.9651)
		},
		targets = {
			{ loc = vec3(2714.6396, 3493.7002, 55.9651), length = 1.0, width = 1.5, heading = 342.4746, minZ = 54.9, maxZ = 57.5, distance = 2.5 }
		}
	},

	WeedFarmShop = {
		name = 'Weed Farm Shop',
		inventory = {
			{ name = 'rolling_paper', price = 250 },
			{ name = 'paper_bags', price = 500 },
			{ name = 'zipper_bag', price = 250 },
			{ name = 'illegal_phone', price = 1500 },
		}, locations = {
			vec3(2224.7139, 5604.8462, 54.9226)
		}, targets = {

		}
	},

	YouTool = {
		name = 'YouTool',
		blip = {
			id = 402, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'weapon_battleaxe', price = 250 },
			{ name = 'trowel', price = 1500 },
			{ name = 'lockpick', price = 1500 },
		}, locations = {
			vec3(153.3959, 6645.4497, 31.5720)
		}, targets = {
			{ loc = vec3(153.3959, 6645.4497, 31.5720), length = 1.0, width = 1.5, heading = 141.7415, minZ = 30.57, maxZ = 33.57, distance = 2.5 }
		}
	},

	BlackMarketArms = {
		name = 'Black Market (Arms)',
		inventory = {
			{ name = 'WEAPON_DAGGER', price = 1500, metadata = { registered = false }, currency = 'black_money' },
			{ name = 'WEAPON_CERAMICPISTOL', price = 2500, metadata = { registered = false }, currency = 'black_money' },
			{ name = 'at_suppressor_light', price = 1000, currency = 'black_money' },
			{ name = 'ammo-box2', price = 50000, currency = 'black_money' },
			{ name = 'ammo-box3', price = 50000, currency = 'black_money' },
			{ name = 'ammo-box1', price = 50000, currency = 'black_money' },
			{ name = 'gun_blueprint_glock22', price = 100000, currency = 'black_money' },
		}, locations = {
			vec3(171.3619, 2221.2034, 90.8033)
		}, targets = {
			{ loc = vec3(171.3619, 2221.2034, 90.8033), length = 1.0, width = 1.5, heading = 60.0994, minZ = 89.80, maxZ = 92.80, distance = 2.5 }
		}
	},

	SpectreAmmu = {
		name = 'Spectre Ammu',
		groups = { ['spectreammu'] = 0 },
		inventory = {
			{ name = 'WEAPON_DEAGLE', price = 25000 },
			{ name = 'WEAPON_PISTOL', price = 15000 },
			{ name = 'WEAPON_MILITARYRIFLE', price = 50000 },
			{ name = 'ammo-box1', price = 5000 },
			{ name = 'ammo-box2', price = 7500 },
			{ name = 'ammo-box3', price = 10000 },
		},
		locations = {
			vec3(-1304.6237, -397.0958, 36.6957),
		},
		targets = {
			{ loc = vec3(-1304.6237, -397.0958, 36.6957), length = 1.0, width = 1.5, heading = 164.9064, minZ = 35.69, maxZ = 38.0, distance = 2.5 },
		},
	},

	VendingMachineDrinks = {
		name = 'Vending Machine',
		inventory = {
			{ name = 'water', price = 10 },
			{ name = 'cola', price = 10 },
		},
		model = {
			`prop_vend_soda_02`, `prop_vend_fridge01`, `prop_vend_water_01`, `prop_vend_soda_01`
		}
	}
}
