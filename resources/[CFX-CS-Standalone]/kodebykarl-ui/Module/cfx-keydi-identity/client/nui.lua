-- FiveM client Lua has no `os` library. Keep all date work here os-free.

local function pad2(n)
    n = math.floor(tonumber(n) or 0)
    if n < 10 then
        return "0" .. n
    end
    return tostring(n)
end

local function isLeapYear(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local function unixToIso(ts)
    ts = math.floor(tonumber(ts) or 0)
    if ts <= 0 then
        return nil
    end
    if ts > 9999999999 then
        ts = math.floor(ts / 1000)
    end

    local days = math.floor(ts / 86400)
    local year = 1970
    while true do
        local diy = isLeapYear(year) and 366 or 365
        if days < diy then
            break
        end
        days = days - diy
        year = year + 1
        if year > 2100 then
            return nil
        end
    end

    local mdays = { 31, isLeapYear(year) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    local month = 1
    for i = 1, 12 do
        if days < mdays[i] then
            month = i
            break
        end
        days = days - mdays[i]
        month = i
    end

    return ("%04d-%s-%s"):format(year, pad2(month), pad2(days + 1))
end

local function DobToIso(dob)
    if type(dob) == "string" and dob ~= "" then
        local y, m, d = dob:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
        if y then
            return ("%s-%s-%s"):format(y, m, d)
        end
        local d2, m2, y2 = dob:match("(%d%d)/(%d%d)/(%d%d%d%d)")
        if y2 then
            return ("%s-%s-%s"):format(y2, m2, d2)
        end
    end

    local iso = unixToIso(dob)
    if iso then
        return iso
    end
    return "2005-01-01"
end

RegisterNUICallback("submitIdentity", function(data, cb)
    data = type(data) == "table" and data or {}
    IdentityUtils.Debug("submitIdentity NUI callback triggered with: %s", json.encode(data))

    if not data.firstName or data.firstName == ""
        or not data.lastName or data.lastName == ""
        or not data.dob or not data.height or not data.gender then
        cb({ error = "All fields are required." })
        return
    end

    local heightVal = tonumber(data.height)
    if not heightVal or heightVal < Config.MinHeight or heightVal > Config.MaxHeight then
        cb({ error = ("Height must be between %d and %d cm."):format(Config.MinHeight, Config.MaxHeight) })
        return
    end

    local payload = {
        firstname = data.firstName,
        lastname = data.lastName,
        dateofbirth = DobToIso(data.dob),
        height = heightVal,
        sex = Constants.Genders[data.gender] or "m"
    }

    -- Brand-new accounts: kodebykarl-identity creates the users row, then loads ESX.
    if not ESX.PlayerLoaded and GetResourceState("kodebykarl-identity") == "started" then
        local ok = pcall(function()
            exports["kodebykarl-identity"]:SubmitNewCharacter(payload)
        end)
        if ok then
            ToggleUI(false)
            cb({ success = true })
            return
        end
    end

    RegisterCharacter({
        firstname = payload.firstname,
        lastname = payload.lastname,
        dateofbirth = payload.dateofbirth,
        height = payload.height,
        sex = payload.sex,
    })
    cb({ success = true })
end)

RegisterNUICallback("closeUI", function(_, cb)
    if not ESX.PlayerLoaded then
        cb({ ok = false })
        return
    end
    ToggleUI(false)
    cb({ ok = true })
end)
