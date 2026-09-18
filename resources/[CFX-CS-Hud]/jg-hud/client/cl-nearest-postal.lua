
---@type boolean
local postalsLoaded = false

CreateThread(function()
  if not Config.ShowNearestPostal then return end


    local jsonData = LoadResourceFile(GetCurrentResourceName(), Config.NearestPostalsData)
    if not jsonData then 
      return DebugPrint(("[ERROR] Could not find postals data file: %s"):format(Config.NearestPostalsData)) 
    end
    
    local postals = json.decode(jsonData)
 
    if not postals then
      return DebugPrint("[ERROR] Failed to decode postals JSON data")
    end

    for i = 1, #postals do
      local postal = postals[i]
      lib.grid.addEntry({
        coords = vec(postal.x, postal.y),
        code = postal.code,
        radius = 1
      })
    end
    
    postalsLoaded = true
    DebugPrint(("Loaded %d postal codes into ox_lib grid system"):format(#postals))
end)

---@param pos vector
---@return {code: string, dist: number} | false
function GetNearestPostal(pos)
  if not Config.ShowNearestPostal or not postalsLoaded then 
    return false 
  end

  local nearbyEntries = lib.grid.getNearbyEntries(pos)
  if not nearbyEntries or #nearbyEntries == 0 then
    return false
  end

  local closestEntry, minDist

  -- Check only nearby entries from grid
  for i = 1, #nearbyEntries do
    local entry = nearbyEntries[i]
    local dx = pos.x - entry.coords.x
    local dy = pos.y - entry.coords.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if not minDist or dist < minDist then
      closestEntry = entry
      minDist = dist
    end
  end

  if not closestEntry then
    return false
  end

  return {
    code = closestEntry.code,
    dist = math.round(Framework.Client.ConvertDistance(minDist, UserSettingsData?.distanceMeasurement))
  }
end