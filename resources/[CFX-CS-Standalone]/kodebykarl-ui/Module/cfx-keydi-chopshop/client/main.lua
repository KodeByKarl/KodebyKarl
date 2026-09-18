ESX = ESX or exports["es_extended"]:getSharedObject()

local chopping = false
local frozenVehicle = 0
local targetAdded = false

local function Notify(msg, nType)
    lib.notify({
        title = (Config.ChopShop and Config.ChopShop.Label) or "Illegal Chop",
        description = msg,
        type = nType or "inform",
    })
end

local function IsInChopZone(coords)
    local cfg = Config.ChopShop
    local radius = cfg.ZoneRadius or 22.0
    for i = 1, #cfg.Locations do
        if #(coords - cfg.Locations[i].coords) <= radius then
            return true, cfg.Locations[i]
        end
    end
    return false
end

local function IsAllowedClass(vehicle)
    local class = GetVehicleClass(vehicle)
    return Config.ChopShop.AllowedClasses[class] == true
end

local function VehicleOccupiedByOther(vehicle, localPed)
    for seat = -1, 8 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped ~= 0 and ped ~= localPed and IsPedAPlayer(ped) then
            return true
        end
    end
    return false
end

local function UnfreezeVehicle(vehicle)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        FreezeEntityPosition(vehicle, false)
        SetVehicleUndriveable(vehicle, false)
    end
    frozenVehicle = 0
end

local function FreezeChopVehicle(vehicle)
    frozenVehicle = vehicle
    FreezeEntityPosition(vehicle, true)
    SetVehicleUndriveable(vehicle, true)
    SetVehicleEngineOn(vehicle, false, true, true)
end

local function RunProgressSegment(duration, fromPct, toPct, label)
    local pctLabel = ('%s%% → %s%%'):format(fromPct or 0, toPct or 100)
    return lib.progressBar({
        duration = duration,
        label = ('%s (%s)'):format(label or 'Illegal chop in progress…', pctLabel),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped',
            flag = 49,
        },
    })
end

local function RunSkillChecks(difficulties)
    if type(difficulties) ~= 'table' or #difficulties < 1 then
        return true
    end
    local keys = Config.ChopShop.SkillCheckKeys or { 'w', 'a', 's', 'd' }
    return lib.skillCheck(difficulties, keys) == true
end

--- Full chop sequence: skill check → progress → skill check → progress…
local function RunChopSequence(totalDuration)
    local sequence = Config.ChopShop.Sequence
    if type(sequence) ~= 'table' or #sequence < 1 then
        return RunProgressSegment(totalDuration or 45000, 1, 100, 'Illegal chop in progress…')
    end

    totalDuration = math.max(1000, tonumber(totalDuration) or Config.ChopShop.ProgressDuration or 45000)
    local segmentMs = math.floor(totalDuration / #sequence)

    for i = 1, #sequence do
        local stage = sequence[i]
        if not RunSkillChecks(stage.skillCheck) then
            return false
        end

        local duration = tonumber(stage.duration) or segmentMs
        -- Last segment absorbs remainder so total matches server durationMs
        if i == #sequence then
            duration = totalDuration - (segmentMs * (#sequence - 1))
        end

        if not RunProgressSegment(duration, stage.progressFrom, stage.progressTo, stage.label) then
            return false
        end
    end

    return true
end

local function CanUseChopShop()
    if not ConfigServerLocations or not ConfigServerLocations.CanUseFunction then
        return false
    end
    return ConfigServerLocations.CanUseFunction("illegal")
end

local function CanTargetVehicle(entity)
    if chopping then return false end
    if not CanUseChopShop() then return false end
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if not IsEntityAVehicle(entity) then return false end
    if not IsAllowedClass(entity) then return false end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return false end
    if IsPedDeadOrDying(ped, true) then return false end

    local coords = GetEntityCoords(ped)
    if not IsInChopZone(coords) then return false end
    if #(coords - GetEntityCoords(entity)) > (Config.ChopShop.InteractionDistance or 3.2) then
        return false
    end

    return true
end

local function StartChop(entity)
    if chopping or not CanTargetVehicle(entity) then return end
    if not CanUseChopShop() then
        Notify((ConfigServerLocations and ConfigServerLocations.WrongServerMessage)
            and ConfigServerLocations.WrongServerMessage("illegal")
            or "Illegal chop is only available on Region 1.", "error")
        return
    end

    local ped = PlayerPedId()
    if VehicleOccupiedByOther(entity, ped) then
        Notify("Someone is still in that vehicle.", "error")
        return
    end

    if GetEntitySpeed(entity) > (Config.ChopShop.MaxVehicleSpeed or 1.2) then
        Notify("Stop the vehicle first.", "error")
        return
    end

    if IsPedInVehicle(ped, entity, false) then
        TaskLeaveVehicle(ped, entity, 16)
        local timeout = GetGameTimer() + 2500
        while IsPedInVehicle(ped, entity, false) and GetGameTimer() < timeout do
            Wait(50)
        end
        if IsPedInVehicle(ped, entity, false) then
            Notify("Get out of the vehicle first.", "error")
            return
        end
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    local plate = GetVehicleNumberPlateText(entity)
    local vehicleClass = GetVehicleClass(entity)
    local modelName = GetEntityArchetypeName(entity)
    if not modelName or modelName == "" then
        modelName = tostring(GetEntityModel(entity))
    end
    chopping = true

    local result = lib.callback.await("cfx-keydi-chopshop:server:request", false, netId, plate, vehicleClass, modelName)
    if type(result) ~= "table" or not result.ok then
        chopping = false
        local reason = result and result.reason or "denied"
        if reason == "not_owned" then
            Notify("Spawn / test cars cannot be chopped. Only database-owned vehicles.", "error")
        elseif reason == "job" then
            Notify("Job vehicles cannot be chopped.", "error")
        elseif reason == "blocked" then
            Notify("That plate is blocked from the chop shop.", "error")
        elseif reason == "already_chopped" then
            Notify("That vehicle was already chopped. Available again after server restart.", "error")
        elseif reason == "busy" then
            Notify("Already chopping a vehicle.", "error")
        elseif reason == "in_use" then
            Notify("That vehicle is already being chopped.", "error")
        elseif reason == "cooldown" then
            Notify("Wait before chopping another car.", "error")
        elseif reason == "cops" then
            Notify("Not enough police / sheriff on duty.", "error")
        elseif reason == "occupied" then
            Notify("Someone is still in that vehicle.", "error")
        elseif reason == "class" then
            Notify("This vehicle type cannot be chopped.", "error")
        elseif reason == "zone" then
            Notify("Bring the vehicle into the illegal chop yard.", "error")
        elseif reason == "speed" then
            Notify("Stop the vehicle first.", "error")
        else
            Notify("Cannot chop this vehicle.", "error")
        end
        return
    end

    Notify("Police have been tipped off — finish before they arrive.", "warning")

    FreezeChopVehicle(entity)

    local success = RunChopSequence(result.duration or Config.ChopShop.ProgressDuration)
    if not success then
        UnfreezeVehicle(entity)
        chopping = false
        TriggerServerEvent("cfx-keydi-chopshop:server:cancel")
        Notify("Chop cancelled.", "inform")
        return
    end

    TriggerServerEvent("cfx-keydi-chopshop:server:complete")
    chopping = false
end

RegisterNetEvent("cfx-keydi-chopshop:client:deleteVehicle", function(netId)
    netId = tonumber(netId)
    if not netId then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) then return end

    NetworkRequestControlOfEntity(entity)
    local timeout = GetGameTimer() + 1500
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    SetEntityAsMissionEntity(entity, true, true)
    DeleteVehicle(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    if frozenVehicle == entity then
        frozenVehicle = 0
    end
end)

RegisterNetEvent("cfx-keydi-chopshop:client:unlock", function()
    UnfreezeVehicle(frozenVehicle)
    chopping = false
end)

-- LEO alert blip when someone starts an illegal chop
RegisterNetEvent("cfx-keydi-chopshop:client:policeAlert", function(data)
    if type(data) ~= "table" or type(data.coords) ~= "table" then return end
    local c = data.coords
    local blip = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetBlipSprite(blip, data.sprite or 380)
    SetBlipColour(blip, data.color or 1)
    SetBlipScale(blip, data.scale or 1.0)
    SetBlipFlashes(blip, true)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.label or "Illegal Chop")
    EndTextCommandSetBlipName(blip)

    lib.notify({
        title = "Dispatch",
        description = ("Illegal chop reported: %s"):format(data.label or "Unknown yard"),
        type = "error",
        duration = 10000,
    })

    CreateThread(function()
        Wait(tonumber(data.time) or 180000)
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

local function AddVehicleTarget()
    if targetAdded then return end
    if GetResourceState("ox_target") ~= "started" then return end

    exports.ox_target:addGlobalVehicle({
        {
            name = "cfx-keydi-chopshop:chop",
            icon = "fa-solid fa-screwdriver-wrench",
            label = "Illegal Chop Vehicle",
            distance = Config.ChopShop.InteractionDistance or 3.2,
            canInteract = function(entity)
                return CanTargetVehicle(entity)
            end,
            onSelect = function(data)
                StartChop(data.entity)
            end,
        },
    })
    targetAdded = true
end

local function CreateBlips()
    local blipCfg = Config.ChopShop.Blip
    if not blipCfg or not blipCfg.enabled then return end

    for i = 1, #Config.ChopShop.Locations do
        local loc = Config.ChopShop.Locations[i]
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, blipCfg.sprite or 380)
        SetBlipDisplay(blip, 2)
        SetBlipScale(blip, blipCfg.scale or 0.75)
        SetBlipColour(blip, blipCfg.color or 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipCfg.label or loc.label or "Illegal Chop Yard")
        EndTextCommandSetBlipName(blip)
    end
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.015 + factor, 0.03, 5, 25, 47, 190)
    ClearDrawOrigin()
end

CreateThread(function()
    CreateBlips()
    AddVehicleTarget()

    local drawDistance = Config.ChopShop.DrawDistance or 50.0
    local markerCfg = Config.ChopShop.Marker or {}

    while true do
        local sleep = 1000
        if markerCfg.enabled ~= false then
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)

            for i = 1, #Config.ChopShop.Locations do
                local loc = Config.ChopShop.Locations[i]
                local c = loc.coords
                local dist = #(pCoords - c)

                if dist <= drawDistance then
                    sleep = 0
                    local heading = loc.heading or 0.0
                    local size = markerCfg.size or vector3(5.2, 5.2, 0.55)
                    local col = markerCfg.color or { r = 196, g = 30, b = 45, a = 150 }
                    local zOff = markerCfg.zOffset or -0.95

                    DrawMarker(
                        markerCfg.type or 1,
                        c.x, c.y, c.z + zOff,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, heading,
                        size.x, size.y, size.z,
                        col.r, col.g, col.b, col.a,
                        false, false, 2, false, nil, nil, false
                    )

                    if markerCfg.carIcon ~= false then
                        local iconSize = markerCfg.carIconSize or 1.15
                        DrawMarker(
                            36,
                            c.x, c.y, c.z + (markerCfg.carIconZ or 1.15),
                            0.0, 0.0, 0.0,
                            0.0, 0.0, heading,
                            iconSize, iconSize, iconSize,
                            col.r, col.g, col.b, 230,
                            false, true, 2, true, nil, nil, false
                        )
                    end

                    if dist <= 18.0 then
                        local label = markerCfg.text or "Park vehicle here"
                        DrawText3D(c.x, c.y, c.z + (markerCfg.textZ or 1.55), ("~r~%s"):format(label))
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    UnfreezeVehicle(frozenVehicle)
    chopping = false
end)
