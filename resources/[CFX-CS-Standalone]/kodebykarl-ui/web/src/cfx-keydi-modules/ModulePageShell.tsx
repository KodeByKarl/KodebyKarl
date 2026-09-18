import React from "react";
import { ArrowLeft, X } from "lucide-react";
import grimLogo from "@/assets/grim-city-logo.png";

interface ModulePageShellProps {
  /** Big left-panel headline (e.g. Multi-Job Roster) */
  title: string;
  eyebrow: string;
  subtitle: string;
  onClose: () => void;
  children: React.ReactNode;
  sidebarHint?: string;
}

/** Shared chrome for Control Center sub-pages. */
export default function ModulePageShell({
  title,
  eyebrow,
  subtitle,
  onClose,
  children,
  sidebarHint = "Configure settings from the Control Center.",
}: ModulePageShellProps) {
  React.useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

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
              <h1 className="mt-1 text-2xl font-black tracking-tight text-white">{title}</h1>
              <p className="mx-auto mt-2 max-w-[210px] text-[11px] leading-relaxed text-[#ffc2c2]">
                {sidebarHint}
              </p>
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
            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={onClose}
                className="flex cursor-pointer items-center gap-1 rounded-lg border border-[#ff3a3a]/40 bg-[#181216] px-2.5 py-1 text-[10px] font-black uppercase text-[#ff4d4d] transition hover:bg-[#ff3a3a]/20"
              >
                <ArrowLeft className="h-3.5 w-3.5" /> Back
              </button>
              <div>
                <span className="text-xs font-black uppercase tracking-[0.2em] text-[#ff4d4d]">
                  {eyebrow}
                </span>
                <p className="mt-0.5 text-[11px] text-[#a08890]">{subtitle}</p>
              </div>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="flex cursor-pointer items-center gap-1.5 rounded-lg border border-[#ff3a3a]/30 bg-[#181216] px-3 py-1 text-[11px] font-semibold text-white/80 transition hover:border-[#ff3a3a] hover:text-white"
            >
              <span>Esc</span>
              <X className="h-3.5 w-3.5 text-[#ff4d4d]" />
            </button>
          </div>

          <div className="flex min-h-0 flex-1 flex-col">{children}</div>
        </div>
      </div>
    </div>
  );
}
