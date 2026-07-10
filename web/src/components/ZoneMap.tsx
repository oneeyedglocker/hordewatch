import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";
import { classColor } from "../lib/classColors";
import { relativeTime } from "../lib/format";
import { useZoneImage } from "../lib/useZoneImage";
import { LeafletZoneMap } from "./LeafletZoneMap";

interface Props {
  sightings: Sighting[];
}

const SIZE = 560;
const DOT_R = 5;

interface Tooltip {
  x: number;
  y: number;
  text: string;
}

export function ZoneMap({ sightings }: Props) {
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
    return sightings.filter((s) => s.zone === activeZone && s.mapX !== undefined && s.mapY !== undefined);
  }, [sightings, activeZone]);

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

  if (zoneStats.length === 0) {
    return <div className="empty-state">No sightings with zone-local coordinates (mapX/mapY) to plot yet.</div>;
  }

  return (
    <div className="zone-map-view">
      <div className="table-controls">
        <select value={activeZone ?? ""} onChange={(e) => setZone(e.target.value)}>
          {zoneStats.map(([z, count]) => (
            <option key={z} value={z}>
              {z} ({count})
            </option>
          ))}
        </select>
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
