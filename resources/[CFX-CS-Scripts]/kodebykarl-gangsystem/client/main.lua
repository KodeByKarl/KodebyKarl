local ESX = exports['es_extended']:getSharedObject()

Gang = Gang or {}

function Gang.Notify(title, msg, nType, duration)
    if ESX and ESX.Notify then
        ESX.Notify(title or 'GANG', msg, nType or 'info', duration or 5000)
    else
        lib.notify({ title = title or 'GANG', description = msg, type = nType or 'inform' })
    end
end

function Gang.GetLocalGang()
    -- Prefer state bag (always synced from setGang); fall back to ESX player data
    local state = LocalPlayer.state and LocalPlayer.state.gang
    if type(state) == 'table' and state.name and state.name ~= '' then
        return state
    end
    local pd = ESX.GetPlayerData and ESX.GetPlayerData() or {}
    if type(pd.gang) == 'table' and pd.gang.name then
        return pd.gang
    end
    return nil
end

function Gang.IsInGang(gangName)
    local gang = Gang.GetLocalGang()
    if type(gang) ~= 'table' or not gang.name or gang.name == 'none' then
        return false
    end
    if gangName then
        return gang.name == gangName
    end
    return true
end

function Gang.IsBoss(gangName)
    local gang = Gang.GetLocalGang()
    if type(gang) ~= 'table' or not gang.name or gang.name == 'none' then
        return false
    end
    if gangName and gang.name ~= gangName then
        return false
    end
    if gang.isboss then return true end
    local level = gang.grade and (gang.grade.level or gang.grade) or 0
    local cfg = Config.Gangs[gang.name]
    if not cfg then return false end
    for i = 1, #cfg.grades do
        local g = cfg.grades[i]
        if g.isboss and tonumber(g.grade) == tonumber(level) then
            return true
        end
    end
    return false
end

function Gang.GetConfig(gangName)
    return Config.Gangs[gangName]
end

RegisterNetEvent('esx:setGang', function(gang)
    if ESX.SetPlayerData then
        ESX.SetPlayerData('gang', gang)
    end
end)

RegisterNetEvent('kodebykarl-gangsystem:client:notify', function(title, msg, nType)
    Gang.Notify(title, msg, nType)
end)
