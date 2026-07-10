import { useEffect, useRef } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import type { Sighting } from "../lib/types";
import { classColor } from "../lib/classColors";
import { absoluteTime, relativeTime } from "../lib/format";

interface Props {
  imageUrl: string;
  imageWidth: number;
  imageHeight: number;
  points: Sighting[];
  zoneName: string;
}

// L.CRS.Simple treats coordinates as [y, x] with y increasing upward (like
// normal map "latitude"), but mapX/mapY (from Blizzard's own
// GetPlayerMapPosition - see Position.lua) are [0,0] at the TOP-LEFT with y
// increasing downward, same as any image/screen. Negating y converts one
// convention to the other; this is the standard trick for putting
// screen-space art on a CRS.Simple map (floor plans, game maps, etc).
function toLatLng(mapX: number, mapY: number, width: number, height: number): L.LatLngTuple {
  return [-(mapY * height), mapX * width];
}

export function LeafletZoneMap({ imageUrl, imageWidth, imageHeight, points, zoneName }: Props) {
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
      minZoom: -2,
      maxZoom: 3,
      attributionControl: false,
    });
    L.imageOverlay(imageUrl, bounds).addTo(map);
    map.fitBounds(bounds);
    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
    };
    // Re-init whenever the underlying image (i.e. the zone) changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [imageUrl, imageWidth, imageHeight]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    // Leaflet's SVG renderer sets `stroke` as a plain attribute, not a CSS
    // style property, so a raw `var(--surface-1)` string won't resolve -
    // read the computed value once per render pass instead.
    const ringColor = getComputedStyle(document.documentElement).getPropertyValue("--surface-1").trim() || "#fff";

    const markers = points
      .filter((p) => p.mapX !== undefined && p.mapY !== undefined)
      .map((p) => {
        const marker = L.circleMarker(toLatLng(p.mapX!, p.mapY!, imageWidth, imageHeight), {
          radius: 6,
          weight: 2,
          color: ringColor,
          fillColor: classColor(p.class),
          fillOpacity: 1,
        });
        marker.bindTooltip(
          `<b>${p.player}</b>${p.class ? ` (${p.class}${p.level ? " " + p.level : ""})` : ""}<br/>${relativeTime(
            p.ts,
          )} &middot; <span title="${absoluteTime(p.ts)}">${p.method}</span>`,
        );
        marker.addTo(map);
        return marker;
      });

    return () => {
      for (const m of markers) m.remove();
    };
  }, [points, imageWidth, imageHeight]);

  return (
    <div
      ref={containerRef}
      className="leaflet-zone-map"
      role="img"
      aria-label={`Map of ${zoneName} with sighting locations`}
    />
  );
}
