import type { ReactNode } from "react";
import {
  Activity,
  Clock,
  Flame,
  Heart,
  Lock,
  MapPin,
  Shield,
  Sparkles,
  Trophy,
  Unlock,
  Users,
  Wrench,
  Zap,
} from "lucide-react";
import grimLogo from "@/assets/grim-city-logo.png";

interface PopulationData {
  current: number;
  max: number;
}

interface JobData {
  name: string;
  online: number;
}

interface PriorityData {
  name: string;
  status: "Safe" | "In Progress" | "Cooldown" | "Hold" | string;
}

interface WorldEventData {
  name: string;
  location: string;
  status: "ACTIVE" | "INACTIVE";
  timeLeft?: string;
}

interface ActiveRobberyData {
  name: string;
  location: string;
  timeLeft: string;
}

interface ScoreboardData {
  toggleKey?: string;
  serverName: string;
  enablePriorityStatus: boolean;
  playerName: string;
  playerId: number;
  ping: number;
  avatarUrl?: string;
  stats: {
    playTime: string;
    rank: string;
    kills: number;
    kd: string;
    health: number;
    armor: number;
  };
  population: PopulationData;
  jobs: JobData[];
  priorities: PriorityData[];
  worldEvents: WorldEventData[];
  robberies: ActiveRobberyData[];
}

const MOCK_DATA: ScoreboardData = {
  toggleKey: "F10",
  serverName: "Grim City",
  enablePriorityStatus: true,
  playerName: "Player",
  playerId: 1,
  ping: 28,
  avatarUrl: "https://cdn.discordapp.com/embed/avatars/0.png",
  stats: {
    playTime: "12h",
    rank: "—",
    kills: 0,
    kd: "0.00",
    health: 100,
    armor: 0,
  },
  population: {
    current: 1,
    max: 128,
  },
  jobs: [
    { name: "LS EMS", online: 0 },
    { name: "LS Police", online: 1 },
  ],
  priorities: [
    { name: "LS Police", status: "Safe" },
    { name: "Paleto Sheriff", status: "Safe" },
  ],
  worldEvents: [
    { name: "Airdrop", location: "Sandy Shores", status: "INACTIVE", timeLeft: "45:00" },
    { name: "Traphouse", location: "Unknown", status: "INACTIVE", timeLeft: "12:30" },
    { name: "Turf Wars", location: "Unknown", status: "INACTIVE", timeLeft: "28:00" },
  ],
  robberies: [],
};

const ACCENT = "#ff3a3a";

function getJobIcon(name: string) {
  const lower = name.toLowerCase();
  if (lower.includes("ems") || lower.includes("medical") || lower.includes("ambulance")) {
    return <Activity className="h-4 w-4 text-white" strokeWidth={2.2} />;
  }
  if (lower.includes("mechanic")) {
    return <Wrench className="h-4 w-4 text-white" strokeWidth={2.2} />;
  }
  return <Shield className="h-4 w-4 text-white" strokeWidth={2.2} />;
}

function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <p className="mb-2.5 text-[11px] font-bold uppercase tracking-[0.18em]" style={{ color: ACCENT }}>
      {children}
    </p>
  );
}

function InnerCard({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <div
      className={`rounded-[14px] px-3.5 py-3 ${className}`}
      style={{
        backgroundColor: "rgba(255,255,255,0.06)",
        border: "1px solid rgba(255,255,255,0.08)",
      }}
    >
      {children}
    </div>
  );
}

function EmptyBox({ children }: { children: ReactNode }) {
  return (
    <div
      className="rounded-[14px] px-3.5 py-5 text-center text-[12px] text-white/35"
      style={{
        backgroundColor: "rgba(255,255,255,0.05)",
        border: "1px solid rgba(255,255,255,0.08)",
      }}
    >
      {children}
    </div>
  );
}

function Pill({
  children,
  tone,
}: {
  children: ReactNode;
  tone: "green" | "red" | "amber" | "muted" | "orange";
}) {
  const styles = {
    green: "bg-emerald-500/18 text-emerald-300",
    red: "bg-rose-500/18 text-rose-300",
    amber: "bg-amber-500/18 text-amber-300",
    orange: "bg-orange-500/18 text-orange-300",
    muted: "bg-white/8 text-white/45",
  };
  return (
    <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide ${styles[tone]}`}>
      {children}
    </span>
  );
}

function Panel({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle: string;
  children: ReactNode;
}) {
  return (
    <section
      className="relative flex min-h-0 flex-col overflow-hidden rounded-[22px]"
      style={{
        height: "min(620px, 82vh)",
        backgroundColor: "rgba(10, 8, 10, 0.82)",
        border: "1px solid rgba(255,58,58,0.45)",
      }}
    >
      <div className="pointer-events-none absolute inset-0 opacity-[0.22] panel-grid" />
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background: "radial-gradient(ellipse at 50% 0%, rgba(255,58,58,0.10), transparent 55%)",
        }}
      />

      <header className="relative z-10 flex shrink-0 items-center gap-3 px-5 pb-1 pt-5">
        <img
          src={grimLogo}
          alt=""
          className="h-10 w-10 rounded-full object-cover ring-1 ring-[#ff3a3a]/40"
        />
        <div className="min-w-0">
          <h2 className="text-[17px] font-black uppercase leading-none tracking-[0.04em] text-white">
            {title}
          </h2>
          <p className="mt-1.5 text-[11px] font-medium text-white/40">{subtitle}</p>
        </div>
      </header>

      <div className="relative z-10 min-h-0 flex-1 space-y-4 overflow-y-auto overflow-x-hidden px-5 py-4 no-scrollbar">
        {children}
      </div>

      <footer className="relative z-10 flex shrink-0 items-center justify-center gap-1.5 pb-3.5 pt-1 text-[10px] font-semibold tracking-[0.14em] text-white/25">
        <img src={grimLogo} alt="" className="h-3.5 w-3.5 rounded-full opacity-70" />
        grim.city
      </footer>
    </section>
  );
}

interface ScoreboardProps {
  data?: Partial<ScoreboardData>;
}

export default function Scoreboard({ data = {} }: ScoreboardProps) {
  const merged: ScoreboardData = {
    ...MOCK_DATA,
    ...data,
    stats: {
      ...MOCK_DATA.stats,
      ...data.stats,
    },
    population: {
      ...MOCK_DATA.population,
      ...data.population,
    },
    jobs: data.jobs || MOCK_DATA.jobs,
    priorities: data.priorities || MOCK_DATA.priorities,
    worldEvents: data.worldEvents || MOCK_DATA.worldEvents,
    robberies: data.robberies || MOCK_DATA.robberies,
  };

  const popPercentage = Math.min((merged.population.current / Math.max(1, merged.population.max)) * 100, 100);
  const brand = merged.serverName || "Grim City";
  const pingGood = merged.ping < 80;

  return (
    <div className="pointer-events-auto fixed inset-0 z-[99930] flex flex-col items-center justify-center bg-transparent px-5 py-6 font-sans select-none">
      <div className="grid w-full max-w-[1180px] grid-cols-3 items-stretch gap-3.5">
        {/* LEFT — YOUR PROFILE */}
        <Panel title="Your Profile" subtitle="Player card">
          <div className="flex items-center gap-3.5">
            <div className="h-[68px] w-[68px] shrink-0 overflow-hidden rounded-[16px] ring-1 ring-white/10">
              {merged.avatarUrl ? (
                <img src={merged.avatarUrl} alt="" className="h-full w-full object-cover" />
              ) : (
                <div className="flex h-full w-full items-center justify-center bg-white/5">
                  <Users className="h-7 w-7 text-white/35" />
                </div>
              )}
            </div>
            <div className="min-w-0 flex-1">
              <h3 className="truncate text-[18px] font-bold leading-tight text-white">
                {merged.playerName}
              </h3>
              <div className="mt-2 flex flex-wrap items-center gap-1.5">
                <span className="rounded-full bg-white/8 px-2.5 py-0.5 text-[11px] font-semibold text-white/55">
                  ID {merged.playerId}
                </span>
                <span
                  className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[11px] font-semibold ${
                    pingGood ? "bg-emerald-500/15 text-emerald-300" : "bg-amber-500/15 text-amber-300"
                  }`}
                >
                  <span className={`h-1.5 w-1.5 rounded-full ${pingGood ? "bg-emerald-400" : "bg-amber-400"}`} />
                  {merged.ping}ms
                </span>
              </div>
            </div>
          </div>

          <div>
            <SectionLabel>Global Stats</SectionLabel>
            <div className="grid grid-cols-2 gap-2.5">
              {(
                [
                  { icon: Clock, label: "Play Time", value: merged.stats.playTime },
                  { icon: Trophy, label: "Rank", value: merged.stats.rank || "—" },
                  { icon: Flame, label: "Kills", value: merged.stats.kills },
                  { icon: Activity, label: "K/D", value: merged.stats.kd },
                ] as const
              ).map((stat) => (
                <InnerCard key={stat.label}>
                  <div className="flex items-center gap-2">
                    <div
                      className="flex h-7 w-7 items-center justify-center rounded-lg"
                      style={{ background: "rgba(255,58,58,0.16)" }}
                    >
                      <stat.icon className="h-3.5 w-3.5" style={{ color: ACCENT }} />
                    </div>
                    <span className="text-[10px] font-semibold uppercase tracking-[0.12em] text-white/40">
                      {stat.label}
                    </span>
                  </div>
                  <p className="mt-2 truncate text-[16px] font-bold text-white">{stat.value}</p>
                </InnerCard>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2.5">
            <InnerCard>
              <div className="mb-2 flex items-center gap-2">
                <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-[#ff4d6d]/18">
                  <Heart className="h-3.5 w-3.5 text-[#ff7aa0]" fill="#ff7aa0" />
                </div>
                <span className="text-[10px] font-semibold uppercase tracking-[0.12em] text-white/45">Health</span>
                <span className="ml-auto text-[11px] font-bold text-white">{merged.stats.health}%</span>
              </div>
              <div className="h-[6px] overflow-hidden rounded-full bg-white/10">
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${merged.stats.health}%`,
                    background: "linear-gradient(90deg, #ff3a5c, #ff8aa8)",
                    boxShadow: "0 0 10px rgba(255,58,92,0.55)",
                  }}
                />
              </div>
            </InnerCard>
            <InnerCard>
              <div className="mb-2 flex items-center gap-2">
                <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-white/8">
                  <Shield className="h-3.5 w-3.5 text-white/70" />
                </div>
                <span className="text-[10px] font-semibold uppercase tracking-[0.12em] text-white/45">Armor</span>
                <span className="ml-auto text-[11px] font-bold text-white">{merged.stats.armor}%</span>
              </div>
              <div className="h-[6px] overflow-hidden rounded-full bg-white/10">
                <div
                  className="h-full rounded-full bg-slate-300"
                  style={{ width: `${merged.stats.armor}%` }}
                />
              </div>
            </InnerCard>
          </div>

          <div>
            <SectionLabel>Achievements</SectionLabel>
            <EmptyBox>No badges yet.</EmptyBox>
          </div>
        </Panel>

        {/* MIDDLE — SERVER STATUS */}
        <Panel title="Server Status" subtitle={brand}>
          <InnerCard>
            <div className="flex items-center justify-between gap-3">
              <div className="flex items-center gap-2.5">
                <div
                  className="flex h-8 w-8 items-center justify-center rounded-lg"
                  style={{ background: "rgba(255,58,58,0.16)" }}
                >
                  <Users className="h-4 w-4" style={{ color: ACCENT }} />
                </div>
                <span className="text-[11px] font-bold uppercase tracking-[0.16em] text-white/45">
                  Population
                </span>
              </div>
              <p className="text-[22px] font-black leading-none text-white">
                {merged.population.current}
                <span className="text-[13px] font-semibold text-white/35">
                  {" "}
                  / {merged.population.max}
                </span>
              </p>
            </div>
            <div className="mt-3 h-[5px] overflow-hidden rounded-full bg-white/10">
              <div
                className="h-full rounded-full"
                style={{
                  width: `${popPercentage}%`,
                  background: ACCENT,
                  boxShadow: "0 0 12px rgba(255,58,58,0.7)",
                }}
              />
            </div>
          </InnerCard>

          <div>
            <SectionLabel>Jobs Online</SectionLabel>
            <div className="flex flex-col gap-2">
              {merged.jobs.map((job) => (
                <InnerCard key={job.name} className="!py-2.5">
                  <div className="flex items-center justify-between gap-3">
                    <div className="flex items-center gap-2.5">
                      <div
                        className="flex h-9 w-9 items-center justify-center rounded-[10px]"
                        style={{ background: "rgba(255,58,58,0.22)" }}
                      >
                        {getJobIcon(job.name)}
                      </div>
                      <span className="text-[13px] font-semibold text-white">{job.name}</span>
                    </div>
                    <span className="text-[12px] font-semibold text-white/45">{job.online} online</span>
                  </div>
                </InnerCard>
              ))}
            </div>
          </div>

          {merged.enablePriorityStatus && (
            <div>
              <SectionLabel>Priority Status</SectionLabel>
              <div className="flex flex-col gap-2">
                {merged.priorities.map((prio) => {
                  const status = String(prio.status || "");
                  const lower = status.toLowerCase();
                  let pill: ReactNode;
                  if (lower === "safe") {
                    pill = (
                      <Pill tone="green">
                        <Unlock className="h-3 w-3" /> Safe
                      </Pill>
                    );
                  } else if (lower === "in progress") {
                    pill = (
                      <Pill tone="orange">
                        <Zap className="h-3 w-3" /> In Progress
                      </Pill>
                    );
                  } else if (lower.startsWith("cooldown")) {
                    pill = (
                      <Pill tone="amber">
                        <Clock className="h-3 w-3" /> {status}
                      </Pill>
                    );
                  } else {
                    pill = (
                      <Pill tone="red">
                        <Lock className="h-3 w-3" /> {status || "Hold"}
                      </Pill>
                    );
                  }
                  return (
                    <InnerCard key={prio.name} className="!py-2.5">
                      <div className="flex items-center justify-between gap-3">
                        <span className="text-[13px] font-semibold text-white">{prio.name}</span>
                        {pill}
                      </div>
                    </InnerCard>
                  );
                })}
              </div>
            </div>
          )}
        </Panel>

        {/* RIGHT — CRIME STATUS */}
        <Panel title="Crime Status" subtitle="Live activity">
          <div>
            <SectionLabel>World Events</SectionLabel>
            <div className="flex flex-col gap-2">
              {merged.worldEvents.map((event) => (
                <InnerCard key={event.name} className="!py-2.5">
                  <div className="flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <p className="truncate text-[13px] font-semibold text-white">{event.name}</p>
                      <p className="mt-0.5 flex items-center gap-1 text-[11px] text-white/35">
                        <MapPin className="h-3 w-3" style={{ color: ACCENT }} />
                        {event.location || "—"}
                      </p>
                    </div>
                    {event.timeLeft ? (
                      <Pill tone={event.status === "ACTIVE" ? "amber" : "muted"}>
                        <span className="inline-flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          {event.timeLeft}
                        </span>
                      </Pill>
                    ) : event.status === "ACTIVE" ? (
                      <Pill tone="amber">Active</Pill>
                    ) : (
                      <Pill tone="muted">—</Pill>
                    )}
                  </div>
                </InnerCard>
              ))}
            </div>
          </div>

          <div>
            <SectionLabel>Active Robberies</SectionLabel>
            {merged.robberies.length > 0 ? (
              <div className="flex flex-col gap-2">
                {merged.robberies.map((rob) => (
                  <InnerCard key={`${rob.name}-${rob.location}`} className="!py-2.5">
                    <div className="flex items-center justify-between gap-3">
                      <div className="min-w-0">
                        <p className="truncate text-[13px] font-semibold text-white">{rob.name}</p>
                        <p className="mt-0.5 text-[11px] text-white/35">{rob.location}</p>
                      </div>
                      <Pill tone="red">{rob.timeLeft}</Pill>
                    </div>
                  </InnerCard>
                ))}
              </div>
            ) : (
              <EmptyBox>No active robberies.</EmptyBox>
            )}
          </div>
        </Panel>
      </div>

      <p className="mt-4 flex items-center gap-2 text-[11px] font-bold uppercase tracking-[0.22em] text-white/45">
        <Sparkles className="h-3.5 w-3.5" style={{ color: ACCENT }} />
        Press {merged.toggleKey?.toUpperCase() || "F10"} to toggle
      </p>
    </div>
  );
}
