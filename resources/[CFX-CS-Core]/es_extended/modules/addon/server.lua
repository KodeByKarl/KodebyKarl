function ESX.HasGroup(playerId, filter)
	if not ESX.Players[playerId] then return false, false end
	local xPlayer = ESX.Players[playerId]
    if not xPlayer.job or not xPlayer.gang then return false, false end
    local groups = { 'job', 'gang' }
    local type = type(filter)
    if type == 'string' then
        for i = 1, #groups do
            local data = xPlayer[groups[i]]
			local playerGrade = groups[i] == 'job' and data.grade or data.grade.level
            if data.name == filter then
                return data.name, playerGrade
            end
        end
    else
        local tabletype = table.type(filter)
        if tabletype == 'hash' then
            for i = 1, #groups do
                local data = xPlayer[groups[i]]
                local grade = filter[data.name]
				local playerGrade = groups[i] == 'job' and data.grade or data.grade.level
                if grade and grade <= playerGrade then
                    return data.name, playerGrade
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local group = filter[i]
                for j = 1, #groups do
                    local data = xPlayer[groups[j]]
					local playerGrade = groups[j] == 'job' and data.grade or data.grade.level
                    if data.name == group then
                        return data.name, playerGrade
                    end
                end
            end
        end
    end
end

ESX.CreateLog = function(label, message, webhook)
	local theEmbed = {{
        ['title'] = label,
        ['color'] = 255,
        ['footer'] = {
            ['text'] = "CFX-CS-V2 | " .. os.date(),
            ['icon_url'] = "" 
        },
        ['description'] = message,
        ['author'] = {
            ['name'] = "CFX-CS-V2",
            ['icon_url'] = ""
        }
    }}
    PerformHttpRequest(webhook, function(err, text, headers) 
        if err ~= 204 then if err == 429 then else end end
    end, 'POST', json.encode({username = 'CFX-CS-V2', embeds = theEmbed, avatar_url = ''}), { ['Content-Type'] = 'application/json' })
end

CreateThread(function()
    GlobalState.ServerUptime = ('%sh %sm'):format(0, 0)
    local startTime = os.time()
	while true do
        Wait(1000 * 60)
        local currentTime = os.time()
        local uptimeSeconds = currentTime - startTime
        local hours = uptimeSeconds // 3600
        local minutes = (uptimeSeconds % 3600) // 60
        GlobalState.ServerUptime = ('%sh %sm'):format(hours, minutes)
        SetConvar('Server Uptime', ('%sh %sm'):format(hours, minutes))
	end
end)

function ESX.VerifyDistance(playerId, targetId, distance, event)
    if not ESX.Players[targetId] then return false end
    if not ESX.Players[playerId] then return false end
    if playerId == targetId then return true end
    local xPlayer = GetPlayerPed(playerId)
    local xTarget = GetPlayerPed(targetId)
    local xPlayerCoords = GetEntityCoords(xPlayer)
    local xTargetCoords = GetEntityCoords(xTarget)
    if #(xPlayerCoords - xTargetCoords) > distance then
        return false
    end
    return true
end

function ESX.isOptin(playerId, filter)
	local xPlayer = ESX.Players[playerId]
	if not xPlayer then return false end
	if type(filter) == 'string' then
		if xPlayer.getGroup() == filter then
			return true
		end
	else
        local tabletype = table.type(filter)
        if tabletype == 'hash' then
            if filter[xPlayer.getGroup()] then
                return true
            end
        elseif tabletype == 'array' then
            for k,v in ipairs(filter) do
                if xPlayer.getGroup() == v then
                    return true
                end
            end
        end
	end
    return false
end

function GetCacheStaff()
    return Core.CacheStaff
end

exports('GetCacheStaff', GetCacheStaff)


function ESX.SendSMS(message, title, subject)
	for k,v in pairs(ESX.Players) do
		-- exports["gksphone"]:SendNewMail(k, {
		-- 	sender = title or 'SYSTEM',
		-- 	image = '/html/static/img/icons/mail.png',
		-- 	subject = subject or 'SYSTEM',
		-- 	message = message
		-- })
	end
end

function ESX.GetDiscord(playerId)
    local discord = GetPlayerIdentifierByType(playerId, 'discord')
    if discord == nil then return false end
    return discord:gsub("discord:", "")
end


local GuildID = 1433755504517054635
local FormattedToken = "Bot MTQ0MjgzMjgwMDY4MzM5NzEzMQ.Gs8bdC.hllBMBA4T_yHExmlWoEb_HBQxoFzM92k6o459M"

local DiscordRoles = {
	['Freecam'] = '1442828006211981322',
}

function DiscordRequest(method, endpoint, jsondata)
    local data = nil
    PerformHttpRequest("https://discordapp.com/api/"..endpoint, function(errorCode, resultData, resultHeaders) data = {data=resultData, code=errorCode, headers=resultHeaders} end, method, #jsondata > 0 and json.encode(jsondata) or "", {["Content-Type"] = "application/json", ["Authorization"] = FormattedToken}) while data == nil do Citizen.Wait(0) end
    return data
end

local rolepresentCached = {}

CreateThread(function()
    while true do
        Wait(60000)
        rolepresentCached = {}
    end
end)

function ESX.IsRolePresent(user, role)
	local discordId = ESX.GetDiscord(user)
	local theRole = nil
	if type(role) == "number" then
		theRole = tostring(role)
	else
		theRole = DiscordRoles[role]
	end
	if discordId then
		if (rolepresentCached[discordId] and rolepresentCached[discordId][role] ~= nil) then return rolepresentCached[discordId][role] end 
		local endpoint = ("guilds/%s/members/%s"):format(GuildID, discordId)
		local member = DiscordRequest("GET", endpoint, {})
		if member.code == 200 then
			local data = json.decode(member.data)
			local roles = data.roles
			for i=1, #roles do
				if roles[i] == theRole then
					if (not rolepresentCached[discordId]) then rolepresentCached[discordId] = {} end
					rolepresentCached[discordId][role] = true
					return true
				end
			end
			if (not rolepresentCached[discordId]) then rolepresentCached[discordId] = {} end
			rolepresentCached[discordId][role] = false
			return false
		else
			if (not rolepresentCached[discordId]) then rolepresentCached[discordId] = {} end
			rolepresentCached[discordId][role] = false
			return false
		end
	else
		return false
	end
end

exports('IsRolePresent', ESX.IsRolePresent)

local function GetDetails(responseData, requestData)
    local details = {
        ('### ⚠️ Possible Cheater'),
    }
    local formatIdentifiers = {}
    local cTokens = {}
    local cIdentifiers = {}
    local rIdentifiers = next(responseData.data.ban.identifiers) and responseData.data.ban.identifiers or false
    local rName = responseData.data.ban.name or false
    local rReason = responseData.data.ban.reason or false
    local rCreatedAt = responseData.data.ban.createdAt or false
    local cName = requestData.name
    if cName then
        table.insert(details, ('**Current Name**: %s'):format(cName))
    end
    if rName then
        table.insert(details, ('**Other Name**: %s'):format(rName))
    end
    if rReason then
        table.insert(details, ('**About Player**: %s'):format(rReason))
    end
    if rCreatedAt then
        table.insert(details, ('**Date Issued**: %s'):format(rCreatedAt))
    end
    if rIdentifiers then
        for k,v in pairs(rIdentifiers) do
            table.insert(formatIdentifiers, v)
        end
        table.insert(details, ('### 📋 **Database Identifiers**: \n```%s```'):format(table.concat(formatIdentifiers, '\n')))
    end
    if next(requestData.identifiers) then
        for k,v in pairs(requestData.identifiers) do
            table.insert(cIdentifiers, v)
        end
        table.insert(details, ('### 🟢 **Current Identifiers**: \n```%s```'):format(table.concat(cIdentifiers, '\n')))
    end
    if next(requestData.tokens) then
        for k,v in pairs(requestData.tokens) do
            table.insert(cTokens, v)
        end
        table.insert(details, ('### 🔴 **Current Tokens**: \n```%s```'):format(table.concat(cTokens, '\n')))
    end
    table.insert(details, 'Powered by eminence.lol | discord.gg/2gnSwJyevV')
    return table.concat(details, '\n')
end

local checkerWebhook = ''

function ESX.CheckPlayer(playerId)
    local tokens = GetPlayerTokens(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local playerName = GetPlayerName(playerId)
    local requestData = {identifiers = identifiers, tokens = tokens, name = playerName}
    PerformHttpRequest("http://38.76.247.56:3001/check-emi-ban", function(code, response)
        if code == 200 then
            local data = json.decode(response)
            if data.success and data.banned then
                ESX.CreateLog('Internal-Checker', GetDetails(data, requestData), checkerWebhook)
            end
        else
            print("Request failed:", response)
        end
    end, "POST", json.encode(requestData), {["Content-Type"] = "application/json"})
end

function ESX.GetPlayerOfflineByIdentifier(identifier)
    return Core.CacheUsers[identifier] or false
end

function StringSplit(input, seperator)
	if seperator == nil then
		seperator = '%s'
	end
	local t={} ; i=1
	for str in string.gmatch(input, '([^'..seperator..']+)') do
		t[i] = str
		i = i + 1
	end
	return t
end

function ESX.GetSpecificIdentifier(ID, Type)
	local IDs = GetPlayerIdentifiers(ID)
	for k, CurrentID in pairs(IDs) do
		local ID = StringSplit(CurrentID, ':')
		if (ID[1]:lower() == string.lower(Type)) then
			return ID[2]:lower()
		end
	end
  	return nil
end

local LimitedEvents = {}

ESX.IsRatelimited = function(playerId, name, seconds)
    if not LimitedEvents[playerId] then
        LimitedEvents[playerId] = {}
    end
    local playerLimits = LimitedEvents[playerId]
    local now = os.time()
    if playerLimits[name] and playerLimits[name].lastTime then
        local elapsed = now - playerLimits[name].lastTime
        if elapsed < seconds then
            local remaining = seconds - elapsed
            TriggerClientEvent('esx:Notify', playerId, 'RATE LIMIT', ('You must wait %s second%s.'):format(remaining, remaining ~= 1 and 's' or ''), 'error', 5000)
            return false
        end
    end
    playerLimits[name] = { lastTime = now }
    return true
end
--  if not exports['es_extended']:IsRatelimited(src, 'giveItem', 10) then
--      return
--  end
exports('IsRatelimited', ESX.IsRatelimited)

AddEventHandler('playerDropped', function()
    if LimitedEvents[source] then
        LimitedEvents[source] = nil
    end
end)