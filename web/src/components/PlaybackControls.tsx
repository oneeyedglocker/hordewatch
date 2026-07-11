import { absoluteTime } from "../lib/format";
import { PLAYBACK_SPEEDS } from "../lib/usePlayback";

interface Props {
  start: number;
  end: number;
  playhead: number;
  playing: boolean;
  active: boolean;
  speedIdx: number;
  onPlay: () => void;
  onPause: () => void;
  onSeek: (ts: number) => void;
  onSpeedChange: (idx: number) => void;
  onShowFullRange: () => void;
}

export function PlaybackControls({
  start,
  end,
  playhead,
  playing,
  active,
  speedIdx,
  onPlay,
  onPause,
  onSeek,
  onSpeedChange,
  onShowFullRange,
}: Props) {
  if (end <= start) return null;
  const pct = Math.min(100, Math.max(0, ((playhead - start) / (end - start)) * 100));

  return (
    <div className="playback-controls">
      <button
        className="playback-btn"
        onClick={playing ? onPause : onPlay}
        aria-label={playing ? "Pause playback" : "Play sightings over time"}
      >
        {playing ? "⏸" : "▶"}
      </button>
      <select value={speedIdx} onChange={(e) => onSpeedChange(Number(e.target.value))} aria-label="Playback speed">
        {PLAYBACK_SPEEDS.map((s, i) => (
          <option key={s.label} value={i}>
            {s.label}
          </option>
        ))}
      </select>
      <div className="playback-track">
        <input
          type="range"
          className="playback-scrubber"
          style={{ "--pct": `${pct}%` } as React.CSSProperties}
          min={start}
          max={end}
          step={1}
          value={Math.round(playhead)}
          onChange={(e) => onSeek(Number(e.target.value))}
          aria-label="Playback position"
        />
      </div>
      <span className="playback-time muted">{absoluteTime(Math.round(playhead))}</span>
      {active && (
        <button className="playback-exit" onClick={onShowFullRange}>
          Show full range
        </button>
      )}
    </div>
  );
}
