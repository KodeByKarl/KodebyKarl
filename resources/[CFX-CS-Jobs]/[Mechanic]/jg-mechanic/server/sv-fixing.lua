lib.addCommand(Config.FullRepairAdminCommand or "vfix", {
  help = "Fully fix a vehicle (admin only)"
}, function(source)
  if not Framework.Server.IsAdmin(source) then
    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
    return
  end
  TriggerClientEvent("jg-mechanic:client:fix-vehicle-admin", source)
end)
