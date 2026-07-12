import { useEffect, useMemo, useState } from "react";
import { ImportPanel } from "./components/ImportPanel";
import { SightingsTable } from "./components/SightingsTable";
import { ZoneMap } from "./components/ZoneMap";
import { GuildsView } from "./components/GuildsView";
import { OverviewView } from "./components/OverviewView";
import { TrendsView } from "./components/TrendsView";
import { HistoryView } from "./components/HistoryView";
import { RadarLogo } from "./components/RadarLogo";
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

type Tab = "overview" | "table" | "map" | "guilds" | "trends" | "history" | "import";

const PAGE_INFO: Record<Tab, { title: string; subtitle: string }> = {
  overview: { title: "Overview", subtitle: "Activity at a glance across every import" },
  table: { title: "Sightings", subtitle: "Guild-shared PvP intel, most recent first" },
  map: { title: "Zone map", subtitle: "Zone-relative positions at detection time" },
  guilds: { title: "Guilds", subtitle: "Enemy guilds seen, aggregated across all sightings" },
  trends: { title: "Trends", subtitle: "Top zones and classes by time window, plus per-player/guild fingerprints" },
  history: { title: "History", subtitle: "Import log for this browser" },
  import: { title: "Data Import", subtitle: "Bring sightings in from the addon or the offline parser" },
};

function App() {
  const [sightings, setSightings] = useState<Sighting[]>(() => loadSightings());
  const [importHistory, setImportHistory] = useState<ImportEvent[]>(() => loadImportHistory());
  const [tab, setTab] = useState<Tab>(() => (loadSightings().length === 0 ? "import" : "overview"));
  const [subjectKey, setSubjectKey] = useState("");

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

  // Only "imported from" needs to live at the app shell level now - the
  // rest of what used to be here (sightings/players/guilds/date range) is
  // the Overview page's job, not something repeated in every tab's header.
  const characters = useMemo(() => {
    const set = new Set<string>();
    for (const s of sightings) if (s.sourceCharacter) set.add(s.sourceCharacter);
    return Array.from(set).sort();
  }, [sightings]);

  const info = PAGE_INFO[tab];

  return (
    <div className="app-shell">
      <aside className="rail">
        <div className="brand">
          <RadarLogo />
          <b>HordeRadar</b>
        </div>
        <nav className="navlist">
          <button className="navitem" aria-current={tab === "overview"} onClick={() => setTab("overview")}>
            <OverviewIcon />
            Overview
          </button>
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
            <div>{characters.length > 0 ? characters.join(", ") : "unknown character"}</div>
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
        </header>

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
            {tab === "overview" && (
              <OverviewView
                sightings={sightings}
                onSelectSubject={(key) => {
                  setSubjectKey(key);
                  setTab("trends");
                }}
              />
            )}
            {tab === "table" && <SightingsTable sightings={sightings} />}
            {tab === "map" && <ZoneMap sightings={sightings} />}
            {tab === "guilds" && <GuildsView sightings={sightings} />}
            {tab === "trends" && (
              <TrendsView sightings={sightings} subjectKey={subjectKey} onSubjectKeyChange={setSubjectKey} />
            )}
            {tab === "history" && <HistoryView events={importHistory} />}
          </>
        )}
      </main>
    </div>
  );
}

function OverviewIcon() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" aria-hidden>
      <rect x="1.5" y="1.5" width="6" height="6" rx="1" />
      <rect x="8.5" y="1.5" width="6" height="4" rx="1" />
      <rect x="8.5" y="7.5" width="6" height="7" rx="1" />
      <rect x="1.5" y="9.5" width="6" height="5" rx="1" />
    </svg>
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
