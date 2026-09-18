import { useEffect, useRef, useState } from "react";
import grimLogo from "@/assets/grim-city-logo.png";

interface WelcomeBannerData {
  duration: number;
  width: number;
  height: number;
  maxWidth: number;
  maxHeight: number;
  bottom: number;
  right: number;
  image: string;
  sound: string;
  volume: number;
  playerName: string;
}

const DEFAULT_DATA: WelcomeBannerData = {
  duration: 8,
  width: 350,
  height: 200,
  maxWidth: 480,
  maxHeight: 270,
  bottom: 24,
  right: 24,
  image: "",
  sound: "",
  volume: 0.6,
  playerName: "",
};

function clamp01(value: number) {
  if (Number.isNaN(value)) return 0;
  return Math.min(1, Math.max(0, value));
}

export default function WelcomeBanner() {
  const [visible, setVisible] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [data, setData] = useState<WelcomeBannerData>(DEFAULT_DATA);
  const [imageFailed, setImageFailed] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const bannerVolumeRef = useRef(DEFAULT_DATA.volume);
  const listenerVolumeRef = useRef(1);

  const applyPlaybackVolume = () => {
    const audio = audioRef.current;
    if (!audio) return;
    audio.volume = clamp01(bannerVolumeRef.current * listenerVolumeRef.current);
  };

  const stopSound = () => {
    const audio = audioRef.current;
    if (!audio) return;
    audio.pause();
    audio.currentTime = 0;
    audioRef.current = null;
  };

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg) return;

      if (msg.action === "cfx-keydi-welcomebanner:listenerVolume") {
        listenerVolumeRef.current = clamp01(Number(msg.volume ?? 1));
        applyPlaybackVolume();
        return;
      }

      if (msg.action === "cfx-keydi-welcomebanner:show") {
        const next = { ...DEFAULT_DATA, ...(msg.data || {}) };
        stopSound();
        bannerVolumeRef.current = clamp01(Number(next.volume ?? 0.6));
        if (typeof msg.data?.listenerVolume === "number") {
          listenerVolumeRef.current = clamp01(msg.data.listenerVolume);
        }
        setData(next);
        setImageFailed(false);
        setLeaving(false);
        setVisible(true);
      } else if (msg.action === "cfx-keydi-welcomebanner:hide") {
        setLeaving(true);
        stopSound();
      }
    };

    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  useEffect(() => {
    if (!visible || !data.sound) return;

    const audio = new Audio(data.sound);
    bannerVolumeRef.current = clamp01(Number(data.volume ?? 0.6));
    audio.volume = clamp01(bannerVolumeRef.current * listenerVolumeRef.current);
    audioRef.current = audio;
    audio.play().catch(() => {});

    return () => {
      audio.pause();
      audio.currentTime = 0;
      if (audioRef.current === audio) {
        audioRef.current = null;
      }
    };
  }, [visible, data.sound, data.volume]);

  useEffect(() => {
    if (!leaving) return;
    const timer = window.setTimeout(() => {
      setVisible(false);
      setLeaving(false);
    }, 280);
    return () => window.clearTimeout(timer);
  }, [leaving]);

  if (!visible) return null;

  const customImage = data.image && !imageFailed ? data.image : "";

  const boxWidth = Math.min(data.width, data.maxWidth);
  const boxHeight = Math.min(data.height, data.maxHeight);

  return (
    <div
      className="pandora pointer-events-none fixed z-[99990] select-none"
      style={{
        bottom: data.bottom,
        right: data.right,
        width: boxWidth,
        height: boxHeight,
        maxWidth: data.maxWidth,
        maxHeight: data.maxHeight,
        contain: "layout paint size",
      }}
    >
      <div
        className={leaving ? "animate-welcomebanner-out" : "animate-welcomebanner-in"}
        style={{ width: "100%", height: "100%" }}
      >
        <div
          className="relative h-full w-full overflow-hidden rounded-xl border-2 border-[#ff3a3a]"
          style={{
            background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)",
            boxShadow: "0 10px 24px rgba(0, 0, 0, 0.85)",
          }}
        >
          <img
            src={customImage || grimLogo}
            alt="Welcome"
            decoding="async"
            draggable={false}
            className={customImage ? "h-full w-full object-cover" : "h-full w-full object-contain p-1"}
            style={{
              maxWidth: "100%",
              maxHeight: "100%",
            }}
            onError={() => setImageFailed(true)}
          />
          {data.playerName ? (
            <div
              className="absolute inset-x-0 bottom-0 px-2 py-1.5 text-center"
              style={{
                background: "linear-gradient(180deg, transparent 0%, rgba(13, 13, 18, 0.95) 100%)",
              }}
            >
              <p className="truncate text-[11px] font-bold leading-tight text-white">
                Welcome, {data.playerName}
              </p>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
}
