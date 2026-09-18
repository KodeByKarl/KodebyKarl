import { useEffect, useState } from "react";
import {
  Camera,
  Circle,
  Save,
  Trash2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import ModulePageShell from "@/cfx-keydi-modules/ModulePageShell";
import { fetchNui } from "@/lib/nui";

interface RockstarRecordingProps {
  onClose: () => void;
  onRecordingChange?: (recording: boolean) => void;
}

export default function RockstarRecording({ onClose, onRecordingChange }: RockstarRecordingProps) {
  const [recording, setRecording] = useState(false);
  const [rockstarBusy, setRockstarBusy] = useState(false);

  useEffect(() => {
    fetchNui<{ recording?: boolean }>("cfx-keydi-modules:getRockstarState", {})
      .then((res) => {
        const next = !!res?.recording;
        setRecording(next);
        onRecordingChange?.(next);
      })
      .catch(() => {});
  }, [onRecordingChange]);

  const handleRockstarAction = (button: "record" | "save" | "delete" | "photo" | "open") => {
    if (rockstarBusy) return;
    setRockstarBusy(true);
    fetchNui<{ ok?: boolean; recording?: boolean; close?: boolean }>(
      "cfx-keydi-modules:rockstarAction",
      { button }
    )
      .then((res) => {
        if (typeof res?.recording === "boolean") {
          setRecording(res.recording);
          onRecordingChange?.(res.recording);
        }
      })
      .catch(() => {})
      .finally(() => setRockstarBusy(false));
  };

  return (
    <ModulePageShell
      title="Rockstar Recording"
      eyebrow="ROCKSTAR RECORDING"
      subtitle="Record clips in-game, save, photo, or open Single Player editor."
      sidebarHint="Capture clips without leaving the server."
      onClose={onClose}
    >
      <div className="flex flex-1 flex-col justify-between overflow-hidden">
        <div className="mb-2 flex-1 space-y-3 overflow-y-auto pr-2 custom-scrollbar">
          <div
            className={cn(
              "flex items-center justify-between rounded-xl border bg-[#181216] p-3.5",
              recording ? "border-red-500 bg-red-500/10" : "border-[#ff3a3a]/40"
            )}
          >
            <div className="flex items-center gap-2.5">
              <Circle
                className={cn(
                  "h-3 w-3",
                  recording ? "animate-pulse fill-red-500 text-red-500" : "text-[#a08890]"
                )}
              />
              <div className="flex flex-col text-left">
                <span className="text-[11px] font-bold text-white">
                  {recording ? "Recording in-game" : "Not recording"}
                </span>
                <span className="mt-0.5 text-[9.5px] text-[#a08890]">
                  {recording
                    ? "Play normally, then save or discard the clip here."
                    : "Start a clip without leaving the server."}
                </span>
              </div>
            </div>
            <span
              className={cn(
                "rounded-lg border px-2.5 py-1 text-[10px] font-black uppercase tracking-wider",
                recording
                  ? "border-red-500 bg-red-500 text-white"
                  : "border-white/10 bg-[#0d0d12] text-[#a08890]"
              )}
            >
              {recording ? "REC" : "IDLE"}
            </span>
          </div>

          <div className="grid grid-cols-2 gap-2.5">
            <button
              type="button"
              disabled={rockstarBusy || recording}
              onClick={() => handleRockstarAction("record")}
              className="flex cursor-pointer items-center gap-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-3.5 text-left transition hover:border-[#ff3a3a] disabled:opacity-40"
            >
              <Circle className="h-4 w-4 shrink-0 fill-red-500 text-red-500" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-white">Record</span>
                <span className="text-[9.5px] text-[#a08890]">Start in-game clip</span>
              </div>
            </button>
            <button
              type="button"
              disabled={rockstarBusy || !recording}
              onClick={() => handleRockstarAction("save")}
              className="flex cursor-pointer items-center gap-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-3.5 text-left transition hover:border-[#ff3a3a] disabled:opacity-40"
            >
              <Save className="h-4 w-4 shrink-0 text-[#ff4d4d]" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-white">Save clip</span>
                <span className="text-[9.5px] text-[#a08890]">Keep to editor gallery</span>
              </div>
            </button>
            <button
              type="button"
              disabled={rockstarBusy || !recording}
              onClick={() => handleRockstarAction("delete")}
              className="flex cursor-pointer items-center gap-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-3.5 text-left transition hover:border-[#ff3a3a] disabled:opacity-40"
            >
              <Trash2 className="h-4 w-4 shrink-0 text-red-400" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-white">Discard</span>
                <span className="text-[9.5px] text-[#a08890]">Throw away this take</span>
              </div>
            </button>
            <button
              type="button"
              disabled={rockstarBusy}
              onClick={() => handleRockstarAction("photo")}
              className="flex cursor-pointer items-center gap-3 rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-3.5 text-left transition hover:border-[#ff3a3a] disabled:opacity-40"
            >
              <Camera className="h-4 w-4 shrink-0 text-cyan-400" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-white">Photo</span>
                <span className="text-[9.5px] text-[#a08890]">High quality screenshot</span>
              </div>
            </button>
          </div>
        </div>

        <div className="mt-2 flex justify-end border-t border-[#ff3a3a]/25 pt-3.5">
          <button
            type="button"
            onClick={onClose}
            className="cursor-pointer rounded-xl border border-[#ff3a3a] bg-[#ff3a3a] px-4 py-2 text-xs font-black uppercase tracking-wider text-white transition hover:brightness-110"
          >
            Return to Modules
          </button>
        </div>
      </div>
    </ModulePageShell>
  );
}
