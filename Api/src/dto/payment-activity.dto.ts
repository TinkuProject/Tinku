import { PaymentType, TransactionType } from "../constants/enums.constants";

export type PaymentActivityKind =
  | "payment_request"
  | "financial_transaction";

export type PaymentActivityFlow = "income" | "expense";

export type PaymentActivityStatus =
  | "pending"
  | "approved"
  | "rejected"
  | "failed"
  | "cancelled"
  | "reversed";

export interface PaymentActivityItem {
  id: number;
  kind: PaymentActivityKind;
  flow: PaymentActivityFlow;

  type: PaymentType | TransactionType;
  title: string;

  status: PaymentActivityStatus;
  statusLabel: string;

  amount: number;
  amountLabel: string;
  currency: string;

  createdAt: string;
  updatedAt?: string | null;

  paymentId?: number | null;
  targetId?: number | null;

  description?: string | null;
  comment?: string | null;
  reviewedBy?: string | null;
  reviewedAt?: string | null;

  referenceId?: number | null;
  purpose?: string | null;
}
