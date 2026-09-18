Config = {}

-- Integrations (recommended to leave as "auto")
Config.Framework = "ESX" -- or "QBCore", "Qbox", "ESX"
Config.Inventory = "ox_inventory" -- or "ox_inventory", "qb-inventory", "esx_inventory", "codem-inventory", "qs-inventory"
Config.Notifications = "ox_lib" -- or "default", "ox_lib", "lation_ui", "ps-ui", "okokNotify", "nox_notify"
Config.ProgressBar = "ox-circle" -- or "ox-circle", "ox-bar", "lation_ui", "qb"
Config.SkillCheck = "ox" -- or "ox", "qb", "lation_ui"
Config.DrawText = "ox_lib" -- or "jg-textui", "ox_lib", "okokTextUI", "ps-ui", "lation_ui", "qb"
Config.SocietyBanking = "cfx-keydi-society" -- or "cfx-keydi-society", "okokBanking", "fd_banking", "Renewed-Banking", "tgg-banking", "qb-banking", "qb-management", "esx_addonaccount"
Config.Menus = "ox" -- or "ox", "lation_ui"

-- Localisation
Config.Locale = "en"
Config.NumberAndDateFormat = "en-US"
Config.Currency = "USD"

-- Set to false to use built-in job system
Config.UseFrameworkJobs = true

-- Mechanic Tablet
Config.UseTabletCommand = "tablet" -- set to false to disable command
Config.TabletConnectionMaxDistance = 4.0

-- Shops
Config.Target = "ox_target" -- (shops/stashes only) "qb-target" or "ox_target"
Config.UseSocietyFund = false -- set to false to use player balance
Config.PlayerBalance = "bank" -- or "bank" or "cash"

-- Skill Bars
Config.UseSkillbars = true -- set to false to use progress bars instead of skill bars for installations
Config.ProgressBarDuration = 10000 -- if not using skill bars, this is the progress bar duration in ms (10000 = 10 seconds)
Config.MaximumSkillCheckAttempts = 3 -- How many times the player can attempt a skill check before the skill check fails
Config.SkillCheckDifficulty = { "easy", "easy", "easy", "easy", "easy" } -- for ox only
Config.SkillCheckInputs = { "w", "a", "s", "d" } -- for ox only

-- Servicing
Config.EnableVehicleServicing = true
Config.ServiceRequiredThreshold = 20 -- [%] if any of the servicable parts hit this %, it will flag that the vehicle needs servicing 
Config.ServicingBlacklist = {
  -- Vanilla LEO
  "police", "police2", "police3", "police4", "policeb", "policet", "sheriff", "sheriff2", "pranger", "fbi", "fbi2",
  -- Job garage spawners (shared plates recycle worn servicing — keep these excluded)
  "ghispo2", "slick23tahoeb", "polmav", "cargobob", "seasparrow",
  "ambulance", "dodgeems", "lguard",
}

-- Nitrous
Config.NitrousScreenEffects = true
Config.NitrousRearLightTrails = true -- Only really visible at night
Config.NitrousPowerIncreaseMult = 2.0
Config.NitrousDefaultKeyMapping = "RMENU"
Config.NitrousMaxBottlesPerVehicle = 3 -- The UI can't really handle more than 7, more than that would be unrealistic anyway
Config.NitrousBottleDuration = 10 -- [in seconds] How long a nitrous tank lasts
Config.NitrousBottleCooldown = 5 -- [in seconds] How long until player can start using the next bottle
Config.NitrousPurgeDrainRate = 0.1 -- purging drains bottle only 10% as fast as actually boosting - set to 1 to drain at the same rate 

-- Stancing
Config.StanceMinSuspensionHeight = -0.3
Config.StanceMaxSuspensionHeight = 0.3
Config.StanceMinCamber = 0.0
Config.StanceMaxCamber = 0.5
Config.StanceMinTrackWidth = 0.5
Config.StanceMaxTrackWidth = 1.25
Config.StanceNearbyVehiclesFreqMs = 500

-- Repairs
Config.AllowFixingAtOwnedMechanicsIfNoOneOnDuty = false
Config.DuctTapeMinimumEngineHealth = 100.0
Config.DuctTapeEngineHealthIncrease = 150.0

-- Tuning
Config.TuningGiveInstalledItemBackOnRemoval = false

-- Locations
Config.UseCarLiftPrompt = "[E] Use car lift"
Config.UseCarLiftKey = 38
Config.CustomiseVehiclePrompt = "[E] Customise vehicle"
Config.CustomiseVehicleKey = 38

-- Update vehicle props whenever they are changed [probably should not touch]
-- You can set to false to leave saving any usual props vehicle changes such as
-- GTA performance, cosmetic, colours, wheels, etc to the garage or other scripts
-- that persist the props data to the database. Additional data from this script,
-- such as engine swaps, servicing etc is not affected as it's saved differently
Config.UpdatePropsOnChange = true

-- Stops vehicles from immediately going to redline, for a slightly more realistic feel and
-- reduced liklihood of wheelspin. Can make vehicle launch (slightly) slower.
-- No effect on electric vehicles!
-- May not work immediately for all vehicles; see: https://docs.jgscripts.com/mechanic/manual-transmissions-and-smooth-first-gear#smooth-first-gear
Config.SmoothFirstGear = false

-- If using a manual gearbox, show a notification with key binds when high RPMs 
-- have been detected for too long
Config.ManualHighRPMNotifications = false

-- Misc
Config.UniqueBlips = false -- single "Mechanic" blip (not "Mechanic: bennys")
Config.ModsPricesAsPercentageOfVehicleValue = false -- Enable pricing tuning items as % of vehicle value - it tries jg-dealerships, then QBShared, then the vehicles meta file automagically for pricing data
Config.AdminsHaveEmployeePermissions = false -- admins can use tablet & interact with mechanics like an owner
Config.MechanicEmployeesCanSelfServiceMods = false -- set to true to allow mechanic employees to bypass the "place order" system at their own mechanic
Config.FullRepairAdminCommand = "vfix"
Config.MechanicAdminCommand = "mechanicadmin"
Config.ChangePlateDuringPreview = "PREVIEW"
Config.RequireManagementForOrderDeletion = true 
Config.UseCustomNamesInTuningMenu = false
Config.DisableNoPaymentOptionForEmployees = true

-- Mechanic Locations
Config.MechanicLocations = {
  bennys = {
    type = "owned",
    job = "mechanic",
    logo = "bennys.png", -- logos go in /logos
    locations = {
      -- Working stations (mod / customise vehicle)
      { coords = vector3(2716.3115, 3471.7180, 55.7172), size = 7.0, showBlip = true },
      { coords = vector3(2724.1841, 3469.0698, 55.7172), size = 7.0, showBlip = false },
      { coords = vector3(2709.3286, 3475.4915, 55.7172), size = 7.0, showBlip = false },
      { coords = vector3(2701.8164, 3478.8088, 55.7172), size = 7.0, showBlip = false },
      { coords = vector3(2694.0645, 3481.7749, 55.7172), size = 7.0, showBlip = false },
      { coords = vector3(2686.8181, 3484.9988, 55.7172), size = 7.0, showBlip = false },
      { coords = vector3(2679.4810, 3488.2649, 55.7172), size = 7.0, showBlip = false },
    },
    blip = {
      id = 446,
      color = 47,
      scale = 0.7
    },
    mods = {
      repair           = { enabled = true, price = 0, percentVehVal = 0.01 },
      performance      = { enabled = true, price = 0, percentVehVal = 0.01, priceMult = 0.1 },
      cosmetics        = { enabled = true, price = 0, percentVehVal = 0.01, priceMult = 0.1 },
      stance           = { enabled = true, price = 0, percentVehVal = 0.01 },
      respray          = { enabled = true, price = 0, percentVehVal = 0.01 },
      wheels           = { enabled = true, price = 0, percentVehVal = 0.01, priceMult = 0.1 },
      neonLights       = { enabled = true, price = 0, percentVehVal = 0.01 },
      headlights       = { enabled = true, price = 0, percentVehVal = 0.01 },
      tyreSmoke        = { enabled = true, price = 0, percentVehVal = 0.01 },
      bulletproofTyres = { enabled = false, price = 0, percentVehVal = 0.01 },
      extras           = { enabled = true, price = 0, percentVehVal = 0.01 }
    },
    -- Required for tablet Tuning app (engine swaps, turbo, etc.)
    tuning = {
      engineSwaps   = { enabled = true, requiresItem = true },
      drivetrains   = { enabled = true, requiresItem = true },
      turbocharging = { enabled = true, requiresItem = true },
      tyres         = { enabled = true, requiresItem = true },
      brakes        = { enabled = true, requiresItem = true },
      driftTuning   = { enabled = true, requiresItem = true },
      gearboxes     = { enabled = false, requiresItem = false },
    },
    shops = {},
    stashes = {
      {
        name = "Shared Stash",
        coords = vector4(2710.7559, 3494.9822, 55.7303, 331.4203),
        size = 2.0,
        slots = 100,
        weight = 500000,
        usePed = false,
        marker = {
          id = 21,
          size = { x = 0.35, y = 0.35, z = 0.35 },
          color = { r = 50, g = 205, b = 50, a = 140 },
          bobUpAndDown = 0,
          faceCamera = 0,
          rotate = 1,
          drawOnEnts = 0,
        },
      },
    },
  },
}

-- Add electric vehicles to disable combustion engine features
-----------------------------------------------------------------------
-- PLEASE NOTE: In b3258 (Bottom Dollar Bounties) and newer, electric
-- vehicles are detected automatically, so this list is not used! 
Config.ElectricVehicles = {
  "Airtug",     "buffalo5",   "caddy",
  "Caddy2",     "caddy3",     "coureur",
  "cyclone",    "cyclone2",   "imorgon",
  "inductor",   "iwagen",     "khamelion",
  "metrotrain", "minitank",   "neon",
  "omnisegt",   "powersurge", "raiden",
  "rcbandito",  "surge",      "tezeract",
  "virtue",     "vivanite",   "voltic",
  "voltic2",
}

-- Nerd options
Config.DisableSound = false
Config.AutoRunSQL = true
Config.Debug = false
