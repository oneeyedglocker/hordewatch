import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";
import { DAY_LABELS, buildDayHourMatrix, buildHourHistogram, hourLabel, topZones } from "../lib/fingerprint";
import { buildInsights } from "../lib/insights";
import { SubjectPicker } from "./SubjectPicker";

interface Props {
  sightings: Sighting[];
  /** Controlled from TrendsView so the overview page's "most active"
   * shortcuts can jump straight into a subject's fingerprint. */
  subjectKey: string;
  onSubjectKeyChange: (key: string) => void;
}

const HOUR_CHART_W = 460;
const HOUR_CHART_H = 160;
const HOUR_PAD_L = 26;
const HOUR_PAD_B = 20;
const HOUR_PAD_T = 20;

const HEATMAP_W = 720;
const HEATMAP_ROW_H = 20;
const HEATMAP_PAD_L = 34;
const HEATMAP_PAD_R = 8;
const HEATMAP_PAD_T = 20;
const HEATMAP_PAD_B = 18;

function axisHourLabel(hour: number): string {
  return hourLabel(hour).replace(" ", "").replace("AM", "a").replace("PM", "p");
}

// Sequential encoding on the app's single accent hue via alpha, rather than
// a hardcoded ramp - stays correct across the light/dark theme automatically
// since --accent already flips per theme. sqrt compresses the scale so one
// unusually busy cell doesn't wash out the rest of the grid.
function heatOpacity(count: number, max: number): number {
  if (count === 0 || max === 0) return 0;
  const MIN_OPACITY = 0.16;
  const t = Math.sqrt(count / max);
  return MIN_OPACITY + t * (1 - MIN_OPACITY);
}

// Renders "**text**" as <strong> without pulling in a markdown parser - the
// insight builder only ever wraps a single zone name per sentence.
function renderInsightText(text: string) {
  const parts = text.split("**");
  return parts.map((part, i) => (i % 2 === 1 ? <strong key={i}>{part}</strong> : <span key={i}>{part}</span>));
}

export function ActivityFingerprint({ sightings, subjectKey, onSubjectKeyChange }: Props) {
  const [hoverHour, setHoverHour] = useState<number | null>(null);
  const [hoverCell, setHoverCell] = useState<{ day: number; hour: number } | null>(null);

  const subject = useMemo(() => {
    if (!subjectKey) return null;
    const type = subjectKey.startsWith("guild:") ? "guild" : "player";
    const value = subjectKey.slice(type.length + 1);
    return { type: type as "player" | "guild", value };
  }, [subjectKey]);

  const subjectSightings = useMemo(() => {
    if (!subject) return [];
    return sightings.filter((s) => (subject.type === "player" ? s.player === subject.value : s.guild === subject.value));
  }, [sightings, subject]);

  const subjectRange = useMemo<[number, number] | null>(() => {
    if (subjectSightings.length === 0) return null;
    let lo = Infinity;
    let hi = -Infinity;
    for (const s of subjectSightings) {
      if (s.ts < lo) lo = s.ts;
      if (s.ts > hi) hi = s.ts;
    }
    return [lo, hi];
  }, [subjectSightings]);

  const insights = useMemo(
    () => (subject ? buildInsights(subjectSightings, subject.type) : []),
    [subject, subjectSightings],
  );

  const zones = useMemo(() => topZones(subjectSightings, 6), [subjectSightings]);
  const maxZoneCount = Math.max(1, ...zones.map(([, c]) => c));

  const hourHist = useMemo(() => buildHourHistogram(subjectSightings), [subjectSightings]);
  const maxHourCount = Math.max(1, ...hourHist);
  const peakHour = hourHist.indexOf(Math.max(...hourHist));

  const matrix = useMemo(() => buildDayHourMatrix(subjectSightings), [subjectSightings]);
  const maxCellCount = Math.max(1, ...matrix.flat());

  const hourPlotW = HOUR_CHART_W - HOUR_PAD_L - 8;
  const hourPlotH = HOUR_CHART_H - HOUR_PAD_T - HOUR_PAD_B;
  const hourStep = hourPlotW / 24;

  const heatPlotW = HEATMAP_W - HEATMAP_PAD_L - HEATMAP_PAD_R;
  const cellW = heatPlotW / 24;

  return (
    <div className="panel trend-panel fingerprint-panel">
      <h2>Activity fingerprint</h2>
      <div className="fingerprint-controls">
        <SubjectPicker sightings={sightings} value={subjectKey} onChange={onSubjectKeyChange} />
        {subjectRange && (
          <span className="muted">
            {subjectSightings.length} sighting{subjectSightings.length === 1 ? "" : "s"} &middot;{" "}
            {new Date(subjectRange[0] * 1000).toLocaleDateString()} - {new Date(subjectRange[1] * 1000).toLocaleDateString()}
          </span>
        )}
      </div>

      {!subject ? (
        <p className="muted">Pick a player or guild to see their activity patterns and a rough guess at where they'll be.</p>
      ) : (
        <>
          <div className="insights-card">
            <h3 className="insights-title">Trending snapshot &amp; predictions</h3>
            {insights.length === 0 ? (
              <p className="muted">
                Not enough sightings yet to generate a snapshot for {subject.value} - patterns and predictions need at
                least a handful of hits to say anything meaningful.
              </p>
            ) : (
              <ul className="insights-list">
                {insights.map((insight, i) => (
                  <li key={i} className={`insights-item insights-item--${insight.kind}`}>
                    {renderInsightText(insight.text)}
                  </li>
                ))}
              </ul>
            )}
            <p className="muted insights-footnote">
              These are frequency patterns read from logged sightings, not a trained model - treat them as leads, not
              guarantees. Kill/death counts aren&apos;t tracked yet either, since the addon only logs sightings
              (position + time), not combat outcomes.
            </p>
          </div>

          <div className="trend-cols fingerprint-charts">
            <div>
              <h3>Top zones</h3>
              {zones.length === 0 ? (
                <p className="muted">No sightings yet.</p>
              ) : (
                <div className="bar-list">
                  {zones.map(([zone, count]) => (
                    <div className="bar-row" key={zone}>
                      <span className="bar-label">{zone}</span>
                      <div className="bar-track">
                        <div className="bar-fill" style={{ width: `${(count / maxZoneCount) * 100}%` }} />
                      </div>
                      <span className="bar-value">{count}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div>
              <h3>Active hours (local time)</h3>
              <svg
                className="trend-chart"
                viewBox={`0 0 ${HOUR_CHART_W} ${HOUR_CHART_H}`}
                role="img"
                aria-label={`Sightings by hour of day for ${subject.value}`}
              >
                {[0, 0.5, 1].map((f) => (
                  <line
                    key={f}
                    x1={HOUR_PAD_L}
                    x2={HOUR_CHART_W - 8}
                    y1={HOUR_PAD_T + hourPlotH * (1 - f)}
                    y2={HOUR_PAD_T + hourPlotH * (1 - f)}
                    className="trend-grid"
                  />
                ))}
                {hourHist.map((count, h) => {
                  const barW = Math.max(hourStep - 2, 1);
                  const x = HOUR_PAD_L + h * hourStep + 1;
                  const barH = (count / maxHourCount) * hourPlotH;
                  const y = HOUR_PAD_T + hourPlotH - barH;
                  return (
                    <g key={h}>
                      <rect
                        x={x}
                        y={y}
                        width={barW}
                        height={Math.max(barH, count > 0 ? 2 : 0)}
                        rx={2}
                        className="hist-bar"
                        tabIndex={0}
                        onMouseEnter={() => setHoverHour(h)}
                        onMouseLeave={() => setHoverHour((cur) => (cur === h ? null : cur))}
                        onFocus={() => setHoverHour(h)}
                        onBlur={() => setHoverHour((cur) => (cur === h ? null : cur))}
                      />
                      {h % 3 === 0 && (
                        <text x={x + barW / 2} y={HOUR_CHART_H - 4} className="trend-axis-label" textAnchor="middle">
                          {axisHourLabel(h)}
                        </text>
                      )}
                    </g>
                  );
                })}
                {maxHourCount > 0 && (
                  <text
                    x={HOUR_PAD_L + peakHour * hourStep + hourStep / 2}
                    y={HOUR_PAD_T + hourPlotH - (hourHist[peakHour] / maxHourCount) * hourPlotH - 6}
                    className="trend-tooltip-text"
                    textAnchor="middle"
                  >
                    {hoverHour === null || hoverHour === peakHour ? `peak: ${hourHist[peakHour]}` : ""}
                  </text>
                )}
                {hoverHour !== null && hoverHour !== peakHour && (
                  <text
                    x={HOUR_PAD_L + hoverHour * hourStep + hourStep / 2}
                    y={HOUR_PAD_T + hourPlotH - (hourHist[hoverHour] / maxHourCount) * hourPlotH - 6}
                    className="trend-tooltip-text"
                    textAnchor="middle"
                  >
                    {axisHourLabel(hoverHour)}: {hourHist[hoverHour]}
                  </text>
                )}
              </svg>
            </div>
          </div>

          <h3 className="heatmap-title">Day &times; hour activity</h3>
          <svg
            className="trend-chart heatmap-chart"
            viewBox={`0 0 ${HEATMAP_W} ${HEATMAP_PAD_T + 7 * HEATMAP_ROW_H + HEATMAP_PAD_B}`}
            role="img"
            aria-label={`Sightings by day of week and hour for ${subject.value}`}
          >
            <text x={HEATMAP_PAD_L} y={HEATMAP_PAD_T - 8} className="trend-axis-label" textAnchor="middle">
              {hoverCell
                ? `${DAY_LABELS[hoverCell.day]} ${hourLabel(hoverCell.hour)}: ${matrix[hoverCell.day][hoverCell.hour]} sighting(s)`
                : ""}
            </text>
            {DAY_LABELS.map((day, d) => (
              <text
                key={day}
                x={HEATMAP_PAD_L - 8}
                y={HEATMAP_PAD_T + d * HEATMAP_ROW_H + HEATMAP_ROW_H / 2 + 3}
                className="trend-axis-label"
                textAnchor="end"
              >
                {day}
              </text>
            ))}
            {Array.from({ length: 24 }, (_, h) => h)
              .filter((h) => h % 3 === 0)
              .map((h) => (
                <text
                  key={h}
                  x={HEATMAP_PAD_L + h * cellW + cellW / 2}
                  y={HEATMAP_PAD_T + 7 * HEATMAP_ROW_H + HEATMAP_PAD_B - 4}
                  className="trend-axis-label"
                  textAnchor="middle"
                >
                  {axisHourLabel(h)}
                </text>
              ))}
            {matrix.map((row, d) =>
              row.map((count, h) => (
                <rect
                  key={`${d}-${h}`}
                  x={HEATMAP_PAD_L + h * cellW + 1}
                  y={HEATMAP_PAD_T + d * HEATMAP_ROW_H + 1}
                  width={Math.max(cellW - 2, 1)}
                  height={HEATMAP_ROW_H - 2}
                  rx={2}
                  className="heatmap-cell"
                  fillOpacity={heatOpacity(count, maxCellCount)}
                  tabIndex={0}
                  onMouseEnter={() => setHoverCell({ day: d, hour: h })}
                  onMouseLeave={() => setHoverCell((cur) => (cur && cur.day === d && cur.hour === h ? null : cur))}
                  onFocus={() => setHoverCell({ day: d, hour: h })}
                  onBlur={() => setHoverCell((cur) => (cur && cur.day === d && cur.hour === h ? null : cur))}
                />
              )),
            )}
          </svg>
          <div className="heatmap-legend">
            <span className="muted">Fewer sightings</span>
            <div className="heatmap-legend-gradient" />
            <span className="muted">More sightings</span>
          </div>
        </>
      )}
    </div>
  );
}
