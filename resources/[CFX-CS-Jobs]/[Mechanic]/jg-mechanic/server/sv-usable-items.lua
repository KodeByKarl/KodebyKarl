Framework.Server.RegisterUsableItem("lighting_controller", function(src)
  if not Framework.Server.HasItem(src, "lighting_controller") then return end
  TriggerClientEvent("jg-mechanic:client:show-lighting-controller", src)
end)

Framework.Server.RegisterUsableItem("stancing_kit", function(src)
  if not Framework.Server.HasItem(src, "stancing_kit") then return end
  TriggerClientEvent("jg-mechanic:client:show-stancer-kit", src)
end)

Framework.Server.RegisterUsableItem("nitrous_bottle", function(src)
  if not Framework.Server.HasItem(src, "nitrous_bottle") then return end
  TriggerClientEvent("jg-mechanic:client:use-nitrous-bottle", src)
end)

Framework.Server.RegisterUsableItem("cleaning_kit", function(src)
  if not Framework.Server.HasItem(src, "cleaning_kit") then return end
  TriggerClientEvent("jg-mechanic:client:clean-vehicle", src)
end)

Framework.Server.RegisterUsableItem("repair_kit", function(src)
  if not Framework.Server.HasItem(src, "repair_kit") then return end
  TriggerClientEvent("jg-mechanic:client:repair-vehicle", src)
end)

Framework.Server.RegisterUsableItem("repairkit", function(src)
  if not Framework.Server.HasItem(src, "repairkit") then return end
  TriggerClientEvent("jg-mechanic:client:repair-vehicle", src)
end)

Framework.Server.RegisterUsableItem("duct_tape", function(src)
  if not Framework.Server.HasItem(src, "duct_tape") then return end
  TriggerClientEvent("jg-mechanic:client:use-duct-tape", src)
end)

Framework.Server.RegisterUsableItem("mechanic_tablet", function(src)
  if not Framework.Server.HasItem(src, "mechanic_tablet") then return end
  TriggerClientEvent("jg-mechanic:client:use-tablet", src)
end)
