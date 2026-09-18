-- Grim ESX has ShowNotification / ox_lib, not ESX.Notify (Keydi police modules).
local function patchNotify(esx)
    if not esx or type(esx.Notify) == 'function' then return end

    esx.Notify = function(title, message, nType, duration)
        local head, desc = title, message
        if type(desc) ~= 'string' then
            desc = title
            head = 'Notification'
        end

        local kind = nType
        if kind == 'inform' then kind = 'info' end

        if IsDuplicityVersion() then
            return
        end

        if esx.ShowNotification then
            esx.ShowNotification(desc or tostring(head), kind, duration or 5000, head)
            return
        end

        if lib and lib.notify then
            lib.notify({
                title = head or 'Notification',
                description = desc or '',
                type = kind or 'info',
                duration = duration or 5000,
            })
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
