local WashMoney = require 'configs.washmoney'
local helpers = require 'helpers.game'
local Vars = require 'helpers.vars'
local Region = require 'helpers.region'

local function startExchange(mode)
    local fromItem = mode == 'dm_to_money' and 'black_money' or 'money'
    local fromLabel = mode == 'dm_to_money' and 'Dirty Money' or 'Clean Money'
    local toLabel = mode == 'dm_to_money' and 'Clean Money' or 'Dirty Money'
    local rate = mode == 'dm_to_money'
        and (WashMoney.rates and WashMoney.rates.dm_to_money or WashMoney.odds or 0.8)
        or (WashMoney.rates and WashMoney.rates.money_to_dm or 1.0)

    local balance = Vars.ox:Search('count', fromItem) or 0
    if balance <= 0 then
        return ESX.Notify('WASH MONEY', ('You don\'t have enough %s.'):format(fromLabel:lower()), 'error', 5000)
    end

    local input = lib.inputDialog(('Exchange: %s → %s'):format(fromLabel, toLabel), {
        {
            type = 'number',
            label = 'Amount',
            description = ('Have: $%s  |  Rate: %s%%'):format(
                ESX.Math.GroupDigits(balance),
                math.floor((tonumber(rate) or 1) * 100)
            ),
            default = balance,
            min = 1,
            required = true,
            icon = 'hashtag',
        },
    })
    if not input then return end

    local count = tonumber(input[1]) or 0
    if count < 1 then
        return ESX.Notify('WASH MONEY', 'Invalid amount.', 'error', 5000)
    end
    if balance < count then
        return ESX.Notify('WASH MONEY', ('You don\'t have enough %s.'):format(fromLabel:lower()), 'error', 5000)
    end

    local progress = {
        label = mode == 'dm_to_money' and 'Washing dirty money . . .' or 'Converting to dirty money . . .',
        duration = 10000,
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true },
        anim = {
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    }
    local status = lib.progressBar(progress)
    if status then
        TriggerServerEvent('cfx-keydi-utils:WashMoney', count, mode)
    end
end

local function OpenMoneyWash()
    if not Region.Allowed('illegal') then
        return ESX.Notify('WASH MONEY', Region.Message('illegal'), 'error', 5000)
    end
    local dirty = Vars.ox:Search('count', 'black_money') or 0
    local clean = Vars.ox:Search('count', 'money') or 0

    lib.registerContext({
        id = 'cfx_keydi_washmoney_menu',
        title = 'Money Exchange',
        options = {
            {
                title = 'Dirty → Clean',
                description = ('DM: $%s  →  wash into clean cash'):format(ESX.Math.GroupDigits(dirty)),
                icon = 'fa-solid fa-soap',
                disabled = dirty <= 0,
                onSelect = function()
                    startExchange('dm_to_money')
                end,
            },
            {
                title = 'Clean → Dirty',
                description = ('Cash: $%s  →  convert into dirty money'):format(ESX.Math.GroupDigits(clean)),
                icon = 'fa-solid fa-sack-dollar',
                disabled = clean <= 0,
                onSelect = function()
                    startExchange('money_to_dm')
                end,
            },
        },
    })
    lib.showContext('cfx_keydi_washmoney_menu')
end

local function nearbyWashMoney(point)
    DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 255, 255, 255, 255, false, true, 2, false, nil, nil, false)
	if WashMoney.distance.interact < point.currentDistance then
        if point.isTextUI then
            point.isTextUI = false
            lib.hideTextUI()
        end
        return
    end
	if not point.isTextUI then
        point.isTextUI = true
        local prompt = ('[E] Money Exchange')
		helpers.createTextUI(prompt)
    end
	if IsControlJustPressed(0, 38) then
        OpenMoneyWash()
    end
end

CreateThread(function()
    lib.points.new({
        coords = WashMoney.coords,
        distance = WashMoney.distance.marker,
        nearby = nearbyWashMoney
    })
end)

RegisterNetEvent('cfx-keydi-utils:washmoney:policeAlert', function(data)
    if type(data) ~= 'table' or not data.coords then return end

    local coords = data.coords
    local x = coords.x or coords[1]
    local y = coords.y or coords[2]
    local z = coords.z or coords[3] or 0.0
    if not x or not y then return end

    local duration = tonumber(data.blipDuration) or 90000

    lib.notify({
        title = data.title or '10-90 Money Laundering',
        description = data.message or 'Suspicious cash exchange reported.',
        duration = 18000,
        position = 'top-right',
        type = 'error',
        icon = 'money-bill-wave',
    })

    PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', true)

    local blip = AddBlipForCoord(x + 0.0, y + 0.0, z + 0.0)
    SetBlipSprite(blip, data.blipSprite or 500)
    SetBlipScale(blip, data.blipScale or 1.2)
    SetBlipColour(blip, data.blipColour or 1)
    SetBlipFlashes(blip, true)
    SetBlipFlashTimer(blip, duration)
    SetBlipFlashInterval(blip, 400)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.blipText or 'Money Wash')
    EndTextCommandSetBlipName(blip)
    PulseBlip(blip)

    local radius = AddBlipForRadius(x + 0.0, y + 0.0, z + 0.0, data.radius or 80.0)
    SetBlipHighDetail(radius, true)
    SetBlipColour(radius, 1)
    SetBlipAlpha(radius, 110)

    CreateThread(function()
        Wait(duration)
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        if DoesBlipExist(radius) then RemoveBlip(radius) end
    end)
end)
