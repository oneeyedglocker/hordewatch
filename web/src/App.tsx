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

  return (
    <div className="app-shell">
      <header className="app-header">
        <h1>HordeWatch</h1>
        <p className="muted">PvP intel dashboard, imported from the HordeWatch WoW addon</p>
      </header>

      <ImportPanel onImport={handleImport} />

      {sightings.length === 0 ? (
        <div className="empty-state big">
          No sightings imported yet. Use <code>/hw export</code> in-game and paste the string above, or
          upload a JSON file from the offline parser.
        </div>
      ) : (
        <>
          <section className="stat-bar">
            <Stat label="Sightings" value={stats.total} />
            <Stat label="Unique players" value={stats.players} />
            <Stat label="Guilds seen" value={stats.guilds} />
            <Stat label="Date range" value={stats.range} />
            <button className="btn btn-secondary clear-btn" onClick={handleClear}>
              Clear data
            </button>
          </section>

          <nav className="tabs">
            <button className={`tab ${tab === "table" ? "active" : ""}`} onClick={() => setTab("table")}>
              Table
            </button>
            <button className={`tab ${tab === "map" ? "active" : ""}`} onClick={() => setTab("map")}>
              Zone map
            </button>
          </nav>

          <main className="app-main">
            {tab === "table" ? <SightingsTable sightings={sightings} /> : <ZoneMap sightings={sightings} />}
          </main>
        </>
      )}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="stat-tile">
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
    </div>
  );
}

export default App;
