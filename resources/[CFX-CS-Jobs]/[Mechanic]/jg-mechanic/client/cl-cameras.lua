local activeCam = nil
local cameras = {}
local isTransitioning = false
local activePresetName = nil

function exitCamera()
  for _, cam in pairs(cameras) do
    DestroyCam(cam, true)
  end
  RenderScriptCams(false, false, 0, true, true)
  activePresetName = nil
end

function toggleCamTemporarily(state)
  RenderScriptCams(state, false, 0, true, true)
end

function setupVehicleCamera(vehicle)
  local model = GetEntityModel(vehicle)
  local minDim, maxDim = GetModelDimensions(model)
  local modelLength = (maxDim.y - minDim.y) * 0.9
  local modelWidth = (maxDim.x - minDim.x) * 0.9
  local modelHeight = (maxDim.z - minDim.z) * 0.9

  local camDefault = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local camDefaultCoords = GetOffsetFromEntityInWorldCoords(vehicle, modelWidth * 1.5, maxDim.y + 1.0, 0.0)
  SetCamCoord(camDefault, camDefaultCoords.x, camDefaultCoords.y, camDefaultCoords.z + 1.0)
  PointCamAtEntity(camDefault, vehicle, 0.0, 0.0, 0.0, false)
  SetCamFov(camDefault, 60.0)

  local camFront = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local camFrontCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, modelLength, 0.0)
  SetCamCoord(camFront, camFrontCoords.x, camFrontCoords.y, camFrontCoords.z + 1.0)
  PointCamAtEntity(camFront, vehicle, 0.0, 0.0, 0.0, true)
  SetCamFov(camFront, GetGameplayCamFov())

  local camBack = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local camBackCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -modelLength, 0.0)
  SetCamCoord(camBack, camBackCoords.x, camBackCoords.y, camBackCoords.z + 1.0)
  PointCamAtEntity(camBack, vehicle, 0.0, 0.0, 0.0, true)
  SetCamFov(camBack, GetGameplayCamFov())

  local camExhaust = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local camExhaustCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -modelLength, 0.0)
  SetCamCoord(camExhaust, camExhaustCoords.x, camExhaustCoords.y, camExhaustCoords.z + 0.5)
  PointCamAtEntity(camExhaust, vehicle, 0.0, 0.0, 0.0, true)
  SetCamFov(camExhaust, GetGameplayCamFov())

  local camSide = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local camSideCoords = GetOffsetFromEntityInWorldCoords(vehicle, modelLength, 0.0, 0.0)
  SetCamCoord(camSide, camSideCoords.x, camSideCoords.y, camSideCoords.z + 0.5)
  PointCamAtEntity(camSide, vehicle, 0.0, -0.25, 0.0, true)
  SetCamFov(camSide, GetGameplayCamFov())

  local camEngineBay = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local camEngineBayCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, modelLength * 0.7, 0.5)
  SetCamCoord(camEngineBay, camEngineBayCoords.x, camEngineBayCoords.y, camEngineBayCoords.z + 1.0)
  PointCamAtEntity(camEngineBay, vehicle, 0.0, 0.0, -1.0, true)
  SetCamFov(camEngineBay, GetGameplayCamFov())

  local camRoof = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local camRoofCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.0, maxDim.z)
  SetCamCoord(camRoof, camRoofCoords.x, camRoofCoords.y - 1.25, camRoofCoords.z + (modelWidth / 1.5))
  PointCamAtEntity(camRoof, vehicle, 0.0, 0.0, 0.0, false)
  SetCamFov(camRoof, GetGameplayCamFov())

  local camPov = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local driverSeatBone = GetEntityBoneIndexByName(vehicle, "seat_dside_f")
  local driverSeatCoords = GetWorldPositionOfEntityBone(vehicle, driverSeatBone)
  local forwardVector = GetEntityForwardVector(vehicle)
  local povX = driverSeatCoords.x + (forwardVector.x * -0.4) + -0.1
  local povY = driverSeatCoords.y + (forwardVector.y * -0.4)
  local povZ = driverSeatCoords.z + 0.6
  SetCamCoord(camPov, povX, povY, povZ)
  PointCamAtCoord(camPov, povX + (forwardVector.x * 0.5), povY + (forwardVector.y * 0.5), driverSeatCoords.z + 0.4)
  SetCamFov(camPov, 70.0)

  local camDoorSpeaker = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local speakerCamPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.0, 0.5)
  SetCamCoord(camDoorSpeaker, speakerCamPos.x, speakerCamPos.y, speakerCamPos.z)
  local speakerCamTarget = GetOffsetFromEntityInWorldCoords(vehicle, 1.5, 1.0, 0.5)
  PointCamAtCoord(camDoorSpeaker, speakerCamTarget.x, speakerCamTarget.y, speakerCamTarget.z)
  SetCamFov(camDoorSpeaker, 100.0)

  local camInterior = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  local yLength = maxDim.y - minDim.y
  local zLength = maxDim.z - minDim.z
  local interiorY = maxDim.y - (yLength * 0.5)
  interiorY = math.max(interiorY, maxDim.y * 0.05)
  local interiorZ = maxDim.z * 0.6
  local interiorCamPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, interiorY, interiorZ)
  SetCamCoord(camInterior, interiorCamPos.x, interiorCamPos.y, interiorCamPos.z)
  local interiorTargetY = minDim.y + (yLength * 0.25)
  local interiorTargetZ = minDim.z + (zLength / 2)
  local interiorCamTarget = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, interiorTargetY, interiorTargetZ)
  PointCamAtCoord(camInterior, interiorCamTarget.x, interiorCamTarget.y, interiorCamTarget.z)
  SetCamFov(camInterior, 100.0)

  cameras = {
    default = camDefault,
    frontCamera = camFront,
    backCamera = camBack,
    exhaust = camExhaust,
    sideCamera = camSide,
    engineBay = camEngineBay,
    roof = camRoof,
    pov = camPov,
    doorSpeaker = camDoorSpeaker,
    interior = camInterior
  }

  SetCamActive(camDefault, true)
  RenderScriptCams(true, false, 0, true, true)
  activePresetName = "default"
  activeCam = camDefault
end

function moveCameraToVehiclePreset(presetName)
  if not activeCam then
    return false
  end

  if presetName == activePresetName then
    return false
  end

  local newCam = cameras[presetName]
  if not newCam then
    return false
  end

  activePresetName = presetName
  SetCamActiveWithInterp(newCam, activeCam, 500, 1, 1)
  SetCamActive(activeCam, false)
  activeCam = newCam
  return true
end

function transitionCamera(presetName)
  CreateThread(function()
    while isTransitioning do
      Wait(100)
    end
    isTransitioning = true
    if moveCameraToVehiclePreset(presetName) then
      Wait(500)
    end
    isTransitioning = false
  end)
end
