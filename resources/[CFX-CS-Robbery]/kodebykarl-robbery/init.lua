Config = {}
ox_inventory = exports.ox_inventory
ox_items = ox_inventory:Items()
ESX = exports['es_extended']:getSharedObject()
local duplicity = IsDuplicityVersion()

-- Grim ESX uses ShowNotification / ox_lib, not Keydi-style ESX.Notify
if not duplicity and ESX and type(ESX.Notify) ~= 'function' then
    ESX.Notify = function(title, message, nType, duration)
        local kind = nType
        if kind == 'inform' then kind = 'info' end

        if type(message) ~= 'string' then
            message = title
            title = 'Notification'
        end

        if ESX.ShowNotification then
            ESX.ShowNotification(message or '', kind, duration or 5000, title)
            return
        end

        if lib and lib.notify then
            local libType = kind
            if libType == 'warning' then libType = 'inform' end
            if libType == 'info' then libType = 'inform' end
            lib.notify({
                title = title or 'Notification',
                description = message or '',
                type = libType or 'inform',
                duration = duration or 5000,
            })
        end
    end
end

if not duplicity then
    function HasItem(data)
        if next(data) then
            for k, v in pairs(data) do
                local itemCount = ox_inventory:Search('count', k)
                if itemCount < v then
                    ESX.Notify('ROBBERY', ('You must have %sx %s to proceed with this action.'):format(v, ox_items[k].label), 'error', 5000)
                    return false
                end
            end
        end
        return true
    end
end
