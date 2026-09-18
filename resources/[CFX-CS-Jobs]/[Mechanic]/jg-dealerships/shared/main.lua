Globals = {}
Functions = {}
Locale = Locales[Config.Locale or "en"]

exports("locale", function() return Locale end)
exports("config", function() return Config end)

local jgVehicleStudioStarted = nil

---@param vehicles table[]|nil
---@param spawnCodeField? string
---@param imageField? string
---@param fallbackField? string
---@return table[]|nil
function ApplyJGVehicleStudioImages(vehicles, spawnCodeField, imageField, fallbackField)
  if type(vehicles) ~= "table" then return vehicles end

  spawnCodeField = spawnCodeField or "spawn_code"
  imageField = imageField or "image_url"
  fallbackField = fallbackField or (imageField == "image_url" and "image_fallbacks" or (imageField .. "_fallbacks"))

  local function clearVehicleImages()
    for _, vehicle in pairs(vehicles) do
      if type(vehicle) == "table" then
        vehicle[imageField] = nil
        vehicle[fallbackField] = nil
      end
    end
  end

  if Config.UseJGVehicleStudio == false then
    clearVehicleImages()
    return vehicles
  end

  if jgVehicleStudioStarted == nil then
    jgVehicleStudioStarted = GetResourceState("jg-vehiclestudio") == "started"
  end

  if not jgVehicleStudioStarted then
    clearVehicleImages()
    return vehicles
  end

  local spawnCodes, seen = {}, {}
  for _, vehicle in pairs(vehicles) do
    if type(vehicle) == "table" and vehicle[spawnCodeField] then
      local spawnCode = tostring(vehicle[spawnCodeField])
      if spawnCode ~= "" and not seen[spawnCode] then
        spawnCodes[#spawnCodes + 1] = spawnCode
        seen[spawnCode] = true
      end
    end
  end

  if #spawnCodes == 0 then return vehicles end

  local success, images = pcall(function()
    return exports["jg-vehiclestudio"]:getImages(spawnCodes, Config.JGVehicleStudioImageSet or "default")
  end)

  if not success or type(images) ~= "table" then
    DebugPrint("Failed to fetch jg-vehiclestudio images", "warning", images)
    clearVehicleImages()
    return vehicles
  end

  for _, vehicle in pairs(vehicles) do
    if type(vehicle) == "table" and vehicle[spawnCodeField] then
      local result = images[tostring(vehicle[spawnCodeField])]

      if type(result) == "table" then
        vehicle[imageField] = type(result.image) == "string" and result.image ~= "" and result.image or nil
        vehicle[fallbackField] = type(result.fallbacks) == "table" and result.fallbacks or nil
      else
        vehicle[imageField] = type(result) == "string" and result ~= "" and result or nil
        vehicle[fallbackField] = nil
      end
    end
  end

  return vehicles
end

---@param text string
---@param debugtype? "warning"|"debug"
function DebugPrint(text, debugtype, ...)
  if not Config.Debug then return end
    
  local prefix = "^2[DEBUG]^7"
  if debugtype == "warning" then prefix = "^3[WARNING]^7" end 

  local args = {...}
  local output = ""
  for i = 1, #args do
    if type(args[i]) == "table" then
      output = output .. json.encode(args[i])
    elseif type(args[i]) ~= "string" then
      output = output .. tostring(args[i])
    else
      output = output .. args[i]
    end

    if i ~= #args then output = output .. " " end
  end
  
  print(prefix, text, output)
end

---@param vehicle integer
function JGDeleteVehicle(vehicle)
  if not DoesEntityExist(vehicle) then return end

  if GetResourceState("AdvancedParking") == "started" then
    exports["AdvancedParking"]:DeleteVehicle(vehicle, false)
  else
    DeleteEntity(vehicle)
  end
end

---@param vehicle integer
---@param plate string
function SetVehiclePlateText(vehicle, plate)
  if GetResourceState("AdvancedParking") == "started" then
    exports["AdvancedParking"]:UpdatePlate(vehicle, plate)
  else
    SetVehicleNumberPlateText(vehicle, plate)
  end
end

---@param model string | number
---@return number hash
function ConvertModelToHash(model)
  return type(model) == "string" and joaat(model) or model --[[@as number]]
end

---@param plate string
function IsValidGTAPlate(plate)
  -- Check if the plate matches the pattern and is not longer than 8 characters
  -- %w matches alphanumeric characters, %s matches space characters
  -- The pattern checks for a string starting with 0 or more alphanumeric or space characters
  if #plate <= 8 and plate:match("^[%w%s]*$") then return true end
  return false
end

---@param table table
function TableKeys(table)
  if not table then return {} end

  local keys = {}
  for k, _ in pairs(table) do
    keys[#keys+1] = k  
  end

  return keys
end

-- Round a number to so-many decimal of places,
-- Which can be negative, e.g. -1 places rounds to 10's
---@param num integer
---@param dp? integer
---@return number
function Round(num, dp)
  dp = dp or 0
  local mult = 10^(dp or 0)
  return math.floor(num * mult + 0.5) / mult
end

---@param list table
---@param item string|number
---@return boolean
function IsItemInList(list, item)
  if #list == 0 then
    return true
  end

  for _, value in ipairs(list) do
    if value == item then
      return true
    end
  end

  return false
end

---@param s string
---@return string
function Trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function TableValues(table)
  local values = {}
  for _, val in pairs(table) do
    values[#values+1] = val
  end
  return values
end

---Case-insensitive table key lookup
---@param tbl table The table to search
---@param key string The key to find (case-insensitive)
---@return any value The value if found, nil otherwise
---@return string|nil actualKey The actual key in the table if found
function GetCaseInsensitive(tbl, key)
  if not tbl or not key then return nil, nil end

  -- Try exact match first
  if tbl[key] ~= nil then return tbl[key], key end

  -- Try case-insensitive match
  local lowerKey = string.lower(key)
  for k, v in pairs(tbl) do
    if type(k) == "string" and string.lower(k) == lowerKey then
      return v, k
    end
  end

  return nil, nil
end

---Checks if a job/gang passes a whitelist
---@param whitelist JobGangWhitelist|nil
---@param name string|nil
---@param grade number|nil
---@return boolean
function CheckJobGangWhitelist(whitelist, name, grade)
  if not whitelist or not next(whitelist) then return true end
  if not name or not grade then return false end

  local allowedGrades = whitelist[name]
  if not allowedGrades then return false end

  for _, allowedGrade in ipairs(allowedGrades) do
    if allowedGrade == grade then return true end
  end

  return false
end
