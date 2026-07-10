import { useEffect, useState } from "react";

/** World-yard corners of the continent image, as reported by wow.export's
 * own tile-composite metadata (see web/public/maps/README.md - "Continent
 * map images"). Lets us convert a sighting's worldX/worldY (continuous
 * yards, from HereBeDragons - see HordeWatch/Position.lua) straight to a
 * pixel on the image, with no calibration guesswork. */
export interface ContinentCorners {
  top_left: { world_x: number; world_y: number };
  bottom_right: { world_x: number; world_y: number };
}

export interface ContinentMeta {
  mapID: number;
  mapName: string;
  imageWidth: number;
  imageHeight: number;
  corners: ContinentCorners;
}

export type ContinentImageState =
  | { status: "loading" }
  | { status: "missing" }
  | { status: "found"; url: string; meta: ContinentMeta };

function tryLoad(url: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve();
    img.onerror = () => reject();
    img.src = url;
  });
}

/** Same "look for it on disk" model as useZoneImage, but a continent image
 * additionally needs its <mapID>.json coordinate-mapping sidecar - both
 * must be present. */
export function useContinentImage(mapID: number | undefined): ContinentImageState {
  const [state, setState] = useState<ContinentImageState>({ status: "loading" });

  useEffect(() => {
    if (mapID === undefined) {
      setState({ status: "missing" });
      return;
    }

    let cancelled = false;
    setState({ status: "loading" });

    (async () => {
      const base = `${import.meta.env.BASE_URL}maps/${mapID}`;
      for (const ext of ["jpg", "png"]) {
        try {
          const url = `${base}.${ext}`;
          const metaRes = await fetch(`${base}.json`);
          if (!metaRes.ok) throw new Error("no metadata sidecar");
          const meta = (await metaRes.json()) as ContinentMeta;
          await tryLoad(url);
          if (!cancelled) setState({ status: "found", url, meta });
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
