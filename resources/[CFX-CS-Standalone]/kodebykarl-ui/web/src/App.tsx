import { useState, useEffect, lazy, Suspense } from "react";
import Index from "./routes/index";
import Scoreboard from "./cfx-keydi-scoreboard/Scoreboard";
import IndicatorConfig from "./cfx-keydi-indicator/IndicatorConfig";
import DamageOverlay from "./cfx-keydi-indicator/DamageOverlay";
import Chat from "./cfx-keydi-chat/Chat";
import Me3D from "./cfx-keydi-chat/Me3D";
import ModulesMenu from "./cfx-keydi-modules/ModulesMenu";
import FpsOptimizer, { FpsPreset } from "./cfx-keydi-fps/FpsOptimizer";
import ReportSystem, { OpenReport, ReportCategory } from "./cfx-keydi-report/ReportSystem";
import BankingSystem from "./cfx-keydi-banking/BankingSystem";
import AutofarmHud from "./cfx-keydi-autofarm/AutofarmHud";
import PatchNotes from "./cfx-keydi-patchnotes/PatchNotes";
import MultiJob from "./cfx-keydi-multijob/MultiJob";
import Regions from "./cfx-keydi-regions/Regions";
import RockstarRecording from "./cfx-keydi-rockstar/RockstarRecording";
import VipStatus from "./cfx-keydi-vip/VipStatus";
import DeathScreen, { type DeathScreenData } from "./cfx-keydi-deathscreen/DeathScreen";
import WelcomeBanner from "./welcomebanner/WelcomeBanner";
import WelcomeBannerPanel, { WelcomeBannerPanelData } from "./welcomebanner/WelcomeBannerPanel";
import WelcomeBannerVolume, { WelcomeBannerVolumeData } from "./welcomebanner/WelcomeBannerVolume";
import WelcomeScreen from "./cfx-keydi-welcome/WelcomeScreen";
import Badge, { BadgeData } from "./cfx-keydi-badge/Badge";
import RadioListHud, { RadioPlayer } from "./cfx-keydi-radiolist/RadioListHud";
import RadioListModal from "./cfx-keydi-radiolist/RadioListModal";
import MarketMenu, { MarketData } from "./cfx-keydi-market/MarketMenu";
import ComServHud from "./cfx-keydi-comserv/ComServHud";
import ComServMenu from "./cfx-keydi-comserv/ComServMenu";
import LockMenu from "./cfx-keydi-lockscript/LockMenu";
import InvoiceMenu, { InvoiceData } from "./cfx-keydi-invoice/InvoiceMenu";
import RegistrarMenu, { type RegistrarData } from "./cfx-keydi-university/RegistrarMenu";
import type { IpadPlayerData } from "./cfx-keydi-ipad/Ipad";
import type { UniversityRole } from "./cfx-keydi-ipad/universityTypes";
import PartyHud from "./cfx-keydi-ipad/PartyHud";
import PlaytimeShop, { PlaytimeShopData } from "./cfx-keydi-playtimeshop/PlaytimeShop";
import { Toaster } from "sonner";
import { AlertTriangle } from "lucide-react";
import { isBrowserEnv } from "./lib/nui";
import {
  DEFAULT_INDICATOR_SETTINGS,
  mergeIndicatorSettings,
  type IndicatorSettings,
} from "./cfx-keydi-indicator/types";

const Ipad = lazy(() => import("./cfx-keydi-ipad/Ipad"));
const LoadingScreen = lazy(() => import("./cfx-keydi-loadingscreen/LoadingScreen"));

// Cinematic Purge Siren Audio Synthesizer (City-Wide Alert Horn)
function playPurgeSirenAudio(durationMs = 12000) {
  try {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioContextClass) return;
    const ctx = new AudioContextClass();
    if (ctx.state === "suspended") {
      ctx.resume();
    }

    const now = ctx.currentTime;
    const duration = durationMs / 1000;

    // Master Gain with Fade In/Out
    const masterGain = ctx.createGain();
    masterGain.gain.setValueAtTime(0.001, now);
    masterGain.gain.exponentialRampToValueAtTime(0.38, now + 1.2);
    masterGain.gain.setValueAtTime(0.38, now + duration - 2.0);
    masterGain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

    // Warm Lowpass Filter for distant city echo
    const filter = ctx.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.setValueAtTime(1300, now);

    // Reverb / Echo delay unit
    const delay = ctx.createDelay();
    delay.delayTime.setValueAtTime(0.42, now);
    const delayGain = ctx.createGain();
    delayGain.gain.setValueAtTime(0.38, now);

    // Deep Sub Bass Horn (Purge Fog Horn Drone)
    const droneOsc = ctx.createOscillator();
    droneOsc.type = "sawtooth";
    droneOsc.frequency.setValueAtTime(58, now);
    const droneGain = ctx.createGain();
    droneGain.gain.setValueAtTime(0.28, now);
    droneOsc.connect(droneGain);
    droneGain.connect(filter);

    // Siren Wailer 1 (Iconic Purge Pitch Sweep)
    const sirenOsc1 = ctx.createOscillator();
    sirenOsc1.type = "sawtooth";

    // Siren Wailer 2 (Chorus detune for thick ominous sound)
    const sirenOsc2 = ctx.createOscillator();
    sirenOsc2.type = "triangle";

    const cycleTime = 3.6;
    const totalCycles = Math.ceil(duration / cycleTime);
    for (let i = 0; i < totalCycles; i++) {
      const t = now + i * cycleTime;
      sirenOsc1.frequency.setValueAtTime(240, t);
      sirenOsc1.frequency.exponentialRampToValueAtTime(490, t + cycleTime * 0.45);
      sirenOsc1.frequency.exponentialRampToValueAtTime(240, t + cycleTime);

      sirenOsc2.frequency.setValueAtTime(242, t);
      sirenOsc2.frequency.exponentialRampToValueAtTime(494, t + cycleTime * 0.45);
      sirenOsc2.frequency.exponentialRampToValueAtTime(242, t + cycleTime);
    }

    const sirenGain = ctx.createGain();
    sirenGain.gain.setValueAtTime(0.32, now);
    sirenOsc1.connect(sirenGain);
    sirenOsc2.connect(sirenGain);
    sirenGain.connect(filter);

    // Output routing
    filter.connect(masterGain);
    filter.connect(delay);
    delay.connect(delayGain);
    delayGain.connect(masterGain);
    delayGain.connect(delay); // feedback loop
    masterGain.connect(ctx.destination);

    droneOsc.start(now);
    sirenOsc1.start(now);
    sirenOsc2.start(now);

    droneOsc.stop(now + duration);
    sirenOsc1.stop(now + duration);
    sirenOsc2.stop(now + duration);

    setTimeout(() => {
      try {
        ctx.close();
      } catch {}
    }, durationMs + 1000);
  } catch (e) {
    console.error("Purge siren audio error:", e);
  }
}

export default function App() {
  const [identityVisible, setIdentityVisible] = useState(false);
  const [badgeVisible, setBadgeVisible] = useState(false);
  const [badgeData, setBadgeData] = useState<BadgeData | null>(null);
  
  const [radioChannel, setRadioChannel] = useState<string | null>("100.0 MHz");
  const [radioPlayers, setRadioPlayers] = useState<RadioPlayer[]>([]);
  const [radioHudVisible, setRadioHudVisible] = useState(false);
  const [radioModalVisible, setRadioModalVisible] = useState(false);
  const [radioEditMode, setRadioEditMode] = useState(false);
  const [partyEditMode, setPartyEditMode] = useState(false);
  const [scoreboardVisible, setScoreboardVisible] = useState(false);
  const [scoreboardData, setScoreboardData] = useState<any>({});
  
  const [indicatorConfigVisible, setIndicatorConfigVisible] = useState(false);
  const [indicatorSettings, setIndicatorSettings] = useState<IndicatorSettings>(DEFAULT_INDICATOR_SETTINGS);
  
  const [modulesVisible, setModulesVisible] = useState(false);
  const [modulesUpdates, setModulesUpdates] = useState<any[]>([]);
  const [rockstarRecording, setRockstarRecording] = useState(false);
  const [patchNotesVisible, setPatchNotesVisible] = useState(false);
  const [multiJobVisible, setMultiJobVisible] = useState(false);
  const [regionsVisible, setRegionsVisible] = useState(false);
  const [rockstarVisible, setRockstarVisible] = useState(false);
  const [vipVisible, setVipVisible] = useState(false);
  const [deathScreenVisible, setDeathScreenVisible] = useState(false);
  const [deathScreenData, setDeathScreenData] = useState<DeathScreenData | null>(null);
  const [fpsVisible, setFpsVisible] = useState(false);
  const [fpsPreset, setFpsPreset] = useState("default");
  const [fpsPresets, setFpsPresets] = useState<Record<string, FpsPreset>>({});
  const [reportVisible, setReportVisible] = useState(false);
  const [openReport, setOpenReport] = useState<OpenReport | null>(null);
  const [reportCategories, setReportCategories] = useState<ReportCategory[]>([]);
  const [reportMaxDescription, setReportMaxDescription] = useState(500);
  const [reportMaxTitle, setReportMaxTitle] = useState(80);
  const [reportIsAdmin, setReportIsAdmin] = useState(false);
  const [reportAllReports, setReportAllReports] = useState<any[]>([]);
  const [reportAdminDuty, setReportAdminDuty] = useState(false);

  const [bankingVisible, setBankingVisible] = useState(false);
  const [bankingData, setBankingData] = useState<any>(null);
  const [bankingIsATM, setBankingIsATM] = useState(false);

  const [welcomeVisible, setWelcomeVisible] = useState(false);
  const [welcomeData, setWelcomeData] = useState<any>({});
  const [loadingScreenVisible, setLoadingScreenVisible] = useState(false);

  const [marketVisible, setMarketVisible] = useState(false);
  const [marketData, setMarketData] = useState<MarketData | null>(null);

  const [comServMenuVisible, setComServMenuVisible] = useState(false);
  const [comServMenuData, setComServMenuData] = useState<any>(null);

  const [lockMenuVisible, setLockMenuVisible] = useState(false);
  const [lockMenuData, setLockMenuData] = useState<any>(null);
  const [welcomeBannerPanelVisible, setWelcomeBannerPanelVisible] = useState(false);
  const [welcomeBannerPanelData, setWelcomeBannerPanelData] = useState<WelcomeBannerPanelData | null>(null);
  const [welcomeBannerVolumeVisible, setWelcomeBannerVolumeVisible] = useState(false);
  const [welcomeBannerVolumeData, setWelcomeBannerVolumeData] = useState<WelcomeBannerVolumeData | null>(null);

  const [invoiceVisible, setInvoiceVisible] = useState(false);
  const [invoiceData, setInvoiceData] = useState<InvoiceData | null>(null);
  const [registrarVisible, setRegistrarVisible] = useState(false);
  const [registrarData, setRegistrarData] = useState<RegistrarData | null>(null);

  const [ipadVisible, setIpadVisible] = useState(false);
  const [ipadData, setIpadData] = useState<IpadPlayerData | null>(null);
  const [playtimeVisible, setPlaytimeVisible] = useState(false);
  const [playtimeData, setPlaytimeData] = useState<PlaytimeShopData | null>(null);

  const [announcementVisible, setAnnouncementVisible] = useState(false);
  const [announcementMessage, setAnnouncementMessage] = useState("");
  const [announcementSender, setAnnouncementSender] = useState("");

  useEffect(() => {
    if (announcementVisible) {
      const timer = setTimeout(() => {
        setAnnouncementVisible(false);
      }, 8000);
      return () => clearTimeout(timer);
    }
  }, [announcementVisible]);

  useEffect(() => {
    if (isBrowserEnv()) return;
    let cancelled = false;
    let interval = 0;
    const postReady = () => {
      if (cancelled) return;
      const resourceName = (window as any).GetParentResourceName
        ? (window as any).GetParentResourceName()
        : "kodebykarl-ui";
      fetch(`https://${resourceName}/cfx-keydi-welcome:nuiReady`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({}),
      })
        .then(() => {
          if (!cancelled) window.clearInterval(interval);
        })
        .catch(() => {
          if (!cancelled) window.setTimeout(postReady, 400);
        });
    };
    postReady();
    interval = window.setInterval(postReady, 2000);
    return () => {
      cancelled = true;
      window.clearInterval(interval);
    };
  }, []);

  const postWelcomeShown = () => {
    if (isBrowserEnv()) return;
    const resourceName = (window as any).GetParentResourceName
      ? (window as any).GetParentResourceName()
      : "kodebykarl-ui";
    fetch(`https://${resourceName}/cfx-keydi-welcome:shown`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({}),
    }).catch(() => {});
  };

  useEffect(() => {
    if (!welcomeVisible) return;
    postWelcomeShown();
  }, [welcomeVisible]);

  useEffect(() => {
    // Determine if we are running in the browser dev environment
    const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
    if (isBrowser) {
      setIdentityVisible(false);
      setScoreboardVisible(false); 
      setIndicatorConfigVisible(false); 
      setModulesVisible(false);
      setFpsVisible(false);
      setWelcomeVisible(false);
      setBadgeVisible(false);
      setRadioHudVisible(false);
      setIpadVisible(true);
      // University: ?preview=university|student|teacher|dean|director|registrar
      // Playtime shop: ?preview=shop | Autofarm: ?preview=autofarm | Modules: ?preview=modules | Death: ?preview=deathscreen
      // Scoreboard: ?preview=scoreboard | VIP: ?preview=vip
      // Loading screen: ?preview=loadingscreen
      const preview = new URLSearchParams(window.location.search).get("preview") || "citizen";
      if (preview === "identity") {
        setIpadVisible(false);
        setIdentityVisible(true);
      }
      if (preview === "loadingscreen" || preview === "loading") {
        setIpadVisible(false);
        setLoadingScreenVisible(true);
      }
      if (preview === "registrar") {
        setIpadVisible(false);
        setRegistrarVisible(true);
        setRegistrarData({
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
        });
      }
      const isOwner = preview === "owner";
      const isBoss = preview === "boss" || isOwner;
      const isPolice = preview === "police" || isBoss;
      const universityRole =
        preview === "director" || preview === "university"
          ? "director"
          : preview === "dean"
            ? "dean"
            : preview === "teacher"
              ? "teacher"
              : preview === "student"
                ? "student"
                : "visitor";
      if (preview !== "registrar") setIpadData({
        firstName: "Karl",
        lastName: "Dev",
        cash: 2450,
        bank: 128400,
        job:
          universityRole === "visitor"
            ? isPolice
              ? "Police"
              : preview === "business"
                ? "UwU Cafe"
                : "Unemployed"
            : universityRole === "director"
              ? "University Director"
              : universityRole === "dean"
                ? "Dean"
                : universityRole === "teacher"
                  ? "Professor"
                  : "Student",
        gang: preview === "org" || preview === "organization" ? "Alaskador" : "None",
        canEditEconomy: isOwner,
        canPoliceBoss: isBoss || isOwner,
        canSheriffBoss: isOwner || preview === "sheriff",
        canAmbulanceBoss: isOwner || preview === "ems" || preview === "ambulance",
        canPambulanceBoss: isOwner || preview === "pambulance" || preview === "paletoems",
        canSambulanceBoss: isOwner || preview === "sambulance" || preview === "sandyems",
        canDojBoss: isOwner || preview === "doj",
        canPoliceMdt: isPolice || isOwner || preview === "doj",
        canSheriffMdt: isOwner || preview === "sheriff",
        canBusinessBoss: preview === "business" || isOwner,
        canOrgBoss: preview === "org" || preview === "organization" || isOwner,
        universityRole: universityRole as UniversityRole,
      });
      if (preview === "scoreboard") {
        setIpadVisible(false);
        setScoreboardVisible(true);
        setScoreboardData({
          toggleKey: "F10",
          serverName: "Grim City",
          enablePriorityStatus: true,
          playerName: "Karl Dev",
          playerId: 12,
          ping: 28,
          avatarUrl: "https://cdn.discordapp.com/embed/avatars/1.png",
          stats: {
            playTime: "12h",
            rank: "—",
            kills: 0,
            kd: "0.00",
            health: 100,
            armor: 0,
          },
          population: { current: 42, max: 128 },
          jobs: [
            { name: "LS EMS", online: 2 },
            { name: "LS Police", online: 5 },
          ],
          priorities: [
            { name: "LS Police", status: "Safe" },
            { name: "Paleto Sheriff", status: "Hold" },
          ],
          worldEvents: [
            { name: "Airdrop", location: "Sandy Shores", status: "INACTIVE", timeLeft: "45:00" },
            { name: "Traphouse", location: "Unknown", status: "INACTIVE" },
            { name: "Turf Wars", location: "Unknown", status: "INACTIVE" },
          ],
          robberies: [],
        });
      }
      if (preview === "shop") {
        setIpadVisible(false);
        setPlaytimeVisible(true);
        setPlaytimeData(null);
      }
      if (preview === "weedfarm" || preview === "weed") {
        setIpadVisible(false);
      }
      if (preview === "autofarm") {
        setIpadVisible(false);
      }
      if (preview === "deathscreen") {
        setIpadVisible(false);
        setDeathScreenVisible(true);
        setDeathScreenData({
          brand: "GRIM CITY",
          brandUrl: "grim.city",
          subtitle: "DEATH RECAP",
          killer: {
            name: "KEYDI",
            id: 1,
            ping: 13,
            playTime: "—",
            rank: "Suicide",
            kills: 0,
            kd: "0.00",
            health: 100,
            armor: 0,
            achievements: [],
          },
          combat: {
            weapon: "Pistol",
            streak: 0,
            distance: 12,
            damageDealt: 35,
            damageReceived: 120,
            damageOutPercent: 23,
            damageInPercent: 77,
            hitZones: { head: 1, neck: 0, torso: 2, arm: 1, leg: 0 },
            recentKills: [],
          },
        });
      }
      if (preview === "vip") {
        setIpadVisible(false);
        setVipVisible(true);
      }
      if (preview === "me3d" || preview === "me") {
        setIpadVisible(false);
      }
      if (preview === "modules") {
        setIpadVisible(false);
        setModulesVisible(true);
        setModulesUpdates([
          {
            version: "2.4.0",
            date: "2026-09-05",
            title: "Autofarm + iPad Apps",
            tag: "UPDATE",
            notes: [
              "New Grim City autofarm HUD with bag-full ETA",
              "iPad Economy / PD Boss / Party preview apps",
              "Playtime shop Grim Coins rewards",
            ],
          },
        ]);
        setReportCategories([
          { id: "bug", label: "Bug Report" },
          { id: "player", label: "Player Report" },
          { id: "other", label: "Other" },
        ]);
        setBankingData({
          playerName: "Karl Dev",
          accountNumber: "GC-882194",
          bankBalance: 128400,
          cashBalance: 2450,
          transactions: [
            {
              id: "1",
              type: "deposit",
              label: "Salary",
              amount: 2500,
              date: "Today",
            },
          ],
        });
      }
    }

    const handleMessage = (event: MessageEvent) => {
      const data = event.data;
      if (!data || typeof data !== "object") return;

      // Identity UI Handlers
      if (data.action === "show" || data.action === "showIdentity") {
        setIdentityVisible(true);
      } else if (data.action === "hide" || data.action === "hideIdentity") {
        setIdentityVisible(false);
      }

      // Scoreboard UI Handlers
      if (data.action === "scoreboard:show") {
        if (data.data) setScoreboardData(data.data);
        setScoreboardVisible(true);
      } else if (data.action === "scoreboard:hide") {
        setScoreboardVisible(false);
      } else if (data.action === "scoreboard:update") {
        if (data.data) setScoreboardData(data.data);
      }

      // Community Service staff panel
      if (data.action === "cfx-keydi-comserv:panel:show") {
        if (data.data) setComServMenuData(data.data);
        setComServMenuVisible(true);
      } else if (data.action === "cfx-keydi-comserv:panel:hide") {
        setComServMenuVisible(false);
      } else if (data.action === "cfx-keydi-comserv:panel:update") {
        if (data.data) {
          setComServMenuData((prev: any) => ({ ...(prev || {}), ...data.data }));
        }
      }

      // VIP appearance lock panel
      if (data.action === "cfx-keydi-lockscript:panel:show") {
        if (data.data) setLockMenuData(data.data);
        setLockMenuVisible(true);
      } else if (data.action === "cfx-keydi-lockscript:panel:hide") {
        setLockMenuVisible(false);
      } else if (data.action === "cfx-keydi-lockscript:panel:update") {
        if (data.data) {
          setLockMenuData((prev: any) => ({ ...(prev || {}), ...data.data }));
        }
      }

      if (data.action === "cfx-keydi-welcomebanner:panel:show") {
        if (data.data) setWelcomeBannerPanelData(data.data);
        setWelcomeBannerPanelVisible(true);
      } else if (data.action === "cfx-keydi-welcomebanner:panel:hide") {
        setWelcomeBannerPanelVisible(false);
      } else if (data.action === "cfx-keydi-welcomebanner:panel:update") {
        if (data.data) {
          setWelcomeBannerPanelData((prev) => ({ ...(prev || {}), ...data.data }));
        }
      }

      if (data.action === "cfx-keydi-welcomebanner:volume:show") {
        if (data.data) setWelcomeBannerVolumeData(data.data);
        setWelcomeBannerVolumeVisible(true);
      } else if (data.action === "cfx-keydi-welcomebanner:volume:hide") {
        setWelcomeBannerVolumeVisible(false);
      }

      // Indicator UI Handlers
      if (data.action === "indicator:showConfig") {
        if (data.settings) setIndicatorSettings(mergeIndicatorSettings(data.settings));
        setIndicatorConfigVisible(true);
      } else if (data.action === "indicator:hideConfig") {
        setIndicatorConfigVisible(false);
      } else if (data.action === "indicator:syncSettings") {
        if (data.settings) setIndicatorSettings(mergeIndicatorSettings(data.settings));
      }

      // Modules Menu UI Handlers
      if (data.action === "cfx-keydi-modules:show") {
        if (data.data?.updates) setModulesUpdates(data.data.updates);
        setModulesVisible(true);
      } else if (data.action === "cfx-keydi-modules:hide") {
        // ForceCloseModules only sends hide — also tear down submodule pages
        // (Regions / MultiJob / etc.) or the UI stays stuck with stale Active Server.
        setModulesVisible(false);
        setPatchNotesVisible(false);
        setMultiJobVisible(false);
        setRegionsVisible(false);
        setRockstarVisible(false);
        setVipVisible(false);
      } else if (data.action === "cfx-keydi-vip:show") {
        setVipVisible(true);
      } else if (data.action === "cfx-keydi-vip:hide") {
        setVipVisible(false);
      } else if (data.action === "cfx-keydi-modules:recording") {
        setRockstarRecording(!!data.recording);
      } else if (data.action === "cfx-keydi-serverlocations:applied") {
        // Region switch finished while a module page might still be open — refresh Regions.
        window.dispatchEvent(
          new CustomEvent("grim:regionApplied", { detail: data.location || data.data || null })
        );
      } else if (data.action === "cfx-keydi-serverlocations:switchFailed") {
        window.dispatchEvent(
          new CustomEvent("grim:regionSwitchFailed", {
            detail: { message: data.message || "Switch failed" },
          })
        );
      }

      // Death Screen
      if (data.action === "deathscreen:show") {
        if (data.data) setDeathScreenData(data.data as DeathScreenData);
        setDeathScreenVisible(true);
      } else if (data.action === "deathscreen:hide") {
        setDeathScreenVisible(false);
        setDeathScreenData(null);
      }

      // FPS Optimizer UI Handlers
      if (data.action === "cfx-keydi-fps:show") {
        if (data.preset) setFpsPreset(data.preset);
        if (data.presets) setFpsPresets(data.presets);
        setFpsVisible(true);
      } else if (data.action === "cfx-keydi-fps:hide") {
        setFpsVisible(false);
      }

      // Report System UI Handlers
      if (data.action === "cfx-keydi-report:show") {
        setOpenReport(data.openReport ?? null);
        if (data.categories) setReportCategories(data.categories);
        if (data.maxDescription) setReportMaxDescription(data.maxDescription);
        if (data.maxTitle) setReportMaxTitle(data.maxTitle);
        setReportIsAdmin(data.isAdmin ?? false);
        setReportAllReports(data.allReports ?? []);
        setReportAdminDuty(data.adminDutyStatus ?? false);
        setReportVisible(true);
      } else if (data.action === "cfx-keydi-report:hide") {
        setReportVisible(false);
      } else if (data.action === "cfx-keydi-report:update") {
        if (data.openReport) setOpenReport(data.openReport);
      } else if (data.action === "cfx-keydi-report:updateReport") {
        if (data.openReport) setOpenReport(data.openReport);
      } else if (data.action === "cfx-keydi-report:reportClosed") {
        setOpenReport(null);
      }

      // Banking UI Handlers
      if (data.action === "cfx-keydi-banking:show") {
        if (data.data) setBankingData(data.data);
        setBankingIsATM(!!data.isATM);
        setBankingVisible(true);
      } else if (data.action === "cfx-keydi-banking:hide") {
        setBankingVisible(false);
      } else if (data.action === "cfx-keydi-banking:update") {
        if (data.data) setBankingData(data.data);
      }

      // Welcome UI Handlers
      if (data.action === "cfx-keydi-welcome:show") {
        if (data.data) setWelcomeData(data.data);
        setWelcomeVisible(true);
        postWelcomeShown();
      } else if (data.action === "cfx-keydi-welcome:ping") {
        const resourceName = (window as any).GetParentResourceName
          ? (window as any).GetParentResourceName()
          : "kodebykarl-ui";
        fetch(`https://${resourceName}/cfx-keydi-welcome:nuiReady`, {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify({}),
        }).catch(() => {});
      } else if (data.action === "cfx-keydi-welcome:hide") {
        setWelcomeVisible(false);
      } else if (data.action === "cfx-keydi-admin:announcementReceived") {
        setAnnouncementMessage(data.message || "");
        setAnnouncementSender(data.sender || "Staff");
        setAnnouncementVisible(true);
      }

      // Sell Market UI Handlers
      if (data.action === "cfx-keydi-market:show") {
        if (data.data) setMarketData(data.data);
        setMarketVisible(true);
      } else if (data.action === "cfx-keydi-market:hide") {
        setMarketVisible(false);
      } else if (data.action === "cfx-keydi-market:update") {
        if (data.data) setMarketData(data.data);
      }

      // Billing / Invoice UI Handlers
      if (data.action === "cfx-keydi-invoice:show") {
        if (data.data) setInvoiceData(data.data);
        setInvoiceVisible(true);
      } else if (data.action === "cfx-keydi-invoice:hide") {
        setInvoiceVisible(false);
      } else if (data.action === "cfx-keydi-invoice:update") {
        if (data.data) setInvoiceData(data.data);
      }

      // ULS Registrar
      if (data.action === "cfx-keydi-university:registrar:show") {
        if (data.data) setRegistrarData(data.data);
        setRegistrarVisible(true);
      } else if (data.action === "cfx-keydi-university:registrar:hide") {
        setRegistrarVisible(false);
      }

      // Apple iPad System
      if (data.action === "cfx-keydi-ipad:open") {
        if (data.data) setIpadData(data.data);
        setIpadVisible(true);
      } else if (data.action === "cfx-keydi-ipad:session") {
        if (data.data) {
          setIpadData((prev) => ({ ...(prev || {}), ...data.data }));
        }
      } else if (data.action === "cfx-keydi-ipad:close") {
        setIpadVisible(false);
      }

      // Playtime Shop
      if (data.action === "cfx-keydi-playtimeshop:open") {
        if (data.data) setPlaytimeData(data.data);
        setPlaytimeVisible(true);
      } else if (data.action === "cfx-keydi-playtimeshop:update") {
        if (data.data) {
          setPlaytimeData((prev) => ({ ...(prev || {}), ...data.data }));
        }
      } else if (data.action === "cfx-keydi-playtimeshop:close") {
        setPlaytimeVisible(false);
      }

      // Police & Sheriff Badge UI Handlers
      if (data.action === "cfx-keydi-badge:show" || data.action === "showBadge") {
        if (data.data) setBadgeData(data.data);
        setBadgeVisible(true);
      } else if (data.action === "cfx-keydi-badge:hide" || data.action === "hideBadge") {
        setBadgeVisible(false);
      }

      // Radio List UI Handlers
      if (data.action === "cfx-keydi-radiolist:update" || data.type === "RadioUpdate") {
        const payload = data.data || data;
        if (payload.channel !== undefined) setRadioChannel(payload.channel);
        if (payload.players !== undefined) setRadioPlayers(payload.players);
        if (payload.hudVisible !== undefined) setRadioHudVisible(payload.hudVisible);
        if (payload.modalVisible !== undefined) setRadioModalVisible(payload.modalVisible);
      } else if (data.action === "cfx-keydi-radiolist:startDrag") {
        setRadioEditMode(true);
      } else if (data.action === "cfx-keydi-ipad:party:startDrag") {
        setPartyEditMode(true);
      }
    };

    const handleKeyDown = (event: KeyboardEvent) => {
      const activeKey = scoreboardData.toggleKey || "F10";
      const isPressingToggle = event.key.toLowerCase() === activeKey.toLowerCase();
      const isPressingEscape = event.key === "Escape";

      if (isPressingToggle || isPressingEscape) {
        const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
        if (isBrowser) {
          setScoreboardVisible(false);
          setIndicatorConfigVisible(false);
          setModulesVisible(false);
          setFpsVisible(false);
          setReportVisible(false);
          setBankingVisible(false);
          setWelcomeVisible(false);
          return;
        }

        const resourceName = (window as any).GetParentResourceName 
          ? (window as any).GetParentResourceName() 
          : "kodebykarl-ui";

        if (scoreboardVisible && (isPressingToggle || isPressingEscape)) {
          fetch(`https://${resourceName}/closeScoreboard`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
        }

        if (indicatorConfigVisible && isPressingEscape) {
          fetch(`https://${resourceName}/indicator:closeConfig`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
        }

        if (modulesVisible && isPressingEscape) {
          fetch(`https://${resourceName}/cfx-keydi-modules:closeMenu`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
        }

        if (fpsVisible && isPressingEscape) {
          fetch(`https://${resourceName}/cfx-keydi-fps:close`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
        }

        if (reportVisible && isPressingEscape) {
          fetch(`https://${resourceName}/cfx-keydi-report:close`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
        }

        if (bankingVisible && isPressingEscape) {
          fetch(`https://${resourceName}/cfx-keydi-banking:close`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
        }

        if (welcomeVisible && isPressingEscape) {
          fetch(`https://${resourceName}/cfx-keydi-welcome:close`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
        }

        if (invoiceVisible && isPressingEscape) {
          fetch(`https://${resourceName}/cfx-keydi-invoice:close`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
        }

        if (vipVisible && isPressingEscape) {
          fetch(`https://${resourceName}/cfx-keydi-vip:close`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify({})
          }).catch(() => {});
          setVipVisible(false);
        }
      }
    };

    window.addEventListener("message", handleMessage);
    window.addEventListener("keydown", handleKeyDown);

    return () => {
      window.removeEventListener("message", handleMessage);
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [scoreboardData, scoreboardVisible, indicatorConfigVisible, modulesVisible, fpsVisible, reportVisible, bankingVisible, welcomeVisible, comServMenuVisible, lockMenuVisible, invoiceVisible, vipVisible]);

  const isBrowserPreview =
    typeof window !== "undefined" &&
    !(window as any).invokeNative &&
    !navigator.userAgent.includes("FiveM");
  const isModulesPreview =
    isBrowserPreview &&
    new URLSearchParams(window.location.search).get("preview") === "modules";

  const returnToModulesPreview = () => {
    if (!isModulesPreview) return;
    setIndicatorConfigVisible(false);
    setFpsVisible(false);
    setReportVisible(false);
    setBankingVisible(false);
    setPatchNotesVisible(false);
    setMultiJobVisible(false);
    setRegionsVisible(false);
    setRockstarVisible(false);
    setVipVisible(false);
    setDeathScreenVisible(false);
    setModulesVisible(true);
  };

  const openModulePage = (open: () => void) => {
    setModulesVisible(false);
    open();
  };

  const closeModulePage = (close: () => void) => {
    close();
    if (isBrowserPreview) {
      returnToModulesPreview();
      return;
    }
    setModulesVisible(true);
  };

  return (
    <>
      {loadingScreenVisible && (
        <Suspense fallback={null}>
          <LoadingScreen
            onClose={() => {
              if (isBrowserPreview) setLoadingScreenVisible(false);
            }}
          />
        </Suspense>
      )}
      {identityVisible && <Index />}
      {scoreboardVisible && <Scoreboard data={scoreboardData} />}
      {comServMenuVisible && (
        <ComServMenu
          data={comServMenuData}
          onClose={() => {
            const resourceName = (window as any).GetParentResourceName
              ? (window as any).GetParentResourceName()
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-comserv:close`, {
              method: "POST",
              headers: { "Content-Type": "application/json; charset=UTF-8" },
              body: JSON.stringify({}),
            }).catch(() => {});
          }}
        />
      )}
      {lockMenuVisible && (
        <LockMenu
          data={lockMenuData}
          onClose={() => {
            const resourceName = (window as any).GetParentResourceName
              ? (window as any).GetParentResourceName()
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-lockscript:close`, {
              method: "POST",
              headers: { "Content-Type": "application/json; charset=UTF-8" },
              body: JSON.stringify({}),
            }).catch(() => {});
          }}
        />
      )}
      {welcomeBannerPanelVisible && (
        <WelcomeBannerPanel
          data={welcomeBannerPanelData}
          onClose={() => {
            const resourceName = (window as any).GetParentResourceName
              ? (window as any).GetParentResourceName()
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-welcomebanner:close`, {
              method: "POST",
              headers: { "Content-Type": "application/json; charset=UTF-8" },
              body: JSON.stringify({}),
            }).catch(() => {});
            setWelcomeBannerPanelVisible(false);
          }}
        />
      )}
      {welcomeBannerVolumeVisible && (
        <WelcomeBannerVolume
          data={welcomeBannerVolumeData}
          onClose={() => {
            const resourceName = (window as any).GetParentResourceName
              ? (window as any).GetParentResourceName()
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-welcomebanner:volume:close`, {
              method: "POST",
              headers: { "Content-Type": "application/json; charset=UTF-8" },
              body: JSON.stringify({}),
            }).catch(() => {});
            setWelcomeBannerVolumeVisible(false);
          }}
        />
      )}
      {indicatorConfigVisible && (
        <IndicatorConfig 
          settings={indicatorSettings}
          onChange={setIndicatorSettings}
          onClose={() => {
            if (isBrowserPreview) {
              setIndicatorConfigVisible(false);
              returnToModulesPreview();
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/indicator:closeConfig`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
        />
      )}
      
      {rockstarRecording && (
        <div className="pointer-events-none fixed top-5 left-1/2 z-[90] -translate-x-1/2">
          <div className="flex items-center gap-2 rounded-full border border-red-500/50 bg-black/70 px-3 py-1.5 shadow-[0_0_16px_rgba(239,68,68,0.35)]">
            <span className="h-2.5 w-2.5 animate-pulse rounded-full bg-red-500" />
            <span className="text-[11px] font-black tracking-[0.22em] text-red-400">REC</span>
          </div>
        </div>
      )}

      {modulesVisible && (
        <ModulesMenu
          onClose={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              setModulesVisible(false);
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-modules:closeMenu`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
          onOpenDamageIndicator={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              openModulePage(() => setIndicatorConfigVisible(true));
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-modules:openDamageIndicator`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
          onOpenFpsOptimizer={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              openModulePage(() => setFpsVisible(true));
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-modules:openFpsOptimizer`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
          onOpenReport={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              openModulePage(() => setReportVisible(true));
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-modules:openReport`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
          onOpenPatchNotes={() => openModulePage(() => setPatchNotesVisible(true))}
          onOpenMultiJob={() => openModulePage(() => setMultiJobVisible(true))}
          onOpenRegions={() => openModulePage(() => setRegionsVisible(true))}
          onOpenRockstar={() => openModulePage(() => setRockstarVisible(true))}
          onOpenVip={() => openModulePage(() => setVipVisible(true))}
        />
      )}

      {patchNotesVisible && (
        <PatchNotes
          initialUpdates={modulesUpdates}
          onClose={() => closeModulePage(() => setPatchNotesVisible(false))}
        />
      )}
      {multiJobVisible && (
        <MultiJob onClose={() => closeModulePage(() => setMultiJobVisible(false))} />
      )}
      {regionsVisible && (
        <Regions onClose={() => closeModulePage(() => setRegionsVisible(false))} />
      )}
      {rockstarVisible && (
        <RockstarRecording
          onRecordingChange={setRockstarRecording}
          onClose={() => closeModulePage(() => setRockstarVisible(false))}
        />
      )}
      {vipVisible && (
        <VipStatus
          onClose={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              setVipVisible(false);
              return;
            }
            const resourceName = (window as any).GetParentResourceName
              ? (window as any).GetParentResourceName()
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-vip:close`, {
              method: "POST",
              headers: { "Content-Type": "application/json; charset=UTF-8" },
              body: JSON.stringify({}),
            }).catch(() => {});
            setVipVisible(false);
          }}
        />
      )}

      {deathScreenVisible && (
        <DeathScreen
          data={deathScreenData}
          onClose={() => {
            setDeathScreenVisible(false);
            setDeathScreenData(null);
          }}
        />
      )}

      {fpsVisible && (
        <FpsOptimizer
          initialPreset={fpsPreset}
          presets={Object.keys(fpsPresets).length > 0 ? fpsPresets : undefined}
          onClose={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              setFpsVisible(false);
              returnToModulesPreview();
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-fps:close`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
        />
      )}

      <ReportSystem
          isOpen={reportVisible}
          categories={reportCategories.length > 0 ? reportCategories : undefined}
          initialReport={openReport}
          maxDescription={reportMaxDescription}
          maxTitle={reportMaxTitle}
          initialIsAdmin={reportIsAdmin}
          initialAllReports={reportAllReports}
          initialAdminDuty={reportAdminDuty}
          onClose={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              setReportVisible(false);
              returnToModulesPreview();
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-report:close`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
        />

      {bankingVisible && (
        <BankingSystem
          initialData={bankingData}
          isATM={bankingIsATM}
          onClose={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              setBankingVisible(false);
              returnToModulesPreview();
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-banking:close`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
        />
      )}

      {welcomeVisible && (
        <WelcomeScreen
          data={welcomeData}
          onClose={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              setWelcomeVisible(false);
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-welcome:close`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
          }}
        />
      )}

      {badgeVisible && (
        <Badge
          visible={badgeVisible}
          data={badgeData ?? undefined}
          onClose={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              setBadgeVisible(false);
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-badge:close`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
            setBadgeVisible(false);
          }}
        />
      )}

      {/* Radio List HUD & Roster Modal */}
      <RadioListHud
        channel={radioChannel}
        players={radioPlayers}
        editMode={radioEditMode}
        hudVisible={radioHudVisible}
        onExitEdit={() => setRadioEditMode(false)}
      />

      {radioModalVisible && (
        <RadioListModal
          visible={radioModalVisible}
          channel={radioChannel}
          players={radioPlayers}
          onClose={() => {
            const isBrowser = !(window as any).invokeNative && !navigator.userAgent.includes("FiveM");
            if (isBrowser) {
              setRadioModalVisible(false);
              return;
            }
            const resourceName = (window as any).GetParentResourceName 
              ? (window as any).GetParentResourceName() 
              : "kodebykarl-ui";
            fetch(`https://${resourceName}/cfx-keydi-radiolist:closeModal`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json; charset=UTF-8"
              },
              body: JSON.stringify({})
            }).catch(() => {});
            setRadioModalVisible(false);
          }}
        />
      )}
      
      {/* Damage indicator overlays (always listening for damage events) */}
      <DamageOverlay currentSettings={indicatorSettings} />

      {/* Chat overlay container */}
      <Chat />

      {/* Grim City 3D /me above players */}
      <Me3D
        previewBubbles={
          isBrowserPreview && new URLSearchParams(window.location.search).get("preview") === "me3d"
            ? [
                { id: "preview", text: "scratches his nose", x: 0.5, y: 0.42, scale: 1, opacity: 1 },
              ]
            : undefined
        }
      />

      {/* Auto Farm HUD (shown while standing in a farm marker) */}
      <AutofarmHud />

      {/* Welcome banner (.wcb) — bottom-right 65x65 overlay */}
      <WelcomeBanner />

      {/* Community Service HUD */}
      <ComServHud />

      {/* 4-man Party HUD (draggable via /movesquad) */}
      <PartyHud editMode={partyEditMode} onExitEdit={() => setPartyEditMode(false)} />

      {/* Grind Sell Market UI */}
      <MarketMenu visible={marketVisible} data={marketData || undefined} onClose={() => setMarketVisible(false)} />

      {/* Billing / Invoice System */}
      <InvoiceMenu visible={invoiceVisible} data={invoiceData || undefined} onClose={() => setInvoiceVisible(false)} />

      {/* ULS Registrar NPC menu */}
      <RegistrarMenu
        visible={registrarVisible}
        data={registrarData}
        onClose={() => setRegistrarVisible(false)}
      />

      {/* Playtime Shop */}
      <PlaytimeShop
        visible={playtimeVisible}
        data={playtimeData}
        onClose={() => setPlaytimeVisible(false)}
      />

      {/* Apple iPad System — mount only while open (0 timers when closed) */}
      {ipadVisible ? (
        <Suspense fallback={null}>
          <Ipad visible={ipadVisible} data={ipadData} onClose={() => setIpadVisible(false)} />
        </Suspense>
      ) : null}

      {announcementVisible && (
        <div 
          className="pandora fixed top-6 left-1/2 -translate-x-1/2 z-[99999] flex items-center gap-3.5 p-3 border text-white rounded-lg w-[360px] animate-tx-announcement pointer-events-none text-left shadow-lg"
          style={{ backgroundColor: "#082744", borderColor: "rgba(255, 122, 181, 0.26)" }}
        >
          <AlertTriangle className="h-5 w-5 text-amber-500 shrink-0" fill="currentColor" />
          <div className="flex-1 min-w-0">
            <h4 className="text-[11px] font-black uppercase text-muted-foreground tracking-wider leading-tight">
              Announcement by {announcementSender}
            </h4>
            <p className="mt-0.5 text-xs font-bold text-white leading-relaxed whitespace-pre-wrap">
              {announcementMessage}
            </p>
          </div>
        </div>
      )}

      <Toaster position="top-right" richColors />
    </>
  );
}
