local CAR_LIFT_PLATFORM_HASH = -1375594465
local CAR_LIFT_STAND_HASH = -277236775

local createdCarLifts = {}
local carLiftsInitialized = false

local function createCarLift(x, y, z, heading)
  local platform = CreateObjectNoOffset(CAR_LIFT_PLATFORM_HASH, x, y, z - 1.025, true, true, true)
  
  if not platform then
    return false, false
  end
  
  while not DoesEntityExist(platform) do
    Wait(1)
  end
  
  SetEntityHeading(platform, heading)
  FreezeEntityPosition(platform, true)
  
  local stand = CreateObjectNoOffset(CAR_LIFT_STAND_HASH, x, y, z - 1.0, true, true, true)
  
  if not stand then
    return false, false
  end
  
  while not DoesEntityExist(stand) do
    Wait(1)
  end
  
  SetEntityHeading(stand, heading)
  FreezeEntityPosition(stand, true)
  
  local platformNetId = NetworkGetNetworkIdFromEntity(platform)
  local standNetId = NetworkGetNetworkIdFromEntity(stand)
  
  return platformNetId, standNetId
end

local function initializeCarLifts()
  carLiftsInitialized = true
  
  if GlobalState.carLiftsData then
    for mechanicId, lifts in pairs(GlobalState.carLiftsData) do
      for _, lift in ipairs(lifts) do
        DeleteEntity(NetworkGetEntityFromNetworkId(lift.platform))
        DeleteEntity(NetworkGetEntityFromNetworkId(lift.stand))
      end
    end
  end
  
  local carLiftsData = {}
  
  for mechanicId, location in pairs(Config.MechanicLocations) do
    if location.carLifts then
      if carLiftsData[mechanicId] and #carLiftsData[mechanicId] ~= 0 then
        goto continue
      end
      
      for index, coords in ipairs(location.carLifts) do
        local platformNetId, standNetId = createCarLift(coords.x, coords.y, coords.z, coords.w)
        
        if not platformNetId or not standNetId then
          return false
        end
        
        if not carLiftsData[mechanicId] then
          carLiftsData[mechanicId] = {}
        end
        
        table.insert(carLiftsData[mechanicId], {
          platform = platformNetId,
          stand = standNetId,
          coords = coords
        })
      end
    end
    
    ::continue::
  end
  
  createdCarLifts = carLiftsData
  GlobalState:set("carLiftsData", carLiftsData)
end

lib.callback.register("jg-mechanic:server:get-created-lifts", function()
  if not carLiftsInitialized then
    initializeCarLifts()
  end
  
  lib.waitFor(function()
    if createdCarLifts then
      return true
    end
  end, "Lifts say they have been created, but they are still false", 30000)
  
  return createdCarLifts
end)
