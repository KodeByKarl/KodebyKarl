local playerState           = LocalPlayer.state
playerState.inJail = false
local config                = require 'configs.client'
local prisonBreakcfg        = require 'configs.prisonbreak'
local prisonBreakModules    = require 'modules.client.prisonbreak'
local utils                 = require 'modules.client.utils'
local resources             = require 'bridge.compat.resources'

local inJail = false

local mainBlip
local PrisonZone

local prisonModules = {}

-- Set Jail Time --
function prisonModules.setJailTime(jailTime)
    if playerState.jailTime == jailTime then
        return true
    end

    playerState:set('jailTime', jailTime, true)

    while playerState.jailTime ~= jailTime do
        Wait(1)
    end

    return (playerState.jailTime == jailTime)
end

local CheckOutZones = {}

local function tryReleaseFromCheckout()
    local timeLeft = lib.callback.await('xt-prison:server:checkJailTime', false)
    if timeLeft and timeLeft <= 0 then
        prisonModules.exitPrison(true)
    end
end

local function checkoutOptions()
    return {
        {
            label = locale('input.check_time'),
            icon = 'fas fa-hourglass-start',
            onSelect = function()
                tryReleaseFromCheckout()
            end
        },
        {
            label = locale('notify.leave_prison') or 'Leave Prison',
            icon = 'fas fa-door-open',
            canInteract = function()
                return (LocalPlayer.state.jailTime or 0) <= 0
            end,
            onSelect = tryReleaseFromCheckout
        }
    }
end

local function addCheckoutZone(id, info)
    if not info or not info.coords then return end
    if resources.qb_target then
        CheckOutZones[id] = exports['qb-target']:AddBoxZone(id, info.coords, info.size[1], info.size[2], {
            name = id,
            heading = info.rotation,
            debugPoly = config.DebugPoly,
            minZ = info.minZ,
            maxZ = info.maxZ,
        }, {
            options = {
                {
                    type = "client",
                    icon = "fas fa-hourglass-start",
                    label = locale('input.check_time'),
                    action = tryReleaseFromCheckout
                },
                {
                    type = "client",
                    icon = "fas fa-door-open",
                    label = locale('notify.leave_prison') or 'Leave Prison',
                    canInteract = function()
                        return (LocalPlayer.state.jailTime or 0) <= 0
                    end,
                    action = tryReleaseFromCheckout
                },
            },
            distance = 2.5
        })
    else
        CheckOutZones[id] = exports.ox_target:addBoxZone({
            coords = info.coords,
            size = info.size,
            rotation = info.rotation,
            debug = config.DebugPoly,
            drawsprite = true,
            options = checkoutOptions()
        })
    end
end

-- Create Checkout Location --
function prisonModules.createCheckoutLocation()
    addCheckoutZone('CheckOutZone', config.CheckOut)
    addCheckoutZone('YardCheckOutZone', config.YardCheckOut)
end

-- Remove Checkout Location --
function prisonModules.removeCheckoutLocation()
    for id, zone in pairs(CheckOutZones) do
        if resources.qb_target then
            exports['qb-target']:RemoveZone(id)
        elseif zone then
            exports.ox_target:removeZone(zone)
        end
        CheckOutZones[id] = nil
    end
end

-- Create Prison Zone for Prison Break Distance Checks --
function prisonModules.createPrisonZone()
    PrisonZone = lib.points.new({
        coords = prisonBreakcfg.Center,
        distance =  prisonBreakcfg.Radius,
    })

    function PrisonZone:onExit()
        if inJail then
            SetEntityCoords(cache.ped, 1725.638, 2537.816, 43.585)
        end
        -- if inJail then
        --     inJail = false
        --     local alarm = lib.callback.await('xt-prison:server:setPrisonAlarms', false, true)
        --     if alarm then
        --         lib.notify({ title = locale('notify.escaped'), type = ' error' })
        --         TriggerServerEvent('xt-prison:server:triggerBreakout')
        --         config.Dispatch(prisonBreakcfg.Center)
        --     end
        -- end
    end

    if not resources.xt_prisonjobs then
        -- mainBlip = utils.createBlip('Prison', prisonBreakcfg.Center, 60, 0.7, 3)
    end
end

-- Removes All Prison Zones, Blips, etc --
function prisonModules.prisonCleanup()
    TriggerServerEvent('xt-prison:server:saveJailTime')
    PrisonZone:remove()
    prisonModules.removeCheckoutLocation()
    prisonBreakModules.removeBlip()
    prisonBreakModules.removeHackZones()

    if DoesBlipExist(mainBlip) then
        RemoveBlip(mainBlip)
    end
end

-- Sets Player's Coords --
function prisonModules.setPlayerCoords(coords)
    local x, y, z = coords.x + 0.0, coords.y + 0.0, coords.z + 0.0
    local heading = coords.w or coords.h or 0.0
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(cache.ped, x, y, z, false, false, false)
    SetEntityHeading(cache.ped, heading)
    local dist = #(vec3(x, y, z) - GetEntityCoords(cache.ped))
    return dist <= 8.0
end

local function waitForCollision(coords, timeoutMs)
    local x, y, z = coords.x + 0.0, coords.y + 0.0, coords.z + 0.0
    RequestCollisionAtCoord(x, y, z)
    local deadline = GetGameTimer() + (timeoutMs or 8000)
    while not HasCollisionLoadedAroundEntity(cache.ped) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, z)
        Wait(50)
    end
    return HasCollisionLoadedAroundEntity(cache.ped)
end

local function ensureScreenFadeIn(duration)
    duration = duration or 800
    if IsScreenFadedOut() or IsScreenFadingOut() then
        DoScreenFadeIn(duration)
        local deadline = GetGameTimer() + duration + 1500
        while not IsScreenFadedIn() and GetGameTimer() < deadline do
            if IsScreenFadedOut() then
                DoScreenFadeIn(0)
            end
            Wait(25)
        end
    end
    if IsScreenFadedOut() then
        DoScreenFadeIn(0)
    end
end

-- Entering Prison --
function prisonModules.enterPrison(setTime)
    local setServerJailTime = lib.callback.await('xt-prison:server:setJailStatus', false, setTime)
    if not setServerJailTime then
        return false
    end

    if config.RemoveJob then
        local removed = lib.callback.await('xt-prison:server:removeJob', false)
        if not removed then
            return false
        end
    end

    local setJailTime = prisonModules.setJailTime(setTime)
    if setJailTime then
        if GetResourceState('cfx-keydi-radio') == 'started' then
            exports['cfx-keydi-radio']:leaveRadio()
        elseif GetResourceState('ac_radio') == 'started' then
            exports['ac_radio']:leaveRadio()
        end
        TriggerServerEvent('xt-prison:server:removeItems')
        local isLifer = lib.callback.await('xt-prison:server:liferCheck', false)

        -- Watchdog: never leave the player faded out if teleport / collision hangs.
        local fadeWatchdog = true
        CreateThread(function()
            Wait(12000)
            if fadeWatchdog and (IsScreenFadedOut() or IsScreenFadingOut()) then
                ensureScreenFadeIn(0)
            end
        end)

        DoScreenFadeOut(1000)
        local fadeOutDeadline = GetGameTimer() + 2500
        while not IsScreenFadedOut() and GetGameTimer() < fadeOutDeadline do
            Wait(25)
        end

        local RandomSpawn = config.Spawns[math.random(1, #config.Spawns)]
        FreezeEntityPosition(cache.ped, true)
        prisonModules.setPlayerCoords(RandomSpawn.coords)
        waitForCollision(RandomSpawn.coords, 8000)

        if config.EnablePrisonOutfits then
            pcall(prisonModules.applyPrisonUniform)
        end
        inJail = true
        playerState:set('inJail', true, true)

        FreezeEntityPosition(cache.ped, false)

        pcall(function()
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "jail", 0.5)
        end)

        pcall(function()
            config.Emote(RandomSpawn.emote)
        end)
        prisonModules.createCheckoutLocation()

        fadeWatchdog = false
        ensureScreenFadeIn(1000)

        if config.EnterPrisonAlert.enable and not isLifer then
            CreateThread(function()
                local alertInfo = config.EnterPrisonAlert
                lib.alertDialog({
                    header = alertInfo.header,
                    content = (locale('input.prison_sentence')):format(setTime, alertInfo.content),
                    centered = true,
                    labels = { confirm = 'Close' }
                })
            end)
        elseif config.EnterPrisonAlert.enable and isLifer then
            lib.notify({ title = locale('notify.lifer'), type = 'error' })
        end

        if not isLifer then
            prisonModules.timeReductionLoop()
        end

        if resources.xt_prisonjobs then
            pcall(function()
                exports['xt-prisonjobs']:InitPrisonJob()
            end)
        end
        pcall(function()
            exports['xt-prison']:LoadPrisonJob()
        end)
        return true
    end

    return false
end

-- Exiting Prison --
function prisonModules.exitPrison(isUnjailed)
    if not inJail and not playerState.inJail and (playerState.jailTime or 0) <= 0 then
        return true
    end
    if playerState.jailTime > 0 and not isUnjailed then
        lib.notify({ title = (locale('notify.time_left')):format(playerState.jailTime), type = 'error' })
        return false
	elseif playerState.jailTime <= 0 or isUnjailed then
        local setJailTime = prisonModules.setJailTime(0)
        if setJailTime then
            inJail = false
            playerState:set('inJail', false, true)

            local fadeWatchdog = true
            CreateThread(function()
                Wait(10000)
                if fadeWatchdog and (IsScreenFadedOut() or IsScreenFadingOut()) then
                    ensureScreenFadeIn(0)
                end
            end)

            DoScreenFadeOut(1000)
            local fadeOutDeadline = GetGameTimer() + 2500
            while not IsScreenFadedOut() and GetGameTimer() < fadeOutDeadline do
                Wait(25)
            end

            if config.EnablePrisonOutfits then
                pcall(config.ResetClothing)
            end

            prisonModules.setPlayerCoords(config.Freedom)
            waitForCollision(config.Freedom, 6000)

            Wait(250)
            fadeWatchdog = false
            ensureScreenFadeIn(1000)

            lib.callback.await('xt-prison:server:setJailStatus', false, 0)
            Wait(150)
            TriggerServerEvent('xt-prison:server:returnItems')

            if resources.xt_prisonjobs then
                pcall(function()
                    exports['xt-prisonjobs']:CleanupPrisonJob()
                end)
            end
            pcall(function()
                exports['xt-prison']:UnloadPrisonJob()
            end)
            return true
        end
	end

    return false
end

-- Reduce Jail Time Loop --
function prisonModules.timeReductionLoop()
    CreateThread(function()
        while inJail do
            Wait(60000)
            if not inJail then
                break
            end
            if playerState.jailTime > 0 then
                local newTime = (playerState.jailTime - 1)
                prisonModules.setJailTime(newTime)
                TriggerServerEvent('xt-prison:server:persistJailTime')
            end

            if (playerState.jailTime or 0) <= 0 then
                lib.notify({
                    title = locale('notify.checkout'),
                    icon = 'fas fa-unlock',
                    type = 'success'
                })
                local timeLeft = lib.callback.await('xt-prison:server:checkJailTime', false)
                if timeLeft and timeLeft <= 0 then
                    prisonModules.exitPrison(true)
                end
                break
            end
        end
    end)
end

function prisonModules.applyPrisonUniform()
    local isMale = IsPedModel(cache.ped, `mp_m_freemode_01`)
    local outifitInfo = isMale and config.PrisonOufits.male or config.PrisonOufits.female
    if not outifitInfo then return end

    local function setComponent(slot, drawable, texture)
        drawable = tonumber(drawable) or 0
        texture = tonumber(texture) or 0
        local drawCount = GetNumberOfPedDrawableVariations(cache.ped, slot)
        if drawCount <= 0 then return end
        if drawable < 0 or drawable >= drawCount then
            drawable = 0
        end
        local texCount = GetNumberOfPedTextureVariations(cache.ped, slot, drawable)
        if texCount <= 0 then
            texture = 0
        elseif texture < 0 or texture >= texCount then
            texture = math.max(0, texCount - 1)
        end
        SetPedComponentVariation(cache.ped, slot, drawable, texture, 0)
    end

    setComponent(1, outifitInfo.mask.item, outifitInfo.mask.texture)
    setComponent(3, outifitInfo.arms.item, outifitInfo.arms.texture)
    setComponent(4, outifitInfo.pants.item, outifitInfo.pants.texture)
    setComponent(5, outifitInfo.bags and outifitInfo.bags.item or 0, outifitInfo.bags and outifitInfo.bags.texture or 0)
    setComponent(6, outifitInfo.shoes.item, outifitInfo.shoes.texture)
    setComponent(7, outifitInfo.accessories.item, outifitInfo.accessories.texture)
    setComponent(8, outifitInfo.shirt.item, outifitInfo.shirt.texture)
    setComponent(9, outifitInfo.bodyArmor and outifitInfo.bodyArmor.item or 0, outifitInfo.bodyArmor and outifitInfo.bodyArmor.texture or 0)
    setComponent(10, outifitInfo.decals and outifitInfo.decals.item or 0, outifitInfo.decals and outifitInfo.decals.texture or 0)
    setComponent(11, outifitInfo.jacket.item, outifitInfo.jacket.texture)
end

return prisonModules