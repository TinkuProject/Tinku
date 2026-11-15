import { SubscriptionStatus } from "../constants/enums.constants";

export interface UserSubscription {
  id: number;
  user_id: string;
  plan_id: number;
  start_date: Date;
  end_date?: Date;
  status: SubscriptionStatus;
}