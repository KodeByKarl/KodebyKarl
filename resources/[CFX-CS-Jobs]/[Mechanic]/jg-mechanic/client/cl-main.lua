function setVehicleStatebag(vehicle, key, value, saveToDb, plate)
  return lib.callback.await("jg-mechanic:server:set-vehicle-statebag", false, VehToNet(vehicle), key, value, saveToDb, plate)
end

function setVehicleStatebags(vehicle, data, saveToDb, plate)
  return lib.callback.await("jg-mechanic:server:set-vehicle-statebags", false, VehToNet(vehicle), data, saveToDb, plate)
end

function playAnimation(ped, animDict, animName, isUpperBody)
  CreateThread(function()
    lib.requestAnimDict(animDict)
    if not IsEntityPlayingAnim(ped, animDict, animName, 3) then
      local animFlag = isUpperBody and 33 or 49
      TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, animFlag, 0, false, false, false)
    end
  end)
end

function stopAnimation(ped)
  ClearPedTasks(ped)
end

function playTabletAnim()
  local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
  local animName = "base"
  local propModel = joaat("prop_cs_tablet")
  local boneIndex = 60309
  local offset = vector3(0.03, 0.002, 0.0)
  local rotation = vector3(10.0, 160.0, 0.0)

  CreateThread(function()
    lib.requestAnimDict(animDict)
    lib.requestModel(propModel, 3000)

    local playerPed = cache.ped
    Globals.HoldingTablet = CreateObject(propModel, 0.0, 0.0, 0.0, true, true, false)
    local handBoneIndex = GetPedBoneIndex(playerPed, boneIndex)

    SetCurrentPedWeapon(playerPed, joaat("weapon_unarmed"), true)
    AttachEntityToEntity(Globals.HoldingTablet, playerPed, handBoneIndex, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(propModel)

    if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then
      TaskPlayAnim(playerPed, animDict, animName, 3.0, 3.0, -1, 49, 0, false, false, false)
    end
  end)
end

function stopTabletAnim()
  if not Globals.HoldingTablet then
    return
  end
  ClearPedTasks(cache.ped)
  DetachEntity(Globals.HoldingTablet, true, false)
  DeleteEntity(Globals.HoldingTablet)
  Globals.HoldingTablet = nil
end

function createPedForTarget(model, coords)
  if not model or model == "" then
    model = "s_m_m_lathandy_01"
  end
  lib.requestModel(model)
  local ped = CreatePed(0, joaat(model), coords.x, coords.y, coords.z, coords.w or 0, false, false)
  lib.waitFor(function() return DoesEntityExist(ped) end)
  SetEntityInvincible(ped, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetPedFleeAttributes(ped, 0, false)
  SetPedCombatAttributes(ped, 17, true)
  FreezeEntityPosition(ped, true)
  SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, false)
  SetPedCanRagdoll(ped, false)
  SetEntityProofs(ped, true, true, true, true, true, true, true, true)
  SetModelAsNoLongerNeeded(model)
  return ped
end

RegisterNUICallback("has-item", function(data, cb)
  cb(lib.callback.await("jg-mechanic:server:has-item", false, data.itemName, data.qty))
end)

RegisterNUICallback("nearby-players", function(data, cb)
  local coords = GetEntityCoords(cache.ped)
  local radius = 10.0
  cb(lib.callback.await("jg-mechanic:server:nearby-players", false, coords, radius, data and data.includePlayer or false))
end)

RegisterNUICallback("get-player-balances", function(data, cb)
  cb({
    bank = Framework.Client.GetBalance("bank"),
    cash = Framework.Client.GetBalance("cash"),
  })
end)

RegisterNUICallback("close", function(data, cb)
  exitCamera()
  stopTabletAnim()
  SetNuiFocus(false, false)
  LocalPlayer.state:set("isBusy", false, true)

  if not Globals.HoldingTablet then
    Framework.Client.ToggleHud(true)
  end
  cb(true)
end)

CreateThread(function()
  while true do
    local vehicle = cache.vehicle
    if vehicle and Entity(vehicle)?.state?.unpaidModifications then
      if GetEntitySpeed(vehicle) > 1.0 then
        Framework.Client.Notify("This vehicle appears to have unpaid for modifications. It has been repossessed.")
        DeleteEntity(vehicle)
      end
    end
    Wait(10000)
  end
end)
