local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1
L0_1 = false
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if not A0_2 or 0 == A0_2 then
    return
  end
  L1_2 = cache
  L1_2 = L1_2.seat
  if -1 ~= L1_2 then
    return
  end
  L1_2 = GetVehicleType
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "sea" ~= L1_2 then
    return
  end
  L1_2 = GetEntitySpeed
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2 * 2.2
  if L1_2 > 5 then
    return
  end
  L1_2 = _ENV
  L2_2 = "SetBoatRemainsAnchoredWhilePlayerIsDriver"
  L1_2 = L1_2[L2_2]
  L2_2 = A0_2
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = IsBoatAnchored
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = SetBoatAnchor
  L3_2 = A0_2
  L4_2 = not L1_2
  L2_2(L3_2, L4_2)
end
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if not A0_2 or 0 == A0_2 then
    return
  end
  L1_2 = cache
  L1_2 = L1_2.seat
  if -1 ~= L1_2 then
    return
  end
  L1_2 = Framework
  L1_2 = L1_2.Client
  L1_2 = L1_2.ToggleEngine
  L2_2 = A0_2
  L3_2 = GetIsVehicleEngineRunning
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L3_2 = not L3_2
  L1_2(L2_2, L3_2)
end
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = cache
  L2_2 = L2_2.vehicle
  if L2_2 then
    L2_2 = cache
    L2_2 = L2_2.vehicle
    if 0 ~= L2_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L2_2 = GetVehicleLightsState
  L3_2 = cache
  L3_2 = L3_2.vehicle
  L2_2, L3_2, L4_2 = L2_2(L3_2)
  L5_2 = cache
  L5_2 = L5_2.seat
  L5_2 = -1 ~= L5_2
  if "TOGGLE_ENGINE" == A0_2 and not L5_2 then
    L6_2 = L2_1
    L7_2 = cache
    L7_2 = L7_2.vehicle
    L6_2(L7_2)
  elseif "INDICATE" == A0_2 and not L5_2 then
    L6_2 = Indicate
    L7_2 = A1_2
    L6_2(L7_2)
  elseif "TOGGLE_SEATBELT" == A0_2 then
    L6_2 = ToggleSeatbelt
    L7_2 = cache
    L7_2 = L7_2.vehicle
    L8_2 = IsSeatbeltOn
    L8_2 = not L8_2
    L6_2(L7_2, L8_2)
  elseif "TOGGLE_CRUISE_CONTROL" == A0_2 and not L5_2 then
    L6_2 = ToggleCruiseControl
    L7_2 = cache
    L7_2 = L7_2.vehicle
    L8_2 = cache
    L8_2 = L8_2.seat
    L6_2(L7_2, L8_2)
  elseif "TOGGLE_HEADLIGHTS" == A0_2 and not L5_2 then
    L6_2 = GetIsVehicleEngineRunning
    L7_2 = cache
    L7_2 = L7_2.vehicle
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      return
    end
    L6_2 = SetVehicleLights
    L7_2 = cache
    L7_2 = L7_2.vehicle
    if not L3_2 and not L4_2 then
      L8_2 = 3
      if L8_2 then
        goto lbl_79
      end
    end
    L8_2 = 4
    ::lbl_79::
    L6_2(L7_2, L8_2)
  elseif "TOGGLE_INTERIOR_LIGHT" == A0_2 and not L5_2 then
    L6_2 = SetVehicleInteriorlight
    L7_2 = cache
    L7_2 = L7_2.vehicle
    L8_2 = IsVehicleInteriorLightOn
    L9_2 = cache
    L9_2 = L9_2.vehicle
    L8_2 = L8_2(L9_2)
    L8_2 = not L8_2
    L6_2(L7_2, L8_2)
  else
    if "TOGGLE_VEHICLE_DOOR" == A0_2 then
      if L5_2 then
        L6_2 = cache
        L6_2 = L6_2.seat
        L7_2 = A1_2 - 1
        if L6_2 ~= L7_2 then
          goto lbl_132
        end
      end
      L6_2 = GetVehicleDoorAngleRatio
      L7_2 = cache
      L7_2 = L7_2.vehicle
      L8_2 = A1_2
      L6_2 = L6_2(L7_2, L8_2)
      L7_2 = 0.01
      L6_2 = L6_2 > L7_2
      if L6_2 then
        L7_2 = SetVehicleDoorShut
        L8_2 = cache
        L8_2 = L8_2.vehicle
        L9_2 = A1_2
        L10_2 = false
        L7_2(L8_2, L9_2, L10_2)
      else
        L7_2 = SetVehicleDoorOpen
        L8_2 = cache
        L8_2 = L8_2.vehicle
        L9_2 = A1_2
        L10_2 = false
        L11_2 = false
        L7_2(L8_2, L9_2, L10_2, L11_2)
      end
    ::lbl_132::
    else
      if "TOGGLE_VEHICLE_WINDOW" == A0_2 then
        if L5_2 then
          L6_2 = cache
          L6_2 = L6_2.seat
          L7_2 = A1_2 - 1
          if L6_2 ~= L7_2 then
            goto lbl_161
          end
        end
        L6_2 = IsVehicleWindowIntact
        L7_2 = cache
        L7_2 = L7_2.vehicle
        L8_2 = A1_2
        L6_2 = L6_2(L7_2, L8_2)
        if L6_2 then
          L7_2 = RollDownWindow
          L8_2 = cache
          L8_2 = L8_2.vehicle
          L9_2 = A1_2
          L7_2(L8_2, L9_2)
        else
          L7_2 = RollUpWindow
          L8_2 = cache
          L8_2 = L8_2.vehicle
          L9_2 = A1_2
          L7_2(L8_2, L9_2)
        end
      ::lbl_161::
      elseif "SET_VEHICLE_SEAT" == A0_2 then
        L6_2 = TaskWarpPedIntoVehicle
        L7_2 = cache
        L7_2 = L7_2.ped
        L8_2 = cache
        L8_2 = L8_2.vehicle
        L9_2 = A1_2
        L6_2(L7_2, L8_2, L9_2)
      elseif "TOGGLE_ANCHOR" == A0_2 and not L5_2 then
        L6_2 = L1_1
        L7_2 = cache
        L7_2 = L7_2.vehicle
        L6_2(L7_2)
      elseif "TOGGLE_GEAR" == A0_2 and not L5_2 then
        L6_2 = ControlLandingGear
        L7_2 = cache
        L7_2 = L7_2.vehicle
        L8_2 = GetLandingGearState
        L9_2 = cache
        L9_2 = L9_2.vehicle
        L8_2 = L8_2(L9_2)
        if 0 == L8_2 then
          L8_2 = 1
          if L8_2 then
            goto lbl_197
          end
        end
        L8_2 = 2
        ::lbl_197::
        L6_2(L7_2, L8_2)
      elseif "TOGGLE_CONVERTIBLE_ROOF" == A0_2 and not L5_2 then
        L6_2 = GetConvertibleRoofState
        L7_2 = cache
        L7_2 = L7_2.vehicle
        L6_2 = L6_2(L7_2)
        L6_2 = 0 == L6_2
        if L6_2 then
          L7_2 = LowerConvertibleRoof
          L8_2 = cache
          L8_2 = L8_2.vehicle
          L9_2 = false
          L7_2(L8_2, L9_2)
        else
          L7_2 = RaiseConvertibleRoof
          L8_2 = cache
          L8_2 = L8_2.vehicle
          L9_2 = false
          L7_2(L8_2, L9_2)
        end
      end
    end
  end
end
function L4_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L0_2 = cache
  L0_2 = L0_2.vehicle
  if L0_2 then
    L0_2 = cache
    L0_2 = L0_2.vehicle
    if 0 ~= L0_2 then
      goto lbl_11
    end
  end
  L0_2 = false
  do return L0_2 end
  ::lbl_11::
  L0_2 = GetVehicleLightsState
  L1_2 = cache
  L1_2 = L1_2.vehicle
  L0_2, L1_2, L2_2 = L0_2(L1_2)
  L3_2 = GetNumberOfVehicleDoors
  L4_2 = cache
  L4_2 = L4_2.vehicle
  L3_2 = L3_2(L4_2)
  L4_2 = GetVehicleModelNumberOfSeats
  L5_2 = GetEntityModel
  L6_2 = cache
  L6_2 = L6_2.vehicle
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L5_2 = cache
  L5_2 = L5_2.seat
  L5_2 = -1 ~= L5_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = {}
  L9_2 = {}
  L10_2 = {}
  L11_2 = 0
  L12_2 = 6
  L13_2 = 1
  for L14_2 = L11_2, L12_2, L13_2 do
    L15_2 = GetVehicleDoorAngleRatio
    L16_2 = cache
    L16_2 = L16_2.vehicle
    L17_2 = L14_2
    L15_2 = L15_2(L16_2, L17_2)
    L16_2 = 0.01
    L15_2 = L15_2 > L16_2
    L6_2[L14_2] = L15_2
    if L5_2 then
      L15_2 = cache
      L15_2 = L15_2.seat
      L16_2 = L14_2 - 1
    end
    L15_2 = DoesVehicleHaveDoor
    L16_2 = cache
    L16_2 = L16_2.vehicle
    L17_2 = L14_2
    L15_2 = L15_2 == L16_2 and L15_2
    L7_2[L14_2] = L15_2
  end
  L11_2 = -1
  L12_2 = L4_2
  L13_2 = 1
  for L14_2 = L11_2, L12_2, L13_2 do
    L15_2 = GetPedInVehicleSeat
    L16_2 = cache
    L16_2 = L16_2.vehicle
    L17_2 = L14_2
    L15_2 = L15_2(L16_2, L17_2)
    L16_2 = cache
    L16_2 = L16_2.ped
    if L15_2 == L16_2 then
      L15_2 = "IN_SEAT"
      if L15_2 then
        goto lbl_101
      end
    end
    L15_2 = IsVehicleSeatFree
    L16_2 = cache
    L16_2 = L16_2.vehicle
    L17_2 = L14_2
    L15_2 = L15_2(L16_2, L17_2)
    if not L15_2 then
      L15_2 = "OCCUPIED"
      if L15_2 then
        goto lbl_101
      end
    end
    L15_2 = false
    ::lbl_101::
    L10_2[L14_2] = L15_2
  end
  L11_2 = 0
  L12_2 = L4_2 - 1
  L13_2 = 1
  for L14_2 = L11_2, L12_2, L13_2 do
    L15_2 = IsVehicleWindowIntact
    L16_2 = cache
    L16_2 = L16_2.vehicle
    L17_2 = L14_2
    L15_2 = L15_2(L16_2, L17_2)
    L15_2 = not L15_2
    L8_2[L14_2] = L15_2
    L15_2 = not L5_2
    L9_2[L14_2] = L15_2
  end
  L11_2 = {}
  L12_2 = GetIsVehicleEngineRunning
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L12_2 = L12_2(L13_2)
  L11_2.engineStatus = L12_2
  L12_2 = IsVehicleIndicating
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L14_2 = "left"
  L12_2 = L12_2(L13_2, L14_2)
  L11_2.indicatingLeft = L12_2
  L12_2 = IsVehicleIndicating
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L14_2 = "right"
  L12_2 = L12_2(L13_2, L14_2)
  L11_2.indicatingRight = L12_2
  L12_2 = IsVehicleIndicating
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L14_2 = "hazards"
  L12_2 = L12_2(L13_2, L14_2)
  L11_2.hazards = L12_2
  L11_2.isPassenger = L5_2
  L12_2 = IsSeatbeltOn
  L11_2.seatbelt = L12_2
  L12_2 = IsCruiseControlEnabled
  L11_2.cruiseControl = L12_2
  L11_2.headlights = L1_2
  L11_2.highBeams = L2_2
  L12_2 = IsVehicleInteriorLightOn
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L12_2 = L12_2(L13_2)
  L11_2.interiorLight = L12_2
  L12_2 = 6 == L3_2
  L11_2.bonnetOpen = L12_2
  L12_2 = 6 == L3_2
  L11_2.bootOpen = L12_2
  L11_2.doors = L6_2
  L12_2 = IsVehicleAConvertible
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L14_2 = false
  L12_2 = L12_2(L13_2, L14_2)
  L11_2.isConvertible = L12_2
  L12_2 = GetConvertibleRoofState
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L12_2 = L12_2(L13_2)
  L12_2 = 0 == L12_2
  L11_2.convertibleRoofRaised = L12_2
  L11_2.availableDoors = L7_2
  L11_2.windows = L8_2
  L11_2.availableWindows = L9_2
  L11_2.seats = L10_2
  L11_2.seatsCount = L4_2
  L12_2 = IsBoatAnchored
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L12_2 = L12_2(L13_2)
  L11_2.anchored = L12_2
  L12_2 = GetLandingGearState
  L13_2 = cache
  L13_2 = L13_2.vehicle
  L12_2 = L12_2(L13_2)
  L12_2 = 0 == L12_2
  L11_2.gear = L12_2
  return L11_2
end
function L5_1()
  local L0_2, L1_2
  L0_2 = UserSettingsData
  if L0_2 then
    L0_2 = L0_2.performanceMode
  end
  if "ultra" == L0_2 then
    L0_2 = 50
    return L0_2
  end
  L0_2 = UserSettingsData
  if L0_2 then
    L0_2 = L0_2.performanceMode
  end
  if "performance" == L0_2 then
    L0_2 = 100
    return L0_2
  end
  L0_2 = UserSettingsData
  if L0_2 then
    L0_2 = L0_2.performanceMode
  end
  if "lowResmon" == L0_2 then
    L0_2 = 500
    return L0_2
  end
  L0_2 = 200
  return L0_2
end
function L6_1()
  local L0_2, L1_2, L2_2
  L0_2 = L0_1
  if L0_2 then
    return
  end
  L0_2 = cache
  L0_2 = L0_2.vehicle
  if not L0_2 then
    return
  end
  L0_2 = true
  L0_1 = L0_2
  L0_2 = L5_1
  L0_2 = L0_2()
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3
    while true do
      L0_3 = L0_1
      if not L0_3 then
        break
      end
      L0_3 = DisableControlAction
      L1_3 = 0
      L2_3 = 1
      L3_3 = true
      L0_3(L1_3, L2_3, L3_3)
      L0_3 = DisableControlAction
      L1_3 = 0
      L2_3 = 2
      L3_3 = true
      L0_3(L1_3, L2_3, L3_3)
      L0_3 = DisableControlAction
      L1_3 = 1
      L2_3 = 199
      L3_3 = true
      L0_3(L1_3, L2_3, L3_3)
      L0_3 = DisableControlAction
      L1_3 = 1
      L2_3 = 200
      L3_3 = true
      L0_3(L1_3, L2_3, L3_3)
      L0_3 = Wait
      L1_3 = 0
      L0_3(L1_3)
    end
  end
  L1_2(L2_2)
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3
    L0_3 = Wait
    L1_3 = 1
    L0_3(L1_3)
    while true do
      L0_3 = L0_1
      if not L0_3 then
        break
      end
      L0_3 = L4_1
      L0_3 = L0_3()
      if not L0_3 then
        L1_3 = ToggleVehicleControl
        L2_3 = false
        L1_3(L2_3)
        L1_3 = SendNUIMessage
        L2_3 = {}
        L2_3.type = "closeVehicleControls"
        L1_3(L2_3)
        break
      end
      L1_3 = SendNUIMessage
      L2_3 = {}
      L2_3.type = "vehicleControlsStateData"
      L2_3.data = L0_3
      L1_3(L2_3)
      L1_3 = Wait
      L2_3 = L0_2
      L1_3(L2_3)
    end
  end
  L1_2(L2_2)
end
function L7_1(A0_2)
  local L1_2, L2_2, L3_2
  if not A0_2 then
    L1_2 = SetNuiFocus
    L2_2 = false
    L3_2 = false
    L1_2(L2_2, L3_2)
    L1_2 = SetNuiFocusKeepInput
    L2_2 = false
    L1_2(L2_2)
    L1_2 = false
    L0_1 = L1_2
    return
  end
  L1_2 = L0_1
  if L1_2 then
    return
  end
  L1_2 = IsPauseMenuActive
  L1_2 = L1_2()
  if L1_2 then
    return
  end
  L1_2 = cache
  L1_2 = L1_2.vehicle
  if not L1_2 then
    return
  end
  L1_2 = cache
  L1_2 = L1_2.seat
  if -1 ~= L1_2 then
    L1_2 = Config
    L1_2 = L1_2.AllowPassengersToUseVehicleControl
    if not L1_2 then
      return
    end
  end
  L1_2 = SetNuiFocus
  L2_2 = true
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = SetNuiFocusKeepInput
  L2_2 = true
  L1_2(L2_2)
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.type = "showVehicleControls"
  L1_2(L2_2)
  L1_2 = L6_1
  L1_2()
end
ToggleVehicleControl = L7_1
L7_1 = RegisterNUICallback
L8_1 = "vehicleControlAction"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A0_2 then
    L2_2 = A0_2.action
    if L2_2 then
      goto lbl_12
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.error = true
  do return L2_2(L3_2) end
  ::lbl_12::
  L2_2 = cache
  L2_2 = L2_2.vehicle
  if L2_2 then
    L2_2 = cache
    L2_2 = L2_2.vehicle
    if 0 ~= L2_2 then
      goto lbl_26
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.error = true
  do return L2_2(L3_2) end
  ::lbl_26::
  L2_2 = L3_1
  L3_2 = A0_2.action
  L4_2 = A0_2.value
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = true
  L2_2(L3_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNUICallback
L8_1 = "closeVehicleControls"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = ToggleVehicleControl
  L3_2 = false
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = true
  L2_2(L3_2)
end
L7_1(L8_1, L9_1)
L7_1 = Config
L7_1 = L7_1.VehicleControlKeybind
if L7_1 then
  L7_1 = RegisterCommand
  L8_1 = "open_vehicle_controls"
  function L9_1()
    local L0_2, L1_2
    L0_2 = ToggleVehicleControl
    L1_2 = true
    L0_2(L1_2)
  end
  L7_1(L8_1, L9_1)
  L7_1 = RegisterKeyMapping
  L8_1 = "open_vehicle_controls"
  L9_1 = "Open vehicle control menu"
  L10_1 = "keyboard"
  L11_1 = Config
  L11_1 = L11_1.VehicleControlKeybind
  if not L11_1 then
    L11_1 = "F6"
  end
  L7_1(L8_1, L9_1, L10_1, L11_1)
end
L7_1 = Config
L7_1 = L7_1.BoatAnchorKeybind
if L7_1 then
  L7_1 = RegisterCommand
  L8_1 = "anchor_boat"
  function L9_1()
    local L0_2, L1_2
    L0_2 = L1_1
    L1_2 = cache
    L1_2 = L1_2.vehicle
    L0_2(L1_2)
  end
  L7_1(L8_1, L9_1)
  L7_1 = RegisterKeyMapping
  L8_1 = "anchor_boat"
  L9_1 = "Anchor boat"
  L10_1 = "keyboard"
  L11_1 = Config
  L11_1 = L11_1.BoatAnchorKeybind
  if not L11_1 then
    L11_1 = "J"
  end
  L7_1(L8_1, L9_1, L10_1, L11_1)
end
L7_1 = Config
L7_1 = L7_1.EngineToggleKeybind
if L7_1 then
  L7_1 = RegisterCommand
  L8_1 = "toggle_engine"
  function L9_1()
    local L0_2, L1_2
    L0_2 = L2_1
    L1_2 = cache
    L1_2 = L1_2.vehicle
    L0_2(L1_2)
  end
  L7_1(L8_1, L9_1)
  L7_1 = RegisterKeyMapping
  L8_1 = "toggle_engine"
  L9_1 = "Toggle vehicle engine"
  L10_1 = "keyboard"
  L11_1 = Config
  L11_1 = L11_1.EngineToggleKeybind
  if not L11_1 then
    L11_1 = "G"
  end
  L7_1(L8_1, L9_1, L10_1, L11_1)
end
L7_1 = exports
L8_1 = "toggleVehicleControl"
function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = ToggleVehicleControl
  L2_2 = A0_2
  L1_2(L2_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNetEvent
L8_1 = "jg-hud:client:toggle-vehicle-control"
function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = ToggleVehicleControl
  L2_2 = A0_2
  L1_2(L2_2)
end
L7_1(L8_1, L9_1)
