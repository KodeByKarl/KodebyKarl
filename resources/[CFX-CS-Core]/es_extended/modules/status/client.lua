CreateThread(function()
	while true do
		Wait(Config.Status.client_interval)
		if ESX.PlayerLoaded then
            TriggerServerEvent('es_extended:status:update')
        end
	end
end)


CreateThread(function()
    while true do
        if ESX.PlayerLoaded then
            local metadata = ESX.PlayerData.metadata
            if (metadata and metadata.status and (metadata.status.hunger <= 0 or metadata.status.thirst <= 0)) and not IsEntityDead(ESX.PlayerData.ped) then
				math.randomseed(GetGameTimer())
				local currentHealth = GetEntityHealth(ESX.PlayerData.ped)
                local decreaseThreshold = math.random(5, 10)
                SetEntityHealth(ESX.PlayerData.ped, currentHealth - decreaseThreshold)
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
            end
        end
        Wait(5000)
    end
end)


local removeStatus = {
	['stress'] = 'ESX:Status:RemoveStress',
	['hunger'] = 'ESX:Status:RemoveHunger',
	['thirst'] = 'ESX:Status:RemoveThirst'
}

local addStatus = {
	['stress'] = 'ESX:Status:AddStress',
	['hunger'] = 'ESX:Status:AddHunger',
	['thirst'] = 'ESX:Status:AddThirst'
}

AddEventHandler('es_extended:status:Add', function(status, value)
    if status == 'stress' and LocalPlayer.state.DisableStress then return end
	TriggerServerEvent(addStatus[status], value)
end)

AddEventHandler('es_extended:status:Remove', function(status, value)
	TriggerServerEvent(removeStatus[status], -value)
end)

function IsWhitelistedWeaponStress(weapon)
    if weapon then
        for _, v in pairs(Config.Status.whitelistWeapons) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

CreateThread(function()
    while true do
        local ped = cache.ped
        if IsPedInAnyVehicle(ped, false) then
            local speedMultiplier = 3.6
            local speed = GetEntitySpeed(GetVehiclePedIsIn(ped, false)) * speedMultiplier
            local stressSpeed = Config.Status.vehicleSpeed
            if speed >= stressSpeed then
				TriggerEvent('es_extended:status:Add', 'stress', Config.Status.addStress.vehicle)
            end
        end
        Wait(10000)
    end
end)

CreateThread(function()
    while true do
        local ped = cache.ped
        local weapon = GetSelectedPedWeapon(ped)
        if weapon ~= `WEAPON_UNARMED` then
            if IsPedShooting(ped) then
                if math.random() < 0.15 and not IsWhitelistedWeaponStress(weapon) then
                    TriggerEvent('es_extended:status:Add', 'stress', Config.Status.addStress.shoot)
                end
            end
        else
            Wait(900)
        end
        Wait(8)
    end
end)

function BlinkStress(blurrLength, chance)
    DoFade('fadein')
    TriggerScreenblurFadeIn(1000)
    DoFade('fadeout')
    Wait(blurrLength)
    if math.random(1, 100) < chance then
        DoFade('fadein')
        DoFade('fadeout')
        Wait(blurrLength)
    end
    DoFade('fadein')
    TriggerScreenblurFadeOut(1000)
    DoFade('fadeout')
end

function DoFade(type)
    local opacity = 170
    if type == 'fadein' then
        opacity = 0
    end
    if type == 'fadein' then
        while opacity < 170 do
            if opacity < 170 then
                opacity = opacity + 2
            end
            DrawRect(0, 0, 10.0, 10.0, 1, 1, 1, opacity)
            Wait(1)
        end
    end
    if type == 'fadeout' then
        while opacity > 0 do
            if opacity > 0 then
                opacity = opacity - 2
            end
            DrawRect(0, 0, 10.0, 10.0, 1, 1, 1, opacity)
            Wait(1)
        end
    end
end

CreateThread(function()
    while true do
        Wait(1000)
        if ESX.PlayerLoaded and ESX.PlayerData.metadata then
            local metadata = ESX.PlayerData.metadata
            local stressChance = math.random(1, 100)
            if metadata['status'] then
                if metadata['status']['stress'] >= 80 then
                    Wait(1000)
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.5)
                    if stressChance <= 80 then
                        BlinkStress(5000, 95)
                    end
                elseif metadata['status']['stress'] >= 70 then
                    Wait(1000)
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
                    if stressChance <= 70 then
                        BlinkStress(3000, 70)
                    end
                elseif metadata['status']['stress'] >= 60 then
                    Wait(1000)
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
                    if stressChance <= 60 then
                        BlinkStress(2000, 60)
                    end
                elseif metadata['status']['stress'] >= 50 then
                    Wait(1000)
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
                    if stressChance <= 50 then
                        BlinkStress(1000, 50)
                    end
                end
            end
        end
    end
end)