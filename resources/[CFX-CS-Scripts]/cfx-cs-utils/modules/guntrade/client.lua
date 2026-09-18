--[[
    Gun Trade-In Shop (Client)
    Opens ox_lib context menu of owned firearms; trades one for random parts.
]]

local Config = require 'configs.guntrade'
local Vars = require 'helpers.vars'

local busy = false

local function notify(msg, nType)
    ESX.Notify(Config.label or 'GUN TRADE', msg, nType or 'info', 5000)
end

local function tradeWeapon(entry)
    if busy then
        return notify('You are already trading.', 'error')
    end
    if not entry or not entry.slot or not entry.name then
        return notify('Invalid weapon selection.', 'error')
    end

    busy = true
    if Vars.oxTarget then
        Vars.oxTarget:disableTargeting(true)
    end

    local progress = Config.progress or {}
    local ok = lib.progressBar({
        duration = progress.duration or 4500,
        label = progress.label or 'Trading in firearm…',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = progress.anim,
    })

    busy = false
    if Vars.oxTarget then
        Vars.oxTarget:disableTargeting(false)
    end

    if not ok then
        return notify('Trade cancelled.', 'error')
    end

    local success, gunOrErr, partsSummary = lib.callback.await(
        'cfx-keydi-utils:guntrade:trade',
        false,
        entry.slot,
        entry.name
    )

    if success then
        notify(('Traded %s for %s.'):format(gunOrErr or entry.label, partsSummary or 'parts'), 'success')
    else
        notify(gunOrErr or 'Trade failed.', 'error')
    end
end

local function openTradeMenu()
    if busy then
        return notify('You are already trading.', 'error')
    end

    local weapons = lib.callback.await('cfx-keydi-utils:guntrade:getWeapons', false) or {}
    if #weapons == 0 then
        return notify('No tradeable firearms in your inventory.', 'error')
    end

    local options = {}
    for i = 1, #weapons do
        local w = weapons[i]
        local desc = 'Trade this gun for random 1–5 gun parts.'
        if w.serial then
            desc = desc .. ('\nSerial: %s'):format(w.serial)
        end
        options[#options + 1] = {
            title = w.label or w.name,
            description = desc,
            icon = 'fa-solid fa-gun',
            onSelect = function()
                tradeWeapon(w)
            end,
        }
    end

    lib.registerContext({
        id = 'cfx_keydi_guntrade_menu',
        title = Config.label or 'Gun Trade-In',
        options = options,
    })
    lib.showContext('cfx_keydi_guntrade_menu')
end

exports('OpenGunTrade', openTradeMenu)
exports('openGunTrade', openTradeMenu)
