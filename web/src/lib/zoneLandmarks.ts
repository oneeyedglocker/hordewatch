// Real named sub-locations per zone, in the same zone-relative [0,1] mapX/mapY
// convention already used throughout this app (see Position.lua / LeafletZoneMap.tsx) -
// not fabricated, and not derived from wow.export's corner metadata (the source
// of two earlier real mistakes this project made - see DATA_MODEL.md). Sourced
// from IAmChills/HardcoreAchievements' CheckMapDiscovery.lua (zone exploration
// sub-areas, the same named regions Blizzard's own map API reports) and
// cross-checked against ATTWoWAddon/AllTheThings' independently-maintained quest/
// instance coordinate data and Dugi's Guide's ExplorationTrackingPoints.lua -
// all three agree to within ~1-2% on every landmark spot-checked (e.g. Throne of
// Kil'jaeden: (0.62,0.19) / (0.627,0.195) / (0.61,0.18)). Outland's terrain
// hasn't been reworked since TBC's original release, so these hold for TBC
// Classic despite most of these addons targeting modern retail.
export interface ZoneLandmark {
  name: string;
  x: number;
  y: number;
  /** True for the handful of landmarks that also have a confirmed real
   * worldX/worldY reading (via this session's own /hw pos calibration - see
   * OUTLAND_AFFINE in LeafletContinentMap.tsx) - the only ones it's safe to
   * place on the continent view without guessing. */
  worldAnchor?: { worldX: number; worldY: number };
}

export const ZONE_LANDMARKS: Record<string, ZoneLandmark[]> = {
  "Hellfire Peninsula": [
    { name: "Honor Hold", x: 0.56, y: 0.61, worldAnchor: { worldX: 2657.3, worldY: -700.8 } },
    { name: "Thrallmar", x: 0.56, y: 0.38 },
    { name: "The Dark Portal", x: 0.86, y: 0.5, worldAnchor: { worldX: 1021.2, worldY: -68.5 } },
    { name: "The Legion Front", x: 0.69, y: 0.53 },
    { name: "Zeth'Gor", x: 0.67, y: 0.75 },
    { name: "Expedition Armory", x: 0.55, y: 0.83 },
    { name: "Gor'gaz Outpost", x: 0.45, y: 0.74 },
    { name: "Forge Camp: Megeddon", x: 0.65, y: 0.31 },
    { name: "Throne of Kil'jaeden", x: 0.62, y: 0.19 },
    { name: "Pools of Aggonar", x: 0.41, y: 0.34 },
    { name: "Hellfire Citadel", x: 0.47, y: 0.5 },
    { name: "Mag'har Post", x: 0.32, y: 0.28 },
    { name: "Temple of Telhamat", x: 0.23, y: 0.4 },
    { name: "Fallen Sky Ridge", x: 0.14, y: 0.41 },
    { name: "Ruins of Sha'naar", x: 0.14, y: 0.6 },
    { name: "Falcon Watch", x: 0.28, y: 0.61 },
    { name: "Void Ridge", x: 0.77, y: 0.68 },
    { name: "Den of Haal'esh", x: 0.28, y: 0.8 },
  ],
  Zangarmarsh: [
    { name: "The Spawning Glen", x: 0.15, y: 0.61 },
    { name: "Sporeggar", x: 0.18, y: 0.49 },
    { name: "Marshlight Lake", x: 0.22, y: 0.37 },
    { name: "Ango'rosh Grounds", x: 0.18, y: 0.21 },
    { name: "Ango'rosh Stronghold", x: 0.18, y: 0.07 },
    { name: "Hewn Bog", x: 0.33, y: 0.3 },
    { name: "Quagg Ridge", x: 0.29, y: 0.63 },
    { name: "Feralfen Village", x: 0.47, y: 0.62 },
    { name: "Twin Spire Ruins", x: 0.47, y: 0.5 },
    { name: "Orebor Harborage", x: 0.44, y: 0.27 },
    { name: "Coilfang Reservoir", x: 0.61, y: 0.41 },
    { name: "The Dead Mire", x: 0.82, y: 0.39 },
    { name: "Telredor", x: 0.68, y: 0.5 },
    { name: "The Lagoon", x: 0.58, y: 0.62, worldAnchor: { worldX: 6943.7, worldY: 554.7 } }, // Serpent Lake
    { name: "Cenarion Refuge", x: 0.8, y: 0.64 },
    { name: "Darkcrest Shore", x: 0.7, y: 0.81 },
    { name: "Umbrafen Village", x: 0.83, y: 0.83 },
    { name: "Zabra'jin", x: 0.32, y: 0.5 },
  ],
  "Terokkar Forest": [
    { name: "Cenarion Thicket", x: 0.43, y: 0.22 },
    { name: "Tuurem", x: 0.54, y: 0.29 },
    { name: "Razorthorn Shelf", x: 0.6, y: 0.17 },
    { name: "Firewing Point", x: 0.73, y: 0.35 },
    { name: "Bonechewer Ruins", x: 0.66, y: 0.53 },
    { name: "Raastok Glade", x: 0.58, y: 0.41 },
    { name: "Stonebreaker Hold", x: 0.48, y: 0.43 },
    { name: "Allerian Stronghold", x: 0.57, y: 0.56 },
    { name: "Skettis", x: 0.71, y: 0.83 },
    { name: "Ring of Observance", x: 0.4, y: 0.66 },
    { name: "Tomb of Lights", x: 0.47, y: 0.55, worldAnchor: { worldX: 4939.2, worldY: -3371 } }, // Auchindoun
    { name: "Refuge Caravan", x: 0.37, y: 0.5 },
    { name: "Bleeding Hollow Ruins", x: 0.21, y: 0.67 },
    { name: "Veil Skith", x: 0.3, y: 0.42 },
    { name: "Shadow Tomb", x: 0.31, y: 0.53 },
    { name: "Shattrath City", x: 0.29, y: 0.24 },
    { name: "The Barrier Hills", x: 0.24, y: 0.1 },
  ],
  Nagrand: [
    { name: "Burning Blade Ruins", x: 0.75, y: 0.66 },
    { name: "Kil'sorrow Fortress", x: 0.69, y: 0.8 },
    { name: "Oshu'gun", x: 0.36, y: 0.72, worldAnchor: { worldX: 8303.7, worldY: -2575.2 } },
    { name: "Forge Camp: Hate", x: 0.27, y: 0.37 },
    { name: "Forge Camp: Fear", x: 0.21, y: 0.49 },
    { name: "Warmaul Hill", x: 0.28, y: 0.23 },
    { name: "Halaa", x: 0.43, y: 0.44 },
    { name: "Sunspring Post", x: 0.32, y: 0.43 },
    { name: "Laughing Skull Ruins", x: 0.47, y: 0.22 },
    { name: "Garadar", x: 0.56, y: 0.36 },
    { name: "Throne of the Elements", x: 0.61, y: 0.2 },
    { name: "Telaar", x: 0.52, y: 0.71 },
    { name: "Nesingwary Safari", x: 0.72, y: 0.37 },
    { name: "Windyreed Village", x: 0.74, y: 0.52 },
    { name: "The Ring of Trials", x: 0.66, y: 0.57 },
    { name: "Clan Watch", x: 0.62, y: 0.64 },
    { name: "Southwind Cleft", x: 0.5, y: 0.57 },
    { name: "Zangar Ridge", x: 0.34, y: 0.16 },
  ],
  Netherstorm: [
    { name: "Gyro-Plank Bridge", x: 0.26, y: 0.55 },
    { name: "Ruins of Enkaat", x: 0.34, y: 0.56 },
    { name: "Area 52", x: 0.33, y: 0.65 },
    { name: "Manaforge B'naar", x: 0.24, y: 0.71 },
    { name: "The Heap", x: 0.32, y: 0.77 },
    { name: "Arklon Ruins", x: 0.4, y: 0.72 },
    { name: "Manaforge Coruu", x: 0.49, y: 0.83 },
    { name: "Kirin'var Village", x: 0.58, y: 0.87 },
    { name: "Sunfury Hold", x: 0.56, y: 0.79 },
    { name: "Manaforge Duro", x: 0.6, y: 0.66 },
    { name: "Cosmowrench", x: 0.65, y: 0.68 },
    { name: "Eco-Dome Midreealm", x: 0.45, y: 0.53 },
    { name: "The Stormspire", x: 0.44, y: 0.34 },
    { name: "Manaforge Ara", x: 0.26, y: 0.39 },
    { name: "Forge Base: Oblivion", x: 0.38, y: 0.26 },
    { name: "Forge Base: Gehenna", x: 0.4, y: 0.2 },
    { name: "Socrethar's Seat", x: 0.3, y: 0.16 },
    { name: "Eco-Dome Farfield", x: 0.46, y: 0.11 },
    { name: "Netherstone", x: 0.49, y: 0.18 },
    { name: "Ruins of Farahlon", x: 0.54, y: 0.22 },
    { name: "Manaforge Ultris", x: 0.62, y: 0.4 },
    { name: "Celestial Ridge", x: 0.72, y: 0.4 },
    { name: "Ethereum Staging Grounds", x: 0.55, y: 0.43 },
    { name: "Tempest Keep", x: 0.76, y: 0.62 },
    // No confirmed real-world (worldX/worldY) anchor exists for Netherstorm yet -
    // the original 6-point OUTLAND_AFFINE calibration this session did (see
    // LeafletContinentMap.tsx) didn't include this zone. Don't guess one; leave
    // every Netherstorm landmark without a worldAnchor until a real /hw pos
    // reading comes in from there.
  ],
  "Shadowmoon Valley": [
    { name: "Legion Hold", x: 0.23, y: 0.37 },
    { name: "Shadowmoon Village", x: 0.29, y: 0.28 },
    { name: "Illidari Point", x: 0.3, y: 0.51 },
    { name: "Wildhammer Stronghold", x: 0.36, y: 0.58 },
    { name: "Eclipse Point", x: 0.45, y: 0.66 },
    { name: "Netherwing Fields", x: 0.65, y: 0.58 },
    { name: "Netherwing Ledge", x: 0.7, y: 0.84 },
    { name: "The Black Temple", x: 0.72, y: 0.44 },
    { name: "Coilskar Point", x: 0.46, y: 0.27 },
    { name: "Altar of Sha'tar", x: 0.61, y: 0.29 },
    { name: "The Hand of Gul'dan", x: 0.52, y: 0.44, worldAnchor: { worldX: 1380, worldY: -3557.5 } },
    { name: "Warden's Cage", x: 0.59, y: 0.51 },
    { name: "The Deathforge", x: 0.4, y: 0.39 },
  ],
};

function distance(ax: number, ay: number, bx: number, by: number): number {
  return Math.hypot(ax - bx, ay - by);
}

/** Nearest named landmark to a zone-relative point, or null if the zone has
 * no landmark data yet. */
export function nearestLandmark(zone: string, mapX: number, mapY: number): ZoneLandmark | null {
  const landmarks = ZONE_LANDMARKS[zone];
  if (!landmarks || landmarks.length === 0) return null;
  let best = landmarks[0];
  let bestDist = distance(mapX, mapY, best.x, best.y);
  for (const l of landmarks.slice(1)) {
    const d = distance(mapX, mapY, l.x, l.y);
    if (d < bestDist) {
      best = l;
      bestDist = d;
    }
  }
  return best;
}
