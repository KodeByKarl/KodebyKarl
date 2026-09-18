import { useMemo, useState } from "react";
import { format } from "date-fns";
import {
  CalendarIcon,
  User,
  Globe,
  Ruler,
  ArrowRight,
  FileText,
  IdCard,
  Sparkles,
  Wrench,
  ShieldCheck,
  Zap,
  Check,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { cn } from "@/lib/utils";
import { fetchNui } from "@/lib/nui";
import { toast } from "sonner";
import grimLogo from "@/assets/grim-city-logo.png";

type Tab = "identity" | "updates";
type UpdateTag = "Feature" | "Fix" | "Security" | "Performance" | "Rework";

const SERVER_UPDATES: {
  version: string;
  date: string;
  title: string;
  tag: UpdateTag;
  notes: string[];
}[] = [
  {
    version: "v1.1.0",
    date: "September 6, 2026",
    title: "Jobs Rebrand, Live Leaderboards & Campus Portal",
    tag: "Feature",
    notes: [
      "Live iPad Leaderboards — Turfwar, Traphouse, PvP, Party, and citywide Top Player.",
      "University Campus Portal rework with a brighter tablet UI.",
      "Robbery merge into kodebykarl-robbery with interior shells included.",
    ],
  },
  {
    version: "v1.0.31",
    date: "September 5, 2026",
    title: "PD / EMS Shops, Melee Decay & Clothing Coins",
    tag: "Fix",
    notes: [
      "Police store, stashes, evidence locker, and clothing system items configured.",
      "All melee weapons now last 3 days with durability decay.",
      "Chat wrapping scoped so module cards no longer stretch.",
    ],
  },
  {
    version: "v1.0.30",
    date: "September 5, 2026",
    title: "iPad Apps, VIP, Gang System & Regions",
    tag: "Rework",
    notes: [
      "Apple-style iPad shell with Party, PvP, Leaderboards, Economy, and MDT.",
      "VIP system, death recap, and zone-colored damage indicators.",
      "Server Locations reworked into Regions (farm / school / turf).",
    ],
  },
];

const NATIONALITIES = [
  "American",
  "British",
  "Canadian",
  "Filipino",
  "Mexican",
  "Japanese",
  "Korean",
  "German",
  "French",
  "Australian",
  "Other",
];

const lettersOnly = (value: string) => value.replace(/[^A-Za-z]/g, "").slice(0, 50);

export default function Identity() {
  const [tab, setTab] = useState<Tab>("identity");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [dob, setDob] = useState<Date | undefined>();
  const [nationality, setNationality] = useState("");
  const [height, setHeight] = useState("");
  const [gender, setGender] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const age = dob ? Math.floor((Date.now() - dob.getTime()) / (365.25 * 24 * 60 * 60 * 1000)) : null;
  const required = [firstName, lastName, dob, height, gender];
  const filled = required.filter(Boolean).length;
  const progress = Math.round((filled / required.length) * 100);
  const displayName = [firstName, lastName].filter(Boolean).join(" ") || "New Resident";

  const handleSubmit = async () => {
    if (submitting) return;
    if (!firstName || !lastName || !dob || !height || !gender) {
      toast.error("Fill in name, birthday, height, and gender.");
      setTab("identity");
      return;
    }

    const heightNum = parseInt(height, 10);
    if (Number.isNaN(heightNum) || heightNum < 120 || heightNum > 220) {
      toast.error("Height must be between 120 and 220 cm.");
      return;
    }

    if (firstName.length < 2 || lastName.length < 2) {
      toast.error("First and last names must be at least 2 letters.");
      return;
    }

    setSubmitting(true);
    try {
      const result = await fetchNui<{ error?: string; success?: boolean }>("submitIdentity", {
        firstName,
        lastName,
        dob: format(dob, "yyyy-MM-dd"),
        nationality,
        height: heightNum,
        gender,
      });
      if (result?.error) {
        toast.error(result.error);
        return;
      }
    } catch {
      toast.error("Failed to communicate with the game client.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="pandora pointer-events-auto fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-8 font-sans backdrop-blur-[6px] select-none animate-fade-in">
      <div className="pandora-panel relative flex h-[540px] w-full max-w-6xl flex-col overflow-hidden rounded-2xl border-2 border-[#ff3a3a] bg-[#0d0d12]">
        <div className="flex items-center justify-between border-b border-[#ff3a3a]/30 px-6 py-4">
          <div className="flex items-center gap-6">
            <TabButton active={tab === "identity"} onClick={() => setTab("identity")} icon={<IdCard className="h-4 w-4" />}>
              Identity
            </TabButton>
            <TabButton active={tab === "updates"} onClick={() => setTab("updates")} icon={<FileText className="h-4 w-4" />}>
              Server Updates
            </TabButton>
          </div>

          <div className="flex items-center gap-4">
            {tab === "identity" && (
              <div className="hidden items-center gap-2.5 md:flex">
                <span className="text-[10px] font-black uppercase tracking-[0.2em] text-[#a08890]">
                  {filled}/{required.length} complete
                </span>
                <div className="h-1.5 w-24 overflow-hidden rounded-full bg-[#181216]">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-[#ff4d4d] to-[#b30000] transition-all duration-500"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              </div>
            )}
            <Button
              onClick={handleSubmit}
              disabled={submitting}
              className="pointer-events-auto cursor-pointer rounded-xl border border-[#ff3a3a] bg-gradient-to-r from-[#ff4d4d] via-[#e61e1e] to-[#b30000] px-5 text-xs font-black uppercase text-white hover:brightness-110"
            >
              {submitting ? "Registering..." : "Continue"}
              <ArrowRight className="ml-1 h-4 w-4" />
            </Button>
          </div>
        </div>

        <div className="grid flex-1 grid-cols-[340px_1fr] overflow-hidden">
          <div className="pandora-hero relative flex flex-col items-center justify-between overflow-hidden border-r border-[#ff3a3a] p-10">
            <div className="panel-grid pointer-events-none absolute inset-0 opacity-40" />
            <div className="relative z-10 mt-2 flex flex-col items-center gap-4">
              <img src={grimLogo} alt="Grim City" className="pandora-logo w-[150px] object-contain" />
            </div>

            <div className="relative z-10 my-auto text-center">
              {tab === "identity" ? (
                <>
                  <span className="mb-2 inline-block rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/20 px-2.5 py-1 text-[9px] font-black uppercase tracking-[0.2em] text-[#ff4d4d]">
                    Create your
                  </span>
                  <h1 className="pandora-title mt-1 text-3xl font-black leading-none text-white">Identity</h1>
                  <p className="mx-auto mt-3 max-w-[240px] truncate text-sm font-black uppercase tracking-[0.14em] text-white">
                    {displayName}
                  </p>
                  <p className="mx-auto mt-3 max-w-[240px] text-[11px] leading-relaxed text-[#ffc2c2]">
                    Register your character to enter Grim City. Letters only for names.
                  </p>
                </>
              ) : (
                <>
                  <span className="mb-2 inline-block rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/20 px-2.5 py-1 text-[9px] font-black uppercase tracking-[0.2em] text-[#ff4d4d]">
                    Patch Notes
                  </span>
                  <h1 className="pandora-title mt-1 text-2xl font-black leading-none text-white">Server Updates</h1>
                  <p className="mx-auto mt-3 max-w-[240px] text-[11px] leading-relaxed text-[#ffc2c2]">
                    Latest changes, fixes, and features across Grim City Roleplay.
                  </p>
                </>
              )}
            </div>

            <div className="relative z-10 w-full border-t border-[#ff3a3a]/25 pt-3 text-center">
              <p className="text-[9.5px] font-black tracking-[0.2em] text-[#ff4d4d]">GRIM CITY ROLEPLAY</p>
              <span className="mt-0.5 block text-[9px] text-[#a08890]">Powered by KodeByKarl.Net</span>
            </div>
          </div>

          <div className="flex h-full flex-col overflow-hidden bg-transparent p-8">
            {tab === "identity" ? (
              <IdentityForm
                firstName={firstName}
                setFirstName={(v) => setFirstName(lettersOnly(v))}
                lastName={lastName}
                setLastName={(v) => setLastName(lettersOnly(v))}
                dob={dob}
                setDob={setDob}
                age={age}
                nationality={nationality}
                setNationality={setNationality}
                height={height}
                setHeight={setHeight}
                gender={gender}
                setGender={setGender}
              />
            ) : (
              <ServerUpdates />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function TabButton({
  active,
  onClick,
  icon,
  children,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "flex cursor-pointer items-center gap-2 border-b-2 pb-1 text-sm font-bold transition",
        active ? "border-[#ff3a3a] text-white [&_svg]:text-[#ff4d4d]" : "border-transparent text-[#a08890] hover:text-white",
      )}
    >
      {icon}
      <span>{children}</span>
    </button>
  );
}

function Field({
  icon,
  label,
  title,
  hint,
  done,
  children,
}: {
  icon: React.ReactNode;
  label: string;
  title: string;
  hint?: string;
  done?: boolean;
  children: React.ReactNode;
}) {
  return (
    <div className="rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-4 transition hover:border-[#ff3a3a]">
      <div className="flex items-center gap-2.5">
        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-[#ff3a3a] bg-[#ff3a3a]/20 text-[#ff4d4d]">
          {icon}
        </div>
        <div className="min-w-0 flex-1 leading-tight">
          <span className="text-[9px] font-black tracking-[0.24em] text-[#ff4d4d]">{label}</span>
          <p className="truncate text-[11px] font-bold uppercase tracking-wider text-white">
            {title}
            {hint && <span className="ml-1 font-medium normal-case tracking-normal text-[#a08890]">{hint}</span>}
          </p>
        </div>
        {done && (
          <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-[#ff3a3a]/20 text-[#ff4d4d]">
            <Check className="h-3 w-3" />
          </span>
        )}
      </div>
      <div className="mt-2.5 pl-[42px]">{children}</div>
    </div>
  );
}

const FIELD_INPUT =
  "border-0 bg-transparent px-0 text-base text-white placeholder:text-[#6a555c] focus-visible:ring-0";
const FIELD_TRIGGER =
  "h-auto w-full border-0 bg-transparent px-0 py-1 text-base text-white shadow-none focus:ring-0 data-[placeholder]:text-[#6a555c]";

function IdentityForm(props: {
  firstName: string;
  setFirstName: (v: string) => void;
  lastName: string;
  setLastName: (v: string) => void;
  dob: Date | undefined;
  setDob: (d: Date | undefined) => void;
  age: number | null;
  nationality: string;
  setNationality: (v: string) => void;
  height: string;
  setHeight: (v: string) => void;
  gender: string;
  setGender: (v: string) => void;
}) {
  const {
    firstName,
    setFirstName,
    lastName,
    setLastName,
    dob,
    setDob,
    age,
    nationality,
    setNationality,
    height,
    setHeight,
    gender,
    setGender,
  } = props;

  return (
    <div className="flex h-full flex-col overflow-hidden">
      <div className="mb-4 flex shrink-0 items-start justify-between gap-4 border-b border-[#ff3a3a]/25 pb-3">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.25em] text-[#ff4d4d]">Character Details</p>
          <p className="mt-1 text-[12px] text-[#a08890]">
            All required fields must be filled before you can enter the city.
          </p>
        </div>
        <span className="shrink-0 rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/15 px-3 py-1 text-[9.5px] font-black uppercase tracking-[0.18em] text-[#ff4d4d]">
          New Resident
        </span>
      </div>

      <div className="custom-scrollbar flex-1 space-y-0 overflow-y-auto pr-2">
        <div className="grid grid-cols-2 gap-3">
          <Field icon={<User className="h-3.5 w-3.5" />} label="01" title="First Name" done={firstName.length >= 2}>
            <Input
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              placeholder="John"
              className={FIELD_INPUT}
              maxLength={50}
            />
          </Field>
          <Field icon={<User className="h-3.5 w-3.5" />} label="02" title="Last Name" done={lastName.length >= 2}>
            <Input
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              placeholder="Doe"
              className={FIELD_INPUT}
              maxLength={50}
            />
          </Field>
          <Field
            icon={<CalendarIcon className="h-3.5 w-3.5" />}
            label="03"
            title="Date of Birth"
            hint={age !== null ? `· ${age} yrs` : undefined}
            done={!!dob}
          >
            <Popover>
              <PopoverTrigger asChild>
                <button
                  type="button"
                  className={cn(
                    "flex w-full items-center justify-between bg-transparent py-1 text-left text-base outline-none",
                    dob ? "text-white" : "text-[#6a555c]",
                  )}
                >
                  {dob ? format(dob, "MMMM d, yyyy") : "Select birthday"}
                  <CalendarIcon className="h-4 w-4 text-[#ff4d4d]" />
                </button>
              </PopoverTrigger>
              <PopoverContent className="pandora pointer-events-auto z-50 w-auto border-[#ff3a3a]/60 bg-[#140d11] p-0" align="start">
                <Calendar
                  mode="single"
                  selected={dob}
                  onSelect={setDob}
                  captionLayout="dropdown"
                  defaultMonth={dob ?? new Date(1997, 0)}
                  startMonth={new Date(1990, 0)}
                  endMonth={new Date(2005, 11)}
                  disabled={(date) => {
                    const y = date.getFullYear();
                    return y < 1990 || y > 2005;
                  }}
                />
              </PopoverContent>
            </Popover>
          </Field>
          <Field icon={<Globe className="h-3.5 w-3.5" />} label="04" title="Nationality" hint="optional" done={!!nationality}>
            <Select value={nationality} onValueChange={setNationality}>
              <SelectTrigger className={FIELD_TRIGGER}>
                <SelectValue placeholder="Choose nationality" />
              </SelectTrigger>
              <SelectContent className="pandora pointer-events-auto z-50 max-h-72 border-[#ff3a3a]/40 bg-[#140d11]">
                {NATIONALITIES.map((n) => (
                  <SelectItem key={n} value={n}>
                    {n}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          <Field icon={<Ruler className="h-3.5 w-3.5" />} label="05" title="Height (cm)" done={!!height}>
            <Input
              type="number"
              min={120}
              max={220}
              value={height}
              onChange={(e) => setHeight(e.target.value)}
              placeholder="175"
              className={FIELD_INPUT}
            />
          </Field>
          <div className="rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-4 transition hover:border-[#ff3a3a]">
            <div className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-[#ff3a3a] bg-[#ff3a3a]/20 text-[#ff4d4d]">
                <User className="h-3.5 w-3.5" />
              </div>
              <div className="min-w-0 flex-1 leading-tight">
                <span className="text-[9px] font-black tracking-[0.24em] text-[#ff4d4d]">06</span>
                <p className="text-[11px] font-bold uppercase tracking-wider text-white">Gender</p>
              </div>
              {!!gender && (
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-[#ff3a3a]/20 text-[#ff4d4d]">
                  <Check className="h-3 w-3" />
                </span>
              )}
            </div>
            <div className="mt-3 grid grid-cols-2 gap-2 pl-[42px]">
              {(
                [
                  { id: "male", label: "Male" },
                  { id: "female", label: "Female" },
                ] as const
              ).map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => setGender(option.id)}
                  className={cn(
                    "cursor-pointer rounded-lg border px-3 py-1.5 text-[11px] font-black uppercase tracking-wider transition",
                    gender === option.id
                      ? "border-[#ff3a3a] bg-[#ff3a3a] text-white"
                      : "border-[#ff3a3a]/30 bg-[#0d0d12] text-[#a08890] hover:border-[#ff3a3a] hover:text-white",
                  )}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

const TAG_STYLES: Record<UpdateTag, { icon: React.ReactNode; bg: string; text: string }> = {
  Feature: { icon: <Sparkles className="h-3 w-3" />, bg: "rgba(255, 58, 58, 0.25)", text: "#ffb3b3" },
  Fix: { icon: <Wrench className="h-3 w-3" />, bg: "rgba(255, 128, 128, 0.25)", text: "#ffffff" },
  Security: { icon: <ShieldCheck className="h-3 w-3" />, bg: "rgba(40, 160, 100, 0.3)", text: "#adfcbe" },
  Performance: { icon: <Zap className="h-3 w-3" />, bg: "rgba(255, 210, 76, 0.28)", text: "#ffeeb8" },
  Rework: { icon: <Wrench className="h-3 w-3" />, bg: "rgba(167, 139, 250, 0.28)", text: "#ddd6fe" },
};

function ServerUpdates() {
  const [filter, setFilter] = useState<"all" | UpdateTag>("all");
  const visible = useMemo(
    () => (filter === "all" ? SERVER_UPDATES : SERVER_UPDATES.filter((u) => u.tag === filter)),
    [filter],
  );

  return (
    <div className="flex h-full flex-col overflow-hidden">
      <div className="flex shrink-0 items-center justify-between border-b border-[#ff3a3a]/25 pb-3">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.25em] text-[#ff4d4d]">Changelog</p>
          <p className="mt-0.5 text-[11px] text-[#a08890]">Latest updates, fixes, and features shipped to the city.</p>
        </div>
        <div className="flex gap-1 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-1">
          {(["all", "Feature", "Fix", "Rework", "Security", "Performance"] as const).map((f) => (
            <button
              key={f}
              type="button"
              onClick={() => setFilter(f)}
              className={cn(
                "cursor-pointer rounded-lg px-2.5 py-1 text-[9px] font-black uppercase tracking-wider transition",
                filter === f ? "bg-[#ff3a3a] text-white" : "text-[#a08890] hover:text-white",
              )}
            >
              {f === "all" ? "All" : f}
            </button>
          ))}
        </div>
      </div>

      <div className="custom-scrollbar mt-4 max-h-[300px] flex-1 space-y-3.5 overflow-y-auto pr-2">
        {visible.map((u, i) => {
          const style = TAG_STYLES[u.tag];
          return (
            <article key={u.version} className="rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-4 transition hover:border-[#ff3a3a]">
              <div className="flex flex-wrap items-center gap-3">
                <span className="rounded-md border border-[#ff3a3a]/40 bg-[#ff3a3a]/15 px-2 py-0.5 font-mono text-[10px] font-bold tracking-wider text-[#ff8080]">
                  {u.version}
                </span>
                <span
                  className="inline-flex items-center gap-1 rounded-md px-2.5 py-0.5 text-[9px] font-black uppercase tracking-wider"
                  style={{ background: style.bg, color: style.text }}
                >
                  {style.icon} {u.tag}
                </span>
                <span className="text-[10px] text-[#a08890]">{u.date}</span>
                {i === 0 && (
                  <span className="ml-auto inline-flex items-center gap-1 rounded-md border border-[#ff3a3a] px-2 py-0.5 text-[9px] font-black tracking-widest text-[#ff4d4d]">
                    <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-[#ff3a3a]" />
                    LATEST
                  </span>
                )}
              </div>
              <h3 className="mt-2 text-xs font-bold text-white">{u.title}</h3>
              <ul className="mt-2.5 space-y-1">
                {u.notes.map((n, idx) => (
                  <li key={idx} className="flex gap-2 text-[11px] leading-relaxed text-[#a08890]">
                    <span className="mt-2 h-1 w-1 shrink-0 rounded-full bg-[#ff3a3a]" />
                    <span>{n}</span>
                  </li>
                ))}
              </ul>
            </article>
          );
        })}
        {visible.length === 0 && (
          <p className="rounded-xl border border-[#ff3a3a]/30 p-8 text-center text-xs text-[#a08890]">
            No updates match this filter.
          </p>
        )}
      </div>
    </div>
  );
}
