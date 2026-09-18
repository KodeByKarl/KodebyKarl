import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Play,
  Pause,
  Square,
  SkipBack,
  SkipForward,
  Volume2,
  VolumeX,
  Music,
  ListMusic,
  Sparkles,
  X,
} from "lucide-react";
import grimBanner from "@/assets/grim-loading-banner.png";
import grimLogo from "@/assets/grim-city-logo.png";
import grimTrack from "@/assets/music.mp3";

export interface Track {
  id: string;
  title: string;
  artist: string;
  cover: string;
  url: string;
  duration: number;
}

type StaffMember = {
  id: string;
  name: string;
  avatar: string;
  role: string;
};

type HandoverPayload = {
  serverName?: string;
  music?: { title?: string; artist?: string };
  staff?: Record<string, { id?: string; name?: string; avatar?: string }[]>;
  roleOrder?: string[];
  roles?: Record<string, string>;
};

const DEFAULT_STEPS = [
  "Connecting to Grim City...",
  "Loading streets and interiors...",
  "Streaming vehicles...",
  "Syncing identity...",
  "Entering Grim City...",
];

const PREVIEW_STAFF: StaffMember[] = [
  { id: "1", name: "Karl", avatar: "https://cdn.discordapp.com/embed/avatars/1.png", role: "Owner" },
  { id: "2", name: "Dev Unit", avatar: "https://cdn.discordapp.com/embed/avatars/2.png", role: "Developer" },
  { id: "3", name: "Vex", avatar: "https://cdn.discordapp.com/embed/avatars/3.png", role: "Gods" },
  { id: "4", name: "Nova", avatar: "https://cdn.discordapp.com/embed/avatars/4.png", role: "City Management" },
];

function readHandover(): HandoverPayload {
  return ((window as unknown as { nuiHandoverData?: HandoverPayload }).nuiHandoverData || {}) as HandoverPayload;
}

function isBrowserPreview() {
  const w = window as unknown as { invokeNative?: unknown; nuiHandoverData?: unknown };
  return !w.invokeNative && !navigator.userAgent.includes("FiveM") && !w.nuiHandoverData;
}

function collectStaff(handover: HandoverPayload, allowPreview: boolean): StaffMember[] {
  const order = Array.isArray(handover.roleOrder) && handover.roleOrder.length
    ? handover.roleOrder
    : ["owner", "developer", "gods", "city_management"];
  const labels = handover.roles || {};
  const staff = handover.staff || {};
  const seen = new Set<string>();
  const list: StaffMember[] = [];

  for (const key of order) {
    const role = labels[key] || key;
    for (const member of staff[key] || []) {
      const id = String(member.id || member.name || "");
      if (!id || seen.has(id)) continue;
      seen.add(id);
      list.push({
        id,
        name: member.name || "Unknown",
        avatar: member.avatar || "https://cdn.discordapp.com/embed/avatars/0.png",
        role,
      });
    }
  }

  if (!list.length && allowPreview) return PREVIEW_STAFF;
  return list;
}

interface LoadingScreenProps {
  onClose?: () => void;
}

export default function LoadingScreen({ onClose }: LoadingScreenProps) {
  const handover = useMemo(() => readHandover(), []);
  const browser = isBrowserPreview();
  const serverName = handover.serverName || "Grim City";
  const staff = useMemo(() => collectStaff(handover, browser), [handover, browser]);

  const playlist = useMemo<Track[]>(
    () => [
      {
        id: "1",
        title: handover.music?.title || "Loading Theme",
        artist: handover.music?.artist || serverName,
        cover: grimLogo,
        url: grimTrack,
        duration: 0,
      },
    ],
    [handover.music?.artist, handover.music?.title, serverName]
  );

  const [progress, setProgress] = useState(browser ? 12 : 0);
  const [currentStepMessage, setCurrentStepMessage] = useState(DEFAULT_STEPS[0]);
  const [currentTrackIndex, setCurrentTrackIndex] = useState(0);
  const [isPlaying, setIsPlaying] = useState(true);
  const [isMuted, setIsMuted] = useState(false);
  const [volume, setVolume] = useState(70);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [showPlaylistDrawer, setShowPlaylistDrawer] = useState(false);
  const [showVolumeSlider, setShowVolumeSlider] = useState(false);
  const [staffOpen, setStaffOpen] = useState(false);

  const audioRef = useRef<HTMLAudioElement | null>(null);
  const currentTrack = playlist[currentTrackIndex] || playlist[0];

  useEffect(() => {
    const handleFiveMMessage = (e: MessageEvent) => {
      const data = e.data;
      if (!data) return;

      if (data.action === "shutdown") {
        audioRef.current?.pause();
      } else if (data.eventName === "loadProgress") {
        const pct = Math.round(Number(data.loadFraction || 0) * 100);
        setProgress(Math.max(0, Math.min(100, pct)));
      } else if (data.eventName === "startInitFunction" || data.eventName === "startDataFileInit") {
        if (data.type) setCurrentStepMessage(`Loading ${data.type}...`);
      } else if (data.eventName === "performMapLoadFunction") {
        setCurrentStepMessage("Loading map elements...");
      }
    };

    window.addEventListener("message", handleFiveMMessage);
    return () => window.removeEventListener("message", handleFiveMMessage);
  }, []);

  useEffect(() => {
    if (!browser) return;
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) return 100;
        const next = prev + Math.floor(Math.random() * 4) + 1;
        return next > 100 ? 100 : next;
      });
    }, 400);
    return () => clearInterval(interval);
  }, [browser]);

  useEffect(() => {
    if (!browser) {
      if (progress >= 100) setCurrentStepMessage("Welcome to Grim City");
      return;
    }
    const stepIdx = Math.min(Math.floor((progress / 100) * DEFAULT_STEPS.length), DEFAULT_STEPS.length - 1);
    setCurrentStepMessage(progress >= 100 ? "Welcome to Grim City" : DEFAULT_STEPS[stepIdx]);
  }, [browser, progress]);

  useEffect(() => {
    if (!audioRef.current) return;
    audioRef.current.volume = isMuted ? 0 : volume / 100;
  }, [volume, isMuted]);

  useEffect(() => {
    if (!audioRef.current) return;
    audioRef.current.src = currentTrack.url;
    setCurrentTime(0);
    setDuration(currentTrack.duration);
    const playPromise = audioRef.current.play();
    if (playPromise !== undefined) {
      playPromise.then(() => setIsPlaying(true)).catch(() => setIsPlaying(true));
    }
  }, [currentTrack.url, currentTrackIndex]);

  const togglePlay = () => {
    if (!audioRef.current) return;
    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
      return;
    }
    audioRef.current.play().then(() => setIsPlaying(true)).catch(() => setIsPlaying(true));
  };

  const handleStop = () => {
    if (!audioRef.current) return;
    audioRef.current.pause();
    audioRef.current.currentTime = 0;
    setCurrentTime(0);
    setIsPlaying(false);
  };

  const handleNextTrack = () => setCurrentTrackIndex((prev) => (prev + 1) % playlist.length);
  const handlePrevTrack = () => setCurrentTrackIndex((prev) => (prev - 1 + playlist.length) % playlist.length);

  const handleTimeUpdate = () => {
    if (!audioRef.current) return;
    setCurrentTime(audioRef.current.currentTime);
    if (audioRef.current.duration && !Number.isNaN(audioRef.current.duration)) {
      setDuration(audioRef.current.duration);
    }
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newTime = parseFloat(e.target.value);
    setCurrentTime(newTime);
    if (audioRef.current) audioRef.current.currentTime = newTime;
  };

  const formatTime = (secs: number) => {
    if (Number.isNaN(secs)) return "00:00";
    const m = Math.floor(secs / 60);
    const s = Math.floor(secs % 60);
    return `${m < 10 ? "0" : ""}${m}:${s < 10 ? "0" : ""}${s}`;
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-between overflow-hidden bg-[#0d0d12] font-sans text-white select-none">
      <audio
        ref={audioRef}
        autoPlay
        onTimeUpdate={handleTimeUpdate}
        onEnded={handleNextTrack}
        preload="metadata"
      />

      <div
        className="pointer-events-none absolute inset-0 z-0 bg-cover bg-center bg-no-repeat"
        style={{ backgroundImage: `url(${grimBanner})` }}
      />
      <div className="pointer-events-none absolute inset-0 z-[1] bg-gradient-to-t from-black/80 via-black/20 to-black/35" />

      <div className="relative z-20 flex items-start justify-between px-5 pt-5">
        <button
          type="button"
          onClick={() => setStaffOpen((open) => !open)}
          className={`flex items-center gap-2 rounded-full border px-3 py-1.5 text-[10px] font-black tracking-[0.22em] uppercase backdrop-blur-md transition ${
            staffOpen
              ? "border-[#ff3a3a] bg-[#ff3a3a]/25 text-white"
              : "border-white/20 bg-black/55 text-white/85 hover:bg-black/70"
          }`}
          title="Staff"
        >
          <img src={grimLogo} alt="" className="h-5 w-5 object-contain" />
          Staff
        </button>

        {onClose ? (
          <button
            type="button"
            onClick={onClose}
            className="rounded-full border border-white/20 bg-black/55 p-2 text-white backdrop-blur-md hover:bg-white/15"
            title="Close preview"
          >
            <X className="h-4 w-4" />
          </button>
        ) : (
          <div />
        )}
      </div>

      {staffOpen && (
        <aside className="absolute left-5 top-16 z-40 flex max-h-[62vh] w-[280px] flex-col overflow-hidden rounded-2xl border border-[#ff3a3a]/40 bg-black/80 shadow-[0_16px_40px_rgba(0,0,0,0.65)] backdrop-blur-xl">
          <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
            <div>
              <p className="text-[10px] font-black tracking-[0.24em] text-[#ff8080] uppercase">City Staff</p>
              <p className="text-sm font-bold text-white">{serverName}</p>
            </div>
            <button type="button" onClick={() => setStaffOpen(false)} className="text-white/70 hover:text-white">
              <X className="h-4 w-4" />
            </button>
          </div>
          <div className="custom-scrollbar flex-1 space-y-2 overflow-y-auto p-3">
            {staff.length === 0 ? (
              <p className="px-1 py-6 text-center text-xs text-white/55">No staff listed yet.</p>
            ) : (
              staff.map((member) => (
                <article key={member.id} className="flex items-center gap-2.5 rounded-xl border border-white/10 bg-white/5 px-2.5 py-2">
                  <img
                    src={member.avatar}
                    alt=""
                    className="h-9 w-9 rounded-full object-cover"
                    onError={(event) => {
                      event.currentTarget.src = "https://cdn.discordapp.com/embed/avatars/0.png";
                    }}
                  />
                  <div className="min-w-0">
                    <p className="truncate text-[13px] font-semibold text-white">{member.name}</p>
                    <p className="truncate text-[10px] font-bold tracking-wider text-[#ff8080] uppercase">{member.role}</p>
                  </div>
                </article>
              ))
            )}
          </div>
        </aside>
      )}

      <div className="relative z-30 mt-auto flex flex-col items-center gap-2 px-4 pb-3">
        <div className="flex w-full max-w-xl flex-col gap-1 px-1">
          <div className="flex items-center justify-between text-[11px] font-medium text-white/90 drop-shadow-[0_2px_4px_rgba(0,0,0,0.9)]">
            <span className="flex items-center gap-1.5">
              <Sparkles className="h-3 w-3 animate-spin text-[#ff4d4d]" style={{ animationDuration: "3s" }} />
              {currentStepMessage}
            </span>
            <span className="font-mono font-bold text-[#ffb3b3]">{progress}%</span>
          </div>
          <div className="h-1.5 w-full overflow-hidden rounded-full border border-white/20 bg-black/70 p-px shadow-lg backdrop-blur-md">
            <div
              className="h-full rounded-full transition-all duration-300 ease-out"
              style={{
                width: `${progress}%`,
                background: "linear-gradient(90deg, #b30000 0%, #ff3a3a 55%, #ff8080 100%)",
                boxShadow: "0 0 10px rgba(255, 58, 58, 0.9)",
              }}
            />
          </div>
        </div>

        <div className="relative flex w-full max-w-xl flex-col gap-2 rounded-full border border-white/20 bg-black/75 px-4 py-2 shadow-[0_10px_30px_rgba(0,0,0,0.8)] backdrop-blur-xl">
          <div className="flex items-center justify-between gap-3">
            <div className="flex w-1/3 min-w-[150px] items-center gap-2.5">
              <div className="relative h-8 w-8 shrink-0 overflow-hidden rounded-full border border-white/20 shadow">
                <img
                  src={currentTrack.cover}
                  alt={currentTrack.title}
                  className={`h-full w-full object-cover ${isPlaying ? "animate-spin" : ""}`}
                  style={{ animationDuration: "12s" }}
                />
              </div>
              <div className="overflow-hidden leading-tight">
                <p className="truncate text-[11px] font-bold text-white">{currentTrack.title}</p>
                <p className="truncate text-[9.5px] text-white/70">{currentTrack.artist}</p>
              </div>
            </div>

            <div className="flex w-1/3 flex-col items-center justify-center gap-0.5">
              <div className="flex items-center gap-3">
                <button type="button" onClick={handlePrevTrack} className="cursor-pointer text-white/70 transition hover:text-white">
                  <SkipBack className="h-3 w-3" />
                </button>
                <button
                  type="button"
                  onClick={togglePlay}
                  className="flex h-6 w-6 cursor-pointer items-center justify-center rounded-full bg-[#ff3a3a] text-white shadow transition hover:scale-105"
                >
                  {isPlaying ? <Pause className="h-3 w-3 fill-current" /> : <Play className="ml-0.5 h-3 w-3 fill-current" />}
                </button>
                <button type="button" onClick={handleStop} className="cursor-pointer text-white/70 transition hover:text-[#ff3a3a]">
                  <Square className="h-3 w-3" />
                </button>
                <button type="button" onClick={handleNextTrack} className="cursor-pointer text-white/70 transition hover:text-white">
                  <SkipForward className="h-3 w-3" />
                </button>
              </div>
              <div className="flex w-full items-center gap-1.5">
                <span className="min-w-[26px] text-right font-mono text-[8.5px] text-white/60">{formatTime(currentTime)}</span>
                <input
                  type="range"
                  min={0}
                  max={duration || 100}
                  value={currentTime}
                  onChange={handleSeek}
                  className="h-1 w-full cursor-pointer appearance-none rounded-lg bg-white/20 accent-[#ff3a3a]"
                />
                <span className="min-w-[26px] font-mono text-[8.5px] text-white/60">{formatTime(duration)}</span>
              </div>
            </div>

            <div className="flex w-1/3 min-w-[120px] items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowPlaylistDrawer(!showPlaylistDrawer)}
                className={`cursor-pointer rounded-full border p-1.5 transition ${
                  showPlaylistDrawer
                    ? "border-[#ff3a3a] bg-[#ff3a3a]/30 text-[#ffb3b3]"
                    : "border-white/20 text-white/80 hover:bg-white/10"
                }`}
                title="Playlist"
              >
                <ListMusic className="h-3 w-3" />
              </button>
              <div
                className="relative flex items-center"
                onMouseEnter={() => setShowVolumeSlider(true)}
                onMouseLeave={() => setShowVolumeSlider(false)}
              >
                <button
                  type="button"
                  onClick={() => setIsMuted(!isMuted)}
                  className={`cursor-pointer rounded-full border p-1.5 transition ${
                    showVolumeSlider
                      ? "border-[#ff4d4d] bg-[#ff4d4d]/20 text-[#ff4d4d]"
                      : "border-white/20 text-white/80 hover:bg-white/10"
                  }`}
                  title="Volume"
                >
                  {isMuted || volume === 0 ? (
                    <VolumeX className="h-3 w-3 text-[#ff3a3a]" />
                  ) : (
                    <Volume2 className="h-3 w-3 text-[#ff8080]" />
                  )}
                </button>
                <div className={`flex items-center overflow-hidden transition-all duration-300 ${showVolumeSlider ? "ml-1.5 w-14 opacity-100" : "ml-0 w-0 opacity-0"}`}>
                  <input
                    type="range"
                    min={0}
                    max={100}
                    value={isMuted ? 0 : volume}
                    onChange={(e) => {
                      setVolume(Number(e.target.value));
                      if (isMuted) setIsMuted(false);
                    }}
                    className="h-1 w-12 cursor-pointer appearance-none rounded-lg bg-white/20 accent-[#ff4d4d]"
                  />
                </div>
              </div>
            </div>
          </div>

          {showPlaylistDrawer && (
            <div className="mt-0.5 flex max-h-28 w-full flex-col gap-1 overflow-y-auto border-t border-white/10 pt-1.5">
              {playlist.map((track, idx) => (
                <div
                  key={track.id}
                  onClick={() => {
                    setCurrentTrackIndex(idx);
                    setIsPlaying(true);
                  }}
                  className={`flex cursor-pointer items-center justify-between rounded-lg border px-2.5 py-1 text-[11px] transition ${
                    currentTrackIndex === idx
                      ? "border-[#ff3a3a] bg-[#ff3a3a]/30 font-bold text-white"
                      : "border-white/5 bg-black/40 text-white/80 hover:bg-white/10"
                  }`}
                >
                  <div className="flex items-center gap-2 truncate">
                    <Music className="h-3 w-3 text-[#ff8080]" />
                    <span className="truncate">{track.title}</span>
                  </div>
                  <span className="font-mono text-[9.5px] text-white/60">{formatTime(track.duration)}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
