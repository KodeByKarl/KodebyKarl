-- Version Check Script - Deobfuscated
local print = function(...) end

-- Configuration for version checking
local resourceName = "jg-advancedgarages"
local versionCheckUrl = "https://raw.githubusercontent.com/jgscripts/versions/main/" .. resourceName .. ".txt"

-- Function to compare two version strings (e.g., "v1.2.3" vs "v1.2.4")
function compareVersions(currentVersion, latestVersion)
    local currentParts = {}
    local latestParts = {}
    
    -- Parse current version into numeric parts
    for versionPart in string.gmatch(currentVersion, "[^.]+") do
        local numericPart = tonumber(versionPart)
        if numericPart ~= nil then
            table.insert(currentParts, numericPart)
        end
    end
    
    -- Parse latest version into numeric parts
    for versionPart in string.gmatch(latestVersion, "[^.]+") do
        local numericPart = tonumber(versionPart)
        if numericPart ~= nil then
            table.insert(latestParts, numericPart)
        end
    end
    
    -- Compare version parts (pad with zeros if needed)
    local maxLength = math.max(#currentParts, #latestParts)
    for i = 1, maxLength, 1 do
        local currentPart = currentParts[i] or 0
        local latestPart = latestParts[i] or 0
        
        if currentPart < latestPart then
            return true -- Update available
        end
    end
    
    return false -- No update needed
end

-- Perform version check against remote repository
PerformHttpRequest(versionCheckUrl, function(statusCode, responseBody, responseHeaders)
    -- Check if request was successful
    if statusCode ~= 200 then
        return print("^1Unable to perform update check")
    end
    
    -- Get current resource version from metadata
    local currentResourceName = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(currentResourceName, "version", 0)
    
    if not currentVersion then
        return
    end
    
    -- Skip version check for development versions
    if currentVersion == "dev" then
        return print("^3Using dev version")
    end
    
    -- Extract first line from response (latest version)
    local latestVersion = responseBody:match("^[^\n]+")
    if not latestVersion then
        return
    end
    
    -- Compare versions (remove 'v' prefix if present)
    local currentVersionClean = currentVersion:sub(2) -- Remove 'v' prefix
    local latestVersionClean = latestVersion:sub(2) -- Remove 'v' prefix
    local updateAvailable = compareVersions(currentVersionClean, latestVersionClean)
    
    if updateAvailable then
        print("^3Update available for " .. resourceName .. "! (current: ^1" .. currentVersion .. "^3, latest: ^2" .. latestVersion .. "^3)")
        print("^3Release notes: discord.gg/jgscripts")
    end
end, "GET")

-- Function to check FXServer artifacts version for compatibility
function checkArtifactVersion()
    local fxServerVersion = GetConvar("version", "unknown")
    local artifactNumber = string.match(fxServerVersion, "v%d+%.%d+%.%d+%.(%d+)")
    
    local artifactCheckUrl = "https://artifacts.jgscripts.com/check?artifact=" .. artifactNumber
    
    PerformHttpRequest(artifactCheckUrl, function(statusCode, responseBody, responseHeaders, errorData)
        -- Check for request errors
        if statusCode ~= 200 or errorData then
            return print("^1Could not check artifact version^0")
        end
        
        if not responseBody then
            return
        end
        
        -- Parse JSON response
        local artifactInfo = json.decode(responseBody)
        local artifactStatus = artifactInfo.status
        
        -- Warn about broken artifacts
        if artifactStatus == "BROKEN" then
            print("^1WARNING: The current FXServer version you are using (artifacts version) has known issues. Please update to the latest stable artifacts: https://artifacts.jgscripts.com^0")
            print("^0Artifact version:^3", artifactNumber, "\n\n^0Known issues:^3", artifactInfo.reason, "^0")
            return
        end
    end)
end

-- Run artifact version check in separate thread
CreateThread(function()
    checkArtifactVersion()
end)