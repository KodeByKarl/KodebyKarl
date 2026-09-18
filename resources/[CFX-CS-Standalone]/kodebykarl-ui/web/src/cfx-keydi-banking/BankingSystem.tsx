import React, { useEffect, useState } from "react";
import { X, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import pandoraLogo from "@/assets/pandora-city-logo.png";

export interface Transaction {
  type: "deposit" | "withdraw" | "transfer_in" | "transfer_out";
  label: string;
  amount: number;
  date: string;
  id: string;
}

export interface BankingData {
  playerName: string;
  accountNumber: string;
  bankBalance: number;
  cashBalance: number;
  transactions: Transaction[];
}

interface BankingSystemProps {
  initialData?: BankingData | null;
  isATM?: boolean;
  onClose: () => void;
}

const PANEL_STYLE = {
  background: "linear-gradient(180deg, #0a2846 0%, #05192f 100%)",
  boxShadow: "var(--shadow-elegant)",
  borderColor: "rgba(255, 122, 181, 0.24)",
};

function getResourceName() {
  return (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : "cfx-keydi-ui";
}

export default function BankingSystem({ initialData = null, isATM = false, onClose }: BankingSystemProps) {
  const [tab, setTab] = useState<"overview" | "actions">("overview");
  const [data, setData] = useState<BankingData>({
    playerName: "Kosei Carpio",
    accountNumber: "319-17-8210",
    bankBalance: 380000,
    cashBalance: 1000,
    transactions: [
      {
        type: "deposit",
        label: "Cash deposit",
        amount: 50000,
        date: "2026-07-01 01:23:33",
        id: "TXN-1782840213-518587-1431",
      },
    ],
  });

  // Action Inputs
  const [amount, setAmount] = useState<number>(0);
  const [transferType, setTransferType] = useState<"id" | "account">("id");
  const [transferVal, setTransferVal] = useState<string>("");
  const [submitting, setSubmitting] = useState(false);

  // PIN code variables
  const [pinVerified, setPinVerified] = useState(!isATM);
  const [pinInput, setPinInput] = useState("");
  const [pinError, setPinError] = useState(false);
  const [newPinVal, setNewPinVal] = useState("");

  useEffect(() => {
    if (initialData) {
      setData(initialData);
    }
  }, [initialData]);

  // Sync PIN verification status when opening in different modes
  useEffect(() => {
    setPinVerified(!isATM);
    setPinInput("");
    setPinError(false);
  }, [isATM]);

  // Listen to message updates from client NUI
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const msg = event.data;
      if (msg.action === "cfx-keydi-banking:update" && msg.data) {
        setData(msg.data);
      }
    };
    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  // Escape key handler
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onClose]);

  const handleDeposit = () => {
    if (amount <= 0) {
      toast.error("Please enter a valid amount to deposit.");
      return;
    }
    if (data.cashBalance < amount) {
      toast.error("You do not have enough cash on hand.");
      return;
    }

    setSubmitting(true);
    fetch(`https://${getResourceName()}/cfx-keydi-banking:deposit`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({ amount }),
    })
      .then((res) => res.json())
      .then((resData) => {
        if (resData.success && resData.data) {
          setData(resData.data);
          setAmount(0);
        }
      })
      .finally(() => setSubmitting(false));
  };

  const handleWithdraw = () => {
    if (amount <= 0) {
      toast.error("Please enter a valid amount to withdraw.");
      return;
    }
    if (data.bankBalance < amount) {
      toast.error("You do not have enough funds in your account.");
      return;
    }

    setSubmitting(true);
    fetch(`https://${getResourceName()}/cfx-keydi-banking:withdraw`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({ amount }),
    })
      .then((res) => res.json())
      .then((resData) => {
        if (resData.success && resData.data) {
          setData(resData.data);
          setAmount(0);
        }
      })
      .finally(() => setSubmitting(false));
  };

  const handleTransfer = () => {
    if (amount <= 0) {
      toast.error("Please enter a valid amount to transfer.");
      return;
    }
    if (data.bankBalance < amount) {
      toast.error("Insufficient bank balance.");
      return;
    }
    if (!transferVal.trim()) {
      toast.error(
        transferType === "id"
          ? "Please enter a target Server ID."
          : "Please enter a target Account Number."
      );
      return;
    }

    setSubmitting(true);
    fetch(`https://${getResourceName()}/cfx-keydi-banking:transfer`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({
        amount,
        targetType: transferType,
        targetVal: transferVal.trim(),
      }),
    })
      .then((res) => res.json())
      .then((resData) => {
        if (resData.success && resData.data) {
          setData(resData.data);
          setAmount(0);
          setTransferVal("");
        }
      })
      .finally(() => setSubmitting(false));
  };

  const handleChangePin = () => {
    if (newPinVal.length !== 4) {
      toast.error("PIN code must be exactly 4 digits.");
      return;
    }

    setSubmitting(true);
    fetch(`https://${getResourceName()}/cfx-keydi-banking:changePin`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({ pin: newPinVal }),
    })
      .then((res) => res.json())
      .then((success) => {
        if (success) {
          toast.success("ATM PIN code updated successfully.");
          setNewPinVal("");
        } else {
          toast.error("Failed to update PIN code.");
        }
      })
      .catch(() => toast.error("Error updating PIN code."))
      .finally(() => setSubmitting(false));
  };

  const handleKeyClick = (key: string) => {
    if (pinError) setPinError(false);
    if (key === "C") {
      setPinInput("");
      return;
    }
    if (key === "<-") {
      setPinInput((prev) => prev.slice(0, -1));
      return;
    }
    if (pinInput.length >= 4) return;
    
    const newVal = pinInput + key;
    setPinInput(newVal);

    if (newVal.length === 4) {
      fetch(`https://${getResourceName()}/cfx-keydi-banking:verifyPin`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({ pin: newVal }),
      })
        .then((res) => res.json())
        .then((success) => {
          if (success) {
            setPinVerified(true);
            toast.success("PIN verified successfully.");
          } else {
            setPinError(true);
            setPinInput("");
            toast.error("Incorrect PIN. Please try again.");
          }
        })
        .catch(() => {
          setPinError(true);
          setPinInput("");
          toast.error("Error verifying PIN.");
        });
    }
  };

  // Render numerical keypad if opening via ATM and PIN is not verified
  if (!pinVerified) {
    return (
      <div className="pandora fixed inset-0 flex items-center justify-center p-8 bg-black/60 backdrop-blur-[4px] select-none pointer-events-auto animate-fade-in font-sans z-40">
        <div
          className={cn(
            "pandora-panel w-[340px] p-6 rounded-3xl border flex flex-col items-center relative overflow-hidden transition-all duration-300",
            pinError && "border-red-500/50! shadow-[0_0_30px_rgba(239,68,68,0.2)]! animate-shake"
          )}
        >
          {/* Header Close button */}
          <button
            onClick={onClose}
            className="absolute top-4 right-4 flex h-6 w-6 items-center justify-center rounded-md border border-white/10 text-white/80 hover:text-white hover:border-white/25 bg-black/25 transition cursor-pointer"
          >
            <X className="h-3 w-3" strokeWidth={2.5} />
          </button>

          {/* Logo Circle */}
          <div className="pandora-icon relative flex h-14 w-14 items-center justify-center rounded-full mb-3 mt-2">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor" className="h-6 w-6">
              <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z" />
            </svg>
          </div>

          <p className="pandora-display text-[8.5px] font-black uppercase tracking-[0.25em]" style={{ color: "var(--pandora-sun)" }}>PANDORA CITY BANKING</p>
          <h3 className="text-sm font-bold text-white mt-1">Enter ATM PIN</h3>
          <p className="text-[9.5px] text-muted-foreground/60 mt-1 mb-5">Please insert your 4-digit code</p>

          {/* 4 Digit Display Dots */}
          <div className="flex gap-4 mb-6">
            {[0, 1, 2, 3].map((idx) => {
              const active = pinInput.length > idx;
              return (
                <div
                  key={idx}
                  className={cn(
                    "h-3.5 w-3.5 rounded-full border transition-all duration-200",
                    active
                      ? "bg-[#ff3d96] border-[#ff3d96] shadow-[0_0_8px_rgba(255,61,150,0.8)] scale-110"
                      : "border-white/20 bg-black/30"
                  )}
                />
              );
            })}
          </div>

          {/* Keyboard Grid */}
          <div className="grid grid-cols-3 gap-3 w-full px-2 mb-2">
            {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((val) => (
              <button
                key={val}
                type="button"
                onClick={() => handleKeyClick(val)}
                className="py-3 rounded-2xl border border-white/5 bg-black/25 hover:bg-[#ff3d96]/12 hover:border-[#ff3d96]/45 text-sm font-bold text-white transition active:scale-95 cursor-pointer"
              >
                {val}
              </button>
            ))}
            <button
              type="button"
              onClick={() => handleKeyClick("C")}
              className="py-3 rounded-2xl border border-white/5 bg-black/25 hover:bg-red-500/10 hover:border-red-500/30 text-xs font-bold text-red-400 transition active:scale-95 cursor-pointer"
            >
              C
            </button>
            <button
              type="button"
              onClick={() => handleKeyClick("0")}
              className="py-3 rounded-2xl border border-white/5 bg-black/25 hover:bg-[#ff3d96]/12 hover:border-[#ff3d96]/45 text-sm font-bold text-white transition active:scale-95 cursor-pointer"
            >
              0
            </button>
            <button
              type="button"
              onClick={() => handleKeyClick("<-")}
              className="py-3 rounded-2xl border border-white/5 bg-black/25 hover:bg-amber-500/10 hover:border-amber-500/30 text-xs font-bold text-amber-400 transition active:scale-95 cursor-pointer flex items-center justify-center"
            >
              &larr;
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="pandora fixed inset-0 flex items-center justify-center p-8 bg-black/60 backdrop-blur-[4px] select-none pointer-events-auto animate-fade-in font-sans z-40">
      <div className="pandora-panel flex flex-col h-[680px] w-full max-w-5xl rounded-2xl border overflow-hidden animate-scale-up">
        {/* Core Dual Panel Layout */}
        <div className="flex-1 flex min-h-0">
          {/* LEFT SIDE PANEL (Overview/Accounts Lists) */}
          <div
            className="w-[325px] border-r p-5 flex flex-col shrink-0 relative bg-transparent"
            style={{ borderRightColor: "rgba(255, 122, 181, 0.24)" }}
          >
            <div className="panel-grid absolute inset-0 pointer-events-none" />
            
            {/* Header / Brand Logo */}
            <div className="relative flex flex-col items-center mt-2 shrink-0">
              <img src={pandoraLogo} alt="Pandora City" className="pandora-logo w-16 object-contain" />
              <p className="pandora-display mt-2.5 text-[8.5px] font-black uppercase tracking-[0.25em]" style={{ color: "var(--pandora-sun)" }}>
                PANDORA CITY NETWORK
              </p>
              <h3 className="pandora-title text-[15px] font-black mt-0.5 tracking-wide">
                Banking Console
              </h3>
              <p className="mt-2 text-[10px] leading-relaxed text-muted-foreground/60 text-center max-w-[230px]">
                Manage cash, accounts, transfers, and history from one place.
              </p>
            </div>

            {/* Cash Box */}
            <div className="mt-4 p-3.5 game-card text-center shrink-0">
              <p className="text-[8px] font-black uppercase tracking-wider text-muted-foreground/60">
                Cash on Hand
              </p>
              <p className="text-lg font-black text-primary mt-0.5">
                ${data.cashBalance.toLocaleString()}
              </p>
            </div>

            {/* Menu Buttons */}
            <div className="mt-4 flex flex-col gap-2.5 shrink-0">
              <button
                type="button"
                onClick={() => setTab("overview")}
                className={cn(
                  "flex items-center gap-3 p-3 transition cursor-pointer text-left w-full game-card",
                  tab === "overview"
                    ? "border-primary bg-primary/10 shadow-[0_0_15px_rgba(255,61,150,0.2)] animate-pulse-subtle"
                    : ""
                )}
              >
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl game-card-icon font-bold">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    strokeWidth="2.5"
                    stroke="currentColor"
                    className="h-4 w-4"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-3.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z"
                    />
                  </svg>
                </div>
                <div>
                  <h4 className="text-xs font-bold text-white leading-tight">Overview</h4>
                  <p className="text-[8.5px] text-muted-foreground/60 mt-0.5">Balance and transactions</p>
                </div>
              </button>

              <button
                type="button"
                onClick={() => setTab("actions")}
                className={cn(
                  "flex items-center gap-3 p-3 transition cursor-pointer text-left w-full game-card",
                  tab === "actions"
                    ? "border-primary bg-primary/10 shadow-[0_0_15px_rgba(255,61,150,0.2)] animate-pulse-subtle"
                    : ""
                )}
              >
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl game-card-icon font-bold">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    strokeWidth="2.5"
                    stroke="currentColor"
                    className="h-4 w-4"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5"
                    />
                  </svg>
                </div>
                <div>
                  <h4 className="text-xs font-bold text-white leading-tight">Actions</h4>
                  <p className="text-[8.5px] text-muted-foreground/60 mt-0.5">Move money between accounts</p>
                </div>
              </button>
            </div>

            {/* stats box */}
            <div className="grid grid-cols-2 gap-2.5 mt-3 shrink-0">
              <div className="p-2.5 game-card text-center">
                <p className="text-[8px] font-bold uppercase tracking-wider text-muted-foreground/50">
                  Accounts
                </p>
                <p className="text-[11.5px] font-black text-white mt-0.5">1</p>
              </div>
              <div className="p-2.5 game-card text-center">
                <p className="text-[8px] font-bold uppercase tracking-wider text-muted-foreground/50">
                  Selected
                </p>
                <p className="text-[11.5px] font-black text-primary mt-0.5">
                  ${data.bankBalance.toLocaleString()}
                </p>
              </div>
            </div>

            {/* Accounts Sub List */}
            <div className="mt-4 flex-1 flex flex-col justify-start min-h-0 w-full">
              <p className="text-[8.5px] font-black uppercase tracking-wider text-muted-foreground/60 mb-2">
                Your Accounts
              </p>
              <div className="flex-1 overflow-y-auto custom-scrollbar pr-1">
                <div className="p-3 game-card flex items-start gap-2.5 text-left w-full border-primary/45 bg-primary/5">
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg game-card-icon mt-0.5">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      strokeWidth="2.5"
                      stroke="currentColor"
                      className="h-4 w-4"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z"
                      />
                    </svg>
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-[7.5px] font-black uppercase tracking-wider text-muted-foreground/60">
                      PERSONAL
                    </p>
                    <h4 className="text-[11px] font-black text-white truncate mt-0.5">
                      {data.playerName}
                    </h4>
                    <p className="text-[8.5px] text-muted-foreground/60 mt-0.5 truncate">
                      {data.accountNumber}
                    </p>
                    <p className="text-[11px] font-bold text-primary mt-1.5">
                      ${data.bankBalance.toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* RIGHT PANEL (Main balance / Forms / Actions) */}
          <div className="flex-1 p-6 flex flex-col min-w-0 bg-transparent">
            {/* Right Panel Header */}
            <div className="flex items-start justify-between border-b pb-3.5 border-[#ff3d96]/15 shrink-0">
              <div>
                <p className="text-[9px] font-bold uppercase tracking-[0.25em] text-primary">
                  {tab === "overview" ? "ACCOUNT OVERVIEW" : "BANK ACTIONS"}
                </p>
                <h2 className="text-sm font-bold text-white mt-0.5">
                  {data.playerName}
                </h2>
                <p className="text-[10px] text-muted-foreground/80 mt-1 leading-none">
                  {tab === "overview"
                    ? "Balance snapshot and recent transaction history."
                    : "Deposit, withdraw, and transfer funds securely."}
                </p>
              </div>
              <button
                onClick={onClose}
                className="flex items-center gap-1.5 px-2.5 py-1 rounded-md border border-white/10 text-white/80 hover:text-white hover:border-white/25 bg-black/25 text-[10px] font-semibold transition cursor-pointer"
              >
                <span>Esc</span>
                <X className="h-3 w-3" strokeWidth={2.5} />
              </button>
            </div>

            {tab === "overview" ? (
              /* OVERVIEW TAB CONTENT */
              <div className="flex-1 flex flex-col min-h-0">
                {/* Main Account balance card */}
                <div
                  className="p-5 rounded-2xl border border-primary/25 mt-4 flex flex-col justify-between h-[135px] shrink-0"
                  style={{
                    background: "linear-gradient(135deg, rgba(255, 61, 150, 0.26) 0%, rgba(53, 199, 242, 0.16) 45%, rgba(9, 34, 60, 0.96) 100%)",
                    boxShadow: "0 0 25px rgba(255, 61, 150, 0.16)"
                  }}
                >
                  <div>
                    <p className="text-[8px] font-black uppercase tracking-widest text-primary">
                      {data.playerName.toUpperCase()}
                    </p>
                    <h1 className="text-3xl font-black text-white mt-1.5">
                      ${data.bankBalance.toLocaleString()}
                    </h1>
                    <p className="text-[10px] text-muted-foreground/60 mt-1.5">
                      {data.accountNumber}
                    </p>
                  </div>
                  <div>
                    <span className="px-2 py-0.5 rounded bg-black/30 border border-border/20 text-[8.5px] font-bold uppercase tracking-wider text-muted-foreground/80">
                      Personal Account
                    </span>
                  </div>
                </div>

                {/* Recent transaction rows */}
                <div className="flex-1 flex flex-col mt-5 min-h-0">
                  <div className="flex items-center justify-between shrink-0 mb-3">
                    <div>
                      <p className="text-[9px] font-black uppercase tracking-wider text-primary">
                        RECENT TRANSACTIONS
                      </p>
                      <p className="text-[9.5px] text-muted-foreground/75 mt-0.5">
                        Latest activity on this account
                      </p>
                    </div>
                    <span className="px-2 py-0.5 rounded bg-black/30 text-[9px] font-bold text-muted-foreground border border-[#ff3d96]/15">
                      {data.transactions.length} total
                    </span>
                  </div>

                  <div className="flex-1 overflow-y-auto custom-scrollbar pr-1 flex flex-col gap-2 min-h-0">
                    {data.transactions.length > 0 ? (
                      data.transactions.map((tx, idx) => {
                        const isDeposit = tx.type === "deposit" || tx.type === "transfer_in";
                        return (
                          <div
                            key={idx}
                            className="flex items-center justify-between p-3 game-card"
                          >
                            <div className="flex items-center gap-3">
                              <div
                                className={cn(
                                  "flex h-8 w-8 items-center justify-center rounded-xl border shrink-0",
                                  isDeposit
                                    ? "bg-emerald-500/10 border-emerald-500/30 text-emerald-400"
                                    : "bg-amber-500/10 border-amber-500/30 text-amber-400"
                                )}
                              >
                                {isDeposit ? (
                                  <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    strokeWidth="2.5"
                                    stroke="currentColor"
                                    className="h-4 w-4"
                                  >
                                    <path
                                      strokeLinecap="round"
                                      strokeLinejoin="round"
                                      d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
                                    />
                                  </svg>
                                ) : (
                                  <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    strokeWidth="2.5"
                                    stroke="currentColor"
                                    className="h-4 w-4"
                                  >
                                    <path
                                      strokeLinecap="round"
                                      strokeLinejoin="round"
                                      d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5"
                                    />
                                  </svg>
                                )}
                              </div>
                              <div className="min-w-0">
                                <h5 className="text-xs font-bold text-white">{tx.label}</h5>
                                <p className="text-[8.5px] text-muted-foreground/60 mt-0.5 truncate">
                                  {tx.date} • {tx.id}
                                </p>
                              </div>
                            </div>
                            <span
                              className={cn(
                                "px-2.5 py-1 rounded-full text-[10px] font-black tracking-wide",
                                isDeposit
                                  ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                                  : "bg-amber-500/10 text-amber-400 border border-amber-500/20"
                              )}
                            >
                              {isDeposit ? "+" : "-"}${tx.amount.toLocaleString()}
                            </span>
                          </div>
                        );
                      })
                    ) : (
                      <div className="text-center py-8 text-[10px] text-muted-foreground/50">
                        No recent activity on this account
                      </div>
                    )}
                  </div>

                  {/* Pagination foot */}
                  <div className="flex items-center justify-between mt-4 border-t pt-3 border-[#ff3d96]/15 shrink-0 text-[10px]">
                    <button className="px-2.5 py-1 rounded border border-[#ff3d96]/15 text-muted-foreground/70 hover:text-white transition cursor-pointer">
                      &larr; Prev
                    </button>
                    <span className="text-muted-foreground/50">Page 1/1 - 20 per page</span>
                    <button className="px-2.5 py-1 rounded border border-[#ff3d96]/15 text-muted-foreground/70 hover:text-white transition cursor-pointer">
                      Next &rarr;
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              /* ACTIONS TAB CONTENT */
              <div className="flex-1 flex flex-col min-h-0 justify-between">
                {/* Inputs area */}
                <div className="grid grid-cols-2 gap-4 mt-4 shrink-0">
                  {/* Transaction Amount */}
                  <div className="p-4 game-card flex flex-col justify-between">
                    <div>
                      <label className="text-[8.5px] font-black uppercase tracking-wider text-[#ff3d96]">
                        TRANSACTION AMOUNT
                      </label>
                      <input
                        type="number"
                        value={amount || ""}
                        onChange={(e) => setAmount(Math.max(0, parseInt(e.target.value) || 0))}
                        placeholder="0"
                        className="mt-1.5 w-full rounded-xl border border-border/40 px-3 py-2 text-xs font-medium text-foreground placeholder:text-muted-foreground/60 bg-black/30 focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/30 transition"
                      />
                    </div>
                  </div>

                  {/* Security Settings (Change PIN) */}
                  <div className="p-4 game-card flex flex-col justify-between">
                    <div>
                      <label className="text-[8.5px] font-black uppercase tracking-wider text-[#ff3d96]">
                        UPDATE ATM PIN (4 DIGITS)
                      </label>
                      <div className="flex gap-2 mt-1.5">
                        <input
                          type="text"
                          maxLength={4}
                          value={newPinVal}
                          onChange={(e) => setNewPinVal(e.target.value.replace(/\D/g, ""))}
                          placeholder="e.g. 1234"
                          className="flex-1 rounded-xl border border-border/40 px-3 py-2 text-xs font-medium text-foreground placeholder:text-muted-foreground/60 bg-black/30 focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/30 transition"
                        />
                        <button
                          type="button"
                          onClick={handleChangePin}
                          className="px-3 rounded-xl bg-gradient-to-r from-[#ff5fa8] to-[#d3106f] text-white hover:opacity-95 text-xs font-bold transition cursor-pointer"
                        >
                          Save
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Cash Movement Deposit & Withdraw boxes */}
                <div className="mt-4 shrink-0">
                  <p className="text-[8.5px] font-black uppercase tracking-wider text-[#ff3d96] mb-2">
                    CASH MOVEMENT
                  </p>
                  <p className="text-[9.5px] text-muted-foreground/75 mb-3 leading-none">
                    Move funds between your wallet and the selected account.
                  </p>
                  <div className="grid grid-cols-2 gap-4">
                    {/* Deposit */}
                    <button
                      type="button"
                      onClick={handleDeposit}
                      disabled={submitting}
                      className="p-4 game-card text-left transition cursor-pointer group flex items-start gap-3.5"
                    >
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl game-card-icon font-bold text-white">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          strokeWidth="2.5"
                          stroke="currentColor"
                          className="h-5 w-5"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
                          />
                        </svg>
                      </div>
                      <div>
                        <h4 className="text-xs font-bold text-white">Deposit</h4>
                        <p className="text-[8.5px] text-muted-foreground mt-0.5">Cash to account</p>
                      </div>
                    </button>

                    {/* Withdraw */}
                    <button
                      type="button"
                      onClick={handleWithdraw}
                      disabled={submitting}
                      className="p-4 game-card text-left transition cursor-pointer group flex items-start gap-3.5 hover:bg-amber-500/5! hover:border-amber-500/40!"
                    >
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl game-card-icon font-bold text-white border-amber-500/35! bg-amber-500/20!">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          strokeWidth="2.5"
                          stroke="currentColor"
                          className="h-5 w-5"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5"
                          />
                        </svg>
                      </div>
                      <div>
                        <h4 className="text-xs font-bold text-white">Withdraw</h4>
                        <p className="text-[8.5px] text-muted-foreground mt-0.5">Account to cash</p>
                      </div>
                    </button>
                  </div>
                </div>

                {/* Transfer Panel section */}
                <div className="mt-4 p-4 game-card flex-1 min-h-0 flex flex-col justify-between">
                  <div>
                    <p className="text-[8.5px] font-black uppercase tracking-wider text-[#ff3d96] mb-2">
                      TRANSFER
                    </p>
                    <p className="text-[9.5px] text-muted-foreground mb-3 leading-none">
                      Send from the selected account to another player or account.
                    </p>

                    {/* Toggle PlayerID vs Account Number tabs */}
                    <div className="grid grid-cols-2 gap-3 p-1 bg-black/25 border border-border/20 rounded-xl mb-4 shrink-0">
                      <button
                        type="button"
                        onClick={() => setTransferType("id")}
                        className={cn(
                          "py-1.5 text-[9px] font-black uppercase tracking-wider rounded-lg transition cursor-pointer text-center",
                          transferType === "id"
                            ? "bg-[#ff3d96] text-white shadow-[0_0_8px_rgba(255,61,150,0.25)]"
                            : "text-muted-foreground hover:text-white"
                        )}
                      >
                        Player ID
                      </button>
                      <button
                        type="button"
                        onClick={() => setTransferType("account")}
                        className={cn(
                          "py-1.5 text-[9px] font-black uppercase tracking-wider rounded-lg transition cursor-pointer text-center",
                          transferType === "account"
                            ? "bg-[#ff3d96] text-white shadow-[0_0_8px_rgba(255,61,150,0.25)]"
                            : "text-muted-foreground hover:text-white"
                        )}
                      >
                        Account no.
                      </button>
                    </div>

                    {/* Target inputs */}
                    <div>
                      <label className="text-[8.5px] font-black uppercase tracking-wider text-muted-foreground/80">
                        {transferType === "id" ? "TARGET SERVER ID" : "TARGET ACCOUNT NUMBER"}
                      </label>
                      <input
                        type="text"
                        value={transferVal}
                        onChange={(e) => setTransferVal(e.target.value)}
                        placeholder={transferType === "id" ? "e.g. 42" : "e.g. 319-17-8210"}
                        className="mt-1.5 w-full rounded-xl border border-border/40 px-3 py-2.5 text-xs font-medium text-foreground placeholder:text-muted-foreground/60 bg-black/30 focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/30 transition"
                      />
                    </div>
                  </div>

                  {/* Send transfer button */}
                  <button
                    type="button"
                    onClick={handleTransfer}
                    disabled={submitting}
                    className="mt-4 w-full rounded-xl bg-gradient-to-r from-[#d3106f] to-[#ff3d96] py-3 text-xs font-bold text-white hover:opacity-95 hover:shadow-[0_0_15px_rgba(255,61,150,0.3)] transition cursor-pointer flex items-center justify-center gap-2 shrink-0 disabled:opacity-65"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      strokeWidth="2.5"
                      stroke="currentColor"
                      className="h-4 w-4"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5"
                      />
                    </svg>
                    <span>Send transfer</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Bottom Card Footer */}
        <div className="h-10 bg-black/35 border-t border-[#ff3d96]/20 flex items-center justify-center gap-2 shrink-0">
          <img src={pandoraLogo} alt="Pandora City" className="h-4 w-4 object-contain" />
          <span className="pandora-display text-[10px] font-bold tracking-[0.22em]" style={{ color: "var(--pandora-pink-soft)" }}>
            PANDORA CITY
          </span>
        </div>
      </div>
    </div>
  );
}
