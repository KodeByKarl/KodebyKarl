local SocietySystem = exports['cfx-cs-society']
local WhitelistedJobs = {
    ['police'] = 'government',
    ['ambulance'] = 'government',
    ['mechanic'] = 'government'
}

function StartPayCheck()
    CreateThread(function()
        while true do
            Wait(Config.PaycheckInterval)
            for player, xPlayer in pairs(ESX.Players) do
                local jobLabel = xPlayer.job.label
                local job = xPlayer.job.grade_name
                local onDuty = xPlayer.job.onDuty
                local salary = (job == "unemployed" or onDuty) and xPlayer.job.grade_salary or ESX.Math.Round(xPlayer.job.grade_salary * Config.OffDutyPaycheckMultiplier)

                if xPlayer.paycheckEnabled then
                    if salary > 0 then
                        if job == "unemployed" then -- unemployed
                            xPlayer.addAccountMoney("bank", salary, "Welfare Check")
                            TriggerClientEvent('esx:Notify', player, 'PAYCHECK', TranslateCap('received_help', salary), 'success', 5000)
                            if Config.LogPaycheck then
                                ESX.DiscordLogFields("Paycheck", "Paycheck - Unemployment Benefits", "green", {
                                    { name = "Player", value = xPlayer.name, inline = true },
                                    { name = "ID", value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary, inline = true },
                                })
                            end
                        elseif Config.EnableSocietyPayouts then -- possibly a society
                            local society = WhitelistedJobs[job] or xPlayer.job.name
                            local societyMoney = SocietySystem:GetAccount(society)
                            if societyMoney ~= nil then -- verified society
                                if societyMoney >= salary then
                                    xPlayer.addAccountMoney("bank", salary, "Paycheck")
                                    SocietySystem:RemoveMoney(society, salary, "Paycheck - " .. jobLabel)
                                    if Config.LogPaycheck then
                                        ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                            { name = "Player", value = xPlayer.name, inline = true },
                                            { name = "ID", value = xPlayer.source, inline = true },
                                            { name = "Amount", value = salary, inline = true },
                                        })
                                    end
                                    TriggerClientEvent('esx:Notify', player, 'PAYCHECK', TranslateCap('received_salary', salary), 'success', 5000)
                                else
                                    TriggerClientEvent('esx:Notify', player, 'PAYCHECK', TranslateCap('company_nomoney'), 'error', 5000)
                                end
                            else -- not a society
                                xPlayer.addAccountMoney("bank", salary, "Paycheck")
                                if Config.LogPaycheck then
                                    ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                        { name = "Player", value = xPlayer.name, inline = true },
                                        { name = "ID", value = xPlayer.source, inline = true },
                                        { name = "Amount", value = salary, inline = true },
                                    })
                                end
                                TriggerClientEvent('esx:Notify', player, 'PAYCHECK', TranslateCap('received_salary', salary), 'success', 5000)
                            end
                        else -- generic job
                            xPlayer.addAccountMoney("bank", salary, "Paycheck")
                            if Config.LogPaycheck then
                                ESX.DiscordLogFields("Paycheck", "Paycheck - Generic", "green", {
                                    { name = "Player", value = xPlayer.name, inline = true },
                                    { name = "ID", value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary, inline = true },
                                })
                            end
                            TriggerClientEvent('esx:Notify', player, 'PAYCHECK', TranslateCap('received_salary', salary), 'success', 5000)
                        end
                    end
                end
            end
        end
    end)
end
