import { useEffect, useState } from "react";
import { MapPin, Package, Pickaxe, Timer, Weight, Zap } from "lucide-react";
import { cn } from "@/lib/utils";

type FarmStatus = "idle" | "farming" | "full";
type FarmRarity = "common" | "uncommon" | "rare" | "epic";

interface AutofarmData {
  status: FarmStatus;
  label: string;
  image?: string;
  itemWeight: number;
  collected: number;
  weight: number;
  maxWeight: number;
  progress: number;
  zone: string;
  rarity: FarmRarity;
  untilFull: number;
  etaSeconds: number;
}

const DEFAULT_DATA: AutofarmData = {
  status: "idle",
  label: "Bandage",
  image: "",
  itemWeight: 0,
  collected: 0,
  weight: 0,
  maxWeight: 30000,
  progress: 0,
  zone: "Farm Zone",
  rarity: "common",
  untilFull: 0,
  etaSeconds: 0,
};

const PREVIEW_DATA: AutofarmData = {
  status: "farming",
  label: "Orange",
  image: "nui://ox_inventory/web/images/orange.png",
  itemWeight: 100,
  collected: 33,
  weight: 3300,
  maxWeight: 24000,
  progress: 0.16,
  zone: "Orange Grove",
  rarity: "common",
  untilFull: 207,
  etaSeconds: 690,
};

const STATUS_META: Record<FarmStatus, { label: string }> = {
  idle: { label: "Standby" },
  farming: { label: "Farming" },
  full: { label: "Full" },
};

const RARITY_META: Record<FarmRarity, { label: string; color: string; border: string; bg: string }> = {
  common: {
    label: "Common",
    color: "#a8a8b3",
    border: "rgba(168,168,179,0.45)",
    bg: "rgba(168,168,179,0.12)",
  },
  uncommon: {
    label: "Uncommon",
    color: "#3dd68c",
    border: "rgba(61,214,140,0.45)",
    bg: "rgba(61,214,140,0.12)",
  },
  rare: {
    label: "Rare",
    color: "#4da3ff",
    border: "rgba(77,163,255,0.5)",
    bg: "rgba(77,163,255,0.12)",
  },
  epic: {
    label: "Epic",
    color: "#e10600",
    border: "rgba(225,6,0,0.55)",
    bg: "rgba(225,6,0,0.14)",
  },
};

const RING_RADIUS = 38;
const RING_CIRCUMFERENCE = 2 * Math.PI * RING_RADIUS;
const RED = "#e10600";

function formatWeight(grams: number) {
  if (grams >= 1000) {
    return `${(grams / 1000).toLocaleString(undefined, { maximumFractionDigits: 1 })}kg`;
  }
  return `${grams.toLocaleString()}g`;
}

function formatEta(seconds: number) {
  if (seconds <= 0) return "Full";
  if (seconds < 60) return `${seconds}s`;
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m >= 60) {
    const h = Math.floor(m / 60);
    const rm = m % 60;
    return `${h}h ${rm}m`;
  }
  return s > 0 ? `${m}m ${s}s` : `${m}m`;
}

function normalizeRarity(value?: string): FarmRarity {
  const key = (value || "common").toLowerCase() as FarmRarity;
  return RARITY_META[key] ? key : "common";
}

function isBrowserEnv() {
  return (
    !(window as unknown as { invokeNative?: unknown }).invokeNative &&
    !navigator.userAgent.includes("FiveM")
  );
}

export default function AutofarmHud() {
  const [visible, setVisible] = useState(false);
  const [data, setData] = useState<AutofarmData>(DEFAULT_DATA);
  const [imageFailed, setImageFailed] = useState(false);

  useEffect(() => {
    if (isBrowserEnv()) {
      const params = new URLSearchParams(window.location.search);
      const preview = params.get("preview");
      if (preview === "autofarm") {
        setData(PREVIEW_DATA);
        setVisible(true);
      }
    }

    const handleMessage = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg) return;

      if (msg.action === "cfx-keydi-autofarm:show") {
        if (msg.data) {
          setData({
            ...DEFAULT_DATA,
            ...msg.data,
            rarity: normalizeRarity(msg.data.rarity),
          });
        }
        setImageFailed(false);
        setVisible(true);
      } else if (msg.action === "cfx-keydi-autofarm:update") {
        if (msg.data) {
          setData((prev) => ({
            ...prev,
            ...msg.data,
            rarity: normalizeRarity(msg.data.rarity ?? prev.rarity),
          }));
        }
      } else if (msg.action === "cfx-keydi-autofarm:hide") {
        setVisible(false);
      }
    };

    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  useEffect(() => {
    setImageFailed(false);
  }, [data.image]);

  // Smooth preview progress + live forecast in browser
  useEffect(() => {
    if (!visible || data.status !== "farming" || !isBrowserEnv()) return;
    const id = window.setInterval(() => {
      setData((prev) => {
        const nextProg = prev.progress + 0.01;
        const progress = nextProg >= 1 ? 0 : nextProg;
        const itemW = prev.itemWeight || 100;
        const free = Math.max(0, prev.maxWeight - prev.weight);
        // ETA = estimated time until bag/inventory weight is full
        const untilFull = Math.floor(free / itemW);
        const avgPerCycle = 3;
        const cycleSec = 10;
        const cycles = untilFull > 0 ? Math.ceil(untilFull / avgPerCycle) : 0;
        let etaSeconds = 0;
        if (cycles > 0) {
          const remainingThisCycle = Math.max(0, 1 - progress) * cycleSec;
          etaSeconds = Math.max(1, Math.ceil(remainingThisCycle + Math.max(0, cycles - 1) * cycleSec));
        }
        return { ...prev, progress, untilFull, etaSeconds };
      });
    }, 120);
    return () => window.clearInterval(id);
  }, [visible, data.status]);

  if (!visible) return null;

  const status = STATUS_META[data.status] ?? STATUS_META.idle;
  const rarity = RARITY_META[normalizeRarity(data.rarity)];
  const weightPercent = data.maxWeight > 0 ? Math.min((data.weight / data.maxWeight) * 100, 100) : 0;
  const progressPct = Math.round(Math.min(Math.max(data.progress, 0), 1) * 100);
  const cycleOffset = RING_CIRCUMFERENCE * (1 - Math.min(Math.max(data.progress, 0), 1));

  return (
    <div className="fixed left-6 top-[55%] z-[99990] w-[300px] -translate-y-1/2 select-none pointer-events-none animate-autofarm-in font-sans">
      <div
        className="overflow-hidden rounded-2xl border bg-[#101012] shadow-[0_24px_60px_rgba(0,0,0,0.75)]"
        style={{ borderColor: "rgba(225, 6, 0, 0.55)" }}
      >
          {/* Header */}
          <div className="flex items-center gap-2.5 border-b border-[#e10600]/25 px-3.5 py-3">
            <div
              className="flex h-9 w-9 items-center justify-center rounded-lg border bg-black/40"
              style={{ borderColor: "rgba(225, 6, 0, 0.65)" }}
            >
              <Pickaxe className="h-4 w-4 text-white" strokeWidth={2.2} />
            </div>
            <div className="min-w-0 leading-tight">
              <p className="text-[14px] font-black uppercase tracking-[0.08em] text-white">Auto Farm</p>
              <p className="mt-0.5 text-[10px] font-bold uppercase tracking-[0.22em] text-[#e10600]">
                Grim City
              </p>
            </div>
            <div
              className="ml-auto flex items-center gap-1.5 rounded-full border px-2.5 py-1"
              style={{ borderColor: "rgba(225, 6, 0, 0.7)", background: "rgba(225, 6, 0, 0.12)" }}
            >
              <span
                className={cn("h-1.5 w-1.5 rounded-full bg-[#e10600]", data.status === "farming" && "animate-pulse")}
              />
              <span className="text-[10px] font-black uppercase tracking-wider text-[#e10600]">
                {status.label}
              </span>
            </div>
          </div>

          <div className="space-y-3 px-3.5 py-3.5">
            {/* Zone identity */}
            <div className="flex items-center gap-2">
              <div className="flex min-w-0 flex-1 items-center gap-1.5 rounded-lg border border-white/8 bg-[#17171a] px-2.5 py-1.5">
                <MapPin className="h-3.5 w-3.5 shrink-0 text-[#e10600]" />
                <span className="truncate text-[11px] font-bold uppercase tracking-wide text-white/90">
                  {data.zone}
                </span>
              </div>
              <div
                className="shrink-0 rounded-lg border px-2 py-1.5 text-[10px] font-black uppercase tracking-wider"
                style={{ color: rarity.color, borderColor: rarity.border, background: rarity.bg }}
              >
                {rarity.label}
              </div>
            </div>

            {/* Item row */}
            <div className="flex items-center gap-3">
              <div className="relative flex h-[88px] w-[88px] shrink-0 items-center justify-center rounded-xl border border-white/10 bg-[#17171a]">
                <svg className="absolute inset-1 -rotate-90" viewBox="0 0 100 100">
                  <circle
                    cx="50"
                    cy="50"
                    r={RING_RADIUS}
                    fill="none"
                    stroke="rgba(255,255,255,0.08)"
                    strokeWidth="5"
                  />
                  <circle
                    cx="50"
                    cy="50"
                    r={RING_RADIUS}
                    fill="none"
                    stroke={RED}
                    strokeWidth="5"
                    strokeLinecap="round"
                    strokeDasharray={RING_CIRCUMFERENCE}
                    strokeDashoffset={cycleOffset}
                    style={{ transition: "stroke-dashoffset 100ms linear" }}
                  />
                </svg>
                <div className="relative z-10 flex h-14 w-14 items-center justify-center rounded-full bg-black/50">
                  {data.image && !imageFailed ? (
                    <img
                      src={data.image}
                      alt={data.label}
                      onError={() => setImageFailed(true)}
                      className="h-10 w-10 object-contain drop-shadow-md"
                    />
                  ) : (
                    <Package className="h-8 w-8 text-[#e10600]" />
                  )}
                </div>
              </div>

              <div className="min-w-0 flex-1">
                <p className="truncate text-[18px] font-black uppercase tracking-wide text-white">
                  {data.label}
                </p>
                <p className="mt-0.5 text-[11px] font-semibold uppercase tracking-wider text-white/45">
                  {formatWeight(data.itemWeight)} / ea
                </p>
                <div className="mt-2.5 flex items-center justify-between rounded-lg border border-white/8 bg-[#17171a] px-2.5 py-2">
                  <div className="flex items-center gap-1.5">
                    <Package className="h-3.5 w-3.5 text-[#e10600]" />
                    <span className="text-[10px] font-bold uppercase tracking-wider text-white/70">
                      Gathered
                    </span>
                  </div>
                  <span className="text-[14px] font-black text-white">{data.collected}</span>
                </div>
              </div>
            </div>

            {/* Compact forecast: items left + bag-full ETA */}
            <div className="grid grid-cols-2 gap-2">
              <div className="rounded-xl border border-white/8 bg-[#17171a] px-2.5 py-2">
                <p className="text-[9px] font-bold uppercase tracking-wider text-white/45">Until Full</p>
                <p className="mt-1 text-[15px] font-black text-white">
                  {data.untilFull > 0 ? `~${data.untilFull}` : "0"}
                  <span className="ml-1 text-[10px] font-bold uppercase text-white/40">more</span>
                </p>
              </div>
              <div className="rounded-xl border border-white/8 bg-[#17171a] px-2.5 py-2">
                <div className="flex items-center gap-1">
                  <Timer className="h-3 w-3 text-[#e10600]" />
                  <p className="text-[9px] font-bold uppercase tracking-wider text-white/45">Bag Full</p>
                </div>
                <p className="mt-1 text-[15px] font-black text-white">
                  {data.untilFull > 0 || data.etaSeconds > 0 ? formatEta(data.etaSeconds) : "Full"}
                </p>
              </div>
            </div>

            {/* Inventory load */}
            <div className="rounded-xl border border-white/8 bg-[#17171a] px-3 py-2.5">
              <div className="mb-1.5 flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  <Weight className="h-3.5 w-3.5 text-[#e10600]" />
                  <span className="text-[10px] font-bold uppercase tracking-wider text-white">
                    Inventory Load
                  </span>
                </div>
                <span className="text-[12px] font-black text-white">{Math.round(weightPercent)}%</span>
              </div>
              <div className="h-1.5 w-full overflow-hidden rounded-full bg-black/50">
                <div
                  className="h-full rounded-full transition-[width] duration-200"
                  style={{
                    width: `${weightPercent}%`,
                    background: weightPercent >= 100 ? "#ff3b30" : RED,
                  }}
                />
              </div>
              <div className="mt-1.5 flex items-center justify-between text-[10px] font-semibold text-white/40">
                <span>{formatWeight(data.weight)}</span>
                <span>Max: {formatWeight(data.maxWeight)}</span>
              </div>
            </div>

            {/* Extracting */}
            <div
              className="rounded-xl border px-3 py-2.5"
              style={{
                borderColor: data.status === "farming" ? "rgba(225, 6, 0, 0.55)" : "rgba(255,255,255,0.08)",
                background: data.status === "farming" ? "rgba(225, 6, 0, 0.06)" : "#17171a",
              }}
            >
              <div className="mb-1.5 flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  <Zap className="h-3.5 w-3.5 text-[#e10600]" fill={data.status === "farming" ? RED : "none"} />
                  <span className="text-[11px] font-black uppercase tracking-wider text-white">
                    {data.status === "farming"
                      ? "Extracting..."
                      : data.status === "full"
                        ? "Inventory Full"
                        : "Ready"}
                  </span>
                </div>
                <span className="text-[12px] font-black tabular-nums text-[#e10600]">{progressPct}%</span>
              </div>
              <div className="mb-2.5 h-1.5 w-full overflow-hidden rounded-full bg-black/50">
                <div
                  className="h-full rounded-full transition-[width] duration-100 ease-linear"
                  style={{
                    width: `${progressPct}%`,
                    background: RED,
                    boxShadow: data.status === "farming" ? "0 0 10px rgba(225,6,0,0.55)" : undefined,
                  }}
                />
              </div>

              <div className="flex items-center justify-center gap-3 text-[11px] font-bold uppercase tracking-wider text-white/85">
                <span className="flex items-center gap-1.5">
                  <kbd className="rounded-[4px] bg-white px-1.5 py-0.5 text-[10px] font-black text-black">
                    E
                  </kbd>
                  {data.status === "farming" ? "Pause" : "Start"}
                </span>
                <span className="text-white/25">|</span>
                <span className="flex items-center gap-1.5">
                  <kbd className="rounded-[4px] bg-white px-1.5 py-0.5 text-[10px] font-black text-black">
                    X
                  </kbd>
                  Cancel
                </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
