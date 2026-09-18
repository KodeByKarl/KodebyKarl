import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { cn } from "@/lib/utils";
import {
  BatteryFull,
  BookOpen,
  Building2,
  CalendarDays,
  ChevronDown,
  ChevronRight,
  GraduationCap,
  IdCard,
  MapPin,
  Plus,
  Search,
  Signal,
  Sparkles,
  Users,
  Wifi,
  Landmark,
  ClipboardList,
  Bell,
  BadgeCheck,
  UserRound,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";
import type { UniversityRole } from "./universityTypes";
import { fetchNui, isBrowserEnv } from "@/lib/nui";

export type { UniversityRole };

type PendingApp = {
  id: number;
  citizenName?: string;
  programCode?: string;
  programLabel?: string;
  createdAt?: string;
};

type Course = {
  id: string;
  code: string;
  name: string;
  college: string;
  seats: number;
  enrolled: number;
  schedule: string;
  room: string;
};

const COLLEGES = [
  "College of Computing",
  "College of Nursing",
  "College of Criminal Justice",
  "College of Business",
  "College of Liberal Arts",
];

const MOCK_COURSES: Course[] = [
  {
    id: "1",
    code: "BSIT-101",
    name: "Introduction to Computing",
    college: "College of Computing",
    seats: 40,
    enrolled: 28,
    schedule: "Mon / Wed · 09:00",
    room: "Lab A · Chemistry Wing",
  },
  {
    id: "2",
    code: "BSN-210",
    name: "Fundamentals of Nursing",
    college: "College of Nursing",
    seats: 32,
    enrolled: 30,
    schedule: "Tue / Thu · 13:00",
    room: "Clinic Hall 2",
  },
  {
    id: "3",
    code: "CRIM-150",
    name: "Criminal Law & Procedure",
    college: "College of Criminal Justice",
    seats: 45,
    enrolled: 22,
    schedule: "Fri · 10:30",
    room: "Lecture Hall B",
  },
  {
    id: "4",
    code: "BSA-120",
    name: "Principles of Accounting",
    college: "College of Business",
    seats: 36,
    enrolled: 19,
    schedule: "Mon / Fri · 14:00",
    room: "Business Suite 3",
  },
  {
    id: "5",
    code: "ENG-180",
    name: "Academic Writing Workshop",
    college: "College of Liberal Arts",
    seats: 28,
    enrolled: 16,
    schedule: "Wed · 11:00",
    room: "Language Room · Spanish",
  },
];

const ROLE_META: Record<
  UniversityRole,
  { label: string; accent: string; blurb: string }
> = {
  visitor: {
    label: "Visitor",
    accent: "#b45309",
    blurb: "Explore campus · Apply when ready",
  },
  student: {
    label: "Student",
    accent: "#1d4ed8",
    blurb: "Courses · ID · Schedule",
  },
  teacher: {
    label: "Faculty",
    accent: "#047857",
    blurb: "Classes · Roster · Grades",
  },
  dean: {
    label: "Dean",
    accent: "#a16207",
    blurb: "College oversight · Curriculum",
  },
  director: {
    label: "Director",
    accent: "#9a3412",
    blurb: "Campus command · Programs",
  },
};

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return "G";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0] || ""}${parts[1][0] || ""}`.toUpperCase();
}

function StatusBar() {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(id);
  }, []);
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  return (
    <div
      className="relative z-40 flex items-center justify-between px-7 pt-[18px] text-[12px] font-semibold tracking-tight"
      style={{ color: "#334155" }}
    >
      <span className="min-w-[54px]">{time}</span>
      <div className="flex items-center gap-1.5" style={{ color: "#475569" }}>
        <Signal className="h-3.5 w-3.5" strokeWidth={2.4} />
        <Wifi className="h-3.5 w-3.5" strokeWidth={2.4} />
        <BatteryFull className="h-4 w-4" strokeWidth={2.2} />
      </div>
    </div>
  );
}

function resolveRole(player?: IpadPlayerData | null): UniversityRole {
  if (player?.universityRole) return player.universityRole;
  return "visitor";
}

function SeatBar({ enrolled, seats }: { enrolled: number; seats: number }) {
  const pct = Math.min(100, Math.round((enrolled / Math.max(1, seats)) * 100));
  return (
    <div className="mt-2">
      <div className="flex items-center justify-between text-[11px] font-medium text-[#475569]">
        <span>
          {enrolled}/{seats} seats
        </span>
        <span>{pct}%</span>
      </div>
      <div className="mt-1 h-1.5 overflow-hidden rounded-full bg-[#e2e8f0]">
        <div
          className="h-full rounded-full bg-[#1d4ed8]"
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}

function ProfileMenu({
  name,
  role,
  meta,
}: {
  name: string;
  role: UniversityRole;
  meta: (typeof ROLE_META)[UniversityRole];
}) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  return (
    <div ref={rootRef} className="relative z-[80] shrink-0">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className={cn(
          "relative z-[81] flex items-center gap-2 rounded-full border border-[#cbd5e1] bg-white py-1 pl-1 pr-2.5 shadow-sm transition-colors",
          "hover:border-[#94a3b8] hover:bg-[#f8fafc]",
          "active:bg-[#f1f5f9]",
          open && "border-[#94a3b8] bg-[#f8fafc]",
        )}
        aria-expanded={open}
        aria-haspopup="menu"
      >
        <span
          className="flex h-9 w-9 items-center justify-center rounded-full text-[12px] font-bold"
          style={{ backgroundColor: meta.accent, color: "#ffffff" }}
        >
          {initials(name)}
        </span>
        <ChevronDown
          className={cn("h-3.5 w-3.5 shrink-0 transition-transform", open && "rotate-180")}
          style={{ color: "#475569" }}
        />
      </button>

      {open && (
        <div
          role="menu"
          className="absolute right-0 top-[calc(100%+8px)] z-[90] w-[260px] rounded-2xl border border-[#cbd5e1] shadow-[0_20px_50px_rgba(15,23,42,0.28)]"
          style={{ backgroundColor: "#ffffff", color: "#0f172a" }}
        >
          <div
            className="rounded-t-2xl border-b border-[#e2e8f0] px-3.5 py-3"
            style={{ backgroundColor: "#f1f5f9" }}
          >
            <div className="flex items-center gap-3">
              <span
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-[13px] font-bold"
                style={{ backgroundColor: meta.accent, color: "#ffffff" }}
              >
                {initials(name)}
              </span>
              <div className="min-w-0">
                <p
                  className="truncate text-[14px] font-semibold"
                  style={{ color: "#0f172a" }}
                >
                  {name}
                </p>
                <p
                  className="mt-1 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-semibold"
                  style={{
                    backgroundColor: "#ffffff",
                    color: "#0f172a",
                    border: "1px solid #cbd5e1",
                  }}
                >
                  <BadgeCheck className="h-3 w-3" style={{ color: meta.accent }} />
                  {meta.label}
                </p>
              </div>
            </div>
          </div>
          <div className="rounded-b-2xl px-3.5 py-3" style={{ backgroundColor: "#ffffff" }}>
            <p
              className="text-[10px] font-bold uppercase"
              style={{ color: "#64748b", letterSpacing: "0.14em" }}
            >
              Signed in
            </p>
            <p
              className="mt-1.5 text-[13px] leading-relaxed"
              style={{ color: "#334155" }}
            >
              {meta.blurb}
            </p>
            <div
              className="mt-3 flex items-center gap-2 rounded-xl px-2.5 py-2 text-[12px] font-semibold"
              style={{ backgroundColor: "#f1f5f9", color: "#1e3a5f" }}
            >
              <UserRound className="h-3.5 w-3.5" style={{ color: "#1e3a5f" }} />
              Role · {role}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function UniversityPortalApp({
  player,
}: {
  player?: IpadPlayerData | null;
}) {
  const role = resolveRole(player);
  const meta = ROLE_META[role];
  const name =
    [player?.firstName, player?.lastName].filter(Boolean).join(" ") || "Guest";
  const [tab, setTab] = useState<"home" | "courses" | "campus" | "admin">(
    role === "visitor" ? "campus" : "home",
  );
  const [query, setQuery] = useState("");
  const [collegeFilter, setCollegeFilter] = useState<string>("All");
  const [courses, setCourses] = useState(MOCK_COURSES);
  const [enrolledIds, setEnrolledIds] = useState<string[]>(["1"]);
  const [toast, setToast] = useState<string | null>(null);
  const [draftCode, setDraftCode] = useState("");
  const [draftName, setDraftName] = useState("");
  const [draftCollege, setDraftCollege] = useState(COLLEGES[0]);
  const [pendingApps, setPendingApps] = useState<PendingApp[]>([]);
  const [pendingLoading, setPendingLoading] = useState(false);

  const flash = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const createCourse = () => {
    if (!draftCode.trim() || !draftName.trim()) {
      flash("Code and course name required");
      return;
    }
    const next: Course = {
      id: String(Date.now()),
      code: draftCode.trim().toUpperCase(),
      name: draftName.trim(),
      college: draftCollege,
      seats: 40,
      enrolled: 0,
      schedule: "TBA",
      room: "Assign room",
    };
    setCourses((prev) => [next, ...prev]);
    setDraftCode("");
    setDraftName("");
    flash("Course created");
    setTab("courses");
  };

  const isStaff = role === "teacher" || role === "dean" || role === "director";
  const isAdmin = role === "dean" || role === "director";

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return courses.filter((c) => {
      if (collegeFilter !== "All" && c.college !== collegeFilter) return false;
      if (!q) return true;
      return (
        c.name.toLowerCase().includes(q) ||
        c.code.toLowerCase().includes(q) ||
        c.college.toLowerCase().includes(q)
      );
    });
  }, [courses, collegeFilter, query]);

  const loadPending = useCallback(async () => {
    if (!(role === "dean" || role === "director")) return;
    setPendingLoading(true);
    const res = await fetchNui<{ ok?: boolean; rows?: PendingApp[] }>(
      "cfx-keydi-university:portal:pending",
    );
    setPendingLoading(false);
    if (isBrowserEnv()) {
      setPendingApps([
        {
          id: 1,
          citizenName: "Mia Cruz",
          programCode: "CJPS",
          programLabel: "Criminal Justice and Public Safety",
          createdAt: "just now",
        },
        {
          id: 2,
          citizenName: "Ace Walker",
          programCode: "BSIT",
          programLabel: "Information Technology",
          createdAt: "5m ago",
        },
      ]);
      return;
    }
    setPendingApps(res?.rows || []);
  }, [role]);

  useEffect(() => {
    if (tab === "admin" && (role === "dean" || role === "director")) {
      void loadPending();
    }
  }, [tab, role, loadPending]);

  const reviewApp = async (id: number, decision: "approve" | "deny") => {
    const res = await fetchNui<{ ok?: boolean; rows?: PendingApp[]; message?: string }>(
      "cfx-keydi-university:portal:review",
      { id, decision },
    );
    if (isBrowserEnv()) {
      setPendingApps((rows) => rows.filter((r) => r.id !== id));
      flash(decision === "approve" ? "Applicant approved" : "Application denied");
      return;
    }
    if (!res?.ok) {
      flash(res?.message || "Review failed");
      return;
    }
    setPendingApps(res.rows || []);
    flash(decision === "approve" ? "Applicant approved" : "Application denied");
  };

  const tabs = useMemo(() => {
    const list: { id: typeof tab; label: string }[] = [
      { id: "home", label: "Portal" },
      { id: "courses", label: "Courses" },
      { id: "campus", label: "Campus" },
    ];
    if (isAdmin) list.push({ id: "admin", label: "Director" });
    return list;
  }, [isAdmin]);

  return (
    <div
      className="absolute inset-0 flex flex-col select-none overflow-hidden bg-[#e8eef5] text-[#0f172a]"
      style={{
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif',
      }}
    >
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.35]"
        style={{
          backgroundImage:
            "linear-gradient(rgba(30,58,95,0.06) 1px, transparent 1px), linear-gradient(90deg, rgba(30,58,95,0.06) 1px, transparent 1px)",
          backgroundSize: "40px 40px",
        }}
      />
      <div className="pointer-events-none absolute inset-x-0 top-0 h-40 bg-gradient-to-b from-white/80 to-transparent" />

      <StatusBar />

      <div className="relative z-30 px-5 pb-3 pt-2">
        <div className="flex items-center justify-between gap-3">
          <div className="min-w-0">
            <div className="flex items-center gap-2.5">
              <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#1e3a5f] text-white shadow-md">
                <GraduationCap className="h-5 w-5" strokeWidth={2.2} />
              </div>
              <div className="min-w-0">
                <p
                  className="text-[10px] font-bold uppercase"
                  style={{ color: "#1e3a5f", letterSpacing: "0.18em" }}
                >
                  University of Los Santos
                </p>
                <h1
                  className="truncate text-[22px] font-bold leading-none tracking-tight"
                  style={{ color: "#0f172a" }}
                >
                  Campus Portal
                </h1>
              </div>
            </div>
          </div>
          <ProfileMenu name={name} role={role} meta={meta} />
        </div>

        <div className="mt-4 flex gap-1 rounded-2xl border border-[#e2e8f0] bg-white p-1 shadow-sm">
          {tabs.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              className={cn(
                "flex-1 rounded-xl px-2 py-2 text-[12px] font-semibold tracking-wide transition-colors",
                tab === t.id
                  ? "bg-[#1e3a5f] text-white shadow-sm"
                  : "bg-transparent text-[#475569] hover:bg-[#f1f5f9] hover:text-[#0f172a] active:bg-[#e2e8f0] active:text-[#0f172a]",
              )}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>

      <div className="relative z-10 min-h-0 flex-1 overflow-y-auto px-5 pb-16" style={{ color: "#0f172a" }}>
        {tab === "home" && (
          <div className="space-y-3">
            <div className="overflow-hidden rounded-[22px] border border-[#e2e8f0] bg-white p-4 shadow-sm">
              <div className="flex items-center gap-2 text-[#1e3a5f]">
                <Sparkles className="h-4 w-4" />
                <span className="text-[11px] font-bold uppercase tracking-[0.16em]">
                  Role workspace
                </span>
              </div>
              <p className="mt-2 text-[20px] font-bold tracking-tight text-[#0f172a]">
                Welcome, {name.split(" ")[0]}
              </p>
              <p className="mt-1 text-[13px] leading-relaxed text-[#475569]">{meta.blurb}</p>

              <div className="mt-4 grid grid-cols-3 gap-2">
                {[
                  { icon: BookOpen, value: courses.length, label: "Courses" },
                  {
                    icon: Users,
                    value: role === "student" ? enrolledIds.length : "128",
                    label: role === "student" ? "Enrolled" : "Students",
                  },
                  { icon: Landmark, value: COLLEGES.length, label: "Colleges" },
                ].map((stat) => (
                  <div
                    key={stat.label}
                    className="rounded-2xl border border-[#f1f5f9] bg-[#f8fafc] px-3 py-3"
                  >
                    <stat.icon className="h-4 w-4 text-[#1e3a5f]" />
                    <p className="mt-2 text-[18px] font-bold text-[#0f172a]">{stat.value}</p>
                    <p className="text-[11px] font-medium text-[#64748b]">{stat.label}</p>
                  </div>
                ))}
              </div>
            </div>

            {role === "visitor" && (
              <div className="rounded-[22px] border border-[#fde68a] bg-[#fffbeb] p-4">
                <p className="text-[15px] font-bold text-[#451a03]">Not enrolled yet</p>
                <p className="mt-1 text-[13px] leading-relaxed text-[#78350f]/80">
                  Visit the Director office or Registrar to get your Student ID. Until then, browse
                  campus and course catalogs as a guest.
                </p>
                <button
                  type="button"
                  onClick={() => setTab("campus")}
                  className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-[#1e3a5f] px-4 py-2 text-[12px] font-semibold text-white hover:bg-[#274b78] active:bg-[#16304f]"
                >
                  View campus map <ChevronRight className="h-3.5 w-3.5" />
                </button>
              </div>
            )}

            {role === "student" && (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <p className="text-[12px] font-bold uppercase tracking-[0.14em] text-[#64748b]">
                    My schedule
                  </p>
                  <button
                    type="button"
                    className="text-[12px] font-semibold text-[#1d4ed8] hover:text-[#1e3a8a]"
                    onClick={() => setTab("courses")}
                  >
                    Browse all
                  </button>
                </div>
                {courses
                  .filter((c) => enrolledIds.includes(c.id))
                  .map((c) => (
                    <div
                      key={c.id}
                      className="rounded-2xl border border-[#e2e8f0] bg-white px-4 py-3 shadow-sm"
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <p className="text-[11px] font-bold tracking-wide text-[#1d4ed8]">
                            {c.code}
                          </p>
                          <p className="text-[15px] font-semibold text-[#0f172a]">{c.name}</p>
                          <p className="mt-1 flex items-center gap-1.5 text-[12px] text-[#475569]">
                            <CalendarDays className="h-3.5 w-3.5" /> {c.schedule}
                          </p>
                        </div>
                        <IdCard className="h-5 w-5 shrink-0 text-[#1d4ed8]" />
                      </div>
                    </div>
                  ))}
              </div>
            )}

            {isStaff && (
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setTab("courses")}
                  className="rounded-2xl border border-[#e2e8f0] bg-white p-4 text-left shadow-sm transition-colors hover:bg-[#f8fafc] active:bg-[#f1f5f9]"
                >
                  <ClipboardList className="h-5 w-5 text-[#059669]" />
                  <p className="mt-3 text-[14px] font-semibold text-[#0f172a]">Class roster</p>
                  <p className="mt-1 text-[12px] text-[#64748b]">Preview · live data soon</p>
                </button>
                <button
                  type="button"
                  onClick={() => flash("Announcements wire next pass")}
                  className="rounded-2xl border border-[#e2e8f0] bg-white p-4 text-left shadow-sm transition-colors hover:bg-[#f8fafc] active:bg-[#f1f5f9]"
                >
                  <Bell className="h-5 w-5 text-[#d97706]" />
                  <p className="mt-3 text-[14px] font-semibold text-[#0f172a]">Campus feed</p>
                  <p className="mt-1 text-[12px] text-[#64748b]">Broadcast to students</p>
                </button>
              </div>
            )}
          </div>
        )}

        {tab === "courses" && (
          <div className="space-y-3">
            <div className="relative">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#94a3b8]" />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search courses, grades, college…"
                className="w-full rounded-2xl border border-[#e2e8f0] bg-white py-2.5 pl-10 pr-3 text-[13px] font-medium text-[#0f172a] outline-none placeholder:text-[#94a3b8] shadow-sm focus:border-[#1d4ed8] focus:ring-2 focus:ring-[#1d4ed8]/20"
              />
            </div>

            <div className="flex gap-1.5 overflow-x-auto pb-1">
              {["All", ...COLLEGES].map((col) => (
                <button
                  key={col}
                  type="button"
                  onClick={() => setCollegeFilter(col)}
                  className={cn(
                    "shrink-0 rounded-full px-3 py-1.5 text-[11px] font-semibold transition-colors",
                    collegeFilter === col
                      ? "bg-[#1e3a5f] text-white"
                      : "bg-white text-[#475569] ring-1 ring-[#e2e8f0] hover:bg-[#f1f5f9] hover:text-[#0f172a] active:bg-[#e2e8f0]",
                  )}
                >
                  {col === "All" ? "All colleges" : col.replace("College of ", "")}
                </button>
              ))}
            </div>

            {filtered.map((c) => {
              const mine = enrolledIds.includes(c.id);
              return (
                <div
                  key={c.id}
                  className="rounded-[20px] border border-[#e2e8f0] bg-white p-4 shadow-sm"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="text-[11px] font-bold tracking-[0.12em] text-[#1d4ed8]">
                        {c.code}
                      </p>
                      <p className="mt-0.5 text-[16px] font-semibold leading-snug text-[#0f172a]">
                        {c.name}
                      </p>
                      <p className="mt-1 text-[12px] text-[#64748b]">{c.college}</p>
                    </div>
                    {mine && (
                      <span className="rounded-full bg-[#eff6ff] px-2 py-1 text-[10px] font-bold uppercase tracking-wide text-[#1d4ed8] ring-1 ring-[#dbeafe]">
                        Enrolled
                      </span>
                    )}
                  </div>
                  <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-[12px] text-[#475569]">
                    <span className="inline-flex items-center gap-1">
                      <CalendarDays className="h-3.5 w-3.5" /> {c.schedule}
                    </span>
                    <span className="inline-flex items-center gap-1">
                      <MapPin className="h-3.5 w-3.5" /> {c.room}
                    </span>
                  </div>
                  <SeatBar enrolled={c.enrolled} seats={c.seats} />
                  {role === "student" && (
                    <button
                      type="button"
                      className={cn(
                        "mt-3 w-full rounded-xl py-2.5 text-[13px] font-semibold transition-colors active:scale-[0.99]",
                        mine
                          ? "border border-[#e2e8f0] bg-white text-[#334155] hover:bg-[#f8fafc]"
                          : "bg-[#1e3a5f] text-white hover:bg-[#274b78] active:bg-[#16304f]",
                      )}
                      onClick={() => {
                        if (mine) {
                          setEnrolledIds((ids) => ids.filter((id) => id !== c.id));
                          setCourses((prev) =>
                            prev.map((x) =>
                              x.id === c.id
                                ? { ...x, enrolled: Math.max(0, x.enrolled - 1) }
                                : x,
                            ),
                          );
                          flash("Dropped course");
                        } else {
                          setEnrolledIds((ids) => [...ids, c.id]);
                          setCourses((prev) =>
                            prev.map((x) =>
                              x.id === c.id ? { ...x, enrolled: x.enrolled + 1 } : x,
                            ),
                          );
                          flash("Enrolled");
                        }
                      }}
                    >
                      {mine ? "Drop course" : "Enroll"}
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {tab === "campus" && (
          <div className="space-y-3">
            <div className="rounded-[22px] border border-[#e2e8f0] bg-white p-4 shadow-sm">
              <div className="flex items-center gap-2 text-[#1e3a5f]">
                <Building2 className="h-4 w-4" />
                <span className="text-[11px] font-bold uppercase tracking-[0.14em]">
                  Campus directory
                </span>
              </div>
              <p className="mt-2 text-[14px] leading-relaxed text-[#475569]">
                Main Campus · Blip on map · Director office, classrooms, lockers, shops, and
                whiteboards live in-world.
              </p>
            </div>

            {[
              { title: "Director Office", desc: "Enrollment · faculty · announcements", icon: Landmark },
              { title: "Language Wings", desc: "Italian · Spanish · Japanese · Russian", icon: BookOpen },
              { title: "Science Block", desc: "Chemistry lab · clinics", icon: Sparkles },
              { title: "Student Services", desc: "Lockers · backpack shop · printers", icon: IdCard },
            ].map((item) => (
              <div
                key={item.title}
                className="flex items-center gap-3 rounded-2xl border border-[#e2e8f0] bg-white px-4 py-3.5 shadow-sm"
              >
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#f1f5f9] text-[#1e3a5f]">
                  <item.icon className="h-5 w-5" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-[14px] font-semibold text-[#0f172a]">{item.title}</p>
                  <p className="text-[12px] text-[#64748b]">{item.desc}</p>
                </div>
                <ChevronRight className="h-4 w-4 text-[#94a3b8]" />
              </div>
            ))}
          </div>
        )}

        {tab === "admin" && isAdmin && (
          <div className="space-y-3">
            <div className="rounded-[22px] border border-[#e2e8f0] bg-white p-4 shadow-sm">
              <div className="flex items-center justify-between gap-2">
                <div>
                  <p className="text-[11px] font-bold uppercase tracking-[0.16em] text-[#1e3a5f]">
                    Enrollment queue
                  </p>
                  <p className="mt-1 text-[12px] text-[#64748b]">
                    Approve Registrar applications · live from database
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => void loadPending()}
                  className="rounded-full border border-[#e2e8f0] bg-white px-3 py-1.5 text-[11px] font-semibold text-[#334155] hover:bg-[#f8fafc] active:bg-[#f1f5f9]"
                >
                  {pendingLoading ? "Loading…" : "Refresh"}
                </button>
              </div>

              <div className="mt-3 space-y-2">
                {pendingApps.length === 0 && (
                  <p className="rounded-xl border border-dashed border-[#e2e8f0] bg-[#f8fafc] px-3 py-4 text-center text-[12px] text-[#64748b]">
                    No pending applications
                  </p>
                )}
                {pendingApps.map((app) => (
                  <div
                    key={app.id}
                    className="rounded-2xl border border-[#e2e8f0] bg-[#f8fafc] px-3.5 py-3"
                  >
                    <div className="min-w-0">
                      <p className="truncate text-[14px] font-semibold text-[#0f172a]">
                        {app.citizenName || "Applicant"}
                      </p>
                      <p className="mt-0.5 text-[12px] font-medium text-[#1d4ed8]">
                        {app.programCode} · {app.programLabel}
                      </p>
                      {app.createdAt && (
                        <p className="mt-1 text-[11px] text-[#64748b]">{app.createdAt}</p>
                      )}
                    </div>
                    <div className="mt-3 flex gap-2">
                      <button
                        type="button"
                        onClick={() => void reviewApp(app.id, "approve")}
                        className="flex-1 rounded-xl bg-[#1e3a5f] py-2 text-[12px] font-bold text-white hover:bg-[#274b78] active:bg-[#16304f]"
                      >
                        Approve
                      </button>
                      <button
                        type="button"
                        onClick={() => void reviewApp(app.id, "deny")}
                        className="flex-1 rounded-xl border border-[#fecaca] bg-[#fef2f2] py-2 text-[12px] font-semibold text-[#b91c1c] hover:bg-[#fee2e2]"
                      >
                        Deny
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-[22px] border border-[#e2e8f0] bg-white p-4 shadow-sm">
              <div className="flex items-center gap-2">
                <Plus className="h-4 w-4 text-[#1e3a5f]" />
                <p className="text-[11px] font-bold uppercase tracking-[0.16em] text-[#1e3a5f]">
                  Create college course
                </p>
              </div>
              <div className="mt-3 space-y-2">
                <input
                  value={draftCode}
                  onChange={(e) => setDraftCode(e.target.value)}
                  placeholder="Course code · e.g. BSIT-220"
                  className="w-full rounded-xl border border-[#e2e8f0] bg-white px-3 py-2.5 text-[13px] text-[#0f172a] outline-none placeholder:text-[#94a3b8] focus:border-[#1d4ed8] focus:ring-2 focus:ring-[#1d4ed8]/20"
                />
                <input
                  value={draftName}
                  onChange={(e) => setDraftName(e.target.value)}
                  placeholder="Course title"
                  className="w-full rounded-xl border border-[#e2e8f0] bg-white px-3 py-2.5 text-[13px] text-[#0f172a] outline-none placeholder:text-[#94a3b8] focus:border-[#1d4ed8] focus:ring-2 focus:ring-[#1d4ed8]/20"
                />
                <select
                  value={draftCollege}
                  onChange={(e) => setDraftCollege(e.target.value)}
                  className="w-full rounded-xl border border-[#e2e8f0] bg-white px-3 py-2.5 text-[13px] text-[#0f172a] outline-none focus:border-[#1d4ed8] focus:ring-2 focus:ring-[#1d4ed8]/20"
                >
                  {COLLEGES.map((c) => (
                    <option key={c} value={c}>
                      {c}
                    </option>
                  ))}
                </select>
                <button
                  type="button"
                  onClick={createCourse}
                  className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#1e3a5f] py-3 text-[13px] font-bold text-white hover:bg-[#274b78] active:bg-[#16304f]"
                >
                  <Plus className="h-4 w-4" strokeWidth={2.4} />
                  Publish course
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="pointer-events-none absolute bottom-9 left-0 right-0 z-20 flex justify-center">
        <p className="rounded-full border border-[#e2e8f0] bg-white/90 px-3 py-1 text-[10px] font-bold tracking-[0.18em] text-[#64748b] shadow-sm backdrop-blur-md">
          ULS CAMPUS PORTAL
        </p>
      </div>

      {toast && (
        <div className="absolute bottom-16 left-1/2 z-50 -translate-x-1/2 rounded-full bg-[#0f172a] px-4 py-2 text-[12px] font-semibold text-white shadow-xl">
          {toast}
        </div>
      )}
    </div>
  );
}
