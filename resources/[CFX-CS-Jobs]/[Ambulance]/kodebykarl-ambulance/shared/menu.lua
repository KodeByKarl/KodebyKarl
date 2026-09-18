return {
    menu = {
        access = {['ambulance'] = 0, ['sambulance'] = 0, ['pambulance'] = 0}
    },
    revive = {
        access = {['ambulance'] = 0, ['sambulance'] = 0, ['pambulance'] = 0},
        require = {
            item = 'ems_medikit',
            amount = 1
        },
        -- Anyone with a medikit can ox_target a downed player (no EMS payout).
        civilian = {
            item = 'medikit',
            amount = 1
        },
        reward = {
            item = 'money',
            amount = 200
        }
    },
    heal = {
        access = {['ambulance'] = 0, ['sambulance'] = 0, ['pambulance'] = 0},
        require = {
            item = 'ems_medikit',
            amount = 1
        },
        civilian = {
            item = 'medikit',
            amount = 1
        },
        reward = {
            item = 'money',
            amount = 100
        }
    },
    vitals = {
        access = {['ambulance'] = 0, ['sambulance'] = 0, ['pambulance'] = 0},
    },
    bodybag = {
        access = {['ambulance'] = 0, ['sambulance'] = 0, ['pambulance'] = 0}
    },
    bed = {
        access = {['ambulance'] = 0, ['sambulance'] = 0, ['pambulance'] = 0},
        locations = {
            -- City HP beds (Trello CITY HP FUNCTIONS)
            ambulance = {
                vec4(-1022.9766, -1363.5746, 6.8696, 72.9378),  -- bed 1
                vec4(-1023.6074, -1366.0686, 6.8696, 75.9634),  -- bed 2
                vec4(-1024.2869, -1368.4521, 6.8696, 71.2299),  -- bed 3
                vec4(-1022.2971, -1360.8201, 6.8696, 77.6786),  -- bed 4
                vec4(-1019.8820, -1342.1165, 11.1715, 161.6155), -- bed 5
                vec4(-1025.8933, -1364.6438, 11.0993, 167.5282), -- bed 6
            },
            sambulance = {
                vec4(1840.9833, 3612.3389, 35.1934, 209.4466), -- bed 1
                vec4(1838.2810, 3610.1929, 35.2119, 7.3052),   -- bed 2
                vec4(1835.1129, 3608.9856, 35.1930, 265.2335), -- bed 3
            },
            pambulance = {
                vec4(-264.4805, 6325.2949, 33.2788, 161.4241),
            },
        }
    },
    unbed = {
        access = {['ambulance'] = 0, ['sambulance'] = 0, ['pambulance'] = 0}
    }
}