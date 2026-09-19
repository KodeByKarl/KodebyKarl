ESX = exports['es_extended']:getSharedObject()
local Vars = require 'helpers.vars'
local config = require 'shared.config'
local menu = require 'shared.menu'

-- oxmysql TINYINT(1) can come back as 1, "1", or true — `value == 1` misses the rest.
local function parseDeadFlag(value)
	if value == true or value == 1 or value == '1' then
		return true
	end
	if type(value) == 'number' and value ~= 0 then
		return true
	end
	return false
end

local function persistDeadFlag(identifier, isDead)
	if not identifier then return end
	pcall(function()
		MySQL.update.await('UPDATE users SET dead = ? WHERE identifier = ?', { isDead and 1 or 0, identifier })
	end)
end

-- Ensure users.dead exists (ambulance death persistence)
CreateThread(function()
	MySQL.ready(function()
		pcall(function()
			MySQL.query.await([[
				ALTER TABLE `users`
				ADD COLUMN IF NOT EXISTS `dead` TINYINT(1) NOT NULL DEFAULT 0
			]])
		end)
	end)
end)

--- Sync pma-voice mute with death. Death mute is authoritative; clearing dead MUST unmute.
local function setVoiceMute(src, muted)
	if GetResourceState('pma-voice') ~= 'started' then return end
	pcall(function()
		exports['pma-voice']:MutePlayer(src, muted and true or false)
	end)
end

local FG_RESOURCE_CANDIDATES = { 'grimbot', 'fiveguard', 'fg', 'FiveGuard' }
local DEATH_FG_PERMS = { 'BypassTeleport', 'BypassInvisible', 'BypassFreecam', 'BypassGodMode' }

local function fgResource()
	local named = GetConvar('fiveguard_resource', '')
	if named ~= '' and GetResourceState(named) == 'started' then
		return named
	end
	for i = 1, #FG_RESOURCE_CANDIDATES do
		local name = FG_RESOURCE_CANDIDATES[i]
		if GetResourceState(name) == 'started' then
			return name
		end
	end
	return nil
end

local function fgTemp(src, enable, perms)
	if type(src) ~= 'number' or src < 1 then return end
	local resource = fgResource()
	if not resource then return end
	pcall(function()
		for i = 1, #perms do
			exports[resource]:SetTempPermission(src, 'Client', perms[i], enable == true, false)
		end
	end)
end

local function eacTemp(src, enable, modules)
	if type(src) ~= 'number' or src < 1 then return end
	pcall(function()
		for i = 1, #modules do
			if enable then
				exports['ElectronAC']:tempWhitelistPlayer(src, modules[i])
			else
				exports['ElectronAC']:tempUnWhitelistPlayer(src, modules[i])
			end
		end
	end)
end

local DEATH_EAC_MODULES = { 'antiGodmode', 'antiClearTasks', 'antiTeleport', 'antiInvisible' }

local function setDeadState(src, bool, opts)
	if not src or bool == nil then return end
	opts = opts or {}
	Player(src).state:set('dead', bool, true)
	Vars.cacheDeads[src] = bool
	if bool then
		eacTemp(src, true, DEATH_EAC_MODULES)
		fgTemp(src, true, DEATH_FG_PERMS)
	else
		-- Revive uses ClearPedTasks / teleport — keep the exception briefly.
		SetTimeout(8000, function()
			if not GetPlayerName(src) then return end
			if not Vars.cacheDeads[src] then
				eacTemp(src, false, DEATH_EAC_MODULES)
				fgTemp(src, false, DEATH_FG_PERMS)
			end
		end)
	end
	-- Reconnect death restore: delay mute so Mumble can bind first (channel=-1).
	if opts.delayMute and bool then
		SetTimeout(4000, function()
			if not GetPlayerName(src) then return end
			if Vars.cacheDeads[src] then
				setVoiceMute(src, true)
			end
		end)
		return
	end
	setVoiceMute(src, bool)
end

local function dropDeadPocketItems(src)
	if GetResourceState('ox_inventory') ~= 'started' then return 0 end
	src = tonumber(src)
	if not src then return 0 end

	local keep = config.General and config.General.KeepItemsOnDrop or { 'identification', 'phone' }
	local dropped = 0

	-- Prefer live inventory (works for STL + quit via ox_inventory:beforePlayerDropped)
	local ok, dropId = pcall(function()
		return exports.ox_inventory:CreateDropFromPlayer(src, keep)
	end)

	if ok and dropId then
		dropped = 1
	end

	return dropped
end

local function grantSpawnProtection(src)
	local duration = config.General and config.General.SpawnProtection and config.General.SpawnProtection.duration or 60
	duration = math.max(1, tonumber(duration) or 60)
	Player(src).state:set('spawnProtect', true, true)
	eacTemp(src, true, { 'antiGodmode' })
	pcall(function()
		exports['es_extended']:MarkRespawn(src, (duration * 1000) + 2000)
	end)
	TriggerClientEvent('cfx-keydi-ambulance:spawnProtect', src, duration)
	SetTimeout(duration * 1000, function()
		if not GetPlayerName(src) then return end
		Player(src).state:set('spawnProtect', false, true)
		if not Vars.cacheDeads[src] then
			eacTemp(src, false, { 'antiGodmode' })
		end
	end)
end

--- Used by /revive (es_extended) to clear death cache before client revive
local function AdminClearDeath(src)
	src = tonumber(src)
	if not src then return false end
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return false end
	pcall(function()
		exports['es_extended']:MarkRespawn(src, 8000)
	end)
	persistDeadFlag(xPlayer.identifier, false)
	setDeadState(src, false)
	return true
end

exports('AdminClearDeath', AdminClearDeath)

--- Client calls this after NetworkResurrectLocalPlayer so unmute sticks post-respawn.
RegisterNetEvent('cfx-keydi-ambulance:ensureVoiceUnmute', function()
	local src = source
	if Vars.cacheDeads[src] then return end
	setVoiceMute(src, false)
end)

--- Drop pockets while inventory is still loaded (ox removes it on playerDropped).
AddEventHandler('ox_inventory:beforePlayerDropped', function(src)
	src = tonumber(src)
	if not src then return end
	if not Vars.cacheDeads[src] then return end
	if config.General.DropItemsOnQuit == false then return end
	dropDeadPocketItems(src)
end)

AddEventHandler('esx:playerDropped', function(playerId)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local wasDead = Vars.cacheDeads[playerId] == true
		or (Player(playerId).state and Player(playerId).state.dead == true)
	if wasDead then
		-- Crash/disconnect must keep users.dead = 1 so login restores the body.
		if xPlayer and xPlayer.identifier then
			persistDeadFlag(xPlayer.identifier, true)
		end
		if config.General.DropItemsOnQuit ~= false then
			dropDeadPocketItems(playerId)
		end
	end
	Vars.cacheDeads[playerId] = nil
	if Player(playerId).state.spawnProtect then
		Player(playerId).state:set('spawnProtect', false, true)
	end
end)

local function hydrateDeathFromDb(src, xPlayer)
	src = tonumber(src)
	if not src then return false end
	xPlayer = xPlayer or ESX.GetPlayerFromId(src)
	if not xPlayer then return false end
	local ok, value = pcall(function()
		return MySQL.scalar.await('SELECT `dead` FROM `users` WHERE `identifier` = ?', { xPlayer.identifier })
	end)
	local isDead = ok and parseDeadFlag(value)
	Vars.cacheDeads[src] = isDead
	Player(src).state:set('dead', isDead, true)
	return isDead
end

-- On character load: apply death flag first, mute after Mumble has a chance to bind.
-- Muting during the reconnect handshake is a common cause of channel=-1.
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	local src = playerId or (xPlayer and xPlayer.source)
	if not src then return end
	CreateThread(function()
		local xP = ESX.GetPlayerFromId(src) or xPlayer
		if not xP then return end
		hydrateDeathFromDb(src, xP)
		TriggerClientEvent('pma-voice:client:joinHandshake', src)
		Wait(3500)
		if not GetPlayerName(src) then return end
		setVoiceMute(src, Vars.cacheDeads[src] and true or false)
	end)
end)

local function getDeathStatus(src)
	src = tonumber(src)
	if not src then return false end

	if Vars.cacheDeads[src] == true then
		return true
	end

	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then
		return Vars.cacheDeads[src] and true or false
	end

	return hydrateDeathFromDb(src, xPlayer)
end

local function registerDeathStatusCallback()
	ESX.RegisterServerCallback('cfx-keydi-ambulance:checkDeathStatus', function(source, cb)
		cb(getDeathStatus(source))
	end)

	if lib and lib.callback and lib.callback.register then
		lib.callback.register('cfx-keydi-ambulance:checkDeathStatus', function(source)
			return getDeathStatus(source)
		end)
	end
end

registerDeathStatusCallback()

-- Re-register after restarts / late ESX boot so client never hits "does not exist"
AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() or resource == 'es_extended' then
		SetTimeout(250, registerDeathStatusCallback)
	end
	if resource == GetCurrentResourceName() then
		SetTimeout(1000, function()
			for _, playerId in ipairs(GetPlayers()) do
				local src = tonumber(playerId)
				if src then
					hydrateDeathFromDb(src)
				end
			end
		end)
	end
end)

ESX.RegisterServerCallback('cfx-keydi-ambulance:removeItems', function(source, cb)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return cb(false) end
	-- Allow if cached dead OR DB still marked dead (prevents soft-lock on respawn)
	local dbDead = MySQL.scalar.await('SELECT `dead` FROM `users` WHERE `identifier` = ?', { xPlayer.identifier })
	local isDead = Vars.cacheDeads[xPlayer.source] or parseDeadFlag(dbDead)
	if not isDead then return cb(false) end
	local items = Vars.ox:GetInventoryItems(xPlayer.source)
	local itemCount = 0
	if type(items) == 'table' then
		for _ in pairs(items) do itemCount += 1 end
	end
	lib.logger(xPlayer.source, 'cfx-keydi-ambulance-bleedout', ('Name: %s | ID: %s | Coords: %s | Inventory Items: %s'):format(xPlayer.name, xPlayer.source, xPlayer.getCoords(true), json.encode(items)))
	if config.General.DropItemsOnStl ~= false then
		dropDeadPocketItems(src)
	else
		Vars.ox:ClearInventory(xPlayer.source)
	end
	pcall(function()
		exports['es_extended']:SecureSetStatus(xPlayer.source, { hunger = 100, thirst = 100, stress = 0 })
	end)
	TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', xPlayer.source)
	TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', xPlayer.source)
	grantSpawnProtection(src)
	if AmbulanceLogs and AmbulanceLogs.Bleedout then
		AmbulanceLogs.Bleedout({
			src = src,
			name = xPlayer.name,
			identifier = xPlayer.identifier,
			coords = xPlayer.getCoords(true),
			itemCount = itemCount,
		})
	end
	cb(true)
end)


ESX.RegisterServerCallback('cfx-keydi-ambulance:checkIn', function(source, cb, index)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return cb(false) end
	local bankAccount = xPlayer.getAccount('bank')
	local bankAmount = bankAccount and bankAccount.money or 0
	local playerCoords = xPlayer.getCoords(true)
	if not config.CheckIn[index] then return cb(false) end
	local checkInConf = config.CheckIn[index]
	local medicCount = GlobalState[('%s:count'):format(checkInConf.job)] or 0
	if medicCount >= checkInConf.onDuty then
		return cb(false)
	end
	local targetCoords = checkInConf.coords.xyz
	local returnValue = true
	local targetDistance = checkInConf.distance.interact + 10.0
	if #(targetCoords - playerCoords) > targetDistance then
		returnValue = false
	end
	if bankAmount >= checkInConf.price then
		xPlayer.removeAccountMoney('bank', checkInConf.price)
		exports['cfx-keydi-society']:AddMoney(checkInConf.job, checkInConf.price)
		pcall(function()
			exports['es_extended']:MarkRespawn(xPlayer.source, 8000)
		end)
		-- Unmute immediately (don't wait for client revive event)
		setDeadState(xPlayer.source, false)
		TriggerClientEvent('cfx-keydi-ambulance:revive', xPlayer.source)
		TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', xPlayer.source)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', xPlayer.source)
		pcall(function()
			exports['es_extended']:SecureSetStatus(xPlayer.source, { hunger = 100, thirst = 100, stress = 0 })
		end)
		SetTimeout(500, function()
			if GetResourceState('kodebykarl-ui') == 'started' then
				pcall(function()
					exports['kodebykarl-ui']:RestorePlayerBucket(src)
				end)
			end
		end)
		SetTimeout(1000, function()
			local hospital = checkInConf.job
			local beds = menu.bed.locations[hospital]
			if not beds or #beds < 1 then return end
			local bedIndex = exports[GetCurrentResourceName()]:GetFreeBedIndex(hospital)
			if not bedIndex then return end
			pcall(function()
				exports[GetCurrentResourceName()]:OccupyBed(hospital, bedIndex, src, xPlayer.identifier)
			end)
			TriggerClientEvent('cfx-keydi-ambulance:placeTempBed', xPlayer.source, 1, bedIndex, hospital)
			SetTimeout(70 * 1000, function()
				pcall(function()
					exports[GetCurrentResourceName()]:ReleaseBed(hospital, bedIndex)
				end)
			end)
		end)
		if AmbulanceLogs and AmbulanceLogs.CheckIn then
			AmbulanceLogs.CheckIn({
				src = src,
				name = xPlayer.name,
				identifier = xPlayer.identifier,
				price = checkInConf.price,
				society = checkInConf.job,
				index = index,
				coords = playerCoords,
			})
		end
		if GetResourceState('kodebykarl-logs') == 'started' then
			pcall(function()
				exports['kodebykarl-logs']:LogRevive({
					src = src,
					method = 'hospital',
					revivedByName = 'Hospital Check-In',
					coords = playerCoords,
				})
			end)
		end
	end
	cb(returnValue)
end)


RegisterNetEvent('cfx-keydi-ambulance:setPlayerDeathStatus', function(isDead, reason)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return end
	if type(isDead) ~= 'boolean' then return end
	persistDeadFlag(xPlayer.identifier, isDead)
	-- setDeadState also applies pma-voice MutePlayer (mute on death, unmute on revive/STL)
	setDeadState(src, isDead, { delayMute = reason == 'restore' })
end)

local excludedJobs = {
	['police'] = true,
	['sheriff'] = true
}

RegisterNetEvent('cfx-keydi-ambulance:payFine', function(zone)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return end
	if excludedJobs[xPlayer.job.name] then return end
	local fine = config.General.RespawnFine or 1000
	local bankAmount = xPlayer.getAccount('bank').money
	local paid = false
	local society = 'ambulance'
	if zone == true or zone == 'sandy' or zone == 'sambulance' then
		society = 'sambulance'
	elseif zone == 'paleto' or zone == 'pambulance' then
		society = 'pambulance'
	elseif type(zone) == 'string' and zone ~= '' then
		society = zone
	end
	if bankAmount >= fine then
		xPlayer.removeAccountMoney('bank', fine)
		exports['cfx-keydi-society']:AddMoney(society, fine)
		paid = true
	end
	if AmbulanceLogs and AmbulanceLogs.Fine then
		AmbulanceLogs.Fine({
			src = src,
			name = xPlayer.name,
			identifier = xPlayer.identifier,
			amount = fine,
			society = society,
			paid = paid,
		})
	end
end)

local function seedEmsJob(name, label, salaryScale)
	if not ESX.CreateJob then return end
	local grades = {}
	for i = 1, #(config.Grades or {}) do
		local row = config.Grades[i]
		grades[#grades + 1] = {
			grade = row.grade,
			name = row.name,
			label = row.label,
			salary = math.floor((row.salary or 0) * (salaryScale or 1)),
			skin_male = {},
			skin_female = {},
		}
	end
	pcall(function()
		ESX.CreateJob({
			name = name,
			label = label,
			grades = grades,
			offduty = false,
		})
	end)
end

AddEventHandler('onResourceStart', function(res)
	if res ~= GetCurrentResourceName() then return end
	local jobs = config.Jobs or {}
	for _, job in pairs(jobs) do
		if job.name and job.label then
			seedEmsJob(job.name, job.label, 1)
			if job.offDuty then
				seedEmsJob(job.offDuty, ('Off-Duty %s'):format(job.label), 0)
			end
		end
	end
end)

exports('GetJobName', function(stationId)
	local stations = config.Stations or {}
	local station = stationId and stations[stationId]
	if station and station.job then return station.job end
	return 'ambulance'
end)

exports('GetOffDutyJobName', function(stationId)
	local jobs = config.Jobs or {}
	if stationId == 'paleto' or stationId == 'pambulance' then
		return jobs.pambulance and jobs.pambulance.offDuty or 'offpambulance'
	end
	if stationId == 'sandy' or stationId == 'sambulance' then
		return jobs.sambulance and jobs.sambulance.offDuty or 'offsambulance'
	end
	return jobs.ambulance and jobs.ambulance.offDuty or 'offambulance'
end)

local function isEmsJob(jobName)
	local jobs = config.General.Dispatch911 and config.General.Dispatch911.jobs or { 'ambulance', 'sambulance', 'pambulance' }
	for i = 1, #jobs do
		if jobs[i] == jobName then return true end
	end
	return false
end

RegisterNetEvent('kodebykarl-ambulance:server:deathFreecam', function(enabled)
	local src = source
	if not Vars.cacheDeads[src] then return end
	fgTemp(src, enabled == true, { 'BypassFreecam' })
end)

RegisterNetEvent('cfx-keydi-ambulance:request911', function()
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return end
	if not Vars.cacheDeads[src] then return end

	local coords = xPlayer.getCoords(true)
	local payload = {
		callerId = src,
		callerName = xPlayer.getName(),
		coords = { x = coords.x, y = coords.y, z = coords.z },
	}

	for _, xTarget in pairs(ESX.GetExtendedPlayers()) do
		if isEmsJob(xTarget.job.name) then
			TriggerClientEvent('cfx-keydi-ambulance:911Dispatch', xTarget.source, payload)
		end
	end

	TriggerClientEvent('esx:Notify', src, '911', 'Emergency services have been notified. You are marked on EMS GPS.', 'success', 7000)
	lib.logger(src, 'cfx-keydi-ambulance-911', ('911 from %s [%s] at %s'):format(xPlayer.name, src, xPlayer.getCoords(true)))
end)

-- /911 while alive (optional manual call)
RegisterCommand('911', function(source, args)
	local src = source
	if src == 0 then return end

	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return end

	local message = table.concat(args, ' ')
	if message == '' then
		message = 'Emergency assistance needed at my location.'
	end

	local coords = xPlayer.getCoords(true)
	local payload = {
		callerId = src,
		callerName = xPlayer.getName(),
		coords = { x = coords.x, y = coords.y, z = coords.z },
		message = message,
	}

	for _, xTarget in pairs(ESX.GetExtendedPlayers()) do
		if isEmsJob(xTarget.job.name) then
			TriggerClientEvent('cfx-keydi-ambulance:911Dispatch', xTarget.source, payload)
			TriggerClientEvent('esx:Notify', xTarget.source, '911 DISPATCH', ('%s [%s]: %s'):format(xPlayer.getName(), src, message), 'error', 10000)
		end
	end

	TriggerClientEvent('esx:Notify', src, '911', 'Your emergency call has been sent to EMS.', 'success', 5000)
end, false)

AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
	if GetInvokingResource() ~= "monitor" or type(eventData) ~= "table" or type(eventData.id) ~= "number" then return end
	pcall(function()
		exports['es_extended']:MarkRespawn(eventData.id, 8000)
	end)
	if Vars.cacheDeads[eventData.id] then
		TriggerClientEvent('cfx-keydi-ambulance:revive', eventData.id)
		TriggerClientEvent('cfx-keydi-ambulance:client:ResetLimbs', eventData.id)
		TriggerClientEvent('cfx-keydi-ambulance:client:RemoveBleed', eventData.id)
		pcall(function()
			exports['es_extended']:SecureSetStatus(eventData.id, { hunger = 100, thirst = 100, stress = 0 })
		end)
		setDeadState(eventData.id, false)
	end
end)

AddEventHandler('onServerResourceStart', function(resourceName)
	if resourceName == 'es_extended' then
		ESX = exports['es_extended']:getSharedObject()
	end
end)

--- Spawn protect is two-way: attacker and victim both blocked.
AddEventHandler('weaponDamageEvent', function(sender, data)
	if Player(sender).state.spawnProtect then
		CancelEvent()
		return
	end

	local hitId = data and data.hitGlobalId
	if not hitId then return end

	local entity = NetworkGetEntityFromNetworkId(hitId)
	if not entity or entity == 0 then
		entity = hitId
	end
	if not entity or entity == 0 or not DoesEntityExist(entity) then return end
	if not IsPedAPlayer(entity) then return end

	for _, playerId in ipairs(GetPlayers()) do
		local id = tonumber(playerId)
		if id and GetPlayerPed(id) == entity and Player(id).state.spawnProtect then
			CancelEvent()
			return
		end
	end
end)