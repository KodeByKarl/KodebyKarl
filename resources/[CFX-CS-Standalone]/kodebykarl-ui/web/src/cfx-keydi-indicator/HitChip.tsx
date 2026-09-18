import type { ReactNode } from "react";
import {
  Skull,
  HeartCrack,
  Ghost,
  AlertTriangle,
  X,
  Ban,
  Smile,
  Shield,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { HitKind, HitZone, IndicatorSettings } from "./types";
import { ZONE_META } from "./types";

const ICONS: Record<string, ReactNode> = {
  skull: <Skull className="h-[0.95em] w-[0.95em]" />,
  crossbones: <Skull className="h-[0.95em] w-[0.95em] rotate-12" />,
  "heart-crack": <HeartCrack className="h-[0.95em] w-[0.95em]" />,
  ghost: <Ghost className="h-[0.95em] w-[0.95em]" />,
  danger: <AlertTriangle className="h-[0.95em] w-[0.95em]" />,
  sick: <Smile className="h-[0.95em] w-[0.95em] rotate-180" />,
  "x-mark": <X className="h-[0.95em] w-[0.95em]" />,
  "skull-io": <Skull className="h-[0.95em] w-[0.95em] text-[#ffa6ce]" />,
  ban: <Ban className="h-[0.95em] w-[0.95em]" />,
};

export function DeadIcon({ name, className }: { name: string; className?: string }) {
  return <span className={cn("inline-flex", className)}>{ICONS[name] || ICONS.skull}</span>;
}

export function resolveHitColor(opts: {
  type: HitKind;
  zone?: string;
  zoneColor?: string;
  settings: IndicatorSettings;
}) {
  if (opts.type === "dead") return "#ffffff";
  if (opts.zoneColor) return opts.zoneColor;
  if (opts.zone && ZONE_META[opts.zone as HitZone]) return ZONE_META[opts.zone as HitZone].color;
  if (opts.type === "armor") return opts.settings.armorColor;
  return opts.settings.healthColor;
}

export function zoneShortLabel(zone?: string, fallback?: string) {
  if (fallback) return fallback;
  if (zone && ZONE_META[zone as HitZone]) return ZONE_META[zone as HitZone].label;
  return "";
}

interface HitChipProps {
  type: HitKind;
  amount: string | number;
  settings: IndicatorSettings;
  zone?: string;
  zoneLabel?: string;
  zoneColor?: string;
  className?: string;
}

export default function HitChip({
  type,
  amount,
  settings,
  zone,
  zoneColor,
  className,
}: HitChipProps) {
  const color = resolveHitColor({ type, zone, zoneColor, settings });
  const isHead = zone === "head";
  const isDead = type === "dead";
  const value =
    type === "dead"
      ? String(amount || settings.deadText || "DEAD").toUpperCase()
      : type === "armor"
        ? String(amount)
        : `-${amount}`;

  return (
    <div
      className={cn(
        "inline-flex items-center gap-1.5 rounded-lg border px-2 py-0.5 font-black uppercase tracking-wide",
        isHead && "scale-110",
        className,
      )}
      style={{
        fontFamily: settings.fontFamily,
        fontSize: `${settings.fontSize}px`,
        color,
        backgroundColor: "rgba(8, 7, 10, 0.92)",
        borderColor: isDead ? "rgba(255, 58, 58, 0.9)" : color,
        boxShadow: isDead
          ? "0 0 16px rgba(255, 58, 58, 0.45), 0 6px 18px rgba(0,0,0,0.65)"
          : `0 0 14px ${color}88, 0 6px 16px rgba(0,0,0,0.6)`,
        textShadow: `0 1px 2px rgba(0,0,0,0.95), 0 0 8px ${color}99`,
      }}
    >
      {isDead && <DeadIcon name={settings.deadIcon} />}
      {type === "armor" && <Shield className="h-[0.85em] w-[0.85em]" />}
      <span className={cn("leading-none", isDead && "tracking-[0.12em]")}>{value}</span>
    </div>
  );
}
