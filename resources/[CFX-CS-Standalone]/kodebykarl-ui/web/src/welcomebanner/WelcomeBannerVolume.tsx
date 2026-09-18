import { useEffect, useRef, useState } from "react";
import { Volume2, VolumeX, X } from "lucide-react";
import { cn } from "@/lib/utils";

export interface WelcomeBannerVolumeData {
  volume?: number;
}

interface WelcomeBannerVolumeProps {
  data?: WelcomeBannerVolumeData | null;
  onClose: () => void;
}

const PRESETS = [
  { label: "Mute", value: 0 },
  { label: "Quiet", value: 0.25 },
  { label: "Low", value: 0.5 },
  { label: "Normal", value: 0.75 },
  { label: "Full", value: 1 },
];

function getResourceName() {
  return (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName
    ? (window as Window & { GetParentResourceName: () => string }).GetParentResourceName()
    : "cfx-keydi-ui";
}

function clamp01(value: number) {
  if (Number.isNaN(value)) return 1;
  return Math.min(1, Math.max(0, value));
}

async function fetchNui(event: string, payload?: unknown) {
  try {
    await fetch(`https://${getResourceName()}/${event}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(payload ?? {}),
    });
  } catch {
    // NUI fetch can fail in browser preview.
  }
}

export default function WelcomeBannerVolume({ data, onClose }: WelcomeBannerVolumeProps) {
  const [volume, setVolume] = useState(() => clamp01(data?.volume ?? 1));
  const lastAudibleRef = useRef(volume > 0 ? volume : 1);

  useEffect(() => {
    const next = clamp01(data?.volume ?? 1);
    setVolume(next);
    if (next > 0) lastAudibleRef.current = next;
  }, [data]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const commit = (next: number) => {
    const clamped = clamp01(next);
    setVolume(clamped);
    if (clamped > 0) lastAudibleRef.current = clamped;
    fetchNui("cfx-keydi-welcomebanner:volume:set", { volume: clamped });
  };

  const muted = volume <= 0;
  const percent = Math.round(volume * 100);

  return (
    <div className="pandora fixed inset-0 z-[99950] flex items-center justify-center bg-black/80 p-4 font-sans backdrop-blur-[6px]">
      <div
        className="relative flex w-full max-w-sm flex-col overflow-hidden rounded-2xl border-2 border-[#ff3a3a]"
        style={{ background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)" }}
      >
        <div
          className="flex items-center justify-between border-b px-3 py-2"
          style={{ borderBottomColor: "rgba(255, 58, 58, 0.25)" }}
        >
          <div>
            <p className="text-[9px] font-black uppercase tracking-[0.22em] text-[#ff4d4d]">Player Setting</p>
            <h2 className="text-[14px] font-black text-white">Banner Volume</h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex items-center gap-1 rounded-md border border-[#ff3a3a]/30 bg-[#181216] px-2 py-1 text-[10px] font-semibold text-white/80 transition hover:border-[#ff3a3a] hover:text-white"
          >
            <span>Esc</span>
            <X className="h-3 w-3 text-[#ff4d4d]" />
          </button>
        </div>

        <div className="space-y-3 p-3">
          <p className="text-[11px] leading-relaxed text-[#a08890]">
            Lower this if welcome banners are too loud. Only affects what you hear.
          </p>

          <div className="rounded-lg border border-[#ff3a3a]/25 bg-[#181216] p-3">
            <div className="mb-2 flex items-center justify-between">
              <span className="flex items-center gap-1.5 text-[12px] font-bold text-white">
                {muted ? <VolumeX className="h-3.5 w-3.5 text-[#a08890]" /> : <Volume2 className="h-3.5 w-3.5 text-[#ff4d4d]" />}
                Your volume
              </span>
              <span className="text-[12px] font-black text-[#ff4d4d]">{percent}%</span>
            </div>

            <input
              type="range"
              min={0}
              max={1}
              step={0.05}
              value={volume}
              onChange={(e) => commit(Number(e.target.value))}
              className="w-full accent-[#ff3a3a]"
            />

            <button
              type="button"
              onClick={() => commit(muted ? lastAudibleRef.current || 1 : 0)}
              className={cn(
                "mt-2 w-full rounded-md border px-3 py-1.5 text-[10px] font-bold",
                muted
                  ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-[#ff4d4d]"
                  : "border-[#ff3a3a]/25 bg-black/20 text-[#a08890] hover:text-white"
              )}
            >
              {muted ? "Unmute banners" : "Mute banners"}
            </button>
          </div>

          <div className="grid grid-cols-5 gap-1">
            {PRESETS.map((preset) => {
              const active = Math.abs(volume - preset.value) < 0.001;
              return (
                <button
                  key={preset.label}
                  type="button"
                  onClick={() => commit(preset.value)}
                  className={cn(
                    "rounded-md border px-1 py-1.5 text-[9px] font-bold",
                    active
                      ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-[#ff4d4d]"
                      : "border-[#ff3a3a]/20 bg-[#181216] text-[#a08890] hover:text-white"
                  )}
                >
                  {preset.label}
                </button>
              );
            })}
          </div>
        </div>

        <div
          className="flex shrink-0 items-center justify-center border-t px-3 py-1.5"
          style={{ borderTopColor: "rgba(255, 58, 58, 0.25)" }}
        >
          <p className="text-[9px] font-semibold tracking-[0.16em] text-[#a08890]">
            Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
          </p>
        </div>
      </div>
    </div>
  );
}
