ConfigRadioList = ConfigRadioList or {}

ConfigRadioList.Debug = false

-- Commands
ConfigRadioList.ToggleListCommand = "radiolist" -- Toggle full player roster modal
ConfigRadioList.EditPosCommand = "moveradio"      -- Toggle HUD edit/drag mode
ConfigRadioList.ToggleHudCommand = "toggleradio"  -- Toggle HUD visibility

-- pma-voice channel is MHz * 100 (100.00 → 10000). Fall back to raw MHz
-- if a leftover float from the old key format is passed in.
ConfigRadioList.FormatFrequency = function(channel)
    channel = tonumber(channel)
    if not channel or channel == 0 then return "Disconnected" end
    if channel == math.floor(channel) then
        return string.format("%.2f MHz", channel / 100)
    end
    return string.format("%.2f MHz", channel)
end

ConfigRadioList.ToVoiceChannel = function(freqOrChannel)
    local n = tonumber(freqOrChannel) or 0
    if n <= 0 then return 0 end
    if n == math.floor(n) then
        return n
    end
    return math.floor(n * 100 + 0.5)
end

-- Allowed jobs to see specific private radio info if needed
ConfigRadioList.LetPlayersDragHud = true
