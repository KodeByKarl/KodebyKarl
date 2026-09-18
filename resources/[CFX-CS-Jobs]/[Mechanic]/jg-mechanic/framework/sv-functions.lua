function Framework.Server.Notify(src, msg, type)
  TriggerClientEvent("jg-mechanic:client:notify", src, msg, type, 5000)
end

function Framework.Server.IsAdmin(src)
  return IsPlayerAceAllowed(tostring(src), "command") or false
end

lib.callback.register("jg-mechanic:server:is-admin", function(src)
  return Framework.Server.IsAdmin(src)
end)

function Framework.Server.GetPlate(vehicle)
  local plate = GetVehicleNumberPlateText(vehicle)
  if not plate or plate == "" then return false end

  if GetResourceState("brazzers-fakeplates") == "started" then
    local result = MySQL.scalar.await("SELECT plate FROM player_vehicles WHERE fakeplate = ?", {plate})
    if result then return result end
  end

  local trPlate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
  return trPlate
end

if GetResourceState("brazzers-fakeplates") == "started" then
  lib.callback.register("jg-mechanic:server:brazzers-get-plate-from-fakeplate", function(_, fakeplate)
    local result = MySQL.scalar.await("SELECT plate FROM player_vehicles WHERE fakeplate = ?", {fakeplate})
    if result then return result end
    return false
  end)
end

function Framework.Server.RegisterUsableItem(itemName, cb)
  if (Config.Inventory == "auto" and GetResourceState("ox_inventory") == "started") or Config.Inventory == "ox_inventory" then
  elseif (Config.Inventory == "auto" and GetResourceState("qs-inventory") == "started") or Config.Inventory == "qs-inventory" then
    exports["qs-inventory"]:CreateUsableItem(itemName, cb)
  elseif Config.Framework == "QBCore" or Config.Inventory == "qb-inventory" then
    QBCore.Functions.CreateUseableItem(itemName, cb)
  elseif Config.Framework == "ESX" or Config.Inventory == "esx_inventory" then
    ESX.RegisterUsableItem(itemName, cb)
  end
end

local function inventoryItemCount(src, itemName)
  if (Config.Inventory == "auto" and GetResourceState("ox_inventory") == "started") or Config.Inventory == "ox_inventory" then
    return exports.ox_inventory:GetItem(src, itemName, nil, true) or 0
  elseif (Config.Inventory == "auto" and GetResourceState("qs-inventory") == "started") or Config.Inventory == "qs-inventory" then
    return exports["qs-inventory"]:GetItemTotalAmount(src, itemName) or 0
  elseif (Config.Inventory == "auto" and GetResourceState("codem-inventory") == "started") or Config.Inventory == "codem-inventory" then
    return exports["codem-inventory"]:GetItemsTotalAmount(src, itemName) or 0
  elseif Config.Framework == "QBCore" or Config.Inventory == "qb-inventory" then
    local Player = Framework.Server.GetPlayer(src)
    return Player and Player.Functions.GetItemByName(itemName)?.amount or 0
  elseif Config.Framework == "ESX" or Config.Inventory == "esx_inventory" then
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and xPlayer.getInventoryItem(itemName)?.count or 0
  end
  return 0
end

local function resolveRepairKitItem(src, qty)
  qty = qty or 1
  if inventoryItemCount(src, "repairkit") >= qty then return "repairkit" end
  if inventoryItemCount(src, "repair_kit") >= qty then return "repair_kit" end
  return nil
end

function Framework.Server.HasItem(src, itemName, qty)
  qty = qty or 1

  if itemName == "repair_kit" or itemName == "repairkit" then
    if resolveRepairKitItem(src, qty) then return true end
    Framework.Server.Notify(src, Locale.itemNotInInventory:format(qty, Locale.repair_kit or "Repair Kit"), "error")
    return false
  end

  local itemCount = inventoryItemCount(src, itemName)
  if not itemCount or itemCount < qty then
    Framework.Server.Notify(src, Locale.itemNotInInventory:format(qty, Locale[itemName] or itemName), "error")
    return false
  end
  
  return true
end

lib.callback.register("jg-mechanic:server:has-item", Framework.Server.HasItem)

function Framework.Server.GiveItem(src, itemName, qty)
  qty = qty or 1

  if (Config.Inventory == "auto" and GetResourceState("ox_inventory") == "started") or Config.Inventory == "ox_inventory" then
    local added = exports.ox_inventory:AddItem(src, itemName, qty)
    if not added then return false end
  elseif (Config.Inventory == "auto" and GetResourceState("qs-inventory") == "started") or Config.Inventory == "qs-inventory" then
    local added = exports["qs-inventory"]:AddItem(src, itemName, qty)
    if not added then return false end
  elseif (Config.Inventory == "auto" and GetResourceState("codem-inventory") == "started") or Config.Inventory == "codem-inventory" then
    local added = exports["codem-inventory"]:AddItem(src, itemName, qty)
    if not added then return false end
  elseif Config.Framework == "QBCore" or Config.Inventory == "qb-inventory" then
    local Player = Framework.Server.GetPlayer(src)
    local added = Player.Functions.AddItem(itemName, qty)
    if not added then return false end
  elseif Config.Framework == "ESX" or Config.Inventory == "esx_inventory" then
    local xPlayer = ESX.GetPlayerFromId(src)
    xPlayer.addInventoryItem(itemName, qty)
  else
    return false
  end

  return true
end

function Framework.Server.RemoveItem(src, itemName, qty)
  qty = qty or 1

  if itemName == "repair_kit" or itemName == "repairkit" then
    local ownedKit = resolveRepairKitItem(src, qty)
    if not ownedKit then
      Framework.Server.Notify(src, Locale.itemNotInInventory:format(qty, Locale.repair_kit or "Repair Kit"), "error")
      return false
    end
    itemName = ownedKit
  else
    local hasItem = Framework.Server.HasItem(src, itemName, qty)
    if not hasItem then return false end
  end

  if (Config.Inventory == "auto" and GetResourceState("ox_inventory") == "started") or Config.Inventory == "ox_inventory" then
    local removed = exports.ox_inventory:RemoveItem(src, itemName, qty)
    if not removed then return false end
  elseif (Config.Inventory == "auto" and GetResourceState("qs-inventory") == "started") or Config.Inventory == "qs-inventory" then
    local removed = exports["qs-inventory"]:RemoveItem(src, itemName, qty)
    if not removed then return false end
  elseif (Config.Inventory == "auto" and GetResourceState("codem-inventory") == "started") or Config.Inventory == "codem-inventory" then
    local removed = exports["codem-inventory"]:RemoveItem(src, itemName, qty)
    if not removed then return false end
  elseif Config.Framework == "QBCore" or Config.Inventory == "qb-inventory" then
    local Player = Framework.Server.GetPlayer(src)
    local removed = Player.Functions.RemoveItem(itemName, qty)
    if not removed then return false end
  elseif Config.Framework == "ESX" or Config.Inventory == "esx_inventory" then
    local xPlayer = ESX.GetPlayerFromId(src)
    xPlayer.removeInventoryItem(itemName, qty)
  else
    return false
  end

  return true
end

RegisterNetEvent("jg-mechanic:server:remove-item", function(...)
  Framework.Server.RemoveItem(source, ...)
end)

function Framework.Server.GetPlayer(src)
  if Config.Framework == "QBCore" then
    return QBCore.Functions.GetPlayer(src)
  elseif Config.Framework == "Qbox" then
    return exports.qbx_core:GetPlayer(src)
  elseif Config.Framework == "ESX" then
    return ESX.GetPlayerFromId(src)
  end
end

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

function Framework.Server.GetPlayerIdentifier(src)
  local player = Framework.Server.GetPlayer(src)
  if not player then return false end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return player.PlayerData.citizenid
  elseif Config.Framework == "ESX" then
    return player.getIdentifier()
  end
end

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

function Framework.Server.GetPlayerBalance(src, type)
  local player = Framework.Server.GetPlayer(src)
  if not player then return 0 end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return player.PlayerData.money[type]
  elseif Config.Framework == "ESX" then
    if type == "cash" then type = "money" end

    for _, acc in pairs(player.getAccounts()) do
      if acc.name == type then
        return acc.money
      end
    end

    return 0
  end
end

function Framework.Server.PlayerAddMoney(src, amount, account)
  local player = Framework.Server.GetPlayer(src)
  account = account or "bank"

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    player.Functions.AddMoney(account, round(amount, 0))
  elseif Config.Framework == "ESX" then
    if account == "cash" then account = "money" end
    player.addAccountMoney(account, round(amount, 0))
  end
end

function Framework.Server.PlayerRemoveMoney(src, amount, account)
  local player = Framework.Server.GetPlayer(src)
  account = account or "bank"

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    player.Functions.RemoveMoney(account, round(amount, 0))
  elseif Config.Framework == "ESX" then
    if account == "cash" then account = "money" end
    player.removeAccountMoney(account, round(amount, 0))
  end
end

function Framework.Server.PlayerAddMoneyOffline(identifier, amount)
  local src = Framework.Server.GetPlayerFromIdentifier(identifier)
  if src then
    return Framework.Server.PlayerAddMoney(src, amount, "bank")
  end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    local money = MySQL.scalar.await("SELECT money FROM players WHERE citizenid = ?", {
      identifier
    })
    if not money then return false end
    
    local moneyData = json.decode(money)
    moneyData.bank = (moneyData.bank or 0) + amount

    MySQL.update.await("UPDATE players SET money = ? WHERE citizenid = ?", {
      json.encode(moneyData), identifier
    })
  elseif Config.Framework == "ESX" then
    local accounts = MySQL.scalar.await("SELECT accounts FROM users WHERE identifier = ?", {
      identifier
    })
    if not accounts then return false end
    
    local accountsData = json.decode(accounts)
    accountsData.bank = (accountsData.bank or 0) + amount

    MySQL.update.await("UPDATE users SET accounts = ? WHERE identifier = ?", {
      json.encode(accountsData), identifier
    })
  end
end

function Framework.Server.GetPlayerJob(src)
  local player = Framework.Server.GetPlayer(src)
  if not player then return {} end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return {
      name = player.PlayerData.job.name,
      label = player.PlayerData.job.label,
      grade = player.PlayerData.job.grade.level
    }
  elseif Config.Framework == "ESX" then
    return {
      name = player.getJob().name,
      label = player.getJob().label,
      grade = player.getJob().grade
    }
  end

  return {}
end

function Framework.Server.PlayerSetJob(src, job, role)
  local player = Framework.Server.GetPlayer(src)

  local rank = role
  if role == "mechanic" then rank = 1 end
  if role == "manager" then rank = 2 end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    player.Functions.SetJob(job, rank)
  elseif Config.Framework == "ESX" then
    player.setJob(job, rank)
  end
end

function Framework.Server.PlayerSetJobOffline(identifier, job, role)
  local rank = role
  if role == "mechanic" then rank = 1 end
  if role == "manager" then rank = 2 end
  
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

function Framework.Server.PlayerToggleJobDuty(src, toggle)
  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    local Player = Framework.Server.GetPlayer(src)
    if Player.PlayerData.job.onduty then
      Player.Functions.SetJobDuty(false)
    else
      Player.Functions.SetJobDuty(true)
    end
    TriggerClientEvent("QBCore:Client:SetDuty", src, Player.PlayerData.job.onduty)
  elseif Config.Framework == "ESX" then
  end
end

lib.callback.register("jg-mechanic:server:toggle-duty", function(src, toggle)
  Framework.Server.PlayerToggleJobDuty(src, toggle)
end)

local usingNewQBBanking = GetResourceState("qb-banking") == "started" and tonumber(string.sub(GetResourceMetadata("qb-banking", "version", 0), 1, 3)) >= 2

function Framework.Server.GetSocietyBalance(society, societyType)
  if Config.SocietyBanking == "cfx-keydi-society"
    or (Config.SocietyBanking == "auto" and GetResourceState("cfx-keydi-society") == "started")
  then
    return exports["cfx-keydi-society"]:GetMoney(society) or 0
  elseif Config.SocietyBanking == "okokBanking" then
    return exports["okokBanking"]:GetAccount(society)
  elseif Config.SocietyBanking == "fd_banking" then
    return exports.fd_banking:GetAccount(society)
  elseif Config.SocietyBanking == "tgg-banking" then
    return exports["tgg-banking"]:GetSocietyAccountMoney(society)
  elseif (Config.Framework == "Qbox" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "Renewed-Banking" then
    return exports["Renewed-Banking"]:getAccountMoney(society)
  elseif (Config.Framework == "QBCore" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "qb-banking" or Config.SocietyBanking == "qb-management" then
    if Config.SocietyBanking == "qb-banking" or usingNewQBBanking then
      return exports["qb-banking"]:GetAccountBalance(society)
    else
      if societyType == "job" then
        return exports["qb-management"]:GetAccount(society)
      elseif societyType == "gang" then
        return exports["qb-management"]:GetGangAccount(society)
      end
    end
  elseif (Config.Framework == "ESX" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "esx_addonaccount" then
    local balance = promise.new()
    local settled = false

    local function resolveBalance(amount)
      if settled then return end
      settled = true
      balance:resolve(tonumber(amount) or 0)
    end

    -- Missing society / addonaccount must never hang Citizen.Await forever
    -- (that freezes jg-mechanic employees mid-open of the mods menu).
    SetTimeout(3000, function()
      resolveBalance(0)
    end)

    TriggerEvent("esx_society:getSociety", society, function(data)
      if not data or not data.account then
        return resolveBalance(0)
      end

      TriggerEvent("esx_addonaccount:getSharedAccount", data.account, function(account)
        if not account then
          return resolveBalance(0)
        end
        return resolveBalance(account.money)
      end)
    end)

    return Citizen.Await(balance)
  end

  return 0
end

lib.callback.register("jg-mechanic:server:get-society-balance", function(_, society, type)
  return Framework.Server.GetSocietyBalance(society, type)
end)

function Framework.Server.PayIntoSocietyFund(societyName, societyType, amount)
  if Config.SocietyBanking == "cfx-keydi-society"
    or (Config.SocietyBanking == "auto" and GetResourceState("cfx-keydi-society") == "started")
  then
    exports["cfx-keydi-society"]:AddMoney(societyName, amount)
  elseif Config.SocietyBanking == "okokBanking" then
    exports["okokBanking"]:AddMoney(societyName, amount)
  elseif Config.SocietyBanking == "fd_banking" then
    exports.fd_banking:AddMoney(societyName, amount)
  elseif Config.SocietyBanking == "tgg-banking" then
    exports["tgg-banking"]:AddSocietyMoney(societyName, amount)
  elseif (Config.Framework == "Qbox" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "Renewed-Banking" then
    exports["Renewed-Banking"]:addAccountMoney(societyName, amount)
  elseif (Config.Framework == "QBCore" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "qb-banking" or Config.SocietyBanking == "qb-management" then
    if Config.SocietyBanking == "qb-banking" or usingNewQBBanking then
      exports["qb-banking"]:AddMoney(societyName, amount)
    else
      if societyType == "job" then
        exports["qb-management"]:AddMoney(societyName, amount)
      elseif societyType == "gang" then
        exports["qb-management"]:AddGangMoney(societyName, amount)
      end
    end
  elseif (Config.Framework == "ESX" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "esx_addonaccount" then
    TriggerEvent("esx_society:getSociety", societyName, function(society)
      TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
        account.addMoney(amount)
      end)
    end)
  end
end

function Framework.Server.RemoveFromSocietyFund(societyName, societyType, amount)
  if Config.SocietyBanking == "cfx-keydi-society"
    or (Config.SocietyBanking == "auto" and GetResourceState("cfx-keydi-society") == "started")
  then
    exports["cfx-keydi-society"]:RemoveMoney(societyName, amount)
  elseif Config.SocietyBanking == "okokBanking" then
    exports["okokBanking"]:RemoveMoney(societyName, amount)
  elseif Config.SocietyBanking == "fd_banking" then
    exports.fd_banking:RemoveMoney(societyName, amount)
  elseif Config.SocietyBanking == "tgg-banking" then
    exports["tgg-banking"]:RemoveSocietyMoney(societyName, amount)
  elseif (Config.Framework == "Qbox" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "Renewed-Banking" then
    exports["Renewed-Banking"]:removeAccountMoney(societyName, amount)
  elseif (Config.Framework == "QBCore" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "qb-banking" or Config.SocietyBanking == "qb-management" then
    if Config.SocietyBanking == "qb-banking" or usingNewQBBanking then
      exports["qb-banking"]:RemoveMoney(societyName, amount)
    else
      if societyType == "job" then
        exports["qb-management"]:RemoveMoney(societyName, amount)
      elseif societyType == "gang" then
        exports["qb-management"]:RemoveGangMoney(societyName, amount)
      end
    end
  elseif (Config.Framework == "ESX" and Config.SocietyBanking == "auto") or Config.SocietyBanking == "esx_addonaccount" then
    TriggerEvent("esx_society:getSociety", societyName, function(society)
      TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
        account.removeMoney(amount)
      end)
    end)
  end
end

function Framework.Server.OpenInventoryStash(src, stashId, stashName)  
  if (Config.Inventory == "auto" and GetResourceState("qb-inventory") == "started") or Config.Inventory == "qb-inventory" then
    exports["qb-inventory"]:OpenInventory(src, stashId, { label = stashName or stashId or "Stash", maxweight = 400000, slots = 50 })
  else
    error("Error: Unsupported system set in Config.")
  end
end

RegisterServerEvent("jg-mechanic:server:open-inventory-stash", function(stashId, stashName)
  local src = source
  Framework.Server.OpenInventoryStash(src, stashId, stashName)
end)

lib.callback.register("jg-mechanic:server:dealerships-vehicle-value", function(src, vehicleHash)
  if not vehicleHash or GetResourceState("jg-dealerships") ~= "started" then return false end
  
  local price = MySQL.scalar.await("SELECT price FROM dealership_vehicles WHERE hashkey = ?", {vehicleHash})

  if not price then return false end
  return price
end)

lib.callback.register("jg-mechanic:server:save-vehicle-props", function(src, plate, props)
  if not plate or not props or type(props) ~= "table" then
    return false
  end

  MySQL.update.await(
    "UPDATE " .. Framework.VehiclesTable .. " SET " .. Framework.VehProps .. " = ? WHERE plate = ?",
    { json.encode(props), plate }
  )

  return true
end)
