import React, { useCallback, useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import {
  BatteryFull,
  ClipboardList,
  FileText,
  Loader2,
  Plus,
  Radio,
  Receipt,
  Search,
  Signal,
  Siren,
  Trash2,
  Users,
  Wifi,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";
import { fetchNui } from "@/lib/nui";
import type { DeptId } from "./DeptBossApp";

type TabId = "home" | "announce" | "units" | "bolos" | "cases" | "fines";

type Unit = {
  serverId: number;
  name: string;
  job?: string;
  gradeLabel?: string;
  callsign?: string;
};

type Announcement = {
  id: number;
  title: string;
  body: string;
  author: string;
  priority?: boolean;
  createdAt?: string | number;
};

type Bolo = {
  id: number;
  plate: string;
  description: string;
  author: string;
  createdAt?: string | number;
};

type CaseRecord = {
  id: number | string;
  source?: string;
  suspectName: string;
  identifier?: string | null;
  charges: string;
  notes?: string | null;
  officerName?: string;
  createdAt?: string | number;
};

type FineRecord = {
  id: number;
  reference?: string;
  title: string;
  description?: string | null;
  total: number;
  status?: string;
  officerName?: string;
  citizenName?: string;
  identifier?: string | null;
  createdAt?: string | number;
};

type Dashboard = {
  ok: boolean;
  error?: string;
  label?: string;
  units?: Unit[];
  announcements?: Announcement[];
  bolos?: Bolo[];
  cases?: CaseRecord[];
  fines?: FineRecord[];
  onlineCount?: number;
  canAnnounce?: boolean;
};

const TABS: { id: TabId; label: string }[] = [
  { id: "home", label: "Home" },
  { id: "announce", label: "Announce" },
  { id: "units", label: "Units" },
  { id: "bolos", label: "BOLOs" },
  { id: "cases", label: "Cases" },
  { id: "fines", label: "Fines" },
];

const THEME: Record<"police" | "sheriff", { accent: string; header: string }> = {
  police: { accent: "#1e3a8a", header: "from-[#081226] to-[#122447]" },
  sheriff: { accent: "#92400e", header: "from-[#1f1408] to-[#3d2a12]" },
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

function formatWhen(value?: string | number | null) {
  if (value == null || value === "") return "";
  let d: Date;
  if (typeof value === "number" && Number.isFinite(value)) {
    d = new Date(value < 1e12 ? value * 1000 : value);
  } else {
    const s = String(value);
    if (/^\d+(\.\d+)?$/.test(s)) {
      const n = Number(s);
      d = new Date(n < 1e12 ? n * 1000 : n);
    } else {
      d = new Date(s.includes("T") ? s : s.replace(" ", "T"));
    }
  }
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleString([], { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
}

export default function LeoMdtApp({
  player,
  department,
}: {
  player?: IpadPlayerData | null;
  department: Extract<DeptId, "police" | "sheriff">;
}) {
  const theme = THEME[department];
  const [tab, setTab] = useState<TabId>("home");
  const [loading, setLoading] = useState(true);
  const [dash, setDash] = useState<Dashboard | null>(null);
  const [query, setQuery] = useState("");
  const [plate, setPlate] = useState("");
  const [desc, setDesc] = useState("");
  const [recordQuery, setRecordQuery] = useState("");
  const [suspectName, setSuspectName] = useState("");
  const [charges, setCharges] = useState("");
  const [caseNotes, setCaseNotes] = useState("");
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const flash = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    const result = await fetchNui<Dashboard>("cfx-keydi-ipad:mdt:dashboard", { department });
    if (result?.ok) setDash(result);
    else {
      setDash(result || { ok: false });
      flash(result?.error === "denied" ? "MDT access denied." : "Failed to load MDT.");
    }
    setLoading(false);
  }, [department, flash]);

  useEffect(() => {
    void load();
  }, [load]);

  const announcements = useMemo(() => {
    const list = dash?.announcements || [];
    const q = query.trim().toLowerCase();
    if (!q || tab !== "announce") return list;
    return list.filter((a) =>
      [a.title, a.body, a.author].some((field) => String(field || "").toLowerCase().includes(q)),
    );
  }, [dash?.announcements, query, tab]);

  const addBolo = async () => {
    if (!desc.trim() || busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; error?: string; bolos?: Bolo[] }>(
      "cfx-keydi-ipad:mdt:addBolo",
      { department, plate, description: desc },
    );
    setBusy(false);
    if (!result?.ok) {
      flash("Could not add BOLO.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, bolos: result.bolos } : prev));
    setPlate("");
    setDesc("");
    flash("BOLO posted.");
  };

  const removeBolo = async (id: number) => {
    if (busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; bolos?: Bolo[] }>("cfx-keydi-ipad:mdt:removeBolo", {
      department,
      id,
    });
    setBusy(false);
    if (!result?.ok) {
      flash("Could not remove BOLO.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, bolos: result.bolos } : prev));
    flash("BOLO cleared.");
  };

  const searchRecords = async () => {
    if (busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; cases?: CaseRecord[]; fines?: FineRecord[] }>(
      "cfx-keydi-ipad:mdt:search",
      { department, query: recordQuery },
    );
    setBusy(false);
    if (!result?.ok) {
      flash("Search failed.");
      return;
    }
    setDash((prev) =>
      prev ? { ...prev, cases: result.cases || [], fines: result.fines || [] } : prev,
    );
  };

  const addCase = async () => {
    if (!suspectName.trim() || !charges.trim() || busy) return;
    setBusy(true);
    const result = await fetchNui<{ ok: boolean; cases?: CaseRecord[] }>("cfx-keydi-ipad:mdt:addCase", {
      department,
      suspectName,
      charges,
      notes: caseNotes,
    });
    setBusy(false);
    if (!result?.ok) {
      flash("Could not file case.");
      return;
    }
    setDash((prev) => (prev ? { ...prev, cases: result.cases } : prev));
    setSuspectName("");
    setCharges("");
    setCaseNotes("");
    flash("Case filed.");
  };

  const latest = dash?.announcements?.[0];

  return (
    <div className={cn("absolute inset-0 flex flex-col select-none bg-[#0a0c12]", `bg-gradient-to-b ${theme.header}`)}>
      <StatusBar />
      <div className="border-b border-white/10 px-5 pb-3 pt-1">
        <div className="flex items-center gap-2">
          <ClipboardList className="h-5 w-5 text-white/80" />
          <div>
            <p className="text-[17px] font-bold text-white">{dash?.label || "MDT"}</p>
            <p className="text-[11px] text-white/50">
              Cases, fines, units & BOLOs · {player?.firstName || "Officer"}
            </p>
          </div>
        </div>
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
            <Loader2 className="h-4 w-4 animate-spin" /> Loading MDT…
          </div>
        ) : null}

        {tab === "home" ? (
          <div className="space-y-3">
            <div className="grid grid-cols-2 gap-2">
              <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
                <p className="text-[9px] font-black uppercase tracking-wider text-white/45">Units online</p>
                <p className="mt-1 text-[24px] font-black text-white">{dash?.onlineCount || 0}</p>
              </div>
              <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
                <p className="text-[9px] font-black uppercase tracking-wider text-white/45">Active BOLOs</p>
                <p className="mt-1 text-[24px] font-black text-white">{dash?.bolos?.length || 0}</p>
              </div>
              <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
                <p className="text-[9px] font-black uppercase tracking-wider text-white/45">Cases</p>
                <p className="mt-1 text-[24px] font-black text-white">{dash?.cases?.length || 0}</p>
              </div>
              <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
                <p className="text-[9px] font-black uppercase tracking-wider text-white/45">Fines</p>
                <p className="mt-1 text-[24px] font-black text-white">{dash?.fines?.length || 0}</p>
              </div>
            </div>
            <div className="rounded-2xl border border-white/10 bg-black/25 p-3.5">
              <div className="mb-1 flex items-center gap-2 text-white/70">
                <Radio className="h-4 w-4" />
                <p className="text-[10px] font-black uppercase tracking-wider">Latest announcement</p>
              </div>
              {latest ? (
                <>
                  <p className="text-[14px] font-semibold text-white">{latest.title}</p>
                  <p className="mt-1 text-[12px] leading-relaxed text-white/65">{latest.body}</p>
                  <p className="mt-2 text-[10px] text-white/40">
                    {latest.author} · {formatWhen(latest.createdAt)}
                  </p>
                </>
              ) : (
                <p className="py-4 text-center text-[12px] text-white/40">No announcements yet.</p>
              )}
            </div>
          </div>
        ) : null}

        {tab === "announce" ? (
          <div className="space-y-3">
            <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-black/25 px-3 py-2">
              <Search className="h-4 w-4 text-white/40" />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search announcements"
                className="w-full bg-transparent text-[13px] text-white outline-none placeholder:text-white/35"
              />
            </div>
            {announcements.length === 0 ? (
              <p className="py-10 text-center text-[12px] text-white/40">No announcements.</p>
            ) : (
              announcements.map((a) => (
                <div key={a.id} className="rounded-2xl border border-white/10 bg-black/25 px-3.5 py-3">
                  <div className="flex items-start justify-between gap-2">
                    <p className="text-[14px] font-semibold text-white">{a.title}</p>
                    {a.priority ? (
                      <Siren className="h-4 w-4 shrink-0 text-amber-400" />
                    ) : null}
                  </div>
                  <p className="mt-1 text-[12px] leading-relaxed text-white/65">{a.body}</p>
                  <p className="mt-2 text-[10px] text-white/40">
                    {a.author} · {formatWhen(a.createdAt)}
                  </p>
                </div>
              ))
            )}
          </div>
        ) : null}

        {tab === "units" ? (
          <div className="overflow-hidden rounded-2xl border border-white/10 bg-black/25">
            {(dash?.units || []).length === 0 ? (
              <div className="px-4 py-10 text-center">
                <Users className="mx-auto mb-2 h-7 w-7 text-white/25" />
                <p className="text-[12px] text-white/40">No units online.</p>
              </div>
            ) : (
              (dash?.units || []).map((u, i) => (
                <div
                  key={`${u.serverId}-${u.name}`}
                  className={cn("flex items-center justify-between px-3 py-2.5", i > 0 && "border-t border-white/8")}
                >
                  <div>
                    <p className="text-[13px] font-semibold text-white">{u.name}</p>
                    <p className="text-[11px] text-white/45">
                      {u.callsign} · {u.gradeLabel || u.job}
                    </p>
                  </div>
                  <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-bold text-emerald-300">
                    #{u.serverId}
                  </span>
                </div>
              ))
            )}
          </div>
        ) : null}

        {tab === "bolos" ? (
          <div className="space-y-3">
            <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
              <input
                value={plate}
                onChange={(e) => setPlate(e.target.value.slice(0, 20).toUpperCase())}
                placeholder="Plate (optional)"
                className="mb-2 w-full rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-[13px] text-white outline-none"
              />
              <textarea
                value={desc}
                onChange={(e) => setDesc(e.target.value.slice(0, 400))}
                placeholder="BOLO description…"
                rows={3}
                className="w-full resize-none rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-[13px] text-white outline-none"
              />
              <button
                type="button"
                disabled={busy || !desc.trim()}
                onClick={() => void addBolo()}
                className="mt-2 flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-[13px] font-bold text-white disabled:opacity-40"
                style={{ backgroundColor: theme.accent }}
              >
                <Plus className="h-4 w-4" /> Add BOLO
              </button>
            </div>
            {(dash?.bolos || []).map((b) => (
              <div key={b.id} className="rounded-2xl border border-white/10 bg-black/25 px-3.5 py-3">
                <div className="flex items-start justify-between gap-2">
                  <p className="text-[13px] font-black tracking-wide text-amber-300">{b.plate}</p>
                  <button
                    type="button"
                    onClick={() => void removeBolo(b.id)}
                    className="rounded-lg bg-red-500/15 p-1.5 text-red-300"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
                <p className="mt-1 text-[12px] leading-relaxed text-white/70">{b.description}</p>
                <p className="mt-2 text-[10px] text-white/40">
                  {b.author} · {formatWhen(b.createdAt)}
                </p>
              </div>
            ))}
          </div>
        ) : null}

        {tab === "cases" ? (
          <div className="space-y-3">
            <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-black/25 px-3 py-2">
              <Search className="h-4 w-4 text-white/40" />
              <input
                value={recordQuery}
                onChange={(e) => setRecordQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") void searchRecords();
                }}
                placeholder="Search suspect, charges, officer…"
                className="w-full bg-transparent text-[13px] text-white outline-none placeholder:text-white/35"
              />
              <button
                type="button"
                disabled={busy}
                onClick={() => void searchRecords()}
                className="shrink-0 rounded-lg px-2 py-1 text-[11px] font-bold text-white/80"
                style={{ backgroundColor: theme.accent }}
              >
                Search
              </button>
            </div>
            <div className="rounded-2xl border border-white/10 bg-black/25 p-3">
              <input
                value={suspectName}
                onChange={(e) => setSuspectName(e.target.value.slice(0, 80))}
                placeholder="Suspect name"
                className="mb-2 w-full rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-[13px] text-white outline-none"
              />
              <input
                value={charges}
                onChange={(e) => setCharges(e.target.value.slice(0, 255))}
                placeholder="Charges"
                className="mb-2 w-full rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-[13px] text-white outline-none"
              />
              <textarea
                value={caseNotes}
                onChange={(e) => setCaseNotes(e.target.value.slice(0, 500))}
                placeholder="Notes (optional)"
                rows={2}
                className="w-full resize-none rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-[13px] text-white outline-none"
              />
              <button
                type="button"
                disabled={busy || !suspectName.trim() || !charges.trim()}
                onClick={() => void addCase()}
                className="mt-2 flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-[13px] font-bold text-white disabled:opacity-40"
                style={{ backgroundColor: theme.accent }}
              >
                <Plus className="h-4 w-4" /> File case
              </button>
            </div>
            {(dash?.cases || []).length === 0 ? (
              <div className="px-4 py-10 text-center">
                <FileText className="mx-auto mb-2 h-7 w-7 text-white/25" />
                <p className="text-[12px] text-white/40">No cases on file.</p>
              </div>
            ) : (
              (dash?.cases || []).map((c) => (
                <div key={String(c.id)} className="rounded-2xl border border-white/10 bg-black/25 px-3.5 py-3">
                  <p className="text-[14px] font-semibold text-white">{c.suspectName}</p>
                  <p className="mt-1 text-[12px] leading-relaxed text-white/70">{c.charges}</p>
                  {c.notes ? <p className="mt-1 text-[11px] text-white/45">{c.notes}</p> : null}
                  <p className="mt-2 text-[10px] text-white/40">
                    {c.officerName || "Officer"} · {formatWhen(c.createdAt) || "record"}
                  </p>
                </div>
              ))
            )}
          </div>
        ) : null}

        {tab === "fines" ? (
          <div className="space-y-3">
            <div className="flex items-center gap-2 rounded-xl border border-white/10 bg-black/25 px-3 py-2">
              <Search className="h-4 w-4 text-white/40" />
              <input
                value={recordQuery}
                onChange={(e) => setRecordQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") void searchRecords();
                }}
                placeholder="Search citizen, reference, title…"
                className="w-full bg-transparent text-[13px] text-white outline-none placeholder:text-white/35"
              />
              <button
                type="button"
                disabled={busy}
                onClick={() => void searchRecords()}
                className="shrink-0 rounded-lg px-2 py-1 text-[11px] font-bold text-white/80"
                style={{ backgroundColor: theme.accent }}
              >
                Search
              </button>
            </div>
            {(dash?.fines || []).length === 0 ? (
              <div className="px-4 py-10 text-center">
                <Receipt className="mx-auto mb-2 h-7 w-7 text-white/25" />
                <p className="text-[12px] text-white/40">No LEO fines on file. Issue them from /billing.</p>
              </div>
            ) : (
              (dash?.fines || []).map((f) => (
                <div key={f.id} className="rounded-2xl border border-white/10 bg-black/25 px-3.5 py-3">
                  <div className="flex items-start justify-between gap-2">
                    <p className="text-[14px] font-semibold text-white">{f.citizenName || "Citizen"}</p>
                    <span
                      className={cn(
                        "rounded-full px-2 py-0.5 text-[10px] font-bold uppercase",
                        f.status === "paid" ? "bg-emerald-500/15 text-emerald-300" : "bg-amber-500/15 text-amber-300",
                      )}
                    >
                      {f.status || "unpaid"}
                    </span>
                  </div>
                  <p className="mt-1 text-[12px] text-white/70">{f.title}</p>
                  {f.description ? <p className="mt-0.5 text-[11px] text-white/45">{f.description}</p> : null}
                  <p className="mt-2 text-[12px] font-bold text-white">${Number(f.total || 0).toLocaleString()}</p>
                  <p className="mt-1 text-[10px] text-white/40">
                    {f.reference ? `${f.reference} · ` : ""}
                    {f.officerName || "Officer"} · {formatWhen(f.createdAt)}
                  </p>
                </div>
              ))
            )}
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
