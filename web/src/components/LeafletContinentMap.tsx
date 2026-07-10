import { useEffect, useRef } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import type { Sighting } from "../lib/types";
import type { ContinentCorners } from "../lib/useContinentImage";
import { classColor } from "../lib/classColors";
import { absoluteTime, relativeTime } from "../lib/format";

interface Props {
  imageUrl: string;
  imageWidth: number;
  imageHeight: number;
  corners: ContinentCorners;
  points: Sighting[];
  mapName: string;
}

// wow.export's corners describe Outland's RAW per-ADT world coordinates
// (continentID 530's native frame, straight from Blizzard's map data).
// HereBeDragons doesn't hand back that raw frame for most real positions,
// though: per its own transform table for TBC Classic
// (HordeWatch/Libs/HereBeDragons/HereBeDragons-2.0.lua, the `WoWBC` block),
// most of Outland's raw coordinate space gets bucketed into continentID 0
// or 1 with an offset ADDED to worldX/worldY before the addon ever sees it
// - only a small "leftover" pocket keeps continentID 530 unmodified. To
// plot correctly against wow.export's raw-frame image, that offset has to
// be subtracted back out first. Table format matches HBD's own
// (offsetY, offsetX) order for each continentID it can produce for
// Outland.
const OUTLAND_OFFSETS: Record<number, { offsetX: number; offsetY: number }> = {
  530: { offsetX: 0, offsetY: 0 },
  0: { offsetX: 2662.8, offsetY: -2400 },
  1: { offsetX: 17600, offsetY: 10339.7 },
};

// Converts a sighting's worldX/worldY (continuous yards, from HereBeDragons -
// see HordeWatch/Position.lua) to a pixel on the continent image, using the
// exact world-space corners wow.export reported for that image (see
// web/public/maps/README.md - "Continent map images"). Note the axis
// swap: WoW's world X is north/south and Y is east/west, which is
// transposed relative to image row/col - the image's horizontal axis
// tracks worldY, and its vertical axis tracks worldX. Then negate the
// resulting pixel-Y for CRS.Simple, same trick as LeafletZoneMap.
function toLatLng(
  worldX: number,
  worldY: number,
  continentID: number,
  corners: ContinentCorners,
  width: number,
  height: number,
): L.LatLngTuple {
  const offset = OUTLAND_OFFSETS[continentID] ?? { offsetX: 0, offsetY: 0 };
  const rawX = worldX - offset.offsetX;
  const rawY = worldY - offset.offsetY;

  const { top_left, bottom_right } = corners;
  const px = ((top_left.world_y - rawY) / (top_left.world_y - bottom_right.world_y)) * width;
  const py = ((top_left.world_x - rawX) / (top_left.world_x - bottom_right.world_x)) * height;
  return [-py, px];
}

export function LeafletContinentMap({ imageUrl, imageWidth, imageHeight, corners, points, mapName }: Props) {
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

    return () => {
      map.remove();
      mapRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [imageUrl, imageWidth, imageHeight]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    const ringColor = getComputedStyle(document.documentElement).getPropertyValue("--surface-1").trim() || "#fff";

    const markers = points
      .filter((p) => p.worldX !== undefined && p.worldY !== undefined)
      .map((p) => {
        const marker = L.circleMarker(toLatLng(p.worldX!, p.worldY!, p.continentID ?? 530, corners, imageWidth, imageHeight), {
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

    return () => {
      for (const m of markers) m.remove();
    };
  }, [points, corners, imageWidth, imageHeight]);

  return (
    <div
      ref={containerRef}
      className="leaflet-zone-map"
      role="img"
      aria-label={`Continent map of ${mapName} with sighting locations`}
    />
  );
}
