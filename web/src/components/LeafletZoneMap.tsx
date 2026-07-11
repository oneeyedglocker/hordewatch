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
      // Extra SVG renderer padding so markers away from the initial
      // viewport center don't land outside the renderer's bounds and
      // render as degenerate empty paths (see LeafletContinentMap.tsx,
      // where this was caught at the continent image's much larger scale).
      renderer: L.svg({ padding: 10 }),
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

    const withCoords = points.filter((p) => p.mapX !== undefined && p.mapY !== undefined);

    const markers = withCoords.map((p) => {
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

    // A trail per player (chronological path across their own sightings) -
    // only drawn when few enough distinct players are in view for it to add
    // clarity instead of spaghetti (see buildTrails). The most recent point
    // in each trail gets a bigger ring so direction ("this is where they
    // were headed") is readable from the dot sizes alone.
    const trailLines: L.Polyline[] = [];
    for (const trail of buildTrails(withCoords)) {
      const latlngs = trail.map((p) => toLatLng(p.mapX!, p.mapY!, imageWidth, imageHeight));
      trailLines.push(
        L.polyline(latlngs, { color: ringColor, weight: 2, opacity: 0.55, dashArray: "4,6" }).addTo(map),
      );
      const lastMarker = markers.find((m) => {
        const ll = m.getLatLng();
        const target = latlngs[latlngs.length - 1];
        return ll.lat === target[0] && ll.lng === target[1];
      });
      lastMarker?.setRadius(9);
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
      aria-label={`Map of ${zoneName} with sighting locations`}
    />
  );
}
