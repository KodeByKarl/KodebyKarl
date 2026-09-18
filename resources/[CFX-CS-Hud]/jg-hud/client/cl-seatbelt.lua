IsSeatbeltOn = true
local seatbeltThreadCreated = false
local noEjectThreadCreated = false

---Can vehicle class have a seatbelt? Disabled for bikes, motorcycles boats etc by default
---@param vehicle integer
---@return boolean canHaveSeatbelt
local function canVehicleClassHaveSeatbelt(vehicle)
  if not Config.EnableSeatbelt then return false end

  if not vehicle or not DoesEntityExist(vehicle) then
    return false
  end
  
  local vehicleClass = GetVehicleClass(vehicle)
  
  local seatbeltCompatibleClasses = {
    [0] = true,  -- Compacts
    [1] = true,  -- Sedans
    [2] = true,  -- SUVs
    [3] = true,  -- Coupes
    [4] = true,  -- Muscle
    [5] = true,  -- Sports Classics
    [6] = true,  -- Sports
    [7] = true,  -- Super
    [9] = true,  -- Off-road
    [10] = true, -- Industrial
    [11] = true, -- Utility
    [12] = true, -- Vans
    [17] = true, -- Service
    [18] = true, -- Emergency
    [19] = true, -- Military
    [20] = true, -- Commercial
  }
  
  -- Excluded veh classes (no seatbelt UI — must NEVER eject/unseat)
  -- [8] = Motorcycles
  -- [13] = Cycles/Bicycles
  -- [14] = Boats
  -- [15] = Helicopters
  -- [16] = Planes
  -- [21] = Trains
  
  return seatbeltCompatibleClasses[vehicleClass] or false
end

---Is a seatbelt allowed in this particular vehicle? Checks emergency vehicles, passenger seats etc
---@param vehicle integer
---@return boolean isSeatbeltAllowed
local function isSeatbeltAllowed(vehicle)
  if not Config.EnableSeatbelt then return false end
  if not vehicle then return false end
  
  if not canVehicleClassHaveSeatbelt(vehicle) then
    return false
  end

  if Config.DisablePassengerSeatbelts and cache.seat ~= -1 then
    return false
  end
  
  if Config.DisableSeatbeltInEmergencyVehicles then
    local vehicleClass = GetVehicleClass(vehicle)
    if vehicleClass == 18 then -- Emergency vehicles
      return false
    end
  end
  
  return true
end

---Simple built in seatbelt system using "fly through windscreen" natives
---@param willBeYeeted boolean
local function setWhetherPedWillFlyThroughWindscreen(willBeYeeted)
  local min = willBeYeeted and Config.MinSpeedMphEjectionSeatbeltOff or Config.MinSpeedMphEjectionSeatbeltOn
  local minConverted = min / 2.237

  SetFlyThroughWindscreenParams(minConverted, 1.0, 1.0, 0.0)
  SetPedConfigFlag(cache.ped, 32, willBeYeeted) -- 32 = Can fly through windscreen
end

---Lock ped into seat for vehicles with no seatbelt (heli/boat/plane/bike).
---GTA resets flag 32 — must re-apply every frame or players randomly unseat (white flash).
local function startNoEjectHoldThread()
  if noEjectThreadCreated then return end
  noEjectThreadCreated = true

  CreateThread(function()
    while cache.vehicle and not isSeatbeltAllowed(cache.vehicle) do
      local ped = cache.ped
      SetPedConfigFlag(ped, 32, false)
      SetPedCanBeKnockedOffVehicle(ped, 1) -- KNOCKOFFVEHICLE_NEVER
      SetFlyThroughWindscreenParams(10000.0, 1.0, 1.0, 0.0)
      Wait(0)
    end

    noEjectThreadCreated = false
  end)
end

---GTA resets flag 32; keep re-applying while in a seatbelt-compatible vehicle
local function startSeatbeltHoldThread()
  if seatbeltThreadCreated then return end
  seatbeltThreadCreated = true

  CreateThread(function()
    while cache.vehicle and isSeatbeltAllowed(cache.vehicle) do
      local ped = cache.ped
      if IsSeatbeltOn then
        SetPedConfigFlag(ped, 32, false)
        SetPedCanBeKnockedOffVehicle(ped, 1)
        if Config.PreventExitWhileBuckled then
          DisableControlAction(0, 75, true)
          DisableControlAction(27, 75, true)
        end
        Wait(0)
      else
        SetPedConfigFlag(ped, 32, true)
        SetPedCanBeKnockedOffVehicle(ped, 0) -- default
        Wait(100)
      end
    end

    seatbeltThreadCreated = false
  end)
end

---Toggle seatbelt main function
---@param vehicle integer
---@param toggle boolean
function ToggleSeatbelt(vehicle, toggle)
  if not vehicle or not isSeatbeltAllowed(vehicle) then
    return
  end

  IsSeatbeltOn = toggle
  LocalPlayer.state:set("seatbelt", toggle) -- for integrations with other scripts, like jg-stress-addon

  if Config.UseCustomSeatbeltIntegration then
    Framework.Client.ToggleSeatbelt(vehicle, toggle)
  else
    setWhetherPedWillFlyThroughWindscreen(not toggle)
  end
end

---When entering vehicle
---@param vehicle integer
local function onEnterVehicle(vehicle)
  if not vehicle or vehicle == 0 then return end

  -- Heli / boat / plane / bike: never eject or force-unseat
  if not isSeatbeltAllowed(vehicle) then
    IsSeatbeltOn = false -- do not trigger buckled exit thread
    LocalPlayer.state:set("seatbelt", false)
    setWhetherPedWillFlyThroughWindscreen(false)
    SetPedCanBeKnockedOffVehicle(cache.ped, 1)
    startNoEjectHoldThread()
    return
  end

  ToggleSeatbelt(vehicle, false) -- Seatbelt is off when entering vehicle
  startSeatbeltHoldThread()
end

if Config.EnableSeatbelt then
  lib.onCache("vehicle", function(value)
    if value then
      onEnterVehicle(value)
    else
      -- Leaving any vehicle: clear knockoff / windscreen state
      SetPedConfigFlag(cache.ped, 32, false)
      SetPedCanBeKnockedOffVehicle(cache.ped, 0)
      SetFlyThroughWindscreenParams(10000.0, 1.0, 1.0, 0.0)
      IsSeatbeltOn = false
      LocalPlayer.state:set("seatbelt", false)
    end
  end)

  CreateThread(function()
    if cache.vehicle then
      onEnterVehicle(cache.vehicle)
    end
  end)
end

-- Key mapping
if Config.EnableSeatbelt and Config.SeatbeltKeybind then
  RegisterCommand("toggle_seatbelt", function()
    ToggleSeatbelt(cache.vehicle, not IsSeatbeltOn)
  end, false)

  RegisterKeyMapping("toggle_seatbelt", "Toggle vehicle seatbelt", "keyboard", Config.SeatbeltKeybind or "B")
end

-- Exit while buckled: only for real seatbelt vehicles (never heli/boat/plane)
if Config.EnableSeatbelt then
  CreateThread(function()
    while true do
      local sleep = 400
      local vehicle = cache.vehicle
      if vehicle and IsSeatbeltOn and isSeatbeltAllowed(vehicle) then
        sleep = 0
        if IsControlJustPressed(0, 75) or IsDisabledControlJustPressed(0, 75) then
          ToggleSeatbelt(vehicle, false)
          TaskLeaveVehicle(cache.ped or PlayerPedId(), vehicle, 0)
        end
      end
      Wait(sleep)
    end
  end)
end
