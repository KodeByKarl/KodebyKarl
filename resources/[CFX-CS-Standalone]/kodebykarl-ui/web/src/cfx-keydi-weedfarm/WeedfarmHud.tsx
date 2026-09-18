import React, { useState, useEffect } from "react";
import {
  Sprout,
  Package,
  Cigarette,
  MapPin,
  Clock,
  Weight,
  Sparkles,
  Flame,
  CheckCircle2,
  Layers,
  Info,
  DollarSign,
} from "lucide-react";
import { cn } from "@/lib/utils";

export type WeedStage = "harvest" | "package" | "roll";

export interface WeedfarmData {
  status: "active" | "idle" | "full";
  stage: WeedStage;
  label: string;
  image?: string;
  itemWeight: number; // in grams
  collected: number;
  weight: number; // current inventory weight in grams
  maxWeight: number; // max inventory weight in grams
  progress: number; // 0.0 to 1.0
  zone: string;
  rarity: "common" | "uncommon" | "rare" | "exotic";
  untilFull: number;
  etaSeconds: number;
  recipe?: {
    inputLabel?: string;
    inputAmount?: number;
    requireLabel?: string;
    requireAmount?: number;
    requires?: Array<{
      label: string;
      amount: number;
      isMoney?: boolean;
    }>;
    outputLabel?: string;
    outputAmount?: number;
  };
}

const STAGES_CONFIG: Record<
  WeedStage,
  {
    id: WeedStage;
    label: string;
    actionVerb: string;
    itemName: string;
    itemLabel: string;
    itemWeight: number;
    image: string;
    icon: typeof Sprout;
    zone: string;
    rarity: WeedfarmData["rarity"];
    recipe?: WeedfarmData["recipe"];
  }
> = {
  harvest: {
    id: "harvest",
    label: "Harvest Plant",
    actionVerb: "Harvesting Weed",
    itemName: "weed_bud",
    itemLabel: "Weed Bud",
    itemWeight: 50,
    image: "nui://ox_inventory/web/images/weed_bud.png",
    icon: Sprout,
    zone: "San Chianski Weed Farm",
    rarity: "uncommon",
    recipe: {
      outputLabel: "Weed Bud",
      outputAmount: 3,
    },
  },
  package: {
    id: "package",
    label: "Package Weed",
    actionVerb: "Packaging Weed",
    itemName: "packaged_weed",
    itemLabel: "Packaged Weed",
    itemWeight: 100,
    image: "nui://ox_inventory/web/images/packaged_weed.png",
    icon: Package,
    zone: "Weed Processing Bench #1",
    rarity: "uncommon",
    recipe: {
      inputLabel: "Weed Bud",
      inputAmount: 5,
      requires: [
        { label: "Zip-lock Bag", amount: 1 },
      ],
      requireLabel: "Zip-lock Bag",
      requireAmount: 1,
      outputLabel: "Packaged Weed",
      outputAmount: 5,
    },
  },
  roll: {
    id: "roll",
    label: "Roll Joints",
    actionVerb: "Rolling Joints",
    itemName: "joint",
    itemLabel: "Joint",
    itemWeight: 10,
    image: "nui://ox_inventory/web/images/joint.png",
    icon: Cigarette,
    zone: "Weed Rolling Bench #2",
    rarity: "rare",
    recipe: {
      inputLabel: "Packaged Weed",
      inputAmount: 5,
      requires: [
        { label: "Rolling Paper", amount: 5 },
        { label: "Paper Bag", amount: 5 },
        { label: "Dirty Money", amount: 1000, isMoney: true },
      ],
      outputLabel: "Joint",
      outputAmount: 5,
    },
  },
};

const DEFAULT_DATA: WeedfarmData = {
  status: "active",
  stage: "harvest",
  label: "Weed Bud",
  image: "nui://ox_inventory/web/images/weed_bud.png",
  itemWeight: 50,
  collected: 28,
  weight: 4200,
  maxWeight: 24000,
  progress: 0.42,
  zone: "San Chianski Weed Farm",
  rarity: "uncommon",
  untilFull: 396,
  etaSeconds: 520,
  recipe: {
    outputLabel: "Weed Bud",
    outputAmount: 3,
  },
};

const RARITY_META = {
  common: { label: "Common", color: "#9ca3af", border: "rgba(156,163,175,0.4)", bg: "rgba(156,163,175,0.12)" },
  uncommon: { label: "Uncommon", color: "#10b981", border: "rgba(16,185,129,0.45)", bg: "rgba(16,185,129,0.12)" },
  rare: { label: "Rare", color: "#38bdf8", border: "rgba(56,189,248,0.45)", bg: "rgba(56,189,248,0.12)" },
  exotic: { label: "Exotic", color: "#ec4899", border: "rgba(236,72,153,0.45)", bg: "rgba(236,72,153,0.12)" },
};

function formatWeight(grams: number): string {
  if (grams >= 1000) {
    return `${(grams / 1000).toFixed(1)}kg`;
  }
  return `${Math.round(grams)}g`;
}

function formatEta(seconds: number): string {
  if (seconds <= 0) return "--";
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m > 0) return `~${m}m ${s}s`;
  return `~${s}s`;
}

function isBrowserEnv(): boolean {
  return !(window as unknown as { invokeNative?: unknown }).invokeNative && !navigator.userAgent.includes("FiveM");
}

const RING_RADIUS = 38;
const RING_CIRCUMFERENCE = 2 * Math.PI * RING_RADIUS;

export default function WeedfarmHud() {
  const [visible, setVisible] = useState(false);
  const [data, setData] = useState<WeedfarmData>(DEFAULT_DATA);
  const [imageFailed, setImageFailed] = useState(false);

  // Setup preview in browser or listen to NUI events
  useEffect(() => {
    if (isBrowserEnv()) {
      const params = new URLSearchParams(window.location.search);
      const preview = params.get("preview");
      // Default to visible weedfarm when preview is weedfarm, weed, or default
      if (preview === "weedfarm" || preview === "weed" || !preview || preview === "") {
        setData(DEFAULT_DATA);
        setVisible(true);
      }
    }

    const handleMessage = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg) return;

      if (msg.action === "cfx-keydi-weedfarm:show") {
        if (msg.data) {
          setData((prev) => ({
            ...prev,
            ...msg.data,
            status: msg.data.status || "active",
          }));
        }
        setImageFailed(false);
        setVisible(true);
      } else if (msg.action === "cfx-keydi-weedfarm:update") {
        if (msg.data) {
          setData((prev) => ({
            ...prev,
            ...msg.data,
          }));
        }
      } else if (msg.action === "cfx-keydi-weedfarm:hide") {
        setVisible(false);
      }
    };

    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  // Smooth simulated progress loop in browser preview
  useEffect(() => {
    if (!visible || data.status !== "active" || !isBrowserEnv()) return;

    const interval = window.setInterval(() => {
      setData((prev) => {
        const nextProg = prev.progress + 0.015;
        const progress = nextProg >= 1 ? 0 : nextProg;
        const itemW = prev.itemWeight || 50;
        const freeWeight = Math.max(0, prev.maxWeight - prev.weight);
        const untilFull = Math.floor(freeWeight / itemW);
        const cycleSec = 5;
        const remainingThisCycle = Math.max(0, 1 - progress) * cycleSec;
        const etaSeconds = Math.max(1, Math.ceil(remainingThisCycle + Math.max(0, (untilFull - 1) * cycleSec)));

        return {
          ...prev,
          progress,
          untilFull,
          etaSeconds,
          collected: nextProg >= 1 ? prev.collected + (prev.stage === "roll" ? 5 : 3) : prev.collected,
          weight: nextProg >= 1 ? Math.min(prev.maxWeight, prev.weight + itemW * 3) : prev.weight,
        };
      });
    }, 120);

    return () => window.clearInterval(interval);
  }, [visible, data.status, data.stage]);

  // Handle stage tab click in preview mode
  const handleStageSelect = (stageId: WeedStage) => {
    const config = STAGES_CONFIG[stageId];
    setData((prev) => ({
      ...prev,
      stage: stageId,
      label: config.itemLabel,
      image: config.image,
      itemWeight: config.itemWeight,
      zone: config.zone,
      rarity: config.rarity,
      recipe: config.recipe,
      progress: 0.1,
    }));
    setImageFailed(false);
  };

  if (!visible) return null;

  const currentStageConfig = STAGES_CONFIG[data.stage] || STAGES_CONFIG.harvest;
  const StageIcon = currentStageConfig.icon;
  const rarity = RARITY_META[data.rarity] || RARITY_META.uncommon;
  const weightPercent = data.maxWeight > 0 ? Math.min((data.weight / data.maxWeight) * 100, 100) : 0;
  const progressPct = Math.round(Math.min(Math.max(data.progress, 0), 1) * 100);
  const cycleOffset = RING_CIRCUMFERENCE * (1 - Math.min(Math.max(data.progress, 0), 1));

  return (
    <div className="fixed left-6 top-[48%] z-[99990] w-[315px] -translate-y-1/2 select-none font-sans transition-all duration-300 pointer-events-none">
      <div
        className="pointer-events-auto relative overflow-hidden rounded-2xl border shadow-[0_24px_65px_rgba(0,0,0,0.95)]"
        style={{
          backgroundColor: "#0d120f",
          borderColor: "rgba(16, 185, 129, 0.55)",
          boxShadow: "0 0 30px rgba(0,0,0,0.9), 0 0 15px rgba(16, 185, 129, 0.25)",
        }}
      >
        {/* Top Header */}
        <div
          className="relative flex items-center justify-between border-b border-emerald-500/20 px-4 py-3"
          style={{ backgroundColor: "#111814" }}
        >
          <div className="flex items-center gap-2.5">
            <div className="relative flex h-9 w-9 items-center justify-center rounded-xl border border-emerald-500/40 bg-emerald-500/15 shadow-[inset_0_0_12px_rgba(16,185,129,0.2)]">
              <Sprout className="h-5 w-5 text-emerald-400" strokeWidth={2.4} />
              <span className="absolute -right-0.5 -top-0.5 h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
            </div>
            <div className="leading-tight">
              <div className="flex items-center gap-1.5">
                <span className="text-[14px] font-black uppercase tracking-[0.08em] text-white">
                  Weed Farm
                </span>
                <span className="rounded border border-red-500/40 bg-red-500/20 px-1.5 py-0.2 text-[8.5px] font-black uppercase tracking-wider text-red-400">
                  REDZONE
                </span>
              </div>
              <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-emerald-400">
                Grim City Ops
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1.5 rounded-full border border-emerald-500/40 bg-emerald-500/10 px-2.5 py-1">
            <span
              className={cn(
                "h-1.5 w-1.5 rounded-full",
                data.status === "active" ? "bg-emerald-400 animate-ping" : "bg-white/40"
              )}
            />
            <span className="text-[9.5px] font-black uppercase tracking-wider text-emerald-300">
              {data.status === "active" ? "ACTIVE" : "IDLE"}
            </span>
          </div>
        </div>

        {/* Interactive Stages Bar (Especially useful for browser preview) */}
        <div
          className="border-b border-white/5 px-3 py-2"
          style={{ backgroundColor: "#0a0e0c" }}
        >
          <div className="flex items-center justify-between gap-1">
            {(["harvest", "package", "roll"] as const).map((stg) => {
              const cfg = STAGES_CONFIG[stg];
              const isCurrent = data.stage === stg;
              const IconComp = cfg.icon;
              return (
                <button
                  key={stg}
                  type="button"
                  onClick={() => handleStageSelect(stg)}
                  className={cn(
                    "flex flex-1 items-center justify-center gap-1.5 rounded-lg border py-1.5 text-[10px] font-black uppercase tracking-wider transition-all duration-200 cursor-pointer",
                    isCurrent
                      ? "border-emerald-500/60 bg-emerald-950 text-emerald-300 shadow-[0_0_10px_rgba(16,185,129,0.25)]"
                      : "border-white/5 bg-[#141b16] text-white/45 hover:border-white/20 hover:text-white/80"
                  )}
                >
                  <IconComp className="h-3.5 w-3.5 shrink-0" />
                  <span className="truncate">{cfg.label.split(" ")[0]}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Content Body */}
        <div className="space-y-3 p-3.5" style={{ backgroundColor: "#0d120f" }}>
          {/* Zone & Rarity Header */}
          <div className="flex items-center gap-2">
            <div
              className="flex min-w-0 flex-1 items-center gap-1.5 rounded-lg border border-white/8 px-2.5 py-1.5"
              style={{ backgroundColor: "#111814" }}
            >
              <MapPin className="h-3.5 w-3.5 shrink-0 text-emerald-400" />
              <span className="truncate text-[10.5px] font-bold uppercase tracking-wide text-white/90">
                {data.zone}
              </span>
            </div>
            <div
              className="shrink-0 rounded-lg border px-2 py-1.5 text-[9.5px] font-black uppercase tracking-wider"
              style={{ color: rarity.color, borderColor: rarity.border, background: rarity.bg }}
            >
              {rarity.label}
            </div>
          </div>

          {/* Core Item Progress Card */}
          <div
            className="flex items-center gap-3.5 rounded-xl border border-white/5 p-3"
            style={{ backgroundColor: "#111814" }}
          >
            {/* Animated Progress Radial Ring */}
            <div
              className="relative flex h-[88px] w-[88px] shrink-0 items-center justify-center rounded-xl border border-emerald-500/25"
              style={{ backgroundColor: "#080c09" }}
            >
              <svg className="absolute inset-1 -rotate-90" viewBox="0 0 100 100">
                <circle
                  cx="50"
                  cy="50"
                  r={RING_RADIUS}
                  fill="none"
                  stroke="rgba(255,255,255,0.06)"
                  strokeWidth="6"
                />
                <circle
                  cx="50"
                  cy="50"
                  r={RING_RADIUS}
                  fill="none"
                  stroke="#10b981"
                  strokeWidth="6"
                  strokeLinecap="round"
                  strokeDasharray={RING_CIRCUMFERENCE}
                  strokeDashoffset={cycleOffset}
                  style={{
                    transition: "stroke-dashoffset 120ms linear",
                    filter: "drop-shadow(0 0 5px rgba(16,185,129,0.7))",
                  }}
                />
              </svg>

              <div
                className="relative z-10 flex h-14 w-14 items-center justify-center rounded-full shadow-inner"
                style={{ backgroundColor: "#050806" }}
              >
                {data.image && !imageFailed ? (
                  <img
                    src={data.image}
                    alt={data.label}
                    onError={() => setImageFailed(true)}
                    className="h-10 w-10 object-contain drop-shadow-md"
                  />
                ) : (
                  <StageIcon className="h-7 w-7 text-emerald-400" />
                )}
              </div>

              <span
                className="absolute -bottom-1.5 rounded-full border border-emerald-500/40 px-1.5 py-0.2 text-[8px] font-black text-emerald-400"
                style={{ backgroundColor: "#050806" }}
              >
                {progressPct}%
              </span>
            </div>

            {/* Item Title & Specs */}
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5">
                <span className="text-[9.5px] font-black uppercase tracking-wider text-emerald-400/80">
                  {currentStageConfig.actionVerb}
                </span>
              </div>
              <p className="truncate text-[17px] font-black uppercase tracking-wide text-white">
                {data.label}
              </p>
              <div className="mt-1 flex items-center gap-2 text-[10.5px] font-semibold text-white/50">
                <span className="flex items-center gap-1">
                  <Weight className="h-3 w-3 text-emerald-400" />
                  {formatWeight(data.itemWeight)} / ea
                </span>
                <span>•</span>
                <span className="text-emerald-300 font-bold">
                  +{data.stage === "roll" ? 5 : 3} per cycle
                </span>
              </div>
            </div>
          </div>

          {/* Recipe Requirements (for Packaging & Rolling) */}
          {data.recipe && (data.recipe.requires || data.recipe.requireLabel) && (
            <div
              className="rounded-xl border border-emerald-500/20 p-2.5 text-[10.5px] space-y-1.5 shadow-sm"
              style={{ backgroundColor: "#111814" }}
            >
              <div className="flex items-center justify-between text-white/70 font-semibold">
                <span className="flex items-center gap-1.5">
                  <Layers className="h-3.5 w-3.5 text-emerald-400" />
                  <span>
                    Recipe ({data.recipe.outputAmount || 5}x {data.recipe.outputLabel || "Joint"}):
                  </span>
                </span>
                {data.recipe.inputLabel && (
                  <span
                    className="rounded border border-emerald-500/30 px-1.5 py-0.5 font-bold text-emerald-300"
                    style={{ backgroundColor: "#080c09" }}
                  >
                    {data.recipe.inputAmount}x {data.recipe.inputLabel}
                  </span>
                )}
              </div>

              {/* Multi-requirement Badges */}
              <div className="flex flex-wrap items-center gap-1.5 pt-0.5">
                {data.recipe.requires && data.recipe.requires.length > 0 ? (
                  data.recipe.requires.map((req, idx) => (
                    <span
                      key={idx}
                      className={cn(
                        "inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-[9.5px] font-bold border shadow-sm",
                        req.isMoney
                          ? "border-amber-500/40 bg-amber-500/10 text-amber-300"
                          : "border-emerald-500/30 bg-emerald-500/10 text-emerald-300"
                      )}
                    >
                      {req.isMoney ? (
                        <>
                          <DollarSign className="h-3 w-3 text-amber-400" />
                          <span>${req.amount.toLocaleString()} {req.label}</span>
                        </>
                      ) : (
                        <span>{req.amount}x {req.label}</span>
                      )}
                    </span>
                  ))
                ) : (
                  <span className="inline-flex items-center rounded-md border border-emerald-500/30 bg-emerald-500/10 px-2 py-0.5 text-[9.5px] font-bold text-emerald-300">
                    {data.recipe.requireAmount}x {data.recipe.requireLabel}
                  </span>
                )}
              </div>
            </div>
          )}

          {/* Inventory Capacity & Yield Forecast */}
          <div
            className="rounded-xl border border-white/5 p-3 space-y-2"
            style={{ backgroundColor: "#111814" }}
          >
            <div className="flex items-center justify-between text-[11px] font-bold">
              <span className="flex items-center gap-1.5 text-white/60">
                <Weight className="h-3.5 w-3.5 text-emerald-400" />
                Carry Weight
              </span>
              <span className="text-white">
                {formatWeight(data.weight)}{" "}
                <span className="text-white/40">/ {formatWeight(data.maxWeight)}</span>
              </span>
            </div>

            {/* Custom emerald weight progress bar */}
            <div
              className="h-2 w-full overflow-hidden rounded-full border border-white/5"
              style={{ backgroundColor: "#060907" }}
            >
              <div
                className="h-full rounded-full transition-all duration-300"
                style={{
                  width: `${weightPercent}%`,
                  background:
                    weightPercent > 90
                      ? "linear-gradient(90deg, #f59e0b, #ef4444)"
                      : "linear-gradient(90deg, #059669, #10b981)",
                  boxShadow: "0 0 10px rgba(16,185,129,0.5)",
                }}
              />
            </div>

            <div className="grid grid-cols-2 gap-2 pt-1">
              <div
                className="rounded-lg border border-white/5 p-2 text-left"
                style={{ backgroundColor: "#080c09" }}
              >
                <p className="text-[9px] font-bold uppercase tracking-wider text-white/40">Gathered</p>
                <p className="text-[13px] font-black text-white">
                  {data.collected}{" "}
                  <span className="text-[9.5px] font-normal text-emerald-400">units</span>
                </p>
              </div>
              <div
                className="rounded-lg border border-white/5 p-2 text-left"
                style={{ backgroundColor: "#080c09" }}
              >
                <p className="text-[9px] font-bold uppercase tracking-wider text-white/40">Bag Full In</p>
                <div className="flex items-center gap-1 text-[13px] font-black text-emerald-400">
                  <Clock className="h-3 w-3" />
                  <span>{formatEta(data.etaSeconds)}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Guidance Footer */}
          <div className="flex items-center justify-between border-t border-white/8 pt-2 text-[9.5px] font-bold text-white/40">
            <span className="flex items-center gap-1">
              <Sparkles className="h-3 w-3 text-emerald-400" />
              <span>+{data.untilFull} more can fit</span>
            </span>
            <span className="text-white/30">Region 1 · Farm Realm</span>
          </div>
        </div>
      </div>
    </div>
  );
}
