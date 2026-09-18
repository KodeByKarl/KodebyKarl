local L0_1, L1_1
L0_1 = {}
Functions = L0_1
L0_1 = Locales
L1_1 = Config
L1_1 = L1_1.Locale
if not L1_1 then
  L1_1 = "en"
end
L0_1 = L0_1[L1_1]
Locale = L0_1
L0_1 = {}
L1_1 = {}
L0_1.OutsideVehicles = L1_1
Globals = L0_1
function L0_1(A0_2, A1_2, ...)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Config
  L2_2 = L2_2.Debug
  if not L2_2 then
    return
  end
  L2_2 = "^2[DEBUG]^7"
  if "warning" == A1_2 then
    L2_2 = "^3[WARNING]^7"
  end
  L3_2 = {}
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = ...
  L3_2[1] = L4_2
  L3_2[2] = L5_2
  L3_2[3] = L6_2
  L3_2[4] = L7_2
  L3_2[5] = L8_2
  L3_2[6] = L9_2
  L3_2[7] = L10_2
  L3_2[8] = L11_2
  L4_2 = ""
  L5_2 = 1
  L6_2 = #L3_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = type
    L10_2 = L3_2[L8_2]
    L9_2 = L9_2(L10_2)
    if "table" == L9_2 then
      L9_2 = L4_2
      L10_2 = json
      L10_2 = L10_2.encode
      L11_2 = L3_2[L8_2]
      L10_2 = L10_2(L11_2)
      L9_2 = L9_2 .. L10_2
      L4_2 = L9_2
    else
      L9_2 = type
      L10_2 = L3_2[L8_2]
      L9_2 = L9_2(L10_2)
      if "string" ~= L9_2 then
        L9_2 = L4_2
        L10_2 = tostring
        L11_2 = L3_2[L8_2]
        L10_2 = L10_2(L11_2)
        L9_2 = L9_2 .. L10_2
        L4_2 = L9_2
      else
        L9_2 = L4_2
        L10_2 = L3_2[L8_2]
        L9_2 = L9_2 .. L10_2
        L4_2 = L9_2
      end
    end
    L9_2 = #L3_2
    if L8_2 ~= L9_2 then
      L9_2 = L4_2
      L10_2 = " "
      L9_2 = L9_2 .. L10_2
      L4_2 = L9_2
    end
  end
  L5_2 = print
  L6_2 = L2_2
  L7_2 = A0_2
  L8_2 = L4_2
  L5_2(L6_2, L7_2, L8_2)
end
debugPrint = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetResourceState
  L3_2 = "AdvancedParking"
  L2_2 = L2_2(L3_2)
  if "started" == L2_2 then
    L2_2 = exports
    L2_2 = L2_2.AdvancedParking
    L3_2 = L2_2
    L2_2 = L2_2.UpdatePlate
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  else
    L2_2 = SetVehicleNumberPlateText
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end
setVehiclePlateText = L0_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = {}
  L1_2.Jan = 1
  L1_2.Feb = 2
  L1_2.Mar = 3
  L1_2.Apr = 4
  L1_2.May = 5
  L1_2.Jun = 6
  L1_2.Jul = 7
  L1_2.Aug = 8
  L1_2.Sep = 9
  L1_2.Oct = 10
  L1_2.Nov = 11
  L1_2.Dec = 12
  L2_2 = "%a+%s+(%a+)%s+(%d+)%s+(%d+)%s+(%d+):(%d+):(%d+)"
  L4_2 = A0_2
  L3_2 = A0_2.match
  L5_2 = L2_2
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2, L5_2)
  L9_2 = {}
  L10_2 = tonumber
  L11_2 = L5_2
  L10_2 = L10_2(L11_2)
  L9_2.year = L10_2
  L10_2 = L1_2[L3_2]
  L9_2.month = L10_2
  L10_2 = tonumber
  L11_2 = L4_2
  L10_2 = L10_2(L11_2)
  L9_2.day = L10_2
  L10_2 = tonumber
  L11_2 = L6_2
  L10_2 = L10_2(L11_2)
  L9_2.hour = L10_2
  L10_2 = tonumber
  L11_2 = L7_2
  L10_2 = L10_2(L11_2)
  L9_2.min = L10_2
  L10_2 = tonumber
  L11_2 = L8_2
  L10_2 = L10_2(L11_2)
  L9_2.sec = L10_2
  L10_2 = os
  L10_2 = L10_2.time
  L11_2 = L9_2
  return L10_2(L11_2)
end
convertJSTimestamp = L0_1
function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" == L1_2 then
    L1_2 = joaat
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_12
    end
  end
  L1_2 = A0_2
  ::lbl_12::
  return L1_2
end
convertModelToHash = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2 or nil
  if not A1_2 then
    L2_2 = 0
  end
  L3_2 = 10
  L2_2 = L3_2 ^ L2_2
  L3_2 = math
  L3_2 = L3_2.floor
  L4_2 = A0_2 * L2_2
  L4_2 = L4_2 + 0.5
  L3_2 = L3_2(L4_2)
  L3_2 = L3_2 / L2_2
  return L3_2
end
round = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = #A0_2
  if 0 == L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = ipairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    if L7_2 == A1_2 then
      L8_2 = true
      return L8_2
    end
  end
  L2_2 = false
  return L2_2
end
isItemInList = L0_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = #A0_2
  if L1_2 <= 8 then
    L2_2 = A0_2
    L1_2 = A0_2.match
    L3_2 = "^[%w%s]*$"
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L1_2 = true
      return L1_2
    end
  end
  L1_2 = false
  return L1_2
end
isValidGTAPlate = L0_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = #L1_2
    L8_2 = L8_2 + 1
    L1_2[L8_2] = L6_2
  end
  return L1_2
end
tableKeys = L0_1
L0_1 = CreateThread
function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = pairs
  L1_2 = Config
  L1_2 = L1_2.VehicleLabels
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = Config
    L6_2 = L6_2.VehicleLabels
    L7_2 = tostring
    L8_2 = joaat
    L9_2 = L4_2
    L8_2, L9_2 = L8_2(L9_2)
    L7_2 = L7_2(L8_2, L9_2)
    L6_2[L7_2] = L5_2
  end
end
L0_1(L1_1)
