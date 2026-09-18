import DeptBossApp from "./DeptBossApp";
import type { IpadPlayerData } from "./Ipad";

/** @deprecated use DeptBossApp — kept as police wrapper */
export default function PoliceBossApp({ player }: { player?: IpadPlayerData | null }) {
  return <DeptBossApp player={player} department="police" />;
}
