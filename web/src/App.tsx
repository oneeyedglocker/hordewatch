import { useEffect, useMemo, useState } from "react";
import { ImportPanel } from "./components/ImportPanel";
import { SightingsTable } from "./components/SightingsTable";
import { ZoneMap } from "./components/ZoneMap";
import { GuildsView } from "./components/GuildsView";
import { TrendsView } from "./components/TrendsView";
import { HistoryView } from "./components/HistoryView";
import {
  loadSightings,
  mergeSightings,
  saveSightings,
  clearSightings,
  loadImportHistory,
  saveImportHistory,
} from "./lib/store";
import type { ImportEvent, Sighting } from "./lib/types";
import "./App.css";

type Tab = "table" | "map" | "guilds" | "trends" | "history" | "import";

const PAGE_INFO: Record<Tab, { title: string; subtitle: string }> = {
  table: { title: "Sightings", subtitle: "Guild-shared PvP intel, most recent first" },
  map: { title: "Zone map", subtitle: "Zone-relative positions at detection time" },
  guilds: { title: "Guilds", subtitle: "Enemy guilds seen, aggregated across all sightings" },
  trends: { title: "Trends", subtitle: "Activity over time, top zones, top classes" },
  history: { title: "History", subtitle: "Import log for this browser" },
  import: { title: "Data Import", subtitle: "Bring sightings in from the addon or the offline parser" },
};

function App() {
  const [sightings, setSightings] = useState<Sighting[]>(() => loadSightings());
  const [importHistory, setImportHistory] = useState<ImportEvent[]>(() => loadImportHistory());
  const [tab, setTab] = useState<Tab>(() => (loadSightings().length === 0 ? "import" : "table"));

  useEffect(() => {
    saveSightings(sightings);
  }, [sightings]);

  useEffect(() => {
    saveImportHistory(importHistory);
  }, [importHistory]);

  function handleImport(incoming: Sighting[], label: string, source: "string" | "json") {
    setSightings((prev) => {
      const { merged, newCount } = mergeSightings(prev, incoming);
      setImportHistory((h) => [
        {
          id: `${Date.now()}-${h.length}`,
          at: Math.floor(Date.now() / 1000),
          source,
          label,
          count: incoming.length,
          newCount,
        },
        ...h,
      ]);
      return merged;
    });
  }

  function handleClear() {
    if (!confirm("Clear all imported sightings and import history from this browser? This can't be undone.")) return;
    clearSightings();
    setSightings([]);
    setImportHistory([]);
    setTab("import");
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

  const showStats = sightings.length > 0 && (tab === "table" || tab === "map" || tab === "guilds" || tab === "trends");
  const info = PAGE_INFO[tab];

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
          <button className="navitem" aria-current={tab === "guilds"} onClick={() => setTab("guilds")}>
            <GuildIcon />
            Guilds
          </button>
          <button className="navitem" aria-current={tab === "trends"} onClick={() => setTab("trends")}>
            <TrendsIcon />
            Trends
          </button>
          <button className="navitem" aria-current={tab === "history"} onClick={() => setTab("history")}>
            <HistoryIcon />
            History
          </button>
          <div className="nav-divider" />
          <button className="navitem" aria-current={tab === "import"} onClick={() => setTab("import")}>
            <ImportIcon />
            Data Import
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
            <h1>{info.title}</h1>
            <p className="muted">{info.subtitle}</p>
          </div>
          {showStats && <span className="range-pill">{stats.range}</span>}
        </header>

        {showStats && (
          <section className="stat-row">
            <Stat label="Sightings" value={stats.total} />
            <Stat label="Unique players" value={stats.players} />
            <Stat label="Guilds seen" value={stats.guilds} />
            <Stat label="Date range" value={stats.range} />
          </section>
        )}

        {tab === "import" && <ImportPanel onImport={handleImport} />}

        {tab !== "import" && sightings.length === 0 ? (
          <div className="empty-state big">
            No sightings imported yet.{" "}
            <button className="link-btn" onClick={() => setTab("import")}>
              Go to Data Import
            </button>{" "}
            to paste a <code>/hw export</code> string or upload a JSON file from the offline parser.
          </div>
        ) : (
          <>
            {tab === "table" && <SightingsTable sightings={sightings} />}
            {tab === "map" && <ZoneMap sightings={sightings} />}
            {tab === "guilds" && <GuildsView sightings={sightings} />}
            {tab === "trends" && <TrendsView sightings={sightings} />}
            {tab === "history" && <HistoryView events={importHistory} />}
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

function GuildIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" aria-hidden>
      <circle cx="8" cy="5.5" r="2.5" />
      <path d="M2.5 14c0-3 2.5-4.5 5.5-4.5s5.5 1.5 5.5 4.5" />
    </svg>
  );
}

function TrendsIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" aria-hidden>
      <path d="M2 12.5 6 8l3 2.5 4.5-5" />
      <path d="M10.5 5.5H13.5V8.5" />
    </svg>
  );
}

function HistoryIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" aria-hidden>
      <circle cx="8" cy="8" r="6" />
      <path d="M8 4.5v4l2.5 1.5" />
    </svg>
  );
}

function ImportIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" aria-hidden>
      <path d="M8 2.5v6.5" />
      <path d="M5.2 6.2 8 9l2.8-2.8" />
      <path d="M2.5 11v2a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1v-2" />
    </svg>
  );
}

export default App;
