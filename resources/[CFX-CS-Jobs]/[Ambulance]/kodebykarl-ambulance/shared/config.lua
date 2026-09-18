return {
    General = {
        -- Time before STL / respawn button unlocks (ms)
        RedZoneRespawnTimer = 60000, -- 1 min inside RedZone
        RespawnTimer = 300000, -- 5 mins outside RedZone
        BleedoutTimer = 600000, -- 10 mins bleedout buffer after respawn unlocks
        -- STL (morgue) respawn bank charge
        RespawnFine = 15000, -- 15K fine
        RespawnWithNegativeBank = 300000, -- 5 mins
        -- After STL respawn
        STLRecovery = {
            total = 10,
            crutch = 0,
        },
        -- Pocket items drop on the ground at the death spot (STL + quit while dead)
        DropItemsOnStl = false, -- TEST (was true) so we don't wipe pockets while checking spawn
        DropItemsOnQuit = true,
        KeepItemsOnDrop = { 'identification', 'phone', 'illegal_phone' },
        -- Anti spawn-kill after STL. Protected players cannot take or deal damage.
        SpawnProtection = {
            duration = 60,
        },
        -- Dead players cannot hear voice or world audio (anti-ghost)
        DeathMuteHearing = true,
        -- EMS revive recovery (seconds). crutch = forced crutch prop / no-sprint window.
        Recovery = {
            ['all'] = 120,
            ['police'] = 60,
            ['sheriff'] = 60,
            crutch = 120,
        },
        Dispatch911 = {
            blipSprite = 153,
            blipColor = 1,
            blipScale = 1.1,
            blipDuration = 300000, -- 5 minutes
            jobs = { 'ambulance', 'sambulance', 'pambulance' },
        },
    },

    --[[
        Discord logs via kodebykarl-logs → AMBULANCE channels:
        #ems-revive #ems-money #ems-bodybag #ems-bed #ems-sentry
    ]]
    Logs = {
        Enabled = true,
        LogTypes = {
            revive = true,
            heal = true,
            money = true,
            bodybag = true,
            bed = true,
            sentry = true,
            bleedout = true,
        },
    },

    -- Seeded on resource start if missing (city / Paleto / Sandy)
    Grades = {
        { grade = 0, name = 'intern', label = 'Intern', salary = 65000 },
        { grade = 1, name = 'nurse', label = 'Nurse', salary = 70000 },
        { grade = 2, name = 'head_nurse', label = 'Head Nurse', salary = 75000 },
        { grade = 3, name = 'resident_doctor', label = 'Resident Doctor', salary = 80000 },
        { grade = 4, name = 'senior_resident_doctor', label = 'Senior Resident Doctor', salary = 85000 },
        { grade = 5, name = 'assistant_director', label = 'Assistant Director', salary = 90000 },
        { grade = 6, name = 'boss', label = 'Medical Director', salary = 100000 },
    },
    Jobs = {
        ambulance = { name = 'ambulance', offDuty = 'offambulance', label = 'EMS' },
        pambulance = { name = 'pambulance', offDuty = 'offpambulance', label = 'Paleto Ambulance' },
        sambulance = { name = 'sambulance', offDuty = 'offsambulance', label = 'Sandy Ambulance' },
    },

    Blips = {
        {
            label = 'Hospital',
            coords = vec3(-1040.5308, -1355.7512, 5.9474),
            sprite = 61,
            colour = 1,
            scale = 0.8,
            shortRange = true,
            category = 1,
            highDetail = true,
            display = 4,
        },
        {
            label = 'Sandy Hospital',
            coords = vec3(1834.5216, 3625.2712, 34.4751),
            sprite = 61,
            colour = 1,
            scale = 0.8,
            shortRange = true,
            category = 1,
            highDetail = true,
            display = 4,
        },
        {
            label = 'Paleto Ambulance',
            coords = vec3(-243.7424, 6317.6816, 32.4270),
            sprite = 61,
            colour = 1,
            scale = 0.8,
            shortRange = true,
            category = 1,
            highDetail = true,
            display = 4,
        },
    },

    -- One table per hospital. Add a new HP by copying a block (wardrobe / garage / helipad / boss).
    Stations = {
        city = {
            label = 'City Hospital',
            job = 'ambulance',
            wardrobeJobs = { ambulance = 0, offambulance = 0 },
            Wardrobe = {
                coords = vector3(-1043.5509, -1351.8776, 5.9474),
                heading = 78.2985,
                size = vector3(1.2, 2.0, 2.5),
                label = 'EMS Wardrobe',
                icon = 'fa-solid fa-shirt',
            },
            Garage = {
                access = vector3(-1030.4906, -1415.4324, 5.4256),
                heading = 24.4261,
                spawn = vector4(-1035.8992, -1421.0535, 5.4292, 66.2173),
                label = 'EMS Garage',
                garageId = 'EMS Garage',
            },
            Helipad = {
                access = vector3(-1036.1455, -1347.8751, 21.5959),
                heading = 170.2800,
                spawn = vector4(-1036.1455, -1347.8751, 21.5959, 170.2800),
                label = 'EMS Helipad',
                garageId = 'EMS Helipad',
            },
        },
        paleto = {
            label = 'Paleto Ambulance',
            job = 'pambulance',
            wardrobeJobs = { pambulance = 0, offpambulance = 0 },
            BossMenu = {
                coords = vector3(-243.7424, 6317.6816, 32.4270),
                heading = 221.6605,
                minGrade = 5,
                label = 'Paleto EMS Boss Menu',
                icon = 'fa-solid fa-briefcase',
            },
            Wardrobe = {
                coords = vector3(-251.7039, 6313.1899, 32.4328),
                heading = 229.5909,
                size = vector3(1.2, 2.0, 2.5),
                label = 'Paleto EMS Wardrobe',
                icon = 'fa-solid fa-shirt',
            },
            Garage = {
                access = vector3(-273.5200, 6318.0293, 32.4212),
                heading = 206.0106,
                spawn = vector4(-268.4462, 6309.9468, 32.3824, 215.0898),
                label = 'Paleto EMS Garage',
                garageId = 'Paleto EMS Garage',
            },
            Helipad = {
                access = vector3(-278.5622, 6323.5981, 32.4263),
                heading = 124.1429,
                spawn = vector4(-278.5622, 6323.5981, 32.4263, 124.1429),
                label = 'Paleto EMS Helipad',
                garageId = 'Paleto EMS Helipad',
            },
        },
        sandy = {
            label = 'Sandy Hospital',
            job = 'sambulance',
            wardrobeJobs = { sambulance = 0, offsambulance = 0 },
            Wardrobe = {
                coords = vector3(1834.5216, 3625.2712, 34.4751),
                heading = 38.2063,
                size = vector3(1.2, 2.0, 2.5),
                label = 'Sandy EMS Wardrobe',
                icon = 'fa-solid fa-shirt',
            },
            Garage = {
                access = vector3(1844.5409, 3635.6526, 34.2286),
                heading = 57.1469,
                spawn = vector4(1843.8750, 3644.0823, 34.2248, 358.1708),
                label = 'Sandy EMS Garage',
                garageId = 'Sandy EMS Garage',
            },
            Helipad = {
                access = vector3(1810.6118, 3606.9382, 34.2953),
                heading = 38.8812,
                spawn = vector4(1810.6118, 3606.9382, 34.2953, 38.8812),
                label = 'Sandy EMS Helipad',
                garageId = 'Sandy EMS Helipad',
            },
        },
    },
    CheckIn = {
        {
            price = 1000,
            onDuty = 1, -- only available when medic count is below this
            job = 'ambulance',
            coords = vec3(-1047.7570, -1376.8696, 5.9474),
            heading = 162.7177,
            distance = {interact = 2.0},
            ped = {
                model = 's_m_m_doctor_01',
                scenario = 'WORLD_HUMAN_CLIPBOARD',
            },
        },
        {
            price = 1000,
            onDuty = 1,
            job = 'pambulance',
            coords = vec3(-256.80, 6318.20, 32.4327),
            heading = 226.0,
            distance = {interact = 2.0},
            ped = {
                model = 's_m_m_doctor_01',
                scenario = 'WORLD_HUMAN_CLIPBOARD',
            },
        },
        {
            price = 1000,
            onDuty = 1,
            job = 'sambulance',
            coords = vec3(1841.1823, 3623.0559, 34.4751),
            heading = 125.3423,
            distance = {interact = 2.0},
            ped = {
                model = 's_m_m_doctor_01',
                scenario = 'WORLD_HUMAN_CLIPBOARD',
            },
        },
    },

    -- City HP plastic surgery desk (illenium surgeon shop)
    Surgery = {
        {
            coords = vec4(-1023.3960, -1342.0713, 6.2205, 252.6069),
            label = 'Plastic Surgery',
            ped = {
                model = 's_m_m_doctor_01',
                scenario = 'WORLD_HUMAN_CLIPBOARD',
            },
        },
    },

    -- Auto bill when EMS bodybags a player (society invoice).
    -- autoAccept deducts bank/cash immediately; the player can still Reject to refund.
    Bodybag = {
        bill = 15000,
        title = 'BODYBAG',
        description = 'EMS body bag / remains transport',
        autoAccept = true,
        -- Where the player wakes up after being bodybagged (overrides STL selector).
        respawn = vec4(-1026.9998, -1332.8424, 5.4475, 48.9816),
    },

    -- Hospital coin grind — same loop as PD (no skill check)
    MopGrind = {
        enabled = true,
        jobs = { ambulance = true, pambulance = true, sambulance = true },
        interactDistance = 1.5,
        drawDistance = 8.0,
        duration = 8000,
        reward = {
            item = 'grimemscoin',
            amount = 10,
        },
        defaultTask = 'mop',
        tasks = {
            mop = {
                startLabel = '[E] - Start Auto-Farming EMS Coins',
                progressLabel = 'Mopping the floor...',
                anim = {
                    dict = 'move_mop',
                    clip = 'idle_scrub_small_player',
                    flag = 1,
                },
                prop = {
                    model = `prop_cs_mop_s`,
                    bone = 28422,
                    pos = vec3(0.0, 0.0, 0.12),
                    rot = vec3(0.0, 0.0, 0.0),
                },
            },
            mop2 = {
                startLabel = '[E] - Start Auto-Farming EMS Coins',
                progressLabel = 'Mopping the floor...',
                anim = {
                    dict = 'move_mop',
                    clip = 'idle_scrub_small_player',
                    flag = 1,
                },
                prop = {
                    model = `prop_cs_mop_s`,
                    bone = 28422,
                    pos = vec3(0.0, 0.0, 0.12),
                    rot = vec3(0.0, 0.0, 0.0),
                },
            },
            clean2 = {
                startLabel = '[E] - Start Auto-Farming EMS Coins',
                progressLabel = 'Wiping surfaces...',
                anim = {
                    dict = 'amb@world_human_maid_clean@',
                    clip = 'base',
                    flag = 1,
                },
                prop = {
                    model = `prop_sponge_01`,
                    bone = 28422,
                    pos = vec3(0.0, 0.0, -0.01),
                    rot = vec3(90.0, 0.0, 0.0),
                },
            },
        },
        locations = {
            -- City
            vector4(-1031.3527, -1385.6373, 5.8475, 94.8561),
            vector4(-1038.5088, -1384.1973, 5.9474, 82.3312),
            vector4(-1033.3867, -1364.5939, 5.9474, 353.2818),
            vector4(-1029.2113, -1349.0383, 5.9474, 181.6015),
            vector4(-1022.8370, -1348.8467, 5.9474, 346.1404),
            { coords = vector4(-1033.8179, -1388.1624, 6.0770, 162.8916), task = 'clean2' },
            -- Paleto
            { coords = vector4(-248.1266, 6328.1958, 32.4270, 331.2639), task = 'clean2' },
            { coords = vector4(-254.3547, 6329.1089, 32.4270, 43.2185), task = 'clean2' },
            -- Sandy
            { coords = vector4(1842.9224, 3626.3538, 34.4751, 308.7755), task = 'clean2' },
            { coords = vector4(1845.5255, 3618.6692, 34.4751, 225.3917), task = 'clean2' },
            { coords = vector4(1845.1139, 3627.3672, 34.4794, 322.0634), task = 'mop2' },
            { coords = vector4(1842.3307, 3619.3640, 34.4751, 159.7717), task = 'mop2' },
        },
    },
}