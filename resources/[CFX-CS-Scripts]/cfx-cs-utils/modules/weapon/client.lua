local config = require 'configs.weapon'

---------------------------------------------------------------------------
-- Gun license gate (requires police meta license and/or weaponlicense item)
---------------------------------------------------------------------------
local licenseCfg = config.RequireGunLicense or {}
local lastLicenseNotify = 0
local hasGunLicenseCache = nil
local licenseCacheAt = 0

local FIREARM_GROUPS = {
    [`GROUP_PISTOL`] = true,
    [`GROUP_SMG`] = true,
    [`GROUP_RIFLE`] = true,
    [`GROUP_MG`] = true,
    [`GROUP_SHOTGUN`] = true,
    [`GROUP_SNIPER`] = true,
    [`GROUP_HEAVY`] = true,
    [416676366] = true,       -- GROUP_PISTOL
    [-957766203] = true,      -- GROUP_SMG
    [860033945] = true,       -- GROUP_SHOTGUN
    [970310034] = true,       -- GROUP_RIFLE
    [1159398588] = true,      -- GROUP_MG
    [-1212426201] = true,     -- GROUP_SNIPER
    [-1569042529] = true,     -- GROUP_HEAVY
}

local NON_GUN_GROUPS = {
    [`GROUP_MELEE`] = true,
    [`GROUP_THROWN`] = true,
    [`GROUP_FIREEXTINGUISHER`] = true,
    [`GROUP_PETROLCAN`] = true,
    [-728555052] = true,      -- GROUP_MELEE
    [1548507267] = true,      -- GROUP_THROWN
}

local function notifyNoLicense()
    local now = GetGameTimer()
    local cooldown = tonumber(licenseCfg.notifyCooldown) or 4000
    if (now - lastLicenseNotify) < cooldown then return end
    lastLicenseNotify = now
    ESX.Notify(
        licenseCfg.notifyTitle or 'WEAPON LICENSE',
        licenseCfg.notifyMessage or 'You need a weapon license to use this firearm.',
        'error',
        5000
    )
end

local function isExemptJob()
    local data = ESX.GetPlayerData and ESX.GetPlayerData() or {}
    local job = data.job and data.job.name
    if not job then return false end
    local exempt = licenseCfg.exemptJobs or {}
    return exempt[job] == true
end

local function isFirearmThatNeedsLicense(weaponHash)
    if not weaponHash or weaponHash == 0 or weaponHash == `WEAPON_UNARMED` then
        return false
    end
    local exempt = licenseCfg.exemptWeapons or {}
    if exempt[weaponHash] then
        return false
    end
    local group = GetWeapontypeGroup(weaponHash)
    if FIREARM_GROUPS[group] then
        return true
    end
    if NON_GUN_GROUPS[group] then
        return false
    end
    -- Unknown/custom gun group: treat as firearm (safer for custom WEAPON_*)
    return true
end

local function refreshLicenseCache(force)
    local now = GetGameTimer()
    -- Short cache while armed so giving/dropping license is caught quickly
    local ttl = (cache.weapon and isFirearmThatNeedsLicense(cache.weapon)) and 1000 or 5000
    if not force and hasGunLicenseCache ~= nil and (now - licenseCacheAt) < ttl then
        return hasGunLicenseCache
    end

    if isExemptJob() then
        hasGunLicenseCache = true
        licenseCacheAt = now
        return true
    end

    local ok, allowed = pcall(function()
        return lib.callback.await('cfx-keydi-utils:weapon:hasGunLicense', false)
    end)

    hasGunLicenseCache = ok and allowed == true
    licenseCacheAt = now
    return hasGunLicenseCache
end

local function denyWeaponUse()
    notifyNoLicense()
    TriggerEvent('ox_inventory:disarm', true)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
end

local function enforceGunLicense(weaponHash)
    if not licenseCfg.enabled then return true end
    if not isFirearmThatNeedsLicense(weaponHash) then return true end
    if refreshLicenseCache(false) then return true end
    denyWeaponUse()
    return false
end

AddEventHandler('ox_inventory:currentWeapon', function(item)
    if not licenseCfg.enabled then return end
    if not item or not item.name then return end

    local hash = joaat(item.name)
    if not isFirearmThatNeedsLicense(hash) then return end

    if not refreshLicenseCache(true) then
        denyWeaponUse()
    end
end)

-- Keep enforcing while holding a gun (covers edge cases / cache expiry)
if licenseCfg.enabled then
    CreateThread(function()
        while true do
            local weapon = cache.weapon
            if weapon and isFirearmThatNeedsLicense(weapon) then
                if not refreshLicenseCache(true) then
                    denyWeaponUse()
                end
            end
            Wait(1000)
        end
    end)
end

-- Refresh cache when police grants / revokes license
RegisterNetEvent('cfx-keydi-utils:weapon:licenseUpdated', function(hasLicense)
    hasGunLicenseCache = hasLicense == true
    licenseCacheAt = GetGameTimer()
    if hasGunLicenseCache == false and cache.weapon and isFirearmThatNeedsLicense(cache.weapon) then
        denyWeaponUse()
    end
end)

AddEventHandler('esx:setJob', function()
    hasGunLicenseCache = nil
    licenseCacheAt = 0
end)

AddEventHandler('esx:playerLoaded', function()
    hasGunLicenseCache = nil
    licenseCacheAt = 0
end)

---------------------------------------------------------------------------
-- Existing weapon recoil / damage logic
---------------------------------------------------------------------------
local components = {
    [`WEAPON_PISTOL`] = { suppressor = `component_at_pi_supp_02`, grip = nil},
    [`WEAPON_PISTOL_MK2`] = { suppressor = `COMPONENT_AT_PI_SUPP_02`, grip = nil},
    [`WEAPON_PISTOL50`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = nil},
    [`WEAPON_COMBATPISTOL`] = { suppressor = `COMPONENT_AT_PI_SUPP`, grip = nil},
    [`WEAPON_APPISTOL`] = { suppressor = `COMPONENT_AT_PI_SUPP`, grip = nil},
    [`WEAPON_HEAVYPISTOL`] = { suppressor = `COMPONENT_AT_PI_SUPP`, grip = nil},
    [`WEAPON_SNSPISTOL_MK2`] = { suppressor = `COMPONENT_AT_PI_SUPP_02`, grip = nil},
    [`WEAPON_VINTAGEPISTOL`] = { suppressor = `COMPONENT_AT_PI_SUPP`, grip = nil},
    [`WEAPON_SMG`] = { suppressor = `COMPONENT_AT_PI_SUPP`, grip = nil},
    [`WEAPON_SMG_MK2`] = { suppressor = `COMPONENT_AT_PI_SUPP`, grip = nil},
    [`WEAPON_MICROSMG`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = nil},
    [`WEAPON_ASSAULTSMG`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = nil},
    [`WEAPON_ASSAULTRIFLE`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_ASSAULTRIFLE_MK2`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = `COMPONENT_AT_AR_AFGRIP_02`},
    [`WEAPON_CARBINERIFLE`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_CARBINERIFLE_MK2`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = `COMPONENT_AT_AR_AFGRIP_02`},
    [`WEAPON_ADVANCEDRIFLE`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = nil},
    [`WEAPON_SPECIALCARBINE`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_SPECIALCARBINE_MK2`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = `COMPONENT_AT_AR_AFGRIP_02`},
    [`WEAPON_BULLPUPRIFLE`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_BULLPUPRIFLE_MK2`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = `COMPONENT_AT_AR_AFGRIP_02`},
    [`WEAPON_MILITARYRIFLE`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = nil},
    [`WEAPON_TACTICALRIFLE`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_ASSAULTSHOTGUN`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_HEAVYSHOTGUN`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_BULLPUPSHOTGUN`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_PUMPSHOTGUN`] = { suppressor = `COMPONENT_AT_SR_SUPP`, grip = nil},
    [`WEAPON_PUMPSHOTGUN_MK2`] = { suppressor = `COMPONENT_AT_SR_SUPP_03`, grip = nil},
    [`WEAPON_COMBATMG_MK2`] = { suppressor = nil, grip = `COMPONENT_AT_AR_AFGRIP_02`},
    [`WEAPON_MARKSMANRIFLE`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = `COMPONENT_AT_AR_AFGRIP`},
    [`WEAPON_MARKSMANRIFLE_MK2`] = { suppressor = `COMPONENT_AT_AR_SUPP`, grip = `COMPONENT_AT_AR_AFGRIP_02`},
    [`WEAPON_SNIPERRIFLE`] = { suppressor = `COMPONENT_AT_AR_SUPP_02`, grip = nil},
    [`WEAPON_COMBATPDW`] = { suppressor = nil, grip = `COMPONENT_AT_AR_AFGRIP`}
}

local SpecificGunRecoil = {}
local GeneralGunRecoil = config.GlobalRecoilMultiplier or 1.00
local gunHash = nil

function AlterSpecificGunRecoil(hash, value)
    if(hash ~=nil)then
        gunHash = hash
        if(value ~=nil)then
            SpecificGunRecoil[gunHash] = value
        end
    end
end

function AlterGeneralGunRecoil(value)
    if(value ~=nil)then
        GeneralGunRecoil = value
    end
end

function ResetAllGunRecoil()
    SpecificGunRecoil = {}
    GeneralGunRecoil = config.GlobalRecoilMultiplier or 1.00
end

function ViewCamForcerJoined()
    config.UseFirstJoinViewCamForcer = false
end

local function RotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayWeapon(weapon,distance,flag)
    local cameraRotation = GetGameplayCamRot()
    
    local weapCoord = GetEntityCoords(weapon)

    local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =  vector3(cameraCoord.x + direction.x * distance, 
		cameraCoord.y + direction.y * distance, 
		cameraCoord.z + direction.z * distance 
    )
    if not flag then
        flag = 1
    end
   
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(weapCoord.x, weapCoord.y, weapCoord.z, destination.x, destination.y, destination.z, flag, -1, 1))
	return b, c, e, destination
end

local function RayCastGamePlayCamera(weapon,distance,flag)
    local cameraRotation = GetGameplayCamRot()
    
    local weapCoord = GetEntityCoords(weapon)

    local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =  vector3(cameraCoord.x + direction.x * distance, 
		cameraCoord.y + direction.y * distance, 
		cameraCoord.z + direction.z * distance 
    )
    if not flag then
        flag = 1
    end

	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, flag, -1, 1))
	return b, c, e, destination
end

local function Draw3DText(x, y, z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    if onScreen then
        SetTextScale(0.3, 0.3)
        SetTextFont(0)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

CreateThread(function()
    local ped, weapon, pedid, sleep
    while true do
        sleep = 500 
        pedid = cache.playerId
        ped = cache.ped
        weapon = GetCurrentPedWeaponEntityIndex(ped)
        if weapon > 0 and IsPlayerFreeAiming(pedid) then
            local _, currentHash = GetCurrentPedWeapon(ped, true)
            local group = GetWeapontypeGroup(currentHash)
            -- Jerry can / fire extinguisher must still spray on vehicles
            if group ~= `GROUP_PETROLCAN` and group ~= `GROUP_FIREEXTINGUISHER` then
                local hitW, coordsW, entityW = RayCastGamePlayWeapon(weapon, 15.0,1)
                local hitC, coordsC, entityC = RayCastGamePlayCamera(weapon, 1000.0,1)
                if hitW > 0 and entityW > 0 and math.abs(#coordsW-#coordsC) > 1 then
                    sleep = 0
                    Draw3DText(coordsW.x, coordsW.y, coordsW.z, '❌')
                    DisablePlayerFiring(ped,true)
                    DisableControlAction(0, 106, true)
                end
            end
        else
            Wait(1000)
        end    
        Wait(sleep)
    end
end)



-- Disable Lean Fire
if config.LeanFire then
    CreateThread(function()
        while true do
            local sleep = 500
            if IsPedInCover(cache.ped) == 1 or IsPedAimingFromCover(cache.ped) == 1 then
                sleep = 0
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 257, true)
            end
            Wait(sleep)
        end
    end)
end

CreateThread(function()
    while true do
        if IsPedArmed(cache.ped, 6) then
            DisableControlAction(1, 140, true)
            DisableControlAction(1, 141, true)
            DisableControlAction(1, 142, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        for _, v in pairs(config.Weapons) do
            SetWeaponDamageModifier(v.hash, v.damageMultiplier)
        end
        Wait(10000)
    end
end)

local rightleft = 3

local function update_rightleft(value)
    rightleft = value
end

local recoilThreadStarted = false

function startWeapStuff ()
    if recoilThreadStarted then return end
    recoilThreadStarted = true
    CreateThread(function()
        while true do
            local ply = cache.ped
            if not cache.weapon then
                Wait(750)
            else
                Wait(50)
                if IsPedShooting(ply) and not GlobalState.PurgeState then
                    local wep = GetCurrentPedWeapon(ply)
                    local _,cAmmo = GetAmmoInClip(ply, wep)
                    local Vehicled = cache.vehicle
                    local MovementSpeed = math.ceil(GetEntitySpeed(ply))

                    if MovementSpeed > 69 then
                        MovementSpeed = 69
                    end
                    Wait(50)
                    local wep = cache.weapon
                    if wep then
                        local group = GetWeapontypeGroup(wep)
                        local p = GetGameplayCamRelativePitch()
                        local cameraDistance = #(GetGameplayCamCoord() - GetEntityCoords(ply))

                        local recoil = math.random(100,140+MovementSpeed)/100
                        local vehicleRecoil = math.random(100,140+MovementSpeed)/100

                        for k, v in pairs(config.Weapons) do
                            if(wep == v.hash)then

                                recoil = recoil * v.recoil * GeneralGunRecoil
                                vehicleRecoil = recoil * v.vehicleRecoil * GeneralGunRecoil
                                
                                if (not Vehicled) then
                                    shaker = v.rightLeftRecoil * GeneralGunRecoil
                                else
                                    shaker = v.vehicleRightLeftRecoil * GeneralGunRecoil
                                end

                                if(SpecificGunRecoil[v.hash] ~= nil)then
                                    recoil = recoil * SpecificGunRecoil[v.hash]
                                    vehicleRecoil = vehicleRecoil * SpecificGunRecoil[v.hash]
                                    shaker = shaker * SpecificGunRecoil[v.hash]
                                end

                                if(config.GripMultiplier)then
                                    if(components[v.hash] ~= nil)then
                                        if(components[v.hash]['grip'] ~= nil)then
                                            if(HasPedGotWeaponComponent(cache.ped, v.hash, components[v.hash]['grip']))then
                                                recoil = recoil * v.gripMultiplier
                                                vehicleRecoil = vehicleRecoil * v.gripMultiplier
                                                shaker = shaker * v.gripMultiplier
                                            end
                                        end
                                    end
                                end

                                if(config.SuppressorMultiplier)then
                                    if(components[v.hash] ~= nil)then
                                        if(components[v.hash]['suppressor'] ~= nil)then
                                            if(HasPedGotWeaponComponent(cache.ped, v.hash, components[v.hash]['suppressor']))then
                                                recoil = recoil * v.suppressorMultiplier
                                                vehicleRecoil = vehicleRecoil * v.suppressorMultiplier 
                                                shaker = shaker * v.suppressorMultiplier 
                                            end
                                        end
                                    end
                                end



                                break;
                            end
                        end

                        if cameraDistance < 5.3 then
                            cameraDistance = 1.5
                        else
                            if cameraDistance < 8.0 then
                                cameraDistance = 4.0
                            else
                                cameraDistance = 7.0
                            end
                        end

                        if Vehicled then
                            recoil = vehicleRecoil * cameraDistance
                        else
                            recoil = recoil * 0.8
                        end

                        if(config.RightLeftRecoil)then
                            if(config.RightLeftRecoilRandomiser)then
                                if(config.RightLeftRecoilRandomiserChance > math.random(1,100))then
                                    update_rightleft(math.random(1,2))
                                else
                                    update_rightleft(3)
                                end
                            else
                                update_rightleft(math.random(1,2))
                            end

                            local h = GetGameplayCamRelativeHeading()
                            local hf = math.random(10,40+MovementSpeed)/100

                            if Vehicled then
                                hf = hf * 2.00
                            end
                            
                            if(shaker == nil)then
                                shaker = 1.00
                            end

                            if config.UseVehicleRecoil then
                                if rightleft == 1 then
                                    SetGameplayCamRelativeHeading(h+hf * shaker)
                                elseif rightleft == 2 then
                                    SetGameplayCamRelativeHeading(h-hf * shaker)
                                end
                            elseif not Vehicled then
                                if rightleft == 1 then
                                    SetGameplayCamRelativeHeading(h+hf * shaker)
                                elseif rightleft == 2 then
                                    SetGameplayCamRelativeHeading(h-hf * shaker)
                                end
                            end
                        end
                        
                        if config.UseScreenExplosions then
                            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', recoil/100)
                        end

                        if config.UseVehicleRecoil then
                            local set = p+recoil
                            SetGameplayCamRelativePitch(set,0.8)
                        elseif not Vehicled then
                            local set = p+recoil
                            SetGameplayCamRelativePitch(set,0.8)
                        end
                    end
                end
            end
        end
    end)
end

CreateThread(function()
    startWeapStuff()
end)

AddEventHandler('esx:enteredVehicle', function()
    SetPlayerCanDoDriveBy(cache.playerId, config.CanDriveBy == true)
end)

AddEventHandler('esx:exitedVehicle', function()
    SetPlayerCanDoDriveBy(cache.playerId, true)
end)