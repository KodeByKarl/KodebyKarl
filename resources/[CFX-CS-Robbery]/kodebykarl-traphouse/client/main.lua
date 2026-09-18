local ESX = exports['es_extended']:getSharedObject()
local isInRedZone = false
local currentZoneLabel = nil
local currentActiveZone = nil
local activeSphere = nil
local activeRadiusBlip = nil
local activeMarkerBlip = nil

local function CanUseTrapHouse()
    if GetResourceState('kodebykarl-ui') ~= 'started' then
        return false
    end
    local ok, allowed = pcall(function()
        return exports['kodebykarl-ui']:HasFunction('traphouse')
    end)
    return ok and allowed == true
end

-- Helper: Set RedZone In/Out state and TextUI
local function setRedZoneState(state, label)
    if state == isInRedZone then return end
    isInRedZone = state
    currentZoneLabel = label

    if isInRedZone then
        DisplayRadar(true)
        DisplayHud(true)

        lib.showTextUI('TRAPHOUSE REDZONE • KILL ON SIGHT', {
            position = 'top-center',
            icon = 'fa-solid fa-skull',
            style = {
                borderRadius = '6px',
                backgroundColor = 'rgba(13, 13, 18, 0.9)',
                color = '#ff4d4d',
                border = '1px solid rgba(255, 58, 58, 0.4)',
                padding = '6px 12px',
                fontSize = '12px',
                fontWeight = '600',
                letterSpacing = '0.5px'
            }
        })
    else
        lib.hideTextUI()
    end
end

-- Helper: Clean up existing blips & sphere zone
local function clearActiveTrapHouseZone()
    if activeSphere then
        activeSphere:remove()
        activeSphere = nil
    end

    if activeRadiusBlip and DoesBlipExist(activeRadiusBlip) then
        RemoveBlip(activeRadiusBlip)
    end
    activeRadiusBlip = nil

    if activeMarkerBlip and DoesBlipExist(activeMarkerBlip) then
        RemoveBlip(activeMarkerBlip)
    end
    activeMarkerBlip = nil

    currentActiveZone = nil
    setRedZoneState(false, nil)
end

-- Helper: Create or restore 2D Radius Blip and Skull Marker Blip
local function createActiveBlips(zoneData)
    if not zoneData or not zoneData.coords then return end

    local cx = tonumber(zoneData.coords.x) or 0.0
    local cy = tonumber(zoneData.coords.y) or 0.0
    local cz = tonumber(zoneData.coords.z) or 0.0
    local radius = (tonumber(zoneData.radius) or 200.0) + 0.0

    -- 1. Create/Restore 2D RedZone Radius Blip on Map and Minimap
    if not activeRadiusBlip or not DoesBlipExist(activeRadiusBlip) then
        activeRadiusBlip = AddBlipForRadius(cx + 0.0, cy + 0.0, cz + 0.0, radius)
        SetBlipSprite(activeRadiusBlip, 9)
        SetBlipColour(activeRadiusBlip, (zoneData.blip and zoneData.blip.color) or 1)
        SetBlipAlpha(activeRadiusBlip, (zoneData.blip and zoneData.blip.alpha) or 130)
        SetBlipHighDetail(activeRadiusBlip, true)
        SetBlipAsShortRange(activeRadiusBlip, false)
        SetBlipRotation(activeRadiusBlip, 0)
        SetBlipDisplay(activeRadiusBlip, 4)
    end

    -- 2. Create/Restore Marker Skull Blip
    if not activeMarkerBlip or not DoesBlipExist(activeMarkerBlip) then
        activeMarkerBlip = AddBlipForCoord(cx, cy, cz)
        SetBlipSprite(activeMarkerBlip, 310)
        SetBlipColour(activeMarkerBlip, 1)
        SetBlipScale(activeMarkerBlip, 0.85)
        SetBlipAsShortRange(activeMarkerBlip, false)
        SetBlipDisplay(activeMarkerBlip, 4)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(('TRAPHOUSE: %s'):format(zoneData.label or 'Zone'))
        EndTextCommandSetBlipName(activeMarkerBlip)
    end
end

-- Helper: Load and activate single active TrapHouse zone
local function updateActiveTrapHouseZone(zoneData)
    if not zoneData or not zoneData.coords then
        clearActiveTrapHouseZone()
        return
    end

    -- If the zone is already active and blips are healthy, avoid redundant recreate
    if currentActiveZone and currentActiveZone.id == zoneData.id and activeRadiusBlip and DoesBlipExist(activeRadiusBlip) and activeMarkerBlip and DoesBlipExist(activeMarkerBlip) then
        currentActiveZone = zoneData
        return
    end

    clearActiveTrapHouseZone()
    currentActiveZone = zoneData

    local cx = tonumber(zoneData.coords.x) or 0.0
    local cy = tonumber(zoneData.coords.y) or 0.0
    local cz = tonumber(zoneData.coords.z) or 0.0
    local radius = (tonumber(zoneData.radius) or 200.0) + 0.0
    local zoneCoords = vector3(cx, cy, cz)

    createActiveBlips(zoneData)

    -- Create Sphere Zone for Active TrapHouse
    activeSphere = lib.zones.sphere({
        coords = zoneCoords,
        radius = radius,
        debug = false,
        onEnter = function()
            setRedZoneState(true, zoneData.label)
        end,
        onExit = function()
            setRedZoneState(false, nil)
        end
    })

    -- Immediate position check in case player is already inside zone
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        local pCoords = GetEntityCoords(ped)
        if #(pCoords - zoneCoords) <= radius then
            setRedZoneState(true, zoneData.label)
        end
    end
end

-- Synchronize active zone from GlobalState
local function refreshActiveTrapHouseZone()
    if not CanUseTrapHouse() then
        clearActiveTrapHouseZone()
        return
    end
    local activeZone = GlobalState.traphouse_active_zone
    if activeZone and activeZone.coords then
        updateActiveTrapHouseZone(activeZone)
    else
        clearActiveTrapHouseZone()
    end
end

-- Watchdog Heartbeat: Guarantees 2D redzone blip and state consistency (self-healing)
CreateThread(function()
    while true do
        Wait(2500)
        if not CanUseTrapHouse() then
            if currentActiveZone then
                clearActiveTrapHouseZone()
            end
        else
            local activeZone = GlobalState.traphouse_active_zone
            if activeZone and activeZone.coords then
                -- Re-assert blips if missing/wiped by engine
                if not activeRadiusBlip or not DoesBlipExist(activeRadiusBlip) or not activeMarkerBlip or not DoesBlipExist(activeMarkerBlip) then
                    createActiveBlips(activeZone)
                end

                -- Ensure zone state is 100% accurate relative to player coords
                local ped = PlayerPedId()
                if DoesEntityExist(ped) then
                    local cx = tonumber(activeZone.coords.x) or 0.0
                    local cy = tonumber(activeZone.coords.y) or 0.0
                    local cz = tonumber(activeZone.coords.z) or 0.0
                    local radius = (tonumber(activeZone.radius) or 200.0) + 0.0
                    local dist = #(GetEntityCoords(ped) - vector3(cx, cy, cz))

                    if dist <= radius then
                        if not isInRedZone then
                            setRedZoneState(true, activeZone.label)
                        end
                    else
                        if isInRedZone then
                            setRedZoneState(false, nil)
                        end
                    end
                end
            elseif currentActiveZone then
                clearActiveTrapHouseZone()
            end
        end
    end
end)

-- Listen to GlobalState change for instant rotation
AddStateBagChangeHandler('traphouse_active_zone', 'global', function(bagName, key, value)
    if not CanUseTrapHouse() then
        clearActiveTrapHouseZone()
        return
    end
    updateActiveTrapHouseZone(value)
end)

-- Player Lifecycle Handlers: Refresh on spawn, load, or dimension change
RegisterNetEvent('esx:playerLoaded', function()
    Wait(1000)
    refreshActiveTrapHouseZone()
end)

RegisterNetEvent('esx:onPlayerSpawn', function()
    Wait(1000)
    refreshActiveTrapHouseZone()
end)

AddEventHandler('playerSpawned', function()
    Wait(1000)
    refreshActiveTrapHouseZone()
end)

AddEventHandler('cfx-keydi-serverlocations:changed', function()
    Wait(200)
    refreshActiveTrapHouseZone()
end)

-- Initial Load on Client Start (Waits for player activation to avoid premature radar wipe)
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end
    Wait(1500) -- Allow radar subsystem to settle
    refreshActiveTrapHouseZone()
end)

-- Optional Vehicle Cleanup Thread inside Active TrapHouse Zone
CreateThread(function()
    if not Config.DeleteVehiclesInZone then return end

    local lastVehicle = nil

    while true do
        Wait(1000)
        local ped = PlayerPedId()

        if isInRedZone then
            if IsPedInAnyVehicle(ped, false) then
                lastVehicle = GetVehiclePedIsIn(ped, false)
            else
                if lastVehicle and DoesEntityExist(lastVehicle) then
                    local vCoords = GetEntityCoords(lastVehicle)
                    local driver = GetPedInVehicleSeat(lastVehicle, -1)

                    if driver == 0 or not IsPedAPlayer(driver) then
                        if #(GetEntityCoords(ped) - vCoords) > 5.0 then
                            SetEntityAsMissionEntity(lastVehicle, true, true)
                            DeleteVehicle(lastVehicle)
                            lastVehicle = nil
                        end
                    end
                end
            end
        else
            lastVehicle = nil
        end
    end
end)

-- Global Exports
function InRedZoneField()
    return isInRedZone
end

function GetActiveTrapHouseZone()
    return currentActiveZone or GlobalState.traphouse_active_zone
end

exports('InRedZoneField', InRedZoneField)
exports('GetActiveTrapHouseZone', GetActiveTrapHouseZone)

-- Manual Refresh Command
RegisterCommand('refreshtraphouse', function()
    refreshActiveTrapHouseZone()
    lib.notify({
        title = 'TRAPHOUSE',
        description = 'TrapHouse 2D RedZone refreshed.',
        type = 'inform'
    })
end, false)

-- Cleanup on Resource Stop
AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    clearActiveTrapHouseZone()
end)
