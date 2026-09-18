local playing_pvp = false
local isPlaying = false
local attempt_exit = false
local Dead = false
local leaveCoords = nil
local exitPeds = {}

LocalPlayer.state:set('inPvp', false, true)
LocalPlayer.state:set('isInPvp', false, true)

local function SetPvpState(enabled)
    LocalPlayer.state:set('inPvp', enabled, true)
    LocalPlayer.state:set('isInPvp', enabled, true)
end

local function Notify(msg, nType)
    lib.notify({
        title = 'PvP',
        description = msg,
        type = nType or 'inform',
        position = 'center-left',
    })
end

local function TeleportTo(coords)
    local ped = PlayerPedId()
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)
end

local function GiveLoadout()
    TriggerServerEvent('kodebykarl-pvp:giveLoadout')
    SetPedArmour(PlayerPedId(), 100)
    if GetResourceState('jg-hud') == 'started' then
        TriggerServerEvent('hud:server:RelieveStress', 1000000)
    end
end

local function WaitUntilAlive(timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 10000)
    local started = false
    while GetGameTimer() < deadline do
        if LocalPlayer.state.isReviving then
            started = true
        end
        local ped = PlayerPedId()
        local alive = ped and ped ~= 0 and not IsEntityDead(ped) and not IsPedFatallyInjured(ped)
        -- Return as soon as the ped is up. Do not wait for ambulance's post-revive guard
        -- (~3s) — that was causing a visible delay after standing back up.
        if started and alive then
            return true
        end
        Wait(50)
    end
    return false
end

local function ArenaRespawn()
    -- Fade out before revive so the kill spot is never shown after the deathscreen.
    DoScreenFadeOut(150)
    local fadeDeadline = GetGameTimer() + 1500
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
        Wait(0)
    end

    TriggerServerEvent('kodebykarl-pvp:requestRevive')
    WaitUntilAlive(10000)
    if not playing_pvp then return end
    GiveLoadout()
    Dead = false
    -- Ambulance RespawnPed clears armour/weapons during appearance restore.
    CreateThread(function()
        local deadline = GetGameTimer() + 8000
        while LocalPlayer.state.isReviving and GetGameTimer() < deadline do
            Wait(50)
        end
        if playing_pvp and not Dead then
            GiveLoadout()
        end
    end)
end

local function DeleteExitPeds()
    for i = 1, #exitPeds do
        local ped = exitPeds[i]
        if ped and DoesEntityExist(ped) then
            exports.ox_target:removeLocalEntity(ped)
            DeleteEntity(ped)
        end
    end
    exitPeds = {}
end

local function SpawnExitPeds()
    DeleteExitPeds()
    for _, zone in ipairs(Config.ExitPed) do
        local model = joaat(zone.ModelName)
        RequestModel(model)
        local deadline = GetGameTimer() + 5000
        while not HasModelLoaded(model) and GetGameTimer() < deadline do
            Wait(10)
        end
        if HasModelLoaded(model) then
            local pos = zone.ModelPosition
            local ped = CreatePed(4, model, pos.x, pos.y, pos.z - 1.0, pos.w, false, true)
            SetEntityAsMissionEntity(ped, true, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedDiesWhenInjured(ped, false)
            SetPedCanRagdollFromPlayerImpact(ped, false)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            if zone.ModelScenario then
                TaskStartScenarioInPlace(ped, zone.ModelScenario, 0, true)
            end
            SetModelAsNoLongerNeeded(model)

            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'kodebykarl_pvp_exit',
                    icon = 'fa-solid fa-skull',
                    label = 'Exit Deathmatch Mode',
                    distance = 2.0,
                    onSelect = function()
                        TriggerEvent('kodebykarl-pvp:client:leave')
                    end,
                },
            })

            exitPeds[#exitPeds + 1] = ped
        end
    end
end

local function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(_x, _y)
    local factor = (#text) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

exports('playingPvPDeathmatch', function()
    return playing_pvp
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    if not playing_pvp or Dead then return end
    Dead = true

    local playerPed = cache.ped
    local victimCoords = GetEntityCoords(playerPed)
    local killedByPlayer = data and data.killedByPlayer == true
    local killerServerId = killedByPlayer and tonumber(data.killerServerId) or 0
    local killerClientId = killedByPlayer and tonumber(data.killerClientId) or -1

    if killedByPlayer and killerServerId > 0 and (not killerClientId or killerClientId < 0 or not NetworkIsPlayerActive(killerClientId)) then
        local resolved = GetPlayerFromServerId(killerServerId)
        if resolved and resolved >= 0 then
            killerClientId = resolved
        end
    end

    local killerCoords = victimCoords
    if killedByPlayer and killerClientId and killerClientId >= 0 and NetworkIsPlayerActive(killerClientId) then
        local killerPed = GetPlayerPed(killerClientId)
        if killerPed and killerPed ~= 0 then
            killerCoords = GetEntityCoords(killerPed)
        end
    end

    TriggerServerEvent('kodebykarl-pvp:OnDeath', {
        killedByPlayer = killedByPlayer,
        killerServerId = killerServerId,
        killerClientId = killerClientId,
        victimCoords = { x = victimCoords.x, y = victimCoords.y, z = victimCoords.z },
        killerCoords = { x = killerCoords.x, y = killerCoords.y, z = killerCoords.z },
    })

    CreateThread(function()
        Wait(Config.DeathScreenMs or 5000)
        if playing_pvp and Dead then
            ArenaRespawn()
        else
            Dead = false
        end
    end)
end)

RegisterNetEvent('kodebykarl-pvp:startMatch', function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    leaveCoords = vector4(c.x, c.y, c.z, GetEntityHeading(ped))
    playing_pvp = true
    isPlaying = false
    attempt_exit = false
    Dead = false
    SetPvpState(true)
    SpawnExitPeds()
end)

RegisterNetEvent('kodebykarl-pvp:endMatch', function()
    playing_pvp = false
    isPlaying = false
    attempt_exit = false
    Dead = false
    SetPvpState(false)
    SetLocalPlayerAsGhost(false)
    DeleteExitPeds()
    TriggerEvent('ox_inventory:disarm', true)
    RemoveAllPedWeapons(PlayerPedId(), true)
    SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
    SetPedArmour(PlayerPedId(), 0)

    local dest = leaveCoords or Config.Leave
    leaveCoords = nil
    TeleportTo(dest)
end)

RegisterNetEvent('kodebykarl-pvp:joinDenied', function(reason)
    Notify(reason or 'Could not join deathmatch.', 'error')
end)

local function RequestJoin()
    if playing_pvp then
        Notify('You are already in deathmatch.', 'error')
        return
    end

    local confirmation = lib.alertDialog({
        header = 'WARNING: ALL ITEMS IN YOUR INVENTORY WILL BE WIPED EXCEPT CASH. DO YOU WANT TO PROCEED?',
        centered = true,
        cancel = true,
        size = 'xs',
    })

    if confirmation == 'confirm' then
        TriggerServerEvent('kodebykarl-pvp:requestJoin')
    end
end

local function RequestLeave()
    if not playing_pvp then return end

    local confirmation = lib.alertDialog({
        header = 'ARE YOU SURE YOU WANT TO EXIT DEATHMATCH MODE?',
        centered = true,
        cancel = true,
        size = 'xs',
    })

    if confirmation == 'confirm' then
        TriggerServerEvent('kodebykarl-pvp:requestLeave')
    end
end

AddEventHandler('kodebykarl-pvp:client:joinFromIpad', RequestJoin)
AddEventHandler('kodebykarl-pvp:client:leaveFromIpad', RequestLeave)
AddEventHandler('kodebykarl-pvp:client:leave', RequestLeave)
AddEventHandler('cfx-bwd-pvp:enter', RequestJoin)
AddEventHandler('cfx-bwd-pvp:exit', RequestLeave)

lib.zones.poly({
    points = Config.Points,
    thickness = Config.Thickness or 4,
    onEnter = function()
        SetPvpState(true)
    end,
    onExit = function()
        if playing_pvp then
            attempt_exit = true
        else
            SetPvpState(false)
        end
    end,
    debug = false,
})

lib.zones.poly({
    points = Config.Safe,
    thickness = 4,
    onEnter = function()
        if playing_pvp then
            SetLocalPlayerAsGhost(true)
        end
    end,
    onExit = function()
        if playing_pvp then
            SetLocalPlayerAsGhost(false)
        end
    end,
    debug = false,
})

CreateThread(function()
    while true do
        if playing_pvp then
            if attempt_exit then
                Wait(1000)
                TeleportTo(Config.Enter)
                attempt_exit = false
            end

            if not isPlaying then
                Wait(1000)
                TeleportTo(Config.Enter)
                GiveLoadout()
                isPlaying = true
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        if playing_pvp then
            local coords = GetEntityCoords(PlayerPedId())
            for i = 1, #Config.Locker do
                local data = Config.Locker[i]
                local dist = #(coords - data.pos)
                if dist <= 0.5 then
                    sleep = 0
                    Draw3DText(data.pos.x, data.pos.y, data.pos.z, data.label)
                    if IsControlJustReleased(0, 38) then
                        exports.ox_inventory:openInventory('stash', 'deathmatch-locker')
                    end
                elseif dist <= 10 then
                    sleep = 0
                    DrawMarker(2, data.pos.x, data.pos.y, data.pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 30, 150, 30, 222, false, false, false, true, false, false, false)
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    DeleteExitPeds()
    SetLocalPlayerAsGhost(false)
    SetPvpState(false)
end)
