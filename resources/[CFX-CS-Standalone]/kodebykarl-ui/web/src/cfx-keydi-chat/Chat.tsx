import React, { useState, useEffect, useLayoutEffect, useRef, useMemo, useCallback, memo } from "react";
import grimLogo from "@/assets/grim-city-logo.png";

interface Message {
  template?: string;
  templateId?: string;
  args?: string[];
  color?: [number, number, number];
  multiline?: boolean;
}

interface StoredMessage extends Message {
  id: number;
  html: string;
}

interface SuggestionParam {
  name: string;
  help?: string;
  disabled?: boolean;
}

interface Suggestion {
  name: string;
  help?: string;
  params?: SuggestionParam[];
  disabled?: boolean;
}

const DEFAULT_TEMPLATES: Record<string, string> = {
  default: '<div style="background: linear-gradient(135deg, rgba(28, 14, 18, 0.82) 0%, rgba(15, 10, 14, 0.9) 100%); border-radius: 6px; padding: 5px 9px; margin-bottom: 4px; border-left: 2px solid #ff3a3a; border-top: 1px solid rgba(255, 58, 58, 0.12); box-shadow: 0 3px 12px rgba(0,0,0,0.45); text-align: left; font-family: \'Outfit\', sans-serif; word-break: break-word; overflow-wrap: anywhere; white-space: pre-wrap; max-width: 100%; box-sizing: border-box; flex-shrink: 0; min-height: min-content; line-height: 1.3; font-size: 12px;"><b style="color: #ff8080; letter-spacing: 0.2px;">{0}</b><span style="color: rgba(255,255,255,0.4); margin: 0 5px;">•</span><span style="color: #ffffff; font-weight: 500;">{1}</span></div>',
  defaultAlt: "<div style='word-break: break-word; overflow-wrap: anywhere; white-space: pre-wrap; max-width: 100%; flex-shrink: 0; min-height: min-content; line-height: 1.3; font-size: 12px;'>{0}</div>",
  print: "<pre style='text-align: left; font-family: monospace; font-size: 11px; color: #ff8080; word-break: break-word; overflow-wrap: anywhere; white-space: pre-wrap; max-width: 100%; box-sizing: border-box; margin: 0; flex-shrink: 0; min-height: min-content; line-height: 1.3;'>{0}</pre>",
  "example:important": "<h1 style='text-align: left; color: #ff3a3a; word-break: break-word; overflow-wrap: anywhere; flex-shrink: 0; line-height: 1.3; font-size: 14px;'>^2{0}</h1>"
};

const MAX_MESSAGES = 80;

function escapeHtml(unsafe: string): string {
  return String(unsafe)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function colorizeOld(str: string, color: [number, number, number]): string {
  return `<span style="color: rgb(${color[0]}, ${color[1]}, ${color[2]})">${str}</span>`;
}

function colorize(str: string): string {
  const colorMap: Record<string, string> = {
    "0": "#ffffff",
    "1": "#ff4d4d",
    "2": "#2ecc71",
    "3": "#f1c40f",
    "4": "#3498db",
    "5": "#00d2d3",
    "6": "#9b59b6",
    "7": "#ffffff",
    "8": "#e74c3c",
    "9": "#ff7979"
  };

  let s = "<span>" + str.replace(/\^([0-9])/g, (_, colorNum) => {
    const hex = colorMap[colorNum] || "#ffffff";
    return `</span><span style="color: ${hex}">`;
  }) + "</span>";

  const styleDict: Record<string, string> = {
    "*": "font-weight: bold;",
    "_": "text-decoration: underline;",
    "~": "text-decoration: line-through;",
    "=": "text-decoration: underline line-through;",
    "r": "text-decoration: none; font-weight: normal; font-style: normal;"
  };

  const styleRegex = /\^([_*~=r])(.*?)(?=$|\^r|<\/em>)/;
  while (s.match(styleRegex)) {
    s = s.replace(styleRegex, (_, styleCode, inner) => {
      const style = styleDict[styleCode] || "";
      return `<em style="${style}">${inner}</em>`;
    });
  }

  return s.replace(/<span[^>]*><\/span[^>]*>/g, "");
}

function formatMessage(msg: Message, templates: Record<string, string>): string {
  let templateStr = msg.template ? msg.template : (templates[msg.templateId || "default"] || "{0}: {1}");

  if (!msg.template && (!msg.templateId || msg.templateId === "default") && msg.args && msg.args.length === 1) {
    templateStr = templates["defaultAlt"] || "{0}";
  }

  const args = msg.args || [];
  templateStr = templateStr.replace(/{(\d+)}/g, (match, numberStr) => {
    const number = parseInt(numberStr, 10);
    let argEscaped = args[number] !== undefined ? escapeHtml(args[number]) : match;
    if (number === 0 && msg.color) {
      argEscaped = colorizeOld(argEscaped, msg.color);
    }
    return argEscaped;
  });

  return colorize(templateStr);
}

const MessageRow = memo(function MessageRow({ html }: { html: string }) {
  return (
    <div
      className="grim-chat-msg shrink-0 min-h-min text-[12px] leading-snug break-words [overflow-wrap:anywhere] [word-break:break-word] font-medium antialiased text-white [text-shadow:_0_1px_3px_rgba(0,0,0,0.9)] text-left w-full max-w-full overflow-x-hidden overflow-y-visible"
      style={{ wordBreak: "break-word", overflowWrap: "anywhere", whiteSpace: "pre-wrap", flexShrink: 0, minHeight: "min-content" }}
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
});

function getResourceName(): string {
  return (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : "cfx-keydi-ui";
}

export default function Chat() {
  const [isOpen, setIsOpen] = useState(false);
  const [showWindow, setShowWindow] = useState(false);
  const [shouldHide, setShouldHide] = useState(false);
  const [inputValue, setInputValue] = useState("");
  const [messages, setMessages] = useState<StoredMessage[]>([]);
  const [templates, setTemplates] = useState<Record<string, string>>(DEFAULT_TEMPLATES);
  const [allSuggestions, setAllSuggestions] = useState<Suggestion[]>([]);
  const [removedSuggestions, setRemovedSuggestions] = useState<string[]>([]);
  const [fadeTimeout, setFadeTimeout] = useState(10000);

  const [history, setHistory] = useState<string[]>([]);
  const [historyIndex, setHistoryIndex] = useState(-1);

  const inputRef = useRef<HTMLInputElement>(null);
  const openListRef = useRef<HTMLDivElement>(null);
  const overlayListRef = useRef<HTMLDivElement>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isOpenRef = useRef(false);
  const fadeTimeoutRef = useRef(10000);
  const templatesRef = useRef(templates);
  const msgIdRef = useRef(0);
  const resetShowWindowTimerRef = useRef<() => void>(() => {});

  useEffect(() => {
    isOpenRef.current = isOpen;
  }, [isOpen]);

  useEffect(() => {
    fadeTimeoutRef.current = fadeTimeout;
  }, [fadeTimeout]);

  useEffect(() => {
    templatesRef.current = templates;
  }, [templates]);

  const resetShowWindowTimer = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    setShowWindow(true);
    timerRef.current = setTimeout(() => {
      if (!isOpenRef.current) {
        setShowWindow(false);
      }
    }, fadeTimeoutRef.current);
  }, []);

  useEffect(() => {
    resetShowWindowTimerRef.current = resetShowWindowTimer;
  }, [resetShowWindowTimer]);

  const scrollMessagesToBottom = useCallback(() => {
    const doScroll = () => {
      const els = [openListRef.current, overlayListRef.current];
      for (let i = 0; i < els.length; i++) {
        const el = els[i];
        if (!el) continue;
        el.scrollTop = el.scrollHeight;
      }
    };
    doScroll();
    requestAnimationFrame(() => {
      doScroll();
      setTimeout(doScroll, 10);
      setTimeout(doScroll, 50);
    });
  }, []);

  // Pin to newest message as soon as DOM updates (fixes "stuck on old chats")
  useLayoutEffect(() => {
    scrollMessagesToBottom();
  }, [messages, showWindow, isOpen, scrollMessagesToBottom]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const item = event.data;
      if (!item || typeof item.type !== "string") return;

      switch (item.type) {
        case "ON_CHAT_CONFIG":
          if (typeof item.fadeTimeout === "number" && item.fadeTimeout > 0) {
            setFadeTimeout(item.fadeTimeout);
            fadeTimeoutRef.current = item.fadeTimeout;
          }
          break;

        case "ON_OPEN":
          isOpenRef.current = true;
          setIsOpen(true);
          setShowWindow(true);
          if (timerRef.current) {
            clearTimeout(timerRef.current);
            timerRef.current = null;
          }
          scrollMessagesToBottom();
          break;

        case "ON_MESSAGE": {
          const raw = item.message as Message;
          const id = ++msgIdRef.current;
          const html = formatMessage(raw || {}, templatesRef.current);
          setMessages((prev) => {
            const next = [...prev, { ...(raw || {}), id, html }];
            return next.length > MAX_MESSAGES ? next.slice(next.length - MAX_MESSAGES) : next;
          });
          resetShowWindowTimerRef.current();
          scrollMessagesToBottom();
          break;
        }

        case "ON_CLEAR":
          setMessages([]);
          setHistory([]);
          setHistoryIndex(-1);
          setShowWindow(false);
          if (timerRef.current) {
            clearTimeout(timerRef.current);
            timerRef.current = null;
          }
          break;

        case "ON_SUGGESTION_ADD": {
          const sug = item.suggestion as Suggestion;
          setAllSuggestions((prev) => {
            const idx = prev.findIndex((a) => a.name === sug.name);
            if (idx !== -1) {
              const copy = prev.slice();
              const exists = { ...copy[idx] };
              if (sug.help && sug.help.trim() !== "") {
                exists.help = sug.help;
              }
              if (sug.params && sug.params.length > 0) {
                exists.params = sug.params;
              }
              copy[idx] = exists;
              return copy;
            }
            return [...prev, { ...sug, params: sug.params || [] }];
          });
          setRemovedSuggestions((prev) => prev.filter((name) => name !== sug.name));
          break;
        }

        case "ON_SUGGESTION_REMOVE":
          setRemovedSuggestions((prev) => (prev.includes(item.name) ? prev : [...prev, item.name]));
          break;

        case "ON_COMMANDS_RESET":
          setAllSuggestions([]);
          setRemovedSuggestions([]);
          break;

        case "ON_TEMPLATE_ADD": {
          const tpl = item.template;
          setTemplates((prev) => ({
            ...prev,
            [tpl.id]: tpl.html
          }));
          break;
        }

        case "ON_SCREEN_STATE_CHANGE":
          setShouldHide(!!item.shouldHide);
          break;

        default:
          break;
      }
    };

    window.addEventListener("message", handleMessage);

    fetch(`https://${getResourceName()}/chatLoaded`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({})
    }).catch(() => {});

    return () => {
      window.removeEventListener("message", handleMessage);
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  useEffect(() => {
    if (!isOpen) return;
    const focusTimer = window.setTimeout(() => {
      inputRef.current?.focus();
    }, 30);
    return () => window.clearTimeout(focusTimer);
  }, [isOpen]);

  // Suggestions only while typing a command — keep typing snappy for long text
  const formattedSuggestions = useMemo(() => {
    const raw = inputValue.trim();
    if (!raw.startsWith("/")) return [];

    const normalizedMessage = raw;
    const removed = new Set(removedSuggestions);

    const matched: Suggestion[] = [];
    for (let i = 0; i < allSuggestions.length; i++) {
      const s = allSuggestions[i];
      if (removed.has(s.name)) continue;

      let ok = false;
      if (s.name.startsWith(normalizedMessage)) {
        ok = true;
      } else {
        const suggestionSplitted = s.name.split(" ");
        const messageSplitted = normalizedMessage.split(" ");
        ok = true;
        for (let j = 0; j < messageSplitted.length; j++) {
          if (j >= suggestionSplitted.length) {
            ok = j < suggestionSplitted.length + (s.params || []).length;
            break;
          }
          if (suggestionSplitted[j] !== messageSplitted[j]) {
            ok = false;
            break;
          }
        }
      }

      if (!ok) continue;

      const disabled = !s.name.startsWith(normalizedMessage);
      const params = s.params || [];
      const formattedParams = params.map((p, index) => {
        const wType = index === params.length - 1 ? "." : "\\S";
        const escapedName = s.name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        const regex = new RegExp(`${escapedName} (?:\\S+ ){${index}}(?:${wType}*)$`, "g");
        return {
          ...p,
          disabled: inputValue.match(regex) == null
        };
      });

      matched.push({ ...s, disabled, params: formattedParams });
      if (matched.length >= 5) break;
    }

    return matched;
  }, [inputValue, allSuggestions, removedSuggestions]);

  const closeChatAndScheduleHide = useCallback(() => {
    isOpenRef.current = false;
    setIsOpen(false);
    resetShowWindowTimer();
  }, [resetShowWindowTimer]);

  const sendSubmit = () => {
    const resourceName = getResourceName();

    if (inputValue.trim() !== "") {
      fetch(`https://${resourceName}/chatResult`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: inputValue })
      }).catch(() => {});

      setHistory((prev) => [inputValue, ...prev]);
      setHistoryIndex(-1);
    } else {
      fetch(`https://${resourceName}/chatResult`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ canceled: true })
      }).catch(() => {});
    }

    setInputValue("");
    closeChatAndScheduleHide();
  };

  const cancelSubmit = () => {
    fetch(`https://${getResourceName()}/chatResult`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ canceled: true })
    }).catch(() => {});

    setInputValue("");
    closeChatAndScheduleHide();
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      sendSubmit();
    } else if (e.key === "Escape") {
      e.preventDefault();
      cancelSubmit();
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      if (history.length > 0 && historyIndex + 1 < history.length) {
        const nextIdx = historyIndex + 1;
        setHistoryIndex(nextIdx);
        setInputValue(history[nextIdx]);
      }
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      if (historyIndex - 1 >= 0) {
        const nextIdx = historyIndex - 1;
        setHistoryIndex(nextIdx);
        setInputValue(history[nextIdx]);
      } else if (historyIndex - 1 === -1) {
        setHistoryIndex(-1);
        setInputValue("");
      }
    }
  };

  const selectSuggestion = (s: Suggestion) => {
    setInputValue(s.name + " ");
    inputRef.current?.focus();
  };

  const onInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
  };

  if (shouldHide) return null;

  const messageNodes = messages.map((msg) => (
    <MessageRow key={msg.id} html={msg.html} />
  ));

  return (
    <>
      {/* Full Chat Console (when typing) */}
      <div
        className={`pandora grim-chat-console fixed top-[4%] left-[20px] w-[360px] z-40 rounded-xl border-2 border-[#ff3a3a] shadow-2xl p-3 flex flex-col font-sans backdrop-blur-xl transition-all duration-300 ${isOpen
            ? "opacity-100 translate-x-0 pointer-events-auto scale-100"
            : "opacity-0 -translate-x-6 pointer-events-none scale-95"
          }`}
        style={{
          background: "linear-gradient(180deg, rgba(22, 14, 18, 0.98) 0%, rgba(11, 11, 16, 0.99) 100%)",
          visibility: isOpen ? "visible" : "hidden",
        }}
      >
        {/* Header Bar */}
        <div className="flex items-center justify-between pb-3 border-b border-[#ff3a3a]/40">
          <div className="flex items-center gap-2.5">
            <div className="relative flex items-center justify-center p-1.5 rounded-lg bg-[#ff3a3a]/15 border border-[#ff3a3a]">
              <img src={grimLogo} alt="Grim City" className="w-5 h-5 object-contain" />
            </div>
            <div className="flex flex-col">
              <div className="flex items-center gap-2">
                <span className="font-black tracking-wider text-[13px] text-white">GRIM CHAT</span>
                <span className="flex items-center gap-1 text-[8.5px] font-black uppercase text-[#ff4d4d] bg-[#ff3a3a]/15 border border-[#ff3a3a] px-1.5 py-0.5 rounded-md">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#ff3a3a] animate-pulse" />
                  LIVE HUD
                </span>
              </div>
              <span className="text-[9.5px] text-[#a08890] font-semibold mt-0.5">
                Official Server Comms Console
              </span>
            </div>
          </div>

          <div className="flex items-center gap-1.5 text-[9.5px] font-bold text-[#a08890] bg-[#181216] border border-white/10 px-2 py-1 rounded-md">
            <span>[ENTER ↵]</span> <span className="text-white/30">•</span> <span>[ESC ✕]</span>
          </div>
        </div>

        {/* Messages List Area */}
        <div ref={openListRef} className="h-[230px] overflow-y-auto overflow-x-hidden pr-1 my-2 flex flex-col gap-1.5 no-scrollbar w-full max-w-full">
          {isOpen ? messageNodes : null}
        </div>

        {/* Input Bar */}
        <div className="flex items-center w-full mt-1.5 relative">
          <div className="relative flex-1 flex items-center">
            <span className="absolute left-3 text-[13px] font-extrabold text-[#ff4d4d] pointer-events-none select-none">/</span>
            <input
              ref={inputRef}
              type="text"
              className="w-full bg-[#0d0d12] border border-[#ff3a3a] focus:border-[#ff3a3a] outline-none text-white text-[13px] font-medium rounded-xl pl-7 pr-3.5 py-2.5 placeholder-[#a08890]/70 transition"
              placeholder="Type command or message..."
              value={inputValue}
              onChange={onInputChange}
              onKeyDown={handleKeyDown}
              autoComplete="off"
              spellCheck={false}
            />
          </div>
          <button
            type="button"
            onClick={sendSubmit}
            className="ml-2 shrink-0 px-4 h-[42px] bg-gradient-to-r from-[#ff4d4d] via-[#e61e1e] to-[#b30000] border border-[#ff3a3a] hover:brightness-110 active:scale-95 rounded-xl flex items-center justify-center text-white cursor-pointer transition"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2.5}
              stroke="currentColor"
              className="w-4 h-4 text-white"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
            </svg>
          </button>
        </div>

        {/* Command Suggestions Popup */}
        {isOpen && formattedSuggestions.length > 0 && (
          <div
            className="mt-2 border border-[#ff3a3a]/40 rounded-xl shadow-[0_15px_35px_rgba(0,0,0,0.9)] p-1.5 flex flex-col gap-1 max-h-[160px] overflow-y-auto no-scrollbar backdrop-blur-xl"
            style={{ backgroundColor: "rgba(13, 13, 18, 0.98)" }}
          >
            {formattedSuggestions.map((s) => (
              <button
                key={s.name}
                type="button"
                onClick={() => selectSuggestion(s)}
                className="w-full text-left flex flex-col px-3 py-2 rounded-lg text-[12px] hover:bg-[#ff3a3a]/15 transition group cursor-pointer"
              >
                <div className="flex items-center gap-1.5 font-bold">
                  <span className={s.disabled ? "text-white/40" : "text-[#ff8080] group-hover:text-[#ff4d4d]"}>
                    {s.name}
                  </span>
                  {s.params && s.params.map((p, pIdx) => (
                    <span
                      key={`${s.name}-${p.name}-${pIdx}`}
                      className={`text-[10.5px] font-semibold tracking-wide px-1.5 py-0.5 rounded bg-[#ff3a3a]/10 border border-[#ff3a3a]/20 ${p.disabled ? "text-white/20" : "text-[#ffb3b3]"}`}
                    >
                      [{p.name}]
                    </span>
                  ))}
                </div>
                {s.help && (
                  <span className="text-[10px] text-[#a08890] mt-0.5">
                    {s.help}
                  </span>
                )}
              </button>
            ))}
          </div>
        )}

        {/* Official Footer */}
        <div className="flex items-center justify-between mt-3 pt-2.5 border-t border-[#ff3a3a]/20 text-[10px]">
          <div className="flex items-center gap-1.5">
            <img src={grimLogo} alt="Grim City" className="w-3.5 h-3.5 object-contain" />
            <span className="font-black tracking-[0.2em] text-[#ff4d4d]">
              GRIM CITY ROLEPLAY
            </span>
          </div>
          <span className="tracking-wider text-[#a08890]">
            POWERED BY <strong className="text-[#ff4d4d]">KODEBYKARL.NET</strong>
          </span>
        </div>
      </div>

      {/* Overlay: only mount when closed + visible so new chats aren't stuck off-screen */}
      {!isOpen && showWindow && (
        <div
          className="grim-chat-overlay fixed top-[5%] left-[20px] w-[340px] max-w-[calc(100vw-40px)] z-30 font-sans opacity-100 overflow-x-hidden"
          style={{ transition: "opacity 200ms ease" }}
        >
          <div ref={overlayListRef} className="max-h-[320px] overflow-y-auto overflow-x-hidden pr-1 flex flex-col gap-1.5 no-scrollbar w-full max-w-full">
            {messageNodes}
          </div>
        </div>
      )}
    </>
  );
}
