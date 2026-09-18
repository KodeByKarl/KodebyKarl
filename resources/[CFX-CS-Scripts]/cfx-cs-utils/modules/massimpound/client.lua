local Config = require 'configs.massimpound'

CreateThread(function()
    Wait(1500)
    TriggerEvent('chat:addSuggestion', '/' .. (Config.Command or 'reqmassimpound'), 'Request a city-wide mass impound vote (ox_lib notify).')
    TriggerEvent('chat:addSuggestion', '/yes', 'Vote YES on the mass impound (anonymous).')
    TriggerEvent('chat:addSuggestion', '/no', 'Vote NO on the mass impound (anonymous).')
end)
