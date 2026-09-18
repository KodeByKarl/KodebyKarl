DEFAULT_LOCATIONS = {
  ["pdm"] = {
    label = "Platinum Deluxe Motorsport",
    type = "self-service",
    zone = {
      vec3(-61.96832656860352, -1093.244873046875, 26.50298309326172),
      vec3(-61.89256286621094, -1099.4454345703126, 26.36795616149902),
      vec3(-63.95220565795898, -1111.5518798828126, 26.39735603332519),
      vec3(-62.21648788452149, -1118.2406005859376, 26.43209457397461),
      vec3(-40.89399337768555, -1117.974853515625, 26.4392147064209),
      vec3(-30.73427200317382, -1121.8397216796876, 26.58179473876953),
      vec3(-25.16510009765625, -1117.9866943359376, 26.72819519042968),
      vec3(-17.47736740112304, -1118.057373046875, 26.8187255859375),
      vec3(-9.06537055969238, -1097.8765869140626, 26.67206001281738),
      vec3(-10.70630550384521, -1094.0048828125, 26.67206001281738),
      vec3(-8.02139377593994, -1084.4581298828126, 26.67206001281738),
      vec3(-17.64135551452636, -1081.295166015625, 26.67206001281738),
      vec3(-21.90179824829101, -1082.6927490234376, 26.64069747924804),
      vec3(-53.52227783203125, -1071.516845703125, 27.2151927947998)
    },
    openShowroom = {
      coords = vector3(-55.99, -1096.59, 26.42),
      size = 5
    },
    openManagement = {
      coords = vector3(-30.43, -1106.84, 26.42),
      size = 5
    },
    sellVehicle = {
      coords = vector3(-27.89, -1082.1, 26.64),
      size = 5
    },
    purchaseSpawn = vector4(-13.68, -1092.31, 26.67, 159.82),
    testDriveSpawn = vector4(-49.77, -1110.83, 26.44, 75.94),
    camera = {
      name = "Car",
      coords = vector4(-146.6166, -596.6301, 166.0, 270.0),
      positions = {5.0, 8.0, 12.0, 8.0}
    },
    categories = {"sedans", "compacts", "motorcycles", "offroad", "coupes", "muscle", "suvs", "sportsclassics"},
    enableTestDrive = true,
    hideBlip = false,
    blip = {
      id = 326,
      color = 2,
      scale = 0.6
    },
    enableSellVehicle = true,
    sellVehiclePercent = 0.6,
    enableFinance = true,
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
    showroomJobWhitelist = {},
    showroomGangWhitelist = {},
    societyPurchaseJobWhitelist = {},
    societyPurchaseGangWhitelist = {},
    disableShowroomPurchase = false,
    directSaleDistance = 50,
  },
  ["luxury"] = {
    label = "Luxury Autos",
    type = "self-service",
    zone = {
      vec3(-1269.079833984375, -376.67193603515627, 36.54177856445312),
      vec3(-1274.8675537109376, -360.0185546875, 36.66796875),
      vec3(-1272.938720703125, -354.2353515625, 36.6653938293457),
      vec3(-1260.4613037109376, -348.0028991699219, 36.84260940551758),
      vec3(-1246.5419921875, -339.59332275390627, 37.1115837097168),
      vec3(-1236.010009765625, -335.1236877441406, 37.30297088623047),
      vec3(-1226.7403564453126, -351.6814880371094, 37.33281707763672),
      vec3(-1226.3885498046876, -352.32891845703127, 37.33281707763672)
    },
    openShowroom = {
      coords = vector3(-1257.4, -369.12, 36.98),
      size = 5
    },
    openManagement = {
      coords = vector3(-1249.04, -346.96, 37.34),
      size = 5
    },
    sellVehicle = {
      coords = vector3(-1233.46, -346.81, 37.33),
      size = 5
    },
    purchaseSpawn = vector4(-1233.46, -346.81, 37.33, 23.36),
    testDriveSpawn = vector4(-1233.46, -346.81, 37.33, 23.36),
    camera = {
      name = "Car",
      coords = vector4(-146.6166, -596.6301, 166.0, 270.0),
      positions = {5.0, 8.0, 12.0, 8.0}
    },
    categories = {"super", "sports"},
    enableSellVehicle = true,
    sellVehiclePercent = 0.6,
    enableTestDrive = true,
    enableFinance = true,
    hideBlip = false,
    blip = {
      id = 523,
      color = 2,
      scale = 0.6
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
    showroomJobWhitelist = {},
    showroomGangWhitelist = {},
    societyPurchaseJobWhitelist = {},
    societyPurchaseGangWhitelist = {},
  },
  ["boats"] = {
    label = "Boat Dealer",
    type = "self-service",
    zone = {
      vec3(-789.5499877929688, -1383.75, 1.60000002384185),
      vec3(-689.5499877929688, -1383.75, 1.60000002384185),
      vec3(-689.5499877929688, -1283.75, 1.60000002384185),
      vec3(-789.5499877929688, -1283.75, 1.60000002384185)
    },
    openShowroom = {
      coords = vector3(-739.55, -1333.75, 1.6),
      size = 5
    },
    openManagement = {
      coords = vector3(-731.37, -1310.35, 5.0),
      size = 5
    },
    sellVehicle = {
      coords = vector3(-714.42, -1340.01, -0.18),
      size = 5
    },
    purchaseSpawn = vector4(-714.42, -1340.01, -0.18, 139.38),
    testDriveSpawn = vector4(-714.42, -1340.01, -0.18, 139.38),
    camera = {
      name = "Sea",
      coords = vector4(-808.28, -1491.19, -0.47, 113.53),
      positions = {7.5, 12.0, 15.0, 12.0}
    },
    categories = {"boats"},
    enableSellVehicle = true,
    sellVehiclePercent = 0.6,
    enableTestDrive = false,
    hideBlip = false,
    blip = {
      id = 410,
      color = 2,
      scale = 0.6
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
    showroomJobWhitelist = {},
    showroomGangWhitelist = {},
    societyPurchaseJobWhitelist = {},
    societyPurchaseGangWhitelist = {},
  },
  ["air"] = {
    label = "Aircraft Dealer",
    type = "self-service",
    zone = {
      vec3(-1672.8134765625, -3105.486328125, 13.9902229309082),
      vec3(-1693.2274169921876, -3141.412353515625, 13.99023914337158),
      vec3(-1685.011474609375, -3146.032958984375, 13.99054813385009),
      vec3(-1694.6263427734376, -3163.054443359375, 13.99024391174316),
      vec3(-1646.007080078125, -3190.672119140625, 13.99027633666992),
      vec3(-1607.4957275390626, -3141.554931640625, 13.9903450012207)
    },
    openShowroom = {
      coords = vector3(-1623.0, -3151.56, 13.99),
      size = 5
    },
    openManagement = {
      coords = vector3(-1637.78, -3177.94, 13.99),
      size = 5
    },
    sellVehicle = {
      coords = vector3(-1654.9, -3147.58, 13.99),
      size = 5
    },
    purchaseSpawn = vector4(-1654.9, -3147.58, 13.99, 324.78),
    testDriveSpawn = vector4(-1654.9, -3147.58, 13.99, 324.78),
    camera = {
      name = "Air",
      coords = vector4(-1267.0, -3013.14, -48.5, 310.96),
      positions = {12.0, 15.0, 20.0, 15.0}
    },
    categories = {"planes", "helicopters"},
    enableSellVehicle = true,
    sellVehiclePercent = 0.6,
    enableTestDrive = false,
    hideBlip = false,
    blip = {
      id = 423,
      color = 2,
      scale = 0.6
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
    showroomJobWhitelist = {},
    showroomGangWhitelist = {},
    societyPurchaseJobWhitelist = {},
    societyPurchaseGangWhitelist = {},
  },
  ["truck"] = {
    label = "Truck Dealer",
    type = "self-service",
    zone = {
      vec3(1175.86669921875, -3207.540283203125, 6.0280418395996),
      vec3(1174.5440673828126, -3178.2724609375, 6.0280418395996),
      vec3(1211.421875, -3178.83349609375, 5.57529926300048),
      vec3(1211.4990234375, -3200.65087890625, 6.0280418395996),
      vec3(1216.6416015625, -3200.782958984375, 5.52807092666626),
      vec3(1215.9632568359376, -3208.222412109375, 6.0280418395996)
    },
    openShowroom = {
      coords = vector3(1214.37, -3204.53, 6.03),
      size = 5
    },
    openManagement = {
      coords = vector3(1184.45, -3179.27, 7.1),
      size = 5
    },
    sellVehicle = {
      coords = vector3(1196.75, -3205.31, 6.0),
      size = 5
    },
    purchaseSpawn = vector4(1196.75, -3205.31, 6.0, 91.12),
    testDriveSpawn = vector4(1196.75, -3205.31, 6.0, 91.12),
    camera = {
      name = "Truck",
      coords = vector4(-1267.0, -3013.14, -48.5, 310.96),
      positions = {7.5, 12.0, 15.0, 12.0}
    },
    categories = {"vans", "commercial", "industrial"},
    enableSellVehicle = true,
    sellVehiclePercent = 0.6,
    enableTestDrive = true,
    enableFinance = true,
    hideBlip = false,
    blip = {
      id = 477,
      color = 2,
      scale = 0.6
    },
    hideMarkers = false,
    markers = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 }, bobUpAndDown = 0, faceCamera = 0, rotate = 1, drawOnEnts = 0 },
    showroomJobWhitelist = {},
    showroomGangWhitelist = {},
    societyPurchaseJobWhitelist = {},
    societyPurchaseGangWhitelist = {},
  },
}