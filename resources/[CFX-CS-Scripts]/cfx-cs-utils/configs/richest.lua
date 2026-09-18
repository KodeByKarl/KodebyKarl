--[[
  Richest player logger (ESX users.accounts).
  Posts the #1 richest player to Discord via WebHook.
]]

return {
    Enabled = true,

    -- short | standard | full  (used for the Top N list under #1)
    LogMessageType = 'standard',

    -- Include black_money in the total
    BlackMoney = true,

    -- Rank a Top N list after the richest player
    OnlyTopRichest = {
        enable = true,
        top = 10,
    },

    -- Post as soon as the resource starts
    SendOnStart = true,

    -- Auto-send on an interval (minutes)
    SendLogByTime = {
        enable = true,
        time = 60,
    },

    -- Admin command (ESX group admin+)
    AdminCommand = 'topmoney',

    -- kodebykarl-logs channel alias (used only if WebHook is empty / fails)
    LogsChannel = 'richest',

    -- Discord webhook (preferred when set)
    WebHook = 'https://discord.com/api/webhooks/1549037745316434043/zTUm_zP__-bkLTaNfEzHpNMQaGc1C5-LMXtOA26GesGRB2_emYZizacUKX4O19dUT9tb',

    ServerName = 'Grim City',
    LogTitle = 'Richest Player',
    LogColour = 10181046, -- purple
    AvatarURL = '',
}
