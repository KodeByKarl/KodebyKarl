import { useEffect, useMemo, useState } from "react";
import {
  AlertTriangle,
  Ban,
  CalendarClock,
  CheckCircle2,
  Clock,
  Crown,
  Image,
  Pencil,
  PersonStanding,
  RefreshCw,
  Search,
  ShieldCheck,
  ShieldOff,
  UserPlus,
  Users,
  Wheat,
  X,
  Zap,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { fetchNui } from "@/lib/nui";
import grimLogo from "@/assets/grim-city-logo.png";
import {
  EMPTY_VIP,
  type DbVipMember,
  type VipMembership,
  type VipPlayerRow,
  type VipTierOption,
} from "./types";

interface VipStatusProps {
  onClose: () => void;
}

const ALL_TIERS_SHOWCASE = [
  {
    tier: "vip1",
    label: "VIP 1",
    subLabel: "Tier 1",
    slots: 1,
    pedMenu: false,
    banner: true,
    grindBonus: "+5",
    perks: [
      "+ 5 ALL GRINDINGS",
      "DISCORD ROLE",
      "WELCOME BANNER WITH AUDIO",
    ],
  },
  {
    tier: "vip2",
    label: "IMMORTAL",
    subLabel: "VIP 2",
    slots: 2,
    pedMenu: true,
    banner: true,
    grindBonus: "+10",
    perks: [
      "1 MONTH ACCESS /PED",
      "+ 10 ALL GRINDINGS",
      "WELCOME BANNER WITH AUDIO",
      "DISCORD ROLE",
      "VIP CAR  ( CARDEALER)",
    ],
  },
  {
    tier: "vip3",
    label: "SUPREME",
    subLabel: "VIP 3",
    slots: 3,
    pedMenu: true,
    banner: true,
    grindBonus: "+15",
    perks: [
      "1 MONTH ACCESS /PED",
      "+ 15 ALL GRINDINGS",
      "WELCOME BANNER WITH AUDIO",
      "1 EXCLUSIVE CAR  OWN SCRIPT",
      "DEATH CAM AUDIO/Banner",
      "1 FREE CLOTHES w/ 2 variant",
      "DISCORD ROLE",
    ],
  },
];

const DURATION_PRESETS: { label: string; days: number }[] = [
  { label: "7 Days", days: 7 },
  { label: "15 Days", days: 15 },
  { label: "30 Days", days: 30 },
  { label: "60 Days", days: 60 },
  { label: "90 Days", days: 90 },
  { label: "180 Days", days: 180 },
  { label: "365 Days", days: 365 },
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

function remainingLabel(days: number, hours: number) {
  if (days <= 0 && hours <= 0) return "Expired";
  if (days <= 0) return `${hours}h left`;
  if (days === 1) return hours > 0 ? `1 day ${hours}h left` : "1 day left";
  return hours > 0 ? `${days} days ${hours}h left` : `${days} days left`;
}

function computeExpiryPreview(days: number) {
  if (!Number.isFinite(days) || days < 1) return null;
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
}

export default function VipStatus({ onClose }: VipStatusProps) {
  const [activeTab, setActiveTab] = useState<"perks" | "members" | "grant">("perks");
  const [vip, setVip] = useState<VipMembership>(EMPTY_VIP);
  const [canManage, setCanManage] = useState(false);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  // Staff State
  const [dbMembers, setDbMembers] = useState<DbVipMember[]>([]);
  const [onlinePlayers, setOnlinePlayers] = useState<VipPlayerRow[]>([]);
  const [tiers, setTiers] = useState<VipTierOption[]>([]);
  const [searchQuery, setSearchQuery] = useState("");

  // Grant Form State
  const [grantTargetId, setGrantTargetId] = useState("");
  const [grantPlayerName, setGrantPlayerName] = useState("");
  const [grantTier, setGrantTier] = useState("vip3");
  const [grantDays, setGrantDays] = useState(30);
  const [grantAutoRenew, setGrantAutoRenew] = useState(false);

  // Edit Modal State
  const [editingMember, setEditingMember] = useState<DbVipMember | null>(null);
  const [editTier, setEditTier] = useState("vip3");
  const [editMode, setEditMode] = useState<"keep" | "add" | "custom">("keep");
  const [editAddDays, setEditAddDays] = useState(30);
  const [editCustomDate, setEditCustomDate] = useState("");
  const [editAutoRenew, setEditAutoRenew] = useState(false);

  // Keyboard Escape listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        if (editingMember) {
          setEditingMember(null);
        } else {
          onClose();
        }
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onClose, editingMember]);

  const loadAllData = () => {
    setLoading(true);
    setMessage(null);

    fetchNui<{ vip?: VipMembership; canManage?: boolean }>("cfx-keydi-vip:getStatus", {})
      .then((res) => {
        if (res?.vip) setVip(res.vip);
        else setVip(EMPTY_VIP);
        const hasStaff = !!res?.canManage;
        setCanManage(hasStaff);

        if (hasStaff) {
          Promise.all([
            fetchNui<{ ok?: boolean; members?: DbVipMember[]; tiers?: VipTierOption[] }>(
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
            .catch(() => undefined);
        }
      })
      .catch(() => {
        setVip(EMPTY_VIP);
        setCanManage(false);
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadAllData();
  }, []);

  const filteredMembers = useMemo(() => {
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

  // Save Edit
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
          setMessage({ ok: false, text: "Please select an expiration date." });
          setBusy(false);
          return;
        }
        payload.customExpires = editCustomDate.replace("T", " ") + (editCustomDate.length === 16 ? ":00" : "");
      }

      const res = await fetchNui<{ ok?: boolean; error?: string }>("cfx-keydi-vip:staffEditVip", payload);
      if (!res?.ok) {
        setMessage({ ok: false, text: res?.error || "Failed to update VIP." });
        return;
      }

      setMessage({ ok: true, text: `Successfully updated VIP for ${editingMember.name}` });
      setEditingMember(null);
      loadAllData();
    } catch {
      setMessage({ ok: false, text: "Failed to update VIP member." });
    } finally {
      setBusy(false);
    }
  };

  // Revoke Member
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
      if (editingMember?.identifier === identifier) setEditingMember(null);
      loadAllData();
    } catch {
      setMessage({ ok: false, text: "Failed to revoke VIP." });
    } finally {
      setBusy(false);
    }
  };

  // Grant VIP
  const handleGrantVip = async () => {
    const id = Number.parseInt(grantTargetId, 10);
    if (!Number.isFinite(id) || id < 1) {
      setMessage({ ok: false, text: "Please select or type a valid online Player ID." });
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

      setMessage({ ok: true, text: `Granted ${grantTier.toUpperCase()} to ID #${id} for ${grantDays} days.` });
      setGrantTargetId("");
      setGrantPlayerName("");
      loadAllData();
      setActiveTab("members");
    } catch {
      setMessage({ ok: false, text: "Failed to grant VIP." });
    } finally {
      setBusy(false);
    }
  };

  const urgency =
    !vip.active ? "none" : vip.daysRemaining <= 3 ? "critical" : vip.daysRemaining <= 7 ? "warn" : "ok";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/85 p-4 sm:p-6 select-none font-sans backdrop-blur-md animate-fade-in pointer-events-auto">
      {/* Spacious Full-Width Container (No 32% Sidebar!) */}
      <div className="relative flex flex-col w-full max-w-[1260px] h-[86vh] max-h-[880px] rounded-2xl border-2 border-[#ff3a3a] bg-[#0c080b] shadow-[0_0_50px_rgba(255,58,58,0.2)] overflow-hidden">
        {/* Top Header Bar */}
        <div className="flex shrink-0 items-center justify-between border-b border-[#ff3a3a]/40 bg-gradient-to-r from-[#180e14] via-[#120a0f] to-[#0c080b] px-6 py-4">
          {/* Logo & Branding */}
          <div className="flex items-center gap-3.5">
            <img src={grimLogo} alt="Grim City" className="h-10 w-auto object-contain drop-shadow" />
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black uppercase tracking-tight text-white">VIP Membership System</h1>
                <span className="rounded-md border border-[#ff3a3a]/60 bg-[#ff3a3a]/20 px-2 py-0.5 text-[9px] font-black uppercase tracking-widest text-[#ff4d4d]">
                  Grim City
                </span>
              </div>
              <p className="text-[11px] text-[#a08890]">
                Ped Menu · Welcome Banner · Autofarm Boost
              </p>
            </div>
          </div>

          {/* Clean Navigation Tabs */}
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => {
                setActiveTab("perks");
                setMessage(null);
              }}
              className={cn(
                "flex cursor-pointer items-center gap-2 rounded-xl border px-4 py-2 text-xs font-black uppercase tracking-wider transition",
                activeTab === "perks"
                  ? "border-[#ff3a3a] bg-[#ff3a3a] text-white shadow-lg shadow-[#ff3a3a]/30"
                  : "border-white/10 bg-black/40 text-[#a08890] hover:border-white/20 hover:text-white"
              )}
            >
              <Crown className="h-4 w-4" />
              Perks & Status
            </button>

            {canManage && (
              <>
                <button
                  type="button"
                  onClick={() => {
                    setActiveTab("members");
                    setMessage(null);
                  }}
                  className={cn(
                    "flex cursor-pointer items-center gap-2 rounded-xl border px-4 py-2 text-xs font-black uppercase tracking-wider transition",
                    activeTab === "members"
                      ? "border-[#ff3a3a] bg-[#ff3a3a] text-white shadow-lg shadow-[#ff3a3a]/30"
                      : "border-white/10 bg-black/40 text-[#a08890] hover:border-white/20 hover:text-white"
                  )}
                >
                  <Users className="h-4 w-4" />
                  All VIP Members ({dbMembers.length})
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setActiveTab("grant");
                    setMessage(null);
                  }}
                  className={cn(
                    "flex cursor-pointer items-center gap-2 rounded-xl border px-4 py-2 text-xs font-black uppercase tracking-wider transition",
                    activeTab === "grant"
                      ? "border-[#ff3a3a] bg-[#ff3a3a] text-white shadow-lg shadow-[#ff3a3a]/30"
                      : "border-white/10 bg-black/40 text-[#a08890] hover:border-white/20 hover:text-white"
                  )}
                >
                  <UserPlus className="h-4 w-4" />
                  Grant VIP
                </button>
              </>
            )}
          </div>

          {/* Right Action: Refresh & Close */}
          <div className="flex items-center gap-2.5">
            <button
              type="button"
              onClick={loadAllData}
              disabled={loading || busy}
              className="flex cursor-pointer items-center gap-1.5 rounded-xl border border-white/10 bg-black/40 px-3 py-1.5 text-[11px] font-black uppercase tracking-wider text-white transition hover:border-white/30"
            >
              <RefreshCw className={cn("h-3.5 w-3.5 text-[#ff4d4d]", loading && "animate-spin")} />
              Refresh
            </button>

            <button
              type="button"
              onClick={onClose}
              className="flex cursor-pointer items-center gap-1.5 rounded-xl border border-[#ff3a3a]/40 bg-[#ff3a3a]/15 px-3 py-1.5 text-[11px] font-black uppercase tracking-wider text-[#ff4d4d] transition hover:bg-[#ff3a3a] hover:text-white"
            >
              <X className="h-4 w-4" />
              Esc
            </button>
          </div>
        </div>

        {/* Status Notification Alert */}
        {message && (
          <div
            className={cn(
              "mx-6 mt-3 flex items-center justify-between rounded-xl border px-4 py-2.5 text-xs font-bold transition",
              message.ok
                ? "border-emerald-500/50 bg-emerald-500/15 text-emerald-300"
                : "border-red-500/50 bg-red-500/15 text-red-300"
            )}
          >
            <div className="flex items-center gap-2">
              {message.ok ? <ShieldCheck className="h-4 w-4 shrink-0" /> : <AlertTriangle className="h-4 w-4 shrink-0" />}
              <span>{message.text}</span>
            </div>
            <button
              type="button"
              onClick={() => setMessage(null)}
              className="cursor-pointer text-white/60 hover:text-white"
            >
              <X className="h-3.5 w-3.5" />
            </button>
          </div>
        )}

        {/* Main Spacious Content */}
        <div className="flex-1 overflow-hidden p-6">
          {activeTab === "perks" && (
            // ================= TAB 1: PERKS & CURRENT STATUS =================
            <div className="flex h-full flex-col justify-between overflow-y-auto pr-1 custom-scrollbar">
              {/* Active Plan Horizontal Card */}
              {loading ? (
                <div className="flex h-32 items-center justify-center text-xs text-[#a08890]">
                  <RefreshCw className="mr-2 h-4 w-4 animate-spin text-[#ff4d4d]" /> Loading membership profile...
                </div>
              ) : !vip.active ? (
                <div className="mb-4 flex items-center justify-between rounded-2xl border border-white/10 bg-[#140d12] p-4">
                  <div className="flex items-center gap-4">
                    <div className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-[#6d5a62]">
                      <ShieldOff className="h-6 w-6" />
                    </div>
                    <div>
                      <span className="text-[10px] font-black uppercase tracking-[0.2em] text-[#a08890]">Account Status</span>
                      <h2 className="text-xl font-black text-white">No Active VIP Membership</h2>
                      <p className="text-xs text-[#a08890]">
                        Unlock full ped customization and farm bonuses below.
                      </p>
                    </div>
                  </div>
                  <span className="rounded-xl border border-white/10 bg-black/40 px-3.5 py-1.5 text-xs font-black uppercase text-[#a08890]">
                    Standard Account
                  </span>
                </div>
              ) : (
                <div
                  className={cn(
                    "mb-4 rounded-2xl border p-4.5 bg-gradient-to-r from-[#1b1016] via-[#140d12] to-[#100a0e] shadow-xl",
                    urgency === "critical"
                      ? "border-red-500/50"
                      : urgency === "warn"
                        ? "border-amber-500/40"
                        : "border-[#ff3a3a]/50"
                  )}
                >
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex items-center gap-4">
                      <div className="flex h-14 w-14 items-center justify-center rounded-2xl border border-[#ff3a3a] bg-[#ff3a3a]/25 text-[#ff4d4d] shadow-lg shadow-[#ff3a3a]/20">
                        <Crown className="h-8 w-8" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="text-[10px] font-black uppercase tracking-[0.2em] text-[#ff8080]">
                            Active VIP
                          </span>
                          <span className="rounded bg-[#ff3a3a]/20 px-2 py-0.5 text-[10px] font-black uppercase text-white">
                            {vip.tier.toUpperCase()}
                          </span>
                        </div>
                        <h2 className="text-2xl font-black uppercase tracking-tight text-white">{vip.label}</h2>
                        <p className="text-xs text-[#a08890]">
                          {vip.autoRenew ? "Auto-renew is active" : "Non-renewing plan"} · Synced across all server systems
                        </p>
                      </div>
                    </div>

                    <div className="flex flex-wrap items-center gap-3">
                      <div className="rounded-xl border border-white/10 bg-black/40 px-4 py-2 text-right">
                        <div className="flex items-center justify-end gap-1.5 text-[10px] font-bold uppercase tracking-wider text-[#a08890]">
                          <CalendarClock className="h-3.5 w-3.5 text-[#ff4d4d]" />
                          Expires On
                        </div>
                        <p className="text-sm font-black text-white">{formatDate(vip.expiresAt)}</p>
                      </div>

                      <div
                        className={cn(
                          "rounded-xl border px-4 py-2.5 text-center font-black uppercase tracking-wider",
                          urgency === "critical"
                            ? "border-red-500 bg-red-500/20 text-red-200"
                            : urgency === "warn"
                              ? "border-amber-500/50 bg-amber-500/20 text-amber-200"
                              : "border-emerald-500/40 bg-emerald-500/20 text-emerald-300"
                        )}
                      >
                        <span className="block text-[9px] opacity-75">Remaining Time</span>
                        <span className="text-sm">{remainingLabel(vip.daysRemaining, vip.hoursRemaining)}</span>
                      </div>
                    </div>
                  </div>

                  {/* Feature Quick Launchers */}
                  <div className="mt-4 grid grid-cols-2 gap-2.5 sm:grid-cols-4 border-t border-white/10 pt-3">
                    <div className="rounded-xl border border-white/10 bg-black/30 px-3.5 py-2">
                      <span className="text-[9px] font-bold uppercase tracking-wider text-[#a08890]">Reskin</span>
                      <p className="text-xs font-black text-white">{vip.pedMenu ? '/reskin look' : 'VIP 2+'}</p>
                    </div>

                    <div className="rounded-xl border border-white/10 bg-black/30 px-3.5 py-2">
                      <span className="text-[9px] font-bold uppercase tracking-wider text-[#a08890]">All Grindings</span>
                      <p className="text-xs font-black text-emerald-400">
                        +{vip.grindBonus || (vip.tier === "vip3" ? 15 : vip.tier === "vip2" ? 10 : vip.tier === "vip1" ? 5 : 0)} Bonus Yield
                      </p>
                    </div>

                    <button
                      type="button"
                      disabled={!vip.pedMenu}
                      onClick={() => fetchNui("cfx-keydi-vip:openPedMenu", {})}
                      className={cn(
                        "flex flex-col rounded-xl border px-3.5 py-2 text-left transition",
                        vip.pedMenu
                          ? "cursor-pointer border-[#ff3a3a]/40 bg-black/30 hover:border-[#ff3a3a] hover:bg-[#ff3a3a]/15"
                          : "border-white/5 bg-black/20 opacity-40 cursor-not-allowed"
                      )}
                    >
                      <span className="text-[9px] font-bold uppercase tracking-wider text-[#a08890]">1 Month /ped</span>
                      <p className="text-xs font-black text-white">{vip.pedMenu ? "Open /pedmenu" : "IMMORTAL+ Req"}</p>
                    </button>

                    <button
                      type="button"
                      disabled={!vip.welcomeBanner}
                      onClick={() => fetchNui("cfx-keydi-vip:openWelcomeBanner", {})}
                      className={cn(
                        "flex flex-col rounded-xl border px-3.5 py-2 text-left transition",
                        vip.welcomeBanner
                          ? "cursor-pointer border-[#ff3a3a]/40 bg-black/30 hover:border-[#ff3a3a] hover:bg-[#ff3a3a]/15"
                          : "border-white/5 bg-black/20 opacity-40 cursor-not-allowed"
                      )}
                    >
                      <span className="text-[9px] font-bold uppercase tracking-wider text-[#a08890]">Banner + Audio</span>
                      <p className="text-xs font-black text-white">{vip.welcomeBanner ? "Edit /wcb" : "Not Included"}</p>
                    </button>
                  </div>
                </div>
              )}

              {/* 3-Column Side-By-Side Tiers Showcase (Spacious & Zero Scrolling!) */}
              <div>
                <div className="mb-3 flex items-center justify-between">
                  <span className="text-[11px] font-black uppercase tracking-[0.2em] text-[#ff4d4d]">
                    Grim City VIP Tiers
                  </span>
                  <span className="text-xs text-[#a08890]">Server membership privileges & perks</span>
                </div>

                <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
                  {ALL_TIERS_SHOWCASE.map((t) => {
                    const isCurrent = vip.active && vip.tier === t.tier;
                    return (
                      <div
                        key={t.tier}
                        className={cn(
                          "flex flex-col justify-between rounded-2xl border p-5 transition shadow-lg",
                          isCurrent
                            ? "border-[#ff3a3a] bg-gradient-to-b from-[#ff3a3a]/20 to-[#140d12] shadow-[#ff3a3a]/20"
                            : "border-white/10 bg-[#120a0f] hover:border-[#ff3a3a]/40"
                        )}
                      >
                        <div>
                          <div className="mb-3 flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              <h3 className="text-base font-black uppercase tracking-wide text-white">{t.label}</h3>
                              <span className="rounded bg-white/10 px-2 py-0.5 text-[9px] font-black uppercase text-[#a08890]">
                                {t.subLabel}
                              </span>
                            </div>
                            {isCurrent && (
                              <span className="rounded bg-[#ff3a3a] px-2 py-0.5 text-[9px] font-black uppercase tracking-wider text-white shadow">
                                Current
                              </span>
                            )}
                          </div>

                          <div className="mb-4 flex flex-wrap gap-2">
                            <span className="rounded-lg border border-[#ff3a3a]/40 bg-black/40 px-2.5 py-1 text-[10px] font-bold text-[#ff8080]">
                              {t.slots} Character Slots
                            </span>
                            <span className="rounded-lg border border-emerald-500/40 bg-emerald-500/15 px-2.5 py-1 text-[10px] font-bold text-emerald-300">
                              {t.grindBonus} Grindings
                            </span>
                          </div>

                          <ul className="space-y-2 border-t border-white/10 pt-3">
                            {t.perks.map((p) => (
                              <li key={p} className="flex items-start gap-2 text-xs font-semibold text-[#d0c0c6]">
                                <CheckCircle2 className="h-4 w-4 shrink-0 text-[#ff4d4d] mt-0.5" />
                                <span>{p}</span>
                              </li>
                            ))}
                          </ul>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {activeTab === "members" && canManage && (
            // ================= TAB 2: DATABASE MEMBERS (FULL WIDTH TABLE) =================
            <div className="flex h-full flex-col">
              {/* Search & Stats Bar */}
              <div className="mb-3 flex items-center justify-between gap-4">
                <div className="relative flex-1 max-w-md">
                  <Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-[#a08890]" />
                  <input
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search existing VIP by name, identifier, or tier..."
                    className="w-full rounded-xl border border-white/10 bg-black/40 py-2 pl-10 pr-3.5 text-xs text-white outline-none focus:border-[#ff3a3a]/70"
                  />
                </div>

                <div className="flex items-center gap-2 text-xs text-[#a08890]">
                  <span>Total VIPs:</span>
                  <span className="rounded-lg bg-[#ff3a3a]/20 px-2 py-0.5 font-bold text-[#ff4d4d]">
                    {dbMembers.length}
                  </span>
                </div>
              </div>

              {/* Members List Table */}
              <div className="flex-1 overflow-y-auto rounded-xl border border-white/10 bg-[#120a0f] custom-scrollbar">
                {loading ? (
                  <div className="flex h-40 items-center justify-center text-xs text-[#a08890]">
                    <RefreshCw className="mr-2 h-4 w-4 animate-spin text-[#ff4d4d]" /> Loading database VIP records...
                  </div>
                ) : filteredMembers.length === 0 ? (
                  <div className="flex h-40 flex-col items-center justify-center text-center p-6">
                    <Users className="mb-2 h-8 w-8 text-[#6d5a62]" />
                    <p className="text-sm font-black uppercase tracking-wider text-white">No VIP Members Found</p>
                    <p className="mt-1 text-xs text-[#a08890]">
                      {searchQuery ? "No members matched your search filter." : "There are currently no VIP records in the database."}
                    </p>
                  </div>
                ) : (
                  <table className="w-full text-left text-xs">
                    <thead className="sticky top-0 bg-[#180e14] border-b border-white/10 text-[10px] font-black uppercase tracking-wider text-[#a08890]">
                      <tr>
                        <th className="py-2.5 px-4">Player / Name</th>
                        <th className="py-2.5 px-3">Status</th>
                        <th className="py-2.5 px-3">Tier & Slots</th>
                        <th className="py-2.5 px-4">Expiration Date</th>
                        <th className="py-2.5 px-3">Remaining Time</th>
                        <th className="py-2.5 px-3">Auto-Renew</th>
                        <th className="py-2.5 px-4 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-white/5">
                      {filteredMembers.map((m) => (
                        <tr key={m.identifier} className="transition hover:bg-white/5">
                          <td className="py-2.5 px-4">
                            <span className="font-bold text-white block text-sm">{m.name}</span>
                            <span className="font-mono text-[10px] text-[#88707a] truncate block max-w-[220px]">
                              {m.identifier}
                            </span>
                          </td>
                          <td className="py-2.5 px-3">
                            {m.isOnline ? (
                              <span className="rounded bg-emerald-500/20 px-2 py-0.5 text-[9.5px] font-black uppercase text-emerald-400">
                                Online #{m.onlineId}
                              </span>
                            ) : (
                              <span className="rounded bg-white/5 px-2 py-0.5 text-[9.5px] font-bold uppercase text-[#a08890]">
                                Offline
                              </span>
                            )}
                          </td>
                          <td className="py-2.5 px-3">
                            <span className="rounded border border-[#ff3a3a]/40 bg-[#ff3a3a]/15 px-2 py-0.5 text-[10px] font-black uppercase text-[#ff8080]">
                              {m.label}
                            </span>
                          </td>
                          <td className="py-2.5 px-4 font-mono text-[11px] text-white/90">
                            {formatDate(m.expiresAt)}
                          </td>
                          <td className="py-2.5 px-3">
                            <span
                              className={cn(
                                "rounded px-2 py-0.5 text-[10px] font-black uppercase tracking-wider",
                                m.daysRemaining <= 3
                                  ? "bg-red-500/20 text-red-300"
                                  : m.daysRemaining <= 7
                                    ? "bg-amber-500/20 text-amber-300"
                                    : "bg-emerald-500/20 text-emerald-400"
                              )}
                            >
                              {m.daysRemaining <= 0
                                ? m.hoursRemaining > 0
                                  ? `${m.hoursRemaining}h left`
                                  : "Expired"
                                : `${m.daysRemaining}d left`}
                            </span>
                          </td>
                          <td className="py-2.5 px-3">
                            {m.autoRenew ? (
                              <span className="text-[10px] font-bold text-emerald-400">Enabled</span>
                            ) : (
                              <span className="text-[10px] text-[#6d5a62]">Disabled</span>
                            )}
                          </td>
                          <td className="py-2.5 px-4 text-right">
                            <div className="flex items-center justify-end gap-1.5">
                              <button
                                type="button"
                                onClick={() => openEditModal(m)}
                                className="flex cursor-pointer items-center gap-1 rounded-lg border border-[#ff3a3a]/40 bg-[#ff3a3a]/15 px-2.5 py-1 text-[10px] font-black uppercase tracking-wider text-white transition hover:bg-[#ff3a3a]"
                              >
                                <Pencil className="h-3 w-3" /> Edit
                              </button>
                              <button
                                type="button"
                                disabled={busy}
                                onClick={() => handleRevoke(m.identifier, m.name)}
                                className="flex cursor-pointer items-center gap-1 rounded-lg border border-red-500/40 bg-red-500/10 px-2.5 py-1 text-[10px] font-black uppercase tracking-wider text-red-300 transition hover:bg-red-500 hover:text-white"
                              >
                                <Ban className="h-3 w-3" /> Revoke
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          )}

          {activeTab === "grant" && canManage && (
            // ================= TAB 3: GRANT VIP =================
            <div className="grid h-full grid-cols-1 gap-6 lg:grid-cols-2 overflow-y-auto pr-1 custom-scrollbar">
              {/* Online Player Selection */}
              <div className="flex flex-col rounded-2xl border border-white/10 bg-[#120a0f] p-5">
                <div className="mb-3 flex items-center justify-between">
                  <div>
                    <h3 className="text-sm font-black uppercase tracking-wider text-white">Online Players</h3>
                    <p className="text-[10px] text-[#a08890]">Click any player to grant or modify their VIP</p>
                  </div>
                  <span className="rounded-lg bg-emerald-500/20 px-2 py-0.5 text-[10px] font-black uppercase text-emerald-400">
                    {onlinePlayers.length} Active
                  </span>
                </div>

                {/* Search */}
                <div className="relative mb-3">
                  <Search className="absolute left-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[#a08890]" />
                  <input
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search player name or server ID..."
                    className="w-full rounded-xl border border-white/10 bg-black/40 py-2 pl-9 pr-3 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                  />
                </div>

                <div className="flex-1 space-y-1.5 overflow-y-auto pr-1 custom-scrollbar max-h-[360px]">
                  {filteredOnlinePlayers.length === 0 ? (
                    <p className="py-10 text-center text-xs text-[#a08890]">No matching online players.</p>
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
                            "flex w-full cursor-pointer items-center justify-between rounded-xl border px-3.5 py-2.5 text-left transition",
                            isSelected
                              ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white shadow-md shadow-[#ff3a3a]/15"
                              : "border-white/5 bg-black/20 text-[#a08890] hover:border-white/20 hover:text-white"
                          )}
                        >
                          <div className="flex items-center gap-2.5 truncate">
                            <span className="font-mono text-xs font-bold text-[#ff4d4d]">#{p.id}</span>
                            <span className="truncate text-xs font-semibold text-white">{p.name}</span>
                          </div>
                          <span
                            className={cn(
                              "shrink-0 rounded px-2 py-0.5 text-[9.5px] font-black uppercase",
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

              {/* Grant Parameters Form */}
              <div className="flex flex-col justify-between rounded-2xl border border-[#ff3a3a]/40 bg-[#120a0f] p-5 shadow-xl">
                <div>
                  <div className="mb-4">
                    <h3 className="text-sm font-black uppercase tracking-wider text-white">VIP Configuration</h3>
                    <p className="text-[10px] text-[#a08890]">Set tier, duration, and auto-renew properties</p>
                  </div>

                  {/* Target Player ID */}
                  <div className="mb-3.5">
                    <label className="mb-1 block text-[10px] font-bold uppercase tracking-wider text-[#a08890]">
                      Target Player ID {grantPlayerName && `(${grantPlayerName})`}
                    </label>
                    <input
                      type="number"
                      placeholder="Select online player or enter server ID"
                      value={grantTargetId}
                      onChange={(e) => {
                        setGrantTargetId(e.target.value);
                        setGrantPlayerName("");
                      }}
                      className="w-full rounded-xl border border-white/10 bg-black/40 px-3.5 py-2 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                    />
                  </div>

                  {/* Tier Selection */}
                  <div className="mb-3.5">
                    <label className="mb-1.5 block text-[10px] font-bold uppercase tracking-wider text-[#a08890]">
                      Select VIP Tier
                    </label>
                    <div className="grid grid-cols-3 gap-2.5">
                      {tiers.map((t) => (
                        <button
                          key={t.id}
                          type="button"
                          onClick={() => setGrantTier(t.id)}
                          className={cn(
                            "flex cursor-pointer flex-col items-center rounded-xl border py-2 transition",
                            grantTier === t.id
                              ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white"
                              : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20 hover:text-white"
                          )}
                        >
                          <span className="text-xs font-black uppercase">{t.label}</span>
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Duration Presets */}
                  <div className="mb-3.5">
                    <label className="mb-1.5 block text-[10px] font-bold uppercase tracking-wider text-[#a08890]">
                      Duration ({grantDays} Days)
                    </label>
                    <div className="flex flex-wrap gap-1.5 mb-2">
                      {DURATION_PRESETS.map((p) => (
                        <button
                          key={p.days}
                          type="button"
                          onClick={() => setGrantDays(p.days)}
                          className={cn(
                            "cursor-pointer rounded-lg border px-3 py-1 text-[10px] font-black uppercase transition",
                            grantDays === p.days
                              ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white"
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
                      placeholder="Custom days amount"
                      className="w-full rounded-xl border border-white/10 bg-black/40 px-3.5 py-2 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                    />
                  </div>

                  {/* Live Expiration Preview */}
                  <div className="mb-3.5 flex items-center justify-between rounded-xl border border-white/5 bg-black/30 px-3.5 py-2.5 text-xs">
                    <span className="text-[#a08890]">Calculated Expiration:</span>
                    <span className="font-bold text-white font-mono">{formatDate(computeExpiryPreview(grantDays))}</span>
                  </div>

                  {/* Auto Renew Toggle */}
                  <label className="flex cursor-pointer items-center gap-2.5 text-xs text-white/85">
                    <input
                      type="checkbox"
                      checked={grantAutoRenew}
                      onChange={(e) => setGrantAutoRenew(e.target.checked)}
                      className="h-4 w-4 accent-[#ff3a3a]"
                    />
                    Enable Auto-Renewal Checkpoint
                  </label>
                </div>

                <button
                  type="button"
                  disabled={busy || !grantTargetId}
                  onClick={handleGrantVip}
                  className="mt-4 w-full cursor-pointer rounded-xl border border-[#ff3a3a] bg-[#ff3a3a] py-2.5 text-xs font-black uppercase tracking-wider text-white transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-40"
                >
                  Confirm & Grant VIP Membership
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Bottom Status Bar */}
        <div className="flex shrink-0 items-center justify-between border-t border-[#ff3a3a]/30 bg-[#0c080b] px-6 py-3 text-xs text-[#a08890]">
          <span>
            Press <strong className="text-white">Esc</strong> or type <strong className="text-white">/viperks</strong> to toggle this menu.
          </span>
          <span>
            Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
          </span>
        </div>
      </div>

      {/* ================= EDIT MODAL ================= */}
      {editingMember && (
        <div className="fixed inset-0 z-60 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 animate-fade-in">
          <div className="w-full max-w-lg rounded-2xl border-2 border-[#ff3a3a] bg-[#120a0f] p-6 shadow-2xl">
            <div className="mb-4 flex items-center justify-between border-b border-[#ff3a3a]/30 pb-3">
              <div className="flex items-center gap-2.5">
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

            <div className="space-y-4">
              {/* Tier Selection */}
              <div>
                <label className="mb-1.5 block text-[10px] font-bold uppercase tracking-wider text-[#a08890]">
                  Select Tier
                </label>
                <div className="grid grid-cols-3 gap-2.5">
                  {tiers.map((t) => (
                    <button
                      key={t.id}
                      type="button"
                      onClick={() => setEditTier(t.id)}
                      className={cn(
                        "flex cursor-pointer flex-col items-center rounded-xl border py-2 transition",
                        editTier === t.id
                          ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white"
                          : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20 hover:text-white"
                      )}
                    >
                      <span className="text-xs font-black uppercase">{t.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Expiration Mode Selector */}
              <div>
                <label className="mb-1.5 block text-[10px] font-bold uppercase tracking-wider text-[#a08890]">
                  Expiration Setting
                </label>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    type="button"
                    onClick={() => setEditMode("keep")}
                    className={cn(
                      "cursor-pointer rounded-xl border py-2 text-xs font-black uppercase tracking-wider transition",
                      editMode === "keep"
                        ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white"
                        : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20"
                    )}
                  >
                    Keep Expiry
                  </button>
                  <button
                    type="button"
                    onClick={() => setEditMode("add")}
                    className={cn(
                      "cursor-pointer rounded-xl border py-2 text-xs font-black uppercase tracking-wider transition",
                      editMode === "add"
                        ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white"
                        : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20"
                    )}
                  >
                    Add Days
                  </button>
                  <button
                    type="button"
                    onClick={() => setEditMode("custom")}
                    className={cn(
                      "cursor-pointer rounded-xl border py-2 text-xs font-black uppercase tracking-wider transition",
                      editMode === "custom"
                        ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white"
                        : "border-white/10 bg-black/30 text-[#a08890] hover:border-white/20"
                    )}
                  >
                    Custom Date
                  </button>
                </div>
              </div>

              {/* Expiry Details Based on Mode */}
              {editMode === "keep" && (
                <div className="rounded-xl border border-white/5 bg-black/30 p-3 text-xs text-[#a08890]">
                  Current expiration date preserved: <span className="font-bold text-white font-mono">{formatDate(editingMember.expiresAt)}</span>
                </div>
              )}

              {editMode === "add" && (
                <div>
                  <div className="flex flex-wrap gap-1.5 mb-2">
                    {[7, 15, 30, 60, 90, 180, 365].map((d) => (
                      <button
                        key={d}
                        type="button"
                        onClick={() => setEditAddDays(d)}
                        className={cn(
                          "cursor-pointer rounded-lg border px-2.5 py-1 text-[10px] font-black uppercase",
                          editAddDays === d
                            ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white"
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
                    className="w-full rounded-xl border border-white/10 bg-black/40 px-3.5 py-2 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                  />
                </div>
              )}

              {editMode === "custom" && (
                <div>
                  <label className="mb-1 block text-[10px] text-[#a08890]">
                    Select specific date & time:
                  </label>
                  <input
                    type="datetime-local"
                    value={editCustomDate}
                    onChange={(e) => setEditCustomDate(e.target.value)}
                    className="w-full rounded-xl border border-white/10 bg-black/40 px-3.5 py-2 text-xs text-white outline-none focus:border-[#ff3a3a]/60"
                  />
                </div>
              )}

              {/* Auto Renew Toggle */}
              <label className="flex cursor-pointer items-center gap-2.5 text-xs text-white/85">
                <input
                  type="checkbox"
                  checked={editAutoRenew}
                  onChange={(e) => setEditAutoRenew(e.target.checked)}
                  className="h-4 w-4 accent-[#ff3a3a]"
                />
                Auto-Renew Checkpoint Enabled
              </label>

              {/* Buttons */}
              <div className="flex items-center justify-end gap-2.5 border-t border-white/10 pt-4">
                <button
                  type="button"
                  onClick={() => setEditingMember(null)}
                  className="cursor-pointer rounded-xl border border-white/10 bg-black/40 px-4 py-2 text-xs font-black uppercase text-[#a08890] transition hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={handleSaveEdit}
                  className="cursor-pointer rounded-xl border border-[#ff3a3a] bg-[#ff3a3a] px-5 py-2 text-xs font-black uppercase tracking-wider text-white transition hover:brightness-110 disabled:opacity-40"
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
