export function relativeTime(ts: number, now: number = Date.now() / 1000): string {
  const diff = Math.max(0, Math.floor(now - ts));
  if (diff < 60) return "just now";
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 86400 * 30) return `${Math.floor(diff / 86400)}d ago`;
  return new Date(ts * 1000).toLocaleDateString();
}

export function absoluteTime(ts: number): string {
  return new Date(ts * 1000).toLocaleString();
}
