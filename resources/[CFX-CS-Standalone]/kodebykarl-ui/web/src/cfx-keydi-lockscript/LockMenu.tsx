import { useEffect, useMemo, useRef, useState } from "react";
import {
  Lock,
  Search,
  X,
  RefreshCw,
  Plus,
  Trash2,
  Users,
  User,
  Wifi,
  WifiOff,
  Shirt,
  Glasses,
  Sparkles,
  PenLine,
  Share2,
  Download,
  Upload,
  Hand,
  AlertTriangle,
} from "lucide-react";
import { cn } from "@/lib/utils";

export interface LockCategory {
  id: string;
  label: string;
  type: string;
  componentId: string;
  group?: string;
}

export interface LockPlayer {
  source?: number;
  identifier: string;
  name: string;
  online?: boolean;
}

export interface AppearanceLock {
  id: number;
  category: string;
  componentId: string;
  drawable: number;
  texture: number;
  anyTexture?: boolean;
  gender: string;
  ownerIdentifier: string;
  ownerName: string;
  sharedIdentifiers: string[];
  sharedJobs?: string[];
  sharedCount: number;
  expiresAt?: string;
  createdAt?: string;
}

export interface LockPanelData {
  brand?: string;
  staffName?: string;
  staffId?: number;
  staffIdentifier?: string;
  categories?: LockCategory[];
  genders?: { id: string; label: string }[];
  online?: LockPlayer[];
  locks?: AppearanceLock[];
}

interface LockMenuProps {
  data?: LockPanelData | null;
  onClose: () => void;
}

interface GrabFromPedResult {
  drawable?: number;
  texture?: number;
  gender?: string;
  componentId?: string;
}

interface DuplicateCheckResult {
  duplicate?: boolean;
  lock?: AppearanceLock;
}

async function fetchNui<T = unknown>(event: string, payload?: unknown): Promise<T> {
  const resourceName = (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName
    ? (window as Window & { GetParentResourceName: () => string }).GetParentResourceName()
    : "cfx-keydi-ui";
  try {
    const resp = await fetch(`https://${resourceName}/${event}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(payload ?? {}),
    });
    return await resp.json();
  } catch {
    return undefined as T;
  }
}

function lockMatchesSearch(lock: AppearanceLock, query: string): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  const haystack = [
    lock.ownerName,
    lock.ownerIdentifier,
    String(lock.drawable),
    lock.componentId,
    lock.gender,
  ]
    .join(" ")
    .toLowerCase();
  return haystack.includes(q);
}

const GROUP_META: Record<string, { label: string; icon: typeof Shirt }> = {
  clothes: { label: "Clothes", icon: Shirt },
  props: { label: "Props", icon: Glasses },
  head: { label: "Head", icon: Sparkles },
  tattoos: { label: "Tattoos", icon: PenLine },
};

const GENDER_PILLS = [
  { id: "any", label: "Any" },
  { id: "male", label: "Male" },
  { id: "female", label: "Female" },
];

export default function LockMenu({ data, onClose }: LockMenuProps) {
  const categories = data?.categories || [];

  const importRef = useRef<HTMLInputElement>(null);

  const [online, setOnline] = useState<LockPlayer[]>(data?.online || []);
  const [locks, setLocks] = useState<AppearanceLock[]>(data?.locks || []);
  const [selectedGroup, setSelectedGroup] = useState<string>(categories[0]?.group || "clothes");
  const [selectedCategory, setSelectedCategory] = useState<string>(categories[0]?.id || "tops");
  const [busy, setBusy] = useState(false);
  const [lockSearch, setLockSearch] = useState("");

  const [showAdd, setShowAdd] = useState(false);
  const [showShared, setShowShared] = useState<AppearanceLock | null>(null);

  const [drawable, setDrawable] = useState(0);
  const [gender, setGender] = useState("any");
  const [componentOverride, setComponentOverride] = useState("");
  const [ownerMode, setOwnerMode] = useState<"online" | "offline">("online");
  const [ownerSearch, setOwnerSearch] = useState("");
  const [owner, setOwner] = useState<LockPlayer | null>(null);
  const [offlineResults, setOfflineResults] = useState<LockPlayer[]>([]);
  const [sharedPick, setSharedPick] = useState<string[]>([]);
  const [searching, setSearching] = useState(false);
  const [duplicateWarning, setDuplicateWarning] = useState(false);
  const [grabbing, setGrabbing] = useState(false);

  const [sharedSearch, setSharedSearch] = useState("");
  const [sharedOffline, setSharedOffline] = useState<LockPlayer[]>([]);
  const [sharedDraft, setSharedDraft] = useState<string[]>([]);

  const brand = data?.brand || "GRIM CITY";
  const staffIdentifier = data?.staffIdentifier;
  const staffSelf = useMemo(() => {
    if (staffIdentifier) {
      const found = online.find((p) => p.identifier === staffIdentifier);
      if (found) return found;
    }
    if (data?.staffId != null) {
      const found = online.find((p) => p.source === data.staffId);
      if (found) return found;
    }
    if (staffIdentifier) {
      return {
        identifier: staffIdentifier,
        name: data?.staffName || "Me",
        source: data?.staffId,
        online: true,
      } satisfies LockPlayer;
    }
    return null;
  }, [online, staffIdentifier, data?.staffId, data?.staffName]);

  useEffect(() => {
    setOnline(data?.online || []);
    setLocks(data?.locks || []);
    if (data?.categories?.length) {
      const stillExists = data.categories.find((c) => c.id === selectedCategory);
      if (!stillExists) {
        const first = data.categories[0];
        setSelectedGroup(first.group || "clothes");
        setSelectedCategory(first.id);
      } else if (stillExists.group && stillExists.group !== selectedGroup) {
        setSelectedGroup(stillExists.group);
      }
    }
  }, [data, selectedCategory, selectedGroup]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg) return;
      if (msg.action === "cfx-keydi-lockscript:panel:update" && msg.data) {
        if (msg.data.online) setOnline(msg.data.online);
        if (msg.data.locks) setLocks(msg.data.locks);
      }
    };
    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  useEffect(() => {
    if (!showAdd || ownerMode !== "offline") return;
    const q = ownerSearch.trim();
    if (q.length < 2) {
      setOfflineResults([]);
      return;
    }
    const timer = setTimeout(async () => {
      setSearching(true);
      const results = await fetchNui<LockPlayer[]>("cfx-keydi-lockscript:searchOffline", { query: q });
      setOfflineResults(Array.isArray(results) ? results : []);
      setSearching(false);
    }, 280);
    return () => clearTimeout(timer);
  }, [ownerSearch, ownerMode, showAdd]);

  useEffect(() => {
    if (!showShared) return;
    const q = sharedSearch.trim();
    if (q.length < 2) {
      setSharedOffline([]);
      return;
    }
    const timer = setTimeout(async () => {
      const results = await fetchNui<LockPlayer[]>("cfx-keydi-lockscript:searchOffline", { query: q });
      setSharedOffline(Array.isArray(results) ? results : []);
    }, 280);
    return () => clearTimeout(timer);
  }, [sharedSearch, showShared]);

  useEffect(() => {
    if (duplicateWarning) setDuplicateWarning(false);
  }, [drawable, gender, componentOverride, selectedCategory, owner?.identifier]);

  const grouped = useMemo(() => {
    const map: Record<string, LockCategory[]> = {};
    for (const cat of categories) {
      const g = cat.group || "other";
      if (!map[g]) map[g] = [];
      map[g].push(cat);
    }
    return map;
  }, [categories]);

  const groupKeys = useMemo(() => Object.keys(grouped), [grouped]);

  const categoriesInGroup = useMemo(
    () => grouped[selectedGroup] || [],
    [grouped, selectedGroup]
  );

  const searchActive = lockSearch.trim().length > 0;

  const displayedLocks = useMemo(() => {
    const base = searchActive
      ? locks
      : locks.filter((l) => l.category === selectedCategory);
    return base.filter((l) => lockMatchesSearch(l, lockSearch));
  }, [locks, selectedCategory, lockSearch, searchActive]);

  const activeCat = categories.find((c) => c.id === selectedCategory);

  const onGroupChange = (group: string) => {
    setSelectedGroup(group);
    const first = grouped[group]?.[0];
    if (first) setSelectedCategory(first.id);
  };

  const filteredOnline = useMemo(() => {
    const q = ownerSearch.trim().toLowerCase();
    const list = q
      ? online.filter((p) => `${p.name} ${p.source ?? ""} ${p.identifier}`.toLowerCase().includes(q))
      : [...online];
    const meId = staffIdentifier;
    if (!meId) return list;
    return list.sort((a, b) => {
      if (a.identifier === meId) return -1;
      if (b.identifier === meId) return 1;
      return 0;
    });
  }, [online, ownerSearch, staffIdentifier]);

  const ownerList = useMemo(() => {
    const base = ownerMode === "online" ? filteredOnline : offlineResults;
    if (ownerMode !== "online" || !staffSelf) return base;
    if (base.some((p) => p.identifier === staffSelf.identifier)) return base;
    return [staffSelf, ...base];
  }, [ownerMode, filteredOnline, offlineResults, staffSelf]);

  const refresh = async () => {
    setBusy(true);
    const res = await fetchNui<{ online?: LockPlayer[]; locks?: AppearanceLock[] }>(
      "cfx-keydi-lockscript:refresh"
    );
    if (res?.online) setOnline(res.online);
    if (res?.locks) setLocks(res.locks);
    setBusy(false);
  };

  const openAdd = () => {
    setDrawable(0);
    setGender("any");
    setComponentOverride("");
    setOwner(staffSelf);
    setSharedPick([]);
    setOwnerSearch("");
    setOwnerMode("online");
    setDuplicateWarning(false);
    setShowAdd(true);
  };

  /** Whole drawable is locked (all textures). */
  const buildAddPayload = () => ({
    category: selectedCategory,
    componentId: componentOverride.trim() || activeCat?.componentId,
    drawable: Math.floor(Number(drawable) || 0),
    texture: 0,
    anyTexture: true,
    gender,
    ownerIdentifier: owner?.identifier,
    ownerName: owner?.name,
    sharedIdentifiers: sharedPick,
    sharedJobs: [] as string[],
  });

  const grabFromPed = async () => {
    setGrabbing(true);
    const res = await fetchNui<GrabFromPedResult>("cfx-keydi-lockscript:grabFromPed", {
      category: selectedCategory,
    });
    if (res) {
      if (res.drawable != null) setDrawable(res.drawable);
      if (res.gender) setGender(res.gender);
      if (res.componentId) setComponentOverride(res.componentId);
    }
    setGrabbing(false);
  };

  const submitAdd = async () => {
    if (!owner || busy) return;

    setBusy(true);
    const payload = buildAddPayload();
    const dup = await fetchNui<DuplicateCheckResult>("cfx-keydi-lockscript:checkDuplicate", payload);

    if (dup?.duplicate) {
      setDuplicateWarning(true);
      setBusy(false);
      return;
    }

    await fetchNui("cfx-keydi-lockscript:addLock", payload);
    setShowAdd(false);
    setDuplicateWarning(false);
    setTimeout(refresh, 350);
    setBusy(false);
  };

  const removeLock = async (lock: AppearanceLock) => {
    if (busy) return;
    setBusy(true);
    await fetchNui("cfx-keydi-lockscript:removeLock", { lockId: lock.id });
    setTimeout(refresh, 350);
    setBusy(false);
  };

  const openShared = (lock: AppearanceLock) => {
    setShowShared(lock);
    setSharedDraft([...(lock.sharedIdentifiers || [])]);
    setSharedSearch("");
  };

  const saveShared = async () => {
    if (!showShared || busy) return;
    setBusy(true);
    await fetchNui("cfx-keydi-lockscript:setShared", {
      lockId: showShared.id,
      sharedIdentifiers: sharedDraft,
      sharedJobs: [],
    });
    setShowShared(null);
    setTimeout(refresh, 350);
    setBusy(false);
  };

  const exportLocks = async () => {
    setBusy(true);
    const res = await fetchNui<AppearanceLock[] | { locks?: AppearanceLock[] }>(
      "cfx-keydi-lockscript:exportLocks"
    );
    const exported = Array.isArray(res) ? res : res?.locks || locks;
    const blob = new Blob([JSON.stringify(exported, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "keydi-locks.json";
    a.click();
    URL.revokeObjectURL(url);
    setBusy(false);
  };

  const importLocks = async (file: File) => {
    try {
      const text = await file.text();
      const parsed = JSON.parse(text);
      const imported: AppearanceLock[] = Array.isArray(parsed) ? parsed : parsed?.locks;
      if (!Array.isArray(imported)) return;

      setBusy(true);
      await fetchNui("cfx-keydi-lockscript:importLocks", { locks: imported });
      setTimeout(refresh, 350);
      setBusy(false);
    } catch {
      /* invalid JSON */
    } finally {
      if (importRef.current) importRef.current.value = "";
    }
  };

  const toggleSharedId = (identifier: string, list: string[], setList: (v: string[]) => void) => {
    if (list.includes(identifier)) {
      setList(list.filter((id) => id !== identifier));
    } else {
      setList([...list, identifier]);
    }
  };

  const playerLabel = (identifier: string) => {
    const found = online.find((p) => p.identifier === identifier);
    return found ? `${found.name} (#${found.source})` : identifier;
  };

  const preferredGroupOrder = ["clothes", "props", "head"];
  const orderedGroups = [
    ...preferredGroupOrder.filter((g) => grouped[g]),
    ...groupKeys.filter((g) => !preferredGroupOrder.includes(g)),
  ];

  const categoryLockCount = locks.filter((l) => l.category === selectedCategory).length;

  return (
    <div className="pandora fixed inset-0 z-[99995] flex items-center justify-center bg-black/80 p-3 font-sans backdrop-blur-[6px]">
      <div
        className="relative flex h-[78vh] w-[980px] max-h-[820px] max-w-[96vw] flex-col overflow-hidden rounded-2xl border-2 border-[#ff3a3a] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.95)]"
        style={{ background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)" }}
      >
        <div className="panel-grid pointer-events-none absolute inset-0 opacity-25" />

        <div
          className="relative flex items-center justify-between gap-2 border-b px-4 py-2.5"
          style={{ borderBottomColor: "rgba(255, 58, 58, 0.25)" }}
        >
          <div className="flex min-w-0 items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg border border-[#ff3a3a] bg-[#ff3a3a]/15">
              <Lock className="h-4 w-4 text-white" />
            </div>
            <div className="min-w-0">
              <p className="text-[10px] font-black uppercase tracking-[0.22em] text-[#ff4d4d]">
                VIP Appearance Locks
              </p>
              <p className="truncate text-[11px] font-bold uppercase tracking-wider text-[#a08890]">
                {brand} · {data?.staffName || "Staff"}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={exportLocks}
              disabled={busy}
              className="flex h-8 items-center gap-1 rounded-md border border-[#ff3a3a]/30 bg-[#181216] px-2.5 text-[9px] font-bold uppercase tracking-wide text-white/80 transition hover:border-[#ff3a3a] hover:text-white disabled:opacity-40"
              title="Export locks"
            >
              <Download className="h-3.5 w-3.5 text-[#ff4d4d]" />
              Export
            </button>
            <button
              type="button"
              onClick={() => importRef.current?.click()}
              disabled={busy}
              className="flex h-8 items-center gap-1 rounded-md border border-[#ff3a3a]/30 bg-[#181216] px-2.5 text-[9px] font-bold uppercase tracking-wide text-white/80 transition hover:border-[#ff3a3a] hover:text-white disabled:opacity-40"
              title="Import locks"
            >
              <Upload className="h-3.5 w-3.5 text-[#ff4d4d]" />
              Import
            </button>
            <input
              ref={importRef}
              type="file"
              accept=".json,application/json"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) void importLocks(file);
              }}
            />
            <button
              type="button"
              onClick={refresh}
              disabled={busy}
              className="flex h-8 w-8 items-center justify-center rounded-md border border-[#ff3a3a]/30 bg-[#181216] text-white/80 transition hover:border-[#ff3a3a] hover:text-white disabled:opacity-40"
              title="Refresh"
            >
              <RefreshCw className={cn("h-3.5 w-3.5 text-[#ff4d4d]", busy && "animate-spin")} />
            </button>
            <button
              type="button"
              onClick={onClose}
              className="flex items-center gap-1 rounded-md border border-[#ff3a3a]/30 bg-[#181216] px-2.5 py-1.5 text-[10px] font-semibold text-white/80 transition hover:border-[#ff3a3a] hover:text-white"
            >
              <span>Esc</span>
              <X className="h-3.5 w-3.5 text-[#ff4d4d]" />
            </button>
          </div>
        </div>

        <div className="relative grid min-h-0 flex-1 grid-cols-[150px_1fr]">
          <div className="flex min-h-0 flex-col gap-1 border-r border-[#ff3a3a]/20 p-2.5">
            {orderedGroups.map((g) => {
              const meta = GROUP_META[g] || { label: g, icon: Lock };
              const Icon = meta.icon;
              const active = selectedGroup === g;
              const groupLockCount = (grouped[g] || []).reduce(
                (sum, cat) => sum + locks.filter((l) => l.category === cat.id).length,
                0
              );
              return (
                <button
                  key={g}
                  type="button"
                  onClick={() => onGroupChange(g)}
                  className={cn(
                    "flex items-center gap-2 rounded-lg border px-2.5 py-2.5 text-left transition",
                    active
                      ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-[#ff4d4d]"
                      : "border-transparent bg-[#181216] text-[#a08890] hover:border-[#ff3a3a]/40 hover:text-white"
                  )}
                >
                  <Icon className="h-3.5 w-3.5 shrink-0" />
                  <span className="min-w-0 flex-1 truncate text-[11px] font-bold uppercase tracking-wide">
                    {meta.label}
                  </span>
                  {groupLockCount > 0 && (
                    <span
                      className={cn(
                        "rounded px-1.5 py-0.5 text-[9px] font-bold",
                        active ? "bg-black/30 text-[#ff4d4d]" : "bg-black/30 text-white/40"
                      )}
                    >
                      {groupLockCount}
                    </span>
                  )}
                </button>
              );
            })}
          </div>

          <div className="flex min-h-0 flex-col">
            <div className="flex items-center gap-2 border-b border-[#ff3a3a]/20 px-3 py-2">
              <div className="no-scrollbar flex min-w-0 flex-1 gap-1.5 overflow-x-auto">
                {categoriesInGroup.map((cat) => {
                  const count = locks.filter((l) => l.category === cat.id).length;
                  const active = selectedCategory === cat.id;
                  return (
                    <button
                      key={cat.id}
                      type="button"
                      onClick={() => setSelectedCategory(cat.id)}
                      className={cn(
                        "shrink-0 rounded-md border px-2.5 py-1.5 text-[10px] font-bold uppercase tracking-wide transition",
                        active
                          ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-[#ff4d4d]"
                          : "border-[#ff3a3a]/20 bg-[#181216] text-[#a08890] hover:border-[#ff3a3a]/50 hover:text-white"
                      )}
                    >
                      {cat.label}
                      {count > 0 ? ` · ${count}` : ""}
                    </button>
                  );
                })}
              </div>
              <button
                type="button"
                onClick={openAdd}
                className="inline-flex h-8 shrink-0 items-center gap-1 rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/20 px-3 text-[10px] font-bold uppercase tracking-wide text-[#ff4d4d] transition hover:bg-[#ff3a3a]/30"
              >
                <Plus className="h-3.5 w-3.5" /> Add
              </button>
            </div>

            <div className="flex items-center gap-2 px-3 pt-2 pb-1.5">
              <p className="shrink-0 text-[10px] text-[#a08890]">
                <span className="font-semibold text-white/80">{activeCat?.label || "—"}</span>
                {" · "}
                {searchActive ? (
                  <>
                    {displayedLocks.length} match{displayedLocks.length === 1 ? "" : "es"}
                  </>
                ) : (
                  <>
                    {categoryLockCount} lock{categoryLockCount === 1 ? "" : "s"}
                  </>
                )}
              </p>
              <div className="relative min-w-0 flex-1">
                <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[#a08890]" />
                <input
                  value={lockSearch}
                  onChange={(e) => setLockSearch(e.target.value)}
                  placeholder="Search owner, identifier, drawable..."
                  className="w-full rounded-md border border-[#ff3a3a]/25 bg-[#181216] py-1.5 pl-8 pr-8 text-[11px] text-white outline-none placeholder:text-[#a08890]/60 focus:border-[#ff3a3a]"
                />
                {lockSearch && (
                  <button
                    type="button"
                    onClick={() => setLockSearch("")}
                    className="absolute right-2 top-1/2 -translate-y-1/2 text-[#a08890] hover:text-white"
                  >
                    <X className="h-3.5 w-3.5" />
                  </button>
                )}
              </div>
            </div>

            <div className="no-scrollbar relative min-h-0 flex-1 overflow-y-auto px-3 pb-3">
              {displayedLocks.length === 0 ? (
                <div className="flex h-full min-h-[220px] items-center justify-center rounded-lg border border-dashed border-[#ff3a3a]/25 bg-[#181216]/60">
                  <p className="text-[11px] text-[#a08890]">
                    {searchActive ? "No locks match your search." : "No locks in this category yet."}
                  </p>
                </div>
              ) : (
                <div className="overflow-hidden rounded-lg border border-[#ff3a3a]/25">
                  <table className="w-full text-left text-[11px]">
                    <thead className="sticky top-0 z-[1]">
                      <tr className="border-b border-[#ff3a3a]/20 bg-[#140d11] text-[9px] font-black uppercase tracking-wider text-[#a08890]">
                        <th className="px-3 py-2">Drawable</th>
                        <th className="px-3 py-2">Gender</th>
                        <th className="px-3 py-2">Owner</th>
                        <th className="px-3 py-2">Shared</th>
                        <th className="px-3 py-2 text-right"> </th>
                      </tr>
                    </thead>
                    <tbody>
                      {displayedLocks.map((lock) => {
                        const lockCat = categories.find((c) => c.id === lock.category);
                        return (
                          <tr
                            key={lock.id}
                            className="border-b border-white/5 transition hover:bg-white/[0.03]"
                          >
                            <td className="px-3 py-2.5 font-mono text-white">
                              <span className="text-[13px] font-black text-[#ff4d4d]">{lock.drawable}</span>
                              <span className="ml-1.5 text-[9px] font-bold uppercase text-[#a08890]">
                                all textures
                              </span>
                              {(lockCat?.type === "tattoo" || searchActive) && (
                                <p className="mt-0.5 max-w-[140px] truncate text-[9px] text-white/40">
                                  {lock.componentId}
                                  {searchActive && lockCat && (
                                    <span className="text-white/25"> · {lockCat.label}</span>
                                  )}
                                </p>
                              )}
                            </td>
                            <td className="px-3 py-2.5 capitalize text-white/70">{lock.gender}</td>
                            <td className="px-3 py-2.5">
                              <p className="max-w-[180px] truncate font-semibold text-white">{lock.ownerName}</p>
                              <p className="max-w-[180px] truncate font-mono text-[9px] text-[#a08890]">
                                {lock.ownerIdentifier}
                              </p>
                            </td>
                            <td className="px-3 py-2.5 text-white/70">
                              {lock.sharedCount ?? lock.sharedIdentifiers?.length ?? 0}
                            </td>
                            <td className="px-3 py-2.5">
                              <div className="flex items-center justify-end gap-1">
                                <button
                                  type="button"
                                  onClick={() => openShared(lock)}
                                  className="rounded-md border border-[#ff3a3a]/25 bg-[#181216] p-1.5 text-[#a08890] transition hover:border-[#ff3a3a] hover:text-[#ff4d4d]"
                                  title="Share with players"
                                >
                                  <Share2 className="h-3.5 w-3.5" />
                                </button>
                                <button
                                  type="button"
                                  onClick={() => removeLock(lock)}
                                  className="rounded-md border border-[#ff3a3a]/25 bg-[#181216] p-1.5 text-[#a08890] transition hover:border-red-400/40 hover:text-red-300"
                                  title="Remove lock"
                                >
                                  <Trash2 className="h-3.5 w-3.5" />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>

        {showAdd && (
          <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/65 p-4">
            <div
              className="flex h-[520px] w-full max-w-[860px] flex-col overflow-hidden rounded-xl border-2 border-[#ff3a3a]"
              style={{ background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)" }}
            >
              <div className="flex shrink-0 items-center justify-between border-b border-[#ff3a3a]/25 px-4 py-2.5">
                <div>
                  <p className="text-[12px] font-black uppercase tracking-wider text-white">
                    Add Lock · {activeCat?.label}
                  </p>
                  <p className="text-[9px] text-[#a08890]">Locks the whole drawable (all textures)</p>
                </div>
                <button type="button" onClick={() => setShowAdd(false)} className="text-[#a08890] hover:text-white">
                  <X className="h-4 w-4" />
                </button>
              </div>

              {duplicateWarning && (
                <div className="mx-4 mt-2 flex shrink-0 items-center gap-2 rounded-lg border border-red-400/40 bg-red-500/15 px-3 py-2">
                  <AlertTriangle className="h-4 w-4 shrink-0 text-red-300" />
                  <p className="text-[11px] font-semibold text-red-200">Already locked — duplicate entry exists.</p>
                </div>
              )}

              <div className="grid min-h-0 flex-1 grid-cols-2">
                {/* Left panel — lock values */}
                <div className="flex min-h-0 flex-col gap-3 overflow-y-auto border-r border-[#ff3a3a]/25 p-4">
                  <p className="text-[9px] font-black uppercase tracking-[0.18em] text-[#ff4d4d]">Lock Values</p>

                  <div className="flex items-end gap-2">
                    <label className="min-w-0 flex-1">
                      <span className="text-[9px] font-bold uppercase text-[#a08890]">Drawable</span>
                      <input
                        type="number"
                        value={drawable}
                        onChange={(e) => setDrawable(Number(e.target.value))}
                        className="mt-1 w-full rounded-lg border border-[#ff3a3a]/30 bg-[#181216] px-3 py-2.5 text-[18px] font-black text-[#ff4d4d] outline-none focus:border-[#ff3a3a]"
                      />
                    </label>
                    <button
                      type="button"
                      onClick={grabFromPed}
                      disabled={grabbing || busy}
                      className="inline-flex h-[46px] shrink-0 items-center gap-1.5 rounded-lg border border-[#ff3a3a] bg-[#ff3a3a]/15 px-3 text-[10px] font-bold uppercase tracking-wide text-[#ff4d4d] transition hover:bg-[#ff3a3a]/25 disabled:opacity-40"
                    >
                      <Hand className={cn("h-3.5 w-3.5", grabbing && "animate-pulse")} />
                      Grab
                    </button>
                  </div>

                  <div>
                    <span className="mb-1.5 block text-[9px] font-bold uppercase text-[#a08890]">Gender</span>
                    <div className="flex gap-1.5">
                      {GENDER_PILLS.map((g) => (
                        <button
                          key={g.id}
                          type="button"
                          onClick={() => setGender(g.id)}
                          className={cn(
                            "flex-1 rounded-md border px-2 py-2 text-[10px] font-bold uppercase transition",
                            gender === g.id
                              ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-[#ff4d4d]"
                              : "border-[#ff3a3a]/20 bg-[#181216] text-[#a08890] hover:text-white"
                          )}
                        >
                          {g.label}
                        </button>
                      ))}
                    </div>
                  </div>

                  {(activeCat?.type === "tattoo" || activeCat?.type === "headOverlay") && (
                    <label className="block">
                      <span className="text-[9px] font-bold uppercase text-[#a08890]">
                        {activeCat?.type === "tattoo" ? "Tattoo name" : "Component key"}
                      </span>
                      <input
                        value={componentOverride}
                        onChange={(e) => setComponentOverride(e.target.value)}
                        placeholder={activeCat?.componentId}
                        className="mt-1 w-full rounded-lg border border-[#ff3a3a]/25 bg-[#181216] px-2.5 py-2 text-[12px] text-white outline-none placeholder:text-[#a08890]/50 focus:border-[#ff3a3a]"
                      />
                    </label>
                  )}

                  <div className="mt-auto rounded-lg border border-[#ff3a3a]/25 bg-[#181216] p-3">
                    <p className="text-[9px] font-bold uppercase tracking-wider text-[#a08890]">Summary</p>
                    <p className="mt-1.5 text-[12px] font-semibold text-white">
                      {activeCat?.label || "—"} · Drawable{" "}
                      <span className="font-black text-[#ff4d4d]">{drawable}</span>
                    </p>
                    <p className="mt-0.5 text-[10px] capitalize text-[#a08890]">
                      Gender · {gender} · All textures
                    </p>
                    <p className="mt-0.5 truncate text-[10px] text-[#a08890]">
                      Owner · {owner?.name || "Select on right →"}
                    </p>
                  </div>
                </div>

                {/* Right panel — owner + shared */}
                <div className="flex min-h-0 flex-col gap-2.5 overflow-hidden p-4">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-[9px] font-black uppercase tracking-[0.18em] text-[#ff4d4d]">Owner</p>
                    <div className="flex items-center gap-1.5">
                      {staffSelf && (
                        <button
                          type="button"
                          onClick={() => {
                            setOwnerMode("online");
                            setOwner(staffSelf);
                            setOwnerSearch("");
                          }}
                          className={cn(
                            "inline-flex items-center gap-1 rounded-md border px-2 py-0.5 text-[9px] font-bold uppercase tracking-wide transition",
                            owner?.identifier === staffSelf.identifier
                              ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-[#ff4d4d]"
                              : "border-[#ff3a3a]/20 bg-[#181216] text-[#a08890] hover:text-[#ff4d4d]"
                          )}
                        >
                          <User className="h-3 w-3" /> Me
                        </button>
                      )}
                      <div className="flex rounded-md border border-[#ff3a3a]/25 bg-[#181216] p-0.5">
                        <button
                          type="button"
                          onClick={() => setOwnerMode("online")}
                          className={cn(
                            "inline-flex items-center gap-1 rounded px-2 py-0.5 text-[9px] font-bold uppercase",
                            ownerMode === "online" ? "bg-[#ff3a3a]/25 text-[#ff4d4d]" : "text-[#a08890]"
                          )}
                        >
                          <Wifi className="h-3 w-3" /> Online
                        </button>
                        <button
                          type="button"
                          onClick={() => setOwnerMode("offline")}
                          className={cn(
                            "inline-flex items-center gap-1 rounded px-2 py-0.5 text-[9px] font-bold uppercase",
                            ownerMode === "offline" ? "bg-[#ff3a3a]/25 text-[#ff4d4d]" : "text-[#a08890]"
                          )}
                        >
                          <WifiOff className="h-3 w-3" /> Offline
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="relative">
                    <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[#a08890]" />
                    <input
                      value={ownerSearch}
                      onChange={(e) => setOwnerSearch(e.target.value)}
                      placeholder={ownerMode === "online" ? "Search online..." : "Search by name / identifier..."}
                      className="w-full rounded-lg border border-[#ff3a3a]/25 bg-[#181216] py-2 pl-8 pr-3 text-[12px] text-white outline-none placeholder:text-[#a08890]/60 focus:border-[#ff3a3a]"
                    />
                  </div>

                  <div className="no-scrollbar min-h-0 flex-1 space-y-1 overflow-y-auto rounded-lg border border-[#ff3a3a]/25 bg-[#181216] p-1.5">
                    {ownerMode === "offline" && ownerSearch.trim().length < 2 && (
                      <p className="py-4 text-center text-[10px] text-[#a08890]">Type at least 2 characters.</p>
                    )}
                    {searching && <p className="py-3 text-center text-[10px] text-[#a08890]">Searching...</p>}
                    {ownerList.map((p) => {
                      const sel = owner?.identifier === p.identifier;
                      return (
                        <button
                          key={`${p.identifier}-${p.source ?? "off"}`}
                          type="button"
                          onClick={() => setOwner(p)}
                          className={cn(
                            "flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-left transition",
                            sel ? "bg-[#ff3a3a]/20 text-[#ff4d4d]" : "text-white/70 hover:bg-white/5"
                          )}
                        >
                          <User className="h-3.5 w-3.5 shrink-0 opacity-50" />
                          <span className="min-w-0 flex-1 truncate text-[11px] font-semibold">{p.name}</span>
                          {(p.identifier === staffIdentifier || p.source === data?.staffId) && (
                            <span className="rounded bg-[#ff3a3a]/20 px-1.5 py-0.5 text-[8px] font-black uppercase tracking-wide text-[#ff4d4d]">
                              You
                            </span>
                          )}
                          {p.source != null && (
                            <span className="text-[9px] text-[#a08890]">#{p.source}</span>
                          )}
                        </button>
                      );
                    })}
                  </div>

                  <div className="shrink-0">
                    <span className="text-[9px] font-bold uppercase text-[#a08890]">
                      Also allow ({sharedPick.length})
                    </span>
                    <div className="mt-1 max-h-[110px] space-y-1 overflow-y-auto rounded-lg border border-[#ff3a3a]/25 bg-[#181216] p-1.5">
                      {online
                        .filter((p) => p.identifier !== owner?.identifier)
                        .map((p) => {
                          const on = sharedPick.includes(p.identifier);
                          return (
                            <button
                              key={p.identifier}
                              type="button"
                              onClick={() => toggleSharedId(p.identifier, sharedPick, setSharedPick)}
                              className={cn(
                                "flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-left text-[11px] transition",
                                on ? "bg-emerald-500/15 text-emerald-300" : "text-white/60 hover:bg-white/5"
                              )}
                            >
                              <Users className="h-3 w-3 shrink-0 opacity-50" />
                              <span className="truncate font-semibold">{p.name}</span>
                            </button>
                          );
                        })}
                      {online.filter((p) => p.identifier !== owner?.identifier).length === 0 && (
                        <p className="py-2 text-center text-[10px] text-[#a08890]">No other online players.</p>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              <div className="flex shrink-0 justify-end gap-2 border-t border-[#ff3a3a]/25 px-4 py-2.5">
                <button
                  type="button"
                  onClick={() => setShowAdd(false)}
                  className="rounded-lg border border-[#ff3a3a]/25 px-3 py-1.5 text-[11px] font-semibold text-[#a08890] hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={!owner || busy || duplicateWarning}
                  onClick={submitAdd}
                  className="rounded-lg border border-[#ff3a3a] bg-[#ff3a3a]/25 px-4 py-1.5 text-[11px] font-bold uppercase text-[#ff4d4d] disabled:opacity-40"
                >
                  Create Lock
                </button>
              </div>
            </div>
          </div>
        )}

        {showShared && (
          <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/65 p-5">
            <div
              className="flex max-h-[92%] w-full max-w-[460px] flex-col overflow-hidden rounded-xl border-2 border-[#ff3a3a]"
              style={{ background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)" }}
            >
              <div className="flex items-center justify-between border-b border-[#ff3a3a]/25 px-4 py-2.5">
                <div>
                  <p className="text-[12px] font-black uppercase tracking-wider text-white">Shared Access</p>
                  <p className="text-[9px] text-[#a08890]">
                    Owner · {showShared.ownerName} · drawable {showShared.drawable}
                  </p>
                </div>
                <button type="button" onClick={() => setShowShared(null)} className="text-[#a08890] hover:text-white">
                  <X className="h-4 w-4" />
                </button>
              </div>

              <div className="no-scrollbar min-h-0 flex-1 space-y-3 overflow-y-auto p-4">
                <div>
                  <span className="text-[9px] font-bold uppercase text-[#a08890]">Currently shared</span>
                  <div className="mt-1.5 space-y-1">
                    {sharedDraft.length === 0 && (
                      <p className="py-2 text-[10px] text-[#a08890]">Nobody else has access.</p>
                    )}
                    {sharedDraft.map((id) => (
                      <div
                        key={id}
                        className="flex items-center justify-between gap-2 rounded-lg border border-[#ff3a3a]/25 bg-[#181216] px-2.5 py-1.5"
                      >
                        <span className="truncate text-[11px] text-white/80">{playerLabel(id)}</span>
                        <button
                          type="button"
                          onClick={() => setSharedDraft(sharedDraft.filter((x) => x !== id))}
                          className="text-red-300/80 hover:text-red-300"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>

                <div>
                  <span className="text-[9px] font-bold uppercase text-[#a08890]">Add players</span>
                  <div className="relative mt-1.5 mb-2">
                    <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[#a08890]" />
                    <input
                      value={sharedSearch}
                      onChange={(e) => setSharedSearch(e.target.value)}
                      placeholder="Search offline to add..."
                      className="w-full rounded-lg border border-[#ff3a3a]/25 bg-[#181216] py-2 pl-8 pr-3 text-[12px] text-white outline-none placeholder:text-[#a08890]/60 focus:border-[#ff3a3a]"
                    />
                  </div>
                  <div className="max-h-[180px] space-y-1 overflow-y-auto rounded-lg border border-[#ff3a3a]/25 bg-[#181216] p-1.5">
                    {[...online, ...sharedOffline]
                      .filter(
                        (p, i, arr) =>
                          p.identifier !== showShared.ownerIdentifier &&
                          arr.findIndex((x) => x.identifier === p.identifier) === i
                      )
                      .map((p) => {
                        const on = sharedDraft.includes(p.identifier);
                        return (
                          <button
                            key={p.identifier}
                            type="button"
                            onClick={() => toggleSharedId(p.identifier, sharedDraft, setSharedDraft)}
                            className={cn(
                              "flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-left text-[11px] transition",
                              on ? "bg-emerald-500/15 text-emerald-300" : "text-white/60 hover:bg-white/5"
                            )}
                          >
                            <span className="truncate font-semibold">{p.name}</span>
                            {p.online !== false && p.source != null && (
                              <span className="text-[9px] text-[#a08890]">#{p.source}</span>
                            )}
                          </button>
                        );
                      })}
                  </div>
                </div>
              </div>

              <div className="flex justify-end gap-2 border-t border-[#ff3a3a]/25 px-4 py-3">
                <button
                  type="button"
                  onClick={() => setShowShared(null)}
                  className="rounded-lg border border-[#ff3a3a]/25 px-3 py-1.5 text-[11px] font-semibold text-[#a08890] hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={saveShared}
                  className="rounded-lg border border-[#ff3a3a] bg-[#ff3a3a]/25 px-4 py-1.5 text-[11px] font-bold uppercase text-[#ff4d4d] disabled:opacity-40"
                >
                  Save Access
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
