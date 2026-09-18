export interface IndicatorSettings {
  deadText: string;
  deadIcon: string;
  fontFamily: string;
  fontSize: number;
  duration: number;
  healthColor: string;
  armorColor: string;
  enabled: boolean;
  showZoneLabel: boolean;
}

export type HitKind = "health" | "armor" | "dead";
export type HitZone = "head" | "neck" | "torso" | "arms" | "legs";

export const DEFAULT_INDICATOR_SETTINGS: IndicatorSettings = {
  deadText: "Dead",
  deadIcon: "skull",
  fontFamily: "JetBrains Mono",
  fontSize: 18,
  duration: 3.0,
  healthColor: "#f87171",
  armorColor: "#60a5fa",
  enabled: true,
  showZoneLabel: false,
};

export const ZONE_META: Record<HitZone, { label: string; color: string }> = {
  head: { label: "HEAD", color: "#3b82f6" },
  neck: { label: "NECK", color: "#ef4444" },
  torso: { label: "BODY", color: "#f59e0b" },
  arms: { label: "ARM", color: "#f59e0b" },
  legs: { label: "LEGS", color: "#22c55e" },
};

export function mergeIndicatorSettings(partial?: Partial<IndicatorSettings> | null): IndicatorSettings {
  return {
    ...DEFAULT_INDICATOR_SETTINGS,
    ...(partial || {}),
    enabled: partial?.enabled !== false,
    showZoneLabel: false,
    fontSize: Number(partial?.fontSize) || DEFAULT_INDICATOR_SETTINGS.fontSize,
    duration: Number(partial?.duration) || DEFAULT_INDICATOR_SETTINGS.duration,
  };
}
