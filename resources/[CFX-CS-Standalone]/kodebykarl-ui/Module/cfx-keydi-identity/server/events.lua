if Config.EnableCommands then
    ESX.RegisterCommand('char', 'user', function(xPlayer, args, showError)
        if xPlayer and xPlayer.getName() then
            xPlayer.showNotification(("Active Character: %s"):format(xPlayer.getName()))
        else
            xPlayer.showNotification("No active character found.")
        end
    end, false, { help = "Show active character name" })

    ESX.RegisterCommand('chardel', 'user', function(xPlayer, args, showError)
        if xPlayer and xPlayer.getName() then
            local identifier = xPlayer.identifier
            xPlayer.kick("Your character was deleted. Re-connect to create a new one.")
            Wait(1500)
            Database.DeleteIdentity(identifier, function(success)
                if success then
                    IdentityUtils.Debug("Deleted character identity for: %s", identifier)
                end
            end)
        else
            xPlayer.showNotification("Error: You do not have an active character to delete.")
        end
    end, false, { help = "Delete your active character identity" })
end
