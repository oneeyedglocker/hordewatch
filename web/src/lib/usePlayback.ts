import { useCallback, useEffect, useRef, useState } from "react";

export interface PlaybackSpeed {
  label: string;
  /** How long a full sweep from start to end takes at this speed, in real
   * seconds - not a raw multiplier, since "20x" is meaningless without
   * knowing the span, whereas "sweeps the whole range in ~30s" isn't. */
  durationSec: number;
}

export const PLAYBACK_SPEEDS: PlaybackSpeed[] = [
  { label: "Slow", durationSec: 60 },
  { label: "Normal", durationSec: 30 },
  { label: "Fast", durationSec: 12 },
];

// Throttles how often the playhead actually reaches React state (and
// therefore how often the map's marker layer gets torn down and rebuilt) -
// the animation loop itself still runs every frame for smooth timing, but
// committing at 60fps would rebuild every circle marker on the map 60
// times a second for no visible benefit on a multi-day sweep.
const COMMIT_INTERVAL_MS = 150;

// The window of sightings shown around the playhead at any instant - a
// fraction of the selected range (bounded so a short range still gets a
// usable trail and a long one doesn't drown in months of stale dots).
const TRAIL_WINDOW_FLOOR_SEC = 15 * 60;
const TRAIL_WINDOW_FRACTION = 0.05;

export function trailWindowFor(start: number, end: number): number {
  return Math.max(TRAIL_WINDOW_FLOOR_SEC, (end - start) * TRAIL_WINDOW_FRACTION);
}

/** Drives a "watch it happen over time" playhead across [start, end] -
 * play/pause/seek plus the sweep animation itself. `active` tracks whether
 * the caller should be filtering the map down to a trailing window around
 * `playhead` at all; it only turns on from an explicit play/seek, never
 * just because the outer [start, end] range moved (so narrowing the range
 * slider doesn't unexpectedly drop you into playback mode). */
export function usePlayback(start: number, end: number) {
  const [active, setActive] = useState(false);
  const [playing, setPlaying] = useState(false);
  const [speedIdx, setSpeedIdx] = useState(1);
  const [playhead, setPlayheadState] = useState(start);

  const rafRef = useRef<number | null>(null);
  const lastFrameRef = useRef<number | null>(null);
  const lastCommitRef = useRef(0);
  const internalRef = useRef(start);

  // A new [start, end] (the user dragged the outer time-range slider)
  // invalidates whatever playhead position we had.
  useEffect(() => {
    internalRef.current = start;
    setPlayheadState(start);
    setPlaying(false);
  }, [start, end]);

  useEffect(() => {
    if (!playing) {
      lastFrameRef.current = null;
      return;
    }
    const span = Math.max(1, end - start);
    const durationSec = PLAYBACK_SPEEDS[speedIdx].durationSec;
    const ratePerMs = span / (durationSec * 1000);

    function tick(now: number) {
      if (lastFrameRef.current === null) lastFrameRef.current = now;
      const dt = now - lastFrameRef.current;
      lastFrameRef.current = now;
      internalRef.current = Math.min(end, internalRef.current + dt * ratePerMs);
      const reachedEnd = internalRef.current >= end;
      if (reachedEnd || now - lastCommitRef.current >= COMMIT_INTERVAL_MS) {
        lastCommitRef.current = now;
        setPlayheadState(internalRef.current);
      }
      if (reachedEnd) {
        setPlaying(false);
        return;
      }
      rafRef.current = requestAnimationFrame(tick);
    }
    rafRef.current = requestAnimationFrame(tick);
    return () => {
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
    };
  }, [playing, start, end, speedIdx]);

  const play = useCallback(() => {
    setActive(true);
    if (internalRef.current >= end) {
      internalRef.current = start;
      setPlayheadState(start);
    }
    setPlaying(true);
  }, [start, end]);

  const pause = useCallback(() => setPlaying(false), []);

  const seek = useCallback((ts: number) => {
    setActive(true);
    setPlaying(false);
    internalRef.current = ts;
    setPlayheadState(ts);
  }, []);

  const showFullRange = useCallback(() => {
    setActive(false);
    setPlaying(false);
  }, []);

  return { active, playing, playhead, speedIdx, setSpeedIdx, play, pause, seek, showFullRange };
}
