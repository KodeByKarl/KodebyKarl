local function splitString(inputStr, delimiter)
  local result = {}
  for match in string.gmatch(inputStr, "([^" .. delimiter .. "]+)") do
    table.insert(result, string.gsub(match, "^%s*(.-)%s*$", "%1"))
  end
  return result
end

function initSQL()
  if Config.AutoRunSQL then
    local success, err = pcall(function()
      local file = assert(io.open(GetResourcePath(GetCurrentResourceName()) .. "/install/database/run.sql", "rb"))
      local content = file:read("*all")
      file:close()
      local queries = splitString(content, ";")
      MySQL.transaction.await(queries)
    end)
    if not success then
      print("^1[SQL ERROR] There was an error while automatically running the required SQL. Don't worry, you just need to run the SQL file for your framework, found in the 'install/database' folder manually. If you've already ran the SQL code previously, and this error is annoying you, set Config.AutoRunSQL = false^0")
    end
  end
end
