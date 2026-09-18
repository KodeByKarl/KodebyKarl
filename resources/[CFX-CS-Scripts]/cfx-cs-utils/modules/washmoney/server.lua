local WashMoney = require 'configs.washmoney'
local Vars = require 'helpers.vars'
local Region = require 'helpers.region'
local MoneyWashCooldown = {}

local VALID_MODES = {
    dm_to_money = true,
    money_to_dm = true,
}

local function FormatLogs(xPlayer, amount, mode, reason)
    local targetCoords = WashMoney.coords
    local playerCoords = xPlayer.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR WASH MONEY'),
        ('Player: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Mode: %s'):format(tostring(mode)),
        ('Amount Provided: %s'):format(ESX.Math.GroupDigits(amount)),
        ('Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')'),
        ('Distance: %s'):format(#(playerCoords - targetCoords)),
        ('Reason: %s'):format(reason),
    }
    return table.concat(text, ' | ')
end

local function getRate(mode)
    local rates = WashMoney.rates or {}
    if mode == 'money_to_dm' then
        return tonumber(rates.money_to_dm) or 1.0
    end
    -- legacy fallback: WashMoney.odds
    return tonumber(rates.dm_to_money) or tonumber(WashMoney.odds) or 0.8
end

local function ValidateExchange(xPlayer, amount, mode)
    if type(amount) ~= 'number' or amount ~= amount or amount <= 0 then
        return false, 'INVALID AMOUNT'
    end
    amount = math.floor(amount)
    if amount < 1 then
        return false, 'INVALID AMOUNT'
    end
    if not VALID_MODES[mode] then
        return false, 'INVALID MODE'
    end

    local targetCoords = WashMoney.coords
    local playerCoords = xPlayer.getCoords(true)
    if #(playerCoords - targetCoords) > 5.0 then
        return false, 'OUT OF RANGE'
    end

    local fromItem = mode == 'dm_to_money' and 'black_money' or 'money'
    local have = Vars.ox:Search(xPlayer.source, 'count', fromItem) or 0
    if have < amount then
        return false, mode == 'dm_to_money' and 'NOT ENOUGH DIRTY MONEY' or 'NOT ENOUGH CLEAN MONEY'
    end

    local cooldown = MoneyWashCooldown[xPlayer.source]
    local duration = 10
    if cooldown and os.time() - cooldown < duration then
        return false, 'ON COOLDOWN'
    end
    MoneyWashCooldown[xPlayer.source] = os.time()
    return true, amount
end

local function alertPolice(coords, mode)
    local cfg = WashMoney.policeAlert
    if not cfg or not cfg.enable then return end

    local chance = tonumber(cfg.chance) or 100
    if math.random(100) > chance then return end

    local jobs = cfg.jobs or { 'police', 'sheriff' }
    local title = cfg.title or '10-90 Money Laundering'
    local message = cfg.message or 'Suspicious cash exchange reported.'
    if mode == 'money_to_dm' then
        message = 'Someone is converting clean cash to dirty money.'
    elseif mode == 'dm_to_money' then
        message = 'Someone is washing dirty money into clean cash.'
    end

    for i = 1, #jobs do
        local players = ESX.GetExtendedPlayers('job', jobs[i])
        if type(players) == 'table' then
            for _, xTarget in pairs(players) do
                local onDuty = xTarget.job and xTarget.job.onDuty
                if onDuty ~= false and xTarget.source then
                    TriggerClientEvent('cfx-keydi-utils:washmoney:policeAlert', xTarget.source, {
                        title = title,
                        message = message,
                        coords = coords,
                        blipText = 'Money Wash',
                        blipSprite = cfg.blipSprite,
                        blipColour = cfg.blipColour,
                        blipScale = cfg.blipScale,
                        blipDuration = cfg.blipDuration,
                        radius = cfg.radius,
                    })
                end
            end
        end
    end
end

RegisterNetEvent('cfx-keydi-utils:WashMoney', function(amount, mode)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not Region.Allowed('illegal', src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'WASH MONEY',
            description = Region.Message('illegal'),
            type = 'error',
            duration = 5000,
        })
        return
    end

    mode = type(mode) == 'string' and mode or 'dm_to_money'
    local success, resultOrReason = ValidateExchange(xPlayer, amount, mode)
    if not success then
        lib.logger(xPlayer.source, 'cfx-keydi-sentry', FormatLogs(xPlayer, amount, mode, resultOrReason), 'ERROR')
        print(("^0[^3cfx-keydi-utils^0] [WASH MONEY]: Validation failed for %s: %s"):format(xPlayer.name, resultOrReason))
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'WASH MONEY',
            description = 'Exchange failed.',
            type = 'error',
            duration = 5000,
        })
        return
    end

    amount = resultOrReason
    local rate = getRate(mode)
    local totalAmount = ESX.Math.Round(rate * amount)
    if totalAmount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'WASH MONEY',
            description = 'Amount too small after fees.',
            type = 'error',
            duration = 5000,
        })
        return
    end

    local fromItem, toItem
    if mode == 'dm_to_money' then
        fromItem, toItem = 'black_money', 'money'
    else
        fromItem, toItem = 'money', 'black_money'
    end

    if not Vars.ox:RemoveItem(src, fromItem, amount) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'WASH MONEY',
            description = 'Could not take payment.',
            type = 'error',
            duration = 5000,
        })
        return
    end

    if not Vars.ox:AddItem(src, toItem, totalAmount) then
        -- refund
        Vars.ox:AddItem(src, fromItem, amount)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'WASH MONEY',
            description = 'Inventory full. Refunded.',
            type = 'error',
            duration = 5000,
        })
        return
    end

    local label = mode == 'dm_to_money'
        and ('Washed $%s dirty → $%s clean'):format(ESX.Math.GroupDigits(amount), ESX.Math.GroupDigits(totalAmount))
        or ('Converted $%s clean → $%s dirty'):format(ESX.Math.GroupDigits(amount), ESX.Math.GroupDigits(totalAmount))

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'WASH MONEY',
        description = label,
        type = 'success',
        duration = 7000,
    })

    alertPolice(xPlayer.getCoords(true), mode)
end)
