import { useEffect, useState } from "react";

export interface Me3DBubble {
  id: string;
  text: string;
  x: number;
  y: number;
  scale?: number;
  opacity?: number;
}

interface Me3DProps {
  previewBubbles?: Me3DBubble[];
}

export default function Me3D({ previewBubbles }: Me3DProps) {
  const [bubbles, setBubbles] = useState<Me3DBubble[]>(previewBubbles || []);

  useEffect(() => {
    if (previewBubbles) {
      setBubbles(previewBubbles);
      return;
    }

    const onMessage = (event: MessageEvent) => {
      const data = event.data;
      if (!data || data.action !== "me3d:sync") return;
      setBubbles(Array.isArray(data.bubbles) ? data.bubbles : []);
    };

    window.addEventListener("message", onMessage);
    return () => window.removeEventListener("message", onMessage);
  }, [previewBubbles]);

  if (bubbles.length === 0) return null;

  return (
    <div className="pointer-events-none fixed inset-0 z-[70] h-full w-full overflow-hidden select-none">
      {bubbles.map((bubble) => (
        <div
          key={bubble.id}
          className="absolute will-change-transform"
          style={{
            left: `${(bubble.x || 0) * 100}%`,
            top: `${(bubble.y || 0) * 100}%`,
            opacity: bubble.opacity ?? 1,
            transform: `translate(-50%, calc(-100% - 10px)) scale(${bubble.scale ?? 1})`,
            transformOrigin: "bottom center",
          }}
        >
          <div className="me3d-card max-w-[280px] rounded-lg border border-[#ff3a3a]/20 border-l-[3px] border-l-[#ff3a3a] px-3 py-2 shadow-[0_10px_28px_rgba(0,0,0,0.55)]">
            <div className="flex items-center gap-1.5">
              <span className="h-1.5 w-1.5 rounded-full bg-[#ff3a3a]" />
              <span className="font-['Outfit',sans-serif] text-[9px] font-black tracking-[0.22em] text-[#ff3a3a]">
                ME
              </span>
            </div>
            <p className="mt-1 font-['Outfit',sans-serif] text-[12px] font-medium italic leading-snug text-white/95 break-words">
              {bubble.text}
            </p>
          </div>
        </div>
      ))}
    </div>
  );
}
