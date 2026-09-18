local wasTabletHiddenForInteraction = false

function hideTabletToShowInteractionPrompt(instructionText)
	if Globals.HoldingTablet then
		stopTabletAnim()
		wasTabletHiddenForInteraction = true
	end
	TriggerEvent("jg-mechanic:client:tablet-hidden-for-interaction")
	SendNUIMessage({
		instructionText = instructionText
	})
end

function showTabletAfterInteractionPrompt()
	if wasTabletHiddenForInteraction then
		playTabletAnim()
		wasTabletHiddenForInteraction = false
	end
	TriggerEvent("jg-mechanic:client:tablet-shown-after-interaction")
	SendNUIMessage({
		instructionText = false
	})
end

function ConnectVehicle(vehicleData)
	if not vehicleData then
		return false
	end

	local netId = vehicleData.netId
	local plate = vehicleData.plate
	local vehicleEntity

	while true do
		vehicleEntity = NetworkGetEntityFromNetworkId(netId)
		if vehicleEntity then
			break
		end
		Wait(0)
	end

	vehicleEntity = NetToVeh(netId)
	if not DoesEntityExist(vehicleEntity) then
		return false
	end

	if GetEntitySpeed(vehicleEntity) > 1.0 then
		Framework.Client.Notify(Locale.stopVehicleFirst, "error")
		return false
	end

	local success = lib.callback.await("jg-mechanic:server:connect-vehicle", false, plate, netId)
	if not success then
		Framework.Client.Notify("Another mechanic is connected to this vehicle", "error")
		return false
	end

	FreezeEntityPosition(vehicleEntity, true)
	vehicleData.vehicleEntity = vehicleEntity
	LocalPlayer.state:set("tabletConnectedVehicle", vehicleData, true)

	local vehicleState = Entity(vehicleEntity).state
	local vehicleModel = GetEntityModel(vehicleEntity)
	local vehicleType = "other"

	if IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel) then
		vehicleType = "car"
	elseif IsThisModelABike(vehicleModel) then
		vehicleType = "bike"
	end

	local tuningConfig = getVehicleTuningConfig(vehicleEntity, vehicleState.tuningConfig)
	local capacity = vehicleState.nitrousCapacity and (vehicleState.nitrousCapacity * 10) or 0

	local vehicleInfo = {
		vehicleType = vehicleType,
		archetypeName = GetEntityArchetypeName(vehicleEntity),
		isVehicleElectric = isVehicleElectric(GetEntityArchetypeName(vehicleEntity)),
		tuningConfig = tuningConfig,
		servicingData = vehicleState.servicingData,
		nitrousData = {
			installedBottles = vehicleState.nitrousInstalledBottles,
			filledBottles = vehicleState.nitrousFilledBottles,
			activeBtlCapacity = capacity
		}
	}
	return vehicleInfo
end

function DisconnectVehicle()
	local connectedVehicle = LocalPlayer.state.tabletConnectedVehicle
	if not connectedVehicle then
		return false
	end

	local vehicleEntity = connectedVehicle.vehicleEntity
	if vehicleEntity and DoesEntityExist(vehicleEntity) then
		FreezeEntityPosition(vehicleEntity, false)
	end

	lib.callback.await("jg-mechanic:server:disconnect-vehicle", false, connectedVehicle.plate)
	LocalPlayer.state:set("tabletConnectedVehicle", nil, true)
	return true
end

local function getNearbyVehicles()
	local playerPed = cache.ped
	local nearbyVehicles = {}
	local playerCoords = GetEntityCoords(playerPed)
	local maxDistance = Config.TabletConnectionMaxDistance or 4.0
	local foundVehicles = lib.getNearbyVehicles(playerCoords, maxDistance, true) or {}

	for _, data in ipairs(foundVehicles) do
		local plate = Framework.Client.GetPlate(data.vehicle)
		local mileage, mileageUnit = lib.callback.await("jg-mechanic:server:get-vehicle-mileage", false, plate)
		table.insert(nearbyVehicles, {
			netId = VehToNet(data.vehicle),
			label = Framework.Client.GetVehicleLabel(GetEntityArchetypeName(data.vehicle)),
			plate = plate,
			mileage = mileage,
			mileageUnit = mileageUnit
		})
	end
	return nearbyVehicles
end

local function openTablet()
	local connectedVehicleData = false
	local connectedVehicleInfo = {}
	local availableMechanics = lib.callback.await("jg-mechanic:server:get-player-mechanics", false)

	if not next(availableMechanics) then
		Framework.Client.Notify(Locale.notPartOfAnyMechanics, "error")
		return false
	end

	if cache.vehicle then
		local vehicleEntity = cache.vehicle
		local plate = Framework.Client.GetPlate(vehicleEntity)
		local mileage, mileageUnit = lib.callback.await("jg-mechanic:server:get-vehicle-mileage", false, plate)

		connectedVehicleData = {
			netId = VehToNet(vehicleEntity),
			label = Framework.Client.GetVehicleLabel(GetEntityArchetypeName(vehicleEntity)),
			plate = plate,
			mileage = mileage,
			mileageUnit = mileageUnit
		}

		local vehicleInfo = ConnectVehicle(connectedVehicleData)
		if not vehicleInfo then
			return false
		end
		connectedVehicleInfo = vehicleInfo
	end

	local preferences = lib.callback.await("jg-mechanic:server:get-tablet-preferences", false)
	LocalPlayer.state:set("isBusy", true, true)
	playTabletAnim()
	SetNuiFocus(true, true)

	SendNUIMessage(lib.table.merge({
		type = "show-tablet",
		gameBuild = GetGameBuildNumber() or 0,
		connectedVehicle = connectedVehicleData,
		availableMechanics = availableMechanics,
		vehicleConnections = getNearbyVehicles(),
		gameTime = {
			hours = GetClockHours(),
			mins = GetClockMinutes()
		},
		preferences = preferences,
		config = Config,
		locale = Locale
	}, connectedVehicleInfo))
end

-- NUI Tuning page reads .enabled on every Config.Tuning category.
local function getMechanicTuningConfig(locationTuning)
	local normalized = {}
	for category, _ in pairs(Config.Tuning or {}) do
		local entry = locationTuning and locationTuning[category]
		if type(entry) == "table" then
			normalized[category] = {
				enabled = entry.enabled == true,
				requiresItem = entry.requiresItem == true,
			}
		else
			normalized[category] = {
				enabled = false,
				requiresItem = false,
			}
		end
	end
	return normalized
end

RegisterNUICallback("tablet-login", function(data, cb)
	local mechanicId = data.mechanicId
	local mechanicLocation = Config.MechanicLocations and Config.MechanicLocations[mechanicId]

	if not mechanicId or not mechanicLocation then
		return cb(false)
	end

	LocalPlayer.state:set("mechanicId", mechanicId, true)
	local mechanicData = lib.callback.await("jg-mechanic:server:get-tablet-mechanic-data", false, mechanicId)

	if not mechanicData then
		return cb({ error = true })
	end

	cb({
		onDuty = Framework.Client.GetPlayerJobDuty(mechanicId),
		label = mechanicData.label,
		balance = mechanicData.balance,
		ownerId = mechanicData.ownerId,
		ordersCount = mechanicData.ordersCount,
		unpaidInvoicesCount = mechanicData.unpaidInvoicesCount,
		employeeRole = mechanicData.employeeRole,
		stats = mechanicData.stats,
		mechanicTuningConfig = getMechanicTuningConfig(mechanicLocation.tuning),
		playerBalance = {
			bank = Framework.Client.GetBalance("bank"),
			cash = Framework.Client.GetBalance("cash")
		}
	})
end)

RegisterNUICallback("connect-vehicle", function(data, cb)
	cb(ConnectVehicle(data.vehicle))
end)

RegisterNUICallback("disconnect-vehicle", function(data, cb)
	cb(DisconnectVehicle())
end)

RegisterNUICallback("toggle-on-duty", function(data, cb)
	if not data then
		return cb(false)
	end

	local toggle = data.toggle
	local success = lib.callback.await("jg-mechanic:server:toggle-on-duty", false, toggle)
	if not success then
		cb(false)
	end

	Framework.Client.ToggleJobDuty(toggle)
	if toggle then
		Framework.Client.Notify(Locale.onDutyNotify, "success")
	else
		Framework.Client.Notify(Locale.offDutyNotify, "success")
	end
	cb(true)
end)

RegisterNUICallback("save-preferences", function(data, cb)
	local preferences = data.preferences
	if not preferences then
		return cb(false)
	end

	local success = lib.callback.await("jg-mechanic:server:save-tablet-settings", false, preferences)
	if not success then
		return cb(false)
	end
	cb(true)
end)

RegisterNetEvent("jg-mechanic:client:use-tablet", function()
	openTablet()
end)

AddEventHandler("onResourceStop", function(resourceName)
	if GetCurrentResourceName() == resourceName then
		local connectedVehicle = LocalPlayer.state.tabletConnectedVehicle
		if connectedVehicle then
			local vehicleEntity = connectedVehicle.vehicleEntity
			if vehicleEntity then
				FreezeEntityPosition(vehicleEntity, false)
			end
		end
	end
end)
