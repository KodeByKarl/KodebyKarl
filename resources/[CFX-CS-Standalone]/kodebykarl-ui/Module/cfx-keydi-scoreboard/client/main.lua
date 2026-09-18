local ESX = exports["es_extended"]:getSharedObject()
local isVisible = false

function ToggleScoreboard(state, data)
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "scoreboard:show" or "scoreboard:hide",
        data = data
    })
end

exports('ToggleScoreboard', ToggleScoreboard)

-- Function to collect stats and update/show the scoreboard
local function UpdateScoreboard()
    ESX.TriggerServerCallback('cfx-keydi-scoreboard:getServerData', function(serverData)
        if not serverData then return end
        
        local playerPed = PlayerPedId()
        
        -- Get player health percentage (corrected for standard GTA 100-200 range)
        local health = GetEntityHealth(playerPed)
        local healthPercent = 100
        if health > 0 then
            -- GTA Ped health goes from 0-200. Usually 100 is dead, 200 is max.
            local maxHealth = GetEntityMaxHealth(playerPed)
            if maxHealth > 100 then
                healthPercent = math.floor(((health - 100) / (maxHealth - 100)) * 100)
            else
                healthPercent = math.floor((health / maxHealth) * 100)
            end
        else
            healthPercent = 0
        end
        healthPercent = math.max(0, math.min(100, healthPercent))

        -- Get player armor percentage
        local armor = GetPedArmour(playerPed)
        local armorPercent = math.max(0, math.min(100, math.floor(armor)))

        -- Combine data payload
        local finalData = {
            toggleKey = ConfigScoreboard.ToggleKey,
            serverName = serverData.serverName,
            enablePriorityStatus = serverData.enablePriorityStatus,
            playerName = serverData.playerDetails.name,
            playerId = GetPlayerServerId(PlayerId()),
            ping = serverData.playerDetails.ping,
            avatarUrl = serverData.playerDetails.avatarUrl,
            stats = {
                playTime = serverData.playerDetails.playTime or "12m",
                rank = serverData.playerDetails.rank or "-",
                kills = serverData.playerDetails.kills or 0,
                kd = serverData.playerDetails.kd or "0.00",
                health = healthPercent,
                armor = armorPercent
            },
            population = serverData.population,
            jobs = serverData.jobs,
            priorities = serverData.priorities,
            worldEvents = serverData.worldEvents,
            robberies = serverData.robberies
        }

        ToggleScoreboard(isVisible, finalData)
    end)
end

-- Key registration
RegisterKeyMapping('toggleScoreboard', 'Toggle Server Scoreboard', 'keyboard', ConfigScoreboard.ToggleKey)

RegisterCommand('toggleScoreboard', function()
    if isVisible then
        isVisible = false
        ToggleScoreboard(false, nil)
    else
        isVisible = true
        UpdateScoreboard()
    end
end, false)

-- Refresh thread while visible
CreateThread(function()
    while true do
        Wait(ConfigScoreboard.RefreshInterval)
        if isVisible then
            UpdateScoreboard()
        end
    end
end)

-- Kills / Deaths tracking using GTA V network events
local kills = 0
local deaths = 0

AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName == 'CEventNetworkEntityDamage' then
        local victim = data[1]
        local attacker = data[2]
        local isDead = data[6] == 1 -- 1 means dead

        if isDead then
            local playerPed = PlayerPedId()
            
            -- If local player died
            if victim == playerPed then
                deaths = deaths + 1
                TriggerServerEvent('cfx-keydi-scoreboard:updateKDA', kills, deaths)
            -- If local player killed someone
            elseif attacker == playerPed then
                -- Check if victim was a player
                if IsPedAPlayer(victim) then
                    kills = kills + 1
                    TriggerServerEvent('cfx-keydi-scoreboard:updateKDA', kills, deaths)
                end
            end
        end
    end
end)

-- Register NUI Callback to handle keyboard escape or toggle closes
RegisterNUICallback('closeScoreboard', function(data, cb)
    cb('ok')
    if isVisible then
        isVisible = false
        ToggleScoreboard(false, nil)
    end
end)

-- Used by kodebykarl-robbery (and legacy cfx-cs-scoreboard provide)
exports('CheckLawEnforcementByTable', function(requireTable)
    return lib.callback.await('cfx-keydi-scoreboard:checkLawEnforcement', false, requireTable)
end)

