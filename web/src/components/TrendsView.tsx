import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";
import { classColor } from "../lib/classColors";
import { ActivityFingerprint } from "./ActivityFingerprint";

interface Props {
  sightings: Sighting[];
  subjectKey: string;
  onSubjectKeyChange: (key: string) => void;
}

const PRESETS = [
  { key: "1h", label: "1h", seconds: 3600 },
  { key: "24h", label: "24h", seconds: 86400 },
  { key: "3d", label: "3d", seconds: 86400 * 3 },
  { key: "7d", label: "7d", seconds: 86400 * 7 },
  { key: "30d", label: "30d", seconds: 86400 * 30 },
  { key: "all", label: "All", seconds: null },
] as const;
type PresetKey = (typeof PRESETS)[number]["key"];

// Anchored to the most recent sighting in the log, not the wall clock - an
// older export/demo dataset shouldn't read as "empty" just because real
// time has moved past it.
function filterByPreset(sightings: Sighting[], preset: PresetKey): Sighting[] {
  if (preset === "all" || sightings.length === 0) return sightings;
  const seconds = PRESETS.find((p) => p.key === preset)!.seconds!;
  const maxTs = Math.max(...sightings.map((s) => s.ts));
  const cutoff = maxTs - seconds;
  return sightings.filter((s) => s.ts >= cutoff);
}

export function TrendsView({ sightings, subjectKey, onSubjectKeyChange }: Props) {
  const [preset, setPreset] = useState<PresetKey>("all");

  const windowed = useMemo(() => filterByPreset(sightings, preset), [sightings, preset]);

  const topZones = useMemo(() => {
    const counts = new Map<string, number>();
    for (const s of windowed) counts.set(s.zone, (counts.get(s.zone) ?? 0) + 1);
    return Array.from(counts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8);
  }, [windowed]);

  const topClasses = useMemo(() => {
    const counts = new Map<string, number>();
    for (const s of windowed) if (s.class) counts.set(s.class, (counts.get(s.class) ?? 0) + 1);
    return Array.from(counts.entries()).sort((a, b) => b[1] - a[1]);
  }, [windowed]);

  if (sightings.length === 0) {
    return <div className="empty-state">No sightings yet to chart.</div>;
  }

  const maxZoneCount = Math.max(1, ...topZones.map(([, c]) => c));
  const maxClassCount = Math.max(1, ...topClasses.map(([, c]) => c));

  return (
    <div className="trends-view">
      <div className="table-controls">
        <span className="muted">Time window</span>
        <div className="view-toggle">
          {PRESETS.map((p) => (
            <button key={p.key} className="view-toggle-btn" aria-current={preset === p.key} onClick={() => setPreset(p.key)}>
              {p.label}
            </button>
          ))}
        </div>
        {windowed.length === 0 && <span className="muted">No sightings in this time window.</span>}
      </div>

      <div className="trend-cols">
        <div className="panel trend-panel">
          <h2>Top zones</h2>
          {topZones.length === 0 ? (
            <p className="muted">No sightings in this window.</p>
          ) : (
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
          )}
        </div>

        <div className="panel trend-panel">
          <h2>Top classes</h2>
          {topClasses.length === 0 ? (
            <p className="muted">No class-identified sightings in this window.</p>
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

      {/* Deliberately fed the full, unwindowed history (not `windowed`) -
          the fingerprint's own day-of-week/hour-of-day tiering needs the
          complete log to find a recurring pattern; narrowing it to "last
          1h" would starve that logic rather than scope it usefully. */}
      <ActivityFingerprint sightings={sightings} subjectKey={subjectKey} onSubjectKeyChange={onSubjectKeyChange} />
    </div>
  );
}
