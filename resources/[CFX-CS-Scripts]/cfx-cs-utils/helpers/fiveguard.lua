local FG_RESOURCE_CANDIDATES = { 'grimbot', 'fiveguard', 'fg', 'FiveGuard' }

local function fgResource()
    local named = GetConvar('fiveguard_resource', '')
    if named ~= '' and GetResourceState(named) == 'started' then
        return named
    end
    for i = 1, #FG_RESOURCE_CANDIDATES do
        local name = FG_RESOURCE_CANDIDATES[i]
        if GetResourceState(name) == 'started' then
            return name
        end
    end
    return nil
end

local M = {}

---@param src number
---@param category string
---@param perm string
---@param enable boolean
function M.set(src, category, perm, enable)
    local resource = fgResource()
    if not resource then return end
    pcall(function()
        exports[resource]:SetTempPermission(src, category, perm, enable == true, false)
    end)
end

return M
