import React, { useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import {
  Banknote,
  CreditCard,
  Minus,
  Package,
  Plus,
  Search,
  ShoppingCart,
  Trash2,
  X,
} from "lucide-react";

export interface MarketItem {
  item: string;
  label: string;
  category: string;
  price: number;
  count: number;
  image?: string;
}

export interface MarketData {
  items?: MarketItem[];
}

export interface MarketMenuProps {
  visible?: boolean;
  data?: MarketData;
  onClose?: () => void;
}

interface CartEntry {
  item: string;
  label: string;
  price: number;
  amount: number;
  max: number;
  image?: string;
}

const MOCK: MarketData = {
  items: [
    {
      item: "orange",
      label: "Orange",
      category: "Farming",
      price: 55,
      count: 12,
      image: "nui://ox_inventory/web/images/orange.png",
    },
    {
      item: "wood",
      label: "Wood",
      category: "Lumber",
      price: 60,
      count: 8,
      image: "nui://ox_inventory/web/images/wood.png",
    },
    {
      item: "raw_meat",
      label: "Raw Meat",
      category: "Hunting",
      price: 75,
      count: 3,
      image: "nui://ox_inventory/web/images/raw_meat.png",
    },
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

const formatMoney = (n: number) =>
  `$${Math.max(0, Math.floor(n || 0)).toLocaleString()}`;

function ItemThumb({
  image,
  label,
  item,
}: {
  image?: string;
  label: string;
  item: string;
}) {
  const [failed, setFailed] = useState(false);
  const src = image || `nui://ox_inventory/web/images/${item}.png`;

  if (failed) {
    return (
      <div className="flex h-full w-full flex-col items-center justify-center text-[#8b8374]">
        <Package className="mb-1 h-8 w-8 text-[#f5c542]/50" />
        <span className="text-[10px] font-bold uppercase tracking-wider text-white/45">
          {item}
        </span>
      </div>
    );
  }

  return (
    <img
      src={src}
      alt={label}
      className="max-h-[88px] max-w-[88px] object-contain drop-shadow-[0_4px_10px_rgba(0,0,0,0.7)] transition-transform duration-200 group-hover:scale-105"
      onError={() => setFailed(true)}
      loading="lazy"
      draggable={false}
    />
  );
}

export const MarketMenu: React.FC<MarketMenuProps> = ({
  visible = true,
  data,
  onClose,
}) => {
  const [items, setItems] = useState<MarketItem[]>([]);
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [cart, setCart] = useState<CartEntry[]>([]);

  const shop = data || (isBrowser() ? MOCK : null);

  useEffect(() => {
    if (!visible) return;
    setItems(shop?.items || []);
    setSelectedCategory("all");
    setSearchQuery("");
    setCart([]);
  }, [visible, shop]);

  useEffect(() => {
    if (!visible) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        void nui("cfx-keydi-market:close");
        onClose?.();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [visible, onClose]);

  const categories = useMemo(() => {
    const set = new Set(items.map((i) => i.category || "General"));
    return ["all", ...Array.from(set)];
  }, [items]);

  const filtered = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return items.filter((i) => {
      const catOk =
        selectedCategory === "all" || i.category === selectedCategory;
      const searchOk =
        !q ||
        i.label.toLowerCase().includes(q) ||
        i.item.toLowerCase().includes(q);
      return catOk && searchOk;
    });
  }, [items, selectedCategory, searchQuery]);

  const cartTotal = useMemo(
    () => cart.reduce((sum, row) => sum + row.price * row.amount, 0),
    [cart],
  );

  const cartCount = useMemo(
    () => cart.reduce((sum, row) => sum + row.amount, 0),
    [cart],
  );

  const handleClose = () => {
    void nui("cfx-keydi-market:close");
    onClose?.();
  };

  const addToCart = (entry: MarketItem) => {
    if ((entry.count || 0) < 1) return;
    setCart((prev) => {
      const existing = prev.find((c) => c.item === entry.item);
      if (existing) {
        if (existing.amount >= entry.count) return prev;
        return prev.map((c) =>
          c.item === entry.item
            ? {
                ...c,
                amount: Math.min(entry.count, c.amount + 1),
                max: entry.count,
              }
            : c,
        );
      }
      return [
        ...prev,
        {
          item: entry.item,
          label: entry.label,
          price: entry.price,
          amount: 1,
          max: entry.count,
          image: entry.image,
        },
      ];
    });
  };

  const setCartAmount = (item: string, amount: number) => {
    setCart((prev) =>
      prev
        .map((c) => {
          if (c.item !== item) return c;
          const next = Math.max(0, Math.min(c.max, Math.floor(amount)));
          return { ...c, amount: next };
        })
        .filter((c) => c.amount > 0),
    );
  };

  const removeFromCart = (item: string) => {
    setCart((prev) => prev.filter((c) => c.item !== item));
  };

  const sellAllOwned = (entry: MarketItem) => {
    if ((entry.count || 0) < 1) return;
    setCart((prev) => {
      const without = prev.filter((c) => c.item !== entry.item);
      return [
        ...without,
        {
          item: entry.item,
          label: entry.label,
          price: entry.price,
          amount: entry.count,
          max: entry.count,
          image: entry.image,
        },
      ];
    });
  };

  const handleCheckout = (payout: "cash" | "bank") => {
    if (cart.length < 1 || cartTotal < 1) return;
    void nui("cfx-keydi-market:sell", {
      cart: cart.map((c) => ({ item: c.item, amount: c.amount })),
      payout,
    });
    setCart([]);
  };

  if (!visible || (!shop && !isBrowser())) return null;

  return (
    <div className="fixed inset-0 z-[100050] flex items-center justify-center bg-[#05060a]/80 p-6 font-sans pointer-events-auto select-none animate-fade-in backdrop-blur-[10px]">
      <div className="relative flex h-[min(740px,92vh)] w-full max-w-6xl flex-col overflow-hidden rounded-[28px] border border-[#f5c542]/20 bg-[#0c0e14] shadow-[0_40px_120px_rgba(0,0,0,0.75),0_0_80px_rgba(245,197,66,0.08)]">
        <div className="pointer-events-none absolute -top-24 left-1/2 h-64 w-[520px] -translate-x-1/2 rounded-full bg-[#f5c542]/12 blur-3xl" />
        <div className="pointer-events-none absolute -bottom-28 -right-16 h-56 w-56 rounded-full bg-[#c99212]/10 blur-3xl" />

        <header className="relative z-10 flex shrink-0 items-center justify-between gap-4 border-b border-white/5 px-6 py-4">
          <div className="flex items-center gap-4">
            <div className="flex h-[64px] w-[64px] items-center justify-center rounded-2xl border border-[#f5c542]/25 bg-[#f5c542]/10 shadow-[0_8px_20px_rgba(245,197,66,0.2)]">
              <ShoppingCart className="h-7 w-7 text-[#f5c542]" />
            </div>
            <div>
              <span className="text-[10px] font-black uppercase tracking-[0.28em] text-[#f5c542]">
                Grim City · Sell stall
              </span>
              <h1 className="text-[28px] font-black leading-none tracking-tight text-[#f8f3e8]">
                Sell Market
              </h1>
              <p className="mt-1 text-xs text-[#9a9386]">
                Cash out autofarm &amp; raven grind loot.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="rounded-2xl border border-[#f5c542]/25 bg-[#f5c542]/8 px-4 py-2.5">
              <p className="text-[9px] font-black uppercase tracking-[0.18em] text-[#f5c542]">
                Cart value
              </p>
              <div className="mt-0.5 flex items-center gap-2">
                <Banknote className="h-5 w-5 text-[#f5c542]" />
                <span className="text-2xl font-black tabular-nums text-white">
                  {formatMoney(cartTotal)}
                </span>
              </div>
            </div>
            <button
              type="button"
              onClick={handleClose}
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
                  Sources
                </span>
                <p className="mt-1.5 text-sm font-bold text-white">Autofarm · Raven</p>
                <p className="mt-1 text-[11px] leading-relaxed text-[#9a9386]">
                  Orange, wood, and raw meat only. Grind it, sell it here.
                </p>
              </div>

              <div className="rounded-2xl border border-[#f5c542]/20 bg-gradient-to-br from-[#f5c542]/10 to-transparent px-3.5 py-3">
                <span className="text-[9px] font-black uppercase tracking-[0.16em] text-[#f5c542]">
                  In cart
                </span>
                <div className="mt-1.5 flex items-center justify-between text-white">
                  <div className="flex items-center gap-2">
                    <Package className="h-4 w-4 text-[#f5c542]" />
                    <span className="text-lg font-black tabular-nums">{cartCount}</span>
                  </div>
                  <span className="text-[10px] text-[#9a9386]">units</span>
                </div>
              </div>

              <div className="space-y-1.5">
                <span className="px-1 text-[9px] font-black uppercase tracking-[0.16em] text-[#9a9386]">
                  Category
                </span>
                <div className="flex flex-col gap-1">
                  {categories.map((cat) => (
                    <button
                      key={cat}
                      type="button"
                      onClick={() => setSelectedCategory(cat)}
                      className={cn(
                        "flex cursor-pointer items-center justify-between rounded-xl px-3 py-2 text-left text-xs font-black uppercase tracking-wider transition",
                        selectedCategory === cat
                          ? "bg-[#f5c542] text-[#1a1406] shadow-[0_6px_18px_rgba(245,197,66,0.28)]"
                          : "border border-white/6 bg-[#141720] text-[#9a9386] hover:border-[#f5c542]/30 hover:text-white",
                      )}
                    >
                      <span>{cat === "all" ? "All loot" : cat}</span>
                      <span
                        className={cn(
                          "rounded-md px-1.5 text-[9px]",
                          selectedCategory === cat ? "bg-black/20" : "bg-white/5",
                        )}
                      >
                        {cat === "all"
                          ? items.length
                          : items.filter((i) => i.category === cat).length}
                      </span>
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <p className="text-center text-[10px] tracking-[0.14em] text-[#6f685c]">
              Powered by <strong className="text-[#f5c542]">KodeByKarl.Net</strong>
            </p>
          </aside>

          <main className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden">
            <div className="flex shrink-0 items-center justify-between gap-3 border-b border-white/5 px-5 py-3">
              <div>
                <span className="text-[10px] font-black uppercase tracking-[0.22em] text-[#f5c542]">
                  Catalog
                </span>
                <h2 className="text-lg font-black uppercase tracking-tight text-[#f8f3e8]">
                  Grind listings
                </h2>
              </div>

              <div className="relative w-full max-w-[240px]">
                <Search className="pointer-events-none absolute left-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[#f5c542]" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search loot..."
                  className="w-full rounded-xl border border-white/8 bg-[#141720] py-2 pl-9 pr-3 text-xs text-white placeholder:text-[#6f685c] outline-none transition focus:border-[#f5c542]/40"
                />
              </div>
            </div>

            <div className="flex min-h-0 flex-1 overflow-hidden">
              <div className="no-scrollbar min-h-0 flex-1 overflow-y-auto overflow-x-hidden p-5">
                {filtered.length === 0 ? (
                  <div className="flex h-full min-h-[280px] flex-col items-center justify-center text-center">
                    <Package className="mb-2 h-12 w-12 text-[#f5c542]/35" />
                    <div className="text-sm font-bold text-[#f8f3e8]">No loot found</div>
                    <div className="mt-1 max-w-xs text-xs text-[#9a9386]">
                      Harvest oranges, chop wood, or hunt with raven — then sell here.
                    </div>
                  </div>
                ) : (
                  <div className="grid grid-cols-2 content-start gap-3 xl:grid-cols-3">
                    {filtered.map((entry) => {
                      const owned = entry.count || 0;
                      const disabled = owned < 1;
                      return (
                        <div
                          key={entry.item}
                          className={cn(
                            "group flex flex-col rounded-2xl border border-white/6 bg-[#141720] p-3.5 transition",
                            disabled
                              ? "opacity-45"
                              : "hover:border-[#f5c542]/35 hover:bg-[#f5c542]/6",
                          )}
                        >
                          <div className="mb-2 flex items-start justify-between gap-2">
                            <div className="min-w-0">
                              <p className="text-[9px] font-black uppercase tracking-[0.16em] text-[#f5c542]">
                                {entry.category}
                              </p>
                              <h3 className="truncate text-sm font-black uppercase tracking-tight text-[#f8f3e8]">
                                {entry.label}
                              </h3>
                            </div>
                            <span className="shrink-0 rounded-md bg-black/30 px-1.5 py-0.5 text-[10px] font-black tabular-nums text-[#9a9386]">
                              {owned}x
                            </span>
                          </div>

                          <div className="mb-3 flex h-[88px] items-center justify-center rounded-xl bg-black/25">
                            <ItemThumb
                              image={entry.image}
                              label={entry.label}
                              item={entry.item}
                            />
                          </div>

                          <div className="mb-3 flex items-baseline gap-1.5">
                            <span className="text-lg font-black tabular-nums text-[#f5c542]">
                              {formatMoney(entry.price)}
                            </span>
                            <span className="text-[10px] font-bold uppercase tracking-wider text-[#6f685c]">
                              / each
                            </span>
                          </div>

                          <div className="mt-auto flex items-center gap-2">
                            <button
                              type="button"
                              disabled={disabled}
                              onClick={() => sellAllOwned(entry)}
                              className="cursor-pointer rounded-xl border border-white/8 bg-black/30 px-2.5 py-2 text-[10px] font-black uppercase tracking-wider text-[#9a9386] transition hover:border-[#f5c542]/30 hover:text-white disabled:cursor-not-allowed"
                            >
                              All
                            </button>
                            <button
                              type="button"
                              disabled={disabled}
                              onClick={() => addToCart(entry)}
                              className="flex flex-1 cursor-pointer items-center justify-center gap-1.5 rounded-xl bg-[#f5c542] py-2 text-xs font-black uppercase tracking-wider text-[#1a1406] shadow-[0_6px_18px_rgba(245,197,66,0.28)] transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50"
                            >
                              <ShoppingCart className="h-3.5 w-3.5" />
                              Sell
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>

              <div className="flex w-[300px] shrink-0 flex-col overflow-hidden border-l border-white/5 bg-[#0a0c12]/80">
                <div className="flex items-center gap-2 border-b border-white/5 px-4 py-3.5">
                  <ShoppingCart className="h-4 w-4 text-[#f5c542]" />
                  <h2 className="text-sm font-black uppercase tracking-wider text-[#f8f3e8]">
                    Sell cart
                  </h2>
                </div>

                <div className="no-scrollbar min-h-0 flex-1 space-y-2 overflow-y-auto overflow-x-hidden px-3 py-3">
                  {cart.length === 0 ? (
                    <div className="flex h-full min-h-[160px] flex-col items-center justify-center px-4 text-center text-[#6f685c]">
                      <ShoppingCart className="mb-2 h-8 w-8 opacity-40" />
                      <div className="text-xs font-bold text-[#9a9386]">Cart is empty</div>
                      <div className="mt-1 text-[11px]">
                        Add loot to cash out at the stall.
                      </div>
                    </div>
                  ) : (
                    cart.map((row) => (
                      <div
                        key={row.item}
                        className="rounded-2xl border border-white/6 bg-[#141720] p-3"
                      >
                        <div className="mb-2 flex items-start justify-between gap-2">
                          <div className="min-w-0">
                            <div className="truncate text-xs font-black uppercase text-[#f8f3e8]">
                              {row.label}
                            </div>
                            <div className="text-[11px] font-mono text-[#f5c542]">
                              {formatMoney(row.price)} each
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => removeFromCart(row.item)}
                            className="cursor-pointer rounded-md p-1 text-[#6f685c] transition hover:text-[#f5c542]"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </button>
                        </div>

                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-1 rounded-xl border border-white/8 bg-black/30 p-0.5">
                            <button
                              type="button"
                              onClick={() => setCartAmount(row.item, row.amount - 1)}
                              className="flex h-7 w-7 cursor-pointer items-center justify-center rounded-lg hover:bg-white/5"
                            >
                              <Minus className="h-3.5 w-3.5" />
                            </button>
                            <span className="w-8 text-center text-xs font-black tabular-nums">
                              {row.amount}
                            </span>
                            <button
                              type="button"
                              onClick={() => setCartAmount(row.item, row.amount + 1)}
                              className="flex h-7 w-7 cursor-pointer items-center justify-center rounded-lg hover:bg-white/5"
                            >
                              <Plus className="h-3.5 w-3.5" />
                            </button>
                          </div>
                          <div className="text-sm font-black tabular-nums text-[#f5c542]">
                            {formatMoney(row.price * row.amount)}
                          </div>
                        </div>
                      </div>
                    ))
                  )}
                </div>

                <div className="shrink-0 space-y-3 border-t border-white/5 p-4">
                  <div className="flex items-center justify-between rounded-2xl border border-[#f5c542]/20 bg-[#f5c542]/8 px-3.5 py-3">
                    <span className="text-[10px] font-black uppercase tracking-[0.16em] text-[#f5c542]">
                      Total payout
                    </span>
                    <span className="text-xl font-black tabular-nums text-white">
                      {formatMoney(cartTotal)}
                    </span>
                  </div>

                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      disabled={cart.length < 1}
                      onClick={() => handleCheckout("cash")}
                      className="flex cursor-pointer items-center justify-center gap-1.5 rounded-2xl bg-[#f5c542] py-2.5 text-xs font-black uppercase tracking-wider text-[#1a1406] shadow-[0_6px_18px_rgba(245,197,66,0.28)] transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-40"
                    >
                      <Banknote className="h-4 w-4" />
                      Cash
                    </button>
                    <button
                      type="button"
                      disabled={cart.length < 1}
                      onClick={() => handleCheckout("bank")}
                      className="flex cursor-pointer items-center justify-center gap-1.5 rounded-2xl border border-white/10 bg-white/5 py-2.5 text-xs font-black uppercase tracking-wider text-white transition hover:border-[#f5c542]/40 disabled:cursor-not-allowed disabled:opacity-40"
                    >
                      <CreditCard className="h-4 w-4 text-[#f5c542]" />
                      Bank
                    </button>
                  </div>
                  <p className="text-center text-[10px] text-[#6f685c]">
                    Cash = pocket · Bank = account deposit
                  </p>
                </div>
              </div>
            </div>
          </main>
        </div>
      </div>
    </div>
  );
};

export default MarketMenu;
