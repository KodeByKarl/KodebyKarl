--[[
  Description:
    Registers ESX society accounts for all dealership locations that have a job configured.
    This is required for esx_society balance operations (get/add/remove) to work.
    Also exposes a global function to register individual societies when locations are created or updated.

  Global Namespace:
    EsxSociety.Server

  Globals:
    EsxSociety.Server.RegisterSociety(jobName) - Registers a single ESX society for the given job name

  Exports:
    None
]]--

EsxSociety = EsxSociety or {}
EsxSociety.Server = EsxSociety.Server or {}

---@param jobName string
function EsxSociety.Server.RegisterSociety(jobName)
  if not jobName or jobName == "" then return end
  if (Config.Framework == "auto" and GetResourceState("es_extended") == "started") or Config.Framework == "ESX" then
    TriggerEvent("esx_society:registerSociety", jobName, jobName, "society_" .. jobName, "society_" .. jobName)
  end
end

if (Config.Framework == "auto" and GetResourceState("es_extended") == "started") or Config.Framework == "ESX" then
  CreateThread(function()
    local locations = Locations.Server.GetAll()

    for _, location in ipairs(locations) do
      EsxSociety.Server.RegisterSociety(location.job_name)
    end
  end)
end
