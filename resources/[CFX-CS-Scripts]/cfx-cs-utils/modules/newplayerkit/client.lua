local Config = require 'configs.newplayerkit'

if not Config or not Config.Enabled then return end

RegisterNetEvent('cfx-keydi-utils:newplayerkit:claim', function()
    TriggerServerEvent('cfx-keydi-utils:newplayerkit:server:claim')
end)

exports('ClaimNewPlayerKit', function()
    TriggerServerEvent('cfx-keydi-utils:newplayerkit:server:claim')
end)
