local function canSearchTarget(playerId)
    if not playerId then return false end
    local state = Player(playerId).state
    if state.canSteal or state.dead or state.cuffed then
        return true
    end

    local target = GetPlayerFromServerId(playerId)
    local ped = target ~= -1 and GetPlayerPed(target) or 0
    if ped == 0 then return false end

    return IsPedCuffed(ped)
        or IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
        or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 3)
        or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_enter', 3)
        or IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3)
end

AddEventHandler('cfx-cs-police:searchPlayer', function(data)
    if not HasGroup() then return end
    local playerId = GetTargetServerId(data, 2.0)
    if not playerId then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end
    if not canSearchTarget(playerId) then
        ESX.Notify(PlayerData.job.label, 'Target must have their hands up or be restrained.', 'error', 5000)
        return
    end
    local dict = nil
    local clip = nil
    local scenario = nil
    local time = 2500
    local flag = 12
    if Player(playerId).state.dead then
        time = 5000
        scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD'
        flag = 49
    else
        dict = 'mini@repair'
        clip = 'fixing_a_ped'
        flag = 49
    end
    local status = lib.progressBar({
        duration = time,
        label = 'Searching Please Wait . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            weapon = false
        },
        anim = {
            dict = dict,
            clip = clip,
            flag = flag,
            scenario = scenario
        }
    })
    if status then
        TriggerServerEvent('cfx-cs-police:logSearch', playerId)
        LocalPlayer.state:set('invBusy', false, true)
        Wait(100)
        exports.ox_inventory:openInventory('player', playerId)
    end
end)

-- Start of Check Identification --
function checkPlayerId(targetId)
    ESX.TriggerServerCallback('cfx-cs-police:checkPlayerId', function(data)
        if not data then
            ESX.Notify(PlayerData.job.label, 'Unable to check identification.', 'error', 5000)
            return
        end
        local Options = {
            {
                title = 'Name: '..data.name,
                icon = 'fa-solid fa-id-badge',
                arrow = false
            },
            {
                title = 'Job: '..data.job,
                icon = 'fa-solid fa-briefcase',
                arrow = false
            },
            {
                title = 'Job Position: '..data.position,
                icon = 'fa-solid fa-briefcase',
                arrow = false
            },
        }
        if data.dob then
            Options[#Options + 1] = {
                title = 'Date Of Birth: '..data.dob,
                icon = 'fa-solid fa-cake-candles',
                arrow = false
            }
        end
        if data.sex then
            Options[#Options + 1] = {
                title = 'Gender: '..data.sex,
                icon = 'fa-solid fa-venus-mars',
                arrow = false
            }
        end
        Options[#Options + 1] = {
            title = 'Licenses',
            description = 'View licenses.',
            icon = 'fa-solid fa-id-badge',
            arrow = true,
            event = 'cfx-cs-police:licenseMenu',
            args = {licenses = data.licenses, targetId = targetId}
        }
        lib.registerContext({
            id = 'police_menu_playerdetails',
            title = "Identifications",
            options = Options
        })
        lib.showContext('police_menu_playerdetails')
    end, targetId)
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

AddEventHandler('cfx-cs-police:revokeLicense', function(data)
    if not HasGroup() then return end
    TriggerServerEvent('cfx-cs-police:revokeLicense', data.targetId, data.license)
    ESX.Notify(PlayerData.job.label, 'You have successfully revoked license', 'success', 5000)
    Wait(420) -- lul
    checkPlayerId(data.targetId)
end)

function manageId(data)
    local Options = {
        {
            title = 'Revoke License',
            arrow = false,
            event = 'cfx-cs-police:revokeLicense',
            args = {targetId = data.targetId, license = data.licenseType}
        },
        {
            title = '< Go Back',
            arrow = false,
            event = 'cfx-cs-police:checkId',
            args = data.targetId
        },
    }
    lib.registerContext({
        id = 'police_menu_revoke_license',
        title = "License",
        options = Options
    })
    lib.showContext('police_menu_revoke_license')
end

function openLicenseMenu(data)
    local targetId, licenses = data.targetId, data.licenses or {}
    local Options = {}
    for k,v in pairs(licenses) do
        if type(v) == 'table' and v.has and k ~= 'therotical' then
            Options[#Options + 1] = {
                title = v.label or firstToUpper(k),
                arrow = true,
                event = 'cfx-cs-police:manageId',
                args = {targetId = targetId, license = v, licenseType = k}
            }
        end
    end
    if #Options <= 0 then
        Options[#Options + 1] = {
            title = 'No Licenses',
            icon = 'fa-regular fa-id-card',
        }
    end
    lib.registerContext({
        id = 'police_menu_license_list',
        title = "Licenses",
        options = Options
    })
    lib.showContext('police_menu_license_list')
end

AddEventHandler('cfx-cs-police:licenseMenu', function(data)
    if not HasGroup() then return end
    openLicenseMenu(data)
end)

AddEventHandler('cfx-cs-police:manageId', function(data)
    if not HasGroup() then return end
    manageId(data)
end)

AddEventHandler('cfx-cs-police:checkId', function(data)
    if not HasGroup() then return end
    WithNearbyPlayer(6.0, 'Check Identification', function(targetId)
        checkPlayerId(targetId)
    end)
end)
-- End of Check Identification --

-- Start of Grant License --
function GiveWeaponLicense(id)
    ESX.TriggerServerCallback('cfx-cs-police:grantLicense', function(granted)
        if granted then
            ESX.Notify(PlayerData.job.label, ('You awarded a weapons license to %s (%s)'):format(granted, id), 'success', 5000)
        else
            ESX.Notify(PlayerData.job.label, 'This person already has a license!', 'error', 5000)
        end
    end, id)
end

AddEventHandler('cfx-cs-police:grantLicense', function(data)
    if not HasGroup() then return end
    local playerId = GetTargetServerId(data, 10.0)
    if playerId then
        GiveWeaponLicense(playerId)
        return
    end
    local coords = GetEntityCoords(cache.ped)
    local closestPlayers = lib.getNearbyPlayers(vector3(coords.x, coords.y, coords.z), 10.0, false)
    if #closestPlayers < 1 then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end
    local Options = {}
    for i=1, #closestPlayers do
        local player = closestPlayers[i]
        local nearbyId = GetPlayerServerId(player.id)
        Options[#Options + 1] = {
            icon = 'user',
            title = 'ID '..nearbyId,
            arrow = true,
            onSelect = function ()
                GiveWeaponLicense(nearbyId)
            end
        }
    end
    lib.registerContext({
        id = 'police_menu_grant_license_weapon',
        title = "Grant Weapon License",
        options = Options
    })
    lib.showContext('police_menu_grant_license_weapon')
end)
-- End of Grant License --

-- Start of Revoke Weapon License --
function RevokeWeaponLicense(id)
    ESX.TriggerServerCallback('cfx-cs-police:revokeWeaponLicense', function(result)
        if result then
            ESX.Notify(PlayerData.job.label, ('You revoked the weapons license from %s (%s)'):format(result, id), 'success', 5000)
        else
            ESX.Notify(PlayerData.job.label, 'This person does not have a weapon license.', 'error', 5000)
        end
    end, id)
end

AddEventHandler('cfx-cs-police:revokeWeaponLicense', function(data)
    if not HasGroup() then return end
    local playerId = GetTargetServerId(data, 10.0)
    if playerId then
        RevokeWeaponLicense(playerId)
        return
    end
    local coords = GetEntityCoords(cache.ped)
    local closestPlayers = lib.getNearbyPlayers(vector3(coords.x, coords.y, coords.z), 10.0, false)
    if #closestPlayers < 1 then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end
    local Options = {}
    for i = 1, #closestPlayers do
        local player = closestPlayers[i]
        local nearbyId = GetPlayerServerId(player.id)
        Options[#Options + 1] = {
            icon = 'user',
            title = 'ID ' .. nearbyId,
            arrow = true,
            onSelect = function()
                RevokeWeaponLicense(nearbyId)
            end
        }
    end
    lib.registerContext({
        id = 'police_menu_revoke_license_weapon',
        title = 'Revoke Weapon License',
        options = Options
    })
    lib.showContext('police_menu_revoke_license_weapon')
end)
-- End of Revoke Weapon License --



AddEventHandler('cfx-cs-police:grantHuntingLicense', function()
    if not HasGroup() then return end
    local coords = GetEntityCoords(cache.ped)
    local closestPlayers = lib.getNearbyPlayers(vector3(coords.x, coords.y, coords.z), 10.0, false)
    if #closestPlayers < 1 then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end
    local Options = {}
    for i=1, #closestPlayers do
        local player = closestPlayers[i]
        local playerId = GetPlayerServerId(player.id)
        Options[#Options + 1] = {
            icon = 'user',
            title = 'ID '..playerId,
            arrow = true,
            onSelect = function ()
                GiveHuntingLicense(playerId)
            end
        }
    end
    lib.registerContext({
        id = 'police_menu_grant_license_hunting',
        title = "Grant Hunting License",
        options = Options
    })
    lib.showContext('police_menu_grant_license_hunting')
end)
-- End of Grant Hunting License --

-- Start of Handcuff --

function uncuffed()
    isCuffed = false
    if escorted?.active then
        escorted.active = nil
    end
    TriggerServerEvent('cfx-cs-police:setCuff', false)
    SetEnableHandcuffs(cache.ped, false)
    DisablePlayerFiring(cache.ped, false)
    SetPedCanPlayGestureAnims(cache.ped, true)
    FreezeEntityPosition(cache.ped, false)
    Wait(250)
    ClearPedTasks(cache.ped)
    ClearPedSecondaryTask(cache.ped)
    if cuffProp and DoesEntityExist(cuffProp) then
        SetEntityAsMissionEntity(cuffProp, true, true)
        DetachEntity(cuffProp)
        DeleteObject(cuffProp)
        cuffProp = nil
    end
end

function handcuffed()
    isCuffed = true
    TriggerServerEvent('cfx-cs-police:setCuff', true)
    SetEnableHandcuffs(cache.ped, true)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    SetPedCanPlayGestureAnims(cache.ped, false)
    lib.requestAnimDict('mp_arresting', 10000)
    TaskPlayAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
end

RegisterNetEvent('cfx-cs-police:cuffAnim', function(target)
    isBusy = true
    local escaped = false
    local pdPlayer = GetPlayerFromServerId(target)
    local pdPed = pdPlayer ~= -1 and GetPlayerPed(pdPlayer) or 0

    lib.requestAnimDict('mp_arrest_paired', 10000)
    if pdPed ~= 0 and DoesEntityExist(pdPed) then
        AttachEntityToEntity(cache.ped, pdPed, 11816, -0.1, 0.45, 0.0, 0.0, 0.0, 20.0, false, false, true, false, 20, false)
        FreezeEntityPosition(pdPed, true)
    end
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'crook_p2_back_left', 8.0, -8.0, 5500, 33, 0, false, false, false)
    Wait(5500)
    DetachEntity(cache.ped, true, false)
    if pdPed ~= 0 then
        FreezeEntityPosition(pdPed, false)
    end
    RemoveAnimDict('mp_arrest_paired')
    if not escaped then
        handcuffed()
    end
    isBusy = false
end)

RegisterNetEvent('cfx-cs-police:cuff', function()
    isBusy = true
    lib.requestAnimDict('mp_arrest_paired', 10000)
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'cop_p2_back_left', 8.0, -8.0, 3400, 33, 0, false, false, false)
    Wait(3000)
    isBusy = false
end)

RegisterNetEvent('cfx-cs-police:uncuffAnim', function(target)
    local suspectPlayer = GetPlayerFromServerId(target)
    local suspectPed = suspectPlayer ~= -1 and GetPlayerPed(suspectPlayer) or 0
    if suspectPed ~= 0 and DoesEntityExist(suspectPed) then
        local playerheading = GetEntityHeading(cache.ped)
        local playerlocation = GetEntityForwardVector(cache.ped)
        local playerCoords = GetEntityCoords(cache.ped)
        local x, y, z = table.unpack(playerCoords + playerlocation * 1.0)
        SetEntityCoords(suspectPed, x, y, z - 1.0, false, false, false, false)
        SetEntityHeading(suspectPed, playerheading)
    end
    Wait(250)
    if escorting?.active then
        escorting.active = nil
        escorting.target = nil
    end
    lib.requestAnimDict('mp_arresting', 10000)
    TaskPlayAnim(cache.ped, 'mp_arresting', 'a_uncuff', 8.0, -8, -1, 2, 0, 0, 0, 0)
    Wait(5500)
    ClearPedTasks(cache.ped)
end)

RegisterNetEvent('cfx-cs-police:uncuff', uncuffed)

AddEventHandler('cfx-cs-police:Cuff', function(data)
    if not HasGroup() then return end
    WithNearbyPlayer(6.0, 'Handcuff Suspect', function(targetId)
        if Player(targetId).state.dead then
            ESX.Notify(PlayerData.job.label, 'Person appears unconcious', 'error', 5000)
            return
        end
        if Player(targetId).state.cuffed then
            ESX.Notify(PlayerData.job.label, 'Person is already cuffed.', 'error', 5000)
            return
        end
        TriggerServerEvent('cfx-cs-police:CuffPlayer', targetId)
    end)
end)

AddEventHandler('cfx-cs-police:Uncuff', function(data)
    if not HasGroup() then return end
    WithNearbyPlayer(6.0, 'Uncuff Suspect', function(targetId)
        if Player(targetId).state.dead then
            ESX.Notify(PlayerData.job.label, 'Person appears unconcious', 'error', 5000)
            return
        end
        if not Player(targetId).state.cuffed then
            ESX.Notify(PlayerData.job.label, 'Person is not cuffed.', 'error', 5000)
            return
        end
        TriggerServerEvent('cfx-cs-police:UncuffPlayer', targetId)
    end)
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if isCuffed then
            sleep = 0
            if not IsEntityPlayingAnim(cache.ped, 'mp_arresting', 'idle', 3) then
                TaskPlayAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
            end
            DisablePlayerFiring(cache.playerId, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(27, 75, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            if not cuffProp or not DoesEntityExist(cuffProp) then
                lib.requestModel('p_cs_cuffs_02_s', 10000)
                local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(cache.ped,0.0,3.0,0.5))
                cuffProp = CreateObjectNoOffset(`p_cs_cuffs_02_s`, x, y, z, true, false)
                SetModelAsNoLongerNeeded(`p_cs_cuffs_02_s`)
                AttachEntityToEntity(cuffProp, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.04, 0.06, 0.0, -85.24, 4.2, -106.6, true, true, false, true, 1, true)
            end
        end
        Wait(sleep)
    end
end)

function IsHandcuffed()
    return isCuffed
end

exports('IsHandcuffed', IsHandcuffed)
-- End of Handcuff --

-- Start of Escort --
AddEventHandler('cfx-cs-police:EscortPlayer', function(data)
    if not HasGroup() then return end
    local targetId = GetTargetServerId(data, 5.0)
    if not targetId then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end
    if not Player(targetId).state.cuffed then
        ESX.Notify(PlayerData.job.label, 'You must restrain the criminal before escorting them', 'error', 5000)
        return
    end
    TriggerServerEvent('cfx-cs-police:escortPlayer', targetId)
end)

AddEventHandler('cfx-cs-police:JailPlayer', function(data)
    if not HasGroup() then return end
    local targetId = GetTargetServerId(data, 5.0)
    if not targetId then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end

    local input = lib.inputDialog('Jail Suspect', {
        {
            type = 'number',
            label = 'Sentence (Months)',
            description = 'How long should they stay in jail?',
            icon = 'hashtag',
            required = true,
            min = 1,
        },
    })
    if not input then return end

    local time = tonumber(input[1])
    if not time or time < 1 then
        ESX.Notify(PlayerData.job.label, 'Invalid jail time.', 'error', 5000)
        return
    end

    lib.callback.await('xt-prison:server:JailPlayer', false, targetId, time)
end)

local function CanUnjail()
    if not HasGroup() then return false end
    local job = PlayerData and PlayerData.job
    if (not job or not job.name) and ESX.GetPlayerData then
        job = ESX.GetPlayerData().job
    end
    if not job then return false end
    local gradeName = tostring(job.grade_name or ''):lower()
    if gradeName == 'boss' or gradeName == 'director' or gradeName == 'chief' then
        return true
    end
    return (tonumber(job.grade) or 0) >= 1
end

AddEventHandler('cfx-cs-police:UnjailPlayer', function(data)
    if not HasGroup() then return end
    if not CanUnjail() then
        ESX.Notify(PlayerData.job.label, 'Only officers and directors can unjail.', 'error', 5000)
        return
    end

    local targetId = GetTargetServerId(data, 5.0)
    if not targetId then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end

    local released = lib.callback.await('xt-prison:server:unjailPlayerByRoster', false, targetId)
    if released then
        ESX.Notify(PlayerData.job.label, 'Suspect released from jail.', 'success', 5000)
    else
        ESX.Notify(PlayerData.job.label, 'That player is not in jail, or release failed.', 'error', 5000)
    end
end)

RegisterNetEvent('cfx-cs-police:setEscort', function(targetId)
    escorting.active = not escorting.active
    if escorting.active then
        escorting.target = targetId
    else
        escorting.target = nil
        ClearPedTasks(cache.ped)
    end
end)

RegisterNetEvent('cfx-cs-police:escortedPlayer', function(pdId)
    if not (isCuffed or LocalPlayer.state.cuffed) then return end
    escorted.active = not escorted.active
    if escorted.active then
        escorted.pdId = pdId
    else
        escorted.pdId = nil
        isBusy = nil
        DetachEntity(cache.ped, true, false)
        ClearPedTasks(cache.ped)
    end
end)

RegisterNetEvent('cfx-cs-police:stopEscorting', function()
    if escorting.active then
        escorting.active = nil
        escorting.target = nil
        ClearPedTasks(cache.ped)
    end
end)

-- Escorting loop
CreateThread(function()
    local alrEscorting
    while true do
        local sleep = 1500
        if escorting?.active and escorting.target then
            sleep = 0
            local targetPlayer = GetPlayerFromServerId(escorting.target)
            local targetPed = targetPlayer ~= -1 and GetPlayerPed(targetPlayer) or 0
            if targetPed ~= 0 and DoesEntityExist(targetPed) and IsPedOnFoot(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                if not alrEscorting then
                    lib.requestAnimDict('amb@code_human_wander_drinking_fat@beer@male@base', 10000)
                    TaskPlayAnim(cache.ped, 'amb@code_human_wander_drinking_fat@beer@male@base', 'static', 8.0, 1.0, -1, 49, 0, 0, 0, 0)
                    alrEscorting = true
                    RemoveAnimDict('amb@code_human_wander_drinking_fat@beer@male@base')
                elseif alrEscorting and not IsEntityPlayingAnim(cache.ped, 'amb@code_human_wander_drinking_fat@beer@male@base', 'static', 3) then
                    lib.requestAnimDict('amb@code_human_wander_drinking_fat@beer@male@base', 10000)
                    TaskPlayAnim(cache.ped, 'amb@code_human_wander_drinking_fat@beer@male@base', 'static', 8.0, 1.0, -1, 49, 0, 0, 0, 0)
                    RemoveAnimDict('amb@code_human_wander_drinking_fat@beer@male@base')
                else
                    sleep = 1500
                end
            else
                alrEscorting = nil
                escorting.active = nil
                escorting.target = nil
                ClearPedTasks(cache.ped)
            end
        elseif alrEscorting then
            alrEscorting = nil
            escorting.active = nil
            escorting.target = nil
            ClearPedTasks(cache.ped)
        else
            sleep = 1500
        end
        Wait(sleep)
    end
end)

-- Being escorted loop
CreateThread(function()
    local alrEscorted
    while true do
        local sleep = 1500
        local cuffed = isCuffed or LocalPlayer.state.cuffed
        if cuffed and escorted?.active and escorted.pdId then
            sleep = 0
            local pdPlayer = GetPlayerFromServerId(escorted.pdId)
            local pdPed = pdPlayer ~= -1 and GetPlayerPed(pdPlayer) or 0
            if pdPed ~= 0 and DoesEntityExist(pdPed) and IsPedOnFoot(pdPed) and not IsPedDeadOrDying(pdPed, true) then
                if not alrEscorted then
                    AttachEntityToEntity(cache.ped, pdPed, 11816, 0.26, 0.48, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 2, true)
                    alrEscorted = true
                    isBusy = true
                else
                    sleep = 500
                end
                if IsPedWalking(pdPed) then
                    if not IsEntityPlayingAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 3) then
                        lib.requestAnimDict('anim@move_m@prisoner_cuffed', 10000)
                        TaskPlayAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 8.0, -8, -1, 1, 0.0, false, false, false)
                    end
                elseif IsPedRunning(pdPed) or IsPedSprinting(pdPed) then
                    if not IsEntityPlayingAnim(cache.ped, 'anim@move_m@trash', 'run', 3) then
                        lib.requestAnimDict('anim@move_m@trash', 10000)
                        TaskPlayAnim(cache.ped, 'anim@move_m@trash', 'run', 8.0, -8, -1, 1, 0.0, false, false, false)
                    end
                elseif IsEntityPlayingAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 3) or IsEntityPlayingAnim(cache.ped, 'anim@move_m@trash', 'run', 3) then
                    StopAnimTask(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', -8.0)
                    StopAnimTask(cache.ped, 'anim@move_m@trash', 'run', -8.0)
                end
            else
                alrEscorted = false
                escorted.active = nil
                escorted.pdId = nil
                isBusy = nil
                DetachEntity(cache.ped, true, false)
            end
        elseif alrEscorted then
            alrEscorted = nil
            isBusy = nil
            DetachEntity(cache.ped, true, false)
        else
            sleep = 1500
        end
        Wait(sleep)
    end
end)
-- End of Escort --

-- Start of In vehicle --
AddEventHandler('cfx-cs-police:inVehiclePlayer', function(data)
    if not HasGroup() then return end
    local playerId = GetTargetServerId(data, 5.0)
    if not playerId then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end
    if Player(playerId).state.dead then
        ESX.Notify(PlayerData.job.label, 'Person appears unconcious', 'error', 5000)
        return
    end
    if not Player(playerId).state.cuffed then
        ESX.Notify(PlayerData.job.label, 'You must restrain the criminal first', 'error', 5000)
        return
    end
    TriggerServerEvent('cfx-cs-police:inVehiclePlayer', playerId)
end)

RegisterNetEvent('cfx-cs-police:putInVehicle', function()
    if not (isCuffed or LocalPlayer.state.cuffed) then return end
    if escorted?.active then
        escorted.active = nil
        escorted.pdId = nil
        DetachEntity(cache.ped, true, false)
        Wait(1000)
    end
    local coords = GetEntityCoords(cache.ped)
    if IsAnyVehicleNearPoint(coords, 5.0) then
        local vehicle = GetVehicleInDirection()
        if DoesEntityExist(vehicle) then
            local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)
            for i = maxSeats - 1, 0, -1 do
                if IsVehicleSeatFree(vehicle, i) then
                    freeSeat = i
                    break
                end
            end
            if freeSeat then
                FreezeEntityPosition(cache.ped, false)
                TaskWarpPedIntoVehicle(cache.ped, vehicle, freeSeat)
                FreezeEntityPosition(cache.ped, true)
                ExecuteCommand('seatbelt')
            end
        end
    end
end)
-- End of In vehicle --

-- Start of Out Vehicle --
AddEventHandler('cfx-cs-police:outVehiclePlayer', function(data)
    if not HasGroup() then return end
    local playerId = GetTargetServerId(data, 5.0)
    if not playerId then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end
    if Player(playerId).state.dead then
        ESX.Notify(PlayerData.job.label, 'Person appears unconcious', 'error', 5000)
        return
    end
    TriggerServerEvent('cfx-cs-police:outVehiclePlayer', playerId)
end)

RegisterNetEvent('cfx-cs-police:takeFromVehicle', function()
	if IsPedSittingInAnyVehicle(cache.ped) then
		local vehicle = GetVehiclePedIsIn(cache.ped, false)
		TaskLeaveVehicle(cache.ped, vehicle, 64)
        FreezeEntityPosition(cache.ped, false)
	end
end)
-- End of Out Vehicle --

-- Start of Place Object --

AddEventHandler('cfx-cs-police:OpenObjectMenu', function()
    if not HasGroup() then return end
    local SendMenu = {
        {
            title = 'Cone',
            icon = 'fa-solid fa-person-cane',
            description = 'Place a Cone',
            event = 'cfx-cs-police:client:spawnCone'
        },
        {
            title = 'Gate',
            icon = 'fa-solid fa-dungeon',
            description ='Place a Gate',
            event = 'cfx-cs-police:client:spawnBarrier'
        },
        {
            title = 'Speed Limit Sign',
            icon = 'fa-solid fa-sign-hanging',
            description = 'Place a Speed Limit Sign',
            event = 'cfx-cs-police:client:spawnRoadSign'
        },
        {
            title = 'Tent',
            icon = 'fa-solid fa-tent',
            description = 'Place a Tent',
            event = 'cfx-cs-police:client:spawnTent'
        },
        {
            title = 'Lighting',
            icon = 'fa-solid fa-lightbulb',
            description = 'Place a Lighting',
            event = 'cfx-cs-police:client:spawnLight'
        },
        {
            title = 'Spike Strips',
            icon = 'fa-solid fa-road-spikes',
            description = 'Place a Spike Strips',
            event = 'cfx-cs-police:client:SpawnSpikeStrip'
        },
        {
            title = 'Remove Object',
            icon = 'fa-solid fa-xmark',
            description = 'Remove the object',
            event = 'cfx-cs-police:client:deleteObject'
        },
    }
    lib.registerContext({
        id = 'police_menu_object_list',
        title = "Object List",
        options = SendMenu
    })
    lib.showContext('police_menu_object_list')
end)

local ObjectList = {}
local SpawnedSpikes = {}
local spikemodel = `P_ld_stinger_s`
local ClosestSpike = nil

local function GetClosestPoliceObject()
    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist = nil
    for id, objData in pairs(ObjectList) do
        if objData and objData.coords then
            local dist2 = #(pos - objData.coords)
            if not dist or dist2 < dist then
                dist = dist2
                current = id
            end
        end
    end
    return current, dist
end

function GetClosestSpike()
    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist = nil

    if not SpawnedSpikes or not next(SpawnedSpikes) then
        ClosestSpike = nil
        return
    end

    for id, spikeData in pairs(SpawnedSpikes) do
        if spikeData and spikeData.coords then
            local currentDist = #(pos - vector3(spikeData.coords.x, spikeData.coords.y, spikeData.coords.z))
            if not dist or currentDist < dist then
                dist = currentDist
                current = id
            end
        end
    end
    ClosestSpike = current
end

RegisterNetEvent('cfx-cs-police:client:spawnCone', function()
    if not HasGroup() then return end
    local status = lib.progressBar({
        duration = 2500,
        label = 'Placing object . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            weapon = false
        },
        anim = {
            dict = 'anim@narcotics@trash',
            clip = 'drop_front',
            flag = 16
        }
    })
    if status then
        TriggerServerEvent("cfx-cs-police:server:spawnObject", "cone")
    end
end)

RegisterNetEvent('cfx-cs-police:client:spawnBarrier', function()
    if not HasGroup() then return end
    local status = lib.progressBar({
        duration = 2500,
        label = 'Placing object . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            weapon = false
        },
        anim = {
            dict = 'anim@narcotics@trash',
            clip = 'drop_front',
            flag = 16
        }
    })
    if status then
        TriggerServerEvent("cfx-cs-police:server:spawnObject", "barrier")
    end
end)

RegisterNetEvent('cfx-cs-police:client:spawnRoadSign', function()
    if not HasGroup() then return end
    local status = lib.progressBar({
        duration = 2500,
        label = 'Placing object . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            weapon = false
        },
        anim = {
            dict = 'anim@narcotics@trash',
            clip = 'drop_front',
            flag = 16
        }
    })
    if status then
        TriggerServerEvent("cfx-cs-police:server:spawnObject", "roadsign")
    end
end)

RegisterNetEvent('cfx-cs-police:client:spawnTent', function()
    if not HasGroup() then return end
    local status = lib.progressBar({
        duration = 2500,
        label = 'Placing object . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            weapon = false
        },
        anim = {
            dict = 'anim@narcotics@trash',
            clip = 'drop_front',
            flag = 16
        }
    })
    if status then
        TriggerServerEvent("cfx-cs-police:server:spawnObject", "tent")
    end
end)

RegisterNetEvent('cfx-cs-police:client:spawnLight', function()
    if not HasGroup() then return end
    local status = lib.progressBar({
        duration = 2500,
        label = 'Placing object . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            weapon = false
        },
        anim = {
            dict = 'anim@narcotics@trash',
            clip = 'drop_front',
            flag = 16
        }
    })
    if status then
        TriggerServerEvent("cfx-cs-police:server:spawnObject", "light")
    end
end)

RegisterNetEvent('cfx-cs-police:client:deleteObject', function()
    if not HasGroup() then return end
    local objectId, dist = GetClosestPoliceObject()
    if dist and dist < 5.0 then
        local status = lib.progressBar({
            duration = 2500,
            label = 'Removing object . . .',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                mouse = false,
                weapon = false
            },
            anim = {
                dict = 'weapons@first_person@aim_rng@generic@projectile@thermal_charge@',
                clip = 'plant_floor',
                flag = 16
            }
        })
        if status then
            TriggerServerEvent("cfx-cs-police:server:deleteObject", objectId)
        end
    end
end)

RegisterNetEvent('cfx-cs-police:client:removeObject', function(objectId)
    if ObjectList[objectId] == nil then return end
    NetworkRequestControlOfEntity(ObjectList[objectId].object)
    DeleteObject(ObjectList[objectId].object)
    ObjectList[objectId] = nil
end)

RegisterNetEvent('cfx-cs-police:client:spawnObject', function(objectId, type, player)
    local coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(player)))
    local heading = GetEntityHeading(GetPlayerPed(GetPlayerFromServerId(player)))
    local forward = GetEntityForwardVector(cache.ped)
    local x, y, z = table.unpack(coords + forward * 0.5)
    local spawnedObj = CreateObject(Config.Objects[type].model, x, y, z, true, false, false)
    PlaceObjectOnGroundProperly(spawnedObj)
    SetEntityHeading(spawnedObj, heading)
    FreezeEntityPosition(spawnedObj, Config.Objects[type].freeze)
    ObjectList[objectId] = {
        id = objectId,
        object = spawnedObj,
        coords = vector3(x, y, z - 0.3),
    }
end)

RegisterNetEvent('cfx-cs-police:client:SpawnSpikeStrip', function()
    if not HasGroup() then return end
    if #SpawnedSpikes + 1 < Config.MaxSpikes then
        local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.0)
        local spike = CreateObject(spikemodel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 1, 1, 1)
        local netid = NetworkGetNetworkIdFromEntity(spike)
        SetNetworkIdExistsOnAllMachines(netid, true)
        SetNetworkIdCanMigrate(netid, false)
        SetEntityHeading(spike, GetEntityHeading(cache.ped))
        PlaceObjectOnGroundProperly(spike)
        SpawnedSpikes[#SpawnedSpikes+1] = {
            coords = vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z),
            netid = netid,
            object = spike,
        }
        TriggerServerEvent('cfx-cs-police:server:SyncSpikes', SpawnedSpikes)
    else
        ESX.Notify(PlayerData.job.label, 'Cannot place anymore spike strips', 'error', 5000)
    end
end)

RegisterNetEvent('cfx-cs-police:client:SyncSpikes', function(table)
    SpawnedSpikes = table
end)

CreateThread(function()
    while true do
        if next(PlayerData) then
            GetClosestSpike()
        end
        Wait(500)
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        if next(PlayerData) and ClosestSpike and SpawnedSpikes and SpawnedSpikes[ClosestSpike] and SpawnedSpikes[ClosestSpike].coords then
            local vehicle = GetVehiclePedIsIn(cache.ped, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == cache.ped then
                sleep = 5
                local tires = {
                    {bone = "wheel_lf", index = 0},
                    {bone = "wheel_rf", index = 1},
                    {bone = "wheel_lm", index = 2},
                    {bone = "wheel_rm", index = 3},
                    {bone = "wheel_lr", index = 4},
                    {bone = "wheel_rr", index = 5}
                }
                for a = 1, #tires do
                    local boneIndex = GetEntityBoneIndexByName(vehicle, tires[a].bone)
                    if boneIndex ~= -1 then
                        local tirePos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
                        local spike = GetClosestObjectOfType(tirePos.x, tirePos.y, tirePos.z, 15.0, spikemodel, 1, 1, 1)
                        if spike ~= 0 then
                            local spikePos = GetEntityCoords(spike, false)
                            local distance = #(tirePos - spikePos)
                            if distance < 1.8 then
                                if not IsVehicleTyreBurst(vehicle, tires[a].index, true) or IsVehicleTyreBurst(vehicle, tires[a].index, false) then
                                    SetVehicleTyreBurst(vehicle, tires[a].index, false, 1000.0)
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if next(PlayerData) then
            if ClosestSpike and SpawnedSpikes and SpawnedSpikes[ClosestSpike] and SpawnedSpikes[ClosestSpike].coords then
                local ped = cache.ped
                local pos = GetEntityCoords(ped)
                local dist = #(pos - SpawnedSpikes[ClosestSpike].coords)
                if dist < 4 then
                    if not IsPedInAnyVehicle(cache.ped) then
                        if HasGroup() then
                            sleep = 0
                            ESX.DrawText3D(pos.x, pos.y, pos.z, '[~g~E~w~] Delete Spike Strip')
                            if IsControlJustPressed(0, 38) then
                                local spikeObj = SpawnedSpikes[ClosestSpike].object
                                if spikeObj and DoesEntityExist(spikeObj) then
                                    NetworkRegisterEntityAsNetworked(spikeObj)
                                    NetworkRequestControlOfEntity(spikeObj)
                                    SetEntityAsMissionEntity(spikeObj)
                                    DeleteEntity(spikeObj)
                                end
                                SpawnedSpikes[ClosestSpike] = nil
                                ClosestSpike = nil
                                TriggerServerEvent('cfx-cs-police:server:SyncSpikes', SpawnedSpikes)
                            end
                        end
                    end
                end
            else
                ClosestSpike = nil
            end
        end
        Wait(sleep)
    end
end)
-- End of Place Object --

-- Start of Vehicle Interaction --
AddEventHandler('cfx-cs-police:vehicleInteractions', function()
    if not HasGroup() then return end
    local Options = {
        {
            title = 'Vehicle Information',
            icon = 'fa-solid fa-magnifying-glass',
            description = 'Information on nearby vehicle',
            onSelect = function()
                VehicleInfo()
            end
        },
        {
            title = 'Lockpick Vehicle',
            icon = 'fa-solid fa-lock-open',
            description = 'Force access to nearby vehicle',
            onSelect = function()
                LockpickVehicle()
            end
        },
        {
            title = 'Impound Vehicle',
            icon = 'fa-solid fa-reply',
            description = 'Impound Nearby Vehicle',
            onSelect = function()
                impoundVehicle()
            end
        },
    }
    lib.registerContext({
        id = 'police_menu_vehicle_interact',
        title = "Vehicle Interaction",
        options = Options
    })
    lib.showContext('police_menu_vehicle_interact')
end)
-- End of Vehicle Interaction --

-- Start of Vehicle Info --
function VehicleInfo()
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 5.0, false)
    if not vehicle or not DoesEntityExist(vehicle) then
        ESX.Notify(PlayerData.job.label, 'No vehicle found nearby', 'error', 5000)
    else
        local vehCoords = GetEntityCoords(vehicle)
        local dist = #(coords - vehCoords)
        if dist < 3.5 then
            vehicleInfoMenu(vehicle)
        else
            ESX.Notify(PlayerData.job.label, 'The target vehicle is too far away', 'error', 5000)
        end
    end
end

function vehicleInfoMenu(vehicle)
    if not DoesEntityExist(vehicle) then
        ESX.Notify(PlayerData.job.label, 'No vehicle found nearby', 'error', 5000)
        return
    end

    local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle) or '')
    local modelHash = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(modelHash) or 'UNKNOWN'
    local modelLabel = GetLabelText(modelName)
    if not modelLabel or modelLabel == 'NULL' or modelLabel == '' then
        modelLabel = modelName
    end

    ESX.TriggerServerCallback('cfx-cs-police:getVehicleOwner', function(ownerData)
        local ownerText = 'Unknown / not registered'
        if type(ownerData) == 'table' then
            ownerText = ownerData.owner or ownerText
        elseif type(ownerData) == 'string' then
            ownerText = ownerData
        elseif ownerData == false then
            ownerText = 'Unregistered (possibly stolen)'
        end

        local Menu = {
            {
                title = ('Plate: %s'):format(plate ~= '' and plate or 'N/A'),
                icon = 'fa-solid fa-id-card',
            },
            {
                title = ('Model: %s'):format(modelLabel),
                description = ('Spawn: %s'):format(modelName),
                icon = 'fa-solid fa-car',
            },
            {
                title = ('Owner: %s'):format(ownerText),
                icon = ownerData and 'fa-solid fa-user' or 'fa-solid fa-xmark',
            },
        }
        lib.registerContext({
            id = 'police_menu_vehicle_info',
            title = 'Vehicle Info',
            options = Menu
        })
        lib.showContext('police_menu_vehicle_info')
    end, plate)
end
-- End of Vehicle Info --

-- Start of Vehicle Lockpick --
function LockpickVehicle()
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 5.0, false)
    if not vehicle or not DoesEntityExist(vehicle) then
        ESX.Notify(PlayerData.job.label, 'No vehicle found nearby', 'error', 5000)
    else
        local vehCoords = GetEntityCoords(vehicle)
        local dist = #(coords - vehCoords)
        if dist < 2.5 then
            LockpickAnim(vehicle)
        else
            ESX.Notify(PlayerData.job.label, 'The target vehicle is too far away', 'error', 5000)
        end
    end
end

function LockpickAnim(vehicle)
    if not DoesEntityExist(vehicle) then
        ESX.Notify(PlayerData.job.label, 'No vehicle found nearby', 'error', 5000)
    else
        local playerCoords = GetEntityCoords(cache.ped)
        local targetCoords = GetEntityCoords(vehicle)
        local dist = #(playerCoords - targetCoords)
        if dist < 2.5 then
            TaskTurnPedToFaceCoord(cache.ped, targetCoords.x, targetCoords.y, targetCoords.z, 2000)
            Wait(2000)
            local status = lib.progressBar({
                duration = 7500,
                label = 'Lockpicking Vehicle . . .',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    mouse = false,
                    weapon = false
                },
                anim = {
                    scenario = 'PROP_HUMAN_PARKING_METER'
                }
            })
            if status then
                SetVehicleDoorsLocked(vehicle, 1)
                SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                ESX.Notify(PlayerData.job.label, 'You have successfully unlocked the target vehicle', 'success', 5000)
            else
                ESX.Notify(PlayerData.job.label, 'You cancelled your last action', 'error', 5000)
            end
        else
            ESX.Notify(PlayerData.job.label, 'The target vehicle is too far away', 'error', 5000)
        end
    end
end
-- End of Vehicle Lockpick --

-- Start of Impound Vehicle --
function impoundVehicle()
    TriggerEvent('jg-advancedgarages:client:show-impound-form')
end
-- End of Impound Vehicle --

-- Start of GSR Test --
local GSRTest = false
local GSRTestTimer = 0

local function GSRThread()
    CreateThread(function()
        while GSRTest do
            Wait(1000)
            GSRTestTimer -= 1
            if GSRTestTimer <= 0 then
                GSRTest = false
                TriggerServerEvent('cfx-cs-police:RegisterGSR', false)
                break
            end
            if not GSRTest then break end
        end
    end)
end

function WhitelistedWeaponGroup(hash)
    local group = GetWeapontypeGroup(hash)
    if group == `GROUP_MELEE` then
        return true
    end
    if group == 1548507267 then
        return true
    end
    if group == `GROUP_PETROLCAN` then
        return true
    end
    if group == `GROUP_FIREEXTINGUISHER` then
        return true
    end
    return false
end

CreateThread(function()
    while true do
        local sleep = 500
        if cache.weapon and not WhitelistedWeaponGroup(cache.weapon) then
            sleep = 0
            if IsPedShooting(cache.ped) then
                if not GSRTest then
                    GSRTest = true
                    GSRTestTimer = Config.GSR.GSRTestTimer
                    TriggerServerEvent('cfx-cs-police:RegisterGSR', true)
                    GSRThread()
                else
                    GSRTestTimer = Config.GSR.GSRTestTimer
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('cfx-cs-police:gsrTest', function(data)
    if not HasGroup() then return end
    local playerId = GetTargetServerId(data, 5.0)
    if not playerId then
        ESX.Notify(PlayerData.job.label, 'No nearby player.', 'error', 5000)
        return
    end

    pcall(function()
        exports['cfx-keydi-ui']:playEmoteByCommand('clipboard')
    end)

    local status = lib.progressBar({
        duration = 5000,
        label = 'Please Wait . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            weapon = false
        }
    })

    pcall(function()
        exports['cfx-keydi-ui']:cancelEmote(true)
    end)

    if not status then
        ESX.Notify('GSR TEST', 'Cancelled.', 'error', 5000)
        return
    end

    local result = lib.callback.await('cfx-cs-police:GSRTest', false, playerId)
    if not result or not result.success then
        local reason = result and result.reason or 'unknown'
        if reason == 'too_far' then
            ESX.Notify('GSR TEST', 'Subject is too far away.', 'error', 5000)
        elseif reason == 'not_police' then
            ESX.Notify('GSR TEST', 'You are not authorized.', 'error', 5000)
        else
            ESX.Notify('GSR TEST', 'Unable to complete GSR test.', 'error', 5000)
        end
        return
    end

    if result.positive then
        ESX.Notify('GSR TEST', 'Subject Tested Positive GSR', 'success', 5000)
    else
        ESX.Notify('GSR TEST', 'Subject Tested Negative GSR', 'error', 5000)
    end
end)

local OngoingTextUI = false

function GSRTextUI()
    local Seconds = 30
    while true do
        Wait(1000)
        Seconds -= 1
        lib.showTextUI(('[GSR]: %s seconds remaining'):format(Seconds), {
            position = "bottom-center",
            icon = 'fa-solid fa-radiation',
            iconColor = '#63E6BE',
            style = {
                backgroundColor = '#212121',
                color = 'white',
                ['.description'] = {
                  color =  'white'
                },
                boxShadow = '0 0 10px rgba(0, 0, 0, 0.5)'
            }
        })
        if Seconds <= 0 then
            lib.hideTextUI()
            break
        end
    end
    OngoingTextUI = false
    return true
end

CreateThread(function()
    while true do
        Wait(2000)
        if GSRTest and GSRTestTimer > 0 then
            local ped = PlayerPedId()
            if IsEntityInWater(ped) and not OngoingTextUI then
                OngoingTextUI = true
                ESX.Notify('GSR', 'You begin cleaning off the Gunshot Residue... stay in the water.', 'info', 5000)
                Wait(100)
                local washed = GSRTextUI()
                if washed then
                    if IsEntityInWater(ped) then
                        GSRTest = false
                        TriggerServerEvent('cfx-cs-police:RegisterGSR', false)
                        ESX.Notify('GSR', 'You washed off all the Gunshot Residue in the water.', 'success', 5000)
                    else
                        ESX.Notify('GSR', 'You left the water too early and did not wash off the gunshot residue.', 'error', 5000)
                    end
                end
            end
        end
    end
end)

-- End of GSR Test --

-- Start of Riot Shield --
local RiotShield = {
    active = false,
    entity = nil,
    lastHealth = nil,
}

local function PlayShieldAnim(ped)
    local anim = Config.RiotShield.anim
    lib.requestAnimDict(anim.dict, 10000)
    TaskPlayAnim(ped, anim.dict, anim.name, 8.0, 8.0, -1, 49, 0.0, false, false, false)
end

local function DisableShield(silent)
    local ped = cache.ped
    if RiotShield.entity and DoesEntityExist(RiotShield.entity) then
        DetachEntity(RiotShield.entity, true, false)
        SetEntityAsMissionEntity(RiotShield.entity, true, true)
        DeleteObject(RiotShield.entity)
    end
    RiotShield.entity = nil
    RiotShield.active = false
    RiotShield.lastHealth = nil
    ClearPedTasks(ped)
    if not silent then
        ESX.Notify(PlayerData.job and PlayerData.job.label or 'Police', 'Riot shield deactivated.', 'error', 4000)
    end
end

local function loadShieldModel()
    local cfg = Config.RiotShield
    local models = { cfg.model, cfg.fallbackModel, `prop_ballistic_shield`, `prop_riot_shield` }
    for i = 1, #models do
        local model = models[i]
        if model then
            lib.requestModel(model, 8000)
            if HasModelLoaded(model) then
                return model
            end
        end
    end
    return nil
end

local function EnableShield()
    if not HasGroup() then
        ESX.Notify('PD Armory', 'Only on-duty police can use a riot shield.', 'error', 4000)
        return
    end
    if RiotShield.active then return end

    local ped = cache.ped
    local cfg = Config.RiotShield
    local coords = GetEntityCoords(ped)
    local model = loadShieldModel()
    if not model then
        ESX.Notify(PlayerData.job and PlayerData.job.label or 'Police', 'Riot shield model failed to load.', 'error', 4000)
        return
    end

    local shield = CreateObjectNoOffset(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
    if (not shield or shield == 0 or not DoesEntityExist(shield)) then
        shield = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
    end
    SetModelAsNoLongerNeeded(model)
    if not shield or shield == 0 or not DoesEntityExist(shield) then
        ESX.Notify(PlayerData.job and PlayerData.job.label or 'Police', 'Riot shield could not be equipped.', 'error', 4000)
        return
    end

    SetEntityAsMissionEntity(shield, true, true)
    SetEntityVisible(shield, true, false)
    SetEntityCollision(shield, false, false)

    local boneIndex = GetPedBoneIndex(ped, cfg.bone or 45509)
    if not boneIndex or boneIndex == -1 then
        boneIndex = GetEntityBoneIndexByName(ped, 'IK_L_Hand')
    end
    AttachEntityToEntity(
        shield, ped, boneIndex,
        cfg.offset.x, cfg.offset.y, cfg.offset.z,
        cfg.rotation.x, cfg.rotation.y, cfg.rotation.z,
        true, true, false, true, 1, true
    )

    RiotShield.entity = shield
    RiotShield.active = true
    RiotShield.lastHealth = GetEntityHealth(ped)
    PlayShieldAnim(ped)
    ESX.Notify(PlayerData.job and PlayerData.job.label or 'Police', 'Riot shield activated.', 'success', 4000)

    CreateThread(function()
        local anim = Config.RiotShield.anim
        while RiotShield.active do
            Wait(0)
            ped = cache.ped

            if Player(cache.serverId).state.dead or IsPedInAnyVehicle(ped, false) then
                DisableShield()
                break
            end

            -- Block shooting while riot shield is equipped
            DisablePlayerFiring(cache.playerId, true)
            DisableControlAction(0, 24, true)  -- INPUT_ATTACK
            DisableControlAction(0, 25, true)  -- INPUT_AIM
            DisableControlAction(0, 69, true)  -- INPUT_VEH_ATTACK
            DisableControlAction(0, 70, true)  -- INPUT_VEH_ATTACK2
            DisableControlAction(0, 92, true)  -- INPUT_VEH_PASSENGER_ATTACK
            DisableControlAction(0, 114, true) -- INPUT_VEH_FLY_ATTACK
            DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
            DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
            DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
            DisableControlAction(0, 257, true) -- INPUT_ATTACK2
            DisableControlAction(0, 263, true) -- INPUT_MELEE_ATTACK1
            DisableControlAction(0, 264, true) -- INPUT_MELEE_ATTACK2

            if not IsEntityPlayingAnim(ped, anim.dict, anim.name, 3) then
                PlayShieldAnim(ped)
            end
        end
    end)
end

local function ToggleRiotShield()
    if Player(cache.serverId).state.dead then return end
    if RiotShield.active then
        DisableShield()
    else
        EnableShield()
    end
end

RegisterNetEvent('cfx-cs-police:EquipShield', ToggleRiotShield)
RegisterNetEvent('kodebykarl-police:EquipShield', ToggleRiotShield)
exports('useRiotShield', ToggleRiotShield)

-- Reduce incoming damage while riot shield is active (Config.RiotShield.damageReduction)
AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if not RiotShield.active then return end

    local victim = args[1]
    if victim ~= cache.ped then return end

    local ped = cache.ped
    local currentHealth = GetEntityHealth(ped)
    local lastHealth = RiotShield.lastHealth or currentHealth
    local damageTaken = lastHealth - currentHealth

    if damageTaken > 0 then
        local reduced = math.floor(damageTaken * (1.0 - (Config.RiotShield.damageReduction or 0.5)))
        local restore = damageTaken - reduced
        if restore > 0 then
            SetEntityHealth(ped, math.min(lastHealth - reduced, GetEntityMaxHealth(ped)))
        end
    end

    RiotShield.lastHealth = GetEntityHealth(ped)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if RiotShield.active then
        DisableShield(true)
    end
end)
-- End of Riot Shield --