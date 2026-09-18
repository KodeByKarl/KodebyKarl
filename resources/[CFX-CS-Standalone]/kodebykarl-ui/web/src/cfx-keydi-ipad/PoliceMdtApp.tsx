import LeoMdtApp from "./LeoMdtApp";
import type { IpadPlayerData } from "./Ipad";

/** @deprecated use LeoMdtApp — kept as police wrapper */
export default function PoliceMdtApp({ player }: { player?: IpadPlayerData | null }) {
  return <LeoMdtApp player={player} department="police" />;
}
