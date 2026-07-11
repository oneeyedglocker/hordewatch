import { absoluteTime } from "../lib/format";

interface Props {
  min: number;
  max: number;
  start: number;
  end: number;
  onChange: (start: number, end: number) => void;
}

// Classic "two overlapping range inputs" dual-handle slider - no extra
// dependency needed for a real draggable range control. Each <input>'s own
// track is made invisible/click-through via CSS (App.css), leaving just the
// two thumbs grabbable, both sharing the same underlying min/max/track.
export function TimeRangeSlider({ min, max, start, end, onChange }: Props) {
  if (min >= max) return null;

  return (
    <div className="time-range-slider">
      <div className="time-range-track">
        <input
          type="range"
          min={min}
          max={max}
          value={start}
          onChange={(e) => onChange(Math.min(Number(e.target.value), end), end)}
        />
        <input
          type="range"
          min={min}
          max={max}
          value={end}
          onChange={(e) => onChange(start, Math.max(Number(e.target.value), start))}
        />
      </div>
      <div className="time-range-labels">
        <span>{absoluteTime(start)}</span>
        <span>{absoluteTime(end)}</span>
      </div>
    </div>
  );
}
