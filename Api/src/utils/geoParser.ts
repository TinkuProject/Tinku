import wkx from "wkx";

export function parseLocation<T>(data: T): T {
  if (!data) return data;

  const parseGeometry = (value: any) => {
    if (typeof value !== "string") return value;

    try {
      const geom = wkx.Geometry.parse(Buffer.from(value, "hex"));
      return geom.toGeoJSON();
    } catch (e) {
      console.error("Error parsing location:", e);
      return value;
    }
  };

  const parseOne = (obj: any) => {
    const newObj = { ...obj };

    // ubicación directa
    if (newObj.location) {
      newObj.location = parseGeometry(newObj.location);
    }

    // stops como objeto
    if (newObj.stops?.location) {
      newObj.stops = {
        ...newObj.stops,
        location: parseGeometry(newObj.stops.location),
      };
    }

    return newObj;
  };

  return Array.isArray(data)
    ? (data.map(parseOne) as T)
    : (parseOne(data) as T);
}