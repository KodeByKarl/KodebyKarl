local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = "jg-hud"
L1_1 = "https://raw.githubusercontent.com/jgscripts/versions/main/"
L2_1 = L0_1
L3_1 = ".txt"
L1_1 = L1_1 .. L2_1 .. L3_1
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = {}
  L3_2 = string
  L3_2 = L3_2.gmatch
  L4_2 = A0_2
  L5_2 = "[^.]+"
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2, L5_2)
  for L7_2 in L3_2, L4_2, L5_2, L6_2 do
    L8_2 = table
    L8_2 = L8_2.insert
    L9_2 = L2_2
    L10_2 = tonumber
    L11_2 = L7_2
    L10_2 = L10_2(L11_2)
    L8_2(L9_2, L10_2)
  end
  L3_2 = {}
  L4_2 = string
  L4_2 = L4_2.gmatch
  L5_2 = A1_2
  L6_2 = "[^.]+"
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2, L6_2)
  for L8_2 in L4_2, L5_2, L6_2, L7_2 do
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = L3_2
    L11_2 = tonumber
    L12_2 = L8_2
    L11_2 = L11_2(L12_2)
    L9_2(L10_2, L11_2)
  end
  L4_2 = 1
  L5_2 = math
  L5_2 = L5_2.max
  L6_2 = #L2_2
  L7_2 = #L3_2
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = L2_2[L7_2]
    if not L8_2 then
      L8_2 = 0
    end
    L9_2 = L3_2[L7_2]
    if not L9_2 then
      L9_2 = 0
    end
    if L8_2 < L9_2 then
      L10_2 = true
      return L10_2
    end
  end
  L4_2 = false
  return L4_2
end
L3_1 = PerformHttpRequest
L4_1 = L1_1
function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if 200 ~= A0_2 then
    L3_2 = print
    L4_2 = "^1Unable to perform update check"
    return L3_2(L4_2)
  end
  L3_2 = GetResourceMetadata
  L4_2 = GetCurrentResourceName
  L4_2 = L4_2()
  L5_2 = "version"
  L6_2 = 0
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  if not L3_2 then
    return
  end
  if "dev" == L3_2 then
    L4_2 = print
    L5_2 = "^3Using dev version"
    return L4_2(L5_2)
  end
  L5_2 = A1_2
  L4_2 = A1_2.match
  L6_2 = [[
^[^
]+]]
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    return
  end
  L5_2 = L2_1
  L7_2 = L3_2
  L6_2 = L3_2.sub
  L8_2 = 2
  L6_2 = L6_2(L7_2, L8_2)
  L8_2 = L4_2
  L7_2 = L4_2.sub
  L9_2 = 2
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L7_2(L8_2, L9_2)
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  if L5_2 then
    L5_2 = print
    L6_2 = "^3Update available for "
    L7_2 = L0_1
    L8_2 = "! (current: ^1"
    L9_2 = L3_2
    L10_2 = "^3, latest: ^2"
    L11_2 = L4_2
    L12_2 = "^3)"
    L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2
    L5_2(L6_2)
    L5_2 = print
    L6_2 = "^3Release notes: discord.gg/jgscripts"
    L5_2(L6_2)
  end
end
L6_1 = "GET"
L3_1(L4_1, L5_1, L6_1)
function L3_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = GetConvar
  L1_2 = "version"
  L2_2 = "unknown"
  L0_2 = L0_2(L1_2, L2_2)
  L1_2 = string
  L1_2 = L1_2.match
  L2_2 = L0_2
  L3_2 = "v%d+%.%d+%.%d+%.(%d+)"
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = PerformHttpRequest
  L3_2 = "https://artifacts.jgscripts.com/check?artifact="
  L4_2 = L1_2
  L3_2 = L3_2 .. L4_2
  function L4_2(A0_3, A1_3, A2_3, A3_3)
    local L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    if 200 ~= A0_3 or A3_3 then
      L4_3 = print
      L5_3 = "^1Could not check artifact version^0"
      return L4_3(L5_3)
    end
    if not A1_3 then
      return
    end
    L4_3 = json
    L4_3 = L4_3.decode
    L5_3 = A1_3
    L4_3 = L4_3(L5_3)
    L5_3 = L4_3.status
    if "BROKEN" == L5_3 then
      L5_3 = print
      L6_3 = "^1WARNING: The current FXServer version you are using (artifacts version) has known issues. Please update to the latest stable artifacts: https://artifacts.jgscripts.com^0"
      L5_3(L6_3)
      L5_3 = print
      L6_3 = "^0Artifact version:^3"
      L7_3 = L1_2
      L8_3 = [[

^0Known issues:^3]]
      L9_3 = L4_3.reason
      L10_3 = "^0"
      L5_3(L6_3, L7_3, L8_3, L9_3, L10_3)
      return
    end
  end
  L2_2(L3_2, L4_2)
end
L4_1 = CreateThread
function L5_1()
  local L0_2, L1_2
  L0_2 = L3_1
  L0_2()
end
L4_1(L5_1)
