import { useMemo, useState } from "react";
import type { Sighting } from "../lib/types";
import { relativeTime, absoluteTime } from "../lib/format";

interface Props {
  sightings: Sighting[];
}

interface GuildStat {
  guild: string;
  members: Set<string>;
  zones: Set<string>;
  sightingCount: number;
  lastSeen: number;
}

export function GuildsView({ sightings }: Props) {
  const [search, setSearch] = useState("");

  const guilds = useMemo(() => {
    const byGuild = new Map<string, GuildStat>();
    for (const s of sightings) {
      if (!s.guild) continue;
      let g = byGuild.get(s.guild);
      if (!g) {
        g = { guild: s.guild, members: new Set(), zones: new Set(), sightingCount: 0, lastSeen: 0 };
        byGuild.set(s.guild, g);
      }
      g.members.add(s.player);
      g.zones.add(s.zone);
      g.sightingCount++;
      if (s.ts > g.lastSeen) g.lastSeen = s.ts;
    }
    return Array.from(byGuild.values()).sort((a, b) => b.lastSeen - a.lastSeen);
  }, [sightings]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return guilds;
    return guilds.filter((g) => g.guild.toLowerCase().includes(q));
  }, [guilds, search]);

  if (guilds.length === 0) {
    return (
      <div className="empty-state">
        No sightings have a known guild yet - guild tags only come through on directly targeted, moused-over, or
        nameplate detections.
      </div>
    );
  }

  return (
    <div className="table-view">
      <div className="table-controls">
        <input
          className="text-input"
          placeholder="Search guilds..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <span className="muted result-count">
          {filtered.length} of {guilds.length} guilds
        </span>
      </div>

      <div className="table-scroll">
        <table className="sightings-table">
          <thead>
            <tr>
              <th>Guild</th>
              <th>Members seen</th>
              <th>Sightings</th>
              <th>Zones</th>
              <th>Last seen</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((g) => (
              <tr key={g.guild}>
                <td className="player-cell">{g.guild}</td>
                <td>{g.members.size}</td>
                <td>{g.sightingCount}</td>
                <td className="muted">{Array.from(g.zones).sort().join(", ")}</td>
                <td title={absoluteTime(g.lastSeen)}>{relativeTime(g.lastSeen)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
