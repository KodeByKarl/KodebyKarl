--[[
    Electron AC punishments for cfx-keydi-ui.
    Always invoke on "ElectronAC" even if the folder was renamed (Pandorangani).
    https://docs.electron-services.com/exports/punishments
]]

KeydiElectron = KeydiElectron or {}

local strikes = {} -- [src] = { n = number, t = number }

local STRIKE_WINDOW_MS = 8000
local STRIKES_TO_BAN = 5

local function eacCall(fn, ...)
    local args = { ... }
    return pcall(function()
        return exports["ElectronAC"][fn](table.unpack(args))
    end)
end

--- Temporarily whitelist a player from one or more Electron modules.
--- durationMs: optional auto-remove (nil = until Deny / disconnect).
function KeydiElectron.Allow(src, modules, durationMs)
    if type(src) ~= "number" or src < 1 then return end
    if type(modules) == "string" then modules = { modules } end
    if type(modules) ~= "table" then return end

    for i = 1, #modules do
        eacCall("tempWhitelistPlayer", src, modules[i])
    end

    durationMs = tonumber(durationMs)
    if durationMs and durationMs > 0 then
        SetTimeout(durationMs, function()
            if not GetPlayerName(src) then return end
            for i = 1, #modules do
                eacCall("tempUnWhitelistPlayer", src, modules[i])
            end
        end)
    end
end

function KeydiElectron.Deny(src, modules)
    if type(src) ~= "number" or src < 1 then return end
    if type(modules) == "string" then modules = { modules } end
    if type(modules) ~= "table" then return end

    for i = 1, #modules do
        eacCall("tempUnWhitelistPlayer", src, modules[i])
    end
end

function KeydiElectron.Ban(src, reason, details)
    if type(src) ~= "number" or src < 1 then return end
    reason = reason or "Trigger exploit"
    details = details or "cfx-keydi-ui"

    print(("[cfx-keydi-ui] Electron ban %s [%s]: %s (%s)"):format(GetPlayerName(src) or "?", src, reason, details))

    local ok = pcall(function()
        exports["ElectronAC"]:banPlayer(src, reason, details, true)
    end)
    if not ok then
        DropPlayer(src, reason)
    end
end

--- Count an invalid trigger. Ban after repeated hits in a short window (Probe spam).
function KeydiElectron.Flag(src, reason, details)
    if type(src) ~= "number" or src < 1 then return end

    local now = GetGameTimer()
    local entry = strikes[src]
    if not entry or (now - entry.t) > STRIKE_WINDOW_MS then
        strikes[src] = { n = 1, t = now }
        print(("[cfx-keydi-ui] Exploit strike 1/%s %s [%s]: %s"):format(STRIKES_TO_BAN, GetPlayerName(src) or "?", src, reason))
        return
    end

    entry.n = entry.n + 1
    entry.t = now
    print(("[cfx-keydi-ui] Exploit strike %s/%s %s [%s]: %s"):format(entry.n, STRIKES_TO_BAN, GetPlayerName(src) or "?", src, reason))

    if entry.n >= STRIKES_TO_BAN then
        strikes[src] = nil
        KeydiElectron.Ban(src, reason, details)
    end
end

AddEventHandler("playerDropped", function()
    strikes[source] = nil
end)
