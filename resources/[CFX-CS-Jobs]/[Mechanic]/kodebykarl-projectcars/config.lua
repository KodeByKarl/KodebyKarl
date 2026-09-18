Config = {}

Config.Locale = 'en'
Config.GarageId = 'Legion Square'
Config.FinishFuel = 100
Config.MaxProjects = 1
Config.SpawnDistance = 60.0
Config.InteractDistance = 2.15
Config.DrawDistance = 8.0
Config.InstallDuration = 4500
Config.DefaultModel = 'ody18'

-- Blueprint required when placing a vehicle shell (each project craft)
Config.BlueprintItem = 'car_blueprint'
Config.BlueprintAmount = 25
Config.BlueprintLabel = 'Car Blueprint'

-- Display names for project vehicles (metadata "Vehicle: …")
-- Keys MUST be lowercase spawncodes from kodebykarl-cars vehicles.meta
-- prefix = unique inventory item prefix (charger_engine, charger_tires, …)
-- short  = inventory label prefix ("Charger Engine")
Config.Vehicles = {
    -- Honda / Civic
    ody18 = { label = 'Odyssey 2018', short = 'Odyssey', prefix = 'odyssey' },
    ['74civrswb'] = { label = 'Honda Civic RS', short = 'Civic', prefix = 'civic' },

    -- Dodge / Chevy / GMC
    ['16charger'] = { label = 'Dodge Charger 2016', short = 'Charger', prefix = 'charger' },
    ['17silvk9rb'] = { label = 'Silverado K9', short = 'Silvia', prefix = 'silvia' },
    ['21sierra'] = { label = 'GMC Sierra 2021', short = 'Sierra', prefix = 'sierra' },
    ['2nddragg'] = { label = 'Drag Car', short = 'Dragg', prefix = 'dragg', loot = false },

    -- Mercedes / Land Rover / Genesis
    ['16topcargle'] = { label = 'Mercedes GLE TopCar', short = 'Top Car', prefix = 'topcar' },
    ['17mansorypnmr'] = { label = 'Mansory Panamera', short = 'Mansory', prefix = 'mansory' },
    ['18velar'] = { label = 'Range Rover Velar', short = 'Velar', prefix = 'velar' },
    ['19gv80'] = { label = 'Genesis GV80', short = 'GV80', prefix = 'gv80' },
    ['22g63'] = { label = 'Mercedes-AMG G63', short = 'G63', prefix = 'g63' },

    -- Audi
    ['18rs7'] = { label = 'Audi RS7', short = 'RS7', prefix = 'rs7' },
    ['21rsq8'] = { label = 'Audi RS Q8', short = 'RSQ8', prefix = 'rsq8' },

    -- BMW
    ['17m760i'] = { label = 'BMW 760i', short = 'M760i', prefix = 'm760i' },
    ['20xb7'] = { label = 'Alpina XB7', short = 'XB7', prefix = 'xb7' },
    ['22m5'] = { label = 'BMW M5', short = 'M5', prefix = 'm5' },
    ['2ncsx7'] = { label = 'BMW X7', short = 'X7', prefix = 'x7', loot = false },
    ['2ncsbmwm8'] = { label = 'BMW M8', short = 'BMW M8', prefix = 'bmwm8', loot = false },

    -- Exotic
    ['18performante'] = { label = 'Huracan Performante', short = 'Performante', prefix = 'performante' },
    ['22arturac'] = { label = 'McLaren Artura', short = 'Artura', prefix = 'artura' },

    -- Police pack
    ['slick23tahoeb'] = { label = 'Tahoe', short = 'Tahoe', prefix = 'tahoe' },
    ghispo2 = { label = 'Ghispo', short = 'Ghispo', prefix = 'ghispo' },

    -- Fast & Furious pack (data/2f2fgtr34) — metas only, no stream yet
    ['2f2fgtr34'] = { label = 'Nissan GTR R34', short = 'GTR R34', prefix = 'gtrr34', loot = false },
    ['2f2fgts'] = { label = 'Spyder GTS', short = 'GTS', prefix = 'gts', loot = false },
    ['2f2fmk4'] = { label = 'Toyota Supra MK4', short = 'MK4', prefix = 'mk4', loot = false },
    ['2f2fmle7'] = { label = 'Lancer Evo 7', short = 'MLE7', prefix = 'mle7', loot = false },
    ['ff4wrx'] = { label = 'Subaru WRX', short = 'WRX', prefix = 'wrx', loot = false },
    ['fnf4r34'] = { label = 'Nissan Skyline R34', short = 'R34', prefix = 'r34', loot = false },
    ['fnfmk4'] = { label = 'Toyota Supra MK4', short = 'MK4', prefix = 'mk4', loot = false },
    ['fnfrx7'] = { label = 'Mazda RX-7', short = 'RX7', prefix = 'rx7', loot = false },
    ['fnfmits'] = { label = 'Mitsubishi Eclipse', short = 'Mits', prefix = 'mits', loot = false },
}

-- Inventory tooltip titles for non-unique items (shell / blueprint / boxes)
Config.PartItemLabels = {
    car_blueprint = 'Project Vehicle Blueprint',
    project_parts_box = 'Project Parts Box',
    project_ayuda_box = 'Project Ayuda Box',
}

-- If true, shells can only be placed inside Config.BuildZones
Config.EnableZoneOnly = false
Config.BuildZones = {
    { label = 'Sandy Shores Yard', coords = vector3(1730.56, 3310.72, 41.22), radius = 150.0 },
}

Config.AdminGroups = {
    developer = true,
    owner = true,
    superadmin = true,
    admin = true,
    mod = true,
    god = true,
}

Config.DeleteCommand = 'destroyprojectcar'
Config.GiveShellCommand = 'giveshell'

-- Unique items = `{prefix}_{suffix}` e.g. charger_engine, charger_tires
-- count = how many are required to finish a project (loot/box kit size)
Config.Parts = {
    engine = {
        suffix = 'engine',
        label = 'Engine',
        count = 1,
        requires = { 'bodyframe' },
    },
    transmission = {
        suffix = 'transmission',
        label = 'Transmission',
        count = 1,
        requires = { 'engine' },
    },
    suspension = {
        suffix = 'suspension',
        label = 'Suspension',
        count = 1,
        requires = { 'bodyframe' },
    },
    bodyframe = {
        suffix = 'body_frame',
        label = 'Body Frame',
        count = 1,
    },
    tire = {
        suffix = 'tires',
        label = 'Tires',
        count = 4,
        requires = { 'suspension' },
        bones = {
            [0] = { bone = 'wheel_lf', label = 'Front Left Tire' },
            [1] = { bone = 'wheel_rf', label = 'Front Right Tire' },
            [2] = { bone = 'wheel_lr', label = 'Rear Left Tire' },
            [3] = { bone = 'wheel_rr', label = 'Rear Right Tire' },
        },
    },
    door = {
        suffix = 'doors',
        label = 'Doors',
        count = 4,
        requires = { 'bodyframe' },
        bones = {
            [0] = { bone = 'door_dside_f', label = 'Front Left Door' },
            [1] = { bone = 'door_pside_f', label = 'Front Right Door' },
            [2] = { bone = 'door_dside_r', label = 'Rear Left Door' },
            [3] = { bone = 'door_pside_r', label = 'Rear Right Door' },
        },
    },
    window = {
        suffix = 'windows',
        label = 'Windows',
        count = 4,
        requiresIndex = 'door',
        bones = {
            [0] = { bone = 'door_dside_f', label = 'Front Left Window' },
            [1] = { bone = 'door_pside_f', label = 'Front Right Window' },
            [2] = { bone = 'door_dside_r', label = 'Rear Left Window' },
            [3] = { bone = 'door_pside_r', label = 'Rear Right Window' },
        },
    },
}

Config.PartLootTypes = { 'engine', 'transmission', 'suspension', 'bodyframe', 'tire', 'door', 'window' }

Config.DoorBones = {
    [0] = 'door_dside_f',
    [1] = 'door_pside_f',
    [2] = 'door_dside_r',
    [3] = 'door_pside_r',
    [4] = 'bonnet',
    [5] = 'boot',
}

Config.WheelBones = {
    [0] = 'wheel_lf',
    [1] = 'wheel_rf',
    [2] = 'wheel_lr',
    [3] = 'wheel_rr',
}

function NormalizeProjectModel(model)
    return tostring(model or ''):lower():gsub('%s+', '')
end

function GetProjectVehicleData(model)
    return Config.Vehicles[NormalizeProjectModel(model)]
end

function GetProjectVehicleLabel(model)
    local data = GetProjectVehicleData(model)
    if data and data.label then
        return data.label
    end
    model = NormalizeProjectModel(model)
    if model == '' then
        return 'Unknown'
    end
    return model:upper()
end

function GetProjectVehicleShort(model)
    local data = GetProjectVehicleData(model)
    if data and data.short then
        return data.short
    end
    return GetProjectVehicleLabel(model)
end

function GetProjectVehiclePrefix(model)
    local data = GetProjectVehicleData(model)
    return data and data.prefix or nil
end

function IsProjectPartType(partType)
    return partType ~= nil and Config.Parts[partType] ~= nil
end

function GetPartItemName(model, partType)
    local prefix = GetProjectVehiclePrefix(model)
    local part = Config.Parts[partType]
    if not prefix or not part or not part.suffix then
        return nil
    end
    return ('%s_%s'):format(prefix, part.suffix)
end

function GetPartDisplayLabel(model, partType)
    local short = GetProjectVehicleShort(model)
    local part = Config.Parts[partType]
    if not part then
        return short
    end
    return ('%s %s'):format(short, part.label)
end

--- Map unique item (charger_engine) or part type (engine) back to a part type
function GetPartTypeFromItem(itemName)
    itemName = tostring(itemName or ''):lower()
    if itemName == '' then return nil end
    if Config.Parts[itemName] then
        return itemName
    end
    for partType, part in pairs(Config.Parts) do
        local suffix = part.suffix
        if suffix and itemName:sub(-(#suffix + 1)) == ('_' .. suffix) then
            return partType
        end
    end
    return nil
end

function ResolveProjectPartItem(itemName, model)
    itemName = tostring(itemName or '')
    if itemName == '' then
        return itemName, nil
    end
    if Config.Parts[itemName] then
        local unique = GetPartItemName(model, itemName)
        return unique or itemName, itemName
    end
    local partType = GetPartTypeFromItem(itemName)
    return itemName, partType
end

--- Shared helper — used by shop / boxes / chop / install
---@param itemName string
---@param model string|nil
---@return table
function BuildProjectPartMetadata(itemName, model)
    model = NormalizeProjectModel(model or Config.DefaultModel or 'ody18')
    local vehicleLabel = GetProjectVehicleLabel(model)
    local short = GetProjectVehicleShort(model)
    local meta = {
        model = model,
        vehicle = vehicleLabel,
    }

    if itemName == 'vehicle_shell' then
        meta.label = ('%s Shell'):format(vehicleLabel)
        meta.description = ('Wrecked %s chassis — place it and install matching parts.'):format(vehicleLabel)
        return meta
    end

    if itemName == 'car_blueprint' then
        meta.label = Config.PartItemLabels.car_blueprint or 'Project Vehicle Blueprint'
        meta.description = ('Fits %s project cars only.'):format(vehicleLabel)
        return meta
    end

    local partType = GetPartTypeFromItem(itemName)
    if partType then
        meta.label = GetPartDisplayLabel(model, partType)
        meta.description = ('Fits %s project cars only.'):format(vehicleLabel)
        return meta
    end

    local partLabel = Config.PartItemLabels and Config.PartItemLabels[itemName]
    if partLabel then
        meta.label = partLabel
    else
        meta.label = ('%s Part'):format(short)
    end
    meta.description = ('Fits %s project cars only.'):format(vehicleLabel)
    return meta
end

function IsProjectVehicle(model)
    model = NormalizeProjectModel(model)
    return model ~= '' and Config.Vehicles[model] ~= nil
end

--- Cars that can actually spawn (have stream). Used for random part/shop loot.
function IsLootProjectVehicle(model)
    model = NormalizeProjectModel(model)
    local data = Config.Vehicles[model]
    return data ~= nil and data.loot ~= false
end

function GetLootProjectModels()
    local list = {}
    for spawnName, data in pairs(Config.Vehicles) do
        if data and data.loot ~= false then
            list[#list + 1] = spawnName
        end
    end
    table.sort(list)
    return list
end

function PickRandomProjectModel()
    local list = GetLootProjectModels()
    if #list < 1 then
        return Config.DefaultModel or 'ody18'
    end
    return list[math.random(1, #list)]
end

function GetProjectBuildKit(model)
    model = NormalizeProjectModel(model or Config.DefaultModel or 'ody18')
    local kit = {
        { item = 'vehicle_shell', count = 1, metadata = BuildProjectPartMetadata('vehicle_shell', model) },
        { item = Config.BlueprintItem or 'car_blueprint', count = Config.BlueprintAmount or 25, metadata = BuildProjectPartMetadata('car_blueprint', model) },
    }
    for i = 1, #Config.PartLootTypes do
        local partType = Config.PartLootTypes[i]
        local part = Config.Parts[partType]
        local itemName = GetPartItemName(model, partType)
        if part and itemName then
            kit[#kit + 1] = {
                item = itemName,
                count = part.count or 1,
                metadata = BuildProjectPartMetadata(itemName, model),
                partType = partType,
            }
        end
    end
    return kit
end
