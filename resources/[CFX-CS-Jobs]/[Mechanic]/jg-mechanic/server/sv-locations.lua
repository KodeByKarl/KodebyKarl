lib.callback.register("jg-mechanic:server:get-mechanic-locations-data", function()
  local mechanicData = MySQL.query.await("SELECT * FROM mechanic_data")
  return mechanicData
end)
