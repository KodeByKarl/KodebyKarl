import React, { useCallback, useEffect, useState } from "react";
import {
  BatteryFull,
  Check,
  Loader2,
  RefreshCw,
  Signal,
  Tags,
  Wifi,
} from "lucide-react";
import type { IpadPlayerData } from "./Ipad";

interface MarketItem {
  item: string;
  label: string;
  category: string;
  price: number;
  minPrice: number;
  maxPrice: number;
  enabled?: boolean;
}

function useClock(enabled = true) {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    if (!enabled) return;
    const id = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(id);
  }, [enabled]);
  return now;
}

function StatusBar() {
  const now = useClock();
  const time = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  return (
    <div className="relative z-40 flex items-center justify-between px-6 pt-3.5 text-[12px] font-semibold tracking-tight text-black">
      <span className="min-w-12">{time}</span>
      <div className="w-25" />
      <div className="flex items-center gap-1 opacity-90">
        <Signal className="h-3 w-3" strokeWidth={2.4} />
        <Wifi className="h-3 w-3" strokeWidth={2.4} />
        <BatteryFull className="h-3.5 w-3.5" strokeWidth={2.2} />
      </div>
    </div>
  );
}

function isBrowser() {
  return (
    !(window as unknown as { invokeNative?: unknown }).invokeNative &&
    !navigator.userAgent.includes("FiveM") &&
    !navigator.userAgent.includes("CitizenFX")
  );
}

async function nui<T>(event: string, data: Record<string, unknown> = {}): Promise<T | null> {
  if (isBrowser()) {
    if (event.endsWith(":get") || event.endsWith(":reroll")) {
      return {
        ok: true,
        intervalMinutes: 120,
        nextUpdateAt: Math.floor(Date.now() / 1000) + 3600,
        items: [
          { item: "orange", label: "Orange", category: "Farming", price: 55, minPrice: 30, maxPrice: 80, enabled: true },
          { item: "wood", label: "Wood", category: "Lumber", price: 60, minPrice: 35, maxPrice: 85, enabled: true },
          { item: "raw_meat", label: "Raw Meat", category: "Hunting", price: 75, minPrice: 50, maxPrice: 100, enabled: true },
        ],
      } as T;
    }
    return { ok: true, item: data } as T;
  }

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

function formatMoney(n: number) {
  return `$${Math.max(0, Math.floor(n || 0)).toLocaleString()}`;
}

export default function MarketAdminApp({ player }: { player?: IpadPlayerData | null }) {
  const [items, setItems] = useState<MarketItem[]>([]);
  const [drafts, setDrafts] = useState<Record<string, { min: string; max: string; price: string }>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);
  const [rerolling, setRerolling] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [nextUpdateAt, setNextUpdateAt] = useState(0);
  const [intervalMinutes, setIntervalMinutes] = useState(120);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2800);
  }, []);

  const applyCatalog = useCallback((list: MarketItem[], meta?: { nextUpdateAt?: number; intervalMinutes?: number }) => {
    setItems(list);
    const next: Record<string, { min: string; max: string; price: string }> = {};
    for (const row of list) {
      next[row.item] = {
        min: String(row.minPrice),
        max: String(row.maxPrice),
        price: String(row.price),
      };
    }
    setDrafts(next);
    if (meta?.nextUpdateAt) setNextUpdateAt(meta.nextUpdateAt);
    if (meta?.intervalMinutes) setIntervalMinutes(meta.intervalMinutes);
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    const res = await nui<{
      ok?: boolean;
      error?: string;
      items?: MarketItem[];
      nextUpdateAt?: number;
      intervalMinutes?: number;
    }>("cfx-keydi-ipad:market:get");
    if (res?.ok && res.items) {
      applyCatalog(res.items, res);
    } else {
      showToast(res?.error === "denied" ? "Access denied" : "Failed to load market");
      applyCatalog([]);
    }
    setLoading(false);
  }, [applyCatalog, showToast]);

  useEffect(() => {
    void load();
  }, [load]);

  const saveItem = async (item: string) => {
    const d = drafts[item];
    if (!d) return;
    let minPrice = Math.max(1, Math.floor(Number(String(d.min).replace(/[^\d]/g, "")) || 1));
    let maxPrice = Math.max(1, Math.floor(Number(String(d.max).replace(/[^\d]/g, "")) || minPrice));
    if (maxPrice < minPrice) {
      const t = minPrice;
      minPrice = maxPrice;
      maxPrice = t;
    }
    let price = Math.floor(Number(String(d.price).replace(/[^\d]/g, "")) || minPrice);
    if (price < minPrice) price = minPrice;
    if (price > maxPrice) price = maxPrice;

    setSaving(item);
    const res = await nui<{ ok?: boolean; error?: string; item?: MarketItem }>(
      "cfx-keydi-ipad:market:setRange",
      { item, minPrice, maxPrice, price },
    );
    setSaving(null);

    if (!res?.ok || !res.item) {
      showToast(res?.error === "denied" ? "Access denied" : "Save failed");
      return;
    }

    setItems((prev) => prev.map((r) => (r.item === item ? { ...r, ...res.item! } : r)));
    setDrafts((prev) => ({
      ...prev,
      [item]: {
        min: String(res.item!.minPrice),
        max: String(res.item!.maxPrice),
        price: String(res.item!.price),
      },
    }));
    showToast(`${res.item.label} updated`);
  };

  const reroll = async () => {
    setRerolling(true);
    const res = await nui<{
      ok?: boolean;
      error?: string;
      items?: MarketItem[];
      nextUpdateAt?: number;
      intervalMinutes?: number;
    }>("cfx-keydi-ipad:market:reroll");
    setRerolling(false);
    if (res?.ok && res.items) {
      applyCatalog(res.items, res);
      showToast("Prices rerolled for everyone");
    } else {
      showToast(res?.error === "denied" ? "Access denied" : "Reroll failed");
    }
  };

  const countdown = (() => {
    if (!nextUpdateAt) return "—";
    const remaining = Math.max(0, Math.floor(nextUpdateAt - Date.now() / 1000));
    const h = Math.floor(remaining / 3600);
    const m = Math.floor((remaining % 3600) / 60);
    if (h > 0) return `${h}h ${m}m`;
    if (m > 0) return `${m}m`;
    return `${remaining}s`;
  })();

  return (
    <div className="absolute inset-0 flex flex-col select-none bg-[#0c0e14]">
      <StatusBar />
      <div className="border-b border-white/8 px-4 pb-3 pt-2">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-[18px] font-bold text-[#f8f3e8]">Sell Market</p>
            <p className="text-[11px] text-[#9a9386]">
              Owner / Developer · ranges save to database
              {player?.firstName ? ` · ${player.firstName}` : ""}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => void load()}
              className="flex h-9 w-9 items-center justify-center rounded-full bg-white/8 text-[#f8f3e8] active:scale-95"
              title="Refresh"
            >
              <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
            </button>
            <button
              type="button"
              disabled={rerolling}
              onClick={() => void reroll()}
              className="rounded-full bg-[#f5c542] px-3.5 py-2 text-[12px] font-black text-[#1a1408] disabled:opacity-50"
            >
              {rerolling ? "Rolling…" : "Reroll now"}
            </button>
          </div>
        </div>
        <div className="mt-3 flex gap-2">
          <div className="flex-1 rounded-xl border border-white/8 bg-[#141720] px-3 py-2">
            <p className="text-[9px] font-black uppercase tracking-wider text-[#9a9386]">Next auto roll</p>
            <p className="text-[14px] font-semibold text-[#f8f3e8]">{countdown}</p>
          </div>
          <div className="flex-1 rounded-xl border border-white/8 bg-[#141720] px-3 py-2">
            <p className="text-[9px] font-black uppercase tracking-wider text-[#9a9386]">Interval</p>
            <p className="text-[14px] font-semibold text-[#f8f3e8]">{intervalMinutes}m</p>
          </div>
        </div>
      </div>

      <div className="no-scrollbar min-h-0 flex-1 space-y-2.5 overflow-y-auto px-4 py-3 pb-10">
        {loading && items.length === 0 ? (
          <div className="flex items-center justify-center gap-2 py-16 text-[#9a9386]">
            <Loader2 className="h-4 w-4 animate-spin" />
            Loading market…
          </div>
        ) : items.length === 0 ? (
          <div className="rounded-2xl border border-white/8 bg-[#141720] px-4 py-12 text-center">
            <Tags className="mx-auto mb-2 h-8 w-8 text-[#5c564c]" />
            <p className="text-[13px] text-[#9a9386]">No market items in database.</p>
          </div>
        ) : (
          items.map((row) => {
            const d = drafts[row.item] || { min: "", max: "", price: "" };
            return (
              <div
                key={row.item}
                className="rounded-2xl border border-white/8 bg-[#141720] p-3.5"
              >
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="text-[15px] font-bold text-[#f8f3e8]">{row.label}</p>
                    <p className="text-[11px] uppercase tracking-wider text-[#9a9386]">
                      {row.category} · {row.item}
                    </p>
                  </div>
                  <p className="text-[16px] font-black tabular-nums text-[#f5c542]">
                    {formatMoney(row.price)}
                  </p>
                </div>

                <div className="mt-3 grid grid-cols-3 gap-2">
                  <label className="block">
                    <span className="mb-1 block text-[9px] font-black uppercase tracking-wider text-[#9a9386]">
                      Min
                    </span>
                    <input
                      value={d.min}
                      onChange={(e) =>
                        setDrafts((prev) => ({
                          ...prev,
                          [row.item]: { ...d, min: e.target.value.replace(/[^\d]/g, "") },
                        }))
                      }
                      inputMode="numeric"
                      className="w-full rounded-xl border border-white/10 bg-[#0c0e14] px-2.5 py-2 text-[13px] tabular-nums text-[#f8f3e8] outline-none focus:border-[#f5c542]/40"
                    />
                  </label>
                  <label className="block">
                    <span className="mb-1 block text-[9px] font-black uppercase tracking-wider text-[#9a9386]">
                      Max
                    </span>
                    <input
                      value={d.max}
                      onChange={(e) =>
                        setDrafts((prev) => ({
                          ...prev,
                          [row.item]: { ...d, max: e.target.value.replace(/[^\d]/g, "") },
                        }))
                      }
                      inputMode="numeric"
                      className="w-full rounded-xl border border-white/10 bg-[#0c0e14] px-2.5 py-2 text-[13px] tabular-nums text-[#f8f3e8] outline-none focus:border-[#f5c542]/40"
                    />
                  </label>
                  <label className="block">
                    <span className="mb-1 block text-[9px] font-black uppercase tracking-wider text-[#9a9386]">
                      Live
                    </span>
                    <input
                      value={d.price}
                      onChange={(e) =>
                        setDrafts((prev) => ({
                          ...prev,
                          [row.item]: { ...d, price: e.target.value.replace(/[^\d]/g, "") },
                        }))
                      }
                      inputMode="numeric"
                      className="w-full rounded-xl border border-white/10 bg-[#0c0e14] px-2.5 py-2 text-[13px] tabular-nums text-[#f8f3e8] outline-none focus:border-[#f5c542]/40"
                    />
                  </label>
                </div>

                <button
                  type="button"
                  disabled={saving === row.item}
                  onClick={() => void saveItem(row.item)}
                  className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl bg-[#f5c542] py-2.5 text-[13px] font-black text-[#1a1408] disabled:opacity-50"
                >
                  {saving === row.item ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Check className="h-4 w-4" />
                  )}
                  Save range
                </button>
              </div>
            );
          })
        )}
      </div>

      {toast ? (
        <div className="pointer-events-none absolute bottom-8 left-1/2 z-50 -translate-x-1/2 rounded-full bg-[#f5c542] px-4 py-2 text-[12px] font-bold text-[#1a1408] shadow-lg">
          {toast}
        </div>
      ) : null}
    </div>
  );
}
