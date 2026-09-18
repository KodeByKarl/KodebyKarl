local function nearbyPlayers(maxDist)
    local players = {}
    local myPed = cache.ped or PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local myId = PlayerId()

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= myId then
            local ped = GetPlayerPed(player)
            if ped and ped ~= 0 then
                local dist = #(myCoords - GetEntityCoords(ped))
                if dist <= (maxDist or Config.HireDistance or 5.0) then
                    local serverId = GetPlayerServerId(player)
                    players[#players + 1] = {
                        id = serverId,
                        name = GetPlayerName(player) or ('ID %s'):format(serverId),
                        distance = dist,
                    }
                end
            end
        end
    end

    table.sort(players, function(a, b)
        return a.distance < b.distance
    end)
    return players
end

local function formatMoney(n)
    n = math.floor(tonumber(n) or 0)
    local formatted = tostring(n)
    while true do
        local k
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function inputAmount(title)
    local result = lib.inputDialog(title, {
        { type = 'number', label = 'Amount', icon = 'dollar-sign', required = true, min = 1, max = Config.MaxTransfer or 1000000 },
    })
    if not result then return nil end
    return math.floor(tonumber(result[1]) or 0)
end

local function openHireMenu(gangName)
    local players = nearbyPlayers()
    if #players < 1 then
        return Gang.Notify('GANG', 'No players nearby to hire.', 'error')
    end

    local grades = lib.callback.await('kodebykarl-gangsystem:getHireGrades', false, gangName) or {}
    if #grades < 1 then
        return Gang.Notify('GANG', 'No hireable ranks available.', 'error')
    end

    local options = {}
    for i = 1, #players do
        local p = players[i]
        options[#options + 1] = {
            title = p.name,
            description = ('ID: %s  ·  %.1fm'):format(p.id, p.distance),
            icon = 'fa-solid fa-user-plus',
            arrow = true,
            onSelect = function()
                local gradeOptions = {}
                for g = 1, #grades do
                    local grade = grades[g]
                    gradeOptions[#gradeOptions + 1] = {
                        title = grade.label,
                        description = ('Grade %s'):format(grade.grade),
                        icon = 'fa-solid fa-id-badge',
                        onSelect = function()
                            local result = lib.callback.await('kodebykarl-gangsystem:hire', false, {
                                gang = gangName,
                                id = p.id,
                                grade = grade.grade,
                            })
                            if result and result.ok then
                                Gang.Notify('GANG', ('Hired %s as %s.'):format(p.name, grade.label), 'success')
                            else
                                Gang.Notify('GANG', (result and result.message) or 'Hire failed.', 'error')
                            end
                        end,
                    }
                end
                lib.registerContext({
                    id = 'gang_hire_grade',
                    title = ('Hire %s'):format(p.name),
                    menu = 'gang_hire_list',
                    options = gradeOptions,
                })
                lib.showContext('gang_hire_grade')
            end,
        }
    end

    lib.registerContext({
        id = 'gang_hire_list',
        title = 'Hire Member',
        menu = 'gang_boss_menu',
        options = options,
    })
    lib.showContext('gang_hire_list')
end

local function openMemberActions(gangName, member)
    local grades = lib.callback.await('kodebykarl-gangsystem:getHireGrades', false, gangName) or {}
    local options = {
        {
            title = 'Promote / Set Rank',
            description = ('Current: %s'):format(member.gradeLabel or member.grade),
            icon = 'fa-solid fa-arrow-up',
            arrow = true,
            onSelect = function()
                local gradeOptions = {}
                for i = 1, #grades do
                    local grade = grades[i]
                    gradeOptions[#gradeOptions + 1] = {
                        title = grade.label,
                        description = ('Grade %s'):format(grade.grade),
                        disabled = grade.grade == member.grade,
                        icon = 'fa-solid fa-ranking-star',
                        onSelect = function()
                            local result = lib.callback.await('kodebykarl-gangsystem:setGrade', false, {
                                gang = gangName,
                                identifier = member.identifier,
                                grade = grade.grade,
                            })
                            if result and result.ok then
                                Gang.Notify('GANG', ('Updated %s to %s.'):format(member.name, grade.label), 'success')
                            else
                                Gang.Notify('GANG', (result and result.message) or 'Could not update rank.', 'error')
                            end
                        end,
                    }
                end
                lib.registerContext({
                    id = 'gang_member_promote',
                    title = ('Rank — %s'):format(member.name),
                    menu = 'gang_member_actions',
                    options = gradeOptions,
                })
                lib.showContext('gang_member_promote')
            end,
        },
        {
            title = 'Remove Member',
            description = 'Kick this member from the gang',
            icon = 'fa-solid fa-user-minus',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Remove Member',
                    content = ('Remove **%s** from the gang?'):format(member.name),
                    centered = true,
                    cancel = true,
                })
                if confirm ~= 'confirm' then return end
                local result = lib.callback.await('kodebykarl-gangsystem:fire', false, {
                    gang = gangName,
                    identifier = member.identifier,
                })
                if result and result.ok then
                    Gang.Notify('GANG', ('Removed %s.'):format(member.name), 'success')
                else
                    Gang.Notify('GANG', (result and result.message) or 'Could not remove member.', 'error')
                end
            end,
        },
    }

    lib.registerContext({
        id = 'gang_member_actions',
        title = member.name,
        menu = 'gang_members_menu',
        options = options,
    })
    lib.showContext('gang_member_actions')
end

local function openMembersMenu(gangName)
    local members = lib.callback.await('kodebykarl-gangsystem:getMembers', false, gangName) or {}
    if #members < 1 then
        return Gang.Notify('GANG', 'No members found.', 'error')
    end

    local options = {}
    for i = 1, #members do
        local m = members[i]
        options[#options + 1] = {
            title = m.name,
            description = ('%s%s'):format(m.gradeLabel or ('Grade ' .. m.grade), m.online and '  ·  Online' or '  ·  Offline'),
            icon = m.online and 'fa-solid fa-circle-user' or 'fa-regular fa-circle-user',
            arrow = true,
            onSelect = function()
                openMemberActions(gangName, m)
            end,
        }
    end

    lib.registerContext({
        id = 'gang_members_menu',
        title = 'Manage Members',
        menu = 'gang_boss_menu',
        options = options,
    })
    lib.showContext('gang_members_menu')
end

local function openBossMenu()
    local data = lib.callback.await('kodebykarl-gangsystem:bossDashboard', false)
    if not data or not data.ok then
        return Gang.Notify('GANG', (data and data.message) or 'Boss access only.', 'error')
    end

    local gangName = data.gang
    local funds = tonumber(data.funds) or 0

    lib.registerContext({
        id = 'gang_boss_menu',
        title = ('%s — Boss Menu'):format(data.label or 'Gang'),
        options = {
            {
                title = 'Society Funds',
                description = ('Balance: $%s'):format(formatMoney(funds)),
                icon = 'fa-solid fa-sack-dollar',
                readOnly = true,
            },
            {
                title = 'Deposit',
                description = 'Put cash into society funds',
                icon = 'fa-solid fa-arrow-down',
                onSelect = function()
                    local amount = inputAmount('Deposit to Society')
                    if not amount or amount < 1 then return end
                    local result = lib.callback.await('kodebykarl-gangsystem:money', false, {
                        gang = gangName,
                        action = 'deposit',
                        amount = amount,
                    })
                    if result and result.ok then
                        Gang.Notify('GANG', ('Deposited $%s.'):format(formatMoney(amount)), 'success')
                    else
                        Gang.Notify('GANG', (result and result.message) or 'Deposit failed.', 'error')
                    end
                end,
            },
            {
                title = 'Withdraw',
                description = 'Take cash from society funds',
                icon = 'fa-solid fa-arrow-up',
                onSelect = function()
                    local amount = inputAmount('Withdraw from Society')
                    if not amount or amount < 1 then return end
                    local result = lib.callback.await('kodebykarl-gangsystem:money', false, {
                        gang = gangName,
                        action = 'withdraw',
                        amount = amount,
                    })
                    if result and result.ok then
                        Gang.Notify('GANG', ('Withdrew $%s.'):format(formatMoney(amount)), 'success')
                    else
                        Gang.Notify('GANG', (result and result.message) or 'Withdraw failed.', 'error')
                    end
                end,
            },
            {
                title = 'Hire',
                description = 'Hire a nearby player',
                icon = 'fa-solid fa-user-plus',
                arrow = true,
                onSelect = function()
                    openHireMenu(gangName)
                end,
            },
            {
                title = 'Manage Members',
                description = 'Promote, demote, or remove',
                icon = 'fa-solid fa-users-gear',
                arrow = true,
                onSelect = function()
                    openMembersMenu(gangName)
                end,
            },
        },
    })

    lib.showContext('gang_boss_menu')
end

RegisterCommand('gangmenu', function()
    openBossMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/gangmenu', 'Open gang boss menu (hire, funds, promote, remove)')
