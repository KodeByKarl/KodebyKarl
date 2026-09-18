local function retrieveAndApplyVehicleStatebagData(vehicle, plate)
  local state = Entity(vehicle).state
  local defaultStance, baseHandling = getVehicleDefaultStance(vehicle), getBaseVehicleHandling(vehicle)

  if not state.defaultStance then
    state:set("defaultStance", defaultStance, true)
  end
  if not state.baseHandling then
    state:set("baseHandling", baseHandling, true)
  end

  lib.callback.await("jg-mechanic:server:retrieve-and-apply-veh-statebag-data", false, VehToNet(vehicle), plate)
end

function getVehicleProperties(vehicle, withStatebags)
  if not DoesEntityExist(vehicle) then return false end

  local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
  local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
  local paintType1 = GetVehicleModColor_1(vehicle)
  local paintType2 = GetVehicleModColor_2(vehicle)

  if GetIsVehiclePrimaryColourCustom(vehicle) then
    colorPrimary = { GetVehicleCustomPrimaryColour(vehicle) }
  end

  if GetIsVehicleSecondaryColourCustom(vehicle) then
    colorSecondary = { GetVehicleCustomSecondaryColour(vehicle) }
  end

  local extras = {}
  for extraId = 1, 15 do
    if DoesExtraExist(vehicle, extraId) then
      extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
    end
  end

  local modLiveryCount = GetVehicleLiveryCount(vehicle)
  local modLivery = GetVehicleLivery(vehicle)

  if modLiveryCount == -1 or modLivery == -1 then
    modLivery = GetVehicleMod(vehicle, 48)
  end

  local tireHealth = {}
  for i = 0, 3 do
    tireHealth[i] = GetVehicleWheelHealth(vehicle, i)
  end

  local tireBurstState = {}
  for i = 0, 5 do
    tireBurstState[i] = IsVehicleTyreBurst(vehicle, i, false)
  end

  local tireBurstCompletely = {}
  for i = 0, 5 do
    tireBurstCompletely[i] = IsVehicleTyreBurst(vehicle, i, true)
  end

  local windowStatus = {}
  for i = 0, 7 do
    windowStatus[i] = IsVehicleWindowIntact(vehicle, i) == 1
  end

  local doorStatus = {}
  for i = 0, 5 do
    doorStatus[i] = IsVehicleDoorDamaged(vehicle, i) == 1
  end

  local neons = {}
  for i = 0, 3 do
    neons[i + 1] = IsVehicleNeonLightEnabled(vehicle, i)
  end

  local xenonCustomColor = {}
  local xenonCustomColorEnabled, x_red, x_green, x_blue = GetVehicleXenonLightsCustomColor(vehicle)
  if xenonCustomColorEnabled then
    xenonCustomColor = { x_red, x_green, x_blue }
  end

  local hasCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(vehicle)
  local customPrimaryColor = nil
  if hasCustomPrimaryColor then
    customPrimaryColor = { GetVehicleCustomPrimaryColour(vehicle) }
  end

  local hasCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(vehicle)
  local customSecondaryColor = nil
  if hasCustomSecondaryColor then
    customSecondaryColor = { GetVehicleCustomSecondaryColour(vehicle) }
  end

  local hasCustomXenonColor, customXenonColorR, customXenonColorG, customXenonColorB = GetVehicleXenonLightsCustomColor(vehicle)
  local customXenonColor = nil
  if hasCustomXenonColor then
    customXenonColor = { customXenonColorR, customXenonColorG, customXenonColorB }
  end

  local doorsBroken, windowsBroken, tyreBurst = {}, {}, {}
  local numWheels = tostring(GetVehicleNumberOfWheels(vehicle))

  local tyresIndex = {
    ["2"] = { 0, 4 },
    ["3"] = { 0, 1, 4, 5 },
    ["4"] = { 0, 1, 4, 5 },
    ["6"] = { 0, 1, 2, 3, 4, 5 },
  }

  if tyresIndex[numWheels] then
    for _, idx in pairs(tyresIndex[numWheels]) do
      tyreBurst[tostring(idx)] = IsVehicleTyreBurst(vehicle, idx, false)
    end
  end

  for windowId = 0, 7 do
    windowsBroken[tostring(windowId)] = not IsVehicleWindowIntact(vehicle, windowId)
  end

  local numDoors = GetNumberOfVehicleDoors(vehicle)
  if numDoors and numDoors > 0 then
    for doorsId = 0, numDoors do
      doorsBroken[tostring(doorsId)] = IsVehicleDoorDamaged(vehicle, doorsId)
    end
  end

  local props = {
    model = GetEntityModel(vehicle),
    plate = GetVehicleNumberPlateText(vehicle),
    plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
    bodyHealth = math.floor(GetVehicleBodyHealth(vehicle) + 0.5) + 0.0,
    engineHealth = math.floor(GetVehicleEngineHealth(vehicle) + 0.5) + 0.0,
    tankHealth = math.floor(GetVehiclePetrolTankHealth(vehicle) + 0.5) + 0.0,
    fuelLevel = math.floor(GetVehicleFuelLevel(vehicle) + 0.5) + 0.0,
    oilLevel = math.floor(GetVehicleOilLevel(vehicle) + 0.5) + 0.0,
    dirtLevel = math.floor(GetVehicleDirtLevel(vehicle) + 0.5) + 0.0,
    paintType1 = paintType1,
    paintType2 = paintType2,
    color1 = colorPrimary,
    color2 = colorSecondary,
    pearlescentColor = pearlescentColor,
    interiorColor = GetVehicleInteriorColor(vehicle),
    dashboardColor = GetVehicleDashboardColour(vehicle),
    wheelColor = wheelColor,
    wheelWidth = GetVehicleWheelWidth(vehicle),
    wheelSize = GetVehicleWheelSize(vehicle),
    wheels = GetVehicleWheelType(vehicle),
    tireHealth = tireHealth,
    tireBurstState = tireBurstState,
    tireBurstCompletely = tireBurstCompletely,
    windowTint = GetVehicleWindowTint(vehicle),
    windowStatus = windowStatus,
    doorStatus = doorStatus,
    xenonColor = GetVehicleXenonLightsColor(vehicle),
    neonEnabled = neons,
    neonColor = { GetVehicleNeonLightsColour(vehicle) },
    extras = extras,
    tyreSmokeColor = { GetVehicleTyreSmokeColor(vehicle) },
    modSpoilers = GetVehicleMod(vehicle, 0),
    modFrontBumper = GetVehicleMod(vehicle, 1),
    modRearBumper = GetVehicleMod(vehicle, 2),
    modSideSkirt = GetVehicleMod(vehicle, 3),
    modExhaust = GetVehicleMod(vehicle, 4),
    modFrame = GetVehicleMod(vehicle, 5),
    modGrille = GetVehicleMod(vehicle, 6),
    modHood = GetVehicleMod(vehicle, 7),
    modFender = GetVehicleMod(vehicle, 8),
    modRightFender = GetVehicleMod(vehicle, 9),
    modRoof = GetVehicleMod(vehicle, 10),
    modEngine = GetVehicleMod(vehicle, 11),
    modBrakes = GetVehicleMod(vehicle, 12),
    modTransmission = GetVehicleMod(vehicle, 13),
    modHorns = GetVehicleMod(vehicle, 14),
    modSuspension = GetVehicleMod(vehicle, 15),
    modArmor = GetVehicleMod(vehicle, 16),
    modNitrous = GetVehicleMod(vehicle, 17),
    modTurbo = IsToggleModOn(vehicle, 18),
    modSubwoofer = GetVehicleMod(vehicle, 19),
    modSmokeEnabled = IsToggleModOn(vehicle, 20),
    modHydraulics = IsToggleModOn(vehicle, 21),
    modXenon = IsToggleModOn(vehicle, 22),
    modFrontWheels = GetVehicleMod(vehicle, 23),
    modBackWheels = GetVehicleMod(vehicle, 24),
    modCustomTiresF = GetVehicleModVariation(vehicle, 23),
    modCustomTiresR = GetVehicleModVariation(vehicle, 24),
    modPlateHolder = GetVehicleMod(vehicle, 25),
    modVanityPlate = GetVehicleMod(vehicle, 26),
    modTrimA = GetVehicleMod(vehicle, 27),
    modOrnaments = GetVehicleMod(vehicle, 28),
    modDashboard = GetVehicleMod(vehicle, 29),
    modDial = GetVehicleMod(vehicle, 30),
    modDoorSpeaker = GetVehicleMod(vehicle, 31),
    modSeats = GetVehicleMod(vehicle, 32),
    modSteeringWheel = GetVehicleMod(vehicle, 33),
    modShifterLeavers = GetVehicleMod(vehicle, 34),
    modAPlate = GetVehicleMod(vehicle, 35),
    modSpeakers = GetVehicleMod(vehicle, 36),
    modTrunk = GetVehicleMod(vehicle, 37),
    modHydrolic = GetVehicleMod(vehicle, 38),
    modEngineBlock = GetVehicleMod(vehicle, 39),
    modAirFilter = GetVehicleMod(vehicle, 40),
    modStruts = GetVehicleMod(vehicle, 41),
    modArchCover = GetVehicleMod(vehicle, 42),
    modAerials = GetVehicleMod(vehicle, 43),
    modTrimB = GetVehicleMod(vehicle, 44),
    modTank = GetVehicleMod(vehicle, 45),
    modWindows = GetVehicleMod(vehicle, 46),
    modDoorR = GetVehicleMod(vehicle, 47),
    modLivery = modLivery,
    modRoofLivery = GetVehicleRoofLivery(vehicle),
    modLightbar = GetVehicleMod(vehicle, 49),
    bulletProofTyres = not GetVehicleTyresCanBurst(vehicle),
    driftTyres = GetGameBuildNumber() >= 2372 and GetDriftTyresEnabled(vehicle),
    xenonCustomColorEnabled = xenonCustomColorEnabled,
    xenonCustomColor = xenonCustomColor,
    doorsBroken = doorsBroken,
    windowsBroken = windowsBroken,
    tyreBurst = tyreBurst,
    tyresCanBurst = GetVehicleTyresCanBurst(vehicle),
    customPrimaryColor = customPrimaryColor,
    customSecondaryColor = customSecondaryColor,
    customXenonColor = customXenonColor,
    modCustomFrontWheels = GetVehicleModVariation(vehicle, 23),
    modCustomBackWheels = GetVehicleModVariation(vehicle, 24),
    modKit17 = GetVehicleMod(vehicle, 17),
    modKit19 = GetVehicleMod(vehicle, 19),
    modKit21 = GetVehicleMod(vehicle, 21),
    modKit47 = GetVehicleMod(vehicle, 47),
    modKit49 = GetVehicleMod(vehicle, 49),
    liveryRoof = GetVehicleRoofLivery(vehicle),
  }

  if withStatebags then
    local statebag = Entity(vehicle).state
    local statebagProps = {
      primarySecondarySync = statebag.primarySecondarySync,
      disablePearl = statebag.disablePearl,
      enableStance = statebag.enableStance or false,
      wheelsAdjIndv = statebag.wheelsAdjIndv or false,
      defaultStance = statebag.defaultStance or getVehicleDefaultStance(vehicle),
      stance = statebag.stance or getVehicleDefaultStance(vehicle),
      lcInstalled = statebag.lightingControllerInstalled,
      lcXenons = statebag.xenons,
      lcUnderglowDirections = statebag.underglowDirections,
      lcUnderglow = statebag.underglow,
      tuningConfig = statebag.tuningConfig,
      servicingData = statebag.servicingData,
      nitrousInstalledBottles = statebag.nitrousInstalledBottles,
      nitrousFilledBottles = statebag.nitrousFilledBottles,
      nitrousCapacity = statebag.nitrousCapacity,
    }

    props = tableConcat(props, statebagProps)
  end

  return props
end

exports("getVehicleProperties", getVehicleProperties)

function setVehicleProperties(vehicle, props, withStatebags)
  if not DoesEntityExist(vehicle) or not props or type(props) ~= "table" then return false end

  local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
  local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

  SetVehicleModKit(vehicle, 0)

  if props.windowsBroken ~= nil then
    for k, v in pairs(props.windowsBroken) do
      if v then
        k = tonumber(k)
        if k then
          RemoveVehicleWindow(vehicle, k)
        end
      end
    end
  end

  if props.doorsBroken ~= nil then
    for k, v in pairs(props.doorsBroken) do
      if v then
        k = tonumber(k)
        if k then
          SetVehicleDoorBroken(vehicle, k, true)
        end
      end
    end
  end

  if props.tyreBurst ~= nil then
    for k, v in pairs(props.tyreBurst) do
      if v then
        k = tonumber(k)
        if k then
          SetVehicleTyreBurst(vehicle, k, true, 1000.0)
        end
      end
    end
  end

  if props.tyresCanBurst ~= nil then
    SetVehicleTyresCanBurst(vehicle, props.tyresCanBurst)
  end

  if props.modKit17 then
    SetVehicleMod(vehicle, 17, props.modKit17, false)
  end

  if props.modKit19 then
    SetVehicleMod(vehicle, 19, props.modKit19, false)
  end

  if props.modKit21 then
    SetVehicleMod(vehicle, 21, props.modKit21, false)
  end

  if props.modKit47 then
    SetVehicleMod(vehicle, 47, props.modKit47, false)
  end

  if props.modKit49 then
    SetVehicleMod(vehicle, 49, props.modKit49, false)
  end

  if props.liveryRoof then
    SetVehicleRoofLivery(vehicle, props.liveryRoof)
  end

  if props.extras then
    for id, enabled in pairs(props.extras) do
      SetVehicleExtra(vehicle, tonumber(id), not enabled)
    end
  end

  if props.plate then
    SetVehicleNumberPlateText(vehicle, props.plate)
  end

  if props.plateIndex then
    SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
  end

  if props.bodyHealth then
    SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
  end

  if props.engineHealth then
    SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
  end

  if props.tankHealth then
    SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
  end

  if props.fuelLevel then
    SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
  end

  if props.oilLevel then
    SetVehicleOilLevel(vehicle, props.oilLevel + 0.0)
  end

  if props.dirtLevel then
    SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
  end

  if props.color1 then
    if type(props.color1) == "number" then
      ClearVehicleCustomPrimaryColour(vehicle)
      SetVehicleColours(vehicle, props.color1, colorSecondary)
    elseif type(props.color1) == "table" then
      local r = tonumber(props.color1[1] or props.color1.r)
      local g = tonumber(props.color1[2] or props.color1.g)
      local b = tonumber(props.color1[3] or props.color1.b)
      if r and g and b then
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
        if props.paintType1 then SetVehicleModColor_1(vehicle, props.paintType1, 0, tonumber(props.pearlescentColor) or 0) end
      end
    end
  end

  if props.color2 then
    if type(props.color2) == "number" then
      ClearVehicleCustomSecondaryColour(vehicle)
      -- color1 may be RGB (table); SetVehicleColours only accepts palette indices
      local primaryColour = colorPrimary
      if type(props.color1) == "number" then
        primaryColour = props.color1
      end
      SetVehicleColours(vehicle, primaryColour, props.color2)
      if type(props.color1) == "table" and props.paintType1 then
        SetVehicleModColor_1(vehicle, props.paintType1, 0, tonumber(props.pearlescentColor) or 0)
      end
    elseif type(props.color2) == "table" then
      local r = tonumber(props.color2[1] or props.color2.r)
      local g = tonumber(props.color2[2] or props.color2.g)
      local b = tonumber(props.color2[3] or props.color2.b)
      if r and g and b then
        SetVehicleCustomSecondaryColour(vehicle, r, g, b)
        if props.paintType2 then SetVehicleModColor_2(vehicle, props.paintType2, 0) end
      end
    end
  end

  local pearl = tonumber(props.pearlescentColor)
  local wheelCol = tonumber(props.wheelColor)
  if pearl or wheelCol then
    SetVehicleExtraColours(vehicle, pearl or pearlescentColor, wheelCol or wheelColor)
  end

  if props.interiorColor then
    local interior = tonumber(props.interiorColor)
    if interior then SetVehicleInteriorColor(vehicle, interior) end
  end

  if props.dashboardColor then
    local dash = tonumber(props.dashboardColor)
    if dash then SetVehicleDashboardColor(vehicle, dash) end
  end

  if props.wheels then
    SetVehicleWheelType(vehicle, props.wheels)
  end

  if props.wheelSize then
    SetVehicleWheelSize(vehicle, props.wheelSize)
  end

  if props.wheelWidth then
    SetVehicleWheelWidth(vehicle, props.wheelWidth)
  end

  if props.windowTint then
    SetVehicleWindowTint(vehicle, props.windowTint)
  end

  if props.windowStatus then
    for windowIndex, smashWindow in pairs(props.windowStatus) do
      if not smashWindow then
        RemoveVehicleWindow(vehicle, windowIndex)
      end
    end
  end

  if props.doorStatus then
    for doorIndex, breakDoor in pairs(props.doorStatus) do
      if breakDoor then
        if type(doorIndex) == "string" then doorIndex = tonumber(doorIndex) or 0 end
        SetVehicleDoorBroken(vehicle, doorIndex, true)
      end
    end
  end

  if props.tireHealth then
    for wheelIndex, health in pairs(props.tireHealth) do
      SetVehicleWheelHealth(vehicle, wheelIndex, health)
    end
  end

  if props.tireBurstState then
    for wheelIndex, burstState in pairs(props.tireBurstState) do
      if burstState then
        if type(wheelIndex) == "string" then wheelIndex = tonumber(wheelIndex) or 0 end
        SetVehicleTyreBurst(vehicle, wheelIndex, false, 1000.0)
      end
    end
  end

  if props.tireBurstCompletely then
    for wheelIndex, burstState in pairs(props.tireBurstCompletely) do
      if burstState then
        if type(wheelIndex) == "string" then wheelIndex = tonumber(wheelIndex) or 0 end
        SetVehicleTyreBurst(vehicle, wheelIndex, true, 1000.0)
      end
    end
  end

  if props.neonEnabled then
    for i = 1, #props.neonEnabled do
      SetVehicleNeonLightEnabled(vehicle, i - 1, props.neonEnabled[i])
    end
  end

  if props.neonColor and type(props.neonColor) == "table" then
    local r = tonumber(props.neonColor[1] or props.neonColor.r)
    local g = tonumber(props.neonColor[2] or props.neonColor.g)
    local b = tonumber(props.neonColor[3] or props.neonColor.b)
    if r and g and b then
      SetVehicleNeonLightsColour(vehicle, r, g, b)
    end
  end

  if props.modSmokeEnabled ~= nil then
    ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled)
  end

  if props.tyreSmokeColor and type(props.tyreSmokeColor) == "table" then
    local r = tonumber(props.tyreSmokeColor[1] or props.tyreSmokeColor.r)
    local g = tonumber(props.tyreSmokeColor[2] or props.tyreSmokeColor.g)
    local b = tonumber(props.tyreSmokeColor[3] or props.tyreSmokeColor.b)
    if r and g and b then
      SetVehicleTyreSmokeColor(vehicle, r, g, b)
    end
  end

  if props.modSpoilers then
    SetVehicleMod(vehicle, 0, props.modSpoilers, false)
  end

  if props.modFrontBumper then
    SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
  end

  if props.modRearBumper then
    SetVehicleMod(vehicle, 2, props.modRearBumper, false)
  end

  if props.modSideSkirt then
    SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
  end

  if props.modExhaust then
    SetVehicleMod(vehicle, 4, props.modExhaust, false)
  end

  if props.modFrame then
    SetVehicleMod(vehicle, 5, props.modFrame, false)
  end

  if props.modGrille then
    SetVehicleMod(vehicle, 6, props.modGrille, false)
  end

  if props.modHood then
    SetVehicleMod(vehicle, 7, props.modHood, false)
  end

  if props.modFender then
    SetVehicleMod(vehicle, 8, props.modFender, false)
  end

  if props.modRightFender then
    SetVehicleMod(vehicle, 9, props.modRightFender, false)
  end

  if props.modRoof then
    SetVehicleMod(vehicle, 10, props.modRoof, false)
  end

  if props.modEngine then
    SetVehicleMod(vehicle, 11, props.modEngine, false)
  end

  if props.modBrakes then
    SetVehicleMod(vehicle, 12, props.modBrakes, false)
  end

  if props.modTransmission then
    SetVehicleMod(vehicle, 13, props.modTransmission, false)
  end

  if props.modHorns then
    SetVehicleMod(vehicle, 14, props.modHorns, false)
  end

  if props.modSuspension then
    SetVehicleMod(vehicle, 15, props.modSuspension, false)
  end

  if props.modArmor then
    SetVehicleMod(vehicle, 16, props.modArmor, false)
  end

  if props.modNitrous then
    SetVehicleMod(vehicle, 17, props.modNitrous, false)
  end

  if props.modTurbo ~= nil then
    ToggleVehicleMod(vehicle, 18, props.modTurbo)
  end

  if props.modSubwoofer ~= nil then
    ToggleVehicleMod(vehicle, 19, props.modSubwoofer)
  end

  if props.modHydraulics ~= nil then
    ToggleVehicleMod(vehicle, 21, props.modHydraulics)
  end

  if props.modXenon ~= nil then
    ToggleVehicleMod(vehicle, 22, props.modXenon)
  end

  if type(props.xenonColor) == "table" then
    props.xenonCustomColorEnabled = true
    props.xenonCustomColor = props.xenonColor
  end

  if props.xenonCustomColorEnabled and type(props.xenonCustomColor) == "table" then
    SetVehicleXenonLightsCustomColor(
      vehicle,
      props.xenonCustomColor[1], props.xenonCustomColor[2], props.xenonCustomColor[3]
    )
  elseif props.xenonColor and type(props.xenonColor) == "number" then
    SetVehicleXenonLightsColor(vehicle, props.xenonColor)
  end

  if props.modFrontWheels then
    SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomTiresF or props.modCustomFrontWheels)
  end

  if props.modBackWheels then
    SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomTiresR or props.modCustomBackWheels)
  end

  if props.modPlateHolder then
    SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
  end

  if props.modVanityPlate then
    SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
  end

  if props.modTrimA then
    SetVehicleMod(vehicle, 27, props.modTrimA, false)
  end

  if props.modOrnaments then
    SetVehicleMod(vehicle, 28, props.modOrnaments, false)
  end

  if props.modDashboard then
    SetVehicleMod(vehicle, 29, props.modDashboard, false)
  end

  if props.modDial then
    SetVehicleMod(vehicle, 30, props.modDial, false)
  end

  if props.modDoorSpeaker then
    SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
  end

  if props.modSeats then
    SetVehicleMod(vehicle, 32, props.modSeats, false)
  end

  if props.modSteeringWheel then
    SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
  end

  if props.modShifterLeavers then
    SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
  end

  if props.modAPlate then
    SetVehicleMod(vehicle, 35, props.modAPlate, false)
  end

  if props.modSpeakers then
    SetVehicleMod(vehicle, 36, props.modSpeakers, false)
  end

  if props.modTrunk then
    SetVehicleMod(vehicle, 37, props.modTrunk, false)
  end

  if props.modHydrolic then
    SetVehicleMod(vehicle, 38, props.modHydrolic, false)
  end

  if props.modEngineBlock then
    SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
  end

  if props.modAirFilter then
    SetVehicleMod(vehicle, 40, props.modAirFilter, false)
  end

  if props.modStruts then
    SetVehicleMod(vehicle, 41, props.modStruts, false)
  end

  if props.modArchCover then
    SetVehicleMod(vehicle, 42, props.modArchCover, false)
  end

  if props.modAerials then
    SetVehicleMod(vehicle, 43, props.modAerials, false)
  end

  if props.modTrimB then
    SetVehicleMod(vehicle, 44, props.modTrimB, false)
  end

  if props.modTank then
    SetVehicleMod(vehicle, 45, props.modTank, false)
  end

  if props.modWindows then
    SetVehicleMod(vehicle, 46, props.modWindows, false)
  end

  if props.modDoorR then
    SetVehicleMod(vehicle, 47, props.modDoorR, false)
  end

  if props.modLivery then
    SetVehicleMod(vehicle, 48, props.modLivery, false)
    SetVehicleLivery(vehicle, props.modLivery)
  end

  if props.modRoofLivery then
    SetVehicleRoofLivery(vehicle, props.modRoofLivery)
  end

  if props.modLightbar then
    SetVehicleMod(vehicle, 49, props.modLightbar, false)
  end

  if props.bulletProofTyres ~= nil then
    SetVehicleTyresCanBurst(vehicle, not props.bulletProofTyres)
  end

  if GetGameBuildNumber() >= 2372 and props.driftTyres then
    SetDriftTyresEnabled(vehicle, true)
  end

  if withStatebags then
    SetTimeout(500, function()
      setStatebagsFromProps(vehicle, props, props.plate)
    end)

    return not NetworkGetEntityIsNetworked(vehicle) or NetworkGetEntityOwner(vehicle) == cache.playerId
  else
    if not NetworkGetEntityIsNetworked(vehicle) or NetworkGetEntityOwner(vehicle) == cache.playerId then
      retrieveAndApplyVehicleStatebagData(vehicle, props.plate)
      return true
    end
  end

  return false
end

exports("setVehicleProperties", setVehicleProperties)

function getVehicleStatebagProperties(vehicle)
  if not DoesEntityExist(vehicle) then return false end

  local statebag = Entity(vehicle).state

  return {
    primarySecondarySync = statebag.primarySecondarySync,
    disablePearl = statebag.disablePearl,
    enableStance = statebag.enableStance or false,
    wheelsAdjIndv = statebag.wheelsAdjIndv or false,
    defaultStance = statebag.defaultStance or getVehicleDefaultStance(vehicle),
    stance = statebag.stance or getVehicleDefaultStance(vehicle),
    lcInstalled = statebag.lightingControllerInstalled,
    lcXenons = statebag.xenons,
    lcUnderglowDirections = statebag.underglowDirections,
    lcUnderglow = statebag.underglow,
    tuningConfig = statebag.tuningConfig,
    servicingData = statebag.servicingData,
    nitrousInstalledBottles = statebag.nitrousInstalledBottles,
    nitrousFilledBottles = statebag.nitrousFilledBottles,
    nitrousCapacity = statebag.nitrousCapacity
  }
end

exports("getVehicleStatebagProperties", getVehicleStatebagProperties)

function setVehicleStatebagProperties(vehicle, props)
  if not DoesEntityExist(vehicle) or not props or type(props) ~= "table" then return false end

  setStatebagsFromProps(vehicle, props)
  return true
end

exports("setVehicleStatebagProperties", setVehicleStatebagProperties)

function setStatebagsFromProps(vehicle, props, plateOverride)
  if not vehicle or vehicle == 0 or not props or type(props) ~= "table" then
    debugPrint("Could not run setStatebagsFromProps", "warning", vehicle, json.encode(props))
    return false
  end

  setVehicleStatebags(
    vehicle,
    {
      primarySecondarySync = props.primarySecondarySync,
      disablePearl = props.disablePearl,
      enableStance = props.enableStance,
      wheelsAdjIndv = props.wheelsAdjIndv,
      stance = props.stance,
      lightingControllerInstalled = props.lcInstalled,
      xenons = props.lcXenons,
      underglowDirections = props.lcUnderglowDirections,
      underglow = props.lcUnderglow,
      tuningConfig = props.tuningConfig,
      servicingData = props.servicingData,
      nitrousInstalledBottles = props.nitrousInstalledBottles,
      nitrousFilledBottles = props.nitrousFilledBottles,
      nitrousCapacity = props.nitrousCapacity,
    },
    true,
    plateOverride
  )
end

AddStateBagChangeHandler("applyVehicleProps", "", function(bagName, _, props)
  if not props or type(props) ~= "table" then return false end

  local vehicle = GetEntityFromStateBagName(bagName)
  if not vehicle or vehicle == 0 then return end

  SetTimeout(0, function()
    local state, attempts = Entity(vehicle).state, 0

    while attempts < 20 do
      if NetworkGetEntityOwner(vehicle) == cache.playerId and setVehicleProperties(vehicle, props) then
        state:set("applyVehicleProps", nil, true)
        break
      end

      attempts += 1
      Wait(100)
    end
  end)
end)

local vehiclePlate = nil
local function onEnterVehicle(vehicle)
  if vehiclePlate then
    lib.callback.await("jg-mechanic:server:save-veh-statebag-data-to-db", false, vehiclePlate, true)
  end

  if not vehicle or vehicle == 0 then
    vehiclePlate = nil
    return
  end

  SetTimeout(2000, function()
    vehiclePlate = Framework.Client.GetPlate(vehicle)
    retrieveAndApplyVehicleStatebagData(vehicle, vehiclePlate)
  end)
end

lib.onCache("vehicle", onEnterVehicle)
if cache.vehicle then onEnterVehicle(cache.vehicle) end
