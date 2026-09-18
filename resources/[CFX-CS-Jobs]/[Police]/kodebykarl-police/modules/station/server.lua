local function dutyJobs()
    return 'police', Config.OffDutyJob or 'offpolice'
end

RegisterNetEvent('cfx-cs-police:toggleDuty', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then return end

    local onDuty, offDuty = dutyJobs()
    local name = xPlayer.job.name
    local grade = xPlayer.job.grade or 0

    if name ~= onDuty and name ~= offDuty then
        TriggerClientEvent('esx:Notify', src, 'POLICE', 'You are not police personnel.', 'error', 5000)
        return
    end

    if name == onDuty then
        if ESX.DoesJobExist and not ESX.DoesJobExist(offDuty, grade) then
            TriggerClientEvent('esx:Notify', src, 'POLICE', 'Off-duty job is not configured.', 'error', 5000)
            return
        end
        xPlayer.setJob(offDuty, grade)
        TriggerClientEvent('esx:Notify', src, 'POLICE', 'You are now OFF DUTY.', 'warning', 5000)
        return
    end

    if ESX.DoesJobExist and not ESX.DoesJobExist(onDuty, grade) then
        TriggerClientEvent('esx:Notify', src, 'POLICE', 'On-duty job is not configured.', 'error', 5000)
        return
    end
    xPlayer.setJob(onDuty, grade)
    TriggerClientEvent('esx:Notify', src, 'POLICE', 'You are now ON DUTY.', 'success', 5000)
end)
