import React, { useEffect, useMemo, useState } from "react";
import { cn } from "@/lib/utils";
import {
  Ban,
  CheckCircle2,
  ChevronDown,
  FileText,
  GraduationCap,
  X,
} from "lucide-react";
import { fetchNui, isBrowserEnv } from "@/lib/nui";

export type RegistrarProgram = {
  id: string;
  code: string;
  label: string;
};

export type RegistrarApplication = {
  id: number;
  programId: string;
  programCode: string;
  programLabel: string;
  status: string;
  createdAt?: string;
};

export type RegistrarData = {
  ok?: boolean;
  brand?: string;
  label?: string;
  citizenName?: string;
  alreadyStudent?: boolean;
  application?: RegistrarApplication | null;
  programs?: RegistrarProgram[];
};

type View = "menu" | "apply";

const MOCK: RegistrarData = {
  ok: true,
  brand: "Keydi.dev",
  label: "ULS Registrar",
  citizenName: "Karl Dev",
  alreadyStudent: false,
  application: null,
  programs: [
    { id: "aes", code: "AES", label: "Aesthetic Services (Beauty Care)" },
    { id: "aut", code: "AUT", label: "Automotive" },
    { id: "cjps", code: "CJPS", label: "Criminal Justice and Public Safety" },
    { id: "fab", code: "FAB", label: "Food and Beverage" },
    { id: "hcs", code: "HCS", label: "Health Care Services" },
    { id: "bsit", code: "BSIT", label: "Information Technology" },
  ],
};

export default function RegistrarMenu({
  visible,
  data,
  onClose,
}: {
  visible: boolean;
  data?: RegistrarData | null;
  onClose?: () => void;
}) {
  const [view, setView] = useState<View>("menu");
  const [local, setLocal] = useState<RegistrarData | null>(null);
  const [programId, setProgramId] = useState("");
  const [openDrop, setOpenDrop] = useState(false);
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (!visible) {
      setView("menu");
      setProgramId("");
      setOpenDrop(false);
      setBusy(false);
      return;
    }
    setLocal(data || (isBrowserEnv() ? MOCK : null));
  }, [visible, data]);

  const payload = local || data;
  const app = payload?.application;
  const programs = payload?.programs || [];
  const selected = useMemo(
    () => programs.find((p) => p.id === programId),
    [programs, programId],
  );

  const flash = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  };

  const close = async () => {
    await fetchNui("cfx-keydi-university:registrar:close");
    onClose?.();
  };

  useEffect(() => {
    if (!visible) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        if (view === "apply") setView("menu");
        else void close();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [visible, view]);

  if (!visible || !payload) return null;

  const statusLine = payload.alreadyStudent
    ? "Enrolled student"
    : app?.status === "pending"
      ? `Pending · ${app.programCode}`
      : "No application on file.";

  const apply = async () => {
    if (!selected || busy) return;
    setBusy(true);
    const res = await fetchNui<{ ok?: boolean; application?: RegistrarApplication; message?: string }>(
      "cfx-keydi-university:registrar:apply",
      { programId: selected.id },
    );
    setBusy(false);
    if (isBrowserEnv()) {
      const mockApp: RegistrarApplication = {
        id: 1,
        programId: selected.id,
        programCode: selected.code,
        programLabel: selected.label,
        status: "pending",
      };
      setLocal((prev) => ({ ...(prev || MOCK), application: mockApp }));
      setView("menu");
      flash("Application submitted");
      return;
    }
    if (!res?.ok) {
      flash(res?.message || "Could not apply");
      return;
    }
    setLocal((prev) => ({ ...(prev || {}), application: res.application || null }));
    setView("menu");
    flash("Application submitted");
  };

  const cancel = async () => {
    if (!app || app.status !== "pending" || busy) return;
    setBusy(true);
    const res = await fetchNui<{ ok?: boolean; application?: null; message?: string }>(
      "cfx-keydi-university:registrar:cancel",
    );
    setBusy(false);
    if (isBrowserEnv()) {
      setLocal((prev) => ({ ...(prev || MOCK), application: null }));
      flash("Application cancelled");
      return;
    }
    if (!res?.ok) {
      flash(res?.message || "Could not cancel");
      return;
    }
    setLocal((prev) => ({ ...(prev || {}), application: null }));
    flash("Application cancelled");
  };

  return (
    <div className="fixed inset-0 z-[100050] flex items-center justify-end bg-black/25 pr-8 backdrop-blur-[1px]">
      <div
        className="w-[min(380px,92vw)] animate-[registrarIn_280ms_cubic-bezier(0.32,0.72,0,1)] overflow-hidden rounded-[18px] border border-white/10 shadow-[0_28px_80px_rgba(0,0,0,0.55)]"
        style={{
          background: "linear-gradient(165deg, #141a24 0%, #0c1018 55%, #090b10 100%)",
          fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif',
        }}
      >
        {/* Header */}
        <div className="flex items-start justify-between gap-3 border-b border-white/8 px-4 py-3.5">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-[#e8d5b0] to-[#9a7b4f] text-[#1a1208] shadow-md">
              <GraduationCap className="h-5 w-5" strokeWidth={2.2} />
            </div>
            <div>
              <p className="text-[10px] font-bold uppercase tracking-[0.22em] text-[#c4a574]">
                Interaction
              </p>
              <h2 className="text-[18px] font-semibold tracking-tight text-white">
                {payload.label || "ULS Registrar"}
              </h2>
            </div>
          </div>
          <button
            type="button"
            onClick={() => void close()}
            className="rounded-full p-1.5 text-white/40 hover:bg-white/5 hover:text-white"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {view === "menu" && (
          <div className="space-y-2 p-3">
            <div className="rounded-2xl border border-white/8 bg-white/[0.03] px-3.5 py-3">
              <div className="flex items-center gap-3">
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#c4a574]/15 text-[#c4a574]">
                  <FileText className="h-4 w-4" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-[14px] font-semibold text-white">Application Status</p>
                  <p className="truncate text-[12px] text-white/45">{statusLine}</p>
                </div>
                {app?.status === "pending" && (
                  <CheckCircle2 className="h-4 w-4 shrink-0 text-[#c4a574]" />
                )}
              </div>
            </div>

            <button
              type="button"
              disabled={!!payload.alreadyStudent || app?.status === "pending"}
              onClick={() => setView("apply")}
              className={cn(
                "flex w-full items-center gap-3 rounded-2xl border px-3.5 py-3 text-left transition-colors",
                payload.alreadyStudent || app?.status === "pending"
                  ? "cursor-not-allowed border-white/5 bg-white/[0.02] opacity-45"
                  : "border-white/8 bg-white/[0.04] hover:bg-white/[0.07]",
              )}
            >
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#c4a574]/15 text-[#c4a574]">
                <GraduationCap className="h-4 w-4" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-[14px] font-semibold text-white">Apply for Enrollment</p>
                <p className="text-[12px] text-white/45">Submit an application to ULS.</p>
              </div>
            </button>

            <button
              type="button"
              disabled={app?.status !== "pending"}
              onClick={() => void cancel()}
              className={cn(
                "flex w-full items-center gap-3 rounded-2xl border px-3.5 py-3 text-left transition-colors",
                app?.status === "pending"
                  ? "border-red-500/25 bg-red-500/10 hover:bg-red-500/15"
                  : "cursor-not-allowed border-white/5 bg-white/[0.02] opacity-40",
              )}
            >
              <div
                className={cn(
                  "flex h-9 w-9 items-center justify-center rounded-xl",
                  app?.status === "pending" ? "bg-red-500/20 text-red-400" : "bg-white/5 text-white/30",
                )}
              >
                <Ban className="h-4 w-4" />
              </div>
              <div className="min-w-0 flex-1">
                <p
                  className={cn(
                    "text-[14px] font-semibold",
                    app?.status === "pending" ? "text-red-300" : "text-white/50",
                  )}
                >
                  Cancel Application
                </p>
                <p className="text-[12px] text-white/40">
                  {app?.status === "pending"
                    ? `Cancel pending ${app.programCode} application`
                    : "No pending application to cancel."}
                </p>
              </div>
            </button>
          </div>
        )}

        {view === "apply" && (
          <div className="space-y-3 p-4">
            <div>
              <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#c4a574]">Input</p>
              <h3 className="text-[17px] font-semibold text-white">Apply to ULS</h3>
            </div>

            <div>
              <p className="text-[13px] font-semibold text-white">
                Course / Program <span className="text-[#c4a574]">*</span>
              </p>
              <p className="mt-0.5 text-[12px] text-white/40">Which course would you like to apply for?</p>

              <button
                type="button"
                onClick={() => setOpenDrop((v) => !v)}
                className="mt-2 flex w-full items-center justify-between rounded-xl border border-[#c4a574]/55 bg-black/35 px-3 py-2.5 text-left text-[13px] text-white"
              >
                <span className={selected ? "text-white" : "text-white/40"}>
                  {selected ? `${selected.label} (${selected.code})` : "Select…"}
                </span>
                <ChevronDown className={cn("h-4 w-4 text-[#c4a574] transition-transform", openDrop && "rotate-180")} />
              </button>

              {openDrop && (
                <div className="mt-1 max-h-[200px] overflow-y-auto rounded-xl border border-white/10 bg-[#0e131c] py-1 shadow-xl">
                  {programs.map((p) => (
                    <button
                      key={p.id}
                      type="button"
                      onClick={() => {
                        setProgramId(p.id);
                        setOpenDrop(false);
                      }}
                      className={cn(
                        "flex w-full px-3 py-2.5 text-left text-[13px] transition-colors hover:bg-white/5",
                        programId === p.id ? "text-[#e8d5b0]" : "text-white/85",
                      )}
                    >
                      {p.label} ({p.code})
                    </button>
                  ))}
                </div>
              )}
            </div>

            <div className="flex gap-2 pt-1">
              <button
                type="button"
                onClick={() => setView("menu")}
                className="flex-1 rounded-xl border border-white/10 py-2.5 text-[13px] font-semibold text-white/70 hover:bg-white/5"
              >
                Back
              </button>
              <button
                type="button"
                disabled={!selected || busy}
                onClick={() => void apply()}
                className="flex-1 rounded-xl bg-gradient-to-r from-[#e8d5b0] to-[#b8955f] py-2.5 text-[13px] font-bold text-[#1a1208] disabled:opacity-40"
              >
                {busy ? "Submitting…" : "Submit"}
              </button>
            </div>
          </div>
        )}

        <div className="flex items-center justify-between border-t border-white/8 px-4 py-2.5">
          <p className="text-[11px] text-white/35">Press ESC to close</p>
          <p className="text-[10px] font-semibold tracking-[0.16em] text-[#c4a574]/80">
            {(payload.brand || "Keydi.dev").toUpperCase()}
          </p>
        </div>
      </div>

      {toast && (
        <div className="absolute bottom-10 left-1/2 -translate-x-1/2 rounded-full bg-[#f4efe6] px-4 py-2 text-[12px] font-semibold text-[#1a1208] shadow-xl">
          {toast}
        </div>
      )}

      <style>{`
        @keyframes registrarIn {
          from { opacity: 0; transform: translateX(16px); }
          to { opacity: 1; transform: translateX(0); }
        }
      `}</style>
    </div>
  );
}
