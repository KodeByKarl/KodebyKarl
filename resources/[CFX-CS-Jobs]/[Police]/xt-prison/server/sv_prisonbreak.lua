local globalState       = GlobalState
local prisonBreakcfg    = require 'configs.prisonbreak'
local prisonModules     = require 'modules.server.prisonbreak'

local function setPrisonAlarms(setState)
    if globalState.prisonAlarms == setState then return end

    globalState.prisonAlarms = setState

    if setState then
        prisonModules.alarmCountdown()
    end

    return (globalState.prisonAlarms == setState)
end

-- Toggle Prison Alarms --
lib.callback.register('xt-prison:server:setPrisonAlarms', function(_, setState)
    return setPrisonAlarms(setState)
end)

RegisterNetEvent('xt-prison:server:setPrisonAlarmsChance', function(success)
    local alarmChance = success and prisonBreakcfg.AlarmChanceOnHack.success or prisonBreakcfg.AlarmChanceOnHack.fail
    if math.random(100) <= alarmChance then return end
    setPrisonAlarms(true)
end)

-- Prisonbreak Terminal States --
RegisterNetEvent('xt-prison:server:setTerminalHackedState', function(terminalID, setState)
    local src = source
    local ok = prisonModules.setTerminalHackedState(src, terminalID, setState)
    if ok and setState and PrisonLogs and PrisonLogs.Hack then
        PrisonLogs.Hack({
            success = true,
            src = src,
            name = getCharName(src),
            identifier = getCharID(src),
            terminal = terminalID,
        })
    end
end)

lib.callback.register('xt-prison:server:setTerminalBusyState', function(source, terminalID, setState)
    local ok = prisonModules.setTerminalBusyState(source, terminalID, setState)
    if ok and setState and PrisonLogs and PrisonLogs.Hack then
        PrisonLogs.Hack({
            success = false,
            src = source,
            name = getCharName(source),
            identifier = getCharID(source),
            terminal = terminalID,
        })
    end
    return ok
end)

-- Remove Hacking Item(s) --
RegisterNetEvent('xt-prison:server:removePrisonbreakItems', function(success)
    local src = source

    local removeItemsChance = success and prisonBreakcfg.RemoveItemsChanceOnHack.success or prisonBreakcfg.RemoveItemsChanceOnHack.fail
    if math.random(100) <= removeItemsChance then return end

    local requiredItems = prisonBreakcfg.RequiredItems
    local removedCount = 0

    for requiredItem, requiredCount in pairs(requiredItems) do
        if exports.ox_inventory:RemoveItem(src, requiredItem, (requiredCount or 1)) then
            removedCount += 1
            if removedCount == #requiredItems then
                break
            end
        end
    end
end)

-- Breakout of Prison --
RegisterNetEvent('xt-prison:server:triggerBreakout', function()
    local src = source
    prisonModules.prisonBreakout(src)
    if PrisonLogs and PrisonLogs.Breakout then
        PrisonLogs.Breakout({
            src = src,
            name = getCharName(src),
            identifier = getCharID(src),
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    globalState.prisonAlarms = false

    -- Reset Hack Zones & Doors --
    for x = 1, #prisonBreakcfg.HackZones do
        local door = exports.ox_doorlock:getDoorFromName(prisonBreakcfg.HackZones[x].gate)
        if door then
            TriggerEvent('ox_doorlock:setState', door.id, true)
        end

        globalState[('PrisonTerminal_%s'):format(x)] = nil
    end
end)

-- Create Hacking Terminals --
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for x = 1, #prisonBreakcfg.HackZones do
        globalState[('PrisonTerminal_%s'):format(x)] = {
            isHacked = false,
            isBusy = false
        }
    end
end)