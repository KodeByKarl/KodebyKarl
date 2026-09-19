local ESX = exports['es_extended']:getSharedObject()

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

local function isPlayerBoss(jobName)
    if not ESX.PlayerData or not ESX.PlayerData.job then return false end
    local playerJob = ESX.PlayerData.job

    if jobName and jobName ~= '' and playerJob.name ~= jobName then
        return false
    end

    local gradeName = playerJob.grade_name or playerJob.gradeName
    if type(gradeName) == 'string' and gradeName:lower() == 'boss' then
        return true
    end

    if tonumber(playerJob.grade) and tonumber(playerJob.grade) >= 3 then
        return true
    end

    return false
end

local function openHireMenu(jobName, jobLabel)
    ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(onlinePlayers)
        if not onlinePlayers or #onlinePlayers == 0 then
            return lib.notify({ title = jobLabel, description = 'No players online.', type = 'error' })
        end

        local myPed = cache.ped or PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        local nearby = {}

        for i = 1, #onlinePlayers do
            local p = onlinePlayers[i]
            if p.source ~= cache.serverId then
                local targetPlayer = GetPlayerFromServerId(p.source)
                if targetPlayer and targetPlayer ~= -1 then
                    local targetPed = GetPlayerPed(targetPlayer)
                    if targetPed and targetPed ~= 0 then
                        local dist = #(myCoords - GetEntityCoords(targetPed))
                        if dist <= 5.0 then
                            nearby[#nearby + 1] = {
                                source = p.source,
                                identifier = p.identifier,
                                name = p.name or ('ID %s'):format(p.source),
                                distance = dist
                            }
                        end
                    end
                end
            end
        end

        if #nearby == 0 then
            return lib.notify({ title = jobLabel, description = 'No players nearby to hire (within 5m).', type = 'error' })
        end

        ESX.TriggerServerCallback('esx_society:getJob', function(jobData)
            local grades = (jobData and jobData.grades) or {}
            if #grades == 0 then
                return lib.notify({ title = jobLabel, description = 'No job grades found.', type = 'error' })
            end

            local playerOptions = {}
            for i = 1, #nearby do
                local player = nearby[i]
                playerOptions[#playerOptions + 1] = {
                    title = player.name,
                    description = ('ID: %s  ·  Distance: %.1fm'):format(player.source, player.distance),
                    icon = 'fa-solid fa-user-plus',
                    arrow = true,
                    onSelect = function()
                        local gradeOptions = {}
                        for g = 1, #grades do
                            local gr = grades[g]
                            gradeOptions[#gradeOptions + 1] = {
                                title = gr.label,
                                description = ('Grade %s'):format(gr.grade),
                                icon = 'fa-solid fa-id-badge',
                                onSelect = function()
                                    ESX.TriggerServerCallback('esx_society:setJob', function()
                                        lib.notify({
                                            title = jobLabel,
                                            description = ('Hired %s as %s.'):format(player.name, gr.label),
                                            type = 'success'
                                        })
                                    end, player.identifier, jobName, gr.grade, 'hire')
                                end
                            }
                        end

                        lib.registerContext({
                            id = 'business_hire_grade_select',
                            title = ('Hire %s'):format(player.name),
                            menu = 'business_hire_list',
                            options = gradeOptions
                        })
                        lib.showContext('business_hire_grade_select')
                    end
                }
            end

            lib.registerContext({
                id = 'business_hire_list',
                title = 'Hire Nearby Player',
                menu = 'business_boss_menu',
                options = playerOptions
            })
            lib.showContext('business_hire_list')
        end, jobName)
    end)
end

local function openEmployeeActions(jobName, jobLabel, emp)
    ESX.TriggerServerCallback('esx_society:getJob', function(jobData)
        local grades = (jobData and jobData.grades) or {}

        local options = {
            {
                title = 'Promote / Demote (Set Rank)',
                description = ('Current: %s (Grade %s)'):format(emp.job.grade_label, emp.job.grade),
                icon = 'fa-solid fa-ranking-star',
                arrow = true,
                onSelect = function()
                    local gradeOptions = {}
                    for i = 1, #grades do
                        local gr = grades[i]
                        gradeOptions[#gradeOptions + 1] = {
                            title = gr.label,
                            description = ('Grade %s'):format(gr.grade),
                            disabled = gr.grade == emp.job.grade,
                            icon = 'fa-solid fa-award',
                            onSelect = function()
                                ESX.TriggerServerCallback('esx_society:setJob', function()
                                    lib.notify({
                                        title = jobLabel,
                                        description = ('Updated %s to %s.'):format(emp.name, gr.label),
                                        type = 'success'
                                    })
                                end, emp.identifier, jobName, gr.grade, 'promote')
                            end
                        }
                    end

                    lib.registerContext({
                        id = 'business_employee_grade_select',
                        title = ('Rank — %s'):format(emp.name),
                        menu = 'business_employee_actions',
                        options = gradeOptions
                    })
                    lib.showContext('business_employee_grade_select')
                end
            },
            {
                title = 'Remove Employee (Fire)',
                description = 'Remove this employee from the business',
                icon = 'fa-solid fa-user-minus',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Fire Employee',
                        content = ('Are you sure you want to remove **%s** from **%s**?'):format(emp.name, jobLabel),
                        centered = true,
                        cancel = true
                    })
                    if confirm ~= 'confirm' then return end

                    ESX.TriggerServerCallback('esx_society:setJob', function()
                        lib.notify({
                            title = jobLabel,
                            description = ('Removed %s.'):format(emp.name),
                            type = 'success'
                        })
                    end, emp.identifier, 'unemployed', 0, 'fire')
                end
            }
        }

        lib.registerContext({
            id = 'business_employee_actions',
            title = emp.name,
            menu = 'business_employees_list',
            options = options
        })
        lib.showContext('business_employee_actions')
    end, jobName)
end

local function openEmployeesMenu(jobName, jobLabel)
    ESX.TriggerServerCallback('esx_society:getEmployees', function(employees)
        if not employees or #employees == 0 then
            return lib.notify({ title = jobLabel, description = 'No employees found.', type = 'error' })
        end

        local options = {}
        for i = 1, #employees do
            local emp = employees[i]
            options[#options + 1] = {
                title = emp.name,
                description = ('%s  ·  Grade %s'):format(emp.job.grade_label, emp.job.grade),
                icon = 'fa-solid fa-user',
                arrow = true,
                onSelect = function()
                    openEmployeeActions(jobName, jobLabel, emp)
                end
            }
        end

        lib.registerContext({
            id = 'business_employees_list',
            title = ('%s — Employees (%s)'):format(jobLabel, #employees),
            menu = 'business_boss_menu',
            options = options
        })
        lib.showContext('business_employees_list')
    end, jobName)
end

local function openBusinessBossMenu(targetJob)
    local playerJob = ESX.PlayerData and ESX.PlayerData.job
    if not playerJob then
        return lib.notify({ title = 'Business', description = 'Player job data not loaded.', type = 'error' })
    end

    local jobName = targetJob or playerJob.name
    local jobLabel = (targetJob and targetJob == playerJob.name and playerJob.label) or playerJob.label or 'Business'

    if not isPlayerBoss(jobName) then
        return lib.notify({ title = jobLabel, description = 'You do not have boss permissions for this business.', type = 'error' })
    end

    ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
        money = tonumber(money) or 0

        lib.registerContext({
            id = 'business_boss_menu',
            title = ('%s — Boss Menu'):format(jobLabel),
            options = {
                {
                    title = 'Society Funds',
                    description = ('Balance: $%s'):format(formatMoney(money)),
                    icon = 'fa-solid fa-sack-dollar',
                    readOnly = true
                },
                {
                    title = 'Deposit Money',
                    description = 'Deposit cash into the society account',
                    icon = 'fa-solid fa-arrow-down',
                    onSelect = function()
                        local input = lib.inputDialog('Deposit Funds', {
                            { type = 'number', label = 'Amount', icon = 'dollar-sign', min = 1, required = true }
                        })
                        if not input or not input[1] then return end
                        local amount = math.floor(tonumber(input[1]) or 0)
                        if amount > 0 then
                            TriggerServerEvent('esx_society:depositMoney', jobName, amount)
                            Wait(400)
                            openBusinessBossMenu(jobName)
                        end
                    end
                },
                {
                    title = 'Withdraw Money',
                    description = 'Withdraw cash from the society account',
                    icon = 'fa-solid fa-arrow-up',
                    onSelect = function()
                        local input = lib.inputDialog('Withdraw Funds', {
                            { type = 'number', label = 'Amount', icon = 'dollar-sign', min = 1, max = money, required = true }
                        })
                        if not input or not input[1] then return end
                        local amount = math.floor(tonumber(input[1]) or 0)
                        if amount > 0 then
                            TriggerServerEvent('esx_society:withdrawMoney', jobName, amount)
                            Wait(400)
                            openBusinessBossMenu(jobName)
                        end
                    end
                },
                {
                    title = 'Hire Employee',
                    description = 'Hire a nearby player into the business',
                    icon = 'fa-solid fa-user-plus',
                    arrow = true,
                    onSelect = function()
                        openHireMenu(jobName, jobLabel)
                    end
                },
                {
                    title = 'Manage Employees',
                    description = 'View employees, promote, demote, or fire',
                    icon = 'fa-solid fa-users-gear',
                    arrow = true,
                    onSelect = function()
                        openEmployeesMenu(jobName, jobLabel)
                    end
                }
            }
        })

        lib.showContext('business_boss_menu')
    end, jobName)
end

-- Commands
RegisterCommand('bossmenu', function()
    openBusinessBossMenu()
end, false)

RegisterCommand('businessboss', function()
    openBusinessBossMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/bossmenu', 'Open business boss menu (funds, employees, hire, promote, fire)')
TriggerEvent('chat:addSuggestion', '/businessboss', 'Open business boss menu (funds, employees, hire, promote, fire)')

-- Export
exports('OpenBossMenu', openBusinessBossMenu)

-- ox_target integration for business boss spots in Config.Business
CreateThread(function()
    if GetResourceState('ox_target') ~= 'started' then return end

    for i = 1, #(Config.Business or {}) do
        local biz = Config.Business[i]
        local boss = biz.BossAction
        if boss and boss.pos and boss.setjob then
            exports.ox_target:addBoxZone({
                coords = boss.pos,
                size = vec3(1.2, 1.2, 2.0),
                rotation = 0.0,
                debug = false,
                options = {
                    {
                        name = ('business_boss_%s'):format(boss.setjob),
                        icon = 'fa-solid fa-briefcase',
                        label = ('Open %s Boss Menu'):format(boss.joblabel or biz.BusinessName or 'Boss'),
                        groups = { [boss.setjob] = 3 },
                        onSelect = function()
                            openBusinessBossMenu(boss.setjob)
                        end,
                        distance = 2.0
                    }
                }
            })
        end
    end
end)
