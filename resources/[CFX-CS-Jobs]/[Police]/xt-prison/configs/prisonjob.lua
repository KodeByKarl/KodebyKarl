return {
    Welding = {
        -- Sentence cut is rolled server-side between min/max minutes.
        reduceTime = { min = 1, max = 3 },
        cooldown = 0, -- 0 = no wait between skill-check jobs (speed up sentence)
        rewards = {
            { item = 'burger', count = 1 },
            { item = 'sprunk', count = 1 },
        },
        locations = {
            { name = "work1", coords = vec3(1760.0504, 2519.1914, 45.5650), heading = 254.5383, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work2", coords = vec3(1737.4327, 2505.0950, 45.5650), heading = 162.9935, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work3", coords = vec3(1706.5212, 2481.5762, 45.5649), heading = 224.7357, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work4", coords = vec3(1699.8833, 2475.0776, 45.5649), heading = 221.0364, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work5", coords = vec3(1679.9246, 2480.5471, 45.5649), heading = 135.6075, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work6", coords = vec3(1643.8760, 2491.2129, 45.5649), heading = 183.6898, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work7", coords = vec3(1622.8600, 2507.8215, 45.5649), heading = 96.3693, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work8", coords = vec3(1610.0505, 2539.9309, 45.5649), heading = 148.3789, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work9", coords = vec3(1609.1952, 2566.8398, 45.5649), heading = 41.9052, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work10", coords = vec3(1629.9615, 2564.1726, 45.5649), heading = 2.6056, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work11", coords = vec3(1652.4727, 2564.0422, 45.5649), heading = 357.7359, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work12", coords = vec3(1761.5715, 2539.9155, 45.5650), heading = 357.0117, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work13", coords = vec3(1718.8912, 2528.0515, 45.5649), heading = 118.3932, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work14", coords = vec3(1664.7209, 2501.2922, 45.5649), heading = 169.5612, distance = { marker = 5.0, interact = 1.5 }, state = true },
            { name = "work15", coords = vec3(1627.8866, 2538.1633, 45.5649), heading = 358.7282, distance = { marker = 5.0, interact = 1.5 }, state = true },
        }
    },
    skillCheck = {
        count = { min = 3, max = 5 },
        keys = {
            { 'e', 'e', 'e' },
            { 'w', 'a', 'd' },
        }
    }
}
