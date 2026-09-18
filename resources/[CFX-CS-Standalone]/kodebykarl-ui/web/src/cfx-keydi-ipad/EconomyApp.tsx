import React, { useCallback, useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import {
  BatteryFull,
  Briefcase,
  Check,
  DollarSign,
  Loader2,
  RefreshCw,
  Search,
  Signal,
  Wifi,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";

export interface EconomyGrade {
  grade: number;
  name: string;
  label: string;
  salary: number;
}

export interface EconomyJob {
  name: string;
  label: string;
  grades: EconomyGrade[];
}

const MOCK_JOBS: EconomyJob[] = [
  {
    name: "ambulance",
    label: "EMS",
    grades: [
      { grade: 0, name: "intern", label: "Intern", salary: 65000 },
      { grade: 1, name: "nurse", label: "Nurse", salary: 70000 },
      { grade: 2, name: "head_nurse", label: "Head Nurse", salary: 75000 },
      { grade: 3, name: "resident_doctor", label: "Resident Doctor", salary: 80000 },
      { grade: 4, name: "senior_resident_doctor", label: "Senior Resident Doctor", salary: 85000 },
      { grade: 5, name: "assistant_director", label: "Assistant Director", salary: 90000 },
      { grade: 6, name: "boss", label: "Medical Director", salary: 100000 },
    ],
  },
  {
    name: "mechanic",
    label: "Mechanic",
    grades: [
      { grade: 0, name: "recruit", label: "Recruit", salary: 0 },
      { grade: 1, name: "employee", label: "Mechanic", salary: 0 },
      { grade: 2, name: "lead", label: "Lead Mechanic", salary: 0 },
      { grade: 3, name: "boss", label: "Boss", salary: 0 },
    ],
  },
  {
    name: "8ball",
    label: "8Ball",
    grades: [
      { grade: 0, name: "trainee", label: "Trainee", salary: 0 },
      { grade: 1, name: "staff", label: "Staff", salary: 0 },
      { grade: 2, name: "manager", label: "Manager", salary: 0 },
      { grade: 3, name: "boss", label: "Owner", salary: 0 },
    ],
  },
  {
    name: "burgershot",
    label: "Burger Shot",
    grades: [
      { grade: 0, name: "trainee", label: "Trainee", salary: 0 },
      { grade: 1, name: "crew", label: "Crew", salary: 0 },
      { grade: 2, name: "manager", label: "Manager", salary: 0 },
      { grade: 3, name: "boss", label: "Owner", salary: 0 },
    ],
  },
  {
    name: "uwu",
    label: "UwU Cafe",
    grades: [
      { grade: 0, name: "trainee", label: "Trainee", salary: 0 },
      { grade: 1, name: "barista", label: "Barista", salary: 0 },
      { grade: 2, name: "manager", label: "Manager", salary: 0 },
      { grade: 3, name: "boss", label: "Owner", salary: 0 },
    ],
  },
  {
    name: "tacoshop",
    label: "Taco Shop",
    grades: [
      { grade: 0, name: "trainee", label: "Trainee", salary: 0 },
      { grade: 1, name: "cook", label: "Cook", salary: 0 },
      { grade: 2, name: "manager", label: "Manager", salary: 0 },
      { grade: 3, name: "boss", label: "Owner", salary: 0 },
    ],
  },
  {
    name: "weedshop",
    label: "Weed Shop",
    grades: [
      { grade: 0, name: "trimmer", label: "Trimmer", salary: 0 },
      { grade: 1, name: "budtender", label: "Budtender", salary: 0 },
      { grade: 2, name: "manager", label: "Manager", salary: 0 },
      { grade: 3, name: "boss", label: "Owner", salary: 0 },
    ],
  },
  {
    name: "police",
    label: "Police",
    grades: [
      { grade: 0, name: "cadet", label: "Cadet", salary: 60000 },
      { grade: 1, name: "officer", label: "Police Officer", salary: 65000 },
      { grade: 2, name: "senior", label: "Senior Police Officer", salary: 70000 },
      { grade: 3, name: "captain", label: "Captain", salary: 75000 },
      { grade: 4, name: "deputy", label: "Deputy Chief", salary: 80000 },
      { grade: 5, name: "chief", label: "Chief of Police", salary: 100000 },
      { grade: 6, name: "director", label: "Director", salary: 120000 },
    ],
  },
  {
    name: "student",
    label: "Student",
    grades: [{ grade: 0, name: "student", label: "Student", salary: 0 }],
  },
  {
    name: "teacher",
    label: "Teacher",
    grades: [
      { grade: 0, name: "teacher", label: "Teacher", salary: 50000 },
      { grade: 1, name: "dean", label: "Dean", salary: 70000 },
    ],
  },
  {
    name: "unemployed",
    label: "Unemployed",
    grades: [{ grade: 0, name: "unemployed", label: "Unemployed", salary: 200 }],
  },
];

async function nui<T>(event: string, data: Record<string, unknown> = {}): Promise<T | null> {
  const isBrowser =
    !(window as unknown as { invokeNative?: unknown }).invokeNative &&
    !navigator.userAgent.includes("FiveM") &&
    !navigator.userAgent.includes("CitizenFX");
  if (isBrowser) return null;
  const resourceName = (window as unknown as { GetParentResourceName?: () => string })
    .GetParentResourceName
    ? (window as unknown as { GetParentResourceName: () => string }).GetParentResourceName()
    : "kodebykarl-ui";
  try {
    const res = await fetch(`https://${resourceName}/${event}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data),
    });
    return (await res.json()) as T;
  } catch {
    return null;
  }
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

export default function EconomyApp({
  player,
}: {
  player?: IpadPlayerData | null;
}) {
  const [jobs, setJobs] = useState<EconomyJob[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<string | null>(null);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const applyJobs = useCallback((list: EconomyJob[]) => {
    setJobs(list);
    setSelected((prev) => {
      if (prev && list.some((j) => j.name === prev)) return prev;
      return list[0]?.name ?? null;
    });
    const next: Record<string, string> = {};
    for (const job of list) {
      for (const g of job.grades) {
        next[`${job.name}:${g.grade}`] = String(g.salary);
      }
    }
    setDrafts(next);
  }, []);

  const loadJobs = useCallback(async () => {
    setLoading(true);
    const isBrowser =
      !(window as unknown as { invokeNative?: unknown }).invokeNative &&
      !navigator.userAgent.includes("FiveM") &&
      !navigator.userAgent.includes("CitizenFX");

    if (isBrowser) {
      applyJobs(MOCK_JOBS);
      setLoading(false);
      return;
    }

    const result = await nui<{ ok: boolean; jobs?: EconomyJob[]; error?: string }>(
      "cfx-keydi-ipad:economy:getJobs",
    );
    if (result?.ok && result.jobs) {
      applyJobs(result.jobs);
    } else {
      showToast(result?.error === "denied" ? "Access denied" : "Failed to load jobs");
      applyJobs([]);
    }
    setLoading(false);
  }, [applyJobs, showToast]);

  useEffect(() => {
    void loadJobs();
  }, [loadJobs]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return jobs;
    return jobs.filter(
      (j) =>
        j.label.toLowerCase().includes(q) ||
        j.name.toLowerCase().includes(q),
    );
  }, [jobs, query]);

  const active = useMemo(
    () => jobs.find((j) => j.name === selected) ?? null,
    [jobs, selected],
  );

  const saveGrade = async (jobName: string, grade: number) => {
    const key = `${jobName}:${grade}`;
    // CEF number inputs are flaky — parse digits from text draft
    const raw = String(drafts[key] ?? "").replace(/[^\d]/g, "");
    const salary = Math.max(0, Math.min(2147483647, Math.floor(Number(raw) || 0)));
    setSaving(key);
    setDrafts((d) => ({ ...d, [key]: String(salary) }));

    const isBrowser =
      !(window as unknown as { invokeNative?: unknown }).invokeNative &&
      !navigator.userAgent.includes("FiveM") &&
      !navigator.userAgent.includes("CitizenFX");

    if (isBrowser) {
      setJobs((prev) =>
        prev.map((j) =>
          j.name !== jobName
            ? j
            : {
                ...j,
                grades: j.grades.map((g) =>
                  g.grade === grade ? { ...g, salary } : g,
                ),
              },
        ),
      );
      showToast("Saved (preview)");
      setSaving(null);
      return;
    }

    const result = await nui<{
      ok: boolean;
      salary?: number;
      jobs?: EconomyJob[];
      error?: string;
    }>("cfx-keydi-ipad:economy:setSalary", { job: jobName, grade, salary });

    if (result?.ok) {
      if (result.jobs) applyJobs(result.jobs);
      else {
        setJobs((prev) =>
          prev.map((j) =>
            j.name !== jobName
              ? j
              : {
                  ...j,
                  grades: j.grades.map((g) =>
                    g.grade === grade ? { ...g, salary: result.salary ?? salary } : g,
                  ),
                },
          ),
        );
        setDrafts((d) => ({ ...d, [key]: String(result.salary ?? salary) }));
      }
      showToast("Salary updated");
    } else {
      const err = result?.error;
      showToast(
        err === "denied"
          ? "Access denied"
          : err === "db_failed"
            ? "DB save failed"
            : err === "invalid"
              ? "Invalid salary"
              : "Save failed",
      );
    }
    setSaving(null);
  };

  return (
    <div
      className="absolute inset-0 flex flex-col select-none"
      style={{
        background:
          "radial-gradient(ellipse at 30% 0%, rgba(46,125,50,0.18), transparent 45%), linear-gradient(165deg, #0a0a0a 0%, #121212 40%, #0d0d0d 100%)",
      }}
    >
      <StatusBar />

      {/* Header */}
      <div className="flex items-start justify-between gap-4 px-5 pb-3 pt-2">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <DollarSign className="h-5 w-5 text-[#69f0ae]" strokeWidth={2.4} />
            <h1 className="text-[22px] font-bold tracking-wide text-white">ECONOMY</h1>
            <span className="rounded-md bg-[#2e7d32] px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-white">
              Owner / Dev
            </span>
          </div>
          <p className="mt-1 text-[12px] text-white/45">
            Edit job grade salaries · live paycheck sync · every 30 mins
          </p>
          {player?.firstName ? (
            <p className="mt-0.5 text-[11px] text-white/30">
              Signed in · {player.firstName} {player.lastName}
            </p>
          ) : null}
        </div>
        <button
          type="button"
          className="flex shrink-0 items-center gap-1.5 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-[13px] font-semibold text-white/80 transition-colors hover:bg-white/10"
          onClick={() => void loadJobs()}
          disabled={loading}
        >
          <RefreshCw className={cn("h-3.5 w-3.5", loading && "animate-spin")} />
          Refresh
        </button>
      </div>

      <div className="mx-5 mb-5 flex min-h-0 flex-1 gap-4 overflow-hidden">
        {/* Sidebar */}
        <aside className="flex w-[280px] shrink-0 flex-col overflow-hidden rounded-2xl border border-white/8 bg-[#161616]/95 shadow-xl">
          <div className="border-b border-white/8 p-3">
            <div className="flex items-center gap-2 rounded-xl bg-black/40 px-3 py-2.5">
              <Search className="h-4 w-4 text-white/35" strokeWidth={2.4} />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search jobs..."
                className="w-full bg-transparent text-[14px] text-white outline-none placeholder:text-white/30"
              />
            </div>
          </div>
          <div className="min-h-0 flex-1 overflow-y-auto p-2">
            {loading ? (
              <div className="flex items-center justify-center gap-2 py-10 text-white/40">
                <Loader2 className="h-4 w-4 animate-spin" />
                Loading…
              </div>
            ) : filtered.length === 0 ? (
              <p className="px-3 py-8 text-center text-[13px] text-white/35">No jobs found</p>
            ) : (
              filtered.map((job) => {
                const activeJob = selected === job.name;
                return (
                  <button
                    key={job.name}
                    type="button"
                    className={cn(
                      "mb-1.5 flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition-all",
                      activeJob
                        ? "border border-[#69f0ae]/55 bg-[#1b3d24] shadow-[0_0_18px_rgba(105,240,174,0.18)]"
                        : "border border-transparent bg-transparent hover:bg-white/5",
                    )}
                    onClick={() => setSelected(job.name)}
                  >
                    <div
                      className={cn(
                        "flex h-9 w-9 shrink-0 items-center justify-center rounded-lg",
                        activeJob ? "bg-[#2e7d32] text-white" : "bg-white/8 text-white/55",
                      )}
                    >
                      <Briefcase className="h-4 w-4" strokeWidth={2.2} />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-[15px] font-semibold text-white">{job.label}</p>
                      <p className="truncate text-[12px] text-white/40">
                        {job.name} · {job.grades.length} grade{job.grades.length === 1 ? "" : "s"}
                      </p>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </aside>

        {/* Detail */}
        <main className="flex min-w-0 flex-1 flex-col overflow-hidden rounded-2xl border border-white/8 bg-[#161616]/95 shadow-xl">
          {active ? (
            <>
              <div className="flex items-start justify-between gap-3 border-b border-white/8 px-5 py-4">
                <div>
                  <h2 className="text-[24px] font-bold uppercase tracking-wide text-white">
                    {active.label}
                  </h2>
                  <p className="mt-1 text-[13px] text-white/40">
                    Changes apply instantly to online players — no restart needed.
                  </p>
                </div>
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#2e7d32] text-white">
                  <DollarSign className="h-5 w-5" strokeWidth={2.4} />
                </div>
              </div>

              <div className="min-h-0 flex-1 space-y-2 overflow-y-auto p-4">
                {active.grades.map((g) => {
                  const key = `${active.name}:${g.grade}`;
                  const isSaving = saving === key;
                  return (
                    <div
                      key={key}
                      className="flex items-center gap-3 rounded-xl border border-white/6 bg-[#1c1c1c] px-3 py-3"
                    >
                      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#2e7d32] text-[14px] font-bold text-white">
                        {g.grade}
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-[15px] font-semibold text-white">{g.label}</p>
                        <p className="truncate text-[12px] text-white/40">
                          {g.name} · current ${g.salary.toLocaleString()} / paycheck
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <div className="flex items-center gap-1.5 rounded-xl border border-white/10 bg-black/40 px-3 py-2">
                          <span className="text-[14px] font-semibold text-white/50">$</span>
                          <input
                            type="text"
                            inputMode="numeric"
                            autoComplete="off"
                            spellCheck={false}
                            value={drafts[key] ?? String(g.salary)}
                            onChange={(e) => {
                              const next = e.target.value.replace(/[^\d]/g, "");
                              setDrafts((d) => ({ ...d, [key]: next }));
                            }}
                            className="w-[140px] bg-transparent text-[15px] font-semibold text-white outline-none"
                          />
                        </div>
                        <button
                          type="button"
                          className="flex items-center gap-1.5 rounded-full bg-[#2e7d32] px-3.5 py-2 text-[12px] font-bold uppercase tracking-wide text-white shadow-[0_4px_14px_rgba(46,125,50,0.35)] transition-colors hover:bg-[#388e3c] disabled:opacity-60"
                          disabled={isSaving}
                          onClick={() => void saveGrade(active.name, g.grade)}
                        >
                          {isSaving ? (
                            <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          ) : (
                            <Check className="h-3.5 w-3.5" strokeWidth={2.6} />
                          )}
                          Save
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </>
          ) : (
            <div className="flex flex-1 items-center justify-center text-[14px] text-white/35">
              Select a job to edit salaries
            </div>
          )}
        </main>
      </div>

      {toast ? (
        <div className="pointer-events-none absolute bottom-8 left-1/2 z-50 -translate-x-1/2 rounded-full bg-[#2e7d32] px-4 py-2 text-[13px] font-semibold text-white shadow-lg">
          {toast}
        </div>
      ) : null}
    </div>
  );
}
