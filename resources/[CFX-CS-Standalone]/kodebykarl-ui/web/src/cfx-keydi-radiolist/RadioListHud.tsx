import React, { useState, useEffect, useRef } from "react";
import { Users, Move, Radio } from "lucide-react";
import { cn } from "@/lib/utils";

export interface RadioPlayer {
  id: number;
  serverId: number;
  name: string;
  self: boolean;
  talking: boolean;
}

interface RadioListHudProps {
  channel?: string | null;
  players?: RadioPlayer[];
  editMode?: boolean;
  hudVisible?: boolean;
  onExitEdit?: () => void;
}

const POS_KEY = "grim_radio_pos";
const LEGACY_POS_KEY = "pandora_radio_pos";

function loadPos() {
  const saved = localStorage.getItem(POS_KEY) || localStorage.getItem(LEGACY_POS_KEY);
  if (saved) {
    try {
      return JSON.parse(saved);
    } catch {
      /* ignore */
    }
  }
  return {
    x: window.innerWidth - 228,
    y: window.innerHeight / 2 - 100,
  };
}

export const RadioListHud: React.FC<RadioListHudProps> = ({
  channel = "100.0 MHz",
  players = [],
  editMode = false,
  hudVisible = true,
}) => {
  const [pos, setPos] = useState(loadPos);

  const dragRef = useRef({
    down: false,
    sx: 0,
    sy: 0,
    bx: 0,
    by: 0,
  });

  const startDrag = (e: React.MouseEvent) => {
    if (!editMode) return;
    dragRef.current.down = true;
    dragRef.current.sx = e.clientX;
    dragRef.current.sy = e.clientY;
    dragRef.current.bx = pos.x;
    dragRef.current.by = pos.y;
  };

  useEffect(() => {
    const onMouseMove = (e: MouseEvent) => {
      if (!dragRef.current.down) return;
      const dx = e.clientX - dragRef.current.sx;
      const dy = e.clientY - dragRef.current.sy;
      setPos({ x: dragRef.current.bx + dx, y: dragRef.current.by + dy });
    };

    const onMouseUp = () => {
      if (!dragRef.current.down) return;
      dragRef.current.down = false;
      localStorage.setItem(POS_KEY, JSON.stringify(pos));
    };

    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseup", onMouseUp);
    return () => {
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("mouseup", onMouseUp);
    };
  }, [pos]);

  if (!hudVisible && !editMode) return null;

  const activeTalkers = players.filter((p) => p.talking);

  return (
    <div
      style={{ left: pos.x, top: pos.y }}
      className={cn(
        "pandora fixed z-[9990] w-48 select-none font-sans transition-shadow",
        editMode && "cursor-grab ring-2 ring-[#ff3a3a] ring-offset-2 ring-offset-black/50",
      )}
      onMouseDown={startDrag}
    >
      <div
        className="relative overflow-hidden rounded-xl border-2 border-[#ff3a3a] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.95)]"
        style={{ background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)" }}
      >
        <div className="panel-grid pointer-events-none absolute inset-0 opacity-30" />

        <div
          className="relative flex items-center justify-between gap-2 px-3 py-2"
          style={{ borderBottom: "1px solid rgba(255, 58, 58, 0.25)" }}
        >
          <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/15">
            <Radio className="h-3 w-3 text-white" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-[9px] font-black uppercase tracking-[0.18em] text-[#ff4d4d]">Radio</p>
            <p className="truncate text-[8px] font-bold uppercase tracking-wider text-[#a08890]">
              {channel || "—"}
            </p>
          </div>
        </div>

        <div className="relative space-y-1.5 px-3 py-2 min-h-[36px] max-h-36 overflow-y-auto">
          {activeTalkers.length > 0 ? (
            activeTalkers.map((p) => (
              <div key={p.id} className="flex items-center justify-between gap-1.5">
                <div className="flex min-w-0 items-center gap-2">
                  <div className="relative flex shrink-0 items-center justify-center">
                    <div className="h-2 w-2 rounded-full bg-[#ff3a3a] shadow-[0_0_8px_#ff3a3a]" />
                    <div className="absolute h-4 w-4 rounded-full border border-[#ff3a3a]/70 animate-ping" />
                  </div>
                  <span className="max-w-[95px] truncate text-[11px] font-bold text-white">
                    {p.name}
                  </span>
                </div>
                <span className="shrink-0 text-[9px] font-black uppercase tracking-wider text-[#ff4d4d]">
                  TNC
                </span>
              </div>
            ))
          ) : (
            <div className="py-1 text-center text-[10px] font-semibold italic text-[#a08890]">
              {editMode ? "Drag to reposition HUD" : "No active talkers"}
            </div>
          )}
        </div>

        <div
          className="relative flex items-center justify-between px-3 py-1.5 text-[10px]"
          style={{ borderTop: "1px solid rgba(255, 58, 58, 0.25)" }}
        >
          {editMode ? (
            <span className="flex items-center gap-1 text-[9px] font-black uppercase tracking-wider text-[#ff4d4d]">
              <Move className="h-3 w-3" /> Drag mode
            </span>
          ) : (
            <span className="text-[9px] font-black uppercase tracking-[0.16em] text-[#a08890]">
              Grim City
            </span>
          )}

          <div className="flex items-center gap-1 font-extrabold text-[#ff4d4d]">
            <Users className="h-3 w-3" />
            <span>{players.length}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RadioListHud;
