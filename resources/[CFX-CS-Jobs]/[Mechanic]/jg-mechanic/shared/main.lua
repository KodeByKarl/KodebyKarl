Globals = {}
Functions = {}
Locale = Locales[Config.Locale or "en"]

exports("config", function()
  return Config
end)

function debugPrint(context, logType, ...)
  return
end

function getTrimmedVehiclePlate(vehicle)
  if not vehicle or not DoesEntityExist(vehicle) then
    return false
  end

  local plate = GetVehicleNumberPlateText(vehicle)
  if not plate then
    return false
  end

  return string.gsub(plate, "^%s*(.-)%s*$", "%1")
end

function isVehicleElectric(modelName)
  if GetGameBuildNumber() >= 3258 then
    return Citizen.InvokeNative(0x1F33C33A4FCC175B, joaat(modelName)) == 1
  end
  return lib.table.contains(Config.ElectricVehicles, modelName)
end

function round(number, decimals)
  local effectiveDecimals = decimals or 0
  local factor = 10 ^ effectiveDecimals
  return math.floor(number * factor + 0.5) / factor
end

function deepMerge(originalTable, newTable)
  for key, value in pairs(newTable) do
    if type(value) == "table" and type(originalTable[key]) == "table" then
      deepMerge(originalTable[key], value)
    elseif value == "nil (deleted)" then
      originalTable[key] = nil
    else
      originalTable[key] = value
    end
  end
  return originalTable
end

function tableConcat(table1, table2)
  local newTable = {}
  if #table1 > 0 and #table2 > 0 then
    for i = 1, #table1 do
      newTable[#newTable + 1] = table1[i]
    end
    for i = 1, #table2 do
      newTable[#newTable + 1] = table2[i]
    end
  else
    for key, value in pairs(table1) do
      newTable[key] = value
    end
    for key, value in pairs(table2) do
      newTable[key] = value
    end
  end
  return newTable
end

function tableKeys(inputTable)
  local keys = {}
  for key, _ in pairs(inputTable) do
    keys[#keys + 1] = key
  end
  return keys
end

function bitOper(val1, val2, op)
  val1 = tonumber(val1) or 0
  val2 = tonumber(val2) or 0
  if op == 1 then
    return val1 | val2
  elseif op == 3 then
    return val1 & ~val2
  elseif op == 4 then
    return val1 & val2
  end
  return 0
end

function hasFlag(flags, flag)
  flags = tonumber(flags) or 0
  flag = tonumber(flag) or 0
  if flags == 0 or flag == 0 then return false end
  return (flags & flag) == flag
end

function addFlag(flags, flag)
  flags = tonumber(flags) or 0
  flag = tonumber(flag) or 0
  return flags | flag
end

function removeFlag(flags, flag)
  flags = tonumber(flags) or 0
  flag = tonumber(flag) or 0
  return flags & ~flag
end

function parseControlBinding(control)
  local button = GetControlInstructionalButton(0, control, true)
  local parsedButton = string.gsub(button, "^t_", "")
  if button ~= parsedButton then
    return parsedButton
  end

  if CONTROL_KEYBINDS[button] then
    return CONTROL_KEYBINDS[button]
  end

  return button
end
