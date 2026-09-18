local radioChannel = 0
local radioNames = {}
local disableRadioAnim = false

--- event syncRadioData
--- syncs the current players on the radio to the client
---@param radioTable table the table of the current players on the radio
---@param localPlyRadioName string the local players name
function syncRadioData(radioTable, localPlyRadioName)
	radioData = radioTable
	logger.info('[radio] Syncing radio table.')
	if GetConvarInt('voice_debugMode', 0) >= 4 then
		print('-------- RADIO TABLE --------')
		tPrint(radioData)
		print('-----------------------------')
	end
	for tgt, enabled in pairs(radioTable) do
		if tgt ~= playerServerId then
			toggleVoice(tgt, enabled, 'radio')
		end
	end
	sendUIMessage({
		radioChannel = radioChannel,
		radioEnabled = radioEnabled
	})
	if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
		radioNames[playerServerId] = localPlyRadioName
	end
end
RegisterNetEvent('pma-voice:syncRadioData', syncRadioData)

--- event setTalkingOnRadio
--- sets the players talking status, triggered when a player starts/stops talking.
---@param plySource number the players server id.
---@param enabled boolean whether the player is talking or not.
function setTalkingOnRadio(plySource, enabled)
	toggleVoice(plySource, enabled, 'radio')
	radioData[plySource] = enabled
	playMicClicks(enabled)
end
RegisterNetEvent('pma-voice:setTalkingOnRadio', setTalkingOnRadio)

--- event addPlayerToRadio
--- adds a player onto the radio.
---@param plySource number the players server id to add to the radio.
function addPlayerToRadio(plySource, plyRadioName)
	radioData[plySource] = false
	if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
		radioNames[plySource] = plyRadioName
	end
	if radioPressed then
		logger.info('[radio] %s joined radio %s while we were talking, adding them to targets', plySource, radioChannel)
		playerTargets(radioData, MumbleIsPlayerTalking(PlayerId()) and callData or {})
	else
		logger.info('[radio] %s joined radio %s', plySource, radioChannel)
	end
end
RegisterNetEvent('pma-voice:addPlayerToRadio', addPlayerToRadio)

--- event removePlayerFromRadio
--- removes the player (or self) from the radio
---@param plySource number the players server id to remove from the radio.
function removePlayerFromRadio(plySource)
	if plySource == playerServerId then
		logger.info('[radio] Left radio %s, cleaning up.', radioChannel)
		for tgt, _ in pairs(radioData) do
			if tgt ~= playerServerId then
				toggleVoice(tgt, false, 'radio')
			end
		end
		sendUIMessage({
			radioChannel = 0,
			radioEnabled = radioEnabled
		})
		radioNames = {}
		radioData = {}
		playerTargets(MumbleIsPlayerTalking(PlayerId()) and callData or {})
	else
		toggleVoice(plySource, false)
		if radioPressed then
			logger.info('[radio] %s left radio %s while we were talking, updating targets.', plySource, radioChannel)
			playerTargets(radioData, MumbleIsPlayerTalking(PlayerId()) and callData or {})
		else
			logger.info('[radio] %s has left radio %s', plySource, radioChannel)
		end
		radioData[plySource] = nil
		if GetConvarInt("voice_syncPlayerNames", 0) == 1 then
			radioNames[plySource] = nil
		end
	end
end
RegisterNetEvent('pma-voice:removePlayerFromRadio', removePlayerFromRadio)

--- function setRadioChannel
--- sets the local players current radio channel and updates the server
---@param channel number the channel to set the player to, or 0 to remove them.
function setRadioChannel(channel)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	channel = tonumber(channel) or 0
	type_check({channel, "number"})
	TriggerServerEvent('pma-voice:setPlayerRadio', channel)
	radioChannel = channel
end

--- exports setRadioChannel
--- sets the local players current radio channel and updates the server
---@param channel number the channel to set the player to, or 0 to remove them.
exports('setRadioChannel', setRadioChannel)
-- mumble-voip compatability
exports('SetRadioChannel', setRadioChannel)

--- exports removePlayerFromRadio
--- sets the local players current radio channel and updates the server
exports('removePlayerFromRadio', function()
	setRadioChannel(0)
end)

--- exports addPlayerToRadio
--- sets the local players current radio channel and updates the server
---@param _radio number the channel to set the player to, or 0 to remove them.
exports('addPlayerToRadio', function(_radio)
	local radio = tonumber(_radio)
	if radio then
		setRadioChannel(radio)
	end
end)

--- exports toggleRadioAnim
--- toggles whether the client should play radio anim or not, if the animation should be played or notvaliddance
exports('toggleRadioAnim', function()
	disableRadioAnim = not disableRadioAnim
	TriggerEvent('pma-voice:toggleRadioAnim', disableRadioAnim)
end)

-- exports disableRadioAnim
--- returns whether the client is undercover or not
exports('getRadioAnimState', function()
	return toggleRadioAnim
end)

--- check if the player is dead
--- seperating this so if people use different methods they can customize
--- it to their need as this will likely never be changed
--- but you can integrate the below state bag to your death resources.
--- LocalPlayer.state:set('isDead', true or false, false)
function isDead()
	if LocalPlayer.state.isDead or Player(GetPlayerServerId(PlayerId())).state.dead then
		return true
	elseif IsPlayerDead(PlayerId()) then
		return true
	end
end

local AdvancedRadioAnim = true -- Enable/Disable Advanced Radio Anim

if AdvancedRadioAnim then
	local CurrentProps = {}

	function AddPropsToPlayerPed(prop, bone, placement, id, disableCollision)
		local playerPos = GetEntityCoords(PlayerPedId())
		RequestModel(joaat(prop))
		while not HasModelLoaded(joaat(prop)) do
			Wait(0)
		end
	
		local object = CreateObject(joaat(prop), playerPos.x, playerPos.y, playerPos.z + 0.2, true, true, true)
		if disableCollision then
			SetEntityCollision(object, false, false)
		end
		AttachEntityToEntity(object, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), bone), placement[1].x, placement[1].y, placement[1].z, placement[2].x, placement[2].y, placement[2].z, true, true, false, true, 1, true)
		SetModelAsNoLongerNeeded(prop)
		CurrentProps[id] = object
		return object
	end
	
	function CreatePedProps(prop, bone, placement, id, col)
		local object = AddPropsToPlayerPed(prop, bone, placement, id, col)
		TriggerServerEvent('scully_emotemenu:syncProp', ObjToNet(object))
	end
	
	function RemovePedProps(id)
		if CurrentProps[id] then
			DeleteEntity(CurrentProps[id])
			CurrentProps[id] = nil
		end
	end
	
	function AttachRadioProps()
		local placement = {
			vector3(0.140000, 0.030000, 0.030000),
			vector3(-105.877000, -10.943200, -33.721200),
		}
		RemovePedProps('radio')
		CreatePedProps('prop_cs_hand_radio', 18905, placement, 'radio', true)
	end
end

RegisterCommand('+radiotalk', function()
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	if isDead() then return end

	if not radioPressed and radioEnabled then
		if radioChannel > 0 then
			logger.info('[radio] Start broadcasting, update targets and notify server.')
			playerTargets(radioData, MumbleIsPlayerTalking(PlayerId()) and callData or {})
			TriggerServerEvent('pma-voice:setTalkingOnRadio', true)
			radioPressed = true
			playMicClicks(true)
			if GetConvarInt('voice_enableRadioAnim', 0) == 1 and not (GetConvarInt('voice_disableVehicleRadioAnim', 0) == 1 and IsPedInAnyVehicle(PlayerPedId(), false)) then
				if not disableRadioAnim then
					if not AdvancedRadioAnim then
						RequestAnimDict('random@arrests')
						while not HasAnimDictLoaded('random@arrests') do
							Citizen.Wait(10)
						end
						TaskPlayAnim(PlayerPedId(), "random@arrests", "generic_radio_enter", 8.0, 2.0, -1, 50, 2.0, 0, 0, 0)
					else
						local currentCam = GetCamActiveViewModeContext()
						local pIsInVehicle = currentCam == 1 or currentCam == 2
						CreateThread(function()
							local playerPed = PlayerPedId()
							local lib = "ultra@walkie_talkie"
							local anim = "walkie_talkie"
							AttachRadioProps()
							RequestAnimDict(lib)
							while not HasAnimDictLoaded(lib) do
								Wait(10)
							end
							local isInVehicleAndFirstPersonDriver = pIsInVehicle and GetCamViewModeForContext(currentCam) == 4 and GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()
							-- Don't play radio anim if driving in first person
							while radioPressed do
								if not isInVehicleAndFirstPersonDriver and not IsEntityPlayingAnim(playerPed, lib, anim, 3) then
									TaskPlayAnim(playerPed, lib, anim, 8.0, 0.0, -1, 49, 0, false, false, false)
								end
								SetControlNormal(0, 249, 1.0)
								Wait(0)
							end
						end)
					end
				end
			end
			Citizen.CreateThread(function()
				TriggerEvent("pma-voice:radioActive", true)
				while radioPressed do
					Wait(0)
					SetControlNormal(0, 249, 1.0)
					SetControlNormal(1, 249, 1.0)
					SetControlNormal(2, 249, 1.0)
				end
			end)
		end
	end
end, false)

RegisterCommand('-radiotalk', function()
	if radioChannel > 0 or radioEnabled and radioPressed then
		radioPressed = false
		MumbleClearVoiceTargetPlayers(voiceTarget)
		playerTargets(MumbleIsPlayerTalking(PlayerId()) and callData or {})
		TriggerEvent("pma-voice:radioActive", false)
		playMicClicks(false)
		if GetConvarInt('voice_enableRadioAnim', 0) == 1 then
			if not AdvancedRadioAnim then
				StopAnimTask(PlayerPedId(), "random@arrests", "generic_radio_enter", -4.0)
			else
				local lib = "ultra@walkie_talkie"
				local anim = "walkie_talkie"
				StopAnimTask(PlayerPedId(), lib, anim, 3.0)
				RemovePedProps('radio')
			end
		end
		TriggerServerEvent('pma-voice:setTalkingOnRadio', false)
	end
end, false)
if gameVersion == 'fivem' then
	RegisterKeyMapping('+radiotalk', '~g~>~w~ Talk over Radio', 'keyboard', GetConvar('voice_defaultRadio', 'LMENU'))
end

--- event syncRadio
--- syncs the players radio, only happens if the radio was set server side.
---@param _radioChannel number the radio channel to set the player to.
function syncRadio(_radioChannel)
	if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
	logger.info('[radio] radio set serverside update to radio %s', radioChannel)
	radioChannel = _radioChannel
end
RegisterNetEvent('pma-voice:clSetPlayerRadio', syncRadio)
