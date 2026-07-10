import { useEffect, useState } from "react";

export type ZoneImageState =
  | { status: "loading" }
  | { status: "missing" }
  | { status: "found"; url: string; width: number; height: number };

/** Real zone map art isn't shipped with this project (Blizzard's own IP -
 * see DATA_MODEL.md gap #2) - instead we look for a locally-supplied image
 * at build/deploy time, named by mapID (the addon's stable per-zone join
 * key, unlike zone name which can collide). See web/public/maps/README.md
 * for how to produce one. Falls back to "missing" so callers can render a
 * placeholder instead. */
export function useZoneImage(mapID: number | undefined): ZoneImageState {
  const [state, setState] = useState<ZoneImageState>({ status: "loading" });

  useEffect(() => {
    if (mapID === undefined) {
      setState({ status: "missing" });
      return;
    }

    let cancelled = false;
    setState({ status: "loading" });

    const img = new Image();
    img.onload = () => {
      if (!cancelled) setState({ status: "found", url: img.src, width: img.naturalWidth, height: img.naturalHeight });
    };
    img.onerror = () => {
      if (!cancelled) setState({ status: "missing" });
    };
    img.src = `${import.meta.env.BASE_URL}maps/${mapID}.jpg`;

    return () => {
      cancelled = true;
    };
  }, [mapID]);

  return state;
}
