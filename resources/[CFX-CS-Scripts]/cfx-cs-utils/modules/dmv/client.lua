local Config = require 'configs.dmv'

local TheroticalQuestion = {
	{
		question = "If you're going 80 km/h, and you're approaching a residential area you must:",
		A = "You accelerate",
		B = "You keep your speed, if you do not pass other vehicles",
		C = "You slow down",
		D = "You keep your speed",
		correct = "C"
	},
	{
		question = "If you're turning right at a traffic light, but see a pedestrian crossing what do you do:",
		A = "You pass the pedestrian",
		B = "You check that there is no other vehicles around",
		C = "You wait until the pedestrian has crossed",
		D = "You shoot the pedestrian and continue to drive",
		correct = "C"
	},
	{
		question = "Without any prior indication, the speed in a residential area is: __ km/h",
		A = "30 km/h",
		B = "50 km/h",
		C = "40 km/h",
		D = "60 km/h",
		correct = "C"
	},
	{
		question = "Before every lane change you must:",
		A = "Check your mirrors",
		B = "Check your blind spots",
		C = "Signal your intentions",
		D = "All of the above",
		correct = "D"
	},
	{
		question = "What blood alcohol level is classified as driving while intoxicated?",
		A = "0.05%",
		B = "0.18%",
		C = "0.08%",
		D = "0.06%",
		correct = "A"
	},
	{
		question = "When can you continue to drive at a traffic light?",
		A = "When it is green",
		B = "When there is nobody in the intersection",
		C = "You are in a school zone",
		D = "When it is green and / or red and you're turning right",
		correct = "A"
	},
	{
		question = "A pedestrian has a do not cross signal, what do you do?",
		A = "You let them pass",
		B = "You observe before continuing",
		C = "You wave to tell them to cross",
		D = "You continue because your traffic light is green",
		correct = "D"
	},
	{
		question = "What is allowed when passing another vehicle",
		A = "You follow it closely me to pass it faster",
		B = "You pass it without leaving the roadway",
		C = "You drive on the opposite side of the road to pass",
		D = "You exceed the speed limit to pass them",
		correct = "C"
	},
	{
		question = "You are driving on a highway which indicates a maximum speed of 120 km/h. But most trafficers drive at 125 km/h, so you should not drive faster than:",
		A = "120 km/h",
		B = "125 km/h",
		C = "130 km/h",
		D = "110 km/h",
		correct = "A"
	},
	{
		question = "When you are overtaken by another vehicle it is important NOT to:",
		A = "Slow Down",
		B = "Check your mirrors",
		C = "Watch other drivers",
		D = "Increase your speed",
		correct = "D"
	},
}

local PlayerData = {}
local CurrentTest, CurrentVehicle, CurrentBlip, CurrentZoneType, LastVehicleHealth, IsAboveSpeedLimit = nil, nil, nil, nil, nil, false
local CurrentCheckPoint, DriveErrors, LastCheckPoint = 0, 0, -1
local theDrivingTestType = nil
local isLoaded = false

local function RefreshPlayerData()
    PlayerData = ESX.GetPlayerData() or PlayerData or {}
    return PlayerData
end

local function licenseGranted(entry)
    if entry == true or entry == 1 or entry == 'true' then return true end
    return type(entry) == 'table' and (entry.has == true or entry.has == 1 or entry.has == 'true')
end

local function HasLicense(licenseType)
    local licenses = PlayerData.metadata and PlayerData.metadata.licenses
    if type(licenses) ~= 'table' then return false end
    if licenseGranted(licenses[licenseType]) then return true end
    if licenseType == 'car' then
        return licenseGranted(licenses.drive) or licenseGranted(licenses.driver)
    end
    if licenseType == 'motorcycle' then
        return licenseGranted(licenses.drive_bike) or licenseGranted(licenses.bike)
    end
    return false
end

local function MarkLicenseLocal(licenseType, label)
    PlayerData.metadata = PlayerData.metadata or {}
    PlayerData.metadata.licenses = PlayerData.metadata.licenses or {}
    local entry = PlayerData.metadata.licenses[licenseType]
    if type(entry) ~= 'table' then
        PlayerData.metadata.licenses[licenseType] = { has = true, label = label or licenseType }
    else
        entry.has = true
        if not entry.label then
            entry.label = label or licenseType
        end
    end
end

local function PayDMV(price, method)
    if lib.callback.await('cfx-keydi-utils:dmv:pay', false, price, method) then
        return true
    end
    return lib.callback.await('cfx-cs-dmv:pay', false, price, method) == true
end

local function CompleteDMV(data)
    TriggerServerEvent('cfx-keydi-utils:dmv:Complete', data)
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    if isLoaded then return end
    isLoaded = true
    PlayerData = xPlayer or ESX.GetPlayerData() or {}
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    isLoaded = false
    PlayerData = {}
end)

RegisterNetEvent('esx:updatePlayerData', function(key, val)
    PlayerData[key] = val
end)

function openDMV()
    if CurrentTest == 'drive' then
        ESX.Notify('DRIVING SCHOOL', 'You are currently taking a driving test.', 'warning', 5000)
        return
    end

    RefreshPlayerData()
    while not next(PlayerData) do
        RefreshPlayerData()
        Wait(500)
    end

    local SendMenu = {}
    if not HasLicense('therotical') then
        SendMenu[#SendMenu + 1] = {
            title = 'Therotical Test',
            description = 'You must pass this test before proceeding to the driving test.',
            icon = 'fas fa-car',
            onSelect = function()
                if PayDMV(Config.DrivingSchool.prices.therotical, 'therotical') then
                    TheroticalTest({zxc = 'therotical'})
                else
                    ESX.Notify('DRIVING SCHOOL', 'You must have $'..ESX.Math.GroupDigits(Config.DrivingSchool.prices.therotical)..' to proceed with this action.', 'error', 5000)
                end
            end,
            arrow = true
        }
    end
    if HasLicense('therotical') and not HasLicense('car') then
        SendMenu[#SendMenu + 1] = {
            title = 'Driving Test (Car)',
            description = 'This test is required for your license card.',
            icon = 'fas fa-car',
            arrow = true,
            onSelect = function()
                if PayDMV(Config.DrivingSchool.prices.car, 'car') then
                    StartDriveTest('car')
                else
                    ESX.Notify('DRIVING SCHOOL', 'You must have $'..ESX.Math.GroupDigits(Config.DrivingSchool.prices.car)..' to proceed with this action.', 'error', 5000)
                end
            end
        }
    end
    if HasLicense('therotical') and not HasLicense('motorcycle') then
        SendMenu[#SendMenu + 1] = {
            title = 'Driving Test (Motorcycle)',
            description = 'This test is required for your license card.',
            icon = 'fa-solid fa-motorcycle',
            arrow = true,
            onSelect = function()
                if PayDMV(Config.DrivingSchool.prices.motorcycle, 'motorcycle') then
                    StartDriveTest('motorcycle')
                else
                    ESX.Notify('DRIVING SCHOOL', 'You must have $'..ESX.Math.GroupDigits(Config.DrivingSchool.prices.motorcycle)..' to proceed with this action.', 'error', 5000)
                end
            end
        }
    end
    if #SendMenu == 0 then
        SendMenu[#SendMenu + 1] = {
            title = 'All tests completed',
            description = 'You already have your driving licenses.',
            icon = 'fas fa-check',
            disabled = true,
        }
    end
    lib.registerContext({
        id = 'dmv_context_menu',
        title = 'Driving School',
        options = SendMenu
    })
    lib.showContext('dmv_context_menu')
end

exports('openDMV', openDMV)

function TheroticalTest(data)
    local sourceQuestions = (Config and Config.DrivingSchool and Config.DrivingSchool.Questions) or TheroticalQuestion
    if not sourceQuestions or #sourceQuestions == 0 then
        ESX.Notify('DRIVING SCHOOL', 'No theoretical questions available.', 'error', 5000)
        return
    end

    -- Create question pool copy
    local questionPool = {}
    for i = 1, #sourceQuestions do
        questionPool[i] = sourceQuestions[i]
    end

    -- Randomize questions if enabled (default: true)
    local shouldRandomize = not Config or not Config.DrivingSchool or Config.DrivingSchool.RandomizeQuestions ~= false
    if shouldRandomize then
        for i = #questionPool, 2, -1 do
            local j = math.random(i)
            questionPool[i], questionPool[j] = questionPool[j], questionPool[i]
        end
    end

    -- Determine how many questions to ask
    local questionAmount = (Config and Config.DrivingSchool and Config.DrivingSchool.QuestionAmount) or #questionPool
    if questionAmount > #questionPool then
        questionAmount = #questionPool
    end

    local selectedQuestions = {}
    for i = 1, questionAmount do
        selectedQuestions[i] = questionPool[i]
    end

    local userAnswers = {}
    for i = 1, #selectedQuestions do
        local q = selectedQuestions[i]
        local options = {}
        if q.A then options[#options + 1] = { value = 'A', label = q.A } end
        if q.B then options[#options + 1] = { value = 'B', label = q.B } end
        if q.C then options[#options + 1] = { value = 'C', label = q.C } end
        if q.D then options[#options + 1] = { value = 'D', label = q.D } end

        local prompt = lib.inputDialog(('Question %d/%d'):format(i, #selectedQuestions), {
            {
                type = 'select',
                label = q.question,
                description = 'Your Answer?',
                required = true,
                options = options
            }
        }, {
            size = 'md',
            allowCancel = true,
        })

        if not prompt then
            ESX.Notify('DRIVING SCHOOL', 'You cancelled the theoretical test.', 'error', 5000)
            return
        end

        userAnswers[i] = prompt[1]
    end

    local WrongAnswer = {}
    for index = 1, #selectedQuestions do
        local v = userAnswers[index]
        local q = selectedQuestions[index]
        if v ~= q.correct then
            WrongAnswer[#WrongAnswer + 1] = {
                label = 'Question #'..index,
                correctAnwser = q[q.correct],
                yourAnwser = q[v]
            }
        end
    end

    local maxErrors = (Config and Config.DrivingSchool and Config.DrivingSchool.MaxTheoreticalErrors) or 0
    if #WrongAnswer <= maxErrors then
        CompleteDMV(data)
        MarkLicenseLocal('therotical', 'Theoretical License')
        ESX.Notify('DRIVING SCHOOL', 'You passed the theoretical test, congratulations!', 'success', 5000)
    else
        ESX.Notify('DRIVING SCHOOL', 'You failed the theoretical test, better luck next time!', 'error', 5000)
        local Message = {
            ('--Theoretical Test Result--    \n\n')
        }
        for _, v in ipairs(WrongAnswer) do
            table.insert(Message, v.label..': Wrong.    \n')
        end
        ESX.Notify('Theoretical Test Result', table.concat(Message), 'info', 10000)
    end
end

function StartDriveTest(theType)
    if CurrentTest == 'drive' then
        ESX.Notify('DRIVING SCHOOL', 'You already have an active driving test.', 'warning', 5000)
        return
    end

    -- Clean up previous vehicle / blip if any
    if CurrentVehicle and DoesEntityExist(CurrentVehicle) then
        local oldPlate = GetVehicleNumberPlateText(CurrentVehicle)
        if oldPlate and oldPlate ~= '' then
            TriggerServerEvent('cfx-keydi-carlock:server:removeKey', oldPlate)
        end
        ESX.Game.DeleteVehicle(CurrentVehicle)
        CurrentVehicle = nil
    end
    if DoesBlipExist(CurrentBlip) then
        RemoveBlip(CurrentBlip)
        CurrentBlip = nil
    end

    local spawnCoords = Config.DrivingSchool.Coords.vehicleSpawn
    ClearAreaOfVehicles(spawnCoords.x, spawnCoords.y, spawnCoords.z, 5.0, false, false, false, false, false)

    ESX.Game.SpawnVehicle(Config.DrivingSchool.Models[theType], vec3(spawnCoords.x, spawnCoords.y, spawnCoords.z), spawnCoords.w, function(vehicle)
        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            ESX.Notify('DRIVING SCHOOL', 'Failed to spawn test vehicle. Please try again.', 'error', 5000)
            return
        end

        CurrentTest        = 'drive'
        CurrentCheckPoint  = 0
        LastCheckPoint     = -1
        CurrentZoneType    = 'residence'
        DriveErrors        = 0
        IsAboveSpeedLimit  = false
        CurrentVehicle     = vehicle
        theDrivingTestType = theType
        LastVehicleHealth  = GetEntityHealth(vehicle)

        local plate = "DMV" .. tostring(math.random(10000, 99999))
        SetVehicleNumberPlateText(vehicle, plate)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleDoorsLocked(vehicle, 1)

        -- Put player into driver seat
        TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)

        -- Fully prepare engine, fuel, and physics
        Entity(vehicle).state.fuel = 100
        SetVehicleFuelLevel(vehicle, 100.0)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleHandbrake(vehicle, false)
        FreezeEntityPosition(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)

        -- Register vehicle key with cfx-keydi-carlock
        TriggerServerEvent('cfx-keydi-carlock:server:giveKey', plate)
        pcall(function()
            if exports['kodebykarl-ui'] and exports['kodebykarl-ui'].GiveKey then
                exports['kodebykarl-ui']:GiveKey(plate)
            end
        end)

        -- Secondary enforcement after ped is seated
        CreateThread(function()
            Wait(400)
            if DoesEntityExist(vehicle) then
                SetVehicleEngineOn(vehicle, true, true, false)
                SetVehicleUndriveable(vehicle, false)
                SetVehicleHandbrake(vehicle, false)
                FreezeEntityPosition(vehicle, false)
                SetVehicleFuelLevel(vehicle, 100.0)
            end
        end)
    end, true)
end

function StopDriveTest(success)
    local testType = theDrivingTestType
    local vehicleToDelete = CurrentVehicle

    CurrentTest = nil
    theDrivingTestType = nil
    CurrentCheckPoint = 0
    LastCheckPoint = -1
    DriveErrors = 0
    IsAboveSpeedLimit = false

    if DoesBlipExist(CurrentBlip) then
        RemoveBlip(CurrentBlip)
        CurrentBlip = nil
    end

    if success then
        CompleteDMV({zxc = testType})
        if testType == 'car' then
            MarkLicenseLocal('car', 'Drivers License')
        elseif testType == 'motorcycle' then
            MarkLicenseLocal('motorcycle', 'Motorcycle License')
        end
        ESX.Notify('DRIVING SCHOOL', 'You passed the driving test, congratulations!', 'success', 5000)
    else
        ESX.Notify('DRIVING SCHOOL', 'You failed the driving test, better luck next time!', 'error', 5000)
    end

    if vehicleToDelete and DoesEntityExist(vehicleToDelete) then
        local plate = GetVehicleNumberPlateText(vehicleToDelete)
        if plate and plate ~= '' then
            TriggerServerEvent('cfx-keydi-carlock:server:removeKey', plate)
        end
        if IsPedInVehicle(cache.ped, vehicleToDelete, false) then
            TaskLeaveVehicle(cache.ped, vehicleToDelete, 64)
            Wait(1200)
        end
        if DoesEntityExist(vehicleToDelete) then
            ESX.Game.DeleteVehicle(vehicleToDelete)
        end
    end
    CurrentVehicle = nil
end

function SetCurrentZoneType(theType)
    CurrentZoneType = theType
end

CreateThread(function()
    while true do
        local sleep = 1500
        if CurrentTest == 'drive' then
            sleep = 0
            local playerPed = cache.ped
            local coords = GetEntityCoords(playerPed)
            local nextCheckPoint = CurrentCheckPoint + 1

            if not CurrentVehicle or not DoesEntityExist(CurrentVehicle) or IsEntityDead(CurrentVehicle) then
                ESX.Notify('DRIVING SCHOOL', 'The driving test vehicle was destroyed or lost.', 'error', 5000)
                StopDriveTest(false)
            elseif Config.DrivingSchool.CheckPoints[nextCheckPoint] == nil then
                StopDriveTest(true)
            else
                if CurrentCheckPoint ~= LastCheckPoint then
                    if DoesBlipExist(CurrentBlip) then
                        RemoveBlip(CurrentBlip)
                    end
                    CurrentBlip = AddBlipForCoord(Config.DrivingSchool.CheckPoints[nextCheckPoint].Pos.x, Config.DrivingSchool.CheckPoints[nextCheckPoint].Pos.y, Config.DrivingSchool.CheckPoints[nextCheckPoint].Pos.z)
                    SetBlipRoute(CurrentBlip, 1)
                    LastCheckPoint = CurrentCheckPoint
                end

                local targetPos = vector3(Config.DrivingSchool.CheckPoints[nextCheckPoint].Pos.x, Config.DrivingSchool.CheckPoints[nextCheckPoint].Pos.y, Config.DrivingSchool.CheckPoints[nextCheckPoint].Pos.z)
                local distance = #(coords - targetPos)

                if distance <= 25.0 then
                    DrawMarker(1, targetPos.x, targetPos.y, targetPos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.5, 3.5, 1.5, 102, 204, 102, 100, false, true, 2, false, false, false, false)
                end

                if distance <= 4.0 then
                    local action = Config.DrivingSchool.CheckPoints[nextCheckPoint].Action
                    if type(action) == 'function' then
                        pcall(action, playerPed, CurrentVehicle, SetCurrentZoneType)
                    end
                    CurrentCheckPoint += 1
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    local leftVehicleTicks = 0
    while true do
        local sleep = 1000
        if CurrentTest == 'drive' then
            sleep = 100
            local playerPed = cache.ped
            if CurrentVehicle and DoesEntityExist(CurrentVehicle) then
                if IsPedInVehicle(playerPed, CurrentVehicle, false) then
                    leftVehicleTicks = 0
                    local speed = GetEntitySpeed(CurrentVehicle) * 3.6
                    local maxSpeed = Config.DrivingSchool.SpeedLimits[CurrentZoneType]
                    if maxSpeed and speed > maxSpeed then
                        if not IsAboveSpeedLimit then
                            DriveErrors += 1
                            IsAboveSpeedLimit = true
                            ESX.Notify('DRIVING SCHOOL', ('You\'re driving too fast! Limit: %s km/h'):format(maxSpeed), 'warning', 5000)
                            ESX.Notify('DRIVING SCHOOL', ('Mistakes: %s/%s'):format(DriveErrors, Config.DrivingSchool.MaxErrors), 'warning', 5000)
                        end
                    else
                        IsAboveSpeedLimit = false
                    end

                    local health = GetEntityHealth(CurrentVehicle)
                    if health < LastVehicleHealth then
                        local diff = LastVehicleHealth - health
                        if diff > 10 then
                            DriveErrors += 1
                            ESX.Notify('DRIVING SCHOOL', 'You damaged the vehicle!', 'error', 5000)
                            ESX.Notify('DRIVING SCHOOL', ('Mistakes: %s/%s'):format(DriveErrors, Config.DrivingSchool.MaxErrors), 'error', 5000)
                        end
                        LastVehicleHealth = health
                        Wait(1000)
                    end

                    if DriveErrors >= Config.DrivingSchool.MaxErrors then
                        ESX.Notify('DRIVING SCHOOL', 'You made too many mistakes during the test.', 'error', 5000)
                        StopDriveTest(false)
                    end
                else
                    leftVehicleTicks += 1
                    if leftVehicleTicks == 1 then
                        ESX.Notify('DRIVING SCHOOL', 'Return to your test vehicle within 30 seconds!', 'warning', 5000)
                    elseif leftVehicleTicks >= 300 then -- 30 seconds (300 * 100ms)
                        ESX.Notify('DRIVING SCHOOL', 'You abandoned the driving test vehicle.', 'error', 5000)
                        StopDriveTest(false)
                        leftVehicleTicks = 0
                    end
                end
            end
        else
            leftVehicleTicks = 0
        end
        Wait(sleep)
    end
end)
