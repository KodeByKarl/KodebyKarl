Vars = {}
Vars.ox = exports.ox_inventory
Vars.bleedingData = {
	[0] = 'NONE',
	[1] = 'SLOW',
	[2] = 'MEDIUM',
	[5] = 'FAST',
}

local function loadOxItems()
	local ok, items = pcall(function()
		return exports.ox_inventory:Items()
	end)
	if ok and type(items) == 'table' then
		Vars.oxItems = items
		return true
	end
	return false
end

if not loadOxItems() then
	Vars.oxItems = {}
	CreateThread(function()
		local attempts = 100
		while attempts > 0 and not loadOxItems() do
			attempts -= 1
			Wait(100)
		end
		if not next(Vars.oxItems) then
			warn('[cfx-keydi-ambulance] ox_inventory Items export unavailable')
		end
	end)
end

if IsDuplicityVersion() then
	Vars.cacheDeads = {}
else
	Vars.isBed = false
	Vars.isBusy = false
	Vars.isDead = false
	Vars.isReviving = false
	Vars.deathToken = 0
	Vars.lastHitBone = nil
	Vars.lastHitBoneAt = 0
	Vars.inSandy = false
	Vars.deathInSandy = false
	Vars.deathCoords = nil
	Vars.diedInRedZone = false
	Vars.stlUnlocked = false
	-- North of this Y = Sandy / Paleto / Grapeseed (Blaine). City is south.
	Vars.BlaineMinY = 1425.0
	-- North of this Y = Paleto / Chiliad. Sandy + Grapeseed stay on Sandy Hospital.
	Vars.PaletoMinY = 5000.0

	function Vars.IsBlaineCoords(coords)
		if not coords then return false end
		local y = coords.y or coords[2]
		return type(y) == 'number' and y >= Vars.BlaineMinY
	end

	function Vars.IsPaletoCoords(coords)
		if not coords then return false end
		local y = coords.y or coords[2]
		return type(y) == 'number' and y >= Vars.PaletoMinY
	end

	function Vars.CheckInRedZone(coords)
		if GetResourceState('kodebykarl-traphouse') == 'started' then
			local ok, inZone = pcall(function()
				return exports['kodebykarl-traphouse']:InRedZoneField()
			end)
			if ok and inZone == true then return true end
		end
		local activeTrap = GlobalState.traphouse_active_zone
		if activeTrap and activeTrap.coords and coords then
			local zCoords = vector3(tonumber(activeTrap.coords.x) or 0.0, tonumber(activeTrap.coords.y) or 0.0, tonumber(activeTrap.coords.z) or 0.0)
			local radius = (tonumber(activeTrap.radius) or 200.0) + 0.0
			if #(coords - zCoords) <= radius then
				return true
			end
		end
		if LocalPlayer.state.inRedZone then
			return true
		end
		return false
	end

	function Vars.CaptureDeathZone(ped)
		ped = ped or (cache and cache.ped) or PlayerPedId()
		local coords = (ped and ped ~= 0) and GetEntityCoords(ped) or vector3(0.0, 0.0, 0.0)
		Vars.deathCoords = coords
		Vars.deathInSandy = Vars.IsBlaineCoords(coords) or Vars.inSandy == true
		Vars.diedInRedZone = Vars.CheckInRedZone(coords)
		return Vars.deathInSandy, coords
	end

	function Vars.DiedInBlaine()
		if Vars.deathInSandy == true then return true end
		if Vars.deathCoords and Vars.IsBlaineCoords(Vars.deathCoords) then return true end
		if Vars.inSandy == true then return true end
		local ped = (cache and cache.ped) or PlayerPedId()
		if ped and ped ~= 0 then
			return Vars.IsBlaineCoords(GetEntityCoords(ped))
		end
		return false
	end

	function Vars.DiedInPaleto()
		if Vars.deathCoords then
			return Vars.IsPaletoCoords(Vars.deathCoords)
		end
		local ped = (cache and cache.ped) or PlayerPedId()
		if ped and ped ~= 0 then
			return Vars.IsPaletoCoords(GetEntityCoords(ped))
		end
		return false
	end

	-- STL hospital for this death: city / Sandy / Paleto.
	-- City default is Integrity Way; death UI still lists Carson Ave + hospitals.
	function Vars.SelectStlZone()
		if Vars.DiedInPaleto() then
			return 'paleto_hospital'
		end
		if Vars.DiedInBlaine() then
			return 'sandy_hospital'
		end
		return 'integrity_way'
	end

	Vars.IsDispatched = false
	Vars.Status = {
		health = 0,
		multiplier = 2.0,
		pulse = 70,
		area = 'NONE',
		blood = 100,
		bleeding = 0,
		timer = 0,
		currentPulse = -1,
		currentBlood = -1,
		currentArea = '',
		currentBleeding = 'NONE',
		name = '',
		bone = {
			[24817] = true,
			[24818] = true,
			[10706] = true,
			[24816] = true,
			[11816] = true
		}
	}
	Vars.ReviveAnim = {
		cpr_a_1 = 'mini@cpr@char_a@cpr_def',
		cpr_a_2 = 'mini@cpr@char_a@cpr_str',
		cpr_b_1 = 'mini@cpr@char_b@cpr_def',
		cpr_b_2 = 'mini@cpr@char_b@cpr_str',
		start = 'cpr_intro',
		pump = 'cpr_pumpchest',
		success = 'cpr_success'
	}
end

return Vars
