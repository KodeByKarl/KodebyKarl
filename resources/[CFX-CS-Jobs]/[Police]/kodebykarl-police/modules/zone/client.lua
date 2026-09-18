local CreatedZones = {}
local CreatedBlip = {}
local CreatedBlipRadius = {}

function NewZone(data)
    local NewBlip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(NewBlip, 60)
    SetBlipScale(NewBlip, 1.0)
    SetBlipColour(NewBlip, 1)
    SetBlipAsShortRange(NewBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Police - Red Zone')
    EndTextCommandSetBlipName(NewBlip)
    local NewRadiusBlip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, 150.0)
    SetBlipHighDetail(NewRadiusBlip, true)
    SetBlipColour(NewRadiusBlip, 1)
    SetBlipAlpha(NewRadiusBlip, 128)
    SetBlipFlashes(NewRadiusBlip, true)
    local points = lib.points.new({
        coords = data.coords,
        distance = 150
    })
    function points:onEnter()
        local format = {
            ('You currently entered in a REDZONE.       \n'),
            ('Please avoid in this area.        \n')
        }
        ESX.Notify('Zone', table.concat(format), 'warning', 5000)
    end
    function points:onExit()
        ESX.Notify('Zone', 'You exited the REDZONE Please stay away from here!', 'success', 10000)
    end
    CreatedZones[data.index] = points
    CreatedBlip[data.index] = NewBlip
    CreatedBlipRadius[data.index] = NewRadiusBlip
end

function DeleteZone(index)
    CreatedZones[index]:remove()
    SetBlipFlashes(CreatedBlipRadius[index], false)
    RemoveBlip(CreatedBlip[index])
    RemoveBlip(CreatedBlipRadius[index])
    CreatedZones[index] = nil
    CreatedBlip[index] = nil
    CreatedBlipRadius[index] = nil
end

ESX.SecureNetEvent('cfx-cs-police:CreateZone', function(coords, index)
    NewZone({coords = coords, index = index})
end)

ESX.SecureNetEvent('cfx-cs-police:DeleteCreatedZone', function(index)
    DeleteZone(index)
end)