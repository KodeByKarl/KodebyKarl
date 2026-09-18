import React from "react";

export type BadgeType =
  | "owner"
  | "developer"
  | "superadmin"
  | "admin"
  | "vip5"
  | "vip4"
  | "vip3"
  | "vip2"
  | "vip1";

interface BadgeIconProps {
  type: BadgeType;
  size?: number;
  className?: string;
  showGlow?: boolean;
}

export const Badges: React.FC<BadgeIconProps> = ({
  type,
  size = 64,
  className = "",
  showGlow = true,
}) => {
  const s = size;

  switch (type) {
    case "owner":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_12px_rgba(255,183,3,0.5)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="goldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#fff2a3" />
              <stop offset="30%" stopColor="#ffd700" />
              <stop offset="70%" stopColor="#d4af37" />
              <stop offset="100%" stopColor="#8a6700" />
            </linearGradient>
            <linearGradient id="rubyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#ff4d6d" />
              <stop offset="50%" stopColor="#c9184a" />
              <stop offset="100%" stopColor="#590d22" />
            </linearGradient>
            <filter id="ownerGlow" x="-20%" y="-20%" width="140%" height="140%">
              <feGaussianBlur stdDeviation="3" result="blur" />
              <feComposite in="SourceGraphic" in2="blur" operator="over" />
            </filter>
          </defs>
          {/* Wings */}
          <path
            d="M 12 48 C 5 35 15 22 30 25 C 22 34 26 44 32 48 C 22 50 18 42 12 48 Z"
            fill="url(#goldGrad)"
            opacity="0.9"
          />
          <path
            d="M 88 48 C 95 35 85 22 70 25 C 78 34 74 44 68 48 C 78 50 82 42 88 48 Z"
            fill="url(#goldGrad)"
            opacity="0.9"
          />
          {/* Main Shield */}
          <path
            d="M 50 12 L 78 24 C 78 58 50 82 50 88 C 50 82 22 58 22 24 Z"
            fill="url(#rubyGrad)"
            stroke="url(#goldGrad)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* Inner Shield */}
          <path
            d="M 50 20 L 71 30 C 71 55 50 74 50 78 C 50 74 29 55 29 30 Z"
            fill="#20050c"
            stroke="url(#goldGrad)"
            strokeWidth="1.5"
            opacity="0.85"
          />
          {/* Imperial Crown */}
          <path
            d="M 37 46 L 40 33 L 46 39 L 50 28 L 54 39 L 60 33 L 63 46 Z"
            fill="url(#goldGrad)"
            stroke="#fff"
            strokeWidth="0.8"
          />
          {/* Crown Jewels */}
          <circle cx="50" cy="28" r="1.8" fill="#fff" />
          <circle cx="40" cy="33" r="1.4" fill="#ff4d6d" />
          <circle cx="60" cy="33" r="1.4" fill="#ff4d6d" />
          {/* Star Gem */}
          <polygon
            points="50,50 52,56 58,56 53,60 55,66 50,62 45,66 47,60 42,56 48,56"
            fill="url(#goldGrad)"
          />
          {/* Label Banner */}
          <rect x="26" y="70" width="48" height="12" rx="3" fill="#120205" stroke="url(#goldGrad)" strokeWidth="1.2" />
          <text x="50" y="79" fill="url(#goldGrad)" fontSize="7" fontWeight="900" textAnchor="middle" letterSpacing="0.8">
            OWNER
          </text>
        </svg>
      );

    case "developer":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_12px_rgba(0,240,255,0.5)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="cyberCyan" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#a5f3fc" />
              <stop offset="40%" stopColor="#00f0ff" />
              <stop offset="100%" stopColor="#0284c7" />
            </linearGradient>
            <linearGradient id="cyberPurple" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#c084fc" />
              <stop offset="50%" stopColor="#7e22ce" />
              <stop offset="100%" stopColor="#3b0764" />
            </linearGradient>
          </defs>
          {/* Outer Circuit Nodes */}
          <line x1="20" y1="50" x2="30" y2="50" stroke="#00f0ff" strokeWidth="2" strokeDasharray="2,2" />
          <line x1="80" y1="50" x2="70" y2="50" stroke="#00f0ff" strokeWidth="2" strokeDasharray="2,2" />
          <line x1="50" y1="12" x2="50" y2="20" stroke="#c084fc" strokeWidth="2" />
          {/* Hexagonal Base */}
          <polygon
            points="50,15 82,32 82,68 50,85 18,68 18,32"
            fill="url(#cyberPurple)"
            stroke="url(#cyberCyan)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* Inner Tech Core */}
          <polygon
            points="50,22 75,36 75,64 50,78 25,64 25,36"
            fill="#050a14"
            stroke="#00f0ff"
            strokeWidth="1.2"
            opacity="0.9"
          />
          {/* Terminal Code Brackets < / > */}
          <path
            d="M 40 40 L 33 48 L 40 56"
            stroke="#00f0ff"
            strokeWidth="3"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M 60 40 L 67 48 L 60 56"
            stroke="#00f0ff"
            strokeWidth="3"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <line x1="53" y1="38" x2="47" y2="58" stroke="#c084fc" strokeWidth="2.5" strokeLinecap="round" />
          {/* Bottom Badge Banner */}
          <rect x="24" y="69" width="52" height="12" rx="3" fill="#030712" stroke="#00f0ff" strokeWidth="1.2" />
          <text x="50" y="78" fill="#00f0ff" fontSize="6.5" fontWeight="900" textAnchor="middle" letterSpacing="0.6">
            DEVELOPER
          </text>
        </svg>
      );

    case "superadmin":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_12px_rgba(168,85,247,0.5)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="amethystGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#f472b6" />
              <stop offset="50%" stopColor="#9333ea" />
              <stop offset="100%" stopColor="#4c1d95" />
            </linearGradient>
            <linearGradient id="platinumGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#ffffff" />
              <stop offset="50%" stopColor="#cbd5e1" />
              <stop offset="100%" stopColor="#64748b" />
            </linearGradient>
          </defs>
          {/* Flaming Wing Accents */}
          <path d="M 16 45 C 8 32 20 20 32 24 C 24 32 28 42 34 46 Z" fill="url(#amethystGrad)" opacity="0.8" />
          <path d="M 84 45 C 92 32 80 20 68 24 C 76 32 72 42 66 46 Z" fill="url(#amethystGrad)" opacity="0.8" />
          {/* Main Diamond Shield */}
          <path
            d="M 50 14 L 78 26 C 78 58 50 82 50 88 C 50 82 22 58 22 26 Z"
            fill="url(#amethystGrad)"
            stroke="url(#platinumGrad)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* Inner Dark Chamber */}
          <path
            d="M 50 22 L 71 32 C 71 56 50 74 50 78 C 50 74 29 56 29 32 Z"
            fill="#130722"
            stroke="url(#platinumGrad)"
            strokeWidth="1.2"
          />
          {/* 4-Pointed Star Core */}
          <path
            d="M 50 32 L 53 43 L 64 46 L 53 49 L 50 60 L 47 49 L 36 46 L 47 43 Z"
            fill="url(#platinumGrad)"
          />
          <circle cx="50" cy="46" r="3" fill="#f472b6" />
          {/* Banner */}
          <rect x="22" y="70" width="56" height="12" rx="3" fill="#090212" stroke="url(#platinumGrad)" strokeWidth="1.2" />
          <text x="50" y="79" fill="#f472b6" fontSize="6" fontWeight="900" textAnchor="middle" letterSpacing="0.4">
            SUPERADMIN
          </text>
        </svg>
      );

    case "admin":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_12px_rgba(16,185,129,0.5)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="emeraldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#6ee7b7" />
              <stop offset="40%" stopColor="#10b981" />
              <stop offset="100%" stopColor="#064e3b" />
            </linearGradient>
            <linearGradient id="silverTrim" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#ffffff" />
              <stop offset="60%" stopColor="#94a3b8" />
              <stop offset="100%" stopColor="#475569" />
            </linearGradient>
          </defs>
          {/* Shield */}
          <path
            d="M 50 14 L 78 26 C 78 58 50 82 50 88 C 50 82 22 58 22 26 Z"
            fill="url(#emeraldGrad)"
            stroke="url(#silverTrim)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* Inner Inset */}
          <path
            d="M 50 22 L 71 32 C 71 56 50 74 50 78 C 50 74 29 56 29 32 Z"
            fill="#031a13"
            stroke="url(#silverTrim)"
            strokeWidth="1.2"
          />
          {/* Eagle / Star Wings */}
          <polygon
            points="50,34 54,44 64,44 56,50 59,60 50,54 41,60 44,50 36,44 46,44"
            fill="url(#silverTrim)"
          />
          {/* Banner */}
          <rect x="27" y="70" width="46" height="12" rx="3" fill="#02150f" stroke="url(#silverTrim)" strokeWidth="1.2" />
          <text x="50" y="79" fill="#34d399" fontSize="7" fontWeight="900" textAnchor="middle" letterSpacing="0.8">
            ADMIN
          </text>
        </svg>
      );

    case "vip5":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_14px_rgba(236,72,153,0.6)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="vip5Grad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#fbcfe8" />
              <stop offset="35%" stopColor="#ec4899" />
              <stop offset="70%" stopColor="#8b5cf6" />
              <stop offset="100%" stopColor="#3b0764" />
            </linearGradient>
            <linearGradient id="vipGold" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#fff" />
              <stop offset="40%" stopColor="#ffd700" />
              <stop offset="100%" stopColor="#b45309" />
            </linearGradient>
          </defs>
          {/* Majestic Mythic Wings */}
          <path d="M 10 46 C 2 30 16 16 32 20 C 22 30 26 42 34 46 Z" fill="url(#vipGold)" opacity="0.9" />
          <path d="M 90 46 C 98 30 84 16 68 20 C 78 30 74 42 66 46 Z" fill="url(#vipGold)" opacity="0.9" />
          {/* Diamond Shield */}
          <path
            d="M 50 14 L 78 26 C 78 58 50 82 50 88 C 50 82 22 58 22 26 Z"
            fill="url(#vip5Grad)"
            stroke="url(#vipGold)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* 5 Stars Array */}
          <g fill="url(#vipGold)" transform="translate(0, -2)">
            <polygon points="32,38 33,42 37,42 34,44 35,48 32,46 29,48 30,44 27,42 31,42" />
            <polygon points="41,33 42,37 46,37 43,39 44,43 41,41 38,43 39,39 36,37 40,37" />
            <polygon points="50,30 51.5,35 56.5,35 52.5,38 54,43 50,40 46,43 47.5,38 43.5,35 48.5,35" />
            <polygon points="59,33 60,37 64,37 61,39 62,43 59,41 56,43 57,39 54,37 58,37" />
            <polygon points="68,38 69,42 73,42 70,44 71,48 68,46 65,48 66,44 63,42 67,42" />
          </g>
          {/* Diamond Prism Emblem */}
          <polygon points="50,46 60,54 50,65 40,54" fill="#fff" opacity="0.85" />
          <polygon points="50,46 50,65 40,54" fill="url(#vip5Grad)" opacity="0.6" />
          {/* Banner */}
          <rect x="25" y="70" width="50" height="12" rx="3" fill="#18041c" stroke="url(#vipGold)" strokeWidth="1.2" />
          <text x="50" y="79" fill="url(#vipGold)" fontSize="7" fontWeight="900" textAnchor="middle" letterSpacing="0.8">
            VIP 5
          </text>
        </svg>
      );

    case "vip4":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_12px_rgba(245,158,11,0.5)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="vip4Grad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#fef08a" />
              <stop offset="40%" stopColor="#eab308" />
              <stop offset="100%" stopColor="#713f12" />
            </linearGradient>
          </defs>
          <path d="M 12 46 C 6 32 18 20 32 24 C 24 32 28 42 34 46 Z" fill="url(#vip4Grad)" opacity="0.8" />
          <path d="M 88 46 C 94 32 82 20 68 24 C 76 32 72 42 66 46 Z" fill="url(#vip4Grad)" opacity="0.8" />
          <path
            d="M 50 14 L 78 26 C 78 58 50 82 50 88 C 50 82 22 58 22 26 Z"
            fill="#1e1302"
            stroke="url(#vip4Grad)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* 4 Stars */}
          <g fill="url(#vip4Grad)">
            <polygon points="36,34 37,38 41,38 38,40 39,44 36,42 33,44 34,40 31,38 35,38" />
            <polygon points="45,31 46,35 50,35 47,37 48,41 45,39 42,41 43,37 40,35 44,35" />
            <polygon points="55,31 56,35 60,35 57,37 58,41 55,39 52,41 53,37 50,35 54,35" />
            <polygon points="64,34 65,38 69,38 66,40 67,44 64,42 61,44 62,40 59,38 63,38" />
          </g>
          {/* Center Crown Glyph */}
          <path d="M 40 58 L 44 48 L 50 53 L 56 48 L 60 58 Z" fill="url(#vip4Grad)" />
          {/* Banner */}
          <rect x="25" y="70" width="50" height="12" rx="3" fill="#120b02" stroke="url(#vip4Grad)" strokeWidth="1.2" />
          <text x="50" y="79" fill="url(#vip4Grad)" fontSize="7" fontWeight="900" textAnchor="middle" letterSpacing="0.8">
            VIP 4
          </text>
        </svg>
      );

    case "vip3":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_12px_rgba(5,150,105,0.5)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="vip3Emerald" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#a7f3d0" />
              <stop offset="40%" stopColor="#10b981" />
              <stop offset="100%" stopColor="#047857" />
            </linearGradient>
            <linearGradient id="vip3Gold" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#fef08a" />
              <stop offset="100%" stopColor="#ca8a04" />
            </linearGradient>
          </defs>
          <path
            d="M 50 14 L 78 26 C 78 58 50 82 50 88 C 50 82 22 58 22 26 Z"
            fill="#031a12"
            stroke="url(#vip3Emerald)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* 3 Stars */}
          <g fill="url(#vip3Gold)">
            <polygon points="38,34 39,39 44,39 40,42 42,47 38,44 34,47 36,42 32,39 37,39" />
            <polygon points="50,30 51.5,35 56.5,35 52.5,38 54,43 50,40 46,43 47.5,38 43.5,35 48.5,35" />
            <polygon points="62,34 63,39 68,39 64,42 66,47 62,44 58,47 60,42 56,39 61,39" />
          </g>
          {/* Shield Emblem */}
          <polygon points="50,50 58,58 50,66 42,58" fill="url(#vip3Emerald)" />
          {/* Banner */}
          <rect x="25" y="70" width="50" height="12" rx="3" fill="#02130d" stroke="url(#vip3Emerald)" strokeWidth="1.2" />
          <text x="50" y="79" fill="#34d399" fontSize="7" fontWeight="900" textAnchor="middle" letterSpacing="0.8">
            VIP 3
          </text>
        </svg>
      );

    case "vip2":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_12px_rgba(59,130,246,0.5)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="vip2Sapphire" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#93c5fd" />
              <stop offset="40%" stopColor="#3b82f6" />
              <stop offset="100%" stopColor="#1e3a8a" />
            </linearGradient>
            <linearGradient id="vip2Silver" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#ffffff" />
              <stop offset="100%" stopColor="#94a3b8" />
            </linearGradient>
          </defs>
          <path
            d="M 50 14 L 78 26 C 78 58 50 82 50 88 C 50 82 22 58 22 26 Z"
            fill="#031024"
            stroke="url(#vip2Sapphire)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* 2 Stars */}
          <g fill="url(#vip2Silver)">
            <polygon points="42,32 43.5,37 48.5,37 44.5,40 46,45 42,42 38,45 39.5,40 35.5,37 40.5,37" />
            <polygon points="58,32 59.5,37 64.5,37 60.5,40 62,45 58,42 54,45 55.5,40 51.5,37 56.5,37" />
          </g>
          {/* Crest */}
          <polygon points="50,48 57,56 50,64 43,56" fill="url(#vip2Sapphire)" />
          {/* Banner */}
          <rect x="25" y="70" width="50" height="12" rx="3" fill="#020a17" stroke="url(#vip2Sapphire)" strokeWidth="1.2" />
          <text x="50" y="79" fill="#60a5fa" fontSize="7" fontWeight="900" textAnchor="middle" letterSpacing="0.8">
            VIP 2
          </text>
        </svg>
      );

    case "vip1":
      return (
        <svg
          width={s}
          height={s}
          viewBox="0 0 100 100"
          className={`shrink-0 drop-shadow-[0_4px_12px_rgba(217,119,6,0.5)] ${className}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="vip1Bronze" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#fed7aa" />
              <stop offset="40%" stopColor="#f59e0b" />
              <stop offset="100%" stopColor="#78350f" />
            </linearGradient>
          </defs>
          <path
            d="M 50 14 L 78 26 C 78 58 50 82 50 88 C 50 82 22 58 22 26 Z"
            fill="#170d03"
            stroke="url(#vip1Bronze)"
            strokeWidth="3.5"
            strokeLinejoin="round"
          />
          {/* 1 Radiant Center Star */}
          <polygon
            points="50,30 52.5,38 60.5,38 54,43 56.5,51 50,46 43.5,51 46,43 39.5,38 47.5,38"
            fill="url(#vip1Bronze)"
          />
          {/* Laurel Accent */}
          <path d="M 36 56 C 42 62 58 62 64 56" stroke="url(#vip1Bronze)" strokeWidth="2" fill="none" strokeLinecap="round" />
          {/* Banner */}
          <rect x="25" y="70" width="50" height="12" rx="3" fill="#0f0802" stroke="url(#vip1Bronze)" strokeWidth="1.2" />
          <text x="50" y="79" fill="#fbbf24" fontSize="7" fontWeight="900" textAnchor="middle" letterSpacing="0.8">
            VIP 1
          </text>
        </svg>
      );
  }
};

export default Badges;
