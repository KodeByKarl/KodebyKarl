--[[
    kodebykarl-projectcars — ox_inventory CORE items

    Merge these entries into ox_inventory/data/items.lua
    (do not replace the whole file).

    Box `server.export` calls this resource, so you do NOT need to
    patch ox_inventory/modules/custom_items.

    Images (copy into ox_inventory/web/images/):
      vehicle_shell.png
      car_blueprint.png
      project_parts_box.png
      project_ayuda_box.png
]]

return {
    ['vehicle_shell'] = {
        label = 'Vehicle Shell',
        weight = 8000,
        stack = false,
        close = true,
        consume = 0,
        description = 'Wrecked chassis. Use it to place a project car and start assembling.',
        client = {
            image = 'vehicle_shell.png',
            event = 'kodebykarl-projectcars:client:useShell',
        },
    },

    ['car_blueprint'] = {
        label = 'Car Blueprint',
        weight = 100,
        stack = true,
        close = true,
        description = 'Required to start assembling a project car (25 needed per shell).',
        client = {
            image = 'car_blueprint.png',
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
            export = 'kodebykarl-projectcars.project_parts_box',
        },
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
            export = 'kodebykarl-projectcars.project_ayuda_box',
        },
    },
}
