return {
    DebugPoly = false,
    Freedom = vec4(1848.762, 2585.830, 45.672, 270.535), -- Freedom spawn coords
    RemoveJob = false,          -- Remove player jobs when send to jail

    -- Front reception checkout (outside the yard)
    CheckOut = {
        coords = vec3(1836.5, 2592.05, 46.35),
        size = vec3(0.9, 7.8, 1.45),
        rotation = 0.5,
    },

    -- Yard release point so inmates can leave when time is up
    YardCheckOut = {
        coords = vec3(1756.80, 2513.40, 45.57),
        size = vec3(1.8, 1.8, 2.2),
        rotation = 30.0,
    },

    -- Alert When Entering Prison --
    EnterPrisonAlert  = {
        enable = true,
        header = 'Welcome to Prison, Criminal Scum!',
        content = 'To reduce your time in prison, get a job from the guard in the cells. Get your ass to work and maybe you\'ll learn a thing or two.',
    },

    -- Enter Prison Spawn Location & Emotes --
    Spawns = {
        { coords = vec4(1750.611, 2509.054, 45.564, 28.909),   emote = 'idle3' },
        -- { coords = vec4(1770.7249755859, 2479.9802246094, 45.74076461792, 31.66007232666),   emote = 'pushup' },
        -- { coords = vec4(1761.0710449219, 2474.9235839844, 49.693054199219, 33.123195648193), emote = 'pushup' },
        -- { coords = vec4(1745.0281982422, 2479.2116699219, 45.740684509277, 323.06579589844), emote = 'weights' },
        -- { coords = vec4(1768.1342773438, 2481.6772460938, 45.740734100342, 33.281074523926), emote = 'lean' },
    },
    -- Prison Doctor --
    PrisonDoctor = {
        model = 's_m_m_doctor_01',
        coords = vector4(1746.37, 2467.26, 45.85, 354.14),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        healLength = 5
    },

    -- Set Prison Outfits --
    EnablePrisonOutfits = true,
    PrisonOufits = {
        male = {
            accessories = {
                item = 0,
                texture = 0
            },
            mask = {
                item = 0,
                texture = 0
            },
            pants = {
                item = 5,
                texture = 7
            },
            jacket = {
                item = 146,
                texture = 7
            },
            shirt = {
                item = 15,
                texture = 0
            },
            arms = {
                item = 0,
                texture = 0
            },
            shoes = {
                item = 5,
                texture = 1
            },
            bodyArmor = {
                item = 0,
                texture = 0
            },
            bags = {
                item = 0,
                texture = 0
            },
            decals = {
                item = 0,
                texture = 0
            },
        },
        female = {
            accessories = {
                item = 0,
                texture = 0
            },
            mask = {
                item = 0,
                texture = 0
            },
            pants = {
                item = 109,
                texture = 2
            },
            jacket = {
                item = 1901,
                texture = 2
            },
            shirt = {
                item = 0,
                texture = 0
            },
            arms = {
                item = 11,
                texture = 0
            },
            shoes = {
                item = 199,
                texture = 9
            },
            bodyArmor = {
                item = 0,
                texture = 0
            },
            bags = {
                item = 0,
                texture = 0
            },
            decals = {
                item = 0,
                texture = 0
            },
        }
    },

    -- Reloads Player's Last Skin When Freed --
    ResetClothing = function()
        TriggerEvent('illenium-appearance:client:reloadSkin', true)
    end,

    -- Triggered on Player Heal --
    PlayerHealed = function()
        -- TriggerEvent('hospital:client:Revive')
        -- TriggerEvent('osp_ambulance:partialRevive')
    end,

    -- Trigger Emote --
    Emote = function(emote)
        if GetResourceState('cfx-keydi-ui') == 'started' then
            exports['cfx-keydi-ui']:playEmoteByCommand(emote)
        end
    end,

    -- Trigger Prison Break Dispatch --
    Dispatch = function(coords)
        -- exports['ps-dispatch']:PrisonBreak()
        -- TriggerEvent('police:client:policeAlert', coords, 'Prison Break')
        
       -- ND Core
        -- exports["ND_MDT"]:createDispatch({
        --             caller = "Boilingbroke Penitentiary",
        --             location = "Sandy Shores",
        --             callDescription = "Prison Break",
        --             coords = vec3(1845.8302, 2585.9011, 45.6726)
        --         })
    end,
}