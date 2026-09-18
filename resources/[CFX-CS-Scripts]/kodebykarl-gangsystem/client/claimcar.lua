local claimPed = nil

local FALLBACK_MODELS = {
    'g_m_y_mexgoon_02',
    'g_m_y_mexgoon_01',
    'g_m_y_strpunk_01',
    'a_m_y_mexthug_01',
    's_m_y_dealer_01',
}

local function formatPlaytime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    return ('%dh %dm'):format(h, m)
end

local function openClaimMenu()
    local status = lib.callback.await('kodebykarl-gangsystem:claimPed:status', false)
    if not status or not status.ok then
        return Gang.Notify('GANG CAR', 'Unable to load claim status.', 'error')
    end

    local options = {
        {
            title = 'Your Status',
            description = ('Playtime: %s / %s%s'):format(
                formatPlaytime(status.playtime),
                formatPlaytime(status.required),
                status.banned and '  ·  BANNED' or (status.claimed and ('  ·  Claimed [%s]'):format(status.plate or '?') or '')
            ),
            icon = 'fa-solid fa-circle-info',
            readOnly = true,
        },
    }

    if status.canClaim then
        options[#options + 1] = {
            title = 'Claim Gang Car',
            description = 'One-time claim. Leaving this gang locks you forever.',
            icon = 'fa-solid fa-file-signature',
            onSelect = function()
                local result = lib.callback.await('kodebykarl-gangsystem:claimPed:claim', false)
                if result and result.ok then
                    Gang.Notify('GANG CAR', ('Claimed [%s]. Use Take Out here.'):format(result.plate), 'success')
                else
                    Gang.Notify('GANG CAR', (result and result.message) or 'Claim failed.', 'error')
                end
            end,
        }
    elseif not status.claimed and status.banned then
        options[#options + 1] = {
            title = 'Claim Locked',
            description = 'You left/switched gangs — you can never claim a gang car.',
            icon = 'fa-solid fa-ban',
            disabled = true,
        }
    elseif not status.claimed and not status.inGang then
        options[#options + 1] = {
            title = 'Join a Gang First',
            description = 'You need to be in a gang to claim.',
            icon = 'fa-solid fa-users',
            disabled = true,
        }
    elseif not status.claimed and not status.playtimeOk then
        options[#options + 1] = {
            title = 'Need More Playtime',
            description = ('Requires %s total playtime.'):format(formatPlaytime(status.required)),
            icon = 'fa-solid fa-clock',
            disabled = true,
        }
    end

    if status.canTakeOut then
        options[#options + 1] = {
            title = 'Take Out Gang Car',
            description = ('[%s] — ped only'):format(status.plate or ''),
            icon = 'fa-solid fa-car',
            onSelect = function()
                local result = lib.callback.await('kodebykarl-gangsystem:claimPed:takeOut', false)
                if not result or not result.ok then
                    return Gang.Notify('GANG CAR', (result and result.message) or 'Take out failed.', 'error')
                end

                local ped = cache.ped or PlayerPedId()
                local timeout = GetGameTimer() + 5000
                while not NetworkDoesEntityExistWithNetworkId(result.netId) and GetGameTimer() < timeout do
                    Wait(50)
                end
                local veh = NetToVeh(result.netId)
                if veh and veh ~= 0 then
                    TaskWarpPedIntoVehicle(ped, veh, -1)
                end
                Gang.Notify('GANG CAR', ('Taken out [%s].'):format(result.plate), 'success')
            end,
        }
    end

    if status.canStore then
        options[#options + 1] = {
            title = 'Store Gang Car',
            description = 'Must be near this ped (in or with your car)',
            icon = 'fa-solid fa-warehouse',
            onSelect = function()
                local result = lib.callback.await('kodebykarl-gangsystem:claimPed:store', false)
                if result and result.ok then
                    Gang.Notify('GANG CAR', result.message or 'Stored.', 'success')
                else
                    Gang.Notify('GANG CAR', (result and result.message) or 'Store failed.', 'error')
                end
            end,
        }
    elseif status.claimed and status.banned then
        options[#options + 1] = {
            title = 'Access Locked',
            description = 'You left/switched gangs — this car can no longer be taken out.',
            icon = 'fa-solid fa-lock',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'gang_claim_ped_menu',
        title = 'Gang Vehicle',
        options = options,
    })
    lib.showContext('gang_claim_ped_menu')
end

local function loadModel(modelName)
    local hash = type(modelName) == 'number' and modelName or joaat(modelName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then return nil end
        Wait(0)
    end
    return hash
end

local function deleteClaimPed()
    if claimPed and DoesEntityExist(claimPed) then
        pcall(function()
            exports.ox_target:removeLocalEntity(claimPed)
        end)
        DeleteEntity(claimPed)
    end
    claimPed = nil
end

local function addPedTarget(entity)
    if GetResourceState('ox_target') ~= 'started' then
        print('^1[kodebykarl-gangsystem]^7 ox_target not started — claim ped has no target')
        return
    end

    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'gang_claim_vehicle',
            icon = 'fa-solid fa-car',
            label = 'Gang Vehicle',
            distance = 2.5,
            onSelect = openClaimMenu,
        },
    })
end

local function spawnClaimPed()
    local cfg = Config.ClaimPed
    if not cfg or not cfg.enabled or not cfg.coords then return end
    if claimPed and DoesEntityExist(claimPed) then return end

    deleteClaimPed()

    local models = { cfg.model }
    for i = 1, #FALLBACK_MODELS do
        models[#models + 1] = FALLBACK_MODELS[i]
    end

    local hash
    for i = 1, #models do
        hash = loadModel(models[i])
        if hash then break end
    end
    if not hash then
        print('^1[kodebykarl-gangsystem]^7 Failed to load claim ped model')
        return
    end

    local c = cfg.coords
    -- Same pattern as other scripts: spawn slightly below coords so feet sit on floor
    claimPed = CreatePed(0, hash, c.x, c.y, c.z - 1.0, c.w or 0.0, false, true)
    if not claimPed or claimPed == 0 or not DoesEntityExist(claimPed) then
        print('^1[kodebykarl-gangsystem]^7 CreatePed failed')
        SetModelAsNoLongerNeeded(hash)
        claimPed = nil
        return
    end

    SetEntityAsMissionEntity(claimPed, true, true)
    SetPedFleeAttributes(claimPed, 0, false)
    SetBlockingOfNonTemporaryEvents(claimPed, true)
    SetEntityInvincible(claimPed, true)
    FreezeEntityPosition(claimPed, true)
    SetEntityCanBeDamaged(claimPed, false)
    SetPedCanRagdoll(claimPed, false)
    SetEntityVisible(claimPed, true, false)
    SetEntityAlpha(claimPed, 255, false)
    SetPedDefaultComponentVariation(claimPed)
    SetEntityHeading(claimPed, c.w or 0.0)
    TaskStartScenarioInPlace(claimPed, 'WORLD_HUMAN_SMOKING', 0, true)

    SetModelAsNoLongerNeeded(hash)
    addPedTarget(claimPed)

    print(('[kodebykarl-gangsystem] Claim ped ready @ %.2f %.2f %.2f'):format(c.x, c.y, c.z))
end

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(200)
    end

    local tries = 0
    while tries < 150 do
        local ped = PlayerPedId()
        if ped ~= 0 and DoesEntityExist(ped) then
            if not ESX or not ESX.IsPlayerLoaded or ESX.IsPlayerLoaded() or tries > 30 then
                spawnClaimPed()
                break
            end
        end
        tries = tries + 1
        Wait(200)
    end

    if not claimPed or not DoesEntityExist(claimPed) then
        spawnClaimPed()
    end

    -- Keep ped alive if something despawns it
    while true do
        Wait(5000)
        local cfg = Config.ClaimPed
        if cfg and cfg.enabled then
            if not claimPed or not DoesEntityExist(claimPed) then
                spawnClaimPed()
            end
        end
    end
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(1500)
    spawnClaimPed()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteClaimPed()
end)
