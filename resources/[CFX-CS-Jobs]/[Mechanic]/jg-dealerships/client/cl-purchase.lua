--[[
  Description:
    Client-side vehicle purchase handling

  Global Namespace:
    None

  Globals:
    None

  Exports:
    None
]]--

---Purchase a vehicle
---@param purchaseData table Purchase data containing all purchase information
---@return boolean success
local function purchaseVehicle(purchaseData)
  local dealership = Locations.Client.GetLocationById(purchaseData.dealershipId)
  if not dealership then return false end

  local hash = ConvertModelToHash(purchaseData.model)
  local vehicleType = GetVehicleTypeFromClass(GetVehicleClassFromName(hash))

  local purchaseCoords = Utils.Client.ConvertSpawnCoordsToVec4(dealership.purchase_vehicle_coords)
  local coords = Utils.Client.FindAvailableSpawnCoords(purchaseCoords)

  Showroom.Client.Exit()

  local success, netId, vehicleId, plate, price = lib.callback.await(
    "jg-dealerships:server:purchase-vehicle", 
    false, 
    {
      dealershipId = purchaseData.dealershipId,
      coords = coords,
      purchaseType = purchaseData.purchaseType,
      society = purchaseData.society,
      societyType = purchaseData.societyType,
      model = purchaseData.model,
      colour = purchaseData.colour,
      paymentMethod = purchaseData.paymentMethod,
      finance = purchaseData.finance,
      directSaleUuid = purchaseData.directSaleUuid,
      couponCode = purchaseData.couponCode,
      tradeIn = purchaseData.tradeIn,
    }
  )
  local vehicle = netId and NetToVeh(netId) or nil --[[@as integer|false]]
  if not success then return false end

  if Config.SpawnVehiclesWithServerSetter and not vehicle then
    print("^1[ERROR] There was a problem spawning in your vehicle")
    DoScreenFadeIn(500)
    return true
  end

  -- Server spawning disabled, create vehicle on client
  if not vehicle and not Config.SpawnVehiclesWithServerSetter then
    -- For direct sales, don't warp the customer into the vehicle (let them walk to it with the seller)
    local isDirectSale = purchaseData.directSaleUuid ~= nil
    local warp = not Config.DoNotSpawnInsideVehicle and not isDirectSale
    local properties = {
      plate = plate,
      colour = purchaseData.colour
    }
    
    vehicle = Spawn.Client.Create(vehicleId or 0, purchaseData.model, plate, coords, warp, properties, "purchase")
    if not vehicle then
      print("^1[ERROR] The purchased vehicle was saved but could not be spawned")
      DoScreenFadeIn(500)
      return true
    end
    
    netId = VehToNet(vehicle)
  end

  if not vehicle then return false end

  local props = Framework.Client.GetVehicleProperties(vehicle)
  TriggerServerEvent("jg-dealerships:server:update-purchased-vehicle-props", purchaseData.purchaseType, purchaseData.society, plate, props)

  TriggerEvent("jg-dealerships:client:purchase-vehicle:config", vehicle, plate, purchaseData.purchaseType, price, purchaseData.paymentMethod, purchaseData.finance)
  TriggerServerEvent("jg-dealerships:server:purchase-vehicle:config", netId, plate, purchaseData.purchaseType, price, purchaseData.paymentMethod, purchaseData.finance)

  -- If they are running jg-advancedgarages, register the vehicle is out & set vehicle in valid garage ID
  if GetResourceState("jg-advancedgarages") == "started" then
    TriggerServerEvent("jg-advancedgarages:server:register-vehicle-outside", plate, netId)
    TriggerServerEvent("jg-advancedgarages:server:dealerships-send-to-default-garage", vehicleType, plate)
  end

  DoScreenFadeIn(500)

  return true
end

RegisterNUICallback("purchase-vehicle", function(data, cb)
  DoScreenFadeOut(500)
  Wait(500)

  local res = purchaseVehicle({
    dealershipId = data.dealership,
    model = data.vehicle,
    colour = data.color,
    purchaseType = data.purchaseType,
    paymentMethod = data.paymentMethod,
    finance = data.finance,
    society = data.society,
    societyType = data.societyType,
    directSaleUuid = data.directSaleUuid,
    couponCode = data.couponCode,
    tradeIn = data.tradeIn,
  })
  
  if not res then
    DoScreenFadeIn(0)
    return cb({error = true}) 
  end
  
  cb(true)
end)
