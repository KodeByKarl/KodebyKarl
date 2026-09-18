local weaponHashToNameKey = {}
for weaponName in pairs(Config.WeaponNames or {}) do
    weaponHashToNameKey[joaat(weaponName)] = weaponName
end

local oxInventoryStarted = GetResourceState('ox_inventory') == 'started'

local function isWeaponHudEnabled()
    return Config.ShowComponents and Config.ShowComponents.weapon
end

--- ox_inventory keeps reserve ammo as inventory items, not on the ped.
local function getOxInventoryReserveAmmo(weaponHash)
    if not oxInventoryStarted or not weaponHash then return end

    local ok, currentWeapon = pcall(function()
        return exports.ox_inventory:getCurrentWeapon()
    end)

    if not ok or not currentWeapon or currentWeapon.hash ~= weaponHash or not currentWeapon.ammo then
        return
    end

    local metadata = currentWeapon.metadata?.specialAmmo and { type = currentWeapon.metadata.specialAmmo }
    return exports.ox_inventory:GetItemCount(currentWeapon.ammo, metadata), currentWeapon.ammo
end

local function getWeaponAmmoValues(weaponHash, isVehicleWeapon, vehicleWeaponHash)
    local _, clipAmmo = GetAmmoInClip(cache.ped, weaponHash)
    local reserveAmmo = getOxInventoryReserveAmmo(weaponHash)

    if reserveAmmo == nil then
        local totalAmmo

        if isVehicleWeapon then
            totalAmmo = GetVehicleWeaponRestrictedAmmo(cache.vehicle, vehicleWeaponHash)
        end

        if not totalAmmo then
            totalAmmo = GetAmmoInPedWeapon(cache.ped, weaponHash)
        end

        reserveAmmo = totalAmmo - clipAmmo
    end

    return clipAmmo, reserveAmmo
end

function GetWeaponData(weaponHash)
    if not isWeaponHudEnabled() then
        return false
    end

    weaponHash = weaponHash or cache.weapon
    if not weaponHash then
        return false
    end

    local weaponNameKey = weaponHashToNameKey[weaponHash]
    local weaponLabel = Config.WeaponNames and Config.WeaponNames[weaponNameKey]

    local isVehicleWeapon, vehicleWeaponHash = GetCurrentPedVehicleWeapon(cache.ped)
    if isVehicleWeapon then
        weaponLabel = "Vehicle Weapon"
    end

    local clipAmmo, reserveAmmo = getWeaponAmmoValues(weaponHash, isVehicleWeapon, vehicleWeaponHash)

    return {
        weaponHash = weaponNameKey,
        weaponName = weaponLabel,
        reserveAmmo = reserveAmmo,
        clipAmmo = clipAmmo
    }
end

local function pushWeaponDataToNui(weaponHash)
    SendNUIMessage({
        type = "weaponData",
        weaponData = GetWeaponData(weaponHash)
    })
end

local isWeaponRefreshThreadRunning = false
local lastWeaponHash = nil
local lastClipAmmo = -1
local lastReserveAmmo = -1

local function ensureWeaponRefreshThread()
    CreateThread(function()
        Wait(10)

        if not isWeaponHudEnabled() then
            return
        end

        if not cache.ped or not cache.weapon then
            return
        end

        if isWeaponRefreshThreadRunning then
            return
        end

        isWeaponRefreshThreadRunning = true

        while cache.ped and cache.weapon and IsHudRunning do
            Wait(5000)
            
            local currentWeapon = cache.weapon
            if currentWeapon ~= lastWeaponHash then
                lastWeaponHash = currentWeapon
                pushWeaponDataToNui(currentWeapon)
            else
                local isVehicleWeapon, vehicleWeaponHash = GetCurrentPedVehicleWeapon(cache.ped)
                local clipAmmo, reserveAmmo = getWeaponAmmoValues(currentWeapon, isVehicleWeapon, vehicleWeaponHash)

                if clipAmmo ~= lastClipAmmo or reserveAmmo ~= lastReserveAmmo then
                    lastClipAmmo = clipAmmo
                    lastReserveAmmo = reserveAmmo
                    pushWeaponDataToNui(currentWeapon)
                end
            end
        end

        isWeaponRefreshThreadRunning = false
    end)
end

function CheckWeaponOnLoad()
    if not isWeaponHudEnabled() then
        return
    end

    if cache.weapon then
        lastWeaponHash = cache.weapon
        pushWeaponDataToNui(cache.weapon)
        ensureWeaponRefreshThread()
    end
end

if isWeaponHudEnabled() then
    lib.onCache("weapon", function(weaponHash)
        lastWeaponHash = weaponHash
        pushWeaponDataToNui(weaponHash)
        ensureWeaponRefreshThread()
    end)

    AddEventHandler("CEventGunShot", function(_, ped)
        if ped ~= cache.ped then
            return
        end

        lastWeaponHash = cache.weapon
        lastClipAmmo = -1
        lastReserveAmmo = -1
        pushWeaponDataToNui(cache.weapon)
        ensureWeaponRefreshThread()
    end)

    if oxInventoryStarted then
        AddEventHandler('ox_inventory:currentWeapon', function()
            lastClipAmmo = -1
            lastReserveAmmo = -1
            pushWeaponDataToNui(cache.weapon)
            ensureWeaponRefreshThread()
        end)

        AddEventHandler('ox_inventory:itemCount', function(itemName)
            local _, ammoItem = getOxInventoryReserveAmmo(cache.weapon)
            if ammoItem == itemName then
                lastClipAmmo = -1
                lastReserveAmmo = -1
                pushWeaponDataToNui(cache.weapon)
            end
        end)
    end
end
