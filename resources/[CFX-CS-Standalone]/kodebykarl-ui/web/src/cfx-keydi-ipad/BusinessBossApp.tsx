import React, { useCallback, useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  BatteryFull,
  DollarSign,
  Loader2,
  Receipt,
  Search,
  Signal,
  Store,
  UserMinus,
  UserPlus,
  Users,
  Wifi,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";
import { fetchNui } from "@/lib/nui";

type TabId = "overview" | "staff" | "invoices";

type ChartPoint = { day: string; sales: number; income: number };
type Grade = { grade: number; name: string; label: string };
type Employee = {
  identifier: string;
  name: string;
  grade: number;
  gradeLabel: string;
  online: boolean;
  serverId?: number | null;
};
type InvoiceRow = {
  id: number;
  reference: string;
  title: string;
  total: number;
  status: string;
  senderName: string;
  receiverName: string;
  createdAt?: string;
  paidAt?: string | null;
};
type LedgerRow = {
  id: number;
  action: string;
  amount: number;
  note?: string;
  createdAt?: string;
};
type NearbyPlayer = { id: number; name: string };

type Dashboard = {
  ok: boolean;
  error?: string;
  job?: string;
  label?: string;
  funds?: number;
  sales?: number;
  income?: number;
  pending?: number;
  pendingAmount?: number;
  chart?: ChartPoint[];
  ledger?: LedgerRow[];
  employees?: Employee[];
  grades?: Grade[];
  invoices?: InvoiceRow[];
  yourGrade?: number;
};

const TABS: { id: TabId; label: string }[] = [
  { id: "overview", label: "Overview" },
  { id: "staff", label: "Employees" },
  { id: "invoices", label: "Invoice Logs" },
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

export default function BusinessBossApp({
  player,
}: {
  player?: IpadPlayerData | null;
}) {
  const [tab, setTab] = useState<TabId>("overview");
  const [loading, setLoading] = useState(true);
  const [dash, setDash] = useState<Dashboard | null>(null);
  const [amount, setAmount] = useState("");
  const [query, setQuery] = useState("");
  const [hireId, setHireId] = useState("");
  const [hireGrade, setHireGrade] = useState("0");
  const [nearby, setNearby] = useState<NearbyPlayer[]>([]);
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const flash = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    const result = await fetchNui<Dashboard>("cfx-keydi-ipad:business:dashboard");
    if (result?.ok) setDash(result);
    else {
      setDash(result || { ok: false });
      flash(ERR[result?.error || ""] || "Failed to load business.");
    }
    setLoading(false);
  }, [flash]);

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
      (e) => e.name.toLowerCase().includes(q) || e.gradeLabel.toLowerCase().includes(q),
    );
  }, [dash?.employees, query]);

  const hireGrades = useMemo(() => {
    const your = dash?.yourGrade ?? 99;
    return (dash?.grades || []).filter((g) => g.grade < your);
  }, [dash?.grades, dash?.yourGrade]);

  const transfer = async (action: "deposit" | "withdraw") => {
    const n = Math.floor(Number(amount) || 0);
    if (n <= 0 || busy) return;
    setBusy(true);
    const result = await fetchNui<Dashboard & { ok: boolean; error?: string }>(
      "cfx-keydi-ipad:business:transfer",
      { action, amount: n },
    );
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Transfer failed.");
      return;
    }
    setDash((prev) =>
      prev
        ? { ...prev, funds: result.funds, ledger: result.ledger, sales: result.sales ?? prev.sales, income: result.income ?? prev.income }
        : prev,
    );
    setAmount("");
    flash(action === "deposit" ? `Deposited ${money(n)}` : `Withdrew ${money(n)}`);
  };

  const hire = async () => {
    const id = Math.floor(Number(hireId) || 0);
    const grade = Math.floor(Number(hireGrade) || 0);
    if (!id || busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; error?: string; employees?: Employee[]; grades?: Grade[] }>(
      "cfx-keydi-ipad:business:hire",
      { id, grade },
    );
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Hire failed.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, employees: result.employees, grades: result.grades } : prev));
    setHireId("");
    flash("Employee hired.");
  };

  const setGrade = async (identifier: string, grade: number) => {
    if (busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; error?: string; employees?: Employee[]; grades?: Grade[] }>(
      "cfx-keydi-ipad:business:setGrade",
      { identifier, grade },
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
      "cfx-keydi-ipad:business:fire",
      { identifier },
    );
    setBusy(false);
    if (!result?.ok) {
      flash(ERR[result?.error || ""] || "Could not remove employee.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, employees: result.employees, grades: result.grades } : prev));
    flash(`${name} removed.`);
  };

  const chart = dash?.chart || [];

  return (
    <div
      className="absolute inset-0 flex flex-col select-none"
      style={{
        background:
          "radial-gradient(ellipse at 12% 0%, rgba(245,158,11,0.22), transparent 46%), linear-gradient(165deg, #120c06 0%, #1a140c 48%, #0c0a08 100%)",
      }}
    >
      <StatusBar />

      <div className="flex items-start justify-between gap-3 px-5 pb-2 pt-2">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <Store className="h-5 w-5 text-[#fbbf24]" strokeWidth={2.2} />
            <h1 className="text-[22px] font-bold tracking-wide text-white">
              {dash?.label || "Business"}
            </h1>
            <span className="rounded-md bg-[#b45309] px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-white">
              Boss
            </span>
          </div>
          <p className="mt-1 text-[12px] text-white/45">
            {[player?.firstName, player?.lastName].filter(Boolean).join(" ") || "Owner"} · Society funds · Staff · Invoices
          </p>
        </div>
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
                  ? "bg-[#d97706] text-white shadow-[0_4px_16px_rgba(217,119,6,0.35)]"
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

        {!loading && tab === "overview" && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div className="col-span-2 rounded-2xl border border-[#d97706]/35 bg-[#1c1408] p-5 shadow-lg">
                <p className="text-[12px] font-semibold uppercase tracking-[0.14em] text-[#fbbf24]">
                  Society funds
                </p>
                <p className="mt-2 text-[36px] font-bold tracking-tight text-white">
                  {money(dash?.funds)}
                </p>
                <p className="mt-1 text-[13px] text-white/40">
                  {dash?.label || "Business"} operating account
                </p>
              </div>
              <div className="rounded-2xl border border-white/8 bg-[#17120c] p-4">
                <p className="text-[11px] font-semibold uppercase tracking-wider text-white/40">Total sales</p>
                <p className="mt-1 text-[22px] font-bold text-white">{(dash?.sales || 0).toLocaleString()}</p>
                <p className="text-[12px] text-white/35">Paid invoices</p>
              </div>
              <div className="rounded-2xl border border-white/8 bg-[#17120c] p-4">
                <p className="text-[11px] font-semibold uppercase tracking-wider text-white/40">Total income</p>
                <p className="mt-1 text-[22px] font-bold text-[#4ade80]">{money(dash?.income)}</p>
                <p className="text-[12px] text-white/35">
                  {(dash?.pending || 0).toLocaleString()} unpaid · {money(dash?.pendingAmount)}
                </p>
              </div>
            </div>

            <div className="rounded-2xl border border-white/8 bg-[#17120c] p-4">
              <p className="mb-3 text-[14px] font-semibold text-white">Sales · last 14 days</p>
              <div className="h-[180px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={chart} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                    <defs>
                      <linearGradient id="incomeFill" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#f59e0b" stopOpacity={0.45} />
                        <stop offset="100%" stopColor="#f59e0b" stopOpacity={0.02} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid stroke="rgba(255,255,255,0.06)" vertical={false} />
                    <XAxis dataKey="day" tick={{ fill: "rgba(255,255,255,0.4)", fontSize: 11 }} axisLine={false} tickLine={false} />
                    <YAxis
                      tick={{ fill: "rgba(255,255,255,0.35)", fontSize: 11 }}
                      axisLine={false}
                      tickLine={false}
                      width={48}
                      tickFormatter={(v) => (v >= 1000 ? `${Math.round(v / 1000)}k` : String(v))}
                    />
                    <Tooltip
                      contentStyle={{
                        background: "#1c1408",
                        border: "1px solid rgba(245,158,11,0.35)",
                        borderRadius: 12,
                        color: "white",
                        fontSize: 12,
                      }}
                      formatter={(value, name) => [
                        name === "income" ? money(Number(value)) : Number(value).toLocaleString(),
                        name === "income" ? "Income" : "Sales",
                      ]}
                    />
                    <Area type="monotone" dataKey="income" stroke="#f59e0b" strokeWidth={2.2} fill="url(#incomeFill)" />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="rounded-2xl border border-white/8 bg-[#17120c] p-4">
              <p className="mb-3 text-[14px] font-semibold text-white">Deposit / Withdraw</p>
              <div className="flex flex-wrap items-center gap-2">
                <div className="flex flex-1 items-center gap-2 rounded-xl border border-white/10 bg-black/35 px-3 py-2.5">
                  <DollarSign className="h-4 w-4 text-white/40" />
                  <input
                    type="number"
                    min={0}
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="Amount"
                    className="w-full min-w-[120px] bg-transparent text-[15px] font-semibold text-white outline-none"
                  />
                </div>
                <button
                  type="button"
                  disabled={busy}
                  className="rounded-full bg-[#16a34a] px-4 py-2.5 text-[12px] font-bold uppercase text-white disabled:opacity-50"
                  onClick={() => void transfer("deposit")}
                >
                  Deposit
                </button>
                <button
                  type="button"
                  disabled={busy}
                  className="rounded-full bg-[#dc2626] px-4 py-2.5 text-[12px] font-bold uppercase text-white disabled:opacity-50"
                  onClick={() => void transfer("withdraw")}
                >
                  Withdraw
                </button>
              </div>
            </div>

            <div className="rounded-2xl border border-white/8 bg-[#17120c] p-4">
              <p className="mb-2 text-[13px] font-semibold text-white/70">Recent ledger</p>
              <div className="space-y-2 text-[13px]">
                {(dash?.ledger || []).length === 0 && (
                  <p className="text-white/35">No society transfers yet.</p>
                )}
                {(dash?.ledger || []).map((row) => (
                  <div key={row.id} className="flex justify-between text-white/70">
                    <span className="truncate pr-3">
                      {row.action} {row.note ? `· ${row.note}` : ""}
                    </span>
                    <span
                      className={cn(
                        "font-semibold",
                        row.action === "withdraw" ? "text-[#f87171]" : "text-[#4ade80]",
                      )}
                    >
                      {row.action === "withdraw" ? "-" : "+"}
                      {money(row.amount)}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {!loading && tab === "staff" && (
          <div className="space-y-3">
            <div className="rounded-2xl border border-white/8 bg-[#17120c] p-4">
              <p className="mb-3 text-[14px] font-semibold text-white">Hire nearby</p>
              <div className="flex flex-wrap gap-2">
                <select
                  value={hireId}
                  onChange={(e) => setHireId(e.target.value)}
                  className="min-w-[160px] flex-1 rounded-xl border border-white/10 bg-black/35 px-3 py-2.5 text-[13px] text-white outline-none"
                >
                  <option value="">Select player</option>
                  {nearby.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name} (#{p.id})
                    </option>
                  ))}
                </select>
                <select
                  value={hireGrade}
                  onChange={(e) => setHireGrade(e.target.value)}
                  className="rounded-xl border border-white/10 bg-black/35 px-3 py-2.5 text-[13px] text-white outline-none"
                >
                  {hireGrades.map((g) => (
                    <option key={g.grade} value={g.grade}>
                      {g.label}
                    </option>
                  ))}
                </select>
                <button
                  type="button"
                  disabled={busy}
                  className="inline-flex items-center gap-1.5 rounded-full bg-[#d97706] px-4 py-2.5 text-[12px] font-bold uppercase text-white disabled:opacity-50"
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

            <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-[#17120c] px-3 py-2.5">
              <Search className="h-4 w-4 text-white/35" />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search employees"
                className="w-full bg-transparent text-[13px] text-white outline-none"
              />
            </div>

            {employees.map((emp) => (
              <div
                key={emp.identifier}
                className="flex flex-wrap items-center justify-between gap-2 rounded-2xl border border-white/8 bg-[#17120c] px-4 py-3"
              >
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <Users className="h-4 w-4 text-white/40" />
                    <p className="truncate text-[14px] font-semibold text-white">{emp.name}</p>
                    <span
                      className={cn(
                        "h-2 w-2 rounded-full",
                        emp.online ? "bg-[#4ade80]" : "bg-white/25",
                      )}
                    />
                  </div>
                  <p className="mt-0.5 text-[12px] text-white/40">{emp.gradeLabel}</p>
                </div>
                <div className="flex items-center gap-2">
                  {emp.grade < (dash?.yourGrade ?? 0) ? (
                    <>
                      <select
                        value={emp.grade}
                        disabled={busy}
                        onChange={(e) => void setGrade(emp.identifier, Number(e.target.value))}
                        className="rounded-lg border border-white/10 bg-black/35 px-2 py-1.5 text-[12px] text-white outline-none"
                      >
                        {hireGrades.map((g) => (
                          <option key={g.grade} value={g.grade}>
                            {g.label}
                          </option>
                        ))}
                        {!hireGrades.some((g) => g.grade === emp.grade) && (
                          <option value={emp.grade}>{emp.gradeLabel}</option>
                        )}
                      </select>
                      <button
                        type="button"
                        disabled={busy}
                        className="inline-flex items-center gap-1 rounded-full bg-[#dc2626]/90 px-3 py-1.5 text-[11px] font-bold uppercase text-white disabled:opacity-50"
                        onClick={() => void fire(emp.identifier, emp.name)}
                      >
                        <UserMinus className="h-3.5 w-3.5" />
                        Fire
                      </button>
                    </>
                  ) : (
                    <span className="text-[12px] text-white/35">Owner</span>
                  )}
                </div>
              </div>
            ))}
            {employees.length === 0 && (
              <p className="py-8 text-center text-[13px] text-white/35">No employees on roster.</p>
            )}
          </div>
        )}

        {!loading && tab === "invoices" && (
          <div className="space-y-2">
            <div className="mb-3 flex items-center gap-2 text-white/70">
              <Receipt className="h-4 w-4" />
              <p className="text-[13px] font-semibold">Linked to Billing / Invoice</p>
            </div>
            {(dash?.invoices || []).map((inv) => (
              <div
                key={inv.id}
                className="rounded-2xl border border-white/8 bg-[#17120c] px-4 py-3"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="truncate text-[14px] font-semibold text-white">{inv.title}</p>
                    <p className="mt-0.5 text-[12px] text-white/40">
                      #{inv.reference} · {inv.senderName} → {inv.receiverName}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-[14px] font-bold text-white">{money(inv.total)}</p>
                    <span
                      className={cn(
                        "text-[11px] font-bold uppercase",
                        inv.status === "paid" ? "text-[#4ade80]" : inv.status === "unpaid" ? "text-[#fbbf24]" : "text-white/40",
                      )}
                    >
                      {inv.status}
                    </span>
                  </div>
                </div>
              </div>
            ))}
            {(dash?.invoices || []).length === 0 && (
              <p className="py-10 text-center text-[13px] text-white/35">
                No invoices for this business yet. Use /billing to send job invoices.
              </p>
            )}
          </div>
        )}
      </div>

      {toast && (
        <div className="pointer-events-none absolute bottom-8 left-1/2 z-50 -translate-x-1/2 rounded-full bg-black/80 px-4 py-2 text-[12px] font-semibold text-white shadow-lg">
          {toast}
        </div>
      )}
    </div>
  );
}
