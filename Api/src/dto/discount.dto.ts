import { PromotionStatus } from "../constants/enums.constants";

export interface Discount {
  id: number;
  business_id: number;
  description?: string | null;
  discount_percent: number;
  start_date: Date;
  end_date: Date;
  status: PromotionStatus;

  created_at: Date;
  updated_at?: Date | null;
}