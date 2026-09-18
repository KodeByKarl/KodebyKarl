local ESX = exports["es_extended"]:getSharedObject()
local isVisible = false

local function ToggleBanking(state, bankData, isATM)
    if isIdentityOpen then return end
    isVisible = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "cfx-keydi-banking:show" or "cfx-keydi-banking:hide",
        data = bankData,
        isATM = isATM
    })
end

local function OpenBankingMenu(isATM)
    ESX.TriggerServerCallback("cfx-keydi-banking:getBankingData", function(data)
        if data then
            ToggleBanking(true, data, isATM)
        else
            ESX.ShowNotification("Failed to retrieve banking data.", "error")
        end
    end)
end

RegisterNUICallback("cfx-keydi-banking:close", function(_, cb)
    ToggleBanking(false)
    cb("ok")
end)

RegisterNUICallback("cfx-keydi-banking:verifyPin", function(data, cb)
    local pin = data and tostring(data.pin or "")
    ESX.TriggerServerCallback("cfx-keydi-banking:verifyPin", function(success)
        cb(success == true)
    end, pin)
end)

RegisterNUICallback("cfx-keydi-banking:changePin", function(data, cb)
    local pin = data and tostring(data.pin or "")
    ESX.TriggerServerCallback("cfx-keydi-banking:changePin", function(success)
        if success then
            ESX.ShowNotification("Successfully updated your ATM PIN code.", "success")
        else
            ESX.ShowNotification("Failed to update PIN code (must be 4 digits).", "error")
        end
        cb(success == true)
    end, pin)
end)

RegisterNUICallback("cfx-keydi-banking:deposit", function(data, cb)
    ESX.TriggerServerCallback("cfx-keydi-banking:depositMoney", function(success, updatedData)
        if success then
            ESX.ShowNotification(("Successfully deposited $%s to your account."):format(data.amount), "success")
        end
        cb({ success = success, data = updatedData })
    end, tonumber(data.amount))
end)

RegisterNUICallback("cfx-keydi-banking:withdraw", function(data, cb)
    ESX.TriggerServerCallback("cfx-keydi-banking:withdrawMoney", function(success, updatedData)
        if success then
            ESX.ShowNotification(("Successfully withdrew $%s from your account."):format(data.amount), "success")
        end
        cb({ success = success, data = updatedData })
    end, tonumber(data.amount))
end)

RegisterNUICallback("cfx-keydi-banking:transfer", function(data, cb)
    ESX.TriggerServerCallback("cfx-keydi-banking:transferMoney", function(success, updatedData, message)
        if success then
            ESX.ShowNotification(message or "Transfer successful.", "success")
        else
            ESX.ShowNotification(message or "Transfer failed.", "error")
        end
        cb({ success = success, data = updatedData })
    end, {
        amount = tonumber(data.amount),
        targetType = data.targetType,
        targetVal = data.targetVal
    })
end)

-- Command / keybind only when OpenCommand is set (disabled = bank ATM / teller only)
if ConfigBanking.OpenCommand and ConfigBanking.OpenCommand ~= "" then
    RegisterCommand(ConfigBanking.OpenCommand, function()
        if isVisible then
            ToggleBanking(false)
        else
            OpenBankingMenu(false)
        end
    end, false)

    if ConfigBanking.OpenKey and ConfigBanking.OpenKey ~= "" then
        RegisterKeyMapping(ConfigBanking.OpenCommand, "Open Fleeca Banking Console", "keyboard", ConfigBanking.OpenKey)
    end
end

-- ox_target registrations
CreateThread(function()
    -- Register target options for ATMs
    exports.ox_target:addModel(ConfigBanking.ATMs, {
        {
            name = 'access_banking_atm',
            icon = 'fa-solid fa-credit-card',
            label = 'Access ATM',
            onSelect = function()
                OpenBankingMenu(true)
            end
        }
    })

    -- Register target options for Bank Tellers/Peds locations
    for i, loc in ipairs(ConfigBanking.BankPedLocations) do
        exports.ox_target:addSphereZone({
            coords = loc.coords,
            radius = 1.5,
            debug = false,
            options = {
                {
                    name = 'access_banking_teller_'..i,
                    icon = 'fa-solid fa-building-columns',
                    label = 'Access Bank Teller',
                    onSelect = function()
                        OpenBankingMenu(false)
                    end
                }
            }
        })
    end
end)
