import { BasicStatus } from "../constants/enums.constants";

export interface SubscriptionPlan {
  id: number;
  name: string;
  price: number;
  currency: string;
  duration_months: number;
  included_tinku: number;
  status: BasicStatus;

  created_at: Date;
  updated_at?: Date | null;
}