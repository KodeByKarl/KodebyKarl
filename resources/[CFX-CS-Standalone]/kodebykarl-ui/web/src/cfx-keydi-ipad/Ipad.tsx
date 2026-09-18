import React, { Suspense, lazy, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { cn } from "@/lib/utils";
import {
  BatteryFull,
  Signal,
  Wifi,
  Flashlight,
  Camera,
  MessageCircle,
  Wallet,
  Users,
  AppWindow,
  Trophy,
  CircleDollarSign,
  Shield,
  ClipboardList,
  UsersRound,
  Zap,
  GraduationCap,
  Store,
  Tags,
  Ambulance,
  Star,
  Scale,
} from "lucide-react";
import type { UniversityRole } from "./universityTypes";
export type { UniversityRole } from "./universityTypes";

const LeaderboardApp = lazy(() => import("./LeaderboardApp"));
const EconomyApp = lazy(() => import("./EconomyApp"));
const MarketAdminApp = lazy(() => import("./MarketAdminApp"));
const DeptBossApp = lazy(() => import("./DeptBossApp"));
const LeoMdtApp = lazy(() => import("./LeoMdtApp"));
const PartyApp = lazy(() => import("./PartyApp"));
const PvpApp = lazy(() => import("./PvpApp"));
const UniversityPortalApp = lazy(() => import("./UniversityPortalApp"));
const BusinessBossApp = lazy(() => import("./BusinessBossApp"));
const OrganizationApp = lazy(() => import("./OrganizationApp"));

type IpadView = "lock" | "home" | "app";

export interface IpadPlayerData {
  firstName?: string;
  lastName?: string;
  cash?: number;
  bank?: number;
  job?: string;
  gang?: string;
  playtime?: string;
  canEditEconomy?: boolean;
  canPoliceBoss?: boolean;
  canSheriffBoss?: boolean;
  canAmbulanceBoss?: boolean;
  canPambulanceBoss?: boolean;
  canSambulanceBoss?: boolean;
  canDojBoss?: boolean;
  canPoliceMdt?: boolean;
  canSheriffMdt?: boolean;
  canBusinessBoss?: boolean;
  canOrgBoss?: boolean;
  /** University portal role — visitor if unset */
  universityRole?: UniversityRole;
}

interface IpadProps {
  visible: boolean;
  data?: IpadPlayerData | null;
  onClose?: () => void;
}

type AppDef = {
  id: string;
  label: string;
  icon: React.ComponentType<{ className?: string; strokeWidth?: number; fill?: string }>;
  /** Solid flat tile color — Grim phone style */
  color: string;
};

const APPS: AppDef[] = [
  { id: "wallet", label: "Wallet", icon: Wallet, color: "#1c1c1e" },
  { id: "grim", label: "Grim City", icon: AppWindow, color: "#8b0000" },
  { id: "leaderboard", label: "Leaderboards", icon: Trophy, color: "#e10600" },
  { id: "economy", label: "Economy", icon: CircleDollarSign, color: "#2e7d32" },
  { id: "market", label: "Market", icon: Tags, color: "#c99212" },
  { id: "policemdt", label: "Police MDT", icon: ClipboardList, color: "#1e3a8a" },
  { id: "sheriffmdt", label: "Sheriff MDT", icon: ClipboardList, color: "#92400e" },
  { id: "party", label: "Squad", icon: UsersRound, color: "#8b0000" },
  { id: "pvp", label: "PvP", icon: Zap, color: "#f97316" },
  { id: "university", label: "ULS Portal", icon: GraduationCap, color: "#9a7b4f" },
];

const HOME_APPS = ["university", "party", "pvp", "leaderboard"] as const;
const HOME_APPS_OWNER = ["economy", "market"] as const;
const HOME_APPS_POLICE_MDT = ["policemdt"] as const;
const HOME_APPS_SHERIFF_MDT = ["sheriffmdt"] as const;
const DOCK = ["party", "pvp", "leaderboard", "grim"] as const;

async function fetchNui(event: string, data: Record<string, unknown> = {}) {
  const isBrowser = !(window as unknown as { invokeNative?: unknown }).invokeNative
    && !navigator.userAgent.includes("FiveM");
  if (isBrowser) return;
  const resourceName = (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName
    ? (window as unknown as { GetParentResourceName: () => string }).GetParentResourceName()
    : "kodebykarl-ui";
  await fetch(`https://${resourceName}/${event}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(data),
  }).catch(() => {});
}

function useClock(enabled = true) {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    if (!enabled) return;
    const id = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(id);
  }, [enabled]);
  return now;
}

const ISLAND_NOTIF_INTERVAL_MS = 30 * 60 * 1000; // every 30 minutes
const ISLAND_NOTIF_VISIBLE_MS = 7000;

function DynamicIsland({ active }: { active: boolean }) {
  const [showNotif, setShowNotif] = useState(false);

  useEffect(() => {
    if (!active) {
      setShowNotif(false);
      return;
    }

    let hideTimer: number | undefined;
    const show = () => {
      setShowNotif(true);
      window.clearTimeout(hideTimer);
      hideTimer = window.setTimeout(() => setShowNotif(false), ISLAND_NOTIF_VISIBLE_MS);
    };

    // Keydi.dev message appears every 30 minutes (not static)
    const repeat = window.setInterval(show, ISLAND_NOTIF_INTERVAL_MS);

    return () => {
      window.clearInterval(repeat);
      window.clearTimeout(hideTimer);
    };
  }, [active]);

  return (
    <div className="pointer-events-none absolute left-1/2 top-[10px] z-50 -translate-x-1/2">
      <div
        className={cn(
          "relative flex items-center overflow-hidden bg-black shadow-[inset_0_0_0_1px_rgba(255,255,255,0.08)] transition-all duration-500 ease-[cubic-bezier(0.32,0.72,0,1)]",
          showNotif
            ? "h-[52px] w-[320px] gap-2.5 rounded-[28px] pl-2.5 pr-11"
            : "h-[30px] w-[126px] justify-center rounded-[20px]",
        )}
        style={showNotif ? { animation: "islandPulse 3.2s ease-in-out infinite" } : undefined}
      >
        {showNotif && (
          <>
            <div className="relative flex h-[36px] w-[36px] shrink-0 items-center justify-center rounded-full bg-gradient-to-b from-[#64d2ff] to-[#007aff] shadow-sm">
              <MessageCircle className="h-[18px] w-[18px] text-white" strokeWidth={2.4} fill="white" fillOpacity={0.15} />
              <span className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-[#ff3b30] ring-2 ring-black" />
            </div>
            <div className="min-w-0 flex-1 leading-tight">
              <div className="flex items-center justify-between gap-2">
                <p className="truncate text-[13px] font-semibold tracking-tight text-white">Keydi.dev</p>
                <span className="shrink-0 text-[10px] font-medium text-white/45">now</span>
              </div>
              <p className="truncate text-[11px] font-medium text-white/55">
                Message · Built by Keydi.dev for Grim City
              </p>
            </div>
          </>
        )}

        {/* Camera lens */}
        <div
          className={cn(
            "absolute top-1/2 -translate-y-1/2 rounded-full bg-[#0a1a12] ring-1 ring-[#1a3d2a]",
            showNotif ? "right-[14px] h-[9px] w-[9px] opacity-40" : "right-[18px] h-[10px] w-[10px]",
          )}
        >
          <div className="absolute inset-[2px] rounded-full bg-[#0d2818]" />
          {!showNotif && (
            <div className="absolute left-[2px] top-[2px] h-[2px] w-[2px] rounded-full bg-[#2ee59d]/50" />
          )}
        </div>
      </div>
    </div>
  );
}

function StatusBar({ light }: { light?: boolean }) {
  const now = useClock();
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  return (
    <div
      className={cn(
        "relative z-40 flex items-center justify-between px-7 pt-[18px] text-[12px] font-semibold tracking-tight",
        light ? "text-white" : "text-black",
      )}
    >
      <span className="min-w-[54px]">{time}</span>
      <div className="flex items-center gap-1.5 opacity-90">
        <Signal className="h-3.5 w-3.5" strokeWidth={2.4} />
        <Wifi className="h-3.5 w-3.5" strokeWidth={2.4} />
        <BatteryFull className="h-4 w-4" strokeWidth={2.2} />
      </div>
    </div>
  );
}

function LockScreen({ onUnlock, player }: { onUnlock: () => void; player?: IpadPlayerData | null }) {
  const now = useClock();
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const date = now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });
  const name = [player?.firstName, player?.lastName].filter(Boolean).join(" ") || "Player";

  const dragY = useRef(0);
  const startY = useRef<number | null>(null);
  const [offset, setOffset] = useState(0);
  const [unlocking, setUnlocking] = useState(false);
  const [dragging, setDragging] = useState(false);

  const finishUnlock = useCallback(() => {
    setUnlocking(true);
    setDragging(false);
    setOffset(-140);
    window.setTimeout(() => onUnlock(), 240);
  }, [onUnlock]);

  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    startY.current = e.clientY;
    dragY.current = 0;
    setDragging(true);
  };

  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (startY.current == null || unlocking) return;
    const dy = e.clientY - startY.current;
    const up = Math.min(0, dy);
    dragY.current = up;
    setOffset(up);
  };

  const onPointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    if (startY.current == null) return;
    try {
      e.currentTarget.releasePointerCapture(e.pointerId);
    } catch {
      /* already released */
    }
    const upDistance = Math.abs(dragY.current);
    startY.current = null;
    setDragging(false);
    if (upDistance >= 64) {
      finishUnlock();
    } else {
      setOffset(0);
    }
  };

  return (
    <div
      className="absolute inset-0 flex touch-none flex-col select-none"
      style={{
        background:
          "linear-gradient(180deg, #2a3f6e 0%, #4a3a6e 32%, #8f4e72 62%, #d4a07a 100%)",
        transform: `translateY(${offset}px)`,
        opacity: unlocking ? 0 : Math.max(0.35, 1 + offset / 280),
        transition: dragging ? "none" : "transform 220ms ease, opacity 220ms ease",
      }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
    >
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_50%_0%,rgba(255,255,255,0.22),transparent_50%)]" />
      <StatusBar light />

      {/* Classic iPad lock: date + clock centered under Dynamic Island */}
      <div className="relative z-10 flex flex-1 flex-col items-center px-8 pt-14">
        <p className="text-[22px] font-medium tracking-[0.01em] text-white drop-shadow-sm">
          {date}
        </p>
        <p className="mt-1 text-[118px] font-thin leading-none tracking-[-0.045em] text-white drop-shadow-[0_4px_24px_rgba(0,0,0,0.25)]">
          {time}
        </p>

        {/* Notification stack — below clock, centered like iPadOS */}
        <div className="mt-10 flex w-full max-w-[420px] flex-col gap-2.5">
          <div className="flex items-start gap-3 rounded-[22px] bg-white/18 px-4 py-3.5 shadow-[0_8px_32px_rgba(0,0,0,0.12)] backdrop-blur-2xl">
            <div className="mt-0.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-[10px] bg-gradient-to-b from-[#64d2ff] to-[#007aff]">
              <MessageCircle className="h-5 w-5 text-white" strokeWidth={2.2} />
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-baseline justify-between gap-2">
                <p className="truncate text-[14px] font-semibold text-white">Keydi.dev</p>
                <span className="shrink-0 text-[12px] text-white/55">now</span>
              </div>
              <p className="mt-0.5 text-[13px] leading-snug text-white/80">
                Welcome back, {name}. Built for Grim City.
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3 rounded-[22px] bg-white/14 px-4 py-3.5 shadow-[0_8px_32px_rgba(0,0,0,0.1)] backdrop-blur-2xl">
            <div className="mt-0.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-[10px] bg-gradient-to-b from-[#ff3b30] to-[#8b0000]">
              <AppWindow className="h-5 w-5 text-white" strokeWidth={2.2} />
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-baseline justify-between gap-2">
                <p className="truncate text-[14px] font-semibold text-white">Grim City</p>
                <span className="shrink-0 text-[12px] text-white/55">1m ago</span>
              </div>
              <p className="mt-0.5 text-[13px] leading-snug text-white/80">
                Server online · Swipe up to unlock your iPad.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom controls — flashlight / unlock hint / camera */}
      <div className="relative z-10 mb-9 flex items-end justify-between px-16">
        <button
          type="button"
          className="flex h-[58px] w-[58px] items-center justify-center rounded-full bg-black/28 text-white backdrop-blur-xl"
          onPointerDown={(e) => e.stopPropagation()}
        >
          <Flashlight className="h-[22px] w-[22px]" strokeWidth={1.8} />
        </button>
        <div className="flex flex-col items-center gap-2.5 pb-1">
          <p className="text-[13px] font-medium tracking-wide text-white/80">Swipe up to unlock</p>
        </div>
        <button
          type="button"
          className="flex h-[58px] w-[58px] items-center justify-center rounded-full bg-black/28 text-white backdrop-blur-xl"
          onPointerDown={(e) => e.stopPropagation()}
        >
          <Camera className="h-[22px] w-[22px]" strokeWidth={1.8} />
        </button>
      </div>
    </div>
  );
}

function HomeScreen({
  player,
  onOpenApp,
}: {
  player?: IpadPlayerData | null;
  onOpenApp: (id: string) => void;
}) {
  const appMap = useMemo(() => Object.fromEntries(APPS.map((a) => [a.id, a])), []);
  const name = [player?.firstName, player?.lastName].filter(Boolean).join(" ") || "Citizen";
  const homeApps = useMemo(() => {
    // Public citizen apps only — restricted icons never listed unless session grants access
    const apps: string[] = [...HOME_APPS];
    if (player?.canPoliceMdt) apps.unshift(...HOME_APPS_POLICE_MDT);
    if (player?.canSheriffMdt) apps.unshift(...HOME_APPS_SHERIFF_MDT);
    if (player?.canEditEconomy) apps.unshift(...HOME_APPS_OWNER);
    return apps;
  }, [
    player?.canEditEconomy,
    player?.canPoliceMdt,
    player?.canSheriffMdt,
  ]);

  return (
    <div
      className="absolute inset-0 flex flex-col select-none"
      style={{
        background:
          "linear-gradient(180deg, #5b7cfa 0%, #7a8ff5 28%, #c4a0e8 62%, #f0c4b8 100%)",
      }}
    >
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(255,255,255,0.35),transparent_40%)]" />
      <StatusBar light />

      {/* Compact widgets — Wallet / Profile / Grim only */}
      <div className="relative z-10 flex shrink-0 flex-col gap-3 px-10 pt-5">
        <div className="grid grid-cols-12 gap-3">
          <button
            type="button"
            className="col-span-4 flex h-[112px] flex-col justify-between rounded-[22px] bg-black/55 px-4 py-3.5 text-left text-white shadow-[0_10px_28px_rgba(0,0,0,0.16)] backdrop-blur-xl transition-transform active:scale-[0.99]"
            onClick={() => onOpenApp("wallet")}
          >
            <div className="flex items-center justify-between">
              <p className="text-[12px] font-semibold text-white/70">Wallet</p>
              <Wallet className="h-4 w-4 text-white/80" />
            </div>
            <div>
              <p className="text-[22px] font-semibold tracking-tight leading-none">
                ${(player?.bank ?? 0).toLocaleString()}
              </p>
              <p className="mt-1.5 text-[12px] text-white/65">
                Cash ${(player?.cash ?? 0).toLocaleString()}
              </p>
            </div>
          </button>

          <div className="col-span-4 flex h-[112px] flex-col justify-between rounded-[22px] bg-black/45 px-4 py-3.5 text-left text-white shadow-[0_10px_28px_rgba(0,0,0,0.14)] backdrop-blur-xl">
            <div className="flex items-center justify-between">
              <p className="text-[12px] font-semibold text-white/70">Profile</p>
              <Users className="h-4 w-4 text-white/80" />
            </div>
            <div>
              <p className="text-[17px] font-semibold tracking-tight leading-tight">{name}</p>
              <p className="mt-1 text-[12px] text-white/65">Job · {player?.job || "Unemployed"}</p>
              <p className="text-[12px] text-white/65">Gang · {player?.gang || "None"}</p>
            </div>
          </div>

          <div className="col-span-4 flex h-[112px] flex-col justify-between rounded-[22px] bg-gradient-to-br from-[#1c1c1e] to-[#000000] px-4 py-3.5 text-white shadow-[0_10px_28px_rgba(0,0,0,0.2)]">
            <div className="flex items-center justify-between">
              <p className="text-[12px] font-semibold text-white/70">Grim City</p>
              <AppWindow className="h-4 w-4 text-white/80" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-[#30d158]" />
                <span className="text-[13px] text-white/85">Online</span>
              </div>
              <button
                type="button"
                className="mt-2 rounded-full bg-white/15 px-3 py-1.5 text-[12px] font-semibold text-white backdrop-blur-md transition-colors hover:bg-white/25"
                onClick={() => onOpenApp("grim")}
              >
                Open Grim
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Citizen apps — Party / PvP / Leaderboards (+ staff apps when granted) */}
      <div className="relative z-10 px-10 pt-2">
        <div className="flex flex-wrap items-start justify-center gap-x-8 gap-y-5">
          {homeApps.map((id) => {
            const app = appMap[id];
            if (!app) return null;
            return (
              <button
                key={id}
                type="button"
                className="flex w-[72px] flex-col items-center gap-1.5 transition-transform active:scale-95"
                onClick={() => onOpenApp(id)}
              >
                <div
                  className="flex h-[62px] w-[62px] items-center justify-center rounded-[16px] text-white shadow-[0_8px_20px_rgba(0,0,0,0.28)]"
                  style={{ backgroundColor: app.color }}
                >
                  <app.icon
                    className="h-[30px] w-[30px]"
                    strokeWidth={id === "leaderboard" ? 2.2 : 1.9}
                    fill={id === "leaderboard" ? "white" : "none"}
                  />
                </div>
                <span className="w-full truncate text-center text-[11px] font-medium leading-tight text-white drop-shadow-sm">
                  {app.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Empty wallpaper space under apps */}
      <div className="relative z-0 min-h-0 flex-1" />

      {/* Dock hugs icons — equal gaps, no giant empty sides */}
      <div className="relative z-10 mx-auto mb-7 w-fit">
        <div className="flex items-center gap-5 rounded-[28px] border border-white/35 bg-white/28 px-4 py-3 shadow-[0_16px_40px_rgba(0,0,0,0.18)] backdrop-blur-2xl">
          {DOCK.map((id) => {
            const app = appMap[id];
            if (!app) return null;
            return (
              <button
                key={id}
                type="button"
                className="flex h-[54px] w-[54px] shrink-0 items-center justify-center rounded-[14px] text-white shadow-md transition-transform active:scale-90"
                style={{ backgroundColor: app.color }}
                onClick={() => onOpenApp(id)}
                title={app.label}
              >
                <app.icon className="h-[25px] w-[25px]" strokeWidth={1.8} />
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function AppScreen({
  appId,
  player,
}: {
  appId: string;
  player?: IpadPlayerData | null;
}) {
  const fallback = (
    <div className="absolute inset-0 flex items-center justify-center bg-black/40 text-[13px] text-white/50">
      Loading…
    </div>
  );

  if (appId === "leaderboard") {
    return (
      <Suspense fallback={fallback}>
        <LeaderboardApp player={player} />
      </Suspense>
    );
  }
  if (appId === "economy") {
    if (!player?.canEditEconomy) return null;
    return (
      <Suspense fallback={fallback}>
        <EconomyApp player={player} />
      </Suspense>
    );
  }
  if (appId === "market") {
    if (!player?.canEditEconomy) return null;
    return (
      <Suspense fallback={fallback}>
        <MarketAdminApp player={player} />
      </Suspense>
    );
  }
  if (appId === "policemdt") {
    if (!player?.canPoliceMdt) return null;
    return (
      <Suspense fallback={fallback}>
        <LeoMdtApp player={player} department="police" />
      </Suspense>
    );
  }
  if (appId === "sheriffmdt") {
    if (!player?.canSheriffMdt) return null;
    return (
      <Suspense fallback={fallback}>
        <LeoMdtApp player={player} department="sheriff" />
      </Suspense>
    );
  }
  if (appId === "party") {
    return (
      <Suspense fallback={fallback}>
        <PartyApp player={player} />
      </Suspense>
    );
  }
  if (appId === "pvp") {
    return (
      <Suspense fallback={fallback}>
        <PvpApp player={player} />
      </Suspense>
    );
  }
  if (appId === "university") {
    return (
      <Suspense fallback={fallback}>
        <UniversityPortalApp player={player} />
      </Suspense>
    );
  }

  const app = APPS.find((a) => a.id === appId) || APPS[APPS.length - 1];
  const Icon = app.icon;

  return (
    <div className="absolute inset-0 flex flex-col bg-[#f2f2f7] select-none">
      <StatusBar />
      <div className="border-b border-black/5 bg-[#f2f2f7]/95 px-3 pb-2 pt-3">
        <p className="text-center text-[16px] font-semibold text-black">{app.label}</p>
      </div>

      <div className="flex flex-1 flex-col items-center justify-center gap-4 px-8 text-center">
        <div
          className="flex h-20 w-20 items-center justify-center rounded-[22px] text-white shadow-lg"
          style={{ backgroundColor: app.color }}
        >
          <Icon className="h-10 w-10" strokeWidth={1.6} />
        </div>
        <div>
          <h2 className="text-[22px] font-semibold text-[#1c1c1e]">{app.label}</h2>
          <p className="mt-2 max-w-[280px] text-[14px] leading-relaxed text-[#8e8e93]">
            App shell ready. Wire gameplay features here later.
          </p>
        </div>
        {app.id === "grim" && (
          <div className="mt-2 w-full max-w-[300px] rounded-2xl bg-white p-4 text-left shadow-sm">
            <p className="text-[13px] text-[#8e8e93]">Signed in</p>
            <p className="text-[16px] font-semibold text-[#1c1c1e]">
              {[player?.firstName, player?.lastName].filter(Boolean).join(" ") || "Citizen"}
            </p>
            <p className="mt-2 text-[13px] text-[#8e8e93]">
              Job: {player?.job || "Unemployed"} · Gang: {player?.gang || "None"}
            </p>
          </div>
        )}
        {app.id === "wallet" && (
          <div className="w-full max-w-[300px] space-y-2">
            <div className="rounded-2xl bg-gradient-to-br from-[#1c1c1e] to-black p-4 text-left text-white shadow-md">
              <p className="text-[12px] text-white/60">Bank</p>
              <p className="text-[28px] font-semibold">${(player?.bank ?? 0).toLocaleString()}</p>
            </div>
            <div className="rounded-2xl bg-white p-4 text-left shadow-sm">
              <p className="text-[12px] text-[#8e8e93]">Cash</p>
              <p className="text-[22px] font-semibold text-[#1c1c1e]">${(player?.cash ?? 0).toLocaleString()}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default function Ipad({ visible, data, onClose }: IpadProps) {
  const [view, setView] = useState<IpadView>("lock");
  const [activeApp, setActiveApp] = useState<string | null>(null);

  useEffect(() => {
    if (!visible) {
      setView("lock");
      setActiveApp(null);
    }
  }, [visible]);

  const close = useCallback(() => {
    fetchNui("cfx-keydi-ipad:close");
    onClose?.();
  }, [onClose]);

  useEffect(() => {
    if (!visible) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        if (view === "app") {
          setView("home");
          setActiveApp(null);
        } else if (view === "home") {
          setView("lock");
        } else {
          close();
        }
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [visible, view, close]);

  if (!visible) return null;

  return (
    <div className="fixed inset-0 z-[100000] flex items-center justify-center bg-black/45 backdrop-blur-[2px]">
      {/* iPad Pro 13" landscape chassis */}
      <div
        className="relative animate-[ipadIn_420ms_cubic-bezier(0.32,0.72,0,1)]"
        style={{
          width: "min(1180px, 96vw)",
          aspectRatio: "4 / 3",
          maxHeight: "94vh",
          height: "auto",
          fontFamily:
            '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Segoe UI", sans-serif',
        }}
      >
        {/* Outer Space Black / graphite Pro shell */}
        <div
          className="absolute inset-0 rounded-[36px]"
          style={{
            background:
              "linear-gradient(145deg, #5c5c60 0%, #2c2c2e 16%, #111113 48%, #1c1c1e 78%, #4a4a4c 100%)",
            boxShadow:
              "0 50px 100px rgba(0,0,0,0.6), inset 0 1px 1px rgba(255,255,255,0.28), inset 0 -1px 2px rgba(0,0,0,0.65)",
          }}
        />
        {/* Side buttons */}
        <div className="absolute -left-[3px] top-[120px] h-[32px] w-[3px] rounded-l-sm bg-[#3a3a3c]" />
        <div className="absolute -left-[3px] top-[170px] h-[64px] w-[3px] rounded-l-sm bg-[#3a3a3c]" />
        <div className="absolute -left-[3px] top-[250px] h-[64px] w-[3px] rounded-l-sm bg-[#3a3a3c]" />
        <div className="absolute -right-[3px] top-[190px] h-[100px] w-[3px] rounded-r-sm bg-[#3a3a3c]" />

        {/* Ultra-thin Pro bezel */}
        <div className="absolute inset-[7px] overflow-hidden rounded-[30px] bg-black shadow-[inset_0_0_0_1.5px_#0a0a0a]">
          <DynamicIsland active={visible} />

          {view === "lock" && <LockScreen player={data} onUnlock={() => setView("home")} />}
          {view === "home" && (
            <HomeScreen
              player={data}
              onOpenApp={(id) => {
                setActiveApp(id);
                setView("app");
              }}
            />
          )}
          {view === "app" && activeApp && (
            <AppScreen
              appId={activeApp}
              player={data}
            />
          )}

          {/* Home indicator — tap to go back (app → home → lock) */}
          <button
            type="button"
            aria-label="Back"
            className="absolute bottom-0 left-1/2 z-50 flex h-8 w-[180px] -translate-x-1/2 items-end justify-center pb-2.5"
            onClick={() => {
              if (view === "app") {
                setActiveApp(null);
                setView("home");
              } else if (view === "home") {
                setView("lock");
              }
            }}
          >
            <span className="h-[5px] w-[140px] rounded-full bg-white/80 mix-blend-difference" />
          </button>
        </div>
      </div>

      <style>{`
        @keyframes ipadIn {
          from { opacity: 0; transform: translateY(18px) scale(0.96); }
          to { opacity: 1; transform: translateY(0) scale(1); }
        }
        @keyframes islandPulse {
          0%, 100% { transform: scale(1); box-shadow: inset 0 0 0 1px rgba(255,255,255,0.08), 0 8px 24px rgba(0,0,0,0.35); }
          50% { transform: scale(1.015); box-shadow: inset 0 0 0 1px rgba(255,255,255,0.14), 0 10px 28px rgba(0,122,255,0.22); }
        }
      `}</style>
    </div>
  );
}
