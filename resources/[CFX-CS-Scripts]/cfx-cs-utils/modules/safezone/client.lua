local config = require 'configs.safezone'

local activeZones = 0
local physicallyInside = 0
local notified = false

local function setSafezoneState(inside)
    local value = inside and true or false
    LocalPlayer.state:set('inSafeZone', value, true)
    LocalPlayer.state:set('inSafezone', value, true)
end

local function isInsideSafezone()
    return activeZones > 0
end

exports('IsInSafezone', isInsideSafezone)
exports('isInSafezone', isInsideSafezone)
exports('isInSafeZone', isInsideSafezone)

local function isPoliceJob(jobName)
    if not jobName then return false end
    for i = 1, #config.Zones do
        local zone = config.Zones[i]
        local jobs = zone.policeJobs or { 'police' }
        for j = 1, #jobs do
            if jobs[j] == jobName then
                return true
            end
        end
    end
    return false
end

local function getAllowedWeaponsForPlayer()
    local job = ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
    if not isPoliceJob(job) then
        return nil
    end

    -- Use first matching zone's allow-list (all zones share same rule here)
    for i = 1, #config.Zones do
        local zone = config.Zones[i]
        if zone.restrictWeapons then
            return zone.policeAllowedWeapons or { `WEAPON_STUNGUN` }
        end
    end
    return { `WEAPON_STUNGUN` }
end

local function isWeaponAllowed(weaponHash)
    if weaponHash == `WEAPON_UNARMED` or weaponHash == 0 then
        return true
    end

    local allowed = getAllowedWeaponsForPlayer()
    if not allowed then
        return false
    end

    for i = 1, #allowed do
        if allowed[i] == weaponHash then
            return true
        end
    end
    return false
end

local function disarmIfNeeded()
    local ped = cache.ped
    local weapon = GetSelectedPedWeapon(ped)
    if isWeaponAllowed(weapon) then return end

    if GetResourceState('ox_inventory') == 'started' then
        TriggerEvent('ox_inventory:disarm', true)
    else
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        RemoveAllPedWeapons(ped, true)
    end
end

local function restrictControls()
    DisableControlAction(0, 24, true)  -- attack
    DisableControlAction(0, 25, true)  -- aim
    DisableControlAction(0, 47, true)  -- disable weapon
    DisableControlAction(0, 58, true)  -- disable weapon
    DisableControlAction(0, 140, true) -- melee light
    DisableControlAction(0, 141, true) -- melee heavy
    DisableControlAction(0, 142, true) -- melee alternate
    DisableControlAction(0, 257, true) -- attack 2
    DisableControlAction(0, 263, true) -- melee
    DisableControlAction(0, 264, true) -- melee
    DisablePlayerFiring(cache.playerId, true)
end

CreateThread(function()
    while not ESX.PlayerData or not ESX.PlayerData.job do
        Wait(500)
    end

    for i = 1, #config.Zones do
        local zone = config.Zones[i]
        if zone.points and #zone.points >= 3 then
            lib.zones.poly({
                name = zone.name or ('safezone_%s'):format(i),
                points = zone.points,
                thickness = zone.thickness or 50.0,
                debug = zone.debug == true,
                onEnter = function()
                    physicallyInside += 1
                    activeZones += 1
                    setSafezoneState(true)
                    if not notified then
                        notified = true
                        ESX.Notify('SAFEZONE', zone.label or 'Safezone — weapons restricted', 'inform', 5000)
                    end
                    disarmIfNeeded()
                end,
                onExit = function()
                    physicallyInside = math.max(0, physicallyInside - 1)
                    if activeZones > 0 then
                        activeZones = activeZones - 1
                    end
                    if activeZones <= 0 then
                        local wasProtected = notified
                        notified = false
                        setSafezoneState(false)
                        if wasProtected and physicallyInside <= 0 then
                            ESX.Notify('SAFEZONE', 'You left the safezone', 'inform', 3000)
                        end
                    end
                end,
                inside = function()
                    if not zone.restrictWeapons then return end

                    local ped = cache.ped
                    local weapon = GetSelectedPedWeapon(ped)

                    if isWeaponAllowed(weapon) then
                        -- Police stun gun only: allow aim/fire for that weapon
                        return
                    end

                    restrictControls()
                    if weapon ~= `WEAPON_UNARMED` and weapon ~= 0 then
                        disarmIfNeeded()
                    end
                end,
            })
        end
    end
end)

CreateThread(function()
    while not LocalPlayer or not LocalPlayer.state do
        Wait(100)
    end
    setSafezoneState(activeZones > 0)
end)

RegisterNetEvent('esx:playerLoaded', function()
    setSafezoneState(activeZones > 0)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(250)
        setSafezoneState(activeZones > 0)
    end)
end)

RegisterNetEvent('esx:setJob', function(job)
    ESX.PlayerData.job = job
    if activeZones > 0 then
        disarmIfNeeded()
    end
end)

local function syncSafezoneAfterRegionChange()
    -- Region switch does not teleport. Hospital / mechanic / hub polygons
    -- stay active in every bucket so players cannot holster-check then draw.
    if physicallyInside > 0 then
        activeZones = physicallyInside
        setSafezoneState(true)
        if not notified then
            notified = true
            ESX.Notify('SAFEZONE', 'Safezone — weapons restricted', 'inform', 4000)
        end
        disarmIfNeeded()
        return
    end

    activeZones = 0
    notified = false
    setSafezoneState(false)
end

AddEventHandler('cfx-keydi-serverlocations:changed', function()
    Wait(150)
    syncSafezoneAfterRegionChange()
end)
