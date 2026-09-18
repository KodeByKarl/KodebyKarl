import { useEffect, useRef, useState } from "react";
import {
  Skull,
  HeartCrack,
  Ghost,
  AlertTriangle,
  X,
  Ban,
  Smile,
  Eye,
  Palette,
  Type,
  Crosshair,
  Check,
} from "lucide-react";
import { cn } from "@/lib/utils";
import grimLogo from "@/assets/grim-city-logo.png";
import HitChip, { DeadIcon } from "./HitChip";
import { mergeIndicatorSettings, ZONE_META, type HitKind, type HitZone, type IndicatorSettings } from "./types";

interface IndicatorConfigProps {
  settings: IndicatorSettings;
  onChange?: (next: IndicatorSettings) => void;
  onClose: () => void;
}

const FONTS = ["Outfit", "JetBrains Mono", "Inter", "Roboto", "Arial", "Consolas"];

const ICONS = [
  { id: "skull", name: "Skull", icon: <Skull className="h-4 w-4" /> },
  { id: "crossbones", name: "Crossbones", icon: <Skull className="h-4 w-4 rotate-12" /> },
  { id: "heart-crack", name: "Heart Crack", icon: <HeartCrack className="h-4 w-4" /> },
  { id: "ghost", name: "Ghost", icon: <Ghost className="h-4 w-4" /> },
  { id: "danger", name: "Danger", icon: <AlertTriangle className="h-4 w-4" /> },
  { id: "sick", name: "Sick", icon: <Smile className="h-4 w-4 rotate-180" /> },
  { id: "x-mark", name: "X Mark", icon: <X className="h-4 w-4" /> },
  { id: "skull-io", name: "Skull (Io)", icon: <Skull className="h-4 w-4 text-[#ff8080]" /> },
  { id: "ban", name: "Ban", icon: <Ban className="h-4 w-4" /> },
];

const PREVIEW_HITS: { type: HitKind; amount: string | number; zone: HitZone }[] = [
  { type: "health", amount: 42, zone: "head" },
  { type: "health", amount: 18, zone: "neck" },
  { type: "armor", amount: 22, zone: "torso" },
  { type: "health", amount: 14, zone: "legs" },
];

function getResourceName() {
  return (window as any).GetParentResourceName ? (window as any).GetParentResourceName() : "kodebykarl-ui";
}

function CustomDropdown({
  value,
  options,
  onChange,
}: {
  value: string;
  options: string[];
  onChange: (val: string) => void;
}) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div ref={containerRef} className="relative w-full">
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="flex w-full cursor-pointer items-center justify-between rounded-xl border border-[#ff3a3a]/40 bg-[#0d0d12] px-3.5 py-2 text-xs font-bold text-white transition hover:border-[#ff3a3a]"
      >
        <span style={{ fontFamily: value }}>{value}</span>
        <span className={cn("text-[#ff4d4d] transition-transform", isOpen && "rotate-180")}>▾</span>
      </button>
      {isOpen && (
        <div className="absolute top-full right-0 left-0 z-50 mt-1.5 overflow-hidden rounded-xl border border-[#ff3a3a] bg-[#140d11] p-1.5 shadow-2xl">
          <div className="custom-scrollbar flex max-h-48 flex-col gap-1 overflow-y-auto">
            {options.map((opt) => {
              const isSelected = opt === value;
              return (
                <button
                  key={opt}
                  type="button"
                  onClick={() => {
                    onChange(opt);
                    setIsOpen(false);
                  }}
                  className={cn(
                    "flex cursor-pointer items-center justify-between rounded-lg px-3 py-2 text-left text-xs font-bold transition",
                    isSelected
                      ? "border border-[#ff3a3a]/40 bg-[#ff3a3a]/25 text-[#ff4d4d]"
                      : "text-white/80 hover:bg-[#ff3a3a]/15 hover:text-white",
                  )}
                >
                  <span style={{ fontFamily: opt }}>{opt}</span>
                  {isSelected && <Check className="h-3.5 w-3.5 text-[#ff4d4d]" />}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

export default function IndicatorConfig({ settings: initialSettings, onChange, onClose }: IndicatorConfigProps) {
  const [settings, setSettings] = useState<IndicatorSettings>(() => mergeIndicatorSettings(initialSettings));
  const [showDeadState, setShowDeadState] = useState(false);
  const [preview, setPreview] = useState<{ id: number; type: HitKind; amount: string | number; zone: HitZone; offset: number }[]>([]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onClose]);

  useEffect(() => {
    const tick = () => {
      const id = Date.now() + Math.random();
      const offset = Math.random() * 70 - 35;
      if (showDeadState) {
        setPreview((prev) => [...prev, { id, type: "dead", amount: settings.deadText || "Dead", zone: "head", offset }]);
      } else {
        const hit = PREVIEW_HITS[Math.floor(Math.random() * PREVIEW_HITS.length)];
        setPreview((prev) => [...prev, { id, type: hit.type, amount: hit.amount, zone: hit.zone, offset }]);
      }
      window.setTimeout(() => {
        setPreview((prev) => prev.filter((item) => item.id !== id));
      }, 1800);
    };

    tick();
    const interval = window.setInterval(tick, 1100);
    return () => window.clearInterval(interval);
  }, [showDeadState, settings.deadText]);

  const persist = (next: IndicatorSettings) => {
    setSettings(next);
    onChange?.(next);
    fetch(`https://${getResourceName()}/indicator:updateSettings`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(next),
    }).catch(() => {});
  };

  const updateSetting = <K extends keyof IndicatorSettings>(key: K, value: IndicatorSettings[K]) => {
    persist({ ...settings, [key]: value });
  };

  return (
    <div className="pandora pointer-events-auto fixed inset-0 z-40 flex animate-fade-in items-center justify-center bg-black/70 p-8 font-sans backdrop-blur-[6px] select-none">
      <div className="pandora-panel relative flex h-[540px] w-full max-w-6xl overflow-hidden rounded-2xl border-2 border-[#ff3a3a] bg-[#0d0d12]">
        <div className="pandora-hero relative flex w-[33%] flex-col items-center justify-between overflow-hidden border-r border-[#ff3a3a] p-8">
          <div className="panel-grid pointer-events-none absolute inset-0 opacity-40" />

          <div className="relative z-10 mt-1 flex flex-col items-center gap-3">
            <img src={grimLogo} alt="Grim City" className="pandora-logo w-[140px] object-contain" />
            <div className="text-center">
              <span className="mb-2 inline-block rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/20 px-2.5 py-1 text-[9px] font-black tracking-[0.2em] text-[#ff4d4d] uppercase">
                Combat UI
              </span>
              <h1 className="pandora-title mt-1 text-2xl font-black text-white">Damage Indicator</h1>
              <p className="mx-auto mt-2 max-w-[220px] text-[11px] leading-relaxed text-[#ffc2c2]">
                Zone-colored hitmarkers. Head blue, neck red, body amber, legs green.
              </p>
            </div>
          </div>

          <div className="relative z-10 w-full overflow-hidden rounded-xl border border-[#ff3a3a] bg-[#0d0d12]">
            <div className="flex items-center justify-between border-b border-[#ff3a3a]/30 px-3 py-2">
              <div className="flex items-center gap-1.5 text-[#ff4d4d]">
                <Eye className="h-3.5 w-3.5" />
                <span className="text-[9px] font-black tracking-wider uppercase">Live Preview</span>
              </div>
              <span className="text-[8.5px] font-bold text-[#a08890]">{settings.enabled ? "ENABLED" : "HIDDEN"}</span>
            </div>
            <div className="relative flex h-[168px] items-center justify-center overflow-hidden">
              <div className="panel-grid pointer-events-none absolute inset-0 opacity-30" />
              <div className="absolute top-1/2 left-1/2 z-10 h-2 w-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#ff3a3a]" />
              <div className="absolute top-1/2 left-1/2 h-px w-7 -translate-x-1/2 -translate-y-1/2 bg-[#ff3a3a]/40" />
              <div className="absolute top-1/2 left-1/2 h-7 w-px -translate-x-1/2 -translate-y-1/2 bg-[#ff3a3a]/40" />
              <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                {preview.map((d) => (
                  <div
                    key={d.id}
                    className="animate-preview-float absolute"
                    style={{ ["--offset" as string]: `${d.offset}px` }}
                  >
                    <HitChip
                      type={d.type}
                      amount={d.amount}
                      settings={settings}
                      zone={d.zone}
                      zoneColor={ZONE_META[d.zone].color}
                    />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        <div className="flex h-full flex-1 flex-col bg-transparent p-7">
          <div className="mb-4 flex shrink-0 items-start justify-between border-b border-[#ff3a3a]/25 pb-4">
            <div>
              <span className="text-xs font-black tracking-[0.25em] text-[#ff4d4d] uppercase">Hitmarker Settings</span>
              <p className="mt-0.5 text-[11px] text-[#a08890]">Changes auto-save and apply in combat instantly.</p>
            </div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => updateSetting("enabled", !settings.enabled)}
                className={cn(
                  "flex cursor-pointer items-center gap-1.5 rounded-lg border px-3 py-1 text-[11px] font-black uppercase transition",
                  settings.enabled
                    ? "border-emerald-500/40 bg-emerald-500/15 text-emerald-400"
                    : "border-[#ff3a3a]/40 bg-[#ff3a3a]/15 text-[#ff4d4d]",
                )}
              >
                <Crosshair className="h-3.5 w-3.5" />
                {settings.enabled ? "On" : "Off"}
              </button>
              <button
                type="button"
                onClick={onClose}
                className="flex cursor-pointer items-center gap-1.5 rounded-lg border border-[#ff3a3a]/30 bg-[#181216] px-3 py-1 text-[11px] font-semibold text-white/80 transition hover:border-[#ff3a3a] hover:text-white"
              >
                <span>Esc</span>
                <X className="h-3.5 w-3.5 text-[#ff4d4d]" />
              </button>
            </div>
          </div>

          <div className="custom-scrollbar min-h-0 flex-1 space-y-3 overflow-y-auto pr-1">
            <div className="space-y-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-4">
              <div className="flex items-center gap-2 border-b border-[#ff3a3a]/20 pb-2 text-[#ff4d4d]">
                <Skull className="h-4 w-4" />
                <span className="text-[10px] font-black tracking-wider uppercase">Dead State</span>
              </div>
              <div>
                <label className="mb-1 block text-[9px] font-black tracking-wider text-[#ff4d4d] uppercase">Label</label>
                <input
                  type="text"
                  value={settings.deadText}
                  onChange={(e) => updateSetting("deadText", e.target.value)}
                  placeholder="DEAD"
                  maxLength={16}
                  className="w-full rounded-xl border border-[#ff3a3a]/40 bg-[#0d0d12] px-3.5 py-2 text-xs font-semibold text-white placeholder:text-[#a08890]/60 focus:border-[#ff3a3a] focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1.5 block text-[9px] font-black tracking-wider text-[#ff4d4d] uppercase">Icon</label>
                <div className="grid grid-cols-5 gap-1.5">
                  {ICONS.map((ico) => (
                    <button
                      key={ico.id}
                      type="button"
                      onClick={() => updateSetting("deadIcon", ico.id)}
                      className={cn(
                        "flex cursor-pointer flex-col items-center justify-center gap-1 rounded-xl border p-2 transition-all",
                        settings.deadIcon === ico.id
                          ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-[#ff4d4d]"
                          : "border-white/10 bg-[#0d0d12] text-[#a08890] hover:text-white",
                      )}
                    >
                      {ico.icon}
                      <span className="w-full truncate text-center text-[8.5px] font-bold tracking-tight">{ico.name}</span>
                    </button>
                  ))}
                </div>
              </div>
              <div className="flex items-center justify-between rounded-xl border border-[#ff3a3a]/30 bg-[#0d0d12] p-3">
                <div className="flex items-center gap-2">
                  <DeadIcon name={settings.deadIcon} className="text-[#ff4d4d]" />
                  <span className="text-[11px] font-bold text-white">Preview kill marker</span>
                </div>
                <button
                  type="button"
                  onClick={() => setShowDeadState(!showDeadState)}
                  className={cn(
                    "relative inline-flex h-5 w-10 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors",
                    showDeadState ? "bg-[#ff3a3a]" : "bg-zinc-700",
                  )}
                >
                  <span
                    className={cn(
                      "pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow transition",
                      showDeadState ? "translate-x-5" : "translate-x-0",
                    )}
                  />
                </button>
              </div>
            </div>

            <div className="space-y-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-4">
              <div className="flex items-center gap-2 border-b border-[#ff3a3a]/20 pb-2 text-[#ff4d4d]">
                <Type className="h-4 w-4" />
                <span className="text-[10px] font-black tracking-wider uppercase">Typography</span>
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="mb-1 block text-[9px] font-black tracking-wider text-[#ff4d4d] uppercase">Font</label>
                  <CustomDropdown value={settings.fontFamily} options={FONTS} onChange={(val) => updateSetting("fontFamily", val)} />
                </div>
                <div>
                  <label className="mb-1 block text-[9px] font-black tracking-wider text-[#ff4d4d] uppercase">
                    Size {settings.fontSize}px
                  </label>
                  <input
                    type="range"
                    min={12}
                    max={32}
                    value={settings.fontSize}
                    onChange={(e) => updateSetting("fontSize", Math.max(12, Math.min(32, parseInt(e.target.value, 10) || 18)))}
                    className="mt-2 w-full accent-[#ff3a3a]"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-[9px] font-black tracking-wider text-[#ff4d4d] uppercase">
                    Duration {settings.duration.toFixed(1)}s
                  </label>
                  <input
                    type="range"
                    min={0.5}
                    max={6}
                    step={0.5}
                    value={settings.duration}
                    onChange={(e) => updateSetting("duration", Math.max(0.5, Math.min(6, parseFloat(e.target.value) || 3)))}
                    className="mt-2 w-full accent-[#ff3a3a]"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-4">
              <div className="flex items-center justify-between border-b border-[#ff3a3a]/20 pb-2">
                <div className="flex items-center gap-2 text-[#ff4d4d]">
                  <Palette className="h-4 w-4" />
                  <span className="text-[10px] font-black tracking-wider uppercase">Colors</span>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-1.5">
                {([
                  ["HEAD", "#3b82f6"],
                  ["NECK", "#ef4444"],
                  ["BODY", "#f59e0b"],
                  ["LEGS", "#22c55e"],
                ] as const).map(([label, color]) => (
                  <div key={label} className="flex items-center gap-1.5 rounded-lg border border-white/10 bg-black/30 px-2 py-1.5">
                    <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: color }} />
                    <span className="text-[9px] font-black tracking-wide" style={{ color }}>
                      {label}
                    </span>
                  </div>
                ))}
              </div>

              <div className="grid grid-cols-2 gap-3">
                <ColorField
                  label="Health fallback"
                  value={settings.healthColor}
                  id="healthColorPicker"
                  onChange={(v) => updateSetting("healthColor", v)}
                />
                <ColorField
                  label="Armour"
                  value={settings.armorColor}
                  id="armorColorPicker"
                  onChange={(v) => updateSetting("armorColor", v)}
                />
              </div>
            </div>
          </div>

          <div className="mt-3 flex shrink-0 items-center justify-between border-t border-[#ff3a3a]/25 pt-3">
            <div className="flex items-center gap-2.5">
              <img src={grimLogo} alt="Grim City" className="h-5 w-5 object-contain" />
              <span className="text-[10px] font-black tracking-[0.2em] text-white uppercase">Grim City Roleplay</span>
            </div>
            <span className="text-[10px] tracking-[0.16em] text-[#a08890]">
              Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

function ColorField({
  label,
  value,
  id,
  onChange,
}: {
  label: string;
  value: string;
  id: string;
  onChange: (value: string) => void;
}) {
  return (
    <div>
      <label className="mb-1 block text-[9px] font-black tracking-wider text-[#ff4d4d] uppercase">{label}</label>
      <div className="flex gap-2">
        <div
          className="relative h-8 w-8 shrink-0 cursor-pointer overflow-hidden rounded-xl border border-[#ff3a3a]/40 transition-colors hover:border-[#ff3a3a]"
          style={{ backgroundColor: value }}
          onClick={() => document.getElementById(id)?.click()}
        >
          <input
            type="color"
            id={id}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            className="absolute inset-0 h-full w-full cursor-pointer opacity-0"
          />
        </div>
        <input
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          maxLength={7}
          className="flex-1 rounded-xl border border-[#ff3a3a]/40 bg-[#0d0d12] px-3 py-2 text-xs font-semibold text-white focus:border-[#ff3a3a] focus:outline-none"
        />
      </div>
    </div>
  );
}
