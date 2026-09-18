local config = require 'configs.clothing'
local Vars = require 'helpers.vars'
local registeredItem = {
	['torso'] = true,
	['pants'] = true,
	['shoes'] = true,
	['mask'] = true,
	['ears'] = true,
	['chain'] = true,
	['glasses'] = true,
	['vest'] = true,
	['helmet'] = true,
	['bag'] = true
}

local function FormatSentry(xPlayer, item, metadata)
    local playerCoords = xPlayer.getCoords(true)
    local text = {
        ('SENTRY DETECTION FOR CLOTHING SYSTEM'),
        ('Name: %s [%s]'):format(xPlayer.name, xPlayer.source),
        ('Item Provided: %s'):format(item),
		('Metadata Provided: %s'):format(metadata),
        ('Coords: %s'):format('vec3('..playerCoords.x..', '..playerCoords.y..', '..playerCoords.z..')')
    }
    return table.concat(text, ' | ')
end

RegisterNetEvent('cfx-keydi-utils:Clothing:RemoveClothes', function(itemType, metadata, slot)
	local src = source
	local theType = itemType
	local xPlayer = ESX.GetPlayerFromId(src)
	if type(itemType) ~= 'string' then
		-- backwards compat: old signature (skin1, skin2, type, metadata)
		theType = metadata
		metadata = slot
		slot = nil
	end
	if not registeredItem[theType] then
		lib.logger(src, 'cfx-keydi-sentry', FormatSentry(xPlayer, theType, json.encode(metadata)), 'ERROR')
		print(("^0[^3cfx-keydi-utils^0] [CLOTHING]: Validation failed for %s: %s"):format(xPlayer.name, 'CHECK 1'))
		return
	end
	if slot then
		Vars.ox:RemoveItem(src, theType, 1, nil, slot)
	else
		Vars.ox:RemoveItem(src, theType, 1, metadata)
	end
end)


local function CheckCurrentClothes(src, gender, skin1, skin2, skin3, skin4, skin5, skin6)
	local HasItem = Vars.ox:Search(src, 'slots', 'torso')
	if not HasItem or not next(HasItem) then return true end
	for _, v in pairs(HasItem) do
		if v.metadata and v.metadata.gender == gender and v.metadata.torso1 == skin1 and v.metadata.torso2 == skin2 and v.metadata.arms1 == skin3 and v.metadata.arms2 == skin4 and v.metadata.tshirt1 == skin5 and v.metadata.tshirt2 == skin6 then
			TriggerClientEvent('cfx-keydi-utils:Clothing:Notification', src, 'error', 'You already have this clothing item in your inventory.', 'SYSTEM', 5000)
			return false
		end
	end	
	return true
end

local function CheckClothes(src, gender, skin1, skin2, theType)
	local HasItem = Vars.ox:Search(src, 'slots', theType)
	if not HasItem or not next(HasItem) then return true end
	for _, v in pairs(HasItem) do
		if v.metadata and v.metadata.gender == gender and v.metadata.accessories == skin1 and v.metadata.accessories2 == skin2 then
			TriggerClientEvent('cfx-keydi-utils:Clothing:Notification', src, 'error', 'You already have this clothing item in your inventory.', 'SYSTEM', 5000)
			return false
		end
	end
	return true
end

RegisterNetEvent('cfx-keydi-utils:Clothing:AddClothes', function(skin1, skin2, type, gender)
	local src = source
	local theType = type
	local metadata = {gender = gender, accessories = skin1, accessories2 = skin2, description = '[Gender: '..gender..'] ['..theType..' 1 #'..skin1..'] - ['..theType..' 2 #'..skin2..']'}
	local xPlayer = ESX.GetPlayerFromId(src)
	if not registeredItem[theType] then
		lib.logger(src, 'cfx-keydi-sentry', FormatSentry(xPlayer, theType, json.encode(metadata)), 'ERROR')
        print(("^0[^3cfx-keydi-utils^0] [CLOTHING]: Validation failed for %s: %s"):format(xPlayer.name, 'CHECK 2'))
		return
	end
	if CheckClothes(src, gender, skin1, skin2, theType) then
		Vars.ox:AddItem(src, theType, 1, metadata)
	end
end)

RegisterNetEvent('cfx-keydi-utils:Clothing:AddTorso', function(skin1, skin2, skin3, skin4, skin5, skin6, hakdog, gender)
	local src = source
	local clothes1 = hakdog
	local clothes2 = 'arms'
	local clothes3 = 'tshirt'
	local metadata = {gender = gender,torso1 = skin1, torso2 = skin2, arms1 = skin3, arms2 = skin4, tshirt1 = skin5, tshirt2 = skin6, description = '[Gender: '..gender..'] ['..clothes1..' 1 #'..skin1..'] [Torso 2 #'..skin2..'] ['..clothes2..' 1 #'..skin3..'] [Arms 2 #'..skin4..'] ['..clothes3..' 1 #'..skin5..'] [T-Shirt 2 #'..skin6..']' }
	if CheckCurrentClothes(src, gender, skin1, skin2, skin3, skin4, skin5, skin6) then
		Vars.ox:AddItem(src, 'torso', 1, metadata)
	end
end)

RegisterNetEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', function(robber, skin1, skin2, type, gender)
	local src = source
	robber = tonumber(robber)
	if not robber or robber < 1 or robber == src then return end
	local xVictim = ESX.GetPlayerFromId(src)
	local xRobber = ESX.GetPlayerFromId(robber)
	if not xVictim or not xRobber then return end
	if #(xVictim.getCoords(true) - xRobber.getCoords(true)) > 5.0 then return end

	local theType = type
	if not registeredItem[theType] then return end
	local metadata = {
		gender = gender,
		accessories = skin1,
		accessories2 = skin2,
		description = '[Gender: '..gender..'] ['..theType..' 1 #'..skin1..'] - ['..theType..' 2 #'..skin2..']'
	}
	Vars.ox:AddItem(robber, theType, 1, metadata)
end)

RegisterNetEvent('cfx-keydi-utils:Clothing:Rob:AddTorso', function(robber, skin1, skin2, skin3, skin4, skin5, skin6, hakdog, gender)
	local src = source
	robber = tonumber(robber)
	if not robber or robber < 1 or robber == src then return end
	local xVictim = ESX.GetPlayerFromId(src)
	local xRobber = ESX.GetPlayerFromId(robber)
	if not xVictim or not xRobber then return end
	if #(xVictim.getCoords(true) - xRobber.getCoords(true)) > 5.0 then return end

	local metadata = {
		gender = gender,
		torso1 = skin1,
		torso2 = skin2,
		arms1 = skin3,
		arms2 = skin4,
		tshirt1 = skin5,
		tshirt2 = skin6,
		description = '[Gender: '..gender..'] [torso 1 #'..skin1..'] [Torso 2 #'..skin2..'] [arms 1 #'..skin3..'] [Arms 2 #'..skin4..'] [tshirt 1 #'..skin5..'] [T-Shirt 2 #'..skin6..']'
	}
	Vars.ox:AddItem(robber, 'torso', 1, metadata)
end)

for i = 1, #config.commands do
	local v = config.commands[i]
	RegisterCommand(v.Command, function(source, args, rawCommand)
		local src = source
		TriggerClientEvent('cfx-keydi-utils:Clothing:MenuActions', src, {value = v.type})
	end)
end
