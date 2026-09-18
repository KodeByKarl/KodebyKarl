import React, { useCallback, useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import {
  BatteryFull,
  Loader2,
  Search,
  Signal,
  UserMinus,
  UserPlus,
  Users,
  Wifi,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";
import { fetchNui } from "@/lib/nui";

type TabId = "roster" | "online" | "hire";

type Grade = { grade: number; name: string; label: string };
type Member = {
  identifier: string;
  name: string;
  grade: number;
  gradeLabel: string;
  online: boolean;
  serverId?: number | null;
  lastSeen?: string;
};
type NearbyPlayer = { id: number; name: string };

type Dashboard = {
  ok: boolean;
  error?: string;
  message?: string;
  gang?: string;
  label?: string;
  yourGrade?: number;
  members?: Member[];
  grades?: Grade[];
  memberCount?: number;
  onlineCount?: number;
  staff?: boolean;
  gangs?: { name: string; label: string }[];
};

const TABS: { id: TabId; label: string }[] = [
  { id: "roster", label: "Roster" },
  { id: "online", label: "Online" },
  { id: "hire", label: "Hire" },
];

const ERR: Record<string, string> = {
  denied: "Gang boss access only.",
  invalid: "Invalid request.",
  offline: "That player is offline.",
  far: "Player is too far away.",
  grade: "You cannot set that rank.",
  self: "You cannot edit yourself.",
  not_member: "Not in this organization.",
  already: "Already in your gang.",
  discord: "Discord role check failed.",
};

function StatusBar() {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
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

export default function OrganizationApp({
  player,
}: {
  player?: IpadPlayerData | null;
}) {
  const [tab, setTab] = useState<TabId>("roster");
  const [loading, setLoading] = useState(true);
  const [dash, setDash] = useState<Dashboard | null>(null);
  const [selectedGang, setSelectedGang] = useState("");
  const [query, setQuery] = useState("");
  const [hireId, setHireId] = useState("");
  const [hireGrade, setHireGrade] = useState("0");
  const [discordId, setDiscordId] = useState("");
  const [nearby, setNearby] = useState<NearbyPlayer[]>([]);
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const flash = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const load = useCallback(async (gangName?: string) => {
    setLoading(true);
    const gang = gangName ?? selectedGang;
    const result = await fetchNui<Dashboard>("cfx-keydi-ipad:org:dashboard", gang ? { gang } : {});
    if (result?.ok) {
      setDash(result);
      if (result.gang) setSelectedGang(result.gang);
    } else {
      setDash(result || { ok: false });
      flash(ERR[result?.error || ""] || result?.message || "Failed to load organization.");
    }
    setLoading(false);
  }, [flash, selectedGang]);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    if (tab !== "hire") return;
    void fetchNui<{ ok: boolean; players?: NearbyPlayer[] }>("cfx-keydi-ipad:org:nearby").then(
      (res) => setNearby(res?.players || []),
    );
  }, [tab]);

  const members = useMemo(() => {
    const list = dash?.members || [];
    const q = query.trim().toLowerCase();
    if (!q) return list;
    return list.filter(
      (e) => e.name.toLowerCase().includes(q) || e.gradeLabel.toLowerCase().includes(q),
    );
  }, [dash?.members, query]);

  const online = useMemo(() => (dash?.members || []).filter((e) => e.online), [dash?.members]);

  const hireGrades = useMemo(() => {
    const your = dash?.yourGrade ?? 99;
    return (dash?.grades || []).filter((g) => g.grade < your);
  }, [dash?.grades, dash?.yourGrade]);

  const hire = async () => {
    const id = Math.floor(Number(hireId) || 0);
    const grade = Math.floor(Number(hireGrade) || 0);
    if (!id || busy) return;
    setBusy(true);
    const result = await fetchNui<Dashboard>("cfx-keydi-ipad:org:hire", {
      id,
      grade,
      gang: dash?.gang || selectedGang,
    });
    setBusy(false);
    if (!result?.ok) {
      flash(result?.message || ERR[result?.error || ""] || "Hire failed.");
      return;
    }
    setDash((prev) =>
      prev
        ? {
            ...prev,
            members: result.members,
            grades: result.grades,
            memberCount: result.memberCount,
            onlineCount: result.onlineCount,
          }
        : prev,
    );
    setHireId("");
    flash("Member hired.");
  };

  const hireDiscord = async () => {
    const discord = discordId.trim();
    if (!discord || !dash?.gang || busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; error?: string }>("cfx-keydi-ipad:org:hireDiscord", {
      gang: dash.gang,
      discord,
    });
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Discord hire failed.");
      return;
    }
    setDiscordId("");
    flash("Discord hire sent.");
    window.setTimeout(() => void load(), 800);
  };

  const setGrade = async (identifier: string, grade: number) => {
    if (busy) return;
    setBusy(true);
    const result = await fetchNui<Dashboard>("cfx-keydi-ipad:org:setGrade", {
      identifier,
      grade,
      gang: dash?.gang || selectedGang,
    });
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Could not update rank.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, members: result.members, grades: result.grades } : prev));
    flash("Rank updated.");
  };

  const fire = async (identifier: string, name: string) => {
    if (busy) return;
    setBusy(true);
    const result = await fetchNui<Dashboard>("cfx-keydi-ipad:org:fire", {
      identifier,
      gang: dash?.gang || selectedGang,
    });
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Could not remove member.");
      return;
    }
    setDash((prev) =>
      prev
        ? {
            ...prev,
            members: result.members,
            grades: result.grades,
            memberCount: result.memberCount,
            onlineCount: result.onlineCount,
          }
        : prev,
    );
    flash(`${name} removed.`);
  };

  return (
    <div
      className="absolute inset-0 flex flex-col select-none"
      style={{
        background:
          "radial-gradient(ellipse at 12% 0%, rgba(56,189,248,0.18), transparent 46%), linear-gradient(165deg, #071018 0%, #0c1824 48%, #070b10 100%)",
      }}
    >
      <StatusBar />

      <div className="flex items-start justify-between gap-3 px-5 pb-2 pt-2">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <Users className="h-5 w-5 text-[#7dd3fc]" strokeWidth={2.2} />
            <h1 className="text-[22px] font-bold tracking-wide text-white">
              {dash?.label || player?.gang || "Organization"}
            </h1>
            <span className="rounded-md bg-[#0369a1] px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-white">
              {dash?.staff ? "Staff" : "Boss"}
            </span>
          </div>
          <p className="mt-1 text-[12px] text-white/45">
            {[player?.firstName, player?.lastName].filter(Boolean).join(" ") || "Boss"} ·{" "}
            {dash?.memberCount ?? 0} members · {dash?.onlineCount ?? 0} online
          </p>
        </div>
        {(dash?.gangs?.length ?? 0) > 0 ? (
          <select
            value={dash?.gang || selectedGang}
            onChange={(e) => {
              const next = e.target.value;
              setSelectedGang(next);
              void load(next);
            }}
            className="max-w-[180px] rounded-xl border border-white/10 bg-black/40 px-3 py-2 text-[12px] font-semibold text-white outline-none"
          >
            <option value="" className="bg-[#111]">
              Select organization
            </option>
            {dash?.gangs?.map((g) => (
              <option key={g.name} value={g.name} className="bg-[#111]">
                {g.label}
              </option>
            ))}
          </select>
        ) : null}
      </div>

      <div className="flex gap-2 overflow-x-auto px-5 pb-3">
        {TABS.map((t) => {
          const active = tab === t.id;
          return (
            <button
              key={t.id}
              type="button"
              className={cn(
                "shrink-0 rounded-full px-3.5 py-1.5 text-[12px] font-semibold transition-colors",
                active
                  ? "bg-[#0284c7] text-white shadow-[0_4px_16px_rgba(2,132,199,0.35)]"
                  : "bg-white/6 text-white/55 hover:bg-white/10",
              )}
              onClick={() => setTab(t.id)}
            >
              {t.label}
            </button>
          );
        })}
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-6">
        {loading && (
          <div className="flex h-40 items-center justify-center text-white/50">
            <Loader2 className="h-6 w-6 animate-spin" />
          </div>
        )}

        {!loading && !dash?.gang && (dash?.gangs?.length ?? 0) > 0 && (
          <div className="flex h-40 items-center justify-center text-center text-[13px] text-white/45">
            Select an organization to manage roster, ranks, and hires.
          </div>
        )}

        {!loading && tab === "roster" && !!dash?.gang && (
          <div className="space-y-3">
            <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-[#0d1822] px-3 py-2.5">
              <Search className="h-4 w-4 text-white/35" />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search roster"
                className="w-full bg-transparent text-[13px] text-white outline-none"
              />
            </div>

            {members.length === 0 ? (
              <p className="py-10 text-center text-[12px] text-white/40">No members yet.</p>
            ) : (
              members.map((emp) => (
                <div
                  key={emp.identifier}
                  className="flex flex-wrap items-center justify-between gap-2 rounded-2xl border border-white/8 bg-[#0d1822] px-4 py-3"
                >
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="truncate text-[14px] font-semibold text-white">{emp.name}</p>
                      <span className={cn("h-2 w-2 rounded-full", emp.online ? "bg-[#4ade80]" : "bg-white/25")} />
                    </div>
                    <p className="mt-0.5 text-[12px] text-white/40">
                      {emp.gradeLabel}
                      {emp.online && emp.serverId ? ` · #${emp.serverId}` : ""}
                    </p>
                  </div>
                  {emp.grade < (dash?.yourGrade ?? 0) ? (
                    <div className="flex items-center gap-2">
                      <select
                        value={emp.grade}
                        onChange={(ev) => void setGrade(emp.identifier, Number(ev.target.value))}
                        className="max-w-[130px] rounded-lg border border-white/10 bg-black/40 px-1.5 py-1 text-[11px] text-white"
                      >
                        {(dash?.grades || [])
                          .filter((g) => g.grade < (dash?.yourGrade ?? 99))
                          .map((g) => (
                            <option key={g.grade} value={g.grade} className="bg-[#111]">
                              {g.label}
                            </option>
                          ))}
                      </select>
                      <button
                        type="button"
                        onClick={() => void fire(emp.identifier, emp.name)}
                        className="rounded-lg bg-red-500/15 p-1.5 text-red-300"
                        title="Remove"
                      >
                        <UserMinus className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  ) : null}
                </div>
              ))
            )}
          </div>
        )}

        {!loading && tab === "online" && !!dash?.gang && (
          <div className="overflow-hidden rounded-2xl border border-white/10 bg-[#0d1822]">
            {online.length === 0 ? (
              <div className="px-4 py-10 text-center">
                <Users className="mx-auto mb-2 h-7 w-7 text-white/25" />
                <p className="text-[12px] text-white/40">No one online in this organization.</p>
              </div>
            ) : (
              online.map((e, i) => (
                <div
                  key={e.identifier}
                  className={cn("flex items-center justify-between px-4 py-2.5", i > 0 && "border-t border-white/8")}
                >
                  <div>
                    <p className="text-[13px] font-semibold text-white">{e.name}</p>
                    <p className="text-[11px] text-white/45">{e.gradeLabel}</p>
                  </div>
                  <span className="text-[11px] tabular-nums text-white/50">#{e.serverId}</span>
                </div>
              ))
            )}
          </div>
        )}

        {!loading && tab === "hire" && !!dash?.gang && (
          <div className="space-y-4">
            <div className="rounded-2xl border border-white/8 bg-[#0d1822] p-4">
              <p className="mb-3 text-[14px] font-semibold text-white">Hire nearby</p>
              <div className="flex flex-wrap gap-2">
                {nearby.map((p) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => setHireId(String(p.id))}
                    className={cn(
                      "rounded-full px-2.5 py-1 text-[11px] font-semibold",
                      hireId === String(p.id) ? "bg-[#0284c7] text-white" : "bg-white/10 text-white/70",
                    )}
                  >
                    {p.name} · {p.id}
                  </button>
                ))}
              </div>
              <div className="mt-3 flex flex-wrap gap-2">
                <input
                  value={hireId}
                  onChange={(e) => setHireId(e.target.value.replace(/[^\d]/g, ""))}
                  placeholder="Server ID"
                  className="w-28 rounded-xl border border-white/10 bg-black/35 px-3 py-2.5 text-[13px] text-white outline-none"
                />
                <select
                  value={hireGrade}
                  onChange={(e) => setHireGrade(e.target.value)}
                  className="min-w-0 flex-1 rounded-xl border border-white/10 bg-black/35 px-3 py-2.5 text-[13px] text-white outline-none"
                >
                  {hireGrades.map((g) => (
                    <option key={g.grade} value={g.grade} className="bg-[#111]">
                      {g.label}
                    </option>
                  ))}
                </select>
                <button
                  type="button"
                  disabled={busy}
                  className="inline-flex items-center gap-1.5 rounded-full bg-[#0284c7] px-4 py-2.5 text-[12px] font-bold uppercase text-white disabled:opacity-50"
                  onClick={() => void hire()}
                >
                  <UserPlus className="h-3.5 w-3.5" />
                  Hire
                </button>
              </div>
              {nearby.length === 0 && (
                <p className="mt-2 text-[12px] text-white/35">No players within 5m.</p>
              )}
            </div>

            <div className="rounded-2xl border border-white/8 bg-[#0d1822] p-4">
              <p className="mb-1 text-[14px] font-semibold text-white">Hire by Discord ID</p>
              <p className="mb-3 text-[12px] text-white/40">
                Recruit must have the gang Discord role. Works online or offline.
              </p>
              <div className="flex gap-2">
                <input
                  value={discordId}
                  onChange={(e) => setDiscordId(e.target.value.replace(/[^\d]/g, "").slice(0, 22))}
                  placeholder="Discord numeric ID"
                  className="min-w-0 flex-1 rounded-xl border border-white/10 bg-black/35 px-3 py-2.5 text-[13px] text-white outline-none"
                />
                <button
                  type="button"
                  disabled={busy}
                  className="rounded-full bg-white/10 px-4 py-2.5 text-[12px] font-bold uppercase text-white disabled:opacity-50"
                  onClick={() => void hireDiscord()}
                >
                  Send
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {toast ? (
        <div className="pointer-events-none absolute bottom-8 left-1/2 z-50 -translate-x-1/2 rounded-full bg-white px-4 py-2 text-[12px] font-bold text-black shadow-lg">
          {toast}
        </div>
      ) : null}
    </div>
  );
}
