ESX = exports['es_extended']:getSharedObject()
ox_inventory = exports.ox_inventory
cuffedPlayers = {}

function HasGroup(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer or not xPlayer.job or not xPlayer.job.name then
        return false
    end
    return type(Config.LawEnforcement[xPlayer.job.name]) == 'table'
end

AddEventHandler('playerDropped', function()
    local src = source
    if cuffedPlayers[src] then
        cuffedPlayers[src] = nil
    end
end)


RegisterNetEvent('cfx-cs-police:Tackle:tryTackle', function(target)
    local src = source
    if target == -1 then return end
    if not ESX.VerifyDistance(src, target, 4.0, 'cfx-cs-police:Tackle:tryTackle') then return end
    if not HasGroup(src) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
	local xTarget = ESX.GetPlayerFromId(target)
	if not xTarget then return end
    if not xPlayer then return end
    TriggerClientEvent('cfx-cs-police:Tackle:getTackled', xTarget.source, src)
    TriggerClientEvent('cfx-cs-police:Tackle:playTackle', src)
end)

function DiscordFormat(xPlayer, description, xTarget)
    local Formatted = {
        ('**------- %s Details -------**\n'):format(xPlayer.job.label),
        ('**Name**: `%s`\n'):format(xPlayer.name),
        ('**ID**: `%s`\n'):format(xPlayer.source),
        ('**License**: `%s`\n'):format('license:'..xPlayer.identifier),
        ('**Location**: `%s`\n'):format(xPlayer.getCoords(true)),
        ('**Job**: `%s`\n'):format(xPlayer.job.label),
        ('**Job Rank**: `%s`\n\n'):format(xPlayer.job.grade_label),
        ('**------- Other -------**\n'),
        ('**Description**: %s'):format(description)
    }
    if xTarget then
        table.insert(Formatted, '\n\n**------- Target Player -------**\n')
        table.insert(Formatted, ('**Name**: `%s`\n'):format(xTarget.name))
        table.insert(Formatted, ('**ID**: `%s`\n'):format(xTarget.source))
        table.insert(Formatted, ('**License**: `%s`\n'):format('license:'..xTarget.identifier))
        table.insert(Formatted, ('**Location**: `%s`\n'):format(xTarget.getCoords(true)))
    end
    return table.concat(Formatted)
end

lib.addCommand('givecs', {
    help = 'Set police / sheriff callsign',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Officer Server ID',
        },
        {
            name = 'callsign',
            type = 'string',
            help = 'Callsign',
        }
    }
}, function(source, args, raw)
    local src = source
    local xTarget = ESX.GetPlayerFromId(args.target)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xTarget or not xPlayer or not xPlayer.job then return end
    local job = xPlayer.job.name
    if (job == 'police' or job == 'sheriff') and xPlayer.job.grade_name == 'boss' then
        xTarget.setMeta('callsign', args.callsign)
        local title = job == 'sheriff' and 'SHERIFF' or 'POLICE'
        TriggerClientEvent('esx:Notify', src, title, 'You set '..xTarget.name..' callsign to '..args.callsign, 'success', 5000)
    end
end)
