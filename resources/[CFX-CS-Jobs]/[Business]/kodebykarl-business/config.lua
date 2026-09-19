Config = {}

Config.Business = {
    [1] = {
        BusinessName = 'UwU Cafe',
        BlipData = {
            label = '[~p~Business~w~] UwU Cafe',
			pos = vec3(-581.85, -1064.53, 22.35),
			sprite = 537,
            colour = 8,
			scale  = 0.5
        },
        Tray = {
            [1] = {
                leftinv = vec3(-583.41, -1061.96, 22.34), 
                rightinv = vec3(-584.7, -1061.89, 22.34), 
                id = 'uwu-tray-1', 
                label = 'Tray 1', 
                slots = 10, 
                maxWeight = 100000, 
                owner = false
            },
            [2] = {
                leftinv = vec3(-488.1430, -1010.6349, 24.2894), 
                rightinv = vec3(-488.3121, -1012.6271, 24.2894), 
                id = 'uwu-tray-1', 
                label = 'Tray 1', 
                slots = 10, 
                maxWeight = 100000, 
                owner = false
            }
        },
        BossAction = {
            pos = vec3(-577.08, -1067.67, 26.61),
            setjob = 'uwu',
            joblabel = 'UwU Cafe',
            society = 'society_uwu'
        }
    },
    [2] = {
        BusinessName = 'EL MOFLE BUSINESS',
        BlipData = {
            label = '[~y~Business~w~] EL MOFLE BUSINESS',
			pos = vec3(182.4366, -252.7059, 54.0705),
			sprite = 403,
            colour = 1,
			scale  = 0.8
        },
        Tray = {
            [1] = {
                leftinv = vec3(188.2991, -240.2569, 54.0705), 
                rightinv = vec3(189.8089, -240.7150, 54.0705),
                id = 'em-tray-1', 
                label = 'Tray 1', 
                slots = 10, 
                maxWeight = 100000, 
                owner = false
            }
        },
        BossAction = {
            pos = vec3(182.4366, -252.7059, 54.0705),
            setjob = 'em',
            joblabel = 'EL MOFLE BUSINESS',
            society = 'society_em'
        }
    },
    [3] = {
        BusinessName = 'Taco Shop',
        BlipData = {
            label = '[~y~Business~w~] Taco Shop',
			pos = vec3(7.0636, -1598.7366, 29.2940),
			sprite = 79,
            colour = 5,
			scale  = 0.8
        },
        Tray = {
            [1] = {
                leftinv = vec3(123.0234, 254.4423, 108.2586), 
                rightinv = vec3(120.8151, 255.1701, 108.2586),
                id = 'tacoshop-tray-1', 
                label = 'Tray 1', 
                slots = 10, 
                maxWeight = 100000, 
                owner = false
            }
        },
        BossAction = {
            pos = vec3(11.6856, -1598.2847, 29.3762),
            setjob = 'taco',
            joblabel = 'Taco Shop',
            society = 'society_taco'
        }
    },
    --[[ [4] = {
        BusinessName = 'Joliibert',
        BlipData = {
            label = '[~y~Business~w~] Jollibert',
			pos = vec3(272.19, -964.77, 29.3),
			sprite = 89,
            colour = 10,
			scale  = 0.8
        },
        Tray = {
            [1] = {
                leftinv = vec3(280.38, -974.38, 29.43), 
                rightinv = vec3(280.28, -973.13, 29.43),
                id = 'jollibert-tray-1', 
                label = 'Tray 1', 
                slots = 10, 
                maxWeight = 100000, 
                owner = false
            }
        },
        BossAction = {
            pos = vec3(282.8580, -974.5132, 29.4258),
            setjob = 'jollibert',
            joblabel = 'Jollibert',
            society = 'society_jollibert'
        }
    }, ]]
    [4] = {
        BusinessName = 'Burger Shot',
        BlipData = {
            label = '[~g~Business~w~] Burger Shot',
			pos = vec3(-1180.1260, -885.2622, 13.8074),
			sprite = 106,
            colour = 1,
			scale  = 0.8
        },
        Tray = {
            [1] = {
                leftinv = vec3(-1194.7262, -894.1146, 13.8862), 
                rightinv = vec3(-1194.4841, -892.6497, 13.8862), 
                id = 'bshot-tray-1', 
                label = 'Tray 1', 
                slots = 10, 
                maxWeight = 100000, 
                owner = false
            }
        },
        BossAction = {
            pos = vec3(-1202.5630, -895.0966, 13.8862),
            setjob = 'burgershot',
            joblabel = 'Burger Shot',
            society = 'society_burgershot'
        }
    },
    [5] = {
        BusinessName = '8-Ball Diner',
        BlipData = {
            label = '[~p~Business~w~] 8-Ball Diner',
            pos = nil, -- Set coords when location is chosen
            sprite = 279,
            colour = 0,
            scale = 0.8
        },
        Tray = {
            -- Add tray locations when location is chosen
        },
        BossAction = {
            pos = nil, -- Set boss menu coords when location is chosen
            setjob = '8ball',
            joblabel = '8-Ball Diner',
            society = 'society_8ball'
        }
    },
    [6] = {
        BusinessName = 'Spectre Ammu',
        BlipData = {
            label = '[~r~Business~w~] Spectre Ammu',
            pos = vec3(-1304.6237, -397.0958, 36.6957),
            sprite = 110,
            colour = 1,
            scale = 0.8
        },
        Tray = {},
        BossAction = {
            pos = vec3(-1310.1700, -392.5009, 36.6958),
            setjob = 'spectreammu',
            joblabel = 'Spectre Ammu',
            society = 'society_spectreammu'
        }
    }
}
