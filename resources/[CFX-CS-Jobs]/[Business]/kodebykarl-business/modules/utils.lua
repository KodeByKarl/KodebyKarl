function playAnim(data)
    if data.dict then
        lib.requestAnimDict(data.dict)
        TaskPlayAnim(cache.ped, data.dict, data.clip, data.blendIn or 3.0, data.blendOut or 1.0, data.duration or -1, data.flag or 49, data.playbackRate or 0, data.lockX, data.lockY, data.lockZ)
    elseif data.scenario then
        TaskStartScenarioInPlace(cache.ped, data.scenario, 0, data.playEnter ~= nil and data.playEnter or true)
    end
end

function CraftBusinessItem(recipeId)
    local ok, msg = lib.callback.await('cfx-hu-business:craft', false, recipeId)
    if ok then
        lib.notify({ title = 'BUSINESS', description = msg or 'Success.', type = 'success', duration = 5000, position = 'center-left' })
    else
        lib.notify({ title = 'BUSINESS', description = msg or 'Failed.', type = 'error', duration = 5000, position = 'center-left' })
    end
    return ok
end

CreateThread(function()
	for theJob, theBlipData in pairs(Config.Business) do
		if theBlipData.BlipData and theBlipData.BlipData.pos then
			local colour = theBlipData.BlipData.colour or 0
			local blip = AddBlipForCoord(theBlipData.BlipData.pos)
			SetBlipSprite(blip, theBlipData.BlipData.sprite)
			SetBlipScale(blip, theBlipData.BlipData.scale)
			SetBlipColour(blip, colour)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName(theBlipData.BlipData.label)
			EndTextCommandSetBlipName(blip)
		end
	end
end)