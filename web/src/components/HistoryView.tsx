import type { ImportEvent } from "../lib/types";
import { absoluteTime, relativeTime } from "../lib/format";

interface Props {
  events: ImportEvent[];
}

export function HistoryView({ events }: Props) {
  if (events.length === 0) {
    return <div className="empty-state">No imports recorded yet in this browser.</div>;
  }

  return (
    <div className="table-view">
      <div className="table-scroll">
        <table className="sightings-table">
          <thead>
            <tr>
              <th>When</th>
              <th>Source</th>
              <th>Rows in import</th>
              <th>New rows</th>
            </tr>
          </thead>
          <tbody>
            {events.map((e) => (
              <tr key={e.id}>
                <td title={absoluteTime(e.at)}>{relativeTime(e.at)}</td>
                <td>
                  {e.label} <span className="muted">({e.source === "string" ? "export string" : "JSON file"})</span>
                </td>
                <td>{e.count}</td>
                <td>{e.newCount}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
