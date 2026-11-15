import { VisitEntity, VISIT_ENTITY } from "../constants/enums.constants";
import { NearbyItemDTO } from "../dto/nearby.dto";

export function mapNearbyItem(row: any): NearbyItemDTO {
  if (!VISIT_ENTITY.includes(row.entity_type)) {
    throw new Error(
      `Invalid entity type: ${row.entity_type}`
    );
  }

  return {
    entityId: Number(row.entity_id),
    entityType: row.entity_type as VisitEntity,

    name: String(row.name ?? ""),

    latitude: Number(row.latitude),
    longitude: Number(row.longitude),
    distance: Number(row.distance),

    imageUrl: row.image_url
      ? String(row.image_url)
      : null,
  };
}