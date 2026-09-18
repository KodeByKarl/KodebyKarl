--[[
    Vehicle ox_target — repair / clean with kits (usable by anyone who has the item).
    Repair kits expire (ox_inventory degrade).
]]
return {
    Enabled = true,

    -- nil = anyone can use kits (no job restriction)
    Job = nil,
    Distance = 2.5,

    Repair = {
        item = 'repairkit',
        items = { 'repairkit', 'repair_kit' },
        amount = 1,
        duration = 8000,
        label = 'Repairing vehicle…',
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    },

    Clean = {
        item = 'cleaning_kit',
        amount = 1,
        duration = 5000,
        label = 'Cleaning vehicle…',
        anim = {
            dict = 'amb@world_human_maid_clean@',
            clip = 'base',
        },
        prop = {
            model = `prop_sponge_01`,
            bone = 28422,
            pos = vec3(0.0, 0.0, -0.01),
            rot = vec3(90.0, 0.0, 0.0),
        },
    },
}
