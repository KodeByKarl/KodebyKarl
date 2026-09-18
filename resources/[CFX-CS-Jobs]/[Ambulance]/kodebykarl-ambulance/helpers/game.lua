local helpers = {}

helpers.SecondsToClock = function(seconds)
    local _seconds = tonumber(seconds)
    if _seconds <= 0 then
        return 0, 0
    else
        local hours = string.format('%02.f', math.floor(_seconds / 3600))
        local mins = string.format('%02.f', math.floor(_seconds / 60 - (hours * 60)))
        local secs = string.format('%02.f', math.floor(_seconds - hours * 3600 - mins * 60))
        return mins, secs
    end
end

helpers.createTextUI = function(text)
    lib.showTextUI(text, {
        position = "bottom-center",
        icon = 'fa-solid fa-briefcase',
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

helpers.DrawDeathTimerText = function()
    SetTextFont(4)
	SetTextScale(0.0, 0.4)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)
end

helpers.DrawAdvancedText = function(x,y,w,h,sc,text,r,g,b,a,font,jus)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(sc, sc)
	SetTextJustification(jus)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,100)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
	DrawText(x - 0.1+w, y - 0.02+h)
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