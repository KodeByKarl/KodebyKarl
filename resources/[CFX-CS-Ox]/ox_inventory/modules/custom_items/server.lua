--[[ Custom item use handlers (migrated from ox_items) ]]

local ESX = exports['es_extended']:getSharedObject()
local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'
local cacheBetaCars = {}

local function notify(src, title, message, nType, duration)
	TriggerClientEvent('ox_lib:notify', src, {
		title = title,
		description = message,
		type = nType or 'inform',
		duration = duration or 5000,
	})
end

local function hasGroup(src, groups)
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer or not xPlayer.job then return false end
	local job = xPlayer.job.name
	if type(groups) == 'string' then
		return job == groups
	end
	for i = 1, #groups do
		if job == groups[i] then return true end
	end
	return false
end

--- Authorize health/armor gains so StatusSecure does not flag legit item use.
local function grantHealthArmor(playerId, healthDelta, armorDelta)
	pcall(function()
		exports['es_extended']:GrantHealthArmorBudget(playerId, healthDelta or 0, armorDelta or 0)
	end)
end

-- Beta car pool
local BetaCarPool = {
	{ model = 'sultan',  label = 'Karin Sultan',   chance = 32.333 },
	{ model = 'kuruma',  label = 'Karin Kuruma',   chance = 32.333 },
	{ model = 'sugoi',   label = 'Dinka Sugoi',    chance = 32.334 },
	{ model = 'jugular', label = 'Ocelot Jugular', chance = 2.0 },
	{ model = 'neon',    label = 'Pfister Neon',   chance = 1.0 },
}
local BetaBonusVehicle = { model = 'burrito', label = 'Declasse Burrito' }

local function rollBetaVehicle()
	local total = 0
	for i = 1, #BetaCarPool do
		total = total + (BetaCarPool[i].chance or 0)
	end
	local roll = math.random() * total
	local cursor = 0
	for i = 1, #BetaCarPool do
		cursor = cursor + (BetaCarPool[i].chance or 0)
		if roll <= cursor then
			return BetaCarPool[i]
		end
	end
	return BetaCarPool[1]
end

local function isPlateTaken(plate)
	local exists = MySQL.scalar.await('SELECT 1 FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
	return exists ~= nil
end

local function generateVehiclePlate()
	if GetResourceState('jg-dealerships-v2') == 'started' then
		local ok, plate = pcall(function()
			return exports['jg-dealerships-v2']:generatePlate(nil, true)
		end)
		if ok and type(plate) == 'string' and plate ~= '' and not isPlateTaken(plate) then
			return plate
		end
	end

	if GetResourceState('jg-dealerships') == 'started' then
		local ok, plate = pcall(function()
			return exports['jg-dealerships']:generatePlate()
		end)
		if ok and type(plate) == 'string' and plate ~= '' and not isPlateTaken(plate) then
			return plate
		end
	end

	for _ = 1, 20 do
		local plate = ('GR%06d'):format(math.random(0, 999999))
		if not isPlateTaken(plate) then
			return plate
		end
	end

	return ('GC%06d'):format(math.random(0, 999999))
end

local function insertOwnedVehicle(identifier, model, plate, namePrefix, garageId)
	local nick = ('%s-%s'):format(namePrefix, plate:upper())
	local vehicleJson = json.encode({ model = joaat(model), plate = plate })
	garageId = garageId or 'Legion Square'

	local ok, err = pcall(function()
		MySQL.insert.await([[
			INSERT INTO owned_vehicles
				(`owner`, `plate`, `vehicle`, `stored`, `in_garage`, `garage_id`, `nickname`, `fuel`, `engine`, `body`)
			VALUES (?, ?, ?, 1, 1, ?, ?, 100, 1000, 1000)
		]], { identifier, plate, vehicleJson, garageId, nick })
	end)
	if ok then return true end

	ok, err = pcall(function()
		MySQL.insert.await(
			'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`, `in_garage`, `garage_id`, `nickname`) VALUES (?, ?, ?, 1, 1, ?, ?)',
			{ identifier, plate, vehicleJson, garageId, nick }
		)
	end)
	if ok then return true end

	ok, err = pcall(function()
		MySQL.insert.await(
			'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`) VALUES (?, ?, ?, 1)',
			{ identifier, plate, vehicleJson }
		)
	end)
	if ok then return true end

	print(('[ox_inventory] insertOwnedVehicle failed for %s (%s / %s): %s'):format(tostring(identifier), tostring(model), tostring(plate), tostring(err)))
	return false
end

local function refundUsedItem(inventory)
	local itemName = inventory.usingItem and inventory.usingItem.name
	if not itemName then return end
	Inventory.AddItem(inventory.id, itemName, 1)
end

local function giveVehicleItem(inventory, model, namePrefix, title)
	local xPlayer = ESX.GetPlayerFromId(inventory.id)
	if not xPlayer then return false end

	local plate = generateVehiclePlate()
	if not plate or plate == '' then
		notify(xPlayer.source, title, 'Failed to generate a vehicle plate. Try again.', 'error', 7000)
		refundUsedItem(inventory)
		return false
	end

	if not insertOwnedVehicle(xPlayer.identifier, model, plate, namePrefix) then
		notify(xPlayer.source, title, 'Failed to add the vehicle to your garage. Try again.', 'error', 7000)
		refundUsedItem(inventory)
		return false
	end

	pcall(function()
		exports['kodebykarl-ui']:GiveKey(xPlayer.source, plate)
	end)

	notify(xPlayer.source, title, ('Vehicle added to Legion Square garage. Plate: %s'):format(plate:upper()), 'success', 10000)
	return true
end

CreateThread(function()
	Wait(5000)

	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `cfx-keydi-betacars` (
			`id` int NOT NULL AUTO_INCREMENT,
			`identifier` varchar(60) NOT NULL,
			`vehicle` varchar(50) DEFAULT NULL,
			`plate` varchar(12) DEFAULT NULL,
			`claimed_at` timestamp NOT NULL DEFAULT current_timestamp(),
			PRIMARY KEY (`id`),
			UNIQUE KEY `identifier` (`identifier`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	]])

	local betaCars = MySQL.query.await('SELECT `identifier` FROM `cfx-keydi-betacars`', {})
	if betaCars then
		for i = 1, #betaCars do
			cacheBetaCars[betaCars[i].identifier] = true
		end
	end
end)

exports('ems_medikit', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		notify(inventory.id, 'INVENTORY', 'Medkit is EMS-only. Eye a downed player and use Medkit (Revive).', 'error', 5000)
		return false
	end
end)

exports('medikit', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		notify(inventory.id, 'INVENTORY', 'Eye a downed player and use Medikit (Revive).', 'error', 5000)
		return false
	end
end)

exports('bandage', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local canUse, reason = lib.callback.await('ox_inventory:canUseBandage', inventory.id)
		if not canUse then
			notify(inventory.id, 'INVENTORY', reason or 'You cannot use a bandage right now.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 200, 0)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'bandage')
		return true
	end
end)

exports('gauze', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local isBleeding = lib.callback.await('ox_inventory:isPlayerBleeding', inventory.id)
		if not isBleeding then
			notify(inventory.id, 'INVENTORY', 'You are not bleeding.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		return true
	end
end)

exports('stresstabs', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		if not xPlayer then return false end

		local status = xPlayer.getMeta('status') or {}
		local stress = tonumber(status.stress) or 0
		if stress <= 0 then
			notify(inventory.id, 'INVENTORY', 'You are not stressed.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		if not xPlayer then return false end

		local status = xPlayer.getMeta('status') or {}
		local stress = tonumber(status.stress) or 0
		if stress <= 0 then return false end

		local reduction = math.max(1, math.floor(stress * 0.5))
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { stress = -reduction })
		return true
	end
end)

exports('ammo_box1', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-9', 250) then
			notify(inventory.id, 'Ammo Box', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-9', 250)
		notify(inventory.id, 'Ammo Box', 'Unpacked 250 rounds of 9mm ammunition.', 'success', 4000)
		return true
	end
end)

exports('ammo_box_smg', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-9', 300)
		return true
	end
end)

exports('ammo_box2', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-rifle', 500) then
			notify(inventory.id, 'Ammo Box', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-rifle', 500)
		notify(inventory.id, 'Ammo Box', 'Unpacked 500 rounds of 5.56x45mm ammunition.', 'success', 4000)
		return true
	end
end)

exports('ammo_box3', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-rifle2', 500) then
			notify(inventory.id, 'Ammo Box', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-rifle2', 500)
		notify(inventory.id, 'Ammo Box', 'Unpacked 500 rounds of 7.62x39mm ammunition.', 'success', 4000)
		return true
	end
end)

exports('ammo_box4', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-50', 200)
		return true
	end
end)

exports('ammo_box5', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-45', 200)
		return true
	end
end)

exports('pd_ammo_box_9', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-9', 250) then
			notify(inventory.id, 'PD Armory', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-9', 250)
		notify(inventory.id, 'PD Armory', 'Unpacked 250 rounds of 9mm Ammunition.', 'success', 4000)
		return true
	end
end)

exports('pd_ammo_box_rifle', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-rifle', 250) then
			notify(inventory.id, 'PD Armory', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-rifle', 250)
		notify(inventory.id, 'PD Armory', 'Unpacked 250 rounds of 5.56 Rifle Ammunition.', 'success', 4000)
		return true
	end
end)

exports('pd_ammo_box_rifle2', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-rifle2', 250) then
			notify(inventory.id, 'PD Armory', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-rifle2', 250)
		notify(inventory.id, 'PD Armory', 'Unpacked 250 rounds of 7.62 Rifle Ammunition.', 'success', 4000)
		return true
	end
end)

exports('pd_ammo_box_shotgun', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-shotgun', 250) then
			notify(inventory.id, 'PD Armory', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-shotgun', 250)
		notify(inventory.id, 'PD Armory', 'Unpacked 250 rounds of 12G Shotgun Ammunition.', 'success', 4000)
		return true
	end
end)

exports('pd_ammo_box_45', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-45', 250) then
			notify(inventory.id, 'PD Armory', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-45', 250)
		notify(inventory.id, 'PD Armory', 'Unpacked 250 rounds of .45 ACP Ammunition.', 'success', 4000)
		return true
	end
end)

-- Sheriff Custom Items
exports('sheriff_ammo_box_9', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-9', 250) then
			notify(inventory.id, 'Sheriff Armoury', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-9', 250)
		notify(inventory.id, 'Sheriff Armoury', 'Unpacked 250 rounds of 9mm Ammunition.', 'success', 4000)
		return true
	end
end)

exports('sheriff_ammo_box_rifle', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-rifle', 250) then
			notify(inventory.id, 'Sheriff Armoury', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-rifle', 250)
		notify(inventory.id, 'Sheriff Armoury', 'Unpacked 250 rounds of 5.56 Rifle Ammunition.', 'success', 4000)
		return true
	end
end)

exports('sheriff_ammo_box_rifle2', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-rifle2', 250) then
			notify(inventory.id, 'Sheriff Armoury', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-rifle2', 250)
		notify(inventory.id, 'Sheriff Armoury', 'Unpacked 250 rounds of 7.62 Rifle Ammunition.', 'success', 4000)
		return true
	end
end)

exports('sheriff_ammo_box_shotgun', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-shotgun', 250) then
			notify(inventory.id, 'Sheriff Armoury', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-shotgun', 250)
		notify(inventory.id, 'Sheriff Armoury', 'Unpacked 250 rounds of 12G Shotgun Ammunition.', 'success', 4000)
		return true
	end
end)

exports('sheriff_ammo_box_45', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'ammo-45', 250) then
			notify(inventory.id, 'Sheriff Armoury', 'Inventory is too full to unpack this ammo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'ammo-45', 250)
		notify(inventory.id, 'Sheriff Armoury', 'Unpacked 250 rounds of .45 ACP Ammunition.', 'success', 4000)
		return true
	end
end)

exports('sheriff_vitamins', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'sheriff', 'police'}) then
			notify(inventory.id, 'INVENTORY', 'You are not an active sheriff deputy.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 200, 100)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'sheriff_vitamins')
		return true
	end
end)

exports('sheriff_drink', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'sheriff', 'police'}) then
			notify(inventory.id, 'INVENTORY', 'You are not an active sheriff deputy.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { thirst = 50 })
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'sheriff_drink')
		return true
	end
end)

exports('sheriff_vest', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'sheriff', 'police'}) then
			notify(inventory.id, 'Inventory', 'You can\'t use this item.', 'error', 5000)
			return false
		end
	end
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 0, 100)
		local ped = GetPlayerPed(inventory.id)
		local currentAmour = GetPedArmour(ped) + 100
		if currentAmour > 100 then currentAmour = 100 end
		SetPedArmour(ped, currentAmour)
		return true
	end
end)

local ProjectPartsBoxContents = {
	{ partType = 'engine', count = 1 },
	{ partType = 'transmission', count = 1 },
	{ partType = 'suspension', count = 1 },
	{ partType = 'bodyframe', count = 1 },
	{ partType = 'tire', count = 4 },
	{ partType = 'door', count = 4 },
	{ partType = 'window', count = 4 },
}

local function resolveProjectModel(metadata)
	if type(metadata) == 'table' and metadata.model and metadata.model ~= '' then
		return tostring(metadata.model):lower():gsub('%s+', '')
	end
	return 'ody18'
end

local function pickProjectModel()
	if GetResourceState('kodebykarl-projectcars') == 'started' then
		local ok, rolled = pcall(function()
			return exports['kodebykarl-projectcars']:PickRandomProjectModel()
		end)
		if ok and type(rolled) == 'string' and rolled ~= '' then
			return rolled
		end
	end
	return 'ody18'
end

local function resolvePartItem(partType, model)
	if GetResourceState('kodebykarl-projectcars') == 'started' then
		local ok, itemName = pcall(function()
			return exports['kodebykarl-projectcars']:GetPartItemName(model, partType)
		end)
		if ok and type(itemName) == 'string' and itemName ~= '' then
			return itemName
		end
	end
	return partType
end

local function buildPartMeta(itemName, model)
	if GetResourceState('kodebykarl-projectcars') == 'started' then
		local ok, meta = pcall(function()
			return exports['kodebykarl-projectcars']:BuildPartMetadata(itemName, model)
		end)
		if ok and type(meta) == 'table' then
			return meta
		end
	end
	return {
		model = model,
		vehicle = model:upper(),
		label = itemName == 'vehicle_shell' and (model:upper() .. ' Shell') or ('Project Vehicle Part'),
		description = ('Fits %s project cars only.'):format(model:upper()),
	}
end

-- Full ayuda kit: shell + 25 blueprints + all install parts for one vehicle
local function buildAyudaContents(model)
	if GetResourceState('kodebykarl-projectcars') == 'started' then
		local ok, kit = pcall(function()
			return exports['kodebykarl-projectcars']:GetProjectBuildKit(model)
		end)
		if ok and type(kit) == 'table' and #kit > 0 then
			return kit
		end
	end
	return {
		{ item = 'vehicle_shell', count = 1, metadata = buildPartMeta('vehicle_shell', model) },
		{ item = 'car_blueprint', count = 25, metadata = buildPartMeta('car_blueprint', model) },
	}
end

local function canCarryProjectContents(invId, contents)
	for i = 1, #contents do
		local entry = contents[i]
		if not Inventory.CanCarryItem(invId, entry.item, entry.count) then
			return false
		end
	end
	return true
end

local function giveProjectContents(invId, contents)
	for i = 1, #contents do
		local entry = contents[i]
		Inventory.AddItem(invId, entry.item, entry.count, entry.metadata)
	end
end

exports('project_parts_box', function(event, item, inventory, slot, data)
	local contents = {}
	for i = 1, #ProjectPartsBoxContents do
		local entry = ProjectPartsBoxContents[i]
		for _ = 1, (entry.count or 1) do
			local model = pickProjectModel()
			local itemName = resolvePartItem(entry.partType, model)
			contents[#contents + 1] = {
				item = itemName,
				count = 1,
				metadata = buildPartMeta(itemName, model),
			}
		end
	end

	if event == 'usingItem' then
		if not canCarryProjectContents(inventory.id, contents) then
			notify(inventory.id, 'PROJECT PARTS', 'Inventory is too full to unpack this parts box.', 'error', 5000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		giveProjectContents(inventory.id, contents)
		notify(inventory.id, 'PROJECT PARTS', 'Unpacked mixed project-car parts. Check each item for which vehicle it fits.', 'success', 5000)
		return true
	end
end)

exports('project_ayuda_box', function(event, item, inventory, slot, data)
	local model = resolveProjectModel(item and item.metadata)
	local contents = buildAyudaContents(model)

	if event == 'usingItem' then
		if not canCarryProjectContents(inventory.id, contents) then
			notify(inventory.id, 'PROJECT AYUDA', 'Inventory is too full to unpack this ayuda box.', 'error', 5000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		giveProjectContents(inventory.id, contents)
		notify(inventory.id, 'PROJECT AYUDA', ('Unpacked shell, blueprints, and %s parts.'):format(model:upper()), 'success', 6000)
		return true
	end
end)

local RecycleProjectParts = {
	'engine',
	'transmission',
	'suspension',
	'bodyframe',
	'tire',
	'door',
	'window',
}

local RecycleDirtyMoney = { min = 20000, max = 30000 }

local pendingRecycle = {}

local function pickRecycleProjectModel()
	if GetResourceState('kodebykarl-projectcars') == 'started' then
		local ok, model = pcall(function()
			return exports['kodebykarl-projectcars']:PickRandomProjectModel()
		end)
		if ok and type(model) == 'string' and model ~= '' then
			return model
		end
	end
	return 'ody18'
end

local function rollRecycleContents()
	local model = pickRecycleProjectModel()
	local contents = {
		{ item = 'iron', count = 2 },
		{ item = 'copper', count = 2 },
		{ item = 'aluminum', count = 2 },
		{ item = 'plastic', count = 2 },
		{ item = 'glass', count = 2 },
		{ item = 'rubber', count = 2 },
		{ item = 'steel', count = 2 },
		{ item = 'gunpowder', count = 2 },
		{ item = 'car_blueprint', count = 2, metadata = buildPartMeta('car_blueprint', model) },
	}

	for _ = 1, 2 do
		local partType = RecycleProjectParts[math.random(1, #RecycleProjectParts)]
		local partModel = pickRecycleProjectModel()
		local itemName = resolvePartItem(partType, partModel)
		contents[#contents + 1] = {
			item = itemName,
			count = 1,
			metadata = buildPartMeta(itemName, partModel),
		}
	end

	local dirtyMin = RecycleDirtyMoney.min
	local dirtyMax = RecycleDirtyMoney.max
	if dirtyMax < dirtyMin then dirtyMax = dirtyMin end
	contents[#contents + 1] = {
		item = 'black_money',
		count = math.random(dirtyMin, dirtyMax),
	}

	return contents
end

local function summarizeRecycleLoot(contents)
	local grouped = {}
	local order = {}
	for i = 1, #contents do
		local entry = contents[i]
		local label = Items(entry.item) and Items(entry.item).label or entry.item
		local model = entry.metadata and entry.metadata.model
		local key = entry.item .. '\0' .. tostring(model or '')
		if not grouped[key] then
			grouped[key] = { item = entry.item, label = label, count = 0, model = model }
			order[#order + 1] = key
		end
		grouped[key].count = grouped[key].count + (entry.count or 1)
	end
	local bits = {}
	for i = 1, #order do
		local row = grouped[order[i]]
		if row.item == 'black_money' then
			bits[#bits + 1] = ('$%s dirty money'):format(row.count)
		elseif row.model and row.model ~= '' then
			bits[#bits + 1] = ('%sx %s (%s)'):format(row.count, row.label, tostring(row.model):upper())
		else
			bits[#bits + 1] = ('%sx %s'):format(row.count, row.label)
		end
	end
	return table.concat(bits, ', ')
end

exports('recmats', function(event, item, inventory, slot, data)
	local invId = inventory and inventory.id
	if not invId then return false end

	if event == 'usingItem' then
		local contents = rollRecycleContents()
		if not canCarryProjectContents(invId, contents) then
			notify(invId, 'RECYCLING', 'Inventory is too full to sort these materials.', 'error', 5000)
			return false
		end
		pendingRecycle[invId] = contents
		return true
	elseif event == 'usedItem' then
		local contents = pendingRecycle[invId]
		pendingRecycle[invId] = nil
		if not contents then
			contents = rollRecycleContents()
		end
		giveProjectContents(invId, contents)
		notify(invId, 'RECYCLING', ('Sorted %s.'):format(summarizeRecycleLoot(contents)), 'success', 7000)
		return true
	end
end)

exports('joint', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 0, 50)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'joint')
		TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', inventory.id)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		return true
	end
end)

exports('weeds', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 0, 50)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'joint')
		TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', inventory.id)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		return true
	end
end)

exports('meth', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 50, 0)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'meth')
		TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', inventory.id)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		return true
	end
end)

exports('cocaine', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 50, 50)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'cocaine')
		TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', inventory.id)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		return true
	end
end)

exports('energy_drink', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'police', 'sheriff'}) then
			notify( inventory.id, 'Inventory', 'You can\'t use this item.', 'error', 5000)
			return false
		end
	end
	if event == 'usedItem' then
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'energy_drink')
		return true
	end
end)

exports('police_pill', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'police', 'sheriff'}) then
			notify( inventory.id, 'INVENTORY', 'You are not a cop.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 800, 100)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'police_pill')
		return true
	end
end)

exports('police_vitamins', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'police', 'sheriff'}) then
			notify(inventory.id, 'INVENTORY', 'You are not an active police officer.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 200, 100)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'police_vitamins')
		return true
	end
end)

exports('police_drink', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'police', 'sheriff'}) then
			notify(inventory.id, 'INVENTORY', 'You are not an active police officer.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { thirst = 50 })
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'police_drink')
		return true
	end
end)

exports('oxy', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 50, 50)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'oxy')
		TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', inventory.id)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		return true
	end
end)

exports('ecstasy', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 50, 50)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'ecstasy')
		TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', inventory.id)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		return true
	end
end)

exports('half_vest', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 0, 50)
		local ped = GetPlayerPed(inventory.id)
		local currentAmour = GetPedArmour(ped) + 50
		if currentAmour > 50 then currentAmour = 50 end
		SetPedArmour(ped, currentAmour)
		return true
	end
end)

exports('bulletproof', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 0, 100)
		local ped = GetPlayerPed(inventory.id)
		local currentAmour = GetPedArmour(ped) + 100
		if currentAmour > 100 then currentAmour = 100 end
		SetPedArmour(ped, currentAmour)
		return true
	end
end)

local function applyCraftedVest(inventoryId, maxArmor)
	grantHealthArmor(inventoryId, 0, maxArmor)
	local ped = GetPlayerPed(inventoryId)
	local current = GetPedArmour(ped) + maxArmor
	if current > maxArmor then current = maxArmor end
	SetPedArmour(ped, current)
	return true
end

exports('bulletproof_25', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		return applyCraftedVest(inventory.id, 25)
	end
end)

exports('bulletproof_50', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		return applyCraftedVest(inventory.id, 50)
	end
end)

exports('bulletproof_75', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		return applyCraftedVest(inventory.id, 75)
	end
end)

exports('bulletproof_100', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		return applyCraftedVest(inventory.id, 100)
	end
end)

exports('police_vest', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'police'}) then
			notify(inventory.id, 'Inventory', 'Only on-duty police can use this vest.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 0, 100)
		local ped = GetPlayerPed(inventory.id)
		SetPedArmour(ped, 100)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'police_vest')
		return true
	end
end)

exports('riot_shield', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not hasGroup(inventory.id, {'police', 'sheriff'}) then
			notify(inventory.id, 'PD Armory', 'Only on-duty police can use a riot shield.', 'error', 5000)
			return false
		end
		-- consume = 0 never reaches usedItem — equip as soon as use is allowed.
		TriggerClientEvent('cfx-cs-police:EquipShield', inventory.id)
		return true
	end
end)

exports('lockpick', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		if GetResourceState('kodebykarl-robbery') == 'started' or GetResourceState('cfx-cs-robbery') == 'started' then
			TriggerClientEvent('cfx-cs-robbery:houserob:UseLockpick', inventory.id, false)
		end
		return true
	end
end)

exports('advancedlockpick', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		if GetResourceState('kodebykarl-robbery') == 'started' or GetResourceState('cfx-cs-robbery') == 'started' then
			TriggerClientEvent('cfx-cs-robbery:houserob:UseLockpick', inventory.id, true)
		end
		return true
	end
end)

exports('documents', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		if GetResourceState('cfx-cs-docs') == 'started' then
			TriggerClientEvent('cfx-cs-docs:ViewDocs', inventory.id, inventory.usingItem.metadata)
		end
		return true
	end
end)

exports('reskin_card', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local src = inventory.id
		if GetResourceState('illenium-appearance') ~= 'started' then
			notify( src, 'RESKIN', 'Appearance system is unavailable.', 'error', 5000)
			return false
		end
		return true
	end

	if event == 'usedItem' then
		local src = inventory.id
		-- Full ped menu (same as /balat): ped, face, surgery features, clothes — free, no shop charge
		TriggerClientEvent('illenium-appearance:client:openClothingShopMenu', src, true)
		notify( src, 'RESKIN', 'Reskin card used. Customize your appearance.', 'success', 5000)
		return true
	end
end)

-- Beta box car token — uses cfx-keydi-betacars
exports('item_beta_car', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		if not xPlayer then return false end

		if cacheBetaCars[xPlayer.identifier] then
			notify( xPlayer.source, 'BETA CAR', 'You have already claimed your beta vehicle!', 'error', 5000)
			return false
		end

		return true
	end

	if event == 'usedItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		if not xPlayer then return false end

		if cacheBetaCars[xPlayer.identifier] then
			notify( xPlayer.source, 'BETA CAR', 'You have already claimed your beta vehicle!', 'error', 5000)
			return false
		end

		local win = rollBetaVehicle()
		local plate1 = generateVehiclePlate()
		local plate2 = generateVehiclePlate()

		local id = MySQL.insert.await(
			'INSERT INTO `cfx-keydi-betacars` (`identifier`, `vehicle`, `plate`) VALUES (?, ?, ?)',
			{ xPlayer.identifier, win.model, plate1 }
		)

		if not id then
			notify( xPlayer.source, 'BETA CAR', 'Failed to claim beta vehicle. Try again.', 'error', 5000)
			return false
		end

		if not insertOwnedVehicle(xPlayer.identifier, win.model, plate1, 'BETA-' .. win.model:upper()) then
			notify(xPlayer.source, 'BETA CAR', 'Failed to add the prize vehicle. Try again.', 'error', 5000)
			return false
		end
		insertOwnedVehicle(xPlayer.identifier, BetaBonusVehicle.model, plate2, 'BETA-BURRITO')

		cacheBetaCars[xPlayer.identifier] = true

		notify(xPlayer.source, 'BETA CAR', ('You won %s + %s! Both are in your garage.'):format(win.label, BetaBonusVehicle.label), 'success', 10000)
		return true
	end
end)

exports('robitussin', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		local result = lib.callback.await('cfx-cs-utils:Cure', inventory.id, 'cough')
		if result then
			local xPlayer = ESX.GetPlayerFromId(inventory.id)
			xPlayer.setMeta('disease', 'none')
			return true
		end
		return false
	end
end)

exports('ondansetron', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		local result = lib.callback.await('cfx-cs-utils:Cure', inventory.id, 'vomit')
		if result then
			local xPlayer = ESX.GetPlayerFromId(inventory.id)
			xPlayer.setMeta('disease', 'none')
			return true
		end
		return false
	end
end)

exports('meclizine', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		local result = lib.callback.await('cfx-cs-utils:Cure', inventory.id, 'dizzy')
		if result then
			local xPlayer = ESX.GetPlayerFromId(inventory.id)
			xPlayer.setMeta('disease', 'none')
			return true
		end
		return false
	end
end)

local handcuffUsed = {}
local handcuffKeyUsed = {}
local ropeUsed = {}
local cuffedPlayers = {}
local escortCache = {}

exports('handcuff', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		handcuffUsed[inventory.id] = true
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'handcuff')
		return true
	end
end)

exports('handcuff_keys', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		handcuffKeyUsed[inventory.id] = true
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'handcuff_keys')
		return true
	end
end)

exports('rope', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		ropeUsed[inventory.id] = true
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'rope')
		return true
	end
end)

local function ValidateCuff(xPlayer, xTarget, target)
	local playerCoords = xPlayer.getCoords(true)
	local targetCoords = xTarget.getCoords(true)
	if target == -1 then
		return false, 'ALL PLAYERS CHECK'
	end
	if #(playerCoords - targetCoords) > 3.5 then
		return false, 'DISTANCE CHECK'
	end
	local itemCount = Inventory.Search(xPlayer.source, 'count', 'handcuff')
	if itemCount < 0 then
		return false, 'ITEM CHECK'
	end
	if not handcuffUsed[xPlayer.source] then
		return false, 'ADVANCED CHECK'
	end
	return true
end

local function ValidateUncuff(xPlayer, xTarget, target)
	local playerCoords = xPlayer.getCoords(true)
	local targetCoords = xTarget.getCoords(true)
	if target == -1 then
		return false, 'ALL PLAYERS CHECK'
	end
	if #(playerCoords - targetCoords) > 3.5 then
		return false, 'DISTANCE CHECK'
	end
	local itemCount = Inventory.Search(xPlayer.source, 'count', 'handcuff_keys')
	if itemCount < 0 then
		return false, 'ITEM CHECK'
	end
	if not handcuffKeyUsed[xPlayer.source] then
		return false, 'ADVANCED CHECK'
	end
	return true
end

local function ValidateRope(xPlayer, xTarget, target)
	local playerCoords = xPlayer.getCoords(true)
	local targetCoords = xTarget.getCoords(true)
	if target == -1 then
		return false, 'ALL PLAYERS CHECK'
	end
	if #(playerCoords - targetCoords) > 3.5 then
		return false, 'DISTANCE CHECK'
	end
	local itemCount = Inventory.Search(xPlayer.source, 'count', 'rope')
	if itemCount < 0 then
		return false, 'ITEM CHECK'
	end
	if not ropeUsed[xPlayer.source] then
		return false, 'ADVANCED CHECK'
	end
	return true
end

local function HandcuffLogs(xPlayer, xTarget, item)
	local sourceName = xPlayer.name
	local targetName = xTarget.name
	local sourceCoords = xPlayer.getCoords(true)
	local targetCooords = xTarget.getCoords(true)
	local text = {
		('SENTRY DETECTION FOR %s ITEM'):format(item),
		('Source Player: %s [%s]'):format(sourceName, xPlayer.source),
		('Target Player: %s [%s]'):format(targetName, xTarget.source),
		('Source Coords: %s'):format('vec3('..sourceCoords.x..', '..sourceCoords.y..', '..sourceCoords.z..')'),
		('Target Coords: %s'):format('vec3('..targetCooords.x..', '..targetCooords.y..', '..targetCooords.z..')')
	}
	return table.concat(text, ' | ')
end

RegisterNetEvent('ox_items:handcuff', function(target)
	if target == -1 then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(target)
	if cuffedPlayers[xTarget.source] then return end
	local success, reason = ValidateCuff(xPlayer, xTarget, target)
	if not success then
		local logText = HandcuffLogs(xPlayer, xTarget, 'HANDCUFF')
		return lib.print.error(('%s | %s'):format(logText, reason))
	end
	cuffedPlayers[xTarget.source] = true
	Player(xTarget.source).state.cuffed = true
	Inventory.RemoveItem(xPlayer.source, 'handcuff', 1)
	TriggerClientEvent('ox_items:handcuffClient', xTarget.source)
	handcuffUsed[xPlayer.source] = nil
end)

RegisterNetEvent('ox_items:handcuff_keys', function(target)
	if target == -1 then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(target)
	if not cuffedPlayers[xTarget.source] then return end
	local success, reason = ValidateUncuff(xPlayer, xTarget, target)
	if not success then
		local logText = HandcuffLogs(xPlayer, xTarget, 'HANDCUFF KEY')
		return lib.print.error(('%s | %s'):format(logText, reason))
	end
	cuffedPlayers[xTarget.source] = nil
	Player(xTarget.source).state.cuffed = false
	Inventory.RemoveItem(xPlayer.source, 'handcuff_keys', 1)
	TriggerClientEvent('ox_items:handcuffKeyClient', xTarget.source)
	handcuffKeyUsed[xPlayer.source] = nil
end)

RegisterNetEvent('ox_items:rope', function(target)
	if target == -1 then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(target)
	if not cuffedPlayers[xTarget.source] then return end
	local success, reason = ValidateRope(xPlayer, xTarget, target)
	if not success then
		local logText = HandcuffLogs(xPlayer, xTarget, 'ROPE')
		return lib.print.error(('%s | %s'):format(logText, reason))
	end
	local progressLabel = {}
	local isEscorting = {}
	if not escortCache[xPlayer.source] then
		escortCache[xPlayer.source] = true
		isEscorting[xPlayer.source] = true
		progressLabel[xPlayer.source] = 'Attempting to drag . . .'
	else
		escortCache[xPlayer.source] = nil
		isEscorting[xPlayer.source] = false
		progressLabel[xPlayer.source] = 'Removing drag . . .'
	end
	if lib.callback.await('ox_items:RopeUsed', xPlayer.source, xTarget.source, progressLabel[xPlayer.source], isEscorting[xPlayer.source]) then
		TriggerClientEvent('ox_items:ropeClient', xTarget.source, xPlayer.source)
		ropeUsed[xPlayer.source] = nil
	end
end)

exports('business_combo', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		if inventory.usingItem.metadata and next(inventory.usingItem.metadata) then
			for i = 1, #inventory.usingItem.metadata.toAdd do
				local itemData = inventory.usingItem.metadata.toAdd[i]
				Inventory.AddItem(inventory.id, itemData.item, itemData.amount)
			end
		end
		return true
	end
end)

local ItemBoxes = {
	['bshot_combo1'] = {
		{ item = 'burgershot_food3', amount = 5 },
		{ item = 'burgershot_drink3', amount = 5 },
	},
	['welcome_kit'] = {
		{ item = 'money', amount = 50000 },
		{ item = 'burger', amount = 5 },
		{ item = 'water', amount = 5 },
		{ item = 'phone', amount = 1 },
		{ item = 'lockpick', amount = 5 },
		{ item = 'reskin_card', amount = 1 },
		{ item = 'new_player_card', amount = 1 },
	},
	['betabox'] = {
		{ item = 'item_beta_car', amount = 1 },
		{ item = 'money', amount = 50000 },
		{ item = 'ayuda_box', amount = 1 },
	},
	['old_player_box'] = {
		{ item = 'money', amount = 500000 },
		{ item = 'WEAPON_PISTOL', amount = 10 },
		{ item = 'ammo-box1', amount = 10 },
		{ item = 'joint', amount = 10 },
		{ item = 'lockpick', amount = 10 },
		{ item = 'stash_car', amount = 1 },
	},
	['ayuda_box'] = {
		{ item = 'money', amount = 300000 },
		{ item = 'lockpick', amount = 10 },
		{ item = 'joint', amount = 5 },
		{ item = 'project_ayuda_box', amount = 1 },
	},
	['food_drinks_box'] = {
		{ item = 'grim_tea', amount = 5 },
		{ item = 'grim_peas', amount = 5 },
	},
	['hightable_box1'] = {
		{ item = 'WEAPON_PISTOL50', amount = 3 },
		{ item = 'WEAPON_VINTAGEPISTOL', amount = 4 },
		{ item = 'WEAPON_PISTOL_MK2', amount = 2 },
		{ item = 'ammo-box4', amount = 2 },
		{ item = 'ammo-box1', amount = 5 },
		{ item = 'at_suppressor_heavy', amount = 3 },
		{ item = 'at_suppressor_light', amount = 5 },
	},
	['hightable_box2'] = {
		{ item = 'WEAPON_APPISTOL', amount = 3 },
		{ item = 'WEAPON_MINISMG', amount = 3 },
		{ item = 'ammo-box1', amount = 4 }
	},
	['hightable_box3'] = {
		{ item = 'WEAPON_ASSAULTRIFLE_MK2', amount = 3 },
		{ item = 'WEAPON_SPECIALCARBINE', amount = 3 },
		{ item = 'WEAPON_ASSAULTRIFLE', amount = 4 },
		{ item = 'ammo-box2', amount = 4 },
		{ item = 'ammo-box3', amount = 4 },
		{ item = 'at_suppressor_heavy', amount = 10 },
	},
	['hightable_box4'] = {
		{ item = 'pendrive', amount = 5 },
		{ item = 'laptop_h', amount = 5 },
		{ item = 'lockpick', amount = 5 },
	},
	['mechanic_box'] = {
		-- Performance & Cosmetics
		{ item = 'performance_part', amount = 10 },
		{ item = 'cosmetic_part', amount = 10 },
		{ item = 'stancing_kit', amount = 10 },
		{ item = 'respray_kit', amount = 10 },
		{ item = 'vehicle_wheels', amount = 10 },
		{ item = 'lighting_controller', amount = 10 },
		{ item = 'tyre_smoke_kit', amount = 10 },
		{ item = 'bulletproof_tyres', amount = 10 },
		{ item = 'extras_kit', amount = 10 },

		-- Tuning & Engine Swaps
		{ item = 'i4_engine', amount = 10 },
		{ item = 'v6_engine', amount = 10 },
		{ item = 'v8_engine', amount = 10 },
		{ item = 'v12_engine', amount = 10 },
		{ item = 'turbocharger', amount = 10 },
		{ item = 'awd_drivetrain', amount = 10 },
		{ item = 'rwd_drivetrain', amount = 10 },
		{ item = 'fwd_drivetrain', amount = 10 },
		{ item = 'slick_tyres', amount = 10 },
		{ item = 'semi_slick_tyres', amount = 10 },
		{ item = 'offroad_tyres', amount = 10 },
		{ item = 'drift_tuning_kit', amount = 10 },
		{ item = 'ceramic_brakes', amount = 10 },
		{ item = 'obd_scanner', amount = 10 },
		{ item = 'ceramic_coating', amount = 10 },
		{ item = 'tire_plug_kit', amount = 10 },
		{ item = 'jumpstarter_pack', amount = 10 },

		-- Servicing & Wearable Parts
		{ item = 'engine_oil', amount = 10 },
		{ item = 'spark_plug', amount = 10 },
		{ item = 'clutch_replacement', amount = 10 },
		{ item = 'air_filter', amount = 10 },
		{ item = 'suspension_parts', amount = 10 },
		{ item = 'tyre_replacement', amount = 10 },
		{ item = 'brakepad_replacement', amount = 10 },
		{ item = 'ev_motor', amount = 10 },
		{ item = 'ev_battery', amount = 10 },
		{ item = 'ev_coolant', amount = 10 },

		-- Tools, Nitrous & Maintenance
		{ item = 'mechanic_tablet', amount = 10 },
		{ item = 'nitrous_install_kit', amount = 10 },
		{ item = 'nitrous_bottle', amount = 10 },
		{ item = 'empty_nitrous_bottle', amount = 10 },
		{ item = 'repair_kit', amount = 10 },
		{ item = 'cleaning_kit', amount = 10 },
		{ item = 'duct_tape', amount = 10 },
	}
}

exports('itemBoxes', function(event, item, inventory, slot, data)
	if event ~= 'usedItem' then return end
	if not item or not item.name then return false end

	local rewards = ItemBoxes[item.name]
	if not rewards then
		print(('[ox_inventory] itemBoxes: no rewards configured for %s'):format(item.name))
		return false
	end

	local invId = inventory and (inventory.id or inventory)
	if not invId then return false end

	for i = 1, #rewards do
		local reward = rewards[i]
		if reward and reward.item and reward.amount then
			Inventory.AddItem(invId, reward.item, reward.amount)
		end
	end

	if item.name == 'food_drinks_box' then
		notify(invId, 'FOOD & DRINKS', 'Unpacked 5x Grim Tea and 5x Grim Peas.', 'success', 4000)
	end

	return true
end)

exports('car_crate', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		local metadata = inventory.usingItem.metadata
		if not metadata or not metadata.crafting then return false end
		local plate = generateVehiclePlate()
		MySQL.insert.await('INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`, `nickname`) VALUES (?, ?, ?, ?, ?)', {xPlayer.identifier, plate, ('{"model":%s,"plate":"%s"}'):format(GetHashKey(metadata.crafting.model), plate), true, ('CRAFTING-%s'):format(plate)})
		notify( xPlayer.source, 'CAR CRAFTING', 'Please get your vehicle for free at your nearest garage!', 'success', 10000)
		notify( xPlayer.source, 'CAR CRAFTING', ('You have received your car with the registration plate: %s'):format(string.upper(plate)), 'success', 10000)
		return true
	end
end)

exports('gang_perks_sunrise', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		local plate = generateVehiclePlate()
		notify( xPlayer.source, 'GANG PERKS', 'Please get your vehicle for free at your nearest garage!', 'success', 10000)
		notify( xPlayer.source, 'GANG PERKS', ('You have received your sunrise with plate: %s'):format(plate:upper()), 'success', 10000)
		MySQL.insert.await('INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `stored`, `nickname`, `name`) VALUES (?, ?, ?, ?, ?, ?)', {xPlayer.identifier, plate, ('{"model":%s,"plate":"%s"}'):format(`sunrise1`, plate), true, ('GANG-SUNRISE-%s'):format(plate:upper()), ('GANG-SUNRISE-%s'):format(plate:upper())})
		return true
	end
end)

exports('stash_car', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		return giveVehicleItem(inventory, 'burrito', 'STASH', 'STASH CAR')
	end
end)

exports('item_sunrise', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		return giveVehicleItem(inventory, 'sunrise1', 'SUNRISE', 'SUNRISE')
	end
end)

exports('item_16topcargle', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		return giveVehicleItem(inventory, '16topcargle', 'TOPCAR', 'TOPCAR GLE')
	end
end)

exports('grim_tea', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { thirst = 50 })
		return true
	end
end)

exports('grim_peas', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { hunger = 50 })
		return true
	end
end)

-- 8-Ball Food, Drink & Combo Box
exports('8ball_food', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { hunger = 50 })
		notify(inventory.id, '8-BALL DINER', 'Ate an 8-Ball Burger (+50% Hunger).', 'success', 3500)
		return true
	end
end)

exports('8ball_drink', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { thirst = 50 })
		notify(inventory.id, '8-BALL DINER', 'Drank an 8-Ball Soda (+50% Thirst).', 'success', 3500)
		return true
	end
end)

exports('8ball_box', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, '8ball_food', 5) or not Inventory.CanCarryItem(inventory.id, '8ball_drink', 5) then
			notify(inventory.id, '8-BALL DINER', 'Inventory is too full to unpack this combo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, '8ball_food', 5)
		Inventory.AddItem(inventory.id, '8ball_drink', 5)
		notify(inventory.id, '8-BALL DINER', 'Unpacked 8-Ball Combo Box: 5x 8-Ball Burgers & 5x 8-Ball Sodas!', 'success', 5000)
		return true
	end
end)

-- Taco Shop Food, Drink & Combo Box
exports('taco_food', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { hunger = 50 })
		notify(inventory.id, 'TACO SHOP', 'Ate a Crispy Taco (+50% Hunger).', 'success', 3500)
		return true
	end
end)

exports('taco_drink', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { thirst = 50 })
		notify(inventory.id, 'TACO SHOP', 'Drank a Taco Drink (+50% Thirst).', 'success', 3500)
		return true
	end
end)

exports('taco_box', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'taco_food', 5) or not Inventory.CanCarryItem(inventory.id, 'taco_drink', 5) then
			notify(inventory.id, 'TACO SHOP', 'Inventory is too full to unpack this combo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'taco_food', 5)
		Inventory.AddItem(inventory.id, 'taco_drink', 5)
		notify(inventory.id, 'TACO SHOP', 'Unpacked Taco Combo Box: 5x Crispy Tacos & 5x Taco Drinks!', 'success', 5000)
		return true
	end
end)

-- Legacy Taco Shop Aliases
exports('taco_food1', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { hunger = 50 })
		notify(inventory.id, 'TACO SHOP', 'Ate a Crispy Taco (+50% Hunger).', 'success', 3500)
		return true
	end
end)

exports('taco_drink1', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		exports['es_extended']:SecureApplyItemStatus(inventory.id, { thirst = 50 })
		notify(inventory.id, 'TACO SHOP', 'Drank a Taco Drink (+50% Thirst).', 'success', 3500)
		return true
	end
end)

exports('taco_meal', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		if not Inventory.CanCarryItem(inventory.id, 'taco_food', 5) or not Inventory.CanCarryItem(inventory.id, 'taco_drink', 5) then
			notify(inventory.id, 'TACO SHOP', 'Inventory is too full to unpack this combo box.', 'error', 4000)
			return false
		end
		return true
	elseif event == 'usedItem' then
		Inventory.AddItem(inventory.id, 'taco_food', 5)
		Inventory.AddItem(inventory.id, 'taco_drink', 5)
		notify(inventory.id, 'TACO SHOP', 'Unpacked Taco Combo Box: 5x Crispy Tacos & 5x Taco Drinks!', 'success', 5000)
		return true
	end
end)

exports('police_gauze', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		if xPlayer and xPlayer.job.name ~= 'police' then
			notify( xPlayer.source, 'INVENTORY', 'You are not a cop.', 'error', 5000)
			return false
		end
		local isBleeding = lib.callback.await('ox_inventory:isPlayerBleeding', inventory.id)
		if not isBleeding then
			notify(inventory.id, 'INVENTORY', 'You are not bleeding.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', inventory.id)
		return true
	end
end)

exports('police_sting', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		if xPlayer and xPlayer.job.name ~= 'police' then
			notify( xPlayer.source, 'INVENTORY', 'You are not a cop.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'police_sting')
		Inventory.RemoveItem(inventory.id, 'police_sting', 1)
		return true
	end
end)

exports('police_bandage', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		if xPlayer and xPlayer.job.name ~= 'police' then
			notify( xPlayer.source, 'INVENTORY', 'You are not a cop.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 160, 0)
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'police_bandage')
		Inventory.RemoveItem(inventory.id, 'police_bandage', 1)
		return true
	end
end)

exports('police_kevlar', function(event, item, inventory, slot, data)
	if event == 'usingItem' then
		local xPlayer = ESX.GetPlayerFromId(inventory.id)
		if xPlayer and xPlayer.job.name ~= 'police' then
			notify( xPlayer.source, 'INVENTORY', 'You are not a cop.', 'error', 5000)
			return false
		end
		return true
	end
	if event == 'usedItem' then
		grantHealthArmor(inventory.id, 0, 100)
		local ped = GetPlayerPed(inventory.id)
		local currentAmour = GetPedArmour(ped) + 100
		if currentAmour > 100 then currentAmour = 100 end
		SetPedArmour(ped, currentAmour)
		Inventory.RemoveItem(inventory.id, 'police_kevlar', 1)
		return true
	end
end)

exports('boombox', function(event, item, inventory, slot, data)
	if event == 'usedItem' then
		TriggerClientEvent('ox_items:UsedItem', inventory.id, 'boombox')
		return true
	end
end)

RegisterNetEvent('wasabi_boombox:syncActive', function(activeRadios)
	TriggerClientEvent('wasabi_boombox:syncActive', -1, activeRadios)
end)

RegisterNetEvent('wasabi_boombox:soundStatus', function(type, musicId, data)
	local src = source
	if type == 'play' and tonumber(data.distance) > 40 or type == 'play' and data.volume > 1.0
	or type == 'distance' and tonumber(data.distance) > 40 or type == 'volume' and data.volume > 1.0 then
		return
	end
	TriggerClientEvent('wasabi_boombox:soundStatus', -1, type, musicId, data)
end)

local cacheBoombox = {}

RegisterNetEvent('wasabi_boombox:deleteObj', function(netId)
	local src = source
	TriggerClientEvent('wasabi_boombox:deleteObj', -1, netId)
	local networkId = NetworkGetEntityFromNetworkId(netId)
	if cacheBoombox[networkId] then
		local boomboxItem = Items('boombox')
		local metadata = { durability = cacheBoombox[networkId], degrade = boomboxItem and boomboxItem.degrade }
		Inventory.AddItem(src, 'boombox', 1, metadata)
		cacheBoombox[networkId] = nil
	end
end)

RegisterNetEvent('wasabi_boombox:registerBoombox', function(netId)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local networkId = NetworkGetEntityFromNetworkId(netId)
	if cacheBoombox[networkId] then return end
	Inventory.RemoveItem(xPlayer.source, 'boombox', 1)
	cacheBoombox[networkId] = os.time()
end)

AddEventHandler('playerDropped', function()
	pendingRecycle[source] = nil
end)
