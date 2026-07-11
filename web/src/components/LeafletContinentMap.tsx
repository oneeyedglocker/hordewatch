import { useEffect, useRef } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import type { Sighting } from "../lib/types";
import { classColor } from "../lib/classColors";
import { absoluteTime, relativeTime } from "../lib/format";
import { buildTrails } from "../lib/trails";

interface Props {
  imageUrl: string;
  imageWidth: number;
  imageHeight: number;
  points: Sighting[];
  mapName: string;
}

// HereBeDragons doesn't hand back Outland's raw per-ADT world coordinates
// for most real positions: per its own transform table for TBC Classic
// (HordeWatch/Libs/HereBeDragons/HereBeDragons-2.0.lua, the `WoWBC` block),
// most of Outland's raw coordinate space gets bucketed into continentID 0
// or 1 with an offset ADDED to worldX/worldY before the addon ever sees it
// - only a small "leftover" pocket keeps continentID 530 unmodified. The
// affine fit below (OUTLAND_AFFINE) was calibrated directly against
// continentID-530 readings, so 0/1 readings need that offset subtracted
// back out first. Table format matches HBD's own (offsetY, offsetX) order
// for each continentID it can produce for Outland.
const OUTLAND_OFFSETS: Record<number, { offsetX: number; offsetY: number }> = {
  530: { offsetX: 0, offsetY: 0 },
  0: { offsetX: 2662.8, offsetY: -2400 },
  1: { offsetX: 17600, offsetY: 10339.7 },
};

// worldX/worldY -> continent-image-pixel affine transform, empirically
// fit (least squares) against 6 real /hw pos readings at named,
// unambiguous landmarks across 5 different zones - NOT derived from
// wow.export's own stated image corners, which turned out not to line up
// with HereBeDragons' coordinates at all (see DATA_MODEL.md for that dead
// end). Max residual across all 6 points was ~115px on a 16384x12800 image
// (~0.7% of width), consistent with manual pixel-picking error rather than
// a systematic mismatch:
//   Dark Portal (Hellfire Peninsula):    worldX=1021.2, worldY=-68.5   -> pixel (8806, 7398)
//   Honor Hold (Hellfire Peninsula):     worldX=2657.3, worldY=-700.8  -> pixel (7180, 7816)
//   Hand of Gul'dan (Shadowmoon Valley): worldX=1380,   worldY=-3557.5 -> pixel (8229, 10490)
//   Auchindoun (Terokkar Forest):        worldX=4939.2, worldY=-3371   -> pixel (4980, 10364)
//   Oshu'gun (Nagrand):                  worldX=8303.7, worldY=-2575.2 -> pixel (1764, 9640)
//   Serpent Lake (Zangarmarsh):          worldX=6943.7, worldY=554.7   -> pixel (3068, 6624)
// Re-derive by least-squares fitting [worldX, worldY, 1] -> pixel_x and
// -> pixel_y separately if more calibration points are ever collected.
const OUTLAND_AFFINE = {
  ax: -0.952319,
  ay: 0.028558,
  bx: 9724.3204,
  cx: -0.006154,
  cy: -0.930896,
  by: 7240.1066,
};

// Converts a sighting's worldX/worldY (continuous yards, from HereBeDragons -
// see HordeWatch/Position.lua) to a pixel on the continent image via
// OUTLAND_AFFINE, then negates the resulting pixel-Y for CRS.Simple (same
// trick as LeafletZoneMap - Leaflet's y increases upward, image pixels
// increase downward).
function toLatLng(worldX: number, worldY: number, continentID: number): L.LatLngTuple {
  const offset = OUTLAND_OFFSETS[continentID] ?? { offsetX: 0, offsetY: 0 };
  const rawX = worldX - offset.offsetX;
  const rawY = worldY - offset.offsetY;

  const px = OUTLAND_AFFINE.ax * rawX + OUTLAND_AFFINE.ay * rawY + OUTLAND_AFFINE.bx;
  const py = OUTLAND_AFFINE.cx * rawX + OUTLAND_AFFINE.cy * rawY + OUTLAND_AFFINE.by;
  return [-py, px];
}

export function LeafletContinentMap({ imageUrl, imageWidth, imageHeight, points, mapName }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    const bounds: L.LatLngBoundsExpression = [
      [-imageHeight, 0],
      [0, imageWidth],
    ];

    const map = L.map(containerRef.current, {
      crs: L.CRS.Simple,
      // This image is far bigger than a zone tile (16384x12800 vs ~1000px) -
      // fitting it into the map container needs a much lower zoom than
      // LeafletZoneMap's -2. -4 clamped fitBounds before it could reach the
      // actual fit level, rendering the image ~2x too large for its
      // container (and clipping the marker positions nearest its edges).
      minZoom: -7,
      maxZoom: 3,
      // Leaflet's default zoomSnap (1) forces fitBounds() onto the nearest
      // whole zoom level, which is very often well short of what the
      // container can actually fit - the image then renders far smaller
      // than its container with dead space around it. 0 lets fitBounds use
      // a continuous zoom that actually fills the space.
      zoomSnap: 0,
      attributionControl: false,
      // Default SVG renderer bounds are only padded 10% past the current
      // viewport - at this image's scale (16384x12800), markers away from
      // the center can land outside that and render as degenerate empty
      // paths. A much larger padding keeps every marker within the actual
      // image bounds valid regardless of the fitBounds/zoom timing.
      renderer: L.svg({ padding: 10 }),
    });
    L.imageOverlay(imageUrl, bounds).addTo(map);
    map.fitBounds(bounds);
    mapRef.current = map;

    // Leaflet sizes its canvas once at init and never re-checks - if the
    // container is later resized by CSS (e.g. the "expand map" overlay in
    // ZoneMap.tsx), the map would otherwise stay at its original pixel size
    // and zoom, just with empty space around it. invalidateSize() alone only
    // fixes the former, so re-run fitBounds too to rescale to the new size.
    const resizeObserver = new ResizeObserver(() => {
      map.invalidateSize();
      map.fitBounds(bounds);
    });
    resizeObserver.observe(containerRef.current);

    return () => {
      resizeObserver.disconnect();
      map.remove();
      mapRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [imageUrl, imageWidth, imageHeight]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    const ringColor = getComputedStyle(document.documentElement).getPropertyValue("--surface-1").trim() || "#fff";

    const withCoords = points.filter((p) => p.worldX !== undefined && p.worldY !== undefined);

    const markers = withCoords.map((p) => {
      const marker = L.circleMarker(toLatLng(p.worldX!, p.worldY!, p.continentID ?? 530), {
        radius: 5,
        weight: 2,
        color: ringColor,
        fillColor: classColor(p.class),
        fillOpacity: 1,
      });
      marker.bindTooltip(
        `<b>${p.player}</b>${p.class ? ` (${p.class}${p.level ? " " + p.level : ""})` : ""}<br/>${p.zone ?? ""}<br/>${relativeTime(
          p.ts,
        )} &middot; <span title="${absoluteTime(p.ts)}">${p.method}</span>`,
      );
      marker.addTo(map);
      return marker;
    });

    // A trail per player (chronological path across their own sightings) -
    // only drawn when few enough distinct players are in view for it to add
    // clarity instead of spaghetti (see buildTrails). The most recent point
    // in each trail gets a bigger ring so direction ("this is where they
    // were headed") is readable from the dot sizes alone.
    const trailLines: L.Polyline[] = [];
    for (const trail of buildTrails(withCoords)) {
      const latlngs = trail.map((p) => toLatLng(p.worldX!, p.worldY!, p.continentID ?? 530));
      trailLines.push(
        L.polyline(latlngs, { color: ringColor, weight: 2, opacity: 0.55, dashArray: "4,6" }).addTo(map),
      );
      const lastMarker = markers.find((m) => {
        const ll = m.getLatLng();
        const target = latlngs[latlngs.length - 1];
        return ll.lat === target[0] && ll.lng === target[1];
      });
      lastMarker?.setRadius(8);
    }

    return () => {
      for (const m of markers) m.remove();
      for (const t of trailLines) t.remove();
    };
  }, [points, imageWidth, imageHeight]);

  return (
    <div
      ref={containerRef}
      className="leaflet-zone-map"
      role="img"
      aria-label={`Continent map of ${mapName} with sighting locations`}
    />
  );
}
