ESX = exports["es_extended"]:getSharedObject()
local playerIdentity = {}
local alreadyRegistered = {}

-- Utility functions for formatting
local function formatDate(value)
    if type(value) == "string" and value ~= "" then
        local y, m, d = value:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
        if y then
            return ("%s-%s-%s"):format(y, m, d)
        end
        local d2, m2, y2 = value:match("(%d%d)/(%d%d)/(%d%d%d%d)")
        if y2 then
            return ("%s-%s-%s"):format(y2, m2, d2)
        end
    end

    local tsNum = tonumber(value)
    if tsNum then
        if tsNum > 9999999999 then
            tsNum = math.floor(tsNum / 1000)
        end
        local dateTable = os.date("*t", tsNum)
        if dateTable then
            return string.format("%04d-%02d-%02d", dateTable.year, dateTable.month, dateTable.day)
        end
    end

    return "2005-01-01"
end

local function formatName(str)
    if not str then return "" end
    local lowered = string.lower(str)
    return lowered:gsub("^%l", string.upper)
end

-- Export functions for other scripts if needed
exports('FormatName', formatName)
exports('FormatDate', formatDate)

local function CheckAndTriggerIdentity(src, xPlayer)
    if not xPlayer then
        xPlayer = ESX.GetPlayerFromId(src)
    end
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    Database.GetIdentity(identifier, function(identity)
        if not identity or not identity.firstName or identity.firstName == "" then
            playerIdentity[identifier] = nil
            alreadyRegistered[identifier] = false
            IdentityUtils.Debug("Player %s has no identity; triggering showRegisterIdentity.", src)
            TriggerClientEvent('esx_identity:showRegisterIdentity', xPlayer.source)
        else
            playerIdentity[identifier] = identity
            alreadyRegistered[identifier] = true

            xPlayer.setName(('%s %s'):format(identity.firstName, identity.lastName))
            xPlayer.set('firstName', identity.firstName)
            xPlayer.set('lastName', identity.lastName)
            xPlayer.set('dateofbirth', identity.dateOfBirth)
            xPlayer.set('sex', identity.sex)
            xPlayer.set('height', identity.height)

            TriggerClientEvent('esx_identity:setPlayerData', xPlayer.source, identity)
            TriggerClientEvent('esx_identity:alreadyRegistered', xPlayer.source)
            IdentityUtils.Debug("Loaded identity for player %s (%s %s)", src, identity.firstName, identity.lastName)
        end
    end)
end

RegisterNetEvent('esx_identity:checkIdentity', function()
    local src = source
    CheckAndTriggerIdentity(src)
end)

-- Check character identity when player loads
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    CheckAndTriggerIdentity(playerId, xPlayer)
end)

-- Handle player disconnect
AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        playerIdentity[xPlayer.identifier] = nil
        alreadyRegistered[xPlayer.identifier] = nil
    end
end)
