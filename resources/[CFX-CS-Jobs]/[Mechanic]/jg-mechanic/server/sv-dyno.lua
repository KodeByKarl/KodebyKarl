lib.callback.register("jg-mechanic:server:dyno-share-with-player", function(source, targetPlayerId, results)
  local targetPlayer = Player(targetPlayerId)
  if targetPlayer.state and targetPlayer.state.isBusy then
    Framework.Server.Notify(source, Locale.playerIsBusy, "error")
    return false
  end
  TriggerClientEvent("jg-mechanic:client:dyno-show-results-sheet", targetPlayerId, results)
  return true
end)
