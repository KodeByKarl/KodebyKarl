ESX = ESX or exports["es_extended"]:getSharedObject()

-- Live player counts + per-player current location (Server Locations module)
ESX.RegisterServerCallback('cfx-keydi-modules:server:getServersData', function(source, cb)
    if ServerLocations and ServerLocations.GetServersData then
        cb(ServerLocations.GetServersData(source))
        return
    end
    cb({})
end)

local function dojCfg()
    return (ConfigModules and ConfigModules.DOJ) or {}
end

local function notify(src, title, description, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = title or 'DOJ',
        description = description,
        type = nType or 'inform',
    })
end

local function isOnDutyDoj(xPlayer)
    return xPlayer and xPlayer.job and xPlayer.job.name == 'doj'
end

local function playersNear(srcA, srcB, maxDist)
    local pedA = GetPlayerPed(srcA)
    local pedB = GetPlayerPed(srcB)
    if not pedA or pedA == 0 or not pedB or pedB == 0 then return false end
    local a = GetEntityCoords(pedA)
    local b = GetEntityCoords(pedB)
    return #(a - b) <= (maxDist or 3.0)
end

local function formatMoney(n)
    n = math.floor(tonumber(n) or 0)
    if ESX and ESX.Math and ESX.Math.GroupDigits then
        return ESX.Math.GroupDigits(n)
    end
    local s = tostring(n)
    local k
    while true do
        s, k = s:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return s
end

local function chargePlayer(xTarget, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    local bank = 0
    local cash = 0
    if xTarget.getAccount then
        local bankAcc = xTarget.getAccount('bank')
        bank = bankAcc and tonumber(bankAcc.money) or 0
        local moneyAcc = xTarget.getAccount('money')
        cash = moneyAcc and tonumber(moneyAcc.money) or 0
    end
    if cash <= 0 and xTarget.getMoney then
        cash = tonumber(xTarget.getMoney()) or 0
    end

    if bank >= amount then
        xTarget.removeAccountMoney('bank', amount, 'DOJ service fee')
        return true
    end
    if cash >= amount then
        if xTarget.removeAccountMoney then
            xTarget.removeAccountMoney('money', amount, 'DOJ service fee')
        elseif xTarget.removeMoney then
            xTarget.removeMoney(amount, 'DOJ service fee')
        else
            return false
        end
        return true
    end
    return false
end

local function depositSociety(amount, identifier, note)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local account = dojCfg().SocietyAccount or 'society_doj'
    if GetResourceState('cfx-keydi-society') ~= 'started' then
        return false
    end
    local ok = pcall(function()
        exports['cfx-keydi-society']:AddMoney(account, amount, identifier, note)
    end)
    return ok
end

local function applyNameChange(xTarget, firstName, lastName)
    firstName = tostring(firstName or ''):gsub('^%s*(.-)%s*$', '%1')
    lastName = tostring(lastName or ''):gsub('^%s*(.-)%s*$', '%1')
    if firstName == '' or lastName == '' then
        return false
    end
    if #firstName > 50 or #lastName > 50 then
        return false
    end

    if xTarget.setName then
        xTarget.setName(('%s %s'):format(firstName, lastName))
    end
    xTarget.set('firstName', firstName)
    xTarget.set('lastName', lastName)

    if MySQL then
        pcall(function()
            MySQL.update(
                'UPDATE users SET firstname = ?, lastname = ? WHERE identifier = ?',
                { firstName, lastName, xTarget.identifier }
            )
        end)
    end
    return true, firstName, lastName
end

-- Free City Hall self-serve disabled — DOJ handles issuance.
RegisterNetEvent('cfx-keydi-identification:server:giveIdItem', function()
    local src = source
    notify(src, 'DOJ', 'Citizen IDs are issued by the Department of Justice ($250,000).', 'error')
end)

RegisterNetEvent('cfx-keydi-identification:server:changeName', function()
    local src = source
    notify(src, 'DOJ', 'Legal name changes are processed by the Department of Justice ($500,000).', 'error')
end)

lib.callback.register('cfx-keydi-doj:issueCitizenId', function(source, targetId)
    local cfg = dojCfg()
    local price = tonumber(cfg.CitizenIdPrice) or 250000
    local maxDist = tonumber(cfg.MaxDistance) or 3.0

    local xStaff = ESX.GetPlayerFromId(source)
    if not isOnDutyDoj(xStaff) then
        return { ok = false, error = 'not_doj' }
    end

    targetId = tonumber(targetId)
    if not targetId or targetId == source then
        return { ok = false, error = 'invalid_target' }
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        return { ok = false, error = 'offline' }
    end

    if not playersNear(source, targetId, maxDist) then
        return { ok = false, error = 'far' }
    end

    local count = exports.ox_inventory:Search(targetId, 'count', 'identification') or 0
    if count > 0 then
        return { ok = false, error = 'has_id' }
    end

    if not chargePlayer(xTarget, price) then
        return { ok = false, error = 'no_money', price = price }
    end

    local success = exports.ox_inventory:AddItem(targetId, 'identification', 1)
    if not success then
        xTarget.addAccountMoney('bank', price, 'DOJ ID refund')
        return { ok = false, error = 'inventory_full' }
    end

    depositSociety(price, xStaff.identifier, ('Citizen ID — %s'):format(xTarget.identifier))

    notify(targetId, 'DOJ', ('You received your Citizen ID. Fee: $%s.'):format(formatMoney(price)), 'success')
    notify(source, 'DOJ', ('Issued Citizen ID. $%s deposited to DOJ funds.'):format(formatMoney(price)), 'success')
    return { ok = true, price = price }
end)

lib.callback.register('cfx-keydi-doj:changeName', function(source, data)
    local cfg = dojCfg()
    local price = tonumber(cfg.ChangeNamePrice) or 500000
    local maxDist = tonumber(cfg.MaxDistance) or 3.0

    local xStaff = ESX.GetPlayerFromId(source)
    if not isOnDutyDoj(xStaff) then
        return { ok = false, error = 'not_doj' }
    end

    data = type(data) == 'table' and data or {}
    local targetId = tonumber(data.targetId)
    if not targetId or targetId == source then
        return { ok = false, error = 'invalid_target' }
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        return { ok = false, error = 'offline' }
    end

    if not playersNear(source, targetId, maxDist) then
        return { ok = false, error = 'far' }
    end

    if not chargePlayer(xTarget, price) then
        return { ok = false, error = 'no_money', price = price }
    end

    local ok, firstName, lastName = applyNameChange(xTarget, data.firstName, data.lastName)
    if not ok then
        xTarget.addAccountMoney('bank', price, 'DOJ name-change refund')
        return { ok = false, error = 'invalid' }
    end

    depositSociety(price, xStaff.identifier, ('Name change — %s → %s %s'):format(xTarget.identifier, firstName, lastName))

    notify(targetId, 'DOJ', ('Legal name updated to %s %s. Fee: $%s.'):format(firstName, lastName, formatMoney(price)), 'success')
    notify(source, 'DOJ', ('Processed name change. $%s deposited to DOJ funds.'):format(formatMoney(price)), 'success')
    return { ok = true, price = price, name = ('%s %s'):format(firstName, lastName) }
end)

-- Self-serve: use purchased Name Change Certificate
lib.callback.register('cfx-keydi-doj:useChangeNameItem', function(source, data)
    local cfg = dojCfg()
    local itemName = cfg.ChangeNameItem or 'change_name'

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return { ok = false, error = 'offline' }
    end

    data = type(data) == 'table' and data or {}
    local slot = tonumber(data.slot)
    if not slot then
        return { ok = false, error = 'invalid' }
    end

    local slotItem = exports.ox_inventory:GetSlot(source, slot)
    if not slotItem or slotItem.name ~= itemName then
        return { ok = false, error = 'no_item' }
    end

    local ok, firstName, lastName = applyNameChange(xPlayer, data.firstName, data.lastName)
    if not ok then
        return { ok = false, error = 'invalid' }
    end

    local removed = exports.ox_inventory:RemoveItem(source, itemName, 1, nil, slot)
    if not removed then
        -- Name already applied; still report success but warn inventory
        notify(source, 'DOJ', 'Name updated but certificate could not be removed. Contact staff.', 'error')
        return { ok = true, name = ('%s %s'):format(firstName, lastName), warn = 'item' }
    end

    notify(source, 'DOJ', ('Legal name updated to %s %s.'):format(firstName, lastName), 'success')
    return { ok = true, name = ('%s %s'):format(firstName, lastName) }
end)

-- DOJ shop purchases → society_doj (shows on DOJ boss iPad)
local dojShopHookRegistered = false

local function registerDojShopHooks()
    if dojShopHookRegistered then return end
    if GetResourceState('ox_inventory') ~= 'started' then return end

    local shopType = (dojCfg().Shop and dojCfg().Shop.type) or 'DOJ'

    -- Block duplicate citizen ID / license at checkout
    exports.ox_inventory:registerHook('buyItem', function(payload)
        if payload.shopType ~= shopType then return end

        local src = payload.source
        local itemName = payload.itemName
        if itemName == 'identification' then
            local count = exports.ox_inventory:Search(src, 'count', 'identification') or 0
            if count > 0 then
                notify(src, 'DOJ', 'You already have a Citizen ID.', 'error')
                return false
            end
        elseif itemName == 'driver_license' then
            local count = exports.ox_inventory:Search(src, 'count', 'driver_license') or 0
            if count > 0 then
                notify(src, 'DOJ', 'You already have a Driver License.', 'error')
                return false
            end
        end
    end, {
        print = false,
        typeFilter = { [shopType] = true },
    })

    -- Deposit purchase total after a successful buy
    local buyId = exports.ox_inventory:registerHook('buyItem', nil, {
        print = false,
        typeFilter = { [shopType] = true },
    })

    AddEventHandler(buyId, function(success, payload)
        if not success or not payload or payload.shopType ~= shopType then return end

        local total = math.floor(tonumber(payload.totalPrice) or 0)
        if total <= 0 then return end

        local src = payload.source
        local xPlayer = ESX.GetPlayerFromId(src)
        local identifier = xPlayer and xPlayer.identifier or tostring(src)
        local itemLabel = tostring(payload.itemName or 'item')
        local count = tonumber(payload.count) or 1

        depositSociety(
            total,
            identifier,
            ('DOJ shop — %sx %s'):format(count, itemLabel)
        )
    end)

    -- Stamp owner on driver licenses created into a player inventory
    exports.ox_inventory:registerHook('createItem', function(payload)
        if not payload.item or payload.item.name ~= 'driver_license' then return end

        local metadata = payload.metadata or {}
        if type(payload.inventoryId) == 'number' then
            local xPlayer = ESX.GetPlayerFromId(payload.inventoryId)
            if xPlayer then
                if not metadata.owner then
                    metadata.owner = xPlayer.identifier
                end
                if metadata.issuedBy == 'DOJ' and not metadata.description then
                    metadata.description = ('Issued to %s by DOJ'):format(xPlayer.getName() or 'Citizen')
                end
            end
        end
        return metadata
    end, {
        itemFilter = { driver_license = true },
    })

    dojShopHookRegistered = true
end

CreateThread(function()
    local deadline = GetGameTimer() + 60000
    while GetResourceState('ox_inventory') ~= 'started' and GetGameTimer() < deadline do
        Wait(500)
    end
    Wait(1500)
    registerDojShopHooks()
end)

AddEventHandler('onResourceStart', function(res)
    if res == 'ox_inventory' then
        dojShopHookRegistered = false
        SetTimeout(1500, registerDojShopHooks)
    end
end)
