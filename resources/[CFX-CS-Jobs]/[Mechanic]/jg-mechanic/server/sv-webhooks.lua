--[[
    JG Mechanic Discord logs via kodebykarl-logs
    Channels: #invoices #self-service #orders #tuning #servicing #admin #mechanic
]]

Webhooks = {
  SelfService = 'self-service',
  Orders = 'orders',
  TabletTuning = 'tuning',
  Servicing = 'servicing',
  Invoices = 'invoices',
  Mechanic = 'mechanic', -- management / employees
  Admin = 'admin',
}

local COLOR = {
  success = 5763719, -- green
  danger = 15158332, -- red
  default = 16742400, -- orange
}

function sendWebhook(playerId, channel, title, logType, data)
  if not channel or channel == '' then return false end
  if GetResourceState('kodebykarl-logs') ~= 'started' then return false end

  -- Legacy: ignore raw Discord webhook URLs left in config
  if type(channel) == 'string' and channel:find('https://', 1, true) then
    return false
  end

  local fields = {}
  if type(data) == 'table' then
    for _, row in pairs(data) do
      if type(row) == 'table' and row.key and row.value ~= nil then
        fields[#fields + 1] = {
          name = tostring(row.key),
          value = tostring(row.value),
          inline = true,
        }
      end
    end
  end

  local color = COLOR[logType] or COLOR.default

  return exports['kodebykarl-logs']:Log(channel, {
    title = title or 'Mechanic',
    player = playerId,
    color = color,
    fields = fields,
  })
end
