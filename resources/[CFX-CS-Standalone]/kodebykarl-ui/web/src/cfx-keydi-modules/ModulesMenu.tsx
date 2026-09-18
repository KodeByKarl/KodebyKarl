import { useEffect } from "react";
import {
  Bug,
  Zap,
  Rocket,
  FileText,
  ChevronRight,
  Video,
  Briefcase,
  X,
  Server,
  Crown,
} from "lucide-react";
import { cn } from "@/lib/utils";
import grimLogo from "@/assets/grim-city-logo.png";

interface ModulesMenuProps {
  onClose: () => void;
  onOpenDamageIndicator: () => void;
  onOpenFpsOptimizer: () => void;
  onOpenReport: () => void;
  onOpenBanking?: () => void;
  onOpenPatchNotes: () => void;
  onOpenMultiJob: () => void;
  onOpenRegions: () => void;
  onOpenRockstar: () => void;
  onOpenVip: () => void;
}

export default function ModulesMenu({
  onClose,
  onOpenDamageIndicator,
  onOpenFpsOptimizer,
  onOpenReport,
  onOpenPatchNotes,
  onOpenMultiJob,
  onOpenRegions,
  onOpenRockstar,
  onOpenVip,
}: ModulesMenuProps) {
  useEffect(() => {
    const handleLocalKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handleLocalKeyDown);
    return () => window.removeEventListener("keydown", handleLocalKeyDown);
  }, [onClose]);

  const moduleItems = [
    {
      id: "report",
      name: "Report System",
      desc: "Communicate directly with active staff for technical or RP issues.",
      icon: <Bug className="h-5 w-5 text-[#ff4d4d]" />,
      action: onOpenReport,
      tag: "SUPPORT",
    },
    {
      id: "indicator",
      name: "Damage Indicator",
      desc: "Zone-colored hitmarkers, dead labels, fonts, and timing.",
      icon: <Zap className="h-5 w-5 text-[#ff4d4d]" />,
      action: onOpenDamageIndicator,
      tag: "COMBAT",
    },
    {
      id: "fps",
      name: "FPS Optimizer",
      desc: "Instant graphics presets to maximize your frame rate.",
      icon: <Rocket className="h-5 w-5 text-[#ff4d4d]" />,
      action: onOpenFpsOptimizer,
      tag: "PERFORMANCE",
    },
    {
      id: "patchnotes",
      name: "Patch Notes",
      desc: "Read the latest server releases, bug fixes, and features.",
      icon: <FileText className="h-5 w-5 text-[#ff4d4d]" />,
      action: onOpenPatchNotes,
      tag: "CHANGELOG",
    },
    {
      id: "multijob",
      name: "Multi-Job Roster",
      desc: "Switch active job duty position on demand (Max 3 held jobs).",
      icon: <Briefcase className="h-5 w-5 text-[#ff4d4d]" />,
      action: onOpenMultiJob,
      tag: "CAREER",
    },
    {
      id: "server",
      name: "Regions",
      desc: "Switch in-game between Farm, School, and Turf War regions. Each region is isolated.",
      icon: <Server className="h-5 w-5 text-[#ff4d4d]" />,
      action: onOpenRegions,
      tag: "INSTANCING",
    },
    {
      id: "rockstar",
      name: "Rockstar Recording",
      desc: "Record clips in-game, save, photo, or open the editor.",
      icon: <Video className="h-5 w-5 text-[#ff4d4d]" />,
      action: onOpenRockstar,
      tag: "MEDIA",
    },
    {
      id: "vip",
      name: "VIP Status",
      desc: "View your VIP plan. Staff can Set and Edit VIP here.",
      icon: <Crown className="h-5 w-5 text-[#ff4d4d]" />,
      action: onOpenVip,
      tag: "MEMBERSHIP",
    },
  ];

  return (
    <div className="pandora fixed inset-0 z-40 flex items-center justify-center bg-black/80 p-8 font-sans pointer-events-auto select-none animate-fade-in backdrop-blur-[6px]">
      <div className="pandora-panel relative flex h-[590px] w-full max-w-6xl overflow-hidden rounded-2xl border-2 border-[#ff3a3a] bg-[#0d0d12]">
        <div
          className="relative flex w-[32%] flex-col justify-between overflow-hidden border-r border-[#ff3a3a] p-7"
          style={{ background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)" }}
        >
          <div className="panel-grid pointer-events-none absolute inset-0 opacity-30" />

          <div className="relative z-10 mt-1 flex flex-col items-center gap-4 text-center">
            <img src={grimLogo} alt="Grim City" className="w-[145px] object-contain drop-shadow" />

            <div>
              <span className="mb-2 inline-block rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/20 px-3 py-1 text-[9px] font-black uppercase tracking-[0.2em] text-[#ff4d4d]">
                GRIM CITY ROLEPLAY
              </span>
              <h1 className="mt-1 text-2xl font-black tracking-tight text-white">MODULE CONTROL</h1>
              <p className="mx-auto mt-2 max-w-[210px] text-[11px] leading-relaxed text-[#ffc2c2]">
                Configure settings, optimize FPS, check job duty, or switch server instances.
              </p>
            </div>

            <div className="mt-2 flex w-full flex-col gap-2">
              <div className="flex items-center justify-between rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-2.5">
                <span className="text-[9.5px] font-bold text-[#a08890]">Active Modules</span>
                <span className="text-[10px] font-black text-[#ff4d4d]">{moduleItems.length} Ready</span>
              </div>
              <div className="flex items-center justify-between rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-2.5">
                <span className="text-[9.5px] font-bold text-[#a08890]">Instance Splitting</span>
                <span className="flex items-center gap-1.5 text-[9.5px] font-black text-emerald-400">
                  <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-400" />
                  2 SERVERS ACTIVE
                </span>
              </div>
            </div>
          </div>

          <div className="relative z-10 border-t border-[#ff3a3a]/25 pt-3 text-center">
            <span className="text-[10px] tracking-[0.16em] text-[#a08890]">
              Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
            </span>
          </div>
        </div>

        <div className="flex h-full flex-1 flex-col bg-transparent p-7">
          <div className="mb-4 flex shrink-0 items-center justify-between border-b border-[#ff3a3a]/30 pb-4">
            <div>
              <span className="text-xs font-black uppercase tracking-[0.2em] text-[#ff4d4d]">
                MODULE MATRIX
              </span>
              <p className="mt-0.5 text-[11px] text-[#a08890]">
                Select a module below to launch its configuration window.
              </p>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={onOpenRegions}
                className={cn(
                  "flex cursor-pointer items-center gap-1.5 rounded-lg border px-3 py-1 text-[11px] font-black uppercase transition",
                  "border-[#ff3a3a]/40 bg-[#ff3a3a]/15 text-[#ff4d4d] hover:bg-[#ff3a3a]/30"
                )}
              >
                <Server className="h-3.5 w-3.5" />
                <span>Regions</span>
              </button>
              <button
                type="button"
                onClick={onClose}
                className="flex cursor-pointer items-center gap-1.5 rounded-lg border border-[#ff3a3a]/30 bg-[#181216] px-3 py-1 text-[11px] font-semibold text-white/80 transition hover:border-[#ff3a3a] hover:text-white"
              >
                <span>Esc</span>
                <X className="h-3.5 w-3.5 text-[#ff4d4d]" />
              </button>
            </div>
          </div>

          <div className="flex min-h-0 flex-1 flex-col justify-between">
            <div className="grid flex-1 grid-cols-2 content-start gap-3 overflow-y-auto p-1.5 pr-2 custom-scrollbar">
              {moduleItems.map((item) => (
                <div
                  key={item.id}
                  onClick={item.action}
                  className="group flex cursor-pointer items-center justify-between rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-3.5 transition-all hover:border-[#ff3a3a] hover:bg-[#ff3a3a]/25"
                >
                  <div className="flex min-w-0 flex-1 items-center gap-3.5">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-[#ff3a3a] bg-[#ff3a3a]/20 text-white">
                      {item.icon}
                    </div>
                    <div className="flex min-w-0 flex-1 flex-col text-left">
                      <div className="flex items-center gap-2">
                        <span className="truncate text-xs font-black text-white">{item.name}</span>
                        <span className="rounded border border-[#ff3a3a]/40 bg-[#ff3a3a]/20 px-1.5 py-0.5 text-[8px] font-black uppercase tracking-wider text-[#ff8080]">
                          {item.tag}
                        </span>
                      </div>
                      <span className="mt-1 line-clamp-2 pr-2 text-[10px] leading-snug text-[#a08890]">
                        {item.desc}
                      </span>
                    </div>
                  </div>
                  <ChevronRight className="ml-2 h-4 w-4 shrink-0 text-[#ff4d4d] transition group-hover:translate-x-1" />
                </div>
              ))}
            </div>

            <div className="mt-3 flex shrink-0 items-center justify-between border-t border-[#ff3a3a]/25 pt-3.5">
              <div className="flex items-center gap-2.5">
                <img src={grimLogo} alt="Grim City" className="h-5 w-5 object-contain" />
                <div className="flex flex-col text-left">
                  <span className="text-[10px] font-black tracking-[0.2em] text-white">
                    GRIM CITY ROLEPLAY
                  </span>
                  <span className="text-[8px] font-semibold tracking-wider text-[#a08890]">
                    INSTANCE SPLITTING ARCHITECTURE
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1.5 rounded-md border border-[#ff3a3a]/40 bg-[#ff3a3a]/15 px-2.5 py-1 text-[9px] font-black uppercase text-[#ff4d4d]">
                  <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-[#ff3a3a]" />
                  VERIFIED v2.4
                </div>
                <span className="text-[10px] tracking-[0.16em] text-[#a08890]">
                  Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
