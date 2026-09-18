local globalState           = GlobalState
local prisonModules         = require 'modules.client.prison'
local prisonBreakModules    = require 'modules.client.prisonbreak'

lib.callback.register('xt-prison:client:enterJail', function(setTime)
    return prisonModules.enterPrison(setTime)
end)

lib.callback.register('xt-prison:client:exitJail', function(isUnjailed)
    return prisonModules.exitPrison(isUnjailed)
end)

-- Jail Player Input Menu (nearest player only — no ToggleId needed) --
lib.callback.register('xt-prison:client:jailPlayerInput', function()
    local closestPlayer = lib.getClosestPlayer(GetEntityCoords(cache.ped), 5.0, false)
    if not closestPlayer then
        lib.notify({
            title = locale('notify.invalid_player'),
            description = 'No nearby player.',
            type = 'error'
        })
        return
    end

    local targetId = GetPlayerServerId(closestPlayer)
    local input = lib.inputDialog(locale('input.jail_player'), {
        { type = 'number', label = locale('input.jailtime'), description = locale('input.months'), icon = 'hourglass', default = 1, min = 1, required = true },
    })
    if not input then return end

    return { targetId, tonumber(input[1]) }
end)

-- Player Load --
local function playerLoaded()
    prisonModules.createPrisonZone()
    prisonBreakModules.createHackZones()
    prisonBreakModules.setPrisonAlarm(globalState?.prisonAlarms or false)

    Wait(500)

    local jailTime = lib.callback.await('xt-prison:server:initJailTime', false)
    if jailTime and jailTime ~= 0 and jailTime > 0 then
        prisonModules.enterPrison(jailTime)
    end
end

-- Handlers --
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    playerLoaded()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    prisonModules.prisonCleanup()
end)

AddEventHandler('xt-prison:client:onLoad', function()
    playerLoaded()
end)

AddEventHandler('xt-prison:client:onUnload', function()
    prisonModules.prisonCleanup()
end)

AddStateBagChangeHandler('prisonAlarms', nil, function(bagName, _, value)
    if bagName ~= 'global' then return end
    prisonBreakModules.setPrisonAlarm(value)
end)