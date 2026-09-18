--[[
    Gang-gated gun crafting UI.
    Reuses cfx-cs-utils guncrafting recipes/callbacks when available,
    otherwise shows a simple unavailable notice.
]]

local busy = false
local craftData = nil

local SECTION_META = {
    weapons = { title = 'Choose a Firearm', icon = 'fa-solid fa-gun' },
    ammo = { title = 'Craft Ammo', icon = 'fa-solid fa-bullets' },
}

local function notify(msg, nType)
    Gang.Notify('GUN CRAFTING', msg, nType or 'info')
end

local function ensureData()
    if craftData then return craftData end
    if GetResourceState('cfx-cs-utils') ~= 'started' then
        return nil
    end
    craftData = lib.callback.await('cfx-keydi-utils:guncrafting:getData', false)
    return craftData
end

local function craftItem(recipe, locationId)
    if busy then return notify('You are already crafting.', 'error') end
    busy = true

    local ok = lib.progressBar({
        duration = recipe.craftTime or 6000,
        label = ('Crafting %s…'):format(recipe.label),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 49 },
    })

    busy = false
    if not ok then return notify('Crafting cancelled.', 'error') end

    -- Prefer gang-system craft (validates gang + uses shared recipes)
    local success, nameOrErr, count = lib.callback.await(
        'kodebykarl-gangsystem:guncraft',
        false,
        locationId,
        recipe.id
    )

    if success then
        notify(('Crafted x%d %s!'):format(count or 1, nameOrErr or recipe.label), 'success')
    else
        notify(nameOrErr or 'Crafting failed.', 'error')
    end
end

local function openSection(sectionKey, locationId, gangName)
    local data = ensureData()
    if not data then return notify('Gun crafting is offline.', 'error') end

    local options = {}
    for i = 1, #(data.recipes or {}) do
        local r = data.recipes[i]
        if r.section == sectionKey then
            local stock = lib.callback.await('cfx-keydi-utils:guncrafting:checkMaterials', false, r.id) or {}
            local ingList = {}
            local canCraft = true
            for j = 1, #(r.ingredients or {}) do
                local ing = r.ingredients[j]
                local userHas = tonumber(stock[j]) or 0
                local needed = ing.count or 1
                if userHas < needed then canCraft = false end
                ingList[#ingList + 1] = ('%s (%d/%d)'):format(ing.label or 'Material', userHas, needed)
            end

            options[#options + 1] = {
                title = ('%s  ×%d'):format(r.label, r.count or 1),
                description = table.concat(ingList, ', '),
                icon = canCraft and 'fa-solid fa-hammer' or 'fa-solid fa-circle-xmark',
                disabled = not canCraft,
                onSelect = function()
                    craftItem(r, locationId)
                end,
            }
        end
    end

    if #options < 1 then
        return notify('No recipes in this category.', 'error')
    end

    lib.registerContext({
        id = 'gang_guncraft_section',
        title = SECTION_META[sectionKey] and SECTION_META[sectionKey].title or 'Recipes',
        menu = 'gang_guncraft_root',
        options = options,
    })
    lib.showContext('gang_guncraft_section')
end

RegisterNetEvent('kodebykarl-gangsystem:client:openGunCraft', function(gangName, locationId)
    if not Gang.IsInGang(gangName) then
        return notify('Gang members only.', 'error')
    end

    local data = ensureData()
    if not data then
        return notify('Gun crafting module is not running.', 'error')
    end

    local sections = { 'weapons', 'ammo' }
    local options = {}
    for i = 1, #sections do
        local key = sections[i]
        local meta = SECTION_META[key]
        options[#options + 1] = {
            title = meta.title,
            icon = meta.icon,
            arrow = true,
            onSelect = function()
                openSection(key, locationId, gangName)
            end,
        }
    end

    lib.registerContext({
        id = 'gang_guncraft_root',
        title = 'Gun Crafting Workbench',
        options = options,
    })
    lib.showContext('gang_guncraft_root')
end)
