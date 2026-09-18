-- Client-side handler for Ceramic Coating, Tire Plug Kit, and Jumpstarter Pack

-- 1. CERAMIC COATING APPLICATION
RegisterNetEvent("jg-mechanic:client:use-ceramic-coating", function()
  local ped = cache.ped or PlayerPedId()
  local coords = GetEntityCoords(ped)
  local vehicle = cache.vehicle or lib.getClosestVehicle(coords, 3.5, false)

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    return lib.notify({
      title = "Ceramic Coating",
      description = Locale.noVehicleNearby or "No vehicle nearby to apply ceramic coating!",
      type = "error"
    })
  end

  local success = lib.progressBar({
    duration = 7500,
    label = "Applying Ceramic Nano-Coating & Gloss Polish...",
    useWhileDead = false,
    canCancel = true,
    disable = {
      car = true,
      move = true,
      combat = true
    },
    anim = {
      dict = "timetable@floyd@clean_kitchen@base",
      clip = "base"
    }
  })

  if not success then return end

  local consumed = lib.callback.await("jg-mechanic:server:consume-roadside-item", false, "ceramic_coating")
  if not consumed then return end

  SetVehicleDirtLevel(vehicle, 0.0)
  WashDecalsFromVehicle(vehicle, 1.0)

  local netId = NetworkGetNetworkIdFromEntity(vehicle)
  if netId and netId ~= 0 then
    TriggerServerEvent("jg-mechanic:server:apply-ceramic-coating", netId)
  end
end)

-- Continuous Ceramic Coating protection loop
CreateThread(function()
  while true do
    local sleep = 2000
    if cache.vehicle and cache.vehicle ~= 0 and DoesEntityExist(cache.vehicle) then
      local state = Entity(cache.vehicle).state
      local expiry = state and state.ceramicCoated
      if expiry and expiry > GetCloudTimeAsInt() then
        sleep = 500
        if GetVehicleDirtLevel(cache.vehicle) > 0.1 then
          SetVehicleDirtLevel(cache.vehicle, 0.0)
        end
      end
    end
    Wait(sleep)
  end
end)

-- 2. EMERGENCY TIRE PLUG KIT
RegisterNetEvent("jg-mechanic:client:use-tire-plug", function()
  local ped = cache.ped or PlayerPedId()
  local coords = GetEntityCoords(ped)
  local vehicle = lib.getClosestVehicle(coords, 3.5, false)

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    return lib.notify({
      title = "Tire Plug Kit",
      description = Locale.noVehicleNearby or "No vehicle nearby to repair tire!",
      type = "error"
    })
  end

  -- Find flat/burst tires
  local burstTireFound = -1
  local numWheels = GetVehicleNumberOfWheels(vehicle)

  for i = 0, (numWheels - 1) do
    if IsVehicleTyreBurst(vehicle, i, false) then
      burstTireFound = i
      break
    end
  end

  if burstTireFound == -1 then
    return lib.notify({
      title = "Tire Plug Kit",
      description = "All tires on this vehicle are in good condition (no punctures detected).",
      type = "inform"
    })
  end

  local success = lib.progressBar({
    duration = 5000,
    label = "Inserting Tire Plug & Sealing Puncture...",
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

  local consumed = lib.callback.await("jg-mechanic:server:consume-roadside-item", false, "tire_plug_kit")
  if not consumed then return end

  SetVehicleTyreFixed(vehicle, burstTireFound)
  lib.notify({
    title = "Tire Plug Kit",
    description = "Punctured tire has been plugged and reinflated successfully!",
    type = "success"
  })
end)

-- 3. JUMPSTARTER BATTERY PACK
RegisterNetEvent("jg-mechanic:client:use-jumpstarter", function()
  local ped = cache.ped or PlayerPedId()
  local coords = GetEntityCoords(ped)
  local vehicle = lib.getClosestVehicle(coords, 3.5, false)

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    return lib.notify({
      title = "Jumpstarter Pack",
      description = Locale.noVehicleNearby or "No vehicle nearby to jumpstart!",
      type = "error"
    })
  end

  local engineHealth = GetVehicleEngineHealth(vehicle)
  if engineHealth >= 500.0 and IsVehicleEngineOn(vehicle) then
    return lib.notify({
      title = "Jumpstarter Pack",
      description = "The battery and engine are already in healthy running condition.",
      type = "inform"
    })
  end

  local success = lib.progressBar({
    duration = 6000,
    label = "Clamping 12V Terminals & Jumpstarting Battery...",
    useWhileDead = false,
    canCancel = true,
    disable = {
      car = true,
      move = true,
      combat = true
    },
    anim = {
      dict = "mini@repair",
      clip = "fixing_a_ped"
    }
  })

  if not success then return end

  local consumed = lib.callback.await("jg-mechanic:server:consume-roadside-item", false, "jumpstarter_pack")
  if not consumed then return end

  SetVehicleUndriveable(vehicle, false)
  if engineHealth < 350.0 then
    SetVehicleEngineHealth(vehicle, 350.0)
  end
  SetVehicleEngineOn(vehicle, true, true, false)

  lib.notify({
    title = "Jumpstarter Pack",
    description = "Engine jumpstarted successfully! The vehicle is running again.",
    type = "success"
  })
end)
