-----------------------------------------------------------------------------------------------------------
------------------------------------------- VEHICLE SERVICING ---------------------------------------------
-----------------------------------------------------------------------------------------------------------
--
-- In here you can modify the various wearable vehicle parts. Please don't remove any options in here as
-- it could have undesirable effects, and instead just disable servicing altogether in config.lua if you
-- don't want this functionality to be enabled.
--
-- Read on for explanations of what each of the options mean in here
--
-----------------------------------------------------------------------------------------------------------
--  enableDamage              Enable or disable this specific part. Disabling it means that it won't wear
--                            as the vehicle drives, and will remain at 100%
-----------------------------------------------------------------------------------------------------------
--  lifespanInKm              This is probably the ONLY option you should mess with. This allows you to
--                            configure how quickly parts wear and need replacing based on mileage
--
--                            250 = 0% health of the part after 250km and will noticely affect the vehicle
-----------------------------------------------------------------------------------------------------------
--  itemName                  The name of the required item to replace the part
-----------------------------------------------------------------------------------------------------------
--  itemQuantity              The number of the above item required to replace the part
-----------------------------------------------------------------------------------------------------------
--  restricted                Either "combustion" or "electric". Restricts parts to a certain engine type
-----------------------------------------------------------------------------------------------------------

Config.Servicing = {
  suspension = {
    enableDamage = true,
    lifespanInKm = 1000,
    itemName = "suspension_parts",
    itemQuantity = 1
  },
  tyres = {
    enableDamage = true,
    lifespanInKm = 250,
    itemName = "tyre_replacement",
    itemQuantity = 4
  },
  brakePads = {
    enableDamage = true,
    lifespanInKm = 500,
    itemName = "brakepad_replacement",
    itemQuantity = 4
  },

  --
  -- Combustion engines only
  --
  engineOil = {
    enableDamage = true,
    lifespanInKm = 100,
    itemName = "engine_oil",
    itemQuantity = 1,
    restricted = "combustion",
  },
  clutch = {
    enableDamage = true,
    lifespanInKm = 500,
    itemName = "clutch_replacement",
    itemQuantity = 1,
    restricted = "combustion",
  },
  airFilter = {
    enableDamage = true,
    lifespanInKm = 250,
    itemName = "air_filter",
    itemQuantity = 1,
    restricted = "combustion",
  },
  sparkPlugs = {
    enableDamage = true,
    lifespanInKm = 150,
    itemName = "spark_plug",
    itemQuantity = 4,
    restricted = "combustion",
  },

  -- 
  -- Electric vehicles only
  --
  evMotor = {
    enableDamage = true,
    electric = true,
    lifespanInKm = 2000,
    itemName = "ev_motor",
    itemQuantity = 1,
    restricted = "electric",
  },
  evBattery = {
    enableDamage = true,
    electric = true,
    lifespanInKm = 500,
    itemName = "ev_battery",
    itemQuantity = 1,
    restricted = "electric",
  },
  evCoolant = {
    enableDamage = true,
    electric = true,
    lifespanInKm = 250,
    itemName = "ev_coolant",
    itemQuantity = 1,
    restricted = "electric",
  }
}

-----------------------------------------------------------------------------------------------------------
--  Crash / Collision Damage to Servicing
--  Degrades servicing parts when a vehicle experiences collisions / crashes
-----------------------------------------------------------------------------------------------------------
Config.CrashDamageToServicing = {
  enabled = true,
  minDamageThreshold = 25.0,     -- Minimum body/engine health drop from a crash to trigger part damage
  damageMultiplier = 0.05,       -- Servicing health loss ratio relative to crash damage (e.g. 200 damage * 0.05 = 10% wear)
  partMultipliers = {
    suspension = 1.2,            -- Suspension takes more damage on impact
    tyres = 1.0,
    brakePads = 0.6,
    engineOil = 1.0,
    sparkPlugs = 1.1,
    clutch = 0.8,
    airFilter = 1.0,
    evMotor = 1.0,
    evBattery = 1.2,
    evCoolant = 1.0
  }
}

