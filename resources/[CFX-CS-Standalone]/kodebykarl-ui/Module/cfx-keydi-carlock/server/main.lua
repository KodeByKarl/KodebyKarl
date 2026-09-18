if not ConfigCarlock or not ConfigCarlock.Enabled then return end

local ESX = ESX or exports["es_extended"]:getSharedObject()

local tempKeys = {}   -- [src] = { [plate] = true }
local sharedKeys = {} -- [plate] = { [src] = ownerSrc }

local function dbg(...)
    if ConfigCarlock.Debug then
        print("[cfx-keydi-carlock]", ...)
    end
end

local function notify(src, description, nType, icon)
    TriggerClientEvent("ox_lib:notify", src, {
        title = ConfigCarlock.Locale.NotifyTitle,
        description = description,
        type = nType or "inform",
        icon = icon,
        position = "top",
    })
end

local function normalizePlate(plate)
    if not plate or plate == "" then return "" end
    return (string.gsub(tostring(plate), "^%s*(.-)%s*$", "%1")):upper()
end

local function playerIdentifier(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and xPlayer.identifier or nil
end

local function addTempKey(src, plate)
    plate = normalizePlate(plate)
    if src < 1 or plate == "" then return false end
    tempKeys[src] = tempKeys[src] or {}
    tempKeys[src][plate] = true
    dbg("temp key", src, plate)
    return true
end

local function removeTempKey(src, plate)
    plate = normalizePlate(plate)
    if not tempKeys[src] then return false end
    if plate == "" then
        tempKeys[src] = nil
        return true
    end
    tempKeys[src][plate] = nil
    if next(tempKeys[src]) == nil then
        tempKeys[src] = nil
    end
    return true
end

local function hasTempKey(src, plate)
    plate = normalizePlate(plate)
    return tempKeys[src] and tempKeys[src][plate] == true
end

local function hasSharedKey(src, plate)
    plate = normalizePlate(plate)
    return sharedKeys[plate] and sharedKeys[plate][src] ~= nil
end

local function isVehicleOwner(src, plate)
    plate = normalizePlate(plate)
    local identifier = playerIdentifier(src)
    if not identifier or plate == "" then return false end

    local row = MySQL.single.await(
        "SELECT 1 FROM owned_vehicles WHERE owner = ? AND UPPER(TRIM(plate)) = ? LIMIT 1",
        { identifier, plate }
    )
    return row ~= nil
end

local function hasAccess(src, plate)
    plate = normalizePlate(plate)
    if plate == "" then return false, nil end
    if isVehicleOwner(src, plate) then return true, "owned" end
    if hasTempKey(src, plate) then return true, "temp" end
    if hasSharedKey(src, plate) then return true, "shared" end
    return false, nil
end

local function shareKeyTo(ownerSrc, targetSrc, plate)
    plate = normalizePlate(plate)
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not GetPlayerName(targetSrc) or plate == "" then
        return false, "invalid"
    end
    if targetSrc == ownerSrc then
        return false, "self"
    end

    sharedKeys[plate] = sharedKeys[plate] or {}
    if sharedKeys[plate][targetSrc] then
        return false, "already"
    end

    sharedKeys[plate][targetSrc] = ownerSrc
    addTempKey(targetSrc, plate)
    return true
end

local function removeSharedKey(ownerSrc, targetSrc, plate)
    plate = normalizePlate(plate)
    targetSrc = tonumber(targetSrc)
    if not targetSrc or plate == "" then return false end

    if sharedKeys[plate] and sharedKeys[plate][targetSrc] == ownerSrc then
        sharedKeys[plate][targetSrc] = nil
        if next(sharedKeys[plate]) == nil then
            sharedKeys[plate] = nil
        end
    end
    removeTempKey(targetSrc, plate)
    return true
end

local function getSharedList(plate)
    plate = normalizePlate(plate)
    local list = {}
    if not sharedKeys[plate] then return list end
    for src, _ in pairs(sharedKeys[plate]) do
        local name = GetPlayerName(src)
        if name then
            list[#list + 1] = {
                id = src,
                player = name,
                plate = plate,
            }
        end
    end
    return list
end

lib.callback.register("cfx-keydi-carlock:hasKeys", function(source, plate)
    local ok, kind = hasAccess(source, plate)
    return ok, kind
end)

lib.callback.register("cfx-keydi-carlock:toggle", function(source, netId, plate, newStatus)
    plate = normalizePlate(plate)
    local ok = hasAccess(source, plate)
    if not ok then return false, "not_owned" end

    netId = tonumber(netId)
    newStatus = tonumber(newStatus)
    if not netId or (newStatus ~= 1 and newStatus ~= 2 and newStatus ~= 4) then
        return false, "invalid"
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false, "invalid"
    end

    SetVehicleDoorsLocked(entity, newStatus)
    Entity(entity).state:set("carlock", newStatus, true)

    dbg("toggle", source, plate, newStatus)
    return true, newStatus
end)

lib.callback.register("cfx-keydi-carlock:shareKeys", function(source, target, plate)
    local ok, kind = hasAccess(source, plate)
    if not ok or kind ~= "owned" then
        return false, "not_owned"
    end

    local shared, reason = shareKeyTo(source, target, plate)
    if not shared then
        return false, reason or "failed"
    end

    local plateText = normalizePlate(plate)
    notify(target, ConfigCarlock.Locale.SharedFrom:format(plateText), "success", "key")
    notify(source, ConfigCarlock.Locale.SharedTo:format(plateText, GetPlayerName(target) or target), "success", "key")
    return true
end)

lib.callback.register("cfx-keydi-carlock:removeKeys", function(source, target, plate)
    local ok, kind = hasAccess(source, plate)
    if not ok or kind ~= "owned" then
        return false, "not_owned"
    end

    removeSharedKey(source, target, plate)
    local plateText = normalizePlate(plate)
    if GetPlayerName(target) then
        notify(target, ConfigCarlock.Locale.RemovedFrom:format(plateText), "error", "key")
    end
    notify(source, ConfigCarlock.Locale.RemovedTo:format(plateText), "success", "key")
    return true
end)

lib.callback.register("cfx-keydi-carlock:getSharedKeys", function(source, plate)
    local ok, kind = hasAccess(source, plate)
    if not ok or kind ~= "owned" then return {} end
    return getSharedList(plate)
end)

RegisterNetEvent("cfx-keydi-carlock:server:giveKey", function(plate)
    local src = source
    addTempKey(src, plate)
end)

RegisterNetEvent("cfx-keydi-carlock:server:removeKey", function(plate)
    local src = source
    removeTempKey(src, plate)
end)

AddEventHandler("playerDropped", function()
    local src = source
    tempKeys[src] = nil
    for plate, holders in pairs(sharedKeys) do
        holders[src] = nil
        if next(holders) == nil then
            sharedKeys[plate] = nil
        end
    end
end)

-- Client garage / dealership / rental
exports("GiveKey", function(src, plate)
    if type(src) == "string" and not plate then
        -- client-style call from another resource's server: GiveKey(plate) is invalid here
        return false
    end
    return addTempKey(src, plate)
end)

exports("RemoveKey", function(src, plate)
    return removeTempKey(src, plate)
end)

exports("HasKey", function(src, plate)
    local ok = hasAccess(src, plate)
    return ok
end)

-- wx_carlock-compatible
exports("shareKey", function(playerId, plate)
    playerId = tonumber(playerId)
    if not playerId then return false end
    addTempKey(playerId, plate)
    return true
end)
