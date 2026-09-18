local HitHeadCount = 0

-- GTA often reports neck / face / bone INDEX instead of SKEL_Head (31086) on headshots.
local HEAD_BONES = {
    [31085] = true,
    [31086] = true, -- SKEL_Head
    [12844] = true, -- IK_Head
    [65068] = true, -- FACIAL_facialRoot
    [39317] = true, -- SKEL_Neck_1 (game headshot bone)
    [24532] = true,
    [97] = true,
    [98] = true,
    [99] = true,
}

local function IsHeadBone(bone)
    bone = tonumber(bone) or -1
    if bone < 0 then return false end
    if HEAD_BONES[bone] then return true end
    return bone >= 98 and bone <= 123
end

AddEventHandler('entityDamaged', function(victim, culprit, weapon, baseDamage)
    if not culprit or culprit == 0 or not IsPedAPlayer(culprit) then return end
    if cache.ped ~= victim then return end
    if not DoesEntityExist(victim) then return end

    local hit, bone = GetPedLastDamageBone(victim)
    if hit and IsHeadBone(bone) then
        HitHeadCount += 1
        if HitHeadCount >= 1 then
            -- Delay clear so deathscreen / hit indicators can read the bone first
            SetTimeout(400, function()
                if not DoesEntityExist(victim) then return end
                ClearEntityLastDamageEntity(victim)
                ClearPedLastDamageBone(victim)
                pcall(ClearPedProp, victim, 0)
            end)
            HitHeadCount = 0
        end
    end
end)
