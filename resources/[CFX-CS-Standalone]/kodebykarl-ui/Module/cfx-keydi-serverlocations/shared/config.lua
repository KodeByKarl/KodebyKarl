--[[
    Regions — in-game instance switcher (routing buckets).

    Each region is a separate routing bucket on THIS FiveM process (not a
    `connect` command). Players keep the same character/inventory.
    Players only see others in the SAME region (bucket isolation).

    Region 1 = MAIN world (bucket 0) — grinding + illegal. Everyone here sees each other.
    Region 2 = School only + school war
    Region 3 = TrapHouse instance A — no safezone
    Region 4 = TrapHouse instance B — no safezone
]]

ConfigServerLocations = {}

ConfigServerLocations.Debug = false
-- Default world is Region 1 so hospital / appearance / "reset to bucket 0" stay together.
ConfigServerLocations.DefaultId = "region1"
-- Stay at current coords. Switching only changes routing bucket / functions.
ConfigServerLocations.TeleportOnSwitch = false
ConfigServerLocations.SwitchCooldown = 8 -- seconds between switches
ConfigServerLocations.FadeOutMs = 400
ConfigServerLocations.FadeInMs = 700

-- Must be inside a safezone to switch (jail / arena / combat / instances still always locked)
ConfigServerLocations.RequireSafezone = true
ConfigServerLocations.LockInJail = true
ConfigServerLocations.LockInArena = true
ConfigServerLocations.LockInPvp = true
ConfigServerLocations.LockInCombat = true
ConfigServerLocations.LockInInstance = true

ConfigServerLocations.WrongServerNotify = "This is only available on %s. Open Control Center (F5) → Regions to switch."

-- Legacy id remaps (old Server #1 / #2 → Regions)
ConfigServerLocations.LegacyIdMap = {
    server1 = "region2",
    server2 = "region1",
}

-- Public location slots always follow sv_maxclients in server.cfg (not these numbers).
-- Optional loc.maxPlayers is only used for side-job instances, and is still capped by sv_maxclients.

ConfigServerLocations.PublicServers = {
    {
        id = "region1",
        name = "Region 1 · Main",
        tag = "MAIN REALM",
        type = "main",
        description = "Main world — all grinding, city jobs, housing, house robbery, turf war, weed farm, gang bases, and illegal. Everyone here sees each other.",
        bucket = 0,
        spawn = vec4(2004.3286, 4902.1523, 42.7468, 58.4939),
        functions = {
            "main", "jobs", "housing",
            "grind", "autofarm", "raven", "weedfarm", "methfarm", "job_orange",
            "illegal", "turfwar", "gangbase", "safezone",
        },
        status = "ONLINE",
    },
    {
        id = "region2",
        name = "Region 2 · School",
        tag = "SCHOOL REALM",
        type = "school",
        description = "School only — campus RP and school war. No farming, illegal, or traphouse.",
        bucket = 1,
        spawn = vec4(222.2027, -864.0162, 30.2922, 1.0),
        functions = { "school", "schoolwar", "safezone" },
        status = "ONLINE",
    },
    {
        id = "region3",
        name = "Region 3 · TrapHouse",
        tag = "TRAP REALM",
        type = "traphouse",
        description = "TrapHouse redzone instance. Isolated from Region 1. No safezones.",
        bucket = 2,
        spawn = vec4(1204.89, -557.81, 69.62, 0.0),
        functions = { "traphouse" },
        status = "ONLINE",
    },
    {
        id = "region4",
        name = "Region 4 · TrapHouse",
        tag = "TRAP REALM",
        type = "traphouse",
        description = "Second TrapHouse instance. Isolated from Region 3. No safezones.",
        bucket = 3,
        spawn = vec4(-1116.84, 304.53, 66.52, 0.0),
        functions = { "traphouse" },
        status = "ONLINE",
    },
}

-- Side job instances (Orange only)
ConfigServerLocations.SideJobServers = {
    {
        id = "job_orange",
        name = "Orange Picking Instance",
        tag = "ORANGE JOB",
        type = "job",
        maxPlayers = 30,
        bucket = 12,
        spawn = vec4(281.1007, 6530.7979, 30.1681, 87.7354),
        description = "Pick oranges in a dedicated orchard instance.",
        functions = { "grind", "autofarm", "job_orange", "safezone" },
    },
}

function ConfigServerLocations.NormalizeId(id)
    if type(id) ~= "string" or id == "" then return nil end
    local mapped = ConfigServerLocations.LegacyIdMap and ConfigServerLocations.LegacyIdMap[id]
    if mapped then return mapped end
    return id
end

function ConfigServerLocations.GetById(id)
    id = ConfigServerLocations.NormalizeId(id)
    if type(id) ~= "string" or id == "" then return nil, nil end

    for i = 1, #ConfigServerLocations.PublicServers do
        local loc = ConfigServerLocations.PublicServers[i]
        if loc.id == id then
            return loc, "public"
        end
    end

    for i = 1, #ConfigServerLocations.SideJobServers do
        local loc = ConfigServerLocations.SideJobServers[i]
        if loc.id == id then
            return loc, "job"
        end
    end

    return nil, nil
end

function ConfigServerLocations.HasFunction(location, fn)
    if not location or type(fn) ~= "string" then return false end
    if location.type == fn then return true end

    local list = location.functions
    if type(list) ~= "table" then return false end

    for i = 1, #list do
        if list[i] == fn or list[i] == "*" then
            return true
        end
    end

    return false
end

--- Client cache so grind scripts see the new server immediately (state bags lag).
function ConfigServerLocations.SetClientCurrentId(id)
    id = ConfigServerLocations.NormalizeId(id)
    if type(id) == "string" and id ~= "" then
        ConfigServerLocations.ClientCurrentId = id
    end
end

function ConfigServerLocations.GetClientCurrentId()
    if ConfigServerLocations.ClientCurrentId and ConfigServerLocations.ClientCurrentId ~= "" then
        return ConfigServerLocations.NormalizeId(ConfigServerLocations.ClientCurrentId)
    end
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.grimServerId then
        return ConfigServerLocations.NormalizeId(LocalPlayer.state.grimServerId)
    end
    return ConfigServerLocations.DefaultId
end

--- Server: pass player id. Client: omit src (uses client cache / LocalPlayer.state).
function ConfigServerLocations.CanUseFunction(fn, src)
    local id
    if IsDuplicityVersion() then
        src = tonumber(src)
        if not src or src < 1 then return false end
        local state = Player(src).state
        id = ConfigServerLocations.NormalizeId((state and state.grimServerId) or ConfigServerLocations.DefaultId)
    else
        id = ConfigServerLocations.GetClientCurrentId()
    end

    local loc = ConfigServerLocations.GetById(id)
    return ConfigServerLocations.HasFunction(loc, fn)
end

function ConfigServerLocations.LocationAllows(location, fn)
    if location then
        return ConfigServerLocations.HasFunction(location, fn)
            or ConfigServerLocations.HasFunction(location, "grind")
    end
    return ConfigServerLocations.CanUseFunction(fn)
        or ConfigServerLocations.CanUseFunction("grind")
end

function ConfigServerLocations.FindLocationForFunction(fn)
    for i = 1, #ConfigServerLocations.PublicServers do
        local loc = ConfigServerLocations.PublicServers[i]
        if ConfigServerLocations.HasFunction(loc, fn) then
            return loc
        end
    end
    for i = 1, #ConfigServerLocations.SideJobServers do
        local loc = ConfigServerLocations.SideJobServers[i]
        if ConfigServerLocations.HasFunction(loc, fn) then
            return loc
        end
    end
    return nil
end

function ConfigServerLocations.WrongServerMessage(fn)
    local loc = ConfigServerLocations.FindLocationForFunction(fn)
    local name = loc and loc.name or "the correct Region"
    return (ConfigServerLocations.WrongServerNotify):format(name)
end

--- TrapHouse regions have no safezones, so players must still be able to leave via F5
--- (combat / jail / death locks still apply).
function ConfigServerLocations.RequiresSafezoneToSwitch(src)
    if ConfigServerLocations.RequireSafezone == false then
        return false
    end

    local id
    if IsDuplicityVersion() then
        src = tonumber(src)
        if not src or src < 1 then return true end
        local state = Player(src).state
        id = ConfigServerLocations.NormalizeId((state and state.grimServerId) or ConfigServerLocations.DefaultId)
    else
        id = ConfigServerLocations.GetClientCurrentId()
    end

    local loc = ConfigServerLocations.GetById(id)
    if not loc then return true end
    return ConfigServerLocations.HasFunction(loc, "safezone")
end
