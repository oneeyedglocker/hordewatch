import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";
import { classColor } from "../lib/classColors";
import { relativeTime } from "../lib/format";

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

// No basemap imagery ships with this project (see DATA_MODEL.md gap #2 -
// zone art is Blizzard's, sourced separately). This plots mapX/mapY as a
// relative scatter inside a plain square per zone rather than over real
// terrain - a positioning signal, not a rendered map.
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

  const classesPresent = useMemo(() => {
    const set = new Set<string>();
    for (const p of points) if (p.class) set.add(p.class);
    return Array.from(set).sort();
  }, [points]);

  const [tooltip, setTooltip] = useState<Tooltip | null>(null);

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
        <span className="muted">Positions are zone-relative (0-1), reporter's location at detection time - not a real map image.</span>
      </div>

      <div className="zone-map-body">
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

        {classesPresent.length > 0 && (
          <div className="zone-map-legend">
            <h3>Classes in view</h3>
            {classesPresent.map((c) => (
              <div key={c} className="legend-row">
                <span className="class-dot" style={{ background: classColor(c) }} aria-hidden />
                <span>{c}</span>
              </div>
            ))}
            <p className="muted legend-note">{points.length} plotted sighting(s)</p>
          </div>
        )}
      </div>
    </div>
  );
}
