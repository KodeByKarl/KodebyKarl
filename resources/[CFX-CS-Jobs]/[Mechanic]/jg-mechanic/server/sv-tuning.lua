lib.callback.register("jg-mechanic:server:pay-for-tune", function(source, tuneCategory, tuneOption, currentOption, plate)
  if not HasActiveTabletConnection(source, plate) then
    return false
  end

  local playerState = Player(source).state
  local tuneData = Config.Tuning[tuneCategory] and Config.Tuning[tuneCategory][tuneOption]
  if not tuneData then
    return false
  end

  local mechanicId = playerState.mechanicId
  local mechanicLocation = Config.MechanicLocations[mechanicId]
  if not mechanicLocation then
    return false
  end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  local tuneLocationConfig = mechanicLocation.tuning[tuneCategory]
  if not tuneLocationConfig or tuneLocationConfig.enabled ~= true then
    return false
  end

  if tuneLocationConfig.requiresItem then
    if not tuneData.itemName then
      return false
    end
    if not Framework.Server.RemoveItem(source, tuneData.itemName) then
      return false
    end

    if Config.TuningGiveInstalledItemBackOnRemoval then
      local previousTuneData = Config.Tuning[tuneCategory] and Config.Tuning[tuneCategory][currentOption]
      if previousTuneData and previousTuneData.itemName then
        if not Framework.Server.GiveItem(source, previousTuneData.itemName) then
          return false
        end
      end
    end
  else
    if not removeFromSocietyFund(source, mechanicId, tuneData.price) then
      return false
    end
  end

  sendWebhook(source, Webhooks.TabletTuning, "Tuning: Tune Applied via Tablet", "success", {
    { key = "Mechanic", value = mechanicId },
    { key = "Vehicle Plate", value = plate },
    { key = "Tune Category", value = Locale[tuneCategory] or tuneCategory },
    { key = "Tune Option", value = tuneData.name },
  })

  return true
end)

lib.callback.register("jg-mechanic:server:remove-tune", function(source, tuneCategory, tuneOption, plate)
  if not HasActiveTabletConnection(source, plate) then
    return false
  end

  local playerState = Player(source).state
  local tuneData = Config.Tuning[tuneCategory] and Config.Tuning[tuneCategory][tuneOption]
  if not tuneData then
    return false
  end

  local mechanicId = playerState.mechanicId
  local mechanicLocation = Config.MechanicLocations[mechanicId]
  if not mechanicLocation then
    return false
  end

  if not isEmployee(source, mechanicId, { "mechanic", "manager" }, true) then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  if not Config.TuningGiveInstalledItemBackOnRemoval then
    return true
  end

  local tuneLocationConfig = mechanicLocation.tuning[tuneCategory]
  if not tuneLocationConfig or tuneLocationConfig.enabled ~= true then
    return false
  end

  if tuneLocationConfig.requiresItem then
    if not tuneData.itemName then
      return false
    end
    if not Framework.Server.GiveItem(source, tuneData.itemName) then
      return false
    end
  end

  sendWebhook(source, Webhooks.TabletTuning, "Tuning: Tune Removed", "danger", {
    { key = "Mechanic", value = mechanicId },
    { key = "Vehicle Plate", value = plate },
    { key = "Tune Category", value = Locale[tuneCategory] or tuneCategory },
    { key = "Tune Option", value = tuneData.name },
  })

  return true
end)
