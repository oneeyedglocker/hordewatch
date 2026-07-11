import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";
import { classColor } from "../lib/classColors";
import { ActivityFingerprint } from "./ActivityFingerprint";

interface Props {
  sightings: Sighting[];
}

const CHART_W = 720;
const CHART_H = 220;
const PAD_L = 36;
const PAD_B = 22;
const PAD_T = 12;

function dayKey(ts: number): string {
  const d = new Date(ts * 1000);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function dayLabel(key: string): string {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

export function TrendsView({ sightings }: Props) {
  const [hoverIdx, setHoverIdx] = useState<number | null>(null);

  const byDay = useMemo(() => {
    const counts = new Map<string, number>();
    for (const s of sightings) {
      const key = dayKey(s.ts);
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
    const keys = Array.from(counts.keys()).sort();
    // Fill gaps so a quiet day reads as zero, not a skipped point.
    if (keys.length > 1) {
      const [firstY, firstM, firstD] = keys[0].split("-").map(Number);
      const start = new Date(firstY, firstM - 1, firstD);
      const [lastY, lastM, lastD] = keys[keys.length - 1].split("-").map(Number);
      const end = new Date(lastY, lastM - 1, lastD);
      const filled: string[] = [];
      for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
        filled.push(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`);
      }
      return filled.map((key) => ({ key, count: counts.get(key) ?? 0 }));
    }
    return keys.map((key) => ({ key, count: counts.get(key)! }));
  }, [sightings]);

  const topZones = useMemo(() => {
    const counts = new Map<string, number>();
    for (const s of sightings) counts.set(s.zone, (counts.get(s.zone) ?? 0) + 1);
    return Array.from(counts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8);
  }, [sightings]);

  const topClasses = useMemo(() => {
    const counts = new Map<string, number>();
    for (const s of sightings) if (s.class) counts.set(s.class, (counts.get(s.class) ?? 0) + 1);
    return Array.from(counts.entries()).sort((a, b) => b[1] - a[1]);
  }, [sightings]);

  if (sightings.length === 0) {
    return <div className="empty-state">No sightings yet to chart.</div>;
  }

  const maxCount = Math.max(1, ...byDay.map((d) => d.count));
  const plotW = CHART_W - PAD_L - 12;
  const plotH = CHART_H - PAD_T - PAD_B;
  const stepX = byDay.length > 1 ? plotW / (byDay.length - 1) : 0;

  function xFor(i: number) {
    return PAD_L + i * stepX;
  }
  function yFor(count: number) {
    return PAD_T + plotH - (count / maxCount) * plotH;
  }

  const linePath = byDay.map((d, i) => `${i === 0 ? "M" : "L"}${xFor(i)},${yFor(d.count)}`).join(" ");
  const areaPath =
    byDay.length > 0
      ? `${linePath} L${xFor(byDay.length - 1)},${PAD_T + plotH} L${xFor(0)},${PAD_T + plotH} Z`
      : "";

  const gridSteps = [0, 0.5, 1];
  const labelEvery = Math.max(1, Math.ceil(byDay.length / 7));
  const maxZoneCount = Math.max(1, ...topZones.map(([, c]) => c));
  const maxClassCount = Math.max(1, ...topClasses.map(([, c]) => c));

  return (
    <div className="trends-view">
      <div className="panel trend-panel">
        <h2>Sightings per day</h2>
        <svg
          className="trend-chart"
          viewBox={`0 0 ${CHART_W} ${CHART_H}`}
          role="img"
          aria-label="Sightings per day"
        >
          {gridSteps.map((f) => (
            <line
              key={f}
              x1={PAD_L}
              x2={CHART_W - 12}
              y1={PAD_T + plotH * (1 - f)}
              y2={PAD_T + plotH * (1 - f)}
              className="trend-grid"
            />
          ))}
          {gridSteps.map((f) => (
            <text key={f} x={PAD_L - 8} y={PAD_T + plotH * (1 - f) + 3} className="trend-axis-label" textAnchor="end">
              {Math.round(maxCount * f)}
            </text>
          ))}
          {byDay.map((d, i) =>
            i % labelEvery === 0 ? (
              <text key={d.key} x={xFor(i)} y={CHART_H - 4} className="trend-axis-label" textAnchor="middle">
                {dayLabel(d.key)}
              </text>
            ) : null,
          )}
          {areaPath && <path d={areaPath} className="trend-area" />}
          {linePath && <path d={linePath} className="trend-line" />}
          {byDay.map((d, i) => (
            <g key={d.key}>
              <rect
                x={xFor(i) - stepX / 2}
                y={PAD_T}
                width={Math.max(stepX, 4)}
                height={plotH}
                fill="transparent"
                onMouseEnter={() => setHoverIdx(i)}
                onMouseLeave={() => setHoverIdx((cur) => (cur === i ? null : cur))}
              />
              {(i === byDay.length - 1 || hoverIdx === i) && (
                <circle cx={xFor(i)} cy={yFor(d.count)} r={hoverIdx === i ? 5 : 4} className="trend-dot" />
              )}
            </g>
          ))}
          {hoverIdx !== null && (
            <>
              <line
                x1={xFor(hoverIdx)}
                x2={xFor(hoverIdx)}
                y1={PAD_T}
                y2={PAD_T + plotH}
                className="trend-crosshair"
              />
              <text x={xFor(hoverIdx)} y={PAD_T + 12} className="trend-tooltip-text" textAnchor="middle">
                {dayLabel(byDay[hoverIdx].key)}: {byDay[hoverIdx].count}
              </text>
            </>
          )}
        </svg>
      </div>

      <div className="trend-cols">
        <div className="panel trend-panel">
          <h2>Top zones</h2>
          <div className="bar-list">
            {topZones.map(([zone, count]) => (
              <div className="bar-row" key={zone}>
                <span className="bar-label">{zone}</span>
                <div className="bar-track">
                  <div className="bar-fill" style={{ width: `${(count / maxZoneCount) * 100}%` }} />
                </div>
                <span className="bar-value">{count}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="panel trend-panel">
          <h2>Top classes</h2>
          {topClasses.length === 0 ? (
            <p className="muted">No class-identified sightings yet.</p>
          ) : (
            <div className="bar-list">
              {topClasses.map(([cls, count]) => (
                <div className="bar-row" key={cls}>
                  <span className="bar-label">
                    <span className="class-dot" style={{ background: classColor(cls) }} aria-hidden />
                    {cls}
                  </span>
                  <div className="bar-track">
                    <div className="bar-fill" style={{ width: `${(count / maxClassCount) * 100}%`, background: classColor(cls) }} />
                  </div>
                  <span className="bar-value">{count}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <ActivityFingerprint sightings={sightings} />
    </div>
  );
}
