import { useMemo, useState, type CSSProperties } from "react";
import type { Sighting } from "../lib/types";
import { classColor } from "../lib/classColors";
import { absoluteTime, relativeTime } from "../lib/format";

interface Props {
  sightings: Sighting[];
}

type SortKey = "ts" | "player" | "zone" | "level" | "reportCount";
type SortDir = "asc" | "desc";

const PAGE_SIZE = 200;

export function SightingsTable({ sightings }: Props) {
  const [search, setSearch] = useState("");
  const [classFilter, setClassFilter] = useState<string>("all");
  const [methodFilter, setMethodFilter] = useState<string>("all");
  const [sortKey, setSortKey] = useState<SortKey>("ts");
  const [sortDir, setSortDir] = useState<SortDir>("desc");
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);

  const classes = useMemo(() => {
    const set = new Set<string>();
    for (const s of sightings) if (s.class) set.add(s.class);
    return Array.from(set).sort();
  }, [sightings]);

  const methods = useMemo(() => {
    const set = new Set<string>();
    for (const s of sightings) set.add(s.method);
    return Array.from(set).sort();
  }, [sightings]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    let rows = sightings;
    if (classFilter !== "all") rows = rows.filter((s) => s.class === classFilter);
    if (methodFilter !== "all") rows = rows.filter((s) => s.method === methodFilter);
    if (q) {
      rows = rows.filter(
        (s) =>
          s.player.toLowerCase().includes(q) ||
          (s.guild ?? "").toLowerCase().includes(q) ||
          s.zone.toLowerCase().includes(q) ||
          (s.subZone ?? "").toLowerCase().includes(q),
      );
    }

    const dir = sortDir === "asc" ? 1 : -1;
    return [...rows].sort((a, b) => {
      switch (sortKey) {
        case "player":
          return a.player.localeCompare(b.player) * dir;
        case "zone":
          return a.zone.localeCompare(b.zone) * dir;
        case "level":
          return ((a.level ?? -1) - (b.level ?? -1)) * dir;
        case "reportCount":
          return ((a.reportCount ?? 1) - (b.reportCount ?? 1)) * dir;
        case "ts":
        default:
          return (a.ts - b.ts) * dir;
      }
    });
  }, [sightings, search, classFilter, methodFilter, sortKey, sortDir]);

  function toggleSort(key: SortKey) {
    if (key === sortKey) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir(key === "ts" ? "desc" : "asc");
    }
    setVisibleCount(PAGE_SIZE);
  }

  const visible = filtered.slice(0, visibleCount);

  return (
    <div className="table-view">
      <div className="table-controls">
        <input
          className="text-input"
          placeholder="Search player, guild, or zone..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setVisibleCount(PAGE_SIZE);
          }}
        />
        <select
          value={classFilter}
          onChange={(e) => {
            setClassFilter(e.target.value);
            setVisibleCount(PAGE_SIZE);
          }}
        >
          <option value="all">All classes</option>
          {classes.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
        <select
          value={methodFilter}
          onChange={(e) => {
            setMethodFilter(e.target.value);
            setVisibleCount(PAGE_SIZE);
          }}
        >
          <option value="all">All methods</option>
          {methods.map((m) => (
            <option key={m} value={m}>
              {m}
            </option>
          ))}
        </select>
        <span className="muted result-count">
          {filtered.length} of {sightings.length} sightings
        </span>
      </div>

      <div className="table-scroll">
        <table className="sightings-table">
          <thead>
            <tr>
              <SortableHeader label="Player" active={sortKey === "player"} dir={sortDir} onClick={() => toggleSort("player")} />
              <th>Class / Race</th>
              <SortableHeader label="Lvl" active={sortKey === "level"} dir={sortDir} onClick={() => toggleSort("level")} />
              <th>Guild</th>
              <SortableHeader label="Zone" active={sortKey === "zone"} dir={sortDir} onClick={() => toggleSort("zone")} />
              <th>Method</th>
              <SortableHeader label="Seen" active={sortKey === "ts"} dir={sortDir} onClick={() => toggleSort("ts")} />
              <SortableHeader
                label="Corroboration"
                active={sortKey === "reportCount"}
                dir={sortDir}
                onClick={() => toggleSort("reportCount")}
              />
            </tr>
          </thead>
          <tbody>
            {visible.map((s, i) => (
              <SightingRow key={rowKey(s, i)} sighting={s} />
            ))}
          </tbody>
        </table>
        {visible.length === 0 && <div className="empty-state">No sightings match these filters.</div>}
      </div>

      {visibleCount < filtered.length && (
        <button className="btn btn-secondary load-more" onClick={() => setVisibleCount((c) => c + PAGE_SIZE)}>
          Show more ({filtered.length - visibleCount} remaining)
        </button>
      )}
    </div>
  );
}

function rowKey(s: Sighting, i: number): string {
  return s.id !== undefined ? `${s.sourceRealm}/${s.sourceCharacter}#${s.id}` : `${s.player}@${s.ts}@${i}`;
}

function SightingRow({ sighting: s }: { sighting: Sighting }) {
  const via = s.relayed ? ` via ${s.relaySender ?? "?"}` : "";
  const rowColor = s.class ? classColor(s.class) : undefined;
  return (
    <tr>
      <td className="player-cell" style={rowColor ? ({ "--row-color": rowColor } as CSSProperties) : undefined}>
        {s.player}
      </td>
      <td>
        {s.class && (
          <span className="class-dot" style={{ background: classColor(s.class) }} aria-hidden />
        )}
        <span style={{ color: rowColor }}>{s.class ?? "Unknown"}</span>
        {s.race && <span className="muted"> {s.race}</span>}
      </td>
      <td>{s.level ?? "??"}{s.levelIsGuess && s.level ? "*" : ""}</td>
      <td className="muted">{s.guild ?? "—"}</td>
      <td>
        {s.zone}
        {s.subZone ? <span className="muted"> / {s.subZone}</span> : null}
      </td>
      <td className="muted">
        {s.method}
        {via}
      </td>
      <td title={absoluteTime(s.ts)}>{relativeTime(s.ts)}</td>
      <td>
        <CorroborationCell count={s.reportCount} />
      </td>
    </tr>
  );
}

function CorroborationCell({ count }: { count?: number }) {
  if (!count || count <= 1) return <span className="muted">—</span>;
  const pct = Math.min(100, (count / 5) * 100);
  const flagged = count >= 3;
  return (
    <div className="corr-bar-wrap">
      <div className={`corr-bar${flagged ? " flag" : ""}`}>
        <span style={{ width: `${pct}%` }} />
      </div>
      <span className="muted">×{count}</span>
    </div>
  );
}

function SortableHeader({
  label,
  active,
  dir,
  onClick,
}: {
  label: string;
  active: boolean;
  dir: SortDir;
  onClick: () => void;
}) {
  return (
    <th className="sortable" onClick={onClick}>
      {label}
      {active && <span className="sort-arrow">{dir === "asc" ? " ↑" : " ↓"}</span>}
    </th>
  );
}
