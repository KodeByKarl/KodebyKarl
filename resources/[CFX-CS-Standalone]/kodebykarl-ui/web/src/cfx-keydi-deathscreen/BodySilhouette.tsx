import { cn } from "@/lib/utils";
import type { BodyHits, BodyZone } from "./types";

const ZONES: BodyZone[] = ["head", "neck", "torso", "arms", "legs"];

function heat(hits: number, max: number) {
  if (hits <= 0 || max <= 0) return 0.18;
  return Math.min(1, 0.25 + (hits / max) * 0.85);
}

interface BodySilhouetteProps {
  hits: BodyHits;
  className?: string;
}

export default function BodySilhouette({ hits, className }: BodySilhouetteProps) {
  const max = Math.max(1, ...ZONES.map((z) => hits[z] || 0));

  return (
    <svg
      viewBox="0 0 120 220"
      className={cn("h-full w-auto drop-shadow-[0_0_12px_rgba(255,58,58,0.25)]", className)}
      aria-hidden
    >
      {/* Head */}
      <circle
        cx="60"
        cy="28"
        r="20"
        fill={`rgba(180,180,190,${heat(hits.head, max)})`}
        stroke={hits.head > 0 ? "#ff3a3a" : "rgba(255,255,255,0.15)"}
        strokeWidth="2"
      />
      {/* Neck */}
      <rect
        x="52"
        y="48"
        width="16"
        height="14"
        rx="3"
        fill={`rgba(180,180,190,${heat(hits.neck, max)})`}
        stroke={hits.neck > 0 ? "#ff3a3a" : "rgba(255,255,255,0.12)"}
        strokeWidth="1.5"
      />
      {/* Torso */}
      <rect
        x="34"
        y="62"
        width="52"
        height="70"
        rx="10"
        fill={`rgba(180,180,190,${heat(hits.torso, max)})`}
        stroke={hits.torso > 0 ? "#ff3a3a" : "rgba(255,255,255,0.12)"}
        strokeWidth="2"
      />
      {/* Arms */}
      <rect
        x="8"
        y="68"
        width="22"
        height="58"
        rx="8"
        fill={`rgba(180,180,190,${heat(hits.arms, max)})`}
        stroke={hits.arms > 0 ? "#ff3a3a" : "rgba(255,255,255,0.12)"}
        strokeWidth="1.5"
      />
      <rect
        x="90"
        y="68"
        width="22"
        height="58"
        rx="8"
        fill={`rgba(180,180,190,${heat(hits.arms, max)})`}
        stroke={hits.arms > 0 ? "#ff3a3a" : "rgba(255,255,255,0.12)"}
        strokeWidth="1.5"
      />
      {/* Legs */}
      <rect
        x="36"
        y="134"
        width="20"
        height="70"
        rx="8"
        fill={`rgba(180,180,190,${heat(hits.legs, max)})`}
        stroke={hits.legs > 0 ? "#ff3a3a" : "rgba(255,255,255,0.12)"}
        strokeWidth="1.5"
      />
      <rect
        x="64"
        y="134"
        width="20"
        height="70"
        rx="8"
        fill={`rgba(180,180,190,${heat(hits.legs, max)})`}
        stroke={hits.legs > 0 ? "#ff3a3a" : "rgba(255,255,255,0.12)"}
        strokeWidth="1.5"
      />
      {/* Ground glow */}
      <ellipse cx="60" cy="210" rx="36" ry="6" fill="rgba(255,58,58,0.35)" />
    </svg>
  );
}
