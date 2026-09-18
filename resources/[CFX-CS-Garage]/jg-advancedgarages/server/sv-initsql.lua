-- Split string by delimiter and return array of trimmed parts
local function splitString(inputString, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]+)"
    
    for match in string.gmatch(inputString, pattern) do
        -- Trim whitespace from each match
        local trimmed = string.gsub(match, "^%s*(.-)%s*$", "%1")
        table.insert(result, trimmed)
    end
    
    return result
end

-- Initialize SQL database by automatically running SQL files
local function initializeSQL()
    if Config.AutoRunSQL then
        local success = pcall(function()
            local sqlFileName
            
            -- Determine which SQL file to use based on framework
            if Config.Framework == "QBCore" or Config.Framework == "Qbox" then
                sqlFileName = "run-qb.sql"
            else
                -- Default to ESX SQL file
                sqlFileName = "run-esx.sql"
            end
            
            -- Construct full path to SQL file
            local resourcePath = GetResourcePath(GetCurrentResourceName())
            local sqlFilePath = resourcePath .. "/install/" .. sqlFileName
            
            -- Open and read the SQL file
            local file = assert(io.open(sqlFilePath, "rb"))
            local sqlContent = file:read("*all")
            file:close()
            
            -- Split SQL content into individual statements by semicolon
            local sqlStatements = splitString(sqlContent, ";")
            
            -- Execute all SQL statements as a transaction
            MySQL.transaction.await(sqlStatements)
        end)
        
        if not success then
            print("^1[SQL ERROR] There was an error while automatically running the required SQL. Don't worry, you just need to run the SQL file for your framework, found in the 'install' folder manually. If you've already ran the SQL code previously, and this error is annoying you, set Config.AutoRunSQL = false^0")
        end
    end
end

-- Export the initSQL function
initSQL = initializeSQL