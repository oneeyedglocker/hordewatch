// Matches WoW's RAID_CLASS_COLORS, referenced from HordeWatch/UI.lua's
// classColorPrefix(). TBC-era classes only (see DATA_MODEL.md ValidClasses).
export const CLASS_COLORS: Record<string, string> = {
  WARRIOR: "#C79C6E",
  PALADIN: "#F58CBA",
  HUNTER: "#ABD473",
  ROGUE: "#FFF569",
  PRIEST: "#FFFFFF",
  SHAMAN: "#0070DE",
  MAGE: "#69CCF0",
  WARLOCK: "#9482C9",
  DRUID: "#FF7D0A",
};

export function classColor(cls: string | undefined): string {
  return (cls && CLASS_COLORS[cls]) || "var(--text-muted)";
}
