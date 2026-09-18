import React, { useEffect, useState } from "react";
import { Zap, Monitor, Check } from "lucide-react";
import { cn } from "@/lib/utils";
import grimLogo from "@/assets/grim-city-logo.png";

export interface FpsPreset {
  label: string;
  description: string;
}

interface FpsOptimizerProps {
  initialPreset?: string;
  presets?: Record<string, FpsPreset>;
  onClose: () => void;
}

const DEFAULT_PRESETS: Record<string, FpsPreset> = {
  default: {
    label: "Default",
    description: "Stock visuals — no performance modifier.",
  },
  fps_boost: {
    label: "FPS Boost",
    description: "Lighter tunnel look — better frame rate.",
  },
  pack_graphic: {
    label: "Pack Graphic",
    description: "Powerplay blend with ambient reflections.",
  },
  improved_lights: {
    label: "Improved Lights",
    description: "Tunnel modifier — clearer lighting.",
  },
  basic_boost: {
    label: "Basic Boost",
    description: "Clears modifiers — minimal post-processing.",
  },
  ultra_boost: {
    label: "Ultra Boost",
    description: "Cinema modifier — max FPS, fewer effects.",
  },
};

const PRESET_ORDER = [
  "default",
  "fps_boost",
  "pack_graphic",
  "improved_lights",
  "basic_boost",
  "ultra_boost",
];

function PresetIcon({ presetId, className }: { presetId: string; className?: string }) {
  const iconClass = cn("h-5 w-5 shrink-0 stroke-[2] fill-none text-[#ff4d4d]", className);
  if (presetId === "default") return <Zap className={iconClass} strokeWidth={2} />;
  if (presetId === "fps_boost") return <Zap className={iconClass} strokeWidth={2} />;
  return <Monitor className={iconClass} strokeWidth={2} />;
}

function IconBox({ children, size = "md" }: { children: React.ReactNode; size?: "sm" | "md" }) {
  const boxClass = size === "sm" ? "h-9 w-9" : "h-10 w-10";
  return (
    <div className={cn("pandora-icon flex shrink-0 items-center justify-center rounded-lg bg-[#ff3a3a]/15 border border-[#ff3a3a] text-white", boxClass)}>
      {children}
    </div>
  );
}

function getResourceName() {
  return (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : "cfx-keydi-ui";
}

export default function FpsOptimizer({
  initialPreset = "default",
  presets = DEFAULT_PRESETS,
  onClose,
}: FpsOptimizerProps) {
  const [activePreset, setActivePreset] = useState(initialPreset);

  useEffect(() => {
    setActivePreset(initialPreset);
  }, [initialPreset]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onClose]);

  const selectPreset = (presetId: string) => {
    setActivePreset(presetId);

    fetch(`https://${getResourceName()}/cfx-keydi-fps:setPreset`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({ preset: presetId }),
    }).catch(() => {});
  };

  const active = presets[activePreset] ?? presets.default ?? DEFAULT_PRESETS.default;

  return (
    <div className="pandora fixed inset-0 flex items-center justify-center p-8 bg-black/70 backdrop-blur-[6px] select-none pointer-events-auto animate-fade-in font-sans z-40">
      <div className="pandora-panel flex w-full max-w-6xl rounded-2xl border-2 border-[#ff3a3a] overflow-hidden h-[540px] relative bg-[#0d0d12]">
        {/* LEFT PANEL */}
        <div
          className="pandora-hero relative w-[33%] flex flex-col items-center justify-between overflow-hidden p-8 border-r border-[#ff3a3a]"
        >
          <div className="panel-grid absolute inset-0 pointer-events-none opacity-40" />

          <div className="relative z-10 flex flex-col items-center gap-4 mt-2">
            <div className="relative flex flex-col items-center">
              <img src={grimLogo} alt="Grim City" className="pandora-logo w-[150px] object-contain" />
            </div>

            <div className="text-center">
              <span className="inline-block bg-[#ff3a3a]/20 border border-[#ff3a3a] text-[#ff4d4d] text-[9px] font-black tracking-[0.2em] px-2.5 py-1 rounded-md uppercase mb-2">
                GRIM CITY ROLEPLAY
              </span>
              <h1 className="pandora-title text-2xl font-black mt-1">FPS OPTIMIZER</h1>
              <p className="mx-auto mt-2 max-w-[220px] text-[11px] leading-relaxed text-[#ffc2c2]">
                Trade visuals for frame rate with presets tuned for different play styles.
              </p>
              <span className="dev-tag text-[10.5px] text-[#a08890] block mt-3">
                Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
              </span>
            </div>
          </div>

          {/* Active preset card */}
          <div className="relative z-10 w-full p-3.5 rounded-xl bg-[#181216] border border-[#ff3a3a]">
            <p className="text-[9px] font-black uppercase tracking-[0.2em] mb-2 text-[#ff4d4d]">ACTIVE PRESET</p>
            <div className="flex items-start gap-3">
              <IconBox size="sm">
                <PresetIcon presetId={activePreset} className="h-4 w-4" />
              </IconBox>
              <div className="text-left">
                <p className="text-xs font-extrabold text-white">{active.label}</p>
                <p className="text-[9.5px] text-[#a08890] mt-0.5 leading-snug">{active.description}</p>
              </div>
            </div>
          </div>
        </div>

        {/* RIGHT PANEL */}
        <div className="flex-1 p-8 flex flex-col h-full bg-transparent">
          <div className="flex items-start justify-between border-b border-[#ff3a3a]/25 pb-4 mb-5">
            <div>
              <span className="text-xs font-black tracking-[0.25em] text-[#ff4d4d] uppercase">PRESET MODES</span>
              <p className="text-[11px] text-[#a08890] mt-0.5">Select a preset. Changes apply instantly.</p>
            </div>
            <button
              onClick={onClose}
              className="flex items-center gap-1.5 px-3 py-1 rounded-full border border-[#ff3a3a]/30 text-white/80 hover:text-white hover:border-[#ff3a3a] bg-[#181216] text-[11px] font-medium transition cursor-pointer"
            >
              <span>Esc</span>
            </button>
          </div>

          <div className="flex-1 flex flex-col">
            <p className="text-[10px] font-black text-[#ff4d4d] tracking-[0.2em] mb-2 uppercase">AVAILABLE PRESETS</p>
            <p className="text-[11px] text-[#a08890] mb-4">
              Pick the balance between visual quality and performance that fits your setup.
            </p>

            <div className="grid grid-cols-2 gap-4 flex-1">
              {PRESET_ORDER.map((presetId) => {
                const preset = presets[presetId];
                if (!preset) return null;
                const isActive = activePreset === presetId;

                return (
                  <button
                    key={presetId}
                    onClick={() => selectPreset(presetId)}
                    className={cn(
                      "group relative flex items-start gap-3 p-4 text-left transition duration-200 cursor-pointer rounded-xl border bg-[#181216]",
                      isActive
                        ? "border-[#ff3a3a] bg-[#ff3a3a]/20"
                        : "border-white/10 hover:border-[#ff3a3a]/60"
                    )}
                  >
                    <IconBox>
                      <PresetIcon presetId={presetId} />
                    </IconBox>
                    <div className="flex-1 min-w-0">
                      <span className="text-xs font-extrabold text-white">{preset.label}</span>
                      <p className="text-[9.5px] text-[#a08890] mt-0.5 leading-snug pr-6">{preset.description}</p>
                    </div>
                    {isActive && (
                      <Check className="absolute top-3 right-3 h-4 w-4 text-[#ff4d4d] stroke-[2.5] fill-none" />
                    )}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Official Footer */}
          <div className="flex items-center justify-between border-t border-[#ff3a3a]/25 pt-4 mt-2">
            <div className="flex items-center gap-2">
              <img src={grimLogo} alt="Grim City" className="h-5 w-5 object-contain" />
              <span className="text-[10px] font-extrabold tracking-[0.22em] text-[#ff4d4d]">
                GRIM CITY ROLEPLAY
              </span>
            </div>
            <span className="text-[10px] tracking-[0.18em] text-[#a08890]">
              Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
