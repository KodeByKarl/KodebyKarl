/** Shared NUI fetch with browser mocks for module control pages. */

export function isBrowserEnv() {
  const w = window as unknown as {
    GetParentResourceName?: () => string;
    invokeNative?: unknown;
  };
  if (typeof w.GetParentResourceName === "function") return false;
  if (typeof w.invokeNative === "function") return false;
  const ua = navigator.userAgent || "";
  if (ua.includes("FiveM") || ua.includes("CitizenFX")) return false;
  return true;
}

const mockVipTiers = [
  { id: "vip1", label: "VIP 1", characterSlots: 1 },
  { id: "vip2", label: "VIP 2", characterSlots: 2 },
  { id: "vip3", label: "VIP 3", characterSlots: 3 },
  { id: "vip4", label: "VIP 4", characterSlots: 3 },
  { id: "vip5", label: "VIP 5", characterSlots: 3 },
];

function mockBuildVip(
  tier: string,
  amount: number,
  unit: "days" | "months",
  autoRenew: boolean,
  keepExpiresAt: string | null
) {
  const expires = keepExpiresAt ? new Date(keepExpiresAt) : new Date();
  if (!keepExpiresAt) {
    if (unit === "months") expires.setMonth(expires.getMonth() + amount);
    else expires.setDate(expires.getDate() + amount);
  }
  const iso = expires.toISOString();
  const diff = Math.max(0, expires.getTime() - Date.now());
  const daysRemaining = Math.floor(diff / 86400000);
  const hoursRemaining = Math.floor((diff % 86400000) / 3600000);
  const slots = mockVipTiers.find((t) => t.id === tier)?.characterSlots ?? 1;
  const labels: Record<string, string> = {
    vip1: "VIP 1",
    vip2: "VIP 2",
    vip3: "VIP 3",
    vip4: "VIP 4",
    vip5: "VIP 5",
  };
  return {
    active: true,
    tier,
    label: labels[tier] || tier,
    daysRemaining,
    hoursRemaining,
    renewsAt: iso,
    expiresAt: iso,
    autoRenew,
    perks: ["VIP chat tag"],
    characterSlots: slots,
    pedMenu: tier !== "vip1",
    welcomeBanner: true,
  };
}

const mockVipRoster: {
  players: {
    id: number;
    name: string;
    vip: ReturnType<typeof mockBuildVip> | {
      active: false;
      tier: string;
      label: string;
      daysRemaining: number;
      hoursRemaining: number;
      renewsAt: null;
      expiresAt: null;
      autoRenew: boolean;
      perks: string[];
      characterSlots: number;
      pedMenu: boolean;
      welcomeBanner: boolean;
    };
  }[];
} = {
  players: [
    {
      id: 1,
      name: "Karl Dev",
      vip: mockBuildVip("vip3", 12, "days", true, "2026-09-17T18:00:00.000Z"),
    },
    {
      id: 12,
      name: "Alex Rivera",
      vip: {
        active: false,
        tier: "none",
        label: "No VIP",
        daysRemaining: 0,
        hoursRemaining: 0,
        renewsAt: null,
        expiresAt: null,
        autoRenew: false,
        perks: [],
        characterSlots: 1,
        pedMenu: false,
        welcomeBanner: false,
      },
    },
    {
      id: 24,
      name: "Mia Cruz",
      vip: mockBuildVip("vip2", 45, "days", false, null),
    },
  ],
};

const mockBusiness = {
  funds: 245000,
  employees: [
    { identifier: "char1:boss", name: "Karl Dev", grade: 3, gradeLabel: "Boss", online: true, serverId: 1 },
    { identifier: "char1:ace", name: "Ace Walker", grade: 1, gradeLabel: "Cook", online: true, serverId: 12 },
    { identifier: "char1:mia", name: "Mia Storm", grade: 0, gradeLabel: "Trainee", online: false, serverId: null },
  ],
};

export async function fetchNui<T = unknown>(eventName: string, data?: unknown): Promise<T> {
  if (isBrowserEnv()) {
    if (eventName === "cfx-keydi-ipad:business:dashboard") {
      const chart = Array.from({ length: 14 }, (_, i) => {
        const d = new Date();
        d.setDate(d.getDate() - (13 - i));
        return {
          day: d.toLocaleDateString(undefined, { month: "short", day: "numeric" }),
          sales: 4 + ((i * 3) % 9),
          income: 12000 + i * 3500,
        };
      });
      return {
        ok: true,
        job: "uwu",
        label: "UwU Cafe",
        funds: mockBusiness.funds,
        sales: 128,
        income: 890400,
        pending: 6,
        pendingAmount: 24500,
        chart,
        ledger: [
          { id: 1, action: "deposit", amount: 25000, note: "iPad deposit" },
          { id: 2, action: "withdraw", amount: 8000, note: "iPad withdraw" },
        ],
        employees: mockBusiness.employees,
        grades: [
          { grade: 0, name: "trainee", label: "Trainee" },
          { grade: 1, name: "cook", label: "Cook" },
          { grade: 2, name: "manager", label: "Manager" },
          { grade: 3, name: "boss", label: "Boss" },
        ],
        invoices: [
          { id: 41, reference: "K8F2MQ1A", title: "Table 4 combo", total: 12500, status: "paid", senderName: "Karl Dev", receiverName: "Nova Cruz" },
          { id: 40, reference: "P3N9WQ2C", title: "Catering order", total: 48000, status: "unpaid", senderName: "Ace Walker", receiverName: "Rico Vale" },
          { id: 39, reference: "L1D7TX8B", title: "UwU Box x4", total: 8600, status: "paid", senderName: "Karl Dev", receiverName: "Mia Storm" },
        ],
        yourGrade: 3,
      } as T;
    }
    if (eventName === "cfx-keydi-ipad:business:transfer") {
      const body = data as { action?: string; amount?: number };
      const n = Math.floor(Number(body?.amount) || 0);
      if (body?.action === "deposit") mockBusiness.funds += n;
      if (body?.action === "withdraw") mockBusiness.funds = Math.max(0, mockBusiness.funds - n);
      return { ok: true, funds: mockBusiness.funds, ledger: [{ id: Date.now(), action: body?.action, amount: n, note: "iPad" }], sales: 128, income: 890400 } as T;
    }
    if (eventName === "cfx-keydi-ipad:business:nearby") {
      return { ok: true, players: [{ id: 18, name: "Nova Cruz" }, { id: 22, name: "Rico Vale" }] } as T;
    }
    if (eventName === "cfx-keydi-ipad:business:hire") {
      const body = data as { id?: number; grade?: number };
      mockBusiness.employees.push({
        identifier: `char1:${body?.id || Date.now()}`,
        name: body?.id === 18 ? "Nova Cruz" : "Rico Vale",
        grade: Number(body?.grade) || 0,
        gradeLabel: Number(body?.grade) === 1 ? "Cook" : "Trainee",
        online: true,
        serverId: body?.id,
      });
      return { ok: true, employees: mockBusiness.employees } as T;
    }
    if (eventName === "cfx-keydi-ipad:business:setGrade") {
      const body = data as { identifier?: string; grade?: number };
      mockBusiness.employees = mockBusiness.employees.map((e) =>
        e.identifier === body?.identifier
          ? { ...e, grade: Number(body.grade) || 0, gradeLabel: Number(body.grade) === 1 ? "Cook" : Number(body.grade) === 2 ? "Manager" : "Trainee" }
          : e,
      );
      return { ok: true, employees: mockBusiness.employees } as T;
    }
    if (eventName === "cfx-keydi-ipad:business:fire") {
      const body = data as { identifier?: string };
      mockBusiness.employees = mockBusiness.employees.filter((e) => e.identifier !== body?.identifier);
      return { ok: true, employees: mockBusiness.employees } as T;
    }
    if (eventName === "submitIdentity") {
      return { success: true } as T;
    }
    if (eventName === "cfx-keydi-modules:getPatchNotes") {
      return {
        updates: [
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
          {
            version: "2.3.1",
            date: "2026-08-20",
            title: "Regions Control Center",
            tag: "FEATURE",
            notes: ["Farm / School / Turf region switching", "Orange job instance"],
          },
        ],
      } as T;
    }
    if (eventName === "cfx-keydi-modules:getJobs") {
      return {
        jobs: [
          { job: "police", grade: 3, label: "Police", grade_label: "Sergeant", is_active: 1 },
          { job: "ambulance", grade: 1, label: "EMS", grade_label: "EMT", is_active: 0 },
          { job: "mechanic", grade: 0, label: "Mechanic", grade_label: "Trainee", is_active: 0 },
        ],
        activeJob: "police",
        isOnDuty: true,
      } as T;
    }
    if (eventName === "cfx-keydi-modules:getServers") {
      return {
        publicServers: undefined,
        sideJobServers: undefined,
        inSafezone: true,
        isLocked: false,
        lockReason: null,
      } as T;
    }
    if (eventName === "cfx-keydi-modules:getRockstarState") {
      return { recording: false } as T;
    }
    if (eventName === "cfx-keydi-modules:rockstarAction") {
      const button = (data as { button?: string } | undefined)?.button;
      if (button === "record") return { ok: true, recording: true } as T;
      if (button === "save" || button === "delete") return { ok: true, recording: false } as T;
      return { ok: true, recording: false } as T;
    }
    if (eventName === "cfx-keydi-modules:toggleJobDuty") {
      return { ok: true } as T;
    }
    if (eventName === "cfx-keydi-modules:connectServer") {
      return { ok: true } as T;
    }
    if (eventName === "cfx-keydi-vip:getStatus") {
      const self = mockVipRoster.players.find((p) => p.id === 1)?.vip;
      return {
        vip: self,
        canManage: true,
      } as T;
    }
    if (eventName === "cfx-keydi-vip:openPedMenu" || eventName === "cfx-keydi-vip:openWelcomeBanner") {
      return { ok: true } as T;
    }
    if (eventName === "cfx-keydi-vip:staffRoster") {
      return {
        ok: true,
        canManage: true,
        tiers: mockVipTiers,
        players: mockVipRoster.players,
      } as T;
    }
    if (eventName === "cfx-keydi-vip:staffLookup") {
      const targetId = Number((data as { targetId?: number } | undefined)?.targetId);
      const player = mockVipRoster.players.find((p) => p.id === targetId);
      if (!player) return { ok: false, error: "Player offline" } as T;
      return { ok: true, player } as T;
    }
    if (eventName === "cfx-keydi-vip:staffSet") {
      const body = data as {
        targetId?: number;
        tier?: string;
        amount?: number;
        unit?: "days" | "months";
        autoRenew?: boolean;
        keepExpiry?: boolean;
      };
      const idx = mockVipRoster.players.findIndex((p) => p.id === body.targetId);
      if (idx < 0) return { ok: false, error: "Player offline" } as T;
      const current = mockVipRoster.players[idx];
      const nextVip = mockBuildVip(
        body.tier || "vip1",
        Number(body.amount) || 1,
        body.unit === "months" ? "months" : "days",
        !!body.autoRenew,
        body.keepExpiry && current.vip.active ? current.vip.expiresAt : null
      );
      mockVipRoster.players[idx] = { ...current, vip: nextVip };
      return { ok: true, vip: nextVip, players: mockVipRoster.players } as T;
    }
    if (eventName === "cfx-keydi-vip:staffRevoke") {
      const targetId = Number((data as { targetId?: number } | undefined)?.targetId);
      const idx = mockVipRoster.players.findIndex((p) => p.id === targetId);
      if (idx < 0) return { ok: false, error: "Player offline" } as T;
      const empty = {
        active: false,
        tier: "none",
        label: "No VIP",
        daysRemaining: 0,
        hoursRemaining: 0,
        renewsAt: null,
        expiresAt: null,
        autoRenew: false,
        perks: [],
        characterSlots: 1,
        pedMenu: false,
        welcomeBanner: false,
      };
      mockVipRoster.players[idx] = { ...mockVipRoster.players[idx], vip: empty };
      return { ok: true, vip: empty, players: mockVipRoster.players } as T;
    }
    if (eventName === "cfx-keydi-ipad:pvp:status") {
      return {
        ok: true,
        inPvp: false,
        players: 4,
        maxPlayers: 32,
        name: "Deathmatch Arena",
        tags: ["Pistols", "Safe zone", "Public"],
      } as T;
    }
    if (eventName === "cfx-keydi-ipad:pvp:join" || eventName === "cfx-keydi-ipad:pvp:leave") {
      return { ok: true } as T;
    }
    if (eventName.startsWith("cfx-keydi-ipad:party:")) {
      const you = { identifier: "char1:dev", name: "Karl Dev", leader: true, online: true, serverId: 1, you: true };
      const mine = {
        id: 1,
        name: "Night Crew",
        locked: true,
        count: 1,
        max: 4,
        youLeader: true,
        members: [you],
      };
      if (eventName === "cfx-keydi-ipad:party:state") {
        return {
          ok: true,
          max: 4,
          list: [
            { id: 1, name: "Night Crew", leader: "Karl Dev", count: 1, online: 1, max: 4, locked: true, full: false },
            { id: 2, name: "Grove Block", leader: "Ace Walker", count: 3, online: 2, max: 4, locked: false, full: false },
          ],
          mine: null,
        } as T;
      }
      if (eventName === "cfx-keydi-ipad:party:create" || eventName === "cfx-keydi-ipad:party:join") {
        return { ok: true, mine, list: [{ id: 1, name: mine.name, leader: you.name, count: 1, online: 1, max: 4, locked: true, full: false }] } as T;
      }
      return { ok: true, mine: null, list: [] } as T;
    }
    if (eventName === "cfx-keydi-ipad:leaderboard:pvp") {
      return {
        ok: true,
        rows: [
          { rank: 1, name: "Ace Walker", kills: 48, deaths: 12, kd: 4.0 },
          { rank: 2, name: "Nova Cruz", kills: 41, deaths: 15, kd: 2.7 },
          { rank: 3, name: "Rico Vale", kills: 33, deaths: 19, kd: 1.7 },
        ],
        mine: { rank: 3, name: "Rico Vale", kills: 33, deaths: 19, kd: 1.7 },
      } as T;
    }
    if (eventName === "cfx-keydi-ipad:leaderboard:turfwar") {
      return {
        ok: true,
        rows: [
          { rank: 1, name: "Ballas", gang: "ballas", claims: 12, score: "12 claims", subtitle: "Turf wins" },
          { rank: 2, name: "Families", gang: "families", claims: 9, score: "9 claims", subtitle: "Turf wins" },
        ],
      } as T;
    }
    if (
      eventName === "cfx-keydi-ipad:leaderboard:traphouse" ||
      eventName === "cfx-keydi-ipad:leaderboard:party" ||
      eventName === "cfx-keydi-ipad:leaderboard:topplayer"
    ) {
      return {
        ok: true,
        rows: [
          { rank: 1, name: "Smoke King", kills: 22, deaths: 5, kd: 4.4, score: "22 K / 5 D", subtitle: "KDA 4.40" },
          { rank: 2, name: "Night Shift", kills: 17, deaths: 8, kd: 2.13, score: "17 K / 8 D", subtitle: "KDA 2.13" },
        ],
        mine: { rank: 2, name: "Night Shift", kills: 17, deaths: 8, kd: 2.13, score: "17 K / 8 D", subtitle: "KDA 2.13" },
      } as T;
    }
    if (eventName.startsWith("cfx-keydi-ipad:party:")) {
      const mock = (window as unknown as { __partyMock?: {
        list: unknown[];
        mine: unknown;
      } }).__partyMock || { list: [], mine: null };
      (window as unknown as { __partyMock: typeof mock }).__partyMock = mock;
      if (eventName === "cfx-keydi-ipad:party:state") {
        return { ok: true, max: 4, list: mock.list, mine: mock.mine } as T;
      }
      if (eventName === "cfx-keydi-ipad:party:create") {
        const body = (data || {}) as { name?: string; password?: string };
        mock.mine = {
          id: 1,
          name: body.name || "Karl's Team",
          locked: Boolean(body.password),
          count: 1,
          max: 4,
          youLeader: true,
          members: [{ identifier: "you", name: "Karl Dev", leader: true, online: true, you: true, serverId: 1 }],
        };
        mock.list = [{
          id: 1,
          name: body.name || "Karl's Team",
          leader: "Karl Dev",
          count: 1,
          online: 1,
          max: 4,
          locked: Boolean(body.password),
          full: false,
        }];
        window.dispatchEvent(new MessageEvent("message", {
          data: {
            action: "cfx-keydi-ipad:party:hud",
            data: {
              visible: true,
              name: body.name || "Karl's Team",
              count: 1,
              max: 4,
              members: [{ slot: 1, name: "Karl Dev", leader: true, online: true, health: 100, armor: 40 }],
            },
          },
        }));
        return { ok: true, mine: mock.mine, list: mock.list } as T;
      }
      if (eventName === "cfx-keydi-ipad:party:leave" || eventName === "cfx-keydi-ipad:party:disband") {
        mock.mine = null;
        mock.list = [];
        window.dispatchEvent(new MessageEvent("message", {
          data: { action: "cfx-keydi-ipad:party:hud", data: { visible: false, members: [] } },
        }));
        return { ok: true, mine: null, list: [] } as T;
      }
      return { ok: true, mine: mock.mine, list: mock.list } as T;
    }
    if (eventName.startsWith("cfx-keydi-ipad:org:")) {
      const members = [
        { identifier: "char1", name: "Karl Dev", grade: 3, gradeLabel: "Boss", online: true, serverId: 1 },
        { identifier: "char2", name: "Mia Storm", grade: 2, gradeLabel: "Underboss", online: true, serverId: 12 },
        { identifier: "char3", name: "Rico Vale", grade: 0, gradeLabel: "Member", online: false, serverId: null },
      ];
      const grades = [
        { grade: 0, name: "member", label: "Member" },
        { grade: 1, name: "enforcer", label: "Enforcer" },
        { grade: 2, name: "underboss", label: "Underboss" },
        { grade: 3, name: "boss", label: "Boss" },
      ];
      if (eventName === "cfx-keydi-ipad:org:nearby") {
        return { ok: true, players: [{ id: 18, name: "Alex Cruz" }] } as T;
      }
      if (eventName === "cfx-keydi-ipad:org:hireDiscord") {
        return { ok: true, pending: true } as T;
      }
      return {
        ok: true,
        gang: "alaskador",
        label: "Alaskador",
        staff: true,
        gangs: [
          { name: "alaskador", label: "Alaskador" },
          { name: "westside", label: "Westside" },
          { name: "grimgang", label: "GrimGang" },
        ],
        yourGrade: 4,
        members,
        grades,
        memberCount: members.length,
        onlineCount: 2,
      } as T;
    }
    return {} as T;
  }

  const resourceName = (window as unknown as { GetParentResourceName?: () => string })
    .GetParentResourceName
    ? (window as unknown as { GetParentResourceName: () => string }).GetParentResourceName()
    : "kodebykarl-ui";

  const resp = await fetch(`https://${resourceName}/${eventName}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(data ?? {}),
  });
  return (await resp.json()) as T;
}
