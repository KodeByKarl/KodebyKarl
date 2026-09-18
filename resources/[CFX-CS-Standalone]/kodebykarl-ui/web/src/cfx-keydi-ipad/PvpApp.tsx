import React, { useCallback, useEffect, useState } from "react";
import { cn } from "@/lib/utils";
import { fetchNui } from "@/lib/nui";
import {
  BatteryFull,
  Loader2,
  MapPin,
  Shield,
  Signal,
  Users,
  Wifi,
  Zap,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";

type PvpStatus = {
  ok?: boolean;
  inPvp?: boolean;
  players?: number;
  maxPlayers?: number;
  name?: string;
  tags?: string[];
};

async function nui<T>(event: string, data: Record<string, unknown> = {}): Promise<T | null> {
  try {
    return await fetchNui<T>(event, data);
  } catch {
    return null;
  }
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

export default function PvpApp({
  player,
}: {
  player?: IpadPlayerData | null;
}) {
  const [status, setStatus] = useState<PvpStatus | null>(null);
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const flash = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  };

  const loadStatus = useCallback(async () => {
    const result = await nui<PvpStatus>("cfx-keydi-ipad:pvp:status");
    if (result) setStatus(result);
  }, []);

  useEffect(() => {
    void loadStatus();
    const id = window.setInterval(() => void loadStatus(), 4000);
    return () => window.clearInterval(id);
  }, [loadStatus]);

  const name = status?.name || "Deathmatch Arena";
  const players = status?.players ?? 0;
  const maxPlayers = status?.maxPlayers ?? 32;
  const inPvp = Boolean(status?.inPvp);
  const full = !inPvp && players >= maxPlayers;
  const tags = status?.tags?.length ? status.tags : ["Pistols", "Safe zone", "Public"];
  const playerName = [player?.firstName, player?.lastName].filter(Boolean).join(" ") || "Player";

  const onAction = async () => {
    if (busy || (full && !inPvp)) return;
    setBusy(true);
    if (inPvp) {
      flash("Leaving arena…");
      await nui("cfx-keydi-ipad:pvp:leave");
    } else {
      flash("Joining deathmatch…");
      await nui("cfx-keydi-ipad:pvp:join");
    }
    setBusy(false);
  };

  return (
    <div
      className="absolute inset-0 flex flex-col select-none"
      style={{
        background:
          "radial-gradient(ellipse at 70% 0%, rgba(249,115,22,0.18), transparent 48%), linear-gradient(165deg, #100a06 0%, #16100c 50%, #0c0907 100%)",
      }}
    >
      <StatusBar />

      <div className="flex items-start gap-2 px-5 pb-2 pt-2">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <Zap className="h-5 w-5 text-[#fb923c]" strokeWidth={2.2} fill="#fb923c" />
            <h1 className="text-[22px] font-bold tracking-wide text-white">PvP</h1>
          </div>
          <p className="mt-1 text-[12px] text-white/45">
            Public deathmatch · {playerName}
          </p>
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-6">
        <p className="mb-3 text-[11px] font-semibold uppercase tracking-[0.16em] text-white/40">
          Location
        </p>

        <div className="mx-auto max-w-[420px] rounded-2xl border border-white/8 bg-[#1c1917] p-5 shadow-md">
          <div className="mb-3 flex items-start justify-between gap-3">
            <div className="flex items-start gap-2">
              <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-[#fb923c]" />
              <p className="text-[18px] font-semibold leading-snug text-white">{name}</p>
            </div>
            <span
              className={cn(
                "shrink-0 rounded-md px-1.5 py-0.5 text-[10px] font-bold uppercase",
                full ? "bg-[#7f1d1d] text-[#fca5a5]" : "bg-[#14532d] text-[#4ade80]",
              )}
            >
              {full ? "Full" : "Open"}
            </span>
          </div>

          <div className="mb-3 flex items-center gap-1 text-[13px] text-white/45">
            <Users className="h-3.5 w-3.5" />
            {players}/{maxPlayers} players
          </div>

          <div className="mb-4 flex flex-wrap gap-1.5">
            {tags.map((tag) => (
              <span
                key={tag}
                className="inline-flex items-center gap-1 rounded-full bg-white/6 px-2 py-0.5 text-[10px] font-medium text-white/60"
              >
                {tag.toLowerCase().includes("safe") ? (
                  <Shield className="h-2.5 w-2.5" />
                ) : (
                  <Zap className="h-2.5 w-2.5" />
                )}
                {tag}
              </span>
            ))}
          </div>

          <p className="mb-4 text-[12px] leading-relaxed text-white/40">
            Join teleports you to the arena map. Inventory is wiped except cash. Use the exit ped
            or Leave here to return.
          </p>

          <button
            type="button"
            disabled={busy || full}
            className={cn(
              "flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-[14px] font-bold transition-colors disabled:opacity-40",
              inPvp ? "bg-white/10 text-white hover:bg-white/16" : "bg-[#f97316] text-white hover:bg-[#ea580c]",
            )}
            onClick={() => void onAction()}
          >
            {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
            {inPvp ? "Leave" : "Join"}
          </button>
        </div>
      </div>

      {toast ? (
        <div className="pointer-events-none absolute bottom-8 left-1/2 z-50 -translate-x-1/2 rounded-full bg-[#c2410c] px-4 py-2 text-[13px] font-semibold text-white shadow-lg">
          {toast}
        </div>
      ) : null}
    </div>
  );
}
