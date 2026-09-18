import { useEffect, useMemo, useState, useRef } from "react";
import { 
  Image, 
  Plus, 
  Search, 
  Trash2, 
  UserPlus, 
  Users, 
  Volume2, 
  VolumeX, 
  X, 
  Edit3, 
  Play, 
  Square, 
  Clock, 
  Sparkles,
} from "lucide-react";
import { cn } from "@/lib/utils";

export interface WelcomeBannerPlayer {
  identifier: string;
  name?: string;
  gif?: string;
  sound?: string;
  volume?: number;
  width?: number;
  height?: number;
  duration?: number;
  addedBy?: string;
  addedAt?: string;
}

export interface WelcomeBannerOnlinePlayer {
  id: number;
  name: string;
  identifier: string;
}

export interface WelcomeBannerPanelData {
  staffName?: string;
  staffGroup?: string;
  players?: WelcomeBannerPlayer[];
  online?: WelcomeBannerOnlinePlayer[];
  duration?: number;
  /** VIP self-service: only edit own banner */
  selfEdit?: boolean;
  selfIdentifier?: string;
}

interface WelcomeBannerPanelProps {
  data?: WelcomeBannerPanelData | null;
  onClose: () => void;
}

function getResourceName() {
  return (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName
    ? (window as Window & { GetParentResourceName: () => string }).GetParentResourceName()
    : "cfx-keydi-ui";
}

async function fetchNui<T = unknown>(event: string, payload?: unknown): Promise<T | undefined> {
  try {
    const resp = await fetch(`https://${getResourceName()}/${event}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(payload ?? {}),
    });
    return await resp.json();
  } catch {
    return undefined;
  }
}

export default function WelcomeBannerPanel({ data, onClose }: WelcomeBannerPanelProps) {
  const [players, setPlayers] = useState<WelcomeBannerPlayer[]>(data?.players ?? []);
  const [online, setOnline] = useState<WelcomeBannerOnlinePlayer[]>(data?.online ?? []);
  const [search, setSearch] = useState("");
  const [showDrawer, setShowDrawer] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [busy, setBusy] = useState(false);
  const selfEdit = !!data?.selfEdit;

  // Form Fields
  const [identifier, setIdentifier] = useState("");
  const [name, setName] = useState("");
  const [gif, setGif] = useState("");
  const [sound, setSound] = useState("");
  const [volume, setVolume] = useState(0.6);
  const [duration, setDuration] = useState<number>(8);
  const [width, setWidth] = useState<string>("");
  const [height, setHeight] = useState<string>("");

  // Audio Preview state
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);
  const audioPreviewRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    setPlayers(data?.players ?? []);
    setOnline(data?.online ?? []);
  }, [data]);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg) return;
      if (msg.action === "cfx-keydi-welcomebanner:panel:update" && msg.data) {
        if (msg.data.players) setPlayers(msg.data.players);
        if (msg.data.online) setOnline(msg.data.online);
      }
    };
    window.addEventListener("message", onMessage);
    return () => window.removeEventListener("message", onMessage);
  }, []);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        stopAudioPreview();
        if (showDrawer) {
          setShowDrawer(false);
          setIsEditing(false);
        } else {
          onClose();
        }
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose, showDrawer]);

  const stopAudioPreview = () => {
    if (audioPreviewRef.current) {
      audioPreviewRef.current.pause();
      audioPreviewRef.current.currentTime = 0;
      audioPreviewRef.current = null;
    }
    setIsPlayingAudio(false);
  };

  const togglePlayAudio = (soundUrl: string, vol: number) => {
    if (isPlayingAudio) {
      stopAudioPreview();
      return;
    }

    if (!soundUrl || !soundUrl.trim()) return;

    try {
      const audio = new Audio(soundUrl.trim());
      audio.volume = Math.max(0, Math.min(1, vol));
      audioPreviewRef.current = audio;
      audio.play().then(() => {
        setIsPlayingAudio(true);
      }).catch(() => {
        setIsPlayingAudio(false);
      });
      audio.onended = () => {
        setIsPlayingAudio(false);
        audioPreviewRef.current = null;
      };
    } catch {
      setIsPlayingAudio(false);
    }
  };

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return players;
    return players.filter((player) =>
      [player.name, player.identifier, player.gif, player.sound]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(q))
    );
  }, [players, search]);

  const resetForm = () => {
    setIdentifier("");
    setName("");
    setGif("");
    setSound("");
    setVolume(0.6);
    setDuration(8);
    setWidth("");
    setHeight("");
    setIsEditing(false);
    stopAudioPreview();
  };

  const openAddForm = () => {
    resetForm();
    if (selfEdit && data?.selfIdentifier) {
      setIdentifier(data.selfIdentifier);
      setName(data.staffName || "");
    }
    setShowDrawer(true);
  };

  const openEditForm = (player: WelcomeBannerPlayer) => {
    stopAudioPreview();
    setIdentifier(player.identifier);
    setName(player.name || "");
    setGif(player.gif || "");
    setSound(player.sound || "");
    setVolume(player.volume ?? 0.6);
    setDuration(player.duration ?? 8);
    setWidth(player.width ? String(player.width) : "");
    setHeight(player.height ? String(player.height) : "");
    setIsEditing(true);
    setShowDrawer(true);
  };

  const pickOnline = (player: WelcomeBannerOnlinePlayer) => {
    setIdentifier(player.identifier);
    setName(player.name);
  };

  const savePlayerBanner = async () => {
    if (busy || !identifier.trim() || !gif.trim()) return;
    setBusy(true);
    stopAudioPreview();

    const payload: any = {
      identifier: identifier.trim(),
      name: name.trim(),
      gif: gif.trim(),
      sound: sound.trim(),
      volume: volume,
      duration: Number(duration) || 8,
    };

    if (width.trim() && !isNaN(Number(width))) {
      payload.width = Number(width);
    }
    if (height.trim() && !isNaN(Number(height))) {
      payload.height = Number(height);
    }

    await fetchNui("cfx-keydi-welcomebanner:add", payload);
    setBusy(false);
    setShowDrawer(false);
    resetForm();
  };

  const removePlayer = async (player: WelcomeBannerPlayer) => {
    if (busy) return;
    setBusy(true);
    stopAudioPreview();
    await fetchNui("cfx-keydi-welcomebanner:remove", { identifier: player.identifier });
    setBusy(false);
  };

  return (
    <div className="pandora fixed inset-0 z-[99950] flex items-center justify-center bg-black/80 p-4 font-sans select-none backdrop-blur-[6px]">
      <div
        className="relative flex h-[540px] w-full max-w-4xl flex-col overflow-hidden rounded-2xl border-2 border-[#ff3a3a] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.95)]"
        style={{ background: "linear-gradient(180deg, #140d11 0%, #0d0d12 100%)" }}
      >
        <div className="panel-grid pointer-events-none absolute inset-0 opacity-25" />

        {/* Top Header */}
        <div
          className="relative flex items-center justify-between border-b px-3 py-2"
          style={{ borderBottomColor: "rgba(255, 58, 58, 0.25)" }}
        >
          <div className="flex items-center gap-2.5">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-[#ff3a3a] bg-[#ff3a3a]/15 text-white">
              <Sparkles className="h-3.5 w-3.5" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="rounded border border-[#ff3a3a] bg-[#ff3a3a]/20 px-1.5 py-0.5 text-[8px] font-black uppercase tracking-[0.18em] text-[#ff4d4d]">
                  {selfEdit ? "VIP Self Edit" : data?.staffGroup || "Staff"}
                </span>
                <span className="text-[10px] text-[#a08890]">· {data?.staffName || "Admin"}</span>
              </div>
              <h2 className="text-[13px] font-black text-white tracking-wide">
                {selfEdit ? "My Welcome Banner" : "Welcome Banner System"}
              </h2>
            </div>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={openAddForm}
              className="flex items-center gap-1 rounded-md border border-[#ff3a3a] bg-[#ff3a3a]/20 hover:bg-[#ff3a3a]/35 px-2.5 py-1.5 text-[10px] font-bold text-[#ff4d4d] transition active:scale-95"
            >
              <Plus className="h-3.5 w-3.5" />
              {selfEdit ? (players.length > 0 ? "Edit My Banner" : "Create My Banner") : "Add Banner"}
            </button>
            <button
              type="button"
              onClick={onClose}
              className="flex items-center gap-1 rounded-md border border-[#ff3a3a]/30 bg-[#181216] px-2 py-1 text-[10px] font-semibold text-white/80 transition hover:border-[#ff3a3a] hover:text-white"
            >
              <span>Esc</span>
              <X className="h-3 w-3 text-[#ff4d4d]" />
            </button>
          </div>
        </div>

        {/* Search Bar */}
        {!selfEdit && (
        <div className="relative border-b border-[#ff3a3a]/20 px-3 py-1.5">
          <div className="flex items-center gap-2 rounded-md border border-[#ff3a3a]/25 bg-[#181216] px-2.5 py-1.5">
            <Search className="h-3.5 w-3.5 text-[#a08890] shrink-0" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name, identifier, GIF, or sound..."
              className="w-full bg-transparent text-[11px] text-white outline-none placeholder:text-[#a08890]/60"
            />
            {search && (
              <button onClick={() => setSearch("")} className="text-[#a08890] hover:text-white text-[10px]">
                Clear
              </button>
            )}
          </div>
        </div>
        )}

        {/* Main Content Area */}
        <div className="relative flex min-h-0 flex-1 overflow-hidden">
          {/* Left / Center: Player Cards List */}
          <div className="no-scrollbar flex-1 space-y-1.5 overflow-y-auto p-3">
            {filtered.length === 0 ? (
              <div className="flex h-full flex-col items-center justify-center gap-2 text-[#a08890] py-8">
                <Users className="h-9 w-9 stroke-1 opacity-40 text-[#ff4d4d]" />
                <div className="text-center">
                  <p className="text-[12px] font-bold text-white/80">
                    {selfEdit ? "No Banner Yet" : "No Custom Banner Players Found"}
                  </p>
                  <p className="text-[10px] text-[#a08890] mt-0.5 max-w-xs">
                    {selfEdit
                      ? 'Click "Create My Banner" to set your join GIF & sound.'
                      : 'Click "Add Banner" to assign custom GIF & sound.'}
                  </p>
                </div>
              </div>
            ) : (
              filtered.map((player) => (
                <div
                  key={player.identifier}
                  className="flex items-center gap-3 rounded-lg border border-[#ff3a3a]/25 bg-[#181216] hover:border-[#ff3a3a]/50 p-2.5 transition group"
                >
                  <div className="relative h-12 w-20 shrink-0 overflow-hidden rounded-md border border-[#ff3a3a]/30 bg-black/60">
                    {player.gif ? (
                      <img src={player.gif} alt="" className="h-full w-full object-cover" />
                    ) : (
                      <div className="flex h-full items-center justify-center text-[#a08890]">
                        <Image className="h-4 w-4" />
                      </div>
                    )}
                  </div>

                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <h4 className="truncate text-[12px] font-bold text-white">
                        {player.name || "Unnamed Player"}
                      </h4>
                      <span className="px-1.5 py-0.5 rounded text-[8px] font-mono font-bold bg-[#ff3a3a]/15 text-[#ff4d4d] border border-[#ff3a3a]/40">
                        Vol: {Math.round((player.volume ?? 0.6) * 100)}%
                      </span>
                      {player.duration && (
                        <span className="px-1.5 py-0.5 rounded text-[8px] font-mono font-bold bg-black/30 text-[#a08890] border border-[#ff3a3a]/20">
                          {player.duration}s
                        </span>
                      )}
                    </div>

                    <p className="truncate font-mono text-[10px] text-[#a08890] mt-0.5">
                      {player.identifier}
                    </p>

                    <div className="flex items-center gap-2 text-[10px] text-[#a08890] mt-0.5">
                      {player.sound ? (
                        <span className="flex items-center gap-1 text-[#ff8080] font-mono truncate max-w-xs">
                          <Volume2 className="h-3 w-3 shrink-0 text-[#ff4d4d]" />
                          <span className="truncate">{player.sound}</span>
                        </span>
                      ) : (
                        <span className="flex items-center gap-1 italic">
                          <VolumeX className="h-3 w-3 shrink-0" /> No Sound
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-1 shrink-0">
                    {player.sound && (
                      <button
                        type="button"
                        onClick={() => togglePlayAudio(player.sound || "", player.volume ?? 0.6)}
                        className="flex h-7 w-7 items-center justify-center rounded-md border border-[#ff3a3a]/40 bg-[#ff3a3a]/10 text-[#ff4d4d] hover:bg-[#ff3a3a] hover:text-white transition"
                        title="Test Sound Audio"
                      >
                        {isPlayingAudio && audioPreviewRef.current?.src.includes(player.sound) ? (
                          <Square className="h-3 w-3 fill-current" />
                        ) : (
                          <Play className="h-3 w-3 fill-current" />
                        )}
                      </button>
                    )}

                    <button
                      type="button"
                      onClick={() => openEditForm(player)}
                      className="flex h-7 items-center gap-1 px-2 rounded-md border border-[#ff3a3a]/40 bg-[#ff3a3a]/10 hover:bg-[#ff3a3a] text-[#ff4d4d] hover:text-white text-[10px] font-bold transition"
                      title="Edit Player Banner"
                    >
                      <Edit3 className="h-3 w-3" />
                      <span>Edit</span>
                    </button>

                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => removePlayer(player)}
                      className="flex h-7 w-7 items-center justify-center rounded-md border border-rose-500/30 bg-rose-600/15 text-rose-300 hover:bg-rose-600 hover:text-white transition"
                      title="Delete Player Banner"
                    >
                      <Trash2 className="h-3 w-3" />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Right Drawer: Add / Edit Form */}
          {showDrawer && (
            <div className="flex w-[340px] shrink-0 flex-col border-l border-[#ff3a3a]/25 bg-[#0d0d12] animate-in slide-in-from-right-4 duration-200">
              <div className="flex items-center justify-between border-b border-[#ff3a3a]/25 px-3 py-2 bg-[#140d11]">
                <div className="flex items-center gap-2 text-white">
                  {isEditing ? (
                    <Edit3 className="h-3.5 w-3.5 text-[#ff4d4d]" />
                  ) : (
                    <UserPlus className="h-3.5 w-3.5 text-[#ff4d4d]" />
                  )}
                  <div>
                    <h3 className="text-[12px] font-black">
                      {isEditing ? "Edit Banner" : "Add Banner"}
                    </h3>
                    <p className="text-[9px] text-[#a08890]">
                      {isEditing ? "Modify GIF, sound & size" : "Assign GIF & audio"}
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => {
                    stopAudioPreview();
                    setShowDrawer(false);
                  }}
                  className="text-[#a08890] hover:text-white p-1 rounded-md hover:bg-[#181216] transition"
                >
                  <X className="h-3.5 w-3.5" />
                </button>
              </div>

              <div className="no-scrollbar flex-1 space-y-2.5 overflow-y-auto p-3">
                <div>
                  <label className="block text-[9px] font-bold uppercase tracking-wider text-[#a08890] mb-0.5">
                    Player License Identifier
                  </label>
                  <input
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    placeholder="license:xxxxxxxx..."
                    disabled={selfEdit}
                    className="w-full rounded-md border border-[#ff3a3a]/25 bg-[#181216] px-2.5 py-1.5 text-[11px] font-mono text-white outline-none focus:border-[#ff3a3a] disabled:opacity-60"
                  />
                  <span className="text-[9px] text-[#a08890]/70 mt-0.5 block">
                    {selfEdit
                      ? "Locked to your VIP license."
                      : "Full license or pick an online player below."}
                  </span>
                </div>

                <div>
                  <label className="block text-[9px] font-bold uppercase tracking-wider text-[#a08890] mb-0.5">
                    Player Display Name
                  </label>
                  <input
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. John Doe"
                    className="w-full rounded-md border border-[#ff3a3a]/25 bg-[#181216] px-2.5 py-1.5 text-[11px] text-white outline-none focus:border-[#ff3a3a]"
                  />
                </div>

                <div>
                  <label className="block text-[9px] font-bold uppercase tracking-wider text-[#a08890] mb-0.5">
                    GIF / Image URL
                  </label>
                  <input
                    value={gif}
                    onChange={(e) => setGif(e.target.value)}
                    placeholder="https://.../banner.gif"
                    className="w-full rounded-md border border-[#ff3a3a]/25 bg-[#181216] px-2.5 py-1.5 text-[11px] text-white outline-none focus:border-[#ff3a3a]"
                  />
                  {gif && (
                    <div className="mt-1.5 h-16 w-full overflow-hidden rounded-md border border-[#ff3a3a]/25 bg-black/50 flex items-center justify-center">
                      <img
                        src={gif}
                        alt="Preview"
                        className="h-full w-full object-contain"
                        onError={(e) => {
                          (e.target as HTMLImageElement).style.display = "none";
                        }}
                      />
                    </div>
                  )}
                </div>

                <div>
                  <div className="flex items-center justify-between mb-0.5">
                    <label className="block text-[9px] font-bold uppercase tracking-wider text-[#a08890]">
                      Sound URL (MP3 / OGG)
                    </label>
                    {sound && (
                      <button
                        type="button"
                        onClick={() => togglePlayAudio(sound, volume)}
                        className="flex items-center gap-1 text-[9px] font-bold text-[#ff4d4d] hover:text-[#ff8080]"
                      >
                        {isPlayingAudio ? (
                          <>
                            <Square className="h-2.5 w-2.5 fill-current" /> Stop
                          </>
                        ) : (
                          <>
                            <Play className="h-2.5 w-2.5 fill-current" /> Test
                          </>
                        )}
                      </button>
                    )}
                  </div>
                  <input
                    value={sound}
                    onChange={(e) => setSound(e.target.value)}
                    placeholder="https://.../welcome.mp3"
                    className="w-full rounded-md border border-[#ff3a3a]/25 bg-[#181216] px-2.5 py-1.5 text-[11px] text-white outline-none focus:border-[#ff3a3a]"
                  />
                </div>

                <div className="rounded-md border border-[#ff3a3a]/25 bg-[#181216] p-2.5">
                  <div className="flex items-center justify-between text-[10px] font-bold text-[#a08890] mb-1">
                    <span className="flex items-center gap-1">
                      <Volume2 className="h-3 w-3 text-[#ff4d4d]" />
                      Volume
                    </span>
                    <span className="font-mono text-[#ff4d4d]">{Math.round(volume * 100)}%</span>
                  </div>
                  <input
                    type="range"
                    min={0}
                    max={1}
                    step={0.05}
                    value={volume}
                    onChange={(e) => setVolume(Number(e.target.value))}
                    className="w-full accent-[#ff3a3a] cursor-pointer"
                  />
                </div>

                <div className="rounded-md border border-[#ff3a3a]/25 bg-[#181216] p-2.5">
                  <div className="flex items-center justify-between text-[10px] font-bold text-[#a08890] mb-1">
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3 text-[#ff4d4d]" />
                      Duration
                    </span>
                    <span className="font-mono text-[#ff4d4d]">{duration}s</span>
                  </div>
                  <input
                    type="range"
                    min={4}
                    max={20}
                    step={1}
                    value={duration}
                    onChange={(e) => setDuration(Number(e.target.value))}
                    className="w-full accent-[#ff3a3a] cursor-pointer"
                  />
                </div>

                <div className="grid grid-cols-2 gap-1.5">
                  <div>
                    <label className="block text-[8px] font-bold uppercase tracking-wider text-[#a08890] mb-0.5">
                      Width (px)
                    </label>
                    <input
                      type="number"
                      value={width}
                      onChange={(e) => setWidth(e.target.value)}
                      placeholder="350"
                      className="w-full rounded-md border border-[#ff3a3a]/25 bg-[#181216] px-2 py-1 text-[11px] text-white outline-none focus:border-[#ff3a3a]"
                    />
                  </div>
                  <div>
                    <label className="block text-[8px] font-bold uppercase tracking-wider text-[#a08890] mb-0.5">
                      Height (px)
                    </label>
                    <input
                      type="number"
                      value={height}
                      onChange={(e) => setHeight(e.target.value)}
                      placeholder="200"
                      className="w-full rounded-md border border-[#ff3a3a]/25 bg-[#181216] px-2 py-1 text-[11px] text-white outline-none focus:border-[#ff3a3a]"
                    />
                  </div>
                </div>

                {!selfEdit && (
                  <div>
                    <p className="mb-1 text-[8px] font-bold uppercase tracking-wider text-[#a08890]">
                      Quick Pick Online ({online.length})
                    </p>
                    <div className="no-scrollbar max-h-24 space-y-0.5 overflow-y-auto rounded-md border border-[#ff3a3a]/25 bg-[#181216] p-1">
                      {online.length === 0 ? (
                        <p className="text-[10px] text-[#a08890] p-1.5 text-center">No other players online.</p>
                      ) : (
                        online.map((player) => (
                          <button
                            key={`${player.id}-${player.identifier}`}
                            type="button"
                            onClick={() => pickOnline(player)}
                            className={cn(
                              "w-full rounded border px-2 py-1 text-left text-[10px] transition",
                              identifier === player.identifier
                                ? "border-[#ff3a3a] bg-[#ff3a3a]/20 text-white font-bold"
                                : "border-transparent text-[#a08890] hover:bg-[#ff3a3a]/10 hover:text-white"
                            )}
                          >
                            <span className="block truncate">{player.name}</span>
                            <span className="block truncate font-mono text-[8px] opacity-60">{player.identifier}</span>
                          </button>
                        ))
                      )}
                    </div>
                  </div>
                )}
              </div>

              <div className="flex items-center gap-1.5 p-2.5 border-t border-[#ff3a3a]/25 bg-[#140d11]">
                <button
                  type="button"
                  onClick={() => {
                    stopAudioPreview();
                    setShowDrawer(false);
                  }}
                  className="px-3 py-1.5 rounded-md border border-[#ff3a3a]/30 bg-[#181216] text-[#a08890] text-[10px] font-bold transition hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={busy || !identifier.trim() || !gif.trim()}
                  onClick={savePlayerBanner}
                  className="flex-1 rounded-md border border-[#ff3a3a] bg-gradient-to-r from-[#b30000] to-[#ff3a3a] disabled:opacity-40 text-white py-1.5 text-[10px] font-black transition hover:brightness-110"
                >
                  {isEditing ? "Update Banner" : "Save Banner"}
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Bottom Footer */}
        <div
          className="relative flex shrink-0 items-center justify-between border-t px-3 py-1.5 text-[10px] font-mono"
          style={{ borderTopColor: "rgba(255, 58, 58, 0.25)" }}
        >
          <span className="text-[#a08890]">Grim City Welcome Banner</span>
          <span className="text-[#ff4d4d] font-bold">{players.length} Total Banners</span>
        </div>
      </div>
    </div>
  );
}

