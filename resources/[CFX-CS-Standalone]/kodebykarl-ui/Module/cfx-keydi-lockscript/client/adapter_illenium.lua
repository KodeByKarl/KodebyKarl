--[[
    cfx-keydi-lockscript (client/adapter_illenium.lua)
    Live enforcement + auto-skip + clearer notifies.
]]

if not ConfigLockScript or not ConfigLockScript.Enabled then return end

local cachedLocks = {}
local myIdentifier = nil
local myIdentifiers = {}
local myJob = nil
local lastNotifyAt = 0
local lastNotifyKey = nil
local enforcing = false
local enforcePausedUntil = 0

local FALLBACK_COMPONENT = {
    ["1"] = 0, ["3"] = 0, ["4"] = 0, ["5"] = 0, ["6"] = 0,
    ["7"] = 0, ["8"] = 0, ["9"] = 0, ["10"] = 0, ["11"] = 0,
}
local FALLBACK_PROP = {
    ["0"] = -1, ["1"] = -1, ["2"] = -1, ["6"] = -1, ["7"] = -1,
}

local function debugPrint(...)
    if ConfigLockScript.Debug then
        print("[cfx-keydi-lockscript:adapter]", ...)
    end
end

local function getLocalGender()
    local model = GetEntityModel(PlayerPedId())
    if model == `mp_f_freemode_01` then return "female" end
    return "male"
end

local function genderMatches(lockGender, gender)
    if not lockGender or lockGender == "any" then return true end
    return lockGender == gender
end

local function isExpired(expiresAt)
    if not expiresAt or expiresAt == "" then return false end
    return false -- server filters; client trusts cache without expired rows
end

local function identifierInMine(value)
    if not value or value == "" then return false end
    if ConfigLockScript.IdentifiersMatch(value, myIdentifier) then return true end
    for i = 1, #myIdentifiers do
        if ConfigLockScript.IdentifiersMatch(value, myIdentifiers[i]) then
            return true
        end
    end
    return false
end

local function canUseLock(lock)
    if not lock or lock.expired then return true end
    -- Never strip while identity is still loading (wake / spawn race).
    if (not myIdentifier or myIdentifier == "") and #myIdentifiers == 0 then
        return true
    end
    if identifierInMine(lock.ownerIdentifier) then return true end
    local shared = lock.sharedIdentifiers or {}
    for i = 1, #shared do
        if identifierInMine(shared[i]) then return true end
    end
    if myJob and myJob ~= "" then
        local jobs = lock.sharedJobs or {}
        local j = myJob:lower()
        for i = 1, #jobs do
            if tostring(jobs[i]):lower() == j then return true end
        end
    end
    return false
end

local function categoryLabel(categoryId)
    local cat = ConfigLockScript.CategoryById and ConfigLockScript.CategoryById[categoryId]
    return (cat and cat.label) or categoryId or "Item"
end

local function notifyExclusive(lock, key)
    local now = GetGameTimer()
    local cooldown = tonumber(ConfigLockScript.NotifyCooldownMs) or 1500
    key = key or (lock and lock.id) or "x"
    if key == lastNotifyKey and (now - lastNotifyAt) < cooldown then return end
    lastNotifyKey = key
    lastNotifyAt = now

    local owner = lock and lock.ownerName or "another player"
    local label = categoryLabel(lock and lock.category)
    local drawable = lock and lock.drawable or "?"
    local msg
    if ConfigLockScript.Locale.exclusive then
        msg = (ConfigLockScript.Locale.exclusive):format(("%s #%s"):format(label, drawable), owner)
    else
        msg = (ConfigLockScript.Locale.exclusiveGeneric or "This look is exclusive to %s."):format(owner)
    end
    lib.notify({
        title = "VIP Lock",
        description = msg,
        type = "error",
        position = "top-center",
    })
end

local function applyIdentifierPayload(payload)
    myIdentifiers = {}
    myIdentifier = nil
    if type(payload) == "table" then
        for i = 1, #payload do
            if type(payload[i]) == "string" and payload[i] ~= "" then
                myIdentifiers[#myIdentifiers + 1] = payload[i]
            end
        end
        myIdentifier = myIdentifiers[1]
    elseif type(payload) == "string" and payload ~= "" then
        myIdentifier = payload
        myIdentifiers[1] = payload
    end
end

local function refreshMyIdentity()
    local payload = lib.callback.await("cfx-keydi-lockscript:getMyIdentifier", false)
    applyIdentifierPayload(payload)
    myJob = lib.callback.await("cfx-keydi-lockscript:getMyJob", false) or myJob
    debugPrint("Identity:", myIdentifier, "aliases:", #myIdentifiers, "job:", myJob)
end

local function PauseEnforce(ms)
    local untilAt = GetGameTimer() + (tonumber(ms) or 2500)
    if untilAt > enforcePausedUntil then
        enforcePausedUntil = untilAt
    end
end

local function refreshLocks()
    local locks = lib.callback.await("cfx-keydi-lockscript:getLocks", false)
    cachedLocks = type(locks) == "table" and locks or {}
    myJob = lib.callback.await("cfx-keydi-lockscript:getMyJob", false) or myJob
    debugPrint("Cached locks:", #cachedLocks, "job:", myJob)
end

local function findBlockedLock(categoryId, componentId, drawable, texture, gender)
    gender = gender or getLocalGender()
    componentId = tostring(componentId)
    drawable = tonumber(drawable) or 0
    texture = tonumber(texture) or 0

    for i = 1, #cachedLocks do
        local lock = cachedLocks[i]
        if lock.category == categoryId
            and tostring(lock.componentId) == componentId
            and tonumber(lock.drawable) == drawable
            and genderMatches(lock.gender, gender)
            and (lock.anyTexture or tonumber(lock.texture) == texture)
            and not canUseLock(lock)
        then
            return lock
        end
    end
    return nil
end

local function categoryForComponent(componentId)
    componentId = tostring(componentId)
    for i = 1, #ConfigLockScript.Categories do
        local cat = ConfigLockScript.Categories[i]
        if cat.type == "component" and cat.componentId == componentId then
            return cat.id
        end
    end
    return nil
end

local function categoryForProp(propId)
    propId = tostring(propId)
    for i = 1, #ConfigLockScript.Categories do
        local cat = ConfigLockScript.Categories[i]
        if cat.type == "prop" and cat.componentId == propId then
            return cat.id
        end
    end
    return nil
end

local function IsPieceLocked(kind, id, drawable, texture, gender)
    gender = gender or getLocalGender()
    if kind == "component" then
        local cat = categoryForComponent(id)
        if not cat then return false, nil end
        local lock = findBlockedLock(cat, id, drawable, texture, gender)
        return lock ~= nil, lock
    elseif kind == "prop" then
        local cat = categoryForProp(id)
        if not cat then return false, nil end
        local lock = findBlockedLock(cat, id, drawable, texture, gender)
        return lock ~= nil, lock
    elseif kind == "hair" then
        local lock = findBlockedLock("hair", "hair", drawable, texture, gender)
        return lock ~= nil, lock
    elseif kind == "eyeColor" then
        local lock = findBlockedLock("eye_color", "eyeColor", drawable, 0, gender)
        return lock ~= nil, lock
    end
    return false, nil
end

local function isDrawableBlocked(kind, id, drawable, texture, gender)
    local blocked = IsPieceLocked(kind, id, drawable, texture, gender)
    return blocked
end

--- Find next unlocked drawable in a direction (auto-skip)
local function findNextUnlocked(kind, id, fromDrawable, texture, direction, gender, maxIndex)
    if not ConfigLockScript.AutoSkipLocked then return nil end
    local attempts = tonumber(ConfigLockScript.AutoSkipMaxAttempts) or 80
    direction = direction >= 0 and 1 or -1
    maxIndex = tonumber(maxIndex) or 200
    if maxIndex < 0 then maxIndex = 0 end

    for step = 1, attempts do
        local nextDraw = fromDrawable + (step * direction)
        if nextDraw < 0 then nextDraw = maxIndex end
        if nextDraw > maxIndex then nextDraw = 0 end
        if not isDrawableBlocked(kind, id, nextDraw, texture, gender) then
            return nextDraw
        end
    end
    return nil
end

local function stripComponent(ped, componentId)
    SetPedComponentVariation(ped, tonumber(componentId), FALLBACK_COMPONENT[tostring(componentId)] or 0, 0, 0)
end

local function stripProp(ped, propId)
    local fallback = FALLBACK_PROP[tostring(propId)]
    if fallback == nil or fallback < 0 then
        ClearPedProp(ped, tonumber(propId))
    else
        SetPedPropIndex(ped, tonumber(propId), fallback, 0, true)
    end
end

local function isStoryPed(ped)
    local model = GetEntityModel(ped or PlayerPedId())
    return model == `player_zero` or model == `player_one` or model == `player_two`
end

-- VIP strip during ESX spawn races SetPlayerModel and leaves the ped as Michael.
local function appearanceReady()
    if isStoryPed() then return false end
    if GetResourceState("es_extended") == "started" then
        local ok, loaded = pcall(function()
            return exports["es_extended"]:getSharedObject().PlayerLoaded
        end)
        if ok and loaded == false then return false end
    end
    return true
end

local function EnforcePedNow(silent)
    if enforcing then return false end
    if GetGameTimer() < enforcePausedUntil then return false end
    if #cachedLocks == 0 then return false end
    if not appearanceReady() then return false end
    if (not myIdentifier or myIdentifier == "") and #myIdentifiers == 0 then
        return false
    end
    enforcing = true

    local ped = PlayerPedId()
    local gender = getLocalGender()
    local denied = nil

    for i = 1, #ConfigLockScript.Categories do
        local cat = ConfigLockScript.Categories[i]
        if cat.type == "component" then
            local cid = tonumber(cat.componentId)
            local drawable = GetPedDrawableVariation(ped, cid)
            local texture = GetPedTextureVariation(ped, cid)
            local lock = findBlockedLock(cat.id, cat.componentId, drawable, texture, gender)
            if lock then
                stripComponent(ped, cid)
                denied = denied or lock
            end
        elseif cat.type == "prop" then
            local pid = tonumber(cat.componentId)
            local drawable = GetPedPropIndex(ped, pid)
            local texture = GetPedPropTextureIndex(ped, pid)
            if drawable >= 0 then
                local lock = findBlockedLock(cat.id, cat.componentId, drawable, texture, gender)
                if lock then
                    stripProp(ped, pid)
                    denied = denied or lock
                end
            end
        elseif cat.type == "hair" then
            local drawable = GetPedDrawableVariation(ped, 2)
            local texture = GetPedTextureVariation(ped, 2)
            local lock = findBlockedLock("hair", "hair", drawable, texture, gender)
            if lock then
                SetPedComponentVariation(ped, 2, 0, 0, 0)
                denied = denied or lock
            end
        elseif cat.type == "eyeColor" then
            local eye = GetPedEyeColor(ped)
            local lock = findBlockedLock("eye_color", "eyeColor", eye, 0, gender)
            if lock then
                SetPedEyeColor(ped, 0)
                denied = denied or lock
            end
        end
    end

    enforcing = false
    if denied and not silent then
        notifyExclusive(denied, ("strip:%s"):format(denied.id or "?"))
    end
    return denied ~= nil, denied
end

--[[
    TryApply* returns:
      allowed (bool),
      adjusted (table|nil)  -- auto-skip replacement to apply instead
      lock (table|nil)
]]
local function TryApplyComponent(component)
    if type(component) ~= "table" then return true, nil, nil end
    local ped = PlayerPedId()
    local cid = component.component_id
    local drawable = tonumber(component.drawable) or 0
    local texture = tonumber(component.texture) or 0
    local gender = getLocalGender()
    local blocked, lock = IsPieceLocked("component", cid, drawable, texture, gender)
    if not blocked then return true, nil, nil end

    notifyExclusive(lock, ("comp:%s:%s"):format(cid, drawable))

    local current = GetPedDrawableVariation(ped, tonumber(cid))
    local direction = drawable >= current and 1 or -1
    local maxIndex = GetNumberOfPedDrawableVariations(ped, tonumber(cid)) - 1
    if maxIndex < 0 then maxIndex = 0 end
    local nextDraw = findNextUnlocked("component", cid, drawable, texture, direction, gender, maxIndex)
    if nextDraw ~= nil then
        return false, {
            component_id = cid,
            drawable = nextDraw,
            texture = 0,
        }, lock
    end
    return false, nil, lock
end

local function TryApplyProp(prop)
    if type(prop) ~= "table" then return true, nil, nil end
    local ped = PlayerPedId()
    local pid = prop.prop_id
    local drawable = tonumber(prop.drawable)
    local texture = tonumber(prop.texture) or 0
    if not drawable or drawable < 0 then return true, nil, nil end

    local gender = getLocalGender()
    local blocked, lock = IsPieceLocked("prop", pid, drawable, texture, gender)
    if not blocked then return true, nil, nil end

    notifyExclusive(lock, ("prop:%s:%s"):format(pid, drawable))

    local current = GetPedPropIndex(ped, tonumber(pid))
    local direction = drawable >= current and 1 or -1
    local maxIndex = GetNumberOfPedPropDrawableVariations(ped, tonumber(pid)) - 1
    if maxIndex < 0 then maxIndex = 0 end
    local nextDraw = findNextUnlocked("prop", pid, drawable, texture, direction, gender, maxIndex)
    if nextDraw ~= nil then
        return false, { prop_id = pid, drawable = nextDraw, texture = 0 }, lock
    end
    return false, nil, lock
end

local function TryApplyHair(hair)
    if type(hair) ~= "table" then return true, nil, nil end
    local ped = PlayerPedId()
    local style = tonumber(hair.style or hair.drawable) or 0
    local texture = tonumber(hair.texture) or 0
    local gender = getLocalGender()
    local blocked, lock = IsPieceLocked("hair", "hair", style, texture, gender)
    if not blocked then return true, nil, nil end

    notifyExclusive(lock, ("hair:%s"):format(style))

    local current = GetPedDrawableVariation(ped, 2)
    local direction = style >= current and 1 or -1
    local maxIndex = GetNumberOfPedDrawableVariations(ped, 2) - 1
    local nextDraw = findNextUnlocked("hair", "hair", style, texture, direction, gender, maxIndex)
    if nextDraw ~= nil then
        local copy = {}
        for k, v in pairs(hair) do copy[k] = v end
        copy.style = nextDraw
        copy.texture = 0
        return false, copy, lock
    end
    return false, nil, lock
end

local function TryApplyEyeColor(eyeColor)
    local color = type(eyeColor) == "table" and (eyeColor.eyeColor or eyeColor) or eyeColor
    color = tonumber(color) or 0
    local gender = getLocalGender()
    local blocked, lock = IsPieceLocked("eyeColor", "eyeColor", color, 0, gender)
    if not blocked then return true, nil, nil end

    notifyExclusive(lock, ("eye:%s"):format(color))
    local nextDraw = findNextUnlocked("eyeColor", "eyeColor", color, 0, 1, gender, 31)
    if nextDraw ~= nil then
        return false, nextDraw, lock
    end
    return false, nil, lock
end

local function SanitizeAppearance(appearance)
    if type(appearance) ~= "table" then return appearance, nil end
    local gender = getLocalGender()
    if appearance.model then
        local m = tostring(appearance.model):lower()
        if m:find("female") or m == "mp_f_freemode_01" then gender = "female" end
    end

    local denied = nil
    if type(appearance.components) == "table" then
        for i = 1, #appearance.components do
            local c = appearance.components[i]
            if c then
                local cat = categoryForComponent(c.component_id)
                if cat then
                    local lock = findBlockedLock(cat, c.component_id, c.drawable, c.texture or 0, gender)
                    if lock then
                        c.drawable = FALLBACK_COMPONENT[tostring(c.component_id)] or 0
                        c.texture = 0
                        denied = denied or lock
                    end
                end
            end
        end
    end
    if type(appearance.props) == "table" then
        for i = 1, #appearance.props do
            local p = appearance.props[i]
            if p and (tonumber(p.drawable) or -1) >= 0 then
                local cat = categoryForProp(p.prop_id)
                if cat then
                    local lock = findBlockedLock(cat, p.prop_id, p.drawable, p.texture or 0, gender)
                    if lock then
                        p.drawable = -1
                        p.texture = -1
                        denied = denied or lock
                    end
                end
            end
        end
    end
    if type(appearance.hair) == "table" then
        local style = appearance.hair.style or appearance.hair.drawable
        local tex = appearance.hair.texture or 0
        local lock = findBlockedLock("hair", "hair", style, tex, gender)
        if lock then
            appearance.hair.style = 0
            appearance.hair.texture = 0
            denied = denied or lock
        end
    end
    if appearance.eyeColor ~= nil then
        local lock = findBlockedLock("eye_color", "eyeColor", appearance.eyeColor, 0, gender)
        if lock then
            appearance.eyeColor = 0
            denied = denied or lock
        end
    end
    if denied then notifyExclusive(denied, ("sanitize:%s"):format(denied.id or "?")) end
    return appearance, denied
end

--- Grab current ped piece for admin "Add Lock" form
local function GrabFromPed(categoryId)
    local cat = ConfigLockScript.CategoryById and ConfigLockScript.CategoryById[categoryId]
    if not cat then return nil end
    local ped = PlayerPedId()
    local gender = getLocalGender()

    if cat.type == "component" then
        local cid = tonumber(cat.componentId)
        return {
            category = cat.id,
            componentId = cat.componentId,
            drawable = GetPedDrawableVariation(ped, cid),
            texture = GetPedTextureVariation(ped, cid),
            gender = gender,
        }
    elseif cat.type == "prop" then
        local pid = tonumber(cat.componentId)
        local drawable = GetPedPropIndex(ped, pid)
        return {
            category = cat.id,
            componentId = cat.componentId,
            drawable = drawable < 0 and 0 or drawable,
            texture = drawable < 0 and 0 or GetPedPropTextureIndex(ped, pid),
            gender = gender,
        }
    elseif cat.type == "hair" then
        return {
            category = "hair",
            componentId = "hair",
            drawable = GetPedDrawableVariation(ped, 2),
            texture = GetPedTextureVariation(ped, 2),
            gender = gender,
        }
    elseif cat.type == "eyeColor" then
        return {
            category = "eye_color",
            componentId = "eyeColor",
            drawable = GetPedEyeColor(ped),
            texture = 0,
            gender = gender,
        }
    end
    return nil
end

local function GetLockedListForNUI(gender)
    gender = gender or getLocalGender()
    local out = {}
    for i = 1, #cachedLocks do
        local lock = cachedLocks[i]
        if genderMatches(lock.gender, gender) and not canUseLock(lock) then
            out[#out + 1] = {
                category = lock.category,
                componentId = lock.componentId,
                drawable = lock.drawable,
                texture = lock.texture,
                anyTexture = lock.anyTexture,
                gender = lock.gender,
                ownerName = lock.ownerName,
                locked = true,
                tooltip = ("Exclusive to %s"):format(lock.ownerName or "someone"),
            }
        end
    end
    return out
end

exports("GetLockedListForNUI", GetLockedListForNUI)
exports("GetAllCachedLocks", function() return cachedLocks end)
exports("RefreshAppearanceLocks", refreshLocks)
exports("IsPieceLocked", IsPieceLocked)
exports("TryApplyComponent", TryApplyComponent)
exports("TryApplyProp", TryApplyProp)
exports("TryApplyHair", TryApplyHair)
exports("TryApplyEyeColor", TryApplyEyeColor)
exports("SanitizeAppearance", SanitizeAppearance)
exports("EnforcePedNow", EnforcePedNow)
exports("GrabFromPed", GrabFromPed)
exports("PauseEnforce", PauseEnforce)
exports("ValidateAppearanceBeforeSave", function(appearance)
    local cleaned, denied = SanitizeAppearance(appearance)
    if denied then
        EnforcePedNow(true)
        return false, denied
    end
    return true, nil
end)

RegisterNetEvent("cfx-keydi-lockscript:client:locksChanged", function()
    refreshMyIdentity()
    refreshLocks()
    EnforcePedNow(true)
end)

RegisterNetEvent("cfx-keydi-lockscript:client:playerReady", function()
    PauseEnforce(4000)
    refreshMyIdentity()
    refreshLocks()
    local timeout = GetGameTimer() + 10000
    while not appearanceReady() and GetGameTimer() < timeout do
        Wait(250)
    end
    Wait(500)
    refreshMyIdentity()
    if appearanceReady() then
        EnforcePedNow(false)
    end
end)

RegisterNetEvent("cfx-keydi-lockscript:client:deniedLook", function(data)
    if data and data.lock then
        notifyExclusive(data.lock, "server-deny")
    elseif data and data.ownerName then
        lib.notify({
            title = "VIP Lock",
            description = (ConfigLockScript.Locale.exclusiveGeneric or "This look is exclusive to %s."):format(data.ownerName),
            type = "error",
            position = "top-center",
        })
    end
    EnforcePedNow(true)
end)

RegisterNetEvent("cfx-keydi-lockscript:client:applyAppearance", function(appearance)
    PauseEnforce(4000)
    if type(appearance) == "table" and appearance.model then
        local res = ConfigLockScript.AppearanceResource or "illenium-appearance"
        if GetResourceState(res) == "started" then
            pcall(function() exports[res]:setPlayerAppearance(appearance) end)
        end
    end
    Wait(400)
    refreshMyIdentity()
    if appearanceReady() then
        EnforcePedNow(true)
    end
end)

-- Framework load hooks
RegisterNetEvent("esx:playerLoaded", function()
    PauseEnforce(6000)
    local timeout = GetGameTimer() + 12000
    while not appearanceReady() and GetGameTimer() < timeout do
        Wait(250)
    end
    refreshMyIdentity()
    refreshLocks()
    Wait(750)
    if appearanceReady() then
        EnforcePedNow(false)
    end
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    PauseEnforce(6000)
    Wait(2000)
    refreshMyIdentity()
    refreshLocks()
    EnforcePedNow(false)
end)

RegisterNetEvent("esx:setJob", function(job)
    if type(job) == "table" then myJob = job.name end
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
    if type(job) == "table" then myJob = job.name end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(200) end
    local timeout = GetGameTimer() + 30000
    while not appearanceReady() and GetGameTimer() < timeout do
        Wait(200)
    end
    Wait(500)
    refreshMyIdentity()
    refreshLocks()
    PauseEnforce(2500)
    if appearanceReady() then
        EnforcePedNow(true)
    end

    while true do
        local sleep = tonumber(ConfigLockScript.EnforceIntervalMs) or 750
        if appearanceReady() and #cachedLocks > 0 and not enforcing and GetGameTimer() >= enforcePausedUntil then
            local stripped = EnforcePedNow(false)
            if IsNuiFocused() then
                sleep = tonumber(ConfigLockScript.EnforceIntervalMenuMs) or 100
            elseif stripped then
                sleep = 200
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler("illenium-appearance:client:reloadSkin", function()
    PauseEnforce(5000)
    CreateThread(function()
        Wait(1200)
        refreshMyIdentity()
    end)
end)
