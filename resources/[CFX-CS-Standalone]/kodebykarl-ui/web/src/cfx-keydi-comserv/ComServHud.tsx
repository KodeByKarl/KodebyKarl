import { useEffect, useState } from "react";
import { HardHat, CheckCircle2 } from "lucide-react";
import { cn } from "@/lib/utils";

interface ComServData {
  remaining: number;
  total: number;
  reason: string;
  brand?: string;
}

const DEFAULT_DATA: ComServData = {
  remaining: 0,
  total: 0,
  reason: "",
  brand: "GRIM CITY",
};

export default function ComServHud() {
  const [visible, setVisible] = useState(false);
  const [data, setData] = useState<ComServData>(DEFAULT_DATA);
  const [completedFlash, setCompletedFlash] = useState(false);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg) return;

      if (msg.action === "cfx-keydi-comserv:show") {
        if (msg.data) setData({ ...DEFAULT_DATA, ...msg.data });
        setCompletedFlash(false);
        setVisible(true);
      } else if (msg.action === "cfx-keydi-comserv:update") {
        if (msg.data) {
          setData((prev) => ({ ...prev, ...msg.data }));
          if (typeof msg.data.remaining === "number" && msg.data.remaining <= 0) {
            setCompletedFlash(true);
          }
        }
      } else if (msg.action === "cfx-keydi-comserv:hide") {
        setVisible(false);
        setCompletedFlash(false);
      }
    };

    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  if (!visible) return null;

  const total = Math.max(data.total, 1);
  const done = Math.max(0, total - data.remaining);
  const progress = Math.min(100, Math.round((done / total) * 100));

  return (
    <div className="pandora fixed right-6 top-[42%] -translate-y-1/2 z-[99990] w-[250px] select-none pointer-events-none font-sans">
      <div
        className={cn(
          "relative overflow-hidden rounded-xl border-2 shadow-[0_25px_60px_-15px_rgba(0,0,0,0.95)]",
          completedFlash ? "border-emerald-400/50" : "border-[#ff3a3a]"
        )}
        style={{
          background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)",
        }}
      >
        <div className="panel-grid pointer-events-none absolute inset-0 opacity-30" />

        <div
          className="relative flex items-center gap-2 px-3 py-2"
          style={{
            borderBottom: "1px solid rgba(255, 58, 58, 0.25)",
          }}
        >
          <div className="flex h-6 w-6 items-center justify-center rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/15">
            {completedFlash ? (
              <CheckCircle2 className="h-3 w-3 text-emerald-300" />
            ) : (
              <HardHat className="h-3 w-3 text-white" />
            )}
          </div>
          <div className="flex flex-col min-w-0">
            <span className="text-[9px] font-black uppercase tracking-[0.18em] text-[#ff4d4d]">
              Community Service
            </span>
            <span className="text-[8px] font-bold uppercase tracking-wider text-[#a08890] truncate">
              {data.brand || "GRIM CITY"}
            </span>
          </div>
        </div>

        <div className="relative px-3 py-2.5 space-y-2.5">
          <div className="flex items-end justify-between gap-2">
            <div>
              <p className="text-[8px] font-bold uppercase tracking-wider text-[#a08890]">Remaining</p>
              <p className="text-xl font-black tabular-nums text-white leading-none mt-0.5">
                {data.remaining}
                <span className="text-xs font-bold text-[#a08890]"> / {data.total}</span>
              </p>
            </div>
            <div className="text-right">
              <p className="text-[8px] font-bold uppercase tracking-wider text-[#a08890]">Progress</p>
              <p className="text-base font-black tabular-nums text-[#ff4d4d] leading-none mt-0.5">{progress}%</p>
            </div>
          </div>

          <div className="h-1.5 w-full rounded-full bg-white/10 overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-500"
              style={{
                width: `${progress}%`,
                background: completedFlash
                  ? "linear-gradient(90deg, #34d399, #6ee7b7)"
                  : "linear-gradient(90deg, #b30000, #ff3a3a)",
              }}
            />
          </div>

          {data.reason ? (
            <div className="rounded-md border border-[#ff3a3a]/25 bg-[#181216] px-2 py-1.5">
              <p className="text-[7px] font-black uppercase tracking-wider text-[#a08890] mb-0.5">Reason</p>
              <p className="text-[10px] font-semibold text-white/85 leading-snug line-clamp-2">{data.reason}</p>
            </div>
          ) : null}

          <p className="text-[8px] font-medium text-[#a08890] text-center">
            Complete marked tasks in the service zone
          </p>
        </div>
      </div>
    </div>
  );
}
