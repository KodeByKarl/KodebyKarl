local ox_target = exports.ox_target
local _AddStateBagChangeHandler = AddStateBagChangeHandler
local _CreateThread = CreateThread
local playerState = LocalPlayer.state
playerState.inTraphouse = false
local BigHeist = {
    isBusy = {},
    timer = {},
    destroy = {},
    markerCache = {},
    blipCache = {},
    locationBlips = {}, -- always-on map blips for robbery locations
    debugBlipCache = {},
    debugPointsCache = {},
    loaded = false,
}

local function DrawMarkerSimple(coords, r, g, b, a)
    if not coords then return end
    DrawMarker(
        1,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.6, 0.6, 0.35,
        r or 255, g or 0, b or 0, a or 160,
        false, false, 2, false, nil, nil, false
    )
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (#text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function getHeistCoords(value)
    if not value then return nil end
    if value.coords then
        return type(value.coords) == 'vector4' and vec3(value.coords.x, value.coords.y, value.coords.z) or value.coords
    end
    if value.ped and value.ped.coords then
        local c = value.ped.coords
        return vec3(c.x, c.y, c.z)
    end
    if value.marker and value.marker.coords then
        return value.marker.coords
    end
    return nil
end

--- Permanent map blip for robberies (big heists only — store blips are hidden).
--- Fixed 0.5 size, sprite 255, no scale adjustments on pause map.
local function createLocationBlip(heistKey, value)
    if not value then return end
    -- Store robberies use marker zones (no ped) — hide their always-on map blips
    if value.marker and not value.ped then
        return
    end
    if value.settings and value.settings.showMapBlip == false then
        return
    end
    if value.settings and value.settings.autoBlip == false then
        return
    end

    local coords = getHeistCoords(value)
    if not coords then return end

    if BigHeist.locationBlips[heistKey] and DoesBlipExist(BigHeist.locationBlips[heistKey]) then
        RemoveBlip(BigHeist.locationBlips[heistKey])
        BigHeist.locationBlips[heistKey] = nil
    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 255)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)
    SetBlipDisplay(blip, 4)
    SetBlipHighDetail(blip, true)
    SetBlipCategory(blip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(value.label or heistKey)
    EndTextCommandSetBlipName(blip)
    BigHeist.locationBlips[heistKey] = blip
end

function StartBigHeist(data)
    local key = data.args.key
    local config = Config.Heist[key]
    if not config then return end

    local canRob = lib.callback.await('cfx-cs-robbery:check', false, key)
    if not canRob then return end

    if config.requireItem and next(config.requireItem) then
        local hasItem = HasItem(config.requireItem)
        if not hasItem then return end
    end

    if config.minigame then
        if config.minigame.game == 'lockpick' then
            local success = exports['cfx-cs-lockpick']:StartLockpickGame(config.minigame.lockpickCount)
            if not success then
                ESX.Notify('ROBBERY - '..config.label, 'Failed.', 'error', 5000)
                return
            end
        end
        if config.minigame.game == 'skillCheck' then
            local success = lib.skillCheck(config.minigame.skillCheck, {'w', 'a', 's', 'd'})
            if not success then
                ESX.Notify('ROBBERY - '..config.label, 'Failed.', 'error', 5000)
                return
            end
        end
    end

    TriggerServerEvent('cfx-cs-robbery:StartTimer', key)
end

local function setStateBagHandlers(blipId, notifyId, gubed)
    _AddStateBagChangeHandler(blipId, "global", function(_, theGlobalKey, value)
        local theKey = theGlobalKey:gsub('_blip', '')
        local config = Config.Heist[theKey]
        if not config then return end
        if value then
            local coords = getHeistCoords(config)
            if not coords then return end
            BigHeist.blipCache[blipId] = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(BigHeist.blipCache[blipId], 161)
            SetBlipScale(BigHeist.blipCache[blipId], 1.5)
            SetBlipColour(BigHeist.blipCache[blipId], 1)
            PulseBlip(BigHeist.blipCache[blipId])
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName('Illegal Activity')
            EndTextCommandSetBlipName(BigHeist.blipCache[blipId])
        else
            if BigHeist.blipCache[blipId] and DoesBlipExist(BigHeist.blipCache[blipId]) then
                RemoveBlip(BigHeist.blipCache[blipId])
                BigHeist.blipCache[blipId] = nil
            end
        end
    end)
    if notifyId then
        _AddStateBagChangeHandler(notifyId, "global", function(_, theGlobalKey, value)
            local theKey = theGlobalKey:gsub('_notify', '')
            local config = Config.Heist[theKey]
            if value and config then
                lib.notify({
                    title = 'Illegal Activity',
                    description = 'Ongoing '..config.label,
                    duration = 15000,
                    position = 'top-center',
                    icon = 'bullhorn',
                    iconColor = '#E53E3E',
                })
            end
        end)
    end

    if gubed then
        _AddStateBagChangeHandler(gubed, "global", function(_, theGlobalKey, value)
            local theKey = theGlobalKey:gsub('_debug', '')
            local config = Config.Heist[theKey]
            if not config then return end
            local coords = getHeistCoords(config)
            if not coords then return end
            if value then
                local cPoint = lib.points.new({
                    coords = coords,
                    distance = config.debug.ZoneSize,
                    zoneCoords = coords,
                    blipSize = config.debug.blipSize,
                    ZoneSize = config.debug.ZoneSize
                })
                function cPoint:nearby()
                    DrawMarker(28, self.zoneCoords.x, self.zoneCoords.y, self.zoneCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, self.ZoneSize, self.ZoneSize, self.ZoneSize, 255, 0, 0, 40, false, false, 2, true, false, false, false)
                end
                function cPoint:onEnter()
                    SetInTraphouse(true)
                    if not BigHeist.timer[theKey] and not Player(cache.serverId).state.dead then
                        lib.showTextUI('You are in a traphouse zone. This area is kill on sight.', {
                            position = "bottom-center",
                            icon = 'fa-solid fa-skull-crossbones',
                            iconColor = '#FF0949',
                        })
                    end
                end
                function cPoint:onExit()
                    SetInTraphouse(false)
                    if not BigHeist.timer[theKey] and not Player(cache.serverId).state.dead then
                        lib.hideTextUI()
                    end
                end
                BigHeist.debugPointsCache[theKey] = cPoint
            else
                SetInTraphouse(false)
                if BigHeist.debugPointsCache[theKey] then
                    BigHeist.debugPointsCache[theKey]:remove()
                    BigHeist.debugPointsCache[theKey] = nil
                end
                if BigHeist.debugBlipCache[theKey] then
                    if DoesBlipExist(BigHeist.debugBlipCache[theKey]) then
                        RemoveBlip(BigHeist.debugBlipCache[theKey])
                    end
                    BigHeist.debugBlipCache[theKey] = nil
                end
                if not BigHeist.timer[theKey] and not Player(cache.serverId).state.dead then
                    lib.hideTextUI()
                end
            end
        end)
    end
end

function SetInTraphouse(state)
    if type(state) ~= "boolean" then return end
    playerState.inTraphouse = state
end

function LoadBigHeist()
    if BigHeist.loaded then return end
    if not Config.Heist or not next(Config.Heist) then
        print('^1[kodebykarl-robbery]^0 Config.Heist is empty — check shared/heist/*.lua load order.')
        return
    end

    BigHeist.loaded = true
    _CreateThread(function()
        local count = 0
        for heist, value in pairs(Config.Heist) do
            count = count + 1
            createLocationBlip(heist, value)

            if value.ped then
                local model = value.ped.model
                if type(model) == 'string' then model = joaat(model) end
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end
                local spawnedped = CreatePed(0, model, value.ped.coords.x, value.ped.coords.y, value.ped.coords.z - 1.0, value.ped.coords.w, false, false)
                FreezeEntityPosition(spawnedped, true)
                SetEntityInvincible(spawnedped, true)
                SetBlockingOfNonTemporaryEvents(spawnedped, true)
                ox_target:addLocalEntity(spawnedped, {
                    {
                        icon = 'fa-solid fa-book',
                        label = 'Start '..value.label,
                        onSelect = StartBigHeist,
                        args = {key = heist},
                        distance = 2.5
                    }
                })
                Config.Heist[heist].ped.entity = spawnedped
                Config.Heist[heist].ped.model = model
            end
            if value.marker then
                local cPoint = lib.points.new({
                    coords = value.marker.coords,
                    distance = value.marker.distance,
                    storeName = value.label,
                    heistId = heist
                })
                function cPoint:nearby()
                    if GlobalState[self.heistId] then return end
                    DrawMarkerSimple(self.coords, 255, 0, 0, 160)
                    if self.currentDistance < 2.5 then
                        DrawText3D(self.coords.x, self.coords.y, self.coords.z + 0.35, 'Press ~g~E~w~ to start ~r~'..self.storeName..'~w~')
                        if IsControlJustReleased(0, 38) then
                            StartBigHeist({args = {key = heist}})
                        end
                    end
                end
            end
            if value.settings and value.settings.autoBlip then
                setStateBagHandlers(
                    heist..'_blip',
                    (value.settings.autoAnnounce and heist..'_notify' or false),
                    ((value.debug and value.debug.enable) and heist..'_debug' or false)
                )
            end
        end
        print(('^0[^3kodebykarl-robbery^0]: ^2Heist Loaded (%s locations + map blips).^0'):format(count))
    end)
end

RegisterNetEvent('cfx-cs-robbery:DestroyClient', function(key)
    BigHeist.destroy[key] = true
    Wait(5000)
    BigHeist.destroy[key] = false
end)

local function hideHeistTimer(prompt)
    local open, text = lib.isTextUIOpen()
    if open and (not prompt or text == prompt) then
        lib.hideTextUI()
    end
end

RegisterNetEvent('cfx-cs-robbery:SyncTimer', function(key)
    local config = Config.Heist[key]
    if not config then return end
    BigHeist.timer[key] = config.timer
    _CreateThread(function()
        local prompt
        while true do
            Wait(1000)
            BigHeist.timer[key] -= 1
            prompt = config.label..': '..BigHeist.timer[key]..' seconds remaining'
            lib.showTextUI(prompt, {
                position = "bottom-center",
                icon = 'fa-solid fa-stopwatch',
                iconColor = '#FF0949',
            })
            if BigHeist.timer[key] <= 0 then
                hideHeistTimer(prompt)
                break
            end
            if BigHeist.destroy[key] then
                hideHeistTimer(prompt)
                break
            end
        end
    end)
    _CreateThread(function()
        while true do
            Wait(0)
            local coords = GetEntityCoords(cache.ped)
            local heistCoords = getHeistCoords(config)
            if not heistCoords then break end
            local dist = #(coords - heistCoords)
            if dist > config.distanceToCancel then
                TriggerServerEvent('cfx-cs-robbery:DestroyServer', key)
                break
            end
            if BigHeist.destroy[key] then
                break
            end
        end
    end)
end)

function UnloadBigHeist()
    for k, v in pairs(Config.Heist or {}) do
        if v.ped and v.ped.entity and v.ped.entity ~= 0 then
            DeletePed(v.ped.entity)
            Config.Heist[k].ped.entity = 0
        end
    end
    for key, blip in pairs(BigHeist.locationBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        BigHeist.locationBlips[key] = nil
    end
    for id, blip in pairs(BigHeist.blipCache) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        BigHeist.blipCache[id] = nil
    end
    BigHeist.loaded = false
end

RegisterNetEvent('esx:playerLoaded', function()
    Wait(500)
    LoadBigHeist()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(1000)
    LoadBigHeist()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    UnloadBigHeist()
end)

RegisterNetEvent('cfx-cs-robbery:heist:client:dispatchAlert', function(messageOrData, duration, showNotify)
    -- Back-compat: old signature was (message, duration, showNotify)
    local data = type(messageOrData) == 'table' and messageOrData or {
        message = messageOrData,
        duration = duration,
        showNotify = showNotify,
    }

    if data.showNotify ~= false then
        -- ox_lib only accepts info/warning/success/error — 'police' was silent/broken
        ESX.Notify('10-90 DISPATCH', data.message or '10-90 - Robbery in progress.', 'error', data.duration or 14000)
    end
    PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', true)

    local c = data.coords
    if type(c) ~= 'table' then return end
    local x, y, z = (c.x or 0) + 0.0, (c.y or 0) + 0.0, (c.z or 0) + 0.0
    local blipDuration = tonumber(data.time) or 180000

    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, data.sprite or 161)
    SetBlipColour(blip, data.color or 1)
    SetBlipScale(blip, data.scale or 1.2)
    SetBlipFlashes(blip, true)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.label and ('10-90 - ' .. data.label) or '10-90 Robbery')
    EndTextCommandSetBlipName(blip)
    SetNewWaypoint(x, y)

    local radius = AddBlipForRadius(x, y, z, data.radius or 55.0)
    SetBlipHighDetail(radius, true)
    SetBlipColour(radius, 1)
    SetBlipAlpha(radius, 110)

    CreateThread(function()
        Wait(blipDuration)
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        if DoesBlipExist(radius) then RemoveBlip(radius) end
    end)
end)
