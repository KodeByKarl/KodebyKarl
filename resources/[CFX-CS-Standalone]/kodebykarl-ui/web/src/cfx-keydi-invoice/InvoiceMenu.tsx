import React, { useEffect, useMemo, useRef, useState } from "react";
import { Camera, ChevronDown, FileText, Search, X } from "lucide-react";
import { toast } from "sonner";
import { cn } from "@/lib/utils";
import iconCreate from "./icons/create.png";
import iconSociety from "./icons/society.png";
import iconPersonal from "./icons/personal.png";
import iconReference from "./icons/reference.png";
import iconInspect from "./icons/inspect.png";
import iconCity from "./icons/city.png";
import iconPay from "./icons/pay.png";

export interface InvoiceNearby {
  id: number;
  name: string;
  distance?: number;
}

export interface InvoiceRecord {
  id: number;
  reference: string;
  kind: "personal" | "job" | string;
  invoiceType: string;
  title: string;
  description?: string;
  amount: number;
  vat: number;
  total: number;
  dueDate?: string | null;
  senderName: string;
  senderJob?: string | null;
  receiverName: string;
  status: "paid" | "unpaid" | string;
  createdAt?: string | null;
  canPay?: boolean;
  canCancel?: boolean;
  canReject?: boolean;
}

export interface InvoiceData {
  playerName?: string;
  jobName?: string;
  jobLabel?: string;
  canJobInvoice?: boolean;
  forceSocietyInvoice?: boolean;
  jobInvoiceLabel?: string;
  isStaff?: boolean;
  canInspect?: boolean;
  canSociety?: boolean;
  canCity?: boolean;
  incoming?: boolean;
  vatPercent?: number;
  screenshotEnabled?: boolean;
  maxTitle?: number;
  maxDescription?: number;
  maxAmount?: number;
  nearby?: InvoiceNearby[];
  sent?: InvoiceRecord[];
  personal?: InvoiceRecord[];
  society?: InvoiceRecord[];
  selected?: InvoiceRecord | null;
  view?: InvoiceView;
}

export type InvoiceView =
  | "create"
  | "sent"
  | "society"
  | "personal"
  | "reference"
  | "inspect"
  | "city"
  | "detail";

interface InvoiceMenuProps {
  visible?: boolean;
  data?: InvoiceData | null;
  onClose?: () => void;
}

const panel = "bg-[#101114] rounded-2xl";
const field =
  "w-full h-12 rounded-xl bg-[#3a3d45]/55 text-center text-[13px] text-white placeholder:text-zinc-400 outline-none border border-white/5 focus:border-[#3A86FF]/70";
const blueBtn =
  "inline-flex items-center justify-center gap-2 rounded-lg bg-[#3A86FF] hover:bg-[#2f76e8] px-5 py-2.5 text-[13px] font-semibold text-white disabled:opacity-40";

const fetchNui = async (eventName: string, payload?: unknown) => {
  try {
    const resourceName = (window as any).GetParentResourceName
      ? (window as any).GetParentResourceName()
      : "cfx-keydi-ui";
    const response = await fetch(`https://${resourceName}/${eventName}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(payload ?? {}),
    });
    return await response.json();
  } catch {
    return null;
  }
};

const money = (value?: number) => `$${(Number(value) || 0).toLocaleString()}`;

function isPersonalRecord(invoice?: InvoiceRecord | null): boolean {
  if (!invoice) return true;
  if (invoice.kind === "job") return false;
  if (invoice.kind === "personal") return true;
  if (invoice.invoiceType && invoice.invoiceType.toLowerCase() !== "personal") return false;
  return true;
}

function getJobLabel(invoice?: InvoiceRecord | null): string | null {
  if (!invoice) return null;
  if (invoice.invoiceType && invoice.invoiceType.toLowerCase() !== "personal") {
    return invoice.invoiceType;
  }
  if (invoice.senderJob && invoice.senderJob.toLowerCase() !== "unemployed" && invoice.senderJob !== "") {
    return invoice.senderJob;
  }
  return null;
}

function formatDate(value?: string | number | null) {
  if (!value) return "No Due Date";
  const raw = String(value).trim();
  if (!raw || raw === "0" || raw.toLowerCase() === "null") return "No Due Date";

  let date: Date | null = null;
  if (!Number.isNaN(Number(raw)) && !raw.includes("-") && !raw.includes("/")) {
    let num = Number(raw);
    if (num < 1e11) num = num * 1000;
    date = new Date(num);
  } else {
    date = new Date(raw.replace(" ", "T"));
    if (Number.isNaN(date.getTime())) {
      date = new Date(raw);
    }
  }

  if (!date || Number.isNaN(date.getTime())) return raw;
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${pad(date.getDate())}-${pad(date.getMonth() + 1)}-${date.getFullYear()} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function StatusDot({ status }: { status: string }) {
  const paid = status === "paid";
  return (
    <span
      className={cn("inline-block h-2.5 w-2.5 rounded-full", paid ? "bg-emerald-400" : "bg-rose-500")}
      title={paid ? "Paid" : "Unpaid"}
    />
  );
}

export default function InvoiceMenu({ visible = true, data, onClose }: InvoiceMenuProps) {
  const [view, setView] = useState<InvoiceView>(data?.view || "create");
  const [kind, setKind] = useState<"personal" | "job">(data?.canJobInvoice ? "job" : "personal");
  const [title, setTitle] = useState("");
  const [price, setPrice] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [description, setDescription] = useState("");
  const [targetId, setTargetId] = useState<number | "">("");
  const [selected, setSelected] = useState<InvoiceRecord | null>(data?.selected || null);
  const [screenshotOpen, setScreenshotOpen] = useState(false);
  const [payPrompt, setPayPrompt] = useState<"single" | "all" | null>(null);
  const [busy, setBusy] = useState(false);

  const [inspectId, setInspectId] = useState("");
  const [inspectResult, setInspectResult] = useState<{ name: string; unpaid: number } | null>(null);

  const [reference, setReference] = useState("");
  const [referenceResult, setReferenceResult] = useState<{ receiver: string; amount: number; invoice: InvoiceRecord } | null>(null);

  const [citySearch, setCitySearch] = useState("");
  const [cityFilter, setCityFilter] = useState<"all" | "unpaid" | "paid">("all");
  const [cityInvoices, setCityInvoices] = useState<InvoiceRecord[]>([]);
  const [cityPending, setCityPending] = useState(0);
  const [cityPaid, setCityPaid] = useState(0);

  const invoiceCardRef = useRef<HTMLDivElement>(null);
  const nearby = data?.nearby || [];
  const vatPercent = data?.vatPercent ?? 0;

  useEffect(() => {
    if (!visible) return;
    const nextView = data?.view || "create";
    if ((nextView === "city" && !data?.canCity) || (nextView === "society" && !data?.canSociety)) {
      setView("create");
    } else {
      setView(nextView);
    }
    setSelected(data?.selected || null);
    setScreenshotOpen(false);
    setPayPrompt(null);
    if (data?.canJobInvoice || data?.forceSocietyInvoice) {
      setKind("job");
    } else {
      setKind("personal");
    }
    if (nextView === "city" && data?.canCity) {
      loadCity();
    }
  }, [visible, data]);

  useEffect(() => {
    if (nearby.length === 1) {
      setTargetId(nearby[0].id);
    }
  }, [nearby]);

  const handleClose = () => {
    fetchNui("cfx-keydi-invoice:close");
    onClose?.();
  };

  const openDetail = (invoice: InvoiceRecord) => {
    setSelected(invoice);
    setView("detail");
    setScreenshotOpen(false);
    setPayPrompt(null);
  };

  const loadCity = async (search = citySearch, status = cityFilter) => {
    const result = await fetchNui("cfx-keydi-invoice:city", {
      search,
      status: status === "all" ? undefined : status,
    });
    if (result?.ok) {
      setCityInvoices(result.invoices || []);
      setCityPending(result.pending || 0);
      setCityPaid(result.paid || 0);
    }
  };

  const handleCreate = async () => {
    if (!targetId) {
      toast.error("Stand near a citizen to invoice them.");
      return;
    }
    if (!title.trim()) {
      toast.error("Title is required.");
      return;
    }
    const amount = Number(price);
    if (!amount || amount <= 0) {
      toast.error("Enter a valid price.");
      return;
    }

    setBusy(true);
    const result = await fetchNui("cfx-keydi-invoice:create", {
      targetId,
      kind: data?.forceSocietyInvoice || (kind === "job" && data?.canJobInvoice) ? "job" : "personal",
      title: title.trim(),
      price: amount,
      dueDate,
      description,
    });
    setBusy(false);

    if (!result?.ok) {
      toast.error(result?.error || "Could not create billing.");
      return;
    }

    const docName = kind === "personal" ? "Receipt" : "Invoice";
    toast.success(`${docName} #${result.id} created.`);
    setTitle("");
    setPrice("");
    setDueDate("");
    setDescription("");
    setView("sent");
  };

  const handlePay = async (invoice: InvoiceRecord, account: "cash" | "bank") => {
    if (invoice.status === "paid") return;
    setBusy(true);
    const result = await fetchNui("cfx-keydi-invoice:pay", { id: invoice.id, account });
    setBusy(false);
    setPayPrompt(null);
    if (!result?.ok) {
      toast.error(result?.error || "Payment failed.");
      return;
    }
    const docName = isPersonalRecord(invoice) ? "Receipt" : "Invoice";
    toast.success(`${docName} paid with ${account}.`);
    setSelected({ ...invoice, status: "paid", canPay: false });
  };

  const handlePayAll = async (account: "cash" | "bank") => {
    const unpaid = listForView().filter((invoice) => invoice.status !== "paid" && invoice.canPay);
    if (unpaid.length === 0) {
      toast.error("No unpaid items.");
      setPayPrompt(null);
      return;
    }
    setBusy(true);
    let paid = 0;
    for (const invoice of unpaid) {
      const result = await fetchNui("cfx-keydi-invoice:pay", { id: invoice.id, account });
      if (result?.ok) paid += 1;
    }
    setBusy(false);
    setPayPrompt(null);
    toast.success(paid ? `Paid ${paid} item(s) with ${account}.` : "Payment failed.");
  };

  const handleReject = async (invoice: InvoiceRecord) => {
    setBusy(true);
    const result = await fetchNui("cfx-keydi-invoice:reject", { id: invoice.id });
    setBusy(false);
    if (!result?.ok) {
      toast.error(result?.error || "Could not reject.");
      return;
    }
    const docName = isPersonalRecord(invoice) ? "Receipt" : "Invoice";
    toast.success(result?.refunded
      ? `${docName} rejected. $${Number(result.refunded).toLocaleString()} refunded.`
      : `${docName} rejected.`);
    handleClose();
  };

  const handleCancelInvoice = async (invoice: InvoiceRecord) => {
    setBusy(true);
    const result = await fetchNui("cfx-keydi-invoice:cancel", { id: invoice.id });
    setBusy(false);
    if (!result?.ok) {
      toast.error(result?.error || "Could not cancel.");
      return;
    }
    const docName = isPersonalRecord(invoice) ? "Receipt" : "Invoice";
    toast.success(`${docName} cancelled.`);
    setSelected(null);
    setView("sent");
  };

  const handleInspect = async () => {
    const result = await fetchNui("cfx-keydi-invoice:inspect", { id: Number(inspectId) });
    if (!result?.ok) {
      setInspectResult(null);
      toast.error(result?.error || "Citizen not found.");
      return;
    }
    setInspectResult({ name: result.name, unpaid: result.unpaid });
  };

  const handleLookup = async () => {
    const result = await fetchNui("cfx-keydi-invoice:lookup", { reference });
    if (!result?.ok) {
      setReferenceResult(null);
      toast.error(result?.error || "Invoice/receipt not found.");
      return;
    }
    setReferenceResult({
      receiver: result.receiver,
      amount: result.amount,
      invoice: result.invoice,
    });
  };

  const handleDeletePaid = async () => {
    const result = await fetchNui("cfx-keydi-invoice:deletePaid");
    if (!result?.ok) {
      toast.error(result?.error || "No permission.");
      return;
    }
    toast.success("Paid items deleted.");
    loadCity();
  };

  const copyInvoice = async () => {
    if (!selected) return;
    const isPersonal = isPersonalRecord(selected);
    const docType = isPersonal ? "RECEIPT" : "INVOICE";
    const job = getJobLabel(selected);
    const text = [
      `${docType} #${selected.id}`,
      `Bill To: ${selected.receiverName}`,
      `Bill From: ${selected.senderName}${job ? ` (${job})` : ""}`,
      `Title: ${selected.title}`,
      `Amount: ${money(selected.amount)}`,
      selected.vat > 0 ? `VAT: ${money(selected.vat)}` : null,
      `Total: ${money(selected.total)}`,
      `Type: ${isPersonal ? "Personal Receipt" : `Job Invoice (${job || "Society"})`}`,
      `Status: ${selected.status}`,
      `Reference: ${selected.reference}`,
    ]
      .filter(Boolean)
      .join("\n");
    try {
      await navigator.clipboard.writeText(text);
      toast.success(`${isPersonal ? "Receipt" : "Invoice"} copied.`);
    } catch {
      toast.error("Could not copy.");
    }
    setScreenshotOpen(false);
  };

  const navItems = useMemo(
    () => [
      {
        id: "society" as const,
        label: "Society Invoices",
        hint: "Simplify job invoicing and managing",
        icon: iconSociety,
        show: !!data?.canSociety,
      },
      {
        id: "personal" as const,
        label: "Personal Receipts",
        hint: "Receipts & bills sent to you",
        icon: iconPersonal,
        show: true,
      },
      {
        id: "reference" as const,
        label: "Pay Reference",
        hint: "Pay with a reference ID",
        icon: iconReference,
        show: true,
      },
      {
        id: "inspect" as const,
        label: "Inspect Citizen",
        hint: "View a player's unpaid dues",
        icon: iconInspect,
        show: !!data?.canInspect,
      },
      {
        id: "city" as const,
        label: "City Invoices",
        hint: "Admin invoice management",
        icon: iconCity,
        show: !!data?.canCity,
      },
    ],
    [data?.canInspect, data?.canSociety, data?.canCity]
  );

  if (!visible) return null;

  const listForView = (): InvoiceRecord[] => {
    if (view === "sent") return data?.sent || [];
    if (view === "personal") return data?.personal || [];
    if (view === "society") return data?.society || [];
    return [];
  };

  const goNav = (id: InvoiceView) => {
    if (id === "city" && !data?.canCity) return;
    if (id === "society" && !data?.canSociety) return;
    setView(id);
    if (id === "city") loadCity();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4 font-sans select-none text-white">
      {view === "detail" && selected ? (
        <InvoiceDetail
          invoice={selected}
          vatPercent={vatPercent}
          incoming={!!data?.incoming}
          screenshotEnabled={data?.screenshotEnabled !== false}
          screenshotOpen={screenshotOpen}
          payOpen={payPrompt === "single"}
          cardRef={invoiceCardRef}
          busy={busy}
          onClose={handleClose}
          onBack={() => setView(data?.incoming ? "personal" : "create")}
          onScreenshot={() => setScreenshotOpen(true)}
          onCancelScreenshot={() => setScreenshotOpen(false)}
          onCopy={copyInvoice}
          onRequestPay={() => setPayPrompt("single")}
          onConfirmPay={(account) => handlePay(selected, account)}
          onReject={() => handleReject(selected)}
          onCancelInvoice={() => handleCancelInvoice(selected)}
          onClosePay={() => setPayPrompt(null)}
        />
      ) : view === "inspect" ? (
        <div className={cn(panel, "relative w-[320px] px-5 pt-5 pb-5")}>
          <button
            onClick={handleClose}
            className="absolute right-3 top-3 h-7 w-7 rounded-full bg-white/10 text-white hover:bg-white/20 flex items-center justify-center"
          >
            <X className="h-4 w-4" />
          </button>
          <h2 className="mb-4 text-[22px] font-bold tracking-wide">INSPECT CITIZEN</h2>
          <div className="mb-4 flex items-center gap-2">
            <input
              value={inspectId}
              onChange={(e) => setInspectId(e.target.value.replace(/\D/g, ""))}
              placeholder="Player ID"
              className="h-11 flex-1 rounded-lg bg-white text-center text-sm text-black outline-none"
              onKeyDown={(e) => e.key === "Enter" && handleInspect()}
            />
            <button
              onClick={handleInspect}
              className="h-11 w-11 shrink-0 rounded-full bg-[#3A86FF] hover:bg-[#2f76e8] flex items-center justify-center"
            >
              <Search className="h-4 w-4 text-white" />
            </button>
          </div>
          <p className="mb-1 text-[12px] text-zinc-300">Citizen</p>
          <div className="mb-3 h-12 rounded-lg bg-[#2a2c31] flex items-center justify-center text-sm">
            {inspectResult?.name || "—"}
          </div>
          <p className="mb-1 text-[12px] text-zinc-300">Total Unpaid Amount</p>
          <div className="h-12 rounded-lg bg-[#2a2c31] flex items-center justify-center text-sm">
            {inspectResult ? String(inspectResult.unpaid) : "—"}
          </div>
          <button onClick={() => setView("create")} className="mt-4 w-full text-[12px] font-semibold text-zinc-400 hover:text-white">
            BACK
          </button>
        </div>
      ) : view === "reference" ? (
        <FormPanel icon={iconReference} title="PAY REFERENCE" onClose={handleClose} onBack={() => setView("create")}>
          <div className="relative mb-4">
            <input
              value={reference}
              onChange={(e) => setReference(e.target.value.toUpperCase())}
              placeholder="Reference ID"
              className={cn(field, "pr-10 tracking-[0.2em]")}
              onKeyDown={(e) => e.key === "Enter" && handleLookup()}
            />
            <button onClick={handleLookup} className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-white">
              <Search className="h-4 w-4" />
            </button>
          </div>
          <ReadField label="Receiver" value={referenceResult?.receiver || "—"} />
          <ReadField label="Amount" value={referenceResult ? String(referenceResult.amount) : "—"} />
          <button
            disabled={!referenceResult}
            onClick={() => referenceResult && openDetail(referenceResult.invoice)}
            className={cn(blueBtn, "mt-2 w-full")}
          >
            SHOW
          </button>
        </FormPanel>
      ) : view === "city" && data?.canCity ? (
        <ListTable
          title="CITY INVOICES"
          invoices={cityInvoices}
          empty="No invoices found."
          busy={busy}
          search={citySearch}
          onSearch={setCitySearch}
          onSearchSubmit={() => loadCity(citySearch, cityFilter)}
          unpaidCount={cityPending}
          paidCount={cityPaid}
          onFilter={(status) => {
            setCityFilter(status);
            loadCity(citySearch, status);
          }}
          filter={cityFilter}
          showDelete
          onDeletePaid={handleDeletePaid}
          onClose={handleClose}
          onBack={() => setView("create")}
          onView={(invoice) => openDetail(invoice)}
        />
      ) : view === "sent" || view === "personal" || (view === "society" && data?.canSociety) ? (
        <ListTable
          title={view === "sent" ? "MY INVOICES & RECEIPTS" : view === "personal" ? "PERSONAL RECEIPTS" : "SOCIETY INVOICES"}
          invoices={listForView()}
          empty="No records yet."
          busy={busy}
          showPayAll={view === "personal"}
          onPayAll={() => setPayPrompt("all")}
          showDelete={!!data?.canCity && view !== "sent"}
          onDeletePaid={handleDeletePaid}
          onClose={handleClose}
          onBack={() => setView("create")}
          onView={(invoice) => openDetail(invoice)}
        />
      ) : (
        <div className="flex items-stretch gap-3">
          <div className={cn(panel, "relative w-[420px] px-6 pt-6 pb-5")}>
            <button
              onClick={handleClose}
              className="absolute right-3 top-3 h-7 w-7 rounded-md text-zinc-500 hover:text-white hover:bg-white/5 flex items-center justify-center"
            >
              <X className="h-4 w-4" />
            </button>
            <img src={iconCreate} alt="" className="mx-auto h-[88px] w-[88px] object-contain drop-shadow-[0_8px_16px_rgba(58,134,255,0.35)]" />
            <h2 className="mt-3 mb-4 text-center text-[22px] font-bold tracking-wide">
              {kind === "personal" ? "CREATE RECEIPT" : "CREATE INVOICE"}
            </h2>

            {data?.forceSocietyInvoice ? (
              <p className="mb-3 rounded-lg bg-[#3A86FF]/15 px-3 py-2 text-center text-[12px] font-semibold text-[#7eb3ff]">
                Paid funds go to {data?.jobInvoiceLabel || data?.jobLabel || "department"} society
              </p>
            ) : (
              <div className="grid grid-cols-2 gap-2 mb-3">
                <ToggleChip active={kind === "personal"} onClick={() => setKind("personal")}>
                  Personal Receipt
                </ToggleChip>
                <ToggleChip
                  active={kind === "job"}
                  disabled={!data?.canJobInvoice}
                  onClick={() => data?.canJobInvoice && setKind("job")}
                >
                  Job Invoice
                </ToggleChip>
              </div>
            )}

            <div className="space-y-2.5">
              <CitizenDropdown value={targetId} nearby={nearby} onChange={setTargetId} />
              <input
                value={title}
                maxLength={data?.maxTitle || 60}
                placeholder={kind === "personal" ? "Receipt Title" : "Invoice Title"}
                onChange={(e) => setTitle(e.target.value)}
                className={field}
              />
              <input
                value={price}
                placeholder="Price"
                onChange={(e) => setPrice(e.target.value.replace(/[^\d]/g, ""))}
                className={field}
              />
              <input
                value={dueDate}
                placeholder="Due Date (Optional)"
                onChange={(e) => setDueDate(e.target.value)}
                className={field}
              />
              <input
                value={description}
                maxLength={data?.maxDescription || 250}
                placeholder="Description (Optional)"
                onChange={(e) => setDescription(e.target.value)}
                className={field}
              />
            </div>

            {price && (
              <p className="mt-2 text-center text-[11px] text-zinc-400">
                {vatPercent > 0
                  ? `VAT ${vatPercent}% → Total ${money(Math.floor(Number(price || 0) * (1 + vatPercent / 100)))}`
                  : `Total ${money(Number(price || 0))}`}
              </p>
            )}

            <button disabled={busy} onClick={handleCreate} className={cn(blueBtn, "mt-4 w-full")}>
              {kind === "personal" ? "Create Receipt" : "Create Invoice"}
            </button>
            <button onClick={() => setView("sent")} className={cn(blueBtn, "mt-2 w-full")}>
              <FileText className="h-4 w-4" />
              My Invoices & Receipts
            </button>
          </div>

          <div className={cn(panel, "flex w-[280px] flex-col gap-2 p-3 self-stretch")}>
            {navItems
              .filter((item) => item.show)
              .map((item) => (
                <button
                  key={item.id}
                  onClick={() => goNav(item.id)}
                  className="flex items-center gap-3 rounded-xl bg-white/[0.04] border border-white/5 px-3 py-2.5 text-left hover:bg-white/[0.08] hover:border-[#3A86FF]/50 transition"
                >
                  <img src={item.icon} alt="" className="h-12 w-12 object-contain shrink-0" />
                  <span className="min-w-0">
                    <span className="block text-[13px] font-semibold leading-tight">{item.label}</span>
                    <span className="block text-[11px] text-zinc-400 leading-snug">{item.hint}</span>
                  </span>
                </button>
              ))}
          </div>
        </div>
      )}

      {payPrompt === "all" && (
        <PaymentMethodModal
          busy={busy}
          onCash={() => handlePayAll("cash")}
          onBank={() => handlePayAll("bank")}
          onClose={() => setPayPrompt(null)}
        />
      )}
    </div>
  );
}

function CitizenDropdown({
  value,
  nearby,
  onChange,
}: {
  value: number | "";
  nearby: InvoiceNearby[];
  onChange: (id: number | "") => void;
}) {
  const [open, setOpen] = useState(false);
  const [list, setList] = useState<InvoiceNearby[]>(nearby);
  const rootRef = useRef<HTMLDivElement>(null);
  const selected = list.find((player) => player.id === value);

  useEffect(() => {
    setList(nearby);
  }, [nearby]);

  useEffect(() => {
    const onDoc = (event: MouseEvent) => {
      if (rootRef.current && !rootRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, []);

  const toggle = async () => {
    const next = !open;
    setOpen(next);
    if (next) {
      const fresh = await fetchNui("cfx-keydi-invoice:getNearby");
      if (Array.isArray(fresh)) setList(fresh);
    }
  };

  return (
    <div ref={rootRef} className="relative">
      <button
        type="button"
        onClick={toggle}
        className={cn(field, "flex items-center justify-center gap-2 px-3")}
      >
        <span className="truncate">{selected ? `[${selected.id}] ${selected.name}` : "Citizen"}</span>
        <ChevronDown className={cn("h-4 w-4 shrink-0 text-zinc-400 transition", open && "rotate-180")} />
      </button>
      {open && (
        <div className="absolute left-0 right-0 z-30 mt-1 overflow-hidden rounded-xl bg-[#0b0b0d] border border-white/10">
          {list.length === 0 && (
            <div className="px-3 py-3 text-center text-sm text-zinc-500">No nearby citizens</div>
          )}
          {list.map((player) => (
            <button
              key={player.id}
              type="button"
              onClick={() => {
                onChange(player.id);
                setOpen(false);
              }}
              className={cn(
                "w-full px-3 py-2.5 text-center text-[13px] transition",
                value === player.id ? "bg-[#5aa8ff] text-white" : "text-zinc-300 hover:bg-[#5aa8ff] hover:text-white"
              )}
            >
              [{player.id}] {player.name}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function ToggleChip({
  active,
  disabled,
  onClick,
  children,
}: {
  active: boolean;
  disabled?: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      disabled={disabled}
      onClick={onClick}
      className={cn(
        "h-10 rounded-lg text-[13px] font-semibold transition",
        active ? "bg-[#3A86FF] text-white" : "bg-transparent border border-white/70 text-white",
        disabled && "opacity-35 cursor-not-allowed"
      )}
    >
      {children}
    </button>
  );
}

function ReadField({ label, value }: { label: string; value: string }) {
  return (
    <div className="mb-3">
      <p className="mb-1 text-[11px] font-semibold tracking-wide text-zinc-400">{label}</p>
      <p className={cn(field, "flex items-center justify-center")}>{value}</p>
    </div>
  );
}

function FormPanel({
  icon,
  title,
  onClose,
  onBack,
  children,
}: {
  icon: string;
  title: string;
  onClose: () => void;
  onBack: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className={cn(panel, "relative w-[300px] px-5 pt-6 pb-5")}>
      <button
        onClick={onClose}
        className="absolute right-3 top-3 h-7 w-7 rounded-md text-zinc-500 hover:text-white hover:bg-white/5 flex items-center justify-center"
      >
        <X className="h-4 w-4" />
      </button>
      <img src={icon} alt="" className="mx-auto h-[72px] w-[72px] object-contain" />
      <h2 className="mt-3 mb-4 text-center text-[22px] font-bold tracking-wide">{title}</h2>
      {children}
      <button onClick={onBack} className="mt-3 w-full text-[12px] font-semibold text-zinc-400 hover:text-white">
        BACK
      </button>
    </div>
  );
}

function ListTable({
  title,
  invoices,
  empty,
  busy,
  search,
  onSearch,
  onSearchSubmit,
  filter,
  onFilter,
  unpaidCount,
  paidCount,
  showPayAll,
  onPayAll,
  showDelete,
  onDeletePaid,
  onClose,
  onBack,
  onView,
}: {
  title: string;
  invoices: InvoiceRecord[];
  empty: string;
  busy: boolean;
  search?: string;
  onSearch?: (value: string) => void;
  onSearchSubmit?: () => void;
  filter?: "all" | "unpaid" | "paid";
  onFilter?: (status: "all" | "unpaid" | "paid") => void;
  unpaidCount?: number;
  paidCount?: number;
  showPayAll?: boolean;
  onPayAll?: () => void;
  showDelete?: boolean;
  onDeletePaid?: () => void;
  onClose: () => void;
  onBack: () => void;
  onView: (invoice: InvoiceRecord) => void;
}) {
  const unpaidTotal = invoices
    .filter((invoice) => invoice.status !== "paid")
    .reduce((sum, invoice) => sum + (invoice.total || 0), 0);

  return (
    <div className={cn(panel, "relative w-[760px] overflow-hidden")}>
      <div className="flex items-center justify-between px-5 py-4">
        <h2 className="text-[22px] font-bold tracking-wide text-[#5aa2ff]">{title}</h2>
        <div className="flex items-center gap-2">
          {onSearch && (
            <div className="relative w-52">
              <Search className="absolute left-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-zinc-400" />
              <input
                value={search || ""}
                onChange={(e) => onSearch(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && onSearchSubmit?.()}
                placeholder="Search"
                className="h-9 w-full rounded-lg border border-white/10 bg-white/5 pl-8 pr-3 text-xs outline-none focus:border-[#3A86FF]/70"
              />
            </div>
          )}
          <button
            onClick={onClose}
            className="h-7 w-7 rounded-md text-zinc-500 hover:text-white hover:bg-white/5 flex items-center justify-center"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>

      <div className="px-5 pb-5">
        <div className="overflow-hidden rounded-xl border border-white/8">
          <div className="grid grid-cols-[60px_80px_1fr_130px_120px_90px] bg-white/[0.03] px-4 py-3 text-[11px] font-semibold tracking-[0.16em] text-[#7eb3ff]">
            <span>#</span>
            <span>STATUS</span>
            <span>CLIENT</span>
            <span>TYPE / JOB</span>
            <span>AMOUNT</span>
            <span className="text-right">ACTIONS</span>
          </div>
          <div className="max-h-[340px] overflow-y-auto">
            {invoices.length === 0 && (
              <div className="px-4 py-10 text-center text-sm text-zinc-400">{empty}</div>
            )}
            {invoices.map((invoice) => {
              const isPersonal = isPersonalRecord(invoice);
              const jobLabel = getJobLabel(invoice);
              return (
                <div
                  key={invoice.id}
                  className="grid grid-cols-[60px_80px_1fr_130px_120px_90px] items-center border-t border-white/5 px-4 py-3 text-sm"
                >
                  <span className="font-semibold">{invoice.id}</span>
                  <StatusDot status={invoice.status} />
                  <span className="truncate">{invoice.receiverName}</span>
                  <div className="truncate pr-2">
                    {isPersonal ? (
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-semibold bg-purple-500/15 text-purple-300 border border-purple-500/30">
                        Receipt
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-semibold bg-[#3A86FF]/15 text-[#7eb3ff] border border-[#3A86FF]/30 truncate max-w-[120px]" title={jobLabel || "Job"}>
                        {jobLabel || "Job"}
                      </span>
                    )}
                  </div>
                  <span>{money(invoice.total)}</span>
                  <div className="text-right">
                    <button
                      onClick={() => onView(invoice)}
                      className="rounded-md border border-[#3A86FF]/80 px-3 py-1 text-[11px] font-semibold text-[#7eb3ff] hover:bg-[#3A86FF]/15"
                    >
                      View
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <div className="mt-4 flex items-center gap-2">
          {onFilter && (
            <>
              <button
                onClick={() => onFilter("unpaid")}
                className={cn(blueBtn, filter !== "unpaid" && "bg-transparent border border-white/20 hover:bg-white/5")}
              >
                PENDING [{unpaidCount ?? 0}]
              </button>
              <button
                onClick={() => onFilter("paid")}
                className={cn(blueBtn, filter !== "paid" && "bg-transparent border border-white/20 hover:bg-white/5")}
              >
                PAID [{paidCount ?? 0}]
              </button>
            </>
          )}
          {showPayAll && (
            <button disabled={busy} onClick={onPayAll} className={blueBtn}>
              PAY ALL ({money(unpaidTotal)})
            </button>
          )}
          {showDelete && (
            <button
              onClick={onDeletePaid}
              className="rounded-lg bg-[#1a1b1f] border border-white/15 hover:bg-white/5 px-4 py-2.5 text-[13px] font-semibold"
            >
              DELETE ALL PAID
            </button>
          )}
          <button onClick={onBack} className="ml-auto text-[12px] font-semibold text-zinc-400 hover:text-white">
            BACK
          </button>
        </div>
      </div>
    </div>
  );
}

function InvoiceDetail({
  invoice,
  vatPercent,
  incoming,
  screenshotEnabled,
  screenshotOpen,
  payOpen,
  cardRef,
  busy,
  onClose,
  onBack,
  onScreenshot,
  onCancelScreenshot,
  onCopy,
  onRequestPay,
  onConfirmPay,
  onReject,
  onCancelInvoice,
  onClosePay,
}: {
  invoice: InvoiceRecord;
  vatPercent: number;
  incoming: boolean;
  screenshotEnabled: boolean;
  screenshotOpen: boolean;
  payOpen: boolean;
  cardRef: React.RefObject<HTMLDivElement | null>;
  busy: boolean;
  onClose: () => void;
  onBack: () => void;
  onScreenshot: () => void;
  onCancelScreenshot: () => void;
  onCopy: () => void;
  onRequestPay: () => void;
  onConfirmPay: (account: "cash" | "bank") => void;
  onReject: () => void;
  onCancelInvoice: () => void;
  onClosePay: () => void;
}) {
  const isPersonal = isPersonalRecord(invoice);
  const jobLabel = getJobLabel(invoice);
  const unpaid = invoice.status !== "paid";
  const canPay = unpaid && invoice.canPay === true;
  const canReject = incoming && (canPay || invoice.canReject === true);
  const statusLabel = invoice.status === "paid" ? "Paid" : incoming ? "Pending" : "Unpaid";
  const docType = isPersonal ? "RECEIPT" : "INVOICE";
  const docTypeTitle = isPersonal ? "Receipt" : "Invoice";

  return (
    <div className="relative w-[520px]">
      <div ref={cardRef} className={cn(panel, "overflow-hidden px-6 pt-5 pb-5")}>
        <div className="flex items-start justify-between mb-4">
          <div>
            <h2 className="text-[26px] font-bold tracking-wide">
              {docType} #{invoice.id}
            </h2>
            {jobLabel && !isPersonal ? (
              <p className="text-[12px] font-semibold text-[#7eb3ff] mt-0.5 flex items-center gap-1.5">
                <span className="inline-block h-1.5 w-1.5 rounded-full bg-[#3A86FF]" />
                Job Invoice · {jobLabel}
              </p>
            ) : isPersonal ? (
              <p className="text-[12px] font-semibold text-purple-300 mt-0.5 flex items-center gap-1.5">
                <span className="inline-block h-1.5 w-1.5 rounded-full bg-purple-400" />
                Personal Receipt
              </p>
            ) : null}
          </div>
          <div className="flex items-center gap-1">
            {screenshotEnabled && (
              <button onClick={onScreenshot} className="h-8 w-8 rounded-md text-zinc-400 hover:text-white hover:bg-white/5 flex items-center justify-center">
                <Camera className="h-4 w-4" />
              </button>
            )}
            <button onClick={onClose} className="h-8 w-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center">
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-x-6 gap-y-4">
          <Meta label="Bill To" value={invoice.receiverName} />
          <Meta label="Sent Date" value={formatDate(invoice.createdAt)} />
          <div>
            <p className="mb-1 text-[12px] text-zinc-400">{docTypeTitle} Total</p>
            <p className="text-[28px] font-bold leading-none text-emerald-400">{money(invoice.total)}</p>
            <button
              disabled={!canPay}
              onClick={onRequestPay}
              className={cn(
                "mt-2 inline-flex rounded-md px-3 py-1 text-[12px] font-bold",
                invoice.status === "paid" && "bg-emerald-900/70 text-emerald-300",
                unpaid && incoming && "bg-amber-900/70 text-amber-300",
                unpaid && !incoming && "bg-rose-900/80 text-rose-300",
                canPay && "hover:brightness-125 cursor-pointer"
              )}
            >
              {statusLabel}
            </button>
          </div>

          <div>
            <p className="mb-1 text-[12px] text-zinc-400">Bill From</p>
            <p className="text-sm font-semibold">{invoice.senderName}</p>
            {jobLabel && !isPersonal ? (
              <span className="inline-block mt-1 text-[11px] font-semibold text-[#7eb3ff] bg-[#3A86FF]/15 border border-[#3A86FF]/30 px-2 py-0.5 rounded">
                {jobLabel}
              </span>
            ) : isPersonal && jobLabel ? (
              <span className="inline-block mt-1 text-[11px] font-medium text-purple-300/90 bg-purple-500/10 border border-purple-500/20 px-2 py-0.5 rounded">
                {jobLabel}
              </span>
            ) : null}
          </div>

          <Meta label="Due Date" value={invoice.dueDate ? formatDate(invoice.dueDate) : "No Due Date"} />
        </div>

        <div className="mt-5 border-t border-white/10 pt-4">
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0">
              <p className="text-[12px] text-zinc-400">{docTypeTitle} Title</p>
              <p className="mt-1 text-sm font-semibold">{invoice.title}</p>
              {invoice.description && invoice.description !== "0" && (
                <p className="mt-1 text-[12px] text-zinc-400">{invoice.description}</p>
              )}
              {(!invoice.description || invoice.description === "0") && (
                <p className="mt-1 text-[12px] text-zinc-500 italic">No Description Provided.</p>
              )}
            </div>
            <div className="text-right shrink-0">
              <p className="text-[12px] text-zinc-400">Amount</p>
              <p className="mt-1 text-sm font-semibold">{money(invoice.amount)}</p>
            </div>
          </div>
        </div>

        {(vatPercent > 0 || (invoice.vat && invoice.vat > 0)) && (
          <div className="mt-4 flex items-center justify-between border-t border-white/10 pt-3">
            <p className="text-sm font-semibold">VAT({vatPercent}%)</p>
            <p className="text-sm font-semibold">{money(invoice.vat)}</p>
          </div>
        )}

        <div className="mt-3 flex items-center justify-between border-t border-white/10 pt-3">
          <p className="text-[12px] text-zinc-400">{docTypeTitle} Type</p>
          <p className="text-sm font-semibold">
            {isPersonal ? (
              <span className="text-purple-300">Personal Receipt</span>
            ) : (
              <span className="text-[#7eb3ff]">Job Invoice ({jobLabel || "Society"})</span>
            )}
          </p>
        </div>

        <div className="mt-5 flex items-center gap-3">
          {incoming && canPay ? (
            <>
              <button
                disabled={busy}
                onClick={onRequestPay}
                className="flex-1 rounded-lg bg-[#1f7a4d] hover:bg-[#239057] py-3 text-sm font-bold tracking-wide disabled:opacity-50"
              >
                ACCEPT {docType}
              </button>
              <button
                disabled={busy}
                onClick={onReject}
                className="flex-1 rounded-lg bg-white hover:bg-zinc-100 py-3 text-sm font-bold tracking-wide text-rose-600 disabled:opacity-50"
              >
                REJECT {docType}
              </button>
            </>
          ) : canReject ? (
            <button
              disabled={busy}
              onClick={onReject}
              className="flex-1 rounded-lg bg-white hover:bg-zinc-100 py-3 text-sm font-bold tracking-wide text-rose-600 disabled:opacity-50"
            >
              REJECT {docType}
            </button>
          ) : canPay ? (
            <button
              disabled={busy}
              onClick={onRequestPay}
              className="rounded-lg bg-[#1f7a4d] hover:bg-[#239057] px-5 py-3 text-sm font-bold tracking-wide disabled:opacity-50"
            >
              PAY {docType}
            </button>
          ) : unpaid && invoice.canCancel ? (
            <button
              disabled={busy}
              onClick={onCancelInvoice}
              className="rounded-lg bg-rose-900/80 hover:bg-rose-800 px-5 py-3 text-sm font-bold tracking-wide text-rose-200 disabled:opacity-50"
            >
              CANCEL {docType}
            </button>
          ) : (
            <button onClick={onBack} className="text-[12px] font-semibold text-zinc-400 hover:text-white">
              BACK
            </button>
          )}
          <p className="ml-auto text-[12px] text-zinc-400">
            Reference ID: <span className="font-semibold text-white">{invoice.reference}</span>
          </p>
        </div>
      </div>

      {screenshotOpen && (
        <div className="absolute inset-0 flex items-center justify-center rounded-2xl bg-black/70">
          <div className={cn(panel, "w-[300px] p-5 text-center")}>
            <h3 className="mb-3 text-lg font-bold tracking-wide">SCREENSHOT CAPTURED</h3>
            <div className="mb-4 rounded-xl bg-white/5 p-3 text-left text-[11px] leading-relaxed">
              <p className="font-bold">
                {docType} #{invoice.id}
              </p>
              {jobLabel && !isPersonal && <p className="text-[#7eb3ff] font-medium">{jobLabel}</p>}
              <p>{invoice.title}</p>
              <p>
                {money(invoice.total)} · {invoice.reference}
              </p>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <button onClick={onCopy} className={blueBtn}>
                COPY
              </button>
              <button onClick={onCancelScreenshot} className={blueBtn}>
                CANCEL
              </button>
            </div>
          </div>
        </div>
      )}

      {payOpen && (
        <PaymentMethodModal
          busy={busy}
          onCash={() => onConfirmPay("cash")}
          onBank={() => onConfirmPay("bank")}
          onClose={onClosePay}
        />
      )}
    </div>
  );
}

function PaymentMethodModal({
  busy,
  onCash,
  onBank,
  onClose,
}: {
  busy: boolean;
  onCash: () => void;
  onBank: () => void;
  onClose: () => void;
}) {
  return (
    <div className="absolute inset-0 z-[60] flex items-center justify-center bg-black/55">
      <div className={cn(panel, "relative w-[300px] px-6 py-6 text-center")}>
        <button
          onClick={onClose}
          className="absolute right-3 top-3 h-7 w-7 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center"
        >
          <X className="h-4 w-4" />
        </button>
        <h3 className="text-[20px] font-bold tracking-wide">
          PAYMENT <span className="text-[#7eb3ff]">METHOD</span>
        </h3>
        <img src={iconPay} alt="" className="mx-auto mt-4 h-24 w-24 object-contain" />
        <p className="mt-3 mb-5 text-sm">How do you want to pay?</p>
        <div className="grid grid-cols-2 gap-3">
          <button
            disabled={busy}
            onClick={onCash}
            className="rounded-lg bg-[#152238] hover:bg-[#1c2e4a] py-3 text-sm font-semibold text-[#7eb3ff] disabled:opacity-50"
          >
            Cash
          </button>
          <button
            disabled={busy}
            onClick={onBank}
            className="rounded-lg bg-[#152238] hover:bg-[#1c2e4a] py-3 text-sm font-semibold text-[#7eb3ff] disabled:opacity-50"
          >
            Bank
          </button>
        </div>
      </div>
    </div>
  );
}

function Meta({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="mb-1 text-[12px] text-zinc-400">{label}</p>
      <p className="text-sm font-semibold">{value}</p>
    </div>
  );
}
