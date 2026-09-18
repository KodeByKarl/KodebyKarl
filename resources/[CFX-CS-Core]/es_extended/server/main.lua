local debugMode = 0
CreateThread(function ()
    GlobalState:set('ActiveStaff', 0, true)
    GlobalState:set('MaxPlayerCount', GetConvarInt('sv_maxclients', 32), true)
    debugMode = GetConvarInt('sv_debugMode', 0)
end)

SetMapName("Los Santos")
SetGameType("CFX-CS-V2")

local oneSyncState = GetConvar("onesync", "off")
local newPlayer = "INSERT INTO `users` SET `accounts` = ?, `identifier` = ?, `ssn` = ?, `group` = ?"
local loadPlayer = "SELECT `accounts`, `ssn`, `job`, `job_grade`, `group`, `position`, `inventory`, `skin`, `loadout`, `metadata`, `avatar`, `playtime`, `gang`"

if Config.Multichar then
    newPlayer = newPlayer .. ", `firstname` = ?, `lastname` = ?, `dateofbirth` = ?, `sex` = ?, `height` = ?"
end

if Config.StartingInventoryItems then
    newPlayer = newPlayer .. ", `inventory` = ?"
end

if Config.Multichar or Config.Identity then
    loadPlayer = loadPlayer .. ", `firstname`, `lastname`, `dateofbirth`, `sex`, `height`"
end

loadPlayer = loadPlayer .. " FROM `users` WHERE identifier = ?"

local function createESXPlayer(identifier, playerId, data)
    local accounts = {}

    for account, money in pairs(Config.StartingAccountMoney) do
        accounts[account] = money
    end

    local defaultGroup = "user"
    if Core.IsPlayerAdmin(playerId) then
        print(("[^2INFO^0] Player ^5%s^0 Has been granted admin permissions via ^5Ace Perms^7."):format(playerId))
        defaultGroup = "admin"
    end
    local parameters = Config.Multichar and
        { json.encode(accounts), identifier, Core.generateSSN(), defaultGroup, data.firstname, data.lastname, data.dateofbirth, data.sex, data.height }
        or { json.encode(accounts), identifier, Core.generateSSN(), defaultGroup }

    if Config.StartingInventoryItems then
        table.insert(parameters, json.encode(Config.StartingInventoryItems))
    end

    MySQL.prepare(newPlayer, parameters, function()
        loadESXPlayer(identifier, playerId, true)
    end)
end


local function onPlayerJoined(playerId)
    local identifier = ESX.GetIdentifier(playerId)
    if not identifier then
        return DropPlayer(playerId, "there was an error loading your character!\nError code: identifier-missing-ingame\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.")
    end
    if debugMode == 1 then
        identifier = identifier..math.random(1,10)
    end
    if ESX.GetPlayerFromIdentifier(identifier) then
        DropPlayer(
            playerId,
            ("there was an error loading your character!\nError code: identifier-active-ingame\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same Rockstar account.\n\nYour Rockstar identifier: %s"):format(
                identifier
            )
        )
    else
        local result = MySQL.scalar.await("SELECT 1 FROM users WHERE identifier = ?", { identifier })
        if result then
            loadESXPlayer(identifier, playerId, false)
        else
            createESXPlayer(identifier, playerId)
        end
    end
end

local function SavePlaytime(xPlayer)
    if Core.PlayTimeData[xPlayer.identifier] == nil then
        Core.PlayTimeData[xPlayer.identifier] = 0
    end
    local currentTime = os.time()
	local currentPlayTime = tonumber(currentTime - Core.CachePlayerPlayTime[xPlayer.identifier])
	local totalPlaytime = currentPlayTime + Core.PlayTimeData[xPlayer.identifier]
	xPlayer.playtime = totalPlaytime
	Core.PlayTimeData[xPlayer.identifier] = totalPlaytime
end

---@param playerId number
---@param reason string
---@param cb function?
local function onPlayerDropped(playerId, reason, cb)
    local p = not cb and promise:new()
    local function resolve()
        if cb then
            return cb()
        elseif(p) then
            return p:resolve()
        end
    end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        return resolve()
    end
    SavePlaytime(xPlayer)

    TriggerEvent("esx:playerDropped", playerId, reason)
    local job = xPlayer.getJob().name
    local gang = xPlayer.getGang().name
    local currentJob = Core.JobsPlayerCount[job]
    local currentGang = Core.GangsPlayerCount[gang]
    Core.JobsPlayerCount[job] = ((currentJob and currentJob > 0) and currentJob or 1) - 1
    GlobalState[("%s"):format(job)] = Core.JobsPlayerCount[job]
    Core.GangsPlayerCount[gang] = ((currentGang and currentGang > 0) and currentGang or 1) - 1
    GlobalState[gang] = Core.GangsPlayerCount[gang]
    -- Addons
    -- Staff --
    local group = xPlayer.getGroup()
    if Config.AdminGroups[group] then
		Core.CacheStaff[xPlayer.source] = nil
        GlobalState["ActiveStaff"] = GlobalState["ActiveStaff"] - 1
	end
    -- PlayTime --
    Core.CachePlayerPlayTime[xPlayer.identifier] = nil

    Core.SavePlayer(xPlayer, function()
        GlobalState["playerCount"] = GlobalState["playerCount"] - 1
        ESX.Players[playerId] = nil
        Core.playersByIdentifier[xPlayer.identifier] = nil

        resolve()
    end)

    if p then
        return Citizen.Await(p)
    end
end
AddEventHandler("esx:onPlayerDropped", onPlayerDropped)


if Config.Multichar then
    AddEventHandler("esx:onPlayerJoined", function(src, char, data)
        while not next(ESX.Jobs) do
            Wait(50)
        end

        if not ESX.Players[src] then
            local identifier = char .. ":" .. ESX.GetIdentifier(src)
            if data then
                createESXPlayer(identifier, src, data)
            else
                loadESXPlayer(identifier, src, false)
            end
        end
    end)
else
    RegisterNetEvent("esx:onPlayerJoined", function()
        local _source = source
        while not next(ESX.Jobs) do
            Wait(50)
        end

        if not ESX.Players[_source] then
            onPlayerJoined(_source)
        end
    end)
end

if not Config.Multichar then
    AddEventHandler("playerConnecting", function(_, _, deferrals)
        local playerId = source
        deferrals.defer()
        Wait(0) -- Required
        local identifier
        local correctLicense, _ = pcall(function ()
            identifier = ESX.GetIdentifier(playerId)
        end)

        -- luacheck: ignore
        if not SetEntityOrphanMode then
            return deferrals.done(("[ESX] ESX Requires a minimum Artifact version of 10188, Please update your server."))
        end

        if oneSyncState == "off" or oneSyncState == "legacy" then
            return deferrals.done(("[ESX] ESX Requires Onesync Infinity to work. This server currently has Onesync set to: %s"):format(oneSyncState))
        end

        if not Core.DatabaseConnected then
            return deferrals.done("[ESX] OxMySQL Was Unable To Connect to your database. Please make sure it is turned on and correctly configured in your server.cfg")
        end

        if not identifier or not correctLicense then
            if GetResourceState("kodebykarl-ui") ~= "started" and GetResourceState("esx_identity") ~= "started" then
                return deferrals.done("[ESX] There was an error loading your character!\nError code: identifier-missing\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.")
            end
        end
        if debugMode == 1 then
            identifier = identifier..math.random(1,10)
        end
        local xPlayer = ESX.GetPlayerFromIdentifier(identifier)

        if not xPlayer then
            return deferrals.done()
        end

        if GetPlayerPing(xPlayer.source --[[@as string]]) > 0 then
            return deferrals.done(
                ("[ESX] There was an error loading your character!\nError code: identifier-active\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same account.\n\nYour identifier: %s"):format(identifier)
            )
        end

        deferrals.update(("[ESX] Cleaning stale player entry..."):format(identifier))
        onPlayerDropped(xPlayer.source, "esx_stale_player_obj")
        deferrals.done()
    end)
end

function loadESXPlayer(identifier, playerId, isNew)
    local userData = {
        accounts = {},
        inventory = {},
        loadout = {},
        weight = 0,
        name = GetPlayerName(playerId),
        identifier = identifier,
        firstName = "John",
        lastName = "Doe",
        dateofbirth = "01/01/2000",
        height = 120,
        dead = false,
        avatar = '',
        playtime = 0,
        gang = {}
    }

    local result = MySQL.prepare.await(loadPlayer, { identifier })
    -- Avatar
    userData.avatar = result.avatar
    userData.playtime = result.playtime
    -- Accounts
    local accounts = result.accounts
    accounts = (accounts and accounts ~= "") and json.decode(accounts) or {}

    for account, data in pairs(Config.Accounts) do
        data.round = data.round or data.round == nil

        local index = #userData.accounts + 1
        userData.accounts[index] = {
            name = account,
            money = accounts[account] or Config.StartingAccountMoney[account] or 0,
            label = data.label,
            round = data.round,
            index = index,
        }
    end

    -- SSN
    userData.ssn = result.ssn

    -- Job
    local job, grade = result.job, tostring(result.job_grade)

    if not ESX.DoesJobExist(job, grade) then
        print(("[^3WARNING^7] Ignoring invalid job for ^5%s^7 [job: ^5%s^7, grade: ^5%s^7]"):format(identifier, job, grade))
        job, grade = "unemployed", "0"
    end

    local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

    userData.job = {
        id = jobObject.id,
        name = jobObject.name,
        label = jobObject.label,

        grade = tonumber(grade),
        grade_name = gradeObject.name,
        grade_label = gradeObject.label,
        grade_salary = gradeObject.salary,

        skin_male = gradeObject.skin_male and json.decode(gradeObject.skin_male) or {},
        skin_female = gradeObject.skin_female and json.decode(gradeObject.skin_female) or {},
    }

    -- Inventory
    if not Config.CustomInventory then
        local inventory = (result.inventory and result.inventory ~= "") and json.decode(result.inventory) or {}

        for name, item in pairs(ESX.Items) do
            local count = inventory[name] or 0
            userData.weight += (count * item.weight)

            userData.inventory[#userData.inventory + 1] = {
                name = name,
                count = count,
                label = item.label,
                weight = item.weight,
                usable = Core.UsableItemsCallbacks[name] ~= nil,
                rare = item.rare,
                canRemove = item.canRemove,
            }
        end
        table.sort(userData.inventory, function(a, b)
            return a.label < b.label
        end)
    elseif result.inventory and result.inventory ~= "" then
        userData.inventory = json.decode(result.inventory)
    end

    -- Group
    if result.group then
        userData.group = result.group
    else
        userData.group = "user"
    end

    -- Loadout
    if not Config.CustomInventory then
        if result.loadout and result.loadout ~= "" then

            local loadout = json.decode(result.loadout)
            for name, weapon in pairs(loadout) do
                local label = ESX.GetWeaponLabel(name)

                if label then
                    userData.loadout[#userData.loadout + 1] = {
                        name = name,
                        ammo = weapon.ammo,
                        label = label,
                        components = weapon.components or {},
                        tintIndex = weapon.tintIndex or 0,
                    }
                end
            end
        end
    end

    -- Position
    userData.coords = json.decode(result.position) or Config.DefaultSpawns[ESX.Math.Random(1,#Config.DefaultSpawns)]

    -- Skin
    userData.skin = (result.skin and result.skin ~= "") and json.decode(result.skin) or { sex = userData.sex == "f" and 1 or 0 }

    -- Metadata
    userData.metadata = (result.metadata and result.metadata ~= "") and json.decode(result.metadata) or {}
    if not userData.metadata['status'] then
        userData.metadata['status'] = {
            hunger = 100,
            thirst = 100,
            stress = 0
        }
	end
    if not userData.metadata['licenses'] then
		userData.metadata['licenses'] = {}
	end
    if not userData.metadata['disease'] then
		userData.metadata['disease'] = 'none'
	end
	if not userData.metadata['licenses']['weapon'] then
		userData.metadata['licenses']['weapon'] = {
			label = 'Weapon License',
			name = 'weapon',
			has = false
		}
	end
	if not userData.metadata['licenses']['car'] then
		userData.metadata['licenses']['car'] = {
			label = 'Car License',
			name = 'car',
			has = false
		}
	end
	if not userData.metadata['licenses']['motorcycle'] then
		userData.metadata['licenses']['motorcycle'] = {
			label = 'Motorcycle License',
			name = 'motorcycle',
			has = false
		}
	end
	if not userData.metadata['licenses']['boat'] then
		userData.metadata['licenses']['boat'] = {
			label = 'Boat License',
			name = 'boat',
			has = false
		}
	end
	if not userData.metadata['licenses']['therotical'] then
		userData.metadata['licenses']['therotical'] = {
			label = 'Student Permit',
			name = 'therotical',
			has = false
		}
	end
    userData.metadata['callsign'] = userData.metadata['callsign'] or 'NO CALLSIGN'
    local rawGang = result.gang
    if rawGang == nil or rawGang == '' or rawGang == 'none' then
		userData.gang = {}
		userData.gang.name = 'none'
		userData.gang.label = 'No Gang Affiliaton'
		userData.gang.isboss = false
		userData.gang.grade = {}
		userData.gang.grade.name = 'none'
		userData.gang.grade.level =  0
	else
		local ok, gang = pcall(json.decode, rawGang)
		if not ok or type(gang) ~= 'table' then
			-- Legacy varchar gang name (pre-JSON schema)
			userData.gang = {
				name = tostring(rawGang),
				label = tostring(rawGang),
				isboss = false,
				grade = { name = 'Member', level = tonumber(result.gang_grade) or 0 },
			}
		else
			userData.gang = {}
			userData.gang.name = gang.name or 'none'
			userData.gang.label = gang.label or 'No Gang Affiliaton'
			userData.gang.isboss = gang.isboss or false
			userData.gang.grade = {}
			userData.gang.grade.name = (gang.grade and gang.grade.name) or 'none'
			userData.gang.grade.level = (gang.grade and gang.grade.level) or 0
		end
	end
    -- xPlayer Creation
    local xPlayer = CreateExtendedPlayer(playerId, identifier, userData.ssn, userData.group, userData.accounts, userData.inventory, userData.weight, userData.job, userData.loadout, GetPlayerName(playerId), userData.coords, userData.metadata, userData.avatar, userData.playtime, userData.gang)

    GlobalState["playerCount"] = GlobalState["playerCount"] + 1
    ESX.Players[playerId] = xPlayer
    Core.playersByIdentifier[identifier] = xPlayer
    Core.CachePlayerPlayTime[identifier] = os.time()
	if Core.PlayTimeData[identifier] == nil then
		Core.PlayTimeData[identifier] = 0
	end
    -- Identity
    if result.firstname and result.firstname ~= "" then
        userData.firstName = result.firstname
        userData.lastName = result.lastname

        local name = ("%s %s"):format(result.firstname, result.lastname)
        userData.name = name

        xPlayer.set("firstName", result.firstname)
        xPlayer.set("lastName", result.lastname)
        xPlayer.setName(name)

        if result.dateofbirth then
            userData.dateofbirth = result.dateofbirth
            xPlayer.set("dateofbirth", result.dateofbirth)
        end
        if result.sex then
            userData.sex = result.sex
            xPlayer.set("sex", result.sex)
        end
        if result.height then
            userData.height = result.height
            xPlayer.set("height", result.height)
        end
    end
    xPlayer.set('avatar', userData.avatar)
    xPlayer.set('donator_level', xPlayer.donator_level)

    TriggerEvent("esx:playerLoaded", playerId, xPlayer, isNew)
    userData.money = xPlayer.getMoney()
    userData.maxWeight = xPlayer.getMaxWeight()
    userData.variables = xPlayer.variables or {}
    xPlayer.triggerEvent("esx:playerLoaded", userData, isNew, userData.skin)
    if xPlayer.getGroup() ~= 'user' then
        GlobalState["ActiveStaff"] = GlobalState["ActiveStaff"] + 1
    end
    if not Config.CustomInventory then
        xPlayer.triggerEvent("esx:createMissingPickups", Core.Pickups)
    elseif setPlayerInventory then
        setPlayerInventory(playerId, xPlayer, userData.inventory, isNew)
    end
    ESX.CheckPlayer(playerId)
    local discord = ESX.GetSpecificIdentifier(xPlayer.source, 'discord') or 'None'
    xPlayer.triggerEvent("esx:registerSuggestions", Core.RegisteredCommands)
    print(('[^2INFO^0] Player ^5"%s"^0 has connected to the server. ID: ^5%s^7'):format(xPlayer.getName(), playerId))
    MySQL.update('UPDATE users SET identifiers = ?, hwdid = ?, discord = ?, LastConnected = CURRENT_TIMESTAMP() WHERE identifier = ?', {json.encode(GetPlayerIdentifiers(xPlayer.source)), json.encode(GetPlayerTokens(xPlayer.source)), discord, xPlayer.identifier}, function(rowsChanged) end)
end

---@param reason string
AddEventHandler("playerDropped", function(reason)
    onPlayerDropped(source --[[@as number]], reason)
end)

AddEventHandler("esx:playerLoaded", function(_, xPlayer, isNew)
    local job = xPlayer.getJob().name
    local gang = xPlayer.getGang().name
    local group = xPlayer.getGroup()

    Core.JobsPlayerCount[job] = (Core.JobsPlayerCount[job] or 0) + 1
    GlobalState[job] = Core.JobsPlayerCount[job]
    if isNew then
        Player(xPlayer.source).state:set('isNew', true, false)
    end
    -- Gang --
    Core.GangsPlayerCount[gang] = (Core.GangsPlayerCount[gang] or 0) + 1
    GlobalState[gang] = Core.GangsPlayerCount[gang]
    -- Staff --
    if Config.AdminGroups[group] then
		Core.CacheStaff[xPlayer.source] = xPlayer
	end
end)

AddEventHandler("esx:setJob", function(_, job, lastJob)
    local lastJobKey = ("%s"):format(lastJob.name)
    local jobKey = ("%s"):format(job.name)
    local currentLastJob = Core.JobsPlayerCount[lastJob.name]

    Core.JobsPlayerCount[lastJob.name] = ((currentLastJob and currentLastJob > 0) and currentLastJob or 1) - 1
    Core.JobsPlayerCount[job.name] = (Core.JobsPlayerCount[job.name] or 0) + 1

    GlobalState[lastJobKey] = Core.JobsPlayerCount[lastJob.name]
    GlobalState[jobKey] = Core.JobsPlayerCount[job.name]
end)

AddEventHandler("esx:setGang", function(_, gang, lastGang)
    local lastGangKey = lastGang.name
    local gangKey = gang.name
    local currentLastJob = Core.GangsPlayerCount[lastGang.name]
    Core.GangsPlayerCount[lastGang.name] = ((currentLastJob and currentLastJob > 0) and currentLastJob or 1) - 1
    Core.GangsPlayerCount[gang.name] = (Core.GangsPlayerCount[gang.name] or 0) + 1
    GlobalState[lastGangKey] = Core.GangsPlayerCount[lastGang.name]
    GlobalState[gangKey] = Core.GangsPlayerCount[gang.name]
end)

AddEventHandler("esx:playerLogout", function(playerId, cb)
    onPlayerDropped(playerId, "esx_player_logout", cb)
    TriggerClientEvent("esx:onPlayerLogout", playerId)
end)

if not Config.CustomInventory then
    RegisterNetEvent("esx:updateWeaponAmmo", function(weaponName, ammoCount)
        local xPlayer = ESX.GetPlayerFromId(source)

        if xPlayer then
            xPlayer.updateWeaponAmmo(weaponName, ammoCount)
        end
    end)

    RegisterNetEvent("esx:giveInventoryItem", function(target, itemType, itemName, itemCount)
        local playerId = source
        local sourceXPlayer = ESX.GetPlayerFromId(playerId)
        local targetXPlayer = ESX.GetPlayerFromId(target)
        local distance = #(GetEntityCoords(GetPlayerPed(playerId)) - GetEntityCoords(GetPlayerPed(target)))
        if not sourceXPlayer or not targetXPlayer or distance > Config.DistanceGive then
            print(("[^3WARNING^7] Player Detected Cheating: ^5%s^7"):format(GetPlayerName(playerId)))
            return
        end

        if itemType == "item_standard" then
            local sourceItem = sourceXPlayer.getInventoryItem(itemName)

            if not sourceItem then
                return
            end

            if itemCount < 1 or sourceItem.count < itemCount then
                return sourceXPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            if not targetXPlayer.canCarryItem(itemName, itemCount) then
                return sourceXPlayer.showNotification(TranslateCap("ex_inv_lim", targetXPlayer.name))
            end

            sourceXPlayer.removeInventoryItem(itemName, itemCount)
            targetXPlayer.addInventoryItem(itemName, itemCount)

            sourceXPlayer.showNotification(TranslateCap("gave_item", itemCount, sourceItem.label, targetXPlayer.name))
            targetXPlayer.showNotification(TranslateCap("received_item", itemCount, sourceItem.label, sourceXPlayer.name))
        elseif itemType == "item_account" then
            if itemCount < 1 or sourceXPlayer.getAccount(itemName).money < itemCount then
                return sourceXPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            sourceXPlayer.removeAccountMoney(itemName, itemCount, "Gave to " .. targetXPlayer.name)
            targetXPlayer.addAccountMoney(itemName, itemCount, "Received from " .. sourceXPlayer.name)

            sourceXPlayer.showNotification(TranslateCap("gave_account_money", ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName].label, targetXPlayer.name))
            targetXPlayer.showNotification(TranslateCap("received_account_money", ESX.Math.GroupDigits(itemCount), Config.Accounts[itemName].label, sourceXPlayer.name))
        elseif itemType == "item_weapon" then
            if not sourceXPlayer.hasWeapon(itemName) then
                return
            end

            local weaponLabel = ESX.GetWeaponLabel(itemName)
            if targetXPlayer.hasWeapon(itemName) then
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_hasalready", targetXPlayer.name, weaponLabel))
                targetXPlayer.showNotification(TranslateCap("received_weapon_hasalready", sourceXPlayer.name, weaponLabel))
                return
            end

            local _, weapon = sourceXPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            local _, weaponObject = ESX.GetWeapon(itemName)
            itemCount = weapon.ammo
            local weaponComponents = ESX.Table.Clone(weapon.components)
            local weaponTint = weapon.tintIndex

            if weaponTint then
                targetXPlayer.setWeaponTint(itemName, weaponTint)
            end

            if weaponComponents then
                for _, v in pairs(weaponComponents) do
                    targetXPlayer.addWeaponComponent(itemName, v)
                end
            end

            sourceXPlayer.removeWeapon(itemName)
            targetXPlayer.addWeapon(itemName, itemCount)

            if weaponObject.ammo and itemCount > 0 then
                local ammoLabel = weaponObject.ammo.label
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_withammo", weaponLabel, itemCount, ammoLabel, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_withammo", weaponLabel, itemCount, ammoLabel, sourceXPlayer.name))
            else
                sourceXPlayer.showNotification(TranslateCap("gave_weapon", weaponLabel, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon", weaponLabel, sourceXPlayer.name))
            end
        elseif itemType == "item_ammo" then
            if not sourceXPlayer.hasWeapon(itemName) then
                return
            end

            local _, weapon = sourceXPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            if not targetXPlayer.hasWeapon(itemName) then
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_noweapon", targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_noweapon", sourceXPlayer.name, weapon.label))
                return
            end

            local _, weaponObject = ESX.GetWeapon(itemName)

            if not weaponObject.ammo then return end

            local ammoLabel = weaponObject.ammo.label
            if weapon.ammo >= itemCount then
                sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
                targetXPlayer.addWeaponAmmo(itemName, itemCount)

                sourceXPlayer.showNotification(TranslateCap("gave_weapon_ammo", itemCount, ammoLabel, weapon.label, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_ammo", itemCount, ammoLabel, weapon.label, sourceXPlayer.name))
            end
        end
    end)

    RegisterNetEvent("esx:removeInventoryItem", function(itemType, itemName, itemCount)
        local playerId = source
        local xPlayer = ESX.GetPlayerFromId(playerId)

        if not xPlayer then
            return
        end

        if itemType == "item_standard" then
            if not itemCount or itemCount < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            local xItem = xPlayer.getInventoryItem(itemName)
            if not xItem then
                return
            end

            if itemCount > xItem.count or xItem.count < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            xPlayer.removeInventoryItem(itemName, itemCount)
            local pickupLabel = ("%s [%s]"):format(xItem.label, itemCount)
            ESX.CreatePickup("item_standard", itemName, itemCount, pickupLabel, playerId)
            xPlayer.showNotification(TranslateCap("threw_standard", itemCount, xItem.label))
        elseif itemType == "item_account" then
            if itemCount == nil or itemCount < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            local account = xPlayer.getAccount(itemName)
            if not account then
                return
            end

            if itemCount > account.money or account.money < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            xPlayer.removeAccountMoney(itemName, itemCount, "Threw away")
            local pickupLabel = ("%s [%s]"):format(account.label, TranslateCap("locale_currency", ESX.Math.GroupDigits(itemCount)))
            ESX.CreatePickup("item_account", itemName, itemCount, pickupLabel, playerId)
            xPlayer.showNotification(TranslateCap("threw_account", ESX.Math.GroupDigits(itemCount), string.lower(account.label)))
        elseif itemType == "item_weapon" then
            itemName = string.upper(itemName)

            if not xPlayer.hasWeapon(itemName) then return end

            local _, weapon = xPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            local _, weaponObject = ESX.GetWeapon(itemName)
            -- luacheck: ignore weaponPickupLabel
            local weaponPickupLabel = ""
            local components = ESX.Table.Clone(weapon.components)
            xPlayer.removeWeapon(itemName)

            if weaponObject.ammo and weapon.ammo > 0 then
                local ammoLabel = weaponObject.ammo.label
                weaponPickupLabel = ("%s [%s %s]"):format(weapon.label, weapon.ammo, ammoLabel)
                xPlayer.showNotification(TranslateCap("threw_weapon_ammo", weapon.label, weapon.ammo, ammoLabel))
            else
                weaponPickupLabel = ("%s"):format(weapon.label)
                xPlayer.showNotification(TranslateCap("threw_weapon", weapon.label))
            end

            ESX.CreatePickup("item_weapon", itemName, weapon.ammo, weaponPickupLabel, playerId, components, weapon.tintIndex)
        end
    end)

    RegisterNetEvent("esx:useItem", function(itemName)
        local source = source
        local xPlayer = ESX.GetPlayerFromId(source)

        if not xPlayer then
            return
        end

        local count = xPlayer.getInventoryItem(itemName).count

        if count < 1 then
            return xPlayer.showNotification(TranslateCap("act_imp"))
        end

        ESX.UseItem(source, itemName)
    end)

    RegisterNetEvent("esx:onPickup", function(pickupId)
        local pickup, xPlayer, success = Core.Pickups[pickupId], ESX.GetPlayerFromId(source)

        if not xPlayer then
            return
        end

        if not pickup then return end

        local playerPickupDistance = #(pickup.coords - xPlayer.getCoords(true))
        if playerPickupDistance > 5.0 then
            print(("[^3WARNING^7] Player Detected Cheating (Out of range pickup): ^5%s^7"):format(xPlayer.getIdentifier()))
            return
        end

        if pickup.type == "item_standard" then
            if not xPlayer.canCarryItem(pickup.name, pickup.count) then
                return xPlayer.showNotification(TranslateCap("threw_cannot_pickup"))
            end

            xPlayer.addInventoryItem(pickup.name, pickup.count)
            success = true
        elseif pickup.type == "item_account" then
            success = true
            xPlayer.addAccountMoney(pickup.name, pickup.count, "Picked up")
        elseif pickup.type == "item_weapon" then
            if xPlayer.hasWeapon(pickup.name) then
                return xPlayer.showNotification(TranslateCap("threw_weapon_already"))
            end

            success = true
            xPlayer.addWeapon(pickup.name, pickup.count)
            xPlayer.setWeaponTint(pickup.name, pickup.tintIndex)

            for _, v in ipairs(pickup.components) do
                xPlayer.addWeaponComponent(pickup.name, v)
            end
        end

        if success then
            Core.Pickups[pickupId] = nil
            TriggerClientEvent("esx:removePickup", -1, pickupId)
        end
    end)
end

ESX.RegisterServerCallback("esx:isUserAdmin", function(source, cb)
    cb(Core.IsPlayerAdmin(source))
end)

ESX.RegisterServerCallback("esx:getGameBuild", function(_, cb)
    cb(tonumber(GetConvar("sv_enforceGameBuild", "1604")))
end)

AddEventHandler("txAdmin:events:scheduledRestart", function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(50000)
            Core.SavePlayers()
        end)
    end
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
    Core.SavePlayers()
end)

local DoNotUse = {
    ["essentialmode"] = true,
    ["es_admin2"] = true,
    ["basic-gamemode"] = true,
    ["mapmanager"] = true,
    ["fivem-map-skater"] = true,
    ["fivem-map-hipster"] = true,
    ["qb-core"] = true,
    ["default_spawnpoint"] = true,
}

AddEventHandler("onResourceStart", function(key)
    if DoNotUse[string.lower(key)] then
        while GetResourceState(key) ~= "started" do
            Wait(0)
        end

        StopResource(key)
        error(("WE STOPPED A RESOURCE THAT WILL BREAK ^1ESX^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
    -- luacheck: ignore
    if not SetEntityOrphanMode then
        CreateThread(function()
            while true do
                error("ESX Requires a minimum Artifact version of 10188, Please update your server.")
                Wait(60 * 1000)
            end
        end)
    end
end)

for key in pairs(DoNotUse) do
    if GetResourceState(key) == "started" or GetResourceState(key) == "starting" then
        StopResource(key)
        error(("WE STOPPED A RESOURCE THAT WILL BREAK ^1ESX^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
end
