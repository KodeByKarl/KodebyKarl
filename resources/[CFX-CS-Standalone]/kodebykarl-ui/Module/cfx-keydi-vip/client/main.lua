local function Notify(title, description, nType)
    lib.notify({
        title = title or "VIP",
        description = description,
        type = nType or "inform",
        position = "top-center",
    })
end

local function OpenPedMenu()
    lib.callback("cfx-keydi-vip:canPedMenu", false, function(ok)
        if not ok then
            Notify("Reskin", "VIP 2+ or staff (admin+) required for ped menu.", "error")
            return
        end
        -- Same event staff /pedmenu uses (full ped customization)
        TriggerEvent("illenium-appearance:client:openClothingShopMenu", true)
    end)
end

local function OpenWelcomeBannerSelf()
    lib.callback("cfx-keydi-vip:canWelcomeBanner", false, function(ok)
        if not ok then
            Notify("Welcome Banner", "Active VIP required to edit your banner.", "error")
            return
        end
        ExecuteCommand(ConfigWelcomeBanner and ConfigWelcomeBanner.Command or "wcb")
    end)
end

local isVipOpen = false

local function ToggleVipMenu(state)
    if state == nil then
        isVipOpen = not isVipOpen
    else
        isVipOpen = state
    end

    SetNuiFocus(isVipOpen, isVipOpen)
    SendNUIMessage({
        action = isVipOpen and "cfx-keydi-vip:show" or "cfx-keydi-vip:hide"
    })
end

exports("ToggleVipMenu", ToggleVipMenu)

RegisterNUICallback("cfx-keydi-vip:getStatus", function(_, cb)
    lib.callback("cfx-keydi-vip:getStatus", false, function(result)
        cb(result or { vip = nil })
    end)
end)

RegisterNUICallback("cfx-keydi-vip:close", function(_, cb)
    ToggleVipMenu(false)
    cb("ok")
end)

RegisterNUICallback("cfx-keydi-vip:openPedMenu", function(_, cb)
    OpenPedMenu()
    cb({ ok = true })
end)

RegisterNUICallback("cfx-keydi-vip:openWelcomeBanner", function(_, cb)
    OpenWelcomeBannerSelf()
    cb({ ok = true })
end)

RegisterNUICallback("cfx-keydi-vip:staffRoster", function(_, cb)
    lib.callback("cfx-keydi-vip:staffRoster", false, function(result)
        cb(result or { ok = false, canManage = false })
    end)
end)

RegisterNUICallback("cfx-keydi-vip:getAllVipMembers", function(_, cb)
    lib.callback("cfx-keydi-vip:getAllVipMembers", false, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback("cfx-keydi-vip:staffEditVip", function(data, cb)
    lib.callback("cfx-keydi-vip:staffEditVip", false, function(result)
        cb(result or { ok = false })
    end, data)
end)

RegisterNUICallback("cfx-keydi-vip:staffRevokeByIdentifier", function(data, cb)
    lib.callback("cfx-keydi-vip:staffRevokeByIdentifier", false, function(result)
        cb(result or { ok = false })
    end, data and data.identifier)
end)

RegisterNUICallback("cfx-keydi-vip:staffLookup", function(data, cb)
    lib.callback("cfx-keydi-vip:staffLookup", false, function(result)
        cb(result or { ok = false })
    end, tonumber(data and data.targetId))
end)

RegisterNUICallback("cfx-keydi-vip:staffSet", function(data, cb)
    lib.callback("cfx-keydi-vip:staffSet", false, function(result)
        cb(result or { ok = false })
    end, data)
end)

RegisterNUICallback("cfx-keydi-vip:staffRevoke", function(data, cb)
    lib.callback("cfx-keydi-vip:staffRevoke", false, function(result)
        cb(result or { ok = false })
    end, tonumber(data and data.targetId))
end)

-- Main VIP container commands
RegisterCommand("viperks", function()
    ToggleVipMenu(true)
end, false)

RegisterCommand("vip", function()
    ToggleVipMenu(true)
end, false)

RegisterCommand("vipmenu", function()
    ToggleVipMenu(true)
end, false)

-- VIP players can also type /pedmenu; illenium admin ACE still works separately.
-- Note: do not RegisterCommand("pedmenu") here — illenium owns /pedmenu (staff + VIP).
RegisterCommand("vipped", function()
    OpenPedMenu()
end, false)

RegisterCommand("reskin", function()
    OpenPedMenu()
end, false)

CreateThread(function()
    TriggerEvent("chat:addSuggestion", "/pedmenu", "VIP 2/3 or staff: change character look. Use /pedmenu or /pedmenu me")
    TriggerEvent("chat:addSuggestion", "/reskin", "VIP 2/3: change your character look (not money, bank, or items)")
    TriggerEvent("chat:addSuggestion", "/vipped", "VIP 2/3: open ped menu")
end)

RegisterCommand("mybanner", function()
    OpenWelcomeBannerSelf()
end, false)
