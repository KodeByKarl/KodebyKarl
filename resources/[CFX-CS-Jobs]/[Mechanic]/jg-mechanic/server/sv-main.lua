lib.callback.register("jg-mechanic:server:nearby-players", function(source, coords, distance, includeSelf)
  local nearbyPlayers = lib.getNearbyPlayers(coords, distance)
  local formattedPlayers = {}
  for _, player in ipairs(nearbyPlayers) do
    if not includeSelf and player.id == source then
      goto continue
    end
    formattedPlayers[#formattedPlayers + 1] = {
      id = player.id,
      name = Framework.Server.GetPlayerInfo(player.id) and Framework.Server.GetPlayerInfo(player.id).name
    }
    ::continue::
  end
  return formattedPlayers
end)

AddEventHandler("onResourceStart", function(resourceName)
  if GetCurrentResourceName() ~= resourceName then
    return
  end
  initSQL()
  for name, data in pairs(Config.MechanicLocations) do
    MySQL.query.await("INSERT IGNORE INTO mechanic_data (name, balance) VALUES(?, 0)", { name })
  end
end)
