---@diagnostic disable: undefined-field

---@param src integer
---@param msg string
---@param type "success" | "warning" | "error"
function Framework.Server.Notify(src, msg, type)
  TriggerClientEvent("jg-dealerships:client:notify", src, msg, type, 5000)
end

---@param src integer
---@returns boolean
function Framework.Server.IsAdmin(src)
  return IsPlayerAceAllowed(tostring(src), "command") or false
end

---Build SQL expression for searching player name by identifier column
---@param identifierColumn string The column containing the player identifier (e.g., "sales.player")
---@return string sqlExpression SQL expression that resolves to player's full name
function Framework.Server.GetPlayerNameSearchExpression(identifierColumn)
  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    -- For QB/Qbox: charinfo is JSON, need to extract firstname and lastname
    return ("(SELECT CONCAT_WS(' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) FROM %s WHERE %s = %s)"):format(
      Framework.PlayersTable,
      Framework.PlayersTableId,
      identifierColumn
    )
  elseif Config.Framework == "ESX" then
    -- For ESX: firstname and lastname are separate columns
    return ("(SELECT CONCAT_WS(' ', firstname, lastname) FROM %s WHERE %s = %s)"):format(
      Framework.PlayersTable,
      Framework.PlayersTableId,
      identifierColumn
    )
  end
  return identifierColumn
end

-- 
-- Society
--

local usingNewQBBanking = GetResourceState("qb-banking") == "started" and tonumber(string.sub(GetResourceMetadata("qb-banking", "version", 0), 1, 3)) >= 2

local function callSocietyExport(fn)
  local ok, result = pcall(fn)
  if not ok then return false end
  return result ~= false
end

---@param society string
---@param societyType "job"|"gang"
---@return number balance
function Framework.Server.GetSocietyBalance(society, societyType)
  if GetResourceState("RxBanking") == "started" then
    local account = exports["RxBanking"]:GetSocietyAccount(society)
    return account and account.balance or 0
  elseif GetResourceState("okokBanking") == "started" then
    return exports["okokBanking"]:GetAccount(society)
  elseif GetResourceState("tgg-banking") == "started" then
    return exports["tgg-banking"]:GetSocietyAccountMoney(society)
  elseif GetResourceState("Renewed-Banking") == "started" then
    return exports["Renewed-Banking"]:getAccountMoney(society)
  elseif GetResourceState("wasabi_banking") == "started" then
    return exports["wasabi_banking"]:GetAccountBalance(society, "society") or 0
  elseif Config.Framework == "QBCore" then
    if usingNewQBBanking then
      return exports["qb-banking"]:GetAccountBalance(society)
    else
      if societyType == "job" then
        return exports["qb-management"]:GetAccount(society)
      elseif societyType == "gang" then
        return exports["qb-management"]:GetGangAccount(society)
      end
    end
  elseif Config.Framework == "ESX" then
    local balance = promise.new()

    TriggerEvent("esx_society:getSociety", society, function(data)
      if not data then return balance:resolve(0) end

      TriggerEvent("esx_addonaccount:getSharedAccount", data.account, function(account)
        return balance:resolve(account.money)
      end)
    end)

		return Citizen.Await(balance)
  end

  return 0
end

lib.callback.register("jg-dealerships:server:get-society-balance", function(_, society, type)
  return Framework.Server.GetSocietyBalance(society, type)
end)

---@param societyName string
---@param societyType "job"|"gang"
---@param amount number
---@return boolean success
function Framework.Server.RemoveFromSocietyFund(societyName, societyType, amount)
  local success = false

  if GetResourceState("RxBanking") == "started" then
    success = callSocietyExport(function() return exports["RxBanking"]:RemoveSocietyMoney(societyName, amount) end)
  elseif GetResourceState("okokBanking") == "started" then
    success = callSocietyExport(function() return exports["okokBanking"]:RemoveMoney(societyName, amount) end)
  elseif GetResourceState("tgg-banking") == "started" then
    success = callSocietyExport(function() return exports["tgg-banking"]:RemoveSocietyMoney(societyName, amount) end)
  elseif GetResourceState("Renewed-Banking") == "started" then
    success = callSocietyExport(function() return exports["Renewed-Banking"]:removeAccountMoney(societyName, amount) end)
  elseif GetResourceState("wasabi_banking") == "started" then
    success = callSocietyExport(function() return exports["wasabi_banking"]:RemoveMoney('society', societyName, amount) end)
  elseif Config.Framework == "QBCore" then
    if usingNewQBBanking then
      success = callSocietyExport(function() return exports["qb-banking"]:RemoveMoney(societyName, amount) end)
    else
      if societyType == "job" then
        success = callSocietyExport(function() return exports["qb-management"]:RemoveMoney(societyName, amount) end)
      elseif societyType == "gang" then
        success = callSocietyExport(function() return exports["qb-management"]:RemoveGangMoney(societyName, amount) end)
      end
    end
  elseif Config.Framework == "ESX" then
    local removed = promise.new()

    TriggerEvent("esx_society:getSociety", societyName, function(society)
      if not society then return removed:resolve(false) end

      TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
        if not account then return removed:resolve(false) end
        account.removeMoney(amount)
        return removed:resolve(true)
      end)
    end)

    success = Citizen.Await(removed)
  end

  return success == true
end

---@param societyName string
---@param societyType "job"|"gang"
---@param amount number
---@return boolean success
function Framework.Server.AddToSocietyFund(societyName, societyType, amount)
  local success = false

  if GetResourceState("RxBanking") == "started" then
    success = callSocietyExport(function() return exports["RxBanking"]:AddSocietyMoney(societyName, amount) end)
  elseif GetResourceState("okokBanking") == "started" then
    success = callSocietyExport(function() return exports["okokBanking"]:AddMoney(societyName, amount) end)
  elseif GetResourceState("tgg-banking") == "started" then
    success = callSocietyExport(function() return exports["tgg-banking"]:AddSocietyMoney(societyName, amount) end)
  elseif GetResourceState("Renewed-Banking") == "started" then
    success = callSocietyExport(function() return exports["Renewed-Banking"]:addAccountMoney(societyName, amount) end)
  elseif GetResourceState("wasabi_banking") == "started" then
    success = callSocietyExport(function() return exports["wasabi_banking"]:AddMoney('society', societyName, amount) end)
  elseif Config.Framework == "QBCore" then
    if usingNewQBBanking then
      success = callSocietyExport(function() return exports["qb-banking"]:AddMoney(societyName, amount) end)
    else
      if societyType == "job" then
        success = callSocietyExport(function() return exports["qb-management"]:AddMoney(societyName, amount) end)
      elseif societyType == "gang" then
        success = callSocietyExport(function() return exports["qb-management"]:AddGangMoney(societyName, amount) end)
      end
    end
  elseif Config.Framework == "ESX" then
    local added = promise.new()

    TriggerEvent("esx_society:getSociety", societyName, function(society)
      if not society then return added:resolve(false) end

      TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
        if not account then return added:resolve(false) end
        account.addMoney(amount)
        return added:resolve(true)
      end)
    end)

    success = Citizen.Await(added)
  end

  return success == true
end

---Generate a VIN with vms_cityhall and store it against the vehicle row
---No-op when vms_cityhall is not started, and never fails the purchase it is called from
---@param plate string
local function SetVehicleVIN(plate)
  if GetResourceState("vms_cityhall") ~= "started" then return end
  if not plate or plate == "" then return end

  local ok, vin = pcall(function() return exports["vms_cityhall"]:GenerateVIN() end)
  if not ok or not vin or vin == "" then
    DebugPrint(("vms_cityhall GenerateVIN returned nothing for plate %s, saving without a VIN"):format(plate), "warning")
    return
  end

  local saved = pcall(function()
    MySQL.update.await(("UPDATE %s SET vin = ? WHERE plate = ?"):format(Framework.VehiclesTable), {vin, plate})
  end)
  if not saved then
    DebugPrint(("Could not write VIN %s to the %s table, check that the vin column exists"):format(vin, Framework.VehiclesTable), "warning")
    return
  end

  DebugPrint(("Set vms_cityhall VIN %s for plate %s"):format(vin, plate), "debug")
end

---@param purchaseType "society"|"personal"
---@param society? string
---@param societyType? string
---@param model string|integer
---@param plate string
---@param financed? boolean
---@param financeData? table
---@return integer|nil vehicleId
function Framework.Server.SaveVehicleToGarage(src, purchaseType, society, societyType, model, plate, financed, financeData)
  local vehicleId = nil
  local props = json.encode({
    model = ConvertModelToHash(model),
    plate = plate
  })

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    local playerData = Framework.Server.GetPlayer(src).PlayerData
    local license = playerData.license
    local citizenid = playerData.citizenid

    if purchaseType == "society" then
      vehicleId = MySQL.insert.await(
        "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, financed, finance_data, job_vehicle, job_vehicle_rank, gang_vehicle, gang_vehicle_rank) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        {license, society, model, joaat(model), props, plate, financed, json.encode(financeData), societyType == "job" and 1 or 0, 0, societyType == "gang" and 1 or 0, 0}
      )
    else
      vehicleId = MySQL.insert.await(
        "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, financed, finance_data) VALUES(?, ?, ?, ?, ?, ?, ?, ?)",
        {license, citizenid, model, joaat(model), props, plate, financed, json.encode(financeData)}
      )
    end
  elseif Config.Framework == "ESX" then
    local identifier = Framework.Server.GetPlayerIdentifier(src)
    DebugPrint("Saving vehicle to garage for "..identifier.. " type: "..purchaseType, "debug")
    if purchaseType == "society" and societyType == "job" then
      vehicleId = MySQL.insert.await(
        "INSERT INTO owned_vehicles (owner, plate, vehicle, financed, finance_data, job_vehicle, job_vehicle_rank) VALUES(?, ?, ?, ?, ?, ?, ?)",
        {society, plate, props, financed, json.encode(financeData), 1, 0}
      )
    else
      vehicleId = MySQL.insert.await(
        "INSERT INTO owned_vehicles (owner, plate, vehicle, financed, finance_data) VALUES(?, ?, ?, ?, ?)",
        {identifier, plate, props, financed, json.encode(financeData)}
      )
    end
  end

  if vehicleId then SetVehicleVIN(plate) end

  return vehicleId
end

---@param vehicle boolean|QueryResult|unknown|{ [number]: { [string]: unknown  }|{ [string]: unknown }}
---@return string | number | false model
function Framework.Server.GetModelColumn(vehicle)
  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return vehicle.vehicle or tonumber(vehicle.hash) or false
  elseif Config.Framework == "ESX" then
    if not vehicle or not vehicle.vehicle then return false end

    if type(vehicle.vehicle) == "string" then
      if not json.decode(vehicle.vehicle) then return false end
      return json.decode(vehicle.vehicle).model
    else
      return vehicle.vehicle.model
    end
  end

  return false
end

---@param vehicle integer
---@return string | false plate 
function Framework.Server.GetPlate(vehicle)
  local plate = GetVehicleNumberPlateText(vehicle)
  if not plate or plate == nil or plate == "" then return false end

  if GetResourceState("brazzers-fakeplates") == "started" then
    local originalPlate = MySQL.scalar.await("SELECT plate FROM player_vehicles WHERE fakeplate = ?", {plate})
    if originalPlate then plate = originalPlate end
  end

  local trPlate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
  return trPlate
end

---Generate a plate based on a seed
---@param seed string
---@param checkIfExists? boolean Check if the plate exists in the DB
---@return string|false generatedPlate
function Framework.Server.VehicleGeneratePlate(seed, checkIfExists)
  seed = seed or "1AA111AA"

  local CHARSET_NUMBERS, CHARSET_LETTERS = "0123456789", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local attempts = 0

  while attempts < 20 do
    local i, plate = 0, ""

    while i <= seed:len() do
      local char = seed:sub(i, i)

      if char == "A" then
        local randLetterPos = math.random(1, #CHARSET_LETTERS)
        local randLetter = CHARSET_LETTERS:sub(randLetterPos, randLetterPos)
        plate = plate .. randLetter
      elseif char == "1" then
        local randNumberPos = math.random(1, #CHARSET_NUMBERS)
        local randNumber = CHARSET_NUMBERS:sub(randNumberPos, randNumberPos)
        plate = plate .. randNumber
      elseif char == "^" then
        i = i + 1
        if i <= seed:len() then plate = plate .. seed:sub(i, i) end
      else
        plate = plate .. char
      end

      i = i + 1
    end

    plate = plate:upper()

    if plate:len() > 8 then
      error("^1[ERROR] You are generating a plate with more than 8 characters.")
      return false
    end

    if not checkIfExists then
      return plate
    end

    local result = MySQL.scalar.await("SELECT plate FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate})
    if not result then return plate end

    attempts = attempts + 1
  end

  return false
end

lib.callback.register("jg-dealerships:server:vehicle-generate-plate", function(_, ...)
  return Framework.Server.VehicleGeneratePlate(...)
end)

exports("generatePlate", Framework.Server.VehicleGeneratePlate)

--
-- Player Functions
--

---@param src integer
function Framework.Server.GetPlayer(src)
  if Config.Framework == "QBCore" then
    return QBCore.Functions.GetPlayer(src)
  elseif Config.Framework == "Qbox" then
    return exports.qbx_core:GetPlayer(src)
  elseif Config.Framework == "ESX" then
    return ESX.GetPlayerFromId(src)
  end
end

---@param src integer
function Framework.Server.GetPlayerInfo(src)
  local player = Framework.Server.GetPlayer(src)
  if not player then return false end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return {
      name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    }
  elseif Config.Framework == "ESX" then
    return {
      name = player.getName()
    }
  end
end

---@param identifier string
function Framework.Server.GetPlayerInfoFromIdentifier(identifier)
  local player = MySQL.single.await("SELECT * FROM " .. Framework.PlayersTable .. " WHERE " .. Framework.PlayersTableId .. " = ?", {identifier})
  if not player then return false end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    local charinfo = json.decode(player.charinfo)
    return {
      name = charinfo.firstname .. " " .. charinfo.lastname
    }
  elseif Config.Framework == "ESX" then
    return {
      name = player.firstname .. " " .. player.lastname
    }
  end
end

---@param src integer
---@return string|false identifier
function Framework.Server.GetPlayerIdentifier(src)
  local player = Framework.Server.GetPlayer(src)
  if not player then return false end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return player.PlayerData.citizenid
  elseif Config.Framework == "ESX" then
    return player.getIdentifier()
  end

  return false
end

---@param identifier string
---@return integer | false src
function Framework.Server.GetPlayerFromIdentifier(identifier)
  if Config.Framework == "QBCore" then
    local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
    if not player then return false end
    return player.PlayerData.source
  elseif Config.Framework == "Qbox" then
    local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    if not player then return false end
    return player.PlayerData.source
  elseif Config.Framework == "ESX" then
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if not xPlayer then return false end
    return xPlayer.source
  end

  return false
end

-- 
-- Player Money
-- These functions now use the centralized Currencies system from sv-currencies.lua
--

---@param src integer
---@param type "cash" | "bank" | string Any registered currency ID
function Framework.Server.GetPlayerBalance(src, type)
  return Currencies.Server.GetBalance(src, type)
end

---@param src integer
---@param amount number
---@param account "cash" | "bank" | string Any registered currency ID
function Framework.Server.PlayerAddMoney(src, amount, account)
  account = account or "bank"
  return Currencies.Server.AddBalance(src, amount, account)
end

---@param src integer
---@param amount number
---@param account "cash" | "bank" | string Any registered currency ID
function Framework.Server.PlayerRemoveMoney(src, amount, account)
  account = account or "bank"
  return Currencies.Server.RemoveBalance(src, amount, account)
end

--
-- Offline Player Money (for finance processing when player is offline)
-- These now use the centralized Currencies system from sv-currencies.lua
--

---Get a player's balance from the database (offline)
---@param identifier string Player identifier (citizenid for QB, identifier for ESX)
---@param currencyId? string Currency ID (defaults to "bank")
---@return number balance
function Framework.Server.GetPlayerBalanceOffline(identifier, currencyId)
  currencyId = currencyId or "bank"
  return Currencies.Server.GetBalanceOffline(identifier, currencyId)
end

---Remove money from a player's balance in the database (offline)
---@param identifier string Player identifier (citizenid for QB, identifier for ESX)
---@param amount number Amount to remove
---@param currencyId? string Currency ID (defaults to "bank")
---@return boolean success
function Framework.Server.PlayerRemoveMoneyOffline(identifier, amount, currencyId)
  currencyId = currencyId or "bank"
  return Currencies.Server.RemoveBalanceOffline(identifier, amount, currencyId)
end

--
-- Player Job
--

---Validate a job name and return its ranks
---@param jobName string
---@return boolean isValid
---@return {rank: number, label: string}[]? ranks
function Framework.Server.IsValidJob(jobName)
  if not jobName or jobName == "" then return false, nil end

  if Config.Framework == "QBCore" then
    local job = QBCore.Shared.Jobs[jobName]
    if not job then return false, nil end

    local ranks = {}
    for gradeStr, gradeData in pairs(job.grades) do
      ranks[#ranks + 1] = {
        rank = tonumber(gradeStr),
        label = gradeData.name
      }
    end
    table.sort(ranks, function(a, b) return a.rank < b.rank end)
    return true, ranks
  elseif Config.Framework == "Qbox" then
    local jobs = exports.qbx_core:GetJobs()
    local job = jobs[jobName]
    if not job then return false, nil end

    local ranks = {}
    for gradeStr, gradeData in pairs(job.grades) do
      ranks[#ranks + 1] = {
        rank = tonumber(gradeStr),
        label = gradeData.name
      }
    end
    table.sort(ranks, function(a, b) return a.rank < b.rank end)
    return true, ranks
  elseif Config.Framework == "ESX" then
    local jobs = ESX.GetJobs()
    local job = jobs[jobName]
    if not job then return false, nil end

    local ranks = {}
    for _, gradeData in pairs(job.grades) do
      ranks[#ranks + 1] = {
        rank = gradeData.grade,
        label = gradeData.label
      }
    end
    table.sort(ranks, function(a, b) return a.rank < b.rank end)
    return true, ranks
  end

  return false, nil
end

lib.callback.register("jg-dealerships:server:validate-job", function(_, jobName)
  local isValid, ranks = Framework.Server.IsValidJob(jobName)
  return {isValid = isValid, ranks = ranks or {}}
end)

---Validate a gang name and return its ranks
---@param gangName string
---@return boolean isValid
---@return {rank: number, label: string}[]? ranks
function Framework.Server.IsValidGang(gangName)
  if not gangName or gangName == "" then return false, nil end

  if Config.Framework == "QBCore" then
    local gang = QBCore.Shared.Gangs[gangName]
    if not gang then return false, nil end

    local ranks = {}
    for gradeStr, gradeData in pairs(gang.grades) do
      ranks[#ranks + 1] = {
        rank = tonumber(gradeStr),
        label = gradeData.name
      }
    end
    table.sort(ranks, function(a, b) return a.rank < b.rank end)
    return true, ranks
  elseif Config.Framework == "Qbox" then
    local gangs = exports.qbx_core:GetGangs()
    local gang = gangs[gangName]
    if not gang then return false, nil end

    local ranks = {}
    for gradeStr, gradeData in pairs(gang.grades) do
      ranks[#ranks + 1] = {
        rank = tonumber(gradeStr),
        label = gradeData.name
      }
    end
    table.sort(ranks, function(a, b) return a.rank < b.rank end)
    return true, ranks
  elseif Config.Framework == "ESX" then
    -- ESX does not have native gang support, return false
    return false, nil
  end

  return false, nil
end

lib.callback.register("jg-dealerships:server:validate-gang", function(_, gangName)
  local isValid, ranks = Framework.Server.IsValidGang(gangName)
  return {isValid = isValid, ranks = ranks or {}}
end)

--
-- Player Job
--

---@param src integer
---@return {name: string, label: string, grade: number, gradeLabel: string} | {}
function Framework.Server.GetPlayerJob(src)
  local player = Framework.Server.GetPlayer(src)
  if not player then return {} end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return {
      name = player.PlayerData.job.name,
      label = player.PlayerData.job.label,
      grade = player.PlayerData.job.grade.level,
      gradeLabel = player.PlayerData.job.grade.name
    }
  elseif Config.Framework == "ESX" then
    return {
      name = player.getJob().name,
      label = player.getJob().label,
      grade = player.getJob().grade,
      gradeLabel = player.getJob().grade_label
    }
  end

  return {}
end

---@param src integer
---@return {name: string, label: string, grade: number} | {}
function Framework.Server.GetPlayerGang(src)
  local player = Framework.Server.GetPlayer(src)
  if not player then return {} end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return {
      name = player.PlayerData.gang.name,
      label = player.PlayerData.gang.label,
      grade = player.PlayerData.gang.grade.level,
      gradeLabel = player.PlayerData.gang.grade.name
    }
  elseif Config.Framework == "ESX" then
    -- ESX does not natively support gangs
    return {}
  end

  return {}
end

---@param src integer
---@param job string
---@param rank number
function Framework.Server.PlayerSetJob(src, job, rank)
  local player = Framework.Server.GetPlayer(src)

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    player.Functions.SetJob(job, rank)
  elseif Config.Framework == "ESX" then
    player.setJob(job, rank)
  end
end

---@param identifier string
---@param job string
---@param rank number
function Framework.Server.PlayerSetJobOffline(identifier, job, rank)
  
  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    local jobsList = {}
    if Config.Framework == "QBCore" then jobsList = QBCore.Shared.Jobs
    elseif Config.Framework == "Qbox" then jobsList = exports.qbx_core:GetJobs() end
    
    if not jobsList[job] then return false end

    local jobData = {
      name = job,
      label = jobsList[job].label,
      onduty = jobsList[job].defaultDuty,
      type = jobsList[job].type or "none",
      grade = {
        name = "No Grades",
        level = 0,
      },
      payment = 30,
      isboss = false
    }
    if jobsList[job].grades[tostring(rank)] then
      local jobgrade = jobsList[job].grades[tostring(rank)]
      jobData.grade = {}
      jobData.grade.name = jobgrade.name
      jobData.grade.level = rank
      jobData.payment = jobgrade.payment or 30
      jobData.isboss = jobgrade.isboss or false
    end

    MySQL.update.await("UPDATE players SET job = ? WHERE citizenid = ?", {json.encode(jobData), identifier})
  elseif Config.Framework == "ESX" then
    MySQL.update.await("UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?", {job, rank, identifier})
  end
end

-- ---------

function Framework.Server.GetPlayers()
  local players = {}
  if Config.Framework == "QBCore" then
    players = QBCore.Functions.GetQBPlayers()
  elseif Config.Framework == "Qbox" then
    players = exports.qbx_core:GetQBPlayers()
  elseif Config.Framework == "ESX" then
    players = ESX.GetExtendedPlayers()
  end

  for id, player in pairs(players) do
    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      players[id].player_id = player.PlayerData.source
    elseif Config.Framework == "ESX" then
      players[id].player_id = player.source
    end
  end

  return players
end

function Framework.Server.GetJobs()
  if Config.Framework == "QBCore" then
    return QBCore.Shared.Jobs
  elseif Config.Framework == "Qbox" then
    return exports.qbx_core:GetJobs()
  elseif Config.Framework == "ESX" then
    return ESX.GetJobs()
  end
end

--
-- ti_fuel
--

RegisterNetEvent("jg-dealerships:server:save-ti-fuel-type", function(plate, type)
  MySQL.query.await("ALTER TABLE " .. Framework.VehiclesTable .. " ADD COLUMN IF NOT EXISTS `ti_fuel_type` VARCHAR(100) DEFAULT '';")
  MySQL.update.await("UPDATE " .. Framework.VehiclesTable .. " SET ti_fuel_type = ? WHERE plate = ?", {type, plate});
end)

lib.callback.register("jg-dealerships:server:get-ti-fuel-type", function(src, plate)
  MySQL.query.await("ALTER TABLE " .. Framework.VehiclesTable .. " ADD COLUMN IF NOT EXISTS `ti_fuel_type` VARCHAR(100) DEFAULT '';")
  return MySQL.scalar.await("SELECT ti_fuel_type FROM  " .. Framework.VehiclesTable .. " WHERE plate = ?", {plate}) or false
end)

--
-- Brazzers-FakePlates
--

if GetResourceState("brazzers-fakeplates") == "started" then
  lib.callback.register("jg-dealerships:server:brazzers-get-plate-from-fakeplate", function(_, fakeplate)
    local result = MySQL.scalar.await("SELECT plate FROM player_vehicles WHERE fakeplate = ?", {fakeplate})
    if result then return result end
    return false
  end)

  lib.callback.register("jg-dealerships:server:brazzers-get-fakeplate-from-plate", function(_, plate)
    local result = MySQL.scalar.await("SELECT fakeplate FROM player_vehicles WHERE plate = ?", {plate})
    if result then return result end
    return false
  end)
end
