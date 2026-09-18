local helpers = require 'helpers.game'
local menu    = require 'shared.menu'
local Vars    = require 'helpers.vars'
local Revive  = require 'actions.revive.client'
local Heal    = require 'actions.heal.client'
local Vitals  = require 'actions.vitals.client'
local Bodybag = require 'actions.bodybag.client'
local Bed     = require 'actions.bed.client'

local function isAuthorized(job, perms)
    return perms[job.name] and job.grade >= perms[job.name]
end

local function OpenAmbulanceMenu()
    local job = ESX.GetPlayerData().job
    if not helpers.HasJob(menu.menu.access) then return end

    local options = {}

    -- Revive
    if isAuthorized(job, menu.revive.access) then
        options[#options + 1] = {
            title       = 'Revive',
            description = 'Revive a nearby unconscious player',
            icon        = 'fa-solid fa-kit-medical',
            onSelect    = function()
                Revive.Target()
            end
        }
    end

    -- Heal
    if isAuthorized(job, menu.heal.access) then
        options[#options + 1] = {
            title       = 'Heal',
            description = 'Heal a nearby injured player',
            icon        = 'fa-solid fa-hand-holding-medical',
            onSelect    = function()
                Heal.Target()
            end
        }
    end

    -- Vitals
    if isAuthorized(job, menu.vitals.access) then
        options[#options + 1] = {
            title       = 'Check Vitals',
            description = 'Scan a nearby player\'s vital signs',
            icon        = 'fa-solid fa-clipboard',
            onSelect    = function()
                Vitals.Target()
            end
        }
    end

    -- Bodybag
    if isAuthorized(job, menu.bodybag.access) then
        options[#options + 1] = {
            title       = 'Bodybag',
            description = 'Place a nearby deceased player in a bodybag',
            icon        = 'fa-solid fa-skull',
            onSelect    = function()
                Bodybag.Target()
            end
        }
    end

    -- Bed
    if helpers.HasJob(menu.bed.access) then
        options[#options + 1] = {
            title       = 'Bed',
            description = 'Open the hospital bed management menu',
            icon        = 'fa-solid fa-bed',
            arrow       = true,
            onSelect    = Bed.Menu
        }
    end

    -- Billing
    if job.name == 'ambulance' or job.name == 'sambulance' or job.name == 'pambulance' then
        options[#options + 1] = {
            title       = 'Bill Player',
            description = 'Send a medical bill to a nearby player',
            icon        = 'fa-solid fa-file-invoice',
            onSelect    = function()
                CreateThread(function()
                    lib.hideContext()
                    local timeout = GetGameTimer() + 1500
                    while IsNuiFocused() and GetGameTimer() < timeout do
                        Wait(50)
                    end
                    Wait(80)
                    SetNuiFocus(false, false)
                    local opened = false
                    if GetResourceState('kodebykarl-ui') == 'started' then
                        opened = pcall(function()
                            exports['kodebykarl-ui']:OpenInvoice({ view = 'create', force = true })
                        end)
                    end
                    if not opened and GetResourceState('cfx-keydi-ui') == 'started' then
                        opened = pcall(function()
                            exports['cfx-keydi-ui']:OpenInvoice({ view = 'create', force = true })
                        end)
                    end
                    if not opened then
                        ExecuteCommand('billing')
                    end
                end)
            end
        }
        options[#options + 1] = {
            title       = 'Documents',
            description = 'Open medical certificates and issued documents',
            icon        = 'fa-solid fa-file-medical',
            onSelect    = function()
                CreateThread(function()
                    lib.hideContext()
                    Wait(120)
                    if GetResourceState('kodebykarl-police') == 'started' then
                        exports['kodebykarl-police']:OpenDocuments()
                        return
                    end
                    if GetResourceState('cfx-cs-police') == 'started' then
                        exports['cfx-cs-police']:OpenDocuments()
                        return
                    end
                    ExecuteCommand('documents')
                end)
            end
        }
    end

    if #options == 0 then
        return ESX.Notify('AMBULANCE', 'No actions available for your rank.', 'error', 3000)
    end

    lib.registerContext({
        id      = 'ems_menu_' .. job.name,
        title   = '🚑  ' .. job.label .. '  —  EMS Actions',
        options = options
    })
    lib.showContext('ems_menu_' .. job.name)
end

-- F6 keybind (already assigned, kept as lib.addKeybind)
lib.addKeybind({
    name        = 'ems_menu',
    description = 'EMS Action Menu',
    defaultKey  = 'F6',
    onPressed   = OpenAmbulanceMenu
})

RegisterNetEvent('cfx-keydi-ambulance:client:openMenu', OpenAmbulanceMenu)

local function targetServerId(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) and IsPedAPlayer(entity) then
        local idx = NetworkGetPlayerIndexFromPed(entity)
        if idx and idx ~= -1 then
            local sid = GetPlayerServerId(idx)
            if sid and sid > 0 then return sid end
        end
    end
    local player = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)
    return player and GetPlayerServerId(player) or nil
end

local function isPlayerDead(entity, sid)
    if sid and Player(sid).state.dead == true then
        return true
    end
    if entity and DoesEntityExist(entity) then
        if IsPedDeadOrDying(entity, true) or IsEntityPlayingAnim(entity, 'dead', 'dead_a', 3) then
            return true
        end
    end
    return false
end

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(200)
    end

    exports.ox_target:addGlobalPlayer({
        {
            name = 'ems_revive',
            icon = 'fa-solid fa-kit-medical',
            label = 'Revive',
            distance = 2.5,
            groups = menu.revive.access,
            items = { 'ems_medikit', 'medikit' },
            canInteract = function(entity)
                if Vars.isBusy then return false end
                local sid = targetServerId(entity)
                if not sid then return false end
                return isPlayerDead(entity, sid)
            end,
            onSelect = function(data)
                local sid = targetServerId(data.entity)
                if sid then
                    Revive.Target(sid)
                end
            end
        },
        {
            name = 'civ_medikit_revive',
            icon = 'fa-solid fa-kit-medical',
            label = 'Use Medikit (Revive)',
            distance = 2.5,
            items = { 'medikit', 'ems_medikit' },
            canInteract = function(entity)
                if Vars.isBusy then return false end
                local job = ESX.GetPlayerData().job
                if job and menu.revive.access[job.name] then
                    return false
                end
                local sid = targetServerId(entity)
                if not sid then return false end
                return isPlayerDead(entity, sid)
            end,
            onSelect = function(data)
                local sid = targetServerId(data.entity)
                if sid then
                    Revive.Target(sid, true)
                end
            end
        },
        {
            name = 'ems_heal',
            icon = 'fa-solid fa-hand-holding-medical',
            label = 'Heal',
            distance = 2.5,
            groups = menu.heal.access,
            items = { 'ems_medikit', 'medikit' },
            canInteract = function(entity)
                if Vars.isBusy then return false end
                local sid = targetServerId(entity)
                if not sid then return false end
                return not isPlayerDead(entity, sid)
            end,
            onSelect = function(data)
                local sid = targetServerId(data.entity)
                if sid then
                    Heal.Target(sid)
                end
            end
        },
        {
            name = 'civ_medikit_heal',
            icon = 'fa-solid fa-hand-holding-medical',
            label = 'Use Medikit (Heal)',
            distance = 2.5,
            items = { 'medikit', 'ems_medikit' },
            canInteract = function(entity)
                if Vars.isBusy then return false end
                local job = ESX.GetPlayerData().job
                if job and menu.heal.access[job.name] then
                    return false
                end
                local sid = targetServerId(entity)
                if not sid then return false end
                return not isPlayerDead(entity, sid)
            end,
            onSelect = function(data)
                local sid = targetServerId(data.entity)
                if sid then
                    Heal.Target(sid, true)
                end
            end
        },
        {
            name = 'ems_check_vitals',
            icon = 'fa-solid fa-heart-pulse',
            label = 'Check Vital Signs',
            distance = 2.5,
            groups = menu.vitals.access,
            canInteract = function(entity)
                if Vars.isBusy then return false end
                return targetServerId(entity) ~= nil
            end,
            onSelect = function(data)
                local sid = targetServerId(data.entity)
                if sid then
                    Vitals.Target(sid)
                end
            end
        },
        {
            name = 'ems_bodybag',
            icon = 'fa-solid fa-skull',
            label = 'Bodybag',
            distance = 2.5,
            groups = menu.bodybag.access,
            canInteract = function(entity)
                if Vars.isBusy then return false end
                local sid = targetServerId(entity)
                if not sid then return false end
                return isPlayerDead(entity, sid)
            end,
            onSelect = function(data)
                local sid = targetServerId(data.entity)
                if sid then
                    Bodybag.Target(sid)
                end
            end
        }
    })
end)
