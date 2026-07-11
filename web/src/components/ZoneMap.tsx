import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";
import { classColor } from "../lib/classColors";
import { relativeTime } from "../lib/format";
import { useZoneImage } from "../lib/useZoneImage";
import { useContinentImage } from "../lib/useContinentImage";
import { LeafletZoneMap } from "./LeafletZoneMap";
import { LeafletContinentMap } from "./LeafletContinentMap";

interface Props {
  sightings: Sighting[];
}

const SIZE = 560;
const DOT_R = 5;

// Outland's continent-level UiMapID (confirmed directly from wow.export's
// own export metadata - see web/public/maps/530.json) - this is what the
// continent image/sidecar are keyed by.
const OUTLAND_CONTINENT_ID = 530;

// The set of continentID values HereBeDragons can actually hand back for a
// real Outland position. Per its own transform table for TBC Classic
// (HordeWatch/Libs/HereBeDragons/HereBeDragons-2.0.lua, the WoWBC block),
// most of Outland's raw coordinate space gets bucketed into 0 or 1 (with an
// offset applied to worldX/worldY) rather than staying 530 - see the
// OUTLAND_OFFSETS comment in LeafletContinentMap.tsx for how that offset
// gets reversed for pixel placement. All three need to be accepted here or
// most real Outland sightings silently don't show up on the continent view.
const OUTLAND_CONTINENT_IDS = new Set([530, 0, 1]);

interface Tooltip {
  x: number;
  y: number;
  text: string;
}

export function ZoneMap({ sightings }: Props) {
  const [view, setView] = useState<"zone" | "continent">("zone");
  const [nameFilter, setNameFilter] = useState("");
  const nameQuery = nameFilter.trim().toLowerCase();

  const continentPoints = useMemo(() => {
    let rows = sightings.filter(
      (s) => s.continentID !== undefined && OUTLAND_CONTINENT_IDS.has(s.continentID) && s.worldX !== undefined && s.worldY !== undefined,
    );
    if (nameQuery) rows = rows.filter((s) => s.player.toLowerCase().includes(nameQuery));
    return rows;
  }, [sightings, nameQuery]);
  const continentImage = useContinentImage(OUTLAND_CONTINENT_ID);

  const zoneStats = useMemo(() => {
    const counts = new Map<string, number>();
    for (const s of sightings) {
      if (s.mapX === undefined || s.mapY === undefined) continue;
      counts.set(s.zone, (counts.get(s.zone) ?? 0) + 1);
    }
    return Array.from(counts.entries()).sort((a, b) => b[1] - a[1]);
  }, [sightings]);

  const [zone, setZone] = useState<string | null>(null);
  const activeZone = zone ?? zoneStats[0]?.[0] ?? null;

  const points = useMemo(() => {
    if (!activeZone) return [];
    let rows = sightings.filter((s) => s.zone === activeZone && s.mapX !== undefined && s.mapY !== undefined);
    if (nameQuery) rows = rows.filter((s) => s.player.toLowerCase().includes(nameQuery));
    return rows;
  }, [sightings, activeZone, nameQuery]);

  // mapID is the addon's stable per-zone key (see DATA_MODEL.md) - zone
  // *name* is just what we group the picker by, so pull mapID from
  // whichever sighting in the group happens to have it.
  const mapID = useMemo(() => points.find((p) => p.mapID !== undefined)?.mapID, [points]);

  const classesPresent = useMemo(() => {
    const set = new Set<string>();
    for (const p of points) if (p.class) set.add(p.class);
    return Array.from(set).sort();
  }, [points]);

  const [tooltip, setTooltip] = useState<Tooltip | null>(null);
  const zoneImage = useZoneImage(mapID);

  const continentClassesPresent = useMemo(() => {
    const set = new Set<string>();
    for (const p of continentPoints) if (p.class) set.add(p.class);
    return Array.from(set).sort();
  }, [continentPoints]);

  if (zoneStats.length === 0 && continentPoints.length === 0) {
    return <div className="empty-state">No sightings with positional data (mapX/mapY or worldX/worldY) to plot yet.</div>;
  }

  const viewToggle = (
    <div className="view-toggle">
      <button className="view-toggle-btn" aria-current={view === "zone"} onClick={() => setView("zone")}>
        Zone
      </button>
      <button className="view-toggle-btn" aria-current={view === "continent"} onClick={() => setView("continent")}>
        Outland (all zones)
      </button>
    </div>
  );

  const nameFilterInput = (
    <input
      type="text"
      className="text-input"
      placeholder="Filter by player name..."
      value={nameFilter}
      onChange={(e) => setNameFilter(e.target.value)}
    />
  );

  if (view === "continent") {
    return (
      <div className="zone-map-view">
        <div className="table-controls">
          {viewToggle}
          {nameFilterInput}
          {continentImage.status === "found" ? (
            <span className="muted">
              Continuous map across every Outland zone - positions come from worldX/worldY (HereBeDragons), not the
              per-zone coordinates.
            </span>
          ) : (
            <span className="muted">No continent image yet.</span>
          )}
        </div>

        <div className="zone-map-body">
          {continentImage.status === "found" ? (
            <div className="zone-map-canvas-wrap">
              <LeafletContinentMap
                imageUrl={continentImage.url}
                imageWidth={continentImage.meta.imageWidth}
                imageHeight={continentImage.meta.imageHeight}
                points={continentPoints}
                mapName={continentImage.meta.mapName}
              />
            </div>
          ) : (
            <div className="empty-state">
              No continent image at <code>web/public/maps/{OUTLAND_CONTINENT_ID}.jpg</code> (plus its{" "}
              <code>.json</code> coordinate sidecar) yet - see <code>web/public/maps/README.md</code>.
            </div>
          )}

          <div className="zone-map-legend">
            {continentClassesPresent.length > 0 && (
              <>
                <h3>Classes in view</h3>
                {continentClassesPresent.map((c) => (
                  <div key={c} className="legend-row">
                    <span className="class-dot" style={{ background: classColor(c) }} aria-hidden />
                    <span>{c}</span>
                  </div>
                ))}
                <p className="muted legend-note">{continentPoints.length} plotted sighting(s)</p>
              </>
            )}
            {continentPoints.length === 0 && (
              <p className="muted">No sightings with worldX/worldY on this continent yet.</p>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="zone-map-view">
      <div className="table-controls">
        {viewToggle}
        <select value={activeZone ?? ""} onChange={(e) => setZone(e.target.value)}>
          {zoneStats.map(([z, count]) => (
            <option key={z} value={z}>
              {z} ({count})
            </option>
          ))}
        </select>
        {nameFilterInput}
        {zoneImage.status === "found" ? (
          <span className="muted">Real zone map - positions are the reporter's location at detection time.</span>
        ) : (
          <span className="muted">Positions are zone-relative (0-1), reporter's location at detection time - not a real map image.</span>
        )}
      </div>

      <div className="zone-map-body">
        {zoneImage.status === "found" ? (
          <div className="zone-map-canvas-wrap">
            <LeafletZoneMap
              imageUrl={zoneImage.url}
              imageWidth={zoneImage.width}
              imageHeight={zoneImage.height}
              points={points}
              zoneName={activeZone ?? ""}
            />
          </div>
        ) : (
          <div className="zone-map-canvas-wrap">
            <svg
              className="zone-map-canvas"
              width={SIZE}
              height={SIZE}
              viewBox={`0 0 ${SIZE} ${SIZE}`}
              role="img"
              aria-label={`Scatter plot of sightings in ${activeZone}`}
            >
              <rect x={0} y={0} width={SIZE} height={SIZE} className="zone-map-bg" />
              {[0.25, 0.5, 0.75].map((f) => (
                <g key={f}>
                  <line x1={f * SIZE} y1={0} x2={f * SIZE} y2={SIZE} className="zone-map-grid" />
                  <line x1={0} y1={f * SIZE} x2={SIZE} y2={f * SIZE} className="zone-map-grid" />
                </g>
              ))}
              {points.map((p, i) => (
                <circle
                  key={i}
                  cx={(p.mapX ?? 0) * SIZE}
                  cy={(p.mapY ?? 0) * SIZE}
                  r={DOT_R}
                  fill={classColor(p.class)}
                  stroke="var(--surface-1)"
                  strokeWidth={2}
                  className="zone-map-dot"
                  onMouseEnter={(e) => {
                    const rect = (e.target as SVGCircleElement).ownerSVGElement!.getBoundingClientRect();
                    setTooltip({
                      x: (p.mapX ?? 0) * SIZE,
                      y: (p.mapY ?? 0) * SIZE,
                      text: `${p.player}${p.class ? ` (${p.class}${p.level ? " " + p.level : ""})` : ""} - ${relativeTime(p.ts)}`,
                    });
                    void rect;
                  }}
                  onMouseLeave={() => setTooltip(null)}
                />
              ))}
              {tooltip && (
                <g pointerEvents="none">
                  <text x={tooltip.x + 10} y={tooltip.y - 10} className="zone-map-tooltip-text">
                    {tooltip.text}
                  </text>
                </g>
              )}
            </svg>
          </div>
        )}

        <div className="zone-map-legend">
          {classesPresent.length > 0 && (
            <>
              <h3>Classes in view</h3>
              {classesPresent.map((c) => (
                <div key={c} className="legend-row">
                  <span className="class-dot" style={{ background: classColor(c) }} aria-hidden />
                  <span>{c}</span>
                </div>
              ))}
              <p className="muted legend-note">{points.length} plotted sighting(s)</p>
            </>
          )}
          {zoneImage.status === "missing" && (
            <div className="map-missing-note">
              <h3>No map image yet</h3>
              <p className="muted">
                Extract {activeZone} (mapID {mapID ?? "?"}) with{" "}
                <a href="https://github.com/Kruithne/wow.export" target="_blank" rel="noreferrer">
                  wow.export
                </a>{" "}
                and save it as <code>web/public/maps/{mapID ?? "?"}.jpg</code> - see{" "}
                <code>web/public/maps/README.md</code>.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
