local Config = require 'configs.redzone'
local Region = require 'helpers.region'

if not Config or not Config.Enabled then return end

local insideZones = {}

local function showNotification(title, message, nType, duration)
    if ESX and ESX.Notify then
        ESX.Notify(title, message, nType, duration)
    else
        lib.notify({
            title = title,
            description = message,
            type = nType or 'inform',
            duration = duration or 5000,
        })
    end
end

local function refreshActiveTextUI()
    for i = 1, #Config.Zones do
        local zone = Config.Zones[i]
        if insideZones[zone.name] then
            lib.showTextUI(zone.textUI or ('You are inside the **%s**'):format(zone.label), {
                id = 'cfx-cs-redzone',
                position = zone.textUIPosition or 'bottom-center',
                icon = zone.textUIIcon or 'fa-solid fa-triangle-exclamation',
            })
            return
        end
    end
    lib.hideTextUI('cfx-cs-redzone')
end

CreateThread(function()
    for i = 1, #Config.Zones do
        local zone = Config.Zones[i]
        if zone.points and #zone.points >= 3 then
            lib.zones.poly({
                name = zone.name or ('redzone_%s'):format(i),
                points = zone.points,
                thickness = zone.thickness or 80.0,
                debug = zone.debug == true,
                onEnter = function()
                    if not Region.Allowed('grind') and not Region.Allowed('illegal') then
                        return
                    end
                    insideZones[zone.name] = true
                    LocalPlayer.state:set('inRedZone', true, false)

                    showNotification('REDZONE', zone.enterMessage or ('You are inside the %s'):format(zone.label), 'error', 5000)
                    refreshActiveTextUI()
                end,
                onExit = function()
                    insideZones[zone.name] = nil
                    if next(insideZones) == nil then
                        LocalPlayer.state:set('inRedZone', false, false)
                    end

                    showNotification('REDZONE', zone.exitMessage or ('You left the %s'):format(zone.label), 'inform', 3000)
                    refreshActiveTextUI()
                end,
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if next(insideZones) ~= nil then
            lib.hideTextUI('cfx-cs-redzone')
        end
    end
end)
