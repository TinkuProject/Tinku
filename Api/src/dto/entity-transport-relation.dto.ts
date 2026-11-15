import { VisitEntity } from "../constants/enums.constants";

export interface EntityTransportRelation {
  entity_type: VisitEntity;
  entity_id: number;
  transport_line_id: number;
  distance_m?: number | null;
  radius_m?: number | null;
  source?: string | null;
  computed_at?: Date | null;
}
