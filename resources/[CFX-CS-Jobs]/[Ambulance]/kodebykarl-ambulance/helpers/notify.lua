-- Grim ESX has ShowNotification / ox_lib, not ESX.Notify (Keydi ambulance).
local function patchNotify(esx)
    if not esx or type(esx.Notify) == 'function' then return end

    esx.Notify = function(title, message, nType, duration)
        local head, desc = title, message
        if type(desc) ~= 'string' then
            desc = title
            head = 'Notification'
        end

        local kind = nType
        if kind == 'info' then kind = 'inform' end

        if IsDuplicityVersion() then
            -- Server: no player context here; callers should use TriggerClientEvent.
            return
        end

        if lib and lib.notify then
            lib.notify({
                title = head or 'Notification',
                description = desc or '',
                type = kind or 'inform',
                duration = duration or 5000,
            })
            return
        end

        if esx.ShowNotification then
            esx.ShowNotification(desc or tostring(head), kind)
        end
    end
end

local function apply()
    local ok, obj = pcall(function()
        return ESX or exports['es_extended']:getSharedObject()
    end)
    if ok and obj then
        patchNotify(obj)
        ESX = obj
    end
end

apply()
CreateThread(function()
    if not ESX or type(ESX.Notify) ~= 'function' then
        apply()
    end
end)
