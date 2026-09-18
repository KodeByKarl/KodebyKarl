ESX.Players = {}
ESX.Jobs = {}
ESX.Items = {}
Core = {}
Core.JobsPlayerCount = {}
Core.UsableItemsCallbacks = {}
Core.RegisteredCommands = {}
Core.Pickups = {}
Core.PickupId = 0
Core.PlayerFunctionOverrides = {}
Core.DatabaseConnected = false
Core.playersByIdentifier = {}
Core.JobsLoaded = false
Core.PlayerStatus = {}

---@type table<string, CVehicleData>
Core.vehicles = {}
Core.vehicleTypesByModel = {}

-- Addons
Core.GangsPlayerCount = {}
Core.CacheUsers = {}
Core.CachePlayerPlayTime = {}
Core.PlayTimeData = {}
Core.CacheStaff = {}
ESX.Shared = ESXShared

RegisterNetEvent("esx:onPlayerSpawn", function()
    ESX.Players[source].spawned = true
end)

if Config.CustomInventory then
    SetConvarReplicated("inventory:framework", "esx")
    SetConvarReplicated("inventory:weight", tostring(Config.MaxWeight * 1000))
end

local function StartDBSync()
    CreateThread(function()
        local interval <const> = 10 * 60 * 1000
        while true do
            Wait(interval)
            Core.SavePlayers()
        end
    end)
end

MySQL.ready(function()
    Core.DatabaseConnected = true

    -- Ensure CFX-CS custom columns exist (avatar / playtime / JSON gang / identifiers)
    local ensureColumns = {
        [[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `avatar` LONGTEXT NOT NULL DEFAULT 'https://r2.fivemanage.com/jnFlnukrREoazOSLNY1VW/male.png']],
        [[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `playtime` INT(10) NOT NULL DEFAULT 0]],
        [[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `discord` VARCHAR(60) DEFAULT NULL]],
        [[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `identifiers` LONGTEXT DEFAULT '[]']],
        [[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `hwdid` LONGTEXT DEFAULT '[]']],
        [[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `DateCreated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()]],
        [[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `LastConnected` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()]],
        [[ALTER TABLE `users` MODIFY COLUMN `gang` LONGTEXT NULL]],
    }
    for i = 1, #ensureColumns do
        pcall(function()
            MySQL.query.await(ensureColumns[i])
        end)
    end

    if not Config.CustomInventory then
        ESX.RefreshItems()
    end

    local usersResponse = MySQL.query.await("SELECT * FROM `users`")
    if usersResponse then
        for i = 1, #usersResponse do
            local row = usersResponse[i]
            if Core.PlayTimeData[row.identifier] == nil then
                Core.PlayTimeData[row.identifier] = row.playtime
            end
            if Core.CacheUsers[row.identifier] == nil then
                Core.CacheUsers[row.identifier] = row
            end
            if Core.PlayerStatus[row.identifier] == nil and row.status then
                Core.PlayerStatus[row.identifier] = json.decode(row.status)
            end
        end
    end

    ESX.RefreshJobs()

    for job in pairs(ESX.Jobs) do
		if not job:find('off') then
			GlobalState[job] = 0
		end
	end

    print(("[^2INFO^7] ESX ^5Legacy %s^0 initialized!"):format(GetResourceMetadata(GetCurrentResourceName(), "version", 0)))
    StartDBSync()
    if Config.EnablePaycheck then
        StartPayCheck()
    end
end)

RegisterNetEvent("esx:clientLog", function(msg)
    if Config.EnableDebug then
        print(("[^2TRACE^7] %s^7"):format(msg))
    end
end)

RegisterNetEvent("esx:ReturnVehicleType", function(Type, Request)
    if Core.ClientCallbacks[Request] then
        Core.ClientCallbacks[Request](Type)
        Core.ClientCallbacks[Request] = nil
    end
end)

GlobalState.playerCount = 0
