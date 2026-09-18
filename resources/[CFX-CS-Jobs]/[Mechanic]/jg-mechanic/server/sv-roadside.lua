-- Server-side handler for roadside rescue & detailing items

lib.callback.register("jg-mechanic:server:consume-roadside-item", function(source, itemName)
  if not itemName or itemName == "" then return false end
  local removed = Framework.Server.RemoveItem(source, itemName, 1)
  return removed
end)

RegisterNetEvent("jg-mechanic:server:apply-ceramic-coating", function(netId)
  local src = source
  if not netId or netId == 0 then return end

  local vehicle = NetworkGetEntityFromNetworkId(netId)
  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

  -- 2 hours of ceramic protection (in seconds)
  local expiresAt = os.time() + 7200
  Entity(vehicle).state:set("ceramicCoated", expiresAt, true)

  Framework.Server.Notify(src, "Ceramic Nano-Coating applied! Vehicle is protected against dirt & grime for 2 hours.", "success")
end)
