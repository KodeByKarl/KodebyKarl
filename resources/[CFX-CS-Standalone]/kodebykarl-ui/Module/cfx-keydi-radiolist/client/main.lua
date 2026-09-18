--[[
    cfx-keydi-radiolist (client)
    Shows radio HUD when connected via cfx-keydi-radio / pma-voice.
]]

local playerServerID = GetPlayerServerId(PlayerId())
local playersInRadio = {}
local currentRadioChannel = 0
local hudVisible = true
local isModalOpen = false

local function SendNui(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local function FormatChannel(channel)
    if ConfigRadioList and type(ConfigRadioList.FormatFrequency) == 'function' then
        return ConfigRadioList.FormatFrequency(channel)
    end
    channel = tonumber(channel)
    if not channel or channel == 0 then return nil end
    if channel == math.floor(channel) then
        return ('%.2f MHz'):format(channel / 100)
    end
    return ('%.2f MHz'):format(channel)
end

local function toVoiceChannel(freqOrChannel)
    if ConfigRadioList and type(ConfigRadioList.ToVoiceChannel) == 'function' then
        return ConfigRadioList.ToVoiceChannel(freqOrChannel)
    end
    local n = tonumber(freqOrChannel) or 0
    if n <= 0 then return 0 end
    if n == math.floor(n) then return n end
    return math.floor(n * 100 + 0.5)
end

local function getRadioResourceChannel()
    if GetResourceState('cfx-keydi-radio') ~= 'started' then return 0 end
    local ok, channel = pcall(function()
        return exports['cfx-keydi-radio']:getChannel()
    end)
    if ok and tonumber(channel) and tonumber(channel) > 0 then
        return tonumber(channel)
    end
    local okFreq, freq = pcall(function()
        return exports['cfx-keydi-radio']:getFrequency()
    end)
    freq = okFreq and tonumber(freq) or 0
    if freq > 0 then
        return math.floor(freq * 100 + 0.5)
    end
    return 0
end

local function GetLocalDisplayName()
    if ESX and ESX.GetPlayerData then
        local pData = ESX.GetPlayerData()
        if pData then
            if pData.firstName then
                return (pData.firstName .. ' ' .. (pData.lastName or '')):gsub('%s+$', '')
            end
            if pData.name then
                return pData.name
            end
        end
    end
    return GetPlayerName(PlayerId()) or ('Player ' .. tostring(playerServerID))
end

local function UpdateRadioNui()
    local playersList = {}
    for _, p in pairs(playersInRadio) do
        playersList[#playersList + 1] = p
    end

    table.sort(playersList, function(a, b)
        if a.self ~= b.self then return a.self end
        return (a.name or '') < (b.name or '')
    end)

    local connected = currentRadioChannel and currentRadioChannel > 0
    SendNui('cfx-keydi-radiolist:update', {
        channel = connected and FormatChannel(currentRadioChannel) or nil,
        channelNum = currentRadioChannel,
        players = playersList,
        -- Show HUD whenever connected (even alone on the channel)
        hudVisible = hudVisible and connected,
        modalVisible = isModalOpen,
    })
end

local function setPlayersFromServerList(channelPlayers)
    playersInRadio = {}
    if type(channelPlayers) == 'table' then
        for _, p in ipairs(channelPlayers) do
            local id = tonumber(p.id or p.serverId)
            if id then
                playersInRadio[id] = {
                    id = id,
                    serverId = id,
                    name = p.name or ('Player ' .. tostring(id)),
                    self = id == playerServerID,
                    talking = p.talking == true,
                }
            end
        end
    end

    -- Ensure local player is always listed while connected
    if currentRadioChannel > 0 and not playersInRadio[playerServerID] then
        playersInRadio[playerServerID] = {
            id = playerServerID,
            serverId = playerServerID,
            name = GetLocalDisplayName(),
            self = true,
            talking = false,
        }
    end

    UpdateRadioNui()
end

local function refreshRadioRoster()
    if currentRadioChannel <= 0 then
        playersInRadio = {}
        UpdateRadioNui()
        return
    end

    ESX.TriggerServerCallback('cfx-keydi-radiolist:getRadioPlayers', function(channelPlayers)
        setPlayersFromServerList(channelPlayers)
    end, currentRadioChannel)
end

local function setRadioChannel(channel)
    channel = toVoiceChannel(channel)
    currentRadioChannel = channel

    if channel <= 0 then
        playersInRadio = {}
        if isModalOpen then
            isModalOpen = false
            SetNuiFocus(false, false)
        end
        UpdateRadioNui()
        return
    end

    -- Immediate self entry so HUD appears without waiting for the callback
    playersInRadio[playerServerID] = {
        id = playerServerID,
        serverId = playerServerID,
        name = GetLocalDisplayName(),
        self = true,
        talking = false,
    }
    UpdateRadioNui()
    refreshRadioRoster()
end

-- Fired to the joining client with the full channel member table (always)
RegisterNetEvent('pma-voice:syncRadioData', function(radioTable)
    local channel = tonumber(LocalPlayer.state.radioChannel) or 0
    if channel <= 0 then
        -- State bag can lag one tick behind the sync event
        SetTimeout(0, function()
            channel = tonumber(LocalPlayer.state.radioChannel) or currentRadioChannel or 0
            if channel > 0 then
                setRadioChannel(channel)
            end
        end)
        return
    end
    setRadioChannel(channel)
end)

-- Primary channel sync (also covers server-export joins)
RegisterNetEvent('pma-voice:clSetPlayerRadio', function(channel)
    setRadioChannel(channel)
end)

-- Local player state bag set by pma-voice server
AddStateBagChangeHandler('radioChannel', ('player:%s'):format(playerServerID), function(_, _, value)
    setRadioChannel(value)
end)

RegisterNetEvent('pma-voice:addPlayerToRadio', function(playerId)
    playerId = tonumber(playerId)
    if not playerId or currentRadioChannel <= 0 then return end

    if not playersInRadio[playerId] then
        playersInRadio[playerId] = {
            id = playerId,
            serverId = playerId,
            name = playerId == playerServerID and GetLocalDisplayName() or ('Player ' .. tostring(playerId)),
            self = playerId == playerServerID,
            talking = false,
        }
        UpdateRadioNui()
        -- Resolve proper character name shortly after
        refreshRadioRoster()
    end
end)

RegisterNetEvent('pma-voice:removePlayerFromRadio', function(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end

    if playerId == playerServerID then
        playersInRadio = {}
        currentRadioChannel = 0
        if isModalOpen then
            isModalOpen = false
            SetNuiFocus(false, false)
        end
    else
        playersInRadio[playerId] = nil
    end
    UpdateRadioNui()
end)

RegisterNetEvent('pma-voice:radioActive', function(talkingState)
    if playersInRadio[playerServerID] then
        playersInRadio[playerServerID].talking = talkingState and true or false
        UpdateRadioNui()
    end
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio', function(source, talkingState)
    source = tonumber(source)
    if source and playersInRadio[source] then
        playersInRadio[source].talking = talkingState and true or false
        UpdateRadioNui()
    end
end)

RegisterNUICallback('cfx-keydi-radiolist:closeModal', function(_, cb)
    isModalOpen = false
    SetNuiFocus(false, false)
    UpdateRadioNui()
    if cb then cb('ok') end
end)

RegisterNUICallback('cfx-keydi-radiolist:stopDrag', function(_, cb)
    SetNuiFocus(false, false)
    if cb then cb('ok') end
end)

RegisterCommand(ConfigRadioList.ToggleListCommand or 'radiolist', function()
    if currentRadioChannel <= 0 then
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification('You are not connected to any radio channel!', 'error')
        end
        return
    end
    isModalOpen = not isModalOpen
    SetNuiFocus(isModalOpen, isModalOpen)
    if isModalOpen then
        refreshRadioRoster()
    else
        UpdateRadioNui()
    end
end, false)

RegisterCommand(ConfigRadioList.EditPosCommand or 'moveradio', function()
    SetNuiFocus(true, true)
    SendNui('cfx-keydi-radiolist:startDrag', {})
end, false)

RegisterCommand(ConfigRadioList.ToggleHudCommand or 'toggleradio', function()
    hudVisible = not hudVisible
    UpdateRadioNui()
end, false)

RegisterNetEvent('cfx-keydi-radiolist:client:openModal', function()
    if currentRadioChannel <= 0 then return end
    isModalOpen = true
    SetNuiFocus(true, true)
    refreshRadioRoster()
end)

exports('ToggleRadioList', function()
    if currentRadioChannel <= 0 then return end
    isModalOpen = not isModalOpen
    SetNuiFocus(isModalOpen, isModalOpen)
    if isModalOpen then
        refreshRadioRoster()
    else
        UpdateRadioNui()
    end
end)

-- Primary hook from cfx-keydi-radio (join / leave / disable)
AddEventHandler('cfx-keydi-radio:channelChanged', setRadioChannel)
AddEventHandler('cfx-keydi-radiolist:setChannel', setRadioChannel)

-- Restore HUD if already on a channel after resource restart
CreateThread(function()
    Wait(1500)
    local fromRadio = getRadioResourceChannel()
    if fromRadio > 0 then
        setRadioChannel(fromRadio)
        return
    end
    local channel = toVoiceChannel(LocalPlayer.state.radioChannel)
    if channel > 0 then
        setRadioChannel(channel)
    end
end)
