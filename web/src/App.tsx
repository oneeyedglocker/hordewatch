import { useEffect, useMemo, useState } from "react";
import { ImportPanel } from "./components/ImportPanel";
import { SightingsTable } from "./components/SightingsTable";
import { ZoneMap } from "./components/ZoneMap";
import { loadSightings, mergeSightings, saveSightings, clearSightings } from "./lib/store";
import type { Sighting } from "./lib/types";
import "./App.css";

type Tab = "table" | "map";

function App() {
  const [sightings, setSightings] = useState<Sighting[]>(() => loadSightings());
  const [tab, setTab] = useState<Tab>("table");

  useEffect(() => {
    saveSightings(sightings);
  }, [sightings]);

  function handleImport(incoming: Sighting[]) {
    setSightings((prev) => mergeSightings(prev, incoming));
  }

  function handleClear() {
    if (!confirm("Clear all imported sightings from this browser? This can't be undone.")) return;
    clearSightings();
    setSightings([]);
  }

  const stats = useMemo(() => {
    const players = new Set<string>();
    const guilds = new Set<string>();
    const characters = new Set<string>();
    let minTs = Infinity;
    let maxTs = -Infinity;
    for (const s of sightings) {
      players.add(s.player);
      if (s.guild) guilds.add(s.guild);
      if (s.sourceCharacter) characters.add(s.sourceCharacter);
      if (s.ts < minTs) minTs = s.ts;
      if (s.ts > maxTs) maxTs = s.ts;
    }
    return {
      total: sightings.length,
      players: players.size,
      guilds: guilds.size,
      characters: Array.from(characters).sort(),
      range:
        sightings.length > 0
          ? `${new Date(minTs * 1000).toLocaleDateString()} - ${new Date(maxTs * 1000).toLocaleDateString()}`
          : "-",
    };
  }, [sightings]);

  return (
    <div className="app-shell">
      <aside className="rail">
        <div className="brand">
          <span className="mark" aria-hidden />
          <b>HordeWatch</b>
        </div>
        <nav className="navlist">
          <button className="navitem" aria-current={tab === "table"} onClick={() => setTab("table")}>
            <TableIcon />
            Sightings
          </button>
          <button className="navitem" aria-current={tab === "map"} onClick={() => setTab("map")}>
            <MapIcon />
            Zone map
          </button>
        </nav>
        {sightings.length > 0 && (
          <div className="rail-foot">
            <div className="rail-foot-label">Imported from</div>
            <div>{stats.characters.length > 0 ? stats.characters.join(", ") : "unknown character"}</div>
            <button className="rail-clear" onClick={handleClear}>
              Clear data
            </button>
          </div>
        )}
      </aside>

      <main className="main">
        <header className="pageheader">
          <div>
            <h1>{tab === "table" ? "Sightings" : "Zone map"}</h1>
            <p className="muted">
              {tab === "table" ? "Guild-shared PvP intel, most recent first" : "Zone-relative positions at detection time"}
            </p>
          </div>
          {sightings.length > 0 && <span className="range-pill">{stats.range}</span>}
        </header>

        <ImportPanel onImport={handleImport} />

        {sightings.length === 0 ? (
          <div className="empty-state big">
            No sightings imported yet. Use <code>/hw export</code> in-game and paste the string above, or
            upload a JSON file from the offline parser.
          </div>
        ) : (
          <>
            <section className="stat-row">
              <Stat label="Sightings" value={stats.total} />
              <Stat label="Unique players" value={stats.players} />
              <Stat label="Guilds seen" value={stats.guilds} />
              <Stat label="Date range" value={stats.range} />
            </section>

            {tab === "table" ? <SightingsTable sightings={sightings} /> : <ZoneMap sightings={sightings} />}
          </>
        )}
      </main>
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

function TableIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" aria-hidden>
      <rect x="1.5" y="2.5" width="13" height="11" rx="1.5" />
      <line x1="1.5" y1="6.5" x2="14.5" y2="6.5" />
      <line x1="6" y1="6.5" x2="6" y2="13.5" />
    </svg>
  );
}

function MapIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" aria-hidden>
      <path d="M5.5 2.5 1.5 4v9.5l4-1.5 5 1.5 4-1.5V4l-4 1.5-5-1.5Z" />
      <line x1="5.5" y1="2.5" x2="5.5" y2="12" />
      <line x1="10.5" y1="4" x2="10.5" y2="13.5" />
    </svg>
  );
}

export default App;
