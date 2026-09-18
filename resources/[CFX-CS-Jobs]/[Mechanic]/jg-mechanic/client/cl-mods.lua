local currentMechanicId = nil
local currentMechanicLabel = nil
local modsZoneCount = 0
local isMenuOpen = false
local isPromptShowing = false
local isPromptLoopRunning = false
local currentVehicle = nil
local originalVehicleProps = {}
local vehiclePlate = ""
local isPurchaseFinalized = false
local isDoingBurnout = false
local canTyresBeBurst = true
local isFreecamActive = false
local isHornLoopActive = false
local appliedMods = {
  repair = {},
  performance = {},
  cosmetics = {},
  stance = {},
  respray = {},
  wheels = {},
  neonLights = {},
  headlights = {},
  tyreSmoke = {},
  bulletproofTyres = {},
  extras = {}
}

local function toggleVehicleFreeze(vehicle, shouldFreeze)
  if not vehicle then return end
  SetVehicleEngineOn(vehicle, not shouldFreeze, true, true)
  FreezeEntityPosition(vehicle, shouldFreeze)
  SetEntityCollision(vehicle, not shouldFreeze, not shouldFreeze)
end

local function stopBurnoutPreview()
  if not currentVehicle then return end
  ClearPedTasks(cache.ped)
  SetVehicleTyresCanBurst(currentVehicle, canTyresBeBurst)
  SetVehicleCurrentRpm(currentVehicle, 0)
  FreezeEntityPosition(currentVehicle, true)
  SetEntityCollision(currentVehicle, false, false)
  SetVehicleEngineOn(currentVehicle, false, true, true)
  isDoingBurnout = false
end

local function revertToOriginalMods()
  if not currentVehicle then return end
  if isPurchaseFinalized then return end
  setVehicleProperties(currentVehicle, originalVehicleProps, true)
end

local function getModSlotName(vehicle, modType)
  if type(modType) == "string" then return false end
  local label = GetLabelText(GetModSlotName(vehicle, modType))
  if label ~= "NULL" then
    return label
  end
  local rawName = GetModSlotName(vehicle, modType)
  if rawName and rawName ~= "" then
    return rawName
  end
  return false
end

local function getModName(vehicle, modType, modSlotName, modIndex)
  if modType == "LIVERY" then
    local label = GetLabelText(GetLiveryName(vehicle, modIndex))
    if label ~= "NULL" then
      return label
    end
  end
  if type(modType) == "string" then return "ERROR" end

  local label = GetLabelText(GetModTextLabel(vehicle, modType, modIndex))
  if label ~= "NULL" then
    return label
  end

  local rawLabel = GetModTextLabel(vehicle, modType, modIndex)
  if rawLabel and rawLabel ~= "" then
    return rawLabel
  end

  return (modSlotName or "") .. " " .. (modIndex + 1)
end

local function isModInCameraGroup(modGroup, vehicle, modId)
  for _, mod in ipairs(modGroup) do
    if modId == mod then
      return true
    elseif type(mod) == "string" and type(modId) == "number" then
      local slotName = GetModSlotName(vehicle, modId)
      if slotName == mod then
        return true
      end
    end
  end
  return false
end

local function getAvailableMods(vehicle, originalProps, mechanicId)
  local mechanicConfig = Config.MechanicLocations[mechanicId]
  local allowedMods = mechanicConfig.mods
  if not allowedMods then return false end

  if Config.ModsPricesAsPercentageOfVehicleValue then
    local vehicleValue = Framework.Client.GetVehicleValue(GetEntityArchetypeName(vehicle))
    for modCategory in pairs(allowedMods) do
      local categoryData = allowedMods[modCategory]
      categoryData.price = round(vehicleValue * (categoryData.percentVehVal or 0.01), 0)
    end
  end

  local vehicleModel = GetEntityModel(vehicle)
  SetVehicleModKit(vehicle, 0)
  local performanceMods = {}
  for _, modInfo in pairs(Config.Mods.Performance) do
    local modCount = GetNumVehicleMods(vehicle, modInfo.modType)
    if modCount > 0 or modInfo.toggle then
      local slotName = getModSlotName(vehicle, modInfo.modType) or modInfo.name
      local modsList = { { modIndex = -1, name = "Stock" } }
      if modInfo.overrideOptions and type(modInfo.overrideOptions) == "table" then
        for _, overrideOption in pairs(modInfo.overrideOptions) do
          modsList[#modsList + 1] = {
            modIndex = overrideOption.modIndex,
            name = overrideOption.name,
            price = overrideOption.price or round(allowedMods.performance.price * (1 + overrideOption.modIndex * (allowedMods.performance.priceMult or 0)), 0)
          }
        end
      else
        for i = 0, modCount - 1 do
          modsList[#modsList + 1] = {
            modIndex = i,
            name = getModName(vehicle, modInfo.modType, slotName, i),
            price = round(allowedMods.performance.price * (i > 0 and (1 + i * (allowedMods.performance.priceMult or 0)) or 1), 0)
          }
        end
      end
      performanceMods[#performanceMods + 1] = {
        modType = modInfo.modType,
        name = slotName,
        mods = modsList,
        toggle = modInfo.toggle,
        price = allowedMods.performance.price
      }
    end
  end

  local cosmeticMods = {}
  for _, modInfo in pairs(Config.Mods.Cosmetics) do
    local slotName = modInfo.name
    local ignorePriceMult = modInfo.ignorePriceMult
    local options = {}
    if modInfo.modType == "PLATE_INDEX" then
      if IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel) or IsThisModelABike(vehicleModel) then
        for i = 1, #Config.Mods.PlateIndexes do
          if i < 6 or GetGameBuildNumber() >= 3095 then
            options[#options + 1] = Config.Mods.PlateIndexes[i]
            local price = ignorePriceMult and allowedMods.cosmetics.price or round(allowedMods.cosmetics.price * (i > 0 and (1 + i * (allowedMods.cosmetics.priceMult or 0)) or 1), 0)
            options[i].price = price
          end
        end
      end
    elseif modInfo.modType == "WINDOW_TINT" then
      if not IsThisModelABicycle(vehicleModel) then
        for i = 1, #Config.Mods.WindowTints do
          options[#options + 1] = Config.Mods.WindowTints[i]
          local price = ignorePriceMult and allowedMods.cosmetics.price or round(allowedMods.cosmetics.price * (i > 0 and (1 + i * (allowedMods.cosmetics.priceMult or 0)) or 1), 0)
          options[i].price = price
        end
      end
    else
      local modCount = 0
      if modInfo.modType == "LIVERY" then
        modCount = GetVehicleLiveryCount(vehicle)
      elseif modInfo.modType == "LIVERY_ROOF" then
        modCount = GetVehicleRoofLiveryCount(vehicle)
      else
        modCount = GetNumVehicleMods(vehicle, modInfo.modType)
      end
      if modCount > 0 or modInfo.toggle then
        slotName = getModSlotName(vehicle, modInfo.modType) or slotName or modInfo.name
        if modInfo.modType == 14 then
          for i = 1, #Config.Mods.Horns do
            options[#options + 1] = Config.Mods.Horns[i]
            local price = ignorePriceMult and allowedMods.cosmetics.price or round(allowedMods.cosmetics.price * (i > 0 and (1 + i * (allowedMods.cosmetics.priceMult or 0)) or 1), 0)
            options[i].price = price
          end
        else
          options = { { modIndex = -1, name = "Stock" } }
          for i = 0, modCount - 1 do
            local name = Config.UseCustomNamesInTuningMenu and modInfo.name or getModName(vehicle, modInfo.modType, slotName, i)
            local price = ignorePriceMult and allowedMods.cosmetics.price or round(allowedMods.cosmetics.price * (i > 0 and (1 + i * (allowedMods.cosmetics.priceMult or 0)) or 1), 0)
            options[#options + 1] = {
              modIndex = i,
              name = name,
              price = price
            }
          end
        end
      end
    end

    if #options > 0 then
      local displayName = Config.UseCustomNamesInTuningMenu and modInfo.name or slotName
      cosmeticMods[#cosmeticMods + 1] = {
        modType = modInfo.modType,
        name = displayName,
        mods = options,
        toggle = modInfo.toggle,
        price = allowedMods.cosmetics.price
      }
    end
  end

  local wheelMods = {}
  if IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel) or IsThisModelABike(vehicleModel) then
    for _, wheelType in ipairs(Config.Mods.WheelTypes) do
      local isCorrectVehicleType = (IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel)) or (IsThisModelABike(vehicleModel) and wheelType.modIndex == 6)
      if isCorrectVehicleType then
        SetVehicleWheelType(vehicle, wheelType.modIndex)
        local modCount = GetNumVehicleMods(vehicle, 23)
        if modCount > 0 then
          local options = { { modIndex = -1, name = "Stock" } }
          for i = 0, modCount - 1 do
            options[#options + 1] = {
              modIndex = i,
              name = getModName(vehicle, 23, wheelType.name, i),
              price = round(allowedMods.wheels.price * (i > 0 and (1 + i * (allowedMods.wheels.priceMult or 0)) or 1), 0)
            }
          end
          wheelMods[#wheelMods + 1] = {
            modType = wheelType.modIndex,
            name = wheelType.name,
            mods = options
          }
        end
      end
    end
  end

  SetVehicleWheelType(vehicle, originalProps.wheels)
  if originalProps.modFrontWheels then
    SetVehicleMod(vehicle, 23, originalProps.modFrontWheels, originalProps.modCustomTiresF)
  end
  if originalProps.modBackWheels then
    SetVehicleMod(vehicle, 24, originalProps.modBackWheels, originalProps.modCustomTiresR)
  end

  local modCategories = {}
  if allowedMods.repair and allowedMods.repair.enabled then modCategories.repair = allowedMods.repair end
  if allowedMods.performance and allowedMods.performance.enabled and #performanceMods > 0 then modCategories.performance = performanceMods end
  if allowedMods.cosmetics and allowedMods.cosmetics.enabled and #cosmeticMods > 0 then modCategories.cosmetics = cosmeticMods end
  if IsThisModelACar(vehicleModel) and allowedMods.stance and allowedMods.stance.enabled then modCategories.stance = allowedMods.stance end
  if allowedMods.respray and allowedMods.respray.enabled and #Config.Mods.Colours > 0 then
    modCategories.respray = { price = allowedMods.respray.price, colours = Config.Mods.Colours }
  end
  if allowedMods.wheels and allowedMods.wheels.enabled and #wheelMods > 0 then modCategories.wheels = wheelMods end
  
  -- NUI Lights/Tyres pages always read .enabled on these categories.
  if (IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel)) and allowedMods.neonLights and allowedMods.neonLights.enabled then
    modCategories.neonLights = allowedMods.neonLights
  else
    modCategories.neonLights = { enabled = false, price = 0 }
  end

  if not IsThisModelABicycle(vehicleModel) and allowedMods.headlights and allowedMods.headlights.enabled then
    modCategories.headlights = allowedMods.headlights
  else
    modCategories.headlights = { enabled = false, price = 0 }
  end

  if (IsThisModelACar(vehicleModel) or IsThisModelABike(vehicleModel) or IsThisModelAQuadbike(vehicleModel)) and allowedMods.tyreSmoke and allowedMods.tyreSmoke.enabled then
    modCategories.tyreSmoke = allowedMods.tyreSmoke
  else
    modCategories.tyreSmoke = { enabled = false, price = 0 }
  end
  if (IsThisModelACar(vehicleModel) or IsThisModelABike(vehicleModel) or IsThisModelAQuadbike(vehicleModel)) and allowedMods.bulletproofTyres and allowedMods.bulletproofTyres.enabled then
    modCategories.bulletproofTyres = allowedMods.bulletproofTyres
  else
    modCategories.bulletproofTyres = { enabled = false, price = 0 }
  end

  local extras = originalProps.extras
  if allowedMods.extras and allowedMods.extras.enabled and type(extras) == "table" and next(extras) ~= nil then
    modCategories.extras = allowedMods.extras
  end

  return modCategories
end

function closeModsMenu()
  if currentVehicle then
    Entity(currentVehicle).state:set("inMechanicMenu", false, true)
    Entity(currentVehicle).state:set("realPlate", nil, true)
    pcall(function()
      lib.callback.await("jg-mechanic:server:close-mods-menu", false, VehToNet(currentVehicle))
    end)
    toggleVehicleFreeze(currentVehicle, false)
    revertToOriginalMods()
    Entity(currentVehicle).state:set("unpaidModifications", false, true)
  end
  -- exit-mods used to leave focus/camera on if the generic "close" NUI path never ran
  if exitCamera then exitCamera() end
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  Framework.Client.ToggleHud(true)
  LocalPlayer.state:set("isBusy", false, true)
  appliedMods = {
    repair = {},
    performance = {},
    cosmetics = {},
    stance = {},
    respray = {},
    wheels = {},
    neonLights = {},
    headlights = {},
    tyreSmoke = {},
    bulletproofTyres = {},
    extras = {}
  }
  isMenuOpen = false
  currentVehicle = nil
  originalVehicleProps = nil
  isPurchaseFinalized = false
end

function openModsMenu(mechId, mechLabel)
  local mechanicConfig = Config.MechanicLocations[mechId]
  if not mechanicConfig then return false end

  currentMechanicId = mechId
  if not cache.vehicle then return false end

  currentVehicle = cache.vehicle
  if GetPedInVehicleSeat(currentVehicle, -1) ~= cache.ped then
    Framework.Client.Notify(Locale.notInDriversSeat, "error")
    currentVehicle = nil
    return false
  end

  local health = {
    GetVehicleBodyHealth(currentVehicle),
    GetVehicleEngineHealth(currentVehicle)
  }

  local props = getVehicleProperties(currentVehicle, true)
  if not props then error("Could not get the vehicle's props") end
  originalVehicleProps = props

  local plate = Framework.Client.GetPlate(currentVehicle)
  if not plate then error("Could not get the vehicle's plate") end
  vehiclePlate = plate

  canTyresBeBurst = not props.bulletProofTyres
  props.windowTint = math.max(props.windowTint, 0)

  local mods = getAvailableMods(currentVehicle, props, mechId)
  if not mods then return false end

  for i = 0, 5 do
    if GetPedInVehicleSeat(currentVehicle, i) ~= 0 then
      Framework.Client.Notify(Locale.passengersMustLeaveVehicleFirst, "error")
      currentVehicle = nil
      return false
    end
  end

  -- Resolve employee/type/balance BEFORE freezing the vehicle.
  -- Previously employees awaited society balance after freeze; a hanging
  -- esx_society/addonaccount promise left players stuck with no UI (common on ESX).
  local isMechanicEmployee = lib.callback.await("jg-mechanic:server:is-mechanic-employee", false, mechId)
  local mechanicType = mechanicConfig.type ~= "self-service" and not (Config.MechanicEmployeesCanSelfServiceMods and isMechanicEmployee) and "owned" or "self-service"
  local mechanicBalance = false
  if isMechanicEmployee and mechanicType == "self-service" then
    mechanicBalance = lib.callback.await("jg-mechanic:server:get-mechanic-balance", false, mechId) or false
  end
  local mechanicsOnDuty = lib.callback.await("jg-mechanic:server:count-currently-on-duty", false, mechId)

  toggleVehicleFreeze(currentVehicle, true)
  SetVehicleModKit(currentVehicle, 0)
  setupVehicleCamera(currentVehicle)

  Entity(currentVehicle).state:set("inMechanicMenu", { originalPlate = vehiclePlate }, true)
  Entity(currentVehicle).state:set("realPlate", vehiclePlate, true)
  lib.callback.await("jg-mechanic:server:open-mods-menu", false, VehToNet(currentVehicle), vehiclePlate)


  LocalPlayer.state:set("isBusy", true, true)
  Framework.Client.ToggleHud(false)
  SetNuiFocus(true, true)

  SendNUIMessage({
    type = "show-vehicle-tuning",
    logo = mechanicConfig.logo,
    mechanicId = mechId,
    name = mechLabel or (mechLabel == "" and mechId or mechLabel),
    mechanicType = mechanicType,
    mechanicsOnDuty = mechanicsOnDuty,
    isMechanicEmployee = isMechanicEmployee,
    mechBalance = mechanicBalance,
    bankBalance = Framework.Client.GetBalance("bank"),
    cashBalance = Framework.Client.GetBalance("cash"),
    changeCamBtn = parseControlBinding(0),
    vehicleDamaged = health,
    props = props,
    mods = mods,
    config = Config,
    locale = Locale
  })

  return true
end

RegisterNetEvent("jg-mechanic:client:open-customisation-menu", openModsMenu)

--- True if player is still near any bay for the current mechanic (safety vs stuck zone count).
local function isNearCurrentMechanicBay()
  if not currentMechanicId then return false end
  local mechanicConfig = Config.MechanicLocations[currentMechanicId]
  if not mechanicConfig or not mechanicConfig.locations then return false end

  local playerCoords = GetEntityCoords(cache.ped)
  for i = 1, #mechanicConfig.locations do
    local location = mechanicConfig.locations[i]
    local size = location.size or 7.0
    -- Box zone half-extent is size/2 on each axis; use size as a forgiving radius
    if #(playerCoords - location.coords) <= size then
      return true
    end
  end
  return false
end

local function startModsPromptLoop()
  if isPromptLoopRunning then return end
  isPromptLoopRunning = true

  CreateThread(function()
    local farTicks = 0

    while modsZoneCount > 0 and currentMechanicId do
      -- Zone refresh / teleport can leave modsZoneCount stuck; never show off-site
      if not isNearCurrentMechanicBay() then
        farTicks += 1
        if isPromptShowing then
          Framework.Client.HideTextUI()
          isPromptShowing = false
        end
        -- Self-heal stuck ref-count after ~2s away from every bay
        if farTicks >= 8 then
          modsZoneCount = 0
          currentMechanicId = nil
          currentMechanicLabel = nil
          break
        end
        Wait(250)
      elseif isMenuOpen then
        farTicks = 0
        Wait(250)
      elseif cache.vehicle then
        farTicks = 0
        if not isPromptShowing then
          Framework.Client.ShowTextUI(Config.CustomiseVehiclePrompt)
          isPromptShowing = true
        end

        -- Must poll every frame; IsControlJustPressed is only true for 1 tick
        if IsControlJustPressed(0, Config.CustomiseVehicleKey)
          or IsDisabledControlJustPressed(0, Config.CustomiseVehicleKey)
        then
          local mechId, mechLabel = currentMechanicId, currentMechanicLabel
          if openModsMenu(mechId, mechLabel) then
            isMenuOpen = true
            isPromptShowing = false
            Framework.Client.HideTextUI()
          end
        end
        Wait(0)
      else
        farTicks = 0
        if isPromptShowing then
          Framework.Client.HideTextUI()
          isPromptShowing = false
        end
        Wait(200)
      end
    end

    isPromptLoopRunning = false
    if isPromptShowing then
      Framework.Client.HideTextUI()
      isPromptShowing = false
    end
  end)
end

-- Ref-count overlapping bay zones so leaving one bay does not kill the prompt
-- while the player is still inside another nearby location.
onEnterModsZone = function(mechId, mechLabel)
  modsZoneCount += 1
  currentMechanicId = mechId
  currentMechanicLabel = mechLabel
  startModsPromptLoop()
end

onExitModsZone = function()
  modsZoneCount = math.max(0, modsZoneCount - 1)
  if modsZoneCount > 0 then return end

  currentMechanicId = nil
  currentMechanicLabel = nil
  closeModsMenu()
  SetTimeout(1, function()
    if modsZoneCount <= 0 then
      Framework.Client.HideTextUI()
      isPromptShowing = false
    end
  end)
end

--- Called when mechanic zones are rebuilt (e.g. mechanicadmin set owner).
--- zone:remove() does not always fire onExit, which left the TextUI stuck city-wide.
resetModsZoneState = function()
  modsZoneCount = 0
  currentMechanicId = nil
  currentMechanicLabel = nil
  isPromptShowing = false
  Framework.Client.HideTextUI()
end

RegisterNUICallback("purchase-mods", function(data, cb)
  if not (currentMechanicId and currentVehicle and originalVehicleProps and currentVehicle) then
    return cb({ error = true })
  end

  local cart = data.cart
  local paymentMethod = data.paymentMethod
  if not cart or type(cart) ~= "table" then
    return cb({ error = true })
  end

  local mechanicConfig = Config.MechanicLocations[currentMechanicId]
  if not mechanicConfig then
    return cb({ error = false })
  end

  local currentProps = getVehicleProperties(currentVehicle, true)
  currentProps.plate = vehiclePlate
  if not currentProps then
    return cb({ error = false })
  end

  local vehicleValue = Framework.Client.GetVehicleValue(GetEntityArchetypeName(currentVehicle))
  local amountPaid = lib.callback.await("jg-mechanic:server:purchase-mods", false, currentMechanicId, vehicleValue, cart, paymentMethod)

  if amountPaid == false then
    return cb({ error = true })
  end

  amountPaid = tonumber(amountPaid) or 0

  local isMechanicEmployee = lib.callback.await("jg-mechanic:server:is-mechanic-employee", false, currentMechanicId)
  if mechanicConfig.type == "self-service" or (Config.MechanicEmployeesCanSelfServiceMods and isMechanicEmployee) then
    toggleVehicleFreeze(currentVehicle, false)
    local combinedMods = {}
    for _, category in pairs(appliedMods) do
      combinedMods = tableConcat(combinedMods, category)
    end
    setStatebagsFromProps(currentVehicle, combinedMods, vehiclePlate)
    lib.callback.await("jg-mechanic:server:save-veh-statebag-data-to-db", false, vehiclePlate)
    isPurchaseFinalized = true
    lib.callback.await("jg-mechanic:server:self-service-mods-applied", false, currentMechanicId, VehToNet(currentVehicle), vehiclePlate, cart, amountPaid, paymentMethod)
    if Config.UpdatePropsOnChange then
      lib.callback.await("jg-mechanic:server:save-vehicle-props", false, vehiclePlate, currentProps)
    end
    if originalVehicleProps and currentProps then
      originalVehicleProps.wheels = currentProps.wheels
      originalVehicleProps.modFrontWheels = currentProps.modFrontWheels
      originalVehicleProps.modBackWheels = currentProps.modBackWheels
    end
  else
    local orderPlaced = lib.callback.await("jg-mechanic:server:place-order", false, currentMechanicId, vehiclePlate, cart, amountPaid, appliedMods, paymentMethod)
    if not orderPlaced then
      return cb({ error = true })
    end
  end

  cb(true)
end)

RegisterNUICallback("exit-mods", function(data, cb)
  closeModsMenu()
  cb(true)
end)

RegisterNUICallback("switch-camera", function(data, cb)
  if not currentVehicle then return cb(false) end
  local modId = data and data.modId
  CreateThread(function()
    SetVehicleDoorsShut(currentVehicle, true)
    if IsVehicleDoorDamaged(currentVehicle, 4) then
      SetVehicleFixed(currentVehicle)
    end
    stopBurnoutPreview()
    if isModInCameraGroup({ "TOP_HL_CV", "TOP_HLT", "TOP_SUNST", "HEADLIGHTS", "TOP_SPLIT" }, currentVehicle, modId) then
      transitionCamera("frontCamera")
    elseif isModInCameraGroup({ "TOP_TRUNK", "TOP_BOOT", "TOP_TGATE", "TOP_RPNL", "TOP_WINP", "TOP_WBAR", "TOP_COVER", "TOP_LOUV" }, currentVehicle, modId) then
      transitionCamera("backCamera")
    elseif isModInCameraGroup({ "TOP_CAGE" }, currentVehicle, modId) then
      transitionCamera("interior")
    elseif isModInCameraGroup({ "TOP_ROOFSC", "TOP_ROOFFIN" }, currentVehicle, modId) then
      transitionCamera("roof")
    elseif isModInCameraGroup({ "TOP_VALHD", "TOP_ENGHD" }, currentVehicle, modId) then
      transitionCamera("backCamera")
      SetVehicleDoorOpen(currentVehicle, 4, false, true)
    elseif isModInCameraGroup({ "TOP_SIDE_PAN", "TOP_MIR" }, currentVehicle, modId) then
      transitionCamera("sideCamera")
    elseif isModInCameraGroup({ "TOP_CATCH" }, currentVehicle, modId) then
      transitionCamera("engineBay")
    elseif isModInCameraGroup({ "TOP_ENGINE", "TOP_BRACE", "TOP_ENGD" }, currentVehicle, modId) then
      transitionCamera("engineBay")
      if GetEntityArchetypeName(currentVehicle) == "z190" then
        SetVehicleDoorBroken(currentVehicle, 4, true)
      end
      SetVehicleDoorOpen(currentVehicle, 4, false, true)
    elseif isModInCameraGroup({ 1, 6, 26, 42, 43 }, currentVehicle, modId) then
      transitionCamera("frontCamera")
    elseif isModInCameraGroup({ 37 }, currentVehicle, modId) then
      transitionCamera("backCamera")
      SetVehicleDoorOpen(currentVehicle, 5, false, true)
    elseif isModInCameraGroup({ 5, 27, 32, "COLOR_INTERIOR" }, currentVehicle, modId) then
      transitionCamera("interior")
    elseif isModInCameraGroup({ 4 }, currentVehicle, modId) then
      transitionCamera("exhaust")
    elseif isModInCameraGroup({ 0, 2, 4, 25, "PLATE_INDEX" }, currentVehicle, modId) then
      transitionCamera("backCamera")
    elseif isModInCameraGroup({ 3, 8, 23, 24, "WHEELS" }, currentVehicle, modId) then
      transitionCamera("sideCamera")
    elseif isModInCameraGroup({ 7 }, currentVehicle, modId) then
      transitionCamera("engineBay")
    elseif isModInCameraGroup({ 39, 40, 41 }, currentVehicle, modId) then
      transitionCamera("engineBay")
      if GetEntityArchetypeName(currentVehicle) == "banshee2" then
        SetVehicleDoorBroken(currentVehicle, 4, true)
      end
      SetVehicleDoorOpen(currentVehicle, 4, false, true)
    elseif isModInCameraGroup({ 31 }, currentVehicle, modId) then
      transitionCamera("doorSpeaker")
    elseif isModInCameraGroup({ 28, 29, 30, 33, 34, "COLOR_DASHBOARD" }, currentVehicle, modId) then
      transitionCamera("pov")
    else
      transitionCamera("default")
    end
    cb(true)
  end)
end)

RegisterNUICallback("toggle-freecam", function(data, cb)
  if data.enable then
    isFreecamActive = true
    toggleCamTemporarily(false)
  else
    toggleCamTemporarily(true)
    isFreecamActive = false
  end
  cb(true)
end)

RegisterNUICallback("move-freecam", function(data, cb)
  if not isFreecamActive then return cb(false) end
  SetNuiFocus(true, false)
  SetNuiFocusKeepInput(true)
  CreateThread(function()
    while isFreecamActive do
      DisableAllControlActions(0)
      EnableControlAction(0, 0, false)
      EnableControlAction(0, 1, true)
      EnableControlAction(0, 2, true)
      EnableControlAction(0, 59, true)
      Wait(0)
    end
  end)
  cb(true)
end)

RegisterNUICallback("stop-moving-freecam", function(data, cb)
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(false)
  cb(true)
end)

RegisterNUICallback("repair-vehicle", function(data, cb)
  if not (currentVehicle and currentVehicle) then
    return cb(false)
  end

  local vehicleValue = Framework.Client.GetVehicleValue(GetEntityArchetypeName(currentVehicle))
  local success = lib.callback.await("jg-mechanic:server:self-service-repair-vehicle", false, currentMechanicId, vehicleValue, data and data.paymentMethod)
  if success then
    Framework.Client.RepairVehicle(currentVehicle)
    if originalVehicleProps then
      originalVehicleProps.dirtLevel = 0.0
      originalVehicleProps.engineHealth = 1000.0
      originalVehicleProps.bodyHealth = 1000.0
      originalVehicleProps.tankHealth = 1000.0
      originalVehicleProps.windowStatus = nil
      originalVehicleProps.doorStatus = nil
      originalVehicleProps.tireHealth = nil
      originalVehicleProps.tireBurstState = nil
      originalVehicleProps.tireBurstCompletely = nil
      originalVehicleProps.windowsBroken = nil
      originalVehicleProps.doorsBroken = nil
      originalVehicleProps.tyreBurst = nil
    end
  end
  cb(true)
end)

RegisterNUICallback("preview-performance-mod", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  local propKey = data.propKey
  local modType = data.modType
  local modIndex = data.modIndex
  local toggleMod = data.toggleMod
  SetVehicleModKit(currentVehicle, 0)
  if toggleMod then
    ToggleVehicleMod(currentVehicle, modType, modIndex)
    appliedMods.performance[propKey] = modIndex
  elseif type(modType) == "number" then
    SetVehicleMod(currentVehicle, modType, modIndex, false)
    appliedMods.performance[propKey] = modIndex
  end
  cb(true)
end)

RegisterNUICallback("preview-cosmetic-mod", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  local propKey = data.propKey
  local modType = data.modType
  local modIndex = data.modIndex
  local toggleMod = data.toggleMod
  SetVehicleModKit(currentVehicle, 0)
  if modType == "LIVERY" then
    SetVehicleLivery(currentVehicle, modIndex)
  elseif modType == "LIVERY_ROOF" then
    SetVehicleRoofLivery(currentVehicle, modIndex)
  elseif modType == "PLATE_INDEX" then
    SetVehicleNumberPlateTextIndex(currentVehicle, modIndex)
  elseif modType == "WINDOW_TINT" then
    SetVehicleWindowTint(currentVehicle, modIndex)
  elseif modType == 14 then
    SetVehicleMod(currentVehicle, 14, modIndex, false)
    Citizen.CreateThreadNow(function()
      if isHornLoopActive then
        isHornLoopActive = false
        Wait(10)
      end
      isHornLoopActive = true
      local duration = Config.Mods.Horns[modIndex + 2].musical and 750 or 100
      while duration > 1 do
        if not isHornLoopActive then break end
        SetControlNormal(0, 86, 1.0)
        Wait(1)
        duration = duration - 1
      end
    end)
  elseif toggleMod then
    ToggleVehicleMod(currentVehicle, modType, modIndex)
  elseif type(modType) == "number" then
    SetVehicleMod(currentVehicle, modType, modIndex, false)
  end
  appliedMods.cosmetics[propKey] = modIndex
  cb(true)
end)

RegisterNUICallback("preview-wheels", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  SetVehicleModKit(currentVehicle, 0)
  SetVehicleWheelType(currentVehicle, data.modType)
  appliedMods.wheels.wheels = data.modType
  SetVehicleMod(currentVehicle, 23, data.modIndex, false)
  appliedMods.wheels.modFrontWheels = data.modIndex
  if IsThisModelABike(GetEntityModel(currentVehicle)) then
    SetVehicleMod(currentVehicle, 24, data.modIndex, false)
    appliedMods.wheels.modBackWheels = data.modIndex
  end
  appliedMods.wheels.wheelWidth = GetVehicleWheelWidth(currentVehicle)
  appliedMods.wheels.wheelSize = GetVehicleWheelSize(currentVehicle)
  cb(true)
end)

RegisterNUICallback("preview-pri-sec-colours", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  SetVehicleModKit(currentVehicle, 0)
  Entity(currentVehicle).state:set("primarySecondarySync", data.primarySecondarySync)
  appliedMods.respray.primarySecondarySync = data.primarySecondarySync
  if data.paintTypeKey == "paintType1" then
    if data.enableRgb then
      SetVehicleModColor_1(currentVehicle, data.paint, 0, 0)
      SetVehicleCustomPrimaryColour(currentVehicle, data.rgbColour[1], data.rgbColour[2], data.rgbColour[3])
      appliedMods.respray.color1 = data.rgbColour
    else
      local _, sec = GetVehicleColours(currentVehicle)
      SetVehicleColours(currentVehicle, data.colourId, sec)
      ClearVehicleCustomPrimaryColour(currentVehicle)
      appliedMods.respray.color1 = data.colourId
    end
    appliedMods.respray.paintType1 = data.paint
  end
  if data.paintTypeKey == "paintType2" or data.primarySecondarySync then
    if data.enableRgb then
      SetVehicleModColor_2(currentVehicle, data.paint, 0)
      SetVehicleCustomSecondaryColour(currentVehicle, data.rgbColour[1], data.rgbColour[2], data.rgbColour[3])
      appliedMods.respray.color2 = data.rgbColour
    else
      local pri, _ = GetVehicleColours(currentVehicle)
      SetVehicleColours(currentVehicle, pri, data.colourId)
      ClearVehicleCustomSecondaryColour(currentVehicle)
      appliedMods.respray.color2 = data.colourId
    end
    appliedMods.respray.paintType2 = data.paint
  end
  cb(true)
end)

RegisterNUICallback("preview-other-colours", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  SetVehicleModKit(currentVehicle, 0)
  if data.colourIdKey == "dashboardColor" then
    SetVehicleDashboardColor(currentVehicle, data.colourId)
  elseif data.colourIdKey == "interiorColor" then
    SetVehicleInteriorColor(currentVehicle, data.colourId)
  else
    local pearl, wheel = GetVehicleExtraColours(currentVehicle)
    if data.colourIdKey == "pearlescentColor" then
      SetVehicleExtraColours(currentVehicle, data.colourId, wheel)
      local disablePearl = data.disablePearl or false
      Entity(currentVehicle).state:set("disablePearl", disablePearl)
      appliedMods.respray.disablePearl = disablePearl
    end
    if data.colourIdKey == "wheelColor" then
      SetVehicleExtraColours(currentVehicle, pearl, data.colourId)
    end
  end
  appliedMods.respray[data.colourIdKey] = data.colourId
  cb(true)
end)

RegisterNUICallback("preview-xenons", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  SetVehicleModKit(currentVehicle, 0)
  ToggleVehicleMod(currentVehicle, 22, data.enableXenons)
  SetVehicleLights(currentVehicle, 2)
  SetVehicleXenonLightsColor(currentVehicle, data.xenonColor)
  appliedMods.headlights.modXenon = true
  appliedMods.headlights.xenonColor = data.xenonColor
  cb(true)
end)

RegisterNUICallback("preview-neons", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  SetVehicleModKit(currentVehicle, 0)
  for i = 0, 3 do
    SetVehicleNeonLightEnabled(currentVehicle, i, data.enableNeons[i + 1])
  end
  SetVehicleNeonLightsColour(currentVehicle, data.neonColor[1], data.neonColor[2], data.neonColor[3])
  appliedMods.neonLights.neonEnabled = data.enableNeons
  appliedMods.neonLights.neonColor = data.neonColor
  cb(true)
end)

RegisterNUICallback("preview-tyre-smoke", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  if isDoingBurnout and not data.enableTyreSmoke then
    stopBurnoutPreview()
  end
  if not isDoingBurnout and data.enableTyreSmoke then
    CreateThread(function()
      isDoingBurnout = true
      if canTyresBeBurst then
        SetVehicleTyresCanBurst(currentVehicle, false)
      end
      SetVehicleEngineOn(currentVehicle, true, true, true)
      SetEntityCollision(currentVehicle, true, true)
      FreezeEntityPosition(currentVehicle, false)
      TaskVehicleTempAction(cache.ped, currentVehicle, 30, 999999)
    end)
  end
  SetVehicleModKit(currentVehicle, 0)
  ToggleVehicleMod(currentVehicle, 20, data.enableTyreSmoke)
  SetVehicleTyreSmokeColor(currentVehicle, data.tyreSmokeColor[1], data.tyreSmokeColor[2], data.tyreSmokeColor[3])
  appliedMods.tyreSmoke.modSmokeEnabled = data.enableTyreSmoke
  appliedMods.tyreSmoke.tyreSmokeColor = data.tyreSmokeColor
  cb(true)
end)

RegisterNUICallback("preview-bulletproof-tyres", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  local canBurst = not data.enableBulletproofTyres
  SetVehicleTyresCanBurst(currentVehicle, canBurst)
  canTyresBeBurst = canBurst
  appliedMods.bulletproofTyres.bulletProofTyres = data.enableBulletproofTyres
  cb(true)
end)

RegisterNUICallback("preview-extras", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  for extraId, enabled in pairs(data.extras) do
    SetVehicleExtra(currentVehicle, tonumber(extraId), not enabled)
  end
  appliedMods.extras.extras = data.extras
  cb(true)
end)

RegisterNUICallback("preview-stance", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  previewVehicleStance(currentVehicle, data.enableStance, data.defaultStance, data.stance)
  PreviewingNewStance = true
  cb(true)
end)

RegisterNUICallback("save-previewed-stance", function(data, cb)
  if not currentVehicle then return cb(false) end
  Entity(currentVehicle).state:set("unpaidModifications", true, true)
  setStanceState(currentVehicle, data.enableStance, data.wheelsAdjIndv, data.defaultStance, data.stance)
  PreviewingNewStance = false
  appliedMods.stance.enableStance = data.enableStance
  appliedMods.stance.wheelsAdjIndv = data.wheelsAdjIndv
  appliedMods.stance.defaultStance = data.defaultStance
  appliedMods.stance.stance = data.stance
  cb(true)
end)

AddEventHandler("onResourceStop", function(resourceName)
  if GetCurrentResourceName() == resourceName then
    if currentVehicle then
      revertToOriginalMods()
      Entity(currentVehicle).state:set("unpaidModifications", false, true)
      toggleVehicleFreeze(currentVehicle, false)
    end
  end
end)
