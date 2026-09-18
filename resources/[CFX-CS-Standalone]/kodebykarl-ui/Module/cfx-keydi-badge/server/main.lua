-- Server side logic for cfx-keydi-badge

ESX.RegisterServerCallback('cfx-keydi-badge:getBadgeData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return cb({ success = false, message = "Player not found." })
    end

    local job = xPlayer.getJob()
    if not job or not ConfigBadge.AllowedJobs[job.name] then
        return cb({ success = false, message = "You are not an active Law Enforcement Officer!" })
    end

    MySQL.single('SELECT firstname, lastname FROM users WHERE identifier = ?', { xPlayer.identifier }, function(result)
        local firstName = (result and result.firstname) or xPlayer.get('firstName') or xPlayer.getName() or "Officer"
        local lastName = (result and result.lastname) or xPlayer.get('lastName') or ""

        local department = ConfigBadge.Departments[job.name] or (string.upper(job.label) .. " DEPT")
        local rankLabel = job.grade_label or ("Grade " .. tostring(job.grade))
        local badgeNumber = string.format("LEO-%04d", source)

        cb({
            success = true,
            department = department,
            rank = rankLabel,
            firstName = firstName,
            lastName = lastName,
            badgeNumber = badgeNumber,
            jobName = job.name
        })
    end)
end)

-- Event to show badge to nearby players
RegisterNetEvent("cfx-keydi-badge:server:showBadgeToNearby", function(badgeData)
    local src = source
    if type(badgeData) ~= "table" then return end

    -- Local nui-img mugshots cannot be shared. Viewers capture the officer ped themselves.
    badgeData.photoUrl = nil

    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)

    for _, playerId in ipairs(GetPlayers()) do
        local targetPed = GetPlayerPed(playerId)
        local targetCoords = GetEntityCoords(targetPed)
        if #(srcCoords - targetCoords) <= 5.0 then
            TriggerClientEvent("cfx-keydi-badge:client:displayBadgeUI", playerId, badgeData, src)
        end
    end
end)
