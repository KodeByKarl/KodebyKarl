import { useEffect, useMemo, useState } from "react";
import {
  AlertTriangle,
  Ban,
  CalendarClock,
  Check,
  Clock,
  Crown,
  Pencil,
  RefreshCw,
  Search,
  ShieldCheck,
  UserPlus,
  Users,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { fetchNui } from "@/lib/nui";
import {
  type DbVipMember,
  type VipDurationUnit,
  type VipPlayerRow,
  type VipTierOption,
} from "./types";

interface VipStaffPanelProps {
  onOwnStatusChanged: () => void;
}

const DURATION_PRESETS: { label: string; days: number }[] = [
  { label: "7 Days", days: 7 },
  { label: "15 Days", days: 15 },
  { label: "30 Days (1 Mo)", days: 30 },
  { label: "60 Days (2 Mo)", days: 60 },
  { label: "90 Days (3 Mo)", days: 90 },
  { label: "180 Days (6 Mo)", days: 180 },
  { label: "365 Days (1 Yr)", days: 365 },
];

function formatDate(iso: string | null) {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function computeExpiryPreview(days: number) {
  if (!Number.isFinite(days) || days < 1) return null;
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
}

export default function VipStaffPanel({ onOwnStatusChanged }: VipStaffPanelProps) {
  const [subTab, setSubTab] = useState<"database" | "grant">("database");
  const [tiers, setTiers] = useState<VipTierOption[]>([]);
  const [dbMembers, setDbMembers] = useState<DbVipMember[]>([]);
  const [onlinePlayers, setOnlinePlayers] = useState<VipPlayerRow[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  // Grant Form State
  const [grantTargetId, setGrantTargetId] = useState<string>("");
  const [grantPlayerName, setGrantPlayerName] = useState<string>("");
  const [grantTier, setGrantTier] = useState<string>("vip3");
  const [grantDays, setGrantDays] = useState<number>(30);
  const [grantAutoRenew, setGrantAutoRenew] = useState<boolean>(false);

  // Edit Modal State
  const [editingMember, setEditingMember] = useState<DbVipMember | null>(null);
  const [editTier, setEditTier] = useState<string>("vip3");
  const [editMode, setEditMode] = useState<"keep" | "add" | "custom">("keep");
  const [editAddDays, setEditAddDays] = useState<number>(30);
  const [editCustomDate, setEditCustomDate] = useState<string>("");
  const [editAutoRenew, setEditAutoRenew] = useState<boolean>(false);

  const loadData = () => {
    setLoading(true);
    setMessage(null);
    Promise.all([
      fetchNui<{ ok?: boolean; members?: DbVipMember[]; tiers?: VipTierOption[]; players?: VipPlayerRow[] }>(
        "cfx-keydi-vip:getAllVipMembers",
        {}
      ),
      fetchNui<{ ok?: boolean; tiers?: VipTierOption[]; players?: VipPlayerRow[] }>(
        "cfx-keydi-vip:staffRoster",
        {}
      ),
    ])
      .then(([allRes, rosterRes]) => {
        if (allRes?.members) setDbMembers(allRes.members);
        if (allRes?.tiers) setTiers(allRes.tiers);
        else if (rosterRes?.tiers) setTiers(rosterRes.tiers);
        if (rosterRes?.players) setOnlinePlayers(rosterRes.players);
      })
      .catch(() => undefined)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadData();
  }, []);

  const filteredDbMembers = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return dbMembers;
    return dbMembers.filter(
      (m) =>
        m.name.toLowerCase().includes(q) ||
        m.identifier.toLowerCase().includes(q) ||
        (m.onlineId && String(m.onlineId).includes(q)) ||
        m.tier.toLowerCase().includes(q) ||
        m.label.toLowerCase().includes(q)
    );
  }, [dbMembers, searchQuery]);

  const filteredOnlinePlayers = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return onlinePlayers;
    return onlinePlayers.filter(
      (p) => String(p.id).includes(q) || p.name.toLowerCase().includes(q)
    );
  }, [onlinePlayers, searchQuery]);

  // Open Edit Modal
  const openEditModal = (member: DbVipMember) => {
    setEditingMember(member);
    setEditTier(member.tier || "vip1");
    setEditAutoRenew(!!member.autoRenew);
    setEditMode("keep");
    setEditAddDays(30);
    setEditCustomDate(member.expiresAt ? member.expiresAt.substring(0, 16) : "");
    setMessage(null);
  };

  // Submit Edit
  const handleSaveEdit = async () => {
    if (!editingMember) return;
    setBusy(true);
    setMessage(null);

    try {
      const payload: any = {
        identifier: editingMember.identifier,
        tier: editTier,
        autoRenew: editAutoRenew,
        name: editingMember.name,
      };

      if (editMode === "keep") {
        payload.keepExpiry = true;
      } else if (editMode === "add") {
        payload.addDays = editAddDays;
      } else if (editMode === "custom") {
        if (!editCustomDate) {
          setMessage({ ok: false, text: "Please enter a valid expiration date." });
          setBusy(false);
          return;
        }
        // Convert to SQL format YYYY-MM-DD HH:MM:SS
        payload.customExpires = editCustomDate.replace("T", " ") + (editCustomDate.length === 16 ? ":00" : "");
      }

      const res = await fetchNui<{ ok?: boolean; error?: string }>("cfx-keydi-vip:staffEditVip", payload);
      if (!res?.ok) {
        setMessage({ ok: false, text: res?.error || "Failed to update VIP." });
        return;
      }

      setMessage({ ok: true, text: `Successfully updated VIP for ${editingMember.name}` });
      setEditingMember(null);
      loadData();
      onOwnStatusChanged();
    } catch {
      setMessage({ ok: false, text: "Failed to update VIP member." });
    } finally {
      setBusy(false);
    }
  };

  // Revoke VIP Member
  const handleRevoke = async (identifier: string, name: string) => {
    if (!confirm(`Are you sure you want to revoke VIP from ${name}?`)) return;
    setBusy(true);
    setMessage(null);

    try {
      const res = await fetchNui<{ ok?: boolean; error?: string }>(
        "cfx-keydi-vip:staffRevokeByIdentifier",
        { identifier }
      );
      if (!res?.ok) {
        setMessage({ ok: false, text: res?.error || "Failed to revoke VIP." });
        return;
      }
      setMessage({ ok: true, text: `Revoked VIP for ${name}` });
      if (editingMember?.identifier === identifier) {
        setEditingMember(null);
      }
      loadData();
      onOwnStatusChanged();
    } catch {
      setMessage({ ok: false, text: "Failed to revoke VIP." });
    } finally {
      setBusy(false);
    }
  };

  // Submit Grant VIP
  const handleGrantVip = async () => {
    const id = Number.parseInt(grantTargetId, 10);
    if (!Number.isFinite(id) || id < 1) {
      setMessage({ ok: false, text: "Please enter or select a valid online Player ID." });
      return;
    }

    setBusy(true);
    setMessage(null);

    try {
      const res = await fetchNui<{ ok?: boolean; error?: string }>("cfx-keydi-vip:staffSet", {
        targetId: id,
        tier: grantTier,
        amount: grantDays,
        unit: "days",
        autoRenew: grantAutoRenew,
        keepExpiry: false,
      });

      if (!res?.ok) {
        setMessage({ ok: false, text: res?.error || "Failed to grant VIP." });
        return;
      }

      setMessage({ ok: true, text: `Granted ${grantTier.toUpperCase()} to ID ${id} for ${grantDays} days.` });
      setGrantTargetId("");
      setGrantPlayerName("");
      loadData();
      onOwnStatusChanged();
    } catch {
      setMessage({ ok: false, text: "Could not grant VIP." });
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="flex h-full flex-col overflow-hidden">
      {/* Subtabs Bar */}
      <div className="mb-3 flex items-center justify-between gap-3 border-b border-white/10 pb-3">
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => {
              setSubTab("database");
              setMessage(null);
            }}
            className={cn(
              "flex cursor-pointer items-center gap-2 rounded-xl border px-3 py-1.5 text-xs font-black uppercase tracking-wider transition",
              subTab === "database"
                ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white shadow-lg shadow-[#ff3a3a]/20"
                : "border-white/10 bg-black/40 text-[#a08890] hover:border-white/20 hover:text-white"
            )}
          >
            <Users className="h-3.5 w-3.5 text-[#ff4d4d]" />
            Existing VIPs ({dbMembers.length})
          </button>
          <button
            type="button"
            onClick={() => {
              setSubTab("grant");
              setMessage(null);
            }}
            className={cn(
              "flex cursor-pointer items-center gap-2 rounded-xl border px-3 py-1.5 text-xs font-black uppercase tracking-wider transition",
              subTab === "grant"
                ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white shadow-lg shadow-[#ff3a3a]/20"
                : "border-white/10 bg-black/40 text-[#a08890] hover:border-white/20 hover:text-white"
            )}
          >
            <UserPlus className="h-3.5 w-3.5 text-[#ff4d4d]" />
            Grant VIP
          </button>
        </div>

        <button
          type="button"
          onClick={loadData}
          disabled={loading || busy}
          className="flex cursor-pointer items-center gap-1.5 rounded-lg border border-white/10 bg-black/40 px-2.5 py-1 text-[10px] font-black uppercase tracking-wider text-white transition hover:border-white/30"
        >
          <RefreshCw className={cn("h-3 w-3", loading && "animate-spin")} />
          Refresh
        </button>
      </div>

      {/* Search Bar */}
      <div className="mb-3 flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[#a08890]" />
          <input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={
              subTab === "database"
                ? "Search existing VIP by player name, identifier, or tier..."
                : "Search online players by name or ID..."
            }
            className="w-full rounded-xl border border-white/10 bg-black/40 py-2 pl-9 pr-3 text-xs text-white outline-none placeholder:text-[#6d5a62] focus:border-[#ff3a3a]/60"
          />
        </div>
      </div>

      {message && (
        <div
          className={cn(
            "mb-3 flex items-center gap-2 rounded-xl border px-3 py-2 text-xs font-bold",
            message.ok
              ? "border-emerald-500/40 bg-emerald-500/15 text-emerald-300"
              : "border-red-500/40 bg-red-500/15 text-red-300"
          )}
        >
          {message.ok ? <ShieldCheck className="h-4 w-4 shrink-0" /> : <AlertTriangle className="h-4 w-4 shrink-0" />}
          {message.text}
        </div>
      )}

      {/* Main Content Area */}
      <div className="flex-1 overflow-y-auto pr-1 custom-scrollbar">
        {subTab === "database" ? (
          // ================= DATABASE MEMBERS LIST =================
          loading ? (
            <div className="flex h-40 items-center justify-center text-xs text-[#a08890]">
              <RefreshCw className="mr-2 h-4 w-4 animate-spin text-[#ff4d4d]" /> Loading VIP database records...
            </div>
          ) : filteredDbMembers.length === 0 ? (
            <div className="rounded-xl border border-white/10 bg-[#140f13] p-8 text-center">
              <Users className="mx-auto mb-2 h-8 w-8 text-[#6d5a62]" />
              <p className="text-sm font-black uppercase tracking-wider text-white">No VIP Members Found</p>
              <p className="mt-1 text-xs text-[#a08890]">
                {searchQuery ? "No members matched your search." : "There are currently no VIP records in the database."}
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {filteredDbMembers.map((m) => (
                <div
                  key={m.identifier}
                  className="flex flex-col gap-2 rounded-xl border border-white/10 bg-[#161014] p-3.5 transition hover:border-white/20 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div className="flex items-start gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-[#ff3a3a]/40 bg-[#ff3a3a]/15 text-[#ff4d4d]">
                      <Crown className="h-5 w-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-black text-white">{m.name}</span>
                        {m.isOnline ? (
                          <span className="rounded bg-emerald-500/20 px-1.5 py-0.5 text-[9px] font-black uppercase text-emerald-400">
                            Online · ID #{m.onlineId}
                          </span>
                        ) : (
                          <span className="rounded bg-white/5 px-1.5 py-0.5 text-[9px] font-bold uppercase text-[#a08890]">
                            Offline
                          </span>
                        )}
                      </div>
                      <p className="mt-0.5 font-mono text-[10px] text-[#88707a] truncate max-w-[280px]">
                        {m.identifier}
                      </p>
                      <div className="mt-1 flex flex-wrap items-center gap-2 text-[10px] text-[#a08890]">
                        <span className="font-bold text-[#ff8080]">{m.label}</span>
                        <span>·</span>
                        <span className="flex items-center gap-1">
                          <CalendarClock className="h-3 w-3 text-[#ff4d4d]" />
                          Expires {formatDate(m.expiresAt)}
                        </span>
                        {m.autoRenew && (
                          <>
                            <span>·</span>
                            <span className="text-emerald-400">Auto-Renew ON</span>
                          </>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 self-end sm:self-center">
                    <span
                      className={cn(
                        "rounded-lg border px-2 py-1 text-[9.5px] font-black uppercase tracking-wider",
                        m.daysRemaining <= 3
                          ? "border-red-500/50 bg-red-500/15 text-red-300"
                          : m.daysRemaining <= 7
                            ? "border-amber-500/50 bg-amber-500/15 text-amber-300"
                            : "border-emerald-500/40 bg-emerald-500/15 text-emerald-400"
                      )}
                    >
                      {m.daysRemaining <= 0
                        ? m.hoursRemaining > 0
                          ? `${m.hoursRemaining}h left`
                          : "Expired"
                        : `${m.daysRemaining}d left`}
                    </span>
                    <button
                      type="button"
                      onClick={() => openEditModal(m)}
                      className="flex cursor-pointer items-center gap-1 rounded-lg border border-[#ff3a3a]/40 bg-[#ff3a3a]/15 px-2.5 py-1 text-[10px] font-black uppercase tracking-wider text-white transition hover:border-[#ff3a3a] hover:bg-[#ff3a3a]/30"
                    >
                      <Pencil className="h-3 w-3" /> Edit
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => handleRevoke(m.identifier, m.name)}
                      className="flex cursor-pointer items-center gap-1 rounded-lg border border-red-500/40 bg-red-500/10 px-2.5 py-1 text-[10px] font-black uppercase tracking-wider text-red-300 transition hover:border-red-500 hover:bg-red-500/20"
                    >
                      <Ban className="h-3 w-3" /> Revoke
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )
        ) : (
          // ================= GRANT VIP FORM & ONLINE PLAYERS =================
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            {/* Online Players Roster Picker */}
            <div className="rounded-xl border border-white/10 bg-[#161014] p-4">
              <div className="mb-2 flex items-center justify-between">
                <span className="text-[10px] font-black uppercase tracking-wider text-[#ff4d4d]">
                  Select Online Player
                </span>
                <span className="text-[10px] text-[#a08890]">{onlinePlayers.length} online</span>
              </div>
              <div className="max-h-[260px] overflow-y-auto space-y-1 pr-1 custom-scrollbar">
                {filteredOnlinePlayers.length === 0 ? (
                  <p className="py-6 text-center text-xs text-[#a08890]">No players found.</p>
                ) : (
                  filteredOnlinePlayers.map((p) => {
                    const isSelected = grantTargetId === String(p.id);
                    return (
                      <button
                        key={p.id}
                        type="button"
                        onClick={() => {
                          setGrantTargetId(String(p.id));
                          setGrantPlayerName(p.name);
                        }}
                        className={cn(
                          "flex w-full cursor-pointer items-center justify-between rounded-lg border px-3 py-2 text-left transition",
                          isSelected
                            ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white"
                            : "border-white/5 bg-black/20 text-[#a08890] hover:border-white/15 hover:text-white"
                        )}
                      >
                        <div className="flex items-center gap-2 truncate">
                          <span className="font-mono text-xs font-bold text-[#ff4d4d]">#{p.id}</span>
                          <span className="truncate text-xs font-semibold text-white">{p.name}</span>
                        </div>
                        <span
                          className={cn(
                            "shrink-0 rounded px-1.5 py-0.5 text-[9px] font-black uppercase",
                            p.vip?.active ? "bg-[#ff3a3a]/20 text-[#ff8080]" : "bg-white/5 text-[#6d5a62]"
                          )}
                        >
                          {p.vip?.active ? p.vip.label : "No VIP"}
                        </span>
                      </button>
                    );
                  })
                )}
              </div>
            </div>

            {/* Grant Details Form */}
            <div className="rounded-xl border border-[#ff3a3a]/30 bg-[#161014] p-4">
              <span className="mb-3 block text-[10px] font-black uppercase tracking-wider text-[#ff4d4d]">
                VIP Configuration
              </span>

              {/* Target ID input */}
              <div className="mb-3">
                <label className="mb-1 block text-[9.5px] font-bold uppercase tracking-wider text-[#a08890]">
                  Target Player ID {grantPlayerName && `(${grantPlayerName})`}
                </label>
                <input
                  type="number"
                  placeholder="Enter server player ID (e.g. 1)"
                  value={grantTargetId}
                  onChange={(e) => {
                    setGrantTargetId(e.target.value);
                    setGrantPlayerName("");
                  }}
                  className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-1.5 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                />
              </div>

              {/* Tier Selection */}
              <div className="mb-3">
                <label className="mb-1 block text-[9.5px] font-bold uppercase tracking-wider text-[#a08890]">
                  VIP Tier
                </label>
                <div className="grid grid-cols-3 gap-1.5">
                  {tiers.map((t) => (
                    <button
                      key={t.id}
                      type="button"
                      onClick={() => setGrantTier(t.id)}
                      className={cn(
                        "flex cursor-pointer flex-col items-center rounded-lg border py-1.5 transition",
                        grantTier === t.id
                          ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white"
                          : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20 hover:text-white"
                      )}
                    >
                      <span className="text-[11px] font-black uppercase">{t.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Duration Presets */}
              <div className="mb-3">
                <label className="mb-1 block text-[9.5px] font-bold uppercase tracking-wider text-[#a08890]">
                  Duration ({grantDays} Days)
                </label>
                <div className="flex flex-wrap gap-1 mb-2">
                  {DURATION_PRESETS.map((p) => (
                    <button
                      key={p.days}
                      type="button"
                      onClick={() => setGrantDays(p.days)}
                      className={cn(
                        "cursor-pointer rounded-md border px-2 py-1 text-[9.5px] font-black uppercase transition",
                        grantDays === p.days
                          ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white"
                          : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20"
                      )}
                    >
                      {p.label}
                    </button>
                  ))}
                </div>
                <input
                  type="number"
                  min={1}
                  max={3650}
                  value={grantDays}
                  onChange={(e) => setGrantDays(Math.max(1, Number(e.target.value) || 1))}
                  placeholder="Custom days"
                  className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-1.5 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                />
              </div>

              {/* Preview Expiry */}
              <div className="mb-3 flex items-center justify-between rounded-lg border border-white/5 bg-black/30 px-3 py-2 text-xs">
                <span className="text-[#a08890]">Expiration Preview:</span>
                <span className="font-bold text-white">{formatDate(computeExpiryPreview(grantDays))}</span>
              </div>

              {/* Auto Renew Toggle */}
              <label className="mb-4 flex cursor-pointer items-center gap-2 text-xs text-white/85">
                <input
                  type="checkbox"
                  checked={grantAutoRenew}
                  onChange={(e) => setGrantAutoRenew(e.target.checked)}
                  className="accent-[#ff3a3a]"
                />
                Auto-Renew Enabled
              </label>

              {/* Grant Button */}
              <button
                type="button"
                disabled={busy || !grantTargetId}
                onClick={handleGrantVip}
                className="w-full cursor-pointer rounded-xl border border-[#ff3a3a] bg-[#ff3a3a] py-2 text-xs font-black uppercase tracking-wider text-white transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-40"
              >
                Grant VIP Membership
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ================= EDIT MODAL ================= */}
      {editingMember && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4 animate-fade-in">
          <div className="w-full max-w-md rounded-2xl border-2 border-[#ff3a3a] bg-[#120c10] p-5 shadow-2xl">
            <div className="mb-4 flex items-center justify-between border-b border-[#ff3a3a]/30 pb-3">
              <div className="flex items-center gap-2">
                <Crown className="h-5 w-5 text-[#ff4d4d]" />
                <h3 className="text-base font-black text-white">Edit VIP · {editingMember.name}</h3>
              </div>
              <button
                type="button"
                onClick={() => setEditingMember(null)}
                className="cursor-pointer rounded-lg p-1 text-[#a08890] transition hover:bg-white/10 hover:text-white"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="space-y-3.5">
              {/* Tier Selection */}
              <div>
                <label className="mb-1 block text-[9.5px] font-bold uppercase tracking-wider text-[#a08890]">
                  Select Tier
                </label>
                <div className="grid grid-cols-3 gap-1.5">
                  {tiers.map((t) => (
                    <button
                      key={t.id}
                      type="button"
                      onClick={() => setEditTier(t.id)}
                      className={cn(
                        "flex cursor-pointer flex-col items-center rounded-lg border py-1.5 transition",
                        editTier === t.id
                          ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white"
                          : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20 hover:text-white"
                      )}
                    >
                      <span className="text-[11px] font-black uppercase">{t.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Expiration Mode Selector */}
              <div>
                <label className="mb-1 block text-[9.5px] font-bold uppercase tracking-wider text-[#a08890]">
                  Expiration Setting
                </label>
                <div className="grid grid-cols-3 gap-1.5">
                  <button
                    type="button"
                    onClick={() => setEditMode("keep")}
                    className={cn(
                      "cursor-pointer rounded-lg border py-1.5 text-[10px] font-black uppercase tracking-wider transition",
                      editMode === "keep"
                        ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white"
                        : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20"
                    )}
                  >
                    Keep Current
                  </button>
                  <button
                    type="button"
                    onClick={() => setEditMode("add")}
                    className={cn(
                      "cursor-pointer rounded-lg border py-1.5 text-[10px] font-black uppercase tracking-wider transition",
                      editMode === "add"
                        ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white"
                        : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20"
                    )}
                  >
                    Add Days
                  </button>
                  <button
                    type="button"
                    onClick={() => setEditMode("custom")}
                    className={cn(
                      "cursor-pointer rounded-lg border py-1.5 text-[10px] font-black uppercase tracking-wider transition",
                      editMode === "custom"
                        ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white"
                        : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20"
                    )}
                  >
                    Custom Date
                  </button>
                </div>
              </div>

              {/* Expiry Details Based on Mode */}
              {editMode === "keep" && (
                <div className="rounded-lg border border-white/5 bg-black/30 p-2.5 text-xs text-[#a08890]">
                  Current expiry preserved: <span className="font-bold text-white">{formatDate(editingMember.expiresAt)}</span>
                </div>
              )}

              {editMode === "add" && (
                <div>
                  <div className="flex flex-wrap gap-1 mb-2">
                    {[7, 15, 30, 60, 90, 180, 365].map((d) => (
                      <button
                        key={d}
                        type="button"
                        onClick={() => setEditAddDays(d)}
                        className={cn(
                          "cursor-pointer rounded border px-2 py-0.5 text-[9px] font-black uppercase",
                          editAddDays === d
                            ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white"
                            : "border-white/10 text-[#a08890]"
                        )}
                      >
                        +{d}d
                      </button>
                    ))}
                  </div>
                  <input
                    type="number"
                    min={1}
                    value={editAddDays}
                    onChange={(e) => setEditAddDays(Number(e.target.value) || 1)}
                    placeholder="Days to add"
                    className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-1.5 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                  />
                </div>
              )}

              {editMode === "custom" && (
                <div>
                  <label className="mb-1 block text-[9.5px] text-[#a08890]">
                    Select specific date & time:
                  </label>
                  <input
                    type="datetime-local"
                    value={editCustomDate}
                    onChange={(e) => setEditCustomDate(e.target.value)}
                    className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-1.5 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                  />
                </div>
              )}

              {/* Auto Renew Toggle */}
              <label className="flex cursor-pointer items-center gap-2 text-xs text-white/85">
                <input
                  type="checkbox"
                  checked={editAutoRenew}
                  onChange={(e) => setEditAutoRenew(e.target.checked)}
                  className="accent-[#ff3a3a]"
                />
                Auto-Renew Enabled
              </label>

              {/* Buttons */}
              <div className="flex items-center justify-end gap-2 border-t border-white/10 pt-3">
                <button
                  type="button"
                  onClick={() => setEditingMember(null)}
                  className="cursor-pointer rounded-lg border border-white/10 bg-black/40 px-3 py-1.5 text-xs font-black uppercase text-[#a08890] transition hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={handleSaveEdit}
                  className="cursor-pointer rounded-lg border border-[#ff3a3a] bg-[#ff3a3a] px-4 py-1.5 text-xs font-black uppercase tracking-wider text-white transition hover:brightness-110 disabled:opacity-40"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
