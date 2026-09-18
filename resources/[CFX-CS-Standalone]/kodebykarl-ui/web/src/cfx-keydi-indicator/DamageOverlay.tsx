import { useEffect, useState } from "react";
import HitChip from "./HitChip";
import type { HitKind, IndicatorSettings } from "./types";

interface DamageItem {
  id: string;
  type: HitKind;
  amount: string | number;
  x: number;
  y: number;
  zone?: string;
  zoneLabel?: string;
  zoneColor?: string;
  drift: number;
  settings: IndicatorSettings;
}

interface DamageOverlayProps {
  currentSettings: IndicatorSettings;
}

const MAX_MARKERS = 14;

export default function DamageOverlay({ currentSettings }: DamageOverlayProps) {
  const [indicators, setIndicators] = useState<DamageItem[]>([]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;
      if (data.action !== "indicator:triggerDamage" || !data.data) return;
      if (currentSettings.enabled === false) return;

      const item: DamageItem = {
        id: String(data.data.id ?? `${Date.now()}-${Math.random()}`),
        type: data.data.type,
        amount: data.data.amount,
        x: data.data.x,
        y: data.data.y,
        zone: data.data.zone,
        zoneLabel: data.data.zoneLabel,
        zoneColor: data.data.zoneColor,
        drift: Math.round((Math.random() * 48 - 24) * 10) / 10,
        settings: { ...currentSettings },
      };

      setIndicators((prev) => [...prev.slice(-(MAX_MARKERS - 1)), item]);

      const dur = Math.max(0.5, item.settings.duration || 3) * 1000;
      window.setTimeout(() => {
        setIndicators((prev) => prev.filter((i) => i.id !== item.id));
      }, dur + 80);
    };

    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, [currentSettings]);

  if (currentSettings.enabled === false) return null;

  return (
    <div className="pointer-events-none fixed inset-0 z-50 h-full w-full overflow-hidden select-none">
      {indicators.map((item) => (
        <div
          key={item.id}
          className="animate-damage-float absolute"
          style={{
            left: `${item.x * 100}%`,
            top: `${item.y * 100}%`,
            ["--duration" as string]: `${item.settings.duration}s`,
            ["--drift" as string]: `${item.drift}px`,
          }}
        >
          <HitChip
            type={item.type}
            amount={item.amount}
            settings={item.settings}
            zone={item.zone}
            zoneLabel={item.zoneLabel}
            zoneColor={item.zoneColor}
          />
        </div>
      ))}
    </div>
  );
}
