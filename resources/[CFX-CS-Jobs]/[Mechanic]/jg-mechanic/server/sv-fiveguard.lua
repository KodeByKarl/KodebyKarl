function FgMechanicSession(src, session, enable, ttl)
  if GetResourceState('cfx-cs-utils') == 'started' then
    pcall(function()
      exports['cfx-cs-utils']:FgVehicleSession(src, session, enable == true, ttl)
    end)
  elseif GetResourceState('kodebykarl-utils') == 'started' then
    pcall(function()
      exports['kodebykarl-utils']:FgVehicleSession(src, session, enable == true, ttl)
    end)
  end
end

local function hasItemSilent(src, itemName)
  if GetResourceState('ox_inventory') ~= 'started' then return false end
  return (exports.ox_inventory:Search(src, 'count', itemName) or 0) > 0
end

local function canRequestRepair(src)
  if Framework.Server.IsAdmin(src) then return true end
  if hasItemSilent(src, 'repairkit') or hasItemSilent(src, 'repair_kit') or hasItemSilent(src, 'duct_tape') then return true end
  if isEmployee then
    for mechanicId in pairs(Config.MechanicLocations or {}) do
      if isEmployee(src, mechanicId, { 'mechanic', 'manager' }, false) then
        return true
      end
    end
  end
  return false
end

lib.callback.register('jg-mechanic:server:fg-repair', function(source)
  if not canRequestRepair(source) then return false end
  FgMechanicSession(source, 'repair', true, 8000)
  return true
end)
