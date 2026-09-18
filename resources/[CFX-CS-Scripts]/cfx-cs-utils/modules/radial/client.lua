local radialConfig = require 'configs.radial'

CreateThread(function()
    for i = 1, #radialConfig.radialMenu do
        local data = radialConfig.radialMenu[i]
        if data.id and not data.menu then
            radialConfig.radialMenu[i].menu = data.id
        end
    end

    for radialId, items in pairs(radialConfig.radialSubMenu) do
        lib.registerRadial({ id = radialId, items = items })
    end

    lib.addRadialItem(radialConfig.radialMenu)
end)
