import { VisitEntity } from "../constants/enums.constants";

export type NearbyItemDTO = {
  entityId: number;
  entityType: VisitEntity;
  name: string;
  latitude: number;
  longitude: number;
  distance: number;
  imageUrl?: string | null;
};