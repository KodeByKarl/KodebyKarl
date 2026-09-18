local selectingPlayer = false
local prop = nil
local DocumentZones = {}

local function SendReactMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local function Notify(msg)
    ESX.Notify(PlayerData.job and PlayerData.job.label or 'Documents', msg, 'info', 5000)
end

local function holdDocument(shouldHold)
    if shouldHold then
        detachPaper()
        playAnim('missfam4', 'base')
        attachPaper()
    else
        ClearPedTasks(cache.ped)
        detachPaper()
    end
end

function playAnim(dict, anim, duration)
    duration = duration or -1
    lib.requestAnimDict(dict, 10000)
    TaskPlayAnim(cache.ped, dict, anim, 2.0, 2.0, duration, 51, 0, false, false, false)
end

function attachPaper()
    local paper = Config.Documents.paperProp
    local coords = GetEntityCoords(cache.ped)
    lib.requestModel(paper.name, 10000)
    prop = CreateObject(joaat(paper.name), coords.x, coords.y, coords.z + 0.2, true, true, true)
    SetEntityCompletelyDisableCollision(prop, false, false)
    AttachEntityToEntity(prop, cache.ped, GetPedBoneIndex(cache.ped, 36029), 0.16, 0.08, 0.1, paper.xRot, paper.yRot, paper.zRot, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(paper.name)
end

function detachPaper()
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
    prop = nil
end

local function toggleNuiFrame(shouldShow, shouldHoldDocument)
    holdDocument(shouldHoldDocument)
    SetNuiFocus(shouldShow, shouldShow)
    SendReactMessage('setVisible', shouldShow)
end

local function toggleDocumentFrame(shouldShow, document)
    holdDocument(shouldShow)
    SetNuiFocus(shouldShow, shouldShow)
    -- NUI setDocument does JSON.parse(payload), so this must be a JSON string.
    local payload = nil
    if shouldShow and document then
        if type(document) == 'table' then
            payload = json.encode(document)
        elseif type(document) == 'string' and document ~= '' then
            payload = document
        end
    end
    SendReactMessage('setDocument', payload)
end

function OpenDocuments()
    toggleNuiFrame(true, true)
end

exports('OpenDocuments', OpenDocuments)

local documentsCommand = (Config.Documents and Config.Documents.command) or 'documents'
RegisterCommand(documentsCommand, OpenDocuments, false)
TriggerEvent('chat:addSuggestion', '/' .. documentsCommand, Config.Documents.commandHelp or 'Open your documents')

RegisterNUICallback('hideDocument', function(_, cb)
    toggleDocumentFrame(false, nil)
    cb({})
end)

RegisterNUICallback('hideFrame', function(_, cb)
    toggleNuiFrame(false, false)
    cb({})
end)

RegisterNUICallback('getPlayerJob', function(_, cb)
    local job = PlayerData and PlayerData.job
    if (not job or not job.name) and ESX.GetPlayerData then
        local live = ESX.GetPlayerData()
        job = live and live.job
        if job then
            PlayerData.job = job
        end
    end
    if not job or not job.name then
        cb({})
        return
    end
    cb({
        grade = tonumber(job.grade) or 0,
        grade_label = job.grade_label,
        grade_name = job.grade_name,
        grade_salary = job.grade_salary,
        label = job.label,
        name = job.name,
        isBoss = job.grade_name == 'boss',
        -- Position is intentionally omitted from templates
        position = nil,
    })
end)

RegisterNUICallback('getPlayerData', function(_, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:getPlayerData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('getPlayerCopies', function(_, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:getPlayerCopies', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('getIssuedDocuments', function(_, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:getPlayerDocuments', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('createDocument', function(data, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:createDocument', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('createTemplate', function(data, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:createTemplate', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('editTemplate', function(data, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:editTemplate', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('deleteTemplate', function(data, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:deleteTemplate', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('deleteDocument', function(data, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:deleteDocument', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getMyTemplates', function(_, cb)
    ESX.TriggerServerCallback('cfx-cs-police:documents:getDocumentTemplates', function(result)
        cb(result)
    end)
end)

local function playerSelector(confirmText)
    toggleNuiFrame(false, true)
    selectingPlayer = true
    local maxDistance = 5.0

    while selectingPlayer do
        local coords = GetEntityCoords(cache.ped)
        local closestId, _, closestCoords = lib.getClosestPlayer(coords, maxDistance, false)

        DisableControlAction(2, 200, true)

        if IsControlJustReleased(0, 202) then
            selectingPlayer = false
            return -1
        end

        BeginTextCommandDisplayHelp('main')
        AddTextEntry('main', ('~INPUT_CONTEXT~ %s  ~INPUT_FRONTEND_PAUSE_ALTERNATE~ %s'):format(confirmText, Config.Documents.locale.cancel))
        EndTextCommandDisplayHelp(0, 0, 1, -1)

        if closestId and closestCoords then
            DrawMarker(20, closestCoords.x, closestCoords.y, closestCoords.z + 1.2, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.4, 0.4, -0.4, 255, 255, 255, 100, false, true, 2, false, false, false, false)
            DrawMarker(25, closestCoords.x, closestCoords.y, closestCoords.z - 0.95, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, false, false, false, false)
            if IsControlJustReleased(0, 38) then
                selectingPlayer = false
                return GetPlayerServerId(closestId)
            end
        elseif IsControlJustReleased(0, 38) then
            Notify(Config.Documents.locale.noPlayersAround)
        end
        Wait(0)
    end
end

RegisterNUICallback('giveCopy', function(data, cb)
    CreateThread(function()
        local targetId = playerSelector(Config.Documents.locale.giveCopy)
        if targetId == -1 then
            holdDocument(false)
        else
            TriggerServerEvent('cfx-cs-police:documents:giveCopy', data, targetId)
        end
        cb({})
    end)
end)

RegisterNUICallback('showDocument', function(data, cb)
    CreateThread(function()
        local targetId = playerSelector(Config.Documents.locale.showDocument)
        if targetId == -1 then
            holdDocument(false)
        else
            holdDocument(false)
            playAnim('mp_common', 'givetake1_a', 1500)
            TriggerServerEvent('cfx-cs-police:documents:receiveDocument', data, targetId)
        end
        cb({})
    end)
end)

RegisterNetEvent('cfx-cs-police:documents:copyGave', function(data)
    holdDocument(false)
    playAnim('mp_common', 'givetake1_a', 1500)
    Notify(Config.Documents.locale.giveNotification .. ' ' .. data)
end)

RegisterNetEvent('cfx-cs-police:documents:copyReceived', function(data)
    Notify(Config.Documents.locale.receiveNotification .. ' ' .. data)
end)

RegisterNetEvent('cfx-cs-police:documents:viewDocument', function(data)
    local document = data
    if type(data) == 'table' and data.data ~= nil then
        document = data.data
    end
    if type(document) == 'string' then
        local ok, decoded = pcall(json.decode, document)
        if ok and type(decoded) == 'table' then
            document = decoded
        else
            document = nil
        end
    end
    if type(document) ~= 'table' then
        Notify('Could not open that document.')
        return
    end
    toggleDocumentFrame(true, document)
end)

local function canUseDocuments(loc)
    local job = PlayerData and PlayerData.job
    if (not job or not job.name) and ESX.GetPlayerData then
        job = ESX.GetPlayerData().job
    end
    if not job or not job.name then return false end

    if loc and loc.jobs then
        local minGrade = loc.jobs[job.name]
        if minGrade == nil then return false end
        return (tonumber(job.grade) or 0) >= (tonumber(minGrade) or 0)
    end

    if loc and loc.job then
        return job.name == loc.job
    end

    return HasGroup()
end

CreateThread(function()
    local locations = Config.Documents and Config.Documents.locations
    if not locations then return end

    for i = 1, #locations do
        local loc = locations[i]
        DocumentZones[i] = ox_target:addSphereZone({
            coords = loc.coords,
            radius = loc.radius or 1.5,
            debug = false,
            options = {
                {
                    name = ('cfx_cs_police_documents_%s'):format(i),
                    label = loc.label or 'Open Documents',
                    icon = loc.icon or 'fa-solid fa-file-lines',
                    distance = 2.0,
                    canInteract = function()
                        return canUseDocuments(loc)
                    end,
                    onSelect = function()
                        if not canUseDocuments(loc) then
                            ESX.Notify('Documents', 'You cannot use this desk.', 'error', 5000)
                            return
                        end
                        OpenDocuments()
                    end,
                },
            },
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #DocumentZones do
        if DocumentZones[i] then
            ox_target:removeZone(DocumentZones[i])
        end
    end
    detachPaper()
end)
