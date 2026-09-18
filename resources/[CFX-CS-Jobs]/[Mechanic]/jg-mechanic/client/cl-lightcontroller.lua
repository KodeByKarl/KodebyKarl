local xenonHue = 0
local underglowHue = 0
local xenonFlashState = false
local underglowFlashState = false
local isLoopActive = true
local hasControllerItem = false
local currentVehicle = nil

local function hsvToRgb(h, s, v)
  local r, g, b
  h = h * 360
  local C = v * s
  local X = C * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - C
  if h >= 0 and h < 60 then
    r, g, b = C, X, 0
  elseif h >= 60 and h < 120 then
    r, g, b = X, C, 0
  elseif h >= 120 and h < 180 then
    r, g, b = 0, C, X
  elseif h >= 180 and h < 240 then
    r, g, b = 0, X, C
  elseif h >= 240 and h < 300 then
    r, g, b = X, 0, C
  elseif h >= 300 and h <= 360 then
    r, g, b = C, 0, X
  end
  r = math.floor((r + m) * 255)
  g = math.floor((g + m) * 255)
  b = math.floor((b + m) * 255)
  return r, g, b
end

RegisterNUICallback("install-light-controller", function(data, cb)
  if not hasControllerItem or not currentVehicle then
    return cb(false)
  end

  Framework.Client.ProgressBar(Locale.installingLightingController, 2000, false, false, function()
    setVehicleStatebag(currentVehicle, "lightingControllerInstalled", true, true)
    cb(true)
  end, function()
    cb(false)
  end)
end)

RegisterNUICallback("update-light-controller", function(data, cb)
  if not hasControllerItem or not currentVehicle then
    return cb(false)
  end

  if not Entity(currentVehicle).state.lightingControllerInstalled then
    return cb(false)
  end

  SetVehicleModKit(currentVehicle, 0)

  if data.xenons then
    ToggleVehicleMod(currentVehicle, 22, true)
    SetVehicleLights(currentVehicle, data.xenons.enabled and 2 or 0)
    if data.xenons.effect == "solid" then
      local r, g, b = data.xenons.colour.r, data.xenons.colour.g, data.xenons.colour.b
      SetVehicleXenonLightsCustomColor(currentVehicle, r, g, b)
    end
    setVehicleStatebag(currentVehicle, "xenons", data.xenons, true)
  end

  if data.underglow then
    if not data.underglow.enabled then
      for i = 0, 3 do
        SetVehicleNeonLightEnabled(currentVehicle, i, false)
      end
    end
    if data.underglow.effect == "solid" then
      local r, g, b = data.underglow.colour.r, data.underglow.colour.g, data.underglow.colour.b
      SetVehicleNeonLightsColour(currentVehicle, r, g, b)
    end
    setVehicleStatebag(currentVehicle, "underglowDirections", data.underglowDirections, true)
    setVehicleStatebag(currentVehicle, "underglow", data.underglow, true)
  end
  cb(true)
end)

RegisterNUICallback("sync-light-controller", function(data, cb)
  if not hasControllerItem or not currentVehicle then
    return cb(false)
  end

  if not Entity(currentVehicle).state.lightingControllerInstalled then
    return cb(false)
  end

  CreateThread(function()
    underglowFlashState = false
    xenonFlashState = false
    underglowHue = 0
    xenonHue = 0
    isLoopActive = true
    Wait(500)
    isLoopActive = true
    cb(true)
  end)
end)

RegisterNUICallback("close-light-controller", function(data, cb)
  xenonHue = 0
  underglowHue = 0
  xenonFlashState = false
  underglowFlashState = false
  isLoopActive = true
  hasControllerItem = false
  currentVehicle = nil
  LocalPlayer.state:set("isBusy", false, true)
  SetNuiFocus(false, false)
  cb(true)
end)

RegisterNetEvent("jg-mechanic:client:show-lighting-controller", function()
  hasControllerItem = lib.callback.await("jg-mechanic:server:has-item", 250, "lighting_controller")
  if not hasControllerItem then
    return
  end

  if not cache.vehicle then
    return Framework.Client.Notify(Locale.notInsideVehicle, "error")
  end

  currentVehicle = cache.vehicle
  local model = GetEntityModel(currentVehicle)

  if not IsThisModelACar(model) and not IsThisModelAQuadbike(model) then
    return Framework.Client.Notify("ERR_VEHICLE_TYPE_INCOMPATIBLE", "error")
  end

  local vehicleState = Entity(currentVehicle).state
  LocalPlayer.state:set("isBusy", true, true)
  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "show-lighting-controller",
    installed = vehicleState.lightingControllerInstalled or false,
    xenons = vehicleState.xenons,
    underglow = vehicleState.underglow,
    underglowDirections = vehicleState.underglowDirections,
    locale = Locale,
    config = Config
  })
end)

CreateThread(function()
  while true do
    local playerPed = cache.ped
    if IsPedInAnyVehicle(playerPed, false) then
      local vehicle = GetVehiclePedIsIn(playerPed, false)
      local vehicleState = Entity(vehicle).state
      if vehicleState.underglow then
        while IsPedInVehicle(playerPed, vehicle, false) do
          if not vehicleState.lightingControllerInstalled or not vehicleState.underglow or not vehicleState.underglow.enabled or not isLoopActive then
            break
          end

          for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, vehicleState.underglowDirections[i + 1])
          end

          if vehicleState.underglow.effect == "solid" then
            break
          elseif vehicleState.underglow.effect == "rgb_cycle" then
            underglowHue = (underglowHue + 0.01) % 1
            local r, g, b = hsvToRgb(underglowHue, 1, 1)
            SetVehicleNeonLightsColour(vehicle, r, g, b)
            Wait(50 / (vehicleState.underglow.speed or 1))
          elseif vehicleState.underglow.effect == "flashing" then
            if underglowFlashState then
              SetVehicleNeonLightsColour(vehicle, 0, 0, 0)
              underglowFlashState = false
            else
              local r, g, b = vehicleState.underglow.colour.r, vehicleState.underglow.colour.g, vehicleState.underglow.colour.b
              SetVehicleNeonLightsColour(vehicle, r, g, b)
              underglowFlashState = true
            end
            Wait(200 / (vehicleState.underglow.speed or 1))
          else
            Wait(500)
          end
          vehicleState = Entity(vehicle).state
        end
      end
    end
    Wait(isLoopActive and 1000 or 1)
  end
end)

CreateThread(function()
  while true do
    local playerPed = cache.ped
    if IsPedInAnyVehicle(playerPed, false) then
      local vehicle = GetVehiclePedIsIn(playerPed, false)
      local vehicleState = Entity(vehicle).state
      if vehicleState.xenons then
        while IsPedInVehicle(playerPed, vehicle, false) do
          if not vehicleState.lightingControllerInstalled or not vehicleState.xenons or not vehicleState.xenons.enabled or not isLoopActive then
            break
          end

          if vehicleState.xenons then
            if vehicleState.xenons.effect == "solid" then
              break
            elseif vehicleState.xenons.effect == "rgb_cycle" then
              xenonHue = (xenonHue + 0.01) % 1
              local r, g, b = hsvToRgb(xenonHue, 1, 1)
              SetVehicleXenonLightsCustomColor(vehicle, r, g, b)
              Wait(50 / (vehicleState.xenons.speed or 1))
            elseif vehicleState.xenons.effect == "flashing" then
              if xenonFlashState then
                SetVehicleXenonLightsCustomColor(vehicle, 0, 0, 0)
                xenonFlashState = false
              else
                local r, g, b = vehicleState.xenons.colour.r, vehicleState.xenons.colour.g, vehicleState.xenons.colour.b
                SetVehicleXenonLightsCustomColor(vehicle, r, g, b)
                xenonFlashState = true
              end
              Wait(200 / (vehicleState.xenons.speed or 1))
            else
              Wait(500)
            end
            vehicleState = Entity(vehicle).state
          end
        end
      end
    end
    Wait(isLoopActive and 1000 or 1)
  end
end)
