import { PromotionStatus, VisitEntity } from "../constants/enums.constants";

export interface Boost {
  id: number;
  entity_type: VisitEntity;
  entity_id: number;
  start_date: Date;
  end_date: Date;
  status: PromotionStatus;

  created_at: Date;
  updated_at?: Date | null;
}