--[[
  Description:
    Server-side currency configuration and handling.
    This file defines all available currencies (payment methods) for the dealership system.
    Users can add custom currencies like VIP Coins by extending the Currencies table.

  Global Namespace:
    Currencies.Server

  Globals:
    Currencies.Server.GetAll() - Returns all registered currencies
    Currencies.Server.Get(id) - Returns a specific currency by ID
    Currencies.Server.GetBalance(src, currencyId) - Get player's balance for a currency
    Currencies.Server.AddBalance(src, amount, currencyId) - Add to player's balance
    Currencies.Server.RemoveBalance(src, amount, currencyId) - Remove from player's balance
    Currencies.Server.GetBalanceOffline(identifier, currencyId) - Get offline player's balance
    Currencies.Server.RemoveBalanceOffline(identifier, amount, currencyId) - Remove from offline player's balance
    Currencies.Server.ConvertToBase(amount, currencyId) - Convert currency amount to base value
    Currencies.Server.ConvertFromBase(amount, currencyId) - Convert base value to currency amount (or flatCost if set)
    Currencies.Server.FormatAmount(amount, currencyId) - Format an amount for display
    Currencies.Server.AllowsFinance(currencyId) - Check if currency can be used for financing
    Currencies.Server.HasFlatCost(currencyId) - Check if currency uses flat cost pricing
    Currencies.Server.GetFlatCost(currencyId) - Get the flat cost amount for a currency

  Exports:
    getCurrencies - Returns all registered currencies
    getCurrency - Returns a specific currency by ID
]]--

Currencies = Currencies or {}
Currencies.Server = Currencies.Server or {}

---@class CurrencyDefinition
---@field id string Unique identifier for the currency (e.g., "bank", "cash", "vip_coins")
---@field label string Display name (e.g., "Bank Account", "Cash", "VIP Coins")
---@field format string Format string for displaying amounts. Use %s for the amount (e.g., "$%s" -> "$1,000" or "%s coins" -> "1,000 coins")
---@field conversionRate? number How much 1 unit of this currency is worth in base currency. 1.0 = same as bank/cash, 10000 = 1 unit = $10,000. Ignored if flatCost is set.
---@field flatCost? number Optional: If set, this fixed amount is charged per transaction regardless of the item's base price. E.g., flatCost = 1 means 1 coin per purchase.
---@field allowFinance boolean Whether this currency can be used for financed purchases and recurring payments. Must be false if flatCost is set.
---@field fetchBalance fun(src: number): number Function to get player's balance
---@field addBalance fun(src: number, amount: number): boolean Function to add to player's balance
---@field removeBalance fun(src: number, amount: number): boolean Function to remove from player's balance
---@field fetchBalanceOffline? fun(identifier: string): number Optional: Function to get offline player's balance (for finance processing)
---@field removeBalanceOffline? fun(identifier: string, amount: number): boolean Optional: Function to remove from offline player's balance (for finance processing)

---@type table<string, CurrencyDefinition>
local registeredCurrencies = {}

-- ============================================================================
-- API
-- ============================================================================

---Get all registered currencies
---@return table<string, CurrencyDefinition>
function Currencies.Server.GetAll()
  return registeredCurrencies
end

---Get a specific currency by ID
---@param currencyId string
---@return CurrencyDefinition|nil
function Currencies.Server.Get(currencyId)
  return registeredCurrencies[currencyId]
end

---Register a currency in the system
---@param currency CurrencyDefinition
function Currencies.Server.Register(currency)
  if not currency.id then
    error("Currency must have an 'id' field")
  end
  registeredCurrencies[currency.id] = currency
  DebugPrint(("Registered currency: %s"):format(currency.id), "debug")
end

---Get a list of currency IDs that are valid for purchases
---@return string[]
function Currencies.Server.GetPurchaseCurrencyIds()
  local ids = {}
  for id, _ in pairs(registeredCurrencies) do
    table.insert(ids, id)
  end
  return ids
end

---Get player's balance for a specific currency
---@param src number Player source
---@param currencyId string Currency ID
---@return number balance
function Currencies.Server.GetBalance(src, currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then
    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")
    return 0
  end
  return currency.fetchBalance(src)
end

---Add to player's balance for a specific currency
---@param src number Player source
---@param amount number Amount to add (in the currency's units)
---@param currencyId string Currency ID
---@return boolean success
function Currencies.Server.AddBalance(src, amount, currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then
    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")
    return false
  end
  return currency.addBalance(src, amount)
end

---Remove from player's balance for a specific currency
---@param src number Player source
---@param amount number Amount to remove (in the currency's units)
---@param currencyId string Currency ID
---@return boolean success
function Currencies.Server.RemoveBalance(src, amount, currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then
    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")
    return false
  end
  return currency.removeBalance(src, amount)
end

---Get offline player's balance for a specific currency
---@param identifier string Player identifier
---@param currencyId string Currency ID
---@return number balance
function Currencies.Server.GetBalanceOffline(identifier, currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then
    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")
    return 0
  end
  if not currency.fetchBalanceOffline then
    DebugPrint(("Currency %s does not support offline balance fetching"):format(currencyId), "warning")
    return 0
  end
  return currency.fetchBalanceOffline(identifier)
end

---Remove from offline player's balance for a specific currency
---@param identifier string Player identifier
---@param amount number Amount to remove (in the currency's units)
---@param currencyId string Currency ID
---@return boolean success
function Currencies.Server.RemoveBalanceOffline(identifier, amount, currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then
    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")
    return false
  end
  if not currency.removeBalanceOffline then
    DebugPrint(("Currency %s does not support offline balance removal"):format(currencyId), "warning")
    return false
  end
  return currency.removeBalanceOffline(identifier, amount)
end

---Convert an amount from a custom currency to base currency value
---@param amount number Amount in the custom currency
---@param currencyId string Currency ID
---@return number baseAmount Amount in base currency ($)
function Currencies.Server.ConvertToBase(amount, currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then return amount end
  -- flatCost currencies don't have a meaningful base conversion
  -- Return 0 to indicate this conversion isn't applicable
  if currency.flatCost then
    return 0
  end
  return amount * currency.conversionRate
end

---Convert an amount from base currency to a custom currency
---@param baseAmount number Amount in base currency ($)
---@param currencyId string Currency ID
---@return number amount Amount in the custom currency
function Currencies.Server.ConvertFromBase(baseAmount, currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then return baseAmount end
  -- If flatCost is set, return that fixed amount regardless of base price
  if currency.flatCost then
    return currency.flatCost
  end
  return baseAmount / currency.conversionRate
end

---Format an amount for display using the currency's format string
---@param amount number Amount to format
---@param currencyId string Currency ID
---@return string formatted Formatted string (e.g., "$1,000" or "100 coins")
function Currencies.Server.FormatAmount(amount, currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then
    return tostring(amount)
  end
  -- Note: The actual number formatting is handled by the UI
  return string.format(currency.format, tostring(amount))
end

---Check if a currency allows financing
---@param currencyId string Currency ID
---@return boolean
function Currencies.Server.AllowsFinance(currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then return false end
  -- Flat cost currencies cannot be financed (you can't split 1 coin into payments)
  if currency.flatCost then return false end
  return currency.allowFinance == true
end

---Check if a currency uses flat cost pricing (fixed amount per transaction)
---@param currencyId string Currency ID
---@return boolean
function Currencies.Server.HasFlatCost(currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then return false end
  return currency.flatCost ~= nil
end

---Get the flat cost amount for a currency
---@param currencyId string Currency ID
---@return number|nil flatCost The flat cost amount, or nil if not a flat cost currency
function Currencies.Server.GetFlatCost(currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then return nil end
  return currency.flatCost
end

---Check if a currency supports offline operations (for finance processing)
---@param currencyId string Currency ID
---@return boolean
function Currencies.Server.SupportsOffline(currencyId)
  local currency = registeredCurrencies[currencyId]
  if not currency then return false end
  return currency.fetchBalanceOffline ~= nil and currency.removeBalanceOffline ~= nil
end

---Get all currencies as a simplified table for sending to the client
---@return table[] currencies Array of {id, label, format, conversionRate, flatCost, allowFinance}
function Currencies.Server.GetAllForClient()
  local result = {}
  for id, currency in pairs(registeredCurrencies) do
    table.insert(result, {
      id = currency.id,
      label = (currency.id == "bank" or currency.id == "cash") and Locale[currency.id] or currency.label,
      format = currency.format,
      conversionRate = currency.conversionRate,
      flatCost = currency.flatCost,
      allowFinance = currency.allowFinance,
    })
  end
  return result
end

-- ============================================================================
-- Callbacks
-- ============================================================================

lib.callback.register("jg-dealerships:server:get-currencies", function()
  return Currencies.Server.GetAllForClient()
end)

lib.callback.register("jg-dealerships:server:get-player-balances", function(src, currencyIds)
  local balances = {}
  for _, currencyId in ipairs(currencyIds or Currencies.Server.GetPurchaseCurrencyIds()) do
    balances[currencyId] = Currencies.Server.GetBalance(src, currencyId)
  end
  return balances
end)

-- ============================================================================
-- Exports
-- ============================================================================

exports("getCurrencies", Currencies.Server.GetAll)
exports("getCurrency", Currencies.Server.Get)
exports("registerCurrency", Currencies.Server.Register)

-- ============================================================================
-- Default Currencies (Bank and Cash)
-- These use the framework's built-in money handling
-- The format string comes from Config.Currency so you don't need to modify
-- this file to change the currency symbol!
-- ============================================================================

-- Bank Account
Currencies.Server.Register({
  id = "bank",
  label = "Bank Account",
  format = Config.Currency or "$%s",
  conversionRate = 1.0,
  allowFinance = true,

  fetchBalance = function(src)
    local player = Framework.Server.GetPlayer(src)
    if not player then return 0 end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      return player.PlayerData.money.bank or 0
    elseif Config.Framework == "ESX" then
      for _, acc in pairs(player.getAccounts()) do
        if acc.name == "bank" then
          return acc.money or 0
        end
      end
    end
    return 0
  end,

  addBalance = function(src, amount)
    local player = Framework.Server.GetPlayer(src)
    if not player then return false end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      player.Functions.AddMoney("bank", Round(amount, 0))
    elseif Config.Framework == "ESX" then
      player.addAccountMoney("bank", Round(amount, 0))
    end
    return true
  end,

  removeBalance = function(src, amount)
    local player = Framework.Server.GetPlayer(src)
    if not player then return false end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      player.Functions.RemoveMoney("bank", Round(amount, 0))
    elseif Config.Framework == "ESX" then
      player.removeAccountMoney("bank", Round(amount, 0))
    end
    return true
  end,

  fetchBalanceOffline = function(identifier)
    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      local result = MySQL.scalar.await(
        "SELECT JSON_EXTRACT(money, '$.bank') FROM " .. Framework.PlayersTable .. " WHERE " .. Framework.PlayersTableId .. " = ?",
        { identifier }
      )
      return tonumber(result) or 0
    elseif Config.Framework == "ESX" then
      local result = MySQL.scalar.await(
        "SELECT accounts FROM " .. Framework.PlayersTable .. " WHERE " .. Framework.PlayersTableId .. " = ?",
        { identifier }
      )
      if not result then return 0 end

      local accounts = json.decode(result)
      if type(accounts) == "table" then
        if accounts.bank then
          return tonumber(accounts.bank) or 0
        else
          for _, acc in pairs(accounts) do
            if acc.name == "bank" then
              return tonumber(acc.money) or 0
            end
          end
        end
      end
    end
    return 0
  end,

  removeBalanceOffline = function(identifier, amount)
    amount = Round(amount, 0)

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      local affectedRows = MySQL.update.await(
        "UPDATE " .. Framework.PlayersTable .. " SET money = JSON_SET(money, '$.bank', JSON_EXTRACT(money, '$.bank') - ?) WHERE " .. Framework.PlayersTableId .. " = ?",
        { amount, identifier }
      )
      return affectedRows > 0
    elseif Config.Framework == "ESX" then
      local result = MySQL.single.await(
        "SELECT accounts FROM " .. Framework.PlayersTable .. " WHERE " .. Framework.PlayersTableId .. " = ?",
        { identifier }
      )
      if not result or not result.accounts then return false end

      local accounts = json.decode(result.accounts)
      if type(accounts) == "table" then
        if accounts.bank then
          accounts.bank = (tonumber(accounts.bank) or 0) - amount
        else
          for i, acc in pairs(accounts) do
            if acc.name == "bank" then
              accounts[i].money = (tonumber(acc.money) or 0) - amount
              break
            end
          end
        end

        MySQL.update.await(
          "UPDATE " .. Framework.PlayersTable .. " SET accounts = ? WHERE " .. Framework.PlayersTableId .. " = ?",
          { json.encode(accounts), identifier }
        )
        return true
      end
    end
    return false
  end,
})

-- Cash
Currencies.Server.Register({
  id = "cash",
  label = "Cash",
  format = Config.Currency or "$%s",
  conversionRate = 1.0,
  allowFinance = false, -- Cash typically not allowed for financing

  fetchBalance = function(src)
    local player = Framework.Server.GetPlayer(src)
    if not player then return 0 end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      return player.PlayerData.money.cash or 0
    elseif Config.Framework == "ESX" then
      for _, acc in pairs(player.getAccounts()) do
        if acc.name == "money" then
          return acc.money or 0
        end
      end
    end
    return 0
  end,

  addBalance = function(src, amount)
    local player = Framework.Server.GetPlayer(src)
    if not player then return false end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      player.Functions.AddMoney("cash", Round(amount, 0))
    elseif Config.Framework == "ESX" then
      player.addAccountMoney("money", Round(amount, 0))
    end
    return true
  end,

  removeBalance = function(src, amount)
    local player = Framework.Server.GetPlayer(src)
    if not player then return false end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
      player.Functions.RemoveMoney("cash", Round(amount, 0))
    elseif Config.Framework == "ESX" then
      player.removeAccountMoney("money", Round(amount, 0))
    end
    return true
  end,

  -- Cash doesn't support offline operations (no financing)
  fetchBalanceOffline = nil,
  removeBalanceOffline = nil,
})

-- ============================================================================
-- EXAMPLE: VIP Coins Custom Currency
-- Uncomment and modify this to add your own custom currency!
-- ============================================================================

-- VIP Coins
-- Currencies.Server.Register({
--   id = "vip_coins",
--   label = "VIP Coins",
--   format = "%s coins", -- Displays as "1,000 coins" instead of "$1,000"
--   conversionRate = 10000, -- 1 VIP coin = $10,000 base currency
--   flatCost = 1, -- Use a flat rate of 1 coin = 1 transaction (if this is set, conversionRate is ignored)
--   allowFinance = false, -- Allow VIP coins for financed purchases (not compatible with flatCost = 1)

--   fetchBalance = function(src)
--     -- Replace with your own VIP coins balance system
--     -- Example using a database table:
--     -- local result = MySQL.scalar.await("SELECT coins FROM vip_coins WHERE identifier = ?", { Framework.Server.GetPlayerIdentifier(src) })
--     -- return tonumber(result) or 0

--     -- Example using an export from another resource:
--     -- return exports["your-vip-system"]:GetPlayerCoins(src) or 0

--     return 0 -- Default: no balance
--   end,

--   addBalance = function(src, amount)
--     -- Replace with your own VIP coins add system
--     -- Example:
--     -- MySQL.update.await("UPDATE vip_coins SET coins = coins + ? WHERE identifier = ?", { amount, Framework.Server.GetPlayerIdentifier(src) })
--     -- return true

--     -- Example using an export:
--     -- return exports["your-vip-system"]:AddPlayerCoins(src, amount)

--     return false -- Default: not implemented
--   end,

--   removeBalance = function(src, amount)
--     -- Replace with your own VIP coins remove system
--     -- Example:
--     -- MySQL.update.await("UPDATE vip_coins SET coins = coins - ? WHERE identifier = ?", { amount, Framework.Server.GetPlayerIdentifier(src) })
--     -- return true

--     -- Example using an export:
--     -- return exports["your-vip-system"]:RemovePlayerCoins(src, amount)

--     return false -- Default: not implemented
--   end,

--   -- Optional: Implement these for offline finance payment processing
--   fetchBalanceOffline = function(identifier)
--     -- Example:
--     -- local result = MySQL.scalar.await("SELECT coins FROM vip_coins WHERE identifier = ?", { identifier })
--     -- return tonumber(result) or 0

--     return 0
--   end,

--   removeBalanceOffline = function(identifier, amount)
--     -- Example:
--     -- MySQL.update.await("UPDATE vip_coins SET coins = coins - ? WHERE identifier = ?", { amount, identifier })
--     -- return true

--     return false
--   end,
-- })
