import React, { useCallback, useEffect, useState } from "react";
import { cn } from "@/lib/utils";
import { fetchNui } from "@/lib/nui";
import {
  BatteryFull,
  KeyRound,
  Loader2,
  Plus,
  Signal,
  Users,
  Wifi,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";

type PartyMember = {
  identifier: string;
  name: string;
  leader?: boolean;
  online?: boolean;
  serverId?: number;
  you?: boolean;
};

type PartyMine = {
  id: number;
  name: string;
  locked?: boolean;
  count: number;
  max: number;
  youLeader?: boolean;
  members: PartyMember[];
};

type PartyListItem = {
  id: number;
  name: string;
  leader: string;
  count: number;
  online: number;
  max: number;
  locked?: boolean;
  full?: boolean;
};

type PartyState = {
  ok?: boolean;
  max?: number;
  list?: PartyListItem[];
  mine?: PartyMine | null;
  error?: string;
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

function SeatDots({ filled, max }: { filled: number; max: number }) {
  return (
    <div className="flex gap-1">
      {Array.from({ length: max }).map((_, i) => (
        <span
          key={i}
          className="h-1.5 w-3"
          style={{
            background: i < filled ? "#ff3a3a" : "rgba(255,255,255,0.12)",
            clipPath: "polygon(2px 0, 100% 0, calc(100% - 2px) 100%, 0 100%)",
          }}
        />
      ))}
    </div>
  );
}

export default function PartyApp({ player }: { player?: IpadPlayerData | null }) {
  const [tab, setTab] = useState<"lobby" | "create">("lobby");
  const [state, setState] = useState<PartyState | null>(null);
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [usePassword, setUsePassword] = useState(false);
  const [password, setPassword] = useState("");
  const [joinPw, setJoinPw] = useState<Record<number, string>>({});

  const you = [player?.firstName, player?.lastName].filter(Boolean).join(" ") || "You";

  const flash = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  };

  const load = useCallback(async () => {
    const result = await nui<PartyState>("cfx-keydi-ipad:party:state");
    if (result) setState(result);
  }, []);

  useEffect(() => {
    void load();
    const id = window.setInterval(() => void load(), 4000);
    return () => window.clearInterval(id);
  }, [load]);

  const apply = (result: PartyState | null, okMsg?: string) => {
    if (!result) {
      flash("No response");
      return;
    }
    if (!result.ok) {
      flash(result.error || "Failed");
      return;
    }
    setState((prev) => ({
      ...(prev || {}),
      ...result,
      list: result.list ?? prev?.list,
      mine: result.mine === undefined ? prev?.mine : result.mine,
    }));
    if (okMsg) flash(okMsg);
  };

  const onCreate = async () => {
    if (busy) return;
    setBusy(true);
    const result = await nui<PartyState>("cfx-keydi-ipad:party:create", {
      name: name.trim() || `${you}'s Squad`,
      password: usePassword ? password : "",
    });
    apply(result, "Squad created");
    setBusy(false);
  };

  const onJoin = async (id: number, locked?: boolean) => {
    if (busy) return;
    setBusy(true);
    const result = await nui<PartyState>("cfx-keydi-ipad:party:join", {
      id,
      password: locked ? joinPw[id] || "" : "",
    });
    apply(result, "Joined squad");
    setBusy(false);
  };

  const onLeave = async () => {
    if (busy) return;
    setBusy(true);
    const result = await nui<PartyState>("cfx-keydi-ipad:party:leave");
    apply(result, "Left squad");
    setBusy(false);
  };

  const onKick = async (identifier: string) => {
    if (busy) return;
    setBusy(true);
    const result = await nui<PartyState>("cfx-keydi-ipad:party:kick", { identifier });
    apply(result, "Removed from squad");
    setBusy(false);
  };

  const onDisband = async () => {
    if (busy) return;
    setBusy(true);
    const result = await nui<PartyState>("cfx-keydi-ipad:party:disband");
    apply(result, "Squad closed");
    setBusy(false);
  };

  const mine = state?.mine;
  const list = state?.list || [];
  const max = state?.max || 4;

  return (
    <div
      className="absolute inset-0 flex flex-col select-none"
      style={{
        background:
          "radial-gradient(ellipse at 20% 0%, rgba(255,58,58,0.14), transparent 46%), linear-gradient(180deg, #140d11 0%, #0c090b 100%)",
        fontFamily: "'Outfit', sans-serif",
      }}
    >
      <StatusBar />

      <div className="px-5 pb-3 pt-2">
        <p className="text-[10px] font-semibold uppercase tracking-[0.28em] text-[#ff8080]">Grim City</p>
        <div className="mt-0.5 flex items-end justify-between">
          <h1 className="text-[26px] font-bold leading-none tracking-tight text-white">Squad</h1>
          <SeatDots filled={mine?.count || 0} max={max} />
        </div>
        <p className="mt-1.5 text-[12px] text-white/40">Four seats. Open lobby or host lock.</p>
      </div>

      <div className="mx-5 mb-3 flex border-b border-white/8">
        {(
          [
            { id: "lobby" as const, label: "Lobby" },
            { id: "create" as const, label: mine ? "Roster" : "Form squad" },
          ] as const
        ).map((t) => {
          const active = tab === t.id;
          return (
            <button
              key={t.id}
              type="button"
              className={cn(
                "-mb-px border-b-2 px-4 py-2 text-[12px] font-semibold uppercase tracking-[0.12em]",
                active ? "border-[#ff3a3a] text-white" : "border-transparent text-white/35",
              )}
              onClick={() => setTab(t.id)}
            >
              {t.label}
            </button>
          );
        })}
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-6">
        {tab === "lobby" && (
          <div className="space-y-2">
            {list.length === 0 ? (
              <div className="border border-white/8 bg-[#1a1216] px-5 py-10 text-center">
                <Users className="mx-auto mb-3 h-6 w-6 text-[#ff3a3a]" />
                <p className="text-[15px] font-semibold text-white">Lobby is empty</p>
                <p className="mt-1 text-[12px] text-white/40">Form a squad and it appears here for the whole city.</p>
              </div>
            ) : (
              list.map((p) => (
                <div key={p.id} className="flex overflow-hidden border border-white/8 bg-[#1a1216]">
                  <div className="w-[4px] shrink-0 bg-[#ff3a3a]" />
                  <div className="min-w-0 flex-1 px-3.5 py-3">
                    <div className="flex items-center justify-between gap-3">
                      <div className="min-w-0">
                        <p className="truncate text-[15px] font-semibold text-white">{p.name}</p>
                        <p className="mt-0.5 text-[11px] text-white/40">
                          Host {p.leader} · {p.online} live
                        </p>
                      </div>
                      {mine?.id === p.id ? (
                        <span className="text-[10px] font-bold uppercase tracking-wider text-[#ff8080]">Yours</span>
                      ) : (
                        <button
                          type="button"
                          disabled={busy || p.full || Boolean(mine)}
                          className="bg-[#ff3a3a] px-3 py-1.5 text-[11px] font-bold uppercase tracking-wide text-white disabled:opacity-35"
                          onClick={() => void onJoin(p.id, p.locked)}
                        >
                          {p.full ? "Full" : "Enter"}
                        </button>
                      )}
                    </div>
                    <div className="mt-2 flex items-center justify-between">
                      <SeatDots filled={p.count} max={p.max} />
                      {p.locked ? (
                        <span className="inline-flex items-center gap-1 text-[10px] uppercase tracking-wider text-white/35">
                          <KeyRound className="h-3 w-3" /> Locked
                        </span>
                      ) : (
                        <span className="text-[10px] uppercase tracking-wider text-white/25">Open</span>
                      )}
                    </div>
                    {p.locked && mine?.id !== p.id && !mine ? (
                      <input
                        value={joinPw[p.id] || ""}
                        onChange={(e) => setJoinPw((s) => ({ ...s, [p.id]: e.target.value }))}
                        placeholder="Host lock code"
                        className="mt-2 w-full border border-white/10 bg-black/40 px-3 py-2 text-[13px] text-white outline-none placeholder:text-white/25"
                      />
                    ) : null}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {tab === "create" && !mine && (
          <div className="border border-white/8 bg-[#1a1216] px-5 py-6">
            <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-[#ff8080]">New roster</p>
            <h2 className="mt-1 text-[22px] font-bold text-white">Form a squad</h2>
            <p className="mt-1 text-[13px] text-white/40">
              Open squads sit in the lobby. Host lock keeps it to people who know your code.
            </p>
            <label className="mt-5 block text-[10px] font-semibold uppercase tracking-[0.16em] text-white/35">
              Squad name
            </label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={`${you}'s Squad`}
              maxLength={24}
              className="mt-1.5 w-full border border-white/10 bg-black/40 px-3 py-2.5 text-[14px] text-white outline-none placeholder:text-white/25"
            />
            <label className="mt-4 flex items-center gap-2 text-[13px] text-white/70">
              <input
                type="checkbox"
                checked={usePassword}
                onChange={(e) => setUsePassword(e.target.checked)}
                className="accent-[#ff3a3a]"
              />
              Host lock code
            </label>
            {usePassword ? (
              <input
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Code"
                maxLength={16}
                className="mt-2 w-full border border-white/10 bg-black/40 px-3 py-2.5 text-[14px] text-white outline-none placeholder:text-white/25"
              />
            ) : null}
            <button
              type="button"
              disabled={busy}
              className="mt-5 flex w-full items-center justify-center gap-2 bg-[#ff3a3a] py-2.5 text-[13px] font-bold uppercase tracking-wide text-white disabled:opacity-40"
              onClick={() => void onCreate()}
            >
              {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
              Form squad
            </button>
          </div>
        )}

        {tab === "create" && mine && (
          <div className="space-y-3">
            <div className="border border-white/8 bg-[#1a1216] px-4 py-3">
              <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-[#ff8080]">Active roster</p>
              <p className="mt-1 text-[20px] font-bold text-white">{mine.name}</p>
              <div className="mt-2 flex items-center justify-between">
                <SeatDots filled={mine.count} max={mine.max} />
                <span className="text-[10px] uppercase tracking-wider text-white/35">
                  {mine.locked ? "Host lock on" : "Open lobby"}
                </span>
              </div>
            </div>
            <div className="border border-white/8 bg-[#1a1216]">
              {mine.members.map((m, i) => (
                <div
                  key={m.identifier}
                  className={cn("flex items-center gap-3 px-4 py-3", i < mine.members.length - 1 && "border-b border-white/6")}
                >
                  <div
                    className="flex h-9 w-9 items-center justify-center text-[11px] font-bold text-[#ffb4b4]"
                    style={{
                      background: "rgba(255,58,58,0.16)",
                      clipPath: "polygon(6px 0, 100% 0, 100% calc(100% - 6px), calc(100% - 6px) 100%, 0 100%, 0 6px)",
                    }}
                  >
                    {m.name.slice(0, 1).toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[15px] font-semibold text-white">
                      {m.name}
                      {m.you ? <span className="ml-1 text-[11px] text-white/30">you</span> : null}
                    </p>
                    <p className="text-[11px] text-white/40">
                      {m.leader ? "Host" : "Seat"} · {m.online ? `Live${m.serverId ? ` #${m.serverId}` : ""}` : "Away"}
                    </p>
                  </div>
                  {mine.youLeader && !m.you ? (
                    <button
                      type="button"
                      className="px-2 py-1 text-[10px] font-bold uppercase tracking-wider text-white/45"
                      onClick={() => void onKick(m.identifier)}
                    >
                      Remove
                    </button>
                  ) : null}
                </div>
              ))}
            </div>
            <div className="flex gap-2">
              <button
                type="button"
                className="flex-1 border border-white/10 py-2.5 text-[12px] font-bold uppercase tracking-wide text-white/70"
                onClick={() => void onLeave()}
              >
                Leave
              </button>
              {mine.youLeader ? (
                <button
                  type="button"
                  className="flex-1 bg-[#5c1212] py-2.5 text-[12px] font-bold uppercase tracking-wide text-[#ffb4b4]"
                  onClick={() => void onDisband()}
                >
                  Close squad
                </button>
              ) : null}
            </div>
          </div>
        )}
      </div>

      {toast ? (
        <div className="pointer-events-none absolute bottom-8 left-1/2 z-50 -translate-x-1/2 bg-[#ff3a3a] px-4 py-2 text-[12px] font-semibold uppercase tracking-wide text-white">
          {toast}
        </div>
      ) : null}
    </div>
  );
}
