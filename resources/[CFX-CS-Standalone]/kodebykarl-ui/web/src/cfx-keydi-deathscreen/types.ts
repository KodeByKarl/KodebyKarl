export type BodyZone = "head" | "neck" | "torso" | "arms" | "legs";

export interface BodyHits {
  head: number;
  neck: number;
  torso: number;
  arms: number;
  legs: number;
}

export interface KillerProfile {
  name: string;
  id: number;
  ping: number;
  playTime: string;
  rank: string;
  kills: number;
  kd: string;
  health: number;
  armor: number;
  badges?: string[];
}

export interface CombatRecap {
  fatalWeapon: string;
  killStreak: number;
  distance: number;
  damageDealt: number;
  damageReceived: number;
  damageOutPct: number;
  damageInPct: number;
  bodyHits: BodyHits;
  totalHits: number;
  isSuicide?: boolean;
}

export interface RecentElimination {
  name: string;
  id: number;
  at?: number;
}

export interface DeathScreenData {
  killer: KillerProfile;
  combat: CombatRecap;
  recentEliminations: RecentElimination[];
  brand?: string;
  subtitle?: string;
}

export const PREVIEW_DEATH: DeathScreenData = {
  brand: "GRIM CITY",
  subtitle: "DEATH RECAP",
  killer: {
    name: "KEYDI",
    id: 1,
    ping: 0,
    playTime: "—",
    rank: "Suicide",
    kills: 0,
    kd: "0.00",
    health: 100,
    armor: 0,
    badges: [],
  },
  combat: {
    fatalWeapon: "Pistol",
    killStreak: 0,
    distance: 0,
    damageDealt: 0,
    damageReceived: 100,
    damageOutPct: 0,
    damageInPct: 100,
    bodyHits: { head: 1, neck: 0, torso: 2, arms: 1, legs: 0 },
    totalHits: 4,
    isSuicide: true,
  },
  recentEliminations: [],
};
