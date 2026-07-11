import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";

interface Props {
  /** Already scoped to the active zone (or continent-eligible pool) AND the
   * current time window - NOT further filtered by nameFilter/guildFilter,
   * since that's exactly what this list controls. This is what makes the
   * list only ever offer players/guilds that actually have a sighting here
   * right now, instead of every player/guild that exists anywhere. */
  sightings: Sighting[];
  nameFilter: string;
  onNameFilterChange: (value: string) => void;
  guildFilter: string;
  onGuildFilterChange: (value: string) => void;
}

interface Row {
  name: string;
  count: number;
}

function tally(sightings: Sighting[], keyFn: (s: Sighting) => string | undefined): Row[] {
  const counts = new Map<string, number>();
  for (const s of sightings) {
    const key = keyFn(s);
    if (!key) continue;
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
}

export function PresenceList({ sightings, nameFilter, onNameFilterChange, guildFilter, onGuildFilterChange }: Props) {
  const [tab, setTab] = useState<"players" | "guilds">("players");
  const [guildSearch, setGuildSearch] = useState("");

  // Picking a guild narrows the Players tab to that guild's own roster
  // (drill-down) - the natural direction is browse-a-guild-then-a-member.
  // The Guilds tab intentionally stays independent of any player pick, so
  // it's always the "start over" browsing dimension.
  const playerPool = useMemo(
    () => (guildFilter ? sightings.filter((s) => s.guild === guildFilter) : sightings),
    [sightings, guildFilter],
  );
  const players = useMemo(() => tally(playerPool, (s) => s.player), [playerPool]);
  const guilds = useMemo(() => tally(sightings, (s) => s.guild), [sightings]);

  const nameQuery = nameFilter.trim().toLowerCase();
  const visiblePlayers = nameQuery ? players.filter((p) => p.name.toLowerCase().includes(nameQuery)) : players;
  const guildQuery = guildSearch.trim().toLowerCase();
  const visibleGuilds = guildQuery ? guilds.filter((g) => g.name.toLowerCase().includes(guildQuery)) : guilds;

  return (
    <div className="presence-panel">
      <div className="view-toggle presence-tabs">
        <button className="view-toggle-btn" aria-current={tab === "players"} onClick={() => setTab("players")}>
          Players ({players.length})
        </button>
        <button className="view-toggle-btn" aria-current={tab === "guilds"} onClick={() => setTab("guilds")}>
          Guilds ({guilds.length})
        </button>
      </div>

      {tab === "players" ? (
        <>
          <input
            type="text"
            className="text-input presence-search"
            placeholder="Search players..."
            value={nameFilter}
            onChange={(e) => onNameFilterChange(e.target.value)}
          />
          <div className="presence-list">
            {visiblePlayers.length === 0 ? (
              <p className="muted presence-empty">No players here{guildFilter ? " for this guild" : ""}.</p>
            ) : (
              visiblePlayers.map((p) => (
                <button
                  key={p.name}
                  className="presence-row"
                  aria-current={p.name === nameFilter}
                  onClick={() => onNameFilterChange(p.name === nameFilter ? "" : p.name)}
                >
                  <span>{p.name}</span>
                  <span className="presence-count">{p.count}</span>
                </button>
              ))
            )}
          </div>
        </>
      ) : (
        <>
          <input
            type="text"
            className="text-input presence-search"
            placeholder="Search guilds..."
            value={guildSearch}
            onChange={(e) => setGuildSearch(e.target.value)}
          />
          <div className="presence-list">
            {visibleGuilds.length === 0 ? (
              <p className="muted presence-empty">No guild-tagged sightings here.</p>
            ) : (
              visibleGuilds.map((g) => (
                <button
                  key={g.name}
                  className="presence-row"
                  aria-current={g.name === guildFilter}
                  onClick={() => onGuildFilterChange(g.name === guildFilter ? "" : g.name)}
                >
                  <span>{g.name}</span>
                  <span className="presence-count">{g.count}</span>
                </button>
              ))
            )}
          </div>
        </>
      )}
    </div>
  );
}
