import React, { useEffect } from "react";
import { X, ShieldCheck, Award } from "lucide-react";
import grimLogo from "@/assets/grim-city-logo.png";
import defaultAvatar from "@/assets/default-avatar.png";

export interface BadgeData {
  department?: string;
  rank?: string;
  firstName?: string;
  lastName?: string;
  badgeNumber?: string;
  jobName?: string;
  photoUrl?: string;
}

interface BadgeProps {
  visible?: boolean;
  data?: BadgeData;
  onClose?: () => void;
}

const DEFAULT_BADGE: BadgeData = {
  department: "LOS SANTOS POLICE DEPT",
  rank: "LIEUTENANT",
  firstName: "",
  lastName: "",
  badgeNumber: "LEO-0001",
  jobName: "police",
  photoUrl: ""
};

export const Badge: React.FC<BadgeProps> = ({
  visible = true,
  data = DEFAULT_BADGE,
  onClose
}) => {
  const badgeData = { ...DEFAULT_BADGE, ...data };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.key === "Backspace" || e.key === "Escape") && onClose) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onClose]);

  if (!visible) return null;

  const characterImage = badgeData.photoUrl && badgeData.photoUrl !== "" ? badgeData.photoUrl : defaultAvatar;
  const isSheriff = badgeData.jobName === "sheriff" || badgeData.jobName === "bcso" || (badgeData.department && badgeData.department.includes("SHERIFF"));

  return (
    <div 
      className="pandora fixed top-1/2 right-10 -translate-y-1/2 z-50 select-none animate-in fade-in slide-in-from-right-8 duration-300"
      style={{ perspective: "1000px" }}
    >
      {/* Outer Card Shell - Police / Sheriff Badge */}
      <div 
        className="relative w-[440px] rounded-2xl border-2 border-[#ff3a3a] overflow-hidden font-sans text-white bg-[#0d0d12]"
        style={{
          boxShadow: "0 22px 55px rgba(0, 0, 0, 0.95)",
        }}
      >
        
        {/* Top Border Glow Line */}
        <div 
          className="absolute top-0 left-0 right-0 h-[3px] bg-gradient-to-r from-[#ff3d96] via-[#35c7f2] to-[#ffd24c] shadow-[0_0_12px_rgba(53,199,242,0.6)]" 
        />

        {/* Close Button */}
        {onClose && (
          <button
            onClick={onClose}
            className="absolute top-2.5 right-2.5 z-10 p-1 rounded-full bg-[#35c7f2]/20 text-[#8fe4ff] hover:text-white hover:bg-[#35c7f2]/40 transition-all cursor-pointer opacity-70 hover:opacity-100"
            title="Close (ESC)"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        )}

        {/* Main Card Container */}
        <div className="p-4 space-y-3">
          
          {/* Header Section */}
          <div className="flex items-start justify-between border-b border-[#35c7f2]/25 pb-2.5">
            <div className="space-y-0.5">
              <span className="block text-[9px] font-black tracking-[0.22em] text-[#35c7f2] uppercase">
                {badgeData.department}
              </span>
              <h2 className="text-lg font-extrabold tracking-tight text-white uppercase drop-shadow-sm flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4 text-[#ffd24c]" />
                OFFICIAL BADGE ID
              </h2>
            </div>

            {/* Department Badge Tag */}
            <div className="flex items-center space-x-1.5 bg-[#35c7f2]/15 border border-[#35c7f2]/50 px-2.5 py-0.5 rounded-full shadow-[0_0_10px_rgba(53,199,242,0.15)]">
              <Award className="w-3 h-3 text-[#ffd24c]" />
              <span className="text-[9.5px] font-extrabold tracking-wider text-[#8fe4ff] uppercase">
                {isSheriff ? "SHERIFF" : "POLICE"}
              </span>
            </div>
          </div>

          {/* Card Body Content: Two Columns */}
          <div className="grid grid-cols-[130px_1fr] gap-4 items-stretch">
            
            {/* Left Column: Officer Mugshot Photograph */}
            <div className="relative w-[130px] h-[175px] bg-[#031120] rounded-xl border border-[#35c7f2]/35 overflow-hidden flex flex-col items-center justify-between shadow-md">
              <img
                src={characterImage}
                alt="Officer Photo"
                className="w-full h-full object-cover object-top"
              />
              
              {/* Overlay Strip */}
              <div className="absolute bottom-1 left-1 right-1 bg-[#05192f]/90 backdrop-blur-md py-0.5 px-0.5 rounded text-center border border-white/10 shadow">
                <span className="text-[8px] font-black tracking-[0.18em] text-[#ffd24c] uppercase">
                  OFFICER PORTRAIT
                </span>
              </div>
            </div>

            {/* Right Column: Officer Badge Details */}
            <div className="flex flex-col justify-between space-y-2 py-0.5">
              
              {/* Officer Full Name */}
              <div className="space-y-0.5">
                <span className="block text-[8.5px] font-extrabold tracking-widest text-[#35c7f2] uppercase">
                  OFFICER NAME
                </span>
                <p className="text-base font-black text-white tracking-wide">
                  {badgeData.firstName} {badgeData.lastName}
                </p>
              </div>

              {/* Rank / Grade */}
              <div className="space-y-0.5">
                <span className="block text-[8.5px] font-extrabold tracking-widest text-[#8fe4ff]/80 uppercase">
                  OFFICER RANK
                </span>
                <p className="text-sm font-extrabold text-[#ffd24c] tracking-wide uppercase">
                  {badgeData.rank}
                </p>
              </div>

              {/* Badge Number */}
              <div className="space-y-0.5">
                <span className="block text-[8.5px] font-extrabold tracking-widest text-[#8fe4ff]/80 uppercase">
                  BADGE NUMBER
                </span>
                <p className="text-xs font-black text-white tracking-widest font-mono">
                  {badgeData.badgeNumber}
                </p>
              </div>

              {/* Status & Department */}
              <div className="grid grid-cols-2 gap-3 pt-0.5">
                <div className="space-y-0.5">
                  <span className="block text-[8.5px] font-extrabold tracking-widest text-[#8fe4ff]/80 uppercase">
                    STATUS
                  </span>
                  <div className="flex items-center space-x-1">
                    <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                    <span className="text-xs font-extrabold text-emerald-300 uppercase">
                      ACTIVE DUTY
                    </span>
                  </div>
                </div>
                <div className="space-y-0.5">
                  <span className="block text-[8.5px] font-extrabold tracking-widest text-[#8fe4ff]/80 uppercase">
                    CLEARANCE
                  </span>
                  <p className="text-xs font-bold text-sky-200 uppercase">
                    LEVEL 4
                  </p>
                </div>
              </div>

            </div>
          </div>

          {/* Card Footer Section - Grim City Law Enforcement */}
          <div className="pt-2 border-t border-[#35c7f2]/25 flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <img src={grimLogo} alt="Grim City" className="h-4.5 w-4.5 object-contain" />
              <span className="text-[10px] font-black text-[#8fe4ff] tracking-[0.18em]">
                GRIM CITY LAW ENFORCEMENT
              </span>
            </div>

            <div className="flex items-center space-x-1.5">
              <div className="w-1.5 h-1.5 rounded-full bg-[#ffd24c] animate-pulse" />
              <span className="text-[8.5px] font-extrabold text-[#ffd24c] uppercase tracking-widest">
                VERIFIED BADGE
              </span>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
};

export default Badge;
