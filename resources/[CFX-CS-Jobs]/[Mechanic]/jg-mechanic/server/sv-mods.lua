local function shouldIgnorePriceMultiplier(modName)
  for _, cosmeticData in pairs(Config.Mods.Cosmetics) do
    if cosmeticData.name == modName then
      if cosmeticData.ignorePriceMult then
        return true
      end
    end
  end
  return false
end

local function calculateModsPrice(locationConfig, vehiclePrice, modsCart)
  local totalPrice = 0
  local modPrices = locationConfig.mods

  if Config.ModsPricesAsPercentageOfVehicleValue then
    for _, modData in pairs(modPrices) do
      local percent = modData.percentVehVal or 0.01
      modData.price = round(vehiclePrice * percent, 0)
    end
  end

  for modType, mods in pairs(modsCart) do
    for modName, modData in pairs(mods) do
      local modIndex = modData.modIndex
      local ignoreMultiplier = shouldIgnorePriceMultiplier(modName)
      local modConfig = modPrices[modType]

      if modConfig then
        local basePrice = modConfig.price
        local priceMultiplier = modConfig.priceMult

        if not ignoreMultiplier and basePrice then
          local finalMultiplier
          if type(modIndex) == "number" and modIndex > 0 then
            local multiplierValue = priceMultiplier or 0
            finalMultiplier = 1 + (modIndex * multiplierValue)
          else
            finalMultiplier = 1
          end
          basePrice = round(basePrice * finalMultiplier, 0)
        end

        if modIndex == -1 then
          basePrice = 0
        end
        totalPrice = totalPrice + basePrice
      end
    end
  end
  return totalPrice
end

lib.callback.register("jg-mechanic:server:purchase-mods", function(source, mechanicName, vehiclePrice, modsCart, paymentMethod)
  local locationConfig = Config.MechanicLocations[mechanicName]
  if not locationConfig then
    return false
  end

  local isAnEmployee = isEmployee(source, mechanicName, { "mechanic", "manager" }, false)

  if paymentMethod ~= "noPayment" and paymentMethod ~= "mechanic" and paymentMethod ~= "bank" and paymentMethod ~= "cash" then
    Framework.Server.Notify(source, "INVALID_PAYMENT_METHOD", "error")
    return false
  end

  if paymentMethod == "noPayment" then
    if locationConfig.type == "owned" and isAnEmployee and Config.DisableNoPaymentOptionForEmployees then
      Framework.Server.Notify(source, "INVALID_PAYMENT_METHOD", "error")
      return false
    end
  end

  if paymentMethod == "noPayment" then
    return 0
  end

  local totalPrice = calculateModsPrice(locationConfig, vehiclePrice, modsCart)

  if paymentMethod == "mechanic" and isAnEmployee then
    if Config.MechanicEmployeesCanSelfServiceMods then
      local success = removeFromSocietyFund(source, mechanicName, totalPrice)
      if not success then
        return false
      end
    end
  elseif paymentMethod == "bank" or paymentMethod == "cash" then
    local playerBalance = Framework.Server.GetPlayerBalance(source, paymentMethod)
    if totalPrice > playerBalance then
      Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
      return false
    end
    Framework.Server.PlayerRemoveMoney(source, totalPrice, paymentMethod)
    if locationConfig.type == "owned" then
      addToSocietyFund(source, mechanicName, totalPrice)
    end
  else
    return false
  end
  return totalPrice
end)

lib.callback.register("jg-mechanic:server:open-mods-menu", function(source, vehicleNetId, plate)
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if vehicle and DoesEntityExist(vehicle) then
    Entity(vehicle).state:set("inMechanicMenu", { src = source, originalPlate = plate }, true)
    if plate and plate ~= "" then
      Entity(vehicle).state:set("realPlate", plate, true)
    end
    if Config.ChangePlateDuringPreview then
      SetVehicleNumberPlateText(vehicle, Config.ChangePlateDuringPreview)
    end
  end
  FgMechanicSession(source, 'mods', true)
  return true
end)

lib.callback.register("jg-mechanic:server:close-mods-menu", function(source, vehicleNetId)
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if vehicle and DoesEntityExist(vehicle) then
    Entity(vehicle).state:set("inMechanicMenu", nil, true)
  end
  FgMechanicSession(source, 'mods', false)
  return true
end)

lib.callback.register("jg-mechanic:server:self-service-mods-applied", function(source, mechanicName, vehicleNetId, plate, modsCart, amountPaid, paymentMethod)
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if vehicle and DoesEntityExist(vehicle) then
    Entity(vehicle).state:set("inMechanicMenu", nil, true)
    if Config.ChangePlateDuringPreview and plate then
      SetVehicleNumberPlateText(vehicle, plate)
    end
  end
  FgMechanicSession(source, 'mods', false)

  if not Webhooks.SelfService then
    return true
  end

  local modFields = {}
  local function getKeysAndConcat(data, separator)
    local keys = {}
    for key in pairs(data) do
      table.insert(keys, key)
    end
    return table.concat(keys, separator)
  end

  for modType, mods in pairs(modsCart) do
    local keyName = Locale[modType] or modType
    table.insert(modFields, {
      key = keyName,
      value = getKeysAndConcat(mods, ", ")
    })
  end

  local fields = {
    { key = "Mechanic", value = mechanicName },
    { key = "Vehicle", value = plate },
    { key = "Paid", value = amountPaid },
    { key = "Payment Method", value = paymentMethod }
  }

  sendWebhook(source, Webhooks.SelfService, "Self-Service Tuning Completed", "success", tableConcat(fields, modFields))
  return true
end)

lib.callback.register("jg-mechanic:server:place-order", function(source, mechanicName, plate, cart, amountPaid, propsToApply, paymentMethod)
  local locationConfig = Config.MechanicLocations[mechanicName]
  if not locationConfig then
    return false
  end

  local identifier = Framework.Server.GetPlayerIdentifier(source)
  if not identifier then
    Framework.Server.Notify(source, "There was a problem completing your order. Please try again later.", "error")
    if amountPaid and amountPaid > 0 then
      Framework.Server.PlayerAddMoney(source, amountPaid, paymentMethod)
      if locationConfig.type == "owned" then
        removeFromSocietyFund(source, mechanicName, amountPaid)
      end
    end
    return false
  end

  amountPaid = tonumber(amountPaid) or 0

  local orderId = MySQL.insert.await("INSERT INTO mechanic_orders (identifier, mechanic, plate, cart, props_to_apply, amount_paid) VALUES (?, ?, ?, ?, ?, ?)", {
    identifier,
    mechanicName,
    plate,
    json.encode(cart),
    json.encode(propsToApply),
    amountPaid
  })

  if not orderId then
    Framework.Server.Notify(source, "There was a problem completing your order. Please try again later.", "error")
    if amountPaid and amountPaid > 0 then
      Framework.Server.PlayerAddMoney(source, amountPaid, paymentMethod)
      if locationConfig.type == "owned" then
        removeFromSocietyFund(source, mechanicName, amountPaid)
      end
    end
    return false
  end

  TriggerEvent("jg-mechanic:server:order-placed-config", orderId, mechanicName, plate, cart, amountPaid, propsToApply, paymentMethod)
  sendWebhook(source, Webhooks.Orders, "Orders: Order Placed", "success", {
    { key = "Mechanic", value = mechanicName },
    { key = "Order #", value = orderId },
    { key = "Vehicle", value = plate },
    { key = "Paid", value = amountPaid },
    { key = "Payment Method", value = paymentMethod }
  })
  return true
end)

lib.callback.register("jg-mechanic:server:self-service-repair-vehicle", function(source, mechanicName, vehiclePrice, paymentMethod)
  local locationConfig = Config.MechanicLocations[mechanicName]
  if not locationConfig then
    return false
  end

  local repairConfig = locationConfig.mods.repair
  local isEnabled = repairConfig.enabled
  local price = repairConfig.price
  local percentVehVal = repairConfig.percentVehVal

  if not isEnabled then
    return false
  end

  if Config.ModsPricesAsPercentageOfVehicleValue then
    local percent = percentVehVal or 0.01
    price = round(vehiclePrice * percent, 0)
  end

  if paymentMethod ~= "bank" and paymentMethod ~= "cash" then
    Framework.Server.Notify(source, "INVALID_PAYMENT_METHOD", "error")
    return false
  end

  local playerBalance = Framework.Server.GetPlayerBalance(source, paymentMethod)
  if price > playerBalance then
    Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
    return false
  end

  Framework.Server.PlayerRemoveMoney(source, price, paymentMethod)
  if locationConfig.type == "owned" then
    addToSocietyFund(source, mechanicName, price)
  end

  FgMechanicSession(source, 'repair', true, 8000)
  return true
end)

lib.callback.register("jg-mechanic:server:count-currently-on-duty", function(source, jobName)
  if not GlobalState or not GlobalState.mechanicsOnDuty then
    return 0
  end

  local count = 0
  for playerSource, onDutyJobName in pairs(GlobalState.mechanicsOnDuty) do
    if DoesEntityExist(GetPlayerPed(playerSource)) and onDutyJobName == jobName then
      count = count + 1
    end
  end
  return count
end)
