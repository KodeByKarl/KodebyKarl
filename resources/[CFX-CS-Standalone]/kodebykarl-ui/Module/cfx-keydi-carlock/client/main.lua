if not ConfigCarlock or not ConfigCarlock.Enabled then return end

local busy = false

local function locale(key)
    return ConfigCarlock.Locale[key] or key
end

local function normalizePlate(plate)
    if not plate or plate == "" then return "" end
    return (string.gsub(tostring(plate), "^%s*(.-)%s*$", "%1")):upper()
end

local function notify(description, nType, icon)
    lib.notify({
        title = locale("NotifyTitle"),
        description = description,
        type = nType or "inform",
        icon = icon,
        position = "top",
        style = {
            backgroundColor = "#1E1E2E",
            color = "#C1C2C5",
            [".description"] = { color = "#909296" },
        },
    })
end

local function vehicleLights(vehicle)
    SetVehicleLights(vehicle, 2)
    Wait(200)
    SetVehicleLights(vehicle, 0)
    Wait(150)
    SetVehicleLights(vehicle, 2)
    Wait(500)
    SetVehicleLights(vehicle, 0)
end

local function vehicleHorn(vehicle)
    StartVehicleHorn(vehicle, 200, "HELDDOWN", false)
    Wait(300)
    StartVehicleHorn(vehicle, 150, "HELDDOWN", false)
end

local function getClosestVehicle(radius)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end

    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool("CVehicle")
    local closest, closestDist = 0, radius or ConfigCarlock.CheckRadius

    for i = 1, #vehicles do
        local veh = vehicles[i]
        if DoesEntityExist(veh) then
            local dist = #(coords - GetEntityCoords(veh))
            if dist < closestDist then
                closest = veh
                closestDist = dist
            end
        end
    end

    return closest ~= 0 and closest or nil
end

local function playLockEffects(vehicle, locking)
    local coords = GetEntityCoords(PlayerPedId())

    lib.progressCircle({
        duration = ConfigCarlock.ProgressLength,
        label = locking and locale("ProgressLocking") or locale("ProgressUnlocking"),
        position = "bottom",
        useWhileDead = false,
        canCancel = false,
        disable = ConfigCarlock.DisableWhileLocking,
        anim = ConfigCarlock.Anim,
    })

    if ConfigCarlock.Sounds then
        PlaySoundFromCoord(-1, "PIN_BUTTON", coords.x, coords.y, coords.z, "ATM_SOUNDS", true, 5, false)
    end

    if ConfigCarlock.Lights then
        vehicleLights(vehicle)
    end

    if not locking and ConfigCarlock.Horn then
        vehicleHorn(vehicle)
    end
end

local function ToggleLock(entity)
    if busy then
        notify(locale("Busy"), "error", "triangle-exclamation")
        return
    end

    local vehicle = entity
    if not vehicle or vehicle == 0 then
        vehicle = getClosestVehicle(ConfigCarlock.CheckRadius)
    end

    if not vehicle or not DoesEntityExist(vehicle) then
        if ConfigCarlock.Notifications.NoNearbyVehicles then
            notify(locale("NoVehicleNearby"), "error", "triangle-exclamation")
        end
        return
    end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    if plate == "" then return end

    busy = true

    local hasKeys = lib.callback.await("cfx-keydi-carlock:hasKeys", false, plate)
    if not hasKeys then
        busy = false
        if ConfigCarlock.Notifications.NotYourVehicle then
            notify(locale("NotOwned"), "error", "triangle-exclamation")
        end
        return
    end

    local status = GetVehicleDoorLockStatus(vehicle)
    local locking = status ~= 2 and status ~= 3 and status ~= 4
    -- 2 = locked from outside; occupants can still exit
    local newStatus = locking and 2 or 1
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local ok = lib.callback.await("cfx-keydi-carlock:toggle", false, netId, plate, newStatus)

    if not ok then
        busy = false
        if ConfigCarlock.Notifications.NotYourVehicle then
            notify(locale("NotOwned"), "error", "triangle-exclamation")
        end
        return
    end

    NetworkRequestControlOfEntity(vehicle)
    SetVehicleDoorsLocked(vehicle, newStatus)
    if ConfigCarlock.LockMeCommand then
        ExecuteCommand(locking and "me Locking vehicle" or "me Unlocking vehicle")
    end

    playLockEffects(vehicle, locking)

    if locking and ConfigCarlock.Notifications.Locked then
        notify(locale("NotifyLocked"), "error", "lock")
    elseif not locking and ConfigCarlock.Notifications.Unlocked then
        notify(locale("NotifyUnlocked"), "success", "lock-open")
    end

    busy = false
end

local function openManageKeys(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    local hasKeys, kind = lib.callback.await("cfx-keydi-carlock:hasKeys", false, plate)

    if not hasKeys or kind ~= "owned" then
        notify(locale("ShareBlocked"), "error", "triangle-exclamation")
        return
    end

    lib.registerContext({
        id = "cfx_keydi_carlock_manage",
        title = locale("ShareTitle"),
        options = {
            {
                title = locale("ShareKeys"),
                icon = "key",
                onSelect = function()
                    local opt = {}
                    local myId = GetPlayerServerId(PlayerId())
                    for _, player in ipairs(GetActivePlayers()) do
                        local sid = GetPlayerServerId(player)
                        if sid ~= myId then
                            opt[#opt + 1] = {
                                value = sid,
                                label = ("[%s] %s"):format(sid, GetPlayerName(player)),
                            }
                        end
                    end

                    if #opt == 0 then
                        notify(locale("NoVehicleNearby"), "error", "triangle-exclamation")
                        return
                    end

                    local input = lib.inputDialog(locale("ShareKeys"), {
                        {
                            type = "select",
                            label = locale("SelectPlayer"),
                            icon = "user",
                            options = opt,
                            required = true,
                        },
                    })
                    if not input or not input[1] then return end

                    local shared, reason = lib.callback.await("cfx-keydi-carlock:shareKeys", false, input[1], plate)
                    if not shared and reason == "already" then
                        notify(locale("AlreadyShared"), "error", "triangle-exclamation")
                    end
                end,
            },
            {
                title = locale("RemoveKeys"),
                icon = "trash-alt",
                onSelect = function()
                    local keys = lib.callback.await("cfx-keydi-carlock:getSharedKeys", false, plate) or {}
                    local opt = {}

                    if #keys == 0 then
                        opt = { { title = locale("NoShared"), disabled = true } }
                    else
                        for i = 1, #keys do
                            local v = keys[i]
                            opt[#opt + 1] = {
                                title = ("[%s] %s"):format(v.id, v.player),
                                description = ("Plate: %s"):format(v.plate),
                                icon = "trash-alt",
                                onSelect = function()
                                    local confirm = lib.alertDialog({
                                        header = locale("RemoveKeys"),
                                        content = locale("ConfirmRemove"):format(v.plate, v.player),
                                        centered = true,
                                        cancel = true,
                                    })
                                    if confirm == "confirm" then
                                        lib.callback.await("cfx-keydi-carlock:removeKeys", false, v.id, v.plate)
                                    end
                                end,
                            }
                        end
                    end

                    lib.registerContext({
                        id = "cfx_keydi_carlock_remove",
                        title = locale("RemoveKeys"),
                        options = opt,
                    })
                    lib.showContext("cfx_keydi_carlock_remove")
                end,
            },
        },
    })
    lib.showContext("cfx_keydi_carlock_manage")
end

AddStateBagChangeHandler("carlock", nil, function(bagName, _, value)
    if type(value) ~= "number" then return end
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 or not DoesEntityExist(entity) then return end
    if value == 4 then value = 2 end -- occupants can exit; still locked from outside
    SetVehicleDoorsLocked(entity, value)
end)

if ConfigCarlock.Target then
    exports.ox_target:addGlobalVehicle({
        {
            name = "cfx-keydi-carlock:toggle",
            icon = ConfigCarlock.TargetIcon,
            label = locale("TargetLock"),
            distance = ConfigCarlock.TargetDistance,
            onSelect = function(data)
                ToggleLock(data.entity)
            end,
        },
        {
            name = "cfx-keydi-carlock:manage",
            icon = "fa-solid fa-key",
            label = locale("TargetManage"),
            distance = ConfigCarlock.TargetDistance,
            onSelect = function(data)
                openManageKeys(data.entity)
            end,
        },
    })
end

RegisterCommand(ConfigCarlock.Command, function()
    ToggleLock()
end, false)

RegisterKeyMapping(ConfigCarlock.Command, "Lock or unlock your vehicle", "keyboard", ConfigCarlock.DefaultKey)

exports("GiveKey", function(plate)
    if not plate or plate == "" then return false end
    TriggerServerEvent("cfx-keydi-carlock:server:giveKey", plate)
    return true
end)

exports("RemoveKey", function(plate)
    if not plate or plate == "" then return false end
    TriggerServerEvent("cfx-keydi-carlock:server:removeKey", plate)
    return true
end)

exports("ToggleLock", ToggleLock)
exports("shareKey", function(_, plate)
    -- Client cannot assign keys to another player; use the server export.
    if plate then
        TriggerServerEvent("cfx-keydi-carlock:server:giveKey", plate)
    end
end)
