--[[
  Description:
    Shared utility functions for server-side search functionality.
    Includes smart date parsing for SQL datetime columns.

  Global Namespace:
    SearchHelpers

  Globals:
    SearchHelpers.BuildDateCondition - Builds SQL condition for smart date searching
    SearchHelpers.ParseSearchTermForDate - Parses search term and returns date-related SQL conditions

  Exports:
    None
]]--

SearchHelpers = SearchHelpers or {}

-- Month name mappings (English only)
local MONTH_NAMES = {
  ["january"] = 1, ["jan"] = 1,
  ["february"] = 2, ["feb"] = 2,
  ["march"] = 3, ["mar"] = 3,
  ["april"] = 4, ["apr"] = 4,
  ["may"] = 5,
  ["june"] = 6, ["jun"] = 6,
  ["july"] = 7, ["jul"] = 7,
  ["august"] = 8, ["aug"] = 8,
  ["september"] = 9, ["sep"] = 9, ["sept"] = 9,
  ["october"] = 10, ["oct"] = 10,
  ["november"] = 11, ["nov"] = 11,
  ["december"] = 12, ["dec"] = 12
}

---@param searchTerm string
---@return number|nil month
local function parseMonthName(searchTerm)
  local lower = searchTerm:lower()
  return MONTH_NAMES[lower]
end

---@param searchTerm string
---@return number|nil year
local function parseYear(searchTerm)
  local year = tonumber(searchTerm)
  if year and year >= 1900 and year <= 2100 then
    return year
  end
  return nil
end

---@param searchTerm string
---@param dateColumn string The SQL column name for the datetime field
---@return string|nil condition, table|nil params
function SearchHelpers.BuildDateCondition(searchTerm, dateColumn)
  if not searchTerm or searchTerm == "" then return nil, nil end

  local trimmed = Trim(searchTerm)
  local lower = trimmed:lower()
  local conditions = {}
  local params = {}

  -- Check for exact year (e.g., "2024")
  local year = parseYear(trimmed)
  if year then
    conditions[#conditions+1] = ("YEAR(%s) = ?"):format(dateColumn)
    params[#params+1] = year
    return conditions[1], params
  end

  -- Check for month name only (e.g., "November", "Nov")
  local month = parseMonthName(trimmed)
  if month then
    conditions[#conditions+1] = ("MONTH(%s) = ?"):format(dateColumn)
    params[#params+1] = month
    return conditions[1], params
  end

  -- Check for "Month Year" format (e.g., "November 2024", "Nov 2024")
  local monthYearMatch = trimmed:match("^(%a+)%s+(%d+)$")
  if monthYearMatch then
    local monthPart, yearPart = trimmed:match("^(%a+)%s+(%d+)$")
    local parsedMonth = parseMonthName(monthPart)
    local parsedYear = parseYear(yearPart)
    if parsedMonth and parsedYear then
      conditions[#conditions+1] = ("(MONTH(%s) = ? AND YEAR(%s) = ?)"):format(dateColumn, dateColumn)
      params[#params+1] = parsedMonth
      params[#params+1] = parsedYear
      return conditions[1], params
    end
  end

  -- Check for "Year Month" format (e.g., "2024 November", "2024 Nov")
  local yearMonthMatch = trimmed:match("^(%d+)%s+(%a+)$")
  if yearMonthMatch then
    local yearPart, monthPart = trimmed:match("^(%d+)%s+(%a+)$")
    local parsedMonth = parseMonthName(monthPart)
    local parsedYear = parseYear(yearPart)
    if parsedMonth and parsedYear then
      conditions[#conditions+1] = ("(MONTH(%s) = ? AND YEAR(%s) = ?)"):format(dateColumn, dateColumn)
      params[#params+1] = parsedMonth
      params[#params+1] = parsedYear
      return conditions[1], params
    end
  end

  -- Check for "YYYY-MM" format (e.g., "2024-11")
  local yearDashMonth = trimmed:match("^(%d%d%d%d)%-(%d%d?)$")
  if yearDashMonth then
    local y, m = trimmed:match("^(%d%d%d%d)%-(%d%d?)$")
    local parsedYear = tonumber(y)
    local parsedMonth = tonumber(m)
    if parsedYear and parsedMonth and parsedMonth >= 1 and parsedMonth <= 12 then
      conditions[#conditions+1] = ("(MONTH(%s) = ? AND YEAR(%s) = ?)"):format(dateColumn, dateColumn)
      params[#params+1] = parsedMonth
      params[#params+1] = parsedYear
      return conditions[1], params
    end
  end

  -- Check for "MM/YYYY" or "MM-YYYY" format
  local monthSlashYear = trimmed:match("^(%d%d?)[/%-](%d%d%d%d)$")
  if monthSlashYear then
    local m, y = trimmed:match("^(%d%d?)[/%-](%d%d%d%d)$")
    local parsedMonth = tonumber(m)
    local parsedYear = tonumber(y)
    if parsedYear and parsedMonth and parsedMonth >= 1 and parsedMonth <= 12 then
      conditions[#conditions+1] = ("(MONTH(%s) = ? AND YEAR(%s) = ?)"):format(dateColumn, dateColumn)
      params[#params+1] = parsedMonth
      params[#params+1] = parsedYear
      return conditions[1], params
    end
  end

  -- Check for exact date formats: YYYY-MM-DD, DD/MM/YYYY, MM/DD/YYYY
  -- YYYY-MM-DD
  local ymdMatch = trimmed:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")
  if ymdMatch then
    local y, m, d = trimmed:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")
    conditions[#conditions+1] = ("DATE(%s) = ?"):format(dateColumn)
    params[#params+1] = ("%04d-%02d-%02d"):format(tonumber(y), tonumber(m), tonumber(d))
    return conditions[1], params
  end

  -- DD/MM/YYYY or MM/DD/YYYY with full year
  local dateSlashMatch = trimmed:match("^(%d%d?)/(%d%d?)/(%d%d%d%d)$")
  if dateSlashMatch then
    local first, second, year = trimmed:match("^(%d%d?)/(%d%d?)/(%d%d%d%d)$")
    local firstNum, secondNum = tonumber(first), tonumber(second)
    -- Try to intelligently detect format: if first > 12, it must be day (DD/MM/YYYY)
    -- if second > 12, it must be day (MM/DD/YYYY), otherwise try both
    local day, month
    if firstNum > 12 then
      -- Must be DD/MM/YYYY
      day, month = firstNum, secondNum
    elseif secondNum > 12 then
      -- Must be MM/DD/YYYY
      month, day = firstNum, secondNum
    else
      -- Ambiguous - try both formats with OR condition
      conditions[#conditions+1] = ("(DATE(%s) = ? OR DATE(%s) = ?)"):format(dateColumn, dateColumn)
      params[#params+1] = ("%04d-%02d-%02d"):format(tonumber(year), secondNum, firstNum) -- DD/MM/YYYY
      params[#params+1] = ("%04d-%02d-%02d"):format(tonumber(year), firstNum, secondNum) -- MM/DD/YYYY
      return conditions[1], params
    end
    conditions[#conditions+1] = ("DATE(%s) = ?"):format(dateColumn)
    params[#params+1] = ("%04d-%02d-%02d"):format(tonumber(year), month, day)
    return conditions[1], params
  end

  -- DD/MM/YY or MM/DD/YY with short year (2 digits)
  local dateSlashShortYear = trimmed:match("^(%d%d?)/(%d%d?)/(%d%d)$")
  if dateSlashShortYear then
    local first, second, shortYear = trimmed:match("^(%d%d?)/(%d%d?)/(%d%d)$")
    local firstNum, secondNum = tonumber(first), tonumber(second)
    -- Convert 2-digit year to 4-digit (assume 2000s for 00-99)
    local fullYear = 2000 + tonumber(shortYear)
    
    local day, month
    if firstNum > 12 then
      -- Must be DD/MM/YY
      day, month = firstNum, secondNum
    elseif secondNum > 12 then
      -- Must be MM/DD/YY
      month, day = firstNum, secondNum
    else
      -- Ambiguous - try both formats with OR condition
      conditions[#conditions+1] = ("(DATE(%s) = ? OR DATE(%s) = ?)"):format(dateColumn, dateColumn)
      params[#params+1] = ("%04d-%02d-%02d"):format(fullYear, secondNum, firstNum) -- DD/MM/YY
      params[#params+1] = ("%04d-%02d-%02d"):format(fullYear, firstNum, secondNum) -- MM/DD/YY
      return conditions[1], params
    end
    conditions[#conditions+1] = ("DATE(%s) = ?"):format(dateColumn)
    params[#params+1] = ("%04d-%02d-%02d"):format(fullYear, month, day)
    return conditions[1], params
  end

  return nil, nil
end

---@param searchTerm string The user's search query
---@param textColumns table Array of column names to search with LIKE
---@param dateColumn string|nil Optional datetime column for smart date search
---@param concatenatedColumns table|nil Optional array of column groups to concatenate and search (e.g., {{"brand", "model"}})
---@return string whereClause, table params
function SearchHelpers.BuildSearchConditions(searchTerm, textColumns, dateColumn, concatenatedColumns)
  if not searchTerm or searchTerm == "" then
    return "", {}
  end

  local trimmed = Trim(searchTerm)
  local conditions = {}
  local params = {}

  -- Build text search conditions for individual columns (case-insensitive)
  local likePattern = "%" .. trimmed:lower() .. "%"
  for _, col in ipairs(textColumns) do
    conditions[#conditions+1] = ("LOWER(%s) LIKE ?"):format(col)
    params[#params+1] = likePattern
  end

  -- Build concatenated column search conditions (e.g., brand + ' ' + model) (case-insensitive)
  if concatenatedColumns then
    for _, colGroup in ipairs(concatenatedColumns) do
      if #colGroup > 1 then
        local concatParts = {}
        for _, col in ipairs(colGroup) do
          concatParts[#concatParts+1] = col
        end
        local concatExpr = "CONCAT_WS(' ', " .. table.concat(concatParts, ", ") .. ")"
        conditions[#conditions+1] = ("LOWER(%s) LIKE ?"):format(concatExpr)
        params[#params+1] = likePattern
      end
    end
  end

  -- Add date condition if applicable
  if dateColumn then
    local dateCondition, dateParams = SearchHelpers.BuildDateCondition(trimmed, dateColumn)
    if dateCondition and dateParams then
      conditions[#conditions+1] = dateCondition
      for _, p in ipairs(dateParams) do
        params[#params+1] = p
      end
    end
  end

  if #conditions == 0 then
    return "", {}
  end

  return "(" .. table.concat(conditions, " OR ") .. ")", params
end
