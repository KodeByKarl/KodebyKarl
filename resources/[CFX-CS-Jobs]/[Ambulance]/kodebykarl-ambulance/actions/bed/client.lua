local Bed = {}
local Vars = require 'helpers.vars'
local menu = require 'shared.menu'
local bedTimer = 0

local function BedFunction(_type)
    if _type == 'list' then
        ESX.TriggerServerCallback('cfx-keydi-ambulance:getBeds', function(availableBed)
            if availableBed then
                local List = {}
                for bedIndex, bedData in pairs(availableBed) do
                    local description = ('%s'):format(bedData.state and '🔴 Occupied. (Click to remove)' or '🟢 Available.')
                    List[#List + 1] = {
                        title = 'Bed #'..bedIndex,
                        icon = 'fa-solid fa-bed',
                        description = description,
                    }
                    if bedData.state then
                        List[#List].onSelect = function()
                            if bedData.state then
                                TriggerServerEvent('cfx-keydi-ambulance:unbedTarget', bedIndex, bedData.state)
                            end
                        end
                    end
                end
                lib.registerContext({
                    id = 'bed_list',
                    title = 'Bed List',
                    options = List
                })
                lib.showContext('bed_list')
            end
        end)
    end
    if _type == 'admit' then
        ESX.TriggerServerCallback('cfx-keydi-ambulance:getBeds', function(availableBed)
            if availableBed then
                local coords = GetEntityCoords(cache.ped)
                local playerId = lib.getClosestPlayer(coords, 3.0, false)
                if not playerId then
                    return ESX.Notify('AMBULANCE', 'No nearby player.', 'error', 5000)
                end
                local targetId = GetPlayerServerId(playerId)
                local Select = {}
                for bedIndex, bedData in pairs(availableBed) do
                    if not bedData.state then
                        Select[#Select + 1] = {
                            label = 'Bed #'..bedIndex,
                            value = bedIndex
                        }
                    end
                end
                local input = lib.inputDialog('Admit Information', {
                    {type = 'number', label = 'ID', description = 'Nearby patient', icon = 'hashtag', required = true, default = targetId, disabled = true},
                    {type = 'input', label = 'Reason', description = 'The admit reason', required = true, icon = 'hashtag'},
                    {type = 'number', label = 'Time', description = 'In Seconds', icon = 'hashtag', required = true, min = 1},
                    {type = 'select', label = 'Bed', description = 'Bed Number', required = true, options = Select}
                })
                if not input then return end
                TriggerServerEvent('cfx-keydi-ambulance:admitTarget', input[1], input[2], input[3], input[4])
            end
        end)
    end
end

Bed.Menu = function()
    local SendMenu = {
        {
           title = 'Bed List',
            description = 'Open Bed List',
            icon = 'fa-solid fa-list',
            arrow = true,
            onSelect = function()
                BedFunction('list')
            end
        },
        {
            title = 'Admit Player',
            description = 'Admit a nearby player',
            icon = 'fa-solid fa-user',
            arrow = true,
            onSelect = function()
                BedFunction('admit')
            end
        }
    }
    lib.registerContext({
		id = 'bed_system',
		title = 'Bed System',
		options = SendMenu
	})
  	lib.showContext('bed_system')
end


RegisterNetEvent('cfx-keydi-ambulance:syncBed', function(admitTime, bedIndex, job)
    if source ~= 65535 then return end
    local coords = menu.bed.locations[job] and menu.bed.locations[job][bedIndex]
    if not coords then return end
    Vars.isBed = true
    bedTimer = admitTime
    local ped = cache.ped
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    SetEntityHeading(ped, coords.w)
    lib.requestAnimDict('anim@gangops@morgue@table@', 10000)
    exports.ox_target:disableTargeting(true)
    CreateThread(function()
        while Vars.isBed do
            Wait(500)
            DisableAllControlActions(0)
            EnableControlAction(0, 245, true)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 3, true)
            EnableControlAction(0, 4, true)
            EnableControlAction(0, 5, true)
            EnableControlAction(0, 6, true)
            NetworkSetFriendlyFireOption(false)
            FreezeEntityPosition(cache.ped, true)
            TaskPlayAnim(cache.ped, "anim@gangops@morgue@table@", "body_search", 1.0, -1.0, 120000, 1, 120, false, false, false)
            if bedTimer > 0 then
                bedTimer -= 0.5
                if bedTimer % 60 == 0 then
                    ESX.Notify('AMBULANCE', 'You have '..(ESX.Math.Round(bedTimer / 60, 1)).. ' days left until fully healed.', 'info', 3000)
                end
            end
        end
        exports.ox_target:disableTargeting(false)
        FreezeEntityPosition(ped, false)
        NetworkSetFriendlyFireOption(true)
        SetEntityCoords(ped, coords.x, coords.y, coords.z)
        SetEntityHeading(ped, coords.w)
    end)
end)

RegisterNetEvent('cfx-keydi-ambulance:removeBedFromTarget', function()
    if source ~= 65535 then return end
    Vars.isBed = false
end)

RegisterNetEvent('cfx-keydi-ambulance:placeTempBed', function(duration, bedIndex, job)
    if source ~= 65535 then return end
    local ped = cache.ped
    local coords = menu.bed.locations[job] and menu.bed.locations[job][bedIndex]
    if not coords then return end
    exports.ox_target:disableTargeting(true)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w + 180.0)
    TaskStartScenarioAtPosition(ped, 'WORLD_HUMAN_SUNBATHE_BACK', coords.x, coords.y, coords.z, coords.w + 180.0, 0, true, true)
    FreezeEntityPosition(ped, true)
    local endTime = GetGameTimer() + (duration * 60 * 1000)
    CreateThread(function()
        while GetGameTimer() < endTime do
            Wait(1000)
        end
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        exports.ox_target:disableTargeting(false)
    end)
end)

return Bed