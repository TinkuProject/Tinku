import { PaymentMethod, PaymentStatus, PaymentType } from "../constants/enums.constants";

export interface Payment {
  id: number;
  user_id: string;
  method: PaymentMethod;
  status: PaymentStatus;
  amount: number;
  amount_minor?: number | null;
  currency_minor_unit?: number | null;
  currency: string;
  external_reference?: string | null;
  stripe_client_request_id?: string | null;
  gateway_target_id?: number | null;
  type: PaymentType;

  created_at: Date;
  updated_at?: Date | null;
}
