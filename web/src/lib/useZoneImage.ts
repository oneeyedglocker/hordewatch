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
const EXTENSIONS = ["jpg", "png"];

function tryLoad(url: string): Promise<{ url: string; width: number; height: number }> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve({ url: img.src, width: img.naturalWidth, height: img.naturalHeight });
    img.onerror = () => reject();
    img.src = url;
  });
}

export function useZoneImage(mapID: number | undefined): ZoneImageState {
  const [state, setState] = useState<ZoneImageState>({ status: "loading" });

  useEffect(() => {
    if (mapID === undefined) {
      setState({ status: "missing" });
      return;
    }

    let cancelled = false;
    setState({ status: "loading" });

    (async () => {
      for (const ext of EXTENSIONS) {
        try {
          const found = await tryLoad(`${import.meta.env.BASE_URL}maps/${mapID}.${ext}`);
          if (!cancelled) setState({ status: "found", ...found });
          return;
        } catch {
          // try the next extension
        }
      }
      if (!cancelled) setState({ status: "missing" });
    })();

    return () => {
      cancelled = true;
    };
  }, [mapID]);

  return state;
}
