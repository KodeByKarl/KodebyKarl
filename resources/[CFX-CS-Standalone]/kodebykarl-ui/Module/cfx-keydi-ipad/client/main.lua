local ESX = exports['es_extended']:getSharedObject()
local isOpen = false
local tabletProp = nil
local opening = false

--- Non-blocking model/anim load — never spins the client when iPad is closed.
local function LoadModel(model, timeoutMs)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local deadline = GetGameTimer() + (timeoutMs or 2500)
    while not HasModelLoaded(model) do
        if GetGameTimer() > deadline then return false end
        Wait(50)
    end
    return true
end

local function LoadAnim(dict, timeoutMs)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + (timeoutMs or 2500)
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > deadline then return false end
        Wait(50)
    end
    return true
end

local function PlayAnimAsync()
    if not ConfigIpad.UseProp then return end
    CreateThread(function()
        if not isOpen then return end
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then return end

        local dict = ConfigIpad.Prop.dict
        if not LoadAnim(dict) then return end
        if not isOpen then return end
        TaskPlayAnim(ped, dict, ConfigIpad.Prop.anim, 2.0, 2.0, -1, 49, 0.0, false, false, false)

        local model = ConfigIpad.Prop.model
        if not LoadModel(model) then return end
        if not isOpen or DoesEntityExist(tabletProp) then return end

        local coords = GetEntityCoords(ped)
        tabletProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
        AttachEntityToEntity(
            tabletProp, ped, GetPedBoneIndex(ped, ConfigIpad.Prop.bone),
            ConfigIpad.Prop.offset.x, ConfigIpad.Prop.offset.y, ConfigIpad.Prop.offset.z,
            ConfigIpad.Prop.rotation.x, ConfigIpad.Prop.rotation.y, ConfigIpad.Prop.rotation.z,
            true, true, false, true, 1, true
        )
    end)
end

local function StopAnim()
    local ped = PlayerPedId()
    if ConfigIpad.UseProp then
        StopAnimTask(ped, ConfigIpad.Prop.dict, ConfigIpad.Prop.anim, 1.5)
    end
    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
    end
    tabletProp = nil
end

--- Local-only snapshot — zero server wait.
local function BuildLocalPayload()
    local data = ESX.GetPlayerData() or {}
    local accounts = data.accounts or {}
    local cash, bank = 0, 0
    for i = 1, #accounts do
        local acc = accounts[i]
        if acc.name == 'money' then cash = acc.money or 0 end
        if acc.name == 'bank' then bank = acc.money or 0 end
    end

    local gangLabel = 'None'
    local gang = LocalPlayer and LocalPlayer.state and LocalPlayer.state.gang
    if gang then
        gangLabel = gang.label or gang.name or 'None'
    end

    return {
        firstName = data.firstName or data.firstname or '',
        lastName = data.lastName or data.lastname or '',
        cash = cash,
        bank = bank,
        job = (data.job and (data.job.label or data.job.name)) or 'Unemployed',
        gang = gangLabel,
        canEditEconomy = false,
        canPoliceBoss = false,
        canSheriffBoss = false,
        canAmbulanceBoss = false,
        canPambulanceBoss = false,
        canSambulanceBoss = false,
        canDojBoss = false,
        canPoliceMdt = false,
        canSheriffMdt = false,
        canBusinessBoss = false,
        canOrgBoss = false,
        universityRole = 'visitor',
    }
end

--- Permissions in background — UI already open.
local function RefreshSessionAsync()
    CreateThread(function()
        local session = lib.callback.await('cfx-keydi-ipad:session', false)
        if not isOpen or type(session) ~= 'table' then return end
        SendNUIMessage({
            action = 'cfx-keydi-ipad:session',
            data = session,
        })
    end)
end

local function IsPlayerDeadOrDowned()
    if LocalPlayer and LocalPlayer.state then
        if LocalPlayer.state.dead or LocalPlayer.state.isDead or LocalPlayer.state.isReviving then
            return true
        end
    end

    if GetResourceState('kodebykarl-ambulance') == 'started' then
        local ok, dead = pcall(function()
            return exports['kodebykarl-ambulance']:isDead()
        end)
        if ok and dead then
            return true
        end
    end

    if ESX then
        local pd = (ESX.GetPlayerData and ESX.GetPlayerData()) or ESX.PlayerData
        if pd and pd.dead == true then
            return true
        end
    end

    local ped = PlayerPedId()
    if ped and ped ~= 0 and (IsPedDeadOrDying(ped, true) or IsPedFatallyInjured(ped) or IsEntityDead(ped)) then
        return true
    end

    return false
end

local function OpenIpad()
    if isOpen or opening then return end
    if IsPlayerDeadOrDowned() then
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification('You cannot open the iPad while unconscious.', 'error', 3000)
        end
        return
    end
    opening = true
    isOpen = true

    local payload = BuildLocalPayload()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'cfx-keydi-ipad:open',
        data = payload,
    })

    PlayAnimAsync()
    RefreshSessionAsync()
    opening = false
end

local function CloseIpad()
    if not isOpen then return end
    isOpen = false
    opening = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'cfx-keydi-ipad:close' })
    StopAnim()
end

RegisterCommand(ConfigIpad.OpenCommand, function()
    if isOpen then
        CloseIpad()
    else
        OpenIpad()
    end
end, false)

RegisterKeyMapping(ConfigIpad.OpenCommand, 'Open iPad', 'keyboard', ConfigIpad.OpenKey)

RegisterNUICallback('cfx-keydi-ipad:close', function(_, cb)
    CloseIpad()
    cb({ ok = true })
end)

-- Economy NUI only when Economy app asks — no idle cost
RegisterNUICallback('cfx-keydi-ipad:economy:getJobs', function(_, cb)
    if not isOpen then
        cb({ ok = false, jobs = {} })
        return
    end
    local result = lib.callback.await('cfx-keydi-ipad:economy:getJobs', false)
    cb(result or { ok = false, jobs = {} })
end)

RegisterNUICallback('cfx-keydi-ipad:economy:setSalary', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    data = type(data) == 'table' and data or {}
    local payload = {
        job = data.job or data.jobName,
        grade = tonumber(data.grade),
        salary = tonumber(data.salary),
    }
    local result = lib.callback.await('cfx-keydi-ipad:economy:setSalary', false, payload)
    cb(result or { ok = false, error = 'no_response' })
end)

RegisterNUICallback('cfx-keydi-ipad:market:get', function(_, cb)
    if not isOpen then
        cb({ ok = false, items = {} })
        return
    end
    local result = lib.callback.await('cfx-keydi-market:server:adminGet', false)
    cb(result or { ok = false, items = {} })
end)

RegisterNUICallback('cfx-keydi-ipad:market:setRange', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    local result = lib.callback.await('cfx-keydi-market:server:adminSetRange', false, data or {})
    cb(result or { ok = false, error = 'no_response' })
end)

RegisterNUICallback('cfx-keydi-ipad:market:reroll', function(_, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    local result = lib.callback.await('cfx-keydi-market:server:adminReroll', false)
    cb(result or { ok = false, error = 'no_response' })
end)

local function PvpResourceStarted()
    return GetResourceState('kodebykarl-pvp') == 'started'
end

RegisterNUICallback('cfx-keydi-ipad:pvp:status', function(_, cb)
    if not PvpResourceStarted() then
        cb({ ok = false, inPvp = false, players = 0, maxPlayers = 32, name = 'Deathmatch Arena', tags = {} })
        return
    end
    local result = lib.callback.await('kodebykarl-pvp:status', false)
    cb(result or { ok = false, inPvp = false, players = 0, maxPlayers = 32 })
end)

RegisterNUICallback('cfx-keydi-ipad:pvp:join', function(_, cb)
    CloseIpad()
    cb({ ok = true })
    if not PvpResourceStarted() then return end
    CreateThread(function()
        Wait(200)
        TriggerEvent('kodebykarl-pvp:client:joinFromIpad')
    end)
end)

RegisterNUICallback('cfx-keydi-ipad:pvp:leave', function(_, cb)
    CloseIpad()
    cb({ ok = true })
    if not PvpResourceStarted() then return end
    CreateThread(function()
        Wait(200)
        TriggerEvent('kodebykarl-pvp:client:leaveFromIpad')
    end)
end)

RegisterNUICallback('cfx-keydi-ipad:leaderboard:pvp', function(_, cb)
    if not isOpen then
        cb({ ok = false, rows = {} })
        return
    end
    if not PvpResourceStarted() then
        cb({ ok = false, rows = {}, mine = nil })
        return
    end
    local result = lib.callback.await('kodebykarl-pvp:getLeaderboard', false)
    cb(result or { ok = false, rows = {} })
end)

local function leaderboardCb(name)
    return lib.callback.await(name, false) or { ok = false, rows = {} }
end

RegisterNUICallback('cfx-keydi-ipad:leaderboard:turfwar', function(_, cb)
    if not isOpen then
        cb({ ok = false, rows = {} })
        return
    end
    cb(leaderboardCb('cfx-keydi-ipad:leaderboard:turfwar'))
end)

RegisterNUICallback('cfx-keydi-ipad:leaderboard:traphouse', function(_, cb)
    if not isOpen then
        cb({ ok = false, rows = {} })
        return
    end
    cb(leaderboardCb('cfx-keydi-ipad:leaderboard:traphouse'))
end)

RegisterNUICallback('cfx-keydi-ipad:leaderboard:party', function(_, cb)
    if not isOpen then
        cb({ ok = false, rows = {} })
        return
    end
    cb(leaderboardCb('cfx-keydi-ipad:leaderboard:party'))
end)

RegisterNUICallback('cfx-keydi-ipad:leaderboard:topplayer', function(_, cb)
    if not isOpen then
        cb({ ok = false, rows = {} })
        return
    end
    cb(leaderboardCb('cfx-keydi-ipad:leaderboard:topplayer'))
end)

local function businessCb(name, data)
    return lib.callback.await(name, false, data)
end

RegisterNUICallback('cfx-keydi-ipad:business:dashboard', function(_, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(businessCb('cfx-keydi-ipad:business:dashboard') or { ok = false })
end)

RegisterNUICallback('cfx-keydi-ipad:business:transfer', function(data, cb)
    if not isOpen then
        cb({ ok = false })
        return
    end
    cb(businessCb('cfx-keydi-ipad:business:transfer', data or {}) or { ok = false })
end)

RegisterNUICallback('cfx-keydi-ipad:business:hire', function(data, cb)
    if not isOpen then
        cb({ ok = false })
        return
    end
    cb(businessCb('cfx-keydi-ipad:business:hire', data or {}) or { ok = false })
end)

RegisterNUICallback('cfx-keydi-ipad:business:setGrade', function(data, cb)
    if not isOpen then
        cb({ ok = false })
        return
    end
    cb(businessCb('cfx-keydi-ipad:business:setGrade', data or {}) or { ok = false })
end)

RegisterNUICallback('cfx-keydi-ipad:business:fire', function(data, cb)
    if not isOpen then
        cb({ ok = false })
        return
    end
    cb(businessCb('cfx-keydi-ipad:business:fire', data or {}) or { ok = false })
end)

local function nearbyPlayers(maxDist)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local myId = PlayerId()
    local players = {}
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= myId then
            local tped = GetPlayerPed(player)
            if tped ~= 0 and #(coords - GetEntityCoords(tped)) <= (maxDist or 5.0) then
                players[#players + 1] = {
                    id = GetPlayerServerId(player),
                    name = GetPlayerName(player) or 'Citizen',
                }
            end
        end
    end
    return players
end

RegisterNUICallback('cfx-keydi-ipad:business:nearby', function(_, cb)
    if not isOpen then
        cb({ ok = false, players = {} })
        return
    end
    cb({ ok = true, players = nearbyPlayers(5.0) })
end)

local function orgCb(name, data)
    if GetResourceState('kodebykarl-gangsystem') ~= 'started' then
        return { ok = false, error = 'offline' }
    end
    local ok, result = pcall(function()
        return lib.callback.await(name, false, data)
    end)
    if not ok then
        print(('[cfx-keydi-ipad] callback failed %s: %s'):format(name, tostring(result)))
        return { ok = false, error = 'callback_missing', detail = tostring(result) }
    end
    if type(result) ~= 'table' then
        return { ok = false, error = 'no_response' }
    end
    return result
end

RegisterNUICallback('cfx-keydi-ipad:org:dashboard', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(orgCb('cfx-keydi-gang:org:dashboard', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:org:hire', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(orgCb('cfx-keydi-gang:org:hire', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:org:hireDiscord', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    data = type(data) == 'table' and data or {}
    local gang = data.gang
    local discord = data.discord
    if type(gang) ~= 'string' or type(discord) ~= 'string' or discord == '' then
        cb({ ok = false, error = 'invalid' })
        return
    end
    TriggerServerEvent('cfx-keydi-gang:server:hireByDiscord', gang, discord)
    cb({ ok = true, pending = true })
end)

RegisterNUICallback('cfx-keydi-ipad:org:setGrade', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(orgCb('cfx-keydi-gang:org:setGrade', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:org:fire', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(orgCb('cfx-keydi-gang:org:fire', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:org:nearby', function(_, cb)
    if not isOpen then
        cb({ ok = false, players = {} })
        return
    end
    cb({ ok = true, players = nearbyPlayers(5.0) })
end)

local function deptCb(name, data)
    local ok, result = pcall(function()
        return lib.callback.await(name, false, data)
    end)
    if not ok then
        print(('[cfx-keydi-ipad] callback failed %s: %s'):format(name, tostring(result)))
        return { ok = false, error = 'callback_missing', detail = tostring(result) }
    end
    if type(result) ~= 'table' then
        return { ok = false, error = 'no_response' }
    end
    return result
end

RegisterNUICallback('cfx-keydi-ipad:dept:dashboard', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:dept:dashboard', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:dept:transfer', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:dept:transfer', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:dept:hire', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:dept:hire', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:dept:setGrade', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:dept:setGrade', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:dept:fire', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:dept:fire', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:dept:announce', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:dept:announce', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:mdt:dashboard', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:mdt:dashboard', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:mdt:addBolo', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:mdt:addBolo', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:mdt:removeBolo', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:mdt:removeBolo', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:mdt:search', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:mdt:search', data or {}))
end)

RegisterNUICallback('cfx-keydi-ipad:mdt:addCase', function(data, cb)
    if not isOpen then
        cb({ ok = false, error = 'closed' })
        return
    end
    cb(deptCb('cfx-keydi-ipad:mdt:addCase', data or {}))
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        CloseIpad()
    end
end)

AddEventHandler('esx:onPlayerDeath', function()
    CloseIpad()
end)

AddStateBagChangeHandler('dead', nil, function(bagName, _, value)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply == PlayerId() and value then
        CloseIpad()
    end
end)

exports('OpenIpad', OpenIpad)
exports('CloseIpad', CloseIpad)
exports('IsIpadOpen', function()
    return isOpen
end)
