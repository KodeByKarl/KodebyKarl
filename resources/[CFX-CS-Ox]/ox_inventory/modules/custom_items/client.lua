--[[ Custom item client effects (migrated from ox_items) ]]
local ox_inventory = exports[shared.resource]
local ESX = exports['es_extended']:getSharedObject()
local Handcuff = false
local DragPlayer = false
local DragBy = 0
local isEscorting = false
local isEscortingTarget = 0

local xSound
CreateThread(function()
    for _ = 1, 50 do
        if GetResourceState('xsound') == 'started' then
            local ok, exp = pcall(function()
                return exports.xsound
            end)
            if ok and exp then
                xSound = exp
                break
            end
        end
        Wait(200)
    end
end)

local function notify(title, message, nType, duration)
    lib.notify({
        title = title,
        description = message,
        type = nType or 'inform',
        duration = duration or 5000,
    })
end
local activeRadios = {}
local isUsingBoombox = false

local function canCuff(thePed)
    return IsEntityPlayingAnim(thePed, 'missminuteman_1ig_2', 'handsup_base', 3)
        or IsEntityPlayingAnim(thePed, 'missminuteman_1ig_2', 'handsup_enter', 3)
        or IsEntityPlayingAnim(thePed, 'random@mugging3', 'handsup_standing_base', 3)
end

local function SearchPlayer()
    local coords = GetEntityCoords(cache.ped)
    local player = lib.getClosestPlayer(coords, 2.5, false)
    if not player then
        return notify('SEARCH', 'No nearby player.', 'error', 5000)
    end
    local playerId = GetPlayerServerId(player)
    local isDead = Player(playerId).state.dead
    local dict = not isDead and 'mini@repair' or nil
    local clip = not isDead and 'fixing_a_ped' or nil
    local scenario = isDead and 'CODE_HUMAN_MEDIC_TEND_TO_DEAD' or nil
    local time = isDead and 8000 or 2500
    local flag = 49
    local status = lib.progressBar({
        duration = time,
        label = 'Searching Please Wait . . .',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        },
        anim = {
            dict = dict,
            clip = clip,
            scenario = scenario,
            flag = flag
        }
    })
    if status then
        LocalPlayer.state:set('invBusy', false, true)
        Wait(100)
        exports.ox_inventory:openInventory('player', playerId)
    end
end

CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        label = 'Search',
        icon = 'fa-solid fa-magnifying-glass',
        distance = 2.0,
        canInteract = function(entity, distance, coords, name, bone)
            local networkId = NetworkGetPlayerIndexFromPed(entity)
            local targetId = GetPlayerServerId(networkId)
            return (canCuff(entity) or Player(targetId).state.dead) or IsEntityPlayingAnim(entity, 'mp_arresting', 'idle', 3)
        end,
        onSelect = function()
            SearchPlayer()
        end
    })
end)


local function ItemCuff()
    local coords = GetEntityCoords(cache.ped)
    local targetPlayer, targetPed = lib.getClosestPlayer(coords, 2.5, false)
    if not targetPlayer then return notify('HANDCUFF', 'No nearby player.', 'error', 5000) end
    if not canCuff(targetPed) then notify('HANDCUFF', 'The target must raise their hand.', 'error', 5000) return end
    local playerId = GetPlayerServerId(targetPlayer)
    if Player(playerId).state.dead then return notify('HANDCUFF', 'Person appears unconcious', 'error', 5000) end
    TriggerServerEvent('ox_items:handcuff', playerId)
end

local function ItemUncuff()
    local coords = GetEntityCoords(cache.ped)
    local targetPlayer, targetPed = lib.getClosestPlayer(coords, 2.5, false)
    if not targetPlayer then return notify('HANDCUFF KEY', 'No nearby player.', 'error', 5000) end
    if not IsEntityPlayingAnim(targetPed, 'mp_arresting', 'idle', 3) then return notify('HANDCUFF KEY', 'You need to cuff first!', 'error', 5000)  end
    local playerId = GetPlayerServerId(targetPlayer)
    if Player(playerId).state.dead then return notify('HANDCUFF KEY', 'Person appears unconcious', 'error', 5000) end
    TriggerServerEvent('ox_items:handcuff_keys', playerId)
end

local function itemRope()
    local coords = GetEntityCoords(cache.ped)
    local targetPlayer, targetPed = lib.getClosestPlayer(coords, 2.5, false)
    if not targetPlayer then return notify('ROPE', 'No nearby player.', 'error', 5000) end
    if not IsEntityPlayingAnim(targetPed, 'mp_arresting', 'idle', 3) then return notify('ROPE', 'You need to cuff first!', 'error', 5000)  end
    local playerId = GetPlayerServerId(targetPlayer)
    if Player(playerId).state.dead then return notify('ROPE', 'Person appears unconcious', 'error', 5000) end
    TriggerServerEvent('ox_items:rope', playerId)
end

RegisterNetEvent('ox_items:handcuffClient', function()
    if GetInvokingResource() ~= nil then return end
    if source ~= 65535 then return end
    local ped = cache.ped
    Handcuff = true
    lib.requestAnimDict('mp_arresting', 10000)
	TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
	RemoveAnimDict('mp_arresting')
	SetEnableHandcuffs(ped, true)
	DisablePlayerFiring(ped, true)
	FreezeEntityPosition(ped, true)
    TriggerEvent('ox_inventory:disarm')
end)


RegisterNetEvent('ox_items:handcuffKeyClient', function()
    if GetInvokingResource() ~= nil then return end
    if source ~= 65535 then return end
    if DragPlayer then
        DragPlayer = false
        DragBy = 0
    end
    local ped = cache.ped
    Handcuff = false
    ClearPedSecondaryTask(ped)
	SetEnableHandcuffs(ped, false)
	DisablePlayerFiring(ped, false)
	SetPedCanPlayGestureAnims(ped, true)
	FreezeEntityPosition(ped, false)
end)


lib.callback.register('ox_items:RopeUsed', function(targetId, label, escorting)
    local success = lib.progressBar({
        duration = 1000,
        label = label,
        useWhileDead = false,
        canCancel = true,
    })
    if success then
        isEscorting = escorting
        isEscortingTarget = targetId
    end
    return success
end)

RegisterNetEvent('ox_items:ropeClient', function(copId)
    if GetInvokingResource() ~= nil then return end
    if source ~= 65535 then return end
    if not DragPlayer then
        DragPlayer = true
        DragBy = copId
    else
        DragPlayer = false
        DragBy = 0
    end
end)

CreateThread(function()
    local alrEscorting
    while true do
        local sleep = 1500
        if isEscorting then
            sleep = 0
            local targetPed = GetPlayerPed(GetPlayerFromServerId(isEscortingTarget))
            if DoesEntityExist(targetPed) and IsPedOnFoot(targetPed) and not IsPedDeadOrDying(targetPed, true) then
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
                isEscorting = false
                ClearPedTasks(cache.ped)
            end
        elseif alrEscorting then
            alrEscorting = nil
            isEscorting = false
            ClearPedTasks(cache.ped)
        else
            sleep = 1500
        end
        Wait(sleep)
    end
end)

CreateThread(function()
	local wasDragged
	while true do
		local Sleep = 1500
		if Handcuff and DragPlayer then
			Sleep = 50
			local targetPed = GetPlayerPed(GetPlayerFromServerId(DragBy))
			if DoesEntityExist(targetPed) and IsPedOnFoot(targetPed) and not IsPedDeadOrDying(targetPed, true) then
				if not wasDragged then
					AttachEntityToEntity(cache.ped, targetPed, 11816, 0.26, 0.48, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
					wasDragged = true
				else
					Sleep = 500
				end
                if IsPedWalking(targetPed) then
                    if not IsEntityPlayingAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 3) then
                        lib.requestAnimDict('anim@move_m@prisoner_cuffed', 10000)
                        TaskPlayAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 8.0, -8, -1, 1, 0.0, false, false, false)
                    end
                elseif IsPedRunning(targetPed) or IsPedSprinting(targetPed) then
                    if not IsEntityPlayingAnim(cache.ped, 'anim@move_m@trash', 'run', 3) then
                        lib.requestAnimDict('anim@move_m@trash', 10000)
                        TaskPlayAnim(cache.ped, 'anim@move_m@trash', 'run', 8.0, -8, -1, 1, 0.0, false, false, false)
                    end
                elseif IsEntityPlayingAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 3) or IsEntityPlayingAnim(cache.ped, 'anim@move_m@trash', 'run', 3) then
                    StopAnimTask(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', -8.0)
                    StopAnimTask(cache.ped, 'anim@move_m@trash', 'run', -8.0)
                end
			else
				wasDragged = false
				DragPlayer = false
				DetachEntity(cache.ped, true, false)
			end
		elseif wasDragged then
			wasDragged = false
			DetachEntity(cache.ped, true, false)
		end
	    Wait(Sleep)
	end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if Handcuff then
            sleep = 0
            if not IsEntityPlayingAnim(cache.ped, 'mp_arresting', 'idle', 3) then
                TaskPlayAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
            end
        end
        Wait(sleep)
    end
end)


exports('isHandcuffed', function()
    return Handcuff
end)

local function setDrunk(duration)
    CreateThread(function()
        local ped = cache.ped
        SetTimecycleModifier("spectator5")
        SetPedMotionBlur(ped, true)
        SetPedIsDrunk(ped, true)
        AnimpostfxPlay("ChopVision", 10000001, true)
        ShakeGameplayCam("DRUNK_SHAKE", 5.0)
        Wait(duration)
        SetPedIsDrunk(ped, false)
        SetPedMotionBlur(ped, false)
        AnimpostfxStopAll()
        ShakeGameplayCam("DRUNK_SHAKE", 0.0)
        SetTimecycleModifierStrength(0.0)
    end)
end


RegisterNetEvent('wasabi_boombox:syncActive', function(activeBoxes)
    activeRadios = activeBoxes
end)


AddEventHandler('wasabi_boombox:playMenu', function(data)
    if data.type == 'play' and not xSound then
        return notify('BOOMBOX', 'Audio engine is not available.', 'error')
    end
    local musicId = 'id_'..data.id
    if data.type == 'play' then
        local keyboard = lib.inputDialog('Play Music', {'Youtube URL','Distance (Max 40)', 'Volume (1-100)'})
        if keyboard then
            if keyboard[1] and tonumber(keyboard[2]) and tonumber(keyboard[2]) <= 40 and tonumber(keyboard[3]) and tonumber(keyboard[3]) <= 100 then
                TriggerServerEvent("wasabi_boombox:soundStatus", "play", musicId, { position = activeRadios[data.id].pos, link = keyboard[1], volume = keyboard[3]/100, distance = keyboard[2] })
                activeRadios[data.id].data = {playing = true, currentId = 'id_'..cache.playerId}
                TriggerServerEvent('wasabi_boombox:syncActive', activeRadios)
            end
        end
    elseif data.type == 'stop' then
        TriggerServerEvent("wasabi_boombox:soundStatus", "stop", musicId, {})
        activeRadios[data.id].data = {playing = false}
        TriggerServerEvent('wasabi_boombox:syncActive', activeRadios)
    elseif data.type == 'volume' then
        local keyboard = lib.inputDialog('Change Volume', {'Volume (1-100)'})    
        if keyboard then
            if tonumber(keyboard[1]) and tonumber(keyboard[1]) <= 100 then
                TriggerServerEvent("wasabi_boombox:soundStatus", "volume", musicId, {volume = keyboard[1]/100})
            end
        end
    elseif data.type == 'distance' then
        local keyboard = lib.inputDialog('Change Distance', {'Distance (Max 40)'})
        if keyboard then
            if tonumber(keyboard[1]) and tonumber(keyboard[1]) <= 40 then
                TriggerServerEvent("wasabi_boombox:soundStatus", "distance", musicId, {distance = keyboard[1]})
            end
        end
    end
end)

RegisterNetEvent('wasabi_boombox:soundStatus', function(type, musicId, data)
    CreateThread(function()
        if not xSound then return end
        if type == "position" then
            if xSound:soundExists(musicId) then
                xSound:Position(musicId, data.position)
            end
        end
        if type == "play" then
            xSound:PlayUrlPos(musicId, data.link, data.volume, data.position)
            xSound:Distance(musicId, data.distance)
            xSound:setVolume(musicId, data.volume)
        end

        if type == "volume" then
            xSound:setVolume(musicId, data.volume)
        end

        if type == "stop" then
            xSound:Destroy(musicId)
        end
    end)
end)

local function interactBoombox(radio, radioCoords)
    if not activeRadios[radio] then
        activeRadios[radio] = {
            pos = radioCoords,
            data = {
                playing = false
            }
        }
    else
        activeRadios[radio].pos = radioCoords
    end
    TriggerServerEvent('wasabi_boombox:syncActive', activeRadios)
    if not activeRadios[radio].data.playing then
        lib.registerContext({
            id = 'boomboxFirst',
            title = 'Boombox',
            options = {
                {
                    title = 'Play Music',
                    description = 'Play Music On Speaker',
                    arrow = true,
                    event = 'wasabi_boombox:playMenu',
                    args = {type = 'play', id = radio}
                }
            }
        })
        lib.showContext('boomboxFirst')
    else
        lib.registerContext({
            id = 'boomboxSecond',
            title = 'Boombox',
            options = {
                {
                    title = 'Change Music',
                    description = 'Change music on speaker',
                    arrow = true,
                    event = 'wasabi_boombox:playMenu',
                    args = {type = 'play', id = radio}
                },
                {
                    title = 'Stop Music',
                    description = 'Stop music on speaker',
                    arrow = false,
                    event = 'wasabi_boombox:playMenu',
                    args = {type = 'stop', id = radio}
                },
                {
                    title = 'Adjust Volume',
                    description = 'Change volume on speaker',
                    arrow = false,
                    event = 'wasabi_boombox:playMenu',
                    args = {type = 'volume', id = radio}
                },
                {
                    title = 'Change Distance',
                    description = 'Change distance on speaker',
                    arrow = false,
                    event = 'wasabi_boombox:playMenu',
                    args = {type = 'distance', id = radio}
                }
            }
        })
        lib.showContext('boomboxSecond')
    end
end

AddEventHandler('wasabi_boombox:interact', function()
    local pedCoords = GetEntityCoords(cache.ped)
    local radio = GetClosestObjectOfType(pedCoords, 5.0, `prop_boombox_01`, false)
    local radioCoords = GetEntityCoords(radio)
    interactBoombox(radio, radioCoords)
end)


local function boomboxPlaced(obj)
    local coords = GetEntityCoords(obj)
    local heading = GetEntityHeading(obj)
    local zoneId
    TriggerServerEvent('wasabi_boombox:registerBoombox', ObjToNet(obj))
    CreateThread(function()
        while true do
            if DoesEntityExist(obj) and not zoneId then
                zoneId = exports.ox_target:addBoxZone({
                    coords = coords,
                    size = vec3(1.2, 1.2, 1.8),
                    rotation = heading,
                    debug = false,
                    options = {
                        {
                            name = 'boombox_interact',
                            event = 'wasabi_boombox:interact',
                            icon = 'fas fa-hand-paper',
                            label = 'Interact',
                            distance = 1.5,
                        },
                        {
                            name = 'boombox_pickup',
                            event = 'wasabi_boombox:pickup',
                            icon = 'fas fa-volume-up',
                            label = 'Pick Up',
                            distance = 1.5,
                        },
                    },
                })
            elseif not DoesEntityExist(obj) then
                if zoneId then
                    exports.ox_target:removeZone(zoneId)
                    zoneId = nil
                end
                break
            end
            Wait(1000)
        end
    end)
end

RegisterNetEvent('wasabi_boombox:deleteObj', function(netId)
    local boombox = NetToObj(netId)
    if DoesEntityExist(boombox) then
        DeleteObject(boombox)
    end
end)

AddEventHandler('wasabi_boombox:pickup', function()
    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)
    local radio = `prop_boombox_01`
    local closestRadio = GetClosestObjectOfType(pedCoords, 3.0, radio, false)
    local radioCoords = GetEntityCoords(closestRadio)
    local musicId = 'id_'..closestRadio
    TaskTurnPedToFaceCoord(ped, radioCoords.x, radioCoords.y, radioCoords.z, 2000)
    lib.requestAnimDict('pickup_object', 10000)
    TaskPlayAnim(ped, "pickup_object", "pickup_low", 8.0, 8.0, -1, 50, 0, false, false, false)
    Wait(1000)
    if xSound and xSound:soundExists(musicId) then
        TriggerServerEvent("wasabi_boombox:soundStatus", "stop", musicId, {})
    end
    FreezeEntityPosition(closestRadio, false)
    TriggerServerEvent("wasabi_boombox:deleteObj", ObjToNet(closestRadio))
    if activeRadios[closestRadio] then
        activeRadios[closestRadio] = nil
    end
    TriggerServerEvent('wasabi_boombox:syncActive', activeRadios)
    ClearPedTasks(ped)
end)

local function hasBoomBox(radio)
    local equipRadio = true
    LocalPlayer.state.invBusy = true
    CreateThread(function()
        lib.showTextUI('Press E to drop boombox', {
            position = "bottom-center",
            icon = 'fa-solid fa-radio',
            iconColor = '#00CB86',
            style = {
                backgroundColor = '#212121',
                color = 'white',
                ['.description'] = {
                  color =  'white'
                },
                boxShadow = '0 0 10px rgba(0, 0, 0, 0.5)'
            }
        })
        while equipRadio do
            Wait(0)
            if IsControlJustReleased(0, 38) then
                LocalPlayer.state.invBusy = false
                lib.hideTextUI()
                equipRadio = false
                isUsingBoombox = false
				DetachEntity(radio)
				PlaceObjectOnGroundProperly(radio)
                FreezeEntityPosition(radio, true)
                boomboxPlaced(radio)
            end
        end
    end)
end

local function UseBoombox()
    if isUsingBoombox then return end
    isUsingBoombox = true
    local ped = cache.ped
    local hash = lib.requestModel('prop_boombox_01', 10000)
    local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(ped,0.0,3.0,0.5))
    local radio = CreateObjectNoOffset(hash, x, y, z, true, false)
    SetModelAsNoLongerNeeded(hash)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`)
    AttachEntityToEntity(radio, ped, GetPedBoneIndex(ped, 57005), 0.32, 0, -0.05, 0.10, 270.0, 60.0, true, true, false, true, 1, true)
    hasBoomBox(radio)
end

local iShowSpeed = false
local energyDrinkBoost = false
local policeDrinkBoost = false

lib.callback.register('ox_inventory:canUseBandage', function()
    if GetResourceState('kodebykarl-ambulance') == 'started' then
        local ok, dead = pcall(function()
            return exports['kodebykarl-ambulance']:isDead()
        end)
        if ok and dead then
            return false, 'You cannot use a bandage while dead.'
        end
    end

    if LocalPlayer.state.dead then
        return false, 'You cannot use a bandage while dead.'
    end

    local ped = cache.ped
    local maxHealth = GetEntityMaxHealth(ped)
    if GetEntityHealth(ped) >= maxHealth - 1 then
        return false, 'You are already at full health.'
    end

    return true
end)

lib.callback.register('ox_inventory:isPlayerBleeding', function()
    if GetResourceState('kodebykarl-ambulance') ~= 'started' then
        return false
    end

    local ok, bleeding = pcall(function()
        return exports['kodebykarl-ambulance']:IsBleeding()
    end)

    return ok and bleeding or false
end)

CreateThread(function()
	while true do
		local sleep = 500
		if energyDrinkBoost then
			sleep = 0
			-- Meth-like speed (not the old 3x super-sprint)
			SetPedMoveRateOverride(cache.ped, 1.25)
			SetRunSprintMultiplierForPlayer(cache.playerId, 1.20)
			RestorePlayerStamina(cache.playerId, 1.0)
		elseif policeDrinkBoost then
			sleep = 0
			SetPedMoveRateOverride(cache.ped, 1.49)
			SetRunSprintMultiplierForPlayer(cache.playerId, 1.49)
			RestorePlayerStamina(cache.playerId, 1.0)
		elseif iShowSpeed then
			sleep = 0
			SetPedMoveRateOverride(cache.ped, 1.5)
		end
		Wait(sleep)
	end
end)

RegisterNetEvent('ox_items:UsedItem', function(item)
    if GetInvokingResource() ~= nil then return end
    if source ~= 65535 then return end
    if item == 'bandage' then
        local ped = cache.ped
        SetPedMaxHealth(ped, 200)
        SetEntityMaxHealth(ped, 200)
        SetEntityHealth(ped, 200)
    elseif item == 'oxy' then
        local health = GetEntityHealth(cache.ped)
        local newHealth = health + 50
        if newHealth > 200 then newHealth = 200 end
        SetEntityHealth(cache.ped, newHealth)
        AddArmourToPed(cache.ped, 50)
    elseif item == 'cocaine' then
        local health = GetEntityHealth(cache.ped)
        local newHealth = health + 50
        if newHealth > 200 then newHealth = 200 end
        SetEntityHealth(cache.ped, newHealth)
        AddArmourToPed(cache.ped, 50)
    elseif item == 'ecstasy' then
        local health = GetEntityHealth(cache.ped)
        local newHealth = health + 50
        if newHealth > 200 then newHealth = 200 end
        SetEntityHealth(cache.ped, newHealth)
        AddArmourToPed(cache.ped, 50)
    elseif item == 'meth' then
        -- Meth: +50 health only
        local health = GetEntityHealth(cache.ped)
        local newHealth = health + 50
        if newHealth > 200 then newHealth = 200 end
        SetEntityHealth(cache.ped, newHealth)
    elseif item == 'joint' then
        local ped = cache.ped
        local current = GetPedArmour(ped) or 0
        SetPedArmour(ped, math.min(100, current + 50))
    elseif item == 'energy_drink' then
        energyDrinkBoost = true
        SetTimeout(5000, function()
            energyDrinkBoost = false
            SetPedMoveRateOverride(cache.ped, 1.0)
            SetRunSprintMultiplierForPlayer(cache.playerId, 1.0)
        end)
    elseif item == 'police_pill' then
        local ped = cache.ped
        local maxHealth = GetEntityMaxHealth(ped)
        if not maxHealth or maxHealth < 200 then maxHealth = 200 end
        SetEntityHealth(ped, maxHealth)
        SetPedArmour(ped, 100)
    elseif item == 'police_vest' then
        local ped = cache.ped
        SetPlayerMaxArmour(cache.playerId, 100)
        SetPedArmour(ped, 100)
        local model = GetEntityModel(ped)
        if model == `mp_m_freemode_01` then
            SetPedComponentVariation(ped, 9, 16, 0, 0)
        elseif model == `mp_f_freemode_01` then
            SetPedComponentVariation(ped, 9, 18, 0, 0)
        end
    elseif item == 'police_vitamins' or item == 'sheriff_vitamins' then
        local ped = cache.ped
        TriggerEvent('cfx-keydi-ambulance:client:RemoveBleed')
        if GetResourceState('kodebykarl-ambulance') == 'started' then
            pcall(function() exports['kodebykarl-ambulance']:RemoveBleed() end)
        end
        local maxHealth = GetEntityMaxHealth(ped)
        if not maxHealth or maxHealth < 200 then maxHealth = 200 end
        SetEntityHealth(ped, maxHealth)
        SetPedArmour(ped, 100)
    elseif item == 'police_drink' or item == 'sheriff_drink' then
        policeDrinkBoost = true
        local duration = item == 'police_drink' and 3000 or 10000
        SetTimeout(duration, function()
            policeDrinkBoost = false
            SetPedMoveRateOverride(cache.ped, 1.0)
            SetRunSprintMultiplierForPlayer(cache.playerId, 1.0)
        end)
    elseif item == 'handcuff' then
        ItemCuff()
    elseif item == 'handcuff_keys' then
        ItemUncuff()
    elseif item == 'rope' then
        itemRope()
    elseif item == 'police_sting' then
        iShowSpeed = true
		SetTimeout(5000, function()
			iShowSpeed = false
		end)
    elseif item == 'police_bandage' then
        local maxHealth = 800
	    local health = GetEntityHealth(cache.ped)
        SetEntityHealth(cache.ped, math.min(maxHealth, math.floor(health + maxHealth / 5)))
    elseif item == 'boombox' then
        UseBoombox()
    end
end)
