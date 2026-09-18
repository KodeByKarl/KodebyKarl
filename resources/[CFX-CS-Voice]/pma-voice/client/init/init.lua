
AddEventHandler('onClientResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end
	print('Starting script initialization')

	-- Some people modify pma-voice and mess up the resource Kvp, which means that if someone
	-- joins another server that has pma-voice, it will error out, this will catch and fix the kvp.
	local success = pcall(function()
		local micClicksKvp = GetResourceKvpString('pma-voice_enableMicClicks')
		if not micClicksKvp then
			SetResourceKvp('pma-voice_enableMicClicks', tostring(true))
		else
			if micClicksKvp ~= 'true' and micClicksKvp ~= 'false' then
				error('Invalid Kvp, throwing error for automatic cleaning')
			end
			micClicks = micClicksKvp
		end
	end)

	if not success then
		logger.warn('Failed to load resource Kvp, likely was inappropriately modified by another server, resetting the Kvp.')
		SetResourceKvp('pma-voice_enableMicClicks', tostring(true))
		micClicks = 'true'
	end
	sendUIMessage({
		uiEnabled = GetConvarInt("voice_enableUi", 1) == 1,
		voiceModes = json.encode(Cfg.voiceModes),
		voiceMode = mode - 1
	})

	-- Reinitialize channels if they're set.
	local radio = tonumber(LocalPlayer.state.radioChannel) or 0
	if radio > 0 then
		setRadioChannel(radio)
	end

	local call = tonumber(LocalPlayer.state.callChannel) or 0
	if call > 0 then
		setCallChannel(call)
	end
	print('Script initialization finished.')
end)
