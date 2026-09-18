local Config = require 'configs.playtimereward'

if not Config or not Config.Enabled then return end

RegisterNetEvent('cfx-keydi-utils:playtimereward:claim', function(rewardId)
    TriggerServerEvent('cfx-keydi-utils:playtimereward:server:claim', rewardId or 'sunrise')
end)

exports('ClaimPlaytimeReward', function(rewardId)
    TriggerServerEvent('cfx-keydi-utils:playtimereward:server:claim', rewardId or 'sunrise')
end)

exports('ClaimNeonReward', function()
    TriggerServerEvent('cfx-keydi-utils:playtimereward:server:claim', 'neon')
end)

exports('ClaimSunriseReward', function()
    TriggerServerEvent('cfx-keydi-utils:playtimereward:server:claim', 'sunrise')
end)
