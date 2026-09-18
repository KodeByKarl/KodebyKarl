return {
    {
        model = 's_m_m_fiboffice_01',
        coords = vector4(241.1,-1378.89,33.74, 140.84),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        blip = {
            sprite = 408,
            color = 3, 
            scale = 0.5,
            label = 'Driving School',
            data = 0, -- Do not touch
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-book',
                    label = 'Driving School',
                    onSelect = function()
                        exports[GetCurrentResourceName()]:openDMV()
                    end,
                    distance = 2.5
                }
            },
        }
    },
    {
        model = 'cs_movpremmale',
        coords = vec4(-545.042, -204.037, 38.215, 215.459),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        blip = {
            sprite = 498,
            color = 3, 
            scale = 0.5,
            label = 'City Hall',
            data = 0, -- Do not touch
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-building-columns',
                    label = 'DOJ Services Info',
                    onSelect = function()
                        lib.notify({
                            title = 'DOJ Shop',
                            description = 'Buy Citizen ID ($250,000), Name Change Certificate ($500,000), or Driver License ($150,000) at the DOJ Shop. Fees go to DOJ society funds.',
                            type = 'inform',
                            duration = 9000,
                        })
                    end,
                    distance = 2.5
                },
            },
        }
    },
    {
        model = 'a_m_m_mlcrisis_01',
        coords = vec4(-1038.838, -2730.971, 20.169, 237.722),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        blip = {
            sprite = 226,
            color = 2,
            scale = 0.6,
            label = 'Rental',
            data = 0, -- Do not touch
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-shop',
                    label = 'Open Rental',
                    onSelect = function()
                        exports[GetCurrentResourceName()]:OpenRentalMenu('airport')
                    end,
                    distance = 3.0
                }
            },
        }
    },
    {
        model = 'a_m_m_mlcrisis_01',
        coords = vec4(-1673.3219, -301.4520, 51.8120, 141.9751),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        blip = {
            sprite = 226,
            color = 2,
            scale = 0.6,
            label = 'Rental',
            data = 0, -- Do not touch
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-shop',
                    label = 'Open Rental',
                    onSelect = function()
                        exports[GetCurrentResourceName()]:OpenRentalMenu('rockford')
                    end,
                    distance = 3.0
                }
            },
        }
    },
    {
        model = 'a_m_m_mlcrisis_01',
        coords = vec4(113.543, -3341.364, 6.007, 356.812),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        blip = {
            sprite = 226,
            color = 2,
            scale = 0.6,
            label = 'Rental (Boat)',
            data = 0, -- Do not touch
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-shop',
                    label = 'Open Rental',
                    onSelect = function()
                        exports[GetCurrentResourceName()]:OpenRentalMenu('boat_lsia')
                    end,
                    distance = 3.0
                }
            },
        }
    },
    {
        model = 'a_m_m_mlcrisis_01',
        coords = vec4(-491.9571, -2928.2600, 6.0047, 49.3564),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        blip = {
            sprite = 226,
            color = 2,
            scale = 0.6,
            label = 'Rental (Boat)',
            data = 0, -- Do not touch
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-shop',
                    label = 'Open Rental',
                    onSelect = function()
                        exports[GetCurrentResourceName()]:OpenRentalMenu('boat_terminal')
                    end,
                    distance = 3.0
                }
            },
        }
    },
    {
        model = 'a_m_m_mlcrisis_01',
        coords = vec4(-1796.238, -971.344, 2.174, 29.734),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        blip = {
            sprite = 226,
            color = 2,
            scale = 0.6,
            label = 'Rental (Boat)',
            data = 0, -- Do not touch
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-shop',
                    label = 'Open Rental',
                    onSelect = function()
                        exports[GetCurrentResourceName()]:OpenRentalMenu('boat_delperro')
                    end,
                    distance = 3.0
                }
            },
        }
    },
    {
        model = 'a_m_m_mlcrisis_01',
        coords = vec4(-269.385, 6645.973, 7.427, 130.537),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        blip = {
            sprite = 226,
            color = 2,
            scale = 0.6,
            label = 'Rental (Boat)',
            data = 0, -- Do not touch
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-shop',
                    label = 'Open Rental',
                    onSelect = function()
                        exports[GetCurrentResourceName()]:OpenRentalMenu('boat_paleto')
                    end,
                    distance = 3.0
                }
            },
        }
    },
    {
        -- Sell Market NPC (coords must match kodebykarl-ui ConfigMarket.Locations)
        model = 'a_m_m_business_01',
        coords = vec4(162.0263, 6636.6411, 31.5562, 134.3263),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = false,
        currentpednumber = 0,
        blip = {
            sprite = 78,
            color = 2,
            scale = 0.8,
            label = 'Market',
            data = 0,
            category = 1,
            highDetail = true,
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-store',
                    label = 'Open Sell Market',
                    onSelect = function()
                        if GetResourceState('kodebykarl-ui') == 'started' then
                            exports['kodebykarl-ui']:OpenSellMarket()
                        else
                            TriggerEvent('cfx-keydi-market:client:open')
                        end
                    end,
                    distance = 2.5
                }
            },
        }
    },
    {
        -- Neon + starter pack (immediate) | Sunrise car only after 6h (separate)
        model = 'a_m_y_business_03',
        coords = vec4(-260.5113, -965.4332, 31.2244, 116.3138),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        target = {
            options = {
                {
                    icon = 'fa-solid fa-car',
                    label = 'Claim Free Neon + Starter Pack',
                    onSelect = function()
                        TriggerServerEvent('cfx-keydi-utils:playtimereward:server:claim', 'neon')
                    end,
                    distance = 2.5
                },
                {
                    icon = 'fa-solid fa-car-side',
                    label = 'Claim Free Sunrise (6h Playtime)',
                    onSelect = function()
                        TriggerServerEvent('cfx-keydi-utils:playtimereward:server:claim', 'sunrise')
                    end,
                    distance = 2.5
                }
            },
        }
    },
    {
        -- YouTool NPC (coords must match ox_inventory YouTool location)
        model = 's_m_m_lathandy_01',
        coords = vec4(153.3959, 6645.4497, 31.5720, 141.7415),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = false,
        currentpednumber = 0,
        blip = {
            sprite = 402,
            color = 69,
            scale = 0.8,
            label = 'YouTool',
            data = 0,
        },
        target = {
            options = {
                {
                    icon = 'fa-solid fa-screwdriver-wrench',
                    label = 'Open YouTool',
                    onSelect = function()
                        if GetResourceState('ox_inventory') ~= 'started' then
                            return lib.notify({ title = 'YouTool', description = 'Shop is unavailable right now.', type = 'error' })
                        end
                        local opened = exports.ox_inventory:openInventory('shop', { type = 'YouTool', id = 1 })
                        if opened == false then
                            lib.notify({ title = 'YouTool', description = 'Could not open shop. Step closer and try again.', type = 'error' })
                        end
                    end,
                    distance = 2.5
                }
            },
        }
    },
    {
        -- Weed Farm Shop NPC (coords must match ox_inventory WeedFarmShop location)
        model = 'a_m_m_hillbilly_01',
        coords = vec4(2224.7139, 5604.8462, 54.9226, 286.7909),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_SMOKING',
        currentpednumber = 0,
        target = {
            options = {
                {
                    icon = 'fa-solid fa-cannabis',
                    label = 'Open Weed Farm Shop',
                    onSelect = function()
                        exports.ox_inventory:openInventory('shop', { type = 'WeedFarmShop', id = 1 })
                    end,
                    distance = 2.5
                }
            },
        }
    },
    {
        -- Gun Trade-In (Ammu-Nation Downtown LS) — scrap firearms for random gun parts
        model = 's_m_y_ammucity_01',
        coords = vec4(22.2645, -1106.7292, 29.7970, 159.7594),
        minusOne = false,
        freeze = true,
        invincible = true,
        blockevents = true,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        currentpednumber = 0,
        target = {
            options = {
                {
                    icon = 'fa-solid fa-right-left',
                    label = 'Gun Trade-In',
                    onSelect = function()
                        exports[GetCurrentResourceName()]:OpenGunTrade()
                    end,
                    distance = 2.5
                }
            },
        }
    },

}