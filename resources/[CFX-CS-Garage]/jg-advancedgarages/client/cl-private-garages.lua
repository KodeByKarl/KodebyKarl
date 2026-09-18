local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = lib
  L0_2 = L0_2.callback
  L0_2 = L0_2.await
  L1_2 = "jg-advancedgarages:server:can-create-priv-garage"
  L0_2 = L0_2(L1_2)
  if not L0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = lib
  L1_2 = L1_2.callback
  L1_2 = L1_2.await
  L2_2 = "jg-advancedgarages:server:get-all-private-garages"
  L1_2 = L1_2(L2_2)
  L2_2 = SetNuiFocus
  L3_2 = true
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = SetNuiFocusKeepInput
  L3_2 = false
  L2_2(L3_2)
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.type = "showPrivGarages"
  L4_2 = L1_2.garages
  L3_2.garages = L4_2
  L4_2 = L1_2.allPlayers
  L3_2.allPlayers = L4_2
  L4_2 = Locale
  L3_2.locale = L4_2
  L4_2 = Config
  L3_2.config = L4_2
  L2_2(L3_2)
end
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = lib
  L1_2 = L1_2.callback
  L1_2 = L1_2.await
  L2_2 = "jg-advancedgarages:server:can-create-priv-garage"
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = lib
  L2_2 = L2_2.callback
  L2_2 = L2_2.await
  L3_2 = "jg-advancedgarages:server:create-private-garage"
  L4_2 = false
  L5_2 = A0_2
  return L2_2(L3_2, L4_2, L5_2)
end
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = lib
  L1_2 = L1_2.callback
  L1_2 = L1_2.await
  L2_2 = "jg-advancedgarages:server:can-create-priv-garage"
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = lib
  L2_2 = L2_2.callback
  L2_2 = L2_2.await
  L3_2 = "jg-advancedgarages:server:edit-private-garage"
  L4_2 = false
  L5_2 = A0_2
  return L2_2(L3_2, L4_2, L5_2)
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = lib
  L1_2 = L1_2.callback
  L1_2 = L1_2.await
  L2_2 = "jg-advancedgarages:server:can-create-priv-garage"
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = lib
  L2_2 = L2_2.callback
  L2_2 = L2_2.await
  L3_2 = "jg-advancedgarages:server:delete-private-garage"
  L4_2 = false
  L5_2 = A0_2
  return L2_2(L3_2, L4_2, L5_2)
end
L4_1 = RegisterNUICallback
L5_1 = "is-garage-name-available"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A1_2
  L3_2 = lib
  L3_2 = L3_2.callback
  L3_2 = L3_2.await
  L4_2 = "jg-advancedgarages:server:is-garage-name-available"
  L5_2 = false
  L6_2 = A0_2.name
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNUICallback
L5_1 = "create-private-garage"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = L1_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = {}
    L4_2.error = true
    return L3_2(L4_2)
  end
  L3_2 = A1_2
  L4_2 = L2_2
  L3_2(L4_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNUICallback
L5_1 = "edit-private-garage"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = L2_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = {}
    L4_2.error = true
    return L3_2(L4_2)
  end
  L3_2 = A1_2
  L4_2 = L2_2
  L3_2(L4_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNUICallback
L5_1 = "delete-private-garage"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = L3_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = {}
    L4_2.error = true
    return L3_2(L4_2)
  end
  L3_2 = A1_2
  L4_2 = L2_2
  L3_2(L4_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNUICallback
L5_1 = "get-current-coords"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = GetEntityCoords
  L3_2 = cache
  L3_2 = L3_2.ped
  L2_2 = L2_2(L3_2)
  L3_2 = GetEntityHeading
  L4_2 = cache
  L4_2 = L4_2.ped
  L3_2 = L3_2(L4_2)
  L4_2 = A1_2
  L5_2 = {}
  L6_2 = L2_2.x
  L5_2.x = L6_2
  L6_2 = L2_2.y
  L5_2.y = L6_2
  L6_2 = L2_2.z
  L5_2.z = L6_2
  L5_2.h = L3_2
  L4_2(L5_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "jg-advancedgarages:client:show-private-garages-dashboard"
function L6_1()
  local L0_2, L1_2
  L0_2 = L0_1
  L0_2()
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "jg-advancedgarages:client:show-house-garage"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = openGarageMenu
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "jg-advancedgarages:client:ShowHouseGarage"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = openGarageMenu
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "jg-advancedgarages:client:ShowHouseGarage:qs-housing"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = openGarageMenu
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end
L4_1(L5_1, L6_1)
