import React, { useEffect } from "react";
import { X, Radio, Mic } from "lucide-react";
import grimLogo from "@/assets/grim-city-logo.png";
import { cn } from "@/lib/utils";
import { RadioPlayer } from "./RadioListHud";

interface RadioListModalProps {
  visible?: boolean;
  channel?: string | null;
  players?: RadioPlayer[];
  onClose?: () => void;
}

export const RadioListModal: React.FC<RadioListModalProps> = ({
  visible = true,
  channel = "100.0 MHz",
  players = [],
  onClose,
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.key === "Escape" || e.key === "Backspace") && onClose) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onClose]);

  if (!visible) return null;

  return (
    <div className="pandora fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 p-8 font-sans select-none animate-fade-in backdrop-blur-[6px]">
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
                Grim City Roleplay
              </span>
              <h1 className="mt-1 text-2xl font-black tracking-tight text-white">Radio Members</h1>
              <p className="mx-auto mt-2 max-w-[210px] text-[11px] leading-relaxed text-[#ffc2c2]">
                Live roster of everyone on this frequency.
              </p>
            </div>
          </div>
          <div className="relative z-10 w-full rounded-xl border border-[#ff3a3a] bg-[#181216] p-3.5">
            <p className="mb-1 text-[9px] font-black uppercase tracking-[0.2em] text-[#ff4d4d]">Frequency</p>
            <p className="text-sm font-extrabold text-white">{channel || "Disconnected"}</p>
            <p className="mt-0.5 text-[10px] text-[#a08890]">
              {players.length} connected
            </p>
          </div>
        </div>

        <div className="flex h-full flex-1 flex-col bg-transparent p-7">
          <div className="mb-4 flex shrink-0 items-center justify-between border-b border-[#ff3a3a]/30 pb-4">
            <div>
              <span className="text-xs font-black uppercase tracking-[0.2em] text-[#ff4d4d]">
                Connected players
              </span>
              <p className="mt-0.5 text-[11px] text-[#a08890]">
                {channel || "Disconnected"} · {players.length} on channel
              </p>
            </div>
            {onClose && (
              <button
                type="button"
                onClick={onClose}
                className="flex cursor-pointer items-center gap-1.5 rounded-lg border border-[#ff3a3a]/30 bg-[#181216] px-3 py-1 text-[11px] font-semibold text-white/80 transition hover:border-[#ff3a3a] hover:text-white"
                title="Close (ESC / Backspace)"
              >
                <span>Esc</span>
                <X className="h-3.5 w-3.5 text-[#ff4d4d]" />
              </button>
            )}
          </div>

          <div className="min-h-0 flex-1 space-y-2 overflow-y-auto pr-1">
            {players.length > 0 ? (
              players.map((p) => (
                <div
                  key={p.id}
                  className={cn(
                    "flex items-center justify-between rounded-xl border p-3 transition-colors",
                    p.talking
                      ? "border-[#ff3a3a] bg-[#ff3a3a]/15"
                      : p.self
                        ? "border-[#ff3a3a]/50 bg-[#181216]"
                        : "border-[#ff3a3a]/20 bg-[#181216]/80",
                  )}
                >
                  <div className="flex min-w-0 items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-[#ff3a3a] bg-[#ff3a3a]/15">
                      <Radio className="h-4 w-4 text-white" />
                    </div>
                    <div className="relative flex shrink-0 items-center justify-center">
                      <div
                        className={cn(
                          "h-2.5 w-2.5 rounded-full",
                          p.talking ? "bg-[#ff3a3a] shadow-[0_0_10px_#ff3a3a]" : "bg-[#a08890]",
                        )}
                      />
                      {p.talking && (
                        <div className="absolute h-4 w-4 rounded-full border border-[#ff3a3a] animate-ping" />
                      )}
                    </div>
                    <span className="truncate text-sm font-bold text-white">{p.name}</span>
                  </div>

                  <div className="flex shrink-0 items-center gap-1.5">
                    {p.self && (
                      <span className="rounded-full border border-[#ff3a3a]/40 bg-[#ff3a3a]/20 px-2 py-0.5 text-[9px] font-extrabold uppercase text-[#ff4d4d]">
                        You
                      </span>
                    )}
                    {p.talking && (
                      <span className="flex animate-pulse items-center gap-1 rounded-full border border-[#ff3a3a]/40 bg-[#ff3a3a]/20 px-2 py-0.5 text-[9px] font-black uppercase text-[#ff4d4d]">
                        <Mic className="h-3 w-3" /> Talking
                      </span>
                    )}
                  </div>
                </div>
              ))
            ) : (
              <div className="flex h-full items-center justify-center rounded-xl border border-[#ff3a3a]/20 bg-[#181216] px-6 py-10 text-center text-xs font-semibold text-[#a08890]">
                No players currently connected to this frequency.
              </div>
            )}
          </div>

          <div className="mt-4 shrink-0 border-t border-[#ff3a3a]/25 pt-3 text-center">
            <span className="text-[10px] tracking-[0.16em] text-[#a08890]">
              Powered by <strong className="text-[#ff4d4d]">KodeByKarl.Net</strong>
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RadioListModal;
