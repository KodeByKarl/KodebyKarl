import React, { useCallback, useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import { fetchNui } from "@/lib/nui";
import { BatteryFull, Loader2, Signal, Trophy, Wifi } from "lucide-react";
import type { IpadPlayerData } from "./Ipad";

type TabId = "turfwar" | "traphouse" | "pvp" | "party" | "topplayer";

const TABS: { id: TabId; label: string }[] = [
  { id: "turfwar", label: "Turfwar" },
  { id: "traphouse", label: "Traphouse" },
  { id: "pvp", label: "PvP" },
  { id: "party", label: "Party" },
  { id: "topplayer", label: "Top Player" },
];

interface RankRow {
  rank: number;
  name: string;
  gang?: string | null;
  score: string;
  subtitle?: string;
  kills?: number;
  deaths?: number;
  kd?: number;
  claims?: number;
}

interface MineRow {
  rank?: number | null;
  name: string;
  kills?: number;
  deaths?: number;
  kd?: number;
  score?: string;
  subtitle?: string;
}

const TAB_META: Record<TabId, { title: string; blurb: string; glow: string; chip: string }> = {
  turfwar: {
    title: "Turfwar",
    blurb: "Gangs ranked by Turf War claim wins.",
    glow: "rgba(225,6,0,0.22)",
    chip: "bg-[#e10600] text-white shadow-[0_4px_16px_rgba(225,6,0,0.4)]",
  },
  traphouse: {
    title: "Traphouse",
    blurb: "Most kills inside active TrapHouse redzones.",
    glow: "rgba(52,199,89,0.18)",
    chip: "bg-[#15803d] text-white shadow-[0_4px_16px_rgba(21,128,61,0.4)]",
  },
  pvp: {
    title: "PvP",
    blurb: "Deathmatch arena kills · deaths · KDA only.",
    glow: "rgba(249,115,22,0.22)",
    chip: "bg-[#ea580c] text-white shadow-[0_4px_16px_rgba(234,88,12,0.4)]",
  },
  party: {
    title: "Party",
    blurb: "Combined team kills · deaths · KDA while partied.",
    glow: "rgba(175,82,222,0.2)",
    chip: "bg-[#7c3aed] text-white shadow-[0_4px_16px_rgba(124,58,237,0.4)]",
  },
  topplayer: {
    title: "Top Player",
    blurb: "Citywide player kills · deaths · KDA (outside PvP arena).",
    glow: "rgba(255,159,10,0.2)",
    chip: "bg-[#ca8a04] text-white shadow-[0_4px_16px_rgba(202,138,4,0.4)]",
  },
};

const NUI: Record<TabId, string> = {
  turfwar: "cfx-keydi-ipad:leaderboard:turfwar",
  traphouse: "cfx-keydi-ipad:leaderboard:traphouse",
  pvp: "cfx-keydi-ipad:leaderboard:pvp",
  party: "cfx-keydi-ipad:leaderboard:party",
  topplayer: "cfx-keydi-ipad:leaderboard:topplayer",
};

function normalizeRows(tab: TabId, raw: RankRow[]): RankRow[] {
  return (raw || []).map((row, i) => {
    const rank = row.rank ?? i + 1;
    if (tab === "turfwar") {
      const claims = row.claims ?? 0;
      return {
        ...row,
        rank,
        score: row.score || `${claims} claims`,
        subtitle: row.subtitle || "Turf wins",
      };
    }
    const kills = row.kills ?? 0;
    const deaths = row.deaths ?? 0;
    const kd = row.kd ?? (deaths > 0 ? kills / deaths : kills);
    return {
      ...row,
      rank,
      kills,
      deaths,
      kd,
      score: row.score || `${kills} K / ${deaths} D`,
      subtitle: row.subtitle || `KDA ${Number(kd).toFixed(2)}`,
    };
  });
}

function StatusBar() {
  const [now, setNow] = useState(() => new Date());
  React.useEffect(() => {
    const id = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(id);
  }, []);
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  return (
    <div className="relative z-40 flex items-center justify-between px-7 pt-[18px] text-[12px] font-semibold tracking-tight text-white/90">
      <span className="min-w-[54px]">{time}</span>
      <div className="flex items-center gap-1.5 opacity-90">
        <Signal className="h-3.5 w-3.5" strokeWidth={2.4} />
        <Wifi className="h-3.5 w-3.5" strokeWidth={2.4} />
        <BatteryFull className="h-4 w-4" strokeWidth={2.2} />
      </div>
    </div>
  );
}

function RankBadge({ rank }: { rank: number }) {
  const tone =
    rank === 1
      ? "bg-gradient-to-br from-[#ffd60a] to-[#ff9f0a] text-[#1c1c1e] shadow-[0_4px_12px_rgba(255,214,10,0.35)]"
      : rank === 2
        ? "bg-gradient-to-br from-[#d4d4d8] to-[#71717a] text-[#18181b] shadow-[0_4px_12px_rgba(161,161,170,0.25)]"
        : rank === 3
          ? "bg-gradient-to-br from-[#d97706] to-[#9a3412] text-white shadow-[0_4px_12px_rgba(217,119,6,0.3)]"
          : "bg-white/8 text-white/70 ring-1 ring-white/10";
  return (
    <div
      className={cn(
        "flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-[14px] font-bold",
        tone,
      )}
    >
      {rank}
    </div>
  );
}

export default function LeaderboardApp({
  player,
}: {
  player?: IpadPlayerData | null;
}) {
  const [tab, setTab] = useState<TabId>("turfwar");
  const [rows, setRows] = useState<RankRow[]>([]);
  const [mine, setMine] = useState<MineRow | null>(null);
  const [loading, setLoading] = useState(false);

  const load = useCallback(async (active: TabId) => {
    setLoading(true);
    const result = await fetchNui<{ ok?: boolean; rows?: RankRow[]; mine?: MineRow | null }>(
      NUI[active],
    );
    setRows(normalizeRows(active, result?.rows || []));
    setMine(result?.mine || null);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load(tab);
  }, [tab, load]);

  const meta = TAB_META[tab];
  const you = useMemo(() => {
    const n = [player?.firstName, player?.lastName].filter(Boolean).join(" ");
    return n || null;
  }, [player]);

  const scoreTone =
    tab === "pvp"
      ? "text-[#fdba74]"
      : tab === "traphouse"
        ? "text-[#86efac]"
        : tab === "party"
          ? "text-[#d8b4fe]"
          : tab === "topplayer"
            ? "text-[#fde047]"
            : "text-[#fca5a5]";

  return (
    <div
      className="absolute inset-0 flex flex-col select-none"
      style={{
        background: `radial-gradient(ellipse at 70% 0%, ${meta.glow}, transparent 52%), linear-gradient(165deg, #100808 0%, #140c0c 48%, #0a0707 100%)`,
      }}
    >
      <StatusBar />

      <div className="flex items-start gap-2 px-5 pb-2 pt-2">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <Trophy className="h-5 w-5 text-[#f87171]" strokeWidth={2.2} fill="#f87171" />
            <h1 className="text-[22px] font-bold tracking-wide text-white">Leaderboards</h1>
          </div>
          <p className="mt-1 text-[12px] text-white/45">{meta.blurb}</p>
        </div>
        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-[#e10600] text-white shadow-[0_6px_18px_rgba(225,6,0,0.45)]">
          <Trophy className="h-5 w-5" strokeWidth={2.2} fill="white" />
        </div>
      </div>

      <div className="flex flex-wrap gap-2 px-5 pb-3">
        {TABS.map((t) => {
          const active = tab === t.id;
          return (
            <button
              key={t.id}
              type="button"
              className={cn(
                "rounded-full px-3.5 py-1.5 text-[12px] font-semibold transition-colors",
                active ? TAB_META[t.id].chip : "bg-white/6 text-white/55 hover:bg-white/10",
              )}
              onClick={() => setTab(t.id)}
            >
              {t.label}
            </button>
          );
        })}
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-8">
        <div className="mb-4 overflow-hidden rounded-2xl border border-white/10 bg-[#1a1111]/90 px-5 py-4">
          <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-[#fca5a5]">
            Live standings
          </p>
          <h2 className="mt-1 text-[26px] font-bold tracking-tight text-white">{meta.title}</h2>
          {you ? (
            <p className="mt-3 rounded-xl bg-black/35 px-3 py-2 text-[13px] text-white/80">
              Signed in as <span className="font-semibold text-white">{you}</span>
              {player?.gang ? ` · ${player.gang}` : ""}
              {mine ? (
                <span className="mt-1 block text-white/55">
                  {mine.rank ? `Rank #${mine.rank}` : "Unranked"}
                  {mine.score ? ` · ${mine.score}` : ""}
                  {mine.subtitle ? ` · ${mine.subtitle}` : ""}
                </span>
              ) : null}
            </p>
          ) : null}
        </div>

        <div className="overflow-hidden rounded-2xl border border-white/8 bg-[#141010]">
          {loading ? (
            <div className="flex items-center justify-center gap-2 px-4 py-10 text-[13px] text-white/45">
              <Loader2 className="h-4 w-4 animate-spin" />
              Loading standings…
            </div>
          ) : rows.length === 0 ? (
            <div className="px-4 py-10 text-center text-[13px] text-white/40">
              No records yet. Play to climb the board.
            </div>
          ) : (
            rows.map((row, i) => (
              <div
                key={`${tab}-${row.rank}-${row.name}`}
                className={cn(
                  "flex items-center gap-3 px-4 py-3.5",
                  i < rows.length - 1 && "border-b border-white/6",
                  row.rank === 1 && "bg-white/5",
                )}
              >
                <RankBadge rank={row.rank} />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[16px] font-semibold text-white">{row.name}</p>
                  <p className="truncate text-[13px] text-white/40">
                    {row.gang ? `${row.gang}` : ""}
                    {row.gang && row.subtitle ? " · " : ""}
                    {row.subtitle || ""}
                  </p>
                </div>
                <p className={cn("shrink-0 text-right text-[13px] font-semibold", scoreTone)}>
                  {row.score}
                </p>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
