import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";
import { rankGuilds, rankPlayers } from "../lib/rankings";

interface Props {
  sightings: Sighting[];
  /** Jump straight to a subject's Activity Fingerprint on the Trends page. */
  onSelectSubject: (key: string) => void;
}

const CHART_W = 720;
const CHART_H = 220;
const PAD_L = 36;
const PAD_B = 22;
const PAD_T = 12;

const TOP_GUILD_COUNT = 5;
const TOP_PLAYER_COUNT = 8;

function dayKey(ts: number): string {
  const d = new Date(ts * 1000);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function dayLabel(key: string): string {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

export function OverviewView({ sightings, onSelectSubject }: Props) {
  const [hoverIdx, setHoverIdx] = useState<number | null>(null);

  const stats = useMemo(() => {
    const players = new Set<string>();
    const guilds = new Set<string>();
    let minTs = Infinity;
    let maxTs = -Infinity;
    for (const s of sightings) {
      players.add(s.player);
      if (s.guild) guilds.add(s.guild);
      if (s.ts < minTs) minTs = s.ts;
      if (s.ts > maxTs) maxTs = s.ts;
    }
    return {
      total: sightings.length,
      players: players.size,
      guilds: guilds.size,
      range:
        sightings.length > 0
          ? `${new Date(minTs * 1000).toLocaleDateString()} - ${new Date(maxTs * 1000).toLocaleDateString()}`
          : "-",
    };
  }, [sightings]);

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

  const topGuilds = useMemo(() => rankGuilds(sightings).slice(0, TOP_GUILD_COUNT), [sightings]);
  const topPlayers = useMemo(() => rankPlayers(sightings).slice(0, TOP_PLAYER_COUNT), [sightings]);
  const maxGuildCount = Math.max(1, ...topGuilds.map((g) => g.count));
  const maxPlayerCount = Math.max(1, ...topPlayers.map((p) => p.count));

  if (sightings.length === 0) {
    return <div className="empty-state">No sightings yet.</div>;
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
    byDay.length > 0 ? `${linePath} L${xFor(byDay.length - 1)},${PAD_T + plotH} L${xFor(0)},${PAD_T + plotH} Z` : "";

  const gridSteps = [0, 0.5, 1];
  const labelEvery = Math.max(1, Math.ceil(byDay.length / 7));

  return (
    <div className="overview-view">
      <section className="stat-row">
        <Stat label="Sightings" value={stats.total} />
        <Stat label="Unique players" value={stats.players} />
        <Stat label="Guilds seen" value={stats.guilds} />
        <Stat label="Date range" value={stats.range} />
      </section>

      <div className="panel trend-panel">
        <h2>Sightings per day</h2>
        <svg className="trend-chart" viewBox={`0 0 ${CHART_W} ${CHART_H}`} role="img" aria-label="Sightings per day">
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
              <line x1={xFor(hoverIdx)} x2={xFor(hoverIdx)} y1={PAD_T} y2={PAD_T + plotH} className="trend-crosshair" />
              <text x={xFor(hoverIdx)} y={PAD_T + 12} className="trend-tooltip-text" textAnchor="middle">
                {dayLabel(byDay[hoverIdx].key)}: {byDay[hoverIdx].count}
              </text>
            </>
          )}
        </svg>
      </div>

      <div className="trend-cols">
        <div className="panel trend-panel">
          <h2>Most active guilds</h2>
          {topGuilds.length === 0 ? (
            <p className="muted">No guild-tagged sightings yet.</p>
          ) : (
            <div className="bar-list">
              {topGuilds.map((g) => (
                <button className="bar-row bar-row-link" key={g.name} onClick={() => onSelectSubject(`guild:${g.name}`)}>
                  <span className="bar-label">{g.name}</span>
                  <div className="bar-track">
                    <div className="bar-fill" style={{ width: `${(g.count / maxGuildCount) * 100}%` }} />
                  </div>
                  <span className="bar-value">{g.count}</span>
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="panel trend-panel">
          <h2>Most active players</h2>
          <div className="bar-list">
            {topPlayers.map((p) => (
              <button className="bar-row bar-row-link" key={p.name} onClick={() => onSelectSubject(`player:${p.name}`)}>
                <span className="bar-label">{p.name}</span>
                <div className="bar-track">
                  <div className="bar-fill" style={{ width: `${(p.count / maxPlayerCount) * 100}%` }} />
                </div>
                <span className="bar-value">{p.count}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="stat">
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
    </div>
  );
}
