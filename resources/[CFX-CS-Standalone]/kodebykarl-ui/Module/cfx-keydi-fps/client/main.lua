local ESX = exports["es_extended"]:getSharedObject()
local isVisible = false
local activePreset = ConfigFps.DefaultPreset
local activeOptimizations = {}

local function GetPresetConfig(presetId)
    return ConfigFps.Presets[presetId] or ConfigFps.Presets[ConfigFps.DefaultPreset]
end

local function BuildOptimizations(presetId)
    local preset = GetPresetConfig(presetId)
    local opts = preset and preset.optimizations or {}
    return {
        shadows = opts.shadows == true,
        lights = opts.lights == true,
        density = opts.density == true,
        distance = opts.distance == true,
    }
end

local function ClearVisualModifiers()
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
end

local function ApplyShadowOptimizations(enabled)
    if enabled then
        CascadeShadowsSetCascadeBoundsScale(0.0)
        CascadeShadowsEnableEntityTracker(false)
        CascadeShadowsSetEntityTrackerScale(0.0)
        CascadeShadowsSetAircraftMode(false)
        CascadeShadowsSetDynamicDepthMode(false)
        CascadeShadowsSetDynamicDepthValue(0.0)
    else
        CascadeShadowsSetCascadeBoundsScale(1.0)
        CascadeShadowsEnableEntityTracker(true)
        CascadeShadowsSetEntityTrackerScale(1.0)
        CascadeShadowsSetAircraftMode(true)
        CascadeShadowsSetDynamicDepthMode(true)
        CascadeShadowsSetDynamicDepthValue(1.0)
    end
end

local function ApplyPresetVisuals(presetId)
    local preset = GetPresetConfig(presetId)
    ClearVisualModifiers()

    if preset.timecycle then
        SetTimecycleModifier(preset.timecycle)
        SetTimecycleModifierStrength(1.0)
    end

    if preset.extraTimecycle then
        SetExtraTimecycleModifier(preset.extraTimecycle)
    end
end

local function ApplyPreset(presetId, silent)
    if not ConfigFps.Presets[presetId] then
        presetId = ConfigFps.DefaultPreset
    end

    activePreset = presetId
    activeOptimizations = BuildOptimizations(presetId)
    ApplyPresetVisuals(presetId)
    ApplyShadowOptimizations(activeOptimizations.shadows)
    SetResourceKvp("cfx-keydi-fps:preset", presetId)

    if ConfigFps.Debug then
        print(("[FPS] Preset applied: %s"):format(presetId))
    end

    if not silent then
        local preset = GetPresetConfig(presetId)
        ESX.ShowNotification(("[FPS Optimizer] %s active"):format(preset.label), "info")
    end
end

local function LoadSavedPreset()
    local saved = GetResourceKvpString("cfx-keydi-fps:preset")
    if saved and ConfigFps.Presets[saved] then
        ApplyPreset(saved, true)
    else
        ApplyPreset(ConfigFps.DefaultPreset, true)
    end
end

local function ToggleFps(state)
    if isIdentityOpen then return end
    isVisible = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "cfx-keydi-fps:show" or "cfx-keydi-fps:hide",
        preset = activePreset,
        presets = ConfigFps.Presets,
    })
end

exports("ToggleFps", ToggleFps)
exports("ApplyFpsPreset", function(presetId)
    ApplyPreset(presetId, false)
end)
exports("GetFpsPreset", function()
    return activePreset
end)

RegisterNUICallback("cfx-keydi-fps:close", function(_, cb)
    ToggleFps(false)
    cb("ok")
end)

RegisterNUICallback("cfx-keydi-fps:setPreset", function(data, cb)
    if data.preset then
        ApplyPreset(data.preset, false)
    end
    cb("ok")
end)

RegisterCommand(ConfigFps.OpenCommand, function()
    ToggleFps(not isVisible)
end, false)

if ConfigFps.ToggleKey and ConfigFps.ToggleKey ~= "" then
    RegisterKeyMapping(ConfigFps.OpenCommand, "Toggle FPS Optimizer", "keyboard", ConfigFps.ToggleKey)
end

CreateThread(function()
    LoadSavedPreset()
end)

-- Re-apply timecycle periodically (other scripts may clear it) and run *ThisFrame optimizations only when needed.
CreateThread(function()
    local lastTimecycleApply = 0
    while true do
        local sleep = 1000
        local preset = GetPresetConfig(activePreset)
        local now = GetGameTimer()

        -- Only re-apply timecycle on a cadence; idle default/basic_boost should not force Wait(0).
        if preset.timecycle or preset.extraTimecycle then
            if (now - lastTimecycleApply) >= 500 then
                if preset.timecycle then
                    SetTimecycleModifier(preset.timecycle)
                end
                if preset.extraTimecycle then
                    SetExtraTimecycleModifier(preset.extraTimecycle)
                end
                lastTimecycleApply = now
            end
            sleep = 250
        end

        if activeOptimizations.density then
            sleep = 0
            SetPedDensityMultiplierThisFrame(0.35)
            SetScenarioPedDensityMultiplierThisFrame(0.35, 0.35)
            SetVehicleDensityMultiplierThisFrame(0.35)
            SetRandomVehicleDensityMultiplierThisFrame(0.35)
            SetParkedVehicleDensityMultiplierThisFrame(0.15)
        end

        if activeOptimizations.distance then
            sleep = 0
            OverrideLodscaleThisFrame(0.55)
        end

        if activeOptimizations.lights then
            sleep = 0
            DisableVehicleDistantlights(true)
            SetLightsCutoffDistanceTweak(10.0)
        end

        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ClearVisualModifiers()
    ApplyShadowOptimizations(false)
    if isVisible then
        SetNuiFocus(false, false)
    end
end)

-- Re-apply one-time shadow natives periodically (game can reset them on area transitions).
CreateThread(function()
    while true do
        if activeOptimizations.shadows then
            ApplyShadowOptimizations(true)
        end
        Wait(5000)
    end
end)
