local config = require 'configs.clothing'
local Vars = require 'helpers.vars'
RegisterCommand(config.menu.Command, function()
    if Player(cache.serverId).state.dead or Vars.playerState.isInTrunk then return end
    local SendMenu = {
        {
            title = '👕 Shirt',
            description = 'Take off your shirt',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'shirt'
            }
        },{
            title = '👖 Pants',
            description = 'Take off your pants',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'pants'
            }
        },{
            title = '👞 Shoes',
            description = 'Take off your shoes',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'shoes'
            }
        },{
            title = '😷 Mask',
            description = 'Take off your mask',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'mask'
            }
        },{
            title = '🧢 Hat/Helmet',
            description = 'Take off your Hat/Helmet',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'helmet'
            }
        },{
            title = '💼 Bag',
            description = 'Take off your bag',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'bag'
            }
        },{
            title = '👓 Glasses',
            description = 'Take off your glasses',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'glasses'
            }
        },{
            title = '🦺 Vest',
            description = 'Take off your vest',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'vest'
            }
        },{
            title = '📎 Ear Accessories',
            description = 'Take off your ear accessories',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'ears'
            }
        },{
            title = '🧣 Chain',
            description = 'Take off your chain',
            event = 'cfx-keydi-utils:Clothing:MenuActions',
            args = {
                value = 'chain'
            }
        }
    }
    lib.registerContext({
        id = 'clothes_menu',
        title = 'Clothing Menu',
        options = SendMenu
    })
     
    lib.showContext('clothes_menu')
end)

RegisterKeyMapping(config.menu.Command, config.menu.KeyMappingLabel, 'keyboard', config.menu.KeyMapping)

local IsAnim = false

local function setInvBusy(busy)
    -- ox_inventory listens to LocalPlayer.state.invBusy — must use :set so the handler fires
    pcall(function()
        LocalPlayer.state:set('invBusy', busy == true, true)
    end)
end

local function PlayClothesAnim(dict, anim, wait)
    local ped = cache.ped
    lib.requestAnimDict(dict, 5000)
    TaskPlayAnim(ped, dict, anim, 8.0, 1.0, -1, 49, 0, false, false, false)
    Wait(wait)
    ClearPedTasks(ped)
end

local function ClothesAnimations(method)
    if method == 'torso' then
        PlayClothesAnim("clothingtie", "try_tie_positive_a", 1500)
    elseif method == 'helmet' then
        PlayClothesAnim("mp_masks@standard_car@ds@", "put_on_mask", 600)
    elseif method == 'mask' then
        PlayClothesAnim("mp_masks@standard_car@ds@", "put_on_mask", 600)
    elseif method == 'ears' then
        PlayClothesAnim("mp_cp_stolen_tut", "b_think", 600)
    elseif method == 'pants' then
        PlayClothesAnim("re@construction", "out_of_breath", 1300)
    elseif method == 'shoes' then
        PlayClothesAnim("random@domestic", "pickup_low", 1300)
    elseif method == 'bag' then
        PlayClothesAnim("anim@heists@ornate_bank@grab_cash", "intro", 1300)
    elseif method == 'chain' then
        PlayClothesAnim("clothingtie", "try_tie_positive_a", 1500)
    elseif method == 'glasses' then
        PlayClothesAnim("clothingspecs", "take_off", 1300)
    elseif method == 'vest' then
        PlayClothesAnim("clothingtie", "try_tie_positive_a", 1500)
    end
end

local function isRPPed()
    if IsPedModel(cache.ped, `mp_m_freemode_01`) then
        return true, 'Male'
    elseif IsPedModel(cache.ped, `mp_f_freemode_01`) then
        return false, 'Female'
    end
    return nil, nil
end

local function genderCfg(isMale)
    return isMale and config.male or config.female
end

local function beginClothesAction()
    if IsAnim then return false end
    IsAnim = true
    setInvBusy(true)
    return true
end

local function endClothesAction()
    IsAnim = false
    setInvBusy(false)
end

--- Equip inventory clothing. If already wearing something, stash it first (swap).
local function equipComponentItem(itemType, anim, metadata, slot, applyFn, isNakedFn, stashCurrentFn)
    local ped = cache.ped
    local isMale, genderLabel = isRPPed()
    if isMale == nil then
        return ESX.Notify('CLOTHING', 'Clothing only works on freemode characters.', 'error', 5000)
    end
    if not metadata or metadata.gender ~= genderLabel then
        return ESX.Notify('CLOTHING', ('This clothing is for %s.'):format(metadata and metadata.gender or 'unknown'), 'error', 5000)
    end
    if not beginClothesAction() then return end

    local ok, err = pcall(function()
        ClothesAnimations(anim)

        -- Already wearing real clothes? Put them back into inventory first.
        if not isNakedFn(ped, isMale) then
            stashCurrentFn(ped, genderLabel)
            Wait(50)
        end

        applyFn(ped, metadata)
        TriggerServerEvent('cfx-keydi-utils:Clothing:RemoveClothes', itemType, metadata, slot)
    end)

    endClothesAction()

    if not ok then
        warn(('[kodebykarl-utils] clothing equip error: %s'):format(tostring(err)))
    end
end

-- Safety: never leave inventory locked if resource stops mid-action
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    setInvBusy(false)
end)

exports('chain', function(_, data)
    equipComponentItem('chain', 'chain', data.metadata, data.slot,
        function(ped, meta)
            SetPedComponentVariation(ped, 7, meta.accessories, meta.accessories2 or 0, 0)
        end,
        function(ped, isMale)
            return GetPedDrawableVariation(ped, 7) == genderCfg(isMale).Chain
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedDrawableVariation(ped, 7), GetPedTextureVariation(ped, 7), 'chain', genderLabel)
        end
    )
end)

exports('helmet', function(_, data)
    equipComponentItem('helmet', 'helmet', data.metadata, data.slot,
        function(ped, meta)
            SetPedPropIndex(ped, 0, meta.accessories, meta.accessories2 or 0, true)
        end,
        function(ped, isMale)
            return GetPedPropIndex(ped, 0) == genderCfg(isMale).Hat
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedPropIndex(ped, 0), GetPedPropTextureIndex(ped, 0), 'helmet', genderLabel)
        end
    )
end)

exports('torso', function(_, data)
    equipComponentItem('torso', 'torso', data.metadata, data.slot,
        function(ped, meta)
            SetPedComponentVariation(ped, 11, meta.torso1, meta.torso2 or 0, 0)
            SetPedComponentVariation(ped, 3, meta.arms1 or 0, meta.arms2 or 0, 0)
            SetPedComponentVariation(ped, 8, meta.tshirt1 or 0, meta.tshirt2 or 0, 0)
        end,
        function(ped, isMale)
            local cfg = genderCfg(isMale)
            return GetPedDrawableVariation(ped, 11) == cfg.Torso
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddTorso',
                GetPedDrawableVariation(ped, 11), GetPedTextureVariation(ped, 11),
                GetPedDrawableVariation(ped, 3), GetPedTextureVariation(ped, 3),
                GetPedDrawableVariation(ped, 8), GetPedTextureVariation(ped, 8),
                'torso', genderLabel)
        end
    )
end)

exports('pants', function(_, data)
    equipComponentItem('pants', 'pants', data.metadata, data.slot,
        function(ped, meta)
            SetPedComponentVariation(ped, 4, meta.accessories, meta.accessories2 or 0, 0)
        end,
        function(ped, isMale)
            return GetPedDrawableVariation(ped, 4) == genderCfg(isMale).Pants
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedDrawableVariation(ped, 4), GetPedTextureVariation(ped, 4), 'pants', genderLabel)
        end
    )
end)

exports('shoes', function(_, data)
    equipComponentItem('shoes', 'shoes', data.metadata, data.slot,
        function(ped, meta)
            SetPedComponentVariation(ped, 6, meta.accessories, meta.accessories2 or 0, 0)
        end,
        function(ped, isMale)
            return GetPedDrawableVariation(ped, 6) == genderCfg(isMale).Shoes
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedDrawableVariation(ped, 6), GetPedTextureVariation(ped, 6), 'shoes', genderLabel)
        end
    )
end)

exports('bag', function(_, data)
    equipComponentItem('bag', 'bag', data.metadata, data.slot,
        function(ped, meta)
            SetPedComponentVariation(ped, 5, meta.accessories, meta.accessories2 or 0, 0)
        end,
        function(ped, isMale)
            return GetPedDrawableVariation(ped, 5) == genderCfg(isMale).Bag
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedDrawableVariation(ped, 5), GetPedTextureVariation(ped, 5), 'bag', genderLabel)
        end
    )
end)

exports('mask', function(_, data)
    equipComponentItem('mask', 'mask', data.metadata, data.slot,
        function(ped, meta)
            SetPedComponentVariation(ped, 1, meta.accessories, meta.accessories2 or 0, 0)
        end,
        function(ped, isMale)
            return GetPedDrawableVariation(ped, 1) == genderCfg(isMale).Mask
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedDrawableVariation(ped, 1), GetPedTextureVariation(ped, 1), 'mask', genderLabel)
        end
    )
end)

exports('ears', function(_, data)
    equipComponentItem('ears', 'ears', data.metadata, data.slot,
        function(ped, meta)
            SetPedPropIndex(ped, 2, meta.accessories, meta.accessories2 or 0, true)
        end,
        function(ped, isMale)
            return GetPedPropIndex(ped, 2) == genderCfg(isMale).Ears
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedPropIndex(ped, 2), GetPedPropTextureIndex(ped, 2), 'ears', genderLabel)
        end
    )
end)

exports('glasses', function(_, data)
    equipComponentItem('glasses', 'glasses', data.metadata, data.slot,
        function(ped, meta)
            SetPedPropIndex(ped, 1, meta.accessories, meta.accessories2 or 0, true)
        end,
        function(ped, isMale)
            return GetPedPropIndex(ped, 1) == genderCfg(isMale).Glasses
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedPropIndex(ped, 1), GetPedPropTextureIndex(ped, 1), 'glasses', genderLabel)
        end
    )
end)

exports('vest', function(_, data)
    equipComponentItem('vest', 'vest', data.metadata, data.slot,
        function(ped, meta)
            SetPedComponentVariation(ped, 9, meta.accessories, meta.accessories2 or 0, 0)
        end,
        function(ped, isMale)
            return GetPedDrawableVariation(ped, 9) == genderCfg(isMale).Vest
        end,
        function(ped, genderLabel)
            TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes',
                GetPedDrawableVariation(ped, 9), GetPedTextureVariation(ped, 9), 'vest', genderLabel)
        end
    )
end)

RegisterNetEvent('cfx-keydi-utils:Clothing:MenuActions', function(data)
    if Vars.playerState.isDead or Vars.playerState.isInTrunk then return end
    local ped = cache.ped
    local gender, gender_label = isRPPed()
    if gender == nil then
        return ESX.Notify('CLOTHING', 'Clothing only works on freemode characters.', 'error', 5000)
    end

    local function undress(fn)
        if not beginClothesAction() then return end
        local ok, err = pcall(fn)
        endClothesAction()
        if not ok then
            warn(('[kodebykarl-utils] clothing undress error: %s'):format(tostring(err)))
        end
    end

    if data.value == 'shirt' then
        local DrawableTorso = GetPedDrawableVariation(ped, 11)
        local TextureTorso = GetPedTextureVariation(ped, 11)
        local DrawableGloves = GetPedDrawableVariation(ped, 3)
        local TextureGloves = GetPedTextureVariation(ped, 3)
        local DrawableTshirt = GetPedDrawableVariation(ped, 8)
        local TextureTshirt = GetPedTextureVariation(ped, 8)
        local cfg = gender and config.male or config.female
        if DrawableTorso ~= cfg.Torso then
            undress(function()
                ClothesAnimations('torso')
                SetPedComponentVariation(ped, 11, cfg.Torso, cfg.Torso2, 0)
                SetPedComponentVariation(ped, 8, cfg.Shirt, cfg.Shirt2, 0)
                if DrawableGloves ~= cfg.Gloves then
                    SetPedComponentVariation(ped, 3, cfg.Gloves, cfg.Gloves2, 0)
                end
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddTorso', DrawableTorso, TextureTorso, DrawableGloves, TextureGloves, DrawableTshirt, TextureTshirt, 'torso', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have torso.', 'error', 5000)
        end
    elseif data.value == 'pants' then
        local PantsDrawable = GetPedDrawableVariation(ped, 4)
        local PantsTexture = GetPedTextureVariation(ped, 4)
        local cfg = gender and config.male or config.female
        if PantsDrawable ~= cfg.Pants then
            undress(function()
                ClothesAnimations('pants')
                SetPedComponentVariation(ped, 4, cfg.Pants, cfg.Pants2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', PantsDrawable, PantsTexture, 'pants', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have pants.', 'error', 5000)
        end
    elseif data.value == 'shoes' then
        local ShoesDrawable = GetPedDrawableVariation(ped, 6)
        local ShoesTexture = GetPedTextureVariation(ped, 6)
        local cfg = gender and config.male or config.female
        if ShoesDrawable ~= cfg.Shoes then
            undress(function()
                ClothesAnimations('shoes')
                SetPedComponentVariation(ped, 6, cfg.Shoes, cfg.Shoes2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', ShoesDrawable, ShoesTexture, 'shoes', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have shoes.', 'error', 5000)
        end
    elseif data.value == 'mask' then
        local MaskDrawable = GetPedDrawableVariation(ped, 1)
        local MaskTexture = GetPedTextureVariation(ped, 1)
        local cfg = gender and config.male or config.female
        if MaskDrawable ~= cfg.Mask then
            undress(function()
                ClothesAnimations('mask')
                SetPedComponentVariation(ped, 1, cfg.Mask, cfg.Mask2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', MaskDrawable, MaskTexture, 'mask', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have mask.', 'error', 5000)
        end
    elseif data.value == 'helmet' then
        local HelmetDrawable = GetPedPropIndex(ped, 0)
        local HelmetTexture = GetPedPropTextureIndex(ped, 0)
        local cfg = gender and config.male or config.female
        if HelmetDrawable ~= cfg.Hat then
            undress(function()
                ClothesAnimations('helmet')
                ClearPedProp(ped, 0)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', HelmetDrawable, HelmetTexture, 'helmet', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have hat/helmet.', 'error', 5000)
        end
    elseif data.value == 'bag' then
        local BagDrawable = GetPedDrawableVariation(ped, 5)
        local BagTexture = GetPedTextureVariation(ped, 5)
        local cfg = gender and config.male or config.female
        if BagDrawable ~= cfg.Bag then
            undress(function()
                ClothesAnimations('bag')
                SetPedComponentVariation(ped, 5, cfg.Bag, cfg.Bag2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', BagDrawable, BagTexture, 'bag', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have bag.', 'error', 5000)
        end
    elseif data.value == 'glasses' then
        local GlassesDrawable = GetPedPropIndex(ped, 1)
        local GlassesTexture = GetPedPropTextureIndex(ped, 1)
        local cfg = gender and config.male or config.female
        if GlassesDrawable ~= cfg.Glasses then
            undress(function()
                ClothesAnimations('glasses')
                ClearPedProp(ped, 1)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', GlassesDrawable, GlassesTexture, 'glasses', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have glasses.', 'error', 5000)
        end
    elseif data.value == 'vest' then
        local VestDrawable = GetPedDrawableVariation(ped, 9)
        local VestTexture = GetPedTextureVariation(ped, 9)
        local cfg = gender and config.male or config.female
        if VestDrawable ~= cfg.Vest then
            undress(function()
                ClothesAnimations('vest')
                SetPedComponentVariation(ped, 9, cfg.Vest, cfg.Vest2, 0)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', VestDrawable, VestTexture, 'vest', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have vest.', 'error', 5000)
        end
    elseif data.value == 'ears' then
        local EarsDrawable = GetPedPropIndex(ped, 2)
        local EarsTexture = GetPedPropTextureIndex(ped, 2)
        local cfg = gender and config.male or config.female
        if EarsDrawable ~= cfg.Ears then
            undress(function()
                ClothesAnimations('ears')
                ClearPedProp(ped, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', EarsDrawable, EarsTexture, 'ears', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have ear accessories.', 'error', 5000)
        end
    elseif data.value == 'chain' then
        local ChainDrawable = GetPedDrawableVariation(ped, 7)
        local ChainTexture = GetPedTextureVariation(ped, 7)
        local cfg = gender and config.male or config.female
        if ChainDrawable ~= cfg.Chain then
            undress(function()
                ClothesAnimations('chain')
                SetPedComponentVariation(ped, 7, cfg.Chain, cfg.Chain2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:AddClothes', ChainDrawable, ChainTexture, 'chain', gender_label)
            end)
        else
            ESX.Notify('CLOTHING', 'You don\'t have chain.', 'error', 5000)
        end
    end
end)
RegisterNetEvent('cfx-keydi-utils:Clothing:RemoveAction', function(data)
    if Vars.playerState.isInTrunk then return end
    local ped = cache.ped
    local gender, gender_label = isRPPed()
    if gender == nil then return end
    if data.value == 'shirt' then
        local DrawableTorso = GetPedDrawableVariation(ped, 11) -- Torso 1
        local TextureTorso = GetPedTextureVariation(ped, 11) -- Torso 2
        local DrawableGloves = GetPedDrawableVariation(ped, 3) -- Arms 1
        local TextureGloves = GetPedTextureVariation(ped, 3) -- Arms 2
        local DrawableTshirt = GetPedDrawableVariation(ped, 8) -- Tshirt 1
        local TextureTshirt = GetPedTextureVariation(ped, 8) -- Tshirt 2
        if gender then
            if DrawableTorso ~= config.male.Torso then
                SetPedComponentVariation(ped, 11, config.male.Torso, config.male.Torso2, 0)
                SetPedComponentVariation(ped, 8,  config.male.Shirt, config.male.Shirt2, 0)
                if DrawableGloves ~= config.male.Gloves then
                    SetPedComponentVariation(ped, 3, config.male.Gloves, config.male.Gloves2, 0)
                end
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddTorso', data.robber, DrawableTorso, TextureTorso, DrawableGloves, TextureGloves, DrawableTshirt, TextureTshirt, 'torso', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have torso.', 'error', 5000)
            end
        else
            if DrawableTorso ~= config.female.Torso then
                SetPedComponentVariation(ped, 11, config.female.Torso, config.female.Torso2, 0)
                SetPedComponentVariation(ped, 8,  config.female.Shirt, config.female.Shirt2, 0)
                if DrawableGloves ~= config.female.Gloves then
                    SetPedComponentVariation(ped, 3, config.female.Gloves, config.female.Gloves2, 0)
                end
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddTorso', data.robber, DrawableTorso, TextureTorso, DrawableGloves, TextureGloves, DrawableTshirt, TextureTshirt, 'torso', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have torso.', 'error', 5000)
            end
        end
    elseif data.value == 'pants' then
        local PantsDrawable = GetPedDrawableVariation(ped, 4)
        local PantsTexture = GetPedTextureVariation(ped, 4)
        if gender then
            if PantsDrawable ~= config.male.Pants then
                SetPedComponentVariation(ped, 4, config.male.Pants, config.male.Pants2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, PantsDrawable, PantsTexture, 'pants', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have pants.', 'error', 5000)
            end
        else
            if PantsDrawable ~= config.female.Pants then
                SetPedComponentVariation(ped, 4, config.female.Pants, config.female.Pants2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, PantsDrawable, PantsTexture, 'pants', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have pants.', 'error', 5000)
            end
        end
    elseif data.value == 'shoes' then
        local ShoesDrawable = GetPedDrawableVariation(ped, 6)
        local ShoesTexture = GetPedTextureVariation(ped, 6)
        if gender then
            if ShoesDrawable ~= config.male.Shoes then
                SetPedComponentVariation(ped, 6, config.male.Shoes, config.male.Shoes2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, ShoesDrawable, ShoesTexture, 'shoes', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have shoes.', 'error', 5000)
            end
        else
            if ShoesDrawable ~= config.female.Shoes then
                SetPedComponentVariation(ped, 6, config.female.Shoes, config.female.Shoes2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, ShoesDrawable, ShoesTexture, 'shoes', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have shoes.', 'error', 5000)
            end
        end
    elseif data.value == 'mask' then
        local MaskDrawable = GetPedDrawableVariation(ped, 1)
        local MaskTexture = GetPedTextureVariation(ped, 1)
        if gender then
            if MaskDrawable ~= config.male.Mask then
                SetPedComponentVariation(ped, 1, config.male.Mask, config.male.Mask2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, MaskDrawable, MaskTexture, 'mask', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have mask.', 'error', 5000)
            end
        else
            if MaskDrawable ~= config.female.Mask then
                SetPedComponentVariation(ped, 1, config.female.Mask, config.female.Mask2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, MaskDrawable, MaskTexture, 'mask', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have mask.', 'error', 5000)
            end
        end
    elseif data.value == 'helmet' then
        local HelmetDrawable = GetPedPropIndex(ped, 0)
        local HelmetTexture = GetPedPropTextureIndex(ped, 0)
        if gender then
            if HelmetDrawable ~= config.male.Hat then
                ClearPedProp(ped, 0)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, HelmetDrawable, HelmetTexture, 'helmet', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have hat/helmet.', 'error', 5000)
            end
        else
            if HelmetDrawable ~= config.female.Hat then
                ClearPedProp(ped, 0)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, HelmetDrawable, HelmetTexture, 'helmet', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have hat/helmet.', 'error', 5000)
            end
        end
    elseif data.value == 'bag' then
        local BagDrawable = GetPedDrawableVariation(ped, 5)
        local BagTexture = GetPedTextureVariation(ped, 5)
        if gender then
            if BagDrawable ~= config.male.Bag then
                SetPedComponentVariation(ped, 5, config.male.Bag, config.male.Bag2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, BagDrawable, BagTexture, 'bag', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have bag.', 'error', 5000)
            end
        else
            if BagDrawable ~= config.female.Bag then
                SetPedComponentVariation(ped, 5, config.female.Bag, config.female.Bag2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, BagDrawable, BagTexture, 'bag', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have bag.', 'error', 5000)
            end
        end
    elseif data.value == 'glasses' then
        local GlassesDrawable = GetPedPropIndex(ped, 1)
        local GlassesTexture = GetPedPropTextureIndex(ped, 1)
        if gender then
            if GlassesDrawable ~= config.male.Glasses then
                ClearPedProp(ped, 1)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, GlassesDrawable, GlassesTexture, 'glasses', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have glasses.', 'error', 5000)
            end
        else
            if GlassesDrawable ~= config.female.Glasses then
                ClearPedProp(ped, 1)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, GlassesDrawable, GlassesTexture, 'glasses', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have glasses.', 'error', 5000)
            end
        end
    elseif data.value == 'vest' then
        local VestDrawable = GetPedDrawableVariation(ped, 9)
        local VestTexture = GetPedTextureVariation(ped, 9)
        if gender then
            if VestDrawable ~= config.male.Vest then
                SetPedComponentVariation(ped, 9, config.male.Vest, config.male.Vest2, 0)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, VestDrawable, VestTexture, 'vest', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have vest.', 'error', 5000)
            end
        else
            if VestDrawable ~= config.female.Vest then
                SetPedComponentVariation(ped, 9, config.female.Vest, config.female.Vest2, 0)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, VestDrawable, VestTexture, 'vest', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have vest.', 'error', 5000)
            end
        end
    elseif data.value == 'ears' then
        local EarsDrawable = GetPedPropIndex(ped, 2)
        local EarsTexture = GetPedPropTextureIndex(ped, 2)
        if gender then
            if EarsDrawable ~= config.male.Ears then
                ClearPedProp(ped, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, EarsDrawable, EarsTexture, 'ears', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have ear accessories.', 'error', 5000)
            end
        else
            if EarsDrawable ~= config.female.Ears then
                ClearPedProp(ped, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, EarsDrawable, EarsTexture, 'ears', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have ear accessories.', 'error', 5000)
            end
        end
    elseif data.value == 'chain' then
        local ChainDrawable = GetPedDrawableVariation(ped, 7)
        local ChainTexture = GetPedTextureVariation(ped, 7)
        if gender then
            if ChainDrawable ~= config.male.Chain then
                SetPedComponentVariation(ped, 7, config.male.Chain, config.male.Chain2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, ChainDrawable, ChainTexture, 'chain', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have chain.', 'error', 5000)
            end
        else
            if ChainDrawable ~= config.female.Chain then
                SetPedComponentVariation(ped, 7, config.female.Chain, config.female.Chain2, 2)
                TriggerServerEvent('cfx-keydi-utils:Clothing:Rob:AddClothes', data.robber, ChainDrawable, ChainTexture, 'chain', gender_label)
            else
                ESX.Notify('CLOTHING', 'You don\'t have chain.', 'error', 5000)
            end
        end
    end
end)