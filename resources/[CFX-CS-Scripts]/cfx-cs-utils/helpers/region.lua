local Region = {}

local isServer = IsDuplicityVersion()

local function getResourceName()
    if GetResourceState('kodebykarl-ui') == 'started' then
        return 'kodebykarl-ui'
    elseif GetResourceState('cfx-keydi-ui') == 'started' then
        return 'cfx-keydi-ui'
    end
    return nil
end

--- Checks if a region allows the specified feature/function.
--- @param fn string The function tag (e.g. 'illegal', 'grind')
--- @param src? number Player server ID (required on server-side)
--- @return boolean
function Region.Allowed(fn, src)
    if not fn then return true end

    local res = getResourceName()
    if not res then
        return true -- Fallback: allow if region module is not started
    end

    if isServer then
        if not src or src == 0 then return true end
        local ok, allowed = pcall(function()
            return exports[res]:PlayerHasFunction(src, fn)
        end)
        if ok and allowed ~= nil then
            return allowed == true
        end
    else
        local ok, allowed = pcall(function()
            return exports[res]:HasFunction(fn)
        end)
        if ok and allowed ~= nil then
            return allowed == true
        end
    end

    return true
end

--- Returns the notification message when a function is blocked in the current region.
--- @param fn string The function tag (e.g. 'illegal', 'grind')
--- @return string
function Region.Message(fn)
    local res = getResourceName()
    if res then
        local ok, msg = pcall(function()
            return exports[res]:WrongServerMessage(fn)
        end)
        if ok and type(msg) == 'string' and msg ~= '' then
            return msg
        end
    end

    return "This feature is not available in your current region. Switch regions via Control Center (F5)."
end

return Region
