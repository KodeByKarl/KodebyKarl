ConfigChat = {
    fadeTimeout = 10000, -- hide message overlay 10s after last show/message/open
    suggestionLimit = 4,
    cooldownSeconds = 2,

    -- Personal OOC text chat is disabled. Only /commands are accepted (e.g. /pol, /ems, /gang, /me).
    allowPersonalChat = false,
    personalChatBlockedMessage = '[SYSTEM] Personal chat is disabled. Use your job command (example: /pol message).',

    -- Hide staff-only clutter from chat autocomplete.
    hiddenSuggestions = { '/gc', '/additem', '/giveitem', '/giveallitem', '/setitem' },

    -- Freestyle only: type your own message. No fixed Auto Templates picker.
    -- Job announcement suggestions are built from jobTemplate.jobs command assignments.
    commandSuggestions = {
        { name = '/gang', help = 'Gang announcement (Freestyle)', params = {{ name = 'message', help = 'Your announcement' }} },
        { name = '/me', help = '3D RP action above your head', params = {{ name = 'action', help = 'scratch his nose' }} },
    },

    -- Each whitelisted job has its own command. There is no shared /wl.
    jobAutoTemplates = {
        enabled = false,
        jobs = {},
    },

    -- Charge listed jobs when posting their assigned announcement (/pol, /ems, …).
    jobTemplatePayment = {
        enabled = true,
        amount = 10000,
        jobs = {
            police = true,
            sheriff = true,
            ambulance = true,
            sambulance = true,
            pambulance = true,
        },
    },

    -- Freestyle job banners (same look as /gang). Type your own message.
    -- color = message text, headerColor = FEED line / time.
    -- command = false: no shared command. Each job below is assigned its own.
    jobTemplate = {
        enabled = true,
        command = false,
        allowAnyJob = false,
        blockedJobs = {
            ["unemployed"] = true,
            ["offpolice"] = true,
            ["offsheriff"] = true,
            ["offambulance"] = true,
            ["offsambulance"] = true,
            ["offpambulance"] = true,
            ["offdoj"] = true,
            ["offmechanic"] = true,
        },
        default = {
            gif = nil,
            background = "#111111",
            color = "#ffffff",
            headerColor = "#cfcfcf",
        },
        -- Freestyle messages + custom banner images per job.
        jobs = {
            ["police"] = {
                command = "pol",
                aliases = { "pd", "police" },
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/GCPD.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["sheriff"] = {
                command = "sheriff",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/GCSD.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["doj"] = {
                command = "doj",
                gif = nil,
                background = "#1a0f2e",
                color = "#ffffff",
                headerColor = "#c4b5fd",
            },
            ["ambulance"] = {
                command = "ems",
                aliases = { "hospital" },
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/01_EMS.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["sambulance"] = {
                command = "sems",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/sandyambulance.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["pambulance"] = {
                command = "pems",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/01_EMS.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["mechanic"] = {
                command = "mech",
                aliases = { "mechanic" },
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/mechanibai.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["uwu"] = {
                command = "uwu",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/UWU.png",
                background = nil,
                color = "#111111",
                headerColor = "#4a1a2a",
            },
            ["tacoshop"] = {
                command = "taco",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/taco.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["taco"] = {
                command = "taco",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/taco.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["burgershot"] = {
                command = "bs",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/BSHOT.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["8ball"] = {
                command = "8ball",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/8ball.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#e0aaff",
            },
            ["weedshop"] = {
                command = "weed",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/weedshop.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["school"] = {
                command = "school",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/GCU.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["tattooshop1"] = {
                command = "tattoo",
                gif = nil,
                background = "#111111",
                color = "#ffffff",
                headerColor = "#cfcfcf",
            },
            ["tattooshop2"] = {
                command = "tattoo",
                gif = nil,
                background = "#111111",
                color = "#ffffff",
                headerColor = "#cfcfcf",
            },
            ["tattooshop3"] = {
                command = "tattoo",
                gif = nil,
                background = "#111111",
                color = "#ffffff",
                headerColor = "#cfcfcf",
            },
            ["vu"] = {
                command = "vu",
                gif = nil,
                background = "#1a0814",
                color = "#ffffff",
                headerColor = "#f9a8d4",
            },
        }
    },

    gangTemplate = {
        enabled = true,
        -- Freestyle gang announcement. Registered here as /gang.
        command = "gang",
        -- Any assigned ESX gang can /gang (Freestyle).
        allowAnyGang = true,
        default = {
            gif = nil,
            background = "#111111",
            color = "#ffffff",
            headerColor = "#cfcfcf",
        },
        -- Optional custom colors. Keys MUST match es_extended gang names.
        gangs = {
            ["grimgang"] = {
                label = "GrimGang",
                gif = nil,
                background = "#1a0a0a",
                color = "#ffffff",
                headerColor = "#e8b4b4",
            },
            ["alaskador"] = {
                label = "Alaskador",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/alaskador_template.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#7ec8e8",
            },
            ["westside"] = {
                label = "Westside",
                gif = nil,
                background = "#160a1c",
                color = "#ffffff",
                headerColor = "#d8b4fe",
            },
            ["mellysyndicate"] = {
                label = "Melly Syndicate",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/melly.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ff69b4",
            },
            ["ghettosyndicate"] = {
                label = "Ghetto Syndicate",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/ghetto.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#6ee7a0",
            },
            ["deuscartel"] = {
                label = "Deus Cartel",
                gif = nil,
                background = "#1a120a",
                color = "#ffffff",
                headerColor = "#c4a484",
            },
            ["npa"] = {
                label = "NPA",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/npa.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#ffffff",
            },
            ["tdc"] = {
                label = "Tropa de Calle",
                gif = "https://r2.fivemanage.com/jWHtKTIB2qDgmUWvaXcm9/tdc.png",
                background = nil,
                color = "#ffffff",
                headerColor = "#7eb6ff",
            },
            ["tbs"] = {
                label = "The Boneless",
                gif = nil,
                background = "#1a0808",
                color = "#ffffff",
                headerColor = "#ff6b6b",
            },
        }
    },

    adminTemplate = {
        enabled = true,
        command = "admin",
        permissions = { "group.moderator", "group.admin", "group.superadmin", "group.developer" },
        gif = nil,
        background = "#DC143C",
        color = "#ffffff",
        headerColor = "#ffcccc",
    },

    -- /staff — staff announcement visible to ALL online players
    staffTemplate = {
        enabled = true,
        command = "staff",
        groups = { "mod", "moderator", "admin", "superadmin", "owner", "developer" },
        gif = nil,
        background = "#7C3AED", -- purple
        color = "#ffffff",
        headerColor = "#e9d5ff",
    },

    -- /staffo — staff-only chat (only staff groups can see)
    staffOnlyTemplate = {
        enabled = true,
        command = "sf",
        groups = { "mod", "moderator", "admin", "superadmin", "owner", "developer" },
        gif = nil,
        background = "#1E3A5F", -- dark blue
        color = "#ffffff",
        headerColor = "#93c5fd",
    },

    -- Grim City 3D /me (NUI overlay, not GTA DrawText).
    Me3D = {
        enabled = true,
        language = 'en',
        time = 5500,
        dist = 22.0,
        fadeStart = 14.0,
        headOffset = 1.08,
        maxLength = 140,
        cooldownMs = 1500,
        -- Native DrawText fallback if NUI is down
        useNativeFallback = false,
    },

    Me3DLanguages = {
        ['en'] = {
            commandName = 'me',
            commandDescription = 'Display an RP action above your head.',
            commandSuggestion = {{ name = 'action', help = '"scratch his nose" for example.'}},
            prefix = ''
        }
    },

    Me3DLanguage = 'en'
}

return ConfigChat
