local Config = require 'configs.whitelistedblips'

if not Config or not Config.Enabled then return end

local activeBlips = {}

local function isPlayerOnDuty()
    local jobName = ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
    if not jobName then return false end

    for _, jobConfig in pairs(Config.Jobs) do
        for _, name in ipairs(jobConfig.jobs) do
            if name == jobName then
                return true
            end
        end
    end
    return false
end

local function getVehicleState()
    local ped = cache and cache.ped or PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return 'foot'
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        return 'foot'
    end

    local vehClass = GetVehicleClass(veh)
    -- 15: Helicopters, 16: Planes
    if vehClass == 15 or vehClass == 16 or IsThisModelAHeli(GetEntityModel(veh)) or IsThisModelAPlane(GetEntityModel(veh)) then
        return 'air'
    end

    return 'car'
end

local function clearAllBlips()
    for src, blipInfo in pairs(activeBlips) do
        if DoesBlipExist(blipInfo.handle) then
            RemoveBlip(blipInfo.handle)
        end
    end
    activeBlips = {}
end

RegisterNetEvent('cfx-keydi-utils:whitelistedblips:clear', function()
    clearAllBlips()
end)

RegisterNetEvent('cfx-keydi-utils:whitelistedblips:sync', function(payload)
    if not isPlayerOnDuty() then
        clearAllBlips()
        return
    end

    local myServerId = GetPlayerServerId(PlayerId())
    local currentList = {}

    for i = 1, #payload do
        local data = payload[i]
        local isSelf = (data.src == myServerId)

        if not isSelf or Config.ShowOwnBlip then
            currentList[data.src] = true

            local sprite = data.defaultSprite or 60
            if data.vehState == 'air' then
                sprite = Config.VehicleSprites.air or 15
            elseif data.vehState == 'car' then
                sprite = Config.VehicleSprites.car or 42
            end

            local blipInfo = activeBlips[data.src]
            if not blipInfo then
                local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
                SetBlipSprite(blip, sprite)
                SetBlipColour(blip, data.color or 1)
                SetBlipScale(blip, Config.BlipScale or 0.85)
                SetBlipAsShortRange(blip, false)
                if Config.ShowHeading then
                    ShowHeadingIndicatorOnBlip(blip, true)
                end
                SetBlipRotation(blip, math.ceil(data.heading or 0.0))
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(('[%s] %s'):format(data.label or 'Unit', data.name or 'Officer'))
                EndTextCommandSetBlipName(blip)

                activeBlips[data.src] = {
                    handle = blip,
                    sprite = sprite,
                    color = data.color,
                }
            else
                SetBlipCoords(blipInfo.handle, data.coords.x, data.coords.y, data.coords.z)
                SetBlipRotation(blipInfo.handle, math.ceil(data.heading or 0.0))

                if blipInfo.sprite ~= sprite then
                    SetBlipSprite(blipInfo.handle, sprite)
                    blipInfo.sprite = sprite
                    if Config.ShowHeading then
                        ShowHeadingIndicatorOnBlip(blipInfo.handle, true)
                    end
                end

                if blipInfo.color ~= data.color then
                    SetBlipColour(blipInfo.handle, data.color)
                    blipInfo.color = data.color
                end
            end
        end
    end

    -- Remove blips for players who are no longer on duty / disconnected
    for src, blipInfo in pairs(activeBlips) do
        if not currentList[src] then
            if DoesBlipExist(blipInfo.handle) then
                RemoveBlip(blipInfo.handle)
            end
            activeBlips[src] = nil
        end
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    ESX.PlayerData.job = job
    if not isPlayerOnDuty() then
        clearAllBlips()
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    clearAllBlips()
    ESX.PlayerData = {}
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        clearAllBlips()
    end
end)

CreateThread(function()
    while true do
        if isPlayerOnDuty() then
            local ped = cache and cache.ped or PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local vehState = getVehicleState()

            TriggerServerEvent('cfx-keydi-utils:whitelistedblips:update', coords, heading, vehState)
            Wait(Config.RefreshInterval or 1500)
        else
            Wait(3000)
        end
    end
end)
