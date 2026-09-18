local projects = {}
local spawned = {} -- [plate] = { vehicle, shell }
local placing = false
local installing = false
local myIdentifier = nil

CreateThread(function()
    Wait(500)
    pcall(function()
        exports.ox_inventory:displayMetadata({
            vehicle = 'Vehicle',
        })
    end)
end)

local function Notify(msg, nType)
    lib.notify({
        title = 'Project Cars',
        description = msg,
        type = nType or 'inform',
    })
end

local function NormalizePlate(plate)
    if not plate then return '' end
    return (string.gsub(tostring(plate), '%s+', '')):upper()
end

local function LoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return false, hash
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 7000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
            return false, hash
        end
        Wait(10)
    end
    return true, hash
end

local function DrawText3Ds(pos, text)
    local onScreen, x, y = World3dToScreen2d(pos.x, pos.y, pos.z)
    if not onScreen then return end
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 220)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

local function ValidBoneWorld(entity, boneName)
    if not boneName then return nil end
    local idx = GetEntityBoneIndexByName(entity, boneName)
    if not idx or idx == -1 then return nil end
    local coords = GetWorldPositionOfEntityBone(entity, idx)
    if not coords then return nil end
    if math.abs(coords.x) < 0.01 and math.abs(coords.y) < 0.01 then
        return nil
    end
    if #(coords - GetEntityCoords(entity)) < 0.55 then
        return nil
    end
    return coords
end

local function LocalToWorld(vehicle, x, y, z)
    return GetOffsetFromEntityInWorldCoords(vehicle, x, y, z)
end

local function GetPartWorldCoords(vehicle, partType, index)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local midZ = (min.z + max.z) * 0.55
    local doorZ = math.max(0.18, midZ)
    local leftX = min.x * 1.18
    local rightX = max.x * 1.18
    local frontDoorY = max.y * 0.26
    local rearDoorY = min.y * 0.36
    local frontWheelY = max.y * 0.60
    local rearWheelY = min.y * 0.62
    local wheelZ = min.z + 0.48

    if partType == 'door' then
        local sideX = (index == 0 or index == 2) and leftX or rightX
        local alongY = (index == 0 or index == 1) and frontDoorY or rearDoorY
        local seatBones = {
            [0] = 'seat_dside_f',
            [1] = 'seat_pside_f',
            [2] = 'seat_dside_r',
            [3] = 'seat_pside_r',
        }
        local seat = ValidBoneWorld(vehicle, seatBones[index])
        if seat then
            local localSeat = GetOffsetFromEntityGivenWorldCoords(vehicle, seat.x, seat.y, seat.z)
            return LocalToWorld(vehicle, sideX, localSeat.y, math.max(localSeat.z, doorZ))
        end
        return LocalToWorld(vehicle, sideX, alongY, doorZ)
    end

    if partType == 'tire' then
        local sideX = (index == 0 or index == 2) and (min.x * 1.22) or (max.x * 1.22)
        local alongY = (index == 0 or index == 1) and frontWheelY or rearWheelY
        local wheelBones = {
            [0] = 'wheel_lf',
            [1] = 'wheel_rf',
            [2] = 'wheel_lr',
            [3] = 'wheel_rr',
        }
        local wheel = ValidBoneWorld(vehicle, wheelBones[index])
        if wheel then
            local localWheel = GetOffsetFromEntityGivenWorldCoords(vehicle, wheel.x, wheel.y, wheel.z)
            local outX = localWheel.x >= 0.0 and (max.x * 1.22) or (min.x * 1.22)
            return LocalToWorld(vehicle, outX, localWheel.y, wheelZ)
        end
        return LocalToWorld(vehicle, sideX, alongY, wheelZ)
    end

    if partType == 'engine' then
        return LocalToWorld(vehicle, 0.0, max.y * 0.50, math.max(0.35, max.z * 0.26))
    end

    if partType == 'transmission' then
        return LocalToWorld(vehicle, 0.0, max.y * 0.16, math.max(0.20, max.z * 0.06))
    end

    if partType == 'suspension' then
        return LocalToWorld(vehicle, 0.0, 0.0, min.z + 0.18)
    end

    if partType == 'bodyframe' then
        return LocalToWorld(vehicle, 0.0, 0.0, math.max(0.55, max.z * 0.42))
    end

    if partType == 'window' then
        local sideX = (index == 0 or index == 2) and leftX or rightX
        local alongY = (index == 0 or index == 1) and frontDoorY or rearDoorY
        local windowZ = math.max(0.55, max.z * 0.62)
        local seatBones = {
            [0] = 'seat_dside_f',
            [1] = 'seat_pside_f',
            [2] = 'seat_dside_r',
            [3] = 'seat_pside_r',
        }
        local seat = ValidBoneWorld(vehicle, seatBones[index])
        if seat then
            local localSeat = GetOffsetFromEntityGivenWorldCoords(vehicle, seat.x, seat.y, seat.z)
            return LocalToWorld(vehicle, sideX, localSeat.y, math.max(localSeat.z + 0.32, windowZ))
        end
        return LocalToWorld(vehicle, sideX, alongY, windowZ)
    end

    return GetEntityCoords(vehicle) + vector3(0.0, 0.0, 1.0)
end

local function StatusMissing(tbl, key)
    if type(tbl) ~= 'table' then return false end
    return tbl[tostring(key)] == true
end

local function ApplyWreckedLook(vehicle, status)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleUndriveable(vehicle, true)
    SetVehicleFuelLevel(vehicle, 0.0)
    SetVehicleEngineHealth(vehicle, status.engine and 0.0 or 400.0)
    FreezeEntityPosition(vehicle, true)
    SetVehicleDirtLevel(vehicle, 15.0)
    SetVehicleColours(vehicle, 12, 12)
    SetVehicleExtraColours(vehicle, 12, 12)
    SetVehicleEnveffScale(vehicle, 1.0)
    SetVehicleRudderBroken(vehicle, true)

    SetVehicleFixed(vehicle)

    SetVehicleDoorBroken(vehicle, 4, true)
    SetVehicleDoorBroken(vehicle, 5, true)

    for i = 0, 3 do
        if StatusMissing(status.doors, i) then
            SetVehicleDoorBroken(vehicle, i, true)
        end
    end

    for i = 0, 3 do
        if StatusMissing(status.windows, i) then
            SmashVehicleWindow(vehicle, i)
        end
    end

    for i = 0, 3 do
        if StatusMissing(status.tires, i) then
            SetVehicleWheelTireColliderSize(vehicle, i, -5.0)
        else
            SetVehicleWheelTireColliderSize(vehicle, i, 0.4)
        end
    end

    if status.bodyframe then
        SetVehicleBodyHealth(vehicle, 80.0)
    end
end

local function DeleteSpawned(plate)
    local entry = spawned[plate]
    if not entry then return end
    if entry.vehicle and DoesEntityExist(entry.vehicle) then
        DeleteEntity(entry.vehicle)
    end
    if entry.shell and DoesEntityExist(entry.shell) then
        DeleteEntity(entry.shell)
    end
    if entry.blip and DoesBlipExist(entry.blip) then
        RemoveBlip(entry.blip)
    end
    spawned[plate] = nil
end

local function AddOwnerBlip(data)
    if not myIdentifier or data.owner ~= myIdentifier then return nil end
    local blip = AddBlipForCoord(data.x, data.y, data.z)
    SetBlipSprite(blip, 326)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Project Car')
    EndTextCommandSetBlipName(blip)
    return blip
end

local function SpawnProject(data)
    if spawned[data.plate] then return end

    local ok, hash = LoadModel(data.model)
    if not ok then return end

    local vehicle = CreateVehicle(hash, data.x, data.y, data.z + 0.4, data.w, false, false)
    if not vehicle or vehicle == 0 then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetEntityCompletelyDisableCollision(vehicle, false, false)
    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, true)
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleDoorsLocked(vehicle, 2)
    SetEntityInvincible(vehicle, true)
    SetVehicleCanBeVisiblyDamaged(vehicle, false)

    local shell = CreateObject(hash, data.x, data.y, data.z + 0.4, false, false, false)
    if shell and shell ~= 0 then
        SetEntityHeading(shell, data.w)
        FreezeEntityPosition(shell, true)
        SetEntityInvincible(shell, true)
        SetEntityCanBeDamaged(shell, false)
        SetEntityAlpha(shell, 0, false)
        SetEntityCompletelyDisableCollision(shell, true, false)
        SetEntityNoCollisionEntity(shell, vehicle, false)
    end

    ApplyWreckedLook(vehicle, data.status or {})
    SetModelAsNoLongerNeeded(hash)

    spawned[data.plate] = {
        vehicle = vehicle,
        shell = shell,
        blip = AddOwnerBlip(data),
    }
end

local function RefreshSpawned()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)

    for plate, data in pairs(projects) do
        local dist = #(coords - vector3(data.x, data.y, data.z))
        if dist <= Config.SpawnDistance then
            if not spawned[plate] then
                SpawnProject(data)
            else
                local veh = spawned[plate].vehicle
                local status = data.status or {}
                if veh and DoesEntityExist(veh) then
                    for i = 0, 3 do
                        if StatusMissing(status.tires, i) then
                            SetVehicleWheelTireColliderSize(veh, i, -5.0)
                        end
                    end
                    SetVehicleFuelLevel(veh, 0.0)
                    FreezeEntityPosition(veh, true)
                end
            end
        else
            DeleteSpawned(plate)
        end
    end

    for plate in pairs(spawned) do
        if not projects[plate] then
            DeleteSpawned(plate)
        end
    end
end

local function InBuildZone(coords)
    if not Config.EnableZoneOnly then return true end
    for i = 1, #Config.BuildZones do
        local zone = Config.BuildZones[i]
        if #(coords - zone.coords) <= (zone.radius or 50.0) then
            return true
        end
    end
    return false
end

local function CollectPoints(data, vehicle)
    local points = {}
    local status = data.status or {}
    local parts = Config.Parts

    local function requirementsMet(cfg, index)
        if cfg.requires then
            for i = 1, #cfg.requires do
                if status[cfg.requires[i]] then
                    return false
                end
            end
        end
        if cfg.requiresIndex and index ~= nil then
            local bucketKey = ({ door = 'doors', tire = 'tires', window = 'windows' })[cfg.requiresIndex] or (cfg.requiresIndex .. 's')
            local bucket = status[bucketKey] or status[cfg.requiresIndex]
            if type(bucket) == 'table' and bucket[tostring(index)] then
                return false
            end
        end
        return true
    end

    local function add(partType, index, coords, label)
        if not coords then return end
        local cfg = parts[partType]
        if cfg and not requirementsMet(cfg, index) then return end
        points[#points + 1] = {
            type = partType,
            index = index,
            coords = coords,
            label = label,
        }
    end

    if status.bodyframe and parts.bodyframe then
        add('bodyframe', nil, GetPartWorldCoords(vehicle, 'bodyframe'), GetPartDisplayLabel(data.model, 'bodyframe'))
    end

    if status.suspension and parts.suspension then
        add('suspension', nil, GetPartWorldCoords(vehicle, 'suspension'), GetPartDisplayLabel(data.model, 'suspension'))
    end

    if status.engine and parts.engine then
        add('engine', nil, GetPartWorldCoords(vehicle, 'engine'), GetPartDisplayLabel(data.model, 'engine'))
    end

    if status.transmission and parts.transmission then
        add('transmission', nil, GetPartWorldCoords(vehicle, 'transmission'), GetPartDisplayLabel(data.model, 'transmission'))
    end

    if parts.door and type(status.doors) == 'table' then
        for idx, info in pairs(parts.door.bones) do
            if StatusMissing(status.doors, idx) then
                add('door', idx, GetPartWorldCoords(vehicle, 'door', idx), info.label)
            end
        end
    end

    if parts.window and type(status.windows) == 'table' then
        for idx, info in pairs(parts.window.bones) do
            if StatusMissing(status.windows, idx) then
                add('window', idx, GetPartWorldCoords(vehicle, 'window', idx), info.label)
            end
        end
    end

    if parts.tire and type(status.tires) == 'table' then
        for idx, info in pairs(parts.tire.bones) do
            if StatusMissing(status.tires, idx) then
                add('tire', idx, GetPartWorldCoords(vehicle, 'tire', idx), info.label)
            end
        end
    end

    return points
end

local function BreakPlacementGhost(vehicle)
    for i = 0, 7 do
        SetVehicleDoorBroken(vehicle, i, true)
        SetVehicleWheelTireColliderSize(vehicle, i, -5.0)
    end
    SetVehicleDirtLevel(vehicle, 15.0)
    SetVehicleColours(vehicle, 12, 12)
    SetVehicleEnveffScale(vehicle, 1.0)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleFuelLevel(vehicle, 0.0)
    FreezeEntityPosition(vehicle, true)
end

local function BuildStatus()
    return {
        engine = true,
        transmission = true,
        suspension = true,
        bodyframe = true,
        doors = { ['0'] = true, ['1'] = true, ['2'] = true, ['3'] = true },
        tires = { ['0'] = true, ['1'] = true, ['2'] = true, ['3'] = true },
        windows = { ['0'] = true, ['1'] = true, ['2'] = true, ['3'] = true },
    }
end

local function TooCloseToOtherVehicle(coords, ignore)
    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles do
        local veh = vehicles[i]
        if veh ~= ignore and DoesEntityExist(veh) then
            if #(coords - GetEntityCoords(veh)) < 2.8 then
                return true
            end
        end
    end
    return false
end

local function StartPlacement(model, slot)
    if placing then
        Notify('You are already placing a shell.', 'error')
        return
    end

    local ped = cache.ped
    if IsPedInAnyVehicle(ped, false) then
        Notify('Get out of the vehicle first.', 'error')
        return
    end

    local ok, hash = LoadModel(model)
    if not ok then
        Notify('Invalid vehicle model.', 'error')
        return
    end

    placing = true
    FreezeEntityPosition(ped, true)

    local spawn = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.5, 0.0)
    local ghost = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, GetEntityHeading(ped), false, false)
    if not ghost or ghost == 0 then
        placing = false
        FreezeEntityPosition(ped, false)
        SetModelAsNoLongerNeeded(hash)
        Notify('Failed to spawn the shell preview.', 'error')
        return
    end
    SetEntityAlpha(ghost, 180, false)
    SetEntityCollision(ghost, false, false)
    SetEntityInvincible(ghost, true)
    BreakPlacementGhost(ghost)
    SetVehicleOnGroundProperly(ghost)

    local moveSpeed = 0.05
    lib.showTextUI('[E] Place   [X] Cancel   [Q/R] Rotate   [WASD] Move   [Scroll] Height')

    local function StopPlacement()
        placing = false
        if DoesEntityExist(ghost) then
            DeleteEntity(ghost)
        end
        FreezeEntityPosition(ped, false)
        lib.hideTextUI()
        SetModelAsNoLongerNeeded(hash)
    end

    CreateThread(function()
        while placing and DoesEntityExist(ghost) do
            Wait(0)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            HudWeaponWheelIgnoreSelection()

            local gx, gy, gz = table.unpack(GetEntityCoords(ghost))
            DrawMarker(36, gx, gy, gz + 1.55, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, 200, 255, 255, 200, false, false, 2, true, nil, nil, false)

            moveSpeed = IsControlPressed(0, 21) and 0.12 or 0.05

            if IsControlPressed(0, 32) then
                SetEntityCoords(ghost, GetOffsetFromEntityInWorldCoords(ghost, 0.0, moveSpeed, 0.0), false, false, false, false)
            end
            if IsControlPressed(0, 33) then
                SetEntityCoords(ghost, GetOffsetFromEntityInWorldCoords(ghost, 0.0, -moveSpeed, 0.0), false, false, false, false)
            end
            if IsControlPressed(0, 34) then
                SetEntityCoords(ghost, GetOffsetFromEntityInWorldCoords(ghost, -moveSpeed, 0.0, 0.0), false, false, false, false)
            end
            if IsControlPressed(0, 35) then
                SetEntityCoords(ghost, GetOffsetFromEntityInWorldCoords(ghost, moveSpeed, 0.0, 0.0), false, false, false, false)
            end
            if IsControlPressed(0, 44) then -- Q
                SetEntityHeading(ghost, GetEntityHeading(ghost) + 1.4)
            end
            if IsControlPressed(0, 45) then -- R
                SetEntityHeading(ghost, GetEntityHeading(ghost) - 1.4)
            end
            if IsControlPressed(0, 15) then
                SetEntityCoords(ghost, GetOffsetFromEntityInWorldCoords(ghost, 0.0, 0.0, 0.04), false, false, false, false)
            end
            if IsControlPressed(0, 14) then
                SetEntityCoords(ghost, GetOffsetFromEntityInWorldCoords(ghost, 0.0, 0.0, -0.04), false, false, false, false)
            end

            if IsControlJustPressed(0, 73) then -- X
                StopPlacement()
                Notify('Shell placement cancelled.', 'error')
                break
            end

            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 191) then
                local coords = GetEntityCoords(ghost)
                local heading = GetEntityHeading(ghost)
                if not InBuildZone(coords) then
                    Notify('You can only build in a project-car yard.', 'error')
                elseif TooCloseToOtherVehicle(coords, ghost) then
                    Notify('Too close to another vehicle.', 'error')
                else
                    local status = BuildStatus()
                    local result = lib.callback.await('kodebykarl-projectcars:server:placeShell', false, {
                        model = model,
                        slot = slot,
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        w = heading,
                        status = status,
                    })
                    StopPlacement()
                    if not result or not result.ok then
                        Notify(result and result.reason or 'Could not place the shell.', 'error')
                    else
                        Notify('Wrecked shell placed. Install parts on the 3D prompts.', 'success')
                    end
                    break
                end
            end
        end

        if placing then
            StopPlacement()
        end
    end)
end

local function TryInstall(plate, point)
    if installing or placing then return end
    installing = true

    local finished = lib.progressBar({
        duration = Config.InstallDuration or 4500,
        label = ('Installing %s…'):format(point.label),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
            flag = 49,
        },
    })

    if not finished then
        installing = false
        Notify('Install cancelled.', 'error')
        return
    end

    local result = lib.callback.await('kodebykarl-projectcars:server:installPart', false, {
        plate = plate,
        part = point.type,
        index = point.index,
    })

    installing = false

    if not result or not result.ok then
        Notify(result and result.reason or 'Install failed.', 'error')
        return
    end

    if result.complete then
        return
    end

    Notify(('%s installed.'):format(point.label), 'success')
end

RegisterNetEvent('kodebykarl-projectcars:client:useShell', function(_, info)
    if placing then return end
    local metadata = info and info.metadata or {}
    local model = metadata.model or Config.DefaultModel
    local slot = info and info.slot
    if not model or model == '' then
        Notify('This shell has no vehicle model.', 'error')
        return
    end
    StartPlacement(model, slot)
end)

RegisterNetEvent('kodebykarl-projectcars:client:sync', function(list, identifier)
    projects = list or {}
    if identifier then
        myIdentifier = identifier
    end
    RefreshSpawned()
end)

RegisterNetEvent('kodebykarl-projectcars:client:update', function(plate, data)
    plate = NormalizePlate(plate)
    if not data then
        projects[plate] = nil
        DeleteSpawned(plate)
        return
    end
    projects[plate] = data
    if spawned[plate] and spawned[plate].vehicle then
        ApplyWreckedLook(spawned[plate].vehicle, data.status or {})
    else
        RefreshSpawned()
    end
end)

RegisterNetEvent('kodebykarl-projectcars:client:finish', function(payload)
    local plate = NormalizePlate(payload and payload.plate)
    projects[plate] = nil
    DeleteSpawned(plate)

    local garage = (payload and payload.garage) or Config.GarageId or 'Legion Square'
    lib.notify({
        title = 'Project Cars',
        description = ('Congrats! You officially finished your project car. Plate %s is saved in %s garage.'):format(plate ~= '' and plate or 'your car', garage),
        type = 'success',
        duration = 12000,
    })
end)

CreateThread(function()
    while true do
        Wait(750)
        if next(projects) then
            RefreshSpawned()
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 750
        if not placing and not installing and next(spawned) then
            local ped = cache.ped
            local pCoords = GetEntityCoords(ped)
            local closest, closestDist, closestPlate

            for plate, entry in pairs(spawned) do
                local data = projects[plate]
                local veh = entry.vehicle
                if data and veh and DoesEntityExist(veh) then
                    local points = CollectPoints(data, veh)
                    for i = 1, #points do
                        local point = points[i]
                        local dist = #(pCoords - point.coords)
                        if dist <= Config.DrawDistance then
                            sleep = 0
                            DrawText3Ds(point.coords, ('[~b~E~w~] - Install %s'):format(point.label))
                            if not closestDist or dist < closestDist then
                                closest = point
                                closestDist = dist
                                closestPlate = plate
                            end
                        end
                    end
                end
            end

            if closest and closestDist <= Config.InteractDistance and IsControlJustPressed(0, 38) then
                TryInstall(closestPlate, closest)
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    myIdentifier = xPlayer and xPlayer.identifier or nil
    TriggerServerEvent('kodebykarl-projectcars:server:requestSync')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerServerEvent('kodebykarl-projectcars:server:requestSync')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for plate in pairs(spawned) do
        DeleteSpawned(plate)
    end
    lib.hideTextUI()
end)
