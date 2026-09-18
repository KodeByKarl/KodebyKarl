function ESX.HasGroup(filter)
    local PlayerData = ESX.GetPlayerData()
	while not next(PlayerData) do PlayerData = ESX.GetPlayerData() Wait(100) end
    local groups = { 'job', 'gang' }
    local filterType = type(filter)
    local function getPlayerGrade(group, data)
        if not data or not data.name or not data.grade then return nil end
        return group == 'job' and data.grade or data.grade.level
    end

    if filterType == 'string' then
        for _, group in ipairs(groups) do
            local data = PlayerData[group]
            local grade = getPlayerGrade(group, data)
            if data and data.name == filter then
                return data.name, grade
            end
        end
    elseif filterType == 'table' then
        local tableType = table.type(filter)

        if tableType == 'hash' then
            for _, group in ipairs(groups) do
                local data = PlayerData[group]
                local grade = getPlayerGrade(group, data)
                local requiredGrade = filter[data and data.name or nil]
                if grade and requiredGrade and grade >= requiredGrade then
                    return data.name, grade
                end
            end
        elseif tableType == 'array' then
            for _, name in ipairs(filter) do
                for _, group in ipairs(groups) do
                    local data = PlayerData[group]
                    local grade = getPlayerGrade(group, data)
                    if data and data.name == name then
                        return data.name, grade
                    end
                end
            end
        end
    end
end


-- ESX.DrawText3D(x, y, z, text)
ESX.DrawText3D = function(x, y, z, text)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)

    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end


-- exports['es_extended']:ApplyLocalSkin(skin)
function ApplyLocalSkin(skin)
    for k,v in pairs(skin) do
        TriggerEvent('ESX:Skin:ApplyLocalSkin', k, v.drawable, v.texture)
    end
end

exports('ApplyLocalSkin', ApplyLocalSkin)

AddEventHandler('ESX:Skin:ApplyLocalSkin', function(Type, Drawable, Texture)
    local playerPed = cache.ped
    local theType = string.lower(Type)
    if (theType == 'hat') then 
        exports['illenium-appearance']:setPedProp(playerPed, { prop_id = 0, drawable = Drawable, texture = Texture })
    elseif (theType == 'glasses') then 
        exports['illenium-appearance']:setPedProp(playerPed, { prop_id = 1, drawable = Drawable, texture = Texture })
    elseif (theType == 'mask') then 
        exports['illenium-appearance']:setPedComponent(playerPed, { component_id = 1, drawable = Drawable, texture = Texture })
    elseif (theType == 'accessories') then 
        exports['illenium-appearance']:setPedComponent(playerPed, { component_id = 7, drawable = Drawable, texture = Texture })
    elseif (theType == 'torso') then 
        exports['illenium-appearance']:setPedComponent(playerPed, { component_id = 11, drawable = Drawable, texture = Texture })
    elseif (theType == 'tshirt') then 
        exports['illenium-appearance']:setPedComponent(playerPed, { component_id = 8, drawable = Drawable, texture = Texture })
    elseif (theType == 'leg') then 
        exports['illenium-appearance']:setPedComponent(playerPed, { component_id = 4, drawable = Drawable, texture = Texture })
    elseif (theType == 'shoes') then 
        exports['illenium-appearance']:setPedComponent(playerPed, { component_id = 6, drawable = Drawable, texture = Texture })
    elseif (theType == 'armour') then
        exports['illenium-appearance']:setPedComponent(playerPed, { component_id = 9, drawable = Drawable, texture = Texture })
	elseif (theType == 'arm') then
        exports['illenium-appearance']:setPedComponent(playerPed, { component_id = 3, drawable = Drawable, texture = Texture })
	end
end)

function ESX.PlayAnim(animDict, animName, upperbodyOnly, duration)
    local flags = upperbodyOnly and 16 or 0
    local runTime = duration or -1
    lib.requestAnimDict(animDict, 10000)
    TaskPlayAnim(ESX.PlayerData.ped, animDict, animName, 8.0, 1.0, runTime, flags, 0.0, false, false, true)
    RemoveAnimDict(animDict)
end

-- exports['es_extended']:PersistentAlert(action, persistent_id, 'error/success/info/warning', message, title)
-- exports['es_extended']:PersistentAlert('end', persistent_id)
-- ESX.PersistentAlert(action, persistent_id, 'error/success/info/warning', message, title)
-- ESX.PersistentAlert('end', persistent_id)
function ESX.PersistentAlert(action, id, type, text, title)
	if action:upper() == 'START' then
		SendNUIMessage({
            action  = 'persist',
            persist = action,
            id      = id,
            type    = type,
            text    = string.format(
                '<span class="notif-badge %s">%s</span>%s',
                type,
                title,
                text
            )
        })
	elseif action:upper() == 'END' then
		SendNUIMessage({
			action = 'persist',
			persist = action,
			id = id
		})
	end
end

exports('PersistentAlert', ESX.PersistentAlert)

-- ESX.Limit('start', {ms = 5000, name = 'cardealer_brochure'})
-- ESX.Limit('limit', {name = 'cardealer_brochure', seconds = 5})
local Limited = {}
ESX.Limit = function(method, data)
	local name = data.name
	local ms = data.ms
	local sec = data.seconds
	local theHakdog = 'second' 
	if sec and sec > 1 then theHakdog = 'seconds' end
	if method == 'limit' then
		if not Limited[name] or Limited[name] and GetGameTimer() - Limited[name].time > Limited[name].ms then 
			return false
		end
        ESX.Notify('RATE LIMIT', 'You must wait '..(sec - ESX.Math.Round((GetGameTimer() - Limited[name].time) / 1000))..' '..theHakdog, 'error', 5000)
		return true
	elseif method == 'start' then
		if not Limited[name] then
			Limited[name] = {ms = ms, time = 0}
		else
			Limited[name] = {ms = ms, time = GetGameTimer()}
		end
		return true
	end
end

exports('Limit', ESX.Limit)

function ESX.Notify(title, message, style, duration, position)
	local pos = position or 'center-right'
	local baseStyle = {
		backgroundColor = '#0f0f0f',
		color = '#f5f5f5',
		borderRadius = '10px',
		padding = '16px 20px',
		fontSize = '15px',
		fontWeight = '500',
		fontFamily = 'Segoe UI, sans-serif',
		boxShadow = '0 8px 20px rgba(0, 0, 0, 0.6)',
		borderLeft = '5px solid',
		display = 'flex',
		alignItems = 'center',
		gap = '12px',
		['.description'] = {
			color = '#cccccc',
			marginTop = '4px',
			fontSize = '13px'
		}
	}
	local styleMap = {
		info = {
			icon = 'circle-info',
			iconColor = '#3498db',
			iconAnimation = "beat",
			borderColor = '#3498db'
		},
		warning = {
			icon = 'triangle-exclamation',
			iconColor = '#f39c12',
			iconAnimation = "beat",
			borderColor = '#f39c12'
		},
		success = {
			icon = 'circle-check',
			iconColor = '#2ecc71',
			iconAnimation = "beat",
			borderColor = '#2ecc71'
		},
		error = {
			icon = 'circle-xmark',
			iconColor = '#e74c3c',
			iconAnimation = "beat",
			borderColor = '#e74c3c'
		}
	}
	local current = styleMap[style]
	if current then
		local styled = table.clone(baseStyle)
		styled.borderLeft = '5px solid ' .. current.borderColor
		lib.notify({
			title = title,
			description = message,
			position = pos,
			style = styled,
			icon = current.icon,
			iconColor = current.iconColor,
			iconAnimation = current.iconAnimation,
			duration = duration or 5000
		})
	end
end

-- TriggerClientEvent('esx:Notify', src, title, message, style, duration)
RegisterNetEvent('esx:Notify', ESX.Notify)

-- exports['es_extended']:Notify(title, message, style, duration)
exports('Notify', ESX.Notify)

local id = 0
local MugshotsCache = {}
local Answers = {}

function ESX.GetMugShotBase64(Ped, Tasparent)
	if not Ped then return "" end
	id = id + 1 
	local Handle = RegisterPedheadshot(Ped)
	local timer = 2000
	while ((not Handle or not IsPedheadshotReady(Handle) or not IsPedheadshotValid(Handle)) and timer > 0) do
		Wait(10)
		timer = timer - 10
	end
	local MugShotTxd = 'none'
	if (IsPedheadshotReady(Handle) and IsPedheadshotValid(Handle)) then
		MugshotsCache[id] = Handle
		MugShotTxd = GetPedheadshotTxdString(Handle)
	end
	SendNUIMessage({
		action = 'convert',
		pMugShotTxd = MugShotTxd,
		removeImageBackGround = Tasparent or false,
		id = id,
	})
	local p = promise.new()
	Answers[id] = p
	return Citizen.Await(p)
end

exports("GetMugShotBase64", ESX.GetMugShotBase64)

lib.callback.register('esx:GetMugShotBase64', function()
	return ESX.GetMugShotBase64(cache.ped, false)
end)

RegisterNUICallback('Answer', function(data)
	if MugshotsCache[data.Id] then
		UnregisterPedheadshot(MugshotsCache[data.Id])
		MugshotsCache[data.Id] = nil
	end
	Answers[data.Id]:resolve(data.Answer)
	Answers[data.Id] = nil
end)

function ESX.DrawMarker(pos, r, g, b, opacity)
	DrawMarker(2, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, r, g, b, opacity, false, false, false, true, false, false, false)
end

-- Usage: TriggerClientEvent('esx:ShowBreakingNews', -1, title, message, bottom, 5)
RegisterNetEvent('esx:ShowBreakingNews', function(title, message, bottom, duration)
	ESX.Scaleform.ShowBreakingNews(title, message, bottom, duration)
end)