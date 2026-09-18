if GetResourceState('es_extended') ~= 'started' then return end
local ESX = exports['es_extended']:getSharedObject()
local prisonJob = require 'configs.prisonjob'
local prisonModules = require 'modules.client.prison'

local busy = false
local createdZones = {}
local playerState = LocalPlayer.state
local nextJobAt = 0

local function notify(title, message, nType, duration)
    local kind = nType
    if kind == 'inform' then kind = 'info' end

    if lib and lib.notify then
        lib.notify({
            title = title or 'PRISON',
            description = message or '',
            type = kind or 'info',
            duration = duration or 5000,
        })
        return
    end

    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(message or title or '', kind, duration or 5000)
    end
end

RegisterNetEvent('esx:playerLoaded', function()
    TriggerEvent('xt-prison:client:onLoad')
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    TriggerEvent('xt-prison:client:onUnload')
end)

local function formatCooldown(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    if mins > 0 then
        return ('%dm %02ds'):format(mins, secs)
    end
    return ('%ds'):format(secs)
end

local function FixWirings(id)
    if busy then return end
    if (playerState.jailTime or 0) <= 0 then
        prisonModules.exitPrison(true)
        return
    end

    local cooldownSec = tonumber(prisonJob.Welding.cooldown) or 0
    local remain = nextJobAt - GetGameTimer()
    if cooldownSec > 0 and remain > 0 then
        notify('PRISON', (locale('notify.work_cooldown') or 'Next job available in %s.'):format(formatCooldown(remain / 1000)), 'error', 4000)
        return
    end

    busy = true
    TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_WELDING', 0, false)
    local count = math.random(prisonJob.skillCheck.count.min, prisonJob.skillCheck.count.max)
    local keys = prisonJob.skillCheck.keys[math.random(1, #prisonJob.skillCheck.keys)]
    local skill = {}
    for _ = 1, count do
        skill[#skill + 1] = 'easy'
    end

    local success = lib.skillCheck(skill, keys)
    lib.hideTextUI()
    ClearPedTasks(cache.ped)

    if not success then
        busy = false
        notify('PRISON', 'You failed the work. Try another spot.', 'error', 4000)
        return
    end

    local result = lib.callback.await('xt-prison:server:completeWork', false, id)
    busy = false

    if not result or not result.ok then
        if result and result.error == 'cooldown' then
            nextJobAt = GetGameTimer() + ((result.remain or 0) * 1000)
            notify('PRISON', (locale('notify.work_cooldown') or 'Next job available in %s.'):format(formatCooldown(result.remain)), 'error', 4000)
            return
        end
        notify('PRISON', 'Work was not counted. Stay at the spot and try again.', 'error', 4000)
        return
    end

    if cooldownSec > 0 then
        nextJobAt = GetGameTimer() + (cooldownSec * 1000)
        prisonJob.Welding.locations[id].state = false
        SetTimeout(cooldownSec * 1000, function()
            if prisonJob.Welding.locations[id] then
                prisonJob.Welding.locations[id].state = true
            end
        end)
    end

    notify('PRISON', (locale('notify.work_reduced') or 'Sentence reduced by %s month(s). You received food and a drink.'):format(result.reduced), 'success', 6000)

    if (result.jailTime or 0) <= 0 then
        prisonModules.exitPrison(true)
    end
end

local function nearbyFixZone(point)
    if not playerState.inJail or busy then return end

    local cooldownSec = tonumber(prisonJob.Welding.cooldown) or 0
    local remain = cooldownSec > 0 and (nextJobAt - GetGameTimer()) or 0
    local canWork = prisonJob.Welding.locations[point.fixIndex].state and (playerState.jailTime or 0) > 0 and remain <= 0
    if not canWork and remain <= 0 and (playerState.jailTime or 0) <= 0 then
        return
    end

    DrawMarker(2, point.coords.x, point.coords.y, point.coords.z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 255, 58, 58, 180, false, true, 2, true, nil, nil, false)
    if point.interact < point.currentDistance then
        if point.isTextUI then
            point.isTextUI = false
            lib.hideTextUI()
        end
        return
    end

    local prompt = remain > 0 and ('Cooldown %s'):format(formatCooldown(remain / 1000)) or '[E] Prison Work'
    if not point.isTextUI then
        point.isTextUI = true
        lib.showTextUI(prompt, {
            position = 'bottom-center',
            icon = 'fa-solid fa-briefcase',
            style = {
                backgroundColor = '#2a2a2a',
                color = '#f0f0f0',
                padding = '16px 20px',
                fontSize = '15px',
                fontWeight = '500',
                fontFamily = 'Segoe UI, sans-serif',
                borderRadius = '13px',
                boxShadow = '8px 8px 15px rgba(0,0,0,0.4)',
                border = '1px solid rgba(255, 255, 255, 0.05)',
            }
        })
    end

    if remain <= 0 and IsControlJustPressed(0, 38) then
        FixWirings(point.fixIndex)
    end
end

local function LoadPrisonJob()
    CreateThread(function()
        for i = 1, #prisonJob.Welding.locations do
            local data = prisonJob.Welding.locations[i]
            createdZones[i] = lib.points.new({
                coords = data.coords,
                distance = data.distance.marker,
                interact = data.distance.interact,
                fixIndex = i,
                nearby = nearbyFixZone
            })
        end
    end)
    CreateThread(function()
        while playerState.inJail do
            local timeLeft = tonumber(playerState.jailTime) or 0
            if timeLeft > 0 then
                notify('PRISON', ('You have %s month(s) left. Work spots cut 1-3 months.'):format(timeLeft), 'info', 5000)
            else
                prisonModules.exitPrison(true)
                break
            end
            Wait(60000)
        end
    end)
end

exports('LoadPrisonJob', LoadPrisonJob)

local function UnloadPrisonJob()
    for i = 1, #prisonJob.Welding.locations do
        if createdZones[i] then
            createdZones[i]:remove()
            createdZones[i] = nil
        end
        prisonJob.Welding.locations[i].state = true
    end
    nextJobAt = 0
    lib.hideTextUI()
end

exports('UnloadPrisonJob', UnloadPrisonJob)
