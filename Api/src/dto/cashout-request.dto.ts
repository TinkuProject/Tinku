import { ApprovalStatus } from "../constants/enums.constants";

export interface CashoutRequest {
  id: number;
  user_id: string;
  cashout_package_id: number;
  status: ApprovalStatus;
  tinkus_amount: number;
  cash_amount: number;
  comment?: string | null;
  reviewed_by?: string | null;
  reviewed_at?: Date | null;
  transaction_id?: number | null;
  created_at: Date;
  updated_at?: Date | null;
}
