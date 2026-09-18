--[[
    Raven - Shared pig hunt (server-side session + networked pigs).
    One player starts the hunt; everyone nearby sees the dome and the same pigs.
    Walking into the dome joins the hunt and gives a knife. Leave = knife gone.
]]

ConfigRaven = {
    Debug = false,

    Ped = {
        model = "a_m_m_farmer_01",
        coords = vec4(-2091.3125, 2640.1421, 2.8954, 20.3600),
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },

    Blip = {
        label = "Raven Pig Farm",
        sprite = 141,
        color = 1,
        scale = 0.85,
        shortRange = true,
    },

    Pig = {
        model = "a_c_pig",
        coords = vec4(-2108.3953, 2663.3638, 2.8277, 32.0394),
        count = 5,
        spawnRadius = 10.0,
        health = 200,
        hitsToKill = 2,
    },

    RequiredWeapon = "WEAPON_KNIFE",
    RewardItem = "raw_meat",
    RewardMin = 1,
    RewardMax = 3,
    ToolUses = 100,

    HuntZoneRadius = 25.0,
    HuntZoneGraceMs = 900,
    HuntZoneMarker = { r = 200, g = 36, b = 36, a = 72 },
    HuntZoneBlip = { color = 1, alpha = 120 },
    JobKnifeLabel = "Raven Hunting Knife",
    HarvestDistance = 2.5,
    HarvestDuration = 4000,
    KnifeHitDistance = 3.25,
    KnifeHitCooldown = 350,
}

local function CanUseRaven(src)
    if type(ConfigServerLocations) ~= "table" or not ConfigServerLocations.CanUseFunction then
        return true
    end
    if IsDuplicityVersion() then
        return ConfigServerLocations.CanUseFunction("grind", src) or ConfigServerLocations.CanUseFunction("raven", src)
    end
    return ConfigServerLocations.CanUseFunction("grind") or ConfigServerLocations.CanUseFunction("raven")
end

local function DebugLog(msg)
    if ConfigRaven.Debug then
        print(("[Raven] %s"):format(msg))
    end
end

local function HuntCenter()
    local pig = ConfigRaven.Pig.coords
    return vector3(pig.x, pig.y, pig.z)
end

local function HuntRadius()
    return tonumber(ConfigRaven.HuntZoneRadius) or 25.0
end

if IsDuplicityVersion() then
    ---------------------------------------------------------------------------
    -- SERVER — shared session, networked pigs
    ---------------------------------------------------------------------------
    local sessionActive = false
    local sessionBucket = 0
    local hunters = {}          -- [src] = { knife, entered }
    local pendingHarvest = {}   -- [src] = { netId, started }
    local pigs = {}             -- [netId] = { entity, netId, hits, dead, harvester }
    local lastHitAt = {}        -- [src] = gameTimer

    local function JobKnifeMeta()
        return {
            ravenJob = true,
            label = ConfigRaven.JobKnifeLabel or "Raven Hunting Knife",
            description = "Temporary hunt knife. Removed when you leave the Raven zone.",
        }
    end

    local function IsInsideHuntZone(src)
        local ped = GetPlayerPed(src)
        if not ped or ped == 0 then return false end
        return #(GetEntityCoords(ped) - HuntCenter()) <= HuntRadius()
    end

    local function IsNearStartNpc(src)
        local ped = GetPlayerPed(src)
        if not ped or ped == 0 then return false end
        local farmer = ConfigRaven.Ped.coords
        return #(GetEntityCoords(ped) - vector3(farmer.x, farmer.y, farmer.z)) <= 12.0
    end

    local function IsHunting(src)
        return hunters[src] ~= nil
    end

    local function CountHunters()
        local n = 0
        for _ in pairs(hunters) do
            n = n + 1
        end
        return n
    end

    local function PigNetIds()
        local list = {}
        for netId, pig in pairs(pigs) do
            if pig.entity and DoesEntityExist(pig.entity) then
                list[#list + 1] = netId
            end
        end
        return list
    end

    local function PublishSession()
        GlobalState:set("ravenHunt", {
            active = sessionActive,
            radius = HuntRadius(),
            x = ConfigRaven.Pig.coords.x,
            y = ConfigRaven.Pig.coords.y,
            z = ConfigRaven.Pig.coords.z,
            pigs = PigNetIds(),
        }, true)
    end

    local function SyncPigs(target)
        local payload = PigNetIds()
        if target then
            TriggerClientEvent("cfx-keydi-raven:syncPigs", target, payload)
        else
            TriggerClientEvent("cfx-keydi-raven:syncPigs", -1, payload)
        end
        PublishSession()
    end

    local function HasKnife(src)
        local count = exports.ox_inventory:Search(src, "count", ConfigRaven.RequiredWeapon) or 0
        if type(count) == "table" then
            count = count[ConfigRaven.RequiredWeapon] or 0
        end
        return (tonumber(count) or 0) > 0
    end

    local function HasJobKnife(src)
        local slots = exports.ox_inventory:Search(src, "slots", ConfigRaven.RequiredWeapon)
        if type(slots) ~= "table" then return false end
        for _, entry in pairs(slots) do
            if type(entry) == "table" and entry.metadata and entry.metadata.ravenJob then
                return true, entry
            end
        end
        return false
    end

    local function StripJobKnife(src)
        local slots = exports.ox_inventory:Search(src, "slots", ConfigRaven.RequiredWeapon)
        if type(slots) == "table" then
            for _, entry in pairs(slots) do
                if type(entry) == "table" and entry.slot and entry.metadata and entry.metadata.ravenJob then
                    pcall(function()
                        exports.ox_inventory:RemoveItem(src, ConfigRaven.RequiredWeapon, entry.count or 1, nil, entry.slot)
                    end)
                end
            end
        end
        TriggerClientEvent("cfx-keydi-raven:disarmKnife", src)
        if hunters[src] then
            hunters[src].knife = false
        end
    end

    local function GiveJobKnife(src)
        local hasJob, entry = HasJobKnife(src)
        if hasJob then
            if hunters[src] then hunters[src].knife = true end
            TriggerClientEvent("cfx-keydi-raven:equipKnife", src, entry and entry.slot)
            return true
        end
        local added = exports.ox_inventory:AddItem(src, ConfigRaven.RequiredWeapon, 1, JobKnifeMeta())
        if added then
            if hunters[src] then hunters[src].knife = true end
            local _, given = HasJobKnife(src)
            TriggerClientEvent("cfx-keydi-raven:equipKnife", src, given and given.slot)
            return true
        end
        return false
    end

    local function RandomPigCoords()
        local center = HuntCenter()
        local radius = ConfigRaven.Pig.spawnRadius or 10.0
        local angle = math.random() * math.pi * 2
        local dist = math.random() * radius
        return center.x + math.cos(angle) * dist, center.y + math.sin(angle) * dist, center.z, math.random(0, 359) + 0.0
    end

    local function DeletePig(netId)
        local pig = pigs[netId]
        if not pig then return end
        if pig.entity and DoesEntityExist(pig.entity) then
            DeleteEntity(pig.entity)
        end
        pigs[netId] = nil
    end

    local function SpawnPig()
        local model = joaat(ConfigRaven.Pig.model)
        local x, y, z, heading = RandomPigCoords()
        local ped = CreatePed(28, model, x, y, z, heading, true, true)
        if not ped or ped == 0 then
            ped = CreatePed(0, model, x, y, z, heading, true, true)
        end
        if not ped or ped == 0 then
            DebugLog("failed to spawn networked pig")
            return nil
        end

        -- Ped behavior natives are client-only. Keep the entity on the server, then
        -- let clients apply wander / flee / mission-entity after they resolve the netId.
        pcall(SetEntityOrphanMode, ped, 2)
        pcall(SetEntityRoutingBucket, ped, sessionBucket or 0)
        pcall(SetEntityInvincible, ped, false)
        local health = math.max(200, tonumber(ConfigRaven.Pig.health) or 200)
        pcall(SetEntityHealth, ped, health)

        local netId = NetworkGetNetworkIdFromEntity(ped)
        if not netId or netId == 0 then
            DeleteEntity(ped)
            return nil
        end

        pigs[netId] = {
            entity = ped,
            netId = netId,
            hits = 0,
            dead = false,
            harvester = nil,
        }
        TriggerClientEvent("cfx-keydi-raven:setupPig", -1, netId)
        return netId
    end

    local function EntityIsDead(entity)
        if not entity or entity == 0 then return true end
        local ok, dead = pcall(IsEntityDead, entity)
        return ok and dead == true
    end

    local function CountLivingPigs()
        local n = 0
        for _, pig in pairs(pigs) do
            if pig.entity and DoesEntityExist(pig.entity) and not pig.dead and not EntityIsDead(pig.entity) then
                n = n + 1
            end
        end
        return n
    end

    local function EnsurePigCount()
        local needed = (ConfigRaven.Pig.count or 5) - CountLivingPigs()
        local spawned = false
        for _ = 1, math.max(0, needed) do
            if SpawnPig() then
                spawned = true
            end
        end
        if spawned then
            SyncPigs()
        end
    end

    local function ClearAllPigs()
        for netId in pairs(pigs) do
            DeletePig(netId)
        end
        pigs = {}
        SyncPigs()
    end

    local function EndSession()
        sessionActive = false
        for src in pairs(hunters) do
            StripJobKnife(src)
            pendingHarvest[src] = nil
            TriggerClientEvent("cfx-keydi-raven:forceStop", src, "Raven hunt ended.")
        end
        hunters = {}
        pendingHarvest = {}
        ClearAllPigs()
        PublishSession()
    end

    local function LeaveHunter(src, reason, silent)
        if not IsHunting(src) then return end
        if pendingHarvest[src] then
            local pig = pigs[pendingHarvest[src].netId]
            if pig and pig.harvester == src then
                pig.harvester = nil
            end
        end
        StripJobKnife(src)
        hunters[src] = nil
        pendingHarvest[src] = nil
        if not silent then
            TriggerClientEvent("cfx-keydi-raven:forceStop", src, reason)
        else
            TriggerClientEvent("cfx-keydi-raven:forceStop", src, nil)
        end
        if CountHunters() < 1 then
            EndSession()
        end
    end

    local function JoinHunter(src)
        if not sessionActive then return false, "inactive" end
        if not CanUseRaven(src) then return false, "wrong_server" end
        if hunters[src] then return true end
        hunters[src] = { knife = false, entered = IsInsideHuntZone(src) }
        pendingHarvest[src] = nil
        TriggerClientEvent("cfx-keydi-raven:joined", src)
        SyncPigs(src)
        return true
    end

    local function StartSession(src)
        sessionActive = true
        sessionBucket = GetPlayerRoutingBucket(src) or 0
        hunters[src] = { knife = false, entered = IsInsideHuntZone(src) }
        pendingHarvest[src] = nil
        EnsurePigCount()
        PublishSession()
        TriggerClientEvent("cfx-keydi-raven:joined", src)
        return true
    end

    lib.callback.register("cfx-keydi-raven:startHunt", function(src)
        if type(src) ~= "number" or src < 1 then return false, "invalid" end
        if not CanUseRaven(src) then return false, "wrong_server" end
        if not IsNearStartNpc(src) and not IsInsideHuntZone(src) then return false, "distance" end

        if sessionActive then
            local ok, reason = JoinHunter(src)
            if not ok then return false, reason end
            if IsInsideHuntZone(src) and not GiveJobKnife(src) then
                return false, "inventory"
            end
            return true, "joined"
        end

        StartSession(src)
        if IsInsideHuntZone(src) and not GiveJobKnife(src) then
            LeaveHunter(src, nil, true)
            return false, "inventory"
        end
        return true, "started"
    end)

    RegisterNetEvent("cfx-keydi-raven:enterZone", function()
        local src = source
        if type(src) ~= "number" or src < 1 then return end
        if not sessionActive then return end
        if not CanUseRaven(src) then return end
        if not IsInsideHuntZone(src) then return end

        JoinHunter(src)
        hunters[src].entered = true
        if not GiveJobKnife(src) then
            TriggerClientEvent("cfx-keydi-raven:notify", src, "Make space in your inventory for the hunt knife.", "error")
        end
    end)

    RegisterNetEvent("cfx-keydi-raven:stopHunt", function()
        local src = source
        LeaveHunter(src, nil, true)
    end)

    RegisterNetEvent("cfx-keydi-raven:knifeHit", function(netId)
        local src = source
        netId = tonumber(netId)
        if type(src) ~= "number" or src < 1 or not netId then return end
        if not sessionActive or not IsHunting(src) or not IsInsideHuntZone(src) then return end
        if not HasKnife(src) then return end

        local now = GetGameTimer()
        if lastHitAt[src] and (now - lastHitAt[src]) < (ConfigRaven.KnifeHitCooldown or 350) then
            return
        end
        lastHitAt[src] = now

        local pig = pigs[netId]
        if not pig or pig.dead or not pig.entity or not DoesEntityExist(pig.entity) then return end

        local ped = GetPlayerPed(src)
        if not ped or ped == 0 then return end
        if #(GetEntityCoords(ped) - GetEntityCoords(pig.entity)) > (ConfigRaven.KnifeHitDistance or 3.25) then
            return
        end

        pig.hits = (pig.hits or 0) + 1
        local needed = math.max(1, tonumber(ConfigRaven.Pig.hitsToKill) or 2)
        if pig.hits >= needed then
            pig.dead = true
            pcall(SetEntityHealth, pig.entity, 0)
            TriggerClientEvent("cfx-keydi-raven:pigDead", -1, netId)
        else
            local health = math.max(200, tonumber(ConfigRaven.Pig.health) or 200)
            pcall(SetEntityHealth, pig.entity, health)
        end
    end)

    lib.callback.register("cfx-keydi-raven:beginHarvest", function(src, netId)
        netId = tonumber(netId)
        if type(src) ~= "number" or src < 1 or not netId then return false, "invalid" end
        if not IsHunting(src) or not IsInsideHuntZone(src) or not HasKnife(src) then
            return false, "denied"
        end

        local pig = pigs[netId]
        if not pig or not pig.entity or not DoesEntityExist(pig.entity) then
            return false, "gone"
        end
        if not pig.dead and not EntityIsDead(pig.entity) then
            return false, "alive"
        end
        if pig.harvester and pig.harvester ~= src then
            return false, "busy"
        end

        local ped = GetPlayerPed(src)
        if #(GetEntityCoords(ped) - GetEntityCoords(pig.entity)) > (ConfigRaven.HarvestDistance + 1.5) then
            return false, "distance"
        end

        pig.harvester = src
        pendingHarvest[src] = { netId = netId, started = GetGameTimer() }
        return true
    end)

    RegisterNetEvent("cfx-keydi-raven:cancelHarvest", function(netId)
        local src = source
        netId = tonumber(netId)
        local pending = pendingHarvest[src]
        if pending then
            local pig = pigs[pending.netId]
            if pig and pig.harvester == src then
                pig.harvester = nil
            end
        end
        pendingHarvest[src] = nil
        if netId and pigs[netId] and pigs[netId].harvester == src then
            pigs[netId].harvester = nil
        end
    end)

    RegisterNetEvent("cfx-keydi-raven:harvest", function(netId)
        local src = source
        netId = tonumber(netId)
        if type(src) ~= "number" or src < 1 or not netId then return end

        local pending = pendingHarvest[src]
        if not pending or pending.netId ~= netId then
            if KeydiElectron and KeydiElectron.Flag then
                KeydiElectron.Flag(src, "Raven harvest exploit (no begin)", "cfx-keydi-raven")
            end
            return
        end

        local duration = ConfigRaven.HarvestDuration or 4000
        if (GetGameTimer() - pending.started) < (duration - 400) then
            if KeydiElectron and KeydiElectron.Flag then
                KeydiElectron.Flag(src, "Raven harvest exploit (skipped wait)", "cfx-keydi-raven")
            end
            return
        end
        pendingHarvest[src] = nil

        if not IsHunting(src) or not IsInsideHuntZone(src) or not HasKnife(src) then
            return
        end

        local pig = pigs[netId]
        if not pig or pig.harvester ~= src then
            TriggerClientEvent("cfx-keydi-raven:notify", src, "Someone else already claimed that pig.", "error")
            return
        end

        local amount = math.random(ConfigRaven.RewardMin, ConfigRaven.RewardMax)
        pcall(function()
            if exports["kodebykarl-ui"] and exports["kodebykarl-ui"].GetVipGrindBonus then
                amount = amount + (exports["kodebykarl-ui"]:GetVipGrindBonus(src) or 0)
            end
        end)

        local canCarry = exports.ox_inventory:CanCarryAmount(src, ConfigRaven.RewardItem) or 0
        if canCarry < 1 then
            pig.harvester = nil
            TriggerClientEvent("cfx-keydi-raven:notify", src, "You cannot carry any more raw meat.", "error")
            return
        end
        if amount > canCarry then
            amount = canCarry
        end

        local added = exports.ox_inventory:AddItem(src, ConfigRaven.RewardItem, amount)
        if not added then
            pig.harvester = nil
            TriggerClientEvent("cfx-keydi-raven:notify", src, "Failed to add raw meat.", "error")
            return
        end

        DeletePig(netId)
        EnsurePigCount()
        SyncPigs()
        TriggerClientEvent("cfx-keydi-raven:notify", src, ("You harvested %dx Raw Meat"):format(amount), "success")
        TriggerClientEvent("cfx-keydi-raven:harvested", src, netId)
    end)

    CreateThread(function()
        while true do
            Wait(1000)
            if sessionActive then
                for src in pairs(hunters) do
                    if not GetPlayerName(src) then
                        LeaveHunter(src, nil, true)
                    elseif not IsInsideHuntZone(src) and not IsNearStartNpc(src) then
                        LeaveHunter(src, "You left the Raven hunt zone. The knife was taken.", false)
                    elseif IsInsideHuntZone(src) then
                        hunters[src].entered = true
                        if not hunters[src].knife then
                            GiveJobKnife(src)
                        end
                    end
                end

                for netId, pig in pairs(pigs) do
                    if not pig.entity or not DoesEntityExist(pig.entity) then
                        pigs[netId] = nil
                    elseif not pig.dead and EntityIsDead(pig.entity) then
                        pig.dead = true
                        TriggerClientEvent("cfx-keydi-raven:pigDead", -1, netId)
                    end
                end
                EnsurePigCount()
            end
        end
    end)

    AddEventHandler("playerDropped", function()
        LeaveHunter(source, nil, true)
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end
        for src in pairs(hunters) do
            StripJobKnife(src)
        end
        ClearAllPigs()
        sessionActive = false
        PublishSession()
    end)

    CreateThread(function()
        Wait(500)
        PublishSession()
    end)
else
    ---------------------------------------------------------------------------
    -- CLIENT
    ---------------------------------------------------------------------------
    local ESX = exports["es_extended"]:getSharedObject()

    local npcPed = nil
    local farmBlip = nil
    local farmerTargetZone = nil
    local hunting = false
    local harvesting = false
    local insideHuntZone = false
    local huntSphere = nil
    local huntRadiusBlip = nil
    local pigs = {} -- [netId] = { entity, dead, targeted }
    local LeaveHunt

    local function Notify(msg, nType)
        ESX.ShowNotification(msg, nType or "info")
    end

    local function HideHuntText()
        pcall(lib.hideTextUI)
    end

    local function ShowHuntText()
        lib.showTextUI("RAVEN HUNT  •  Shared pigs  •  Knife in the dome", {
            position = "top-center",
            icon = "fa-solid fa-bacon",
            style = {
                borderRadius = "6px",
                backgroundColor = "rgba(13, 13, 18, 0.9)",
                color = "#ff6b6b",
                border = "1px solid rgba(255, 58, 58, 0.4)",
                padding = "6px 12px",
                fontSize = "12px",
                fontWeight = "600",
            },
        })
    end

    local function SessionActive()
        local data = GlobalState.ravenHunt
        return data and data.active == true
    end

    local function DestroyHuntZone()
        insideHuntZone = false
        HideHuntText()
        if huntSphere then
            huntSphere:remove()
            huntSphere = nil
        end
        if huntRadiusBlip and DoesBlipExist(huntRadiusBlip) then
            RemoveBlip(huntRadiusBlip)
        end
        huntRadiusBlip = nil
    end

    local function CreateHuntZone()
        if huntSphere then return end
        local center = HuntCenter()
        local radius = HuntRadius()

        huntRadiusBlip = AddBlipForRadius(center.x, center.y, center.z, radius)
        local blipCfg = ConfigRaven.HuntZoneBlip or {}
        SetBlipColour(huntRadiusBlip, blipCfg.color or 1)
        SetBlipAlpha(huntRadiusBlip, blipCfg.alpha or 120)
        SetBlipAsShortRange(huntRadiusBlip, false)

        huntSphere = lib.zones.sphere({
            coords = center,
            radius = radius,
            debug = ConfigRaven.Debug,
            onEnter = function()
                insideHuntZone = true
                ShowHuntText()
                TriggerServerEvent("cfx-keydi-raven:enterZone")
            end,
            onExit = function()
                insideHuntZone = false
                HideHuntText()
                if not hunting then return end
                local grace = tonumber(ConfigRaven.HuntZoneGraceMs) or 900
                CreateThread(function()
                    Wait(grace)
                    if hunting and not insideHuntZone then
                        LeaveHunt(true)
                        Notify("You left the Raven hunt zone. The knife was taken.", "error")
                    end
                end)
            end,
        })

        if #(GetEntityCoords(PlayerPedId()) - center) <= radius then
            insideHuntZone = true
            ShowHuntText()
            TriggerServerEvent("cfx-keydi-raven:enterZone")
        end
    end

    local function PlayerHasKnife()
        local count = 0
        pcall(function()
            count = exports.ox_inventory:Search("count", ConfigRaven.RequiredWeapon) or 0
        end)
        if type(count) == "table" then
            count = count[ConfigRaven.RequiredWeapon] or 0
        end
        return (tonumber(count) or 0) > 0
    end

    RegisterNetEvent("cfx-keydi-raven:notify", function(msg, nType)
        Notify(msg, nType)
    end)

    local function LoadModel(model)
        local hash = type(model) == "number" and model or joaat(model)
        if not IsModelInCdimage(hash) then return nil end
        RequestModel(hash)
        local timeout = GetGameTimer() + 5000
        while not HasModelLoaded(hash) and GetGameTimer() < timeout do
            Wait(10)
        end
        if not HasModelLoaded(hash) then return nil end
        return hash
    end

    local function ResolvePigEntity(netId)
        if not netId then return 0 end
        if not NetworkDoesNetworkIdExist(netId) then return 0 end
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
        return 0
    end

    local function ClearPigTarget(pig)
        if pig and pig.targeted and pig.entity and DoesEntityExist(pig.entity) then
            pcall(function()
                exports.ox_target:removeLocalEntity(pig.entity)
            end)
        end
        if pig then pig.targeted = false end
    end

    local function ClearLocalPigs()
        for _, pig in pairs(pigs) do
            ClearPigTarget(pig)
        end
        pigs = {}
    end

    function LeaveHunt(silent)
        if not hunting then return end
        hunting = false
        harvesting = false
        HideHuntText()
        TriggerServerEvent("cfx-keydi-raven:stopHunt")
        if not silent then
            Notify("You left the Raven hunt.", "info")
        end
    end

    local function StartHarvest(netId)
        if harvesting or not hunting or not insideHuntZone then return end
        local pig = pigs[netId]
        local entity = pig and pig.entity or ResolvePigEntity(netId)
        if not entity or entity == 0 or not DoesEntityExist(entity) then
            Notify("That pig is gone.", "error")
            return
        end
        if not IsEntityDead(entity) then
            Notify("The pig is still alive.", "error")
            return
        end
        if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity)) > ConfigRaven.HarvestDistance + 1.0 then
            Notify("Move closer to the pig.", "error")
            return
        end
        if not PlayerHasKnife() then
            Notify("You need the hunt knife to harvest meat.", "error")
            return
        end

        harvesting = true
        local began, reason = lib.callback.await("cfx-keydi-raven:beginHarvest", false, netId)
        if not began then
            harvesting = false
            if reason == "busy" then
                Notify("Someone else is already harvesting that pig.", "error")
            else
                Notify("You cannot harvest right now.", "error")
            end
            return
        end

        local playerPed = PlayerPedId()
        GiveWeaponToPed(playerPed, joaat(ConfigRaven.RequiredWeapon), 0, false, true)
        SetCurrentPedWeapon(playerPed, joaat(ConfigRaven.RequiredWeapon), true)

        local success = lib.progressBar({
            duration = ConfigRaven.HarvestDuration,
            label = "Harvesting raw meat…",
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = "amb@medic@standing@kneel@base", clip = "base" },
        })

        if not success or not hunting then
            harvesting = false
            ClearPedTasks(playerPed)
            TriggerServerEvent("cfx-keydi-raven:cancelHarvest", netId)
            return
        end

        TriggerServerEvent("cfx-keydi-raven:harvest", netId)
        harvesting = false
    end

    local function AddHarvestTarget(netId)
        local pig = pigs[netId]
        if not pig or pig.targeted then return end
        local entity = pig.entity
        if not entity or entity == 0 or not DoesEntityExist(entity) then return end

        pig.targeted = true
        exports.ox_target:addLocalEntity(entity, {
            {
                name = ("raven_harvest_%s"):format(netId),
                icon = "fa-solid fa-drumstick-bite",
                label = "Harvest Raw Meat",
                distance = ConfigRaven.HarvestDistance,
                canInteract = function()
                    return hunting and insideHuntZone and not harvesting
                        and DoesEntityExist(entity) and IsEntityDead(entity)
                end,
                onSelect = function()
                    StartHarvest(netId)
                end,
            },
        })
    end

    local function SyncPigList(netIds)
        local keep = {}
        if type(netIds) == "table" then
            for i = 1, #netIds do
                keep[netIds[i]] = true
            end
        end

        for netId, pig in pairs(pigs) do
            if not keep[netId] then
                ClearPigTarget(pig)
                pigs[netId] = nil
            end
        end

        for netId in pairs(keep) do
            if not pigs[netId] then
                pigs[netId] = { entity = 0, dead = false, targeted = false, hitsSent = 0 }
            end
        end
    end

    RegisterNetEvent("cfx-keydi-raven:syncPigs", function(netIds)
        SyncPigList(netIds)
    end)

    RegisterNetEvent("cfx-keydi-raven:setupPig", function(netId)
        netId = tonumber(netId)
        if not netId then return end
        CreateThread(function()
            local timeout = GetGameTimer() + 5000
            local entity = 0
            while GetGameTimer() < timeout do
                entity = ResolvePigEntity(netId)
                if entity ~= 0 then break end
                Wait(50)
            end
            if entity == 0 or not DoesEntityExist(entity) then return end

            SetEntityAsMissionEntity(entity, true, true)
            SetPedFleeAttributes(entity, 0, false)
            SetBlockingOfNonTemporaryEvents(entity, true)
            pcall(SetPedSuffersCriticalHits, entity, false)
            SetEntityInvincible(entity, false)
            local health = math.max(200, tonumber(ConfigRaven.Pig.health) or 200)
            pcall(SetPedMaxHealth, entity, health)
            if not IsEntityDead(entity) then
                SetEntityHealth(entity, health)
                SetPedArmour(entity, 0)
                local center = HuntCenter()
                TaskWanderInArea(entity, center.x, center.y, center.z, ConfigRaven.Pig.spawnRadius or 10.0, 2.0, 3.0)
            end
        end)
    end)

    RegisterNetEvent("cfx-keydi-raven:pigDead", function(netId)
        netId = tonumber(netId)
        if not netId then return end
        pigs[netId] = pigs[netId] or { entity = 0, dead = true, targeted = false }
        pigs[netId].dead = true
    end)

    RegisterNetEvent("cfx-keydi-raven:harvested", function(netId)
        netId = tonumber(netId)
        if netId and pigs[netId] then
            ClearPigTarget(pigs[netId])
            pigs[netId] = nil
        end
    end)

    RegisterNetEvent("cfx-keydi-raven:joined", function()
        hunting = true
        CreateHuntZone()
        Notify("You joined the Raven hunt. Kill the shared pigs — first to harvest keeps the meat.", "success")
    end)

    RegisterNetEvent("cfx-keydi-raven:equipKnife", function(slot)
        CreateThread(function()
            Wait(250)
            if type(slot) == "number" then
                local ok = pcall(function()
                    exports.ox_inventory:useSlot(slot)
                end)
                if ok then return end
            end
            local ped = PlayerPedId()
            local hash = joaat(ConfigRaven.RequiredWeapon)
            GiveWeaponToPed(ped, hash, 0, false, true)
            SetCurrentPedWeapon(ped, hash, true)
        end)
    end)

    RegisterNetEvent("cfx-keydi-raven:disarmKnife", function()
        local ped = PlayerPedId()
        local hash = joaat(ConfigRaven.RequiredWeapon)
        if GetSelectedPedWeapon(ped) == hash then
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        end
        RemoveWeaponFromPed(ped, hash)
    end)

    RegisterNetEvent("cfx-keydi-raven:forceStop", function(reason)
        hunting = false
        harvesting = false
        HideHuntText()
        if reason then
            Notify(reason, "error")
        end
        if not SessionActive() then
            DestroyHuntZone()
            ClearLocalPigs()
        end
    end)

    local function StartHunting()
        if hunting then
            Notify("You are already in the Raven hunt.", "info")
            return
        end
        if not CanUseRaven() then
            Notify(
                (ConfigServerLocations and ConfigServerLocations.WrongServerMessage)
                    and ConfigServerLocations.WrongServerMessage("grind")
                    or "Pig hunting is only available on Region 1 · Main.",
                "error"
            )
            return
        end

        local playerCoords = GetEntityCoords(PlayerPedId())
        local npcPos = vector3(ConfigRaven.Ped.coords.x, ConfigRaven.Ped.coords.y, ConfigRaven.Ped.coords.z)
        if #(playerCoords - npcPos) > 15.0 and #(playerCoords - HuntCenter()) > HuntRadius() then
            Notify("Stay near the pig farm to start Raven.", "error")
            return
        end

        local started, reason = lib.callback.await("cfx-keydi-raven:startHunt", false)
        if not started then
            if reason == "wrong_server" then
                Notify(
                    (ConfigServerLocations and ConfigServerLocations.WrongServerMessage)
                        and ConfigServerLocations.WrongServerMessage("grind")
                        or "Pig hunting is only available on Region 1 · Main.",
                    "error"
                )
            elseif reason == "inventory" then
                Notify("Make space in your inventory for the hunt knife.", "error")
            else
                Notify("Stay near the pig farm to start Raven.", "error")
            end
        end
    end

    -- Visible 3D dome for everyone while the shared hunt is active
    CreateThread(function()
        while true do
            if SessionActive() then
                CreateHuntZone()
                local center = HuntCenter()
                local radius = HuntRadius()
                local color = ConfigRaven.HuntZoneMarker or { r = 200, g = 36, b = 36, a = 72 }
                DrawMarker(
                    28,
                    center.x, center.y, center.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    radius, radius, radius,
                    color.r, color.g, color.b, color.a,
                    false, false, 2, false, nil, nil, false
                )
                Wait(0)
            else
                if not hunting then
                    DestroyHuntZone()
                    ClearLocalPigs()
                end
                Wait(400)
            end
        end
    end)

    AddStateBagChangeHandler("ravenHunt", "global", function(_, _, value)
        if type(value) == "table" and value.active and type(value.pigs) == "table" then
            SyncPigList(value.pigs)
            CreateHuntZone()
        elseif not (value and value.active) then
            if not hunting then
                DestroyHuntZone()
                ClearLocalPigs()
            end
        end
    end)

    -- Resolve networked pigs + report knife hits to the server
    CreateThread(function()
        local knife = joaat(ConfigRaven.RequiredWeapon)
        while true do
            if SessionActive() then
                for netId, pig in pairs(pigs) do
                    if not pig.entity or pig.entity == 0 or not DoesEntityExist(pig.entity) then
                        pig.entity = ResolvePigEntity(netId)
                        pig.targeted = false
                    end

                    local entity = pig.entity
                    if entity and entity ~= 0 and DoesEntityExist(entity) then
                        if IsEntityDead(entity) then
                            pig.dead = true
                            if hunting and not pig.targeted then
                                AddHarvestTarget(netId)
                            end
                        elseif hunting and insideHuntZone and HasEntityBeenDamagedByWeapon(entity, knife, 0) then
                            ClearEntityLastWeaponDamage(entity)
                            ClearEntityLastDamageEntity(entity)
                            TriggerServerEvent("cfx-keydi-raven:knifeHit", netId)
                        end
                    end
                end
                Wait(50)
            else
                Wait(400)
            end
        end
    end)

    local function GetFarmerCoords()
        local c = ConfigRaven.Ped.coords
        return vector3(c.x, c.y, c.z)
    end

    local function RegisterFarmerTarget()
        if farmerTargetZone then return end
        if GetResourceState("ox_target") ~= "started" then return end

        local c = ConfigRaven.Ped.coords
        farmerTargetZone = exports.ox_target:addSphereZone({
            coords = vec3(c.x, c.y, c.z + 0.5),
            radius = 2.2,
            debug = ConfigRaven.Debug,
            options = {
                {
                    name = "raven_start_hunt",
                    icon = "fa-solid fa-bacon",
                    label = "Start Raven",
                    distance = 2.5,
                    canInteract = function()
                        return CanUseRaven() and not hunting
                    end,
                    onSelect = function()
                        StartHunting()
                    end,
                },
                {
                    name = "raven_stop_hunt",
                    icon = "fa-solid fa-ban",
                    label = "Leave Raven",
                    distance = 2.5,
                    canInteract = function()
                        return hunting
                    end,
                    onSelect = function()
                        LeaveHunt()
                    end,
                },
            },
        })
    end

    local function SpawnFarmer()
        if npcPed and DoesEntityExist(npcPed) then return end
        local pedCfg = ConfigRaven.Ped
        local hash = LoadModel(pedCfg.model)
        if not hash then return end

        local c = pedCfg.coords
        RequestCollisionAtCoord(c.x, c.y, c.z)
        npcPed = CreatePed(0, hash, c.x, c.y, c.z, c.w, false, true)
        if not npcPed or npcPed == 0 then
            SetModelAsNoLongerNeeded(hash)
            npcPed = nil
            return
        end

        SetEntityAsMissionEntity(npcPed, true, true)
        SetPedFleeAttributes(npcPed, 0, false)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
        SetEntityInvincible(npcPed, true)
        SetPedCanBeTargetted(npcPed, true)
        SetEntityCoordsNoOffset(npcPed, c.x, c.y, c.z, false, false, false)
        SetEntityHeading(npcPed, c.w)
        FreezeEntityPosition(npcPed, true)
        if pedCfg.scenario then
            TaskStartScenarioInPlace(npcPed, pedCfg.scenario, 0, true)
        end
        SetModelAsNoLongerNeeded(hash)
    end

    local function DeleteFarmer()
        if npcPed and DoesEntityExist(npcPed) then
            DeleteEntity(npcPed)
        end
        npcPed = nil
    end

    CreateThread(function()
        Wait(1000)
        while GetResourceState("ox_target") ~= "started" do
            Wait(200)
        end

        RegisterFarmerTarget()

        local pedCfg = ConfigRaven.Ped
        local blipCfg = ConfigRaven.Blip
        farmBlip = AddBlipForCoord(pedCfg.coords.x, pedCfg.coords.y, pedCfg.coords.z)
        SetBlipSprite(farmBlip, blipCfg.sprite or 141)
        SetBlipDisplay(farmBlip, 3)
        SetBlipScale(farmBlip, blipCfg.scale or 0.85)
        SetBlipColour(farmBlip, blipCfg.color or 1)
        SetBlipAsShortRange(farmBlip, blipCfg.shortRange ~= false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipCfg.label or "Raven Pig Farm")
        EndTextCommandSetBlipName(farmBlip)
        if not CanUseRaven() then
            SetBlipDisplay(farmBlip, 0)
        end

        local hunt = GlobalState.ravenHunt
        if hunt and hunt.active and type(hunt.pigs) == "table" then
            SyncPigList(hunt.pigs)
            CreateHuntZone()
        end

        while true do
            local dist = #(GetEntityCoords(PlayerPedId()) - GetFarmerCoords())
            if CanUseRaven() and dist < 80.0 then
                SpawnFarmer()
            elseif dist > 120.0 or not CanUseRaven() then
                DeleteFarmer()
            end
            Wait(2000)
        end
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end
        if hunting then
            LeaveHunt(true)
        end
        DestroyHuntZone()
        ClearLocalPigs()
        if farmerTargetZone and GetResourceState("ox_target") == "started" then
            pcall(function()
                exports.ox_target:removeZone(farmerTargetZone)
            end)
        end
        DeleteFarmer()
        if farmBlip then
            RemoveBlip(farmBlip)
        end
    end)

    AddEventHandler("cfx-keydi-serverlocations:changed", function(location)
        local enabled = ConfigServerLocations.LocationAllows
            and ConfigServerLocations.LocationAllows(location, "raven")
            or CanUseRaven()
        if farmBlip then
            SetBlipDisplay(farmBlip, enabled and 3 or 0)
            SetBlipAsShortRange(farmBlip, true)
        end
        if not enabled then
            if hunting then
                LeaveHunt(true)
            end
            DeleteFarmer()
        end
    end)
end
