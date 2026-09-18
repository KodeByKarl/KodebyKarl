Config = {}

--[[
    Discord logs via kodebykarl-logs → POLICE channels:
    #police-license #police-docs #police-action
]]
Config.Logs = {
    Enabled = true,
    LogTypes = {
        license = true,
        docs = true,
        action = true, -- search, id check, cuff, uncuff, gsr
    },
}

-- Object Config --
Config.MaxSpikes = 10
Config.Objects = {
    ["cone"] = {model = `prop_roadcone02a`, freeze = false},
    ["barrier"] = {model = `prop_barrier_work06a`, freeze = true},
    ["roadsign"] = {model = `prop_snow_sign_road_06g`, freeze = true},
    ["tent"] = {model = `prop_gazebo_03`, freeze = true},
    ["light"] = {model = `prop_worklight_03b`, freeze = true},
}

-- Issued License --
Config.GiveLicense = {
    authorized = {['police'] = 4, ['sheriff'] = 4}
}

-- Scoreboard priority (Safe / Hold / Cooldown / In Progress) in the F6 menu
-- In Progress is set automatically when a robbery starts.
Config.PriorityStatus = {
    enabled = true,
    -- Minimum grade required to change status. All officers can view.
    authorized = {
        ['police'] = 0,
        ['sheriff'] = 0,
    },
}

-- GSR Test Configuration --
Config.GSR = {
    GSRTestTimer = 900
}

-- Riot Shield (F6 toggle) --
Config.RiotShield = {
    model = `prop_ballistic_shield`,
    fallbackModel = `prop_riot_shield`,
    damageReduction = 0.5, -- 0.5 = take 50% damage while shield is active
    -- Placement from https://github.com/RMC-Developments/Riot-Shield
    bone = 18905, -- SKEL_L_Hand
    offset = vector3(0.30, 0.0, 0.10),
    rotation = vector3(270.0, 120.0, 0.0),
    anim = {
        dict = 'missfam4',
        name = 'base',
    },
}

Config.OffDutyJob = 'offpolice'
Config.GarageTakeOutCost = 1000

-- Station interiors / lockers / clothing / duty
Config.Station = {
    Wardrobe = {
        coords = vector3(80.1504, -377.2947, 41.6247),
        heading = 153.7896,
        label = 'Police Wardrobe',
        icon = 'fa-solid fa-shirt',
    },
    Duty = {
        coords = vector3(84.1149, -410.0066, 41.6247),
        heading = 342.0952,
        label = 'On / Off Duty',
        icon = 'fa-solid fa-user-clock',
    },
    Garage = {
        access = vector3(112.8899, -394.3368, 40.3253),
        heading = 247.4003,
        spawn = vector4(123.5052, -399.6405, 40.3253, 242.6202),
        label = 'Police Garage',
        garageId = 'Police Garage',
        takeOutCost = 1000,
    },
    Helipad = {
        access = vector3(74.3532, -414.7925, 55.3262),
        heading = 63.4423,
        spawn = vector4(86.7077, -404.2123, 55.3262, 69.1803),
        store = vector4(86.8641, -403.7948, 55.3263, 157.6525),
        label = 'Police Helipad',
        garageId = 'Police Helipad',
    },
}

-- Law Enforcement Config --
Config.LawEnforcement = {
    police = {
        Blip = {
            Coords  = vector3(80.1504, -377.2947, 41.6247),
			Sprite  = 60,
			Display = 4,
			Scale   = 0.8,
			Colour  = 38,
			Label = 'Police Department',
			Category = 1,
			HighDetail = true,
        },
    },
    sheriff = {
        Blip = {
            Coords  = vector3(1886.3198, 3661.4883, 37.3998),
			Sprite  = 60,
			Display = 4,
			Scale   = 0.8,
			Colour  = 5,
			Label = "Sheriff's Office",
			Category = 1,
			HighDetail = true,
        },
    },
}

-- Documents --
Config.Documents = {
    -- Any player can open My Documents (copies). Jobs below can also issue.
    command = 'documents',
    commandHelp = 'Open your documents. Show or give copies to nearby players.',
    issuerJobs = {
        police = true,
        sheriff = true,
        ambulance = true,
        sambulance = true,
        pambulance = true,
    },
    birthdateFormat = 'DD/MM/YYYY',
    paperProp = {
        name = 'prop_cd_paper_pile1',
        xRot = -130.0,
        yRot = -50.0,
        zRot = 0.0,
    },
    locale = {
        receiveNotification = 'You received a document: ',
        giveNotification = 'You gave a document: ',
        cancel = 'Cancel',
        noPlayersAround = "There's no one around you",
        showDocument = 'Show Document',
        giveCopy = 'Give Copy',
    },
    locations = {
        {
            job = 'police',
            coords = vector3(80.1504, -377.2947, 41.6247),
            radius = 1.5,
            label = 'Open Documents',
            icon = 'fa-solid fa-file-lines',
        },
        {
            job = 'sheriff',
            coords = vector3(1886.3198, 3661.4883, 37.3998),
            radius = 1.5,
            label = 'Open Documents',
            icon = 'fa-solid fa-file-lines',
        },
        {
            jobs = { ['ambulance'] = 0, ['sambulance'] = 0, ['pambulance'] = 0 },
            coords = vector3(-1043.5010, -1352.3008, 5.9474),
            radius = 1.5,
            label = 'Medical Certificate',
            icon = 'fa-solid fa-file-medical',
        },
        {
            jobs = { ['pambulance'] = 0, ['sambulance'] = 0, ['ambulance'] = 0 },
            coords = vector3(-243.7424, 6317.6816, 32.4270),
            radius = 1.5,
            label = 'Medical Certificate',
            icon = 'fa-solid fa-file-medical',
        },
    },
    -- Seeded into k5_document_templates if the job has none yet
    DefaultTemplates = {
        police = {
            {
                minGrade = 0,
                documentName = 'Police Report',
                documentDescription = 'Official LSPD incident / crime report',
                fields = {
                    { name = 'Suspect Name', value = '' },
                    { name = 'Incident Location', value = '' },
                    { name = 'Date / Time', value = '' },
                    { name = 'Charges', value = '' },
                },
                infoName = 'REPORT DETAILS',
                infoTemplate = '',
            },
            {
                minGrade = 0,
                documentName = 'Traffic Citation',
                documentDescription = 'Official traffic citation / fine notice',
                fields = {
                    { name = 'Driver Name', value = '' },
                    { name = 'Vehicle Plate', value = '' },
                    { name = 'Violation', value = '' },
                    { name = 'Fine Amount', value = '' },
                },
                infoName = 'CITATION DETAILS',
                infoTemplate = '',
            },
            {
                minGrade = 0,
                documentName = 'Arrest Warrant',
                documentDescription = 'Authorized warrant for arrest',
                fields = {
                    { name = 'Suspect Name', value = '' },
                    { name = 'DOB', value = '' },
                    { name = 'Charges', value = '' },
                    { name = 'Issuing Officer', value = '' },
                },
                infoName = 'WARRANT DETAILS',
                infoTemplate = '',
            },
        },
        sheriff = {
            {
                minGrade = 0,
                documentName = 'Sheriff Report',
                documentDescription = 'Official BCSO incident / crime report',
                fields = {
                    { name = 'Suspect Name', value = '' },
                    { name = 'Incident Location', value = '' },
                    { name = 'Date / Time', value = '' },
                    { name = 'Charges', value = '' },
                },
                infoName = 'REPORT DETAILS',
                infoTemplate = '',
            },
            {
                minGrade = 0,
                documentName = 'Traffic Citation',
                documentDescription = 'Official traffic citation / fine notice',
                fields = {
                    { name = 'Driver Name', value = '' },
                    { name = 'Vehicle Plate', value = '' },
                    { name = 'Violation', value = '' },
                    { name = 'Fine Amount', value = '' },
                },
                infoName = 'CITATION DETAILS',
                infoTemplate = '',
            },
            {
                minGrade = 0,
                documentName = 'Arrest Warrant',
                documentDescription = 'Authorized warrant for arrest',
                fields = {
                    { name = 'Suspect Name', value = '' },
                    { name = 'DOB', value = '' },
                    { name = 'Charges', value = '' },
                    { name = 'Issuing Deputy', value = '' },
                },
                infoName = 'WARRANT DETAILS',
                infoTemplate = '',
            },
        },
        ambulance = {
            {
                minGrade = 0,
                documentName = 'Medical Certificate',
                documentDescription = 'Official EMS medical certificate',
                fields = {
                    { name = 'Patient Name', value = '' },
                    { name = 'Date of Birth', value = '' },
                    { name = 'Diagnosis', value = '' },
                    { name = 'Treatment Given', value = '' },
                    { name = 'Fit for Duty / Work', value = '' },
                    { name = 'Issuing Medic', value = '' },
                },
                infoName = 'MEDICAL DETAILS',
                infoTemplate = '',
            },
        },
        sambulance = {
            {
                minGrade = 0,
                documentName = 'Medical Certificate',
                documentDescription = 'Official EMS medical certificate',
                fields = {
                    { name = 'Patient Name', value = '' },
                    { name = 'Date of Birth', value = '' },
                    { name = 'Diagnosis', value = '' },
                    { name = 'Treatment Given', value = '' },
                    { name = 'Fit for Duty / Work', value = '' },
                    { name = 'Issuing Medic', value = '' },
                },
                infoName = 'MEDICAL DETAILS',
                infoTemplate = '',
            },
        },
        pambulance = {
            {
                minGrade = 0,
                documentName = 'Medical Certificate',
                documentDescription = 'Official EMS medical certificate',
                fields = {
                    { name = 'Patient Name', value = '' },
                    { name = 'Date of Birth', value = '' },
                    { name = 'Diagnosis', value = '' },
                    { name = 'Treatment Given', value = '' },
                    { name = 'Fit for Duty / Work', value = '' },
                    { name = 'Issuing Medic', value = '' },
                },
                infoName = 'MEDICAL DETAILS',
                infoTemplate = '',
            },
        },
    },
}

-- Police Coin Harvesting / Auto-Farm --
Config.CoinHarvest = {
    enabled = true,
    job = 'police',
    locations = {
        vector4(72.0491, -418.6590, 41.6247, 69.8516),
        vector4(71.0332, -420.8160, 41.6248, 68.6787),
        vector4(72.7600, -424.3149, 41.6248, 154.6851),
        vector4(74.7090, -425.0513, 41.6248, 159.3498),
        vector4(75.9791, -424.4807, 41.6248, 247.7198),
    },
    interactDistance = 1.5,
    drawDistance = 6.0,
    duration = 10000, -- 10 seconds progress bar
    reward = {
        item = 'grimpolicecoin',
        min = 1,
        max = 10,
    },
    anim = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        clip = 'cop_b_idle',
        flag = 1,
    },
}

