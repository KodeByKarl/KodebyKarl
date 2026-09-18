-- Server-side sync for Turbo Blow-Off Valve (BOV) flutter sounds
RegisterNetEvent("jg-mechanic:server:trigger-bov", function(netId, bovType)
  local src = source
  if not netId or netId == 0 then return end

  local ped = GetPlayerPed(src)
  if not ped or ped == 0 then return end

  local coords = GetEntityCoords(ped)
  TriggerClientEvent("jg-mechanic:client:sync-bov", -1, src, netId, coords, bovType or "hks")
end)
