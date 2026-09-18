local ESX = ESX or exports["es_extended"]:getSharedObject()

local isOpen = false
local pendingView = nil

local function notify(msg, nType)
    if lib and lib.notify then
        lib.notify({ description = msg, type = nType or "inform" })
        return
    end
    ESX.ShowNotification(msg)
end

local function getNearbyPlayers()
    local cfg = Config.Invoice or {}
    local maxDist = cfg.NearbyDistance or 5.0
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local list = {}

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if ped ~= 0 and DoesEntityExist(ped) then
                local dist = #(GetEntityCoords(ped) - myCoords)
                if dist <= maxDist then
                    list[#list + 1] = {
                        id = GetPlayerServerId(player),
                        name = GetPlayerName(player),
                        distance = math.floor(dist * 10) / 10,
                    }
                end
            end
        end
    end

    table.sort(list, function(a, b)
        return (a.distance or 0) < (b.distance or 0)
    end)

    return list
end

local function closeInvoice()
    if not isOpen then return end
    isOpen = false
    pendingView = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "cfx-keydi-invoice:hide" })
end

local function openInvoice(extra)
    local cfg = Config.Invoice
    if not cfg or cfg.Enabled == false then return end
    if isOpen and not (extra and extra.force) then return end

    local payload = lib.callback.await("cfx-keydi-invoice:open", false, {
        nearby = getNearbyPlayers(),
        view = extra and extra.view or nil,
        invoiceId = extra and extra.invoiceId or nil,
        reference = extra and extra.reference or nil,
        incoming = extra and extra.incoming or nil,
    })

    if not payload then
        notify("Could not open billing.", "error")
        return
    end

    isOpen = true
    pendingView = extra and extra.view or pendingView
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "cfx-keydi-invoice:show",
        data = payload,
    })
end

local function refreshInvoice(extra)
    if not isOpen then return end
    local payload = lib.callback.await("cfx-keydi-invoice:open", false, {
        nearby = getNearbyPlayers(),
        view = extra and extra.view or pendingView,
        invoiceId = extra and extra.invoiceId or nil,
        reference = extra and extra.reference or nil,
        incoming = extra and extra.incoming or nil,
    })
    if payload then
        SendNUIMessage({
            action = "cfx-keydi-invoice:update",
            data = payload,
        })
    end
end

exports("OpenInvoice", openInvoice)
exports("CloseInvoice", closeInvoice)
exports("OpenBilling", openInvoice)

RegisterCommand(Config.Invoice.OpenCommand or "billing", function()
    if isOpen then
        closeInvoice()
    else
        openInvoice()
    end
end, false)

if Config.Invoice.OpenKey and Config.Invoice.OpenKey ~= "" then
    RegisterKeyMapping(Config.Invoice.OpenCommand or "billing", "Open Billing", "keyboard", Config.Invoice.OpenKey)
end

RegisterNetEvent("cfx-keydi-invoice:client:open", function(extra)
    openInvoice(extra)
end)

RegisterNetEvent("cfx-keydi-invoice:client:notify", function(msg, nType)
    notify(msg, nType)
end)

RegisterNetEvent("cfx-keydi-invoice:client:received", function(invoice)
    local isReceipt = (invoice and invoice.kind == "personal") or (invoice and invoice.invoiceType == "Personal")
    local label = isReceipt and "receipt" or "invoice"
    notify(("New %s #%s from %s — $%s"):format(
        label,
        invoice and invoice.id or "?",
        invoice and invoice.senderName or "Unknown",
        invoice and invoice.total or 0
    ), "inform")

    local extra = { view = "detail", invoiceId = invoice and invoice.id, incoming = true, force = true }
    if isOpen then
        refreshInvoice(extra)
    else
        openInvoice(extra)
    end
end)

RegisterNetEvent("cfx-keydi-invoice:client:paid", function(invoice)
    local isReceipt = (invoice and invoice.kind == "personal") or (invoice and invoice.invoiceType == "Personal")
    local label = isReceipt and "Receipt" or "Invoice"
    notify(("%s #%s was paid ($%s)."):format(label, invoice.id or "?", invoice.total or 0), "success")
    if isOpen then
        refreshInvoice()
    end
end)

RegisterNUICallback("cfx-keydi-invoice:close", function(_, cb)
    cb("ok")
    closeInvoice()
end)

RegisterNUICallback("cfx-keydi-invoice:refresh", function(data, cb)
    pendingView = data and data.view or pendingView
    local payload = lib.callback.await("cfx-keydi-invoice:open", false, {
        nearby = getNearbyPlayers(),
        view = pendingView,
        invoiceId = data and data.invoiceId or nil,
        reference = data and data.reference or nil,
    })
    cb(payload or {})
end)

RegisterNUICallback("cfx-keydi-invoice:create", function(data, cb)
    local result = lib.callback.await("cfx-keydi-invoice:create", false, data or {})
    cb(result or { ok = false, error = "Failed" })
    if result and result.ok then
        refreshInvoice({ view = "sent" })
    end
end)

RegisterNUICallback("cfx-keydi-invoice:pay", function(data, cb)
    local result = lib.callback.await("cfx-keydi-invoice:pay", false, data or {})
    cb(result or { ok = false, error = "Failed" })
    if result and result.ok then
        refreshInvoice({ view = "detail", invoiceId = data and data.id })
    end
end)

RegisterNUICallback("cfx-keydi-invoice:reject", function(data, cb)
    local result = lib.callback.await("cfx-keydi-invoice:reject", false, data or {})
    cb(result or { ok = false, error = "Failed" })
    if result and result.ok then
        closeInvoice()
    end
end)

RegisterNUICallback("cfx-keydi-invoice:cancel", function(data, cb)
    local result = lib.callback.await("cfx-keydi-invoice:cancel", false, data or {})
    cb(result or { ok = false, error = "Failed" })
    if result and result.ok then
        refreshInvoice({ view = "sent" })
    end
end)

RegisterNUICallback("cfx-keydi-invoice:inspect", function(data, cb)
    local result = lib.callback.await("cfx-keydi-invoice:inspect", false, data and data.id)
    cb(result or { ok = false, error = "Not found" })
end)

RegisterNUICallback("cfx-keydi-invoice:lookup", function(data, cb)
    local result = lib.callback.await("cfx-keydi-invoice:lookup", false, data and data.reference)
    cb(result or { ok = false, error = "Not found" })
end)

RegisterNUICallback("cfx-keydi-invoice:city", function(data, cb)
    local result = lib.callback.await("cfx-keydi-invoice:city", false, data or {})
    cb(result or { ok = false, invoices = {}, pending = 0, paid = 0 })
end)

RegisterNUICallback("cfx-keydi-invoice:deletePaid", function(_, cb)
    local result = lib.callback.await("cfx-keydi-invoice:deletePaid", false)
    cb(result or { ok = false })
end)

RegisterNUICallback("cfx-keydi-invoice:getNearby", function(_, cb)
    cb(getNearbyPlayers())
end)
