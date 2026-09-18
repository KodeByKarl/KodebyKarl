local Config = {}

Config.DrivingSchool = {
    MaxErrors = 5,
    RandomizeQuestions = true, -- Randomize question order / selection
    QuestionAmount = 10,       -- Number of questions to ask from the pool
    MaxTheoreticalErrors = 0, -- Allowed mistakes in theoretical test (0 = perfect score required)
    Models  = {
        ['car'] = 'blista',
        ['motorcycle'] = 'sanchez'
    },
    prices = {
        therotical = 500,
        car = 1000,
        motorcycle = 2000,
    },
    Questions = {
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
    },
    Coords = {
        ped = vec4(239.387, -1380.915, 32.742, 142.148),
        blip = vec3(239.387, -1380.915, 32.742),
        vehicleSpawn = vec4(250.12, -1406.02, 30.59, 316.08)
    },
    SpeedLimits = {
        residence = 40,
        town = 80,
        freeway = 125
    },
    CheckPoints = {
        {
            Pos = {x = 255.139, y = -1400.731, z = 29.537},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', ('Go to the next point! Speed Limit: %s km/h'):format(Config.DrivingSchool.SpeedLimits.residence), 'info', 5000)
            end
        },
        {
            Pos = {x = 271.874, y = -1370.574, z = 30.932},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Go to the next point!', 'info', 5000)
            end
        },
        {
            Pos = {x = 234.907, y = -1345.385, z = 29.542},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Stop for pedestrian crossing... Please wait 3 seconds.', 'info', 4000)
                PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', false, 0, true)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleForwardSpeed(vehicle, 0.0)
                    Wait(3000)
                    FreezeEntityPosition(vehicle, false)
                    SetVehicleUndriveable(vehicle, false)
                    SetVehicleHandbrake(vehicle, false)
                    SetVehicleEngineOn(vehicle, true, true, false)
                end
                ESX.Notify('DRIVING SCHOOL', 'Good, continue to the next point.', 'info', 4000)
            end
        },
        {
            Pos = {x = 217.821, y = -1410.520, z = 28.292},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                setCurrentZoneType('town')
                ESX.Notify('DRIVING SCHOOL', ('Stop and look left. Speed Limit: %s km/h'):format(Config.DrivingSchool.SpeedLimits.town), 'info', 4000)
                PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', false, 0, true)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleForwardSpeed(vehicle, 0.0)
                    Wait(3000)
                    FreezeEntityPosition(vehicle, false)
                    SetVehicleUndriveable(vehicle, false)
                    SetVehicleHandbrake(vehicle, false)
                    SetVehicleEngineOn(vehicle, true, true, false)
                end
                ESX.Notify('DRIVING SCHOOL', 'Good, turn right and follow the line.', 'info', 4000)
            end
        },
        {
            Pos = {x = 178.550, y = -1401.755, z = 27.725},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Watch the traffic and turn on your lights!', 'info', 5000)
            end
        },
        {
            Pos = {x = 113.160, y = -1365.276, z = 27.725},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Go to the next point!', 'info', 5000)
            end
        },
        {
            Pos = {x = -73.542, y = -1364.335, z = 27.789},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Stop for passing vehicles... Please wait 3 seconds.', 'info', 4000)
                PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', false, 0, true)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleForwardSpeed(vehicle, 0.0)
                    Wait(3000)
                    FreezeEntityPosition(vehicle, false)
                    SetVehicleUndriveable(vehicle, false)
                    SetVehicleHandbrake(vehicle, false)
                    SetVehicleEngineOn(vehicle, true, true, false)
                end
                ESX.Notify('DRIVING SCHOOL', 'Clear! Continue forward.', 'info', 4000)
            end
        },
        {
            Pos = {x = -355.143, y = -1420.282, z = 27.868},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Go to the next point!', 'info', 5000)
            end
        },
        {
            Pos = {x = -439.148, y = -1417.100, z = 27.704},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Go to the next point!', 'info', 5000)
            end
        },
        {
            Pos = {x = -453.790, y = -1444.726, z = 27.665},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                setCurrentZoneType('freeway')
                ESX.Notify('DRIVING SCHOOL', ('Time to drive on the highway! Speed Limit: %s km/h'):format(Config.DrivingSchool.SpeedLimits.freeway), 'info', 5000)
                PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', false, 0, true)
            end
        },
        {
            Pos = {x = -463.237, y = -1592.178, z = 37.519},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Go to the next point!', 'info', 5000)
            end
        },
        {
            Pos = {x = -900.647, y = -1986.28, z = 26.109},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Go to the next point!', 'info', 5000)
            end
        },
        {
            Pos = {x = 1225.759, y = -1948.792, z = 38.718},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                setCurrentZoneType('town')
                ESX.Notify('DRIVING SCHOOL', ('Entered town, pay attention to your speed! Speed Limit: %s km/h'):format(Config.DrivingSchool.SpeedLimits.town), 'info', 5000)
            end
        },
        {
            Pos = {x = 1163.603, y = -1841.771, z = 35.679},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'Great driving! Head back to the DMV to finish.', 'info', 5000)
                PlaySound(-1, 'RACE_PLACED', 'HUD_AWARDS', false, 0, true)
            end
        },
        {
            Pos = {x = 235.283, y = -1398.329, z = 28.921},
            Action = function(playerPed, vehicle, setCurrentZoneType)
                ESX.Notify('DRIVING SCHOOL', 'You have arrived at the destination.', 'success', 5000)
            end
        }
    }
}

return Config

