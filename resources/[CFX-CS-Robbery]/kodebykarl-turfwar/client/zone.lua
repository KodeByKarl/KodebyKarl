local ZoneManager = {}
local TurfBlips = {}
local RadiusBlips = {}
local InsideZones = {}
local DamageThreads = {}
local blipsVisible = false

local function CanUseTurf(data)
    local fn = (data and data.requireFunction) or 'turfwar'
    if GetResourceState('kodebykarl-ui') ~= 'started' then
        return false
    end
    local ok, allowed = pcall(function()
        return exports['kodebykarl-ui']:HasFunction(fn)
    end)
    return ok and allowed == true
end

local function ClearBlips()
    for id, b in pairs(TurfBlips) do
        if b and DoesBlipExist(b) then
            RemoveBlip(b)
        end
        TurfBlips[id] = nil
    end
    for id, r in pairs(RadiusBlips) do
        if r and DoesBlipExist(r) then
            RemoveBlip(r)
        end
        RadiusBlips[id] = nil
    end
    blipsVisible = false
end

-- Create & Update Map Blips for Turf Locations (Region 3 / 4 only)
function ZoneManager.InitBlips()
    ClearBlips()

    for id, data in pairs(Config.TurfWars) do
        if CanUseTurf(data) and data.blip and data.blip.turf and data.blip.turf.enable then
            local b = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
            SetBlipSprite(b, data.blip.turf.id or 310)
            SetBlipDisplay(b, 4)
            SetBlipScale(b, data.blip.turf.scale or 0.8)
            SetBlipColour(b, data.blip.turf.color or 1)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(data.label)
            EndTextCommandSetBlipName(b)
            TurfBlips[id] = b
        end

        if data.blip and data.blip.radius and data.blip.radius.enable then
            local r = AddBlipForRadius(
                data.coords.x,
                data.coords.y,
                data.coords.z,
                data.blip.radius.scale or data.zone and data.zone.radius or 150.0
            )
            SetBlipColour(r, data.blip.radius.color or 1)
            SetBlipAlpha(r, data.blip.radius.alpha or 110)
            SetBlipAsShortRange(r, false)
            RadiusBlips[id] = r
        end
    end

    blipsVisible = true
end

local lastBlipKey = ''

function ZoneManager.RefreshBlips()
    local keyParts = {}
    for id, data in pairs(Config.TurfWars) do
        if CanUseTurf(data) then
            keyParts[#keyParts + 1] = id
        end
    end
    table.sort(keyParts)
    local key = table.concat(keyParts, ',')
    if key == lastBlipKey then return end
    lastBlipKey = key
    if key == '' then
        ClearBlips()
    else
        ZoneManager.InitBlips()
    end
end

-- Update Blip Colors based on Turf State
function ZoneManager.UpdateBlipState(id, state)
    local turfBlip = TurfBlips[id]
    local radiusBlip = RadiusBlips[id]

    if not turfBlip and not radiusBlip then return end

    if state == 'ACTIVE' then
        if turfBlip then SetBlipColour(turfBlip, 1) end
        if radiusBlip then SetBlipColour(radiusBlip, 1); SetBlipAlpha(radiusBlip, 140) end
    elseif state == 'CLAIMABLE' then
        if turfBlip then SetBlipColour(turfBlip, 2) end
        if radiusBlip then SetBlipColour(radiusBlip, 2); SetBlipAlpha(radiusBlip, 140) end
    elseif state == 'COOLDOWN' then
        if turfBlip then SetBlipColour(turfBlip, 39) end
        if radiusBlip then SetBlipColour(radiusBlip, 39); SetBlipAlpha(radiusBlip, 60) end
    else
        if turfBlip then SetBlipColour(turfBlip, 5) end
        if radiusBlip then SetBlipColour(radiusBlip, 5); SetBlipAlpha(radiusBlip, 70) end
    end
end

-- Zone Boundary Monitor Thread
CreateThread(function()
    Wait(1500)
    ZoneManager.RefreshBlips()

    while true do
        Wait(1000)

        ZoneManager.RefreshBlips()

        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            local pCoords = GetEntityCoords(ped)

            for id, data in pairs(Config.TurfWars) do
                if not CanUseTurf(data) then
                    InsideZones[id] = false
                else
                    local state = GlobalState[('turf_state_%s'):format(id)] or 'IDLE'
                    ZoneManager.UpdateBlipState(id, state)

                    if state == 'ACTIVE' and data.zone and data.zone.enable then
                        local dist = #(pCoords - data.coords)
                        local maxRadius = data.zone.radius or 150.0

                        if dist <= maxRadius then
                            InsideZones[id] = true
                        else
                            if InsideZones[id] then
                                if not DamageThreads[id] then
                                    DamageThreads[id] = true
                                    CreateThread(function()
                                        while InsideZones[id] and (GlobalState[('turf_state_%s'):format(id)] == 'ACTIVE') do
                                            local curDist = #(GetEntityCoords(PlayerPedId()) - data.coords)
                                            if curDist > maxRadius then
                                                lib.showTextUI('[!] OUTSIDE TURF BOUNDARY! RETURN IMMEDIATELY!', {
                                                    position = 'top-center',
                                                    icon = 'fa-solid fa-triangle-exclamation',
                                                    style = { backgroundColor = '#b30000', color = '#ffffff' }
                                                })
                                                ApplyDamageToPed(PlayerPedId(), Config.GoBackDrainPerSecond or 10, false)
                                            else
                                                lib.hideTextUI()
                                                break
                                            end
                                            Wait(1000)
                                        end
                                        lib.hideTextUI()
                                        DamageThreads[id] = nil
                                    end)
                                end
                            end
                        end
                    else
                        InsideZones[id] = false
                    end
                end
            end
        else
            for id in pairs(InsideZones) do
                InsideZones[id] = false
            end
        end
    end
end)

-- Force allowed weapons only while inside an active restricted turf (e.g. Stab City melee)
CreateThread(function()
    local lastNotify = 0
    local lastDisarm = 0

    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            local pCoords = GetEntityCoords(ped)

            for id, data in pairs(Config.TurfWars) do
                if data.weapon and data.weapon.enable and data.weapon.enforceDuringWar then
                    local state = GlobalState[('turf_state_%s'):format(id)] or 'IDLE'
                    if state == 'ACTIVE' then
                        local maxRadius = (data.zone and data.zone.radius) or 150.0
                        if #(pCoords - data.coords) <= maxRadius then
                            local _, currentWeapon = GetCurrentPedWeapon(ped, true)
                            if currentWeapon ~= `WEAPON_UNARMED` and not data.weapon.list[currentWeapon] then
                                sleep = 0
                                DisablePlayerFiring(ped, true)
                                DisableControlAction(0, 24, true)
                                DisableControlAction(0, 25, true)
                                DisableControlAction(0, 257, true)

                                local now = GetGameTimer()
                                if now - lastDisarm > 250 then
                                    lastDisarm = now
                                    TriggerEvent('ox_inventory:disarm', true)
                                    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                                end

                                if now - lastNotify > 4000 then
                                    lastNotify = now
                                    lib.notify({
                                        title = 'WEAPON RESTRICTED',
                                        description = data.weapon.restrictMessage or 'You cannot use this weapon in this Turf War.',
                                        type = 'error'
                                    })
                                end
                            else
                                sleep = 100
                            end
                            break
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('cfx-keydi-serverlocations:changed', function()
    Wait(250)
    ZoneManager.RefreshBlips()
end)

AddStateBagChangeHandler('grimServerId', ('player:%s'):format(GetPlayerServerId(PlayerId())), function()
    Wait(250)
    ZoneManager.RefreshBlips()
end)

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    ClearBlips()
end)

return ZoneManager
