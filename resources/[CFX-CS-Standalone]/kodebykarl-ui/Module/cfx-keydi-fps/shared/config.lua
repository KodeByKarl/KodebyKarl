ConfigFps = {}

ConfigFps.Debug = false
ConfigFps.OpenCommand = "fpsoptimizer"
ConfigFps.ToggleKey = "" -- e.g. "F6" to bind a key
ConfigFps.DefaultPreset = "default"

-- Preset definitions: timecycle modifiers + per-frame engine optimizations.
ConfigFps.Presets = {
    default = {
        label = "Default",
        description = "Stock visuals — no performance modifier.",
        timecycle = nil,
        extraTimecycle = nil,
        optimizations = {
            shadows = false,
            lights = false,
            density = false,
            distance = false,
        },
    },
    fps_boost = {
        label = "FPS Boost",
        description = "Lighter tunnel look — better frame rate.",
        timecycle = "yell_tunnel_nodirect",
        extraTimecycle = nil,
        optimizations = {
            shadows = true,
            lights = false,
            density = false,
            distance = false,
        },
    },
    pack_graphic = {
        label = "Pack Graphic",
        description = "Powerplay blend with ambient reflections.",
        timecycle = "MP_Powerplay_blend",
        extraTimecycle = "reflection_correct_ambient",
        optimizations = {
            shadows = false,
            lights = false,
            density = false,
            distance = false,
        },
    },
    improved_lights = {
        label = "Improved Lights",
        description = "Tunnel modifier — clearer lighting.",
        timecycle = "tunnel",
        extraTimecycle = nil,
        optimizations = {
            shadows = false,
            lights = true,
            density = false,
            distance = false,
        },
    },
    basic_boost = {
        label = "Basic Boost",
        description = "Clears modifiers — minimal post-processing.",
        timecycle = nil,
        extraTimecycle = nil,
        optimizations = {
            shadows = true,
            lights = true,
            density = true,
            distance = false,
        },
    },
    ultra_boost = {
        label = "Ultra Boost",
        description = "Cinema modifier — max FPS, fewer effects.",
        timecycle = "cinema",
        extraTimecycle = nil,
        optimizations = {
            shadows = true,
            lights = true,
            density = true,
            distance = true,
        },
    },
}
