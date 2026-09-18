import React, { useCallback, useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import {
  Car,
  ChevronLeft,
  ChevronRight,
  Clock3,
  Crown,
  Medal,
  Package,
  Sparkles,
  Trophy,
  User,
  X,
} from "lucide-react";
import grimCoin from "@/assets/grim-coin.png";

export interface PlaytimeProduct {
  id: string;
  label: string;
  amount?: number;
  price: number;
  image?: string;
  model?: string;
  stock?: number | null;
  kind?: "item" | "part" | "vehicle";
}

export interface PlaytimeShopData {
  playerName?: string;
  coins?: number;
  totalEarned?: number;
  nextRewardSeconds?: number;
  rewardCoins?: number;
  rewardMinutes?: number;
  items?: PlaytimeProduct[];
  cars?: PlaytimeProduct[];
  pageSize?: number;
}

export interface TopEarner {
  rank: number;
  name: string;
  coins: number;
}

type Category = "items" | "cars";

const MOCK: PlaytimeShopData = {
  playerName: "Karl Dev",
  coins: 45,
  nextRewardSeconds: 18 * 60 + 35,
  rewardCoins: 3,
  rewardMinutes: 35,
  pageSize: 6,
  items: [
    { id: "bandage", label: "BANDAGE", amount: 5, price: 15, image: "bandage" },
    { id: "lockpick", label: "LOCKPICK", amount: 1, price: 35, image: "lockpick" },
    { id: "armor", label: "BODY ARMOR", amount: 1, price: 80, image: "armour" },
    { id: "repairkit", label: "REPAIR KIT", amount: 1, price: 45, image: "repairkit" },
    { id: "phone", label: "SMARTPHONE", amount: 1, price: 60, image: "phone" },
    { id: "radio", label: "RADIO", amount: 1, price: 50, image: "radio" },
    { id: "water", label: "WATER BOTTLE", amount: 5, price: 10, image: "water" },
    { id: "burger", label: "BURGER", amount: 5, price: 12, image: "burger" },
  ],
  cars: [
    { id: "vehicle_shell", label: "VEHICLE SHELL", amount: 1, price: 10, image: "vehicle_shell", stock: 5, kind: "part" },
    { id: "project_parts_box", label: "PROJECT PARTS BOX", amount: 1, price: 10, image: "project_parts_box", stock: 2, kind: "part" },
    { id: "car_blueprint", label: "CAR BLUEPRINT", amount: 1, price: 10, image: "car_blueprint", stock: 100, kind: "part" },
    { id: "car_battery", label: "CAR BATTERY", amount: 1, price: 10, image: "car_battery", stock: 3, kind: "part" },
    { id: "car_wheel", label: "CAR WHEEL SET", amount: 4, price: 10, image: "car_wheel", stock: 6, kind: "part" },
  ],
};

function isBrowser() {
  return (
    !(window as unknown as { invokeNative?: unknown }).invokeNative &&
    !navigator.userAgent.includes("FiveM")
  );
}

async function nui<T>(event: string, data: Record<string, unknown> = {}): Promise<T | null> {
  if (isBrowser()) return null;
  const resourceName = (window as unknown as { GetParentResourceName?: () => string })
    .GetParentResourceName
    ? (window as unknown as { GetParentResourceName: () => string }).GetParentResourceName()
    : "kodebykarl-ui";
  try {
    const res = await fetch(`https://${resourceName}/${event}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data),
    });
    return (await res.json()) as T;
  } catch {
    return null;
  }
}

function formatTime(totalSeconds: number) {
  const s = Math.max(0, Math.floor(totalSeconds));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}m ${r.toString().padStart(2, "0")}s`;
}

function CoinIcon({ className }: { className?: string }) {
  return (
    <img
      src={grimCoin}
      alt="Grim Coin"
      className={cn("inline-block h-5 w-5 shrink-0 object-contain drop-shadow-[0_2px_6px_rgba(245,197,66,0.45)]", className)}
      draggable={false}
    />
  );
}

/** Product Item Image Renderer with ox_inventory integration */
function ItemImageDisplay({ image, id }: { image?: string; id: string }) {
  const [failed, setFailed] = useState(false);
  const cleanName = image && image !== "car" ? image : id;
  const src = `nui://ox_inventory/web/images/${cleanName}.png`;

  if (failed) {
    return (
      <div className="flex h-full w-full flex-col items-center justify-center text-[#8b8374]">
        <Package className="mb-1 h-8 w-8 text-[#f5c542]/50" />
        <span className="text-[10px] font-bold uppercase tracking-wider text-white/45">{id}</span>
      </div>
    );
  }

  return (
    <img
      src={src}
      alt={id}
      className="max-h-[85px] max-w-[85px] object-contain drop-shadow-[0_4px_10px_rgba(0,0,0,0.7)] transition-transform duration-200 group-hover:scale-105"
      onError={() => setFailed(true)}
      loading="lazy"
    />
  );
}

/** Product Vehicle Image Renderer with multi-URL fallback */
function CarImageDisplay({ model, id, label }: { model?: string; id: string; label: string }) {
  const carModel = (model || id).toLowerCase();
  const [urlIndex, setUrlIndex] = useState(0);
  const [allFailed, setAllFailed] = useState(false);

  // Sequence of image URLs to try for vehicles
  const urls = useMemo(
    () => [
      `https://docs.fivem.net/vehicles/${carModel}.webp`,
      `https://docs.fivem.net/vehicles/${carModel}.png`,
      `https://raw.githubusercontent.com/root-cause/v-vehicle-hashes/master/images/${carModel}.png`,
      `nui://ox_inventory/web/images/${carModel}.png`,
    ],
    [carModel],
  );

  const handleError = () => {
    if (urlIndex < urls.length - 1) {
      setUrlIndex((prev) => prev + 1);
    } else {
      setAllFailed(true);
    }
  };

  if (allFailed) {
    return (
      <div className="flex h-full w-full flex-col items-center justify-center text-[#8b8374]">
        <Car className="mb-1 h-9 w-9 text-[#f5c542]/60" />
        <span className="text-[10px] font-bold uppercase tracking-wider text-[#f5c542]">
          {carModel}
        </span>
      </div>
    );
  }

  return (
    <img
      key={urls[urlIndex]}
      src={urls[urlIndex]}
      alt={label}
      className="max-h-[85px] max-w-[95%] object-contain drop-shadow-[0_4px_10px_rgba(0,0,0,0.85)] transition-transform duration-200 group-hover:scale-105"
      onError={handleError}
      loading="lazy"
    />
  );
}

export default function PlaytimeShop({
  visible,
  data,
  onClose,
}: {
  visible: boolean;
  data?: PlaytimeShopData | null;
  onClose?: () => void;
}) {
  const [category, setCategory] = useState<Category>("items");
  const [page, setPage] = useState(0);
  const [coins, setCoins] = useState(0);
  const [nextSec, setNextSec] = useState(0);
  const [buying, setBuying] = useState<string | null>(null);
  const [showTopModal, setShowTopModal] = useState(false);
  const [loadingTop, setLoadingTop] = useState(false);
  const [top, setTop] = useState<TopEarner[]>([]);
  const [toast, setToast] = useState<string | null>(null);
  const [itemCatalog, setItemCatalog] = useState<PlaytimeProduct[] | null>(null);
  const [carCatalog, setCarCatalog] = useState<PlaytimeProduct[] | null>(null);

  const shop = data || (isBrowser() ? MOCK : null);
  const pageSize = shop?.pageSize || 6;
  const rewardCoins = shop?.rewardCoins ?? 3;
  const rewardMinutes = shop?.rewardMinutes ?? 35;
  const totalCycleSeconds = rewardMinutes * 60;

  useEffect(() => {
    if (!visible || !shop) return;
    setCoins(shop.coins ?? 0);
    setNextSec(shop.nextRewardSeconds ?? totalCycleSeconds);
    setItemCatalog(shop.items || null);
    setCarCatalog(shop.cars || null);
    setPage(0);
    setCategory("items");
    setShowTopModal(false);
  }, [visible, shop, totalCycleSeconds]);

  useEffect(() => {
    if (!visible || !data) return;
    if (typeof data.coins === "number") setCoins(data.coins);
    if (typeof data.nextRewardSeconds === "number") setNextSec(data.nextRewardSeconds);
    if (data.items) setItemCatalog(data.items);
    if (data.cars) setCarCatalog(data.cars);
  }, [visible, data?.coins, data?.nextRewardSeconds, data?.items, data?.cars]);

  useEffect(() => {
    if (!visible) return;
    const id = window.setInterval(() => {
      setNextSec((s) => Math.max(0, s - 1));
    }, 1000);
    return () => window.clearInterval(id);
  }, [visible]);

  useEffect(() => {
    if (!visible) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        if (showTopModal) {
          setShowTopModal(false);
        } else {
          void nui("cfx-keydi-playtimeshop:close");
          onClose?.();
        }
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [visible, showTopModal, onClose]);

  const products = useMemo(() => {
    if (!shop) return [];
    return category === "cars" ? carCatalog || shop.cars || [] : itemCatalog || shop.items || [];
  }, [shop, category, itemCatalog, carCatalog]);

  const totalPages = Math.max(1, Math.ceil(products.length / pageSize));
  const pageSafe = Math.min(page, totalPages - 1);
  const pageItems = products.slice(pageSafe * pageSize, pageSafe * pageSize + pageSize);

  const flash = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2500);
  };

  const close = () => {
    void nui("cfx-keydi-playtimeshop:close");
    onClose?.();
  };

  const loadTop = useCallback(async () => {
    setLoadingTop(true);
    if (isBrowser()) {
      await new Promise((r) => setTimeout(r, 200));
      setTop([
        { rank: 1, name: "Ace Walker", coins: 420 },
        { rank: 2, name: "Nova Cruz", coins: 310 },
        { rank: 3, name: "Marcus Shaw", coins: 195 },
        { rank: 4, name: "Elena Ramos", coins: 140 },
        { rank: 5, name: "Karl Dev", coins: 95 },
        { rank: 6, name: "Leo Vance", coins: 70 },
        { rank: 7, name: "Chloe King", coins: 55 },
        { rank: 8, name: "Dexter Morgan", coins: 40 },
        { rank: 9, name: "Sarah Connor", coins: 25 },
        { rank: 10, name: "John Wick", coins: 15 },
      ]);
      setLoadingTop(false);
      return;
    }
    const rows = await nui<TopEarner[]>("cfx-keydi-playtimeshop:top");
    setTop(rows || []);
    setLoadingTop(false);
  }, []);

  const openLeaderboard = async () => {
    setShowTopModal(true);
    await loadTop();
  };

  const buy = async (product: PlaytimeProduct) => {
    if (buying) return;
    if (typeof product.stock === "number" && product.stock < 1) {
      flash("Out of stock!");
      return;
    }
    if (coins < product.price) {
      flash("Not enough Grim Coins!");
      return;
    }
    setBuying(product.id);

    if (isBrowser()) {
      setCoins((c) => c - product.price);
      if (typeof product.stock === "number") {
        const bump = (prev: PlaytimeProduct[] | null, fallback: PlaytimeProduct[] | undefined) =>
          (prev || fallback || []).map((row) =>
            row.id === product.id && typeof row.stock === "number"
              ? { ...row, stock: Math.max(0, row.stock - 1) }
              : row,
          );
        if (category === "cars") setCarCatalog((prev) => bump(prev, MOCK.cars));
        else setItemCatalog((prev) => bump(prev, MOCK.items));
      }
      flash(`Purchased ${product.label} (Preview)`);
      setBuying(null);
      return;
    }

    const result = await nui<{
      ok: boolean;
      coins?: number;
      error?: string;
      nextRewardSeconds?: number;
      items?: PlaytimeProduct[];
      cars?: PlaytimeProduct[];
    }>("cfx-keydi-playtimeshop:buy", { category, id: product.id });

    if (result?.ok) {
      if (typeof result.coins === "number") setCoins(result.coins);
      if (typeof result.nextRewardSeconds === "number") setNextSec(result.nextRewardSeconds);
      if (result.items) setItemCatalog(result.items);
      if (result.cars) setCarCatalog(result.cars);
      flash(`Successfully redeemed ${product.label}!`);
    } else {
      if (result?.items) setItemCatalog(result.items);
      if (result?.cars) setCarCatalog(result.cars);
      flash(
        result?.error === "insufficient"
          ? "Not enough Grim Coins!"
          : result?.error === "inventory_full"
            ? "Your inventory is full!"
            : result?.error === "out_of_stock"
              ? "Out of stock!"
              : "Redemption failed.",
      );
    }
    setBuying(null);
  };

  if (!visible || !shop) return null;

  // Cycle progress calculation for progress bar
  const elapsed = Math.max(0, totalCycleSeconds - nextSec);
  const cyclePercent = Math.min(100, Math.max(0, (elapsed / totalCycleSeconds) * 100));

  return (
    <div className="fixed inset-0 z-[100050] flex items-center justify-center bg-[#05060a]/80 p-6 font-sans pointer-events-auto select-none animate-fade-in backdrop-blur-[10px]">
      <div className="relative flex h-[min(740px,92vh)] w-full max-w-6xl flex-col overflow-hidden rounded-[28px] border border-[#f5c542]/20 bg-[#0c0e14] shadow-[0_40px_120px_rgba(0,0,0,0.75),0_0_80px_rgba(245,197,66,0.08)]">
        <div className="pointer-events-none absolute -top-24 left-1/2 h-64 w-[520px] -translate-x-1/2 rounded-full bg-[#f5c542]/12 blur-3xl" />
        <div className="pointer-events-none absolute -bottom-28 -right-16 h-56 w-56 rounded-full bg-[#c99212]/10 blur-3xl" />

        <header className="relative z-10 flex shrink-0 items-center justify-between gap-4 border-b border-white/5 px-6 py-4">
          <div className="flex items-center gap-4">
            <img
              src={grimCoin}
              alt="Grim Coin"
              className="h-[72px] w-[72px] object-contain drop-shadow-[0_8px_20px_rgba(245,197,66,0.4)]"
              draggable={false}
            />
            <div>
              <span className="text-[10px] font-black uppercase tracking-[0.28em] text-[#f5c542]">
                Grim City · Reward Vault
              </span>
              <h1 className="text-[28px] font-black leading-none tracking-tight text-[#f8f3e8]">
                Playtime Shop
              </h1>
              <p className="mt-1 text-xs text-[#9a9386]">
                Stay online, stack Grim Coins, redeem loot.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="rounded-2xl border border-[#f5c542]/25 bg-[#f5c542]/8 px-4 py-2.5">
              <p className="text-[9px] font-black uppercase tracking-[0.18em] text-[#f5c542]">
                Your vault
              </p>
              <div className="mt-0.5 flex items-center gap-2">
                <CoinIcon className="h-7 w-7" />
                <span className="text-2xl font-black tabular-nums text-white">
                  {coins.toLocaleString()}
                </span>
              </div>
            </div>
            <button
              type="button"
              onClick={close}
              className="flex h-10 cursor-pointer items-center gap-1.5 rounded-xl border border-white/10 bg-white/5 px-3 text-[11px] font-semibold text-white/70 transition hover:border-[#f5c542]/40 hover:text-white"
            >
              Esc
              <X className="h-3.5 w-3.5 text-[#f5c542]" />
            </button>
          </div>
        </header>

        <div className="relative z-10 flex min-h-0 flex-1">
          <aside className="flex w-[280px] shrink-0 flex-col justify-between border-r border-white/5 p-5">
            <div className="space-y-3">
              <div className="rounded-2xl border border-white/6 bg-[#141720] px-3.5 py-3">
                <span className="text-[9px] font-black uppercase tracking-[0.16em] text-[#9a9386]">
                  Citizen
                </span>
                <div className="mt-1.5 flex items-center gap-2 text-white">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-[#f5c542]/15 text-[#f5c542]">
                    <User className="h-4 w-4" />
                  </div>
                  <span className="truncate text-sm font-bold">{shop.playerName || "Citizen"}</span>
                </div>
              </div>

              <div className="rounded-2xl border border-[#f5c542]/20 bg-gradient-to-br from-[#f5c542]/10 to-transparent px-3.5 py-3">
                <div className="flex items-center justify-between">
                  <span className="text-[9px] font-black uppercase tracking-[0.16em] text-[#f5c542]">
                    Next drop
                  </span>
                  <span className="flex items-center gap-1 text-[10px] font-black text-[#f5c542]">
                    <Sparkles className="h-3 w-3" /> +{rewardCoins}
                  </span>
                </div>
                <div className="mt-1.5 flex items-center justify-between text-white">
                  <div className="flex items-center gap-2">
                    <Clock3 className="h-4 w-4 text-[#f5c542]" />
                    <span className="text-lg font-black tabular-nums">{formatTime(nextSec)}</span>
                  </div>
                  <span className="text-[10px] text-[#9a9386]">every {rewardMinutes}m</span>
                </div>
                <div className="mt-2.5 h-1.5 overflow-hidden rounded-full bg-black/50">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-[#c99212] to-[#f5c542] transition-all duration-500"
                    style={{ width: `${cyclePercent}%` }}
                  />
                </div>
              </div>

              <button
                type="button"
                onClick={() => void openLeaderboard()}
                className="group flex w-full cursor-pointer items-center justify-between rounded-2xl border border-white/6 bg-[#141720] px-3.5 py-3 text-left transition hover:border-[#f5c542]/40 hover:bg-[#f5c542]/8"
              >
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-[#f5c542]/15 text-[#f5c542]">
                    <Trophy className="h-4 w-4" />
                  </div>
                  <div>
                    <p className="text-xs font-black uppercase tracking-wider text-white">Top earners</p>
                    <p className="text-[10px] text-[#9a9386]">City leaderboard</p>
                  </div>
                </div>
                <span className="text-[10px] font-black uppercase text-[#f5c542]">View</span>
              </button>
            </div>

            <p className="text-center text-[10px] tracking-[0.14em] text-[#6f685c]">
              Powered by <strong className="text-[#f5c542]">KodeByKarl.Net</strong>
            </p>
          </aside>

          <main className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden p-5">
            <div className="mb-4 flex shrink-0 items-center justify-between">
              <div>
                <span className="text-[10px] font-black uppercase tracking-[0.22em] text-[#f5c542]">
                  {category === "cars" ? "Project build" : "Street kit"}
                </span>
                <h2 className="text-lg font-black uppercase tracking-tight text-[#f8f3e8]">
                  {category === "cars" ? "Car parts" : "Item catalog"}
                </h2>
              </div>

              <div className="flex rounded-2xl border border-white/8 bg-[#141720] p-1">
                <button
                  type="button"
                  onClick={() => {
                    setCategory("items");
                    setPage(0);
                  }}
                  className={cn(
                    "flex cursor-pointer items-center gap-2 rounded-xl px-3.5 py-1.5 text-xs font-black uppercase tracking-wider transition",
                    category === "items"
                      ? "bg-[#f5c542] text-[#1a1406] shadow-[0_6px_18px_rgba(245,197,66,0.28)]"
                      : "text-[#9a9386] hover:text-white",
                  )}
                >
                  <Package className="h-3.5 w-3.5" />
                  Items
                  <span className="rounded-md bg-black/20 px-1.5 text-[9px]">
                    {(itemCatalog || shop.items)?.length || 0}
                  </span>
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setCategory("cars");
                    setPage(0);
                  }}
                  className={cn(
                    "flex cursor-pointer items-center gap-2 rounded-xl px-3.5 py-1.5 text-xs font-black uppercase tracking-wider transition",
                    category === "cars"
                      ? "bg-[#f5c542] text-[#1a1406] shadow-[0_6px_18px_rgba(245,197,66,0.28)]"
                      : "text-[#9a9386] hover:text-white",
                  )}
                >
                  <Car className="h-3.5 w-3.5" />
                  Cars
                  <span className="rounded-md bg-black/20 px-1.5 text-[9px]">
                    {(carCatalog || shop.cars)?.length || 0}
                  </span>
                </button>
              </div>
            </div>

            <div className="grid min-h-0 flex-1 grid-cols-3 content-start gap-3 overflow-y-auto pb-2 pr-1">
              {pageItems.map((p) => {
                const canAfford = coins >= p.price;
                const inStock = typeof p.stock !== "number" || p.stock > 0;
                const canBuy = canAfford && inStock;
                const isBuying = buying === p.id;
                const showVehicleArt = Boolean(p.model) && p.kind !== "part";

                return (
                  <div
                    key={p.id}
                    className="group relative flex min-h-0 flex-col justify-between rounded-2xl border border-white/6 bg-[#141720] p-3 transition hover:border-[#f5c542]/35 hover:bg-[#1a1d28]"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <p className="truncate text-xs font-black uppercase tracking-wide text-[#f8f3e8]">
                        {p.label}
                      </p>
                      <div className="flex shrink-0 flex-col items-end gap-1">
                        <span className="rounded-md bg-[#f5c542]/12 px-1.5 py-0.5 text-[10px] font-black text-[#f5c542]">
                          {showVehicleArt ? "1x" : `${p.amount || 1}x`}
                        </span>
                        {typeof p.stock === "number" && (
                          <span
                            className={cn(
                              "rounded-md px-1.5 py-0.5 text-[9px] font-black uppercase",
                              p.stock > 0
                                ? "bg-white/8 text-[#9a9386]"
                                : "bg-red-500/15 text-red-300",
                            )}
                          >
                            {p.stock > 0 ? `${p.stock} left` : "Sold out"}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="my-2 flex h-[88px] w-full items-center justify-center overflow-hidden rounded-xl bg-black/35">
                      {showVehicleArt ? (
                        <CarImageDisplay model={p.model} id={p.id} label={p.label} />
                      ) : (
                        <ItemImageDisplay image={p.image} id={p.id} />
                      )}
                    </div>

                    <div className="mt-auto flex items-center justify-between gap-2 border-t border-white/6 pt-2">
                      <div className="flex items-center gap-1.5">
                        <CoinIcon className="h-5 w-5" />
                        <span className="text-sm font-black text-white">{p.price}</span>
                      </div>
                      <button
                        type="button"
                        disabled={isBuying || !canBuy}
                        onClick={() => void buy(p)}
                        className={cn(
                          "rounded-lg px-3.5 py-1.5 text-xs font-black uppercase tracking-wider transition",
                          canBuy
                            ? "cursor-pointer bg-[#f5c542] text-[#1a1406] hover:brightness-110 active:scale-95"
                            : "cursor-not-allowed bg-white/5 text-white/35",
                        )}
                      >
                        {isBuying ? "..." : !inStock ? "Sold out" : canAfford ? "Redeem" : "Locked"}
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="relative z-10 mt-3 flex shrink-0 items-center justify-between border-t border-white/8 bg-[#0c0e14] pt-3">
              <button
                type="button"
                disabled={pageSafe <= 0}
                onClick={() => setPage((p) => Math.max(0, p - 1))}
                className="flex cursor-pointer items-center gap-1.5 rounded-xl border border-white/8 bg-[#141720] px-3.5 py-1.5 text-xs font-bold uppercase text-white/90 transition hover:border-[#f5c542]/40 disabled:cursor-not-allowed disabled:opacity-30"
              >
                <ChevronLeft className="h-4 w-4" />
                Prev
              </button>
              <span className="text-xs font-black uppercase tracking-widest text-[#9a9386]">
                Page <strong className="text-white">{pageSafe + 1}</strong> /{" "}
                <strong className="text-[#f5c542]">{totalPages}</strong>
              </span>
              <button
                type="button"
                disabled={pageSafe >= totalPages - 1}
                onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                className="flex cursor-pointer items-center gap-1.5 rounded-xl border border-white/8 bg-[#141720] px-3.5 py-1.5 text-xs font-bold uppercase text-white/90 transition hover:border-[#f5c542]/40 disabled:cursor-not-allowed disabled:opacity-30"
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </main>
        </div>
      </div>

      {showTopModal && (
        <div className="fixed inset-0 z-[100060] flex items-center justify-center bg-black/75 p-4 backdrop-blur-[6px] animate-fade-in pointer-events-auto">
          <div className="relative w-full max-w-lg overflow-hidden rounded-[24px] border border-[#f5c542]/25 bg-[#101218] p-6 shadow-[0_30px_90px_rgba(0,0,0,0.85)]">
            <div className="flex items-start justify-between border-b border-white/6 pb-4">
              <div className="flex items-center gap-3">
                <img src={grimCoin} alt="" className="h-12 w-12 object-contain" draggable={false} />
                <div>
                  <span className="text-[10px] font-black uppercase tracking-[0.2em] text-[#f5c542]">
                    Grim Coin ranks
                  </span>
                  <h3 className="text-xl font-black uppercase tracking-tight text-white">Top 10 earners</h3>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowTopModal(false)}
                className="rounded-lg border border-white/10 bg-white/5 p-1.5 text-white/60 transition hover:border-[#f5c542]/40 hover:text-white"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="my-4 max-h-[360px] space-y-2 overflow-y-auto pr-1">
              {loadingTop ? (
                <div className="py-12 text-center text-xs font-bold text-[#9a9386]">Loading top earners...</div>
              ) : top.length === 0 ? (
                <div className="py-12 text-center text-xs font-bold text-[#9a9386]">No Grim Coins recorded yet.</div>
              ) : (
                top.map((t) => {
                  const isGold = t.rank === 1;
                  const isSilver = t.rank === 2;
                  const isBronze = t.rank === 3;

                  return (
                    <div
                      key={`${t.rank}-${t.name}`}
                      className={cn(
                        "flex items-center justify-between rounded-xl px-4 py-2.5",
                        isGold && "border border-[#f5c542]/50 bg-[#f5c542]/10",
                        isSilver && "border border-[#e2e8f0]/30 bg-white/4",
                        isBronze && "border border-[#cd7f32]/40 bg-[#cd7f32]/10",
                        !isGold && !isSilver && !isBronze && "border border-white/5 bg-[#141720]",
                      )}
                    >
                      <div className="flex items-center gap-3">
                        {isGold ? (
                          <div className="flex h-7 w-7 items-center justify-center rounded-full bg-[#f5c542] text-[#1a1406]">
                            <Crown className="h-4 w-4" />
                          </div>
                        ) : isSilver ? (
                          <div className="flex h-7 w-7 items-center justify-center rounded-full bg-[#cbd5e1] text-black">
                            <Medal className="h-4 w-4" />
                          </div>
                        ) : isBronze ? (
                          <div className="flex h-7 w-7 items-center justify-center rounded-full bg-[#cd7f32] text-white">
                            <Medal className="h-4 w-4" />
                          </div>
                        ) : (
                          <span className="flex h-7 w-7 items-center justify-center rounded-full bg-white/5 text-xs font-black text-white/45">
                            #{t.rank}
                          </span>
                        )}
                        <div>
                          <p className="text-sm font-bold text-white">{t.name}</p>
                          <p className="text-[10px] font-semibold text-[#9a9386]">
                            {isGold ? "Champion" : `Rank #${t.rank}`}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1.5 font-black text-[#f5c542]">
                        <CoinIcon className="h-5 w-5" />
                        <span className="text-sm">{t.coins.toLocaleString()}</span>
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            <div className="flex items-center justify-between border-t border-white/6 pt-3">
              <span className="text-[10px] text-[#9a9386]">Stay active to climb the vault ranks.</span>
              <button
                type="button"
                onClick={() => setShowTopModal(false)}
                className="cursor-pointer rounded-lg bg-[#f5c542] px-4 py-1.5 text-xs font-black uppercase text-[#1a1406]"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {toast ? (
        <div className="pointer-events-none fixed bottom-10 left-1/2 z-[100070] -translate-x-1/2 rounded-full border border-[#f5c542]/40 bg-[#12141c] px-5 py-2.5 text-xs font-black uppercase tracking-wider text-[#f8f3e8] shadow-[0_10px_30px_rgba(245,197,66,0.2)] animate-fade-in">
          {toast}
        </div>
      ) : null}
    </div>
  );
}
