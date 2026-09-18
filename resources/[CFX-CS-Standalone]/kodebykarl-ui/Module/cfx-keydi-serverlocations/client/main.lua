ESX = ESX or exports["es_extended"]:getSharedObject()

ServerLocations = ServerLocations or {}

local switching = false

local function DebugLog(msg)
    if ConfigServerLocations.Debug then
        print(("[ServerLocations] %s"):format(msg))
    end
end

local function Notify(msg, nType)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg, nType or "info")
    end
end

local function ApplyClientLocation(location)
    if type(location) ~= "table" or not location.id then return nil end
    ConfigServerLocations.SetClientCurrentId(location.id)
    return location
end

function ServerLocations.GetCurrentId()
    return ConfigServerLocations.GetClientCurrentId() or ConfigServerLocations.DefaultId or "region1"
end

function ServerLocations.GetCurrent()
    return ConfigServerLocations.GetById(ServerLocations.GetCurrentId())
end

function ServerLocations.HasFunction(fn)
    return ConfigServerLocations.CanUseFunction(fn)
end

function ServerLocations.WrongServerMessage(fn)
    return ConfigServerLocations.WrongServerMessage(fn)
end

function ServerLocations.RequiresSafezoneToSwitch()
    return ConfigServerLocations.RequiresSafezoneToSwitch()
end

exports("GetCurrentId", ServerLocations.GetCurrentId)
exports("GetCurrent", ServerLocations.GetCurrent)
exports("HasFunction", ServerLocations.HasFunction)
exports("WrongServerMessage", ServerLocations.WrongServerMessage)
exports("RequiresSafezoneToSwitch", ServerLocations.RequiresSafezoneToSwitch)

local function FadeOut()
    DoScreenFadeOut(ConfigServerLocations.FadeOutMs or 400)
    local timeout = GetGameTimer() + 2500
    while not IsScreenFadedOut() and GetGameTimer() < timeout do
        Wait(0)
    end
end

local function FadeIn()
    DoScreenFadeIn(ConfigServerLocations.FadeInMs or 700)
    local timeout = GetGameTimer() + 2500
    while not IsScreenFadedIn() and GetGameTimer() < timeout do
        Wait(0)
    end
end

RegisterNetEvent("cfx-keydi-serverlocations:client:prepareSwitch", function(location)
    switching = true
    ApplyClientLocation(location)
    FadeOut()
    TriggerServerEvent("cfx-keydi-serverlocations:server:finishSwitch", location and location.id)
end)

RegisterNetEvent("cfx-keydi-serverlocations:client:applied", function(location)
    switching = false

    if location then
        ApplyClientLocation(location)
        TriggerEvent("cfx-keydi-serverlocations:changed", location)
        Notify(("Switched to %s."):format(location.name or "destination"), "success")
        DebugLog(("applied id=%s bucket=%s"):format(tostring(location.id), tostring(location.bucket)))
        -- Keep Regions NUI Active Server badge in sync if the page is still mounted
        SendNUIMessage({
            action = "cfx-keydi-serverlocations:applied",
            location = location,
        })
    end

    FadeIn()
end)

RegisterNetEvent("cfx-keydi-serverlocations:client:switchFailed", function(message)
    switching = false
    if message then
        Notify(message, "error")
    end
    SendNUIMessage({
        action = "cfx-keydi-serverlocations:switchFailed",
        message = message,
    })
    if IsScreenFadedOut() then
        FadeIn()
    end
end)

RegisterNetEvent("cfx-keydi-serverlocations:client:sync", function(location)
    if not location then return end
    ApplyClientLocation(location)
    TriggerEvent("cfx-keydi-serverlocations:changed", location)
end)

AddStateBagChangeHandler("grimServerId", ("player:%s"):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    if switching or not value then return end
    ConfigServerLocations.SetClientCurrentId(value)
    local loc = ConfigServerLocations.GetById(value)
    if loc then
        TriggerEvent("cfx-keydi-serverlocations:changed", loc)
    end
end)

RegisterNetEvent("esx:playerLoaded", function()
    CreateThread(function()
        Wait(1500)
        TriggerServerEvent("cfx-keydi-serverlocations:server:verifyBucket")
        local loc = ServerLocations.GetCurrent()
        if loc then
            TriggerEvent("cfx-keydi-serverlocations:changed", loc)
        end
    end)
end)

RegisterNetEvent("esx:onPlayerSpawn", function()
    CreateThread(function()
        Wait(1200)
        TriggerServerEvent("cfx-keydi-serverlocations:server:verifyBucket")
    end)
end)

CreateThread(function()
    Wait(2000)
    local loc = ServerLocations.GetCurrent()
    if loc then
        TriggerEvent("cfx-keydi-serverlocations:changed", loc)
    end
end)

-- Replicated combat flag so region switches cannot be used to bail mid-fight.
CreateThread(function()
    while not LocalPlayer or not LocalPlayer.state do
        Wait(100)
    end
    local lastCombat = 0
    local flagged = false
    while true do
        local ped = cache and cache.ped or PlayerPedId()
        local shooting = IsPedShooting(ped)
        local melee = IsPedInMeleeCombat(ped)
        local damaged = HasEntityBeenDamagedByAnyPed(ped) or HasEntityBeenDamagedByAnyVehicle(ped)
        if shooting or melee or damaged then
            lastCombat = GetGameTimer()
            if damaged then
                ClearEntityLastDamageEntity(ped)
            end
            if not flagged then
                flagged = true
                LocalPlayer.state:set('inCombat', true, true)
            end
            Wait(200)
        else
            if flagged and (GetGameTimer() - lastCombat) > 15000 then
                flagged = false
                LocalPlayer.state:set('inCombat', false, true)
            end
            Wait(400)
        end
    end
end)
