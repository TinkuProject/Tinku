import { BasicStatus } from "../constants/enums.constants";

export interface CoinPackage {
  id: number;
  name: string;
  tinkus_amount: number;
  cash_amount: number;
  status: BasicStatus;

  created_at: Date;
  updated_at?: Date | null;
}