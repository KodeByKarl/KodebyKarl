export interface VipMembership {
  active: boolean;
  tier: string;
  label: string;
  daysRemaining: number;
  hoursRemaining: number;
  /** Next renewal / billing checkpoint (ISO or display string) */
  renewsAt: string | null;
  /** When VIP will be revoked / ends */
  expiresAt: string | null;
  autoRenew: boolean;
  perks: string[];
  /** Reserved; always 1 character per account */
  characterSlots?: number;
  /** VIP 2+ ped menu access */
  pedMenu?: boolean;
  /** Edit own welcome banner */
  welcomeBanner?: boolean;
  /** VIP All Grindings bonus (+5 / +10 / +15) */
  grindBonus?: number;
}

export const EMPTY_VIP: VipMembership = {
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
  grindBonus: 0,
};

export type VipDurationUnit = "days" | "months";

export interface VipTierOption {
  id: string;
  label: string;
  characterSlots: number;
}

export interface VipPlayerRow {
  id: number;
  name: string;
  vip: VipMembership;
}

export interface DbVipMember {
  identifier: string;
  name: string;
  onlineId?: number | null;
  isOnline: boolean;
  tier: string;
  label: string;
  characterSlots: number;
  expiresAt: string | null;
  startedAt: string | null;
  autoRenew: boolean;
  grantedBy: string;
  daysRemaining: number;
  hoursRemaining: number;
  active: boolean;
}

export const PREVIEW_VIP: VipMembership = {
  active: true,
  tier: "vip3",
  label: "VIP 3",
  daysRemaining: 12,
  hoursRemaining: 8,
  renewsAt: "2026-09-17T18:00:00",
  expiresAt: "2026-09-17T18:00:00",
  autoRenew: true,
  pedMenu: true,
  welcomeBanner: true,
  perks: [
    "Priority queue",
    "Ped Menu (/pedmenu)",
    "Edit own welcome banner",
    "VIP chat tag",
  ],
  characterSlots: 1,
};
