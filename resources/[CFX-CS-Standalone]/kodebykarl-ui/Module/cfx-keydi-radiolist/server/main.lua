-- Server side logic for cfx-keydi-radiolist

ESX.RegisterServerCallback('cfx-keydi-radiolist:getRadioPlayers', function(source, cb, channel)
    local playersInChannel = {}
    channel = tonumber(channel)

    if not channel or channel <= 0 then
        return cb(playersInChannel)
    end

    if channel ~= math.floor(channel) then
        channel = math.floor(channel * 100 + 0.5)
    end

    -- Only members of the channel can pull the roster (blocks encrypted peeking)
    local requesterChannel = 0
    local ply = Player(source)
    if ply and ply.state then
        requesterChannel = tonumber(ply.state.radioChannel) or 0
    end
    if requesterChannel ~= channel then
        return cb(playersInChannel)
    end

    local ok, radioChannelPlayers = pcall(function()
        return exports['pma-voice']:getPlayersInRadioChannel(channel)
    end)

    if not ok or type(radioChannelPlayers) ~= 'table' then
        return cb(playersInChannel)
    end

    for targetId, talking in pairs(radioChannelPlayers) do
        targetId = tonumber(targetId)
        if targetId then
            local xTarget = ESX.GetPlayerFromId(targetId)
            local name
            if xTarget then
                local first = xTarget.get and xTarget.get('firstName')
                local last = xTarget.get and xTarget.get('lastName')
                if first and first ~= '' then
                    name = (first .. ' ' .. (last or '')):gsub('%s+$', '')
                else
                    name = xTarget.getName and xTarget.getName() or GetPlayerName(targetId)
                end
            else
                name = GetPlayerName(targetId) or ('Player ' .. tostring(targetId))
            end

            playersInChannel[#playersInChannel + 1] = {
                id = targetId,
                serverId = targetId,
                name = name,
                self = targetId == source,
                talking = talking == true,
            }
        end
    end

    cb(playersInChannel)
end)
