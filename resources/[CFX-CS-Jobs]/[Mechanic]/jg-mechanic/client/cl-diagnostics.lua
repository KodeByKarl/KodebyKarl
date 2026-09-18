-- Client-side handler for OBD-II Diagnostic Scanner & Odometer Tool

local function getEcuLabel(ecuVal)
  local val = tonumber(ecuVal) or 0
  if val == 1 then
    return "Stage 1 (Street Map)"
  elseif val == 2 then
    return "Stage 2 (Sport Calibration)"
  elseif val == 3 then
    return "Stage 3 (Race Map / 2-Step ALS)"
  end
  return "OEM Factory Map"
end

local function getPartColorBadge(health)
  local h = tonumber(health) or 100
  if h > 70 then
    return "green"
  elseif h > 30 then
    return "yellow"
  else
    return "red"
  end
end

-- Generate diagnostic trouble codes (DTCs) based on vehicle stats
local function generateFaultCodes(engineHealth, bodyHealth, servicingData)
  local dtcs = {}

  if engineHealth < 400 then
    dtcs[#dtcs + 1] = {
      code = "P0217",
      system = "Powertrain / Cooling",
      desc = "Engine Coolant Overtemperature Condition detected.",
      severity = "CRITICAL"
    }
  end

  if servicingData then
    if (servicingData.engine_oil or 100) < 25 then
      dtcs[#dtcs + 1] = {
        code = "P0524",
        system = "Lubrication",
        desc = "Engine Oil Pressure Low - Viscosity degraded, oil change needed.",
        severity = "WARNING"
      }
    end

    if (servicingData.spark_plug or 100) < 30 then
      dtcs[#dtcs + 1] = {
        code = "P0300",
        system = "Ignition",
        desc = "Random / Multiple Cylinder Misfire Detected - Worn spark plugs.",
        severity = "WARNING"
      }
    end

    if (servicingData.clutch_replacement or 100) < 30 then
      dtcs[#dtcs + 1] = {
        code = "P0730",
        system = "Transmission",
        desc = "Incorrect Gear Ratio / Clutch Friction Slippage detected.",
        severity = "WARNING"
      }
    end

    if (servicingData.air_filter or 100) < 30 then
      dtcs[#dtcs + 1] = {
        code = "P0101",
        system = "Air Intake",
        desc = "Mass Airflow (MAF) Circuit / Air Filter Flow Restriction.",
        severity = "ADVISORY"
      }
    end

    if (servicingData.brakepad_replacement or 100) < 25 then
      dtcs[#dtcs + 1] = {
        code = "P0571",
        system = "Braking",
        desc = "Brake Pad Wear Indicator Sensor Triggered - Replacement advised.",
        severity = "WARNING"
      }
    end

    if (servicingData.ev_battery or 100) < 25 then
      dtcs[#dtcs + 1] = {
        code = "P0A7F",
        system = "Hybrid / EV System",
        desc = "Hybrid / EV Battery Pack Deterioration / Low Cell Voltage.",
        severity = "CRITICAL"
      }
    end
  end

  return dtcs
end

-- Display the main Diagnostic Context Menu
local function openDiagnosticReportMenu(data)
  local dtcs = generateFaultCodes(data.engineHealthRaw, data.bodyHealthRaw, data.servicingData)
  local statusBadge = #dtcs == 0 and "🟢 Nominal" or ("🔴 %d Fault Code(s)"):format(#dtcs)

  local options = {
    {
      title = ("Vehicle: %s | Plate: %s"):format(data.modelName, data.plate),
      description = ("Class: %s | Status: %s"):format(data.className, statusBadge),
      icon = "car",
      iconColor = #dtcs == 0 and "#10b981" or "#ef4444",
      readOnly = true
    },
    {
      title = ("Odometer Mileage: %s %s"):format(data.mileage, data.mileageUnit:upper()),
      description = "Total lifetime distance logged by ECU",
      icon = "gauge-high",
      iconColor = "#3b82f6",
      readOnly = true
    },
    {
      title = ("Engine Health: %d%% | Body: %d%%"):format(data.enginePercent, data.bodyPercent),
      description = "Mechanical and structural condition",
      progress = data.enginePercent,
      colorScheme = data.enginePercent > 60 and "green" or data.enginePercent > 30 and "yellow" or "red",
      icon = "heart-pulse",
      readOnly = true
    },
    {
      title = ("ECU Calibration: %s"):format(data.ecuLabel),
      description = "Active engine management software mapping",
      icon = "microchip",
      iconColor = "#8b5cf6",
      readOnly = true
    }
  }

  -- Component Breakdown
  if data.servicingData and next(data.servicingData) then
    local components = {}
    for part, health in pairs(data.servicingData) do
      local label = Locale[part] or part:gsub("_", " "):gsub("^%l", string.upper)
      components[#components + 1] = ("• **%s**: %d%%"):format(label, health)
    end

    options[#options + 1] = {
      title = "Component Wear & Servicing Life",
      description = table.concat(components, "\n"),
      icon = "wrench",
      iconColor = "#f59e0b",
      readOnly = true
    }
  end

  -- DTC Fault Codes
  if #dtcs > 0 then
    local dtcText = {}
    for _, dtc in ipairs(dtcs) do
      dtcText[#dtcText + 1] = ("⚠️ `[%s]` **%s**\n%s"):format(dtc.code, dtc.system, dtc.desc)
    end

    options[#options + 1] = {
      title = ("Active Diagnostic Fault Codes (%d)"):format(#dtcs),
      description = table.concat(dtcText, "\n\n"),
      icon = "triangle-exclamation",
      iconColor = "#ef4444",
      readOnly = true
    }
  else
    options[#options + 1] = {
      title = "OBD-II Fault Codes: Clear",
      description = "No active error codes or warnings detected in ECU memory.",
      icon = "circle-check",
      iconColor = "#10b981",
      readOnly = true
    }
  end

  -- Share report option
  options[#options + 1] = {
    title = "Share Diagnostic Report with Nearby Player",
    description = "Send this live scan report to a customer standing nearby",
    icon = "share-from-square",
    iconColor = "#06b6d4",
    onSelect = function()
      local input = lib.inputDialog("Share Diagnostic Report", {
        { type = "number", label = "Target Player Server ID", description = "Enter the nearby player's Server ID", required = true, min = 1 }
      })
      if input and input[1] then
        TriggerServerEvent("jg-mechanic:server:share-diagnostic-report", tonumber(input[1]), data)
      end
    end
  }

  lib.registerContext({
    id = "jg_obd_diagnostic_menu",
    title = "📟 OBD-II Diagnostic Scan Report",
    options = options
  })

  lib.showContext("jg_obd_diagnostic_menu")
end

-- Shared report viewer for customers
RegisterNetEvent("jg-mechanic:client:show-shared-diagnostic-report", function(data)
  lib.notify({
    title = "OBD-II Diagnostic Report Received",
    description = ("Report for [%s] %s received from mechanic."):format(data.plate, data.modelName),
    type = "inform",
    duration = 6000
  })
  openDiagnosticReportMenu(data)
end)

-- Main trigger when using OBD-II Scanner item
RegisterNetEvent("jg-mechanic:client:use-obd-scanner", function()
  local ped = cache.ped or PlayerPedId()
  local vehicle = cache.vehicle

  if not vehicle or vehicle == 0 then
    local coords = GetEntityCoords(ped)
    vehicle = lib.getClosestVehicle(coords, 4.0, false)
  end

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    return lib.notify({
      title = "OBD-II Scanner",
      description = Locale.noVehicleNearby or "No vehicle nearby to connect OBD-II scanner!",
      type = "error"
    })
  end

  local plate = GetVehicleNumberPlateText(vehicle)
  if not plate or plate == "" then return end

  -- Clean plate
  plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")

  -- Scan Progress Bar & Animation
  local success = lib.progressBar({
    duration = 3200,
    label = "Connecting OBD-II Diagnostic Port...",
    useWhileDead = false,
    canCancel = true,
    disable = {
      car = true,
      move = true,
      combat = true
    },
    anim = {
      dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
      clip = "machinic_loop_mechandplayer"
    }
  })

  if not success then return end

  local netId = NetworkGetNetworkIdFromEntity(vehicle)
  local serverData = lib.callback.await("jg-mechanic:server:get-vehicle-diagnostics", false, plate, netId)

  if not serverData then
    return lib.notify({
      title = "OBD-II Scanner",
      description = "Could not retrieve ECU diagnostic data from vehicle.",
      type = "error"
    })
  end

  local modelHash = GetEntityModel(vehicle)
  local modelName = GetDisplayNameFromVehicleModel(modelHash) or "Unknown Vehicle"
  local classId = GetVehicleClass(vehicle)
  local classNames = {
    [0] = "Compacts", [1] = "Sedans", [2] = "SUVs", [3] = "Coupes", [4] = "Muscle",
    [5] = "Sports Classics", [6] = "Sports", [7] = "Super", [8] = "Motorcycles",
    [9] = "Off-road", [10] = "Industrial", [11] = "Utility", [12] = "Vans",
    [13] = "Cycles", [14] = "Boats", [15] = "Helicopters", [16] = "Planes",
    [17] = "Service", [18] = "Emergency", [19] = "Military", [20] = "Commercial", [21] = "Trains", [22] = "Open Wheel"
  }

  local engineHealth = GetVehicleEngineHealth(vehicle)
  local bodyHealth = GetVehicleBodyHealth(vehicle)
  local enginePercent = math.max(0, math.min(100, math.floor(engineHealth / 10)))
  local bodyPercent = math.max(0, math.min(100, math.floor(bodyHealth / 10)))

  local ecuStage = serverData.tuningConfig and serverData.tuningConfig.ecu or 0

  local reportData = {
    plate = plate,
    modelName = modelName,
    className = classNames[classId] or "Automotive",
    mileage = string.format("%.1f", serverData.mileage or 0),
    mileageUnit = serverData.mileageUnit or "km",
    engineHealthRaw = engineHealth,
    bodyHealthRaw = bodyHealth,
    enginePercent = enginePercent,
    bodyPercent = bodyPercent,
    ecuLabel = getEcuLabel(ecuStage),
    servicingData = serverData.servicingData or {},
    tuningConfig = serverData.tuningConfig or {}
  }

  openDiagnosticReportMenu(reportData)
end)
