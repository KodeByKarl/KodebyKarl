-----------------------------------------------------------------
-- cfx-keydi-radio config
-----------------------------------------------------------------

--- Job-locked emergency bands (Barbie's channel map).
--- Police, Sheriff, and all EMS jobs can join every restricted frequency.
--- Civilians / staff cannot.
---   1.00–1.99  PD band
---   2.00–2.99  City EMS band
---   3.00–3.99  SD band
---   4.00–4.99  Sandy EMS band
---   5.00–5.99  Paleto EMS band
local emergencyJobs = {
    police = 0,
    sheriff = 0,
    ambulance = 0,
    sambulance = 0,
    pambulance = 0,
}
local emergencyBands = {
    { from = 100, to = 199, jobs = emergencyJobs },
    { from = 200, to = 299, jobs = emergencyJobs },
    { from = 300, to = 399, jobs = emergencyJobs },
    { from = 400, to = 499, jobs = emergencyJobs },
    { from = 500, to = 599, jobs = emergencyJobs },
}

--- pma-voice table keys must be integers. Decimal MHz (100.50 vs 100.5)
--- otherwise lands players on different channels and they cannot hear.
--- Channel id = MHz * 100  (100.00 MHz → 10000, 1.01 MHz → 101)
local function mhzToChannel(frequency)
    frequency = tonumber(frequency)
    if not frequency then return nil end
    return math.floor(frequency * 100 + 0.5)
end

--- Build per-frequency restrictions for pma-voice channel checks.
local function buildRestrictedChannels()
    local channels = {}
    for i = 1, #emergencyBands do
        local band = emergencyBands[i]
        for h = band.from, band.to do
            channels[h] = band.jobs
        end
    end
    return channels
end

local restrictedChannels = buildRestrictedChannels()

return {
    -- Enable usable item for opening the radio
    useUsableItem = true,

    -- Enable command for opening the radio
    useCommand = false,

    -- Default keybind for the '/radio' command
    commandKey = '',

    -- Enable disconnecting from frequency when there is no radio item left in player's inventory
    disconnectWithoutRadio = true,

    -- Percentage of volume to increase/decrease per step
    volumeStep = 10,

    -- Frequency decimal precision
    frequencyStep = 0.01,

    -- Maximum amount of available frequencies (starting from 0)
    maximumFrequencies = 1000,

    -- Frequency restrictions (generated from emergency bands above)
    -- 1.x–5.x bands: police, sheriff, and all EMS may join
    restrictedChannels = restrictedChannels,

    mhzToChannel = mhzToChannel,

    ---@param frequency number MHz (1.01, 100.00, …)
    ---@return boolean
    isRestrictedFrequency = function(frequency)
        local channel = mhzToChannel(frequency)
        return channel ~= nil and restrictedChannels[channel] ~= nil
    end,

    -- ! The following options will override pma-voice convars
    -- Enable radio voice effect (voice sounds like on a real radio)
    radioEffect = true,

    -- Enable animation while talking on radio
    radioAnimation = true,

    -- Default keybind for talking on radio
    radioTalkKey = 'LMENU',
}
