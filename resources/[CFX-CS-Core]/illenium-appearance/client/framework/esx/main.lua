if not Framework.ESX() then return end

local ESX = exports["es_extended"]:getSharedObject()
Framework.PlayerData = nil

RegisterNetEvent("esx:playerLoaded", function(xPlayer)
    Framework.PlayerData = xPlayer
    client.job = Framework.PlayerData.job
    client.gang = Framework.PlayerData.gang
    client.citizenid = Framework.PlayerData.identifier
    InitAppearance()
end)

RegisterNetEvent("esx:onPlayerLogout", function()
    Framework.PlayerData = nil
end)

RegisterNetEvent("esx:setJob", function(job)
	Framework.PlayerData.job = job
    client.job = Framework.PlayerData.job
    client.gang = Framework.PlayerData.job
end)

local function getRankInputValues(rankList)
    local rankValues = {}
    for _, v in pairs(rankList) do
        rankValues[#rankValues + 1] = {
            label = v.label,
            value = v.grade
        }
    end
    return rankValues
end

function Framework.GetPlayerGender()
    Framework.PlayerData = ESX.GetPlayerData()
    if Framework.PlayerData.sex == "f" then
        return "Female"
    end
    return "Male"
end

function Framework.UpdatePlayerData()
    local data = ESX.GetPlayerData()
    if data.job then
        Framework.PlayerData = data
        client.job = Framework.PlayerData.job
        client.gang = Framework.PlayerData.job
    end
    client.citizenid = Framework.PlayerData.identifier
end

function Framework.HasTracker()
    return false
end

function Framework.CheckPlayerMeta()
    Framework.PlayerData = ESX.GetPlayerData()
    return Framework.PlayerData.dead or IsPedCuffed(Framework.PlayerData.ped)
end

function Framework.IsPlayerAllowed(citizenid)
    return citizenid == Framework.PlayerData.identifier
end

function Framework.GetRankInputValues(type)
    local jobGrades = lib.callback.await("illenium-appearance:server:esx:getGradesForJob", false, client[type].name)
    return getRankInputValues(jobGrades)
end

function Framework.GetJobGrade()
    return client.job.grade
end

function Framework.GetGangGrade()
    return client.gang.grade
end

function Framework.CachePed()
    ESX.SetPlayerData("ped", cache.ped)
end

function Framework.RestorePlayerArmour()
    return nil
end

function nearbyWardrobe(point)
    if ESX.HasGroup(point.access) then
        DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 0, 255, 0, 255, false, true, 2, false, nil, nil, false)
        if point.interact < point.currentDistance then
            if point.isTextUI then
                point.isTextUI = false
                lib.hideTextUI()
            end
            return
        end
        if not point.isTextUI then
            point.isTextUI = true
            local prompt = ('[E] Wardrobe')
            lib.showTextUI(prompt, Config.TextUIOptions)
        end
        if IsControlJustPressed(0, 38) then
            if not exports['es_extended']:Limit('limit', {name = 'illenium-appearance-wardrobe', seconds = 5}) then
                TriggerEvent('illenium-appearance:client:openOutfitMenu')
            end
            exports['es_extended']:Limit('start', {ms = 5000, name = 'illenium-appearance-wardrobe'})
        end
    end
end

CreateThread(function()
    for i = 1, #Config.Wardrobe do
        local wardrobe = Config.Wardrobe[i]
        lib.points.new({
            coords = wardrobe.coords,
            distance = wardrobe.distance.marker,
            interact = wardrobe.distance.interact,
            access = wardrobe.access,
            nearby = nearbyWardrobe
        })
    end
end)



RegisterNetEvent("esx_skin:OpenMenu", function()
    local config = GetDefaultConfig()
    config.ped          = true
    config.headBlend    = true
    config.faceFeatures = true
    config.headOverlays = false
    config.components   = true
    config.props        = true
    config.tattoos = false
    OpenShop(config, false, "giveclothing")
end)