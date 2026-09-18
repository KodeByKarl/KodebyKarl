import React, { useCallback, useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import {
  BatteryFull,
  DollarSign,
  Loader2,
  Megaphone,
  Search,
  Signal,
  UserMinus,
  UserPlus,
  Users,
  Wifi,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";
import { fetchNui } from "@/lib/nui";

export type DeptId = "police" | "sheriff" | "ambulance" | "pambulance" | "sambulance" | "doj";

type TabId = "funds" | "staff" | "online" | "announce";

type Grade = { grade: number; name: string; label: string };
type Employee = {
  identifier: string;
  name: string;
  job?: string;
  grade: number;
  gradeLabel: string;
  online: boolean;
  serverId?: number | null;
};
type LedgerRow = {
  id: number;
  action: string;
  amount: number;
  note?: string;
  createdAt?: string;
};
type Announcement = {
  id: number;
  title: string;
  body: string;
  author: string;
  priority?: boolean;
  createdAt?: string;
};
type NearbyPlayer = { id: number; name: string };

type Dashboard = {
  ok: boolean;
  error?: string;
  department?: string;
  label?: string;
  funds?: number;
  ledger?: LedgerRow[];
  employees?: Employee[];
  grades?: Grade[];
  announcements?: Announcement[];
  yourGrade?: number;
  onlineCount?: number;
};

const TABS: { id: TabId; label: string }[] = [
  { id: "funds", label: "Funds" },
  { id: "staff", label: "Roster" },
  { id: "online", label: "Online" },
  { id: "announce", label: "Announce" },
];

const ERR: Record<string, string> = {
  denied: "Boss access only.",
  invalid: "Invalid request.",
  no_cash: "Not enough cash.",
  no_funds: "Society funds are too low.",
  inventory_full: "Inventory is full.",
  offline: "That player is offline.",
  far: "Player is too far away.",
  grade: "You cannot set that rank.",
  self: "You cannot edit yourself.",
  not_employee: "Not on this roster.",
  society_offline: "Society account is offline.",
};

const THEME: Record<DeptId, { accent: string; header: string }> = {
  police: { accent: "#1d4ed8", header: "from-[#0b1b3a] to-[#122447]" },
  sheriff: { accent: "#b45309", header: "from-[#2a1a08] to-[#3d2a12]" },
  ambulance: { accent: "#b91c1c", header: "from-[#2a0c0c] to-[#3b1414]" },
  pambulance: { accent: "#9f1239", header: "from-[#2a0c0c] to-[#3b1414]" },
  sambulance: { accent: "#be123c", header: "from-[#2a0c0c] to-[#3b1414]" },
  doj: { accent: "#7c3aed", header: "from-[#1a0f2e] to-[#2e1a4a]" },
};

function money(n: number | undefined) {
  return `$${Math.floor(n || 0).toLocaleString()}`;
}

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

export default function DeptBossApp({
  player,
  department,
}: {
  player?: IpadPlayerData | null;
  department: DeptId;
}) {
  const theme = THEME[department];
  const [tab, setTab] = useState<TabId>("funds");
  const [loading, setLoading] = useState(true);
  const [dash, setDash] = useState<Dashboard | null>(null);
  const [amount, setAmount] = useState("");
  const [query, setQuery] = useState("");
  const [hireId, setHireId] = useState("");
  const [hireGrade, setHireGrade] = useState("0");
  const [nearby, setNearby] = useState<NearbyPlayer[]>([]);
  const [annTitle, setAnnTitle] = useState("");
  const [annBody, setAnnBody] = useState("");
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const flash = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    const result = await fetchNui<Dashboard>("cfx-keydi-ipad:dept:dashboard", { department });
    if (result?.ok) setDash(result);
    else {
      setDash(result || { ok: false });
      flash(ERR[result?.error || ""] || "Failed to load department.");
    }
    setLoading(false);
  }, [department, flash]);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    if (tab !== "staff") return;
    void fetchNui<{ ok: boolean; players?: NearbyPlayer[] }>("cfx-keydi-ipad:business:nearby").then(
      (res) => setNearby(res?.players || []),
    );
  }, [tab]);

  const employees = useMemo(() => {
    const list = dash?.employees || [];
    const q = query.trim().toLowerCase();
    if (!q) return list;
    return list.filter(
      (e) =>
        e.name.toLowerCase().includes(q) ||
        e.gradeLabel.toLowerCase().includes(q) ||
        (e.job || "").toLowerCase().includes(q),
    );
  }, [dash?.employees, query]);

  const online = useMemo(() => (dash?.employees || []).filter((e) => e.online), [dash?.employees]);

  const hireGrades = useMemo(() => {
    const your = dash?.yourGrade ?? 99;
    return (dash?.grades || []).filter((g) => g.grade < your);
  }, [dash?.grades, dash?.yourGrade]);

  const transfer = async (action: "deposit" | "withdraw") => {
    const n = Math.floor(Number(amount) || 0);
    if (n <= 0 || busy) return;
    setBusy(true);
    const result = await fetchNui<Dashboard>("cfx-keydi-ipad:dept:transfer", {
      department,
      action,
      amount: n,
    });
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Transfer failed.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, funds: result.funds, ledger: result.ledger } : prev));
    setAmount("");
    flash(action === "deposit" ? `Deposited ${money(n)}` : `Withdrew ${money(n)}`);
  };

  const hire = async () => {
    const id = Math.floor(Number(hireId) || 0);
    const grade = Math.floor(Number(hireGrade) || 0);
    if (!id || busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; error?: string; employees?: Employee[]; grades?: Grade[] }>(
      "cfx-keydi-ipad:dept:hire",
      { department, id, grade },
    );
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Hire failed.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, employees: result.employees, grades: result.grades } : prev));
    setHireId("");
    flash("Member hired.");
  };

  const setGrade = async (identifier: string, grade: number) => {
    if (busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; error?: string; employees?: Employee[]; grades?: Grade[] }>(
      "cfx-keydi-ipad:dept:setGrade",
      { department, identifier, grade },
    );
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Could not update rank.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, employees: result.employees, grades: result.grades } : prev));
    flash("Rank updated.");
  };

  const fire = async (identifier: string, name: string) => {
    if (busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; error?: string; employees?: Employee[]; grades?: Grade[] }>(
      "cfx-keydi-ipad:dept:fire",
      { department, identifier },
    );
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Could not remove member.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, employees: result.employees, grades: result.grades } : prev));
    flash(`${name} removed.`);
  };

  const postAnnounce = async () => {
    if (!annTitle.trim() || !annBody.trim() || busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; error?: string; announcements?: Announcement[] }>(
      "cfx-keydi-ipad:dept:announce",
      { department, title: annTitle, body: annBody, priority: false },
    );
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Could not post.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, announcements: result.announcements } : prev));
    setAnnTitle("");
    setAnnBody("");
    flash("Announcement posted to MDT.");
  };

  return (
    <div className={cn("absolute inset-0 flex flex-col select-none bg-[#0a0c12]", `bg-gradient-to-b ${theme.header}`)}>
      <StatusBar />
      <div className="border-b border-white/10 px-5 pb-3 pt-1">
        <p className="text-[18px] font-bold text-white">{dash?.label || "Department Boss"}</p>
        <p className="text-[11px] text-white/55">
          Live roster & society · {player?.firstName || "Boss"}
          {loading ? " · loading…" : ""}
        </p>
        <div className="mt-3 flex gap-1.5 overflow-x-auto no-scrollbar">
          {TABS.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              className={cn(
                "shrink-0 rounded-full px-3 py-1.5 text-[11px] font-bold",
                tab === t.id ? "text-white" : "bg-white/10 text-white/65",
              )}
              style={tab === t.id ? { backgroundColor: theme.accent } : undefined}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>

      <div className="no-scrollbar min-h-0 flex-1 overflow-y-auto px-4 py-3 pb-10">
        {loading && !dash?.ok ? (
          <div className="flex items-center justify-center gap-2 py-16 text-white/50">
            <Loader2 className="h-4 w-4 animate-spin" /> Loading…
          </div>
        ) : null}

        {tab === "funds" ? (
          <div className="space-y-3">
            <div className="rounded-2xl border border-white/10 bg-black/25 p-4">
              <p className="text-[10px] font-black uppercase tracking-wider text-white/45">Society balance</p>
              <p className="mt-1 text-[28px] font-black tabular-nums text-white">{money(dash?.funds)}</p>
              <div className="mt-3 flex gap-2">
                <input
                  value={amount}
                  onChange={(e) => setAmount(e.target.value.replace(/[^\d]/g, ""))}
                  placeholder="Amount"
                  className="min-w-0 flex-1 rounded-xl border border-white/10 bg-black/30 px-3 py-2.5 text-[13px] text-white outline-none"
                />
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void transfer("deposit")}
                  className="rounded-xl px-3 py-2 text-[12px] font-bold text-white"
                  style={{ backgroundColor: theme.accent }}
                >
                  Deposit
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void transfer("withdraw")}
                  className="rounded-xl bg-white/10 px-3 py-2 text-[12px] font-bold text-white"
                >
                  Withdraw
                </button>
              </div>
            </div>
            <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
              <p className="mb-2 text-[10px] font-black uppercase tracking-wider text-white/45">Ledger</p>
              {(dash?.ledger || []).length === 0 ? (
                <p className="py-4 text-center text-[12px] text-white/40">No transfers yet.</p>
              ) : (
                <div className="space-y-2">
                  {(dash?.ledger || []).map((row) => (
                    <div key={row.id} className="flex items-center justify-between text-[12px]">
                      <div className="flex items-center gap-2 text-white/70">
                        <DollarSign className="h-3.5 w-3.5" />
                        <span className="capitalize">{row.action}</span>
                      </div>
                      <span className="font-semibold tabular-nums text-white">{money(row.amount)}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        ) : null}

        {tab === "staff" ? (
          <div className="space-y-3">
            <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
              <p className="mb-2 text-[10px] font-black uppercase tracking-wider text-white/45">Hire nearby</p>
              <div className="flex flex-wrap gap-2">
                {nearby.map((p) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => setHireId(String(p.id))}
                    className={cn(
                      "rounded-full px-2.5 py-1 text-[11px] font-semibold",
                      hireId === String(p.id) ? "text-white" : "bg-white/10 text-white/70",
                    )}
                    style={hireId === String(p.id) ? { backgroundColor: theme.accent } : undefined}
                  >
                    {p.name} · {p.id}
                  </button>
                ))}
              </div>
              <div className="mt-2 flex gap-2">
                <input
                  value={hireId}
                  onChange={(e) => setHireId(e.target.value.replace(/[^\d]/g, ""))}
                  placeholder="Server ID"
                  className="w-24 rounded-xl border border-white/10 bg-black/30 px-2.5 py-2 text-[12px] text-white outline-none"
                />
                <select
                  value={hireGrade}
                  onChange={(e) => setHireGrade(e.target.value)}
                  className="min-w-0 flex-1 rounded-xl border border-white/10 bg-black/30 px-2 py-2 text-[12px] text-white outline-none"
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
                  onClick={() => void hire()}
                  className="flex items-center gap-1 rounded-xl px-3 py-2 text-[12px] font-bold text-white"
                  style={{ backgroundColor: theme.accent }}
                >
                  <UserPlus className="h-3.5 w-3.5" /> Hire
                </button>
              </div>
            </div>

            <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-black/25 px-3 py-2">
              <Search className="h-4 w-4 text-white/40" />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search roster"
                className="w-full bg-transparent text-[13px] text-white outline-none placeholder:text-white/35"
              />
            </div>

            <div className="overflow-hidden rounded-2xl border border-white/10 bg-black/25">
              {employees.length === 0 ? (
                <p className="py-8 text-center text-[12px] text-white/40">No members in database.</p>
              ) : (
                employees.map((e, i) => (
                  <div
                    key={e.identifier}
                    className={cn("flex items-center gap-3 px-3 py-2.5", i > 0 && "border-t border-white/8")}
                  >
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-[13px] font-semibold text-white">
                        {e.name}
                        {e.online ? (
                          <span className="ml-1.5 text-[10px] font-bold text-emerald-400">ONLINE</span>
                        ) : null}
                      </p>
                      <p className="text-[11px] text-white/45">
                        {e.gradeLabel}
                        {e.job ? ` · ${e.job}` : ""}
                      </p>
                    </div>
                    <select
                      value={e.grade}
                      onChange={(ev) => void setGrade(e.identifier, Number(ev.target.value))}
                      className="max-w-[110px] rounded-lg border border-white/10 bg-black/40 px-1.5 py-1 text-[10px] text-white"
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
                      onClick={() => void fire(e.identifier, e.name)}
                      className="rounded-lg bg-red-500/15 p-1.5 text-red-300"
                      title="Remove"
                    >
                      <UserMinus className="h-3.5 w-3.5" />
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>
        ) : null}

        {tab === "online" ? (
          <div className="overflow-hidden rounded-2xl border border-white/10 bg-black/25">
            {online.length === 0 ? (
              <div className="px-4 py-10 text-center">
                <Users className="mx-auto mb-2 h-7 w-7 text-white/25" />
                <p className="text-[12px] text-white/40">No one online in this department.</p>
              </div>
            ) : (
              online.map((e, i) => (
                <div
                  key={e.identifier}
                  className={cn("flex items-center justify-between px-3 py-2.5", i > 0 && "border-t border-white/8")}
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
        ) : null}

        {tab === "announce" ? (
          <div className="space-y-3">
            <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
              <input
                value={annTitle}
                onChange={(e) => setAnnTitle(e.target.value.slice(0, 120))}
                placeholder="Title"
                className="mb-2 w-full rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-[13px] text-white outline-none"
              />
              <textarea
                value={annBody}
                onChange={(e) => setAnnBody(e.target.value.slice(0, 500))}
                placeholder="Announcement body…"
                rows={3}
                className="w-full resize-none rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-[13px] text-white outline-none"
              />
              <button
                type="button"
                disabled={busy}
                onClick={() => void postAnnounce()}
                className="mt-2 flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-[13px] font-bold text-white"
                style={{ backgroundColor: theme.accent }}
              >
                <Megaphone className="h-4 w-4" /> Post to MDT
              </button>
            </div>
            {(dash?.announcements || []).map((a) => (
              <div key={a.id} className="rounded-2xl border border-white/10 bg-black/25 px-3 py-2.5">
                <p className="text-[13px] font-semibold text-white">{a.title}</p>
                <p className="mt-1 text-[12px] leading-relaxed text-white/65">{a.body}</p>
                <p className="mt-1.5 text-[10px] text-white/40">{a.author}</p>
              </div>
            ))}
          </div>
        ) : null}
      </div>

      {toast ? (
        <div className="pointer-events-none absolute bottom-8 left-1/2 z-50 -translate-x-1/2 rounded-full bg-white px-4 py-2 text-[12px] font-bold text-black shadow-lg">
          {toast}
        </div>
      ) : null}
    </div>
  );
}
