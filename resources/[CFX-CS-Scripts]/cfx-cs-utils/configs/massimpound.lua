return {
    Command = 'reqmassimpound',
    VoteSeconds = 45,           -- time to vote via /yes /no (or yes/no in chat)
    ImpoundDelaySeconds = 120,  -- 2 minutes after YES wins (manual vote)
    CommandCooldown = 600,      -- seconds between manual vote requests
    MinPlayers = 1,             -- minimum online players to start a vote
    NotifyTitle = 'MASS IMPOUND', -- ox_lib notify only (no chat spam; votes anonymous)

    -- Automatic mass impound (no vote). Timer starts when this resource starts.
    Auto = {
        Enabled = true,
        IntervalMinutes = 25,       -- every 25 minutes from resource start
        WarnSeconds = { 60, 30, 10 }, -- ox_lib warnings before each auto run
        SkipIfVoteActive = true,    -- skip this cycle if a player vote/countdown is running
    },
}
