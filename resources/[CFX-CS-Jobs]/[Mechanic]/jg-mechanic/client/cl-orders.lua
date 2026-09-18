RegisterNUICallback("get-mechanic-orders", function(data, cb)
  local pageIndex = data.pageIndex
  local pageSize = data.pageSize
  local orders = lib.callback.await("jg-mechanic:server:get-orders", false, pageIndex, pageSize)
  cb(orders)
end)

RegisterNUICallback("mark-order-fulfilled", function(data, cb)
  local orderId = data.orderId
  local success = lib.callback.await("jg-mechanic:server:mark-order-fulfilled", false, orderId)
  cb(success)
end)

RegisterNUICallback("delete-order", function(data, cb)
  local orderId = data.orderId
  local success = lib.callback.await("jg-mechanic:server:delete-order", false, orderId)
  cb(success)
end)

RegisterNUICallback("orders-install-category", function(data, cb)
  local orderId = data.orderId
  local category = data.category
  local orderData = lib.callback.await("jg-mechanic:server:can-apply-order", false, orderId)

  if not orderData then
    return cb({ error = true })
  end

  local vehicle = LocalPlayer.state.tabletConnectedVehicle and LocalPlayer.state.tabletConnectedVehicle.vehicleEntity
  if not vehicle or not DoesEntityExist(vehicle) then
    return cb(false)
  end

  local vehiclePlate = Framework.Client.GetPlate(vehicle)
  if vehiclePlate ~= orderData.plate then
    Framework.Client.Notify(Locale.vehPlateMismatch, "error")
    return cb({ error = true })
  end

  local minigameType = "prop"
  local minigameOptions = { prop = "spanner" }
  if category == "respray" then
    minigameType = "respray"
  end
  if category == "wheels" then
    minigameOptions = { prop = "wheel" }
  end

  Entity(vehicle).state:set("isMechanicServicing", true, true)
  playMinigame(vehicle, minigameType, minigameOptions, function(success)
    Entity(vehicle).state:set("isMechanicServicing", nil, true)
    showTabletAfterInteractionPrompt()
    SetNuiFocus(true, true)
    if not success then
      return cb(false)
    end

    local numMods = tableKeys(json.decode(orderData.cart or "{}")[category])
    if #numMods == 0 then
      return cb(false)
    end

    local paymentSuccess = lib.callback.await("jg-mechanic:server:pay-for-order-installation", false, category, #numMods)
    if not paymentSuccess then
      return cb(false)
    end

    if category == "repair" then
      Framework.Client.RepairVehicle(vehicle)
      Framework.Client.Notify(Locale.vehicleRepaired, "success")
    else
      local propsToApply = json.decode(orderData.props_to_apply or "{}")[category]
      if not propsToApply then
        return cb(false)
      end
      setVehicleProperties(vehicle, propsToApply, true)
      Entity(vehicle).state:set("applyVehicleProps", propsToApply, true)
      Framework.Client.Notify(Locale.installationSuccessful, "success")
      if Config.UpdatePropsOnChange then
        SetTimeout(1000, function()
          lib.callback.await("jg-mechanic:server:save-vehicle-props", false, vehiclePlate, getVehicleProperties(vehicle))
        end)
      end
    end
    lib.callback.await("jg-mechanic:server:mark-category-installed", false, orderId, category)
    cb(true)
  end)
end)
