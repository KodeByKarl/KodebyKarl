--[[
    cfx-keydi-lockscript
    Exclusive appearance / clothing permission locks (admin VIP locks).
]]

ConfigLockScript = {}

ConfigLockScript.Enabled = true
ConfigLockScript.Debug = false

--[[
    Framework:
      'auto' | 'esx' | 'qbcore' | 'standalone'
]]
ConfigLockScript.Framework = "auto"

-- Set to false / "" to rely on StaffGroups only
ConfigLockScript.AcePermission = false

-- Only these ESX/QB groups can use /viplock
ConfigLockScript.StaffGroups = {
    owner = true,
    developer = true,
}

ConfigLockScript.Commands = {
    open = "viplock",
}

ConfigLockScript.Brand = "GRIM CITY"
ConfigLockScript.OfflineSearchLimit = 30
ConfigLockScript.AppearanceResource = "illenium-appearance"

-- When browsing a locked drawable, jump to the next unlocked index
ConfigLockScript.AutoSkipLocked = true
ConfigLockScript.AutoSkipMaxAttempts = 80

-- Live ped strip interval (ms). Faster while NUI focused.
ConfigLockScript.EnforceIntervalMs = 750
ConfigLockScript.EnforceIntervalMenuMs = 100

-- Notify debounce (ms)
ConfigLockScript.NotifyCooldownMs = 1500

ConfigLockScript.Locale = {
    noPermission = "You do not have permission to use this command.",
    exclusive = "%s is exclusive to %s.", -- e.g. "Mask #5 is exclusive to Carlito"
    exclusiveGeneric = "This look is exclusive to %s.",
    lockAdded = "Lock created.",
    lockRemoved = "Lock removed.",
    lockFailed = "Failed to create lock.",
    invalidInput = "Invalid lock data.",
    accessGranted = "Shared access updated.",
    accessRevoked = "Shared access revoked.",
    alreadyLocked = "That drawable is already locked.",
    notFound = "Lock not found.",
    imported = "Imported %d lock(s).",
    expiredCleaned = "Removed %d expired lock(s).",
    grabFailed = "Could not read ped appearance.",
}

--[[
    Discord logs (same bot pattern as comserv).
    Create a text channel named VIPLOCK or set ChannelIDs manually.
]]
ConfigLockScript.Logs = {
    Enabled = true,
    BotToken = "MTUzNjM2NDUyMjc5MTUwNjA0Mg.GfAaOT.pXdZcrMv-0yl2Blw9cESfKGSbv56AvD5C6-jTo",
    GuildID = "1536358290777444397",

    ChannelNames = {
        lock = "VIPLOCK",
        blocked = "VIPLOCK",
        access = "VIPLOCK",
    },

    ChannelIDs = {
        lock = "",
        blocked = "",
        access = "",
    },

    LogTypes = {
        lockAdd = true,
        lockRemove = true,
        access = true,
        blocked = true,
        import = true,
    },

    EmbedColors = {
        lockAdd = 5763719,
        lockRemove = 15158332,
        access = 3447003,
        blocked = 15105570,
        import = 10181046,
    },

    PostCooldownMs = 500,
}

--[[
    Lockable categories only.
]]
ConfigLockScript.Categories = {
    { id = "hair",      label = "Hair",               type = "hair",     componentId = "hair",     group = "head" },
    { id = "eye_color", label = "Eye Color",          type = "eyeColor", componentId = "eyeColor", group = "head" },

    { id = "mask",        label = "Mask",               type = "component", componentId = "1",  group = "clothes" },
    { id = "accessories", label = "Scarf and Chains",   type = "component", componentId = "7",  group = "clothes" },
    { id = "jacket",      label = "Jacket",             type = "component", componentId = "11", group = "clothes" },
    { id = "shirt",       label = "Shirt",              type = "component", componentId = "8",  group = "clothes" },
    { id = "bproof",      label = "Body Armor",         type = "component", componentId = "9",  group = "clothes" },
    { id = "bags",        label = "Bags and Parachute", type = "component", componentId = "5",  group = "clothes" },
    { id = "hands",       label = "Hands",              type = "component", componentId = "3",  group = "clothes" },
    { id = "legs",        label = "Legs",               type = "component", componentId = "4",  group = "clothes" },
    { id = "shoes",       label = "Shoes",              type = "component", componentId = "6",  group = "clothes" },
    { id = "decals",      label = "Decals",             type = "component", componentId = "10", group = "clothes" },

    { id = "hats",      label = "Hats",      type = "prop", componentId = "0", group = "props" },
    { id = "glasses",   label = "Glasses",   type = "prop", componentId = "1", group = "props" },
    { id = "ears",      label = "Ear",       type = "prop", componentId = "2", group = "props" },
    { id = "watches",   label = "Watches",   type = "prop", componentId = "6", group = "props" },
    { id = "bracelets", label = "Bracelet",  type = "prop", componentId = "7", group = "props" },
}

ConfigLockScript.CategoryById = {}
for i = 1, #ConfigLockScript.Categories do
    local cat = ConfigLockScript.Categories[i]
    ConfigLockScript.CategoryById[cat.id] = cat
end

ConfigLockScript.Genders = {
    { id = "male", label = "Male" },
    { id = "female", label = "Female" },
    { id = "any", label = "Any" },
}

--- Strip charN: / license: / license2: so VIP owner checks survive ESX format drift.
function ConfigLockScript.NormalizeIdentifier(id)
    if type(id) ~= "string" then return "" end
    id = id:gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if id == "" then return "" end
    id = id:gsub("^char%d+:", "")
    local prev
    repeat
        prev = id
        id = id:gsub("^license2:", ""):gsub("^license:", "")
    until id == prev
    return id
end

function ConfigLockScript.IdentifiersMatch(a, b)
    if type(a) ~= "string" or type(b) ~= "string" then return false end
    if a == "" or b == "" then return false end
    if a == b then return true end
    if a:lower() == b:lower() then return true end
    local ha = ConfigLockScript.NormalizeIdentifier(a)
    local hb = ConfigLockScript.NormalizeIdentifier(b)
    return ha ~= "" and ha == hb
end

