local function decodeDocumentPayload(data)
    if type(data) == 'table' then
        return data
    end
    if type(data) == 'string' and data ~= '' then
        local ok, decoded = pcall(json.decode, data)
        if ok and type(decoded) == 'table' then
            return decoded
        end
    end
    return {}
end

local function encodeDocumentPayload(data)
    local obj = decodeDocumentPayload(data)
    obj.issuerPosition = nil
    obj.position = nil
    obj.issuerRank = nil
    obj.rank = nil
    obj.grade = nil
    obj.grade_label = nil
    if type(obj.fields) == 'table' then
        local cleaned = {}
        for i = 1, #obj.fields do
            local field = obj.fields[i]
            local fieldName = type(field) == 'table' and tostring(field.name or ''):lower() or ''
            if fieldName ~= 'position' and fieldName ~= 'job position'
                and fieldName ~= 'rank' and fieldName ~= 'job rank'
                and fieldName ~= 'issuer rank' and fieldName ~= 'grade' then
                cleaned[#cleaned + 1] = field
            end
        end
        obj.fields = cleaned
    end
    return json.encode(obj), obj
end

local function stripTemplatePosition(template)
    if type(template) ~= 'table' then return template end
    template.issuerPosition = nil
    template.position = nil
    template.issuerRank = nil
    template.rank = nil
    template.grade = nil
    template.grade_label = nil
    if type(template.fields) == 'table' then
        local cleaned = {}
        for i = 1, #template.fields do
            local field = template.fields[i]
            local fieldName = type(field) == 'table' and tostring(field.name or ''):lower() or ''
            if fieldName ~= 'position' and fieldName ~= 'job position'
                and fieldName ~= 'rank' and fieldName ~= 'job rank'
                and fieldName ~= 'issuer rank' and fieldName ~= 'grade' then
                cleaned[#cleaned + 1] = field
            end
        end
        template.fields = cleaned
    end
    return template
end

local function canIssueDocuments(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    local jobs = Config.Documents and Config.Documents.issuerJobs
    return type(jobs) == 'table' and jobs[xPlayer.job.name] == true
end

local function mapDocuments(result)
    local mapped = {}
    for i = 1, #result do
        local row = result[i]
        local thisData = decodeDocumentPayload(row.data)
        if type(thisData) == 'table' then
            thisData.id = row.id
            thisData.isCopy = row.isCopy == true or row.isCopy == 1 or row.isCopy == '1'
            if not thisData.name or thisData.name == '' then
                thisData.name = thisData.documentName or thisData.type or 'Document'
            end
            if not thisData.documentName or thisData.documentName == '' then
                thisData.documentName = thisData.name
            end
            mapped[#mapped + 1] = thisData
        end
    end
    return mapped
end

local function ensureDocumentTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `k5_documents` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `data` longtext,
            `ownerId` varchar(100),
            `isCopy` tinyint,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    -- Existing installs used varchar(50); ESX char+license identifiers are ~54 chars.
    pcall(function()
        local col = MySQL.single.await([[
            SELECT CHARACTER_MAXIMUM_LENGTH AS len
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'k5_documents'
              AND COLUMN_NAME = 'ownerId'
        ]])
        if col and tonumber(col.len) and tonumber(col.len) < 100 then
            MySQL.query.await('ALTER TABLE `k5_documents` MODIFY `ownerId` varchar(100)')
        end
    end)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `k5_document_templates` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `data` longtext,
            `job` varchar(50),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end

local function seedDefaultTemplates()
    local defaults = Config.Documents and Config.Documents.DefaultTemplates
    if type(defaults) ~= 'table' then return end

    for jobName, templates in pairs(defaults) do
        if type(templates) == 'table' and #templates > 0 then
            local count = MySQL.scalar.await(
                'SELECT COUNT(*) FROM k5_document_templates WHERE job = ?',
                { jobName }
            ) or 0

            if count < 1 then
                for i = 1, #templates do
                    local template = templates[i]
                    -- NUI expects `name`; config seeds use documentName
                    if type(template) == 'table' and not template.name and template.documentName then
                        template = {
                            minGrade = template.minGrade,
                            name = template.documentName,
                            documentName = template.documentName,
                            description = template.documentDescription or template.description,
                            documentDescription = template.documentDescription,
                            fields = template.fields,
                            infoName = template.infoName,
                            infoTemplate = template.infoTemplate,
                        }
                    end
                    MySQL.insert.await(
                        'INSERT INTO k5_document_templates (data, job) VALUES (?, ?)',
                        { json.encode(template), jobName }
                    )
                end
                print(('[cfx-cs-police] Seeded %s default document templates for job "%s"'):format(#templates, jobName))
            end
        end
    end
end

MySQL.ready(function()
    ensureDocumentTables()
    seedDefaultTemplates()
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:getPlayerCopies', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    MySQL.Async.fetchAll(
        'SELECT id, data, isCopy FROM k5_documents WHERE ownerId = @identifier AND isCopy = 1',
        { ['@identifier'] = xPlayer.identifier },
        function(result)
            cb(mapDocuments(result or {}))
        end
    )
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:getPlayerDocuments', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    MySQL.Async.fetchAll(
        'SELECT id, data, isCopy FROM k5_documents WHERE ownerId = @identifier AND isCopy = 0',
        { ['@identifier'] = xPlayer.identifier },
        function(result)
            cb(mapDocuments(result or {}))
        end
    )
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:getDocumentTemplates', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    MySQL.Async.fetchAll(
        'SELECT id, data FROM k5_document_templates WHERE job = @job',
        { ['@job'] = xPlayer.job.name },
        function(result)
            local mapped = {}
            for i = 1, #(result or {}) do
                local thisData = decodeDocumentPayload(result[i].data)
                if type(thisData) == 'table' then
                    thisData.id = result[i].id
                    if not thisData.name and thisData.documentName then
                        thisData.name = thisData.documentName
                    end
                    if not thisData.description and thisData.documentDescription then
                        thisData.description = thisData.documentDescription
                    end
                    mapped[#mapped + 1] = stripTemplatePosition(thisData)
                end
            end
            cb(mapped)
        end
    )
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:createTemplate', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not canIssueDocuments(xPlayer) then return cb(false) end

    local payload = encodeDocumentPayload(data)
    MySQL.Async.insert(
        'INSERT INTO k5_document_templates (data, job) VALUES (@data, @job)',
        {
            ['@data'] = payload,
            ['@job'] = xPlayer.job.name,
        },
        function(result)
            cb(result)
        end
    )
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:editTemplate', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not canIssueDocuments(xPlayer) then return cb(false) end

    local payload, obj = encodeDocumentPayload(data)
    MySQL.Async.execute(
        'UPDATE k5_document_templates SET data = @data WHERE id = @id',
        {
            ['@data'] = payload,
            ['@id'] = obj.id,
        },
        function(result)
            cb(result)
        end
    )
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:deleteTemplate', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not canIssueDocuments(xPlayer) then return cb(false) end

    MySQL.Async.execute(
        'DELETE FROM k5_document_templates WHERE id = @id',
        { ['@id'] = data },
        function(result)
            cb(result)
        end
    )
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:getPlayerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    MySQL.Async.fetchAll(
        'SELECT firstname, lastname, dateofbirth FROM users WHERE identifier = @identifier',
        { ['@identifier'] = xPlayer.identifier },
        function(result)
            if not result or not result[1] then
                return cb({})
            end
            cb({
                firstname = result[1].firstname,
                lastname = result[1].lastname,
                dateofbirth = result[1].dateofbirth,
                dateformat = Config.Documents.birthdateFormat,
            })
        end
    )
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:createDocument', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not canIssueDocuments(xPlayer) then return cb(false) end

    local payload, obj = encodeDocumentPayload(data)
    local docName = obj.name or obj.documentName or obj.type or 'Unknown'
    local isCopy = 0
    if obj.isCopy == true or obj.isCopy == 1 or obj.isCopy == '1' then
        isCopy = 1
    end

    MySQL.Async.insert(
        'INSERT INTO k5_documents (data, ownerId, isCopy) VALUES (@data, @ownerId, @isCopy)',
        {
            ['@data'] = payload,
            ['@ownerId'] = xPlayer.identifier,
            ['@isCopy'] = isCopy,
        },
        function(insertId)
            if insertId and PoliceLogs and PoliceLogs.Document then
                PoliceLogs.Document({
                    action = 'create',
                    src = source,
                    name = xPlayer.name,
                    identifier = xPlayer.identifier,
                    docName = docName,
                })
            end
            -- NUI expects a truthy payload so the issued list can refresh
            cb(insertId and insertId ~= 0)
        end
    )
end)

ESX.RegisterServerCallback('cfx-cs-police:documents:deleteDocument', function(source, cb, data)
    MySQL.Async.execute(
        'DELETE FROM k5_documents WHERE id = @id',
        { ['@id'] = data },
        function(result)
            cb(result)
        end
    )
end)

RegisterNetEvent('cfx-cs-police:documents:giveCopy', function(data, targetId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    local payload, obj = encodeDocumentPayload(data)
    local docName = (obj and (obj.name or obj.documentName)) or 'Document'

    MySQL.Async.insert(
        'INSERT INTO k5_documents (data, ownerId, isCopy) VALUES (@data, @ownerId, @isCopy)',
        {
            ['@data'] = payload,
            ['@ownerId'] = xTarget.identifier,
            ['@isCopy'] = 1,
        },
        function()
            TriggerClientEvent('cfx-cs-police:documents:copyGave', src, docName)
            TriggerClientEvent('cfx-cs-police:documents:copyReceived', targetId, docName)
            if PoliceLogs and PoliceLogs.Document then
                PoliceLogs.Document({
                    action = 'give',
                    src = src,
                    name = xPlayer and xPlayer.name,
                    identifier = xPlayer and xPlayer.identifier,
                    targetSrc = targetId,
                    targetName = xTarget.name,
                    targetIdentifier = xTarget.identifier,
                    docName = docName,
                })
            end
        end
    )
end)

RegisterNetEvent('cfx-cs-police:documents:receiveDocument', function(data, targetId)
    local docId = data and (data.docId or data.id)
    if not docId then return end
    MySQL.Async.fetchAll(
        'SELECT data FROM k5_documents WHERE id = @docId',
        { ['@docId'] = docId },
        function(result)
            if result and result[1] then
                local document = decodeDocumentPayload(result[1].data)
                if type(document) == 'table' and next(document) then
                    TriggerClientEvent('cfx-cs-police:documents:viewDocument', targetId, {
                        data = json.encode(document),
                    })
                end
            end
        end
    )
end)

--- Create a document for the triggering player (server API for other scripts)
RegisterNetEvent('cfx-cs-police:documents:createServerDocument', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    data.createdAt = os.date()
    MySQL.Async.insert(
        'INSERT INTO k5_documents (data, ownerId, isCopy) VALUES (@data, @ownerId, @isCopy)',
        {
            ['@data'] = json.encode(data),
            ['@ownerId'] = xPlayer.identifier,
            ['@isCopy'] = true,
        }
    )
end)
