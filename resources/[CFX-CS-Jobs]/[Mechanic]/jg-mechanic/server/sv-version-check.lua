local RESOURCE_NAME = "jg-mechanic"
local VERSION_URL = "https://raw.githubusercontent.com/jgscripts/versions/main/" .. RESOURCE_NAME .. ".txt"

local function isVersionOutdated(currentVersion, latestVersion)
  local currentParts = {}
  for part in string.gmatch(currentVersion, "[^.]+") do
    table.insert(currentParts, tonumber(part))
  end
  local latestParts = {}
  for part in string.gmatch(latestVersion, "[^.]+") do
    table.insert(latestParts, tonumber(part))
  end

  for i = 1, math.max(#currentParts, #latestParts) do
    local current = currentParts[i] or 0
    local latest = latestParts[i] or 0
    if current < latest then
      return true
    end
  end
  return false
end

PerformHttpRequest(VERSION_URL, function(err, text, headers)
  if err ~= 200 then
    -- print("^1Unable to perform update check")
    return
  end
  local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
  if not currentVersion then return end
  if currentVersion == "dev" then
    return print("^3Using dev version")
  end
  local latestVersion = text:match("^[^\n]+")
  if not latestVersion then return end

  if isVersionOutdated(currentVersion:sub(2), latestVersion:sub(2)) then
    -- print("^3Update available for " .. RESOURCE_NAME .. "! (current: ^1" .. currentVersion .. "^3, latest: ^2" .. latestVersion .. "^3)")
    -- print("^3Release notes: discord.gg/jgscripts")
  end
end, "GET")

local function checkArtifactVersion()
  local build = GetConvar("version", "unknown")
  local artifactVersion = string.match(build, "v%d+%.%d+%.%d+%.(%d+)")
  PerformHttpRequest("https://artifacts.jgscripts.com/check?artifact=" .. artifactVersion, function(err, text, headers)
    if err ~= 200 or not text then
      return print("^1Could not check artifact version^0")
    end
    if not text then return end
    local decoded = json.decode(text)
    if decoded.status == "BROKEN" then
      -- print("^1WARNING: The current FXServer version you are using (artifacts version) has known issues. Please update to the latest stable artifacts: https://artifacts.jgscripts.com^0")
      -- print(("^0Artifact version:^3%s\n\n^0Known issues:^3%s^0"):format(artifactVersion, decoded.reason))
      return
    end
  end)
end

CreateThread(function()
  checkArtifactVersion()
end)
