import { useEffect, useMemo, useState, type CSSProperties } from "react";
import {
  Activity,
  BarChart3,
  Crosshair,
  PersonStanding,
  Skull,
  User,
  Wifi,
  Zap,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { fetchNui, isBrowserEnv } from "@/lib/nui";
import BodySilhouette from "./BodySilhouette";
import type { BodyHits, BodyZone } from "./types";

/** Keydi client payload shape (keep function / data contract). */
export interface DeathScreenKiller {
  name: string;
  id: number;
  ping: number;
  avatarUrl?: string;
  playTime: string;
  rank: string;
  kills: number;
  kd: string;
  health: number;
  armor: number;
  achievements?: string[];
  badges?: string[];
}

export interface DeathScreenRecentKill {
  name: string;
  time?: string;
  id?: number;
}

export interface DeathScreenCombat {
  weapon?: string;
  fatalWeapon?: string;
  streak?: number;
  killStreak?: number;
  distance: number;
  damageDealt: number;
  damageReceived: number;
  damageOutPercent?: number;
  damageInPercent?: number;
  damageOutPct?: number;
  damageInPct?: number;
  headshot?: boolean;
  hitZones?: {
    head?: number;
    neck?: number;
    torso?: number;
    arm?: number;
    leg?: number;
    arms?: number;
    legs?: number;
  };
  bodyHits?: BodyHits;
  totalHits?: number;
  recentKills?: DeathScreenRecentKill[];
}

export interface DeathScreenData {
  brand?: string;
  brandUrl?: string;
  subtitle?: string;
  killer: DeathScreenKiller;
  combat: DeathScreenCombat;
  recentEliminations?: DeathScreenRecentKill[];
}

interface DeathScreenProps {
  data?: Partial<DeathScreenData> | null;
  onClose?: () => void;
}

const ZONE_LABELS: { key: BodyZone; label: string }[] = [
  { key: "head", label: "HEAD" },
  { key: "neck", label: "NECK" },
  { key: "torso", label: "TORSO" },
  { key: "arms", label: "ARMS" },
  { key: "legs", label: "LEGS" },
];

const panelShell: CSSProperties = {
  // Solid fills only — FiveM CEF breaks backdrop-blur / low-alpha panels
  backgroundColor: "rgba(14, 12, 16, 0.97)",
  borderColor: "rgba(255, 58, 58, 0.85)",
  boxShadow: "0 14px 40px rgba(0, 0, 0, 0.88), 0 0 22px rgba(255, 58, 58, 0.1)",
};

function StatBox({
  label,
  value,
  tone,
}: {
  label: string;
  value: string | number;
  tone?: "default" | "green" | "red";
}) {
  return (
    <div
      className={cn(
        "rounded-xl border border-[#ff3a3a]/50 px-2.5 py-2.5",
        tone === "green" && "border-emerald-500/50",
        tone === "red" && "border-red-500/55"
      )}
      style={{
        backgroundColor:
          tone === "green"
            ? "rgba(6, 46, 30, 0.95)"
            : tone === "red"
              ? "rgba(55, 10, 14, 0.95)"
              : "rgba(10, 10, 12, 0.96)",
      }}
    >
      <p className="text-[9px] font-bold uppercase tracking-[0.16em] text-[#ff4d4d]">{label}</p>
      <p className="mt-1 text-[15px] font-black uppercase tracking-wide text-white">{value}</p>
    </div>
  );
}

function Meter({ label, value, fillClass }: { label: string; value: number; fillClass: string }) {
  const pct = Math.max(0, Math.min(100, value));
  return (
    <div>
      <div className="mb-1 flex items-center justify-between">
        <span className="text-[9px] font-bold uppercase tracking-[0.16em] text-[#ff4d4d]">{label}</span>
        <span className="text-[10px] font-black text-white">{pct}%</span>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-white/10">
        <div className={cn("h-full rounded-full transition-all", fillClass)} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

function closeDeathUi(onClose?: () => void) {
  onClose?.();
  // Keydi client callback
  fetchNui("closeDeathScreen", {});
}

function normalizeHits(combat: DeathScreenCombat): BodyHits {
  if (combat.bodyHits) return combat.bodyHits;
  const z = combat.hitZones || {};
  return {
    head: z.head || 0,
    neck: z.neck || 0,
    torso: z.torso || 0,
    arms: z.arms ?? z.arm ?? 0,
    legs: z.legs ?? z.leg ?? 0,
  };
}

export default function DeathScreen({ data, onClose }: DeathScreenProps) {
  if (!data?.killer || !data?.combat) return null;

  const [anatomy, setAnatomy] = useState(false);

  const killer = data.killer;
  const combat = data.combat;
  const brand = data.brand || "GRIM CITY";
  const brandUrl = data.brandUrl || "grim.city";
  const subtitle = data.subtitle || "DEATH RECAP";

  const fatalWeapon = combat.fatalWeapon || combat.weapon || "Unknown";
  const killStreak = combat.killStreak ?? combat.streak ?? 0;
  const outPct = combat.damageOutPct ?? combat.damageOutPercent ?? 0;
  const inPct = combat.damageInPct ?? combat.damageInPercent ?? 100;
  const hits = normalizeHits(combat);
  const badges = killer.badges || killer.achievements || [];
  const recent =
    data.recentEliminations ||
    combat.recentKills ||
    [];

  const totalHits = useMemo(
    () => combat.totalHits || ZONE_LABELS.reduce((n, z) => n + (hits[z.key] || 0), 0),
    [combat.totalHits, hits]
  );

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") closeDeathUi(onClose);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div className="pointer-events-auto fixed inset-0 z-[99940] flex items-center justify-center bg-transparent px-4 py-6 font-sans select-none">
      <div className="relative flex h-[min(640px,86vh)] w-full max-w-[1180px] items-stretch gap-4">
        {/* LEFT — Killer Profile */}
        <aside
          className="flex w-[300px] shrink-0 flex-col overflow-hidden rounded-2xl border-2"
          style={panelShell}
        >
          <div className="flex items-start justify-between px-4 pt-4">
            <div>
              <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#ff3a3a]">
                Eliminated By
              </p>
              <h2 className="mt-0.5 text-[22px] font-black uppercase leading-none tracking-wide text-white">
                Killer Profile
              </h2>
            </div>
            <div className="flex h-9 w-9 items-center justify-center rounded-full border border-[#ff3a3a]/60 bg-[#ff3a3a]/15">
              <Skull className="h-4 w-4 text-[#ff4d4d]" />
            </div>
          </div>

          <div className="mt-4 flex flex-1 flex-col gap-3 overflow-y-auto px-4 pb-3 custom-scrollbar">
            <div
              className="flex items-center gap-3 rounded-xl border border-[#ff3a3a]/50 px-3 py-2.5"
              style={{ backgroundColor: "rgba(10, 10, 12, 0.96)" }}
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-full border border-[#ff3a3a]/50 bg-[#ff3a3a]/15">
                <User className="h-5 w-5 text-[#ff8080]" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-[15px] font-black uppercase tracking-wide text-white">
                  {killer.name}
                </p>
                <div className="mt-1 flex items-center gap-1.5">
                  <span className="rounded-md border border-[#ff3a3a]/50 bg-[#ff3a3a]/20 px-1.5 py-0.5 text-[9px] font-black text-[#ffb0b0]">
                    ID {killer.id}
                  </span>
                  <span className="inline-flex items-center gap-1 rounded-md border border-white/10 bg-black/40 px-1.5 py-0.5 text-[9px] font-bold text-[#c8c0c4]">
                    <Wifi className="h-2.5 w-2.5 text-[#ff4d4d]" />
                    {killer.ping}ms
                  </span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <StatBox label="Play Time" value={killer.playTime || "—"} />
              <StatBox label="Rank" value={killer.rank || "—"} />
              <StatBox label="Kills" value={killer.kills} />
              <StatBox label="K/D" value={killer.kd} tone="green" />
            </div>

            <div
              className="space-y-2.5 rounded-xl border border-[#ff3a3a]/40 px-3 py-3"
              style={{ backgroundColor: "rgba(10, 10, 12, 0.96)" }}
            >
              <Meter label="Health" value={killer.health} fillClass="bg-[#ff3a3a]" />
              <Meter label="Armor" value={killer.armor} fillClass="bg-slate-300" />
            </div>

            <div>
              <p className="mb-1.5 text-[9px] font-bold uppercase tracking-[0.18em] text-[#ff4d4d]">
                Achievements
              </p>
              <div
                className="rounded-xl border border-dashed border-white/20 px-3 py-4 text-center text-[11px] text-[#8a8086]"
                style={{ backgroundColor: "rgba(8, 8, 10, 0.96)" }}
              >
                {badges.length > 0 ? badges.join(" · ") : "No badges unlocked"}
              </div>
            </div>
          </div>

          <div className="mt-auto flex items-center justify-between border-t border-[#ff3a3a]/25 px-4 py-2.5 text-[10px] text-[#8a8086]">
            <span className="inline-flex items-center gap-1.5">
              <Zap className="h-3 w-3 text-[#ff4d4d]" />
              You were eliminated
            </span>
            <span className="font-semibold tracking-wide">{brandUrl}</span>
          </div>
        </aside>

        {/* CENTER — transparent killer preview cutout */}
        <div className="relative flex min-w-0 flex-1 flex-col items-center justify-between py-1">
          <div className="rounded-full border border-[#ff3a3a] bg-[#ff3a3a]/90 px-4 py-1 text-[10px] font-black uppercase tracking-[0.22em] text-white shadow-[0_0_20px_rgba(255,58,58,0.45)]">
            Killer Preview
          </div>
          <div className="pointer-events-none flex flex-1 items-center justify-center">
            {isBrowserEnv() && (
              <div className="flex h-[420px] w-[220px] flex-col items-center justify-end rounded-[40%] bg-gradient-to-b from-[#2a2428]/40 via-[#1a1618]/20 to-transparent">
                <div className="mb-6 h-16 w-16 rounded-full bg-[#c4b8b0]/35 ring-2 ring-white/10" />
                <div className="h-40 w-28 rounded-t-[28px] bg-[#d8d0c8]/30 ring-1 ring-white/10" />
                <div className="flex gap-3">
                  <div className="h-36 w-10 rounded-b-xl bg-[#3b5c9a]/45" />
                  <div className="h-36 w-10 rounded-b-xl bg-[#3b5c9a]/45" />
                </div>
              </div>
            )}
          </div>
          <div className="pb-2 text-center">
            <p className="text-[28px] font-black uppercase tracking-[0.12em] text-white drop-shadow-[0_2px_12px_rgba(0,0,0,0.8)]">
              {brand}
            </p>
            <p className="text-[11px] font-bold uppercase tracking-[0.28em] text-white/55">
              {subtitle}
            </p>
            <button
              type="button"
              onClick={() => closeDeathUi(onClose)}
              className="mt-3 cursor-pointer rounded-lg border border-white/20 bg-black/50 px-3 py-1 text-[9px] font-bold uppercase tracking-wider text-white/80 transition hover:border-[#ff3a3a] hover:text-white"
            >
              Close · Esc
            </button>
          </div>
        </div>

        {/* RIGHT — Combat Recap / Anatomy */}
        <aside
          className="flex w-[300px] shrink-0 flex-col overflow-hidden rounded-2xl border-2"
          style={panelShell}
        >
          <div className="flex items-start justify-between px-4 pt-4">
            <div>
              <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#ff3a3a]">
                Last Engagement
              </p>
              <h2 className="mt-0.5 text-[22px] font-black uppercase leading-none tracking-wide text-white">
                Combat Recap
              </h2>
            </div>
            <button
              type="button"
              onClick={() => setAnatomy((v) => !v)}
              className="inline-flex cursor-pointer items-center gap-1.5 rounded-full border border-[#ff3a3a]/60 bg-black/50 px-2.5 py-1 text-[9px] font-black uppercase tracking-wider text-[#ff8080] transition hover:border-[#ff3a3a] hover:text-white"
            >
              <PersonStanding className="h-3.5 w-3.5" />
              {anatomy ? "Hide Body" : "Anatomy"}
            </button>
          </div>

          <div className="mt-4 flex flex-1 flex-col gap-3 overflow-y-auto px-4 pb-3 custom-scrollbar">
            <div
              className="flex items-center gap-3 rounded-xl border border-[#ff3a3a]/50 px-3 py-2.5"
              style={{ backgroundColor: "rgba(10, 10, 12, 0.96)" }}
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-lg border border-[#ff3a3a]/55 bg-[#ff3a3a]/15">
                <Crosshair className="h-5 w-5 text-[#ff4d4d]" />
              </div>
              <div>
                <p className="text-[9px] font-bold uppercase tracking-[0.16em] text-[#ff4d4d]">
                  Fatal Weapon
                </p>
                <p className="text-[16px] font-black uppercase tracking-wide text-white">
                  {fatalWeapon}
                </p>
              </div>
            </div>

            {!anatomy ? (
              <>
                <div className="grid grid-cols-2 gap-2">
                  <StatBox label="Kill Streak" value={killStreak} />
                  <div
                    className="rounded-xl border border-[#ff3a3a]/50 px-2.5 py-2.5"
                    style={{ backgroundColor: "rgba(10, 10, 12, 0.96)" }}
                  >
                    <p className="text-[9px] font-bold uppercase tracking-[0.16em] text-[#ff4d4d]">
                      Distance
                    </p>
                    <p className="mt-1 flex items-center gap-1.5 text-[15px] font-black uppercase tracking-wide text-white">
                      <Crosshair className="h-3.5 w-3.5 text-[#ff4d4d]" />
                      {combat.distance}m
                    </p>
                  </div>
                </div>

                <div
                  className="rounded-xl border border-[#ff3a3a]/40 px-3 py-3"
                  style={{ backgroundColor: "rgba(10, 10, 12, 0.96)" }}
                >
                  <p className="mb-2 text-[9px] font-bold uppercase tracking-[0.16em] text-[#ff4d4d]">
                    Damage Exchange
                  </p>
                  <div className="grid grid-cols-2 gap-2">
                    <StatBox label="Dealt" value={combat.damageDealt} tone="green" />
                    <StatBox label="Received" value={combat.damageReceived} tone="red" />
                  </div>
                  <div className="mt-2.5">
                    <div className="mb-1 flex justify-between text-[9px] font-bold text-[#8a8086]">
                      <span>{outPct}% OUT</span>
                      <span>{inPct}% IN</span>
                    </div>
                    <div className="flex h-2 overflow-hidden rounded-full bg-white/10">
                      <div className="h-full bg-emerald-500/80" style={{ width: `${outPct}%` }} />
                      <div className="h-full bg-[#ff3a3a]" style={{ width: `${inPct}%` }} />
                    </div>
                  </div>
                </div>

                <div>
                  <p className="mb-1.5 text-[9px] font-bold uppercase tracking-[0.18em] text-[#ff4d4d]">
                    Recent Eliminations
                  </p>
                  <div
                    className="rounded-xl border border-dashed border-white/20 px-3 py-3"
                    style={{ backgroundColor: "rgba(8, 8, 10, 0.96)" }}
                  >
                    {recent.length ? (
                      <ul className="space-y-1.5">
                        {recent.map((e, i) => (
                          <li
                            key={`${e.id ?? i}-${e.name}`}
                            className="flex items-center justify-between text-[11px] text-white/85"
                          >
                            <span className="font-bold uppercase">{e.name}</span>
                            <span className="text-[#8a8086]">
                              {e.time || (e.id != null ? `ID ${e.id}` : "")}
                            </span>
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p className="text-center text-[11px] text-[#8a8086]">No recent eliminations</p>
                    )}
                  </div>
                </div>
              </>
            ) : (
              <div>
                <div className="mb-2 flex items-center justify-between">
                  <p className="text-[9px] font-bold uppercase tracking-[0.18em] text-[#ff4d4d]">
                    Body Impact
                  </p>
                  <span className="text-[10px] font-bold text-white/80">{totalHits} hits</span>
                </div>
                <div className="flex gap-3">
                  <div className="flex min-w-0 flex-1 flex-col gap-1.5">
                    {ZONE_LABELS.map(({ key, label }) => (
                      <div
                        key={key}
                        className={cn(
                          "flex items-center justify-between rounded-lg bg-white/5 px-2.5 py-2",
                          (hits[key] || 0) > 0 && "bg-[#ff3a3a]/10 ring-1 ring-[#ff3a3a]/35"
                        )}
                      >
                        <span className="text-[10px] font-bold uppercase tracking-wider text-[#9a9096]">
                          {label}
                        </span>
                        <span className="text-[12px] font-black text-white">{hits[key] || 0}</span>
                      </div>
                    ))}
                  </div>
                  <div className="flex w-[96px] shrink-0 items-center justify-center">
                    <BodySilhouette hits={hits} className="h-[200px]" />
                  </div>
                </div>
              </div>
            )}
          </div>

          <div className="mt-auto flex items-center justify-between border-t border-[#ff3a3a]/25 px-4 py-2.5 text-[10px] text-[#8a8086]">
            <span className="inline-flex items-center gap-1.5">
              <BarChart3 className="h-3 w-3 text-[#ff4d4d]" />
              Combat analysis
            </span>
            <span className="inline-flex items-center gap-1.5 font-semibold tracking-wide">
              <Activity className="h-3 w-3 text-[#ff4d4d]" />
              {brandUrl}
            </span>
          </div>
        </aside>
      </div>
    </div>
  );
}
