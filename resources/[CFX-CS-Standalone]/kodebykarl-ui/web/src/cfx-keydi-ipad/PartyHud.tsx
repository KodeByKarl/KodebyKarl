import { useCallback, useEffect, useRef, useState } from "react";
import { Heart, Move, Shield } from "lucide-react";
import { isBrowserEnv } from "@/lib/nui";
import { cn } from "@/lib/utils";

type PartyMemberHud = {
  slot: number;
  name: string;
  leader?: boolean;
  online?: boolean;
  health?: number;
  armor?: number;
};

type PartyHudData = {
  visible?: boolean;
  name?: string;
  count?: number;
  max?: number;
  members?: PartyMemberHud[];
};

const PREVIEW: PartyHudData = {
  visible: true,
  name: "Night Crew",
  count: 2,
  max: 4,
  members: [
    { slot: 1, name: "Kosel Carpio", leader: true, online: true, health: 92, armor: 0 },
    { slot: 2, name: "Mia Storm", leader: false, online: true, health: 64, armor: 40 },
  ],
};

const POS_KEY = "grim_party_hud_pos";
const HUD_W = 210;

function loadPos() {
  try {
    const saved = localStorage.getItem(POS_KEY);
    if (saved) {
      const parsed = JSON.parse(saved);
      if (typeof parsed?.x === "number" && typeof parsed?.y === "number") {
        return parsed as { x: number; y: number };
      }
    }
  } catch {
    /* ignore */
  }
  return {
    x: Math.max(16, window.innerWidth - HUD_W - 16),
    y: Math.max(80, Math.round(window.innerHeight / 2 - 90)),
  };
}

function clampPos(x: number, y: number) {
  const maxX = Math.max(8, window.innerWidth - HUD_W - 8);
  const maxY = Math.max(8, window.innerHeight - 80);
  return {
    x: Math.min(maxX, Math.max(8, x)),
    y: Math.min(maxY, Math.max(8, y)),
  };
}

function getResourceName() {
  return (window as any).GetParentResourceName ? (window as any).GetParentResourceName() : "kodebykarl-ui";
}

function Ring({ value, color, size = 24, stroke = 2.5 }: { value: number; color: string; size?: number; stroke?: number }) {
  const pct = Math.max(0, Math.min(100, value));
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const dash = (pct / 100) * c;
  return (
    <svg width={size} height={size} className="-rotate-90">
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={stroke} />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        fill="none"
        stroke={color}
        strokeWidth={stroke}
        strokeLinecap="round"
        strokeDasharray={`${dash} ${c}`}
      />
    </svg>
  );
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

type PartyHudProps = {
  editMode?: boolean;
  onExitEdit?: () => void;
};

export default function PartyHud({ editMode = false, onExitEdit }: PartyHudProps) {
  const [data, setData] = useState<PartyHudData | null>(() => {
    if (isBrowserEnv() && new URLSearchParams(window.location.search).get("preview") === "party") {
      return PREVIEW;
    }
    return null;
  });
  const [pos, setPos] = useState(loadPos);
  const dragRef = useRef({ down: false, sx: 0, sy: 0, bx: 0, by: 0 });
  const posRef = useRef(pos);
  posRef.current = pos;

  useEffect(() => {
    const onMsg = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg || msg.action !== "cfx-keydi-ipad:party:hud") return;
      const payload = (msg.data || {}) as PartyHudData;
      if (!payload.visible) {
        setData(null);
        return;
      }
      setData(payload);
    };
    window.addEventListener("message", onMsg);
    return () => window.removeEventListener("message", onMsg);
  }, []);

  const endEdit = useCallback(() => {
    onExitEdit?.();
    if (isBrowserEnv()) return;
    fetch(`https://${getResourceName()}/cfx-keydi-ipad:party:stopDrag`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({}),
    }).catch(() => {});
  }, [onExitEdit]);

  const startDrag = (e: React.MouseEvent) => {
    if (!editMode) return;
    e.preventDefault();
    dragRef.current.down = true;
    dragRef.current.sx = e.clientX;
    dragRef.current.sy = e.clientY;
    dragRef.current.bx = pos.x;
    dragRef.current.by = pos.y;
  };

  useEffect(() => {
    if (!editMode) return;

    const onMouseMove = (e: MouseEvent) => {
      if (!dragRef.current.down) return;
      const dx = e.clientX - dragRef.current.sx;
      const dy = e.clientY - dragRef.current.sy;
      setPos(clampPos(dragRef.current.bx + dx, dragRef.current.by + dy));
    };

    const onMouseUp = () => {
      if (!dragRef.current.down) return;
      dragRef.current.down = false;
      localStorage.setItem(POS_KEY, JSON.stringify(posRef.current));
    };

    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        localStorage.setItem(POS_KEY, JSON.stringify(posRef.current));
        endEdit();
      }
    };

    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseup", onMouseUp);
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("mouseup", onMouseUp);
      window.removeEventListener("keydown", onKey);
    };
  }, [editMode, endEdit]);

  if ((!data?.visible || !data.members?.length) && !editMode) return null;

  const members = data?.members || PREVIEW.members || [];
  const max = data?.max || 4;
  const count = data?.count || members.length;

  return (
    <div
      className={cn(
        "fixed z-[99980] w-[210px] select-none",
        editMode ? "pointer-events-auto cursor-grab active:cursor-grabbing" : "pointer-events-none",
      )}
      style={{ left: pos.x, top: pos.y, fontFamily: "'Outfit', sans-serif" }}
      onMouseDown={startDrag}
    >
      <div
        className={cn("overflow-hidden", editMode && "ring-2 ring-[#ff3a3a] ring-offset-2 ring-offset-black/40")}
        style={{
          background: "linear-gradient(180deg, rgba(22,12,14,0.94) 0%, rgba(10,8,10,0.96) 100%)",
          clipPath: "polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px)",
          borderLeft: "3px solid #ff3a3a",
        }}
      >
        <div className="flex items-end justify-between px-2.5 pb-1 pt-2">
          <div className="min-w-0">
            <p className="text-[8px] font-semibold uppercase tracking-[0.2em] text-white/35">Grim Squad</p>
            <p className="truncate text-[12px] font-bold leading-tight text-white">{data?.name || "Squad"}</p>
          </div>
          <p className="shrink-0 text-[9px] font-semibold tabular-nums text-[#ff8080]">
            {count}
            <span className="text-white/30"> · {max}</span>
          </p>
        </div>

        {editMode && (
          <div className="flex items-center gap-1 px-2.5 pb-1.5 text-[8px] font-black uppercase tracking-wider text-[#ff8080]">
            <Move className="h-3 w-3" />
            Drag · ESC to save
          </div>
        )}

        <div className="space-y-px">
          {members.slice(0, max).map((m) => {
            const hp = m.online ? m.health || 0 : 0;
            const ar = m.online ? m.armor || 0 : 0;
            return (
              <div key={`${m.slot}-${m.name}`} className="flex items-center gap-2 px-2.5 py-1.5">
                <div
                  className="relative flex h-7 w-7 shrink-0 items-center justify-center text-[9px] font-bold"
                  style={{
                    background: m.online ? "rgba(255,58,58,0.18)" : "rgba(255,255,255,0.04)",
                    color: m.online ? "#ffb4b4" : "rgba(255,255,255,0.28)",
                    clipPath: "polygon(5px 0, 100% 0, 100% calc(100% - 5px), calc(100% - 5px) 100%, 0 100%, 0 5px)",
                  }}
                >
                  {initials(m.name)}
                </div>
                <div className="min-w-0 flex-1">
                  <p className={`truncate text-[11px] font-semibold leading-tight ${m.online ? "text-white" : "text-white/30"}`}>
                    {m.name}
                  </p>
                  <p className="text-[8px] font-medium uppercase tracking-wider text-white/30">
                    {m.leader ? "Host" : "Member"}
                    {m.online ? "" : " · Away"}
                  </p>
                </div>
                <div className="flex items-center gap-1">
                  <div className="relative">
                    <Ring value={hp} color="#ff3a3a" />
                    <Heart className="absolute left-1/2 top-1/2 h-2 w-2 -translate-x-1/2 -translate-y-1/2 text-[#ff3a3a]" />
                  </div>
                  <div className="relative">
                    <Ring value={ar} color="#8ea4c8" />
                    <Shield className="absolute left-1/2 top-1/2 h-2 w-2 -translate-x-1/2 -translate-y-1/2 text-[#8ea4c8]" />
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
