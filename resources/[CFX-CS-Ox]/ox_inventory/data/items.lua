return {
	['testburger'] = {
		label = 'Test Burger',
		weight = 220,
		degrade = 60,
		client = {
			image = 'burger_chicken.png',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			export = 'ox_inventory_examples.testburger'
		},
		server = {
			export = 'ox_inventory_examples.testburger',
			test = 'what an amazingly delicious burger, amirite?'
		},
		buttons = {
			{
				label = 'Lick it',
				action = function(slot)
					print('You licked the burger')
				end
			},
			{
				label = 'Squeeze it',
				action = function(slot)
					print('You squeezed the burger :(')
				end
			},
			{
				label = 'What do you call a vegan burger?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('A misteak.')
				end
			},
			{
				label = 'What do frogs like to eat with their hamburgers?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('French flies.')
				end
			},
			{
				label = 'Why were the burger and fries running?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('Because they\'re fast food.')
				end
			}
		},
		consume = 0.3
	},

	['bandage'] = {
		label = 'Bandage',
		weight = 115,
		description = 'Restores 100% health.',
		allowArmed = true,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.bandage'
		}
	},

	['black_money'] = {
		label = 'Dirty Money',
	},

	['recmats'] = {
		label = 'Recycling Materials',
		weight = 1,
		stack = true,
		close = true,
		consume = 1,
		description = 'Open to sort into iron, copper, aluminum, plastic, glass, rubber, steel, gunpowder, blueprints, project parts, and dirty money.',
		client = {
			image = 'recmats.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.recmats'
		},
	},

	['burger'] = {
		label = 'Burger',
		weight = 220,
		client = {
			status = { hunger = 500000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a delicious burger'
		},
	},

	['sprunk'] = {
		label = 'Sprunk',
		weight = 350,
		client = {
			status = { thirst = 500000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},

	['cola'] = {
		label = 'eCola',
		weight = 350,
		client = {
			status = { thirst = 500000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ecola_can`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a cola'
		}
	},

	['parachute'] = {
		label = 'Parachute',
		weight = 8000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},

	['garbage'] = {
		label = 'Garbage',
	},

	['paperbag'] = {
		label = 'Paper Bag',
		weight = 1,
		stack = true,
		close = false,
		consume = 0
	},

	['paper_bags'] = {
		label = 'Paper Bag',
		weight = 10,
		stack = true,
		close = true,
		description = 'Paper bags used for packaging and rolling joints.',
		client = {
			image = 'paperbag.png'
		}
	},

	['identification'] = {
		label = 'Identification',
		client = {
			image = 'card_id.png'
		}
	},

	['panties'] = {
		label = 'Knickers',
		weight = 10,
		consume = 0,
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	['lockpick'] = {
		label = 'Lockpick',
		weight = 40,
		description = 'A lockpick tool used for picking house doors and locks.',
		server = {
			export = 'ox_inventory.lockpick'
		}
	},

	['ammo-box1'] = {
		label = '9mm Ammo Box',
		weight = 350,
		description = 'Sealed ammo box containing 250 rounds of 9mm ammunition.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.ammo_box1'
		}
	},

	['ammo-box2'] = {
		label = '5.56x45 Ammo Box',
		weight = 500,
		description = 'Sealed ammo box containing 500 rounds of 5.56x45mm ammunition.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.ammo_box2'
		}
	},

	['ammo-box3'] = {
		label = '7.62x39 Ammo Box',
		weight = 500,
		description = 'Sealed ammo box containing 500 rounds of 7.62x39mm ammunition.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.ammo_box3'
		}
	},

	['advancedlockpick'] = {
		label = 'Advanced Lockpick',
		weight = 160,
		description = 'A high quality lockpick with improved durability.',
		server = {
			export = 'ox_inventory.advancedlockpick'
		}
	},

	['phone'] = {
		label = 'Grim Phone',
		weight = 190,
		stack = false,
		consume = 0,
		description = 'Official Grim City companion phone.',
		client = {
			add = function(total)
				if total > 0 then
					pcall(function() return exports.npwd:setPhoneDisabled(false) end)
				end
			end,

			remove = function(total)
				if total < 1 then
					pcall(function() return exports.npwd:setPhoneDisabled(true) end)
				end
			end
		}
	},

	['illegal_phone'] = {
		label = 'Illegal Phone',
		weight = 190,
		stack = false,
		consume = 0,
		description = 'An unregistered burner phone.',
		client = {
			image = 'phone.png',
			export = 'kodebykarl-ui.OpenPhone',
		}
	},

	['money'] = {
		label = 'Money',
	},

	['mustard'] = {
		label = 'Mustard',
		weight = 500,
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'You.. drank mustard'
		}
	},

	['water'] = {
		label = 'Water',
		weight = 500,
		client = {
			status = { thirst = 500000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			cancel = true,
			notification = 'You drank some refreshing water'
		}
	},

	['radio'] = {
		label = 'Radio',
		weight = 1000,
		degrade = 480,
		decay = true,
		stack = false,
		allowArmed = true,
		consume = 0,
		client = {
			export = 'cfx-keydi-radio.openRadio',
			remove = function(total)
				if total < 1 and GetResourceState('cfx-keydi-radio') == 'started' then
					exports['cfx-keydi-radio']:leaveRadio()
				end
			end
		}
	},

	['armour'] = {
		label = 'Bulletproof Vest',
		weight = 3000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		}
	},

	['clothing'] = {
		label = 'Clothing',
		consume = 0,
	},

	['mastercard'] = {
		label = 'Fleeca Card',
		stack = false,
		weight = 10,
		client = {
			image = 'card_bank.png'
		}
	},

	['pendrive'] = {
		label = 'Encrypted Pendrive',
		description = 'USB used for Fleeca Bank and Life Invader heists.',
		weight = 15,
		stack = true,
		close = true,
		client = {
			image = 'pendrive.png'
		}
	},

	['laptop_h'] = {
		label = 'Heist Laptop',
		description = 'Encrypted laptop used to start the Pacific Standard (Big Bank) heist.',
		weight = 150,
		stack = true,
		close = true,
	},

	['laptop'] = {
		label = 'Laptop',
		description = 'A laptop used for the Life Invader heist.',
		weight = 150,
		stack = true,
		close = true,
	},

	['drill'] = {
		label = 'Drill',
		description = 'Heavy drill used to breach vaults and reinforced doors.',
		weight = 250,
		stack = true,
		close = true,
	},

	['thermite'] = {
		label = 'Thermite',
		description = 'Incendiary charge used to burn through security doors.',
		weight = 75,
		stack = true,
		close = true,
	},

	['hacking_device'] = {
		label = 'Hacking Device',
		description = 'Handheld device used to bypass electronic security.',
		weight = 80,
		stack = true,
		close = true,
	},

	['keycard'] = {
		label = 'Keycard',
		description = 'Security keycard for restricted heist doors.',
		weight = 5,
		stack = true,
		close = true,
	},

	['glass_cutter'] = {
		label = 'Glass Cutter',
		description = 'Used to cut display glass during the Jewelry heist.',
		weight = 100,
		stack = true,
		close = true,
	},

	['lootbag'] = {
		label = 'Loot Bag',
		description = 'Duffel bag used to carry jewelry and heist loot.',
		weight = 100,
		stack = true,
		close = true,
	},

	['scrapmetal'] = {
		label = 'Scrap Metal',
		weight = 80,
	},

	-- Autofarm & Tools
	['orange'] = {
		label = 'Orange',
		weight = 20,
		client = {
			status = { hunger = 100000, thirst = 50000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a fresh orange'
		}
	},

	['trowel'] = {
		label = 'Garden Trowel',
		weight = 100,
		stack = false,
	},

	['wood'] = {
		label = 'Wood',
		weight = 20,
	},

	['gauze'] = {
		label = 'Medical Gauze',
		weight = 50,
		allowArmed = true,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			usetime = 2500,
			notification = 'You used medical gauze'
		},
		server = {
			export = 'ox_inventory.gauze'
		}
	},

	['oxy'] = {
		label = 'Oxy',
		weight = 20,
		stack = true,
		close = true,
		consume = 1,
		allowArmed = true,
		description = 'Restores 50 health and 50 armor. Stops bleeding and resets limbs.',
		client = {
			image = 'oxy.png',
			anim = { dict = 'mp_suicide', clip = 'pill', flag = 49 },
			usetime = 2000,
			notification = 'You took oxy',
		},
		server = {
			export = 'ox_inventory.oxy'
		}
	},

	['stresstab'] = {
		label = 'Stress Tablet',
		weight = 20,
		client = {
			anim = { dict = 'mp_suicide', clip = 'pill' },
			usetime = 2000,
			notification = 'You took a stress tablet'
		}
	},

	['repairkit'] = {
		label = 'Repair Kit',
		weight = 2500,
		stack = true,
		close = true,
		consume = 0,
		client = {
			event = 'jg-mechanic:client:repair-vehicle',
		},
	},

	-- Sell Market: Farming
	['mango'] = {
		label = 'Mango',
		weight = 120,
		client = {
			status = { hunger = 120000, thirst = 60000 },
			anim = 'eating',
			usetime = 2500,
		}
	},

	['apple'] = {
		label = 'Apple',
		weight = 100,
		client = {
			status = { hunger = 100000, thirst = 40000 },
			anim = 'eating',
			usetime = 2500,
		}
	},

	['pumpkin'] = {
		label = 'Pumpkin',
		weight = 1500,
	},

	['arabica'] = {
		label = 'Arabica Coffee Beans',
		weight = 100,
	},

	['lettuce'] = {
		label = 'Lettuce',
		weight = 80,
	},

	['tomato'] = {
		label = 'Tomato',
		weight = 80,
	},

	['sugar'] = {
		label = 'Sugar',
		weight = 100,
		stack = true,
		description = 'Baking ingredient.',
		client = { image = 'sugar.png' },
	},

	['dough'] = {
		label = 'Dough',
		weight = 150,
		stack = true,
		description = 'Uncooked dough.',
		client = { image = 'dough.png' },
	},

	['butter'] = {
		label = 'Butter',
		weight = 100,
		stack = true,
		description = 'Cooking ingredient.',
		client = { image = 'butter.png' },
	},

	['flour'] = {
		label = 'Flour',
		weight = 150,
		stack = true,
		description = 'Baking ingredient.',
		client = { image = 'flour.png' },
	},

	['cream'] = {
		label = 'Cream',
		weight = 100,
		stack = true,
		description = 'Cooking ingredient.',
		client = { image = 'cream.png' },
	},

	['milk'] = {
		label = 'Milk',
		weight = 250,
		stack = true,
		description = 'Fresh milk.',
		client = {
			image = 'milk.png',
			status = { thirst = 400000, hunger = 100000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			notification = 'You drank some milk'
		},
	},

	['bottle_milk'] = {
		label = 'Milk',
		weight = 250,
		stack = true,
		description = 'A bottle of milk.',
		client = { image = 'bottle_milk.png' },
	},

	['bun'] = {
		label = 'Bun',
		weight = 80,
		stack = true,
		description = 'Burger bun.',
		client = { image = 'bun.png' },
	},

	['burger_patty'] = {
		label = 'Burger Patty',
		weight = 180,
		stack = true,
		description = 'Uncooked burger patty.',
		client = { image = 'burger_patty.png' },
	},

	['soy_sauce'] = {
		label = 'Soy Sauce',
		weight = 150,
		stack = true,
		description = 'Cooking sauce.',
		client = { image = 'soy_sauce.png' },
	},

	['cheese'] = {
		label = 'Cheese',
		weight = 80,
		stack = true,
		description = 'Cooking ingredient.',
		client = { image = 'cheese.png' },
	},

	['rice'] = {
		label = 'Rice',
		weight = 200,
		stack = true,
		description = 'Uncooked rice.',
		client = { image = 'rice.png' },
	},

	['potato'] = {
		label = 'Potato',
		weight = 120,
	},

	['carrot'] = {
		label = 'Carrot',
		weight = 80,
	},

	['honey'] = {
		label = 'Honey',
		weight = 250,
		client = {
			status = { hunger = 50000 },
			usetime = 2000,
		}
	},

	['cocoa'] = {
		label = 'Cocoa Beans',
		weight = 100,
	},

	['mushroom'] = {
		label = 'Mushroom',
		weight = 50,
	},

	['onion'] = {
		label = 'Onion',
		weight = 80,
	},

	['crab'] = {
		label = 'Crab',
		weight = 400,
	},

	-- Hunting
	['raw_chicken'] = {
		label = 'Raw Chicken',
		weight = 300,
	},

	['raw_meat'] = {
		label = 'Raw Meat',
		weight = 20,
	},

	-- Mining & Materials
	['stone'] = {
		label = 'Stone',
		weight = 500,
	},

	['washed_rocks'] = {
		label = 'Washed Stone',
		weight = 400,
	},

	['copper'] = {
		label = 'Copper Ingot',
		weight = 600,
	},

	['iron'] = {
		label = 'Iron Ingot',
		weight = 800,
	},

	['aluminum'] = {
		label = 'Aluminum Ingot',
		weight = 400,
	},

	['steel'] = {
		label = 'Steel Ingot',
		weight = 900,
	},

	['plastic'] = {
		label = 'Plastic',
		weight = 80,
		stack = true,
		description = 'Sorted plastic scrap.',
		client = {
			image = 'plastic.png',
		},
	},

	['glass'] = {
		label = 'Glass',
		weight = 120,
		stack = true,
		description = 'Broken glass ready for recycling.',
		client = {
			image = 'glass.png',
		},
	},

	['rubber'] = {
		label = 'Rubber',
		weight = 100,
		stack = true,
		description = 'Scrap rubber from tires and seals.',
		client = {
			image = 'rubber.png',
		},
	},

	['gunpowder'] = {
		label = 'Gunpowder',
		weight = 50,
		stack = true,
		description = 'Unstable powder recovered from scrap.',
		client = {
			image = 'gunpowder.png',
		},
	},

	['ammo_shells'] = {
		label = 'Ammo Shells',
		weight = 20,
		stack = true,
		description = 'Empty casings used to hand-load ammunition.',
		client = {
			image = 'ammo-9.png',
		},
	},

	['titanium'] = {
		label = 'Titanium Ingot',
		weight = 1200,
	},

	['cloth'] = {
		label = 'Cloth',
		weight = 150,
	},

	['kevlar'] = {
		label = 'Kevlar Sheet',
		weight = 500,
	},

	['emerald'] = {
		label = 'Emerald',
		weight = 100,
	},

	['diamond'] = {
		label = 'Diamond',
		weight = 100,
	},

	-- Weed Farm
	['weed_bud'] = {
		label = 'Weed Bud',
		weight = 50,
	},

	['zipper_bag'] = {
		label = 'Zip-lock Bag',
		weight = 10,
	},

	['packaged_weed'] = {
		label = 'Packaged Weed',
		weight = 100,
	},

	['rolling_paper'] = {
		label = 'Rolling Paper',
		weight = 10,
	},

	['joint'] = {
		label = 'Joint',
		weight = 20,
		stack = true,
		close = true,
		consume = 1,
		allowArmed = true,
		description = 'A rolled joint. Restores 50 armor.',
		client = {
			image = 'joint.png',
			anim = { dict = 'amb@world_human_smoking@male@male_a@base', clip = 'base', flag = 49 },
			usetime = 3000,
			notification = 'You smoked a joint',
		},
		server = {
			export = 'ox_inventory.joint'
		}
	},

	-- Meth Farm
	['stoned_meth'] = {
		label = 'Stoned Meth',
		weight = 50,
		stack = true,
		description = 'Raw meth scraped from the farm trays. Process it at the cook benches.',
	},

	['cracked_meth'] = {
		label = 'Cracked Meth',
		weight = 50,
		stack = true,
		description = 'Cooked meth ready to pack.',
	},

	['meth'] = {
		label = 'Meth',
		weight = 100,
		stack = true,
		close = true,
		consume = 1,
		allowArmed = true,
		description = 'Restores 50 health.',
		client = {
			anim = { dict = 'amb@world_human_aa_smoke@male@idle_a', clip = 'idle_b', flag = 49 },
			usetime = 5000,
			notification = 'You used meth',
		},
		server = {
			export = 'ox_inventory.meth'
		}
	},

	-- Chop Shop
	['car_door'] = {
		label = 'Car Door',
		weight = 4000,
	},

	['car_hood'] = {
		label = 'Car Hood',
		weight = 5000,
	},

	['car_wheel'] = {
		label = 'Car Wheel',
		weight = 4500,
	},

	['car_battery'] = {
		label = 'Car Battery',
		weight = 3000,
	},

	['car_alternator'] = {
		label = 'Car Alternator',
		weight = 2500,
	},

	['car_radiator'] = {
		label = 'Car Radiator',
		weight = 3000,
	},

	['car_engine_part'] = {
		label = 'Engine Part',
		weight = 3500,
	},

	['car_transmission'] = {
		label = 'Transmission',
		weight = 4500,
	},

	['brake_pads'] = {
		label = 'Brake Pads',
		weight = 1200,
	},

	['spark_plugs'] = {
		label = 'Spark Plugs',
		weight = 500,
	},

	['vehicle_shell'] = {
		label = 'Vehicle Shell',
		weight = 8000,
		stack = false,
		close = true,
		consume = 0,
		client = {
			image = 'vehicle_shell.png',
			event = 'kodebykarl-projectcars:client:useShell',
		},
	},

	['project_parts_box'] = {
		label = 'Project Parts Box',
		weight = 5000,
		stack = true,
		close = true,
		consume = 1,
		description = 'Unpack mixed unique project-car parts (engine, transmission, suspension, body frame, tires, doors, windows).',
		client = {
			image = 'project_parts_box.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 3500,
		},
		server = {
			export = 'ox_inventory.project_parts_box'
		}
	},

	['project_ayuda_box'] = {
		label = 'Project Ayuda Box',
		weight = 8000,
		stack = true,
		close = true,
		consume = 1,
		description = 'Full project-car starter kit: shell, blueprints, and all unique parts for one vehicle.',
		client = {
			image = 'project_ayuda_box.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 4000,
		},
		server = {
			export = 'ox_inventory.project_ayuda_box'
		}
	},

	['car_blueprint'] = {
		label = 'Car Blueprint',
		weight = 25,
		stack = true,
		close = true,
		description = 'Required to start assembling a project car (25 needed).',
		client = {
			image = 'car_blueprint.png',
		},
	},

	['gun_blueprint_pistol'] = {
		label = 'Pistol Blueprint',
		weight = 25,
		stack = true,
		close = true,
		description = 'Schematic used to craft a Pistol at a gun workbench.',
		client = {
			image = 'gun_blueprint_pistol.png',
		},
	},

	['gun_blueprint_glock22'] = {
		label = 'Glock 22 Blueprint',
		weight = 25,
		stack = true,
		close = true,
		description = 'Schematic used to craft a Glock 22 at a gun workbench.',
		client = {
			image = 'gun_blueprint_glock22.png',
		},
	},

	['gun_blueprint_deagle'] = {
		label = 'Desert Eagle Blueprint',
		weight = 25,
		stack = true,
		close = true,
		description = 'Schematic used to craft a Desert Eagle at a gun workbench.',
		client = {
			image = 'gun_blueprint_deagle.png',
		},
	},

	['gun_blueprint_appistol'] = {
		label = 'AP Pistol Blueprint',
		weight = 25,
		stack = true,
		close = true,
		description = 'Schematic used to craft an AP Pistol at a gun workbench.',
		client = {
			image = 'gun_blueprint_appistol.png',
		},
	},

	['gun_blueprint_assaultrifle'] = {
		label = 'Assault Rifle Blueprint',
		weight = 25,
		stack = true,
		close = true,
		description = 'Schematic used to craft an Assault Rifle at a gun workbench.',
		client = {
			image = 'gun_blueprint_assaultrifle.png',
		},
	},

	['gun_blueprint_smg'] = {
		label = 'SMG Blueprint',
		weight = 25,
		stack = true,
		close = true,
		description = 'Schematic used to craft an SMG at a gun workbench.',
		client = {
			image = 'gun_blueprint_pistol.png',
		},
	},

	['ayuda_box'] = {
		label = 'Ayuda Box',
		weight = 5000,
		stack = true,
		close = true,
		consume = 1,
		description = 'Starter ayuda package with cash and project-car parts.',
		client = {
			image = 'car_engine_part.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 3500,
		},
		server = {
			export = 'ox_inventory.itemBoxes'
		}
	},

	['food_drinks_box'] = {
		label = 'Food & Drinks Box',
		weight = 1500,
		stack = true,
		close = true,
		consume = 1,
		description = 'Open to receive 5x Grim Tea and 5x Grim Peas.',
		client = {
			image = 'food_drinks_box.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 3000,
		},
		server = {
			export = 'ox_inventory.itemBoxes'
		}
	},

	['grim_tea'] = {
		label = 'Grim Tea',
		weight = 350,
		stack = true,
		close = true,
		consume = 1,
		description = 'Iced Grim City tea. Restores 50% thirst.',
		client = {
			image = 'grim_tea.png',
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_plastic_cup_02`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 3000,
			notification = 'You drank Grim Tea',
		},
		server = {
			export = 'ox_inventory.grim_tea'
		}
	},

	['grim_peas'] = {
		label = 'Grim Peas',
		weight = 400,
		stack = true,
		close = true,
		consume = 1,
		description = 'Canned Grim City peas. Restores 50% hunger.',
		client = {
			image = 'grim_peas.png',
			anim = 'eating',
			prop = { model = `prop_cs_burger_01`, pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 3500,
			notification = 'You ate Grim Peas',
		},
		server = {
			export = 'ox_inventory.grim_peas'
		}
	},

	['stash_car'] = {
		label = 'Stash Car',
		weight = 10,
		stack = false,
		close = true,
		consume = 1,
		description = 'Redeem for a Burrito stash van in your garage.',
		client = {
			image = 'stash_car.png',
			anim = { dict = 'mp_common', clip = 'givetake1_a' },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.stash_car'
		}
	},

	['item_sunrise'] = {
		label = 'Sunrise',
		weight = 10,
		stack = false,
		close = true,
		consume = 1,
		description = 'Use to add a Sunrise (sunrise1) to your garage.',
		client = {
			image = 'item_sunrise.png',
			anim = { dict = 'mp_common', clip = 'givetake1_a' },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.item_sunrise'
		}
	},

	['item_16topcargle'] = {
		label = 'TopCar GLE',
		weight = 10,
		stack = false,
		close = true,
		consume = 1,
		description = 'Use to add a Mercedes GLE TopCar (16topcargle) to your garage.',
		client = {
			image = 'item_16topcargle.png',
			anim = { dict = 'mp_common', clip = 'givetake1_a' },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.item_16topcargle'
		}
	},

	-- University & Starter
	['student_id'] = {
		label = 'Student ID Card',
		weight = 10,
		stack = false,
	},

	['item_free_car'] = {
		label = 'Free Car Voucher',
		weight = 10,
		stack = false,
	},

	['police_vest'] = {
		label = 'Police Vest',
		weight = 3000,
		stack = true,
		consume = 1,
		description = 'On-duty LSPD ballistic vest. Restores 100% armor and equips a police vest. Police only.',
		allowArmed = true,
		client = {
			image = 'police_vest.png',
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500,
		},
		server = {
			export = 'ox_inventory.police_vest'
		}
	},

	['police_vitamins'] = {
		label = 'Police Vitamins',
		weight = 100,
		description = 'Tactical vitamins: Cures bleeding, restores 100% health and full 100 armor.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'police_vitamins.png',
			anim = { dict = 'mp_suicide', clip = 'pill_fp', flag = 49 },
			usetime = 2000,
		},
		server = {
			export = 'ox_inventory.police_vitamins'
		}
	},

	['police_drink'] = {
		label = 'Police Speed Drink',
		weight = 250,
		description = 'Tactical energy drink: Grants 2x sprint speed for 3 seconds.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'police_drink.png',
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2000,
		},
		server = {
			export = 'ox_inventory.police_drink'
		}
	},

	['grimpolicecoin'] = {
		label = 'Grim Police Coin',
		weight = 0,
		description = 'Official Grim City Police Department commendation coin. Used as currency in the Police Armoury.',
		stack = true,
		close = true,
		client = {
			image = 'grimpolicecoin.png',
		}
	},

	['sheriff_coin'] = {
		label = 'Sheriff Coin',
		weight = 0,
		description = 'Official Blaine County Sheriff commendation coin. Used as currency in the Sheriff Armoury.',
		stack = true,
		close = true,
		client = {
			image = 'sheriff_coin.png',
		}
	},

	['sheriffcoin'] = {
		label = 'Sheriff Coin',
		weight = 0,
		description = 'Official Blaine County Sheriff commendation coin. Used as currency in the Sheriff Armoury.',
		stack = true,
		close = true,
		client = {
			image = 'sheriff_coin.png',
		}
	},

	['grimemscoin'] = {
		label = 'EMS Coin',
		weight = 0,
		description = 'Pink Grim City EMS coin. Earned on hospital duty, spent at the EMS supply shop.',
		stack = true,
		close = true,
		client = {
			image = 'grimemscoin.png',
		}
	},

	['traphouse_coin'] = {
		label = 'Traphouse Coin',
		weight = 0,
		description = 'Earned from confirmed kills inside an active TrapHouse redzone.',
		stack = true,
		close = true,
		client = {
			image = 'traphouse_coin.png',
		}
	},

	['ems_medikit'] = {
		label = 'EMS Medikit',
		weight = 500,
		stack = true,
		close = true,
		description = 'Professional EMS trauma kit. Use on a downed patient to revive or heal.',
		client = {
			image = 'medikit.png',
		},
		server = {
			export = 'ox_inventory.ems_medikit'
		}
	},
	['backpack'] = {
		label = 'Student Backpack',
		weight = 220,
		stack = false,
		consume = 0,
		description = 'A spacious backpack used to store university materials.',
		client = {
			export = 'nl-university.openBackpack'
		}
	},
	
	['student_id'] = {
		label = 'Student ID Card',
		weight = 50,
		stack = false,
		close = true,
		description = 'Official university-issued identification card with photo and student info.'
	},
	
	['print_document'] = {
		label = 'Printed Assignment',
		weight = 25,
		stack = true,
		close = true,
		description = 'A printed assignment or form. Don’t lose it!',
		client = {
			export = 'nl-university.useDocument'
		}
	},
	
	['printer_paper'] = {
		label = 'Blank Printer Paper',
		weight = 5,
		stack = true,
		close = true,
		description = 'Standard blank A4 paper used in printers.'
	},
	
	['whiteboard2'] = {
		label = 'Wall Whiteboard',
		weight = 5000,
		stack = false,
		description = 'A classic wall-mounted whiteboard used in classrooms.',
		client = {
			event = 'whiteboards:client:startPlacement'
		}
	},
	
	-- optional
	
	['acetone'] = {
		label = 'Acetone',
		weight = 1,
		stack = true,
		close = true,
		description = 'A flammable solvent.'
	},
	['hydrochloricacid'] = {
		label = 'Hydrochloric Acid',
		weight = 1,
		stack = true,
		close = true,
		description = 'A dangerous chemical.'
	},
	['acid'] = {
		label = 'Acid',
		weight = 1,
		stack = true,
		close = true,
		description = 'A dangerous chemical.'
	},
	['pd_ammo_box_9'] = {
		label = 'PD 9mm Ammo Box',
		weight = 350,
		description = 'Tactical ammo box containing 250 rounds of 9mm ammunition for police sidearms and SMGs.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'pd_ammo_box_9.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.pd_ammo_box_9'
		}
	},

	['pd_ammo_box_rifle'] = {
		label = 'PD 5.56 Rifle Ammo Box',
		weight = 400,
		description = 'Tactical ammo box containing 250 rounds of 5.56x45mm ammunition for police patrol rifles.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'pd_ammo_box_rifle.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.pd_ammo_box_rifle'
		}
	},

	['pd_ammo_box_rifle2'] = {
		label = 'PD 7.62 Rifle Ammo Box',
		weight = 500,
		description = 'Heavy tactical ammo box containing 250 rounds of 7.62x39mm ammunition for heavy police rifles.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'pd_ammo_box_rifle2.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.pd_ammo_box_rifle2'
		}
	},

	['pd_ammo_box_shotgun'] = {
		label = 'PD 12G Shotgun Ammo Box',
		weight = 450,
		description = 'Tactical ammo box containing 250 rounds of 12-gauge shotgun shells for police shotguns.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'pd_ammo_box_shotgun.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.pd_ammo_box_shotgun'
		}
	},

	['pd_ammo_box_45'] = {
		label = 'PD .45 ACP Ammo Box',
		weight = 400,
		description = 'Tactical ammo box containing 250 rounds of .45 ACP ammunition.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'pd_ammo_box_9.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.pd_ammo_box_45'
		}
	},

	['riot_shield'] = {
		label = 'Riot Shield',
		weight = 4000,
		description = 'Ballistic riot shield. On-duty police only. Use to equip / unequip.',
		stack = false,
		consume = 0,
		allowArmed = true,
		client = {
			image = 'riot_shield.png',
		},
		server = {
			export = 'ox_inventory.riot_shield'
		}
	},

	['sheriff_vest'] = {
		label = 'Sheriff Heavy Vest',
		weight = 3000,
		description = 'Tactical body armor issued to Blaine County Sheriff deputies. Restores 100 armor.',
		allowArmed = true,
		client = {
			image = 'sheriff_vest.png',
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500,
		},
		server = {
			export = 'ox_inventory.sheriff_vest'
		}
	},

	['sheriff_vitamins'] = {
		label = 'Sheriff Vitamins',
		weight = 100,
		description = 'Tactical BCSO vitamins: Cures bleeding, restores 100% health and full 100 armor.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'sheriff_vitamins.png',
			anim = { dict = 'mp_suicide', clip = 'pill_fp', flag = 49 },
			usetime = 2000,
		},
		server = {
			export = 'ox_inventory.sheriff_vitamins'
		}
	},

	['sheriff_drink'] = {
		label = 'Sheriff Speed Drink',
		weight = 250,
		description = 'Tactical BCSO energy drink: Grants 2x sprint speed for 10 seconds.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'sheriff_drink.png',
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2000,
		},
		server = {
			export = 'ox_inventory.sheriff_drink'
		}
	},

	['sheriff_ammo_box_9'] = {
		label = 'Sheriff 9mm Ammo Box',
		weight = 350,
		description = 'Tactical ammo box containing 250 rounds of 9mm ammunition for BCSO sidearms and SMGs.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'sheriff_ammo_box_9.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.sheriff_ammo_box_9'
		}
	},

	['sheriff_ammo_box_rifle'] = {
		label = 'Sheriff 5.56 Rifle Ammo Box',
		weight = 400,
		description = 'Tactical ammo box containing 250 rounds of 5.56x45mm ammunition for BCSO patrol rifles.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'sheriff_ammo_box_rifle.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.sheriff_ammo_box_rifle'
		}
	},

	['sheriff_ammo_box_rifle2'] = {
		label = 'Sheriff 7.62 Rifle Ammo Box',
		weight = 500,
		description = 'Heavy tactical ammo box containing 250 rounds of 7.62x39mm ammunition for heavy BCSO rifles.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'sheriff_ammo_box_rifle2.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.sheriff_ammo_box_rifle2'
		}
	},

	['sheriff_ammo_box_shotgun'] = {
		label = 'Sheriff 12G Shotgun Ammo Box',
		weight = 450,
		description = 'Tactical ammo box containing 250 rounds of 12-gauge shotgun shells for BCSO shotguns.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'sheriff_ammo_box_shotgun.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.sheriff_ammo_box_shotgun'
		}
	},

	['sheriff_ammo_box_45'] = {
		label = 'Sheriff .45 ACP Ammo Box',
		weight = 400,
		description = 'Tactical ammo box containing 250 rounds of .45 ACP ammunition for BCSO sidearms.',
		stack = true,
		consume = 1,
		allowArmed = true,
		client = {
			image = 'sheriff_ammo_box_9.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 1500,
		},
		server = {
			export = 'ox_inventory.sheriff_ammo_box_45'
		}
	},

	-- 8-Ball Diner Items
	['8ball_food'] = {
		label = '8-Ball Burger',
		weight = 250,
		description = 'A hearty signature 8-Ball burger. Restores 50% Hunger.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = '8ball_food.png',
			anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
			prop = { model = `prop_cs_burger_01`, pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.8ball_food'
		}
	},

	['8ball_drink'] = {
		label = '8-Ball Soda',
		weight = 200,
		description = 'Crisp and refreshing 8-Ball specialty soda. Restores 50% Thirst.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = '8ball_drink.png',
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.8ball_drink'
		}
	},

	['8ball_box'] = {
		label = '8-Ball Combo Box',
		weight = 1500,
		description = 'A packed 8-Ball combo box containing 5x 8-Ball Burgers and 5x 8-Ball Sodas. Use to unpack.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = '8ball_box.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 2000,
		},
		server = {
			export = 'ox_inventory.8ball_box'
		}
	},

	-- Taco Shop Items
	['taco_food'] = {
		label = 'Crispy Taco',
		weight = 200,
		description = 'Authentic crispy beef taco loaded with fresh toppings. Restores 50% Hunger.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = 'taco_food.png',
			anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
			prop = { model = `prop_taco_01`, pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.taco_food'
		}
	},

	['taco_drink'] = {
		label = 'Taco Drink',
		weight = 200,
		description = 'Refreshing fiesta citrus drink. Restores 50% Thirst.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = 'taco_drink.png',
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.taco_drink'
		}
	},

	['taco_box'] = {
		label = 'Taco Combo Box',
		weight = 1500,
		description = 'A packed Taco Shop combo box containing 5x Crispy Tacos and 5x Taco Drinks. Use to unpack.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = 'taco_box.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 2000,
		},
		server = {
			export = 'ox_inventory.taco_box'
		}
	},

	-- Taco Shop Aliases
	['taco_food1'] = {
		label = 'Crispy Taco',
		weight = 200,
		description = 'Authentic crispy beef taco loaded with fresh toppings. Restores 50% Hunger.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = 'taco_food.png',
			anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' },
			prop = { model = `prop_taco_01`, pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.taco_food'
		}
	},

	['taco_drink1'] = {
		label = 'Taco Drink',
		weight = 200,
		description = 'Refreshing fiesta citrus drink. Restores 50% Thirst.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = 'taco_drink.png',
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
		},
		server = {
			export = 'ox_inventory.taco_drink'
		}
	},

	['taco_meal'] = {
		label = 'Taco Combo Box',
		weight = 1500,
		description = 'A packed Taco Shop combo box containing 5x Crispy Tacos and 5x Taco Drinks. Use to unpack.',
		stack = true,
		consume = 1,
		close = true,
		client = {
			image = 'taco_box.png',
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 2000,
		},
		server = {
			export = 'ox_inventory.taco_box'
		}
	},

	-- Clothing items (cfx-cs-utils clothing menu / Keybind 'U')
	['torso'] = {
		label = 'Shirt / Top',
		weight = 500,
		stack = false,
		close = true,
		description = 'Your stored shirt / torso clothing.',
		client = {
			image = 'torso.png',
			export = 'cfx-cs-utils.torso'
		}
	},

	['pants'] = {
		label = 'Pants',
		weight = 500,
		stack = false,
		close = true,
		description = 'Your stored pants / trousers.',
		client = {
			image = 'pants.png',
			export = 'cfx-cs-utils.pants'
		}
	},

	['shoes'] = {
		label = 'Shoes',
		weight = 500,
		stack = false,
		close = true,
		description = 'Your stored footwear.',
		client = {
			image = 'shoes.png',
			export = 'cfx-cs-utils.shoes'
		}
	},

	['mask'] = {
		label = 'Mask',
		weight = 100,
		stack = false,
		close = true,
		description = 'Your stored face mask.',
		client = {
			image = 'mask.png',
			export = 'cfx-cs-utils.mask'
		}
	},

	['helmet'] = {
		label = 'Hat / Helmet',
		weight = 200,
		stack = false,
		close = true,
		description = 'Your stored hat or helmet.',
		client = {
			image = 'helmet.png',
			export = 'cfx-cs-utils.helmet'
		}
	},

	['bag'] = {
		label = 'Bag',
		weight = 500,
		stack = false,
		close = true,
		description = 'Your stored backpack or bag.',
		client = {
			image = 'bag.png',
			export = 'cfx-cs-utils.bag'
		}
	},

	['chain'] = {
		label = 'Chain',
		weight = 100,
		stack = false,
		close = true,
		description = 'Your stored chain / necklace.',
		client = {
			image = 'chain.png',
			export = 'cfx-cs-utils.chain'
		}
	},

	['glasses'] = {
		label = 'Glasses',
		weight = 50,
		stack = false,
		close = true,
		description = 'Your stored eyewear / sunglasses.',
		client = {
			image = 'glasses.png',
			export = 'cfx-cs-utils.glasses'
		}
	},

	['ears'] = {
		label = 'Ear Accessories',
		weight = 50,
		stack = false,
		close = true,
		description = 'Your stored ear accessories.',
		client = {
			image = 'ears.png',
			export = 'cfx-cs-utils.ears'
		}
	},

	['vest'] = {
		label = 'Vest Carrier',
		weight = 1000,
		stack = false,
		close = true,
		description = 'Your stored tactical vest carrier.',
		client = {
			image = 'vest.png',
			export = 'cfx-cs-utils.vest'
		}
	},

	-- Other cfx-cs-utils items
	['driver_license'] = {
		label = 'Driver License',
		weight = 10,
		stack = false,
		description = 'Official DMV driver license.',
		client = {
			image = 'card_id.png'
		}
	},

	['change_name'] = {
		label = 'Name Change Certificate',
		weight = 10,
		stack = false,
		close = true,
		consume = 0,
		description = 'Official DOJ certificate. Use to legally change your character name. Purchase from the DOJ shop.',
		client = {
			image = 'card_id.png',
			export = 'kodebykarl-ui.UseChangeNameCertificate',
		}
	},

	['reskin_card'] = {
		label = 'Reskin Card',
		weight = 10,
		stack = false,
		close = true,
		description = 'One-time card to fully change your ped, face, and appearance.',
		client = {
			image = 'card_id.png',
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a' },
			usetime = 2500
		},
		server = {
			export = 'ox_inventory.reskin_card'
		}
	},

	['new_player_card'] = {
		label = 'New Player Card',
		weight = 10,
		degrade = 4320,
		decay = true,
		stack = false,
		client = {
			image = 'card_id.png'
		}
	},

	['burgershot_food1'] = {
		label = 'Heart Stopper Burger',
		weight = 300,
		stack = true,
		close = true,
		description = 'A hearty burgershot meal that satisfies your hunger.',
		client = {
			image = 'burgershot_food1.png',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'prop_cs_burger_01',
			usetime = 3500,
			notification = 'You ate a hearty burger'
		}
	},

	["alive_chicken"] = {
		label = "Living chicken",
		weight = 1,
		stack = true,
		close = true,
	},

	["blowpipe"] = {
		label = "Blowtorch",
		weight = 2,
		stack = true,
		close = true,
	},

	["bread"] = {
		label = "Bread",
		weight = 1,
		stack = true,
		close = true,
	},

	["cannabis"] = {
		label = "Cannabis",
		weight = 3,
		stack = true,
		close = true,
	},

	["carokit"] = {
		label = "Body Kit",
		weight = 3,
		stack = true,
		close = true,
	},

	["carotool"] = {
		label = "Tools",
		weight = 2,
		stack = true,
		close = true,
	},

	["clothe"] = {
		label = "Cloth",
		weight = 1,
		stack = true,
		close = true,
	},

	["cutted_wood"] = {
		label = "Cut wood",
		weight = 1,
		stack = true,
		close = true,
	},

	["essence"] = {
		label = "Gas",
		weight = 1,
		stack = true,
		close = true,
	},

	["fabric"] = {
		label = "Fabric",
		weight = 1,
		stack = true,
		close = true,
	},

	["fish"] = {
		label = "Fish",
		weight = 1,
		stack = true,
		close = true,
	},

	["fixkit"] = {
		label = "Repair Kit",
		weight = 3,
		stack = true,
		close = true,
	},

	["fixtool"] = {
		label = "Repair Tools",
		weight = 2,
		stack = true,
		close = true,
	},

	["gazbottle"] = {
		label = "Gas Bottle",
		weight = 2,
		stack = true,
		close = true,
	},

	["gold"] = {
		label = "Gold",
		weight = 1,
		stack = true,
		close = true,
	},

	["marijuana"] = {
		label = "Marijuana",
		weight = 2,
		stack = true,
		close = true,
	},

	["medikit"] = {
		label = "Medikit",
		weight = 2,
		stack = true,
		close = true,
	},

	["packaged_chicken"] = {
		label = "Chicken fillet",
		weight = 1,
		stack = true,
		close = true,
	},

	["packaged_plank"] = {
		label = "Packaged wood",
		weight = 1,
		stack = true,
		close = true,
	},

	["petrol"] = {
		label = "Oil",
		weight = 1,
		stack = true,
		close = true,
	},

	["petrol_raffin"] = {
		label = "Processed oil",
		weight = 1,
		stack = true,
		close = true,
	},

	["slaughtered_chicken"] = {
		label = "Slaughtered chicken",
		weight = 1,
		stack = true,
		close = true,
	},

	["washed_stone"] = {
		label = "Washed stone",
		weight = 1,
		stack = true,
		close = true,
	},

	["wool"] = {
		label = "Wool",
		weight = 1,
		stack = true,
		close = true,
	},

	-- jg-mechanic items
	['engine_oil'] = {
		label = 'Engine Oil',
		weight = 100,
		stack = true,
		close = true,
	},
	['tyre_replacement'] = {
		label = 'Tyre Replacement',
		weight = 100,
		stack = true,
		close = true,
	},
	['clutch_replacement'] = {
		label = 'Clutch Replacement',
		weight = 100,
		stack = true,
		close = true,
	},
	['air_filter'] = {
		label = 'Air Filter',
		weight = 100,
		stack = true,
		close = true,
	},
	['spark_plug'] = {
		label = 'Spark Plug',
		weight = 100,
		stack = true,
		close = true,
	},
	['brakepad_replacement'] = {
		label = 'Brakepad Replacement',
		weight = 100,
		stack = true,
		close = true,
	},
	['suspension_parts'] = {
		label = 'Suspension Parts',
		weight = 100,
		stack = true,
		close = true,
	},
	['i4_engine'] = {
		label = 'I4 Engine',
		weight = 1000,
		stack = true,
		close = true,
	},
	['v6_engine'] = {
		label = 'V6 Engine',
		weight = 1000,
		stack = true,
		close = true,
	},
	['v8_engine'] = {
		label = 'V8 Engine',
		weight = 1000,
		stack = true,
		close = true,
	},
	['v12_engine'] = {
		label = 'V12 Engine',
		weight = 1000,
		stack = true,
		close = true,
	},
	['turbocharger'] = {
		label = 'Turbocharger',
		weight = 1000,
		stack = true,
		close = true,
	},
	['ev_motor'] = {
		label = 'EV Motor',
		weight = 100,
		stack = true,
		close = true,
	},
	['ev_battery'] = {
		label = 'EV Battery',
		weight = 100,
		stack = true,
		close = true,
	},
	['ev_coolant'] = {
		label = 'EV Coolant',
		weight = 100,
		stack = true,
		close = true,
	},
	['awd_drivetrain'] = {
		label = 'AWD Drivetrain',
		weight = 1000,
		stack = true,
		close = true,
	},
	['rwd_drivetrain'] = {
		label = 'RWD Drivetrain',
		weight = 1000,
		stack = true,
		close = true,
	},
	['fwd_drivetrain'] = {
		label = 'FWD Drivetrain',
		weight = 1000,
		stack = true,
		close = true,
	},
	['slick_tyres'] = {
		label = 'Slick Tyres',
		weight = 1000,
		stack = true,
		close = true,
	},
	['semi_slick_tyres'] = {
		label = 'Semi Slick Tyres',
		weight = 1000,
		stack = true,
		close = true,
	},
	['offroad_tyres'] = {
		label = 'Offroad Tyres',
		weight = 1000,
		stack = true,
		close = true,
	},
	['drift_tuning_kit'] = {
		label = 'Drift Tuning Kit',
		weight = 1000,
		stack = true,
		close = true,
	},
	['ceramic_brakes'] = {
		label = 'Ceramic Brakes',
		weight = 1000,
		stack = true,
		close = true,
	},
	['lighting_controller'] = {
		label = 'Lighting Controller',
		weight = 100,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:show-lighting-controller',
		},
	},
	['stancing_kit'] = {
		label = 'Stancer Kit',
		weight = 100,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:show-stancer-kit',
		},
	},
	['cosmetic_part'] = {
		label = 'Cosmetic Parts',
		weight = 100,
		stack = true,
		close = true,
	},
	['respray_kit'] = {
		label = 'Respray Kit',
		weight = 1000,
		stack = true,
		close = true,
	},
	['vehicle_wheels'] = {
		label = 'Vehicle Wheels Set',
		weight = 1000,
		stack = true,
		close = true,
	},
	['tyre_smoke_kit'] = {
		label = 'Tyre Smoke Kit',
		weight = 1000,
		stack = true,
		close = true,
	},
	['bulletproof_tyres'] = {
		label = 'Bulletproof Tyres',
		weight = 1000,
		stack = true,
		close = true,
	},
	['extras_kit'] = {
		label = 'Extras Kit',
		weight = 1000,
		stack = true,
		close = true,
	},
	['nitrous_bottle'] = {
		label = 'Nitrous Bottle',
		weight = 100,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:use-nitrous-bottle',
		},
	},
	['empty_nitrous_bottle'] = {
		label = 'Empty Nitrous Bottle',
		weight = 100,
		stack = true,
		close = true,
	},
	['nitrous_install_kit'] = {
		label = 'Nitrous Install Kit',
		weight = 100,
		stack = true,
		close = true,
	},
	['cleaning_kit'] = {
		label = 'Cleaning Kit',
		weight = 1000,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:clean-vehicle',
		},
	},
	['repair_kit'] = {
		label = 'Repair Kit',
		weight = 1000,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:repair-vehicle',
		},
	},
	['duct_tape'] = {
		label = 'Duct Tape',
		weight = 1000,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:use-duct-tape',
		},
	},
	['performance_part'] = {
		label = 'Performance Parts',
		weight = 1000,
		stack = true,
		close = true,
	},
	['mechanic_tablet'] = {
		label = 'Mechanic Tablet',
		weight = 1000,
		stack = false,
		close = true,
		client = {
			event = 'jg-mechanic:client:use-tablet',
		},
	},
	['manual_gearbox'] = {
		label = 'Manual Gearbox',
		weight = 1000,
		stack = true,
		close = true,
	},
	['obd_scanner'] = {
		label = 'OBD Scanner',
		weight = 500,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:use-obd-scanner',
		},
	},
	['jumpstarter_pack'] = {
		label = 'Jumpstarter Pack',
		weight = 2000,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:use-jumpstarter',
		},
	},
	['tire_plug_kit'] = {
		label = 'Tire Plug Kit',
		weight = 500,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:use-tire-plug',
		},
	},
	['ceramic_coating'] = {
		label = 'Ceramic Coating',
		weight = 500,
		stack = true,
		close = true,
		client = {
			event = 'jg-mechanic:client:use-ceramic-coating',
		},
	},
	['mechanic_box'] = {
		label = 'Mechanic Box',
		weight = 5000,
		stack = true,
		close = true,
		consume = 1,
		description = 'Contains a full set of mechanic parts and tools.',
		client = {
			anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab_cash' },
			usetime = 3500,
		},
		server = {
			export = 'ox_inventory.itemBoxes',
		},
	},
}