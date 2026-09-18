local isUsingElevator = false
local helpers = require 'helpers.game'
local elevator = require 'configs.elevator'
local vars = require 'helpers.vars'

local function UseElevator(coords)
    if isUsingElevator then return end
    isUsingElevator = true
    FreezeEntityPosition(cache.ped, true)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z - 1)
    SetEntityHeading(cache.ped, coords.w)
    DoScreenFadeIn(500)
    FreezeEntityPosition(cache.ped, false)
    isUsingElevator = false
    helpers.hideTextUI()
end

local function hasGroupJob(groupJob)
    if not groupJob or groupJob == 'all' then return true end
    local pData = ESX and ESX.GetPlayerData and ESX.GetPlayerData()
    if not pData or not pData.job then return false end

    if type(groupJob) == 'string' then
        return pData.job.name == groupJob
    elseif type(groupJob) == 'table' then
        if groupJob[pData.job.name] ~= nil then return true end
        for k, v in pairs(groupJob) do
            if k == pData.job.name or v == pData.job.name then return true end
        end
    end
    return false
end

local function nearbyEntry(point)
    if hasGroupJob(point.job) then
        DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 255, 255, 255, 255, false, true, 2, false, nil, nil, false)
        if point.entryData.distance.interact < point.currentDistance then
            if point.isTextUI then
                point.isTextUI = false
                lib.hideTextUI('cfx-cs-utils')
            end
            return
        end
        if not point.isTextUI then
            point.isTextUI = true
            local prompt = ('[E] Enter Elevator [%s]'):format(tostring(point.entryIndex + 1))
            helpers.createTextUI(prompt, 'right-to-bracket', 'right-center')
        end
        if IsControlJustPressed(0, 38) then
            UseElevator(point.entryData.coords.exit)
        end
    end
end

local function nearbyExit(point)
    if hasGroupJob(point.job) then
        DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 255, 255, 255, 255, false, true, 2, false, nil, nil, false)
        if point.exitData.distance.interact < point.currentDistance then
            if point.isTextUI then
                point.isTextUI = false
                lib.hideTextUI('cfx-cs-utils')
            end
            return
        end
        if not point.isTextUI then
            point.isTextUI = true
            local prompt = ('[E] Exit Elevator [%s]'):format(tostring(point.exitIndex + 1))
            helpers.createTextUI(prompt, 'right-from-bracket', 'right-center')
        end
        if IsControlJustPressed(0, 38) then
            UseElevator(point.exitData.coords.enter)
        end
    end
end

local function createEnterElevatorZone()
    for entryIndex, entryData in pairs(elevator) do
        for i = 1, #entryData do
            local data = entryData[i]
            vars.oxPoints.new({
                coords = data.coords.enter,
                distance = data.distance.marker,
                entryData = data,
                entryIndex = i,
                job = data.job,
                nearby = nearbyEntry
            })
        end
    end
end

local function createExitElevatorZone()
    for exitIndex, exitData in pairs(elevator) do
        for i = 1, #exitData do
            local data = exitData[i]
            vars.oxPoints.new({
                coords = data.coords.exit,
                distance = data.distance.marker,
                exitData = data,
                exitIndex = i,
                job = data.job,
                nearby = nearbyExit
            })
        end
    end
end


CreateThread(function()
    createEnterElevatorZone()
    createExitElevatorZone()
end)