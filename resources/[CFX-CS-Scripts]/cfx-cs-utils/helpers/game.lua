local helpers = {}

helpers.createTextUI = function(text, icon, position)
    lib.showTextUI(text, {
        id = 'cfx-cs-utils',
        position = position or "bottom-center",
        icon = icon or 'fa-solid fa-briefcase',
        style = {
            backgroundColor = '#2a2a2a',
            color = '#f0f0f0',
            padding = '16px 20px',
            fontSize = '15px',
            fontWeight = '500',
            fontFamily = 'Segoe UI, sans-serif',
            borderRadius = '13px',
            boxShadow = '8px 8px 15px rgba(0,0,0,0.4), -4px -4px 10px rgba(255,255,255,0.05)',
            border = '1px solid rgba(255, 255, 255, 0.05)',
            ['.description'] = {
                color = '#d0d0d0',
                fontSize = '13px',
                marginTop = '6px'
            }
        }
    })
end

helpers.hideTextUI = function()
    lib.hideTextUI('cfx-cs-utils')
end

helpers.createBlip = function(blipData)
    local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
    SetBlipSprite(blip, blipData.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, blipData.scale)
    SetBlipColour(blip, blipData.color)
    BeginTextCommandSetBlipName("STRING")
    SetBlipAsShortRange(blip, true)
    AddTextComponentSubstringPlayerName(blipData.label)
    EndTextCommandSetBlipName(blip)
end

helpers.getJob = function()
    return ESX.GetPlayerData().job
end

helpers.secondsToClock = function(seconds)
    seconds = tonumber(seconds)
    if not seconds or seconds <= 0 then return "00:00" end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, mins, secs)
    else
        return string.format("%02d:%02d", mins, secs)
    end
end


helpers.HasJob = function(requireJob, xPlayer)
    if IsDuplicityVersion() then
        local type = type(requireJob)
        if type == 'string' then
            local data = xPlayer.job
            if data.name == requireJob then
                return true
            end
        else
            local tabletype = table.type(requireJob)
            if tabletype == 'hash' then
                local data = xPlayer.job
                local grade = requireJob[data.name]
                local playerGrade = data.grade
                if grade and grade <= playerGrade then
                    return true
                end
            elseif tabletype == 'array' then
                for i = 1, #requireJob do
                    local group = requireJob[i]
                    local data = xPlayer.job
                    if data.name == group then
                        return true
                    end
                end
            end
        end
    else
        local type = type(requireJob)
        local job = ESX.GetPlayerData().job
        if type == 'string' then
            local data = job
            if data.name == requireJob then
                return true
            end
        else
            local tabletype = table.type(requireJob)
            if tabletype == 'hash' then
                local data = job
                local grade = requireJob[data.name]
                local playerGrade = data.grade
                if grade and grade <= playerGrade then
                    return true
                end
            elseif tabletype == 'array' then
                for i = 1, #requireJob do
                    local group = requireJob[i]
                    local data = job
                    if data.name == group then
                        return true
                    end
                end
            end
        end
    end
    return false
end

return helpers