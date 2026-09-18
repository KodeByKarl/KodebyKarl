--[[
  Description:
    Server-side vehicle purchase handling (refactored)

  Global Namespace:
    None

  Globals:
    None

  Exports:
    getSalesHistory(dealershipId, limit?) - Get recent sales for a dealership
    getTotalSales(dealershipId) - Get total revenue for a dealership
]]--

local purchaseLocks = {}

---@param directSaleUuid string|nil
---@param buyerSource integer
---@param vehicleId string|number|nil
---@param plate string
---@param amountPaid integer
---@param paymentMethod string
---@param netId? integer
local function markDirectSalePurchased(directSaleUuid, buyerSource, vehicleId, plate, amountPaid, paymentMethod, netId)
  if not directSaleUuid then return end

  DirectSales.Server.CompletePurchase(directSaleUuid, buyerSource, {
    vehicleId = vehicleId,
    plate = plate,
    amountPaid = amountPaid,
    paymentMethod = paymentMethod,
    netId = netId,
  })
end

---@param value any
---@return string|nil plate
local function normalizeTradeInPlate(value)
  if type(value) ~= "string" then return nil end

  local plate = value:match("^%s*(.-)%s*$"):upper()
  if plate == "" or #plate > 20 then return nil end
  return plate
end

---@param exportName string
---@param ... any
---@return table|false result
local function callUsedVehiclesExport(exportName, ...)
  local resourceName = "jg-usedvehicles"
  if GetResourceState(resourceName) ~= "started" then return false end

  local args = table.pack(...)
  local success, result = pcall(function()
    if exportName == "prepareUsedTradeIn" then
      return exports[resourceName]:prepareUsedTradeIn(table.unpack(args, 1, args.n))
    end
    if exportName == "commitUsedTradeIn" then
      return exports[resourceName]:commitUsedTradeIn(table.unpack(args, 1, args.n))
    end
    error("unsupported used vehicles export: " .. exportName)
  end)
  if not success or type(result) ~= "table" then
    DebugPrint(("Used vehicles export %s failed: %s"):format(exportName, tostring(result)), "warning")
    return false
  end
  return result
end

---@param directSaleUuid string
---@return table|nil purchase
local function getTradeInPurchase(directSaleUuid)
  local purchaseReference = "jg-dealerships:trade-in:" .. directSaleUuid
  local operation = UsedVehiclesIntegration.Server.GetOperationRecord(purchaseReference)
  if not operation or operation.operation_type ~= "trade_in_purchase"
    or type(operation.request_data) ~= "table"
    or operation.request_data.direct_sale_uuid ~= directSaleUuid
  then
    return nil
  end

  local purchase = operation.request_data
  purchase.purchase_reference = purchaseReference
  purchase.request_signature = operation.request_signature
  purchase.status = operation.status
  purchase.response_data = operation.result_data
  purchase.error_message = operation.error_message
  return purchase
end

---@param row table
---@return table response
local function getTradeInPurchaseResponse(row)
  if type(row.response_data) == "table" then return row.response_data end
  if type(row.response_data) ~= "string" or row.response_data == "" then return {} end
  local success, response = pcall(json.decode, row.response_data)
  if not success or type(response) ~= "table" then return {} end
  return response
end

---@param purchaseReference string
---@param status string
---@param response table
---@param errorMessage? string
local function updateTradeInPurchase(purchaseReference, status, response, errorMessage)
  local operation = UsedVehiclesIntegration.Server.GetOperationRecord(purchaseReference)
  if not operation or operation.operation_type ~= "trade_in_purchase" then return end

  UsedVehiclesIntegration.Server.UpdateOperation(
    purchaseReference,
    "trade_in_purchase",
    operation.request_signature,
    status,
    response,
    errorMessage,
    operation.status
  )
end

---@param src integer
---@param dealership table
---@param row table
---@param response table
local function compensateTradeInPurchase(src, dealership, row, response)
  if row.purchase_type == "society" and row.payment_method == "societyFund" then
    Framework.Server.AddToSocietyFund(row.society, row.society_type, tonumber(row.base_amount) or 0)
  else
    Framework.Server.PlayerAddMoney(src, tonumber(row.currency_amount) or 0, row.payment_method)
  end

  if dealership.type == "owned" then
    MySQL.update.await(
      "UPDATE dealership_stock SET stock = stock + 1 WHERE vehicle = ? AND dealership = ?",
      {row.vehicle, row.dealership}
    )
    DealershipBalance.Server.Remove(row.dealership, tonumber(row.base_amount) or 0)
  end

  MySQL.update.await(
    "DELETE FROM dealership_sales WHERE dealership = ? AND plate = ?",
    {row.dealership, row.plate}
  )
  MySQL.update.await(
    "DELETE FROM " .. Framework.VehiclesTable .. " WHERE plate = ? AND " .. Framework.PlayerId .. " = ?",
    {row.plate, row.buyer_identifier}
  )
  response.compensatedAt = os.time()
end

---@param src integer
---@param purchaseData table
---@param row table
---@param response table
---@return boolean success
---@return integer|nil netId
local function finishRecoveredTradeInPurchase(src, purchaseData, row, response)
  local netId = math.floor(tonumber(response.netId) or 0)
  if Config.SpawnVehiclesWithServerSetter
    and (not netId or netId == 0 or NetworkGetEntityFromNetworkId(netId) == 0)
  then
    local properties = {
      plate = row.plate,
      colour = purchaseData.colour,
    }
    Spawn.Server.RegisterPendingStatebags(
      src,
      tonumber(row.vehicle_id) or row.vehicle_id or 0,
      row.vehicle,
      row.plate,
      properties
    )
    netId = Spawn.Server.Create(
      src,
      tonumber(row.vehicle_id) or row.vehicle_id or 0,
      row.vehicle,
      row.plate,
      purchaseData.coords,
      false,
      properties,
      "purchase"
    )
    if not netId or netId == 0 then
      Framework.Server.Notify(src, Locale.couldNotSpawnVehicle, "error")
      netId = nil
    end
  end

  response.netId = netId
  response.completedAt = os.time()
  updateTradeInPurchase(row.purchase_reference, "completed", response)
  Showroom.Server.UpdateVehicleCache(row.vehicle, row.dealership)
  Framework.Server.Notify(src, Locale.purchaseSuccess, "success")
  return true, netId
end

---Purchase a vehicle
---@param src number Player source
---@param purchaseData table Purchase data containing all purchase information
---@return boolean success
---@return integer? netId
---@return integer? vehicleId
---@return string? plate
---@return number? amountPaid
local function purchaseVehicle(src, purchaseData)
  DebugPrint("=== PURCHASE VEHICLE ===", "debug")
  DebugPrint("Player: " .. tostring(src), "debug")
  DebugPrint("Dealership: " .. tostring(purchaseData.dealershipId), "debug")
  DebugPrint("Vehicle: " .. tostring(purchaseData.model), "debug")
  DebugPrint("Payment Method: " .. tostring(purchaseData.paymentMethod), "debug")
  DebugPrint("Finance: " .. tostring(purchaseData.finance), "debug")
  DebugPrint("Coupon: " .. tostring(purchaseData.couponCode or "none"), "debug")
  DebugPrint("========================", "debug")
  
  local dealership = Locations.Server.GetById(purchaseData.dealershipId)
  if not dealership then 
    DebugPrint("Dealership not found: " .. tostring(purchaseData.dealershipId), "warning")
    return false 
  end
  local usedVehiclesSettings = Locations.Server.MergeAdditionalData(
    dealership.additional_data
  ).usedVehicles

  local pendingSale, sellerPlayer, sellerPlayerName = nil, nil, nil

  -- If directSaleUuid was provided, fetch info
  if purchaseData.directSaleUuid then
    pendingSale = DirectSales.Server.GetPending(purchaseData.directSaleUuid)
    if not pendingSale then return false end
  
    -- Is the intended recipient accepting?
    if src ~= pendingSale.playerId then return false end
    if pendingSale.dealershipId ~= purchaseData.dealershipId
      or tostring(pendingSale.model) ~= tostring(purchaseData.model)
    then
      return false
    end

    purchaseData.purchaseType = "personal"
    purchaseData.model = pendingSale.model
    purchaseData.colour = pendingSale.colour
    purchaseData.couponCode = pendingSale.couponCode

    if pendingSale.dealerPlayerId then
      sellerPlayer = Framework.Server.GetPlayerIdentifier(pendingSale.dealerPlayerId)
      sellerPlayerName = Framework.Server.GetPlayerInfo(pendingSale.dealerPlayerId)
      sellerPlayerName = sellerPlayerName and sellerPlayerName.name or nil
    end

    purchaseData.finance = pendingSale.finance -- In case this was somehow changed by in transit by manually firing the purchase-vehicle event

    local completedPurchase = pendingSale.completedPurchase
    if completedPurchase then
      return true,
        tonumber(completedPurchase.netId),
        tonumber(completedPurchase.vehicleId) or completedPurchase.vehicleId,
        completedPurchase.plate,
        tonumber(completedPurchase.amountPaid)
    end

    local existingTradeInPurchase = getTradeInPurchase(purchaseData.directSaleUuid)
    if existingTradeInPurchase then
      local playerIdentifier = Framework.Server.GetPlayerIdentifier(src)
      if existingTradeInPurchase.buyer_identifier ~= playerIdentifier
        or existingTradeInPurchase.dealership ~= purchaseData.dealershipId
        or tostring(existingTradeInPurchase.vehicle) ~= tostring(purchaseData.model)
      then
        return false
      end

      local response = getTradeInPurchaseResponse(existingTradeInPurchase)
      if existingTradeInPurchase.status == "completed" then
        markDirectSalePurchased(
          purchaseData.directSaleUuid,
          src,
          existingTradeInPurchase.vehicle_id,
          existingTradeInPurchase.plate,
          tonumber(existingTradeInPurchase.currency_amount) or 0,
          existingTradeInPurchase.payment_method,
          tonumber(response.netId)
        )
        return true,
          tonumber(response.netId),
          tonumber(existingTradeInPurchase.vehicle_id) or existingTradeInPurchase.vehicle_id,
          existingTradeInPurchase.plate,
          tonumber(existingTradeInPurchase.currency_amount)
      end

      if existingTradeInPurchase.status == "committed" then
        local success, netId = finishRecoveredTradeInPurchase(
          src,
          purchaseData,
          existingTradeInPurchase,
          response
        )
        if not success then
          Framework.Server.Notify(src, Locale.couldNotSpawnVehicle, "error")
          return false
        end
        markDirectSalePurchased(
          purchaseData.directSaleUuid,
          src,
          existingTradeInPurchase.vehicle_id,
          existingTradeInPurchase.plate,
          tonumber(existingTradeInPurchase.currency_amount) or 0,
          existingTradeInPurchase.payment_method,
          netId
        )
        return true,
          netId,
          tonumber(existingTradeInPurchase.vehicle_id) or existingTradeInPurchase.vehicle_id,
          existingTradeInPurchase.plate,
          tonumber(existingTradeInPurchase.currency_amount)
      end

      if existingTradeInPurchase.status == "compensated" or existingTradeInPurchase.status == "failed" then
        Framework.Server.Notify(src, Locale.usedVehiclesTradeInSettlementFailed, "error")
        return false
      end

      local commitResult = callUsedVehiclesExport(
        "commitUsedTradeIn",
        existingTradeInPurchase.session_id,
        existingTradeInPurchase.purchase_reference
      )
      if commitResult and (commitResult.success == true or commitResult.status == "completed") then
        response.tradeInCommit = commitResult
        updateTradeInPurchase(existingTradeInPurchase.purchase_reference, "committed", response)
        local success, netId = finishRecoveredTradeInPurchase(
          src,
          purchaseData,
          existingTradeInPurchase,
          response
        )
        if not success then
          Framework.Server.Notify(src, Locale.couldNotSpawnVehicle, "error")
          return false
        end
        markDirectSalePurchased(
          purchaseData.directSaleUuid,
          src,
          existingTradeInPurchase.vehicle_id,
          existingTradeInPurchase.plate,
          tonumber(existingTradeInPurchase.currency_amount) or 0,
          existingTradeInPurchase.payment_method,
          netId
        )
        return true,
          netId,
          tonumber(existingTradeInPurchase.vehicle_id) or existingTradeInPurchase.vehicle_id,
          existingTradeInPurchase.plate,
          tonumber(existingTradeInPurchase.currency_amount)
      end

      if commitResult and commitResult.status == "failed" then
        response.tradeInCommit = commitResult
        compensateTradeInPurchase(src, dealership, existingTradeInPurchase, response)
        updateTradeInPurchase(
          existingTradeInPurchase.purchase_reference,
          "compensated",
          response,
          commitResult.error
        )
        Framework.Server.Notify(src, Locale.usedVehiclesTradeInSettlementFailed, "error")
        return false
      end

      response.tradeInCommit = commitResult or {status = "pending"}
      updateTradeInPurchase(
        existingTradeInPurchase.purchase_reference,
        "pending",
        response,
        commitResult and commitResult.error or "trade-in settlement is pending"
      )
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInSettlementPending, "error")
      return false
    end
  end

  -- Purchases disabled for this dealership? (only applies to showroom purchases, not direct sales)
  if not dealership.enable_purchase and not purchaseData.directSaleUuid then
    DebugPrint(("Player %s attempted to purchase at dealership %s but purchases are disabled"):format(tostring(src), tostring(purchaseData.dealershipId)), "warning")
    return false
  end

  -- Financed but the dealership location doesn't allow that?
  if not dealership.enable_finance and purchaseData.finance then return false end

  -- Check if valid payment method using the new currency system
  local dealershipPaymentMethods = dealership.payment_methods or {"bank", "cash"}
  local isValidPaymentMethod = lib.table.contains(dealershipPaymentMethods, purchaseData.paymentMethod) or purchaseData.paymentMethod == "societyFund"
  
  -- Verify the currency actually exists in the system
  local currency = Currencies.Server.Get(purchaseData.paymentMethod)
  if not isValidPaymentMethod or (purchaseData.paymentMethod ~= "societyFund" and not currency) then
    Framework.Server.Notify(src, Locale.invalidPaymentMethod, "error")
    DebugPrint(("%s attempted to purchase a vehicle with an invalid payment method: %s"):format(tostring(src), purchaseData.paymentMethod), "warning")
    return false
  end

  -- Check if currency allows financing
  if purchaseData.finance and purchaseData.paymentMethod ~= "societyFund" then
    if not Currencies.Server.AllowsFinance(purchaseData.paymentMethod) then
      Framework.Server.Notify(src, Locale.paymentMethodNoFinance, "error")
      DebugPrint(("%s attempted to finance with a payment method that doesn't support financing: %s"):format(tostring(src), purchaseData.paymentMethod), "warning")
      return false
    end
  end
  
  local plate = Framework.Server.VehicleGeneratePlate(Config.PlateFormat, true)
  if not plate then
    Framework.Server.Notify(src, Locale.couldNotGeneratePlate, "error")
    return false
  end
  
  -- Get vehicle data
  local vehicleData = MySQL.single.await([[
    SELECT stock.*, vehicle.category FROM dealership_stock stock
    INNER JOIN dealership_vehicles vehicle ON vehicle.spawn_code = stock.vehicle
    WHERE stock.vehicle = ? AND stock.dealership = ?
  ]], {purchaseData.model, purchaseData.dealershipId})
  if not vehicleData then
    DebugPrint("Vehicle not found in dealership(" .. purchaseData.dealershipId .. ") stock: " .. purchaseData.model, "warning")
    return false
  end

  -- Check stock level
  local vehicleStock = vehicleData.stock
  if dealership.type == "owned" and vehicleStock < 1 then
    Framework.Server.Notify(src, Locale.errorVehicleOutOfStock, "error")
    return false
  end

  local player = Framework.Server.GetPlayerIdentifier(src)
  local financeData = nil
  local agreedVehiclePrice = pendingSale and tonumber(pendingSale.price) or tonumber(vehicleData.price)
  if not agreedVehiclePrice or agreedVehiclePrice < 0 then return false end
  local basePriceToPay = Round(agreedVehiclePrice) -- Price in base currency ($)
  local couponDiscount = 0
  local validatedCoupon = nil
  local tradeInSessionId = nil
  local tradeInPurchaseReference = nil
  local tradeInPrepareResult = nil
  
  -- Validate and apply coupon if provided
  if purchaseData.couponCode and purchaseData.couponCode ~= "" and Coupons.Server.ValidateAndApplyCoupon then
    DebugPrint(("Validating coupon: %s"):format(purchaseData.couponCode), "debug")
    local couponResult = Coupons.Server.ValidateAndApplyCoupon(src, purchaseData.dealershipId, purchaseData.couponCode, purchaseData.model, vehicleData.category, purchaseData.finance, agreedVehiclePrice)
    
    if couponResult.valid then
      couponDiscount = couponResult.discount
      validatedCoupon = couponResult.coupon
      basePriceToPay = Round(math.max(0, agreedVehiclePrice - couponDiscount))
      DebugPrint(("Coupon applied - Discount: %s, New price: %s"):format(couponDiscount, basePriceToPay), "debug")
    else
      -- Coupon validation failed, notify player and reject purchase
      DebugPrint(("Coupon validation failed: %s"):format(couponResult.message or "Unknown error"), "warning")
      Framework.Server.Notify(src, string.gsub(Locale.invalidCoupon, '%%{value}', couponResult.message or "Unknown error"), "error")
      return false
    end
  elseif purchaseData.couponCode and purchaseData.couponCode ~= "" then
    DebugPrint("Coupon system not available but coupon code provided", "warning")
  end

  local tradeInAppraisalAmount = pendingSale and tonumber(pendingSale.tradeInAppraisalAmount) or nil
  if purchaseData.tradeIn and not tradeInAppraisalAmount then
    Framework.Server.Notify(src, Locale.usedVehiclesTradeInUnavailable, "error")
    return false
  end

  if tradeInAppraisalAmount then
    if GetResourceState("jg-usedvehicles") ~= "started"
      or usedVehiclesSettings.enabled ~= true
      or usedVehiclesSettings.directSalesEnabled == false
      or usedVehiclesSettings.tradeInsEnabled ~= true
      or purchaseData.purchaseType ~= "personal"
      or type(purchaseData.tradeIn) ~= "table"
    then
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInUnavailable, "error")
      return false
    end
    if tradeInAppraisalAmount < 1
      or tradeInAppraisalAmount ~= math.floor(tradeInAppraisalAmount)
      or tradeInAppraisalAmount > usedVehiclesSettings.maxTradeInAppraisal
    then
      Framework.Server.Notify(src, Locale.usedVehiclesInvalidAppraisal, "error")
      return false
    end
    if not pendingSale then return false end
    local appraiserSource = tonumber(pendingSale.tradeInAppraiserSource)
    if not appraiserSource
      or not Employees.Server.IsEmployee(
        appraiserSource,
        purchaseData.dealershipId,
        "MANAGE_INVENTORY",
        false
      )
    then
      Framework.Server.Notify(src, Locale.usedVehiclesAppraisalPermissionError, "error")
      return false
    end

    local selection = purchaseData.tradeIn
    local selectedPlate = normalizeTradeInPlate(selection.plate)
    local expectedPlate = normalizeTradeInPlate(pendingSale.tradeInPlate)
    if not selectedPlate or not expectedPlate or selectedPlate ~= expectedPlate then
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInVehicleMismatch, "error")
      return false
    end

    tradeInPurchaseReference = "jg-dealerships:trade-in:" .. purchaseData.directSaleUuid
    tradeInPrepareResult = callUsedVehiclesExport(
      "prepareUsedTradeIn",
      src,
      purchaseData.dealershipId,
      {
        plate = expectedPlate,
        appraisalAmount = math.floor(tradeInAppraisalAmount),
        appraiserSource = appraiserSource,
        surface = "directSales",
        allowFinancePayoff = usedVehiclesSettings.allowFinancePayoffTradeIns ~= false,
        requestKey = tradeInPurchaseReference .. ":prepare",
        directSaleUuid = purchaseData.directSaleUuid,
        purchase = {
          model = purchaseData.model,
          price = basePriceToPay,
          paymentMethod = purchaseData.paymentMethod,
          currencyId = purchaseData.paymentMethod,
          finance = purchaseData.finance == true,
        },
      }
    )
    local netCredit = tradeInPrepareResult and tonumber(tradeInPrepareResult.netCredit)
    local preparedSessionId = tradeInPrepareResult and tonumber(tradeInPrepareResult.sessionId)
    if not tradeInPrepareResult
      or tradeInPrepareResult.success ~= true
      or not preparedSessionId
      or preparedSessionId ~= math.floor(preparedSessionId)
      or preparedSessionId < 1
      or not netCredit
      or netCredit ~= math.floor(netCredit)
    then
      Framework.Server.Notify(
        src,
        tradeInPrepareResult and tradeInPrepareResult.error or Locale.usedVehiclesTradeInSelectionFailed,
        "error"
      )
      return false
    end
    if netCredit > basePriceToPay then
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInCreditExceedsPurchase, "error")
      return false
    end

    tradeInSessionId = preparedSessionId
    basePriceToPay = Round(basePriceToPay - netCredit)
  end

  -- Convert base price to the payment currency amount
  local currencyAmountToPay = Currencies.Server.ConvertFromBase(basePriceToPay, purchaseData.paymentMethod)
  currencyAmountToPay = Round(currencyAmountToPay)
  
  local accountBalance = Framework.Server.GetPlayerBalance(src, purchaseData.paymentMethod)
  local paymentType, paid, owed = "full", basePriceToPay, 0
  local downPayment, noOfPayments = Config.FinanceDownPayment, Config.FinancePayments

  if purchaseData.purchaseType == "society" and purchaseData.paymentMethod == "societyFund" then
    accountBalance = Framework.Server.GetSocietyBalance(purchaseData.society, purchaseData.societyType)
    currencyAmountToPay = basePriceToPay -- Society funds use base currency
  end

  if purchaseData.finance and purchaseData.purchaseType == "personal" then
    local discountedPrice = basePriceToPay
    local baseDownPayment = Round(discountedPrice * (1 + Config.FinanceInterest) * downPayment) -- down payment in base currency

    if pendingSale then
      downPayment, noOfPayments = pendingSale.downPayment, pendingSale.noOfPayments
      baseDownPayment = Round(discountedPrice * (1 + Config.FinanceInterest) * downPayment)
    end

    -- Finance data is stored in the payment currency for recurring payments
    financeData = {
      total = Round(discountedPrice * (1 + Config.FinanceInterest)),
      paid = baseDownPayment,
      recurring_payment = Round((discountedPrice * (1 + Config.FinanceInterest) * (1 - downPayment)) / noOfPayments),
      payments_complete = 0,
      total_payments = noOfPayments,
      payment_interval = Config.FinancePaymentInterval,
      payment_failed = false,
      seconds_to_next_payment = Config.FinancePaymentInterval * 3600,
      seconds_to_repo = 0,
      dealership_id = purchaseData.dealershipId,
      vehicle = purchaseData.model,
      currency = purchaseData.paymentMethod -- Store the currency used for the finance
    }

    -- Convert down payment to the payment currency
    basePriceToPay = baseDownPayment
    currencyAmountToPay = Currencies.Server.ConvertFromBase(baseDownPayment, purchaseData.paymentMethod)
    currencyAmountToPay = Round(currencyAmountToPay)

    local vehiclesOnFinance = MySQL.scalar.await("SELECT COUNT(*) as total FROM " .. Framework.VehiclesTable .. " WHERE financed = 1 AND " .. Framework.PlayerId .. " = ?", {player})
    
    if vehiclesOnFinance >= (Config.MaxFinancedVehiclesPerPlayer or 999999) then
      Framework.Server.Notify(src, Locale.tooManyFinancedVehicles, "error")
      return false
    end

    paymentType = "finance"
    paid = financeData.paid
    owed = financeData.total - financeData.paid
  end

  if currencyAmountToPay > accountBalance then
    DebugPrint(("Insufficient funds - Required: %s, Available: %s (currency: %s)"):format(currencyAmountToPay, accountBalance, purchaseData.paymentMethod), "debug")
    Framework.Server.Notify(src, Locale.errorCannotAffordVehicle, "error")
    return false
  end

  DebugPrint(("Pre-check - Base Amount: %s, Currency Amount: %s, Payment: %s, Financed: %s"):format(basePriceToPay, currencyAmountToPay, purchaseData.paymentMethod, tostring(purchaseData.finance)), "debug")
  
  -- Pre check func in config-sv.lua
  if not PurchaseVehiclePreCheck(src, purchaseData.dealershipId, plate, purchaseData.model, purchaseData.purchaseType, basePriceToPay, purchaseData.paymentMethod, purchaseData.society, purchaseData.societyType, purchaseData.finance, noOfPayments, downPayment, (not not purchaseData.directSaleUuid), pendingSale and pendingSale.dealerPlayerId or nil) then
    DebugPrint(("PurchaseVehiclePreCheck failed for player %s"):format(tostring(src)), "warning")
    return false
  end

  DebugPrint("Pre-check passed, processing payment", "debug")

  -- Remove money (use currency amount for custom currencies, base amount for society funds)
  if purchaseData.purchaseType == "society" and purchaseData.paymentMethod == "societyFund" then
    Framework.Server.RemoveFromSocietyFund(purchaseData.society, purchaseData.societyType, basePriceToPay)
  else
    Framework.Server.PlayerRemoveMoney(src, currencyAmountToPay, purchaseData.paymentMethod)
  end

  if dealership.type == "owned" then
    MySQL.update.await("UPDATE dealership_stock SET stock = stock - 1 WHERE vehicle = ? AND dealership = ?", {purchaseData.model, purchaseData.dealershipId})
    DealershipBalance.Server.Add(purchaseData.dealershipId, basePriceToPay) -- Always add base price to dealership balance
  end
  
  MySQL.insert.await("INSERT INTO dealership_sales (dealership, vehicle, plate, player, seller, purchase_type, paid, owed) VALUES(?, ?, ?, ?, ?, ?, ?, ?)", {purchaseData.dealershipId, purchaseData.model, plate, player, sellerPlayer, paymentType, paid, owed})

  DebugPrint(("Vehicle saved to database - Plate: %s"):format(plate), "debug")

  -- Save vehicle to garage
  local vehicleId = Framework.Server.SaveVehicleToGarage(src, purchaseData.purchaseType, purchaseData.society, purchaseData.societyType, purchaseData.model, plate, purchaseData.finance, financeData)

  DebugPrint(("Vehicle saved to garage - ID: %s"):format(tostring(vehicleId)), "debug")

  local tradeInJournalRow = nil
  local tradeInJournalResponse = nil
  if tradeInSessionId then
    local purchaseReference = tradeInPurchaseReference
    if not purchaseReference then return false end
    tradeInJournalRow = {
      purchase_reference = purchaseReference,
      direct_sale_uuid = purchaseData.directSaleUuid,
      session_id = tradeInSessionId,
      dealership = purchaseData.dealershipId,
      buyer_identifier = player,
      vehicle = tostring(purchaseData.model),
      plate = plate,
      vehicle_id = vehicleId and tostring(vehicleId) or nil,
      payment_method = purchaseData.paymentMethod,
      purchase_type = purchaseData.purchaseType,
      society = purchaseData.society,
      society_type = purchaseData.societyType,
      base_amount = basePriceToPay,
      currency_amount = currencyAmountToPay,
    }
    tradeInJournalResponse = {
      vehicleId = vehicleId,
      plate = plate,
      amountPaid = currencyAmountToPay,
      baseAmountPaid = basePriceToPay,
      tradeInPrepare = tradeInPrepareResult,
      createdAt = os.time(),
    }

    if not vehicleId then
      compensateTradeInPurchase(src, dealership, tradeInJournalRow, tradeInJournalResponse)
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInSettlementFailed, "error")
      return false
    end

    local requestSignature = purchaseReference .. ":" .. tradeInSessionId
    local operation, created = UsedVehiclesIntegration.Server.ClaimOperation(
      purchaseReference,
      "trade_in_purchase",
      requestSignature,
      tradeInJournalRow
    )
    if not operation or not created then
      compensateTradeInPurchase(src, dealership, tradeInJournalRow, tradeInJournalResponse)
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInSettlementPending, "error")
      return false
    end
    local settlingRows = UsedVehiclesIntegration.Server.UpdateOperation(
      purchaseReference,
      "trade_in_purchase",
      requestSignature,
      "settling",
      tradeInJournalResponse,
      nil,
      "pending"
    )
    if settlingRows ~= 1 then
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInSettlementPending, "error")
      return false
    end

    local commitResult = callUsedVehiclesExport(
      "commitUsedTradeIn",
      tradeInSessionId,
      purchaseReference
    )
    tradeInJournalResponse.tradeInCommit = commitResult or {status = "pending"}
    if commitResult and commitResult.status == "failed" then
      compensateTradeInPurchase(src, dealership, tradeInJournalRow, tradeInJournalResponse)
      updateTradeInPurchase(
        purchaseReference,
        "compensated",
        tradeInJournalResponse,
        commitResult.error
      )
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInSettlementFailed, "error")
      return false
    end
    if not commitResult or (commitResult.success ~= true and commitResult.status ~= "completed") then
      updateTradeInPurchase(
        purchaseReference,
        "pending",
        tradeInJournalResponse,
        commitResult and commitResult.error or "trade-in settlement is pending"
      )
      Framework.Server.Notify(src, Locale.usedVehiclesTradeInSettlementPending, "error")
      return false
    end

    updateTradeInPurchase(purchaseReference, "committed", tradeInJournalResponse)
  end

  -- Spawn vehicle on server (if configured)
  local netId = nil
  local properties = {
    plate = plate,
    colour = purchaseData.colour
  }
  Spawn.Server.RegisterPendingStatebags(src, vehicleId or 0, purchaseData.model, plate, properties)

  if Config.SpawnVehiclesWithServerSetter then
    -- For direct sales, don't warp the customer into the vehicle (let them walk to it with the seller)
    local isDirectSale = purchaseData.directSaleUuid ~= nil
    local warp = not Config.DoNotSpawnInsideVehicle and not isDirectSale

    netId = Spawn.Server.Create(src, vehicleId or 0, purchaseData.model, plate, purchaseData.coords, warp, properties, "purchase")
    if not netId or netId == 0 then
      Framework.Server.Notify(src, Locale.couldNotSpawnVehicle, "error") 
      DebugPrint("Could not spawn vehicle with Config.SpawnVehiclesWithServerSetter", "warning")
      netId = nil
    end
  end

  if tradeInJournalRow and tradeInJournalResponse then
    tradeInJournalResponse.netId = netId
    tradeInJournalResponse.completedAt = os.time()
    updateTradeInPurchase(tradeInJournalRow.purchase_reference, "completed", tradeInJournalResponse)
  end

  markDirectSalePurchased(
    purchaseData.directSaleUuid,
    src,
    vehicleId,
    plate,
    currencyAmountToPay,
    purchaseData.paymentMethod,
    netId
  )
  
  -- Record coupon usage if a coupon was applied
  if validatedCoupon then
    DebugPrint(("Recording coupon usage - Coupon ID: %s"):format(validatedCoupon.id), "debug")
    ---@diagnostic disable-next-line: param-type-mismatch
    Coupons.Server.RecordCouponUsage(validatedCoupon.id, player, purchaseData.model, tostring(purchaseData.purchaseType), purchaseData.finance, couponDiscount)
    DebugPrint("Coupon usage recorded successfully", "debug")
  end
  
  -- Send webhook
  local webhookFields = {
    { key = "Vehicle", value = purchaseData.model },
    { key = "Plate", value = plate },
    { key = "Financed", value = purchaseData.finance and "Yes" or "No" },
    { key = "Amount Paid", value = currencyAmountToPay },
    { key = "Payment method", value = purchaseData.paymentMethod },
    { key = "Dealership", value = Locations.Server.GetById(purchaseData.dealershipId)?.name or purchaseData.dealershipId },
    { key = "Seller Name", value = sellerPlayerName or "-" }
  }
  
  if validatedCoupon then
    table.insert(webhookFields, { key = "Coupon Used", value = purchaseData.couponCode })
    table.insert(webhookFields, { key = "Discount Applied", value = couponDiscount })
  end
  
  SendWebhook(src, Webhooks.Purchase, "New Vehicle Purchase", "success", webhookFields)

  -- Update stock level
  Showroom.Server.UpdateVehicleCache(purchaseData.model, purchaseData.dealershipId)

  Framework.Server.Notify(src, Locale.purchaseSuccess, "success")

  DebugPrint(("Purchase completed successfully - Player: %s, Vehicle: %s, Plate: %s"):format(tostring(src), purchaseData.model, plate), "debug")

  return true, netId, vehicleId, plate, currencyAmountToPay
end

lib.callback.register("jg-dealerships:server:purchase-vehicle", function(src, data)
  local lockKey = data and data.directSaleUuid or tostring(src)
  if purchaseLocks[lockKey] then return false end

  purchaseLocks[lockKey] = true
  local results = table.pack(xpcall(function()
    return purchaseVehicle(src, data)
  end, debug.traceback))
  purchaseLocks[lockKey] = nil

  if not results[1] then
    DebugPrint(("Purchase failed unexpectedly: %s"):format(results[2]), "warning")
    return false
  end
  return table.unpack(results, 2, results.n)
end)

lib.callback.register("jg-dealerships:server:validate-coupon", function(src, data)
  local dealershipId, code, vehicleModel, finance = data.dealershipId, data.code, data.vehicleModel, data.isFinanced
  
  -- Get vehicle data to fetch category and price
  local vehicleData = MySQL.single.await([[
    SELECT stock.*, vehicle.category FROM dealership_stock stock
    INNER JOIN dealership_vehicles vehicle ON vehicle.spawn_code = stock.vehicle
    WHERE stock.vehicle = ? AND stock.dealership = ?
  ]], {vehicleModel, dealershipId})
  if not vehicleData then
    return { success = false, error = "Vehicle not found" }
  end
  
  return Coupons.Server.ValidateAndApplyCoupon(src, dealershipId, code, vehicleModel, vehicleData.category, finance, vehicleData.price)
end)

RegisterNetEvent("jg-dealerships:server:update-purchased-vehicle-props", function(purchaseType, society, plate, props)
  local src = source
  local identifier = purchaseType == "society" and society or Framework.Server.GetPlayerIdentifier(src)

  MySQL.update.await("UPDATE " .. Framework.VehiclesTable .. " SET " .. Framework.VehProps .. " = ? WHERE plate = ? AND " .. Framework.PlayerId .. " = ?", {
    json.encode(props), plate, identifier
  })
end)

-- ============================================================================
-- Exports
-- ============================================================================

---@param dealershipId string
---@param limit? integer Max records to return (default 50, max 500)
---@return table[] sales
exports("getSalesHistory", function(dealershipId, limit)
  if type(dealershipId) ~= "string" then return {} end

  limit = tonumber(limit) or 50
  if limit < 1 then limit = 1 end
  if limit > 500 then limit = 500 end

  local sales = MySQL.query.await([[
    SELECT * FROM dealership_sales
    WHERE dealership = ?
    ORDER BY id DESC
    LIMIT ?
  ]], { dealershipId, limit })

  return sales or {}
end)

---@param dealershipId string
---@return number total
exports("getTotalSales", function(dealershipId)
  if type(dealershipId) ~= "string" then return 0 end

  local total = MySQL.scalar.await(
    "SELECT COALESCE(SUM(paid), 0) FROM dealership_sales WHERE dealership = ?",
    { dealershipId }
  )

  return total or 0
end)
