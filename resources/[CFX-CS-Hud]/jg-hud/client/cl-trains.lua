local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1
L0_1 = 50.0
L1_1 = nil
L2_1 = nil
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = math
  L2_2 = L2_2.round
  L3_2 = vector3
  L4_2 = A0_2.x
  L5_2 = A0_2.y
  L6_2 = A0_2.z
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = vector3
  L5_2 = A1_2.x
  L6_2 = A1_2.y
  L7_2 = A1_2.z
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L3_2 = L3_2 - L4_2
  L3_2 = #L3_2
  return L2_2(L3_2)
end
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = math
  L2_2 = L2_2.deg
  L3_2 = math
  L3_2 = L3_2.atan
  L4_2 = A1_2.y
  L5_2 = A0_2.y
  L4_2 = L4_2 - L5_2
  L5_2 = A1_2.x
  L6_2 = A0_2.x
  L5_2 = L5_2 - L6_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2, L5_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  L3_2 = L2_2 + 360
  L3_2 = L3_2 % 360
  return L3_2
end
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = nil
  L2_2 = math
  L2_2 = L2_2.huge
  L3_2 = pairs
  L4_2 = Config
  L4_2 = L4_2.TrainMetroStations
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L3_1
    L10_2 = A0_2
    L11_2 = L8_2.coords
    L9_2 = L9_2(L10_2, L11_2)
    if L2_2 > L9_2 then
      L10_2 = L7_2
      L2_2 = L9_2
      L1_2 = L10_2
    end
  end
  L3_2 = L1_2
  L4_2 = L2_2
  return L3_2, L4_2
end
function L6_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = math
  L2_2 = L2_2.abs
  L3_2 = A0_2 - A1_2
  L3_2 = L3_2 + 180
  L3_2 = L3_2 % 360
  L3_2 = L3_2 - 180
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2 <= 90
  return L3_2
end
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = GetEntityCoords
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = GetEntityHeading
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = L5_1
  L4_2 = L1_2
  L3_2, L4_2 = L3_2(L4_2)
  L5_2 = L0_1
  if L4_2 <= L5_2 then
    L5_2 = Config
    L5_2 = L5_2.TrainMetroStations
    L5_2 = L5_2[L3_2]
    L6_2 = L5_2.nextStation
    L6_2 = L6_2.Northbound
    L7_2 = L5_2.nextStation
    L7_2 = L7_2.Southbound
    L8_2 = L6_2.s
    if L8_2 then
      L8_2 = L6_1
      L9_2 = L2_2
      L10_2 = L6_2.h
      L8_2 = L8_2(L9_2, L10_2)
      if L8_2 then
        L8_2 = "Northbound"
        L1_1 = L3_2
        L2_1 = L8_2
    end
    else
      L8_2 = L7_2.s
      if L8_2 then
        L8_2 = L6_1
        L9_2 = L2_2
        L10_2 = L7_2.h
        L8_2 = L8_2(L9_2, L10_2)
        if L8_2 then
          L8_2 = "Southbound"
          L1_1 = L3_2
          L2_1 = L8_2
        end
      end
    end
    L8_2 = {}
    L8_2.atStation = true
    L9_2 = L5_2.name
    L8_2.currentStation = L9_2
    L8_2.nextStation = ""
    L8_2.stationDistance = 0
    L8_2.stationHeading = 0
    return L8_2
  else
    L5_2 = L1_1
    if L5_2 then
      L5_2 = L2_1
      if L5_2 then
        L5_2 = Config
        L5_2 = L5_2.TrainMetroStations
        L6_2 = L1_1
        L5_2 = L5_2[L6_2]
        L5_2 = L5_2.nextStation
        L6_2 = L2_1
        L5_2 = L5_2[L6_2]
        L5_2 = L5_2.s
        if L5_2 then
          L6_2 = Config
          L6_2 = L6_2.TrainMetroStations
          L6_2 = L6_2[L5_2]
          L7_2 = L3_1
          L8_2 = L1_2
          L9_2 = L6_2.coords
          L7_2 = L7_2(L8_2, L9_2)
          L8_2 = L4_1
          L9_2 = L1_2
          L10_2 = L6_2.coords
          L8_2 = L8_2(L9_2, L10_2)
          L9_2 = {}
          L9_2.atStation = false
          L10_2 = L6_2.name
          L9_2.nextStation = L10_2
          L10_2 = Framework
          L10_2 = L10_2.Client
          L10_2 = L10_2.ConvertDistance
          L11_2 = L7_2
          L12_2 = UserSettingsData
          if L12_2 then
            L12_2 = L12_2.distanceMeasurement
          end
          L10_2 = L10_2(L11_2, L12_2)
          L9_2.stationDistance = L10_2
          L9_2.stationHeading = L8_2
          return L9_2
        end
    end
    else
      L5_2 = false
      return L5_2
    end
  end
end
L8_1 = false
function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = L8_1
  if L1_2 then
    return
  end
  L1_2 = true
  L8_1 = L1_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3
    while true do
      L0_3 = cache
      L0_3 = L0_3.vehicle
      if not L0_3 then
        break
      end
      L0_3 = IsHudRunning
      if not L0_3 then
        break
      end
      L0_3 = SendNUIMessage
      L1_3 = {}
      L1_3.type = "trainMetroData"
      L2_3 = L7_1
      L3_3 = A0_2
      L2_3 = L2_3(L3_3)
      L1_3.trainMetroData = L2_3
      L0_3(L1_3)
      L0_3 = Wait
      L1_3 = 1000
      L0_3(L1_3)
    end
    L0_3 = false
    L8_1 = L0_3
  end
  L1_2(L2_2)
end
function L10_1(A0_2)
  local L1_2, L2_2
  if A0_2 then
    L1_2 = GetVehicleType
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if "train" == L1_2 then
      L1_2 = GetEntityModel
      L2_2 = A0_2
      L1_2 = L1_2(L2_2)
      if 868868440 == L1_2 then
        goto lbl_14
      end
    end
  end
  do return end
  ::lbl_14::
  L1_2 = L9_1
  L2_2 = A0_2
  L1_2(L2_2)
end
L11_1 = lib
L11_1 = L11_1.onCache
L12_1 = "vehicle"
L13_1 = L10_1
L11_1(L12_1, L13_1)
function L11_1()
  local L0_2, L1_2
  L0_2 = cache
  L0_2 = L0_2.vehicle
  if L0_2 then
    L0_2 = L10_1
    L1_2 = cache
    L1_2 = L1_2.vehicle
    L0_2(L1_2)
  end
end
CheckTrainOnLoad = L11_1
