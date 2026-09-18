local config = require 'configs.weapon'
local licenseCfg = config.RequireGunLicense or {}

local function isExemptJob(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    local exempt = licenseCfg.exemptJobs or {}
    return exempt[xPlayer.job.name] == true
end

---True if player may use licensed firearms.
---Only police-granted meta / DB count — inventory card alone is NOT enough (stops pass-around exploit).
---@param src number
---@return boolean
local function playerHasGunLicense(src)
    if not licenseCfg.enabled then return true end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    if isExemptJob(xPlayer) then return true end

    local metaKey = licenseCfg.metaKey or 'weapon'
    local licenses = xPlayer.getMeta('licenses') or {}
    local entry = licenses[metaKey]
    if type(entry) == 'table' and entry.has == true then
        return true
    end

    -- Legacy esx_license / Ammunation shop table (official grant only)
    local ok, hasDb = pcall(function()
        return MySQL.scalar.await(
            'SELECT 1 FROM `user_licenses` WHERE `type` = ? AND `owner` = ? LIMIT 1',
            { metaKey, xPlayer.identifier }
        )
    end)
    if ok and hasDb then
        return true
    end

    return false
end

-- GetWeapontypeGroup is client-only; classify on server via ox_inventory / exempt list.
local function isWeaponItemName(name)
    return type(name) == 'string' and name:sub(1, 7) == 'WEAPON_'
end

local function weaponNeedsLicense(name)
    if not isWeaponItemName(name) then return false end
    local hash = joaat(name)
    local exempt = licenseCfg.exemptWeapons or {}
    if exempt[hash] then return false end

    -- Firearms in ox_inventory define ammoname; melee/thrown usually do not
    local item = exports.ox_inventory:Items(name)
    if type(item) == 'table' then
        if item.weapon and item.ammoname then
            return true
        end
        if item.weapon and not item.ammoname then
            return false
        end
    end

    -- Unknown custom WEAPON_* still require a license
    return true
end

local function isWeaponLicenseItem(name)
    return name == (licenseCfg.itemName or 'weaponlicense')
end

lib.callback.register('cfx-keydi-utils:weapon:hasGunLicense', function(source)
    return playerHasGunLicense(source)
end)

exports('HasGunLicense', playerHasGunLicense)

-- Block equipping firearms from inventory without a license
CreateThread(function()
    Wait(1500)
    if GetResourceState('ox_inventory') ~= 'started' then return end
    if not licenseCfg.enabled then return end

    exports.ox_inventory:registerHook('usingItem', function(payload)
        local item = payload and payload.item
        local name = item and item.name
        if not weaponNeedsLicense(name) then return end

        local src = payload.source
        if playerHasGunLicense(src) then return end

        TriggerClientEvent('esx:Notify', src,
            licenseCfg.notifyTitle or 'WEAPON LICENSE',
            licenseCfg.notifyMessage or 'You need a weapon license to use this firearm.',
            'error',
            5000
        )
        return false
    end)

    -- Stop players from giving / dropping / trading the license card
    exports.ox_inventory:registerHook('swapItems', function(payload)
        local from = payload and payload.fromSlot
        local itemName = type(from) == 'table' and from.name or nil
        if not isWeaponLicenseItem(itemName) then return end

        local action = payload.action
        -- Allow rearranging inside own inventory only
        if action == 'move' and payload.fromInventory == payload.toInventory then
            return
        end

        local src = payload.source
        TriggerClientEvent('esx:Notify', src,
            licenseCfg.notifyTitle or 'WEAPON LICENSE',
            'You cannot give or drop your weapon license.',
            'error',
            4000
        )
        return false
    end, {
        itemFilter = {
            [licenseCfg.itemName or 'weaponlicense'] = true,
        },
    })
end)

-- Keep client cache in sync when police grants/revokes
AddEventHandler('cfx-keydi-utils:weapon:setLicense', function(targetSrc, hasLicense)
    if type(targetSrc) ~= 'number' then return end
    TriggerClientEvent('cfx-keydi-utils:weapon:licenseUpdated', targetSrc, hasLicense == true)
end)

---Helper used by police grant/revoke to ensure meta + DB + item stay aligned.
---@param targetSrc number
---@param granted boolean
exports('SetGunLicense', function(targetSrc, granted)
    local xPlayer = ESX.GetPlayerFromId(targetSrc)
    if not xPlayer then return false end

    local metaKey = licenseCfg.metaKey or 'weapon'
    local licenses = xPlayer.getMeta('licenses') or {}
    if type(licenses[metaKey]) ~= 'table' then
        licenses[metaKey] = { has = false, label = 'Weapon License' }
    end
    licenses[metaKey].has = granted and true or false
    xPlayer.setMeta('licenses', licenses)

    local itemName = licenseCfg.itemName or 'weaponlicense'
    if granted then
        local count = exports.ox_inventory:Search(targetSrc, 'count', itemName) or 0
        if count < 1 then
            exports.ox_inventory:AddItem(targetSrc, itemName, 1, {
                owner = xPlayer.identifier,
                issuedBy = 'LSPD',
            })
        end
        pcall(function()
            MySQL.insert.await(
                'INSERT IGNORE INTO `user_licenses` (`type`, `owner`) VALUES (?, ?)',
                { metaKey, xPlayer.identifier }
            )
        end)
    else
        local count = exports.ox_inventory:Search(targetSrc, 'count', itemName) or 0
        if count > 0 then
            exports.ox_inventory:RemoveItem(targetSrc, itemName, count)
        end
        pcall(function()
            MySQL.update.await(
                'DELETE FROM `user_licenses` WHERE `type` = ? AND `owner` = ?',
                { metaKey, xPlayer.identifier }
            )
        end)
    end

    TriggerClientEvent('cfx-keydi-utils:weapon:licenseUpdated', targetSrc, granted and true or false)
    return true
end)
