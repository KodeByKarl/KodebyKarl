import React, { useState } from "react";
import { 
  Home, FileText, ArrowRight, ExternalLink, Globe, User, MessageSquare, Sparkles, Wrench, ShieldCheck, Zap
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import grimLogo from "@/assets/grim-city-logo.png";

type UpdateTag = "Feature" | "Fix" | "Security" | "Performance" | "Rework" | "Major Update" | string;

interface WelcomeUpdate {
  version: string;
  date: string;
  title: string;
  tag: UpdateTag;
  notes: string[];
}

interface WelcomeData {
  serverName: string;
  playerName: string;
  home: {
    intro: string;
    points: string[];
  };
  links: {
    discord?: { label: string; url?: string | null };
    website?: { label: string; url?: string | null } | null;
    praryo?: { label: string; url?: string | null } | null;
  };
  updates?: WelcomeUpdate[];
}

interface WelcomeScreenProps {
  data: WelcomeData;
  onClose: () => void;
}

type WelcomeTab = "home" | "updates";

const TAG_STYLES: Record<string, { icon: React.ReactNode; bg: string; text: string }> = {
  Feature: { icon: <Sparkles className="h-3 w-3" />, bg: "rgba(255, 58, 58, 0.25)", text: "#ffb3b3" },
  "Major Update": { icon: <Sparkles className="h-3 w-3" />, bg: "rgba(255, 58, 58, 0.25)", text: "#ffb3b3" },
  Fix: { icon: <Wrench className="h-3 w-3" />, bg: "rgba(255, 128, 128, 0.25)", text: "#ffffff" },
  Security: { icon: <ShieldCheck className="h-3 w-3" />, bg: "rgba(40, 160, 100, 0.3)", text: "#adfcbe" },
  Performance: { icon: <Zap className="h-3 w-3" />, bg: "rgba(255, 210, 76, 0.28)", text: "#ffeeb8" },
  Rework: { icon: <Wrench className="h-3 w-3" />, bg: "rgba(167, 139, 250, 0.28)", text: "#ddd6fe" },
};

export default function WelcomeScreen({ data, onClose }: WelcomeScreenProps) {
  const [tab, setTab] = useState<WelcomeTab>("updates");
  const [filter, setFilter] = useState<"all" | UpdateTag>("all");

  const serverUpdates = data.updates ?? [];
  const visibleUpdates = filter === "all" 
    ? serverUpdates 
    : serverUpdates.filter((u) => u.tag === filter);

  const handleOpenUrl = (url: string) => {
    if ((window as any).invokeNative) {
      (window as any).invokeNative("openUrl", url);
    } else {
      window.open(url, "_blank");
    }
  };

  return (
    <div className="pandora fixed inset-0 flex items-center justify-center p-8 bg-black/70 backdrop-blur-[6px] select-none pointer-events-auto animate-fade-in font-sans z-[80]">
      <div className="pandora-panel w-full max-w-6xl overflow-hidden rounded-2xl border-2 border-[#ff3a3a] h-[540px] flex flex-col relative bg-[#0d0d12]">
        {/* Top Navigation */}
        <div className="flex items-center justify-between border-b border-[#ff3a3a]/30 px-6 py-4">
          <div className="flex items-center gap-6">
            <button
              onClick={() => setTab("home")}
              className={cn(
                "flex items-center gap-2 border-b-2 pb-1 text-sm font-bold transition cursor-pointer",
                tab === "home"
                  ? "border-[#ff3a3a] text-white [&_svg]:text-[#ff4d4d]"
                  : "border-transparent text-[#a08890] hover:text-white"
              )}
            >
              <Home className="h-4 w-4" />
              <span>Home</span>
            </button>
            <button
              onClick={() => setTab("updates")}
              className={cn(
                "flex items-center gap-2 border-b-2 pb-1 text-sm font-bold transition cursor-pointer",
                tab === "updates"
                  ? "border-[#ff3a3a] text-white [&_svg]:text-[#ff4d4d]"
                  : "border-transparent text-[#a08890] hover:text-white"
              )}
            >
              <FileText className="h-4 w-4" />
              <span>Server Updates</span>
            </button>
          </div>
          <Button
            onClick={onClose}
            className="rounded-xl bg-gradient-to-r from-[#ff4d4d] via-[#e61e1e] to-[#b30000] border border-[#ff3a3a] px-5 font-black uppercase text-xs text-white hover:brightness-110 pointer-events-auto cursor-pointer"
          >
            Continue <ArrowRight className="ml-1 h-4 w-4" />
          </Button>
        </div>

        {/* Content Body Grid */}
        <div className="grid gap-0 grid-cols-[340px_1fr] flex-1 overflow-hidden">
          {/* Left branding panel */}
          <div
            className="pandora-hero relative flex flex-col items-center justify-between overflow-hidden p-10 border-r border-[#ff3a3a]"
          >
            <div className="panel-grid absolute inset-0 pointer-events-none opacity-40" />
            
            {/* Top Logo Container */}
            <div className="relative z-10 flex flex-col items-center gap-4 mt-2">
              <img src={grimLogo} alt="Grim City" className="pandora-logo w-[150px] object-contain" />
            </div>

            {/* Middle Welcome Message */}
            <div className="relative z-10 text-center my-auto">
              <span className="inline-block bg-[#ff3a3a]/20 border border-[#ff3a3a] text-[#ff4d4d] text-[9px] font-black tracking-[0.2em] px-2.5 py-1 rounded-md uppercase mb-2">
                WELCOME BACK,
              </span>
              <h1 className="pandora-title text-2xl font-black max-w-[280px] truncate text-white">
                {data.playerName || "Player"}
              </h1>
              <p className="mx-auto mt-3 max-w-[240px] text-[11px] leading-relaxed text-[#ffc2c2]">
                Your return hub for rules, community links, and server essentials.
              </p>
            </div>

            {/* Bottom Footer Developer URL */}
            <div className="relative z-10 text-center border-t border-[#ff3a3a]/25 pt-3 w-full">
              <p className="text-[9.5px] font-black tracking-[0.2em] text-[#ff4d4d]">
                GRIM CITY ROLEPLAY
              </p>
              <span className="text-[9px] text-[#a08890] block mt-0.5">Powered by KodeByKarl.Net</span>
            </div>
          </div>

          {/* Right Content View */}
          <div className="p-8 flex flex-col h-full overflow-hidden bg-transparent">
            {tab === "home" ? (
              <div className="flex flex-col h-full justify-between overflow-y-auto pr-3 custom-scrollbar">
                {/* Getting Started section */}
                <div>
                  <p className="text-xs font-black tracking-[0.25em] text-[#ff4d4d] uppercase">GETTING STARTED</p>
                  <p className="mt-2 text-[13px] leading-relaxed text-[#a08890]">
                    {data.home?.intro || "We're glad to have you back on the server."}
                  </p>

                  {/* Points Cards Grid */}
                  <div className="mt-5 grid grid-cols-2 gap-4">
                    {(data.home?.points || []).map((point, index) => (
                      <div 
                        key={index} 
                        className="flex gap-4 p-4 rounded-xl border border-[#ff3a3a]/30 bg-[#181216]"
                      >
                        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#ff3a3a]/20 border border-[#ff3a3a] font-black text-xs text-[#ff4d4d]">
                          {String(index + 1).padStart(2, '0')}
                        </div>
                        <p className="text-[11.5px] leading-relaxed text-white flex-1 flex items-center">
                          {point}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Community Links section */}
                <div className="mt-6 mb-2">
                  <div className="border-t border-[#ff3a3a]/25 pt-4">
                    <p className="text-xs font-black tracking-[0.25em] text-[#ff4d4d] uppercase">COMMUNITY</p>
                    <p className="text-[11px] text-[#a08890] mt-1">
                      Stay connected with the server outside of the game.
                    </p>

                    {/* Social Link Cards Row */}
                    <div className="grid grid-cols-3 gap-3 mt-3">
                      {data.links?.discord && (
                        <button
                          onClick={() => data.links.discord.url && handleOpenUrl(data.links.discord.url)}
                          className="flex items-center justify-between p-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] cursor-pointer text-left transition hover:border-[#ff3a3a]"
                        >
                          <div className="flex items-center gap-2 overflow-hidden">
                            <MessageSquare className="h-4 w-4 text-[#ff4d4d] shrink-0" />
                            <div className="flex flex-col overflow-hidden">
                              <span className="text-[9px] font-black text-[#a08890] uppercase tracking-wider">DISCORD</span>
                              <span className="text-[10px] text-white truncate max-w-[140px] font-bold">{data.links.discord.label}</span>
                            </div>
                          </div>
                          {data.links.discord.url && <ExternalLink className="h-3 w-3 text-[#a08890] shrink-0" />}
                        </button>
                      )}

                      {data.links?.website?.label && (
                        <button
                          onClick={() => data.links.website?.url && handleOpenUrl(data.links.website.url)}
                          className="flex items-center justify-between p-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] cursor-pointer text-left transition hover:border-[#ff3a3a]"
                        >
                          <div className="flex items-center gap-2 overflow-hidden">
                            <Globe className="h-4 w-4 text-[#ff4d4d] shrink-0" />
                            <div className="flex flex-col overflow-hidden">
                              <span className="text-[9px] font-black text-[#a08890] uppercase tracking-wider">WEBSITE</span>
                              <span className="text-[10px] text-white truncate max-w-[140px] font-bold">{data.links.website.label}</span>
                            </div>
                          </div>
                          {data.links.website.url && <ExternalLink className="h-3 w-3 text-[#a08890] shrink-0" />}
                        </button>
                      )}

                      {data.links?.praryo?.label && (
                        <button
                          onClick={() => data.links.praryo?.url && handleOpenUrl(data.links.praryo.url)}
                          className="flex items-center justify-between p-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] cursor-pointer text-left transition hover:border-[#ff3a3a]"
                        >
                          <div className="flex items-center gap-2 overflow-hidden">
                            <User className="h-4 w-4 text-[#ff4d4d] shrink-0" />
                            <div className="flex flex-col overflow-hidden">
                              <span className="text-[9px] font-black text-[#a08890] uppercase tracking-wider">DEVELOPER</span>
                              <span className="text-[10px] text-white truncate max-w-[140px] font-bold">{data.links.praryo.label}</span>
                            </div>
                          </div>
                          {data.links.praryo.url && <ExternalLink className="h-3 w-3 text-[#a08890] shrink-0" />}
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="flex-1 flex flex-col justify-between overflow-hidden">
                {/* Header for Updates */}
                <div className="flex items-center justify-between border-b border-[#ff3a3a]/25 pb-3">
                  <div>
                    <p className="text-xs font-black tracking-[0.25em] text-[#ff4d4d] uppercase">CHANGELOG</p>
                    <p className="text-[11px] text-[#a08890] mt-0.5">
                      Latest updates, fixes, and new features shipped to the server.
                    </p>
                  </div>
                  <div className="flex gap-1 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-1">
                    {(["all", "Feature", "Fix", "Rework", "Security", "Performance"] as const).map((f) => (
                      <button
                        key={f}
                        onClick={() => setFilter(f)}
                        className={cn(
                          "rounded-lg px-2.5 py-1 text-[9px] font-black uppercase tracking-wider transition cursor-pointer",
                          filter === f
                            ? "bg-[#ff3a3a] text-white"
                            : "text-[#a08890] hover:text-white"
                        )}
                      >
                        {f === "all" ? "All" : f}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Updates scroll list */}
                <div className="flex-1 overflow-y-auto custom-scrollbar pr-2 mt-4 space-y-3.5 max-h-[300px]">
                  {visibleUpdates.map((u, i) => {
        const style = TAG_STYLES[u.tag] || TAG_STYLES.Feature;
                    return (
                      <article
                        key={`${u.version}-${i}`}
                        className="group rounded-xl border border-[#ff3a3a]/30 p-4 transition-all hover:border-[#ff3a3a] bg-[#181216]"
                      >
                        <div className="flex flex-wrap items-center gap-3">
                          <span 
                            className="rounded-md px-2 py-0.5 font-mono text-[10px] font-bold tracking-wider border border-[#ff3a3a]/40 bg-[#ff3a3a]/15 text-[#ff8080]"
                          >
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
                          {(u.notes || []).map((n, idx) => (
                            <li key={idx} className="flex gap-2 text-[11px] leading-relaxed text-[#a08890]">
                              <span className="mt-2 h-1 w-1 shrink-0 rounded-full bg-[#ff3a3a]" />
                              <span>{n}</span>
                            </li>
                          ))}
                        </ul>
                      </article>
                    );
                  })}
                  {visibleUpdates.length === 0 && (
                    <p className="rounded-xl border border-[#ff3a3a]/30 p-8 text-center text-xs text-[#a08890]">
                      No updates match this filter.
                    </p>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
