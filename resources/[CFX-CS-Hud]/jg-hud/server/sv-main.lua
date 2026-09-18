local L0_1, L1_1, L2_1
L0_1 = Config
L0_1 = L0_1.UseCustomSeatbeltIntegration
if not L0_1 then
  L0_1 = SetConvarReplicated
  L1_1 = "game_enableFlyThroughWindscreen"
  L2_1 = "true"
  L0_1(L1_1, L2_1)
end
L0_1 = CreateThread
function L1_1()
  local L0_2, L1_2
  L0_2 = Wait
  L1_2 = 10000
  L0_2(L1_2)
  L0_2 = pcall
  function L1_2()
    local L0_3, L1_3
    L0_3 = GetResourceState
    L1_3 = "jg-vehicleindicators"
    L0_3 = L0_3(L1_3)
    if "started" == L0_3 then
      L0_3 = StopResource
      L1_3 = "jg-vehicleindicators"
      L0_3(L1_3)
    end
  end
  L0_2(L1_2)
end
L0_1(L1_1)
