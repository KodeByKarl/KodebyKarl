local Config = require 'configs.antivdm'

if not Config or not Config.Enabled then
    return
end

local radius = Config.PedNoCollisionDistance or 12.0
local disableRunOver = Config.DisableRunOverDamage ~= false
local WEAPON_RUN_OVER = `WEAPON_RUN_OVER_BY_CAR`
local WEAPON_RAMMED = `WEAPON_RAMMED_BY_CAR`

-- Persistent modifiers (do not need a Wait(0) loop)
if disableRunOver then
    SetWeaponDamageModifier(WEAPON_RUN_OVER, 0.0)
    SetWeaponDamageModifier(WEAPON_RAMMED, 0.0)
end

local nearby = {}

-- Scan the vehicle pool slowly. GetGamePool every frame is the 20–40% resmon hog.
CreateThread(function()
    while true do
        local ped = cache.ped or PlayerPedId()
        if ped ~= 0 and not IsPedInAnyVehicle(ped, false) then
            local coords = GetEntityCoords(ped)
            local vehicles = GetGamePool('CVehicle')
            local nextNearby = {}
            for i = 1, #vehicles do
                local veh = vehicles[i]
                if veh ~= 0 and DoesEntityExist(veh) and #(coords - GetEntityCoords(veh)) < radius then
                    nextNearby[#nextNearby + 1] = veh
                end
            end
            nearby = nextNearby
            Wait(#nextNearby > 0 and 200 or 400)
        else
            nearby = {}
            Wait(500)
        end
    end
end)

-- Only tick every frame when there are vehicles actually in range
CreateThread(function()
    while true do
        local n = #nearby
        if n == 0 then
            Wait(250)
        else
            local ped = cache.ped or PlayerPedId()
            if ped ~= 0 and not IsPedInAnyVehicle(ped, false) then
                for i = 1, n do
                    local veh = nearby[i]
                    if veh ~= 0 and DoesEntityExist(veh) then
                        SetEntityNoCollisionEntity(ped, veh, true)
                    end
                end
                if disableRunOver then
                    SetWeaponDamageModifierThisFrame(WEAPON_RUN_OVER, 0.0)
                    SetWeaponDamageModifierThisFrame(WEAPON_RAMMED, 0.0)
                end
                Wait(0)
            else
                Wait(400)
            end
        end
    end
end)
