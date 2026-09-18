local Config <const> = require 'config'
local Utils <const> = require 'modules.server.utils'
local ESX <const> = exports.es_extended:getSharedObject()
local Voice <const> = exports['pma-voice']

AddEventHandler('esx:playerLoaded', function(playerId)
    Voice:setPlayerRadio(playerId, 0)
end)

AddEventHandler('esx:playerLogout', function(playerId)
    Voice:setPlayerRadio(playerId, 0)
    Player(playerId).state:set('ac:hasRadioProp', false, true)
end)

CreateThread(function()
    if Config.useUsableItem and not Utils.hasExport('ox_inventory.Items') then
        ESX.RegisterUsableItem('radio', function(playerId)
            TriggerClientEvent('cfx-keydi-radio:openRadio', playerId)
            TriggerClientEvent('ac_radio:openRadio', playerId)
        end)

        if Config.disconnectWithoutRadio then
            AddEventHandler('esx:onRemoveInventoryItem', function(playerId, name, count)
                if name == 'radio' and count < 1 then
                    TriggerClientEvent('cfx-keydi-radio:disableRadio', playerId)
                    TriggerClientEvent('ac_radio:disableRadio', playerId)
                    Voice:setPlayerRadio(playerId, 0)
                end
            end)
        end
    end

    for frequency, allowed in pairs(Config.restrictedChannels) do
        local freq = tonumber(frequency)
        Voice:addChannelCheck(freq, function(playerId)
            local player = ESX.GetPlayerFromId(playerId)
            if not player then return false end

            local job = player.getJob()
            if not job or not job.name then
                lib.notify(playerId, {
                    type = 'error',
                    description = locale('channel_unavailable'),
                })
                return false
            end

            local allowedJoin = false
            if type(allowed) == 'table' then
                local minGrade = allowed[job.name]
                if minGrade ~= nil and job.grade >= (minGrade or 0) then
                    allowedJoin = true
                end
            elseif job.name == allowed then
                allowedJoin = true
            end

            if allowedJoin then
                lib.notify(playerId, {
                    type = 'success',
                    description = locale('channel_join', string.format('%.2f', freq / 100)),
                })
                return true
            end

            lib.notify(playerId, {
                type = 'error',
                description = locale('channel_unavailable'),
            })
            -- Hard kick off so radiolist / state bag cannot stick on encrypted freqs
            SetTimeout(0, function()
                Voice:setPlayerRadio(playerId, 0)
            end)
            return false
        end)
    end
end)
