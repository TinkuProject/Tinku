import wkx from "wkx";

// PARSE (DB → APP)
export function parseLocation(
  hex: string | null
): { latitude: number; longitude: number } | null {
  if (!hex) return null;

  const buffer = Buffer.from(hex, "hex");
  const geom = wkx.Geometry.parse(buffer);

  const geo = geom.toGeoJSON() as {
    type: string;
    coordinates: unknown;
  };

  if (
    geo.type !== "Point" ||
    !Array.isArray(geo.coordinates) ||
    geo.coordinates.length !== 2
  ) {
    throw new Error("Invalid geometry type");
  }

  const [lon, lat] = geo.coordinates as [number, number];

  return {
    latitude: lat,
    longitude: lon,
  };
}

// BUILD (APP → DB)
export function buildPoint(location?: {
  coordinates: [number, number]; // [lon, lat]
}) {
  if (!location?.coordinates) return undefined;

  const [lon, lat] = location.coordinates;

  if (
    typeof lon !== "number" ||
    typeof lat !== "number" ||
    Number.isNaN(lon) ||
    Number.isNaN(lat)
  ) {
    throw new Error("Invalid coordinates");
  }

  return `SRID=4326;POINT(${lon} ${lat})`;
}