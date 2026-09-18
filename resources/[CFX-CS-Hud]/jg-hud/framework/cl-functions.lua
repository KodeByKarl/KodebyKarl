Framework.CachedPlayerData = {
  job = nil,
  gang = nil,
  cash = nil,
  bank = nil,
  dirtyMoney = nil,
  hunger = 100,
  thirst = 100,
  stress = 0,
  micRange = 2,
  radioActive = false,
  voiceModes = 3,
}

---@param vehicle integer
---@return number fuelLevel
function Framework.Client.VehicleGetFuel(vehicle)
  if not DoesEntityExist(vehicle) then return 0 end

  if (Config.FuelSystem == "LegacyFuel" or Config.FuelSystem == "lc_fuel" or Config.FuelSystem == "ps-fuel" or Config.FuelSystem == "lj-fuel" or Config.FuelSystem == "cdn-fuel" or Config.FuelSystem == "hyon_gas_station" or Config.FuelSystem == "okokGasStation" or Config.FuelSystem == "nd_fuel" or Config.FuelSystem == "myFuel") then
    return exports[Config.FuelSystem]:GetFuel(vehicle)
  elseif Config.FuelSystem == "ti_fuel" then
    local level = exports["ti_fuel"]:getFuel(vehicle)
    return level
  elseif Config.FuelSystem == "ox_fuel" or Config.FuelSystem == "Renewed-Fuel" then
    return GetVehicleFuelLevel(vehicle)
  elseif Config.FuelSystem == "rcore_fuel" then
    return exports.rcore_fuel:GetVehicleFuelPercentage(vehicle)
  else
    return 100 -- or set up custom fuel system here...
  end
end

---Toggles the engine, this is used in the keybind & in the vehicle control panel
---@param vehicle integer
---@param on boolean on or off
function Framework.Client.ToggleEngine(vehicle, on)
  -- !! Consider adding a key script check here - to disallow enabling the engine if no keys are present
  SetVehicleEngineOn(vehicle, on, false, true)
end

---Code to run when seatbelt is toggled
---Please note; you need Config.UseCustomSeatbeltIntegration = true for this to take effect!
---@param vehicle integer
---@param seatbeltOn boolean true = seatbelt on, false = seatbelt off
function Framework.Client.ToggleSeatbelt(vehicle, seatbeltOn)
  if GetResourceState("jim-mechanic") == "started" then
    if (seatbeltOn and not exports["jim-mechanic"]:seatBeltOn()) or (seatbeltOn and exports["jim-mechanic"]:seatBeltOn()) then
      TriggerEvent("jim-mechanic:client:ToggleSeatbelt")
    end
  end

  -- ...or add another custom seatbelt integration here!
end

---@return table | false playerData
function Framework.Client.GetPlayerData()
  if Config.Framework == "QBCore" then
    ---@diagnostic disable-next-line: undefined-field
    return QBCore.Functions.GetPlayerData()
  elseif Config.Framework == "Qbox" then
    return exports.qbx_core:GetPlayerData()
  elseif Config.Framework == "ESX" then
    ---@diagnostic disable-next-line: undefined-field
    return ESX.GetPlayerData()
  end

  return false
end

---@return string?
function Framework.Client.GetPlayerJob()
  local player = Framework.Client.GetPlayerData()
  if not player or not player.job then return nil end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    return string.format("%s (%s)", player.job.label, player.job.grade.name)
  elseif Config.Framework == "ESX" then
    return string.format("%s (%s)", player.job.label, player.job.grade_label)  
  end

  return nil
end

---@return string?
function Framework.Client.GetPlayerGang()
  if GetResourceState("rcore_gangs") == "started" then
    local gang = exports.rcore_gangs:GetPlayerGang()
    if not gang then return "No Gang" end

    return string.format('%s (%s)', gang.tag, gang.rank)
  end

  local player = Framework.Client.GetPlayerData()
  if not player then return "No Gang" end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    if not player.gang then return "No Gang" end
    local label = player.gang.label or "No Gang"
    local gradeName = (player.gang.grade and player.gang.grade.name) or ""
    if player.gang.name == "none" or label == "No Gang" then return "No Gang" end
    return (gradeName ~= "" and gradeName ~= "none") and string.format("%s (%s)", label, gradeName) or label
  elseif Config.Framework == "ESX" then
    if not player.gang then return "No Gang" end
    local label = player.gang.label or "No Gang"
    local gradeLabel = player.gang.grade_label or ""
    if player.gang.name == "none" or label == "No Gang" then return "No Gang" end
    return (gradeLabel ~= "" and gradeLabel ~= "No Grade" and gradeLabel ~= "none") and string.format("%s (%s)", label, gradeLabel) or label
  end

  return "No Gang"
end

---@return boolean dead
function Framework.Client.IsPlayerDead()
  if Config.Framework == "QBCore" then
    local player = Framework.Client.GetPlayerData()
    if not player then return false end

    if player.metadata?.isdead or player.metadata?.inlaststand then
      return true
    end
  elseif Config.Framework == "Qbox" then
    return LocalPlayer.state.isDead
  elseif Config.Framework == "ESX" then
    return IsEntityDead(cache.ped)
  end

  return false
end

---@param type "cash" | "bank" | "money" | "dirtyMoney" | "black_money"
---@return number? balance
function Framework.Client.GetBalance(type)
  if Config.Framework == "QBCore" then
    ---@diagnostic disable-next-line: undefined-field
    local playerData = QBCore.Functions.GetPlayerData()

    if type == "dirtyMoney" then
      -- Fetch "markedbills" from inventory
      local dirty = 0
      for _, item in pairs(playerData.items or {}) do
        if item.name == "markedbills" then
          if item.info and item.info.worth then
            dirty = dirty + item.info.worth
          end
        end
      end
      return dirty
    end
    
    return playerData?.money?[type] or 0
  elseif Config.Framework == "Qbox" then
    if type == "dirtyMoney" and GetResourceState("ox_inventory") == "started" then
      -- Fetch dirty_money from ox_inv
      return exports.ox_inventory:GetItemCount("black_money") or 0
    end
 
    return exports.qbx_core:GetPlayerData()?.money?[type] or 0
  elseif Config.Framework == "ESX" then
    if type == "cash" then type = "money" end
    if type == "dirtyMoney" then type = "black_money" end
 
    ---@diagnostic disable-next-line: undefined-field
    local playerData = ESX.GetPlayerData()
    if not playerData then return 0 end
    
    for i, acc in pairs(playerData?.accounts or {}) do
      if acc.name == type then
        return acc.money or 0
      end
    end

    return 0
  end

  return nil
end

---@param vehicle integer
function Framework.Client.GetVehicleMileageInKm(vehicle)
  if not vehicle or vehicle == 0 then return false end

  -- t1ger_mechanic integration
  if GetResourceState("t1ger_mechanic") == "started" then
    return exports["t1ger_mechanic"]:GetVehicleMileage(vehicle)
  end

  -- jim-mechanic integration
  if GetResourceState("jim-mechanic") == "started" then
    local plate = GetVehicleNumberPlateText(vehicle)
    return exports["jim-mechanic"]:GetMilage(plate)
  end

  -- This is for jg-vehiclemileage (jg-mechanic), as it's stored in a statebag
  -- If you're using a different vehicle mileage script, you can add the export for it here! :)
  return Entity(vehicle).state.vehicleMileage or 0
end

---@param km number
---@return number
function Framework.Client.ConvertKmToMiles(km)
  return km * 0.621371
end

function Framework.Client.ConvertSpeed(speed, unit)
  if unit == "mph" then return speed * 2.236936 end
  if unit == "kph" then return speed * 3.6 end
  return speed
end

function Framework.Client.ConvertDistance(dist, unit)
  if unit == "meters" then return dist * 1 end
  if unit == "feet" then return dist * 3.28084 end
  return dist
end

--
-- From this point on, it's setting up framework event listeners
--

local function updateCachedData(player)
  if Config.ShowComponents.job then
    Framework.CachedPlayerData.job = Framework.Client.GetPlayerJob()
  end
  if Config.ShowComponents.gang then
    Framework.CachedPlayerData.gang = Framework.Client.GetPlayerGang()
  end
  if Config.ShowComponents.cashBalance then
    Framework.CachedPlayerData.cash = Framework.Client.GetBalance("cash")
  end
  if Config.ShowComponents.bankBalance then
    Framework.CachedPlayerData.bank = Framework.Client.GetBalance("bank")
  end
  if Config.ShowComponents.dirtyMoneyBalance then
    Framework.CachedPlayerData.dirtyMoney = Framework.Client.GetBalance("dirtyMoney")
  end
  
  if Config.Framework == "QBCore" and player then
    Framework.CachedPlayerData.hunger = lib.math.clamp(player.metadata?.hunger or 0, 0, 100)
    Framework.CachedPlayerData.thirst = lib.math.clamp(player.metadata?.thirst or 0, 0, 100)
    Framework.CachedPlayerData.stress = lib.math.clamp(player.metadata?.stress or Framework.CachedPlayerData.stress or 0, 0, 100)
  elseif Config.Framework == "ESX" and player then
    local status = player.metadata and player.metadata.status or nil
    local h = (status and status.hunger) or LocalPlayer.state.hunger or Framework.CachedPlayerData.hunger or 100
    local t = (status and status.thirst) or LocalPlayer.state.thirst or Framework.CachedPlayerData.thirst or 100
    local s = (status and status.stress) or LocalPlayer.state.stress or Framework.CachedPlayerData.stress or 0
    Framework.CachedPlayerData.hunger = lib.math.clamp(tonumber(h) or 100, 0, 100)
    Framework.CachedPlayerData.thirst = lib.math.clamp(tonumber(t) or 100, 0, 100)
    Framework.CachedPlayerData.stress = lib.math.clamp(tonumber(s) or 0, 0, 100)
  end
end

local isBalancePollingThreadRunning = false
local function startBalancePollingThread()
  if isBalancePollingThreadRunning then return end
  if not (Config.ShowComponents.cashBalance or Config.ShowComponents.bankBalance or Config.ShowComponents.dirtyMoneyBalance) then return end

  isBalancePollingThreadRunning = true

  CreateThread(function()
    while IsHudRunning do
      if Config.ShowComponents.cashBalance then
        Framework.CachedPlayerData.cash = Framework.Client.GetBalance("cash")
      end
      if Config.ShowComponents.bankBalance then
        Framework.CachedPlayerData.bank = Framework.Client.GetBalance("bank")
      end
      if Config.ShowComponents.dirtyMoneyBalance then
        Framework.CachedPlayerData.dirtyMoney = Framework.Client.GetBalance("dirtyMoney")
      end

      Wait(1000)
    end

    isBalancePollingThreadRunning = false
  end)
end

function Framework.Client.SetupPlayerLoginListeners()
  if Config.Framework == "QBCore" then
    RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
      LocalPlayer.state:set("jgHudPlayerLoggedIn", true)
      updateCachedData(Framework.Client.GetPlayerData())
    end)

    RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
      LocalPlayer.state:set("jgHudPlayerLoggedIn", false)
    end)
    
  elseif Config.Framework == "Qbox" then
    AddStateBagChangeHandler("isLoggedIn", ("player:%s"):format(cache.serverId), function(_, _, loggedIn)
      LocalPlayer.state:set("jgHudPlayerLoggedIn", loggedIn)
    end)
    
  elseif Config.Framework == "ESX" then
    local function onPlayerLoad()
      lib.waitFor(function()
        return Framework.Client.GetPlayerData() and cache.ped
      end, "Ped has not loaded or GetPlayerData returned false (waited 30 seconds)", 30000)

      LocalPlayer.state:set("jgHudPlayerLoggedIn", true)
      Framework.CachedPlayerData.job = Framework.Client.GetPlayerJob()
    end
    
    RegisterNetEvent("esx:playerLoaded", function()
      onPlayerLoad()
      if Config.ShowComponents.gang then
        Framework.CachedPlayerData.gang = Framework.Client.GetPlayerGang()
      end
    end)

    RegisterNetEvent("esx:onPlayerSpawn", function()
      onPlayerLoad()
      if Config.ShowComponents.gang then
        Framework.CachedPlayerData.gang = Framework.Client.GetPlayerGang()
      end
    end)

    RegisterNetEvent("esx:onPlayerLogout", function()
      LocalPlayer.state:set("jgHudPlayerLoggedIn", false)
    end)

  else
    -- No framework, just say they are already logged in.
    -- Or you can add your own system or exports here! Just update the 
    -- LocalPlayer jgHudPlayerLoggedIn true/false and everything will work!
    lib.waitFor(function()
      if cache.ped then
        LocalPlayer.state:set("jgHudPlayerLoggedIn", true)
        return true
      end
    end, "[Standalone] Ped never loaded in; could not login (waited 500 seconds)", 500000)
  end
end

-- Blame Scorpion for this
function Framework.Client.RefreshRcoreGangData()
  if GetResourceState("rcore_gangs") ~= "started" then return end
  
  SetTimeout(500, function()
    local gang = exports.rcore_gangs:GetPlayerGang()
    
    if not gang then
      Framework.CachedPlayerData.gang = nil
      return
    end
    
    Framework.CachedPlayerData.gang = string.format("%s (%s)", gang.tag, gang.rank)
  end)
end

function Framework.Client.CreateEventListeners()
  local state = LocalPlayer.state
  Framework.CachedPlayerData.hunger = lib.math.clamp(state.hunger or Framework.CachedPlayerData.hunger or 100, 0, 100)
  Framework.CachedPlayerData.thirst = lib.math.clamp(state.thirst or Framework.CachedPlayerData.thirst or 100, 0, 100)
  Framework.CachedPlayerData.stress = lib.math.clamp(state.stress or Framework.CachedPlayerData.stress or 0, 0, 100)

  if (Config.Framework == "ESX" or Config.Framework == "QBCore" or Config.Framework == "Qbox") and Framework.Client.GetPlayerData() then
    updateCachedData(Framework.Client.GetPlayerData())
  end
  startBalancePollingThread()

  if Config.Framework == "ESX" then
    RegisterNetEvent("es_extended:status:updateStatus", function(newHunger, newThirst, newStress)
      Framework.CachedPlayerData.hunger = lib.math.clamp(tonumber(newHunger) or 0, 0, 100)
      Framework.CachedPlayerData.thirst = lib.math.clamp(tonumber(newThirst) or 0, 0, 100)
      Framework.CachedPlayerData.stress = lib.math.clamp(tonumber(newStress) or 0, 0, 100)
    end)

    RegisterNetEvent("esx_status:onTick", function(data)
      local newHunger, newThirst
      for i = 1, #data do
        if data[i].name == "thirst" then newThirst = math.floor(data[i].percent)
        elseif data[i].name == "hunger" then newHunger = math.floor(data[i].percent) end
      end
      Framework.CachedPlayerData.hunger = lib.math.clamp(newHunger or 0, 0, 100)
      Framework.CachedPlayerData.thirst = lib.math.clamp(newThirst or 0, 0, 100)
    end)

    RegisterNetEvent("esx:setJob", function(job)
      Framework.CachedPlayerData.job = string.format("%s (%s)", job.label, job.grade_label)
    end)

    RegisterNetEvent("esx:setGang", function(gang)
      if Config.Debug then
        print(("[JG HUD Debug] esx:setGang fired - gang=%s, grade_label=%s"):format(
          tostring(gang and gang.label), tostring(gang and gang.grade_label)
        ))
      end

      if gang and gang.label then
        local label = gang.label or "No Gang"
        local gradeLabel = gang.grade_label or ""
        if gang.name == "none" or label == "No Gang" then
          Framework.CachedPlayerData.gang = "No Gang"
        else
          Framework.CachedPlayerData.gang = (gradeLabel ~= "" and gradeLabel ~= "No Grade" and gradeLabel ~= "none") and string.format("%s (%s)", label, gradeLabel) or label
        end
      else
        Framework.CachedPlayerData.gang = "No Gang"
      end
    end)

    RegisterNetEvent("esx:setAccountMoney", function(account)
      if account.name == "money" then Framework.CachedPlayerData.cash = account.money end
      if account.name == "bank" then Framework.CachedPlayerData.bank = account.money end
      if account.name == "black_money" then Framework.CachedPlayerData.dirtyMoney = account.money end
    end)

    AddStateBagChangeHandler("hunger", ("player:%s"):format(cache.serverId), function(_, _, value)
      if value ~= nil then
        Framework.CachedPlayerData.hunger = lib.math.clamp(tonumber(value) or 0, 0, 100)
      end
    end)

    AddStateBagChangeHandler("thirst", ("player:%s"):format(cache.serverId), function(_, _, value)
      if value ~= nil then
        Framework.CachedPlayerData.thirst = lib.math.clamp(tonumber(value) or 0, 0, 100)
      end
    end)

    AddStateBagChangeHandler("stress", ("player:%s"):format(cache.serverId), function(_, _, value)
      if value ~= nil then
        Framework.CachedPlayerData.stress = lib.math.clamp(tonumber(value) or 0, 0, 100)
      end
    end)

    AddStateBagChangeHandler("gang", ("player:%s"):format(cache.serverId), function(_, _, value)
      if value and value.label then
        local label = value.label or "No Gang"
        local gradeLabel = value.grade_label or ""
        if value.name == "none" or label == "No Gang" then
          Framework.CachedPlayerData.gang = "No Gang"
        else
          Framework.CachedPlayerData.gang = (gradeLabel ~= "" and gradeLabel ~= "No Grade" and gradeLabel ~= "none") and string.format("%s (%s)", label, gradeLabel) or label
        end
      else
        Framework.CachedPlayerData.gang = "No Gang"
      end
    end)
  end

  if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
    RegisterNetEvent("hud:client:UpdateNeeds", function(newHunger, newThirst)
      Framework.CachedPlayerData.hunger = newHunger
      Framework.CachedPlayerData.thirst = newThirst
    end)

    RegisterNetEvent("hud:client:OnMoneyChange", function(type)
      -- The reason I fetch them directly from `GetBalance` and don't use the amount/isMinus args is because
      -- they didn't consistently work for me - especially when using /setmoney in QB or Qbox
      if type == "cash" then Framework.CachedPlayerData.cash = Framework.Client.GetBalance("cash") end
      if type == "bank" then Framework.CachedPlayerData.bank = Framework.Client.GetBalance("bank") end
    end)

    RegisterNetEvent("QBCore:Client:OnJobUpdate", function()
      Framework.CachedPlayerData.job = Framework.Client.GetPlayerJob()
    end)

    RegisterNetEvent("QBCore:Client:OnGangUpdate", function()
      Framework.CachedPlayerData.gang = Framework.Client.GetPlayerGang()
    end)
  end

  if Config.Framework == "Qbox" then
    local playerState = LocalPlayer.state
    Framework.CachedPlayerData.hunger = lib.math.clamp(playerState.hunger or 0, 0, 100)
    Framework.CachedPlayerData.thirst = lib.math.clamp(playerState.thirst or 0, 0, 100)

    AddEventHandler("ox_inventory:itemCount", function(itemName, totalCount)
      if itemName == "black_money" then
        Framework.CachedPlayerData.dirtyMoney = totalCount
      end
    end)

    AddStateBagChangeHandler("hunger", ("player:%s"):format(cache.serverId), function(_, _, value)
      Framework.CachedPlayerData.hunger = lib.math.clamp(value or 0, 0, 100)
    end)

    AddStateBagChangeHandler("thirst", ("player:%s"):format(cache.serverId), function(_, _, value)
      Framework.CachedPlayerData.thirst = lib.math.clamp(value or 0, 0, 100)
    end)
  end

  -- rcore_gangs
  if GetResourceState("rcore_gangs") == "started" then
    RegisterNetEvent("rcore_gangs:client:set_gang", function()
      Framework.Client.RefreshRcoreGangData()
    end)
    
    RegisterNetEvent("jg-hud:client:rcore-refresh-gang", function()
      Framework.Client.RefreshRcoreGangData()
    end)
  end

  -- jg-stress integration
  AddStateBagChangeHandler("stress", ("player:%s"):format(cache.serverId), function(_, _, value)
    Framework.CachedPlayerData.stress = lib.math.clamp(value or 0, 0, 100)
  end)

  -- PMA Voice
  AddEventHandler("pma-voice:setTalkingMode", function(mode)
    Framework.CachedPlayerData.micRange = mode
  end)

  AddEventHandler("pma-voice:radioActive", function(isActive)
    Framework.CachedPlayerData.radioActive = isActive
  end)

  AddEventHandler("pma-voice:settingsCallback", function(voiceSettings)
    Framework.CachedPlayerData.voiceModes = (voiceSettings and voiceSettings.voiceModes and #voiceSettings.voiceModes) or 3
  end)

  AddStateBagChangeHandler("proximity", ("player:%s"):format(cache.serverId), function(_, _, value)
    if value and value.index then
      Framework.CachedPlayerData.micRange = value.index
    end
  end)
end