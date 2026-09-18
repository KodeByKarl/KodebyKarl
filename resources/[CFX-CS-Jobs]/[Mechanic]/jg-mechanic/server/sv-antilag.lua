-- Network sync for vehicle exhaust backfire & anti-lag effects
RegisterNetEvent("jg-mechanic:server:trigger-backfire", function(netId, scale, soundType)
  local src = source
  if not netId or netId == 0 then return end

  local ped = GetPlayerPed(src)
  if not ped or ped == 0 then return end

  local coords = GetEntityCoords(ped)
  TriggerClientEvent("jg-mechanic:client:sync-backfire", -1, src, netId, coords, scale or 1.0, soundType or "pop")
end)
