--[[
  Description:
    Locations & interactions main file

  Global Namespace:
    Locations.Client

  Globals:
    Locations.Client.GetLocations
    Locations.Client.GetLocationById
    Locations.Client.GetAllInteractionData
    Locations.Client.RemoveAllInteractions
    Locations.Client.RemoveLocationInteractions
    Locations.Client.RemoveInteractionType
    Locations.Client.RecreateInteractionType
    Locations.Client.RecreateInteractionTypeFromData
    Locations.Client.RecreatePermissionRestrictedInteractions
    Locations.Client.RefreshEmployeeStatusCache
    Locations.Client.IsEmployeeAtLocation
    Locations.Client.HasShowroomAccess
    Locations.Client.CreateAllInteractions
    Locations.Client.CreateLocationInteractions
    Locations.Client.AddLocation
    Locations.Client.UpdateLocation
    Locations.Client.DeleteLocation

  Exports:
    N/A
]]--

Locations = Locations or {}
Locations.Client = Locations.Client or {}

local cachedLocations = {}
local locationInteractions = {}
local employeeStatusCache = {} ---@type table<string, boolean> locationId -> isEmployee
local showroomPermissionCache = {} ---@type table<string, boolean> locationId -> canAccessShowroom
local isCreatingInteractions = false -- Mutex to prevent concurrent interaction creation
local hasInitiallyLoaded = false -- Flag to track if initial CreateAllInteractions has completed
local usedVehicleGarageRefreshQueued = false
local usedVehicleGarageState

---@return {canInteract: boolean, canStore: boolean, prompt: string}
local function getUsedVehicleGarageState()
  if usedVehicleGarageState then return usedVehicleGarageState end

  usedVehicleGarageState = UsedVehiclesIntegration.Client.GetGarageInteractionState()
  return usedVehicleGarageState
end

---@class InteractionTypeConfig
---@field getKeybind fun(): integer
---@field getPrompt fun(): string
---@field condition fun(location: Location): boolean
---@field canInteract? fun(location: Location): boolean
---@field getCoords? fun(location: Location): table[]
---@field hasPermissionRestriction boolean
---@field callback fun(location: Location): nil

---@type table<string, InteractionTypeConfig>
local interactionTypeConfigs = {
  showroom_coords = {
    getKeybind = function() return Config.OpenShowroomKeyBind end,
    getPrompt = function() return Config.OpenShowroomPrompt end,
    condition = function() return true end,
    canInteract = function(location)
      return showroomPermissionCache[location.id] ~= false
    end,
    hasPermissionRestriction = true,
    callback = function(location) UsedVehiclesIntegration.Client.OpenShowroomChoice(location.id) end
  },
  management_coords = {
    getKeybind = function() return Config.OpenManagementKeyBind end,
    getPrompt = function() return Config.OpenManagementPrompt end,
    condition = function(location) return location.type == "owned" end,
    canInteract = function(location)
      return employeeStatusCache[location.id] == true
    end,
    hasPermissionRestriction = true,
    callback = function(location) DealershipManagement.Client.Open(location.id) end
  },
  used_vehicles_garage = {
    getKeybind = function() return Config.OpenManagementKeyBind end,
    getPrompt = function()
      return getUsedVehicleGarageState().prompt
    end,
    condition = function(location)
      if not UsedVehiclesIntegration.Client.GetCreatorCapabilities().physicalEnabled then return false end
      local usedVehicles = location.additional_data and location.additional_data.usedVehicles or {}
      local garage = type(usedVehicles.stockGarage) == "table" and usedVehicles.stockGarage or {}
      return location.type == "owned" and usedVehicles.enabled == true and garage.enabled == true
    end,
    canInteract = function(location)
      if employeeStatusCache[location.id] ~= true then return false end
      return getUsedVehicleGarageState().canInteract
    end,
    getCoords = function(location)
      local usedVehicles = location.additional_data and location.additional_data.usedVehicles or {}
      local garage = type(usedVehicles.stockGarage) == "table" and usedVehicles.stockGarage or {}
      return type(garage.access) == "table" and garage.access or {}
    end,
    hasPermissionRestriction = true,
    callback = function(location)
      local state = UsedVehiclesIntegration.Client.GetGarageInteractionState()
      if not state.canInteract then return end
      if state.canStore then
        UsedVehiclesIntegration.Client.StoreStock()
        return
      end

      UsedVehiclesIntegration.Client.OpenGarage(location.id)
    end
  },
  sell_vehicle_coords = {
    getKeybind = function() return Config.SellVehicleKeyBind end,
    getPrompt = function() return Config.SellVehiclePrompt end,
    condition = function(location) return location.enable_sell_vehicle end,
    canInteract = function(location)
      return showroomPermissionCache[location.id] ~= false
    end,
    hasPermissionRestriction = true,
    callback = function(location) SellVehicle.Client.Request(location.id) end
  }
}

---Check if player is an employee at a location (from cache)
---@param locationId string
---@return boolean
function Locations.Client.IsEmployeeAtLocation(locationId)
  return employeeStatusCache[locationId] == true
end

---Check if player has showroom access at a location (from cache)
---@param locationId string
---@return boolean
function Locations.Client.HasShowroomAccess(locationId)
  return showroomPermissionCache[locationId] ~= false
end

---Refresh the employee status cache for all locations
---If forceServerCheck is true, makes server calls to refresh permissions (used when job changes)
---Otherwise uses the permissions already in the location data
---@param locations? Location[]
---@param forceServerCheck? boolean
function Locations.Client.RefreshEmployeeStatusCache(locations, forceServerCheck)
  locations = locations or cachedLocations or {}

  for _, location in pairs(locations) do
    Locations.Client.RefreshSingleLocationCache(location, forceServerCheck)
  end
end

---Refresh the employee status cache for a single location
---@param location Location
---@param forceServerCheck? boolean
function Locations.Client.RefreshSingleLocationCache(location, forceServerCheck)
  if not location then return end

  if forceServerCheck then
    -- Make server calls to refresh permissions (job/gang changed)
    local showroomAllowed = lib.callback.await("jg-dealerships:server:check-showroom-whitelist", false, location.id)
    showroomPermissionCache[location.id] = showroomAllowed

    if location.type == "owned" then
      local result = lib.callback.await("jg-dealerships:server:is-employee", false, location.id, false)
      employeeStatusCache[location.id] = result and result.isEmployee or false
    end
  else
    -- Use permissions from location data (already calculated on server)
    showroomPermissionCache[location.id] = location.playerCanAccessShowroom ~= false
    employeeStatusCache[location.id] = location.playerIsEmployee == true
  end
  DebugPrint("[RefreshCache] Location: " .. location.id .. " (" .. location.name .. ") showroom: " .. tostring(showroomPermissionCache[location.id]) .. ", employee: " .. tostring(employeeStatusCache[location.id]), "debug")
end

---@param location Location
---@param interactionType string
---@param customCoords? table[] Optional custom coordinates to use instead of location data
---@return boolean success Whether the interaction was created
local function createInteraction(location, interactionType, customCoords)
  if not location then return false end
  local config = interactionTypeConfigs[interactionType]
  if not config then return false end
  if not config.condition(location) then return false end

  local coords = customCoords or config.getCoords and config.getCoords(location) or location[interactionType]
  if not coords or (type(coords) == "table" and #coords == 0) then return false end

  if not locationInteractions[location.id] then
    locationInteractions[location.id] = {}
  end

  if locationInteractions[location.id][interactionType] then
    Interactions.Client.Remove(locationInteractions[location.id][interactionType])
  end

  local canInteract = config.canInteract and function() return config.canInteract(location) end or nil

  local blipName = location.name
  if Config.BlipNameFormat then
    blipName = Config.BlipNameFormat:format(location.name)
  end

  locationInteractions[location.id][interactionType] = Interactions.Client.Create(
    coords,
    config.getKeybind(),
    config.getPrompt(),
    function() config.callback(location) end,
    blipName,
    canInteract
  )

  return true
end

local function recreateUsedVehicleGarageInteractions()
  if usedVehicleGarageRefreshQueued then return end

  usedVehicleGarageRefreshQueued = true
  CreateThread(function()
    Wait(0)
    while isCreatingInteractions do Wait(0) end
    usedVehicleGarageRefreshQueued = false
    usedVehicleGarageState = UsedVehiclesIntegration.Client.GetGarageInteractionState()
    if not hasInitiallyLoaded then return end

    for _, location in pairs(cachedLocations) do
      createInteraction(location, "used_vehicles_garage")
    end
  end)
end

---@return table locationInteractions
function Locations.Client.GetAllInteractionData()
  return locationInteractions
end

---@param ignoreCache? boolean
---@return Location[] locations
function Locations.Client.GetLocations(ignoreCache)
  if cachedLocations and #cachedLocations > 0 and not ignoreCache then
    return cachedLocations
  end

  cachedLocations = lib.callback.await("jg-dealerships:server:get-all-locations", false)
  return cachedLocations
end

---@param id string dealership IdD
---@return Location|false location
function Locations.Client.GetLocationById(id)
  local locations = Locations.Client.GetLocations()
  for _, location in ipairs(locations) do
    if location.id == id then
      return location
    end
  end

  return false
end

function Locations.Client.RemoveAllInteractions()
  for _, interactionTypes in pairs(locationInteractions) do
    for _, interactions in pairs(interactionTypes) do
      Interactions.Client.Remove(interactions)
    end
  end
  locationInteractions = {}
  hasInitiallyLoaded = false
  usedVehicleGarageState = nil
end

---Remove all interactions for a specific location
---@param locationId string
function Locations.Client.RemoveLocationInteractions(locationId)
  if not locationId then return end
  if not locationInteractions[locationId] then return end

  for _, interactions in pairs(locationInteractions[locationId]) do
    Interactions.Client.Remove(interactions)
  end
  locationInteractions[locationId] = nil
end

---Remove specific interaction type for a location
---@param locationId string
---@param interactionType string
function Locations.Client.RemoveInteractionType(locationId, interactionType)
  if not locationId or not interactionType then return end
  if not locationInteractions[locationId] then return end
  if not locationInteractions[locationId][interactionType] then return end
  
  Interactions.Client.Remove(locationInteractions[locationId][interactionType])
  locationInteractions[locationId][interactionType] = nil
end

---Re-create specific interaction type for a location
---@param locationId string
---@param interactionType string
function Locations.Client.RecreateInteractionType(locationId, interactionType)
  if not locationId or not interactionType then return end

  local location = Locations.Client.GetLocationById(locationId)
  if not location then return end

  createInteraction(location, interactionType)
end

---Re-create specific interaction type for a location using provided interactions data
---@param locationId string
---@param interactionType string
---@param interactions table[] Array of interaction definitions from the UI
function Locations.Client.RecreateInteractionTypeFromData(locationId, interactionType, interactions)
  if not locationId or not interactionType then return end
  if not interactions or #interactions == 0 then return end

  local location = Locations.Client.GetLocationById(locationId)
  if not location then return end

  createInteraction(location, interactionType, interactions)
end

---Recreate all interactions that have permission restrictions (e.g. job-based)
---Called when player job changes to update visibility
function Locations.Client.RecreatePermissionRestrictedInteractions()
  -- Skip if initial load hasn't completed yet - CreateAllInteractions will handle everything
  if not hasInitiallyLoaded then
    DebugPrint("[RecreatePermissionRestrictedInteractions] Skipping - initial load not complete", "debug")
    return
  end
  
  -- Prevent concurrent interaction creation
  if isCreatingInteractions then
    DebugPrint("[RecreatePermissionRestrictedInteractions] Skipping - already creating interactions", "debug")
    return
  end
  isCreatingInteractions = true
  
  local locations = Locations.Client.GetLocations()

  -- Force server check since permissions may have changed (job/gang change)
  Locations.Client.RefreshEmployeeStatusCache(locations, true)

  for _, location in pairs(locations) do
    for interactionType, config in pairs(interactionTypeConfigs) do
      if config.hasPermissionRestriction then
        createInteraction(location, interactionType)
      end
    end
  end
  
  isCreatingInteractions = false
end

---Recreate permission-restricted interactions for a single location
---Called when employee status changes at a specific dealership
---@param dealershipId string
function Locations.Client.RecreatePermissionRestrictedInteractionsForLocation(dealershipId)
  if not hasInitiallyLoaded then
    DebugPrint("[RecreatePermissionRestrictedInteractionsForLocation] Skipping - initial load not complete", "debug")
    return
  end

  local location = Locations.Client.GetLocationById(dealershipId)
  if not location then
    DebugPrint("[RecreatePermissionRestrictedInteractionsForLocation] Location not found: " .. tostring(dealershipId), "debug")
    return
  end

  -- Refresh cache for just this location
  Locations.Client.RefreshSingleLocationCache(location, true)

  -- Recreate permission-restricted interactions for this location
  for interactionType, config in pairs(interactionTypeConfigs) do
    if config.hasPermissionRestriction then
      createInteraction(location, interactionType)
    end
  end
end

---Create all zones, blips & markers
---@param locations? Location[]
---@param ignoreCache? boolean
function Locations.Client.CreateAllInteractions(locations, ignoreCache)
  -- Prevent concurrent interaction creation
  if isCreatingInteractions then
    DebugPrint("[CreateAllInteractions] Skipping - already creating interactions", "debug")
    return
  end
  isCreatingInteractions = true
  
  -- Remove existing interactions first to handle deleted/disabled locations
  Locations.Client.RemoveAllInteractions()
  DealershipZones.Client.RemoveAllZones()
  
  locations = locations or Locations.Client.GetLocations(ignoreCache) or {}
  cachedLocations = locations
  DisplayVehicles.Client.SetLocations(locations)

  -- Use permissions from location data (no extra server calls needed)
  Locations.Client.RefreshEmployeeStatusCache(locations, false)
  usedVehicleGarageState = UsedVehiclesIntegration.Client.GetGarageInteractionState()

  for _, location in pairs(locations) do
    for interactionType in pairs(interactionTypeConfigs) do
      createInteraction(location, interactionType)
    end

    DealershipZones.Client.CreateZone(location)
  end
  
  isCreatingInteractions = false
  hasInitiallyLoaded = true
end

---@param bagName string
local function refreshUsedVehicleGarageStateBag(bagName)
  if not cache.vehicle then return end
  if GetEntityFromStateBagName(bagName) ~= cache.vehicle then return end

  recreateUsedVehicleGarageInteractions()
end

---Create interactions for a single location
---@param location Location
local function createLocationInteractions(location)
  if not location then return end

  -- Use permissions from location data if available, otherwise fetch from server
  if location.playerCanAccessShowroom ~= nil then
    showroomPermissionCache[location.id] = location.playerCanAccessShowroom
    employeeStatusCache[location.id] = location.playerIsEmployee == true
  else
    -- Fallback to server calls (for locations created/updated via admin panel)
    local showroomAllowed = lib.callback.await("jg-dealerships:server:check-showroom-whitelist", false, location.id)
    showroomPermissionCache[location.id] = showroomAllowed

    if location.type == "owned" then
      local result = lib.callback.await("jg-dealerships:server:is-employee", false, location.id, false)
      employeeStatusCache[location.id] = result and result.isEmployee or false
    end
  end

  -- Create all interaction types for this location
  for interactionType in pairs(interactionTypeConfigs) do
    createInteraction(location, interactionType)
  end

  DisplayVehicles.Client.UpsertLocation(location)
  DealershipZones.Client.CreateZone(location)
end

---Add a new location to cache and create its interactions
---@param location Location
function Locations.Client.AddLocation(location)
  if not location or not location.id then return end

  -- Add to cache
  cachedLocations[#cachedLocations + 1] = location

  -- Create interactions for this location
  createLocationInteractions(location)
end

---Update an existing location in cache and recreate its interactions
---@param location Location
function Locations.Client.UpdateLocation(location)
  if not location or not location.id then return end

  -- Remove existing interactions for this location
  Locations.Client.RemoveLocationInteractions(location.id)
  DealershipZones.Client.RemoveZone(location.id)

  -- Update cache
  for i, loc in ipairs(cachedLocations) do
    if loc.id == location.id then
      cachedLocations[i] = location
      break
    end
  end

  -- Recreate interactions for this location
  createLocationInteractions(location)
end

---Delete a location from cache and remove its interactions
---@param locationId string
function Locations.Client.DeleteLocation(locationId)
  if not locationId then return end

  -- Remove interactions
  Locations.Client.RemoveLocationInteractions(locationId)
  DealershipZones.Client.RemoveZone(locationId)
  DisplayVehicles.Client.DeleteLocation(locationId)

  -- Remove from cache
  for i, loc in ipairs(cachedLocations) do
    if loc.id == locationId then
      table.remove(cachedLocations, i)
      break
    end
  end

  -- Clear permission caches
  employeeStatusCache[locationId] = nil
  showroomPermissionCache[locationId] = nil
end

-- Event so we can re-create all dealership locations on all clients (use sparingly - prefer granular events)
RegisterNetEvent("jg-dealerships:client:create-dealership-locations", function(locations, ignoreCache)
  -- Prevent concurrent interaction creation
  if isCreatingInteractions then
    DebugPrint("[create-dealership-locations] Skipping - already creating interactions", "debug")
    return
  end
  isCreatingInteractions = true
  
  -- Immediately remove all existing interactions to ensure clean state
  Locations.Client.RemoveAllInteractions()
  DealershipZones.Client.RemoveAllZones()

  -- Small delay to allow cleanup to complete before recreating
  Wait(500)
  
  -- Release mutex before calling CreateAllInteractions (which has its own mutex check)
  isCreatingInteractions = false
  Locations.Client.CreateAllInteractions(locations, ignoreCache)
end)

-- Event to add a single new location
RegisterNetEvent("jg-dealerships:client:add-location", function(location)
  Locations.Client.AddLocation(location)
end)

-- Event to update a single location
RegisterNetEvent("jg-dealerships:client:update-location", function(location)
  Locations.Client.UpdateLocation(location)
end)

-- Event to delete a single location
RegisterNetEvent("jg-dealerships:client:delete-location", function(locationId)
  Locations.Client.DeleteLocation(locationId)
end)

-- Event when employee status changes (hired/fired/role update)
-- If dealershipId is provided, only refresh that location (used for built-in employee system)
-- If dealershipId is nil, refresh all locations (used for framework job changes)
RegisterNetEvent("jg-dealerships:client:employee-status-changed", function(dealershipId)
  if dealershipId then
    Locations.Client.RecreatePermissionRestrictedInteractionsForLocation(dealershipId)
  else
    Locations.Client.RecreatePermissionRestrictedInteractions()
  end
end)

lib.onCache("vehicle", recreateUsedVehicleGarageInteractions)
lib.onCache("seat", recreateUsedVehicleGarageInteractions)
AddStateBagChangeHandler("uvsPhysicalMode", "", refreshUsedVehicleGarageStateBag)
AddStateBagChangeHandler("uvsPhysicalSessionId", "", refreshUsedVehicleGarageStateBag)
AddEventHandler("jg-usedvehicles:client:physical-session-ready", recreateUsedVehicleGarageInteractions)
RegisterNetEvent("jg-usedvehicles:client:physical-vehicle-stored", recreateUsedVehicleGarageInteractions)
RegisterNetEvent("jg-usedvehicles:client:test-drive-ended", recreateUsedVehicleGarageInteractions)

-- On script start, listen to login state changes to create/remove interactions
CreateThread(function()
  Wait(1000)

  -- Handle case where player is already loaded (e.g. script restart)
  if Globals.PlayerLoggedIn and not hasInitiallyLoaded then
    Locations.Client.CreateAllInteractions()

    CreateThread(function()
      Wait(1000)
      lib.callback.await("jg-dealerships:server:exit-showroom", false)
    end)
  end

  -- React to future login state changes (handles fresh logins that fire after script start)
  AddEventHandler("jg-dealerships:client:player-login-state-changed", function(loggedIn)
    if not loggedIn then
      hasInitiallyLoaded = false
      Locations.Client.RemoveAllInteractions()
      DealershipZones.Client.RemoveAllZones()
      DisplayVehicles.Client.DeleteAll()
      return
    end

    if hasInitiallyLoaded then return end

    Locations.Client.CreateAllInteractions()

    CreateThread(function()
      Wait(1000)
      lib.callback.await("jg-dealerships:server:exit-showroom", false)
    end)
  end)
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
  if GetCurrentResourceName() ~= resourceName then return end
  
  Locations.Client.RemoveAllInteractions()
  DealershipZones.Client.RemoveAllZones()
end)
