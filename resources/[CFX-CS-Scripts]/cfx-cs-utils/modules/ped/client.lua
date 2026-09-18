local pedsReady = false
local streamerStarted = false
local config = require 'configs.peds'
local Vars = require 'helpers.vars'

local SPAWN_DIST = 80.0
local DESPAWN_DIST = 120.0

local function safeRequestModel(model)
	local hash = type(model) == 'string' and joaat(model) or model
	if not hash or not IsModelInCdimage(hash) or not IsModelValid(hash) then
		return nil
	end
	RequestModel(hash)
	local timeout = GetGameTimer() + 8000
	while not HasModelLoaded(hash) do
		if GetGameTimer() > timeout then
			return nil
		end
		Wait(10)
	end
	return hash
end

local function EnsureBlip(k, v)
	if not v.blip then return end
	local handle = v.blip.data
	if handle and handle ~= 0 and DoesBlipExist(handle) then return end
	local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
	SetBlipSprite(blip, v.blip.sprite)
	SetBlipColour(blip, v.blip.color)
	SetBlipScale(blip, v.blip.scale or 0.8)
	SetBlipAsShortRange(blip, v.blip.shortRange ~= false)
	SetBlipDisplay(blip, v.blip.display or 4)
	SetBlipHighDetail(blip, true)
	SetBlipCategory(blip, v.blip.category or 1)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(v.blip.label)
	EndTextCommandSetBlipName(blip)
	config[k].blip.data = blip
end

local function PedExists(v)
	local ped = v and v.currentpednumber
	return ped and ped ~= 0 and DoesEntityExist(ped)
end

local function DespawnConfiguredPed(k)
	local v = config[k]
	if not v then return end
	local ped = v.currentpednumber
	if ped and ped ~= 0 and DoesEntityExist(ped) then
		if v.target and not v.target.useModel then
			pcall(function()
				Vars.oxTarget:removeLocalEntity(ped)
			end)
		end
		DeletePed(ped)
	end
	config[k].currentpednumber = 0
end

local function SpawnConfiguredPed(k)
	local v = config[k]
	if not v or not v.coords then return false end
	if PedExists(v) then return true end

	local modelHash = safeRequestModel(v.model)
	if not modelHash then
		print(('[cfx-keydi-utils] Failed to load ped model: %s'):format(tostring(v.model)))
		return false
	end

	local z = v.minusOne and (v.coords.z - 1.0) or v.coords.z
	RequestCollisionAtCoord(v.coords.x, v.coords.y, z)
	Wait(100)

	local ok, spawnedped = pcall(CreatePed, 0, modelHash, v.coords.x, v.coords.y, z, v.coords.w or 0.0, v.networked or false, false)
	if not ok or not spawnedped or spawnedped == 0 or not DoesEntityExist(spawnedped) then
		print(('[cfx-keydi-utils] Failed to create ped: %s'):format(tostring(v.model)))
		SetModelAsNoLongerNeeded(modelHash)
		return false
	end

	SetEntityAsMissionEntity(spawnedped, true, true)
	SetEntityLodDist(spawnedped, 150)
	SetEntityCoordsNoOffset(spawnedped, v.coords.x, v.coords.y, z, false, false, false)
	SetEntityHeading(spawnedped, v.coords.w or 0.0)

	if v.freeze then
		FreezeEntityPosition(spawnedped, true)
	end

	if v.invincible then
		SetEntityInvincible(spawnedped, true)
	end

	if v.blockevents then
		SetBlockingOfNonTemporaryEvents(spawnedped, true)
	end

	if v.movement then
		RequestAnimSet(v.movement)
		local t = GetGameTimer() + 5000
		while not HasAnimSetLoaded(v.movement) and GetGameTimer() < t do Wait(50) end
		if HasAnimSetLoaded(v.movement) then
			SetPedMovementClipset(spawnedped, v.movement, 0.2)
		end
	end

	if v.animDict and v.anim then
		RequestAnimDict(v.animDict)
		local t = GetGameTimer() + 5000
		while not HasAnimDictLoaded(v.animDict) and GetGameTimer() < t do Wait(10) end
		if HasAnimDictLoaded(v.animDict) then
			TaskPlayAnim(spawnedped, v.animDict, v.anim, 8.0, 0, -1, v.flag or 1, 0, false, false, false)
		end
	end

	if v.scenario then
		SetPedCanPlayAmbientAnims(spawnedped, true)
		TaskStartScenarioInPlace(spawnedped, v.scenario, 0, true)
		-- Scenario can spin the ped; keep configured heading.
		SetEntityHeading(spawnedped, v.coords.w or 0.0)
	end

	if v.pedrelations then
		if type(v.pedrelations.groupname) ~= 'string' then error(v.pedrelations.groupname .. ' is not a string') end

		local pedgrouphash = joaat(v.pedrelations.groupname)

		if not DoesRelationshipGroupExist(pedgrouphash) then
			AddRelationshipGroup(v.pedrelations.groupname)
		end

		SetPedRelationshipGroupHash(spawnedped, pedgrouphash)
		if v.pedrelations.toplayer then
			SetRelationshipBetweenGroups(v.pedrelations.toplayer, pedgrouphash, joaat('PLAYER'))
		end

		if v.pedrelations.toowngroup then
			SetRelationshipBetweenGroups(v.pedrelations.toowngroup, pedgrouphash, pedgrouphash)
		end
	end

	if v.weapon then
		if type(v.weapon.name) == 'string' then v.weapon.name = joaat(v.weapon.name) end

		if IsWeaponValid(v.weapon.name) then
			SetCanPedEquipWeapon(spawnedped, v.weapon.name, true)
			GiveWeaponToPed(spawnedped, v.weapon.name, v.weapon.ammo, v.weapon.hidden or false, true)
			SetPedCurrentWeaponVisible(spawnedped, not v.weapon.hidden or false, true)
		end
	end

	if v.target then
		if v.target.useModel then
			Vars.oxTarget:addModel(modelHash, v.target.options)
		else
			Vars.oxTarget:addLocalEntity(spawnedped, v.target.options)
		end
	end

	if v.action then
		v.action(v)
	end
	if v.prop then
		local propHash = safeRequestModel(v.prop.model)
		if propHash then
			local object = CreateObject(propHash, v.coords.x, v.coords.y, v.coords.z, false, false, false)
			if object and object ~= 0 and DoesEntityExist(object) then
				AttachEntityToEntity(object, spawnedped, (v.prop.bone or GetPedBoneIndex(spawnedped, 57005)), v.prop.pos.x, v.prop.pos.y, v.prop.pos.z, v.prop.rot.x, v.prop.rot.y, v.prop.rot.z, true, true, false, true, 1, true)
			end
			SetModelAsNoLongerNeeded(propHash)
		end
	end

	config[k].currentpednumber = spawnedped
	SetModelAsNoLongerNeeded(modelHash)
	return true
end

local function StartPedStreamer()
	if streamerStarted then return end
	streamerStarted = true
	pedsReady = true

	CreateThread(function()
		while GetResourceState('ox_target') ~= 'started' do
			Wait(200)
		end
		Vars.oxTarget = Vars.oxTarget or exports.ox_target

		while streamerStarted do
			local pos = GetEntityCoords(PlayerPedId())
			for k, v in pairs(config) do
				if v.coords then
					EnsureBlip(k, v)
					local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
					if dist <= SPAWN_DIST then
						if not PedExists(v) then
							SpawnConfiguredPed(k)
						end
					elseif dist >= DESPAWN_DIST then
						if PedExists(v) then
							DespawnConfiguredPed(k)
						end
					end
				end
			end
			Wait(2000)
		end
	end)
end

RegisterNetEvent('esx:playerLoaded', function ()
	-- Delay ped spawn until appearance/model swap has settled
	CreateThread(function()
		Wait(5000)
		SpawnPeds()
	end)
end)

AddEventHandler('onResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	CreateThread(function()
		Wait(2000)
		SpawnPeds()
	end)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	DeletePeds()
end)

function SpawnPeds()
	if not next(config) then return end
	StartPedStreamer()
end

function DeletePeds()
	streamerStarted = false
	if not next(config) then
		pedsReady = false
		return
	end
	for k, v in pairs(config) do
		DespawnConfiguredPed(k)
		if v.blip and v.blip.data and v.blip.data ~= 0 then
			RemoveBlip(v.blip.data)
			config[k].blip.data = 0
		end
	end
	pedsReady = false
end

exports("DeletePeds", DeletePeds)

local function SpawnPed(data)
	local spawnedped
	local key, value = next(data)
	if type(value) == 'table' and type(key) ~= 'string' then
		for _, v in pairs(data) do
			if v.spawnNow then
				RequestModel(v.model)
				while not HasModelLoaded(v.model) do
					Wait(0)
				end

				if type(v.model) == 'string' then v.model = joaat(v.model) end

				if v.minusOne then
					spawnedped = CreatePed(0, v.model, v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w or 0.0, v.networked or false, true)
				else
					spawnedped = CreatePed(0, v.model, v.coords.x, v.coords.y, v.coords.z, v.coords.w or 0.0, v.networked or false, true)
				end

				if v.freeze then
					FreezeEntityPosition(spawnedped, true)
				end

				if v.invincible then
					SetEntityInvincible(spawnedped, true)
				end

				if v.blockevents then
					SetBlockingOfNonTemporaryEvents(spawnedped, true)
				end

				if v.animDict and v.anim then
					RequestAnimDict(v.animDict)
					while not HasAnimDictLoaded(v.animDict) do
						Wait(0)
					end

					TaskPlayAnim(spawnedped, v.animDict, v.anim, 8.0, 0, -1, v.flag or 1, 0, false, false, false)
				end

				if v.scenario then
					SetPedCanPlayAmbientAnims(spawnedped, true)
					TaskStartScenarioInPlace(spawnedped, v.scenario, 0, true)
				end

				if v.pedrelations and type(v.pedrelations.groupname) == 'string' then
					if type(v.pedrelations.groupname) ~= 'string' then error(v.pedrelations.groupname .. ' is not a string') end

					local pedgrouphash = joaat(v.pedrelations.groupname)

					if not DoesRelationshipGroupExist(pedgrouphash) then
						AddRelationshipGroup(v.pedrelations.groupname)
					end

					SetPedRelationshipGroupHash(spawnedped, pedgrouphash)
					if v.pedrelations.toplayer then
						SetRelationshipBetweenGroups(v.pedrelations.toplayer, pedgrouphash, joaat('PLAYER'))
					end

					if v.pedrelations.toowngroup then
						SetRelationshipBetweenGroups(v.pedrelations.toowngroup, pedgrouphash, pedgrouphash)
					end
				end

				if v.weapon then
					if type(v.weapon.name) == 'string' then v.weapon.name = joaat(v.weapon.name) end

					if IsWeaponValid(v.weapon.name) then
						SetCanPedEquipWeapon(spawnedped, v.weapon.name, true)
						GiveWeaponToPed(spawnedped, v.weapon.name, v.weapon.ammo, v.weapon.hidden or false, true)
						SetPedCurrentWeaponVisible(spawnedped, not v.weapon.hidden or false, true)
					end
				end

				if v.target then
					if v.target.useModel then
						Vars.oxTarget:addModel(v.model, v.target.options)
					else
						Vars.oxTarget:addLocalEntity(spawnedped, v.target.options)
					end
				end

				v.currentpednumber = spawnedped

				if v.action then
					v.action(v)
				end
			end

			local nextnumber = #config + 1
			if nextnumber <= 0 then nextnumber = 1 end

			config[nextnumber] = v
		end
	else
		if data.spawnNow then
			RequestModel(data.model)
			while not HasModelLoaded(data.model) do
				Wait(0)
			end

			if type(data.model) == 'string' then data.model = joaat(data.model) end

			if data.minusOne then
				spawnedped = CreatePed(0, data.model, data.coords.x, data.coords.y, data.coords.z - 1.0, data.coords.w, data.networked or false, true)
			else
				spawnedped = CreatePed(0, data.model, data.coords.x, data.coords.y, data.coords.z, data.coords.w, data.networked or false, true)
			end

			if data.freeze then
				FreezeEntityPosition(spawnedped, true)
			end

			if data.invincible then
				SetEntityInvincible(spawnedped, true)
			end

			if data.blockevents then
				SetBlockingOfNonTemporaryEvents(spawnedped, true)
			end

			if data.animDict and data.anim then
				RequestAnimDict(data.animDict)
				while not HasAnimDictLoaded(data.animDict) do
					Wait(0)
				end

				TaskPlayAnim(spawnedped, data.animDict, data.anim, 8.0, 0, -1, data.flag or 1, 0, false, false, false)
			end

			if data.scenario then
				SetPedCanPlayAmbientAnims(spawnedped, true)
				TaskStartScenarioInPlace(spawnedped, data.scenario, 0, true)
			end

			if data.pedrelations then
				if type(data.pedrelations.groupname) ~= 'string' then error(data.pedrelations.groupname .. ' is not a string') end

				local pedgrouphash = joaat(data.pedrelations.groupname)

				if not DoesRelationshipGroupExist(pedgrouphash) then
					AddRelationshipGroup(data.pedrelations.groupname)
				end

				SetPedRelationshipGroupHash(spawnedped, pedgrouphash)
				if data.pedrelations.toplayer then
					SetRelationshipBetweenGroups(data.pedrelations.toplayer, pedgrouphash, joaat('PLAYER'))
				end

				if data.pedrelations.toowngroup then
					SetRelationshipBetweenGroups(data.pedrelations.toowngroup, pedgrouphash, pedgrouphash)
				end
			end

			if data.weapon then
				if type(data.weapon.name) == 'string' then data.weapon.name = joaat(data.weapon.name) end

				if IsWeaponValid(data.weapon.name) then
					SetCanPedEquipWeapon(spawnedped, data.weapon.name, true)
					GiveWeaponToPed(spawnedped, data.weapon.name, data.weapon.ammo, data.weapon.hidden or false, true)
					SetPedCurrentWeaponVisible(spawnedped, not data.weapon.hidden or false, true)
				end
			end

			if data.target then
				if data.target.useModel then
					Vars.oxTarget:addModel(data.model, {
						options = data.target.options,
						distance = data.target.distance
					})
				else
					Vars.oxTarget:addLocalEntity(spawnedped, {
						options = data.target.options,
						distance = data.target.distance
					})
				end
			end
			data.currentpednumber = spawnedped
			if data.action then
				data.action(data)
			end
		end
		local nextnumber = #config + 1
		if nextnumber <= 0 then nextnumber = 1 end
		config[nextnumber] = data
	end
end

exports("SpawnPed", SpawnPed)

local function RemovePed(peds)
	if type(peds) == 'table' then
		for k, v in pairs(peds) do
			DeletePed(v)
			if config[k] then config[k].currentpednumber = 0 end
		end
	elseif type(peds) == 'number' then
		DeletePed(peds)
	end
end

exports("RemoveSpawnedPed", RemovePed)
