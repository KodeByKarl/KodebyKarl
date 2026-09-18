local config = require 'configs.illegalmenu'
if not config.enable then return end

local Vars = require 'helpers.vars'
local Region = require 'helpers.region'

local dragging = {
    active = false,
    target = nil,
}

local function notify(msg, nType)
    ESX.Notify('ILLEGAL MENU', msg, nType or 'error', 5000)
end

local function getJobName()
    local data = ESX.GetPlayerData()
    local name = data and data.job and data.job.name
    if type(name) ~= 'string' or name == '' then return nil end
    return name:lower()
end

-- On-duty police / EMS / sheriff (offdutypolice etc. still use illegal menu)
local function getOnDutyServiceJob()
    local name = getJobName()
    if not name or name:sub(1, 3) == 'off' then return nil end
    if config.blockedJobs[name] then return name end
    return nil
end

local function openServiceMenu(jobName)
    if jobName == 'police' or jobName == 'sheriff' then
        TriggerEvent('cfx-cs-police:client:openQuickMenu')
        return
    end
    if jobName == 'ambulance' or jobName == 'sambulance' or jobName == 'pambulance' then
        TriggerEvent('cfx-keydi-ambulance:client:openMenu')
    end
end

local function isBlocked()
    if LocalPlayer.state.dead or Vars.playerState.isDead or Vars.playerState.isInTrunk then
        return true
    end
    return getOnDutyServiceJob() ~= nil
end

local function getClosest(maxDist)
    local playerId, playerPed = lib.getClosestPlayer(GetEntityCoords(cache.ped), maxDist or config.distance, false)
    if not playerId then return nil end
    return GetPlayerServerId(playerId), playerPed, playerId
end

local function isCuffedPed(ped, serverId)
    if not ped or ped == 0 then return false end
    if serverId and (Player(serverId).state.cuffed or Player(serverId).state.escorted) then
        return true
    end
    return IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
end

local function isHandsUp(ped)
    return IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 3)
        or IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3)
end

local function hasItem(item)
    if not item or item == '' then return true end
    return (exports.ox_inventory:Search('count', item) or 0) > 0
end

local function playProgress(duration, label, anim)
    return lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = anim,
    })
end

local function cuffPlayer()
    if not hasItem(config.items.cuff) then
        return notify('You need a handcuff.')
    end

    local targetId, targetPed = getClosest(config.cuffDistance)
    if not targetId then
        return notify('No players nearby.')
    end
    if Player(targetId).state.dead then
        return notify('Person appears unconscious.')
    end
    if isCuffedPed(targetPed, targetId) then
        return notify('That person is already cuffed.')
    end

    LocalPlayer.state:set('isCuffing', true, false)
    local ok = playProgress(config.progress.cuff, 'Cuffing...', {
        dict = 'mp_arrest_paired',
        clip = 'cop_p2_back_right',
        flag = 49,
    })
    LocalPlayer.state:set('isCuffing', false, false)
    if not ok then return end

    TriggerServerEvent('cfx-keydi-utils:illegal:cuff', targetId)
end

local function uncuffPlayer()
    if not hasItem(config.items.uncuff) then
        return notify('You need a handcuff key.')
    end

    local targetId, targetPed = getClosest(config.cuffDistance)
    if not targetId then
        return notify('No players nearby.')
    end
    if not isCuffedPed(targetPed, targetId) then
        return notify('That person is not cuffed.')
    end

    local ok = playProgress(config.progress.uncuff, 'Uncuffing...', {
        dict = 'mp_arresting',
        clip = 'a_uncuff',
        flag = 49,
    })
    if not ok then return end

    TriggerServerEvent('cfx-keydi-utils:illegal:uncuff', targetId)
end

local function dragPlayer()
    if dragging.active then
        TriggerServerEvent('cfx-keydi-utils:illegal:drag', dragging.target)
        dragging.active = false
        dragging.target = nil
        return
    end

    if not hasItem(config.items.drag) then
        return notify('You need a rope.')
    end

    local targetId, targetPed = getClosest(config.distance)
    if not targetId then
        return notify('No players nearby.')
    end
    if config.requireCuffedToDrag and not isCuffedPed(targetPed, targetId) then
        return notify('You need to cuff first.')
    end

    TriggerServerEvent('cfx-keydi-utils:illegal:drag', targetId)
    dragging.active = true
    dragging.target = targetId
end

local function searchPlayer()
    local targetId, targetPed = getClosest(config.distance)
    if not targetId then
        return notify('No players nearby.')
    end
    if config.requireCuffedToSearch and not (isCuffedPed(targetPed, targetId) or isHandsUp(targetPed)) then
        return notify('You need to cuff first.')
    end

    local ok = playProgress(config.progress.search, 'Searching the body', {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 1,
    })
    if not ok then
        ClearPedTasks(cache.ped)
        return
    end
    ClearPedTasks(cache.ped)
    exports.ox_inventory:openInventory('player', targetId)
end

local function searchDead()
    local targetId = getClosest(config.distance)
    if not targetId then
        return notify('No players nearby.')
    end
    if not Player(targetId).state.dead then
        return notify('That person is not dead.')
    end

    lib.requestAnimDict('amb@medic@standing@kneel@base')
    lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')
    TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, -8.0, -1, 48, 0, false, false, false)

    local ok = playProgress(config.progress.search, 'Searching the body')
    ClearPedTasks(cache.ped)
    if not ok then return end
    exports.ox_inventory:openInventory('player', targetId)
end

local clothingOptions = {
    { value = 'shirt',   title = 'Shirt',            icon = 'fa-solid fa-shirt' },
    { value = 'pants',   title = 'Pants',            icon = 'fa-solid fa-socks' },
    { value = 'shoes',   title = 'Shoes',            icon = 'fa-solid fa-shoe-prints' },
    { value = 'mask',    title = 'Mask',             icon = 'fa-solid fa-mask' },
    { value = 'helmet',  title = 'Hat / Helmet',     icon = 'fa-solid fa-hat-cowboy' },
    { value = 'bag',     title = 'Bag',              icon = 'fa-solid fa-briefcase' },
    { value = 'glasses', title = 'Glasses',          icon = 'fa-solid fa-glasses' },
    { value = 'vest',    title = 'Vest',             icon = 'fa-solid fa-vest' },
    { value = 'ears',    title = 'Ear Accessories',  icon = 'fa-solid fa-ear-listen' },
    { value = 'chain',   title = 'Chain',            icon = 'fa-solid fa-link' },
}

local function stripClothes(clothingType)
    local targetId, targetPed = getClosest(config.distance)
    if not targetId then
        return notify('No players nearby.')
    end
    if config.requireCuffedToStrip and not isCuffedPed(targetPed, targetId) then
        return notify('You need to cuff first.')
    end

    local ok = playProgress(config.progress.clothes, 'Removing clothes', {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 1,
    })
    ClearPedTasks(cache.ped)
    if not ok then return end

    TriggerServerEvent('cfx-keydi-utils:illegal:removeClothes', targetId, clothingType)
end

local function openClothesMenu()
    local options = {}
    for i = 1, #clothingOptions do
        local item = clothingOptions[i]
        options[#options + 1] = {
            title = item.title,
            description = ('Remove citizen %s'):format(item.title:lower()),
            icon = item.icon,
            onSelect = function()
                stripClothes(item.value)
            end,
        }
    end

    lib.registerContext({
        id = 'cfx_keydi_illegal_clothes',
        title = 'Remove Clothes',
        menu = 'cfx_keydi_illegal_menu',
        options = options,
    })
    lib.showContext('cfx_keydi_illegal_clothes')
end

local function openIllegalMenu()
    local serviceJob = getOnDutyServiceJob()
    if serviceJob then
        openServiceMenu(serviceJob)
        return
    end
    if not Region.Allowed('illegal') then
        return notify(Region.Message('illegal'), 'error')
    end
    if isBlocked() then return end

    lib.registerContext({
        id = 'cfx_keydi_illegal_menu',
        title = 'Illegal Menu',
        options = {
            {
                title = 'Handcuff',
                description = 'Cuff a nearby player',
                icon = 'fa-solid fa-handcuffs',
                onSelect = cuffPlayer,
            },
            {
                title = 'Uncuff',
                description = 'Uncuff a nearby player',
                icon = 'fa-solid fa-unlock',
                onSelect = uncuffPlayer,
            },
            {
                title = dragging.active and 'Stop Drag' or 'Drag',
                description = 'Drag a cuffed player',
                icon = 'fa-solid fa-user',
                onSelect = dragPlayer,
            },
            {
                title = 'Search',
                description = 'Search a cuffed or surrendering player',
                icon = 'fa-solid fa-magnifying-glass',
                onSelect = searchPlayer,
            },
            {
                title = 'Search Dead',
                description = 'Search a dead body',
                icon = 'fa-solid fa-skull',
                onSelect = searchDead,
            },
            {
                title = 'Remove Clothes',
                description = 'Strip clothes from a cuffed player',
                icon = 'fa-solid fa-shirt',
                arrow = true,
                onSelect = openClothesMenu,
            },
        },
    })
    lib.showContext('cfx_keydi_illegal_menu')
end

RegisterNetEvent('cfx-keydi-utils:illegal:setCuffed', function(state)
    local ped = cache.ped
    if state then
        lib.requestAnimDict('mp_arresting', 10000)
        TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, false, false, false)
        SetEnableHandcuffs(ped, true)
        DisablePlayerFiring(ped, true)
        TriggerEvent('ox_inventory:disarm')
    else
        ClearPedSecondaryTask(ped)
        SetEnableHandcuffs(ped, false)
        DisablePlayerFiring(ped, false)
        SetPedCanPlayGestureAnims(ped, true)
        FreezeEntityPosition(ped, false)
    end
end)

RegisterNetEvent('cfx-keydi-utils:illegal:setDrag', function(draggerId, enable)
    if enable then
        LocalPlayer.state:set('illegalDragged', draggerId, false)
    else
        LocalPlayer.state:set('illegalDragged', nil, false)
        DetachEntity(cache.ped, true, false)
    end
end)

CreateThread(function()
    local attached = false
    while true do
        local sleep = 1500
        local draggerId = LocalPlayer.state.illegalDragged
        if draggerId then
            sleep = 50
            local targetPed = GetPlayerPed(GetPlayerFromServerId(draggerId))
            if DoesEntityExist(targetPed) and IsPedOnFoot(targetPed) then
                if not attached then
                    AttachEntityToEntity(cache.ped, targetPed, 11816, 0.26, 0.48, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    attached = true
                end
            else
                attached = false
                LocalPlayer.state:set('illegalDragged', nil, false)
                DetachEntity(cache.ped, true, false)
            end
        elseif attached then
            attached = false
            DetachEntity(cache.ped, true, false)
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if LocalPlayer.state.cuffed then
            sleep = 0
            if not IsEntityPlayingAnim(cache.ped, 'mp_arresting', 'idle', 3) then
                TaskPlayAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
            end
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisablePlayerFiring(cache.ped, true)
        end
        Wait(sleep)
    end
end)

RegisterCommand(config.command, function()
    openIllegalMenu()
end, false)

RegisterKeyMapping(config.command, config.keyMappingLabel, 'keyboard', config.keyMapping)
