import React, { useEffect, useState, useRef } from "react";
import { Bug, Shield, ShieldAlert, MessageSquareMore, X, Headphones, CircleHelp, Search, RefreshCw, Send, CheckCircle2, Clock } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import grimLogo from "@/assets/grim-city-logo.png";

export interface ReportCategory {
  id: string;
  label: string;
}

export interface ReportMessage {
  sender: "player" | "admin";
  name: string;
  text: string;
  time: number;
}

export interface OpenReport {
  category: string;
  title: string;
  description: string;
  createdAt?: number;
  updatedAt?: number;
  playerName?: string;
  playerSource?: number;
  messages?: ReportMessage[] | Record<string, ReportMessage>;
  messagesJson?: string;
  identifier?: string;
  playerIdentifier?: string;
  isOnline?: boolean;
}

interface ReportSystemProps {
  categories?: ReportCategory[];
  initialReport?: OpenReport | null;
  maxDescription?: number;
  maxTitle?: number;
  initialIsAdmin?: boolean;
  initialAllReports?: any[];
  initialAdminDuty?: boolean;
  isOpen?: boolean;
  onClose: () => void;
}

function normalizeMessages(raw?: OpenReport["messages"] | ReportMessage[] | null, messagesJson?: string): ReportMessage[] {
  if (typeof messagesJson === "string" && messagesJson.length > 0) {
    try {
      const parsed = JSON.parse(messagesJson);
      if (Array.isArray(parsed)) {
        return parsed.filter(Boolean);
      }
    } catch {
      /* fall through */
    }
  }
  if (!raw) return [];
  if (Array.isArray(raw)) return raw.filter(Boolean);
  if (typeof raw === "object") {
    return Object.keys(raw)
      .sort((a, b) => Number(a) - Number(b))
      .map((key) => raw[key])
      .filter(Boolean);
  }
  return [];
}

function withNormalizedMessages<T extends OpenReport | null>(report: T): T {
  if (!report) return report;
  return {
    ...report,
    messages: normalizeMessages(report.messages, report.messagesJson),
    messagesJson: undefined,
  };
}

const DEFAULT_CATEGORIES: ReportCategory[] = [
  { id: "bug", label: "Bug Reports" },
  { id: "rp", label: "RP Issues" },
  { id: "other", label: "Others" },
];

const PANEL_STYLE = {
  background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)",
  borderColor: "#ff3a3a",
  boxShadow: "0 25px 60px -15px rgba(0, 0, 0, 0.95)",
};

function getResourceName() {
  return (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : "cfx-keydi-ui";
}

function CategoryIcon({ id, selected }: { id: string; selected: boolean }) {
  const className = cn(
    "h-4 w-4 shrink-0 transition",
    selected ? "text-white" : "text-muted-foreground"
  );

  if (id === "bug") return <Bug className={className} strokeWidth={2} />;
  if (id === "rp") return <MessageSquareMore className={className} strokeWidth={2} />;
  return <CircleHelp className={className} strokeWidth={2} />;
}

function PanelHeader({
  icon,
  eyebrow,
  title,
  subtitle,
  onClose,
}: {
  icon: React.ReactNode;
  eyebrow: string;
  title: string;
  subtitle: string;
  onClose: () => void;
}) {
  return (
    <div
      className="flex items-start justify-between border-b pb-3"
      style={{ borderBottomColor: "rgba(255, 58, 58, 0.25)" }}
    >
      <div className="flex items-start gap-3 flex-1 min-w-0">
        <div className="flex h-8.5 w-8.5 shrink-0 items-center justify-center rounded-xl border bg-[#ff3a3a]/15 border-[#ff3a3a] text-white">
          {icon}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-[9px] font-black uppercase tracking-[0.25em] text-[#ff4d4d]">{eyebrow}</p>
          <h2 className="text-sm font-extrabold text-white mt-0.5 truncate">{title}</h2>
          <p className="text-[10px] text-[#a08890] mt-0.5 truncate">{subtitle}</p>
        </div>
      </div>
      <button
        onClick={onClose}
        className="flex items-center gap-1.5 px-2.5 py-1 rounded-md border border-[#ff3a3a]/30 text-white/80 hover:text-white hover:border-[#ff3a3a] bg-[#181216] text-[10px] font-semibold transition cursor-pointer shrink-0 ml-3"
      >
        <span>Esc</span>
        <X className="h-3 w-3 text-[#ff4d4d]" strokeWidth={2.5} />
      </button>
    </div>
  );
}

function PanelFooter() {
  return (
    <div className="flex items-center justify-between border-t pt-3 mt-auto" style={{ borderTopColor: "rgba(255, 58, 58, 0.25)" }}>
      <div className="flex items-center gap-2">
        <img src={grimLogo} alt="Grim City" className="h-4.5 w-4.5 object-contain" />
        <span className="text-[10px] font-extrabold tracking-[0.2em] text-[#ff4d4d]">
          GRIM CITY ROLEPLAY
        </span>
      </div>
      <span className="text-[9.5px] tracking-wider text-[#a08890]">
        Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
      </span>
    </div>
  );
}

function formatTime(timestamp?: number) {
  if (!timestamp) return "";
  const date = new Date(timestamp * 1000);
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

export default function ReportSystem({
  categories = DEFAULT_CATEGORIES,
  initialReport = null,
  maxDescription = 500,
  maxTitle = 80,
  initialIsAdmin = false,
  initialAllReports = [],
  initialAdminDuty = false,
  isOpen = true,
  onClose,
}: ReportSystemProps) {
  const [category, setCategory] = useState(initialReport?.category ?? "bug");
  const [title, setTitle] = useState(initialReport?.title ?? "");
  const [description, setDescription] = useState(initialReport?.description ?? "");
  const [savedReport, setSavedReport] = useState<OpenReport | null>(withNormalizedMessages(initialReport));
  const [formActive, setFormActive] = useState(!initialReport);
  const [submitting, setSubmitting] = useState(false);

  // Admin & Filter States
  const [isAdmin, setIsAdmin] = useState(initialIsAdmin);
  const [allReports, setAllReports] = useState<any[]>(initialAllReports.map((r) => withNormalizedMessages(r)));
  const [adminDuty, setAdminDuty] = useState(initialAdminDuty);
  const [activeTab, setActiveTab] = useState<"player" | "admin">("player");
  const [selectedAdminReport, setSelectedAdminReport] = useState<any | null>(null);
  const [chatMessage, setChatMessage] = useState("");
  const [searchFilter, setSearchFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");

  const chatContainerRef = useRef<HTMLDivElement>(null);

  // Scroll to bottom when messages update
  useEffect(() => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  }, [savedReport, selectedAdminReport, activeTab]);

  useEffect(() => {
    if (initialReport) {
      const report = withNormalizedMessages(initialReport);
      setCategory(report.category ?? "bug");
      setTitle(report.title ?? "");
      setDescription(report.description ?? "");
      setSavedReport(report);
      setFormActive(false);
    }
  }, [initialReport]);

  useEffect(() => {
    setIsAdmin(initialIsAdmin);
  }, [initialIsAdmin]);

  useEffect(() => {
    if (initialAllReports && initialAllReports.length > 0) {
      setAllReports(initialAllReports.map((r) => withNormalizedMessages(r)));
    }
  }, [initialAllReports]);

  useEffect(() => {
    setAdminDuty(initialAdminDuty);
  }, [initialAdminDuty]);

  // Handle NUI Message events from client Lua
  useEffect(() => {
    const handleNuiMessage = (event: MessageEvent) => {
      const data = event.data;
      if (!data) return;

      const action = data.action || data.type;

      if (action === "cfx-keydi-report:show") {
        if (data.isAdmin !== undefined) setIsAdmin(!!data.isAdmin);
        if (data.adminDutyStatus !== undefined) setAdminDuty(!!data.adminDutyStatus);
        if (data.allReports) {
          setAllReports((data.allReports || []).map((r: any) => withNormalizedMessages(r)));
        }
        if (data.openReport) {
          const norm = withNormalizedMessages(data.openReport);
          setSavedReport(norm);
          setFormActive(false);
        } else {
          setSavedReport(null);
          setFormActive(true);
        }
      } else if (action === "cfx-keydi-report:update" || action === "cfx-keydi-report:updateReport") {
        if (data.openReport) {
          const norm = withNormalizedMessages(data.openReport);
          setSavedReport(norm);
        }
      } else if (action === "cfx-keydi-report:reportClosed") {
        setSavedReport(null);
        setFormActive(true);
        toast.info("Report has been closed/resolved");
      } else if (action === "cfx-keydi-report:adminUpdateReport") {
        const { playerIdentifier, report } = data;
        const norm = withNormalizedMessages(report);
        setAllReports((prev) => {
          const idx = prev.findIndex((r) => (r.identifier || r.playerIdentifier) === playerIdentifier);
          if (idx !== -1) {
            const next = [...prev];
            next[idx] = norm;
            return next;
          }
          return [norm, ...prev];
        });
        if (selectedAdminReport && (selectedAdminReport.identifier || selectedAdminReport.playerIdentifier) === playerIdentifier) {
          setSelectedAdminReport(norm);
        }
      } else if (action === "cfx-keydi-report:adminRemoveReport") {
        const { playerIdentifier } = data;
        setAllReports((prev) => prev.filter((r) => (r.identifier || r.playerIdentifier) !== playerIdentifier));
        if (selectedAdminReport && (selectedAdminReport.identifier || selectedAdminReport.playerIdentifier) === playerIdentifier) {
          setSelectedAdminReport(null);
        }
      }
    };
    window.addEventListener("message", handleNuiMessage);
    return () => window.removeEventListener("message", handleNuiMessage);
  }, [selectedAdminReport]);

  const handleSubmit = async () => {
    if (!title.trim() || !description.trim()) {
      toast.error("Please fill in both title and description");
      return;
    }
    setSubmitting(true);
    const resourceName = getResourceName();
    try {
      fetch(`https://${resourceName}/cfx-keydi-report:submit`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({ category, title, description }),
      }).catch(() => {});

      toast.success("Report submitted successfully!");
      const newRep: OpenReport = {
        category,
        title,
        description,
        createdAt: Math.floor(Date.now() / 1000),
        messages: [],
      };
      setSavedReport(newRep);
      setFormActive(false);
    } catch {
      toast.error("Error communicating with server");
    } finally {
      setSubmitting(false);
    }
  };

  const handleSendMessage = (targetIdentifier: string) => {
    if (!chatMessage.trim()) return;
    const msgText = chatMessage.trim();
    setChatMessage("");
    const resourceName = getResourceName();

    fetch(`https://${resourceName}/cfx-keydi-report:sendMessage`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({
        playerIdentifier: targetIdentifier,
        messageText: msgText,
      }),
    }).catch(() => {});
  };

  const handleResolveReport = (targetIdentifier: string) => {
    const resourceName = getResourceName();
    fetch(`https://${resourceName}/cfx-keydi-report:resolveReport`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({ playerIdentifier: targetIdentifier }),
    }).catch(() => {});

    toast.success("Report resolved");
    if (activeTab === "admin") {
      setSelectedAdminReport(null);
    } else {
      setSavedReport(null);
      setFormActive(true);
    }
  };

  const handleToggleDuty = (newDutyState: boolean) => {
    const resourceName = getResourceName();
    fetch(`https://${resourceName}/cfx-keydi-report:toggleDuty`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({ status: newDutyState }),
    }).catch(() => {});

    setAdminDuty(newDutyState);
    toast.success(`Admin Duty set to ${newDutyState ? "ON" : "OFF"}`);
  };

  const activeReportObj = activeTab === "admin" ? selectedAdminReport : (formActive ? null : savedReport);

  const filteredReports = allReports.filter((rep) => {
    const matchesCategory = categoryFilter === "all" || rep.category === categoryFilter;
    const searchLower = searchFilter.toLowerCase().trim();
    const matchesSearch = !searchLower ||
      (rep.title && rep.title.toLowerCase().includes(searchLower)) ||
      (rep.playerName && rep.playerName.toLowerCase().includes(searchLower)) ||
      (rep.playerSource && String(rep.playerSource).includes(searchLower));
    return matchesCategory && matchesSearch;
  });

  return (
    <div
      className={cn(
        "pandora fixed inset-0 flex items-center justify-center p-8 bg-black/75 backdrop-blur-[6px] select-none pointer-events-auto animate-fade-in font-sans z-40",
        !isOpen && "hidden pointer-events-none"
      )}
      aria-hidden={!isOpen}
    >
      <div className="flex items-center justify-center gap-5 max-w-6xl w-full">
        
        {/* LEFT PANEL — Support Hub & Tickets Roster */}
        <section
          className="relative flex flex-col overflow-hidden rounded-2xl border-2 p-5 backdrop-blur-xl h-[580px] w-[350px] shrink-0"
          style={PANEL_STYLE}
        >
          <div className="panel-grid absolute inset-0 pointer-events-none opacity-40" />

          <div className="relative z-10 flex flex-col h-full">
            <PanelHeader
              icon={<Shield className="h-4 w-4 text-white" strokeWidth={2} />}
              eyebrow="SUPPORT DASHBOARD"
              title={activeTab === "admin" ? "Staff Control" : "Report Hub"}
              subtitle={activeTab === "admin" ? "Manage active player tickets" : "Track status or file a new issue"}
              onClose={onClose}
            />

            {/* Admin Switcher Tab */}
            {isAdmin && (
              <div className="grid grid-cols-2 gap-2 p-1 bg-[#0d0d12] border border-[#ff3a3a]/30 rounded-xl mt-3 shrink-0">
                <button
                  type="button"
                  onClick={() => {
                    setActiveTab("player");
                    setSelectedAdminReport(null);
                  }}
                  className={cn(
                    "py-1.5 text-[9.5px] font-black uppercase tracking-wider rounded-lg transition cursor-pointer text-center",
                    activeTab === "player"
                      ? "bg-[#ff3a3a] text-white"
                      : "text-[#a08890] hover:text-white"
                  )}
                >
                  Player Support
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setActiveTab("admin");
                  }}
                  className={cn(
                    "py-1.5 text-[9.5px] font-black uppercase tracking-wider rounded-lg transition cursor-pointer text-center",
                    activeTab === "admin"
                      ? "bg-[#ff3a3a] text-white"
                      : "text-[#a08890] hover:text-white"
                  )}
                >
                  Admin Panel
                </button>
              </div>
            )}

            {activeTab === "admin" ? (
              <div className="flex-1 flex flex-col justify-start py-3 min-h-0 w-full">
                {/* On-Duty / Off-Duty Toggle Box */}
                <div className="flex items-center justify-between p-3 rounded-xl bg-[#181216] border border-[#ff3a3a]/30 mb-3 shrink-0">
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-wider text-white">Duty Status</p>
                    <p className="text-[8.5px] text-[#a08890] mt-0.5">Toggle admin duty availability</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => handleToggleDuty(!adminDuty)}
                    className={cn(
                      "relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none",
                      adminDuty ? "bg-emerald-500" : "bg-zinc-700"
                    )}
                  >
                    <span
                      className={cn(
                        "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
                        adminDuty ? "translate-x-5" : "translate-x-0"
                      )}
                    />
                  </button>
                </div>

                {/* Filter & Search Bar */}
                <div className="flex flex-col gap-2 mb-3 shrink-0">
                  <div className="relative">
                    <Search className="absolute left-2.5 top-2.5 h-3.5 w-3.5 text-[#a08890]" />
                    <input
                      type="text"
                      value={searchFilter}
                      onChange={(e) => setSearchFilter(e.target.value)}
                      placeholder="Search player, ID or title..."
                      className="w-full pl-8 pr-3 py-1.5 bg-[#0d0d12] border border-[#ff3a3a]/30 rounded-lg text-xs text-white placeholder:text-[#a08890]/60 focus:outline-none focus:border-[#ff3a3a]"
                    />
                  </div>

                  {/* Category Chips */}
                  <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar">
                    {["all", "bug", "rp", "other"].map((catKey) => (
                      <button
                        key={catKey}
                        type="button"
                        onClick={() => setCategoryFilter(catKey)}
                        className={cn(
                          "px-2.5 py-1 rounded-md text-[8.5px] font-black uppercase tracking-wider border transition cursor-pointer shrink-0",
                          categoryFilter === catKey
                            ? "bg-[#ff3a3a] border-[#ff3a3a] text-white"
                            : "bg-[#181216] border-white/10 text-[#a08890] hover:text-white"
                        )}
                      >
                        {catKey}
                      </button>
                    ))}
                  </div>
                </div>

                <p className="text-[9px] font-black uppercase tracking-wider text-[#ff4d4d] mb-2 shrink-0">
                  Tickets ({filteredReports.length})
                </p>
                <div className="flex-1 overflow-y-auto custom-scrollbar pr-1 flex flex-col gap-2 min-h-0">
                  {filteredReports.length > 0 ? (
                    filteredReports.map((rep) => {
                      const repId = rep.identifier || rep.playerIdentifier;
                      const selected = selectedAdminReport && (selectedAdminReport.identifier || selectedAdminReport.playerIdentifier) === repId;
                      const msgs = normalizeMessages(rep.messages);
                      const hasReplies = msgs.length > 0;
                      return (
                        <button
                          key={repId}
                          type="button"
                          onClick={() => {
                            setSelectedAdminReport(rep);
                          }}
                          className={cn(
                            "flex items-center gap-3 p-3 rounded-xl border transition cursor-pointer text-left w-full",
                            selected
                              ? "border-[#ff3a3a] bg-[#ff3a3a]/15"
                              : "border-white/5 bg-[#181216]/60 hover:border-[#ff3a3a]/50"
                          )}
                        >
                          <div className="flex h-8.5 w-8.5 shrink-0 items-center justify-center rounded-lg bg-[#ff3a3a]/20 border border-[#ff3a3a] text-white">
                            <CategoryIcon id={rep.category} selected={true} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-1.5">
                              <h4 className="text-xs font-bold text-white truncate flex-1">{rep.title}</h4>
                              <span className={cn(
                                "h-1.5 w-1.5 rounded-full shrink-0",
                                rep.isOnline ? "bg-emerald-500" : "bg-zinc-500"
                              )} />
                            </div>
                            <p className="text-[8.5px] font-semibold text-[#a08890] mt-0.5 truncate">
                              By: <span className="text-[#ff8080] font-bold">{rep.playerName}</span> {rep.isOnline ? `(ID: ${rep.playerSource})` : "(Offline)"}
                            </p>
                          </div>
                        </button>
                      );
                    })
                  ) : (
                    <div className="text-center py-8 text-[11px] text-[#a08890]">
                      No active tickets
                    </div>
                  )}
                </div>
              </div>
            ) : (
              /* PLAYER VIEW */
              <div className="flex-1 flex flex-col justify-between py-4 min-h-0 w-full">
                <div className="flex flex-col min-h-0 flex-1">
                  <div className="flex items-center justify-between mb-3 shrink-0">
                    <p className="text-[9px] font-black uppercase tracking-wider text-[#ff4d4d]">My Support Status</p>
                    <button
                      type="button"
                      onClick={() => setFormActive(true)}
                      className="px-2.5 py-1 rounded bg-[#ff3a3a]/15 border border-[#ff3a3a] text-[#ff4d4d] hover:bg-[#ff3a3a]/30 text-[9px] font-black uppercase tracking-wider transition cursor-pointer"
                    >
                      + New Report
                    </button>
                  </div>

                  {savedReport ? (
                    <button
                      type="button"
                      onClick={() => setFormActive(false)}
                      className={cn(
                        "flex items-center gap-3 p-3 rounded-xl border transition cursor-pointer text-left w-full shrink-0",
                        !formActive
                          ? "border-[#ff3a3a] bg-[#ff3a3a]/15"
                          : "border-white/10 bg-[#181216]/60 hover:border-[#ff3a3a]/50"
                      )}
                    >
                      <div className="flex h-8.5 w-8.5 shrink-0 items-center justify-center rounded-lg bg-[#ff3a3a]/20 border border-[#ff3a3a] text-white">
                        <CategoryIcon id={savedReport.category} selected={true} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="text-xs font-bold text-white truncate">{savedReport.title}</h4>
                        <p className="text-[9px] font-bold text-[#ff4d4d] mt-0.5 uppercase tracking-wider">
                          {savedReport.category === "bug" ? "Bug Report" : savedReport.category === "rp" ? "RP Issue" : "Other"}
                        </p>
                      </div>
                      <div className="shrink-0">
                        <span className="rounded-md px-2 py-0.5 text-[8.5px] font-black uppercase tracking-wider bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
                          Active Chat
                        </span>
                      </div>
                    </button>
                  ) : (
                    <div className="flex-1 flex flex-col items-center justify-center gap-3 p-4 rounded-xl border border-white/5 bg-[#181216]/40 text-center">
                      <Clock className="h-6 w-6 text-[#a08890]/60" />
                      <p className="text-xs font-bold text-white">No Open Report</p>
                      <p className="text-[10px] text-[#a08890] max-w-[200px] leading-relaxed">
                        Fill out the form on the right to submit a new report to active staff.
                      </p>
                    </div>
                  )}
                </div>

                <div className="p-3 rounded-xl border border-[#ff3a3a]/20 bg-[#181216]/80 text-[10px] text-[#a08890] mt-3 leading-relaxed">
                  <span className="font-bold text-white block mb-0.5">ℹ️ Support Guidelines:</span>
                  Be respectful to staff. Provide clear details about your bug or RP issue.
                </div>
              </div>
            )}

            <PanelFooter />
          </div>
        </section>

        {/* RIGHT PANEL — Form Creation or Live Chat */}
        <section
          className="relative flex flex-col overflow-hidden rounded-2xl border-2 p-5 backdrop-blur-xl h-[580px] w-[530px] shrink-0"
          style={PANEL_STYLE}
        >
          <div className="panel-grid absolute inset-0 pointer-events-none opacity-40" />

          <div className="relative z-10 flex flex-col h-full">
            <PanelHeader
              icon={<MessageSquareMore className="h-4 w-4 text-white" strokeWidth={2} />}
              eyebrow={activeTab === "admin" ? "ADMIN CONSOLE" : "SUPPORT CONSOLE"}
              title={activeTab === "admin" ? (selectedAdminReport ? "Reviewing Player Ticket" : "Ticket Console") : (formActive ? "Tell staff what happened" : "Live Ticket Chat")}
              subtitle={activeTab === "admin" ? (selectedAdminReport ? `Chatting with ${selectedAdminReport.playerName}` : "Select a ticket from the left list") : (formActive ? "Submit details for active staff" : "Direct live chat with staff")}
              onClose={onClose}
            />

            {activeReportObj ? (
              /* LIVE CHAT VIEW */
              <div className="flex-1 flex flex-col pt-3 min-h-0">
                {/* Chat Header details */}
                <div className="flex items-center justify-between border-b pb-3 mb-3 border-[#ff3a3a]/20 shrink-0">
                  <div className="flex items-center gap-2.5">
                    <div className="flex h-7.5 w-7.5 shrink-0 items-center justify-center rounded-lg bg-[#ff3a3a]/15 border border-[#ff3a3a] text-white">
                      <CategoryIcon id={activeReportObj.category} selected={true} />
                    </div>
                    <div>
                      <h4 className="text-xs font-bold text-white truncate max-w-[220px]">{activeReportObj.title}</h4>
                      <p className="text-[9px] font-bold text-[#ff4d4d] mt-0.5 uppercase tracking-wider">
                        {activeReportObj.category === "bug" ? "Bug Report" : activeReportObj.category === "rp" ? "RP Issue" : "Other"}
                      </p>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex items-center gap-2">
                    {activeTab === "player" && (
                      <button
                        type="button"
                        onClick={() => setFormActive(true)}
                        className="px-2.5 py-1 rounded bg-[#ff3a3a]/15 border border-[#ff3a3a] text-[#ff4d4d] hover:bg-[#ff3a3a]/30 text-[9px] font-bold uppercase tracking-wider transition cursor-pointer"
                      >
                        + New Report
                      </button>
                    )}
                    {activeTab === "admin" && (
                      <button
                        type="button"
                        onClick={() => handleResolveReport(activeReportObj.identifier || activeReportObj.playerIdentifier || "")}
                        className="px-3 py-1 rounded-md bg-emerald-500/15 text-emerald-400 hover:bg-emerald-500/30 border border-emerald-500/40 text-[9px] font-black uppercase tracking-wider transition cursor-pointer"
                      >
                        Resolve Ticket
                      </button>
                    )}
                  </div>
                </div>

                {/* Messages Bubble Box */}
                <div ref={chatContainerRef} className="flex-1 overflow-y-auto custom-scrollbar pr-1 flex flex-col gap-2.5 mb-3 min-h-0">
                  {/* Original Issue Description */}
                  <div className="p-3 rounded-xl bg-[#181216] border border-[#ff3a3a]/30 max-w-[90%] self-start">
                    <span className="text-[8.5px] font-black text-[#ff4d4d] uppercase tracking-wider block mb-1">
                      {activeReportObj.playerName || "Player"} (Original Issue)
                    </span>
                    <p className="text-xs text-white leading-relaxed break-words">{activeReportObj.description}</p>
                    <span className="text-[8px] text-[#a08890] block mt-1 text-right">
                      {formatTime(activeReportObj.createdAt)}
                    </span>
                  </div>

                  {/* Additional chat replies */}
                  {normalizeMessages(activeReportObj.messages, activeReportObj.messagesJson).map((msg: ReportMessage, idx: number) => {
                    const isSelf = activeTab === "admin" ? msg.sender === "admin" : msg.sender === "player";
                    return (
                      <div
                        key={idx}
                        className={cn(
                          "p-3 rounded-xl max-w-[85%] flex flex-col",
                          isSelf
                            ? "bg-[#ff3a3a]/20 border border-[#ff3a3a] self-end"
                            : "bg-[#181216] border border-white/10 self-start"
                        )}
                      >
                        <span className={cn(
                          "text-[8.5px] font-black uppercase tracking-wider block mb-1",
                          isSelf ? "text-[#ff8080] text-right" : "text-white"
                        )}>
                          {msg.name} ({msg.sender === "admin" ? "Admin" : "Player"})
                        </span>
                        <p className="text-xs text-white leading-relaxed break-words">{msg.text}</p>
                        <span className="text-[8px] text-[#a08890] block mt-1 text-right">
                          {formatTime(msg.time)}
                        </span>
                      </div>
                    );
                  })}
                </div>

                {/* Message Input Box */}
                <div className="flex items-center gap-2 border-t pt-3 border-[#ff3a3a]/20 shrink-0">
                  <input
                    type="text"
                    value={chatMessage}
                    onChange={(e) => setChatMessage(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") handleSendMessage(activeReportObj.identifier || activeReportObj.playerIdentifier || "");
                    }}
                    placeholder="Type your reply message..."
                    className="flex-1 rounded-xl border border-[#ff3a3a]/40 bg-[#0d0d12] px-3.5 py-2.5 text-xs font-medium text-white placeholder:text-[#a08890] focus:outline-none focus:border-[#ff3a3a]"
                  />
                  <button
                    type="button"
                    onClick={() => handleSendMessage(activeReportObj.identifier || activeReportObj.playerIdentifier || "")}
                    className="h-10 px-4 shrink-0 flex items-center justify-center rounded-xl bg-gradient-to-r from-[#ff4d4d] via-[#e61e1e] to-[#b30000] border border-[#ff3a3a] text-white hover:brightness-110 active:scale-95 transition cursor-pointer"
                  >
                    <Send className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ) : formActive ? (
              /* FORM CREATION VIEW */
              <div className="flex-1 flex flex-col pt-3 min-h-0">
                <p className="text-[9px] font-black uppercase tracking-wider text-[#ff4d4d] mb-2">Category</p>
                <div className="grid grid-cols-3 gap-2.5 mb-4">
                  {categories.map((cat) => {
                    const selected = category === cat.id;
                    return (
                      <button
                        key={cat.id}
                        type="button"
                        onClick={() => setCategory(cat.id)}
                        className={cn(
                          "flex items-center gap-2.5 rounded-xl border p-3 transition cursor-pointer text-left w-full",
                          selected
                            ? "border-[#ff3a3a] bg-[#ff3a3a]/20"
                            : "border-white/10 bg-[#181216]/80 hover:border-[#ff3a3a]/50"
                        )}
                      >
                        <div
                          className={cn(
                            "flex h-7 w-7 shrink-0 items-center justify-center rounded-lg transition",
                            selected ? "bg-[#ff3a3a] text-white" : "bg-black/40 text-muted-foreground border border-white/5"
                          )}
                        >
                          <CategoryIcon id={cat.id} selected={selected} />
                        </div>
                        <span className="text-[10.5px] font-extrabold text-white leading-tight">{cat.label}</span>
                      </button>
                    );
                  })}
                </div>

                <div className="mb-4">
                  <label className="text-[9px] font-black uppercase tracking-wider text-[#ff4d4d] block mb-1">Title</label>
                  <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value.slice(0, maxTitle))}
                    placeholder="Short summary of issue..."
                    className="w-full rounded-xl border border-[#ff3a3a]/40 bg-[#0d0d12] px-3.5 py-2.5 text-xs font-medium text-white placeholder:text-[#a08890] focus:outline-none focus:border-[#ff3a3a]"
                    maxLength={maxTitle}
                  />
                </div>

                <div className="flex-1 flex flex-col min-h-0 mb-4">
                  <div className="flex items-center justify-between mb-1">
                    <label className="text-[9px] font-black uppercase tracking-wider text-[#ff4d4d]">Message</label>
                    <span className="text-[9px] text-[#a08890] font-semibold">{description.length}/{maxDescription}</span>
                  </div>
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value.slice(0, maxDescription))}
                    placeholder="Describe your issue clearly..."
                    className="flex-1 min-h-[100px] w-full resize-none rounded-xl border border-[#ff3a3a]/40 bg-[#0d0d12] px-3.5 py-2.5 text-xs font-medium text-white placeholder:text-[#a08890] focus:outline-none focus:border-[#ff3a3a] custom-scrollbar"
                    maxLength={maxDescription}
                  />
                </div>

                <button
                  type="button"
                  onClick={handleSubmit}
                  disabled={submitting}
                  className="w-full rounded-xl bg-gradient-to-r from-[#ff4d4d] via-[#e61e1e] to-[#b30000] border border-[#ff3a3a] py-3 text-xs font-black uppercase tracking-wider text-white hover:brightness-110 active:scale-95 transition cursor-pointer disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  {submitting ? "Submitting..." : "Submit Report"}
                </button>
              </div>
            ) : (
              /* PLACEHOLDER CHAT LOADING VIEW */
              <div className="flex-1 flex flex-col items-center justify-center text-center p-6 my-auto rounded-xl border border-[#ff3a3a]/30 bg-[#181216]/60 min-h-0">
                <div className="flex h-14 w-14 items-center justify-center rounded-full bg-[#ff3a3a]/15 border border-[#ff3a3a] text-[#ff4d4d] mb-4 animate-pulse">
                  <Headphones className="h-6 w-6" />
                </div>
                <h3 className="text-sm font-black text-white">
                  {activeTab === "admin" ? "No Ticket Selected" : "No Report Selected"}
                </h3>
                <p className="mt-2 text-xs text-[#a08890] max-w-[240px] leading-relaxed">
                  {activeTab === "admin"
                    ? "Click on an active player ticket in the left list to review it and chat with them."
                    : "Click on your active report in the left panel under Player Support to open your live chat."}
                </p>
              </div>
            )}

            <PanelFooter />
          </div>
        </section>
      </div>
    </div>
  );
}
