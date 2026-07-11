import { useMemo, useState } from "react";
import type { KeyboardEvent } from "react";
import type { Sighting } from "../lib/types";
import { rankGuilds, rankPlayers, type RankedEntry } from "../lib/rankings";

interface Props {
  sightings: Sighting[];
  /** "" | "player:Name" | "guild:Name" */
  value: string;
  onChange: (value: string) => void;
}

// A flat <select> with hundreds of players and dozens of guilds doesn't
// scale (real guild logs run into the hundreds of unique names) - this
// leads with a short "most active" quick-pick list and only searches on
// demand, same pattern as GitHub's repo switcher or Linear's assignee
// picker: ranked defaults first, search narrows from there.
const QUICK_PLAYER_COUNT = 8;
const QUICK_GUILD_COUNT = 5;
const MAX_SEARCH_RESULTS = 25;

function keyFor(entry: RankedEntry): string {
  return `${entry.type}:${entry.name}`;
}

function labelFor(value: string): string {
  return value.slice(value.indexOf(":") + 1);
}

export function SubjectPicker({ sightings, value, onChange }: Props) {
  const [query, setQuery] = useState("");
  const [isOpen, setIsOpen] = useState(false);
  const [highlighted, setHighlighted] = useState(0);

  const players = useMemo(() => rankPlayers(sightings), [sightings]);
  const guilds = useMemo(() => rankGuilds(sightings), [sightings]);

  const results = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) {
      return { guilds: guilds.slice(0, QUICK_GUILD_COUNT), players: players.slice(0, QUICK_PLAYER_COUNT), truncated: false, totalMatches: guilds.length + players.length };
    }
    const matchedGuilds = guilds.filter((g) => g.name.toLowerCase().includes(q));
    const matchedPlayers = players.filter((p) => p.name.toLowerCase().includes(q));
    const totalMatches = matchedGuilds.length + matchedPlayers.length;
    const cappedGuilds = matchedGuilds.slice(0, MAX_SEARCH_RESULTS);
    const cappedPlayers = matchedPlayers.slice(0, Math.max(0, MAX_SEARCH_RESULTS - cappedGuilds.length));
    return { guilds: cappedGuilds, players: cappedPlayers, truncated: totalMatches > cappedGuilds.length + cappedPlayers.length, totalMatches };
  }, [query, guilds, players]);

  const flatResults = useMemo(() => [...results.guilds, ...results.players], [results]);

  function select(entry: RankedEntry) {
    onChange(keyFor(entry));
    setQuery("");
    setIsOpen(false);
  }

  function handleKeyDown(e: KeyboardEvent<HTMLInputElement>) {
    if (!isOpen) return;
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setHighlighted((h) => Math.min(h + 1, flatResults.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setHighlighted((h) => Math.max(h - 1, 0));
    } else if (e.key === "Enter") {
      e.preventDefault();
      const entry = flatResults[highlighted];
      if (entry) select(entry);
    } else if (e.key === "Escape") {
      setIsOpen(false);
    }
  }

  if (value) {
    return (
      <div className="subject-picker">
        <span className="subject-picker-chip">
          {labelFor(value)}
          <button className="subject-picker-chip-clear" onClick={() => onChange("")} aria-label="Change player or guild">
            &times;
          </button>
        </span>
      </div>
    );
  }

  return (
    <div className="subject-picker">
      <input
        type="text"
        className="text-input"
        placeholder="Search a player or guild..."
        value={query}
        onChange={(e) => {
          setQuery(e.target.value);
          setHighlighted(0);
        }}
        onFocus={() => setIsOpen(true)}
        onBlur={() => setIsOpen(false)}
        onKeyDown={handleKeyDown}
        role="combobox"
        aria-expanded={isOpen}
        aria-autocomplete="list"
      />
      {isOpen && (
        <div className="subject-picker-dropdown" role="listbox">
          {flatResults.length === 0 ? (
            <div className="subject-picker-empty muted">No player or guild matches &quot;{query}&quot;.</div>
          ) : (
            <>
              {results.guilds.length > 0 && (
                <div className="subject-picker-group-label">{query ? "Guilds" : "Most active guilds"}</div>
              )}
              {results.guilds.map((g) => {
                const idx = flatResults.indexOf(g);
                return (
                  <button
                    key={keyFor(g)}
                    className="subject-picker-option"
                    aria-selected={highlighted === idx}
                    onMouseDown={(e) => e.preventDefault()}
                    onMouseEnter={() => setHighlighted(idx)}
                    onClick={() => select(g)}
                  >
                    <span>{g.name}</span>
                    <span className="subject-picker-count">{g.count}</span>
                  </button>
                );
              })}
              {results.players.length > 0 && (
                <div className="subject-picker-group-label">{query ? "Players" : "Most active players"}</div>
              )}
              {results.players.map((p) => {
                const idx = flatResults.indexOf(p);
                return (
                  <button
                    key={keyFor(p)}
                    className="subject-picker-option"
                    aria-selected={highlighted === idx}
                    onMouseDown={(e) => e.preventDefault()}
                    onMouseEnter={() => setHighlighted(idx)}
                    onClick={() => select(p)}
                  >
                    <span>{p.name}</span>
                    <span className="subject-picker-count">{p.count}</span>
                  </button>
                );
              })}
              {results.truncated && (
                <div className="subject-picker-more muted">
                  Showing top {flatResults.length} of {results.totalMatches} matches - keep typing to narrow.
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}
