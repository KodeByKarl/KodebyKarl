local function GetOfficerPriorityJob()
    local job = PlayerData and PlayerData.job and PlayerData.job.name
    if job == 'sheriff' then
        return 'sheriff'
    end
    return 'police'
end

local function GetPriorityUiStatus(job)
    local bag = job == 'sheriff' and 'rb_prio_sheriff' or 'rb_prio_police'
    local state = GlobalState[bag]
    if not state or state.active then
        return 'Safe'
    end
    local status = type(state.status) == 'string' and state.status:lower():gsub('%s+', '') or ''
    if status == 'inprogress' then
        return 'In Progress'
    end
    if status == 'cooldown' then
        local left = 0
        local endsAt = tonumber(state.cooldownEndsAt) or 0
        if endsAt > 0 then
            local now = (GetCloudTimeAsInt and GetCloudTimeAsInt()) or (os and os.time and os.time()) or 0
            left = math.max(0, endsAt - now)
        else
            left = math.max(0, tonumber(state.cooldown) or 0)
        end
        if left <= 0 then
            return 'Safe'
        end
        return ('Cooldown (%d:%02d)'):format(math.floor(left / 60), left % 60)
    end
    -- Hold (legacy Lockdown / Active)
    return 'Hold'
end

local function GetPriorityIconColor(status)
    if type(status) == 'string' and status:find('Cooldown', 1, true) then
        return '#FFD43B'
    end
    if status == 'In Progress' then
        return '#FF922B'
    end
    if status == 'Hold' then
        return '#FA5252'
    end
    return '#63E6BE'
end

local function CanChangePriorityStatus()
    local cfg = Config.PriorityStatus
    if not cfg or not cfg.enabled then
        return false
    end
    local job = PlayerData and PlayerData.job
    if not job or not job.name then
        return false
    end
    local minGrade = cfg.authorized and cfg.authorized[job.name]
    if minGrade == nil then
        return false
    end
    return (job.grade or 0) >= minGrade
end

local function OpenPriorityStatusMenu()
    if not HasGroup() then return end
    if not Config.PriorityStatus or not Config.PriorityStatus.enabled then return end

    local job = GetOfficerPriorityJob()
    local current = GetPriorityUiStatus(job)
    local canChange = CanChangePriorityStatus()
    local label = job == 'sheriff' and 'Paleto Sheriff' or 'LS Police'
    local options = {
        {
            title = ('Current: %s'):format(current),
            description = ('%s priority on the scoreboard'):format(label),
            icon = 'fa-solid fa-shield-halved',
            iconColor = GetPriorityIconColor(current),
            readOnly = true,
        },
    }

    if canChange then
        local statuses = { 'Safe', 'Hold', 'Cooldown', 'In Progress' }
        for i = 1, #statuses do
            local status = statuses[i]
            local isCurrent = current == status or (status == 'Cooldown' and type(current) == 'string' and current:find('Cooldown', 1, true) == 1)
            options[#options + 1] = {
                title = ('Set %s'):format(status),
                description = isCurrent and 'Currently selected' or (
                    status == 'Safe' and 'Robberies can be triggered'
                    or status == 'Hold' and 'Block all robberies until changed'
                    or status == 'Cooldown' and 'Block robberies for 15 minutes, then auto Safe'
                    or status == 'In Progress' and 'Active robbery or major crime in progress'
                    or 'Change priority status'
                ),
                icon = status == 'Safe' and 'fa-solid fa-shield'
                    or (status == 'Cooldown' and 'fa-solid fa-hourglass-half'
                    or (status == 'In Progress' and 'fa-solid fa-person-running'
                    or 'fa-solid fa-ban')),
                iconColor = GetPriorityIconColor(status),
                disabled = isCurrent,
                onSelect = function()
                    -- Update this officer's dept only (police → LS, sheriff → Paleto / rb_prio_sheriff)
                    TriggerServerEvent('cfx-cs-police:setPriorityStatus', status, job)
                end,
            }
        end
    else
        options[#options + 1] = {
            title = 'No permission',
            description = 'Your rank cannot change priority status',
            icon = 'fa-solid fa-ban',
            readOnly = true,
        }
    end

    lib.registerContext({
        id = 'police_menu_priority_status',
        title = 'Priority Status',
        menu = ('%s_quick_menu'):format(PlayerData.job.name),
        options = options,
    })
    lib.showContext('police_menu_priority_status')
end

local function OpenPoliceQuickMenu()
    local live = ESX.GetPlayerData and ESX.GetPlayerData()
    if live and live.job then
        PlayerData.job = live.job
    end
    if not HasGroup() then return end
    if Player(cache.serverId).state.dead then return end
    if Player(cache.serverId).state.isInBed then return end

    local menuOptions = {}

    if Config.PriorityStatus and Config.PriorityStatus.enabled then
        local prioJob = GetOfficerPriorityJob()
        local prioStatus = GetPriorityUiStatus(prioJob)
        menuOptions[#menuOptions + 1] = {
            title = 'Priority Status',
            description = ('Current: %s'):format(prioStatus),
            icon = 'fa-solid fa-shield-halved',
            iconColor = GetPriorityIconColor(prioStatus),
            arrow = true,
            onSelect = OpenPriorityStatusMenu,
        }
        menuOptions[#menuOptions + 1] = {
            title = 'View Scoreboard',
            description = 'Open server scoreboard & crime status (F10)',
            icon = 'fa-solid fa-clipboard-list',
            iconColor = '#4DABF7',
            onSelect = function()
                ExecuteCommand('toggleScoreboard')
            end,
        }
    end

    local extraOptions = {
        {
            title = 'Search Suspect',
            description = 'Search nearby suspect',
            icon = 'fa-solid fa-magnifying-glass',
            event = 'cfx-cs-police:searchPlayer',
        },
        {
            title = 'Check Identification',
            description = 'Check nearby player ID',
            icon = 'fa-regular fa-id-card',
            event = 'cfx-cs-police:checkId',
        },
        {
            title = 'Handcuff Suspect',
            description = 'Handcuff nearby suspect',
            icon = 'fa-solid fa-hands-bound',
            event = 'cfx-cs-police:Cuff',
        },
        {
            title = 'Uncuff Suspect',
            description = 'Uncuff nearby suspect',
            icon = 'fa-solid fa-hands-bound',
            event = 'cfx-cs-police:Uncuff',
        },
        {
            title = 'Escort Suspect',
            description = 'Escort nearby cuffed suspect',
            icon = 'fa-solid fa-hand-holding-hand',
            event = 'cfx-cs-police:EscortPlayer',
        },
        {
            title = 'Place In Vehicle',
            description = 'Put nearby cuffed suspect in vehicle',
            icon = 'fa-solid fa-arrow-right-to-bracket',
            event = 'cfx-cs-police:inVehiclePlayer',
        },
        {
            title = 'Remove From Vehicle',
            description = 'Remove nearby suspect from vehicle',
            icon = 'fa-solid fa-arrow-right-from-bracket',
            event = 'cfx-cs-police:outVehiclePlayer',
        },
        {
            title = 'Jail Suspect',
            description = 'Send nearby suspect to prison',
            icon = 'fa-solid fa-handcuffs',
            event = 'cfx-cs-police:JailPlayer',
        },
        {
            title = 'Unjail Suspect',
            description = 'Release a nearby jailed player (Officers & Directors)',
            icon = 'fa-solid fa-unlock',
            event = 'cfx-cs-police:UnjailPlayer',
        },
        {
            title = 'Issue Bill',
            description = 'Bill for impound and other charges',
            icon = 'fa-solid fa-file-invoice-dollar',
            onSelect = function()
                if GetResourceState('kodebykarl-ui') == 'started' then
                    exports['kodebykarl-ui']:OpenInvoice()
                    return
                end
                if GetResourceState('cfx-keydi-ui') == 'started' then
                    exports['cfx-keydi-ui']:OpenInvoice()
                    return
                end
                ExecuteCommand('billing')
            end,
        },
        {
            title = 'GSR Test',
            description = 'Test nearby player for gunshot residue',
            icon = 'fa-solid fa-gun',
            event = 'cfx-cs-police:gsrTest',
        },
        {
            title = 'Vehicle Interaction',
            description = 'Vehicle info, lockpick, and impound',
            icon = 'fa-solid fa-car',
            event = 'cfx-cs-police:vehicleInteractions',
        },
        {
            title = 'Place Objects',
            description = 'Place objects on the floor',
            icon = 'fa-solid fa-box',
            event = 'cfx-cs-police:OpenObjectMenu',
        },
    }

    for i = 1, #extraOptions do
        menuOptions[#menuOptions + 1] = extraOptions[i]
    end

    if ESX.HasGroup and ESX.HasGroup(Config.GiveLicense.authorized) then
        menuOptions[#menuOptions + 1] = {
            title = 'Issue Weapon License',
            description = 'Grant weapon license to nearby player',
            icon = 'fa-regular fa-id-card',
            event = 'cfx-cs-police:grantLicense',
        }
        menuOptions[#menuOptions + 1] = {
            title = 'Revoke Weapon License',
            description = 'Remove weapon license from nearby player',
            icon = 'fa-solid fa-id-card-clip',
            event = 'cfx-cs-police:revokeWeaponLicense',
        }
    end

    lib.registerContext({
        id = ('%s_quick_menu'):format(PlayerData.job.name),
        title = ('%s Menu'):format(PlayerData.job.label),
        options = menuOptions
    })
    lib.showContext(('%s_quick_menu'):format(PlayerData.job.name))
end

lib.addKeybind({
    name = 'law_menu',
    description = 'Law Enforcement Menu',
    defaultKey = 'F6',
    onPressed = function()
        OpenPoliceQuickMenu()
    end
})

RegisterNetEvent('cfx-cs-police:client:openQuickMenu', function()
    OpenPoliceQuickMenu()
end)
