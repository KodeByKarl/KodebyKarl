local ox_inventory = exports.ox_inventory
local ESX = exports['es_extended']:getSharedObject()

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
        for i = 1, #Config.Business do
            local trayData = Config.Business[i].Tray
            local bossData = Config.Business[i].BossAction
            if trayData then
                for tray = 1, #trayData do
                    if trayData[tray] and trayData[tray].id then
                        ox_inventory:RegisterStash(trayData[tray].id, trayData[tray].label, trayData[tray].slots, trayData[tray].maxWeight, trayData[tray].owner)
                    end
                end
            end
            if bossData and bossData.setjob and bossData.society then
                TriggerEvent('esx_society:registerSociety', bossData.setjob, bossData.joblabel, bossData.society, bossData.society, bossData.society, {type = 'public'})
            end
        end
    end
end)
