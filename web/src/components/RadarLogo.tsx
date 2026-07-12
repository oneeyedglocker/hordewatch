interface Props {
  size?: number;
}

// The HordeRadar mark: range rings + a sweep beam (the "scanning" idea the
// name is built on) with two contact blips in the app's existing --flag red
// - reusing that var rather than a new one-off hex keeps it consistent with
// every other "this needs attention" use of red elsewhere in the app. Pure
// CSS custom properties, so it re-themes for light/dark automatically
// wherever it's rendered inline (unlike public/favicon.svg, which is a
// separate document the page's stylesheet can't reach into).
export function RadarLogo({ size = 20 }: Props) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden>
      <defs>
        <linearGradient id="radarSweep" x1="16" y1="16" x2="23" y2="4" gradientUnits="userSpaceOnUse">
          <stop offset="0" stopColor="var(--accent)" stopOpacity="0.85" />
          <stop offset="1" stopColor="var(--accent)" stopOpacity="0" />
        </linearGradient>
      </defs>
      <circle cx="16" cy="16" r="14" fill="var(--accent)" opacity="0.1" />
      <path d="M16 16 L16 2 A14 14 0 0 1 28.1 9 Z" fill="url(#radarSweep)" />
      <circle cx="16" cy="16" r="14" stroke="var(--accent)" strokeWidth="1.6" />
      <circle cx="16" cy="16" r="9.5" stroke="var(--accent)" strokeWidth="1.2" opacity="0.55" />
      <circle cx="16" cy="16" r="5" stroke="var(--accent)" strokeWidth="1" opacity="0.4" />
      <circle cx="16" cy="16" r="1.7" fill="var(--accent)" />
      <circle cx="21.5" cy="10.5" r="1.8" fill="var(--flag)" />
      <circle cx="9.5" cy="20.5" r="1.3" fill="var(--flag)" opacity="0.85" />
    </svg>
  );
}
