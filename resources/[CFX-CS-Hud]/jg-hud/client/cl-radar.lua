local BASE_ASPECT_RATIO = 1.7777777777777777

local radarPresets = {
    square = {
        minimap = { -0.0045, 0.002, 0.15, 0.188888 },
        minimap_mask = { 0.0, -0.01, 0.12, 0.2 },
        minimap_blur = { -0.0305, 0.04, 0.267, 0.272 }
    },
    rounded = {
        minimap = { -0.0045, 0.002, 0.15, 0.188888 },
        minimap_mask = { 0.0, -0.01, 0.12, 0.2 },
        minimap_blur = { -0.0305, 0.04, 0.267, 0.272 }
    },
    circular = {
        minimap = { -0.008, 0.005, 0.12, 0.202 },
        minimap_mask = { 0.0, 0.0, 0.111, 0.2 },
        minimap_blur = { -0.021, 0.04, 0.192, 0.272 }
    }
}

local function areNuiAndActiveScreenResDifferent()
    local nuiWidth, nuiHeight = GetNUIScreenResolution()
    local screenWidth, screenHeight = GetActiveScreenResolution()
    return nuiWidth ~= screenWidth or nuiHeight ~= screenHeight
end

local function getRadarBaseOffsets(applyUltraWideCorrection)
    local _, nuiHeight = GetNUIScreenResolution()
    local offsetX = 0.0
    local offsetY = -0.05

    if applyUltraWideCorrection then
        local aspectRatio = GetNUIAspectRatio()
        if aspectRatio > BASE_ASPECT_RATIO then
            offsetX = (BASE_ASPECT_RATIO - aspectRatio) / 3.6
        end
    end

    if nuiHeight < 1400 then offsetY = -0.06 end
    if nuiHeight < 1240 then offsetY = -0.07 end
    if nuiHeight < 1050 then offsetY = -0.09 end
    if nuiHeight < 950 then offsetY = -0.09 end
    if nuiHeight < 850 then offsetY = -0.10 end
    if nuiHeight < 750 then offsetY = -0.11 end
    if nuiHeight < 650 then offsetY = -0.14 end

    return offsetX, offsetY
end

local function applyRadarOffsetAndScale(
    baseX,
    baseY,
    baseHeight,
    addPixelX,
    addPixelY,
    _unused,
    overrideHeight,
    applyUltraWideCorrection
)
    local scale = 1.0
    local offsetX, offsetY = getRadarBaseOffsets(applyUltraWideCorrection)
    local nuiWidth, nuiHeight = GetNUIScreenResolution()
    local aspectRatio = GetNUIAspectRatio()

    if overrideHeight then
        scale = overrideHeight / baseHeight
    end

    if addPixelX then
        local extraX = (addPixelX / nuiWidth) * (aspectRatio / BASE_ASPECT_RATIO)
        offsetX = offsetX + extraX
    end

    if addPixelY then
        local heightForShift = overrideHeight or baseHeight
        local extraY = (addPixelY + (heightForShift - baseHeight)) / nuiHeight
        offsetY = offsetY + extraY
    end

    return offsetX, offsetY, scale
end

local function calculateRadarPixelBounds(applyUltraWideCorrection)
    local baseOffsetX, baseOffsetY = getRadarBaseOffsets(applyUltraWideCorrection)
    local safeZoneSize = GetSafeZoneSize()

    SetScriptGfxAlign(string.byte("L"), string.byte("B"))
    local aspectRatio = GetNUIAspectRatio()

    local alignLeftX, _ = GetScriptGfxPosition(0.0, -0.186888)
    local rightX, bottomY = GetScriptGfxPosition(
        baseOffsetX / (aspectRatio / BASE_ASPECT_RATIO),
        -0.186888 + baseOffsetY
    )
    ResetScriptGfxAlign()

    local activeWidth, activeHeight = GetActiveScreenResolution()
    local nuiWidth, nuiHeight = GetNUIScreenResolution()

    if aspectRatio > 2 then
        aspectRatio = BASE_ASPECT_RATIO
    end

    local pixelX = nuiWidth * rightX
    local pixelY = nuiHeight * bottomY

    if areNuiAndActiveScreenResDifferent() then
        local active16by9Width = (1920 * activeHeight) / 1080
        local pillarboxOffset = (activeWidth - active16by9Width) / 2
        pixelX = pixelX + pillarboxOffset

        local nuiToActiveRatio = nuiHeight / activeHeight
        nuiWidth = activeWidth * nuiToActiveRatio
    end

    local widthScale = (1.0 / nuiWidth) * (nuiWidth / (4 * aspectRatio))
    local aspectMultiplier = 1
    if aspectRatio > 2 then
        aspectMultiplier = 0.76
    elseif aspectRatio > 1.8 then
        aspectMultiplier = 0.995
    end
    widthScale = widthScale * aspectMultiplier

    local safeZoneWidth = (nuiWidth / safeZoneSize) - ((nuiWidth * alignLeftX) * 2)
    local pixelWidth = widthScale * safeZoneWidth
    local pixelHeight = nuiHeight / 5.5

    return pixelX, pixelY, pixelWidth, pixelHeight
end

function SetRadarMaskAndPos(maskStyle, addPixelX, addPixelY, _, overrideHeight, applyUltraWideCorrection, showNorth)
    local pixelX, pixelY, pixelWidth, pixelHeight = calculateRadarPixelBounds(applyUltraWideCorrection)

    lib.requestStreamedTextureDict("jgradar")

    local maskTexture = "radarmasksm-rounded"
    if maskStyle == "circular" then
        maskTexture = "radarmasksm-circular"
    elseif maskStyle == "square" then
        maskTexture = "radarmasksm-square"
    end

    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "jgradar", maskTexture)
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "jgradar", maskTexture)
    SetStreamedTextureDictAsNoLongerNeeded("jgradar")

    if areNuiAndActiveScreenResDifferent() then
        local safeZoneOffset = 1920 * (1 - GetSafeZoneSize())
        pixelX = safeZoneOffset / 2
    end

    local offsetX, offsetY, scale = applyRadarOffsetAndScale(
        pixelX,
        pixelY,
        pixelHeight,
        addPixelX,
        addPixelY,
        nil,
        overrideHeight,
        applyUltraWideCorrection
    )

    local preset = radarPresets[maskStyle]
    for component, values in pairs(preset) do
        SetMinimapComponentPosition(
            component,
            "L",
            "B",
            (values[1] * scale) + offsetX,
            (values[2] * scale) + offsetY,
            values[3] * scale,
            values[4] * scale
        )
    end

    SetBlipAlpha(GetNorthRadarBlip(), showNorth and 255 or 0)
    SetMinimapClipType(maskStyle == "circular" and 1 or 0)

    SetBigmapActive(true, false)
    Wait(1)
    SetBigmapActive(false, false)

    return pixelX, pixelY, pixelWidth, pixelHeight
end

local radarThreadRunning = false
function CreateRadarThread()
    if radarThreadRunning then
        return
    end

    radarThreadRunning = true
    CreateThread(function()
        while IsHudRunning do
            DisplayRadarConditionally()
            Wait(2000)
        end

        radarThreadRunning = false
    end)
end

local hideHudComponentThisFrame = HideHudComponentThisFrame
local hideBaseHudThreadRunning = false

function CreateHideHudComponentsThread()
    if not (Config and Config.HideBaseGameHudComponents) then
        return
    end

    if hideBaseHudThreadRunning then
        return
    end

    hideBaseHudThreadRunning = true
    CreateThread(function()
        while IsHudRunning do
            local components = (Config and Config.HideBaseGameHudComponents) or {}
            for _, componentId in ipairs(components) do
                hideHudComponentThisFrame(componentId)
            end

            Wait(1)
        end

        hideBaseHudThreadRunning = false
    end)
end
