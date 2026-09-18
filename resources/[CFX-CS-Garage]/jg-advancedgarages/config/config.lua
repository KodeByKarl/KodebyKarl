-----------------------------------------------------------------------------------
-- WAIT! Before editing this file manually, try our new easy configuration tool! --
--            https://configurator.jgscripts.com/advanced-garages                --
-----------------------------------------------------------------------------------
Config = {}

-- Localisation
Config.Locale = "en"
Config.NumberAndDateFormat = "en-US"
Config.Currency = "USD"

-- Framework & Integrations
Config.Framework = "ESX" -- or "QBCore", "Qbox", "ESX"
Config.FuelSystem = "ox_fuel" -- or "LegacyFuel", "ps-fuel", "lj-fuel", "ox_fuel", "cdn-fuel", "hyon_gas_station", "okokGasStation", "nd_fuel", "myFuel", "ti_fuel", "Renewed-Fuel", "rcore_fuel", "none"
Config.VehicleKeys = "cfx-keydi-carlock" -- or "cfx-keydi-carlock", "qb-vehiclekeys", "MrNewbVehicleKeys", "jaksam-vehicles-keys", "qs-vehiclekeys", "mk_vehiclekeys", "wasabi_carlock", "cd_garage", "okokGarage", "t1ger_keys", "Renewed", "tgiann-hotwire", "none"
Config.Notifications = "ox_lib" -- or "default", "okokNotify", "ox_lib", "ps-ui"
Config.Banking = "esx_addonaccount" -- or "qb-banking", "qb-management", "esx_addonaccount", "Renewed-Banking", "okokBanking", "fd_banking"
Config.Gangs = "none" -- "qb-gangs", "rcore_gangs"

-- Draw text UI prompts (key binding control IDs here: https://docs.fivem.net/docs/game-references/controls/)
Config.DrawText = "ox_lib" -- or "jg-textui", "qb-DrawText", "okokTextUI", "ox_lib", "ps-ui"
Config.OpenGarageKeyBind = 38
Config.OpenGaragePrompt = "[E] Open Garage"
Config.OpenImpoundKeyBind = 38
Config.OpenImpoundPrompt = "[E] Open Impound"
Config.InsertVehicleKeyBind = 38
Config.InsertVehiclePrompt = "[E] Store Vehicle"
Config.ExitInteriorKeyBind = 38
Config.ExitInteriorPrompt = "[E] Exit Garage"

-- Target
Config.UseTarget = false
Config.Target = "ox_target" -- or "qb-target"
Config.TargetPed = "s_m_y_valet_01"

-- Radial
Config.UseRadialMenu = false
Config.RadialMenu = "ox_lib"


-- Little vehicle preview images in the garage UI - learn more/add custom images: https://docs.jgscripts.com/advanced-garages/vehicle-images
Config.ShowVehicleImages = true

-- Vehicle Spawning & Storing
Config.DoNotSpawnInsideVehicle = false
Config.SaveVehicleDamage = true -- Save and apply body and engine damage when taking the vehicle out a garage
Config.AdvancedVehicleDamage = true -- use Kiminaze's VehicleDeformation
Config.SaveVehiclePropsOnInsert = true
Config.CheckVehicleModel = true -- Extra security

-- If you don't know what this means, don't touch this
-- If you know what this means, I do recommend enabling it but be aware you may experience reliability issues on more populated servers
-- Having significant issues? I beg you to just set it back to false before opening a ticket with us
-- HIGHLY recommended that you set Config.DoNotSpawnInsideVehicle = false if you decide to enable this
-- Want to read my rant about server spawned vehicles? https://docs.jgscripts.com/advanced-garages/misc/why-are-you-not-using-createvehicleserversetter-by-default
Config.SpawnVehiclesWithServerSetter = false

-- Vehicle Transfers
Config.GarageVehicleTransferCost = 2500 -- Cost to transfer between garages
Config.GarageVehicleTakeOutCost = 0 -- Free to take out parked cars (CFX behavior). Keep transfer/return fees at 2500.
Config.TransferHidePlayerNames = false
Config.TransferRequireNearbyPlayer = false -- false = any online player (by ID/name); true = must be within TransferNearbyDistance
Config.TransferNearbyDistance = 20.0 -- only used if TransferRequireNearbyPlayer = true
Config.EnableTransfers = {
  betweenGarages = true,
  betweenPlayers = true
}
Config.DisableTransfersToUnregisteredGarages = false -- Potential hacking protection for vigilant servers - unregistered garages are ones created via events in third-party script integrations, such as housing scripts, and therefore could be prone to script kiddie attacks.

-- Prevent vehicle duplication
-- Learn more: https://docs.jgscripts.com/advanced-garages/vehicle-duplication-prevention
Config.AllowInfiniteVehicleSpawns = false -- Public & private garages
Config.JobGaragesAllowInfiniteVehicleSpawns = false -- Job garages
Config.GangGaragesAllowInfiniteVehicleSpawns = false -- Gang garages
Config.GarageVehicleReturnCost = 2500 -- "towing" tax if not placed back in garage after server restart; or if destroyed or underwater while left out
Config.GarageVehicleReturnCostSocietyFund = false -- Job name of society fund to pay return fees into (optional)

-- Public Garages
Config.GarageShowBlips = true
Config.GarageUniqueBlips = false
Config.GarageUniqueLocations = true
Config.GarageEnableInteriors = false
Config.GarageLocations = { -- IMPORTANT - Every garage name must be unique
  ["Legion Square"] = { -- If you change the name of this garage from Legion Square, you must change the default value of `garage_id` to the same name in the SQL table `players_vehicles`
    coords = vector3(215.2302, -806.0093, 30.8056),
    spawn =  vector4(212.9906, -795.6213, 30.8633, 157.3098),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Police Station Public"] = {
    coords = vector3(109.9534, -429.1195, 40.3253),
    spawn = vector4(120.7265, -421.3372, 40.3253, 258.4241),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Integrity Way"] = {
    coords = vector3(-17.1902, -570.9355, 37.7450),
    spawn = vector4(-6.6761, -573.6871, 37.7451, 334.6148),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["New Player Garage"] = {
    coords = vector3(-279.2086, -986.2623, 31.0806),
    spawn = vector4(-279.2086, -986.2623, 31.0806, 247.3372),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Grove Street"] = {
    coords = vector3(14.6599, -1728.5200, 29.3031),
    spawn = vector4(22.0993, -1729.5684, 29.3030, 240.9858),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Mirror Park"] = {
    coords = vector3(1032.8400, -765.1000, 58.1763),
    spawn = vector4(1022.8657, -764.3557, 57.9605, 322.3027),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Beach"] = {
    coords = vector3(-1248.6899, -1425.7098, 4.3228),
    spawn = vector4(-1243.4402, -1421.7596, 4.3233, 43.6672),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Great Ocean Highway"] = {
    coords = vector3(-2961.5801, 375.9303, 15.0207),
    spawn = vector4(-2964.6831, 369.7209, 14.7712, 82.3128),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Sandy South"] = {
    coords = vector3(217.3301, 2605.6499, 46.0345),
    spawn = vector4(215.9984, 2613.4409, 46.9054, 2.3798),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Sandy North"] = {
    coords = vector3(1878.4229, 3760.0886, 32.9429),
    spawn = vector4(1883.7671, 3762.5803, 32.8931, 205.9854),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["North Vinewood Blvd"] = {
    coords = vector3(365.2102, 295.6500, 103.4572),
    spawn = vector4(365.4524, 287.4168, 103.3818, 346.0113),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Paleto Bay"] = {
    coords = vector3(107.3200, 6611.7700, 31.9761),
    spawn = vector4(114.5835, 6609.0938, 31.8836, 228.8401),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["KTG"] = {
    coords = vector3(1386.6598, 1098.4867, 114.2942),
    spawn = vector4(1386.6598, 1098.4867, 114.2942, 93.1718),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["MMS"] = {
    coords = vector3(-1525.8643, 91.1884, 56.5328),
    spawn = vector4(-1525.8643, 91.1884, 56.5328, 286.0026),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Marlboro Syndicate"] = {
    coords = vector3(-329.4856, 223.3680, 86.8149),
    spawn = vector4(-329.4856, 223.3680, 86.8149, 39.8839),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["mechanic garage"] = {
    coords = vector3(2780.2349, 3451.2012, 55.5680),
    spawn = vector4(2771.8662, 3455.5872, 55.6438, 66.8824),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["BurgerShot"] = {
    coords = vector3(-1163.0168, -890.8737, 14.1499),
    spawn = vector4(-1170.2159, -893.0372, 13.9366, 42.2082),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["ScrapMetal"] = {
    coords = vector3(2374.6079, 3128.0840, 48.0714),
    spawn = vector4(2371.5515, 3118.4294, 48.1347, 157.3521),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Crab"] = {
    coords = vector3(-258.0273, 6573.8657, 2.6092),
    spawn = vector4(-249.9898, 6574.1162, 2.6022, 215.3701),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["UwU Garage"] = {
    coords = vector3(-596.2978, -1112.1588, 22.1781),
    spawn = vector4(-589.2759, -1116.1660, 22.1783, 345.0449),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["8Ball Garage"] = {
    coords = vector3(-1585.1644, -1008.1785, 13.0173),
    spawn = vector4(-1578.8673, -1013.4759, 13.0185, 208.2194),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Hospital"] = {
    coords = vector3(-1051.1544, -1410.1101, 5.4256),
    spawn = vector4(-1056.2134, -1415.5654, 5.4258, 134.9362),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Sandy Hospital"] = {
    coords = vector3(1843.3864, 3669.3853, 34.0871),
    spawn = vector4(1835.5785, 3664.4282, 34.1081, 208.7340),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Paleto Hospital"] = {
    coords = vector3(-256.5836, 6349.3579, 32.4263),
    spawn = vector4(-261.1917, 6341.5771, 32.4261, 318.0630),
    distance = 3.0,
    type = "car",
    hideBlip = false,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Market Garage"] = {
    coords = vector3(168.85, 6631.12, 31.57),
    spawn = vector4(168.85, 6631.12, 31.57, 134.33),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Youtool Garage"] = {
    coords = vector3(147.12, 6639.85, 31.57),
    spawn = vector4(147.12, 6639.85, 31.57, 141.74),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["PG Top Garage"] = {
    coords = vector3(636.0460, 200.7011, 97.0902),
    spawn = vector4(641.0535, 193.6051, 96.2119, 345.2906),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Farming Garage"] = {
    coords = vector3(2122.1487, 4804.1250, 41.1960),
    spawn = vector4(2115.0227, 4799.1060, 41.1158, 108.5737),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Lumberjack Garage"] = {
    coords = vector3(-752.6022, 5529.5688, 33.4857),
    spawn = vector4(-758.3409, 5541.3926, 33.4857, 74.3751),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Mining Garage"] = {
    coords = vector3(2960.5388, 2738.3818, 43.6862),
    spawn = vector4(2965.2104, 2745.6604, 43.3748, 293.8130),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Wash Stone Garage"] = {
    coords = vector3(-182.3145, 826.4191, 203.3905),
    spawn = vector4(-174.5468, 822.5656, 203.1350, 235.8710),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Smelting Garage"] = {
    coords = vector3(1059.8445, -1973.5358, 31.0162),
    spawn = vector4(1063.6067, -1966.0409, 31.0146, 359.9608),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Pig Farm Garage"] = {
    coords = vector3(-2088.3555, 2649.9277, 2.8588),
    spawn = vector4(-2097.4146, 2653.3259, 2.8667, 356.1133),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["DCF Garage"] = {
    coords = vector3(-1152.6874, -204.7715, 37.9600),
    spawn = vector4(-1152.6874, -204.7715, 37.9600, 192.6146),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["RBM Garage"] = {
    coords = vector3(-617.9207, -1589.3998, 26.7511),
    spawn = vector4(-617.9207, -1589.3998, 26.7511, 142.4371),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Taylor Garage"] = {
    coords = vector3(-912.9125, -196.4263, 37.8906),
    spawn = vector4(-912.9125, -196.4263, 37.8906, 29.5710),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["SIS Garage"] = {
    coords = vector3(386.3988, 16.9611, 91.3205),
    spawn = vector4(386.3988, 16.9611, 91.3205, 54.9199),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Naughty Boys Garage"] = {
    coords = vector3(111.7439, 286.1402, 109.9738),
    spawn = vector4(111.7439, 286.1402, 109.9738, 334.3685),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Mayores Garage"] = {
    coords = vector3(-597.7269, 190.2263, 70.8371),
    spawn = vector4(-597.7269, 190.2263, 70.8371, 87.7443),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Very Rare Garage"] = {
    coords = vector3(565.8016, -1764.6658, 29.1623),
    spawn = vector4(565.8016, -1764.6658, 29.1623, 328.4400),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["La Fuente Garage"] = {
    coords = vector3(-342.2380, -1366.1277, 31.3652),
    spawn = vector4(-338.2546, -1371.3997, 31.2946, 215.3201),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["El Fuerte Familia Garage"] = {
    coords = vector3(1137.2825, -410.4488, 67.0491),
    spawn = vector4(1138.9187, -404.7604, 67.0493, 344.1730),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["4TK Garage"] = {
    coords = vector3(-307.0563, -627.6821, 33.3691),
    spawn = vector4(-311.2373, -635.4930, 33.1821, 169.1868),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Westside"] = {
    coords = vector3(-1526.2898, 887.9648, 181.7952),
    spawn = vector4(-1519.6462, 880.3286, 181.7831, 294.3454),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 27,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Melly Syndicate"] = {
    coords = vector3(-553.5296, 272.4998, 82.9913),
    spawn = vector4(-556.9075, 267.4720, 82.8945, 90.3719),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["NPA"] = {
    coords = vector3(-1153.7690, -222.9737, 37.9230),
    spawn = vector4(-1146.4014, -215.4896, 37.9553, 184.2798),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 4,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 128, g = 128, b = 128, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Tropa de Calle"] = {
    coords = vector3(969.3305, -118.2687, 74.3531),
    spawn = vector4(967.7197, -126.2153, 74.3584, 144.2916),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 3,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 25, g = 80, b = 210, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["The Boneless"] = {
    coords = vector3(-55.1546, 343.6687, 112.1404),
    spawn = vector4(-59.0989, 334.4221, 111.3442, 156.2872),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 1,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 200, g = 30, b = 30, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Ghetto Syndicate"] = {
    coords = vector3(-1226.8237, -1791.3672, 3.4013),
    spawn = vector4(-1233.0583, -1781.3629, 2.6698, 321.6736),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 2,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 40, g = 180, b = 60, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Deus Cartel"] = {
    coords = vector3(-1539.6759, -560.8541, 25.7077),
    spawn = vector4(-1541.8776, -566.3344, 25.7079, 27.8349),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 21, -- brown
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 139, g = 90, b = 43, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Car Dealer"] = {
    coords = vector3(-2143.9697, -388.2462, 13.2341),
    spawn = vector4(-2155.3921, -389.8757, 13.3304, 66.1611),
    distance = 3.0,
    type = "car",
    hideBlip = true,
    blip = {
      id = 357,
      color = 0,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
}

-- Private Garages
Config.PrivGarageCreateCommand = "privategarages"
Config.PrivGarageCreateJobRestriction = {"realestate"}
Config.PrivGarageEnableInteriors = true
Config.PrivGarageHideBlips = false
Config.PrivGarageBlip = {
  id = 357,
  color = 0,
  scale = 0.7
}

-- Job Garages
Config.JobGarageShowBlips = true
Config.JobGarageSetVehicleCommand = "setjobvehicle" -- admin only
Config.JobGarageRemoveVehicleCommand = "removejobvehicle" -- admin only
Config.JobGarageUniqueBlips = false
Config.JobGarageUniqueLocations = true
Config.JobGarageEnableInteriors = true
Config.JobGarageLocations = { -- IMPORTANT - Every garage name must be unique
  ["EMS Garage"] = {
    coords = vector3(-1030.4906, -1415.4324, 5.4256),
    spawn = {
      vector4(-1035.8992, -1421.0535, 5.4292, 66.2173),
      vector4(-1039.80, -1427.10, 5.4292, 66.2173),
      vector4(-1043.50, -1433.20, 5.4292, 66.2173),
    },
    distance = 8.0,
    type = "car",
    job = {"ambulance", "sambulance", "pambulance"},
    vehiclesType = "spawner",
    takeOutCost = 0,
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "ambulance",
        plate = "EMSAMB",
        minJobGrade = 0,
        nickname = "Ambulance",
        maxMods = true,
      },
      [2] = {
        model = "dodgeems",
        plate = "EMSDOG",
        minJobGrade = 0,
        nickname = "Dodge EMS",
        maxMods = true,
      },
      [3] = {
        model = "lguard",
        plate = "EMSRES",
        minJobGrade = 0,
        nickname = "Rescue",
        maxMods = true,
      },
    },
    hideBlip = false,
    blip = {
      id = 357,
      color = 1,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Paleto EMS Garage"] = {
    coords = vector3(-273.5200, 6318.0293, 32.4212),
    spawn = {
      vector4(-268.4462, 6309.9468, 32.3824, 215.0898),
    },
    distance = 8.0,
    type = "car",
    job = {"pambulance", "sambulance", "ambulance"},
    vehiclesType = "spawner",
    takeOutCost = 0,
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "ambulance",
        plate = "PAMB",
        minJobGrade = 0,
        nickname = "Ambulance",
        maxMods = true,
      },
      [2] = {
        model = "dodgeems",
        plate = "PDOG",
        minJobGrade = 0,
        nickname = "Dodge EMS",
        maxMods = true,
      },
      [3] = {
        model = "lguard",
        plate = "PRES",
        minJobGrade = 0,
        nickname = "Rescue",
        maxMods = true,
      },
    },
    hideBlip = true,
    blip = {
      id = 357,
      color = 1,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["EMS Helipad"] = {
    coords = vector3(-1036.1455, -1347.8751, 21.5959),
    spawn = {
      vector4(-1036.1455, -1347.8751, 21.5959, 170.2800),
    },
    distance = 5.0,
    type = "air",
    job = {"ambulance", "sambulance", "pambulance"},
    vehiclesType = "spawner",
    takeOutCost = 0,
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "polmav",
        plate = "EMSHELI",
        minJobGrade = 0,
        nickname = "EMS Maverick",
        maxMods = true,
        livery = 1, -- Air ambulance
      },
    },
    hideBlip = false,
    blip = {
      id = 43,
      color = 1,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Sandy EMS Garage"] = {
    coords = vector3(1844.5409, 3635.6526, 34.2286),
    spawn = {
      vector4(1843.8750, 3644.0823, 34.2248, 358.1708),
    },
    distance = 8.0,
    type = "car",
    job = {"ambulance", "sambulance", "pambulance"},
    vehiclesType = "spawner",
    takeOutCost = 0,
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "ambulance",
        plate = "SAMB",
        minJobGrade = 0,
        nickname = "Ambulance",
        maxMods = true,
      },
      [2] = {
        model = "dodgeems",
        plate = "SDOG",
        minJobGrade = 0,
        nickname = "Dodge EMS",
        maxMods = true,
      },
      [3] = {
        model = "lguard",
        plate = "SRES",
        minJobGrade = 0,
        nickname = "Rescue",
        maxMods = true,
      },
    },
    hideBlip = true,
    blip = {
      id = 357,
      color = 1,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Sandy EMS Helipad"] = {
    coords = vector3(1810.6118, 3606.9382, 34.2953),
    spawn = {
      vector4(1810.6118, 3606.9382, 34.2953, 38.8812),
    },
    distance = 5.0,
    type = "air",
    job = {"ambulance", "sambulance", "pambulance"},
    vehiclesType = "spawner",
    takeOutCost = 0,
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "polmav",
        plate = "SAMBHELI",
        minJobGrade = 0,
        nickname = "EMS Maverick",
        maxMods = true,
        livery = 1, -- Air ambulance
      },
    },
    hideBlip = true,
    blip = {
      id = 43,
      color = 1,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Paleto EMS Helipad"] = {
    coords = vector3(-278.5622, 6323.5981, 32.4263),
    spawn = {
      vector4(-278.5622, 6323.5981, 32.4263, 124.1429),
    },
    distance = 5.0,
    type = "air",
    job = {"ambulance", "sambulance", "pambulance"},
    vehiclesType = "spawner",
    takeOutCost = 0,
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "polmav",
        plate = "PAMBHELI",
        minJobGrade = 0,
        nickname = "EMS Maverick",
        maxMods = true,
        livery = 1, -- Air ambulance
      },
    },
    hideBlip = true,
    blip = {
      id = 43,
      color = 1,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Police Garage"] = {
    coords = vector3(112.8899, -394.3368, 40.3253),
    spawn = vector4(123.5052, -399.6405, 40.3253, 242.6202),
    distance = 15.0,
    type = "car",
    job = {"police", "lspd"},
    vehiclesType = "spawner",
    takeOutCost = 1000,
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "ghispo2",
        plate = "LSPD",
        minJobGrade = 0,
        nickname = "Police Ghispo",
        maxMods = true,
      },
      [2] = {
        model = "riot",
        plate = "LSPD",
        minJobGrade = 0,
        nickname = "Riot Truck",
        maxMods = true,
      },
    },
    hideBlip = false,
    blip = {
      id = 357,
      color = 3,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Police Helipad"] = {
    coords = vector3(74.3532, -414.7925, 55.3262),
    spawn = vector4(86.7077, -404.2123, 55.3262, 69.1803),
    distance = 15.0,
    type = "air",
    job = {"police", "lspd"},
    vehiclesType = "spawner",
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "polmav",
        plate = "LSPD",
        minJobGrade = 0,
        nickname = "Police Maverick",
        maxMods = true,
        livery = 0, -- LSPD (vanilla polmav 1 = EMS air ambulance)
      },
      [2] = {
        model = "cargobob",
        plate = "LSPD",
        minJobGrade = 0,
        nickname = "Police Cargobob",
        maxMods = true,
      },
      [3] = {
        model = "seasparrow",
        plate = "LSPD",
        minJobGrade = 0,
        nickname = "Police Sea Sparrow",
        maxMods = true,
      },
    },
    hideBlip = false,
    blip = {
      id = 43,
      color = 3,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Sheriff Helipad"] = {
    coords = vector3(1893.3763, 3665.4343, 40.8335),
    spawn = vector4(1893.0033, 3666.2625, 40.8335, 190.9078),
    distance = 3.0,
    type = "air",
    job = {"sheriff", "bcso", "police"},
    vehiclesType = "spawner",
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "polmav",
        plate = "BCSO",
        minJobGrade = 0,
        nickname = "Sheriff Maverick",
        maxMods = true,
      },
      [2] = {
        model = "cargobob",
        plate = "BCSO",
        minJobGrade = 0,
        nickname = "Sheriff Cargobob",
        maxMods = true,
      },
      [3] = {
        model = "seasparrow",
        plate = "BCSO",
        minJobGrade = 0,
        nickname = "Sheriff Sea Sparrow",
        maxMods = true,
      },
    },
    hideBlip = true,
    blip = {
      id = 43,
      color = 5,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
  ["Sheriff Garage"] = {
    coords = vector3(1909.2863, 3662.5608, 33.5966),
    spawn = vector4(1912.4501, 3663.4399, 33.5944, 204.4072),
    distance = 8.0,
    type = "car",
    job = {"sheriff", "bcso", "police"},
    vehiclesType = "spawner",
    takeOutCost = 0,
    showLiveriesExtrasMenu = true,
    vehicles = {
      [1] = {
        model = "slick23tahoeb",
        plate = "BCSO",
        minJobGrade = 0,
        nickname = "Sheriff Tahoe",
        maxMods = true,
      },
      [2] = {
        model = "riot",
        plate = "BCSO",
        minJobGrade = 0,
        nickname = "Riot Truck",
        maxMods = true,
      },
    },
    hideBlip = true,
    blip = {
      id = 357,
      color = 5,
      scale = 0.7
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  },
}

-- Gang Garages (unused — HQ spots are public in Config.GarageLocations)
Config.GangEnableCustomESXIntegration = false
Config.GangGarageShowBlips = true
Config.GangGarageSetVehicleCommand = "setgangvehicle" -- admin only
Config.GangGarageRemoveVehicleCommand = "removegangvehicle" -- admin only
Config.GangGarageUniqueBlips = false
Config.GangGarageUniqueLocations = true
Config.GangGarageEnableInteriors = true
Config.GangGarageLocations = {}

-- Impound
Config.ImpoundCommand = "iv"
Config.ImpoundFeesSocietyFund = "police" -- Job name of society fund to pay impound fees into (optional)
Config.ImpoundShowBlips = false
Config.ImpoundUniqueBlips = false
Config.ImpoundTimeOptions = {0, 1, 4, 12, 24, 72, 168} -- in hours
Config.ImpoundLocations = { -- IMPORTANT - Every impound name must be unique
  ["Police Impound"] = {
    coords = vector3(51.6447, -381.1395, 39.1266),
    spawn = vector4(39.1655, -377.1685, 39.1266, 70.5076),
    distance = 3.0,
    type = "car",
    job = {"police", "lspd", "bcso", "sheriff"},
    hideBlip = true,
    blip = {
      id = 68,
      color = 3,
      scale = 0.8
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
  }
}

-- Garage Interior
Config.GarageInteriorEntrance = vector4(227.96, -1003.06, -99.0, 0.0)
Config.GarageInteriorCameraCutscene = {
  vector4(227.96, -977.81, -98.99, 0.0), -- from
  vector4(227.96, -1006.96, -98.99, 0.0), -- to (this should be the entrance, or slightly further back from the entrance coords for a better final player transition)
}
Config.GarageInteriorVehiclePositions = {
  vector4(233.000000, -984.000000, -99.410004, 118.000000),
  vector4(233.000000, -988.500000, -99.410004, 118.000000),
  vector4(233.000000, -993.000000, -99.410004, 118.000000),
  vector4(233.000000, -997.500000, -99.410004, 118.000000),
  vector4(233.000000, -1002.000000, -99.410004, 118.000000),
  vector4(223.600006, -979.000000, -99.410004, 235.199997),
  vector4(223.600006, -983.599976, -99.410004, 235.199997),
  vector4(223.600006, -988.200012, -99.410004, 235.199997),
  vector4(223.600006, -992.799988, -99.410004, 235.199997),
  vector4(223.600006, -997.400024, -99.410004, 235.199997),
  vector4(223.600006, -1002.000000, -99.410004, 235.199997),
}

-- Staff Commands
Config.ChangeVehiclePlate = "vplate" -- admin only
Config.DeleteVehicleFromDB = "dvdb" -- admin only
Config.ReturnVehicleToGarage = "vreturn" -- admin only

-- Add your import vehicle's spawn name and desired label here for pretty vehicle names in the garage
-- This is mainly designed for ESX - if you are using QB, do this in shared!
Config.VehicleLabels = {
  ["slick23tahoeb"] = "Sheriff Tahoe",
  ["ghispo2"] = "Police Ghispo",
  ["cargobob"] = "Cargobob",
  ["seasparrow"] = "Sea Sparrow",
  ["oycdefenderp"] = "Defender Police",
  ["polgs350"] = "Lexus GS350 Police",
  ["pranger"] = "Police Ranger SUV",
  ["dodgeEMS"] = "Dodge Charger EMS",
  ["dodgeems"] = "Dodge Charger EMS",
  ["libertywalk"] = "Liberty Walk",
  ["rocketbunny"] = "Rocket Bunny",
  ["500"] = "500",
  ["124spider"] = "124 Spider",
  ["yFiat595ssA"] = "595",
  ["yFiat595ssB"] = "595 S",
  ["4c"] = "4C Spider",
  ["8cs"] = "8C Spider",
  ["155q4"] = "155 Q4",
  ["alfa67"] = "33 Stradale",
  ["155alfa"] = "155 TI",
  ["argiu"] = "Giullieta",
  ["brera"] = "Brera",
  ["giulia"] = "Giulia",
  ["giuliasuper"] = "Giulia Super",
  ["gtv6"] = "GT V6",
  ["gtw6"] = "GT W6",
  ["mito"] = "Mito",
  ["105gt"] = "Montreal 105GT",
  ["spider115"] = "Spider 115",
  ["tz3"] = "TZ3 Stradale",
  ["a110s"] = "A110 S",
  ["al1"] = "A110",
  ["amcj"] = "Javelin AMX",
  ["pacer"] = "Pacer",
  ["amxss"] = "AMX SS",
  ["jav401"] = "Javelin",
  ["matador"] = "Matador",
  ["atom"] = "Atom",
  ["nomad"] = "Nomade",
  ["asdbx"] = "DBX 2019",
  ["ast"] = "Vanquish",
  ["cygnet"] = "Cygnet",
  ["cyrus"] = "Cyrus",
  ["db5"] = "DB5",
  ["db905"] = "DB9",
  ["dbx"] = "DBX 2020",
  ["vgt12"] = "GT",
  ["one77"] = "ONE 77",
  ["superleggera"] = "DBS SL",
  ["zagatov12"] = "Zagato V12",
  ["v600"] = "V600",
  ["vantage"] = "Vantage",
  ["vulcanamr"] = "Vulcan",
  ["2015s3"] = "S3",
  ["s3sedan"] = "A3 TFSI",
  ["audia4"] = "Audi A4",
  ["a6avant"] = "A6 avant",
  ["a6tfsi"] = "A6 TFSI",
  ["a6fnbodykit"] = "A6 AR",
  ["a8audi"] = "A8",
  ["a8fsi"] = "A8 FSI",
  ["a8lfsi"] = "A8 LFSI",
  ["a8lw12"] = "A8 W12",
  ["a615"] = "A6 TFSI 2015",
  ["a31999"] = "A3 1999",
  ["aaq4"] = "AA TFSI",
  ["audiq3"] = "Q3",
  ["audirs3"] = "RS3 2012",
  ["audis8om"] = "S8",
  ["yAudiTTmk1"] = "TT",
  ["tts"] = "TTS",
  ["auds5"] = "S5",
  ["c5rs6"] = "RS6",
  ["q5"] = "Q5",
  ["q7"] = "Q7",
  ["q820"] = "Q8 2020",
  ["r820"] = "R8 2020",
  ["rs4avant"] = "RS4 Avant",
  ["rs5r"] = "RS5 ABT",
  ["rs6+"] = "RS6 Mansory",
  ["rs7"] = "RS7",
  ["rs3"] = "RS3 2011",
  ["rs318"] = "RS3 2018",
  ["sq72016"] = "SQ7 2016",
  ["tts07"] = "TT 2007",
  ["audsq517"] = "SQ5 2017",
  ["audquattros"] = "Quattro",
  ["bbentayga"] = "Bentayga",
  ["ben17"] = "Continental GT 2017",
  ["bexp"] = "EXP 10",
  ["bmm"] = "Continental",
  ["brooklands"] = "Brooklands",
  ["contgt13"] = "Continental GT 2013",
  ["contgt2011"] = "Continental GT 2011",
  ["750li"] = "750li",
  ["440i"] = "440i",
  ["m2"] = "M2",
  ["17m760i"] = "760i",
  ["z419"] = "Z4 2019",
  ["i8"] = "I8",
  ["e60"] = "M5 E60",
  ["m3e30"] = "M3 E30",
  ["m5e60"] = "M5 E60",
  ["m5f90"] = "M5 F90",
  ["m6f13"] = "M6 F13",
  ["x5e53"] = "X5 E53",
  ["x6m"] = "X6",
  ["325et"] = "325",
  ["bmw507"] = "507",
  ["bmwe3"] = "E3",
  ["bmwe34"] = "E34 535i",
  ["bmwhommage"] = "BMW H CSL",
  ["bmc2"] = "Nazca C2",
  ["e21"] = "E21",
  ["e30c"] = "318i",
  ["e34"] = "M5 E30",
  ["m3e46"] = "M3 E46",
  ["lumma750"] = "750li",
  ["m1"] = "M1",
  ["m4f82"] = "M4 F82",
  ["m5e28"] = "M5 E28",
  ["m3f80"] = "M3 F80",
  ["mteche39"] = "E39 Tech",
  ["oldm6"] = "M6",
  ["rmodx6"] = "X6 M",
  ["m1procar"] = "M1 Sport",
  ["x5om"] = "X5",
  ["z3"] = "Z3",
  ["z4bmw"] = "Z4 2020",
  ["b63s"] = "E63 S",
  ["brabus700"] = "G700",
  ["brabus850"] = "850",
  ["g500"] = "G500",
  ["bugatti"] = "Veyron",
  ["bugatticentodieci"] = "Centodieci",
  ["centuria"] = "Centuria",
  ["2017chiron"] = "Chiron 2017",
  ["2019chiron"] = "Chiron 2019",
  ["bdivot"] = "Divo",
  ["eb110"] = "EB 110",
  ["royale"] = "Royale",
  ["cnty"] = "Century",
  ["gsxb"] = "GSX",
  ["bgnx"] = "GNX",
  ["cats"] = "ATS",
  ["cesc21"] = "Eldorado",
  ["e78"] = "Escalade",
  ["nova"] = "Nova",
  ["c7"] = "C7",
  ["c8"] = "C8",
  ["c10custom"] = "C10",
  ["chevelle1970"] = "Chevelle SS",
  ["silverado"] = "Silverado",
  ["corvetteZR1"] = "ZR1",
  ["impala"] = "Impala",
  ["impalass2"] = "Impala 1970",
  ["ccss16"] = "Camaro SS",
  ["tahoe"] = "Tahoe",
  ["z2879"] = "Z28 1979",
  ["zl12017"] = "ZL1 2017",
  ["300srt8"] = "300 SRT-8",
  ["airflow"] = "Airflow",
  ["chry300"] = "SRT8",
  ["cross"] = "Crossfire",
  ["newyorker75"] = "NewYorker 1975",
  ["acuralms"] = "Acura LMS",
  ["acuransx"] = "Acura NSX",
  ["apollos"] = "Appolo S",
  ["r8lms"] = "Audi R8 LMS",
  ["audir8lms2"] = "Audi R8 LMS",
  ["bac2"] = "Mono BAC 2",
  ["c7r"] = "Chev C7R",
  ["clklm"] = "CLK LM",
  ["fgt3"] = "Ford GT",
  ["fordcapri"] = "Ford Capri",
  ["gtrlms"] = "GTR LMS",
  ["lhgt3"] = "GT3",
  ["marr"] = "Marrusia",
  ["pragar1"] = "Praga R1",
  ["radical"] = "Radical",
  ["renaultm"] = "Megane LM",
  ["rmodmustang"] = "Mustang GT",
  ["rmp4"] = "MP4 12C GT3",
  ["spano2016"] = "Spano 2016",
  ["me412"] = "Me 4-12",
  ["330p4"] = "330 P4",
  ["f80"] = "F80",
  ["f248"] = "F248",
  ["fxxk"] = "FXX-K",
  ["terzo"] = "Terzo",
  ["mc12"] = "MC12",
  ["p1gtr"] = "P1 GTR",
  ["senna"] = "Senna",
  ["f1"] = "Formule 1",
  ["r18"] = "R18",
  ["mi8"] = "I8",
  ["bmwe65"] = "E65",
  ["m8gte"] = "M8 GTE",
  ["z4alchemist"] = "Z4 Sport",
  ["fordh"] = "Drift",
  ["maj935"] = "935",
  ["sportrs"] = "Sport RS",
  ["l78c"] = "178C",
  ["320ig5"] = "320",
  ["c2vtr"] = "C2 VTR",
  ["cit2cv"] = "2 CV",
  ["ds4"] = "DS4",
  ["ds7"] = "DS7 Crossback",
  ["xsarawrc"] = "Xsara WRC",
  ["survolt"] = "Survolt",
  ["joyster"] = "Joyster",
  ["leganza"] = "Leganza",
  ["tico"] = "Tico Rider",
  ["16challenger"] = "Challenger 2016",
  ["16charger"] = "Charger 2016",
  ["69charger"] = "Charger 1969",
  ["99viper"] = "Viper 1999",
  ["rt70"] = "Charger RT 1970",
  ["ram2500"] = "RAM 2500",
  ["10ram"] = "RAM 1500",
  ["acr"] = "Viper ACR",
  ["250gtb"] = "250 GTB",
  ["gto2"] = "250 GT0",
  ["348s"] = "348 S",
  ["412"] = "412",
  ["f458"] = "458",
  ["488"] = "488",
  ["488gtb"] = "488 GTB",
  ["612ss"] = "612 SS",
  ["f60"] = "F60",
  ["bb512"] = "BB512",
  ["dino"] = "Dino",
  ["pista"] = "458 Pista",
  ["f8t"] = "F8T",
  ["f40"] = "F40",
  ["f288gto"] = "288 GTO",
  ["f308"] = "308",
  ["f355"] = "355",
  ["f430s"] = "430 S",
  ["4881"] = "488 GTB",
  ["fct"] = "599 GTB",
  ["feF50"] = "F50",
  ["fer612"] = "612",
  ["f812"] = "812 Superfast",
  ["gto"] = "599 GTO",
  ["aperta"] = "LaFerrari Aperta",
  ["575m"] = "575 Maranello",
  ["modena"] = "360 Modena",
  ["monza"] = "Monza",
  ["fpino"] = "Enzo",
  ["f12m"] = "F12 Mansory",
  ["trossa"] = "Testarossa",
  ["fiorino"] = "Fiorino",
  ["punto"] = "Punto",
  ["boss302"] = "BOSS 302",
  ["boss429"] = "BOSS 429",
  ["bronco"] = "Bronco",
  ["eleanor"] = "Eleanor",
  ["everest"] = "Everest",
  ["f150"] = "Raptor 150",
  ["f15078"] = "Raptor 150 1978",
  ["fastback"] = "Fastback",
  ["focusrs"] = "Focus RS",
  ["fusiont"] = "Fusion",
  ["gt17"] = "GT 2017",
  ["mgt"] = "Mustang GT",
  ["mst"] = "Shelby",
  ["superduty"] = "Superduty",
  ["fgt"] = "GT 2007",
  ["denalihd"] = "Denali",
  ["gmcyd"] = "Yukon",
  ["gmcs"] = "Yukon S",
  ["yukonxl"] = "Ykon XL",
  ["xnsgt"] = "Venom GT",
  ["ap2"] = "S2000",
  ["civic"] = "Civic",
  ["dc2"] = "Civic Type-R",
  ["ek9"] = "Integra Type-R",
  ["acura2f2f"] = "Acura",
  ["2f2fs2000"] = "S2000",
  ["fnfrx7dom"] = "RX7",
  ["fk2"] = "Civic Type-R",
  ["fk8"] = "Civic Type-R",
  ["hondacivictr"] = "Civic Type R",
  ["na1"] = "NSX 1992",
  ["nc1"] = "NSX 2017",
  ["ody18"] = "Odyssey 2018",
  ["accent"] = "Accent",
  ["gencoupe"] = "Genesis",
  ["hyundaiv"] = "Veracruz",
  ["ix35"] = "IX 35",
  ["hkona"] = "Kona",
  ["sont18"] = "Sonata",
  ["tiburon"] = "Triburon",
  ["veln"] = "Veloster",
  ["fx50s"] = "FX 50S",
  ["inf"] = "Infiniti",
  ["infinitig35"] = "G35",
  ["ipl"] = "G37",
  ["q30"] = "Q30",
  ["qx56"] = "QX56",
  ["p7"] = "P7",
  ["etype2"] = "E-Type",
  ["fpacehm"] = "F-Pace",
  ["ftype"] = "F-Type",
  ["jagpr8"] = "PR8",
  ["jagxjs80"] = "XJS 1980",
  ["xes2015"] = "XES 2015",
  ["xfr"] = "XFR",
  ["xj"] = "XJ",
  ["xj220"] = "XJ 220",
  ["cherokee96"] = "Cherokee 1996",
  ["jeep2012"] = "Jeep 2012",
  ["cherokee1"] = "Cherokee",
  ["jeepreneg"] = "Renegade",
  ["srt8"] = "SRT",
  ["trailcat"] = "TrailCat",
  ["trhawk"] = "Cherokee SC",
  ["kiagt"] = "GT",
  ["kiasoul2"] = "Soul",
  ["koup"] = "Koup",
  ["sportage"] = "Sportage",
  ["KoenigseggAgeraR"] = "Agera R",
  ["agerars"] = "Agera RS",
  ["ccx"] = "CCX",
  ["jes"] = "Jesko",
  ["regera"] = "Regera",
  ["18performante"] = "Huracan Perf",
  ["500gtrlam"] = "Diablo GTR",
  ["asterion"] = "Asterion",
  ["avj"] = "Aventador S",
  ["count6"] = "Countach",
  ["lp610"] = "Hurucan LP610",
  ["lp670sv"] = "Murcielago",
  ["lp700"] = "Aventador LP700",
  ["lp770"] = "Centenario",
  ["diablo"] = "Diablo SV",
  ["miura"] = "Miura",
  ["sc18"] = "SC18",
  ["rmodsian"] = "Sian",
  ["urus"] = "Urus",
  ["rmodveneno"] = "Veneno",
  ["sesto"] = "Sesto Elemento",
  ["deltaintegrale"] = "Delta I",
  ["lanciad"] = "Delta",
  ["l37"] = "Bucca",
  ["gs350"] = "GS 350",
  ["gsf"] = "GSF",
  ["is350mod"] = "IS 350",
  ["lx570"] = "LX 570",
  ["RC350S"] = "RC 350 S",
  ["rx450h"] = "RX 450 H",
  ["lexus"] = "LS 500",
  ["nx200"] = "NX 200",
  ["lx2018"] = "LX 2018",
  ["lc500"] = "LC 500",
  ["gx460"] = "GX 460",
  ["CT200H"] = "CT 200 H",
  ["63lb"] = "C63 AMG",
  ["ar8lb"] = "R8",
  ["filthynsx"] = "NSX",
  ["gallardosuperlb"] = "Gallardo",
  ["gt86lb"] = "GT86",
  ["gtrlb2"] = "GTR R35",
  ["610lb"] = "610",
  ["huralbcamber"] = "Huracan",
  ["lwas5"] = "S5",
  ["lw458s"] = "458",
  ["993rwb"] = "993",
  ["cortina"] = "Cortina",
  ["exigev6"] = "Exige V6",
  ["esprit02"] = "Esprit",
  ["evora"] = "Evora",
  ["l111s"] = "111 S",
  ["carlton"] = "Carlton",
  ["ghis2"] = "Ghibli",
  ["levante"] = "Levante",
  ["mcgt4"] = "GT4",
  ["mgrantur2010"] = "Gran turismo 2010",
  ["mlmansory"] = "LM Mansory",
  ["mlnovitec"] = "Novitech",
  ["mqgts"] = "Quattroparte",
  ["19S650"] = "19 S650",
  ["scaldarsi"] = "Scaldarsi",
  ["fc3s"] = "RX7 Savana",
  ["fd"] = "RX7 FD",
  ["mx5326"] = "MX53 2006",
  ["na6"] = "MX-5",
  ["rx3"] = "RX3",
  ["rx7tunable"] = "RX7",
  ["rx8m"] = "RX8 M",
  ["rx8r"] = "RX8 R",
  ["rxf7"] = "RX-F7",
  ["fnfrx7"] = "RX7",
  ["2f2frx7"] = "RX7",
  ["650s"] = "650S",
  ["675lt"] = "675LT",
  ["720s"] = "720S",
  ["mp412c"] = "MP4 12C",
  ["p1"] = "P1",
  ["12cls63"] = "CLS 63",
  ["mb300sl"] = "300 SL",
  ["500w124"] = "500W124",
  ["600sel"] = "600 SL",
  ["amggt"] = "AMG GT",
  ["amggtr"] = "AMG GTRR",
  ["amggtr2"] = "AMG GTR",
  ["c63w205"] = "C63W205",
  ["e63amg"] = "E 63 AMG",
  ["e400"] = "E400",
  ["g65amg"] = "G65 AMG",
  ["gl63"] = "GL63",
  ["mers63c"] = "63C",
  ["s500w222"] = "S500W222",
  ["s600w220"] = "S600W220",
  ["slsamg"] = "SLS AMG",
  ["v250"] = "Vito",
  ["cla45sb"] = "Classe A AMG",
  ["cooperworks"] = "Works",
  ["mcjcw20"] = "Works 2020",
  ["mrbeanmini"] = "MisterBean",
  ["3000gt"] = "3000 GT",
  ["cp9a"] = "Evo 3",
  ["eclipse"] = "Eclipse",
  ["evo9"] = "Evo 9",
  ["evo10"] = "Evo 10",
  ["tritonhpe"] = "Triton HPE",
  ["lanex400"] = "Evo 10",
  ["evo9mr"] = "Evo 9 MR",
  ["2f2fgts"] = "Spyder GTS",
  ["fnfmits"] = "Eclipse",
  ["2f2fmle7"] = "Evo 7",
  ["fnflan"] = "Evo 8",
  ["hcej1"] = "Mitsubishi",
  ["180sx"] = "180SX",
  ["350z"] = "350 Z",
  ["350zrb"] = "350 ZRB",
  ["370z"] = "370 Z",
  ["gtr"] = "GTR",
  ["kgc10"] = "GT",
  ["maj350"] = "Fairlady Z",
  ["majsr"] = "R32",
  ["gtrnismo17"] = "GTR Nismo 2017",
  ["nisaltima"] = "Altima",
  ["nismo20"] = "GTR Nismo",
  ["nissantitan17"] = "Titan",
  ["patrold"] = "Patrol SLX",
  ["patroly60"] = "Patrol",
  ["qashqai16"] = "Qashqai",
  ["r33"] = "R33",
  ["s30"] = "Fairlady",
  ["skyline"] = "R34",
  ["skylinec110"] = "Skyline GT",
  ["tule"] = "Armada",
  ["z32"] = "300 ZX",
  ["silvias15"] = "Silvia S15",
  ["2f2fgtr34"] = "GTR R34",
  ["fnf4r34"] = "R34",
  ["350zdk"] = "350Z",
  ["350zm"] = "350Z",
  ["m600"] = "M600",
  ["protopolice"] = "Prototype",
  ["onyx"] = "Onyx",
  ["avalk"] = "Valkyrie",
  ["chargerf8"] = "Coquette BlackFin",
  ["212expo51"] = "Blade",
  ["mvisiongt"] = "Vision GT",
  ["gtr2020"] = "GTR 2020",
  ["mb6"] = "Vision Maybach",
  ["arrow"] = "Prototype",
  ["opeladam"] = "Adam",
  ["astraj"] = "Astra",
  ["mokka"] = "Mokka",
  ["corsa05"] = "Corsa 2005",
  ["corsa09"] = "Corsa 2009",
  ["corsae"] = "Corsa",
  ["2dopelr3"] = "R3",
  ["bc"] = "Huayra BC",
  ["huayra"] = "Huayra",
  ["zondac"] = "Zonda C",
  ["zondar"] = "Zonda R",
  ["205GTti"] = "205 GTI",
  ["206lo"] = "206 GTI",
  ["208gti21"] = "208 GTI",
  ["405glxfn"] = "405 GLX",
  ["504coupe"] = "504",
  ["p207"] = "207",
  ["peug108"] = "108",
  ["peug308"] = "308",
  ["peugeot"] = "405",
  ["Peugeot204"] = "204",
  ["rcz16"] = "RCZ 2016",
  ["taxi2"] = "405",
  ["yPG205t16A"] = "205 Turbo",
  ["356ac"] = "356",
  ["718"] = "718",
  ["718b"] = "718B",
  ["718caymans"] = "Cayman",
  ["718rs"] = "718 RS",
  ["p911r"] = "911 R",
  ["911tbs"] = "911 Turbo S",
  ["911turbos"] = "911 Turbo S",
  ["918"] = "918",
  ["968"] = "968",
  ["p901"] = "901",
  ["718boxster"] = "718 Boxster",
  ["pcs18"] = "Cayenne S",
  ["911r"] = "911 R",
  ["p928"] = "928",
  ["panamera17turbo"] = "Panamera T",
  ["pruf"] = "Pruf",
  ["cayenne"] = "Cayenne",
  ["porschehw"] = "Cayman GT4 S",
  ["taycan"] = "Taycan",
  ["macan"] = "Macan Turbo",
  ["cayenneturbo"] = "Cayenne Turbo S",
  ["992c"] = "911 Carrera S",
  ["17cliofl"] = "Clio 4",
  ["clio"] = "Clio 1 W",
  ["cliors"] = "Clio RS",
  ["cliov6"] = "Clio V6",
  ["espace3"] = "Espace 3",
  ["kangoo"] = "kangoo",
  ["koleos"] = "Loleos",
  ["master2019"] = "Master 2019",
  ["mers18"] = "Megane RS",
  ["pacev"] = "Espace 5",
  ["ren21"] = "21",
  ["renault4"] = "4",
  ["renault4l"] = "4L",
  ["renault8"] = "8",
  ["renault16"] = "16",
  ["rencaptur"] = "Captur",
  ["renmaster"] = "Master 2008",
  ["twingo"] = "Twingo 3",
  ["twingo2"] = "Twingo",
  ["twizy"] = "Twizy",
  ["yRenault5TB"] = "Renault 5 T",
  ["zoe"] = "ZOE",
  ["nsexrb"] = "NSX 1992",
  ["rculi"] = "Cullinan",
  ["rrphantom"] = "Phantom",
  ["wraith"] = "Wraith",
  ["def90"] = "Defender 1990",
  ["oycdefenderp"] = "Defender Police",
  ["evoque"] = "Evoque",
  ["FX4"] = "Discovery 4",
  ["landseries3"] = "Serie 3",
  ["lrrr"] = "Range Rover",
  ["rr12"] = "2012",
  ["rrs08"] = "2008",
  ["rrst"] = "Startech",
  ["svr16"] = "SVR 2016",
  ["2012leon"] = "Leon 2012",
  ["ibiza"] = "Cupra",
  ["seatleon"] = "Leon",
  ["ss7"] = "S7",
  ["19gt500"] = "19 GT500",
  ["cobra"] = "Cobra",
  ["fmss"] = "SS",
  ["gdwrxsti"] = "WRX STI",
  ["subwrx"] = "WRX",
  ["SubaruSTI7"] = "STI 2007",
  ["sti"] = "Impreza STI",
  ["sim22"] = "WRC 2002",
  ["ff4wrx"] = "WRX",
  ["teslapd"] = "Model E",
  ["teslax"] = "Model X",
  ["tmodel"] = "Model T",
  ["tr22"] = "Roadster",
  ["a80"] = "A80",
  ["ae86"] = "AE86",
  ["camry18"] = "Camry18",
  ["camry55"] = "Camry55",
  ["camv50"] = "Camry50",
  ["celica"] = "Celica",
  ["chr"] = "CHR",
  ["GT86"] = "GT86",
  ["supraa90"] = "Supra",
  ["2000gt"] = "2000 GT",
  ["prius"] = "Prius",
  ["yaris08"] = "Yaris 2008",
  ["2f2fmk4"] = "Supra",
  ["fnfmk4"] = "Supra",
  ["tvrs"] = "Sagaris",
  ["grif"] = "Grif",
  ["amarok"] = "Amarok",
  ["fulux63"] = "Coccinelle 1963",
  ["golf7r"] = "Golf 7R",
  ["golfgti"] = "Golf 7 GTI",
  ["mk1rabbit"] = "Golf 1 GTI",
  ["passat"] = "Passat",
  ["polo2018"] = "Polo 2018",
  ["R50"] = "Touareg",
  ["fnfjetta"] = "Jetta",
  ["06xc90eu"] = "XC90",
  ["s60pole"] = "S60",
  ["v60"] = "V60",
  ["v242"] = "242",
  ["volvo850r"] = "850 R",
  ["ts1"] = "ST1",
  ["zn20"] = "ST1 2020"
}

-- Block certain vehicles from being transferred to other players
Config.PlayerTransferBlacklist = {
  "spawnName"
}

Config.AutoRunSQL = true
Config.ReturnToPreviousRoutingBucket = false
Config.HideWatermark = true
Config.__v3Config = true
Config.Debug = false